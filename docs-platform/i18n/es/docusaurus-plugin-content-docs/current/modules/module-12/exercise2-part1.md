---
sidebar_position: 3
title: "Exercise 2: Part 1"
description: "## Overview"
---

# Ejercicio 2: Deploy to Kubernetes with AKS ⭐⭐

## Resumen

In this intermediate exercise, you'll deploy your containerized microservice to Azure Kubernetes Service (AKS), implementing producción-grade features including auto-scaling, rolling updates, and comprehensive monitoring. You'll leverage GitHub Copilot to generate Kubernetes manifests and implement cloud-native patterns.

**Duración**: 45-60 minutos  
**Difficulty**: Medio (⭐⭐)  
**Success Rate**: 80%

## 🎯 Objetivos de Aprendizaje

Al completar este ejercicio, usted:

1. Create and configure an AKS cluster using Azure CLI
2. Generate Kubernetes manifests with Copilot assistance
3. Implement horizontal pod autoscaling (HPA)
4. Configure rolling updates with zero downtime
5. Set up service mesh for advanced traffic management
6. Implement comprehensive monitoring with Prometheus

## 📋 Prerrequisitos

- Completard Ejercicio 1 (containerized microservice)
- Azure CLI logged in with active suscripción
- kubectl configurado
- Helm 3 instalado
- Docker image pushed to registry

## 🏗️ Architecture

```mermaid
graph TB
    subgraph "Azure Kubernetes Service"
        subgraph "Ingress"
            IG[Nginx Ingress Controller]
        end
        
        subgraph "Application Layer"
            D1[Product Service Pod 1]
            D2[Product Service Pod 2]
            D3[Product Service Pod 3]
            SVC[ClusterIP Service]
        end
        
        subgraph "Data Layer"
            PG[PostgreSQL StatefulSet]
            RD[Redis StatefulSet]
        end
        
        subgraph "Monitoring"
            PROM[Prometheus]
            GRAF[Grafana]
        end
    end
    
    subgraph "Azure Services"
        ACR[Azure Container Registry]
        AKV[Azure Key Vault]
        AM[Azure Monitor]
    end
    
    IG --&gt; SVC
    SVC --&gt; D1
    SVC --&gt; D2
    SVC --&gt; D3
    D1 --&gt; PG
    D1 --&gt; RD
    D2 --&gt; PG
    D2 --&gt; RD
    D3 --&gt; PG
    D3 --&gt; RD
    
    PROM --&gt; D1
    PROM --&gt; D2
    PROM --&gt; D3
    
    style IG fill:#ff9,stroke:#333,stroke-width:2px
    style SVC fill:#9ff,stroke:#333,stroke-width:2px
    style PROM fill:#f9f,stroke:#333,stroke-width:2px
```

## 📝 Scenario

Your product catalog service has been successful in desarrollo. Now you need to:
- Deploy to producción on AKS
- Handle 10,000+ requests per minute
- Ensure 99.9% uptime with zero-downtime despliegues
- Auto-scale based on CPU and memory usage
- Implement comprehensive monitoring
- Secure secrets and configurations

## 🚀 Partee 1: AKS Cluster Setup

### Step 1: Create AKS Cluster

**Copilot Prompt Suggestion:**
```bash
# Create a script that provisions an AKS cluster with:
# - 3 nodes with Standard_DS2_v2 size
# - Azure CNI networking
# - Managed identity enabled
# - Azure Monitor and Container Insights
# - Network policy support
# - Availability zones enabled
# File: scripts/create-aks-cluster.sh
```

**Expected Output:**
```bash
#!/bin/bash
set -euo pipefail

# Configuration
RESOURCE_GROUP="rg-workshop-module12"
CLUSTER_NAME="aks-workshop-module12"
LOCATION="eastus2"
NODE_COUNT=3
NODE_SIZE="Standard_DS2_v2"
K8S_VERSION="1.28.5"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Creating AKS Cluster: ${CLUSTER_NAME}${NC}"

# Create resource group
echo -e "${YELLOW}Creating resource group...${NC}"
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION"

# Create AKS cluster
echo -e "${YELLOW}Creating AKS cluster...${NC}"
az aks create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CLUSTER_NAME" \
    --location "$LOCATION" \
    --kubernetes-version "$K8S_VERSION" \
    --node-count "$NODE_COUNT" \
    --node-vm-size "$NODE_SIZE" \
    --network-plugin azure \
    --network-policy calico \
    --enable-managed-identity \
    --enable-addons monitoring \
    --enable-cluster-autoscaler \
    --min-count 2 \
    --max-count 5 \
    --zones 1 2 3 \
    --node-osdisk-size 100 \
    --generate-ssh-keys

# Get credentials
echo -e "${YELLOW}Getting cluster credentials...${NC}"
az aks get-credentials \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CLUSTER_NAME" \
    --overwrite-existing

# Verify cluster connection
echo -e "${YELLOW}Verifying cluster connection...${NC}"
kubectl cluster-info

# Create namespaces
echo -e "${YELLOW}Creating namespaces...${NC}"
kubectl create namespace production || true
kubectl create namespace monitoring || true

echo -e "${GREEN}✓ AKS cluster created successfully!${NC}"
echo -e "Cluster: ${CLUSTER_NAME}"
echo -e "Resource Group: ${RESOURCE_GROUP}"
echo -e "Nodes: ${NODE_COUNT}"
```

### Step 2: Configurar Azure Container Registry

