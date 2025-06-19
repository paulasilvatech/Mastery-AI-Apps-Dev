# Production Agent Deployment Troubleshooting Guide

## 🔍 Overview

This guide helps diagnose and resolve common issues encountered when deploying AI agents to production. Each issue includes symptoms, root causes, diagnostic steps, and solutions.

## 📋 Quick Diagnostics

### Health Check Script
```bash
#!/bin/bash
# Quick health check for production agents

echo "🔍 Running Production Agent Health Check..."

# Check Kubernetes cluster
echo -e "\n☸️  Kubernetes Status:"
kubectl cluster-info
kubectl get nodes

# Check agent namespace
echo -e "\n📦 Agent Deployment:"
kubectl get all -n agent-system

# Check pod status
echo -e "\n🏃 Pod Health:"
kubectl get pods -n agent-system -o wide
kubectl top pods -n agent-system

# Check recent events
echo -e "\n📅 Recent Events:"
kubectl get events -n agent-system --sort-by='.lastTimestamp' | tail -10

# Check monitoring
echo -e "\n📊 Monitoring Status:"
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana
```

## 🚨 Common Issues and Solutions

### 1. Pods Not Starting

#### Symptoms
- Pods stuck in `Pending`, `CrashLoopBackOff`, or `ImagePullBackOff` state
- Deployment not reaching ready state

#### Diagnostic Commands
```bash
# Check pod status
kubectl describe pod <pod-name> -n agent-system

# Check pod logs
kubectl logs <pod-name> -n agent-system --previous

# Check events
kubectl get events -n agent-system --field-selector involvedObject.name=<pod-name>
```

#### Common Causes and Solutions

**A. Image Pull Issues**
```bash
# Check if image exists
docker pull <image-name>

# Check image pull secrets
kubectl get secret -n agent-system
kubectl describe secret <secret-name> -n agent-system

# Fix: Create/update image pull secret
kubectl create secret docker-registry regcred \
  --docker-server=<registry-url> \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email> \
  -n agent-system
```

**B. Resource Constraints**
```bash
# Check node resources
kubectl top nodes
kubectl describe nodes | grep -A 5 "Allocated resources"

# Fix: Adjust resource requests
kubectl patch deployment ai-agent -n agent-system --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/memory", "value":"128Mi"}]'
```

**C. Security Context Issues**
```yaml
# Fix: Update security context
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 1001
  capabilities:
    drop:
    - ALL
```

### 2. High Memory/CPU Usage

#### Symptoms
- Pods being OOMKilled
- High CPU throttling
- Slow response times

#### Diagnostic Steps
```bash
# Check resource usage
kubectl top pods -n agent-system --containers

# Check for OOM events
kubectl get events -n agent-system | grep OOMKilled

# Analyze memory dumps
kubectl exec <pod-name> -n agent-system -- jmap -histo <pid>
```

#### Solutions

**A. Memory Leaks**
```typescript
// Fix: Implement proper cleanup
class AgentService {
  private cleanupTasks: Array<() => void> = [];

  async processTask(data: any) {
    const resources = await this.allocateResources();
    
    // Register cleanup
    this.cleanupTasks.push(() => resources.release());
    
    try {
      return await this.process(data, resources);
    } finally {
      // Always cleanup
      this.cleanup();
    }
  }

  private cleanup() {
    this.cleanupTasks.forEach(task => {
      try {
        task();
      } catch (error) {
        logger.error('Cleanup failed', error);
      }
    });
    this.cleanupTasks = [];
  }
}
```

**B. Optimize Resource Limits**
```yaml
# Use Vertical Pod Autoscaler recommendations
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
```

### 3. Network Connectivity Issues

#### Symptoms
- Services unable to communicate
- DNS resolution failures
- Timeouts between services

#### Diagnostic Commands
```bash
# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup ai-agent-service.agent-system.svc.cluster.local

# Test connectivity
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- curl http://ai-agent-service.agent-system/health

# Check network policies
kubectl get networkpolicies -n agent-system
kubectl describe networkpolicy <policy-name> -n agent-system
```

#### Solutions

**A. DNS Issues**
```bash
# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns

# Restart CoreDNS if needed
kubectl rollout restart deployment coredns -n kube-system
```

**B. Network Policy Fixes**
```yaml
# Fix: Allow DNS and required traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: agent-netpol-fixed
spec:
  podSelector:
    matchLabels:
      app: ai-agent
  policyTypes:
  - Ingress
  - Egress
  egress:
  # Allow DNS
  - to:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
  # Allow internal services
  - to:
    - namespaceSelector:
        matchLabels:
          name: agent-system
```

### 4. Storage Issues

#### Symptoms
- PersistentVolume claims pending
- Disk full errors
- Slow I/O performance

#### Diagnostic Steps
```bash
# Check PVC status
kubectl get pvc -n agent-system
kubectl describe pvc <pvc-name> -n agent-system

# Check storage class
kubectl get storageclass
kubectl describe storageclass <storage-class-name>

# Check disk usage in pods
kubectl exec <pod-name> -n agent-system -- df -h
```

#### Solutions

