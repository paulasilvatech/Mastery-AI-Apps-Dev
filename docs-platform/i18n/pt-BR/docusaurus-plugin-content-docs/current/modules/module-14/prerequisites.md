---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 14"
---

# Pré-requisitos for Módulo 14: CI/CD with GitHub Actions

## 📋 Required Knowledge

### From Anterior Módulos
You should have completed and understood:

- ✅ **Módulo 11**: Microservices Architecture
  - Service communication patterns
  - Container basics
  - Service discovery

- ✅ **Módulo 12**: Cloud-Native Development
  - Docker containerization
  - Kubernetes fundamentals
  - Serverless concepts

- ✅ **Módulo 13**: Infrastructure as Code
  - Terraform or Bicep basics
  - GitOps principles
  - Resource provisioning

### Programming Skills
- **Python**: Intermediário level (primary language)
- **YAML**: Configuration syntax
- **Bash/PowerShell**: Basic scripting
- **Git**: Branching, merging, PR workflows

## 🛠️ Ferramentas Necessárias & contas

### Local desenvolvimento ambiente
```bash
# Verify installations
git --version           # &gt;= 2.38.0
docker --version        # &gt;= 24.0.0
python --version        # &gt;= 3.11.0
gh --version           # GitHub CLI &gt;= 2.40.0
```

### GitHub Setup
1. **GitHub Account** with:
   - GitHub Copilot enabled
   - Actions enabled for your conta
   - Personal Access Token (PAT) with appropriate scopes

2. **Repository Access**:
   - Ability to create repositories
   - Admin access to at least one repository
   - GitHub Actions not restricted by organization

### Azure Recursos
- **Azure Subscription**: Free tier acceptable
- **Resource Group**: `rg-workshop-cicd`
- **Service Principal**: For GitHub-Azure authentication

### VS Code Extensions
- GitHub Actions
- GitHub Copilot
- YAML
- Docker
- Azure Tools

## 🔧 ambiente Setup

### Step 1: Install GitHub CLI
```bash
# Windows (winget)
winget install --id GitHub.cli

# macOS
brew install gh

# Linux
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg &gt; /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list &gt; /dev/null
sudo apt update
sudo apt install gh
```

### Step 2: Authenticate GitHub CLI
```bash
gh auth login
gh auth status
```

### Step 3: Create Azure Service Principal
```bash
# Login to Azure
az login

# Create service principal
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/rg-workshop-cicd \
  --json-auth
```

### Step 4: Configure Repository Secrets
```bash
# Add Azure credentials
gh secret set AZURE_CREDENTIALS &lt; azure-creds.json

# Add other required secrets
gh secret set DOCKER_USERNAME
gh secret set DOCKER_PASSWORD
gh secret set SONAR_TOKEN  # Optional for code quality
```

### Step 5: Enable Required GitHub Features
1. Go to repository Configurações
2. Navigate to Actions → General
3. Enable:
   - Actions permissions: "Allow all actions"
   - Workflow permissions: "Read and write"
   - Allow GitHub Actions to create PRs

## 📁 Required Files from Anterior Módulos

Ensure you have these from Módulo 13:
- `infrastructure/main.bicep` or `infrastructure/main.tf`
- `.gitignore` properly configurado
- `README.md` with project documentation

## 🧪 Verification Script

Run this script to verify your ambiente:

```bash
#!/bin/bash
# save as verify-module14.sh

echo "🔍 Checking Module 14 Prerequisites..."

# Check tools
tools=("git" "docker" "python" "gh")
for tool in "${tools[@]}"; do
    if command -v $tool &&gt; /dev/null; then
        echo "✅ $tool is installed"
    else
        echo "❌ $tool is not installed"
        exit 1
    fi
done

# Check GitHub auth
if gh auth status &&gt; /dev/null; then
    echo "✅ GitHub CLI authenticated"
else
    echo "❌ GitHub CLI not authenticated"
    exit 1
fi

# Check Docker
if docker run hello-world &&gt; /dev/null; then
    echo "✅ Docker is running"
else
    echo "❌ Docker is not running"
    exit 1
fi

# Check Python version
python_version=$(python -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
if [[ $(echo "$python_version &gt;= 3.11" | bc) -eq 1 ]]; then
    echo "✅ Python version $python_version"
else
    echo "❌ Python version must be &gt;= 3.11"
    exit 1
fi

echo "✅ All prerequisites met!"
```

## 🎯 Pre-Módulo Verificarlist

Before starting the exercises:

- [ ] All tools instalado and versions verified
- [ ] GitHub conta with Copilot access
- [ ] Azure assinatura and service principal created
- [ ] Repository with Actions enabled
- [ ] Required secrets configurado
- [ ] Anterior module code available
- [ ] At least 2GB free disk space
- [ ] Stable internet connection

## 🆘 Troubleshooting

### Common Issues

1. **Actions not available**: Verificar organization settings
2. **Docker not running**: Start Docker Desktop
3. **Auth issues**: Regenerate PAT with correct scopes
4. **Azure errors**: Verify assinatura and permissions

### Getting Ajuda

- Módulo discussion forum
- GitHub Actions community
- Workshop Discord channel


## 🚀 Ready to Start?

Once all prerequisites are met, you're ready to begin creating powerful CI/CD pipelines with GitHub Actions!

**Próximo Step**: Comece com Exercício 1 - Build Your First Pipeline