**Copilot Prompt Suggestion:**
```bash
# Create a script that:
# - Creates an Azure Container Registry
# - Attaches it to the AKS cluster
# - Builds and pushes the Docker image
# - Configures RBAC for pulling images
# File: scripts/setup-acr.sh
```

**Expected Output:**
```bash
#!/bin/bash
set -euo pipefail

# Configuration from environment or defaults
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-workshop-module12}"
ACR_NAME="${ACR_NAME:-acrworkshop$RANDOM}"
AKS_CLUSTER="${CLUSTER_NAME:-aks-workshop-module12}"
IMAGE_NAME="product-catalog"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "Setting up Azure Container Registry: $ACR_NAME"

# Create ACR
echo "Creating ACR..."
az acr create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$ACR_NAME" \
    --sku Basic \
    --admin-enabled false

# Get ACR ID
ACR_ID=$(az acr show \
    --name "$ACR_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query id --output tsv)

# Attach ACR to AKS
echo "Attaching ACR to AKS cluster..."
az aks update \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_CLUSTER" \
    --attach-acr "$ACR_ID"

# Build and push image
echo "Building and pushing Docker image..."
az acr build \
    --registry "$ACR_NAME" \
    --image "${IMAGE_NAME}:${IMAGE_TAG}" \
    --file Dockerfile \
    .

# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show \
    --name "$ACR_NAME" \
    --query loginServer \
    --output tsv)

echo "✓ ACR setup complete!"
echo "Registry: $ACR_LOGIN_SERVER"
echo "Image: $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG"

# Export for later use
export ACR_LOGIN_SERVER
export FULL_IMAGE_NAME="$ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG"
```

## 🎨 Partee 2: Kubernetes Manifests

### Step 3: Create Namespace and ConfigMap

**Copilot Prompt Suggestion:**
```yaml
# Create kubernetes/00-namespace.yaml that includes:
# - Production namespace with labels
# - Resource quotas for the namespace
# - Network policies for security
# - Default service account configuration
```

**Expected Output:**
```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    name: production
    environment: production
    monitoring: enabled
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: production-quota
  namespace: production
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    persistentvolumeclaims: "10"
    services: "10"
    services.loadbalancers: "2"
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: product-catalog
  namespace: production
  labels:
    app: product-catalog
```

### Step 4: Create ConfigMap and Secret

**Copilot Prompt Suggestion:**
```yaml
# Create kubernetes/01-config.yaml with:
# - ConfigMap for application configuration
# - Environment-specific settings
# - Feature flags
# - Logging configuration
```

**Expected Output:**
```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: product-catalog-config
  namespace: production
  labels:
    app: product-catalog
data:
  # Application settings
  API_VERSION: "1.0.0"
  API_TITLE: "Product Catalog Service"
  API_PORT: "8000"
  LOG_LEVEL: "info"
  ENVIRONMENT: "production"
  
  # Feature flags
  ENABLE_CACHE: "true"
  ENABLE_RATE_LIMITING: "true"
  RATE_LIMIT_MAX_REQUESTS: "100"
  RATE_LIMIT_WINDOW_SECONDS: "60"
  
  # Monitoring
  METRICS_ENABLED: "true"
  METRICS_PORT: "9090"
  TRACING_ENABLED: "true"
  
  # Database configuration
  DB_POOL_SIZE: "20"
  DB_MAX_OVERFLOW: "40"
  DB_POOL_TIMEOUT: "30"
  
  # Redis configuration
  REDIS_MAX_CONNECTIONS: "50"
  REDIS_DECODE_RESPONSES: "true"
  CACHE_TTL: "300"
---
apiVersion: v1
kind: Secret
metadata:
  name: product-catalog-secrets
  namespace: production
  labels:
    app: product-catalog
type: Opaque
stringData:
  # These should be stored in Azure Key Vault in production
  DATABASE_URL: "postgresql://postgres:postgres@postgres-service:5432/products"
  REDIS_URL: "redis://redis-service:6379"
  SECRET_KEY: "your-production-secret-key-here"
```

### Step 5: Create Deployment Manifest

**Copilot Prompt Suggestion:**
```yaml
# Create kubernetes/02-deployment.yaml with:
# - Deployment with 3 replicas
# - Resource requests and limits
# - Health and readiness probes
# - Security context (non-root user)
# - Anti-affinity rules for HA
# - Lifecycle hooks for graceful shutdown
# - Environment variables from ConfigMap and Secrets
```

**Expected Output:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-catalog
  namespace: production
  labels:
    app: product-catalog
    version: v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: product-catalog
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: product-catalog
        version: v1
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9090"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: product-catalog
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
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
                  - product-catalog
              topologyKey: kubernetes.io/hostname
      containers:
      - name: product-catalog
        image: ${ACR_LOGIN_SERVER}/product-catalog:latest
        imagePullPolicy: Always
        ports:
        - name: http
          containerPort: 8000
          protocol: TCP
        - name: metrics
          containerPort: 9090
          protocol: TCP
        envFrom:
        - configMapRef:
            name: product-catalog-config
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: product-catalog-secrets
              key: DATABASE_URL
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: product-catalog-secrets
              key: REDIS_URL
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: product-catalog-secrets
              key: SECRET_KEY
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 30
          periodSeconds: 30
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 3
        lifecycle:
          preStop:
            exec:
              command:
              - /bin/sh
              - -c
              - sleep 15
        volumeMounts:
        - name: tmp
          mountPath: /tmp
          readOnly: false
      volumes:
      - name: tmp
        emptyDir: {}
```

---

**Continue to Part 2** for Service, Ingress, HPA, and monitoring setup...