# Module 13 - Comprehensive Prerequisites & Setup Guide

## 🎯 Overview

This guide ensures you have everything needed to successfully complete Module 13's Infrastructure as Code exercises using both GitHub Copilot approaches.

## 🖥️ System Requirements

### Hardware Requirements

| Component | Minimum | Recommended | Optimal |
|-----------|---------|-------------|---------|
| **CPU** | 4 cores | 8 cores | 16+ cores |
| **RAM** | 8GB | 16GB | 32GB |
| **Storage** | 50GB free | 100GB free | 250GB SSD |
| **Network** | 10 Mbps | 50 Mbps | 100+ Mbps |

### Operating System Support

- ✅ **Windows**: Windows 10/11 (version 1909+)
- ✅ **macOS**: macOS 11 Big Sur or later
- ✅ **Linux**: Ubuntu 20.04+, Fedora 34+, or equivalent

## 🛠️ Required Software

### Core Development Tools

```markdown
# Copilot Agent Prompt:
Create a comprehensive tool installation script that:

1. Detects the operating system
2. Installs all required tools:
   - Git (2.38+)
   - VS Code (latest)
   - Python (3.11+)
   - Node.js (18+)
   - Docker Desktop
   
3. Configures VS Code extensions:
   - GitHub Copilot
   - GitHub Copilot Chat
   - Azure Tools
   - Terraform
   - Bicep
   - GitLens
   
4. Validates installations
5. Sets up development environment

Make it idempotent and handle errors gracefully.
```

### Azure Tools Installation

#### Windows (PowerShell as Administrator)
```powershell
# Install Chocolatey if not present
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Azure tools
choco install azure-cli -y
choco install bicep -y
choco install terraform -y
choco install git -y
choco install vscode -y
choco install python311 -y
choco install nodejs-lts -y

# Install VS Code extensions
code --install-extension GitHub.copilot
code --install-extension GitHub.copilot-chat
code --install-extension ms-azuretools.vscode-azuretools
code --install-extension hashicorp.terraform
code --install-extension ms-azuretools.vscode-bicep
```

#### macOS (Terminal)
```bash
# Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Azure tools
brew install azure-cli
brew install bicep
brew install terraform
brew install git
brew install --cask visual-studio-code
brew install python@3.11
brew install node@18

# Install VS Code extensions
code --install-extension GitHub.copilot
code --install-extension GitHub.copilot-chat
code --install-extension ms-azuretools.vscode-azuretools
code --install-extension hashicorp.terraform
code --install-extension ms-azuretools.vscode-bicep
```

#### Linux (Ubuntu/Debian)
```bash
# Update package manager
sudo apt update && sudo apt upgrade -y

# Install prerequisites
sudo apt install -y curl apt-transport-https lsb-release gnupg

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Install Bicep
curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
chmod +x ./bicep
sudo mv ./bicep /usr/local/bin/bicep

# Install other tools
sudo apt install -y git python3.11 nodejs npm code
```

## 🔑 Account Requirements

### GitHub Account Setup

