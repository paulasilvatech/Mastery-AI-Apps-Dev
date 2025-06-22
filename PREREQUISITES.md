# Prerequisites for Mastery AI Code Development Workshop

## 🖥️ Hardware Requirements

### Minimum Specifications
- **CPU**: 4 cores (Intel i5/AMD Ryzen 5 or equivalent)
- **RAM**: 16GB (8GB absolute minimum, but 16GB strongly recommended)
- **Storage**: 256GB SSD with 100GB free space
- **Network**: Stable broadband internet (25+ Mbps)
- **Display**: 1920x1080 or higher resolution

### Recommended Specifications
- **CPU**: 8+ cores (Intel i7/AMD Ryzen 7 or better)
- **RAM**: 32GB for optimal performance
- **Storage**: 512GB NVMe SSD with 200GB free space
- **Network**: High-speed connection (100+ Mbps)
- **Display**: Dual monitors (productivity boost)

### Why These Requirements?
- **16GB+ RAM**: VS Code + Docker + Azure services can be memory-intensive
- **SSD Storage**: Faster Docker builds and file operations
- **Fast CPU**: AI model inference and compilation tasks
- **Stable Internet**: Continuous GitHub Copilot and Azure connectivity

## 💻 Software Requirements

### Operating System Support
✅ **Windows 11** (version 22H2 or later)  
✅ **Windows 10** (version 21H2 or later)  
✅ **macOS 12 Monterey** or later  
✅ **Ubuntu 20.04 LTS** or later  
✅ **Other Linux distributions** (with manual adaptation)

### Core Development Tools

#### **Git (Required)**
```bash
# Minimum version: 2.38.0
git --version

# Installation:
# Windows: https://git-scm.com/download/win
# macOS: brew install git
# Linux: sudo apt install git
```

#### **Python (Required)**
```bash
# Required version: 3.11.0 or higher
python3 --version

# Installation:
# Windows: https://python.org/downloads
# macOS: brew install python@3.11
# Linux: sudo apt install python3.11 python3.11-venv python3.11-pip
```

#### **Node.js (Required)**
```bash
# Required version: 18.0.0 or higher
node --version

# Installation:
# Windows: https://nodejs.org/download
# macOS: brew install node
# Linux: curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
```

#### **Docker (Required)**
```bash
# Required version: 24.0.0 or higher
docker --version

# Installation:
# Windows/macOS: Docker Desktop
# Linux: sudo apt install docker.io docker-compose
```

#### **Azure CLI (Required)**
```bash
# Required version: 2.50.0 or higher
az --version

# Installation:
# Windows: winget install Microsoft.AzureCLI
# macOS: brew install azure-cli
# Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

#### **Visual Studio Code (Required)**
```bash
# Latest stable version recommended
code --version

# Installation:
# All platforms: https://code.visualstudio.com/download
```

### VS Code Extensions (Required)

Install these essential extensions:

```bash
# Install via VS Code Extensions marketplace or command line:
code --install-extension github.copilot
code --install-extension github.copilot-chat
code --install-extension ms-python.python
code --install-extension ms-vscode.azurecli
code --install-extension ms-azuretools.vscode-azurefunctions
code --install-extension ms-vscode.vscode-typescript-next
code --install-extension bradlc.vscode-tailwindcss
code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
```

**Critical Extensions:**
- **GitHub Copilot** - AI code completion (requires subscription)
- **GitHub Copilot Chat** - AI conversation interface
- **Python** - Python development support
- **Azure Tools** - Azure development and deployment

**Recommended Extensions:**
- **Docker** - Container management
- **Kubernetes** - K8s cluster management
- **Bicep** - Infrastructure as Code
- **REST Client** - API testing
- **GitLens** - Enhanced Git capabilities

## 🔑 Accounts and Access

### Required Accounts

#### **1. GitHub Account**
- **Personal or Organization account** with access to:
  - GitHub Copilot subscription (Individual $10/month or Business $19/month)
  - GitHub Models access (currently in beta)
  - GitHub Actions (included with account)
  - GitHub Advanced Security (for enterprise modules)

**Setup Steps:**
1. Create account at [github.com](https://github.com)
2. Subscribe to GitHub Copilot at [github.com/features/copilot](https://github.com/features/copilot)
3. Request GitHub Models access (if available)
4. Configure 2FA for security

#### **2. Microsoft Azure Account**
- **Active Azure subscription** with:
  - Contributor or Owner permissions
  - $200 Azure credits (free tier) or paid subscription
  - Access to create resources in supported regions

**Supported Regions:** East US 2, West US 2, West Europe, Southeast Asia

**Setup Steps:**
1. Create account at [azure.microsoft.com](https://azure.microsoft.com)
2. Activate $200 free credits (new accounts)
3. Register required resource providers:
```bash
az provider register --namespace Microsoft.CognitiveServices
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Web
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.OperationalInsights
```

#### **3. Microsoft Account (for Azure Portal)**
- Required for Azure portal access
- Can be same as GitHub account if using Microsoft email
- Enable multi-factor authentication

### Optional but Recommended

#### **GitHub CLI**
```bash
# Install GitHub CLI
# Windows: winget install GitHub.GitHubCLI
# macOS: brew install gh
# Linux: sudo apt install gh

# Authenticate
gh auth login
```

#### **Azure PowerShell** (Windows users)
```powershell
Install-Module -Name Az -Force -AllowClobber
```

## 🛠️ Development Environment Setup

### Pre-Workshop Validation

Run our validation script to check your setup:

```bash
# Clone the workshop repository
git clone https://github.com/paulasilvatech/Mastery-AI-Apps-Dev.git
cd Mastery-AI-Apps-Dev

