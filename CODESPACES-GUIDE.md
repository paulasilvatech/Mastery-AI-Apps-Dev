# GitHub Codespaces Guide

## 🚀 Quick Start with GitHub Codespaces

GitHub Codespaces provides a complete, pre-configured development environment in your browser. No local setup required!

## 📋 Overview

### What is GitHub Codespaces?
- Cloud-based development environment
- Full VS Code experience in your browser
- Pre-installed tools and extensions
- Automatic environment configuration
- Works on any device with a browser

### Why Use Codespaces for This Course?
- ✅ **Zero Setup Time**: Start coding in 2 minutes
- ✅ **Consistent Environment**: Everyone has the same setup
- ✅ **Pre-installed Tools**: All course requirements ready
- ✅ **Cost Effective**: 60 hours free per month
- ✅ **Access Anywhere**: Work from any device

## 🛠️ Getting Started

### Step 1: Fork the Repository

You must fork the entire repository (individual directories cannot be forked):

1. Go to the main course repository
2. Click the **Fork** button (top-right corner)
3. Select your GitHub account
4. Wait for the fork to complete

### Step 2: Create Your Codespace

1. In your forked repository, click the green **Code** button
2. Select the **Codespaces** tab
3. Click **Create codespace on main**
4. Choose machine type:
   - **2-core**: Basic exercises (default)
   - **4-core**: Better performance (recommended)
   - **8-core**: Heavy workloads

### Step 3: Wait for Setup

The first time takes 2-3 minutes to:
- Build the container
- Install all tools
- Configure extensions
- Set up the environment

## 📁 Repository Structure

Since you fork the entire repository, here's how to navigate:

```
your-fork/
├── modules/
│   ├── module-01/    # Start here for Module 1
│   ├── module-02/
│   ├── ...
│   ├── module-07/    # Web Applications
│   ├── ...
│   ├── module-13/    # Infrastructure as Code
│   └── module-30/
├── scripts/
├── templates/
└── README.md
```

### Working with Specific Modules

```bash
# Navigate to your module
cd modules/module-07  # For web applications
cd modules/module-13  # For infrastructure as code

# Start working
code .  # Opens in VS Code
```

## 💰 Managing Costs

### Free Tier Limits
- **Compute**: 60 hours/month
- **Storage**: 15 GB/month
- **Bandwidth**: Unlimited

### Cost-Saving Tips

1. **Stop Codespaces When Not in Use**
   ```bash
   # Via UI: Click "Stop codespace" in browser
   # Via CLI: gh codespace stop
   ```

2. **Delete Unused Codespaces**
   ```bash
   # List all codespaces
   gh codespace list
   
   # Delete specific codespace
   gh codespace delete -c CODESPACE-NAME
   ```

3. **Use Appropriate Machine Types**
   - 2-core for reading/light coding
   - 4-core for active development
   - 8-core only when needed

## 🔧 Pre-installed Tools

Your Codespace includes:

### Languages & Runtimes
- Node.js 18.x
- Python 3.11
- .NET 7.0
- Java 17
- Go 1.20

### Cloud Tools
- Azure CLI + Bicep
- AWS CLI
- Terraform
- Docker & Docker Compose
- Kubernetes tools (kubectl, helm)

### Development Tools
- Git
- GitHub CLI
- VS Code Server
- Multiple VS Code extensions

## 📝 Module-Specific Setup

### Module 7: Web Applications
```bash
cd modules/module-07
# All tools ready: React, FastAPI, Docker
./scripts/validate-module-07.sh
```

### Module 13: Infrastructure as Code
```bash
cd modules/module-13
# Azure CLI and Bicep pre-installed
az login --use-device-code
./scripts/check-prerequisites-script.sh
```

## 🌟 Best Practices

### 1. Branch Strategy
```bash
# Create a branch for each module
git checkout -b module07-work

# Or for specific exercises
git checkout -b module13-exercise1
```

### 2. Commit Frequently
```bash
# Save your work often
git add .
git commit -m "Complete exercise 1"
git push origin your-branch
```

### 3. Keep Fork Updated
```bash
# Add upstream remote (one time)
git remote add upstream https://github.com/original/repository.git

# Sync with upstream
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

## 🚨 Troubleshooting

### Common Issues

| Problem | Solution |
|---------|----------|
| Codespace won't start | Check GitHub status page |
| Slow performance | Upgrade to 4-core machine |
| Can't push changes | Check repository permissions |
| Extensions missing | Rebuild container |
| Terminal not working | Refresh browser |

### Rebuild Container
If something goes wrong:
1. Command Palette (Cmd/Ctrl + Shift + P)
2. Type "Codespaces: Rebuild Container"
3. Wait for rebuild

### Recovery Options
```bash
# Export your work
git stash
git stash save "backup before rebuild"

# After rebuild
git stash pop
```

## 🎯 Advanced Features

### Connect from Desktop VS Code
1. Install VS Code locally
2. Install "GitHub Codespaces" extension
3. Connect to your cloud codespace
4. Enjoy local performance with cloud environment

### Personalization
Create `.devcontainer/devcontainer.json` in your fork:
```json
{
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.fontSize": 14,
        "editor.fontSize": 14,
        "editor.theme": "GitHub Dark"
      }
    }
  }
}
```

### Secrets Management
For API keys and tokens:
1. Go to Settings → Codespaces
2. Add repository secrets
3. Access in codespace via environment variables

## 📊 Performance Optimization

### Prebuild Configuration
Speed up startup times:
1. Go to repository Settings
2. Select Codespaces → Prebuilds
3. Add prebuild configuration
4. Select branches to prebuild

### Resource Monitoring
```bash
# Check resource usage
df -h          # Disk space
free -m        # Memory
htop           # CPU and processes
```

## 🔗 Useful Commands

### Codespace Management
```bash
# List your codespaces
gh codespace list

# Connect via SSH
gh codespace ssh -c CODESPACE-NAME

# Port forwarding
gh codespace ports forward 8000:8000 -c CODESPACE-NAME

# View logs
gh codespace logs -c CODESPACE-NAME
```

### Environment Info
```bash
# Show codespace details
echo $CODESPACE_NAME
echo $GITHUB_USER
printenv | grep GITHUB
```

## 📚 Additional Resources

- [GitHub Codespaces Documentation](https://docs.github.com/codespaces)
- [VS Code in Codespaces](https://code.visualstudio.com/docs/remote/codespaces)
- [Codespaces Billing](https://docs.github.com/billing/managing-billing-for-github-codespaces)
- [Troubleshooting Guide](https://docs.github.com/codespaces/troubleshooting)

## 💡 Pro Tips

1. **Use keyboard shortcuts**: Same as desktop VS Code
2. **Multi-window support**: Open multiple browser tabs
3. **Share your codespace**: Collaborate in real-time
4. **Use the terminal**: Full Linux environment
5. **Install additional tools**: `sudo apt-get install ...`

---

**Remember**: Codespaces = No setup hassle + Start coding immediately! 🚀 