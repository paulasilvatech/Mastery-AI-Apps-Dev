# Prerequisites for Module 14: CI/CD with GitHub Actions

## 📋 Required Knowledge

### From Previous Modules
You should have completed and understood:

- ✅ **Module 11**: Microservices Architecture
  - Service communication patterns
  - Container basics
  - Service discovery

- ✅ **Module 12**: Cloud-Native Development
  - Docker containerization
  - Kubernetes fundamentals
  - Serverless concepts

- ✅ **Module 13**: Infrastructure as Code
  - Terraform or Bicep basics
  - GitOps principles
  - Resource provisioning

### Programming Skills
- **Python**: Intermediate level (primary language)
- **YAML**: Configuration syntax
- **Bash/PowerShell**: Basic scripting
- **Git**: Branching, merging, PR workflows

## 🛠️ Required Tools & Accounts

### Local Development Environment
```bash
# Verify installations
git --version           # >= 2.38.0
docker --version        # >= 24.0.0
python --version        # >= 3.11.0
gh --version           # GitHub CLI >= 2.40.0
```

### GitHub Setup
1. **GitHub Account** with:
   - GitHub Copilot enabled
   - Actions enabled for your account
   - Personal Access Token (PAT) with appropriate scopes

2. **Repository Access**:
   - Ability to create repositories
   - Admin access to at least one repository
   - GitHub Actions not restricted by organization

### Azure Resources
- **Azure Subscription**: Free tier acceptable
- **Resource Group**: `rg-workshop-cicd`
- **Service Principal**: For GitHub-Azure authentication

### VS Code Extensions
- GitHub Actions
- GitHub Copilot
- YAML
- Docker
- Azure Tools

## 🔧 Environment Setup

### Step 1: Install GitHub CLI
```bash
# Windows (winget)
winget install --id GitHub.cli

# macOS
brew install gh

# Linux
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
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
gh secret set AZURE_CREDENTIALS < azure-creds.json

# Add other required secrets
gh secret set DOCKER_USERNAME
gh secret set DOCKER_PASSWORD
gh secret set SONAR_TOKEN  # Optional for code quality
```

### Step 5: Enable Required GitHub Features
1. Go to repository Settings
2. Navigate to Actions → General
3. Enable:
   - Actions permissions: "Allow all actions"
   - Workflow permissions: "Read and write"
   - Allow GitHub Actions to create PRs

## 📁 Required Files from Previous Modules

Ensure you have these from Module 13:
- `infrastructure/main.bicep` or `infrastructure/main.tf`
- `.gitignore` properly configured
- `README.md` with project documentation

## 🧪 Verification Script

Run this script to verify your environment:

```bash
#!/bin/bash
# save as verify-module14.sh

echo "🔍 Checking Module 14 Prerequisites..."

# Check tools
tools=("git" "docker" "python" "gh")
for tool in "${tools[@]}"; do
    if command -v $tool &> /dev/null; then
        echo "✅ $tool is installed"
    else
        echo "❌ $tool is not installed"
        exit 1
    fi
done

# Check GitHub auth
if gh auth status &> /dev/null; then
    echo "✅ GitHub CLI authenticated"
else
    echo "❌ GitHub CLI not authenticated"
    exit 1
fi

# Check Docker
if docker run hello-world &> /dev/null; then
    echo "✅ Docker is running"
else
    echo "❌ Docker is not running"
    exit 1
fi

# Check Python version
python_version=$(python -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
if [[ $(echo "$python_version >= 3.11" | bc) -eq 1 ]]; then
    echo "✅ Python version $python_version"
else
    echo "❌ Python version must be >= 3.11"
    exit 1
fi

echo "✅ All prerequisites met!"
```

## 🎯 Pre-Module Checklist

Before starting the exercises:

- [ ] All tools installed and versions verified
- [ ] GitHub account with Copilot access
- [ ] Azure subscription and service principal created
- [ ] Repository with Actions enabled
- [ ] Required secrets configured
- [ ] Previous module code available
- [ ] At least 2GB free disk space
- [ ] Stable internet connection

## 🆘 Troubleshooting

### Common Issues

1. **Actions not available**: Check organization settings
2. **Docker not running**: Start Docker Desktop
3. **Auth issues**: Regenerate PAT with correct scopes
4. **Azure errors**: Verify subscription and permissions

### Getting Help

- Module discussion forum
- GitHub Actions community
- Workshop Discord channel
- Office hours (Thursdays 2-3 PM UTC)

## 🚀 Ready to Start?

Once all prerequisites are met, you're ready to begin creating powerful CI/CD pipelines with GitHub Actions!

**Next Step**: Start with Exercise 1 - Build Your First Pipeline