---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 07"
---

# Prerequisites - Module 07: Building Web Applications with AI

## 🎯 Overview

This module requires specific tools and knowledge to complete successfully. Ensure you have everything set up before starting the 3-hour workshop.

## 📚 Required Knowledge

### Must Have
- ✅ **Basic JavaScript/React**: Components, state, props
- ✅ **Python Basics**: Functions, modules, basic syntax
- ✅ **HTML/CSS**: Basic styling and layout
- ✅ **Git Basics**: Clone, commit, push
- ✅ **API Concepts**: GET/POST requests, JSON

### Nice to Have
- 📘 TypeScript basics (we'll use JS primarily)
- 📘 Database concepts (CRUD operations)
- 📘 Command line comfort
- 📘 Previous Copilot experience

## 🛠️ Required Software

### 1. Node.js and npm
```bash
# Check version (need 18.x or higher)
node --version
npm --version

# Install via https://nodejs.org or:
# macOS
brew install node

# Windows
choco install nodejs

# Linux
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### 2. Python
```bash
# Check version (need 3.9 or higher)
python --version
# or
python3 --version

# Install via https://python.org or:
# macOS
brew install python@3.11

# Windows - download from python.org

# Linux
sudo apt update
sudo apt install python3.11 python3.11-venv python3-pip
```

### 3. Visual Studio Code
- Download from: https://code.visualstudio.com/
- Required extensions:
  ```bash
  # Install via command palette or:
  code --install-extension GitHub.copilot
  code --install-extension ms-python.python
  code --install-extension dbaeumer.vscode-eslint
  code --install-extension esbenp.prettier-vscode
  code --install-extension bradlc.vscode-tailwindcss
  ```

### 4. Git
```bash
# Check version
git --version

# Configure
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## 🔑 Required Accounts

### 1. GitHub Account with Copilot
- **GitHub Account**: https://github.com/signup
- **Copilot Subscription**: 
  - Individual: $10/month (30-day free trial)
  - Student: Free with GitHub Student Pack
  - Business: $19/month
- **Verify Access**: Open VS Code → Check status bar for "GitHub Copilot ✓"

### 2. OpenAI API (Exercise 3 only)
- Sign up: https://platform.openai.com/signup
- Get API key: https://platform.openai.com/api-keys
- **Free credits**: New accounts get $5 free credits
- **Cost estimate**: Exercise 3 uses ~$0.10 of credits

### 3. Cloudinary (Exercise 3 - Optional)
- Sign up: https://cloudinary.com/users/register/free
- Free tier: 25 credits/month (more than enough)
- Alternative: Can skip image upload feature

## 💻 System Requirements

### Minimum
- **OS**: Windows 10+, macOS 12+, Ubuntu 20.04+
- **RAM**: 8GB
- **Storage**: 5GB free space
- **Internet**: Stable connection (for API calls)

### Recommended
- **RAM**: 16GB (smoother development)
- **SSD**: Faster builds
- **Dual Monitor**: Easier to follow along

## ⚡ Quick Setup Script

Save and run this script to verify everything:

```bash
#!/bin/bash
# save as check-prerequisites.sh

echo "🔍 Checking Module 07 Prerequisites..."
echo ""

# Check Node.js
echo -n "Node.js: "
if command -v node &&gt; /dev/null; then
    node_version=$(node --version)
    echo "✅ $node_version"
else
    echo "❌ Not installed"
fi

# Check Python
echo -n "Python: "
if command -v python3 &&gt; /dev/null; then
    python_version=$(python3 --version)
    echo "✅ $python_version"
elif command -v python &&gt; /dev/null; then
    python_version=$(python --version)
    echo "✅ $python_version"
else
    echo "❌ Not installed"
fi

# Check Git
echo -n "Git: "
if command -v git &&gt; /dev/null; then
    git_version=$(git --version)
    echo "✅ $git_version"
else
    echo "❌ Not installed"
fi

# Check VS Code
echo -n "VS Code: "
if command -v code &&gt; /dev/null; then
    echo "✅ Installed"
else
    echo "⚠️  Not found in PATH (may still be installed)"
fi

# Check for GitHub Copilot extension
echo -n "GitHub Copilot: "
if code --list-extensions 2>/dev/null | grep -q "GitHub.copilot"; then
    echo "✅ Extension installed"
else
    echo "❌ Extension not installed"
fi

echo ""
echo "📋 Next Steps:"
echo "1. Ensure all items show ✅"
echo "2. Set up required accounts"
echo "3. Test GitHub Copilot in VS Code"
echo "4. Ready to start Module 07!"
```

## 🚀 Pre-Module Setup (5 minutes)

### 1. Create Working Directory
```bash
mkdir -p ~/workshops/module-07
cd ~/workshops/module-07
```

### 2. Test Copilot
Create a test file to ensure Copilot works:
```bash
# Create test.js
echo "// Create a function to reverse a string" &gt; test.js
code test.js
```
- Type the comment and press Enter
- Wait for Copilot suggestion
- Press Tab to accept

### 3. Install Global Tools
```bash
# Frontend tools
npm install -g create-vite

# Backend tools  
pip install --upgrade pip
```

### 4. Download Exercise Files (Optional)
```bash
# Clone workshop repository
git clone https://github.com/workshop/module-07-exercises.git
cd module-07-exercises
```

## ✅ Readiness Checklist

Before starting the module, verify:

- [ ] Node.js 18+ installed
- [ ] Python 3.9+ installed
- [ ] VS Code with GitHub Copilot working
- [ ] GitHub account with active Copilot subscription
- [ ] OpenAI API key (for Exercise 3)
- [ ] Stable internet connection
- [ ] 5GB free disk space
- [ ] Excitement to build with AI! 🚀

## 🆘 Troubleshooting Setup

### Copilot Not Working?
1. Sign out and back in:
   - Cmd/Ctrl + Shift + P → "GitHub Copilot: Sign Out"
   - Then "GitHub Copilot: Sign In"
2. Check subscription at https://github.com/settings/copilot
3. Restart VS Code

### Python Command Issues?
```bash
# Try python3 instead of python
python3 --version

# Create alias (add to ~/.bashrc or ~/.zshrc)
alias python=python3
alias pip=pip3
```

### Permission Errors?
```bash
# npm permission fix
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' &gt;&gt; ~/.bashrc
source ~/.bashrc

# pip permission fix
pip install --user package-name
```

### Corporate Firewall?
- May need to configure proxy settings
- Some companies block GitHub Copilot
- Check with IT for exceptions

## 📞 Getting Help

If you encounter setup issues:

1. **Workshop Forums**: Post in #module-07-help
2. **Documentation**: 
   - Node.js: https://nodejs.org/docs
   - Python: https://docs.python.org/3/
   - VS Code: https://code.visualstudio.com/docs
3. **Community**:
   - Stack Overflow with tags: `node.js`, `python`, `github-copilot`
   - GitHub Copilot Community: https://github.com/community/community

## 🎯 Ready to Start?

Once everything is checked off:
1. Open VS Code
2. Create a new folder for the module
3. Start with Exercise 1: Rapid Todo App
4. Let GitHub Copilot accelerate your coding!

**Time Investment**: 3 hours of focused learning
**Outcome**: Three working full-stack applications with AI features

Let's build something amazing! 🚀