# Module 13: Infrastructure as Code - Prerequisites

## 📋 Required Knowledge

Before starting this module, you should have:

### From Previous Modules
- ✅ **Module 11**: Understanding of microservices architecture
- ✅ **Module 12**: Experience with containers and cloud-native concepts
- ✅ **Module 14**: Basic CI/CD knowledge (can be done concurrently)

### Technical Skills
- 🐍 **Python**: Intermediate level (for automation scripts)
- ☁️ **Azure Fundamentals**: Resource groups, subscriptions, basic services
- 🔧 **Command Line**: Comfortable with bash/PowerShell
- 📝 **YAML/JSON**: Understanding of configuration formats
- 🌿 **Git**: Branching, merging, pull requests

## 💻 Required Software

### Core Tools
```bash
# Azure CLI (latest version)
az --version  # Should be 2.55.0 or higher

# Terraform
terraform --version  # Should be 1.6.0 or higher

# Azure Bicep
az bicep version  # Should be 0.24.0 or higher

# GitHub CLI (optional but recommended)
gh --version  # Should be 2.40.0 or higher
```

### VS Code Extensions
Ensure these extensions are installed and updated:
- **Bicep**: Official Bicep language support
- **HashiCorp Terraform**: Terraform language support
- **Azure Resource Manager Tools**: ARM template support
- **GitHub Copilot**: AI assistance (required)
- **GitHub Actions**: Workflow authoring support

### Installation Commands

#### Windows (PowerShell as Administrator)
```powershell
# Install Chocolatey if not present
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install required tools
choco install azure-cli terraform gh -y

# Install Bicep
az bicep install
```

#### macOS
```bash
# Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install azure-cli terraform gh

# Install Bicep
az bicep install
```

#### Linux (Ubuntu/Debian)
```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install terraform

# GitHub CLI
type -p curl >/dev/null || sudo apt install curl -y
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
    https://cli.github.com/packages stable main" | \
    sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

sudo apt update && sudo apt install gh

# Install Bicep
az bicep install
```

## 🔑 Required Access

### Azure Subscription
- **Active Azure Subscription**: Free tier is sufficient
- **Permissions**: Contributor role on resource group
- **Resource Providers**: Ensure these are registered:
  ```bash
  az provider register --namespace Microsoft.Web
  az provider register --namespace Microsoft.Storage
  az provider register --namespace Microsoft.Sql
  az provider register --namespace Microsoft.Network
  az provider register --namespace Microsoft.KeyVault
  ```

### GitHub Account
- **GitHub Account**: With Copilot access enabled
- **Repository Access**: Ability to create repos and workflows
- **GitHub Actions**: Should be enabled (default for public repos)

### Service Principal (for automation)
Create a service principal for GitHub Actions:
```bash
# Create service principal
az ad sp create-for-rbac --name "GitHub-Actions-IaC" \
    --role contributor \
    --scopes /subscriptions/{subscription-id} \
    --sdk-auth > github-actions-creds.json

# Save the output securely - you'll need it for GitHub secrets
```

## 📁 Module Structure

Ensure you have the following directory structure:
```
module-13-infrastructure-as-code/
├── README.md
├── prerequisites.md
├── best-practices.md
├── troubleshooting.md
├── exercises/
│   ├── exercise1-bicep-basics/
│   ├── exercise2-terraform-environments/
│   └── exercise3-gitops-pipeline/
├── scripts/
│   ├── check-prerequisites.sh
│   ├── setup-module.sh
│   └── cleanup-resources.sh
├── infrastructure/
│   ├── bicep/
│   ├── terraform/
│   └── github-actions/
└── docs/
    ├── concepts.md
    └── architecture.md
```

## 🔍 Verification Script

Run this script to verify all prerequisites:

```bash
#!/bin/bash
# Save as scripts/check-prerequisites.sh

echo "🔍 Checking Module 13 Prerequisites..."
echo "===================================="

# Function to check command
check_command() {
    if command -v $1 &> /dev/null; then
        echo "✅ $1 is installed: $($1 --version 2>&1 | head -n1)"
        return 0
    else
        echo "❌ $1 is not installed"
        return 1
    fi
}

# Function to check VS Code extension
check_vscode_ext() {
    if code --list-extensions | grep -q "$1"; then
        echo "✅ VS Code extension '$2' is installed"
    else
        echo "❌ VS Code extension '$2' is not installed"
    fi
}

# Check required commands
MISSING=0
check_command "az" || ((MISSING++))
check_command "terraform" || ((MISSING++))
check_command "git" || ((MISSING++))
check_command "code" || ((MISSING++))

# Check Bicep
if az bicep version &> /dev/null; then
    echo "✅ Bicep is installed: $(az bicep version)"
else
    echo "❌ Bicep is not installed"
    ((MISSING++))
fi

# Check Azure login
if az account show &> /dev/null; then
    echo "✅ Logged into Azure"
else
    echo "❌ Not logged into Azure (run 'az login')"
    ((MISSING++))
fi

# Check VS Code extensions
echo -e "\n📦 Checking VS Code Extensions..."
check_vscode_ext "ms-azuretools.vscode-bicep" "Bicep"
check_vscode_ext "hashicorp.terraform" "Terraform"
check_vscode_ext "github.copilot" "GitHub Copilot"

# Summary
echo -e "\n📊 Summary"
echo "=========="
if [ $MISSING -eq 0 ]; then
    echo "✅ All prerequisites met! You're ready to start Module 13."
else
    echo "❌ Missing $MISSING prerequisites. Please install them before continuing."
    exit 1
fi
```

## 🚀 Quick Setup

If you're missing any prerequisites, run:
```bash
./scripts/setup-module.sh
```

This script will attempt to install missing components and configure your environment.

## 💡 Recommended Preparation

Before starting the exercises:

