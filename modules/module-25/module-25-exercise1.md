# Exercise 1: Production Agent Platform (⭐ Easy - 30 minutes)

## 🎯 Objective
Build a production-ready Kubernetes-based platform for deploying and managing AI agents at scale, including infrastructure setup, agent deployment, and basic operations.

## 🧠 What You'll Learn
- Kubernetes deployment patterns for agents
- Container orchestration best practices
- Service discovery and load balancing
- Health checks and readiness probes
- Resource management and scaling
- Basic security configurations

## 📋 Prerequisites
- Kubernetes cluster running (local or cloud)
- kubectl configured and working
- Docker installed
- Basic Kubernetes knowledge

## 📚 Background

A production agent platform provides the foundation for running AI agents reliably at scale. Key components include:

- **Container Orchestration**: Kubernetes manages agent lifecycle
- **Service Discovery**: Agents find each other dynamically
- **Load Balancing**: Distribute requests across agent instances
- **Health Management**: Automatic recovery from failures
- **Resource Control**: CPU and memory limits
- **Security**: Network policies and RBAC

## 🏗️ Architecture Overview

```mermaid
graph TB
    subgraph "Kubernetes Cluster"
        subgraph "Agent Namespace"
            A[Ingress Controller] --> B[Agent Service]
            B --> C[Agent Deployment]
            C --> D[Agent Pod 1]
            C --> E[Agent Pod 2]
            C --> F[Agent Pod N]
            
            G[ConfigMap] --> D
            G --> E
            G --> F
            
            H[Secret] --> D
            H --> E
            H --> F
            
            I[HPA] --> C
            J[PDB] --> C
        end
        
        subgraph "System Components"
            K[Metrics Server] --> I
            L[DNS] --> B
            M[RBAC] --> C
        end
    end
    
    N[External Traffic] --> A
    O[Monitoring] --> D
    O --> E
    O --> F
    
    style A fill:#4CAF50
    style B fill:#2196F3
    style O fill:#FF9800
```

## 🛠️ Step-by-Step Instructions

### Step 1: Create Agent Container

**Copilot Prompt Suggestion:**
```dockerfile
# Create a production-ready Dockerfile for an AI agent that:
# - Uses multi-stage build for smaller image size
# - Runs as non-root user for security
# - Includes health check endpoint
# - Handles graceful shutdown
# - Exposes metrics for monitoring
# - Follows container best practices
```

Create `agent/Dockerfile`:
```dockerfile
# Multi-stage build for production agent
FROM node:20-alpine AS builder

# Install build dependencies
RUN apk add --no-cache python3 make g++

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build application
RUN npm run build

# Production stage
FROM node:20-alpine

# Install production dependencies only
RUN apk add --no-cache tini curl

# Create non-root user
RUN addgroup -g 1001 -S agent && \
    adduser -S agent -u 1001

# Set working directory
WORKDIR /app

# Copy built application from builder
COPY --from=builder --chown=agent:agent /app/dist ./dist
COPY --from=builder --chown=agent:agent /app/node_modules ./node_modules
COPY --from=builder --chown=agent:agent /app/package*.json ./

# Expose ports
EXPOSE 8080 9090

# Use non-root user
USER agent

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=45s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Use tini for proper signal handling
ENTRYPOINT ["/sbin/tini", "--"]

# Start application
CMD ["node", "dist/index.js"]
```

