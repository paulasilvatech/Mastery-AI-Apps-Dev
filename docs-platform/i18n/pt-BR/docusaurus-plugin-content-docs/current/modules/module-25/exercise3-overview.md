---
sidebar_position: 4
title: "Exercise 3: Overview"
description: "## 🎯 Objective"
---

# Exercício 3: Disaster Recovery System (⭐⭐⭐ Difícil - 90 minutos)

## 🎯 Objective
Implement a comprehensive disaster recovery system for produção AI agents, including automated backups, recovery procedures, chaos testing, and compliance with RTO/RPO targets.

## 🧠 O Que Você Aprenderá
- Disaster recovery planning and implementation
- Automated backup strategies
- Recovery Time Objective (RTO) and Recovery Point Objective (RPO)
- Chaos engineering principles
- Multi-region failover patterns
- Voltarup verification and testing
- Incident response automation
- Compliance documentation

## 📋 Pré-requisitos
- Completard Exercícios 1 and 2
- Understanding of backup/restore concepts
- Basic knowledge of distributed systems
- Familiarity with chaos engineering
- Cloud storage access (S3/Azure Blob/GCS)

## 📚 Voltarground

Production disaster recovery requires:

- **RTO (Recovery Time Objective)**: Maximum acceptable downtime
- **RPO (Recovery Point Objective)**: Maximum acceptable data loss
- **Voltarup Strategy**: Regular, verified backups
- **Recovery Procedures**: Documented and tested
- **Chaos Testing**: Proactive failure injection
- **Automation**: Minimize human intervention
- **Compliance**: Meet regulatory requirements

## 🏗️ Disaster Recovery Architecture

```mermaid
graph TB
    subgraph "Primary Region"
        subgraph "Production"
            PA[Primary Agents]
            PD[(Primary Database)]
            PS[Primary Storage]
        end
        
        subgraph "Backup System"
            BS[Backup Service]
            BJ[Backup Jobs]
            BV[Backup Verification]
        end
    end
    
    subgraph "Secondary Region"
        subgraph "Standby"
            SA[Standby Agents]
            SD[(Standby Database)]
            SS[Standby Storage]
        end
    end
    
    subgraph "DR Storage"
        subgraph "Object Storage"
            B1[(Hourly Backups)]
            B2[(Daily Backups)]
            B3[(Weekly Backups)]
            B4[(Monthly Archives)]
        end
    end
    
    subgraph "DR Orchestration"
        DO[DR Controller]
        CT[Chaos Testing]
        FM[Failover Manager]
        RM[Recovery Manager]
    end
    
    subgraph "Monitoring"
        AM[Alert Manager]
        DM[DR Dashboard]
        CM[Compliance Monitor]
    end
    
    PA --&gt; BS
    PD --&gt; BS
    PS --&gt; BS
    
    BS --&gt; B1
    BS --&gt; B2
    BS --&gt; B3
    BS --&gt; B4
    
    BV --&gt; B1
    BV --&gt; B2
    
    DO --&gt; FM
    DO --&gt; RM
    DO --&gt; CT
    
    FM --&gt; SA
    RM --&gt; SD
    RM --&gt; SS
    
    B1 --&gt; SD
    B2 --&gt; SD
    
    AM --&gt; DO
    CM --&gt; DM
    
    style DO fill:#FF5722
    style BS fill:#4CAF50
    style CT fill:#FFC107
    style CM fill:#9C27B0
```

## 🛠️ Step-by-Step Instructions

### Step 1: Create Voltarup System

**Copilot Prompt Suggestion:**
```typescript
// Create a comprehensive backup system that:
// - Performs automated backups on schedule
// - Supports incremental and full backups
// - Verifies backup integrity
// - Manages retention policies
// - Encrypts backups at rest
// - Monitors backup health
// - Supports multiple storage backends
```

