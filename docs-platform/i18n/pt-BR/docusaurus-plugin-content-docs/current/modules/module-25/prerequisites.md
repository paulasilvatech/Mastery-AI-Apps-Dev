---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 25"
---

# Pré-requisitos for Módulo 25: produção Agent implantação

## 🎯 Required Knowledge

Before starting this module, ensure you have:

### From Anterior Módulos
- ✅ **Módulo 21**: AI agent fundamentals
- ✅ **Módulo 22**: Custom agent desenvolvimento
- ✅ **Módulo 23**: Model Context Protocol (MCP)
- ✅ **Módulo 24**: Multi-agent orchestration
- ✅ **Production Experience**: Basic understanding of produção systems

### Infrastructure Knowledge
- ✅ **Containers**: Docker fundamentals
- ✅ **Orchestration**: Basic Kubernetes concepts
- ✅ **Cloud Platforms**: Experience with at least one (Azure/AWS/GCP)
- ✅ **Networking**: Understanding of DNS, load balancing, TLS

### DevOps Skills
- ✅ **CI/CD**: Pipeline concepts and practices
- ✅ **IaC**: Infrastructure as Code basics
- ✅ **Monitoring**: Metrics, logs, and traces
- ✅ **Security**: Basic security principles

## 🛠️ Required Software

### Core Requirements
```bash
# Docker
docker --version  # Must be 24.0.0 or higher

# Kubernetes tools
kubectl version --client  # Must be 1.28.0 or higher
helm version  # Must be 3.13.0 or higher

# Cloud CLIs (at least one)
az --version  # Azure CLI 2.55.0+
aws --version  # AWS CLI 2.15.0+
gcloud --version  # Google Cloud SDK 450.0+

# Infrastructure tools
terraform --version  # Must be 1.6.0 or higher
# OR
pulumi version  # Must be 3.90.0 or higher
```

### desenvolvimento ambiente
```bash
# Container tools
docker-compose --version  # Must be 2.23.0 or higher
kind --version  # For local Kubernetes 0.20.0+

# Monitoring tools
prometheus --version  # Local testing
grafana-server -v  # Optional local setup

# Code quality
hadolint --version  # Dockerfile linting
kubeval --version  # Kubernetes manifest validation
tflint --version  # Terraform linting
```

## 🏗️ Infrastructure Setup

### Option 1: Local Kubernetes (Recommended for Learning)

#### Using Kind (Kubernetes in Docker)
```bash
# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Create cluster with config
cat &lt;<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: agent-platform
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
- role: worker
- role: worker
- role: worker
EOF

kind create cluster --config kind-config.yaml

# Verify cluster
kubectl cluster-info
kubectl get nodes
```

#### Install Ingress Controller
```bash
# Install NGINX ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

### Option 2: Cloud Kubernetes

#### Azure Kubernetes Service (AKS)
```bash
# Create resource group
az group create --name rg-agents --location eastus

# Create AKS cluster
az aks create \
  --resource-group rg-agents \
  --name aks-agents \
  --node-count 3 \
  --enable-addons monitoring \
  --generate-ssh-keys

# Get credentials
az aks get-credentials \
  --resource-group rg-agents \
  --name aks-agents
```

#### Amazon EKS
```bash
# Create cluster
eksctl create cluster \
  --name agent-platform \
  --nodes 3 \
  --node-type t3.medium \
  --region us-east-1
```

#### Google Kubernetes Engine (GKE)
```bash
# Create cluster
gcloud container clusters create agent-platform \
  --num-nodes=3 \
  --machine-type=e2-medium \
  --region=us-central1
```

## 📦 Install Ferramentas Necessárias

### 1. Helm Package Manager
```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Add common repositories
helm repo add stable https://charts.helm.sh/stable
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### 2. Monitoring Stack
```bash
# Create monitoring namespace
kubectl create namespace monitoring

# Install Prometheus & Grafana
helm install prometheus \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=admin123 \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

# Verify installation
kubectl get pods -n monitoring
```

### 3. Service Mesh (Optional but Recommended)
```bash
# Install Istio
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH

# Install Istio
istioctl install --set profile=demo -y

# Enable sidecar injection
kubectl label namespace default istio-injection=enabled
```

### 4. Infrastructure as Code Tools
```bash
# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install terraform

# OR Pulumi
curl -fsSL https://get.pulumi.com | sh
```

## 🔧 ambiente Configuration

### 1. Create Project Structure
```bash
mkdir -p ~/module-25-production
cd ~/module-25-production

# Create directory structure
mkdir -p {infrastructure,kubernetes,monitoring,scripts,docs}
mkdir -p kubernetes/{base,overlays/{dev,staging,prod}}
mkdir -p monitoring/{prometheus,grafana,alerts}
```

### 2. ambiente Variables
Create `.env` file:
```bash
# Cluster Configuration
CLUSTER_NAME=agent-platform
NAMESPACE=agent-system

# Container Registry
REGISTRY_URL=localhost:5000  # Or your cloud registry
REGISTRY_USERNAME=admin
REGISTRY_PASSWORD=changeme

# Monitoring
PROMETHEUS_URL=http://prometheus:9090
GRAFANA_URL=http://grafana:3000
GRAFANA_PASSWORD=admin123

# Agent Configuration
AGENT_REPLICAS=3
AGENT_CPU_REQUEST=100m
AGENT_CPU_LIMIT=500m
AGENT_MEMORY_REQUEST=128Mi
AGENT_MEMORY_LIMIT=512Mi

# Security
TLS_ENABLED=true
RBAC_ENABLED=true
NETWORK_POLICIES=true

# Cloud Provider (if using cloud)
CLOUD_PROVIDER=azure  # or aws, gcp
CLOUD_REGION=eastus
CLOUD_RESOURCE_GROUP=rg-agents
```