Create `agent/src/index.ts`:
```typescript
import express from 'express';
import { createServer } from 'http';
import { register } from 'prom-client';
import helmet from 'helmet';
import winston from 'winston';

// Configure logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.json(),
  defaultMeta: { 
    service: 'ai-agent',
    version: process.env.APP_VERSION || '1.0.0',
    instance: process.env.HOSTNAME || 'unknown'
  },
  transports: [
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

// Create Express app
const app = express();
const server = createServer(app);

// Security middleware
app.use(helmet());
app.use(express.json({ limit: '10mb' }));

// Health check endpoint
app.get('/health', (req, res) => {
  const health = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    pid: process.pid
  };
  
  res.json(health);
});

// Readiness check
app.get('/ready', async (req, res) => {
  try {
    // Check dependencies (Redis, DB, etc.)
    const ready = await checkDependencies();
    
    if (ready) {
      res.json({ status: 'ready' });
    } else {
      res.status(503).json({ status: 'not ready' });
    }
  } catch (error) {
    res.status(503).json({ status: 'error', message: error.message });
  }
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  } catch (error) {
    res.status(500).end(error);
  }
});

// Agent API endpoint
app.post('/api/v1/process', async (req, res) => {
  const startTime = Date.now();
  
  try {
    logger.info('Processing request', { 
      requestId: req.headers['x-request-id'] 
    });
    
    // Simulate agent processing
    const result = await processAgentTask(req.body);
    
    const duration = Date.now() - startTime;
    logger.info('Request processed', { 
      requestId: req.headers['x-request-id'],
      duration 
    });
    
    res.json({ 
      success: true, 
      result,
      processingTime: duration 
    });
    
  } catch (error) {
    logger.error('Processing failed', { 
      error: error.message,
      requestId: req.headers['x-request-id'] 
    });
    
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// Graceful shutdown
const gracefulShutdown = () => {
  logger.info('Received shutdown signal');
  
  server.close(() => {
    logger.info('HTTP server closed');
    process.exit(0);
  });
  
  // Force shutdown after 30 seconds
  setTimeout(() => {
    logger.error('Forced shutdown');
    process.exit(1);
  }, 30000);
};

process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);

// Start server
const port = process.env.PORT || 8080;
server.listen(port, () => {
  logger.info(`Agent server listening on port ${port}`);
});

// Helper functions
async function checkDependencies(): Promise<boolean> {
  // Check external dependencies
  return true; // Simplified for demo
}

async function processAgentTask(data: any): Promise<any> {
  // Simulate agent processing
  await new Promise(resolve => setTimeout(resolve, 100));
  return {
    processed: true,
    timestamp: new Date().toISOString(),
    data
  };
}
```

### Step 2: Create Kubernetes Manifests

**Copilot Prompt Suggestion:**
```yaml
# Create production Kubernetes manifests that include:
# - Namespace with labels
# - ConfigMap for configuration
# - Secret for sensitive data
# - Deployment with best practices
# - Service for load balancing
# - HorizontalPodAutoscaler for scaling
# - PodDisruptionBudget for availability
# - NetworkPolicy for security
```

Create `kubernetes/base/namespace.yaml`:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: agent-system
  labels:
    name: agent-system
    environment: production
    team: ai-platform
    monitoring: enabled
```

Create `kubernetes/base/configmap.yaml`:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: agent-config
  namespace: agent-system
  labels:
    app: ai-agent
    component: config
data:
  # Application configuration
  LOG_LEVEL: "info"
  APP_VERSION: "1.0.0"
  
  # Server configuration
  PORT: "8080"
  METRICS_PORT: "9090"
  
  # Agent configuration
  MAX_CONCURRENT_TASKS: "10"
  TASK_TIMEOUT: "30000"
  
  # Feature flags
  ENABLE_TRACING: "true"
  ENABLE_METRICS: "true"
  
  # External services
  REDIS_HOST: "redis-service.agent-system.svc.cluster.local"
  REDIS_PORT: "6379"
```

Create `kubernetes/base/secret.yaml`:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: agent-secrets
  namespace: agent-system
  labels:
    app: ai-agent
    component: secrets
type: Opaque
stringData:
  # API Keys (use actual base64 encoded values in production)
  OPENAI_API_KEY: "your-openai-api-key"
  AZURE_API_KEY: "your-azure-api-key"
  
  # Database credentials
  DB_CONNECTION_STRING: "postgresql://user:pass@postgres:5432/agents"
  
  # Authentication
  JWT_SECRET: "your-jwt-secret-key"
  API_KEY: "your-internal-api-key"
```

Create `kubernetes/base/deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ai-agent
  namespace: agent-system
  labels:
    app: ai-agent
    version: v1
    component: backend
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: ai-agent
      version: v1
  template:
    metadata:
      labels:
        app: ai-agent
        version: v1
        component: backend
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9090"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: ai-agent
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001
      
      # Anti-affinity for high availability
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
      
      containers:
      - name: agent
        image: localhost:5000/ai-agent:latest
        imagePullPolicy: Always
        
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        - name: metrics
          containerPort: 9090
          protocol: TCP
        
        # Environment variables from ConfigMap
        envFrom:
        - configMapRef:
            name: agent-config
        - secretRef:
            name: agent-secrets
        
        # Resource limits
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        
        # Probes
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        
        # Lifecycle hooks
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15"]
        
        # Security context
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        
        # Volume mounts
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /app/.cache
      
      volumes:
      - name: tmp
        emptyDir: {}
      - name: cache
        emptyDir: {}