1. **Review Azure Resource Manager concepts**
   - [Azure Resource Manager overview](https://learn.microsoft.com/azure/azure-resource-manager/management/overview)

2. **Familiarize yourself with declarative syntax**
   - Think about infrastructure as configuration, not scripts

3. **Understand state management**
   - Why state matters in IaC
   - How Terraform and Bicep handle state differently

4. **Practice with GitHub Actions**
   - Review basic workflow syntax if unfamiliar

## ⚠️ Common Issues

### Azure CLI not found
- Ensure you've restarted your terminal after installation
- Add Azure CLI to your PATH if needed

### Bicep installation fails
- Update Azure CLI first: `az upgrade`
- Try manual installation from [Bicep releases](https://github.com/Azure/bicep/releases)

### Terraform version conflicts
- Use tfenv for version management
- Ensure you're using a compatible provider version

## 🎯 Ready Check

You're ready for Module 13 when:
- [ ] All software is installed and verified
- [ ] You can run `az`, `terraform`, and `bicep` commands
- [ ] You're logged into Azure CLI
- [ ] VS Code has all required extensions
- [ ] You understand basic IaC concepts

**Next Step**: Once prerequisites are met, start with [Exercise 1: Bicep Basics](./exercises/exercise1-bicep-basics/)

## 🚀 GitHub Codespaces (Recommended)

The fastest way to get started with Infrastructure as Code is using GitHub Codespaces, which provides a pre-configured cloud development environment.

### Option 1: Using GitHub Codespaces

1. **Fork the Repository**
   - Navigate to the main course repository
   - Click the "Fork" button (top-right corner)
   - This creates a complete copy in your GitHub account
   - Note: You cannot fork individual directories, only entire repositories

2. **Create a Codespace**
   - In your forked repository, click the green "Code" button
   - Select the "Codespaces" tab
   - Click "Create codespace on main"
   - Choose machine type: **4-core** (recommended for better performance)
   - Wait 2-3 minutes for setup

3. **Navigate to Module 13**
   ```bash
   cd modules/module-13
   ```

4. **Pre-installed Tools** ✅
   - Azure CLI with Bicep
   - GitHub CLI
   - Terraform
   - VS Code with all extensions
   - Docker
   - Python & Node.js

### Option 2: Local Development

If you prefer local development or need to work offline:

## 📋 System Requirements

- **Operating System**: Windows 10/11, macOS 10.15+, Linux (Ubuntu 20.04+)
- **RAM**: 4GB minimum (8GB recommended)
- **Disk Space**: 5GB free
- **Internet**: Required for Azure operations

## 🛠️ Required Software

### 1. Azure CLI (includes Bicep)
```bash
# Windows (winget)
winget install Microsoft.AzureCLI

# macOS
brew update && brew install azure-cli

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verify
az --version
az bicep version
```

### 2. GitHub CLI
```bash
# Installation varies by platform
# See: https://cli.github.com/

# Verify
gh --version
```

### 3. Visual Studio Code
Download from [code.visualstudio.com](https://code.visualstudio.com/)

Required extensions:
- Azure Bicep
- GitHub Actions
- YAML
- Azure Account

### 4. Git
```bash
git --version  # Should be 2.x or higher
```

## 🔑 Account Requirements

### GitHub Account
- Free account is sufficient
- Enable GitHub Actions in your fork
- Personal Access Token (for GitHub CLI)

### Azure Account
- Free tier works for all exercises
- Student accounts get $100 credit
- Create at [azure.microsoft.com/free](https://azure.microsoft.com/free)

## ⚡ Quick Start with Codespaces

### First Time Setup

1. **Fork & Create Codespace**
   ```bash
   # After forking, create codespace as described above
   # All tools are pre-installed!
   ```

2. **Configure Azure**
   ```bash
   # Login to Azure
   az login --use-device-code
   
   # Set subscription (if you have multiple)
   az account list --output table
   az account set --subscription "YOUR-SUBSCRIPTION-NAME"
   ```

3. **Configure GitHub**
   ```bash
   # Should already be authenticated in Codespaces
   gh auth status
   ```

4. **Validate Setup**
   ```bash
   cd modules/module-13
   ./scripts/check-prerequisites-script.sh
   ```

## 💰 Cost Management

### GitHub Codespaces
- **Free tier**: 60 hours/month
- **Storage**: 15 GB/month free
- **Tips**:
  - Stop codespaces when not in use
  - Delete old codespaces
  - Use 2-core machines when possible

### Azure Resources
- **Free tier**: $200 credit for 30 days
- **Exercise costs**: < $5 total if cleaned up
- **Important**: Always run cleanup scripts!

## 🏃‍♂️ Workflow in Codespaces

### Development Flow
```bash
# 1. Create feature branch
git checkout -b module13-exercise1

# 2. Work on exercises
cd exercises/exercise1-bicep-basics
code starter/main.bicep

# 3. Test deployments
./scripts/deploy.sh

# 4. Commit and push
git add .
git commit -m "Complete exercise 1"
git push origin module13-exercise1

# 5. Clean up Azure resources
./scripts/cleanup.sh
```

### Working with Your Fork
- Your fork contains the entire course
- Focus only on `modules/module-13/`
- Create PRs to your own fork for practice
- Keep your fork synced with upstream

## 🔧 Codespaces Configuration

### Recommended Settings
```json
{
  "github.codespaces.defaultMachineType": "standardLinux32gb",
  "terminal.integrated.defaultProfile.linux": "bash",
  "files.autoSave": "afterDelay",
  "editor.formatOnSave": true
}
```

### Prebuild Configuration
For faster startup, enable prebuilds:
1. Go to repository settings
2. Navigate to Codespaces
3. Enable prebuilds for main branch

## 🐛 Troubleshooting

### Codespaces Issues
| Problem | Solution |
|---------|----------|
| Won't start | Check quota/billing |
| Slow performance | Upgrade machine type |
| Extensions missing | Rebuild container |
| Can't push code | Check repository permissions |

### Azure Issues
| Problem | Solution |
|---------|----------|
| Login fails | Use `--use-device-code` flag |
| No subscription | Check free tier activation |
| Deployment fails | Verify region availability |
| Permission denied | Check RBAC assignments |

## 📚 Pre-Module Learning

### Required Knowledge
- ✅ Basic cloud concepts
- ✅ Git version control
- ✅ YAML syntax basics
- ✅ Command line comfort

### Helpful Resources
- [Azure Fundamentals](https://learn.microsoft.com/training/paths/azure-fundamentals/)
- [Introduction to Bicep](https://learn.microsoft.com/training/modules/introduction-to-infrastructure-as-code-using-bicep/)
- [GitHub Actions Basics](https://docs.github.com/actions/learn-github-actions)

## ✅ Validation Checklist

Before starting exercises, ensure:

- [ ] Codespace is running (or local setup complete)
- [ ] Azure CLI logged in
- [ ] Bicep CLI installed
- [ ] GitHub authenticated
- [ ] Validation script passes
- [ ] You understand the fork workflow

## 🎯 Ready to Start?

Once setup is complete:

1. Read the [Module Overview](README.md)
2. Start with [Exercise 1](exercises/exercise1-bicep-basics/README.md)
3. Use Copilot to accelerate your learning!

---

💡 **Pro Tip**: Codespaces is the fastest way to start. You'll be coding in under 5 minutes!