**A. PVC Not Binding**
```yaml
# Fix: Ensure storage class exists
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/azure-disk
parameters:
  storageaccounttype: Premium_LRS
  kind: Managed
```

**B. Disk Space Management**
```typescript
// Implement log rotation
const winston = require('winston');
require('winston-daily-rotate-file');

const transport = new winston.transports.DailyRotateFile({
  filename: 'application-%DATE%.log',
  datePattern: 'YYYY-MM-DD',
  zippedArchive: true,
  maxSize: '20m',
  maxFiles: '14d',
  dirname: '/var/log/agent'
});
```

### 5. Authentication/Authorization Failures

#### Symptoms
- 401/403 errors
- RBAC denials in logs
- Service account issues

#### Diagnostic Commands
```bash
# Check service account
kubectl get sa -n agent-system
kubectl describe sa ai-agent -n agent-system

# Check RBAC
kubectl auth can-i --list --as=system:serviceaccount:agent-system:ai-agent

# Test permissions
kubectl auth can-i get pods --as=system:serviceaccount:agent-system:ai-agent -n agent-system
```

#### Solutions

**A. Fix RBAC Permissions**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: agent-role-fixed
  namespace: agent-system
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch", "create", "update"]
```

**B. Token Mounting Issues**
```yaml
# Ensure token is mounted
spec:
  serviceAccountName: ai-agent
  automountServiceAccountToken: true
  containers:
  - name: agent
    volumeMounts:
    - name: token
      mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      readOnly: true
```

### 6. Monitoring/Metrics Issues

#### Symptoms
- No metrics in Prometheus
- Grafana dashboards showing "No Data"
- Missing traces in Jaeger

#### Diagnostic Steps
```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit http://localhost:9090/targets

# Check metrics endpoint
kubectl exec <pod-name> -n agent-system -- curl localhost:9090/metrics

# Check annotations
kubectl get pod <pod-name> -n agent-system -o yaml | grep -A 5 annotations
```

#### Solutions

**A. Fix Prometheus Scraping**
```yaml
# Ensure correct annotations
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
    prometheus.io/path: "/metrics"
```

**B. Fix Metrics Export**
```typescript
// Ensure metrics are properly exposed
import { register } from 'prom-client';
import express from 'express';

const app = express();

app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    const metrics = await register.metrics();
    res.end(metrics);
  } catch (error) {
    res.status(500).end(error);
  }
});
```

### 7. Deployment Rollout Issues

#### Symptoms
- Deployment stuck in progress
- Old pods not terminating
- New version not becoming ready

#### Diagnostic Commands
```bash
# Check rollout status
kubectl rollout status deployment/ai-agent -n agent-system

# Check rollout history
kubectl rollout history deployment/ai-agent -n agent-system

# Check replica sets
kubectl get rs -n agent-system
```

#### Solutions

**A. Fix Stuck Rollout**
```bash
# Pause and resume rollout
kubectl rollout pause deployment/ai-agent -n agent-system
kubectl rollout resume deployment/ai-agent -n agent-system

# If still stuck, scale down and up
kubectl scale deployment ai-agent -n agent-system --replicas=0
kubectl scale deployment ai-agent -n agent-system --replicas=3
```

**B. Fix Readiness Issues**
```yaml
# Adjust readiness probe
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 30  # Increase if app needs more startup time
  periodSeconds: 10
  timeoutSeconds: 5
  successThreshold: 1
  failureThreshold: 3
```

### 8. Backup/Recovery Failures

#### Symptoms
- Backup jobs failing
- Recovery taking too long
- Data corruption after restore

#### Diagnostic Steps
```bash
# Check backup jobs
kubectl get jobs -n dr-system
kubectl describe job <backup-job> -n dr-system

# Check backup storage
aws s3 ls s3://backup-bucket/backups/ --recursive

# Verify backup integrity
kubectl exec -n dr-system deployment/dr-controller -c backup-service -- \
  ./verify-backup.sh <backup-id>
```

#### Solutions

**A. Fix Backup Permissions**
```yaml
# Ensure proper S3 permissions
apiVersion: v1
kind: Secret
metadata:
  name: backup-credentials
data:
  AWS_ACCESS_KEY_ID: <base64-encoded>
  AWS_SECRET_ACCESS_KEY: <base64-encoded>
