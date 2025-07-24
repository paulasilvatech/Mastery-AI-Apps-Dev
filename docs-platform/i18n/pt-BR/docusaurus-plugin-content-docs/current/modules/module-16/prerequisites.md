---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 16"
---

# Pré-requisitos for Módulo 16: Security Implementation

## 📋 Required Knowledge

### From Anterior Módulos
- ✅ **Módulo 11**: Microservices architecture and service communication
- ✅ **Módulo 12**: Cloud-native desenvolvimento and containerization
- ✅ **Módulo 13**: Infrastructure as Code principles
- ✅ **Módulo 14**: CI/CD pipeline implementation
- ✅ **Módulo 15**: Performance optimization techniques

### Security Fundamentos
- Basic understanding of authentication vs authorization
- Familiarity with HTTPS/TLS concepts
- Knowledge of common security threats (OWASP Top 10)
- Understanding of encryption basics

## 🛠️ Ferramentas Necessárias and Services

### desenvolvimento ambiente
```bash
# Verify Python version
python --version  # Should be 3.11+

# Install security tools
pip install cryptography==41.0.0
pip install pyjwt==2.8.0
pip install python-jose[cryptography]==3.3.0
pip install azure-identity==1.15.0
pip install azure-keyvault-secrets==4.7.0
```

### Azure Services Setup

#### 1. Enable Security Services
```bash
# Register required resource providers
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Security
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.ManagedIdentity

# Create resource group for security resources
az group create --name rg-security-workshop --location eastus
```

#### 2. Create Key Vault
```bash
# Create Key Vault for secrets management
az keyvault create \
  --name kv-workshop-$RANDOM \
  --resource-group rg-security-workshop \
  --location eastus \
  --enable-rbac-authorization true
```

#### 3. Enable Microsoft Defender
```bash
# Enable Defender for Cloud
az security pricing create \
  --name VirtualMachines \
  --tier Standard

az security pricing create \
  --name AppServices \
  --tier Standard

az security pricing create \
  --name KeyVaults \
  --tier Standard
```

### GitHub Setup

#### 1. Enable GitHub Avançado Security
- Navigate to your repository Configurações
- Click on "Security & analysis"
- Enable:
  - Dependency graph
  - Dependabot alerts
  - Dependabot security updates
  - Code scanning
  - Secret scanning

#### 2. Configure Code Scanning
```yaml
# .github/workflows/security-scan.yml
name: Security Scan
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: github/codeql-action/analyze@v3
```

## 🔑 Access Requirements

### Azure Permissions
You need at least **Contributor** role on your Azure assinatura with additional permissions for:
- Creating and managing Key Vaults
- Configuring security policies
- Accessing Microsoft Defender
- Creating managed identities

### GitHub Permissions
- Repository admin access for security settings
- Access to GitHub Avançado Security features
- Ability to create and modify workflows

## 📦 Pre-Módulo Setup Script

Run this script to verify all prerequisites:

```bash
#!/bin/bash
# save as verify-module16-setup.sh

echo "🔍 Verifying Module 16 Prerequisites..."

# Check Azure CLI
if ! command -v az &&gt; /dev/null; then
    echo "❌ Azure CLI not found. Please install it."
    exit 1
fi

# Check Azure login
if ! az account show &&gt; /dev/null; then
    echo "❌ Not logged into Azure. Run: az login"
    exit 1
fi

# Check Python packages
python -c "
import cryptography
import jwt
import azure.identity
import azure.keyvault.secrets
print('✅ All Python packages installed')
" || echo "❌ Missing Python packages. Run pip install commands above."

# Check GitHub CLI (optional but helpful)
if command -v gh &&gt; /dev/null; then
    echo "✅ GitHub CLI installed"
else
    echo "⚠️  GitHub CLI not found (optional)"
fi

# Verify Azure providers
providers=("Microsoft.KeyVault" "Microsoft.Security" "Microsoft.ManagedIdentity")
for provider in "${providers[@]}"; do
    status=$(az provider show --namespace $provider --query "registrationState" -o tsv)
    if [ "$status" == "Registered" ]; then
        echo "✅ $provider registered"
    else
        echo "❌ $provider not registered. Registering..."
        az provider register --namespace $provider
    fi
done

echo "
📋 Manual Checks Required:
1. Verify GitHub Advanced Security is enabled in your repository
2. Ensure you have Contributor access to your Azure subscription
3. Confirm you have completed modules 1-15

Ready to start Module 16? Let's secure your enterprise! 🔐
"
```

## 🎯 Skills Verificar

Before starting this module, you should be comfortable with:

### Security Concepts
- [ ] Difference between authentication and authorization
- [ ] How HTTPS/TLS works
- [ ] Common attack vectors (XSS, SQL injection, etc.)
- [ ] Basic cryptography (hashing vs encryption)

### Technical Skills
- [ ] Writing async Python code
- [ ] Working with ambiente variables
- [ ] Using Git for version control
- [ ] Basic Docker knowledge
- [ ] Understanding of REST APIs

### Azure Experience
- [ ] Creating and managing resources
- [ ] Working with Azure CLI
- [ ] Understanding resource groups
- [ ] Basic networking concepts

## ⚠️ Common Setup Issues

### Issue: Key Vault name already exists
**Solution**: Key Vault names must be globally unique. The script uses $RANDOM to generate a unique suffix.

### Issue: Insufficient permissions
**Solution**: Ask your Azure admin to grant you the required roles or use a personal assinatura.

### Issue: GitHub Avançado Security not available
**Solution**: This requires GitHub Empresarial or public repositories. For private repos, you need GitHub Avançado Security license.

## 📚 Pre-Módulo Reading

Enhance your learning by reviewing these resources:
- [Zero Trust Architecture Visão Geral](https://www.microsoft.com/security/business/zero-trust)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [Azure Security Fundamentos](https://learn.microsoft.com/training/paths/describe-azure-management-governance/)

---

🚀 Once all prerequisites are met, you're ready to implement enterprise-grade security!