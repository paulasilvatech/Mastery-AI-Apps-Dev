# Module 19: Prerequisites and Setup

## 📋 Required Knowledge

Before starting Module 19, you should have completed:

### Previous Modules
- ✅ **Module 16**: Security Implementation
- ✅ **Module 17**: GitHub Models and AI Integration  
- ✅ **Module 18**: Enterprise Integration Patterns

### Technical Concepts
You should be comfortable with:
- Distributed systems monitoring principles
- RESTful API design and implementation
- Microservices architecture patterns
- Basic statistics (percentiles, averages, etc.)
- JSON and structured data formats
- Basic cloud architecture concepts

## 🛠️ Software Requirements

### Local Development Environment

```bash
# Check Python version (3.11+ required)
python --version

# Check Node.js (for some monitoring tools)
node --version  # Should be 18+

# Check Docker
docker --version  # Should be 24+

# Check Azure CLI
az --version  # Should be latest

# Check GitHub CLI
gh --version
```

### Required Python Packages

```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows
.\venv\Scripts\activate
# macOS/Linux
source venv/bin/activate

# Install requirements
pip install -r requirements.txt
```

**requirements.txt**:
```txt
# Core dependencies
fastapi==0.104.1
uvicorn[standard]==0.24.0
httpx==0.25.1
aiofiles==23.2.1

# Azure monitoring
azure-monitor-opentelemetry==1.1.0
azure-monitor-opentelemetry-exporter==1.0.0b20
applicationinsights==0.11.10
opencensus-ext-azure==1.1.11

# OpenTelemetry
opentelemetry-api==1.21.0
opentelemetry-sdk==1.21.0
opentelemetry-instrumentation-fastapi==0.42b0
opentelemetry-instrumentation-httpx==0.42b0
opentelemetry-instrumentation-logging==0.42b0
opentelemetry-exporter-prometheus==0.42b0

# Logging and metrics
structlog==23.2.0
prometheus-client==0.19.0
python-json-logger==2.0.7

# Testing
pytest==7.4.3
pytest-asyncio==0.21.1
pytest-cov==4.1.0
locust==2.17.0

# Utilities
python-dotenv==1.0.0
pydantic==2.5.0
pydantic-settings==2.1.0
tenacity==8.2.3
```

### VS Code Extensions
Ensure these extensions are installed:
- GitHub Copilot
- Python
- Pylance
- Azure Tools
- Azure Monitor
- Log File Highlighter
- JSON

## ☁️ Azure Resources Setup

### 1. Create Resource Group

```bash
# Set variables
RESOURCE_GROUP="rg-workshop-module19"
LOCATION="eastus"
UNIQUE_ID=$RANDOM

# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION
```

### 2. Create Log Analytics Workspace

```bash
# Create workspace
az monitor log-analytics workspace create \
  --resource-group $RESOURCE_GROUP \
  --workspace-name "law-module19-$UNIQUE_ID" \
  --location $LOCATION

# Get workspace ID and key
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group $RESOURCE_GROUP \
  --workspace-name "law-module19-$UNIQUE_ID" \
  --query customerId -o tsv)

WORKSPACE_KEY=$(az monitor log-analytics workspace get-shared-keys \
  --resource-group $RESOURCE_GROUP \
  --workspace-name "law-module19-$UNIQUE_ID" \
  --query primarySharedKey -o tsv)
```

### 3. Create Application Insights

```bash
# Create Application Insights
az monitor app-insights component create \
  --app "ai-module19-$UNIQUE_ID" \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP \
  --application-type web \
  --workspace "law-module19-$UNIQUE_ID"

# Get connection string
CONNECTION_STRING=$(az monitor app-insights component show \
  --app "ai-module19-$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP \
  --query connectionString -o tsv)
```

### 4. Create Storage Account

```bash
# Create storage for logs
az storage account create \
  --name "stmodule19$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS

# Get storage connection string
STORAGE_CONNECTION=$(az storage account show-connection-string \
  --name "stmodule19$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP \
  --query connectionString -o tsv)
```

### 5. (Optional) Create Azure Managed Grafana

```bash
# Create Grafana instance
az grafana create \
  --name "grafana-module19-$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku "Standard"
```

## 🔧 Environment Configuration

Create a `.env` file in the module directory:

```env
# Azure Configuration
APPLICATIONINSIGHTS_CONNECTION_STRING="YOUR_CONNECTION_STRING"
AZURE_LOG_ANALYTICS_WORKSPACE_ID="YOUR_WORKSPACE_ID"
AZURE_LOG_ANALYTICS_WORKSPACE_KEY="YOUR_WORKSPACE_KEY"
AZURE_STORAGE_CONNECTION_STRING="YOUR_STORAGE_CONNECTION"

# Application Configuration
APP_NAME="module19-monitoring"
ENVIRONMENT="development"
LOG_LEVEL="INFO"

# Monitoring Configuration
ENABLE_TRACING=true
ENABLE_METRICS=true
SAMPLING_RATE=1.0
METRIC_EXPORT_INTERVAL=60

# Service URLs (for exercises)
API_URL="http://localhost:8000"
FRONTEND_URL="http://localhost:3000"
DATABASE_URL="postgresql://user:pass@localhost/db"
```

## 🐳 Docker Setup

Create `docker-compose.yml` for local monitoring stack:

```yaml
version: '3.8'

services:
  # Prometheus for local metrics
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'

  # Grafana for local visualization
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_INSTALL_PLUGINS=grafana-azure-monitor-datasource
    volumes:
      - grafana_data:/var/lib/grafana

  # Jaeger for local tracing
  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686"
      - "14268:14268"
    environment:
      - COLLECTOR_OTLP_ENABLED=true

volumes:
  prometheus_data:
  grafana_data:
```

## ✅ Verification Script

Create `scripts/verify-setup.py`:

```python
#!/usr/bin/env python3
"""Verify Module 19 prerequisites and setup."""

import os
import sys
import subprocess
from pathlib import Path

def check_command(cmd, min_version=None):
    """Check if command exists and optionally verify version."""
    try:
        result = subprocess.run(
            [cmd, "--version"], 
            capture_output=True, 
            text=True
        )
        if result.returncode == 0:
            print(f"✅ {cmd} is installed")
            if min_version:
                # Add version checking logic here
                pass
            return True
    except FileNotFoundError:
        print(f"❌ {cmd} is not installed")
        return False

def check_python_packages():
    """Check required Python packages."""
    required = [
        "fastapi",
        "azure-monitor-opentelemetry",
        "opentelemetry-api",
        "structlog",
        "prometheus-client"
    ]
    
    import pkg_resources
    installed = {pkg.key for pkg in pkg_resources.working_set}
    
    all_installed = True
    for package in required:
        if package.lower() in installed:
            print(f"✅ {package} is installed")
        else:
            print(f"❌ {package} is not installed")
            all_installed = False
    
    return all_installed

def check_azure_resources():
    """Check Azure resources are created."""
    env_vars = [
        "APPLICATIONINSIGHTS_CONNECTION_STRING",
        "AZURE_LOG_ANALYTICS_WORKSPACE_ID",
        "AZURE_LOG_ANALYTICS_WORKSPACE_KEY"
    ]
    
    all_set = True
    for var in env_vars:
        if os.getenv(var):
            print(f"✅ {var} is set")
        else:
            print(f"❌ {var} is not set")
            all_set = False
    
    return all_set

def main():
    """Run all verification checks."""
    print("🔍 Verifying Module 19 Prerequisites\n")
    
    # Check commands
    commands_ok = all([
        check_command("python"),
        check_command("docker"),
        check_command("az"),
        check_command("gh")
    ])
    
    print("\n📦 Checking Python packages:")
    packages_ok = check_python_packages()
    
    print("\n☁️ Checking Azure configuration:")
    azure_ok = check_azure_resources()
    
    print("\n" + "="*50)
    if commands_ok and packages_ok and azure_ok:
        print("✅ All prerequisites are met! You're ready to start Module 19.")
        return 0
    else:
        print("❌ Some prerequisites are missing. Please install them before continuing.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
```

## 🚀 Quick Setup Script

Create `scripts/setup-module19.sh`:

```bash
#!/bin/bash

echo "🚀 Setting up Module 19 - Monitoring and Observability"

# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Start local monitoring stack
docker-compose up -d

# Verify setup
python scripts/verify-setup.py

echo "✅ Setup complete! You're ready to start the exercises."
```

## 📝 Final Checklist

Before starting the exercises, ensure you have:

- [ ] Python 3.11+ with virtual environment activated
- [ ] All required Python packages installed
- [ ] Azure resources created and configured
- [ ] Environment variables set in `.env`
- [ ] Docker containers running (optional for local testing)
- [ ] VS Code with required extensions
- [ ] GitHub Copilot working properly

---

Ready? Head back to the [main README](./README.md) to start the exercises!