# Make scripts executable (Linux/macOS)
chmod +x scripts/*.sh

# Run validation
./scripts/validate-prerequisites.sh
```

### Quick Setup (Automated)

If validation passes, run the complete setup:

```bash
# Automated setup (recommended)
./scripts/setup-workshop.sh

# Or manual quick start
./scripts/quick-start.sh
```

### Manual Setup Steps

If you prefer manual setup:

#### **1. Configure Git**
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global init.defaultBranch main
```

#### **2. Python Environment**
```bash
# Create virtual environment
python3 -m venv venv

# Activate (Windows)
venv\Scripts\activate

# Activate (macOS/Linux)
source venv/bin/activate

# Install base packages
pip install --upgrade pip
pip install requests azure-identity azure-keyvault-secrets
pip install fastapi uvicorn pandas numpy matplotlib
pip install pytest pytest-cov black flake8 mypy
```

#### **3. Node.js Environment**
```bash
# Initialize Node.js project
npm init -y

# Install TypeScript and tools
npm install -D typescript @types/node ts-node
npm install express axios dotenv
npm install -D @types/express
```

#### **4. Docker Setup**
```bash
# Verify Docker installation
docker run hello-world

# Pull common images
docker pull python:3.11-slim
docker pull node:18-alpine
docker pull nginx:alpine
```

#### **5. Azure Authentication**
```bash
# Login to Azure
az login

# Set default subscription (if you have multiple)
az account set --subscription "Your Subscription Name"

# Verify access
az account show
```

## 📋 Track-Specific Prerequisites

### **Fundamentals Track (Modules 1-5)**
**Minimum Requirements:**
- Git, Python 3.11+, VS Code with GitHub Copilot
- Basic programming knowledge in any language
- GitHub account with Copilot subscription

**Time Commitment:** 15 hours over 1-2 weeks

### **Intermediate Track (Modules 6-10)**
**Additional Requirements:**
- Node.js 18+, Docker
- Understanding of web development concepts
- Basic database knowledge

**Recommended:** Complete Fundamentals track first

### **Advanced Track (Modules 11-15)**
**Additional Requirements:**
- Azure CLI, kubectl
- Understanding of cloud computing concepts
- Basic networking knowledge
- Docker and containerization experience

**Recommended:** Complete Intermediate track first

### **Enterprise Track (Modules 16-20)**
**Additional Requirements:**
- Azure subscription with ability to create production resources
- Understanding of security principles
- Experience with production systems
- Knowledge of CI/CD concepts

**Recommended:** Complete Advanced track first

### **AI Agents Track (Modules 21-25)**
**Additional Requirements:**
- Advanced Python knowledge
- Understanding of async programming
- API development experience
- Familiarity with AI/ML concepts

**Recommended:** Complete Enterprise track first

### **Enterprise Mastery (Modules 26-28)**
**Additional Requirements:**
- .NET 8+ SDK (for Module 26)
- COBOL knowledge helpful (Module 27)
- Advanced security understanding (Module 28)

### **Mastery Validation (Modules 29-30)**
**Requirements:**
- Completion of previous tracks
- Portfolio of projects from earlier modules
- Ability to work independently on complex challenges

## 💰 Cost Considerations

### **Required Subscriptions**
- **GitHub Copilot**: $10/month (Individual) or $19/month (Business)
- **Azure**: Free tier available, or ~$50-100/month for full experience

### **Azure Cost Optimization**
- Use free tier resources when possible
- Clean up resources after each module
- Set up budget alerts
- Use dev/test pricing tiers
- Consider Azure for Students (if eligible)

### **Cost-Saving Tips**
```bash
# Always clean up after modules
./scripts/cleanup-resources.sh --module 12 --environment dev

# Use consumption-based services
# Choose smaller VM sizes for learning
# Delete resource groups when not needed
```

## 🔧 Troubleshooting Common Issues

### **GitHub Copilot Not Working**
```bash
# Check status
gh copilot status

# Re-authenticate
gh auth refresh -s copilot

# Restart VS Code
```

### **Azure CLI Issues**
```bash
# Clear cached credentials
az account clear

# Login again
az login

# Check subscription access
az account list
```

### **Python Environment Issues**
```bash
# Recreate virtual environment
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
```

### **Docker Issues**
```bash
# Restart Docker Desktop
# Check Docker daemon is running
docker info

# Clean up space
docker system prune -a
```

### **Permission Issues (Linux/macOS)**
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Fix Docker permissions (Linux)
sudo usermod -aG docker $USER
# Then logout and login again
```

## ✅ Validation Checklist

Before starting the workshop, ensure:

- [ ] All required software installed and at minimum versions
- [ ] GitHub account with active Copilot subscription
- [ ] Azure account with valid subscription
- [ ] VS Code with essential extensions installed
- [ ] Git configured with user name and email
- [ ] Python virtual environment created and working
- [ ] Docker running and functional
- [ ] Azure CLI authenticated
- [ ] Validation script passes all checks
- [ ] At least 100GB free disk space
- [ ] Stable internet connection tested

## 🚀 Ready to Start?

Once all prerequisites are met:

1. **Quick Start**: `./scripts/quick-start.sh` (5 minutes)
2. **Full Setup**: `./scripts/setup-workshop.sh` (15 minutes)
3. **Begin Learning**: Start with Module 1

## 🆘 Need Help?

- **Technical Issues**: Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **General Questions**: Read [FAQ.md](FAQ.md)
- **Community Support**: Visit [GitHub Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions)
- **Bug Reports**: File an [Issue](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/issues)

---

**Next Steps**: Once prerequisites are complete, start with [QUICKSTART.md](QUICKSTART.md) or dive into [Module 1](modules/module-01-introduction/README.md).
