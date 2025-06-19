# 📋 Workshop Prerequisites - Complete Guide

## 🎯 Overview

This document provides detailed prerequisites for each module of the AI-Powered Development Workshop. Prerequisites are organized by track and include hardware, software, accounts, and knowledge requirements.

## 🌐 General Prerequisites (All Modules)

### Hardware Requirements

#### Minimum Configuration
- **CPU**: 4-core processor (Intel i5/AMD Ryzen 5 or equivalent)
- **RAM**: 16 GB
- **Storage**: 256 GB SSD with 100 GB free space
- **Network**: Broadband internet (10+ Mbps)

#### Recommended Configuration
- **CPU**: 8-core processor (Intel i7/AMD Ryzen 7 or better)
- **RAM**: 32 GB
- **Storage**: 512 GB SSD with 200 GB free space
- **Network**: High-speed internet (25+ Mbps)

### Operating System Support

#### Windows
- Windows 10 version 1909 or higher
- Windows 11 (all versions)
- WSL2 installed for Linux tooling

#### macOS
- macOS 11.0 (Big Sur) or higher
- Xcode Command Line Tools installed

#### Linux
- Ubuntu 20.04 LTS or higher
- Fedora 36 or higher
- Debian 11 or higher

### Essential Software

```bash
# Version requirements
git >= 2.38.0
node >= 18.0.0
npm >= 9.0.0
python >= 3.11.0
pip >= 23.0.0
docker >= 24.0.0
docker-compose >= 2.20.0
```

### Required Accounts

1. **GitHub Account**
   - Verified email address
   - Two-factor authentication enabled
   - GitHub Copilot subscription (Individual or Business)

2. **Azure Account**
   - Free tier or paid subscription
   - Azure CLI configured
   - Minimum $50 credit recommended

3. **Additional Services** (Module-specific)
   - OpenAI API account (Modules 17-20)
   - Docker Hub account
   - npm registry access

## 🟢 Fundamentals Track Prerequisites (Modules 1-5)

### Module 1: Introduction to AI-Powered Development

#### Knowledge Requirements
- Basic programming concepts (variables, functions, loops)
- Familiarity with any programming language
- Basic understanding of version control

#### Software Setup
```bash
# Install VS Code
# Windows: Download from https://code.visualstudio.com
# macOS: brew install --cask visual-studio-code
# Linux: snap install code --classic

# Install GitHub Copilot extension
code --install-extension GitHub.copilot
code --install-extension GitHub.copilot-chat
```

#### Verification Checklist
- [ ] VS Code installed and running
- [ ] GitHub account created
- [ ] GitHub Copilot trial or subscription active
- [ ] Can create and run a "Hello World" program

### Module 2: GitHub Copilot Fundamentals

#### Additional Requirements
- Completed Module 1
- Basic Git commands knowledge
- Understanding of code comments and documentation

#### Language-Specific Setup

**Python Track:**
```bash
# Create virtual environment
python -m venv copilot-env
# Activate (Windows)
copilot-env\Scripts\activate
# Activate (macOS/Linux)
source copilot-env/bin/activate
```

**.NET Track:**
```bash
# Install .NET SDK
dotnet --version  # Should show 8.0 or higher
# Install Entity Framework tools
dotnet tool install --global dotnet-ef
```

### Module 3: Advanced Prompting Techniques

#### Prerequisites
- Completed Modules 1-2
- Understanding of function signatures
- Basic debugging experience

#### Required VS Code Extensions
```bash
code --install-extension ms-python.python
code --install-extension ms-dotnettools.csharp
code --install-extension dbaeumer.vscode-eslint
code --install-extension esbenp.prettier-vscode
```

### Module 4: AI-Assisted Debugging and Testing

#### Knowledge Requirements
- Understanding of unit testing concepts
- Basic knowledge of test frameworks
- Debugging fundamentals

#### Framework Setup

**Python:**
```bash
pip install pytest pytest-cov pytest-asyncio
pip install unittest-xml-reporting
```

**.NET:**
```bash
dotnet add package xunit
dotnet add package xunit.runner.visualstudio
dotnet add package coverlet.collector
```

### Module 5: Documentation and Code Quality

#### Additional Tools
```bash
# Documentation generators
pip install sphinx mkdocs  # Python
dotnet tool install -g docfx  # .NET

# Linting tools
pip install pylint black flake8  # Python
dotnet tool install -g dotnet-format  # .NET
```

