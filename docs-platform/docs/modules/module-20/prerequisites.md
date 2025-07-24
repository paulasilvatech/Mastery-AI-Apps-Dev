---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 20"
---

# Module 20: Prerequisites and Setup

## 📋 Required Knowledge

Before starting Module 20, you should have completed:

### Previous Modules
- ✅ **Module 16**: Security Implementation
- ✅ **Module 17**: GitHub Models and AI Integration  
- ✅ **Module 18**: Enterprise Integration Patterns
- ✅ **Module 19**: Monitoring and Observability

### Technical Concepts
You should be comfortable with:
- Container orchestration (Docker, Kubernetes)
- Load balancing and traffic management
- CI/CD pipeline design
- Application monitoring and metrics
- Database migration strategies
- Infrastructure as Code (Terraform/Bicep)

## 🛠️ Software Requirements

### Local Development Environment

```bash
# Check versions
python --version          # 3.11+ required
docker --version          # 24+ required
kubectl version --client  # 1.28+ required
az --version             # 2.50+ required
gh --version             # 2.35+ required
terraform --version      # 1.5+ required
```

### Required Tools Installation

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install kubectl
az aks install-cli

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Flagger CLI
curl -sL https://flagger.app/install.sh | sudo bash
```

### VS Code Extensions
Ensure these extensions are installed:
- GitHub Copilot
- Azure Tools
- Kubernetes
- Docker
- YAML
- Python

## ☁️ Azure Resources Setup

### 1. Create Resource Group

```bash
# Set variables
RESOURCE_GROUP="rg-module20-deployments"
LOCATION="eastus"
SUFFIX=$RANDOM

# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION
```

### 2. Create AKS Cluster

```bash
# Create AKS cluster with multiple node pools
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name "aks-module20-$SUFFIX" \
  --node-count 3 \
  --enable-addons monitoring,http_application_routing \
  --generate-ssh-keys \
  --network-plugin azure \
  --network-policy azure

# Get credentials
az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name "aks-module20-$SUFFIX"
```

### 3. Create Container Registry

```bash
# Create ACR
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name "acrmodule20$SUFFIX" \
  --sku Basic

# Attach ACR to AKS
az aks update \
  --resource-group $RESOURCE_GROUP \
  --name "aks-module20-$SUFFIX" \
  --attach-acr "acrmodule20$SUFFIX"
```

### 4. Create Application Insights

```bash
# Create App Insights
az monitor app-insights component create \
  --app "appinsights-module20" \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP \
  --application-type web

# Get instrumentation key
INSTRUMENTATION_KEY=$(az monitor app-insights component show \
  --app "appinsights-module20" \
  --resource-group $RESOURCE_GROUP \
  --query "instrumentationKey" -o tsv)
```

### 5. Create Traffic Manager Profile

```bash
# Create Traffic Manager
az network traffic-manager profile create \
  --name "tm-module20-$SUFFIX" \
  --resource-group $RESOURCE_GROUP \
  --routing-method Performance \
  --unique-dns-name "module20-$SUFFIX"
```

## 📦 Python Environment Setup

### Create Virtual Environment

```bash
# Create and activate virtual environment
python -m venv venv

# Activate
# Linux/Mac:
source venv/bin/activate
# Windows:
.\venv\Scripts\activate

# Upgrade pip
python -m pip install --upgrade pip
```

### Install Dependencies

**requirements.txt**:
```txt
# Core dependencies
fastapi==0.104.1
uvicorn[standard]==0.24.0
httpx==0.25.1
pydantic==2.5.0
pydantic-settings==2.1.0

# Feature flags
launchdarkly-server-sdk==8.3.0
python-multipart==0.0.6

# Azure SDKs
azure-identity==1.15.0
azure-monitor-opentelemetry==1.1.0
azure-keyvault-secrets==4.7.0
azure-servicebus==7.11.0

# Kubernetes
kubernetes==28.1.0
pyyaml==6.0.1

# Monitoring
prometheus-client==0.19.0
opentelemetry-api==1.21.0
opentelemetry-sdk==1.21.0
opentelemetry-instrumentation-fastapi==0.42b0

# Database
sqlalchemy[asyncio]==2.0.23
asyncpg==0.29.0
alembic==1.12.1

# Testing
pytest==7.4.3
pytest-asyncio==0.21.1
pytest-cov==4.1.0
httpx==0.25.1
```

Install all dependencies:
```bash
pip install -r requirements.txt
```

## 🔧 Infrastructure Setup

### Deploy Base Infrastructure

```bash
# Navigate to infrastructure directory
cd infrastructure/

# Initialize Terraform
terraform init

# Create terraform.tfvars
cat &gt; terraform.tfvars &lt;<EOF
resource_group_name = "$RESOURCE_GROUP"
location           = "$LOCATION"
cluster_name       = "aks-module20-$SUFFIX"
acr_name          = "acrmodule20$SUFFIX"
app_insights_key  = "$INSTRUMENTATION_KEY"
EOF

# Plan and apply
terraform plan
terraform apply -auto-approve
```

## ✅ Verification Checklist

Run the verification script to ensure everything is set up:

```bash
# Run verification
./scripts/verify-prerequisites.sh
```

Expected output:
```
✅ Python 3.11+ installed
✅ Docker running
✅ Kubernetes cluster accessible
✅ Azure CLI authenticated
✅ Required Azure resources created
✅ Python dependencies installed
✅ VS Code extensions installed
✅ Infrastructure deployed

🎉 All prerequisites met! You're ready to start Module 20.
```

## 🔑 Environment Variables

Create a `.env` file with your configuration:

```bash
# Azure Configuration
AZURE_SUBSCRIPTION_ID=your-subscription-id
AZURE_RESOURCE_GROUP=rg-module20-deployments
AZURE_LOCATION=eastus

# AKS Configuration
AKS_CLUSTER_NAME=aks-module20-xxxxx
ACR_NAME=acrmodule20xxxxx

# Monitoring
APP_INSIGHTS_KEY=your-instrumentation-key
APP_INSIGHTS_CONNECTION_STRING=your-connection-string

# Feature Flags (will be set in exercises)
LAUNCHDARKLY_SDK_KEY=your-sdk-key

# Database
DATABASE_URL=postgresql+asyncpg://user:pass@host/db
```

## 📚 Additional Setup Resources

- [Azure AKS Quickstart](https://learn.microsoft.com/azure/aks/learn/quick-kubernetes-deploy-cli)
- [Flagger Installation](https://docs.flagger.app/install/flagger-install-on-kubernetes)
- [GitHub Actions for AKS](https://learn.microsoft.com/azure/aks/kubernetes-action)

## ⚠️ Cost Management

This module uses several Azure services. To minimize costs:
- Use the smallest suitable SKUs
- Delete resources after completing the module
- Use the provided cleanup script: `./scripts/cleanup-module-20.sh`

Estimated costs: ~$5-10 for the 3-hour module if cleaned up promptly.

---

Ready to implement production deployment strategies? Let's start with Exercise 1! 🚀