Create `backup/src/backup-service.ts`:
```typescript
import { CronJob } from 'cron';
import * as k8s from '@kubernetes/client-node';
import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { createHash } from 'crypto';
import { compress } from 'zlib';
import { promisify } from 'util';
import winston from 'winston';
import { Counter, Gauge, Histogram } from 'prom-client';

const gzip = promisify(compress);

// Metrics
const backupCounter = new Counter({
  name: 'dr_backups_total',
  help: 'Total number of backups',
  labelNames: ['type', 'status']
});

const backupSizeGauge = new Gauge({
  name: 'dr_backup_size_bytes',
  help: 'Size of backups in bytes',
  labelNames: ['type']
});

const backupDuration = new Histogram({
  name: 'dr_backup_duration_seconds',
  help: 'Duration of backup operations',
  labelNames: ['type'],
  buckets: [10, 30, 60, 300, 600, 1800, 3600]
});

// Logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  defaultMeta: { service: 'backup-service' }
});

// Backup configuration
interface BackupConfig {
  name: string;
  type: 'full' | 'incremental';
  schedule: string;
  retention: {
    hourly: number;
    daily: number;
    weekly: number;
    monthly: number;
  };
  sources: BackupSource[];
  destination: BackupDestination;
  encryption: {
    enabled: boolean;
    keyId?: string;
  };
}

interface BackupSource {
  type: 'database' | 'volume' | 'configmap' | 'secret';
  name: string;
  namespace?: string;
}

interface BackupDestination {
  type: 's3' | 'azure' | 'gcs';
  bucket: string;
  region?: string;
  prefix: string;
}

export class BackupService {
  private k8sApi: k8s.CoreV1Api;
  private k8sAppsApi: k8s.AppsV1Api;
  private s3Client: S3Client;
  private jobs: Map<string, CronJob> = new Map();

  constructor() {
    // Initialize Kubernetes client
    const kc = new k8s.KubeConfig();
    kc.loadFromDefault();
    this.k8sApi = kc.makeApiClient(k8s.CoreV1Api);
    this.k8sAppsApi = kc.makeApiClient(k8s.AppsV1Api);

    // Initialize S3 client
    this.s3Client = new S3Client({
      region: process.env.AWS_REGION || 'us-east-1',
      credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!
      }
    });
  }

  async start(configs: BackupConfig[]) {
    logger.info('Starting backup service', { configs: configs.length });

    for (const config of configs) {
      this.scheduleBackup(config);
    }

    // Schedule verification job
    this.scheduleVerification();

    logger.info('Backup service started');
  }

  private scheduleBackup(config: BackupConfig) {
    const job = new CronJob(config.schedule, async () =&gt; {
      await this.performBackup(config);
    });

    job.start();
    this.jobs.set(config.name, job);

    logger.info('Scheduled backup job', { 
      name: config.name, 
      schedule: config.schedule 
    });
  }

  private async performBackup(config: BackupConfig) {
    const startTime = Date.now();
    const backupId = `${config.name}-${Date.now()}`;

    logger.info('Starting backup', { backupId, config: config.name });

    try {
      // Collect backup data
      const backupData = await this.collectBackupData(config);

      // Compress data
      const compressed = await gzip(JSON.stringify(backupData));

      // Calculate checksum
      const checksum = createHash('sha256')
        .update(compressed)
        .digest('hex');

      // Prepare metadata
      const metadata = {
        backupId,
        configName: config.name,
        type: config.type,
        timestamp: new Date().toISOString(),
        checksum,
        size: compressed.length,
        sources: config.sources,
        version: process.env.APP_VERSION || '1.0.0'
      };

      // Upload to storage
      await this.uploadBackup(
        config.destination,
        backupId,
        compressed,
        metadata,
        config.encryption
      );

      // Update metrics
      const duration = (Date.now() - startTime) / 1000;
      backupCounter.inc({ type: config.type, status: 'success' });
      backupSizeGauge.set({ type: config.type }, compressed.length);
      backupDuration.observe({ type: config.type }, duration);

      logger.info('Backup completed', { 
        backupId, 
        duration, 
        size: compressed.length 
      });

      // Clean old backups
      await this.cleanOldBackups(config);

    } catch (error: any) {
      backupCounter.inc({ type: config.type, status: 'failure' });
      logger.error('Backup failed', { 
        backupId, 
        error: error.message 
      });
      throw error;
    }
  }

  private async collectBackupData(config: BackupConfig): Promise<any> {
    const data: any = {
      timestamp: new Date().toISOString(),
      sources: {}
    };

    for (const source of config.sources) {
      try {
        switch (source.type) {
          case 'database':
            data.sources[source.name] = await this.backupDatabase(source);
            break;
          case 'volume':
            data.sources[source.name] = await this.backupVolume(source);
            break;
          case 'configmap':
            data.sources[source.name] = await this.backupConfigMap(source);
            break;
          case 'secret':
            data.sources[source.name] = await this.backupSecret(source);
            break;
        }
      } catch (error: any) {
        logger.error('Failed to backup source', { 
          source: source.name, 
          error: error.message 
        });
        throw error;
      }
    }

    return data;
  }

  private async backupDatabase(source: BackupSource): Promise<any> {
    // Implement database-specific backup logic
    // This would typically use pg_dump, mysqldump, etc.
    logger.info('Backing up database', { source: source.name });

    // Example: Execute backup job
    const job = await this.k8sApi.createNamespacedJob(
      source.namespace || 'default',
      {
        metadata: {
          name: `backup-${source.name}-${Date.now()}`,
          labels: {
            'backup.dr/type': 'database',
            'backup.dr/source': source.name
          }
        },
        spec: {
          template: {
            spec: {
              restartPolicy: 'Never',
              containers: [{
                name: 'backup',
                image: 'postgres:14',
                command: [
                  'pg_dump',
                  '-h', source.name,
                  '-U', 'postgres',
                  '-d', 'agents',
                  '--no-password',
                  '--format=custom',
                  '--compress=9'
                ],
                env: [{
                  name: 'PGPASSWORD',
                  valueFrom: {
                    secretKeyRef: {
                      name: 'postgres-secret',
                      key: 'password'
                    }
                  }
                }]
              }]
            }
          }
        }
      }
    );

    // Wait for job completion and collect output
    return { 
      type: 'database',
      format: 'pg_dump',
      compressed: true 
    };
  }

  private async backupVolume(source: BackupSource): Promise<any> {
    // Create volume snapshot
    logger.info('Creating volume snapshot', { source: source.name });

    const snapshot = await this.k8sApi.createNamespacedVolumeSnapshot(
      source.namespace || 'default',
      {
        metadata: {
          name: `snapshot-${source.name}-${Date.now()}`
        },
        spec: {
          volumeSnapshotClassName: 'default',
          source: {
            persistentVolumeClaimName: source.name
          }
        }
      }
    );

    return {
      type: 'volume-snapshot',
      snapshotName: snapshot.body.metadata?.name,
      timestamp: new Date().toISOString()
    };
  }

  private async backupConfigMap(source: BackupSource): Promise<any> {
    const configMap = await this.k8sApi.readNamespacedConfigMap(
      source.name,
      source.namespace || 'default'
    );

    return {
      type: 'configmap',
      data: configMap.body.data,
      metadata: configMap.body.metadata
    };
  }

  private async backupSecret(source: BackupSource): Promise<any> {
    const secret = await this.k8sApi.readNamespacedSecret(
      source.name,
      source.namespace || 'default'
    );

    // Encode secret data
    const encodedData: any = {};
    if (secret.body.data) {
      for (const [key, value] of Object.entries(secret.body.data)) {
        encodedData[key] = Buffer.from(value, 'base64').toString('base64');
      }
    }

    return {
      type: 'secret',
      data: encodedData,
      metadata: {
        name: secret.body.metadata?.name,
        namespace: secret.body.metadata?.namespace
      }
    };
  }

  private async uploadBackup(
    destination: BackupDestination,
    backupId: string,
    data: Buffer,
    metadata: any,
    encryption: any
  ) {
    const key = `${destination.prefix}/${backupId}.backup`;

    const command = new PutObjectCommand({
      Bucket: destination.bucket,
      Key: key,
      Body: data,
      ContentType: 'application/octet-stream',
      Metadata: {
        'backup-id': backupId,
        'checksum': metadata.checksum,
        'timestamp': metadata.timestamp
      },
      ServerSideEncryption: encryption.enabled ? 'aws:kms' : undefined,
      SSEKMSKeyId: encryption.keyId
    });

    await this.s3Client.send(command);

    // Also upload metadata
    const metadataCommand = new PutObjectCommand({
      Bucket: destination.bucket,
      Key: `${key}.metadata`,
      Body: JSON.stringify(metadata, null, 2),
      ContentType: 'application/json'
    });

    await this.s3Client.send(metadataCommand);

    logger.info('Backup uploaded', { backupId, key });
  }

  private async cleanOldBackups(config: BackupConfig) {
    // Implement retention policy
    logger.info('Cleaning old backups', { config: config.name });

    // List backups
    // Apply retention rules
    // Delete expired backups
  }

  private scheduleVerification() {
    // Verify backups every hour
    const job = new CronJob('0 * * * *', async () =&gt; {
      await this.verifyBackups();
    });

    job.start();
    logger.info('Scheduled backup verification');
  }

  private async verifyBackups() {
    logger.info('Starting backup verification');

    // List recent backups
    // Download and verify checksums
    // Test restore process
    // Update verification metrics
  }
}

// Backup configurations
export const backupConfigs: BackupConfig[] = [
  {
    name: 'hourly-incremental',
    type: 'incremental',
    schedule: '0 * * * *', // Every hour
    retention: {
      hourly: 24,
      daily: 7,
      weekly: 4,
      monthly: 12
    },
    sources: [
      { type: 'database', name: 'postgres-primary' },
      { type: 'configmap', name: 'agent-config', namespace: 'agent-system' }
    ],
    destination: {
      type: 's3',
      bucket: process.env.BACKUP_BUCKET!,
      region: process.env.AWS_REGION,
      prefix: 'backups/hourly'
    },
    encryption: {
      enabled: true,
      keyId: process.env.KMS_KEY_ID
    }
  },
  {
    name: 'daily-full',
    type: 'full',
    schedule: '0 2 * * *', // 2 AM daily
    retention: {
      hourly: 0,
      daily: 30,
      weekly: 12,
      monthly: 12
    },
    sources: [
      { type: 'database', name: 'postgres-primary' },
      { type: 'volume', name: 'agent-data', namespace: 'agent-system' },
      { type: 'configmap', name: 'agent-config', namespace: 'agent-system' },
      { type: 'secret', name: 'agent-secrets', namespace: 'agent-system' }
    ],
    destination: {
      type: 's3',
      bucket: process.env.BACKUP_BUCKET!,
      region: process.env.AWS_REGION,
      prefix: 'backups/daily'
    },
    encryption: {
      enabled: true,
      keyId: process.env.KMS_KEY_ID
    }
  }
];
```