## 🔵 Intermediate Track Prerequisites (Modules 6-10)

### Module 6: Multi-File Editing and Workspaces

#### Prerequisites
- Completed Fundamentals track
- Understanding of project structure
- Experience with medium-sized codebases

#### Additional Extensions
```bash
code --install-extension eamodio.gitlens
code --install-extension mhutchie.git-graph
code --install-extension donjayamanne.githistory
```

### Module 7: Building Web Applications with AI

#### Web Development Setup

**Frontend Requirements:**
```bash
# Node.js and package managers
node --version  # 18.0+
npm --version   # 9.0+
npm install -g yarn pnpm

# Framework CLIs
npm install -g @angular/cli
npm install -g create-react-app
npm install -g @vue/cli
```

**Backend Requirements:**

**Python (FastAPI):**
```bash
pip install fastapi uvicorn[standard]
pip install sqlalchemy alembic
pip install python-multipart python-jose[cryptography]
```

**.NET (ASP.NET Core):**
```bash
dotnet new webapi -n TestAPI
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
```

### Module 8: AI-Driven API Development

#### API Testing Tools
```bash
# Install Postman or Insomnia
# Install REST Client VS Code extension
code --install-extension humao.rest-client

# API documentation tools
pip install fastapi[all]  # Includes automatic docs
dotnet add package Swashbuckle.AspNetCore
```

### Module 9: Database Design and Optimization

#### Database Setup

**Local Development:**
```bash
# PostgreSQL via Docker
docker run -d --name postgres \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -p 5432:5432 \
  postgres:15

# MongoDB via Docker
docker run -d --name mongodb \
  -p 27017:27017 \
  mongo:6
```

**Database Tools:**
```bash
# Install database clients
# pgAdmin, MongoDB Compass, Azure Data Studio

# ORM Setup
pip install sqlalchemy psycopg2-binary  # Python
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL  # .NET
```

### Module 10: Real-time Applications

#### WebSocket Requirements
```bash
# Python
pip install websockets python-socketio

# .NET
dotnet add package Microsoft.AspNetCore.SignalR.Client

# Node.js (for testing)
npm install -g wscat
```

## 🟠 Advanced Track Prerequisites (Modules 11-15)

### Module 11: Microservices Architecture

#### Container Setup
```bash
# Docker and Kubernetes
docker --version  # 24.0+
kubectl version --client  # 1.28+

# Install Kubernetes tools
# Windows: Install Docker Desktop with Kubernetes
# macOS: brew install kubectl minikube
# Linux: Follow official k8s installation guide

# Verify cluster access
kubectl cluster-info
```

#### Service Mesh (Optional)
```bash
# Istio installation
curl -L https://istio.io/downloadIstio | sh -
# Follow platform-specific installation
```

### Module 12: Cloud-Native Development

#### Cloud CLI Tools
```bash
# Azure CLI
az --version  # 2.50+
az login

# Verify subscription
az account show

# Install Azure Functions Core Tools
npm install -g azure-functions-core-tools@4
```

### Module 13: Infrastructure as Code (Azure)

#### IaC Tools Installation

**Terraform:**
```bash
# Install Terraform
# Windows: choco install terraform
# macOS: brew install terraform
# Linux: Install from HashiCorp repos

terraform --version  # 1.5+
```

**Bicep:**
```bash
# Install Bicep
az bicep install
az bicep version  # 0.20+
```

**Required VS Code Extensions:**
```bash
code --install-extension hashicorp.terraform
code --install-extension ms-azuretools.vscode-bicep
code --install-extension ms-azuretools.vscode-azureresourcemanager
```

### Module 14: CI/CD with GitHub Actions

#### GitHub Setup
- Repository with Actions enabled
- Secrets configured for deployments
- Understanding of YAML syntax

#### Local Testing Tools
```bash
# Act for local GitHub Actions testing
# Windows: choco install act-cli
# macOS: brew install act
# Linux: Follow act installation guide
```

### Module 15: Performance and Scalability

#### Performance Testing Tools
```bash
# Load testing
npm install -g artillery
pip install locust

# Profiling tools
pip install py-spy memory-profiler  # Python
dotnet add package MiniProfiler.AspNetCore  # .NET
```

## 🔴 Enterprise Track Prerequisites (Modules 16-21)

