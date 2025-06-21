# Prerequisites for Mastery AI Apps and Development Workshop

## 🖥️ Hardware Requirements

### Minimum
- **CPU**: 4 cores (Intel i5/AMD Ryzen 5 or equivalent)
- **RAM**: 16GB
- **Storage**: 256GB SSD with 100GB free
- **Network**: Stable broadband (25+ Mbps)

### Recommended
- **CPU**: 8+ cores (Intel i7/AMD Ryzen 7 or better)
- **RAM**: 32GB
- **Storage**: 512GB SSD
- **Network**: High-speed connection (100+ Mbps)

## 💻 Software Requirements

### Operating System
- Windows 11 (version 22H2 or later)
- macOS 12 Monterey or later
- Ubuntu 20.04 LTS or later

### Development Tools
```bash
# Required versions
git >= 2.38.0
node >= 18.0.0
python >= 3.11.0
dotnet >= 8.0.0
docker >= 24.0.0
```

### IDE and Extensions
- **Visual Studio Code** (latest)
  - GitHub Copilot extension
  - Python extension
  - C# extension
  - Docker extension
  - Azure Tools extension pack

## 🔑 Accounts and Access

### Required Accounts
1. **GitHub Account**
   - GitHub Copilot subscription (individual or business)
   - Access to GitHub Models (preview)
   
2. **Azure Account**
   - Active subscription (free tier acceptable for most modules)
   - Resource providers registered:
     - Microsoft.CognitiveServices
     - Microsoft.ContainerService
     - Microsoft.Web

3. **Microsoft Account**
   - For Azure portal access
   - Microsoft Learn access

## 🛠️ Pre-Workshop Setup

### Step 1: Install Core Tools
```bash
# Windows (using Chocolatey)
choco install git nodejs python dotnet-sdk docker-desktop vscode azure-cli

# macOS (using Homebrew)
brew install git node python@3.11 dotnet docker visual-studio-code azure-cli

# Linux (Ubuntu/Debian)
sudo apt update
sudo apt install git nodejs python3.11 dotnet-sdk-8.0 docker.io code azure-cli
```

### Step 2: Configure Git
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Step 3: Verify Installations
Run the verification script:
```bash
./scripts/validate-prerequisites.sh
```

## 📋 Track-Specific Prerequisites

### Fundamentals Track (Modules 1-5)
- Basic programming knowledge (any language)
- Understanding of version control concepts

### Intermediate Track (Modules 6-10)
- Completed Fundamentals track
- Basic web development understanding
- Familiarity with databases

### Advanced Track (Modules 11-15)
- Completed Intermediate track
- Basic cloud computing concepts
- Understanding of distributed systems

### Enterprise Track (Modules 16-20)
- Completed Advanced track
- Exposure to production systems
- Basic security awareness

### AI Agents Track (Modules 21-25)
- Completed Enterprise track
- Understanding of async programming
- API development experience

### Enterprise Mastery Track (Modules 26-30)
- All previous tracks completed
- .NET development experience (for Module 26)
- Enterprise architecture concepts

## 🌐 Network Requirements

### Connectivity
- GitHub.com access
- Azure portal access
- NPM registry access
- Docker Hub access
- Microsoft Learn access

### Firewall Rules
Ensure the following domains are accessible:
- `*.github.com`
- `*.githubusercontent.com`
- `*.azurewebsites.net`
- `*.azure.com`
- `*.microsoft.com`
- `*.npmjs.org`
- `*.docker.com`

## 🔧 Optional but Recommended

### Additional Tools
- **GitHub CLI**: For enhanced GitHub integration
- **Azure CLI**: For cloud resource management
- **Postman/Insomnia**: For API testing
- **WSL2** (Windows): For better Linux compatibility

### VS Code Extensions
- GitLens
- Thunder Client
- Prettier
- ESLint
- Error Lens
- Todo Tree

## ✅ Quick Verification

Run this command to verify all prerequisites:
```bash
curl -fsSL https://raw.githubusercontent.com/paulasilvatech/Mastery-AI-Apps-Dev/main/scripts/validate-prerequisites.sh | bash
```

Or clone and run locally:
```bash
git clone https://github.com/paulasilvatech/Mastery-AI-Apps-Dev.git
cd Mastery-AI-Apps-Dev
./scripts/validate-prerequisites.sh
```

## 🆘 Troubleshooting

### Common Issues

1. **Python version conflicts**
   - Use `pyenv` (macOS/Linux) or `py` launcher (Windows)
   - Create isolated virtual environments

2. **Node version conflicts**
   - Use `nvm` (Node Version Manager)
   - Install multiple versions side-by-side

3. **Docker not starting**
   - Ensure virtualization is enabled in BIOS
   - Check WSL2 installation (Windows)
   - Verify sufficient disk space

4. **Permission issues**
   - Add user to docker group (Linux)
   - Run VS Code as administrator (Windows)
   - Check file permissions

## 📚 Additional Resources

- [GitHub Copilot Setup Guide](https://docs.github.com/copilot/getting-started)
- [Azure Free Account](https://azure.microsoft.com/free/)
- [VS Code Tips and Tricks](https://code.visualstudio.com/docs/getstarted/tips-and-tricks)
- [Docker Getting Started](https://docs.docker.com/get-started/)

---

**Ready to start?** Once you've verified all prerequisites, head to the [Quick Start Guide](QUICKSTART.md) to begin your AI development journey!

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>