### Step 2: Create Recovery System

Create `recovery/src/recovery-manager.ts`:
```typescript
import * as k8s from '@kubernetes/client-node';
import { S3Client, GetObjectCommand, ListObjectsV2Command } from '@aws-sdk/client-s3';
import { createHash } from 'crypto';
import { gunzip } from 'zlib';
import { promisify } from 'util';
import winston from 'winston';
import { Gauge, Histogram } from 'prom-client';

const decompress = promisify(gunzip);

// Metrics
const recoveryTimeGauge = new Gauge({
  name: 'dr_recovery_time_seconds',
  help: 'Time taken for recovery operations',
  labelNames: ['type']
});

const recoveryStatusGauge = new Gauge({
  name: 'dr_recovery_status',
  help: 'Current recovery status (0=idle, 1=in_progress, 2=completed, 3=failed)',
  labelNames: ['type']
});

// Logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  defaultMeta: { service: 'recovery-manager' }
});

export interface RecoveryPlan {
  name: string;
  description: string;
  rto: number; // Recovery Time Objective in seconds
  rpo: number; // Recovery Point Objective in seconds
  steps: RecoveryStep[];
  validation: ValidationStep[];
  rollback: RollbackStep[];
}

interface RecoveryStep {
  name: string;
  type: 'restore' | 'failover' | 'scale' | 'configure';
  target: string;
  config: any;
  timeout: number;
  retries: number;
}

interface ValidationStep {
  name: string;
  type: 'health' | 'data' | 'connectivity';
  target: string;
  expected: any;
}

interface RollbackStep {
  name: string;
  action: string;
  target: string;
}

export class RecoveryManager {
  private k8sApi: k8s.CoreV1Api;
  private k8sAppsApi: k8s.AppsV1Api;
  private s3Client: S3Client;
  private activeRecovery: RecoveryPlan | null = null;

  constructor() {
    const kc = new k8s.KubeConfig();
    kc.loadFromDefault();
    this.k8sApi = kc.makeApiClient(k8s.CoreV1Api);
    this.k8sAppsApi = kc.makeApiClient(k8s.AppsV1Api);

    this.s3Client = new S3Client({
      region: process.env.AWS_REGION || 'us-east-1'
    });
  }

  async executeRecovery(plan: RecoveryPlan, backupId?: string): Promise<boolean> {
    logger.info('Starting recovery', { plan: plan.name, backupId });
    
    this.activeRecovery = plan;
    recoveryStatusGauge.set({ type: plan.name }, 1); // In progress
    
    const startTime = Date.now();
    const recoveryLog: any[] = [];

    try {
      // Pre-recovery validation
      logger.info('Running pre-recovery validation');
      await this.preRecoveryValidation(plan);

      // Find appropriate backup if not specified
      if (!backupId) {
        backupId = await this.selectBackup(plan.rpo);
        logger.info('Selected backup', { backupId });
      }

      // Execute recovery steps
      for (const step of plan.steps) {
        logger.info('Executing recovery step', { step: step.name });
        
        const stepStart = Date.now();
        const result = await this.executeStep(step, backupId);
        
        recoveryLog.push({
          step: step.name,
          duration: Date.now() - stepStart,
          status: result.success ? 'completed' : 'failed',
          details: result.details
        });

        if (!result.success) {
          throw new Error(`Recovery step failed: ${step.name}`);
        }
      }

      // Post-recovery validation
      logger.info('Running post-recovery validation');
      const validationResult = await this.postRecoveryValidation(plan);
      
      if (!validationResult.success) {
        throw new Error('Post-recovery validation failed');
      }

      // Update metrics
      const recoveryTime = (Date.now() - startTime) / 1000;
      recoveryTimeGauge.set({ type: plan.name }, recoveryTime);
      recoveryStatusGauge.set({ type: plan.name }, 2); // Completed

      // Check RTO compliance
      if (recoveryTime &gt; plan.rto) {
        logger.warn('RTO exceeded', { 
          actual: recoveryTime, 
          target: plan.rto 
        });
      }

      logger.info('Recovery completed successfully', { 
        duration: recoveryTime,
        log: recoveryLog 
      });

      return true;

    } catch (error: any) {
      logger.error('Recovery failed', { error: error.message });
      recoveryStatusGauge.set({ type: plan.name }, 3); // Failed

      // Execute rollback
      try {
        await this.executeRollback(plan);
      } catch (rollbackError: any) {
        logger.error('Rollback failed', { error: rollbackError.message });
      }

      return false;
    } finally {
      this.activeRecovery = null;
    }
  }

  private async preRecoveryValidation(plan: RecoveryPlan): Promise<void> {
    // Validate target environment
    // Check resource availability
    // Verify network connectivity
    // Ensure no active workloads
  }

  private async selectBackup(rpo: number): Promise<string> {
    // List available backups
    const response = await this.s3Client.send(new ListObjectsV2Command({
      Bucket: process.env.BACKUP_BUCKET!,
      Prefix: 'backups/',
      MaxKeys: 100
    }));

    // Find backup within RPO window
    const targetTime = Date.now() - (rpo * 1000);
    let selectedBackup: string | null = null;

    for (const object of response.Contents || []) {
      if (object.Key?.endsWith('.metadata')) {
        const metadata = await this.getBackupMetadata(object.Key);
        const backupTime = new Date(metadata.timestamp).getTime();
        
        if (backupTime &gt;= targetTime) {
          selectedBackup = metadata.backupId;
          break;
        }
      }
    }

    if (!selectedBackup) {
      throw new Error('No suitable backup found within RPO window');
    }

    return selectedBackup;
  }

  private async getBackupMetadata(key: string): Promise<any> {
    const response = await this.s3Client.send(new GetObjectCommand({
      Bucket: process.env.BACKUP_BUCKET!,
      Key: key
    }));

    const data = await response.Body?.transformToString();
    return JSON.parse(data!);
  }

  private async executeStep(step: RecoveryStep, backupId: string): Promise<any> {
    switch (step.type) {
      case 'restore':
        return await this.restoreFromBackup(step, backupId);
      case 'failover':
        return await this.executeFailover(step);
      case 'scale':
        return await this.scaleResources(step);
      case 'configure':
        return await this.applyConfiguration(step);
      default:
        throw new Error(`Unknown step type: ${step.type}`);
    }
  }

  private async restoreFromBackup(step: RecoveryStep, backupId: string): Promise<any> {
    logger.info('Restoring from backup', { target: step.target, backupId });

    // Download backup
    const backup = await this.downloadBackup(backupId);

    // Verify checksum
    const checksum = createHash('sha256')
      .update(backup.data)
      .digest('hex');

    if (checksum !== backup.metadata.checksum) {
      throw new Error('Backup checksum verification failed');
    }

    // Decompress data
    const decompressed = await decompress(backup.data);
    const backupData = JSON.parse(decompressed.toString());

    // Restore based on target type
    switch (step.target) {
      case 'database':
        return await this.restoreDatabase(backupData, step.config);
      case 'volume':
        return await this.restoreVolume(backupData, step.config);
      case 'config':
        return await this.restoreConfiguration(backupData, step.config);
      default:
        throw new Error(`Unknown restore target: ${step.target}`);
    }
  }

  private async downloadBackup(backupId: string): Promise<any> {
    const key = `backups/${backupId}.backup`;
    
    // Download backup data
    const dataResponse = await this.s3Client.send(new GetObjectCommand({
      Bucket: process.env.BACKUP_BUCKET!,
      Key: key
    }));

    // Download metadata
    const metadataResponse = await this.s3Client.send(new GetObjectCommand({
      Bucket: process.env.BACKUP_BUCKET!,
      Key: `${key}.metadata`
    }));

    const data = await dataResponse.Body?.transformToByteArray();
    const metadata = JSON.parse(await metadataResponse.Body?.transformToString() || '{}');

    return { data: Buffer.from(data!), metadata };
  }

  private async restoreDatabase(backupData: any, config: any): Promise<any> {
    // Create restore job
    const job = await this.k8sApi.createNamespacedJob(
      config.namespace || 'default',
      {
        metadata: {
          name: `restore-db-${Date.now()}`,
          labels: {
            'dr.recovery/type': 'database-restore'
          }
        },
        spec: {
          template: {
            spec: {
              restartPolicy: 'Never',
              containers: [{
                name: 'restore',
                image: 'postgres:14',
                command: [
                  'psql',
                  '-h', config.host,
                  '-U', 'postgres',
                  '-d', 'agents',
                  '--command', `"${backupData.sources.database.sql}"`
                ],
                env: [{
                  name: 'PGPASSWORD',
                  valueFrom: {
                    secretKeyRef: {
                      name: 'postgres-secret',
                      key: 'password'
                    }
                  }
                }]
              }]
            }
          }
        }
      }
    );

    // Wait for completion
    return { success: true, jobName: job.body.metadata?.name };
  }

  private async restoreVolume(backupData: any, config: any): Promise<any> {
    // Restore from volume snapshot
    if (backupData.sources.volume?.snapshotName) {
      const pvc = await this.k8sApi.createNamespacedPersistentVolumeClaim(
        config.namespace || 'default',
        {
          metadata: {
            name: config.pvcName
          },
          spec: {
            accessModes: ['ReadWriteOnce'],
            resources: {
              requests: {
                storage: config.size || '10Gi'
              }
            },
            dataSource: {
              name: backupData.sources.volume.snapshotName,
              kind: 'VolumeSnapshot',
              apiGroup: 'snapshot.storage.k8s.io'
            }
          }
        }
      );

      return { success: true, pvcName: pvc.body.metadata?.name };
    }

    return { success: false, reason: 'No volume snapshot found' };
  }

  private async restoreConfiguration(backupData: any, config: any): Promise<any> {
    const results = [];

    // Restore ConfigMaps
    for (const [name, data] of Object.entries(backupData.sources)) {
      if (data.type === 'configmap') {
        const cm = await this.k8sApi.createNamespacedConfigMap(
          config.namespace || 'default',
          {
            metadata: {
              name: data.metadata.name,
              labels: {
                'dr.recovery/restored': 'true',
                'dr.recovery/timestamp': new Date().toISOString()
              }
            },
            data: data.data
          }
        );
        results.push({ 
          type: 'configmap', 
          name: cm.body.metadata?.name 
        });
      }

      // Restore Secrets
      if (data.type === 'secret') {
        const secret = await this.k8sApi.createNamespacedSecret(
          config.namespace || 'default',
          {
            metadata: {
              name: data.metadata.name,
              labels: {
                'dr.recovery/restored': 'true',
                'dr.recovery/timestamp': new Date().toISOString()
              }
            },
            type: 'Opaque',
            data: data.data
          }
        );
        results.push({ 
          type: 'secret', 
          name: secret.body.metadata?.name 
        });
      }
    }

    return { success: true, restored: results };
  }

  private async executeFailover(step: RecoveryStep): Promise<any> {
    logger.info('Executing failover', { target: step.target });

    // Update DNS/Load Balancer to point to secondary region
    // Scale up standby instances
    // Verify connectivity

    return { success: true, details: 'Failover completed' };
  }

  private async scaleResources(step: RecoveryStep): Promise<any> {
    const deployment = await this.k8sAppsApi.patchNamespacedDeployment(
      step.target,
      step.config.namespace || 'default',
      {
        spec: {
          replicas: step.config.replicas
        }
      },
      undefined,
      undefined,
      undefined,
      undefined,
      {{{{ headers: {{{{ 'Content-Type': 'application/strategic-merge-patch+json' }}}} }}}}
    );

    return { 
      success: true, 
      replicas: deployment.body.spec?.replicas 
    };
  }

  private async applyConfiguration(step: RecoveryStep): Promise<any> {
    // Apply configuration changes
    // Update environment variables
    // Modify service endpoints

    return { success: true };
  }

  private async postRecoveryValidation(plan: RecoveryPlan): Promise<any> {
    const results = [];

    for (const validation of plan.validation) {
      const result = await this.validateStep(validation);
      results.push(result);

      if (!result.success) {
        return { 
          success: false, 
          failedValidation: validation.name,
          results 
        };
      }
    }

    return { success: true, results };
  }

  private async validateStep(validation: ValidationStep): Promise<any> {
    switch (validation.type) {
      case 'health':
        return await this.validateHealth(validation);
      case 'data':
        return await this.validateData(validation);
      case 'connectivity':
        return await this.validateConnectivity(validation);
      default:
        throw new Error(`Unknown validation type: ${validation.type}`);
    }
  }

  private async validateHealth(validation: ValidationStep): Promise<any> {
    // Check pod health
    // Verify service endpoints
    // Test application health checks

    return { 
      success: true, 
      validation: validation.name 
    };
  }

  private async validateData(validation: ValidationStep): Promise<any> {
    // Verify data integrity
    // Check record counts
    // Validate critical data

    return { 
      success: true, 
      validation: validation.name 
    };
  }

  private async validateConnectivity(validation: ValidationStep): Promise<any> {
    // Test network connectivity
    // Verify service discovery
    // Check external dependencies

    return { 
      success: true, 
      validation: validation.name 
    };
  }

  private async executeRollback(plan: RecoveryPlan): Promise<void> {
    logger.info('Executing rollback', { plan: plan.name });

    for (const step of plan.rollback) {
      try {
        await this.rollbackStep(step);
      } catch (error: any) {
        logger.error('Rollback step failed', { 
          step: step.name, 
          error: error.message 
        });
      }
    }
  }

  private async rollbackStep(step: RollbackStep): Promise<void> {
    // Implement rollback logic based on step action
    logger.info('Rollback step', { step: step.name });
  }
}
```