```

Create `kubernetes/base/service.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: ai-agent-service
  namespace: agent-system
  labels:
    app: ai-agent
    component: service
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
spec:
  type: ClusterIP
  ports:
  - name: http
    port: 80
    targetPort: http
    protocol: TCP
  - name: metrics
    port: 9090
    targetPort: metrics
    protocol: TCP
  selector:
    app: ai-agent
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
```

Create `kubernetes/base/hpa.yaml`:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ai-agent-hpa
  namespace: agent-system
  labels:
    app: ai-agent
    component: autoscaler
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ai-agent
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "100"
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
      - type: Pods
        value: 1
        periodSeconds: 60
      selectPolicy: Min
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
      - type: Pods
        value: 2
        periodSeconds: 60
      selectPolicy: Max
```

Create `kubernetes/base/pdb.yaml`:
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: ai-agent-pdb
  namespace: agent-system
  labels:
    app: ai-agent
    component: pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: ai-agent
  unhealthyPodEvictionPolicy: AlwaysAllow
```

Create `kubernetes/base/networkpolicy.yaml`:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ai-agent-netpol
  namespace: agent-system
  labels:
    app: ai-agent
    component: security
spec:
  podSelector:
    matchLabels:
      app: ai-agent
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    # Allow from ingress controller
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    # Allow from same namespace
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 8080
  - from:
    # Allow Prometheus scraping
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 9090
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
  # Allow external HTTPS
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 169.254.169.254/32  # Block metadata service
    ports:
    - protocol: TCP
      port: 443
  # Allow Redis
  - to:
    - podSelector:
        matchLabels:
          app: redis
    ports:
    - protocol: TCP
      port: 6379
```

Create `kubernetes/base/rbac.yaml`:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ai-agent
  namespace: agent-system
  labels:
    app: ai-agent
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ai-agent-role
  namespace: agent-system
  labels:
    app: ai-agent
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ai-agent-binding
  namespace: agent-system
  labels:
    app: ai-agent
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ai-agent-role
subjects:
- kind: ServiceAccount
  name: ai-agent
  namespace: agent-system
```

Create `kubernetes/base/ingress.yaml`:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ai-agent-ingress
  namespace: agent-system
  labels:
    app: ai-agent
    component: ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "60"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - api.agent-platform.example.com
    secretName: ai-agent-tls
  rules:
  - host: api.agent-platform.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ai-agent-service
            port:
              number: 80
```

### Step 3: Build and Deploy

Create deployment script `scripts/deploy.sh`:
```bash
#!/bin/bash
set -e

# Configuration
REGISTRY="${REGISTRY_URL:-localhost:5000}"
IMAGE_NAME="ai-agent"
IMAGE_TAG="${IMAGE_TAG:-latest}"
NAMESPACE="agent-system"

echo "🚀 Building and deploying AI Agent Platform"

# Build Docker image
echo "📦 Building Docker image..."
cd agent
docker build -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} .

# Push to registry
echo "⬆️ Pushing to registry..."
docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}

# Apply Kubernetes manifests
echo "☸️ Deploying to Kubernetes..."
cd ../kubernetes/base

# Create namespace if not exists
kubectl apply -f namespace.yaml

# Apply all manifests
kubectl apply -f .

# Wait for rollout
echo "⏳ Waiting for deployment..."
kubectl rollout status deployment/ai-agent -n ${NAMESPACE}

# Check pods
echo "✅ Deployment complete!"
kubectl get pods -n ${NAMESPACE}

# Show service endpoint
echo "🌐 Service endpoint:"
kubectl get svc ai-agent-service -n ${NAMESPACE}
```

### Step 4: Verify Deployment

