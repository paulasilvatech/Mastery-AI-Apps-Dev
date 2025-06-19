# Production Agent Deployment Best Practices

## 🎯 Overview

This guide provides comprehensive best practices for deploying AI agents in production environments. These practices are derived from real-world deployments and industry standards.

## 📋 Table of Contents

1. [Infrastructure Best Practices](#infrastructure-best-practices)
2. [Security Best Practices](#security-best-practices)
3. [Reliability & Availability](#reliability--availability)
4. [Performance Optimization](#performance-optimization)
5. [Monitoring & Observability](#monitoring--observability)
6. [Disaster Recovery](#disaster-recovery)
7. [Cost Optimization](#cost-optimization)
8. [Compliance & Governance](#compliance--governance)

## 🏗️ Infrastructure Best Practices

### Container Design

#### 1. **Use Multi-Stage Builds**
```dockerfile
# ✅ Good: Multi-stage build reduces image size
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

FROM node:20-alpine
RUN apk add --no-cache tini
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
USER node
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "dist/index.js"]
```

#### 2. **Run as Non-Root User**
```dockerfile
# ✅ Always create and use a non-root user
RUN addgroup -g 1001 -S agent && \
    adduser -S agent -u 1001
USER agent
```

#### 3. **Implement Health Checks**
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=45s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1
```

### Kubernetes Patterns

#### 1. **Resource Management**
```yaml
# ✅ Always set resource requests and limits
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

#### 2. **Pod Disruption Budgets**
```yaml
# ✅ Ensure availability during updates
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: agent-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: ai-agent
```

#### 3. **Anti-Affinity Rules**
```yaml
# ✅ Spread pods across nodes
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - ai-agent
        topologyKey: kubernetes.io/hostname
```

## 🔒 Security Best Practices

### 1. **Zero Trust Architecture**

```yaml
# Network Policies
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: agent-netpol
spec:
  podSelector:
    matchLabels:
      app: ai-agent
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
```

### 2. **Secrets Management**

```typescript
// ✅ Use external secret management
import { SecretManagerServiceClient } from '@google-cloud/secret-manager';

class SecretManager {
  private client: SecretManagerServiceClient;
  private cache: Map<string, { value: string; expiry: number }> = new Map();

  async getSecret(name: string): Promise<string> {
    // Check cache first
    const cached = this.cache.get(name);
    if (cached && cached.expiry > Date.now()) {
      return cached.value;
    }

    // Fetch from secret manager
    const [version] = await this.client.accessSecretVersion({
      name: `projects/${PROJECT_ID}/secrets/${name}/versions/latest`,
    });

    const secret = version.payload?.data?.toString() || '';
    
    // Cache for 5 minutes
    this.cache.set(name, {
      value: secret,
      expiry: Date.now() + 300000
    });

    return secret;
  }
}
```

### 3. **RBAC Configuration**

```yaml
# ✅ Principle of least privilege
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: agent-role
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
  resourceNames: ["agent-secrets"]  # Limit to specific secrets
```

### 4. **Container Security**

```yaml
# ✅ Security context best practices
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 1001
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
    - ALL
  seccompProfile:
    type: RuntimeDefault
```

## 🔄 Reliability & Availability

### 1. **Graceful Shutdown**

```typescript
// ✅ Implement proper shutdown handling
class GracefulShutdown {
  private shutdownHandlers: Array<() => Promise<void>> = [];
  private isShuttingDown = false;

  register(handler: () => Promise<void>) {
    this.shutdownHandlers.push(handler);
  }

  async shutdown() {
    if (this.isShuttingDown) return;
    this.isShuttingDown = true;

    logger.info('Starting graceful shutdown');

    // Stop accepting new requests
    server.close();

    // Wait for ongoing requests to complete
    await this.drainConnections();

    // Execute shutdown handlers
    await Promise.all(
      this.shutdownHandlers.map(handler => 
        handler().catch(err => logger.error('Shutdown handler error', err))
      )
    );

    logger.info('Graceful shutdown complete');
    process.exit(0);
  }

  private async drainConnections() {
    const timeout = 30000; // 30 seconds
    const start = Date.now();

    while (this.activeConnections > 0) {
      if (Date.now() - start > timeout) {
        logger.warn('Shutdown timeout, forcing exit');
        break;
      }
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
  }
}

// Register handlers
process.on('SIGTERM', () => gracefulShutdown.shutdown());
process.on('SIGINT', () => gracefulShutdown.shutdown());
```

### 2. **Circuit Breaker Pattern**

```typescript
// ✅ Prevent cascading failures
class CircuitBreaker {
  private failures = 0;
  private lastFailureTime = 0;
  private state: 'CLOSED' | 'OPEN' | 'HALF_OPEN' = 'CLOSED';

  constructor(
    private threshold: number = 5,
    private timeout: number = 60000,
    private resetTimeout: number = 30000
  ) {}

  async execute<T>(operation: () => Promise<T>): Promise<T> {
    if (this.state === 'OPEN') {
      if (Date.now() - this.lastFailureTime > this.resetTimeout) {
        this.state = 'HALF_OPEN';
      } else {
        throw new Error('Circuit breaker is OPEN');
      }
    }

    try {
      const result = await operation();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private onSuccess() {
    if (this.state === 'HALF_OPEN') {
      this.state = 'CLOSED';
    }
    this.failures = 0;
  }

  private onFailure() {
    this.failures++;
    this.lastFailureTime = Date.now();

    if (this.failures >= this.threshold) {
      this.state = 'OPEN';
      logger.warn('Circuit breaker opened');
    }
  }
}
```

### 3. **Retry Logic**

```typescript
// ✅ Implement exponential backoff
async function retryWithBackoff<T>(
  operation: () => Promise<T>,
  options: {
    maxRetries?: number;
    initialDelay?: number;
    maxDelay?: number;
    factor?: number;
  } = {}
): Promise<T> {
  const {
    maxRetries = 3,
    initialDelay = 1000,
    maxDelay = 30000,
    factor = 2
  } = options;

  let lastError: Error;
  let delay = initialDelay;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error: any) {
      lastError = error;
      
      if (attempt === maxRetries) {
        throw error;
      }

      // Add jitter to prevent thundering herd
      const jitter = Math.random() * 0.3 * delay;
      const totalDelay = Math.min(delay + jitter, maxDelay);

      logger.warn(`Retry attempt ${attempt + 1} after ${totalDelay}ms`, {
        error: error.message
      });

      await new Promise(resolve => setTimeout(resolve, totalDelay));
      delay *= factor;
    }
  }

  throw lastError!;
}
```

## 🚀 Performance Optimization

### 1. **Connection Pooling**

```typescript
// ✅ Reuse connections efficiently
import { Pool } from 'pg';
import Redis from 'ioredis';

// Database connection pool
const dbPool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 20,                    // Maximum pool size
  idleTimeoutMillis: 30000,   // Close idle clients after 30s
  connectionTimeoutMillis: 2000, // Timeout for new connections
});

// Redis connection with clustering
const redis = new Redis.Cluster([
  { host: 'redis-1', port: 6379 },
  { host: 'redis-2', port: 6379 },
  { host: 'redis-3', port: 6379 }
], {
  redisOptions: {
    password: process.env.REDIS_PASSWORD,
    enableReadyCheck: true,
    maxRetriesPerRequest: 3,
  },
  clusterRetryStrategy: (times) => {
    const delay = Math.min(times * 100, 2000);
    return delay;
  }
});
```

### 2. **Caching Strategy**

```typescript
// ✅ Multi-level caching
class CacheManager {
  private memoryCache: Map<string, CacheEntry> = new Map();
  private readonly maxMemoryItems = 1000;

  constructor(
    private redis: Redis.Cluster,
    private defaultTTL: number = 300
  ) {
    // Periodic cleanup
    setInterval(() => this.cleanupMemoryCache(), 60000);
  }

  async get<T>(key: string): Promise<T | null> {
    // L1: Memory cache
    const memoryResult = this.getFromMemory(key);
    if (memoryResult !== null) {
      return memoryResult;
    }

    // L2: Redis cache
    const redisResult = await this.redis.get(key);
    if (redisResult) {
      const value = JSON.parse(redisResult);
      this.setInMemory(key, value, this.defaultTTL);
      return value;
    }

    return null;
  }

  async set<T>(key: string, value: T, ttl?: number): Promise<void> {
    const ttlSeconds = ttl || this.defaultTTL;
    
    // Set in both caches
    this.setInMemory(key, value, ttlSeconds);
    await this.redis.setex(key, ttlSeconds, JSON.stringify(value));
  }

  private getFromMemory(key: string): any | null {
    const entry = this.memoryCache.get(key);
    if (entry && entry.expiry > Date.now()) {
      return entry.value;
    }
    return null;
  }

  private setInMemory(key: string, value: any, ttl: number): void {
    // Implement LRU eviction if needed
    if (this.memoryCache.size >= this.maxMemoryItems) {
      const firstKey = this.memoryCache.keys().next().value;
      this.memoryCache.delete(firstKey);
    }

    this.memoryCache.set(key, {
      value,
      expiry: Date.now() + (ttl * 1000)
    });
  }

  private cleanupMemoryCache(): void {
    const now = Date.now();
    for (const [key, entry] of this.memoryCache.entries()) {
      if (entry.expiry <= now) {
        this.memoryCache.delete(key);
      }
    }
  }
}
```

### 3. **Request Batching**

```typescript
// ✅ Batch requests to reduce overhead
class BatchProcessor<T, R> {
  private batch: Array<{ item: T; resolve: (value: R) => void; reject: (error: any) => void }> = [];
  private timer: NodeJS.Timeout | null = null;

  constructor(
    private processBatch: (items: T[]) => Promise<R[]>,
    private maxBatchSize: number = 100,
    private maxWaitTime: number = 50
  ) {}

  async process(item: T): Promise<R> {
    return new Promise((resolve, reject) => {
      this.batch.push({ item, resolve, reject });

      if (this.batch.length >= this.maxBatchSize) {
        this.flush();
      } else if (!this.timer) {
        this.timer = setTimeout(() => this.flush(), this.maxWaitTime);
      }
    });
  }

  private async flush(): Promise<void> {
    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = null;
    }

    if (this.batch.length === 0) return;

    const currentBatch = this.batch;
    this.batch = [];

    try {
      const items = currentBatch.map(b => b.item);
      const results = await this.processBatch(items);

      currentBatch.forEach((b, index) => {
        b.resolve(results[index]);
      });
    } catch (error) {
      currentBatch.forEach(b => b.reject(error));
    }
  }
}
```

## 📊 Monitoring & Observability

### 1. **Structured Logging**

```typescript
// ✅ Use structured logging with context
import winston from 'winston';
import { trace } from '@opentelemetry/api';

const logger = winston.createLogger({
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json(),
    winston.format.printf(info => {
      // Add trace context
      const span = trace.getActiveSpan();
      if (span) {
        const spanContext = span.spanContext();
        info.traceId = spanContext.traceId;
        info.spanId = spanContext.spanId;
      }
      return JSON.stringify(info);
    })
  ),
  defaultMeta: {
    service: 'ai-agent',
    version: process.env.APP_VERSION,
    environment: process.env.NODE_ENV
  },
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ 
      filename: 'error.log', 
      level: 'error' 
    })
  ]
});

// Log with context
export function logWithContext(level: string, message: string, meta?: any) {
  const context = {
    timestamp: new Date().toISOString(),
    ...meta
  };
  
  logger.log(level, message, context);
}
```

### 2. **Metrics Collection**

```typescript
// ✅ Comprehensive metrics
import { register, Counter, Histogram, Gauge, Summary } from 'prom-client';

// Business metrics
const requestsTotal = new Counter({
  name: 'agent_requests_total',
  help: 'Total number of requests',
  labelNames: ['method', 'status', 'endpoint']
});

const requestDuration = new Histogram({
  name: 'agent_request_duration_seconds',
  help: 'Request duration in seconds',
  labelNames: ['method', 'endpoint', 'status'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10]
});

// SLI metrics
const availability = new Gauge({
  name: 'agent_availability',
  help: 'Service availability (0-1)',
  labelNames: ['service']
});

// Track SLIs
export class SLITracker {
  private successCount = 0;
  private totalCount = 0;
  private window = 300000; // 5 minutes

  constructor() {
    setInterval(() => this.reset(), this.window);
  }

  recordRequest(success: boolean) {
    this.totalCount++;
    if (success) this.successCount++;
    
    const availability = this.totalCount > 0 
      ? this.successCount / this.totalCount 
      : 1;
    
    availability.set({ service: 'ai-agent' }, availability);
  }

  private reset() {
    this.successCount = 0;
    this.totalCount = 0;
  }
}
```

### 3. **Distributed Tracing**

```typescript
// ✅ Implement comprehensive tracing
import { trace, context, SpanKind, SpanStatusCode } from '@opentelemetry/api';

export function traceAsync<T>(
  name: string,
  fn: () => Promise<T>,
  attributes?: Record<string, any>
): Promise<T> {
  const tracer = trace.getTracer('ai-agent');
  
  return tracer.startActiveSpan(name, async (span) => {
    // Add attributes
    if (attributes) {
      span.setAttributes(attributes);
    }

    try {
      const result = await fn();
      span.setStatus({ code: SpanStatusCode.OK });
      return result;
    } catch (error: any) {
      span.recordException(error);
      span.setStatus({
        code: SpanStatusCode.ERROR,
        message: error.message
      });
      throw error;
    } finally {
      span.end();
    }
  });
}

// Usage
const result = await traceAsync(
  'process-agent-task',
  async () => {
    return await processTask(data);
  },
  { 
    'task.type': 'inference',
    'task.model': 'gpt-4' 
  }
);
```

## 💾 Disaster Recovery

### 1. **Backup Strategy**

```typescript
// ✅ Implement 3-2-1 backup rule
class BackupStrategy {
  // 3 copies of data
  // 2 different storage types
  // 1 offsite backup

  async performBackup(): Promise<void> {
    const backupId = `backup-${Date.now()}`;
    
    // Primary backup to S3
    await this.backupToS3(backupId);
    
    // Secondary backup to different region
    await this.backupToSecondaryRegion(backupId);
    
    // Tertiary backup to different cloud provider
    await this.backupToAlternativeCloud(backupId);
    
    // Verify all backups
    await this.verifyBackups(backupId);
    
    // Clean old backups based on retention
    await this.cleanOldBackups();
  }

  private async verifyBackups(backupId: string): Promise<void> {
    // Download partial data and verify checksums
    // Test restore process
    // Alert on verification failures
  }
}
```

### 2. **Recovery Testing**

```bash
#!/bin/bash
# ✅ Regular DR testing script

# Monthly full DR test
if [[ $(date +%d) == "01" ]]; then
  echo "Running monthly full DR test"
  ./scripts/dr-full-test.sh
fi

# Weekly backup verification
if [[ $(date +%u) == "7" ]]; then
  echo "Running weekly backup verification"
  ./scripts/verify-backups.sh
fi

# Daily incremental backup
echo "Running daily backup"
./scripts/daily-backup.sh
```

## 💰 Cost Optimization

### 1. **Resource Right-Sizing**

```yaml
# ✅ Use Vertical Pod Autoscaler
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: agent-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ai-agent
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: agent
      minAllowed:
        cpu: 50m
        memory: 128Mi
      maxAllowed:
        cpu: 2
        memory: 2Gi
```

### 2. **Spot/Preemptible Instances**

```yaml
# ✅ Use spot instances for non-critical workloads
apiVersion: v1
kind: Node
metadata:
  labels:
    node.kubernetes.io/lifecycle: spot
spec:
  taints:
  - key: kubernetes.io/lifecycle
    value: spot
    effect: NoSchedule
---
# Tolerate spot instances
tolerations:
- key: kubernetes.io/lifecycle
  operator: Equal
  value: spot
  effect: NoSchedule
```

### 3. **Cost Monitoring**

```typescript
// ✅ Track resource costs
class CostTracker {
  async calculateMonthlyCosts(): Promise<CostReport> {
    const costs = {
      compute: await this.getComputeCosts(),
      storage: await this.getStorageCosts(),
      network: await this.getNetworkCosts(),
      aiServices: await this.getAIServiceCosts()
    };

    const total = Object.values(costs).reduce((sum, cost) => sum + cost, 0);
    
    // Alert if costs exceed budget
    if (total > this.monthlyBudget) {
      await this.alertCostOverrun(total);
    }

    return {
      breakdown: costs,
      total,
      projectedMonthly: this.projectMonthlyCost(total),
      recommendations: await this.getCostOptimizationRecommendations()
    };
  }
}
```

## 📜 Compliance & Governance

### 1. **Audit Logging**

```typescript
// ✅ Comprehensive audit trail
interface AuditEvent {
  timestamp: Date;
  userId: string;
  action: string;
  resource: string;
  result: 'success' | 'failure';
  metadata?: Record<string, any>;
}

class AuditLogger {
  async log(event: AuditEvent): Promise<void> {
    // Sign event for tamper detection
    const signature = await this.signEvent(event);
    
    // Store in immutable storage
    await this.storeInBlockchain({
      ...event,
      signature
    });
    
    // Send to SIEM
    await this.sendToSIEM(event);
  }

  private async signEvent(event: AuditEvent): Promise<string> {
    // Use asymmetric cryptography for signing
    const hash = crypto
      .createHash('sha256')
      .update(JSON.stringify(event))
      .digest('hex');
    
    return crypto
      .sign('sha256', Buffer.from(hash), this.privateKey)
      .toString('base64');
  }
}
```

### 2. **Data Privacy**

```typescript
// ✅ Implement data privacy controls
class PrivacyManager {
  async processPersonalData(data: any): Promise<any> {
    // Anonymize PII
    const anonymized = await this.anonymize(data);
    
    // Encrypt sensitive fields
    const encrypted = await this.encryptSensitiveFields(anonymized);
    
    // Add retention metadata
    return {
      ...encrypted,
      _metadata: {
        retentionDate: this.calculateRetentionDate(),
        dataClassification: 'personal',
        consentId: data.consentId
      }
    };
  }

  private async anonymize(data: any): Promise<any> {
    // Implement k-anonymity
    // Remove direct identifiers
    // Generalize quasi-identifiers
    return data;
  }
}
```

## 🎯 Key Takeaways

1. **Security First**: Never compromise on security for convenience
2. **Automate Everything**: Manual processes don't scale
3. **Monitor Proactively**: Detect issues before users do
4. **Plan for Failure**: Everything fails, be prepared
5. **Optimize Continuously**: Performance and cost optimization is ongoing
6. **Document Thoroughly**: Future you will thank present you
7. **Test Regularly**: Especially disaster recovery procedures

## 📚 Additional Resources

- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [SRE Books by Google](https://sre.google/books/)
- [Cloud Native Security Whitepaper](https://www.cncf.io/cloud-native-security-whitepaper/)
- [The Twelve-Factor App](https://12factor.net/)

---

Remember: Best practices evolve. Stay current with industry standards and continuously improve your deployment practices.