### Module 16: Security Implementation

#### Security Tools
```bash
# Scanning tools
pip install bandit safety  # Python
dotnet tool install -g security-scan  # .NET

# Secret management
az keyvault create --name mykeyvault --resource-group mygroup
```

#### Required Knowledge
- OWASP Top 10 understanding
- Basic cryptography concepts
- Authentication vs Authorization

### Module 17: AI Model Integration

#### AI/ML Prerequisites
```bash
# Azure OpenAI access
az cognitiveservices account create \
  --name myopenai \
  --resource-group mygroup \
  --kind OpenAI \
  --sku S0 \
  --location eastus

# Python ML packages
pip install openai langchain azure-cognitiveservices-speech
pip install numpy pandas scikit-learn

# .NET packages
dotnet add package Azure.AI.OpenAI
dotnet add package Microsoft.ML
```

### Module 18: Enterprise Integration Patterns

#### Message Queue Setup
```bash
# RabbitMQ
docker run -d --name rabbitmq \
  -p 5672:5672 -p 15672:15672 \
  rabbitmq:3-management

# Azure Service Bus setup (via portal or CLI)
az servicebus namespace create --name myservicebus
```

### Module 19: Monitoring and Observability

#### Monitoring Stack
```bash
# Prometheus and Grafana via Docker Compose
# Use provided docker-compose.yml in module folder

# Application Insights
az monitor app-insights component create \
  --app myapp \
  --location eastus \
  --resource-group mygroup
```

### Module 20: Production Deployment Strategies

#### Advanced Deployment Tools
```bash
# Helm for Kubernetes
curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz | tar xz
sudo mv linux-amd64/helm /usr/local/bin/

# Feature flag service
# LaunchDarkly or Azure App Configuration
```

### Module 21: COBOL Modernization

#### COBOL Environment
```bash
# GnuCOBOL installation
# Windows: Download from gnucobol.sourceforge.io
# macOS: brew install gnucobol
# Linux: apt-get install gnucobol

# Verify installation
cobc --version

# COBOL to modern language tools
pip install pycobol
```

#### Sample COBOL Programs
- Provided in module resources
- Banking system examples
- Batch processing samples

## ⚡ Module 22: Super Challenge Prerequisites

### Mandatory Completion
- Modules 1-21 completed
- All exercises passed
- Portfolio projects ready

### Technical Requirements
- All previous tools installed
- 50 GB free disk space
- High-performance machine recommended

### Knowledge Validation
- Certification from previous modules
- Code review readiness
- Architecture design experience

## 🔍 Prerequisite Verification Script

Create and run this script to verify all prerequisites:

```python
#!/usr/bin/env python3
"""
Workshop Prerequisites Checker
Verifies all required tools and configurations
"""

import subprocess
import sys
import os

def check_command(cmd, min_version=None):
    """Check if a command exists and optionally its version"""
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ {cmd[0]} found")
            if min_version and len(result.stdout) > 0:
                # Version checking logic here
                pass
            return True
        else:
            print(f"❌ {cmd[0]} not found")
            return False
    except FileNotFoundError:
        print(f"❌ {cmd[0]} not found")
        return False

def main():
    """Main prerequisite checker"""
    print("🔍 AI-Powered Development Workshop Prerequisites Checker\n")
    
    # Check essential tools
    essentials = [
        (["git", "--version"], "2.38"),
        (["python", "--version"], "3.11"),
        (["node", "--version"], "18.0"),
        (["docker", "--version"], "24.0"),
        (["code", "--version"], None),
    ]
    
    all_good = True
    for cmd, version in essentials:
        if not check_command(cmd, version):
            all_good = False
    
    # Check language-specific tools
    print("\n📦 Language-Specific Tools:")
    
    # Python
    check_command(["pip", "--version"])
    
    # .NET
    check_command(["dotnet", "--version"])
    
    # Azure
    print("\n☁️ Cloud Tools:")
    check_command(["az", "--version"])
    
    if all_good:
        print("\n✅ All essential prerequisites are installed!")
    else:
        print("\n❌ Some prerequisites are missing. Please install them before starting.")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

Save this as `check_prerequisites.py` and run:
```bash
python check_prerequisites.py
```

---

**Ready to start?** Once all prerequisites are met, proceed to Module 1!

*Last updated: [Current Date]*