### 3. Install Módulo Dependencies
```bash
# Clone module repository (if provided)
git clone <module-repo-url> .

# Install npm dependencies
npm init -y
npm install \
  @kubernetes/client-node \
  prom-client \
  winston \
  express \
  helmet \
  dotenv

# Install Python dependencies
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

pip install \
  kubernetes>=28.0.0 \
  prometheus-client>=0.19.0 \
  pyyaml>=6.0 \
  jinja2>=3.1.0 \
  requests>=2.31.0
```

## 🧪 Validation Script

Create `scripts/validate-prerequisites.sh`:
```bash
#!/bin/bash

echo "🔍 Validating Module 25 Prerequisites..."
echo

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Check function
check_command() {
    if command -v $1 &&gt; /dev/null; then
        VERSION=$($2)
        echo -e "${GREEN}✓${NC} $1: $VERSION"
        return 0
    else
        echo -e "${RED}✗${NC} $1: Not found"
        return 1
    fi
}

# Check required tools
echo "Checking required tools..."
check_command docker "docker --version | cut -d' ' -f3"
check_command kubectl "kubectl version --client -o json | jq -r .clientVersion.gitVersion"
check_command helm "helm version --short"

echo
echo "Checking optional tools..."
check_command kind "kind --version"
check_command terraform "terraform --version | head -1"
check_command pulumi "pulumi version"

# Check Kubernetes cluster
echo
echo "Checking Kubernetes cluster..."
if kubectl cluster-info &&gt; /dev/null; then
    echo -e "${GREEN}✓${NC} Kubernetes cluster is accessible"
    kubectl get nodes
else
    echo -e "${RED}✗${NC} No Kubernetes cluster found"
    echo "Please set up a cluster using the instructions above"
fi

# Check monitoring
echo
echo "Checking monitoring stack..."
if kubectl get pods -n monitoring &&gt; /dev/null; then
    echo -e "${GREEN}✓${NC} Monitoring namespace exists"
    kubectl get pods -n monitoring --no-headers | grep Running | wc -l | xargs echo "Running pods:"
else
    echo -e "${RED}✗${NC} Monitoring not set up"
    echo "Run: helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring"
fi

echo
echo "Prerequisites check complete!"
```

Make executable and run:
```bash
chmod +x scripts/validate-prerequisites.sh
./scripts/validate-prerequisites.sh
```

## 🐳 Local Container Registry

For local desenvolvimento, set up a registry:
```bash
# Run local registry
docker run -d -p 5000:5000 --restart=always --name registry registry:2

# Configure Docker to use insecure registry
# Add to /etc/docker/daemon.json:
{
  "insecure-registries": ["localhost:5000"]
}

# Restart Docker
sudo systemctl restart docker

# Test registry
docker pull busybox
docker tag busybox localhost:5000/busybox
docker push localhost:5000/busybox
```

## 📊 Resource Requirements

### Minimum System Requirements
- **CPU**: 4 cores (8 recommended)
- **RAM**: 8GB (16GB recommended)
- **Storage**: 50GB free space
- **Network**: Stable internet connection

### Kubernetes Resource Allocations
```yaml
# Recommended resource limits per node
resources:
  requests:
    cpu: "2"
    memory: "4Gi"
  limits:
    cpu: "4"
    memory: "8Gi"
```

## 🚨 Common Setup Issues

### Issue: Kubernetes cluster not accessible
```bash
# Check context
kubectl config current-context
kubectl config get-contexts

# Switch context if needed
kubectl config use-context <context-name>
```

### Issue: Helm installation fails
```bash
# Check Helm version
helm version

# Update repositories
helm repo update

# Debug installation
helm install <release> <chart> --debug --dry-run
```

### Issue: Insufficient Recursos
```bash
# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods -A

# Scale down if needed
kubectl scale deployment <name> --replicas=1
```

## 📚 Pre-Módulo Learning

Before starting, review:

1. **Kubernetes Basics**
   - [Kubernetes Documentação](https://kubernetes.io/docs/home/)
   - [Kubernetes Patterns](https://k8spatterns.io/)

2. **Container Melhores Práticas**
   - [Docker Melhores Práticas](https://docs.docker.com/develop/dev-best-practices/)
   - [12 Factor App](https://12factor.net/)

3. **Production Readiness**
   - [Production Readiness Verificarlist](https://www.weave.works/blog/produção-ready-checklist-kubernetes)
   - [SRE Principles](https://sre.google/sre-book/table-of-contents/)

## ✅ Pre-Módulo Verificarlist

Before starting the exercises, ensure:

- [ ] Kubernetes cluster is running
- [ ] kubectl can access the cluster
- [ ] Helm is instalado and configurado
- [ ] Monitoring stack is deployed
- [ ] Container registry is accessible
- [ ] Environment variables are set
- [ ] Validation script passes
- [ ] You understand basic Kubernetes concepts
- [ ] You're familiar with YAML syntax

## 🎯 Ready to Start?

Once all prerequisites are met:

1. Revisar the [Production Architecture](README.md#-produção-architecture)
2. Understand the module structure
3. Comece com [Exercício 1: Production Agent Platform](./exercise1-overview)
4. Join the discussion for help and tips

---

**Need Help?** Check the [Module 25 Troubleshooting Guide](/docs/guias/troubleshooting) or post in the module discussions.