---
# IAM Policy
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::backup-bucket/*",
        "arn:aws:s3:::backup-bucket"
      ]
    }
  ]
}
```

**B. Optimize Recovery Time**
```typescript
// Parallel recovery operations
async function parallelRestore(backupId: string) {
  const tasks = [
    restoreDatabase(backupId),
    restoreVolumes(backupId),
    restoreConfigs(backupId)
  ];

  // Run in parallel where possible
  const results = await Promise.allSettled(tasks);
  
  // Check results
  const failures = results.filter(r => r.status === 'rejected');
  if (failures.length > 0) {
    throw new Error(`Recovery failed: ${failures}`);
  }
}
```

## 🛠️ Advanced Troubleshooting

### Performance Profiling

```bash
# CPU profiling
kubectl exec <pod-name> -n agent-system -- \
  curl -X GET http://localhost:6060/debug/pprof/profile?seconds=30 > cpu.prof

# Memory profiling
kubectl exec <pod-name> -n agent-system -- \
  curl -X GET http://localhost:6060/debug/pprof/heap > heap.prof

# Analyze with pprof
go tool pprof -http=:8080 cpu.prof
```

### Distributed Tracing Analysis

```typescript
// Add trace context to logs
import { trace } from '@opentelemetry/api';

function logWithTrace(level: string, message: string, meta?: any) {
  const span = trace.getActiveSpan();
  const traceId = span?.spanContext().traceId;
  
  logger.log(level, message, {
    ...meta,
    traceId,
    timestamp: new Date().toISOString()
  });
}

// Use in error handling
catch (error) {
  logWithTrace('error', 'Operation failed', {
    error: error.message,
    stack: error.stack,
    operation: 'processAgentTask'
  });
}
```

### Chaos Testing Validation

```bash
# Run chaos experiment
kubectl apply -f - <<EOF
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: pod-failure-test
  namespace: agent-system
spec:
  action: pod-failure
  mode: random-max-percent
  value: "30"
  duration: "5m"
  selector:
    namespaces:
      - agent-system
    labelSelectors:
      app: ai-agent
EOF

# Monitor during chaos
watch kubectl get pods -n agent-system
```

## 📊 Monitoring Queries

### Prometheus Queries for Troubleshooting

```promql
# High error rate
rate(http_requests_total{status=~"5.."}[5m]) > 0.05

# Memory usage trending up
predict_linear(container_memory_usage_bytes[1h], 3600) > 2e9

# Pod restart frequency
increase(kube_pod_container_status_restarts_total[1h]) > 3

# Request latency percentiles
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))

# Service availability
(1 - (sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])))) < 0.999
```

## 🔧 Recovery Procedures

### Emergency Rollback

```bash
#!/bin/bash
# Emergency rollback procedure

# 1. Stop current deployment
kubectl scale deployment ai-agent -n agent-system --replicas=0

# 2. Rollback to previous version
kubectl rollout undo deployment/ai-agent -n agent-system

# 3. Scale back up
kubectl scale deployment ai-agent -n agent-system --replicas=3

# 4. Verify health
kubectl rollout status deployment/ai-agent -n agent-system
kubectl get pods -n agent-system
```

### Data Recovery

```bash
#!/bin/bash
# Data recovery procedure

# 1. Identify latest valid backup
BACKUP_ID=$(aws s3 ls s3://backup-bucket/backups/ | grep "daily-full" | tail -1 | awk '{print $4}')

# 2. Trigger recovery
kubectl exec -n dr-system deployment/dr-controller -c recovery-manager -- \
  curl -X POST localhost:8081/api/recovery/execute \
    -H "Content-Type: application/json" \
    -d "{\"backupId\": \"$BACKUP_ID\", \"plan\": \"full-recovery\"}"

# 3. Monitor recovery
kubectl logs -n dr-system deployment/dr-controller -c recovery-manager -f
```

## 📱 On-Call Runbooks

### High Severity Incident Response

1. **Assess Impact**
   ```bash
   ./scripts/assess-impact.sh
   ```

2. **Notify Stakeholders**
   ```bash
   ./scripts/notify-incident.sh --severity=high
   ```

3. **Implement Mitigation**
   - Scale up healthy instances
   - Redirect traffic if needed
   - Enable circuit breakers

4. **Root Cause Analysis**
   - Collect logs and metrics
   - Create timeline
   - Document findings

### Escalation Matrix

| Issue Type | L1 Response Time | L2 Escalation | L3 Escalation |
|------------|------------------|---------------|---------------|
| Service Down | 5 minutes | 15 minutes | 30 minutes |
| High Error Rate | 15 minutes | 30 minutes | 1 hour |
| Performance Degradation | 30 minutes | 1 hour | 2 hours |
| Security Incident | Immediate | 5 minutes | 15 minutes |

## 🏃 Quick Fixes

### Restart Unhealthy Pods
```bash
kubectl delete pod -n agent-system -l app=ai-agent --field-selector status.phase!=Running
```

### Clear Cache
```bash
kubectl exec -n agent-system deployment/ai-agent -- redis-cli FLUSHALL
```

### Force Refresh Configuration
```bash
kubectl rollout restart deployment/ai-agent -n agent-system
```

### Emergency Scale
```bash
kubectl scale deployment ai-agent -n agent-system --replicas=10
```

## 📚 Additional Resources

- [Kubernetes Troubleshooting Guide](https://kubernetes.io/docs/tasks/debug/)
- [Prometheus Alerting Best Practices](https://prometheus.io/docs/practices/alerting/)
- [SRE Incident Response](https://sre.google/sre-book/managing-incidents/)
- [Distributed Systems Debugging](https://www.distributedsystemscourse.com/)

---

**Remember**: When troubleshooting production issues, always:
1. Communicate status to stakeholders
2. Document actions taken
3. Preserve evidence for RCA
4. Follow change management procedures
5. Test fixes in staging first when possible