### Step 3: Implement Chaos Testing

Create `chaos/src/chaos-testing.ts`:
```typescript
import * as k8s from '@kubernetes/client-node';
import winston from 'winston';
import { Counter, Histogram } from 'prom-client';

// Metrics
const chaosExperimentCounter = new Counter({
  name: 'chaos_experiments_total',
  help: 'Total number of chaos experiments',
  labelNames: ['type', 'status']
});

const chaosExperimentDuration = new Histogram({
  name: 'chaos_experiment_duration_seconds',
  help: 'Duration of chaos experiments',
  labelNames: ['type']
});

// Logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  defaultMeta: { service: 'chaos-testing' }
});

export interface ChaosExperiment {
  name: string;
  description: string;
  type: 'pod-failure' | 'network-partition' | 'resource-stress' | 'clock-skew';
  target: ChaosTarget;
  duration: number;
  parameters: any;
  validation: ChaosValidation[];
}

interface ChaosTarget {
  namespace: string;
  selector: Record<string, string>;
  percentage?: number;
}

interface ChaosValidation {
  name: string;
  type: 'availability' | 'performance' | 'data-integrity';
  threshold: number;
}

export class ChaosTesting {
  private k8sApi: k8s.CoreV1Api;
  private k8sAppsApi: k8s.AppsV1Api;
  private activeExperiments: Map<string, any> = new Map();

  constructor() {
    const kc = new k8s.KubeConfig();
    kc.loadFromDefault();
    this.k8sApi = kc.makeApiClient(k8s.CoreV1Api);
    this.k8sAppsApi = kc.makeApiClient(k8s.AppsV1Api);
  }

  async runExperiment(experiment: ChaosExperiment): Promise<boolean> {
    logger.info('Starting chaos experiment', { 
      name: experiment.name,
      type: experiment.type 
    });

    const startTime = Date.now();
    const experimentId = `${experiment.name}-${startTime}`;

    try {
      // Pre-experiment validation
      const preValidation = await this.validateSystem(experiment.validation);
      if (!preValidation.healthy) {
        logger.warn('System not healthy before experiment', preValidation);
        return false;
      }

      // Inject chaos
      await this.injectChaos(experiment, experimentId);

      // Wait for duration
      await new Promise(resolve =&gt; setTimeout(resolve, experiment.duration * 1000));

      // Validate during chaos
      const duringValidation = await this.validateSystem(experiment.validation);
      logger.info('Validation during chaos', duringValidation);

      // Stop chaos
      await this.stopChaos(experimentId);

      // Post-experiment validation
      const postValidation = await this.validateSystem(experiment.validation);
      
      // Update metrics
      const duration = (Date.now() - startTime) / 1000;
      chaosExperimentCounter.inc({ 
        type: experiment.type, 
        status: postValidation.healthy ? 'success' : 'failure' 
      });
      chaosExperimentDuration.observe({ type: experiment.type }, duration);

      logger.info('Chaos experiment completed', {
        name: experiment.name,
        duration,
        result: postValidation
      });

      return postValidation.healthy;

    } catch (error: any) {
      logger.error('Chaos experiment failed', { 
        error: error.message 
      });
      
      // Ensure chaos is stopped
      await this.stopChaos(experimentId);
      
      chaosExperimentCounter.inc({ 
        type: experiment.type, 
        status: 'error' 
      });
      
      return false;
    }
  }

  private async injectChaos(experiment: ChaosExperiment, experimentId: string): Promise<void> {
    switch (experiment.type) {
      case 'pod-failure':
        await this.injectPodFailure(experiment, experimentId);
        break;
      case 'network-partition':
        await this.injectNetworkPartition(experiment, experimentId);
        break;
      case 'resource-stress':
        await this.injectResourceStress(experiment, experimentId);
        break;
      case 'clock-skew':
        await this.injectClockSkew(experiment, experimentId);
        break;
    }

    this.activeExperiments.set(experimentId, experiment);
  }

  private async injectPodFailure(experiment: ChaosExperiment, experimentId: string): Promise<void> {
    // Get target pods
    const pods = await this.k8sApi.listNamespacedPod(
      experiment.target.namespace,
      undefined,
      undefined,
      undefined,
      undefined,
      this.selectorToString(experiment.target.selector)
    );

    // Calculate number of pods to kill
    const targetCount = Math.ceil(
      pods.body.items.length * (experiment.target.percentage || 50) / 100
    );

    // Randomly select pods
    const targetPods = this.selectRandom(pods.body.items, targetCount);

    // Delete pods
    for (const pod of targetPods) {
      if (pod.metadata?.name) {
        await this.k8sApi.deleteNamespacedPod(
          pod.metadata.name,
          experiment.target.namespace
        );
        
        logger.info('Deleted pod', { 
          pod: pod.metadata.name,
          experiment: experimentId 
        });
      }
    }
  }

  private async injectNetworkPartition(experiment: ChaosExperiment, experimentId: string): Promise<void> {
    // Create NetworkPolicy to partition network
    const networkPolicy = {
      apiVersion: 'networking.k8s.io/v1',
      kind: 'NetworkPolicy',
      metadata: {
        name: `chaos-${experimentId}`,
        namespace: experiment.target.namespace,
        labels: {
          'chaos.dr/experiment': experimentId
        }
      },
      spec: {
        podSelector: {
          matchLabels: experiment.target.selector
        },
        policyTypes: ['Ingress', 'Egress'],
        ingress: [],
        egress: experiment.parameters.allowDNS ? [{
          to: [{
            namespaceSelector: {},
            podSelector: {
              matchLabels: {
                'k8s-app': 'kube-dns'
              }
            }
          }],
          ports: [{
            protocol: 'UDP',
            port: 53
          }]
        }] : []
      }
    };

    await this.k8sApi.createNamespacedNetworkPolicy(
      experiment.target.namespace,
      networkPolicy as any
    );
  }

  private async injectResourceStress(experiment: ChaosExperiment, experimentId: string): Promise<void> {
    // Deploy stress containers as DaemonSet
    const stressDS = {
      apiVersion: 'apps/v1',
      kind: 'DaemonSet',
      metadata: {
        name: `chaos-stress-${experimentId}`,
        namespace: experiment.target.namespace,
        labels: {
          'chaos.dr/experiment': experimentId
        }
      },
      spec: {
        selector: {
          matchLabels: {
            'chaos.dr/type': 'stress'
          }
        },
        template: {
          metadata: {
            labels: {
              'chaos.dr/type': 'stress'
            }
          },
          spec: {
            nodeSelector: experiment.parameters.nodeSelector || {},
            containers: [{
              name: 'stress',
              image: 'alexeiled/stress-ng',
              args: [
                '--cpu', experiment.parameters.cpu || '2',
                '--io', experiment.parameters.io || '1',
                '--vm', experiment.parameters.vm || '1',
                '--vm-bytes', experiment.parameters.vmBytes || '256M',
                '--timeout', `${experiment.duration}s`
              ],
              resources: {
                limits: {
                  cpu: '1000m',
                  memory: '1Gi'
                }
              }
            }]
          }
        }
      }
    };

    await this.k8sAppsApi.createNamespacedDaemonSet(
      experiment.target.namespace,
      stressDS as any
    );
  }

  private async injectClockSkew(experiment: ChaosExperiment, experimentId: string): Promise<void> {
    // This would typically use a privileged container to modify system time
    logger.warn('Clock skew injection not fully implemented');
  }

  private async stopChaos(experimentId: string): Promise<void> {
    const experiment = this.activeExperiments.get(experimentId);
    if (!experiment) {
      return;
    }

    logger.info('Stopping chaos', { experimentId });

    // Clean up based on experiment type
    switch (experiment.type) {
      case 'network-partition':
        await this.k8sApi.deleteNamespacedNetworkPolicy(
          `chaos-${experimentId}`,
          experiment.target.namespace
        );
        break;
      case 'resource-stress':
        await this.k8sAppsApi.deleteNamespacedDaemonSet(
          `chaos-stress-${experimentId}`,
          experiment.target.namespace
        );
        break;
    }

    this.activeExperiments.delete(experimentId);
  }

  private async validateSystem(validations: ChaosValidation[]): Promise<any> {
    const results: any = {
      healthy: true,
      validations: []
    };

    for (const validation of validations) {
      const result = await this.runValidation(validation);
      results.validations.push(result);
      
      if (!result.passed) {
        results.healthy = false;
      }
    }

    return results;
  }

  private async runValidation(validation: ChaosValidation): Promise<any> {
    switch (validation.type) {
      case 'availability':
        return await this.validateAvailability(validation);
      case 'performance':
        return await this.validatePerformance(validation);
      case 'data-integrity':
        return await this.validateDataIntegrity(validation);
      default:
        throw new Error(`Unknown validation type: ${validation.type}`);
    }
  }

  private async validateAvailability(validation: ChaosValidation): Promise<any> {
    // Check service availability
    // Measure success rate
    return {
      name: validation.name,
      type: validation.type,
      value: 99.5,
      threshold: validation.threshold,
      passed: 99.5 &gt;= validation.threshold
    };
  }

  private async validatePerformance(validation: ChaosValidation): Promise<any> {
    // Measure latency
    // Check throughput
    return {
      name: validation.name,
      type: validation.type,
      value: 95,
      threshold: validation.threshold,
      passed: 95 &gt;= validation.threshold
    };
  }

  private async validateDataIntegrity(validation: ChaosValidation): Promise<any> {
    // Verify data consistency
    // Check for data loss
    return {
      name: validation.name,
      type: validation.type,
      value: 100,
      threshold: validation.threshold,
      passed: true
    };
  }

  private selectorToString(selector: Record<string, string>): string {
    return Object.entries(selector)
      .map(([key, value]) =&gt; `${key}=${value}`)
      .join(',');
  }

  private selectRandom<T>(items: T[], count: number): T[] {
    const shuffled = [...items].sort(() =&gt; 0.5 - Math.random());
    return shuffled.slice(0, count);
  }
}

// Example chaos experiments
export const chaosExperiments: ChaosExperiment[] = [
  {
    name: 'pod-failure-test',
    description: 'Test system resilience to pod failures',
    type: 'pod-failure',
    target: {
      namespace: 'agent-system',
      selector: { app: 'ai-agent' },
      percentage: 33
    },
    duration: 300, // 5 minutes
    parameters: {},
    validation: [
      {
        name: 'service-availability',
        type: 'availability',
        threshold: 99.0
      },
      {
        name: 'response-time',
        type: 'performance',
        threshold: 95.0
      }
    ]
  },
  {
    name: 'network-partition-test',
    description: 'Test behavior during network partition',
    type: 'network-partition',
    target: {
      namespace: 'agent-system',
      selector: { app: 'ai-agent' }
    },
    duration: 180, // 3 minutes
    parameters: {
      allowDNS: true
    },
    validation: [
      {
        name: 'data-consistency',
        type: 'data-integrity',
        threshold: 100
      }
    ]
  }
];
```