Create verification script `scripts/verify.sh`:
```bash
#!/bin/bash

NAMESPACE="agent-system"

echo "🔍 Verifying AI Agent deployment..."

# Check pods
echo -e "\n📦 Pods:"
kubectl get pods -n ${NAMESPACE} -l app=ai-agent

# Check service
echo -e "\n🌐 Service:"
kubectl get svc ai-agent-service -n ${NAMESPACE}

# Check HPA
echo -e "\n📊 Autoscaler:"
kubectl get hpa ai-agent-hpa -n ${NAMESPACE}

# Check PDB
echo -e "\n🛡️ Pod Disruption Budget:"
kubectl get pdb ai-agent-pdb -n ${NAMESPACE}

# Test health endpoint
echo -e "\n❤️ Health check:"
POD=$(kubectl get pod -n ${NAMESPACE} -l app=ai-agent -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n ${NAMESPACE} ${POD} -- curl -s localhost:8080/health | jq .

# Test readiness
echo -e "\n✅ Readiness check:"
kubectl exec -n ${NAMESPACE} ${POD} -- curl -s localhost:8080/ready | jq .

# Check logs
echo -e "\n📜 Recent logs:"
kubectl logs -n ${NAMESPACE} ${POD} --tail=10
```

### Step 5: Test the Platform

Create test script `scripts/test-platform.sh`:
```bash
#!/bin/bash

NAMESPACE="agent-system"
SERVICE="ai-agent-service"

echo "🧪 Testing AI Agent Platform..."

# Port forward for testing
echo "Setting up port forward..."
kubectl port-forward -n ${NAMESPACE} svc/${SERVICE} 8080:80 &
PF_PID=$!

sleep 5

# Test health endpoint
echo -e "\n❤️ Testing health endpoint:"
curl -s http://localhost:8080/health | jq .

# Test readiness endpoint
echo -e "\n✅ Testing readiness endpoint:"
curl -s http://localhost:8080/ready | jq .

# Test API endpoint
echo -e "\n🔧 Testing API endpoint:"
curl -s -X POST http://localhost:8080/api/v1/process \
  -H "Content-Type: application/json" \
  -H "X-Request-ID: test-123" \
  -d '{"task": "test", "data": {"message": "Hello, Agent!"}}' | jq .

# Test metrics endpoint
echo -e "\n📊 Testing metrics endpoint:"
curl -s http://localhost:8080/metrics | grep -E "(http_|process_|nodejs_)"

# Cleanup
kill $PF_PID
```

## 🏃 Running the Exercise

1. **Build and deploy the platform:**
```bash
chmod +x scripts/*.sh
./scripts/deploy.sh
```

2. **Verify deployment:**
```bash
./scripts/verify.sh
```

3. **Test the platform:**
```bash
./scripts/test-platform.sh
```

4. **Scale the deployment:**
```bash
# Manual scaling
kubectl scale deployment ai-agent -n agent-system --replicas=5

# Watch HPA in action
kubectl get hpa ai-agent-hpa -n agent-system -w
```

5. **Simulate load (optional):**
```bash
# Use a load testing tool
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh

# Inside the pod:
while true; do
  wget -q -O- http://ai-agent-service.agent-system/api/v1/process
  sleep 0.1
done
```

## 🎯 Validation

Your production agent platform should now have:
- ✅ Multi-replica deployment with health checks
- ✅ Service discovery and load balancing
- ✅ Horizontal pod autoscaling
- ✅ Pod disruption budget for availability
- ✅ Network policies for security
- ✅ RBAC for least privilege
- ✅ Resource limits and monitoring
- ✅ Graceful shutdown handling

## 🚀 Bonus Challenges

1. **Add Persistent Storage:**
   - Create PersistentVolumeClaim
   - Mount for agent state
   - Implement state backup

2. **Implement Service Mesh:**
   - Install Istio/Linkerd
   - Add traffic management
   - Implement circuit breakers

3. **Add Custom Metrics:**
   - Expose business metrics
   - Create Prometheus rules
   - Build Grafana dashboard

4. **Multi-Region Deployment:**
   - Deploy to multiple regions
   - Implement traffic routing
   - Add disaster recovery

## 📚 Additional Resources

- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Container Security Guide](https://kubernetes.io/docs/concepts/security/)
- [Production Checklist](https://learnk8s.io/production-best-practices)

## ⏭️ Next Exercise

Ready to add comprehensive monitoring? Move on to [Exercise 2: Monitoring & Alerting System](../exercise2-monitoring-system/) where you'll implement full observability!