1. **GitHub Account**
   - Sign up at [github.com](https://github.com) if needed
   - Enable two-factor authentication (required for Copilot)
   
2. **GitHub Copilot Subscription**
   - Individual: $10/month or $100/year
   - Business: $19/user/month
   - Free trial available (30 days)
   - Students/teachers: Free via GitHub Education

3. **Repository Access**
   - Fork the workshop repository
   - Enable GitHub Actions
   - Configure repository secrets

### Azure Account Setup

1. **Azure Subscription**
   - Free account: $200 credit for 30 days
   - Pay-as-you-go: Best for learning
   - Visual Studio subscription: Includes monthly credits
   - Student account: $100 credit

2. **Required Permissions**
   - Contributor role at subscription level
   - User Access Administrator (for RBAC exercises)
   - Key Vault Administrator (for secret management)

3. **Resource Providers**
   ```bash
   # Register required providers
   az provider register --namespace Microsoft.Web
   az provider register --namespace Microsoft.Storage
   az provider register --namespace Microsoft.KeyVault
   az provider register --namespace Microsoft.Network
   az provider register --namespace Microsoft.Compute
   az provider register --namespace Microsoft.ContainerService
   az provider register --namespace Microsoft.OperationalInsights
   az provider register --namespace Microsoft.Insights
   ```

## 🚀 Environment Setup

### Step 1: Clone Workshop Repository

```bash
# Clone the repository
git clone https://github.com/your-org/mastery-ai-workshop.git
cd mastery-ai-workshop/modules/module-13

# Create your working branch
git checkout -b module-13-work
```

### Step 2: Azure Authentication

```bash
# Login to Azure
az login

# Set default subscription
az account list --output table
az account set --subscription "Your Subscription Name"

# Verify subscription
az account show --output table
```

### Step 3: Create Service Principal

```markdown
# Copilot Agent Prompt:
Create a script that:

1. Creates an Azure Service Principal with:
   - Contributor access to subscription
   - Key Vault access policies
   - Unique naming with timestamp
   
2. Stores credentials securely:
   - In GitHub repository secrets
   - In local .env file (git-ignored)
   - In Azure Key Vault
   
3. Validates the service principal:
   - Test authentication
   - Verify permissions
   - Check resource access

Include cleanup instructions.
```

### Step 4: Configure GitHub Repository

```bash
# Set up GitHub CLI
gh auth login

# Configure repository secrets
gh secret set AZURE_SUBSCRIPTION_ID --body "your-subscription-id"
gh secret set AZURE_TENANT_ID --body "your-tenant-id"
gh secret set AZURE_CLIENT_ID --body "your-client-id"
gh secret set AZURE_CLIENT_SECRET --body "your-client-secret"

# Enable GitHub Actions
gh repo edit --enable-actions

# Set up environments
gh api repos/:owner/:repo/environments -X PUT -f name=development
gh api repos/:owner/:repo/environments -X PUT -f name=staging
gh api repos/:owner/:repo/environments -X PUT -f name=production
```

### Step 5: Initialize Infrastructure Backend

```bash
# Create resource group for Terraform state
az group create --name rg-terraform-state --location eastus2

# Create storage account for state
STORAGE_ACCOUNT="tfstate$RANDOM"
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group rg-terraform-state \
  --location eastus2 \
  --sku Standard_LRS

# Create container
az storage container create \
  --name tfstate \
  --account-name $STORAGE_ACCOUNT

# Get storage key
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group rg-terraform-state \
  --account-name $STORAGE_ACCOUNT \
  --query '[0].value' -o tsv)

# Save configuration
echo "STORAGE_ACCOUNT=$STORAGE_ACCOUNT" >> .env
echo "ACCOUNT_KEY=$ACCOUNT_KEY" >> .env
```

## 🧪 Validation Script

Create `validate-prerequisites.sh`:

```bash
#!/bin/bash
# Complete prerequisites validation script

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔍 Validating Module 13 Prerequisites..."
echo "========================================"

# Function to check command
check_command() {
    if command -v $1 &> /dev/null; then
        version=$($2)
        echo -e "${GREEN}✓${NC} $1: $version"
        return 0
    else
        echo -e "${RED}✗${NC} $1: Not installed"
        return 1
    fi
}

# Function to check VS Code extension
check_vscode_extension() {
    if code --list-extensions | grep -q $1; then
        echo -e "${GREEN}✓${NC} VS Code Extension: $1"
        return 0
    else
        echo -e "${YELLOW}!${NC} VS Code Extension: $1 (Not installed)"
        return 1
    fi
}

# Check tools
echo -e "\n📦 Checking Required Tools:"
check_command "git" "git --version"
check_command "az" "az --version | head -n 1"
check_command "terraform" "terraform --version | head -n 1"
check_command "bicep" "bicep --version"
check_command "docker" "docker --version"
check_command "python3" "python3 --version"
check_command "node" "node --version"
check_command "code" "code --version | head -n 1"

# Check VS Code extensions
echo -e "\n🔌 Checking VS Code Extensions:"
check_vscode_extension "GitHub.copilot"
check_vscode_extension "GitHub.copilot-chat"
check_vscode_extension "ms-azuretools.vscode-azuretools"
check_vscode_extension "hashicorp.terraform"
check_vscode_extension "ms-azuretools.vscode-bicep"

# Check Azure login
echo -e "\n☁️ Checking Azure Configuration:"
if az account show &> /dev/null; then
    SUBSCRIPTION=$(az account show --query name -o tsv)
    echo -e "${GREEN}✓${NC} Azure CLI: Logged in to '$SUBSCRIPTION'"
else
    echo -e "${RED}✗${NC} Azure CLI: Not logged in"
fi

# Check GitHub CLI
echo -e "\n🐙 Checking GitHub Configuration:"
if gh auth status &> /dev/null; then
    echo -e "${GREEN}✓${NC} GitHub CLI: Authenticated"
else
    echo -e "${YELLOW}!${NC} GitHub CLI: Not authenticated"
fi

# Check Python packages
echo -e "\n🐍 Checking Python Packages:"
python3 -m pip list | grep -E "azure-cli|terraform|checkov" || echo -e "${YELLOW}!${NC} Some Python packages may be missing"

# Summary
echo -e "\n📊 Summary:"
echo "If any items show ✗ or !, please install them before proceeding."
echo "Run the setup script to install missing components."
```

## 🎯 Exercise-Specific Prerequisites

### Exercise 1 (Bicep) Additional Requirements
- Azure Bicep extension for VS Code
- Azure Resource Manager Tools extension
- Understanding of ARM template concepts

### Exercise 2 (Terraform) Additional Requirements
- Terraform 1.6+ (not just 1.0+)
- Understanding of HCL syntax
- HashiCorp account (optional, for Terraform Cloud)

### Exercise 3 (GitOps) Additional Requirements
- GitHub Actions experience helpful
- Understanding of CI/CD concepts
- YAML familiarity

## 🆘 Troubleshooting Common Setup Issues

### Issue: "GitHub Copilot not working"
```bash
# Solution 1: Re-authenticate
code --list-extensions | grep copilot
# Restart VS Code
# Sign out and back into GitHub

# Solution 2: Check subscription
# Visit: https://github.com/settings/copilot
```

### Issue: "Azure CLI login fails"
```bash
# Solution 1: Clear cache
az account clear
az login --use-device-code

# Solution 2: Update Azure CLI
az upgrade
```

### Issue: "Terraform init fails"
```bash
# Solution 1: Clear cache
rm -rf .terraform
terraform init -upgrade

# Solution 2: Check backend access
az storage account show --name $STORAGE_ACCOUNT
```

## 📚 Additional Learning Resources

### Pre-Module Learning
1. **Azure Fundamentals**: [Microsoft Learn AZ-900](https://learn.microsoft.com/training/paths/azure-fundamentals/)
2. **Git Basics**: [GitHub Skills](https://skills.github.com/)
3. **IaC Concepts**: [HashiCorp Learn](https://learn.hashicorp.com/)

### Recommended Reading
- "Infrastructure as Code" by Kief Morris
- "The Phoenix Project" (DevOps culture)
- Azure Architecture Framework documentation

## ✅ Pre-Module Checklist

Before starting Module 13, ensure:

- [ ] All tools installed and versions verified
- [ ] Azure subscription active with credits
- [ ] GitHub Copilot subscription active
- [ ] VS Code configured with extensions
- [ ] Repository cloned and branch created
- [ ] Azure CLI authenticated
- [ ] Service principal created
- [ ] Backend storage configured
- [ ] Validation script passes all checks
- [ ] Completed Module 1-12 (or have equivalent knowledge)

## 🚀 Ready to Start?

Once all prerequisites are met:
1. Open VS Code in the module directory
2. Review the exercise overviews
3. Start with Exercise 1 (Bicep)
4. Use both Copilot approaches as you learn

**Pro Tip**: Keep this guide open in a browser tab for quick reference during the exercises!

---

**Need Help?** Check the [Module 13 Troubleshooting Guide](./troubleshooting.md) or post in the workshop discussions.