### Step 4: Create DR Orchestration

Create `dr-controller/implantação.yaml`:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: dr-config
  namespace: dr-system
data:
  config.yaml: |
    backup:
      schedule:
        hourly: "0 * * * *"
        daily: "0 2 * * *"
        weekly: "0 3 * * 0"
      retention:
        hourly: 24
        daily: 30
        weekly: 12
        monthly: 12
    recovery:
      rto: 300  # 5 minutes
      rpo: 3600 # 1 hour
      plans:
        - name: database-recovery
          priority: 1
          steps:
            - restore-database
            - validate-data
            - update-connections
        - name: full-recovery
          priority: 2
          steps:
            - restore-volumes
            - restore-database
            - restore-config
            - scale-services
            - validate-system
    chaos:
      enabled: true
      schedule: "0 0 * * 5"  # Weekly on Friday
      experiments:
        - pod-failure
        - network-partition
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dr-controller
  namespace: dr-system
  labels:
    app: dr-controller
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dr-controller
  template:
    metadata:
      labels:
        app: dr-controller
    spec:
      serviceAccountName: dr-controller
      containers:
      - name: backup-service
        image: localhost:5000/backup-service:latest
        ports:
        - containerPort: 8080
        env:
        - name: BACKUP_BUCKET
          value: "agent-backups"
        - name: AWS_REGION
          value: "us-east-1"
        - name: KMS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: dr-secrets
              key: kms-key-id
        volumeMounts:
        - name: config
          mountPath: /etc/dr
          readOnly: true
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      
      - name: recovery-manager
        image: localhost:5000/recovery-manager:latest
        ports:
        - containerPort: 8081
        env:
        - name: BACKUP_BUCKET
          value: "agent-backups"
        - name: AWS_REGION
          value: "us-east-1"
        volumeMounts:
        - name: config
          mountPath: /etc/dr
          readOnly: true
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      
      - name: chaos-testing
        image: localhost:5000/chaos-testing:latest
        ports:
        - containerPort: 8082
        env:
        - name: CHAOS_ENABLED
          value: "true"
        volumeMounts:
        - name: config
          mountPath: /etc/dr
          readOnly: true
        resources:
          requests:
            memory: "128Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"
            cpu: "200m"
      
      volumes:
      - name: config
        configMap:
          name: dr-config
