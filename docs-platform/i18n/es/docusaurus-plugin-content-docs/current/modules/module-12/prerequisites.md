---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 12"
---

# Módulo 12 Prerrequisitos: Cloud-Native desarrollo

## 🔧 Required Software

### Container Tools
```bash
# Docker Desktop
docker --version  # Required: 24.0.0+
docker compose version  # Required: 2.20.0+

# Verify Docker is running
docker run hello-world
```

### Kubernetes Tools
```bash
# kubectl CLI
kubectl version --client  # Required: 1.28.0+

# Azure CLI with AKS extension
az --version  # Required: 2.50.0+
az extension add --name aks-preview

# Helm package manager
helm version  # Required: 3.12.0+
```

### desarrollo Tools
```bash
# Python environment
python --version  # Required: 3.11.0+
pip --version  # Required: 23.0.0+

# Node.js (for Azure Functions Core Tools)
node --version  # Required: 18.0.0+
npm --version  # Required: 9.0.0+

# Azure Functions Core Tools
func --version  # Required: 4.0.0+
```

## ☁️ Azure Recursos

### Required Azure Services
1. **Azure Kubernetes Service (AKS)**
   - Standard tier (for SLA)
   - 3 nodes minimum (Standard_DS2_v2)
   - Kubernetes version 1.28+

2. **Azure Container Registry (ACR)**
   - Basic tier sufficient
   - Geo-replication not required

3. **Azure Functions**
   - Consumption plan for exercises
   - Python 3.11 runtime

4. **Azure Monitor**
   - Log Análisis workspace
   - Application Insights

### Estimated Costs
- **Development**: ~$5-10/day
- **Ejercicios**: ~$2-5/exercise
- **Total Módulo**: ~$15-25
- **Cleanup**: Essential after each session

## 🔐 Access Requirements

### GitHub
- Copilot suscripción active
- Personal access token with:
  - `repo` scope
  - `packages:read` scope
  - `packages:write` scope

### Azure Permissions
```bash
# Check your permissions
az account show
az role assignment list --assignee $(az account show --query user.name -o tsv)

# Required roles:
# - Contributor on subscription or resource group
# - User Access Administrator (for RBAC exercises)
```

## 💾 Local ambiente Setup

### Directory Structure
```bash
mkdir -p ~/workshop/module-12
cd ~/workshop/module-12
mkdir -p .azure .kube docker kubernetes functions
```

### ambiente Variables
```bash
# Create .env file
cat &gt; .env &lt;&lt; EOF
# Azure Configuration
AZURE_SUBSCRIPTION_ID=your-subscription-id
AZURE_RESOURCE_GROUP=rg-workshop-module12
AZURE_LOCATION=eastus2

# Container Registry
ACR_NAME=acrworkshop${RANDOM}
ACR_LOGIN_SERVER=${ACR_NAME}.azurecr.io

# AKS Configuration
AKS_CLUSTER_NAME=aks-workshop-module12
AKS_NODE_COUNT=3
AKS_NODE_SIZE=Standard_DS2_v2

# GitHub
GITHUB_TOKEN=your-pat-token
GITHUB_USERNAME=your-username
EOF
```

### Python Virtual ambiente
```bash
# Create and activate virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: .\venv\Scripts\activate

# Install base packages
pip install -r requirements.txt
```

### Requirements.txt
```txt
# Azure SDKs
azure-functions==1.17.0
azure-storage-blob==12.19.0
azure-identity==1.15.0
azure-mgmt-containerservice==26.0.0
azure-mgmt-containerregistry==10.1.0

# Development tools
pydantic==2.5.0
fastapi==0.109.0
uvicorn==0.27.0
httpx==0.26.0
pytest==7.4.0
pytest-asyncio==0.23.0

# Monitoring
prometheus-client==0.19.0
opentelemetry-api==1.22.0
opentelemetry-sdk==1.22.0

# Utilities
python-dotenv==1.0.0
pyyaml==6.0.1
```

## 🚦 Pre-Módulo Validation

### Run Validation Script
```bash
#!/bin/bash
# save as verify-module-12.sh

echo "🔍 Checking Module 12 Prerequisites..."

# Check Docker
if ! command -v docker &&gt; /dev/null; then
    echo "❌ Docker not installed"
    exit 1
fi

# Check Kubernetes tools
if ! command -v kubectl &&gt; /dev/null; then
    echo "❌ kubectl not installed"
    exit 1
fi

# Check Azure CLI
if ! command -v az &&gt; /dev/null; then
    echo "❌ Azure CLI not installed"
    exit 1
fi

# Check Python
if ! python -c "import sys; exit(0 if sys.version_info &gt;= (3,11) else 1)"; then
    echo "❌ Python 3.11+ required"
    exit 1
fi

# Check Azure login
if ! az account show &&gt; /dev/null; then
    echo "❌ Not logged into Azure"
    exit 1
fi

echo "✅ All prerequisites met!"
```

## 🐳 Docker Configuration

### Docker Desktop Configuraciones
1. **Recursos**:
   - CPUs: 4+ cores
   - Memory: 8GB+
   - Disk: 20GB+ free

2. **Kubernetes**:
   - Enable Kubernetes (optional for local testing)
   - Reset cluster if previously used

3. **Extensions**:
   - Install Docker Scout
   - Install Logs Explorer

## 🌐 Network Requirements

### Firewall Rules
- Docker Hub: `https://hub.docker.com`
- Azure Container Registry: `*.azurecr.io`
- Azure Services: `*.azure.com`
- GitHub: `github.com`, `*.githubusercontent.com`

### Proxy Configuration (if applicable)
```bash
# Docker proxy
~/.docker/config.json

# Kubernetes proxy
export HTTPS_PROXY=http://proxy:port
export NO_PROXY=localhost,127.0.0.1,10.0.0.0/8
```

## 📝 Knowledge Verificar

Before starting, you should understand:
- [ ] Container vs VM differences
- [ ] Kubernetes basic concepts (pods, services, despliegues)
- [ ] RESTful API principles
- [ ] Environment variables and configuration
- [ ] Basic networking (ports, protocols)
- [ ] Git branching and merging

## 🆘 Troubleshooting Setup

### Common Issues

1. **Docker not starting**
   - Enable virtualization in BIOS
   - Verificar WSL2 on Windows
   - Restart Docker Desktop

2. **Kubernetes connection refused**
   ```bash
   kubectl config current-context
   kubectl cluster-info
   ```

3. **Azure CLI issues**
   ```bash
   az logout
   az login --use-device-code
   ```

## ✅ Ready Verificarlist

- [ ] All software instalado and versions verified
- [ ] Azure cuenta with active suscripción
- [ ] Docker Desktop running
- [ ] Python virtual ambiente created
- [ ] Environment variables configurado
- [ ] Network connectivity verified
- [ ] 20GB+ free disk space
- [ ] Módulo 11 completed

---

**Note**: Keep your Azure resources organized in a dedicated resource group for easy cleanup. Run `az group delete -n rg-workshop-module12 --yes` after completing the module.