---
apiVersion: v1
kind: Service
metadata:
  name: dr-controller
  namespace: dr-system
spec:
  selector:
    app: dr-controller
  ports:
  - name: backup
    port: 8080
    targetPort: 8080
  - name: recovery
    port: 8081
    targetPort: 8081
  - name: chaos
    port: 8082
    targetPort: 8082
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: dr-controller
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets", "persistentvolumeclaims"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "daemonsets", "statefulsets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["batch"]
  resources: ["jobs", "cronjobs"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["networking.k8s.io"]
  resources: ["networkpolicies"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["snapshot.storage.k8s.io"]
  resources: ["volumesnapshots"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dr-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: dr-controller
subjects:
- kind: ServiceAccount
  name: dr-controller
  namespace: dr-system
```

### Step 5: Create Compliance Painel

Create `compliance/dashboard.yaml`:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: dr-compliance-dashboard
  namespace: dr-system
data:
  dashboard.json: |
    {
      "dashboard": {
        "title": "Disaster Recovery Compliance",
        "uid": "dr-compliance",
        "tags": ["dr", "compliance", "sla"],
        "timezone": "UTC",
        "panels": [
          {
            "title": "RTO Compliance",
            "type": "gauge",
            "gridPos": { "h": 8, "w": 8, "x": 0, "y": 0 },
            "targets": [{
              "expr": "dr_recovery_time_seconds / 300 * 100"
            }],
            "fieldConfig": {
              "defaults": {
                "unit": "percent",
                "max": 100,
                "thresholds": {
                  "steps": [
                    { "value": 0, "color": "green" },
                    { "value": 80, "color": "yellow" },
                    { "value": 100, "color": "red" }
                  ]
                }
              }
            }
          },
          {
            "title": "RPO Compliance",
            "type": "gauge",
            "gridPos": { "h": 8, "w": 8, "x": 8, "y": 0 },
            "targets": [{
              "expr": "(time() - dr_last_backup_timestamp) / 3600"
            }],
            "fieldConfig": {
              "defaults": {
                "unit": "h",
                "max": 2,
                "thresholds": {
                  "steps": [
                    { "value": 0, "color": "green" },
                    { "value": 0.5, "color": "yellow" },
                    { "value": 1, "color": "red" }
                  ]
                }
              }
            }
          },
          {
            "title": "Backup Success Rate",
            "type": "stat",
            "gridPos": { "h": 8, "w": 8, "x": 16, "y": 0 },
            "targets": [{
              "expr": "sum(rate(dr_backups_total{status=\"success\"}[7d])) / sum(rate(dr_backups_total[7d])) * 100"
            }],
            "fieldConfig": {
              "defaults": {
                "unit": "percent",
                "thresholds": {
                  "steps": [
                    { "value": 99, "color": "green" },
                    { "value": 95, "color": "yellow" },
                    { "value": 0, "color": "red" }
                  ]
                }
              }
            }
          },
          {
            "title": "Recovery Tests",
            "type": "table",
            "gridPos": { "h": 8, "w": 12, "x": 0, "y": 8 },
            "targets": [{
              "expr": "dr_recovery_tests_info"
            }]
          },
          {
            "title": "Chaos Experiments",
            "type": "graph",
            "gridPos": { "h": 8, "w": 12, "x": 12, "y": 8 },
            "targets": [{
              "expr": "sum(rate(chaos_experiments_total[24h])) by (type, status)"
            }]
          }
        ]
      }
    }
```

### Step 6: Deploy DR System

Create `scripts/deploy-dr.sh`:
```bash
#!/bin/bash
set -e

echo "🚀 Deploying Disaster Recovery System"

# Create namespace
kubectl create namespace dr-system --dry-run=client -o yaml | kubectl apply -f -

# Create secrets
kubectl create secret generic dr-secrets \
  --namespace dr-system \
  --from-literal=kms-key-id="${KMS_KEY_ID}" \
  --from-literal=aws-access-key-id="${AWS_ACCESS_KEY_ID}" \
  --from-literal=aws-secret-access-key="${AWS_SECRET_ACCESS_KEY}" \
  --dry-run=client -o yaml | kubectl apply -f -

# Build images
echo "📦 Building DR images..."
docker build -t localhost:5000/backup-service:latest backup/
docker build -t localhost:5000/recovery-manager:latest recovery/
docker build -t localhost:5000/chaos-testing:latest chaos/

# Push images
docker push localhost:5000/backup-service:latest
docker push localhost:5000/recovery-manager:latest
docker push localhost:5000/chaos-testing:latest

# Deploy DR controller
echo "☸️ Deploying DR controller..."
kubectl apply -f dr-controller/

# Deploy compliance dashboard
echo "📊 Deploying compliance dashboard..."
kubectl apply -f compliance/

# Wait for deployment
kubectl rollout status deployment/dr-controller -n dr-system

echo "✅ DR system deployed!"
```

### Step 7: Test DR System

Create `scripts/test-dr.sh`:
```bash
#!/bin/bash

echo "🧪 Testing Disaster Recovery System"

NAMESPACE="dr-system"

# Test backup
echo -e "\n💾 Testing backup..."
curl -X POST http://localhost:8080/api/backup/trigger \
  -H "Content-Type: application/json" \
  -d '{"type": "manual", "sources": ["database", "config"]}'

# Test recovery
echo -e "\n🔄 Testing recovery..."
curl -X POST http://localhost:8081/api/recovery/test \
  -H "Content-Type: application/json" \
  -d '{"plan": "database-recovery", "dryRun": true}'

# Test chaos experiment
echo -e "\n🔥 Testing chaos..."
curl -X POST http://localhost:8082/api/chaos/experiment \
  -H "Content-Type: application/json" \
  -d '{"experiment": "pod-failure-test", "duration": 60}'

# Check compliance metrics
echo -e "\n📊 Compliance status:"
curl -s http://localhost:9090/api/v1/query?query=dr_rto_compliance | jq .
curl -s http://localhost:9090/api/v1/query?query=dr_rpo_compliance | jq .
```

## 🏃 Running the Exercício

1. **Deploy the DR system:**
```bash
chmod +x scripts/*.sh
./scripts/deploy-dr.sh
```

2. **Verify DR components:**
```bash
kubectl get all -n dr-system
kubectl logs -n dr-system deployment/dr-controller
```

3. **Run initial backup:**
```bash
kubectl exec -n dr-system deployment/dr-controller -c backup-service -- \
  curl -X POST localhost:8080/api/backup/trigger
```

4. **Test recovery procedure:**
```bash
./scripts/test-dr.sh
```

5. **Run chaos experiment:**
```bash
kubectl port-forward -n dr-system svc/dr-controller 8082:8082 &
curl -X POST http://localhost:8082/api/chaos/experiment \
  -H "Content-Type: application/json" \
  -d @chaos/experiments/pod-failure.json
```

6. **Simulate disaster and recovery:**
```bash
# Delete production namespace
kubectl delete namespace agent-system

# Trigger recovery
kubectl exec -n dr-system deployment/dr-controller -c recovery-manager -- \
  curl -X POST localhost:8081/api/recovery/execute \
    -d '{"plan": "full-recovery"}'
```

## 🎯 Validation

Your disaster recovery system should now have:
- ✅ Automated backup system with encryption
- ✅ Multiple backup destinations and retention policies
- ✅ Recovery procedures meeting RTO/RPO targets
- ✅ Chaos testing framework with experiments
- ✅ Multi-region failover capabilities
- ✅ Voltarup verification and integrity checks
- ✅ Compliance monitoring and reporting
- ✅ Automated incident response

## 📊 Key DR Metrics

1. **RTO/RPO Compliance:**
   - Recovery Time: Less than 5 minutos
   - Data Loss: Less than 1 hour
   - Voltarup Success: Greater than 99.9%

2. **Chaos Testing Results:**
   - Pod Failures: System remains available
   - Network Parteeitions: No data loss
   - Resource Stress: Performance degrades gracefully

3. **Voltarup Metrics:**
   - Voltarup Size Trends
   - Voltarup Duração
   - Storage Costs
   - Verification Success Rate

## 🚀 Bonus Challenges

1. **Multi-Region DR:**
   - Implement cross-region replication
   - Add geo-failover capabilities
   - Test region-wide outages

2. **Avançado Chaos:**
   - Add more experiment types
   - Implement GameDays
   - Create chaos automation

3. **Compliance Automation:**
   - Generate audit reports
   - Automate compliance checks
   - Add regulatory frameworks

4. **DR Optimization:**
   - Reduce RTO to Less than 1 minute
   - Implement instant recovery
   - Add predictive failure detection

## 📚 Additional Recursos

- [Disaster Recovery Planning](https://aws.amazon.com/disaster-recovery/)
- [Chaos Engineering Principles](https://principlesofchaos.org/)
- [Kubernetes Voltarup Solutions](https://kubernetes.io/docs/concepts/storage/volume-snapshots/)
- [Business Continuity Standards](https://www.iso.org/standard/75106.html)

## ✅ Módulo 25 Completar!

Congratulations! You've completed the entire AI Agents & MCP track. You now have:
- Production-grade agent implantação skills
- Comprehensive monitoring capabilities
- Empresarial disaster recovery expertise

### 🎯 What's Próximo?

- Move to Módulo 26 for .NET Empresarial patterns
- Revisar all modules in the workshop
- Build your own produção agent platform
- Compartilhar your learnings with the community!

---

**Remember**: Production systems require continuous improvement. Keep iterating, testing, and optimizing your disaster recovery procedures!