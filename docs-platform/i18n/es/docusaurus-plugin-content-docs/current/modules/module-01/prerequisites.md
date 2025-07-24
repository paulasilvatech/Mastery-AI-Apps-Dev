---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 01"
---

# Módulo 01 Prerrequisitos

## 🎯 Resumen

This guide ensures you have everything needed to succeed in Módulo 01: Introducción to AI-Powered Development. Seguir each section carefully to set up your ambiente correctly.

## 🖥️ System Requirements

### Minimum Requirements
- **OS**: Windows 10/11, macOS 12+, or Ubuntu 20.04+
- **RAM**: 8GB (16GB recommended)
- **Storage**: 10GB free space
- **Internet**: Stable broadband connection

### Recommended Setup
- **RAM**: 16GB or more
- **Processor**: Multi-core (4+ cores)
- **Display**: 1920x1080 or higher
- **Internet**: 25+ Mbps

## 🛠️ Required Software

### 1. Visual Studio Code

Descargar and install VS Code from the official website:
- **Descargar**: [https://code.visualstudio.com/](https://code.visualstudio.com/)
- **Versión**: Latest stable release

**Installation Verification:**
```bash
code --version
```

Expected output:
```
1.85.0 (or higher)
f5442...
x64
```

### 2. GitHub Copilot Extension

Install the GitHub Copilot extension in VS Code:

1. Abrir VS Code
2. Press `Ctrl+Shift+X` (Windows/Linux) or `Cmd+Shift+X` (macOS)
3. Buscar for "GitHub Copilot"
4. Click Install on the official extension by GitHub
5. Restart VS Code

**Verification:**
- Look for the Copilot icon in the status bar (bottom right)
- It should show "GitHub Copilot" when hovering

### 3. Python Installation

Install Python 3.11 or higher:

**Windows:**
```powershell
# Using Windows installer from python.org
# Download from: https://www.python.org/downloads/

# Or using Chocolatey:
choco install python --version=3.11.0
```

**macOS:**
```bash
# Using Homebrew
brew install python@3.11

# Add to PATH if needed
echo 'export PATH="/opt/homebrew/opt/python@3.11/bin:$PATH"' &gt;&gt; ~/.zshrc
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install python3.11 python3.11-venv python3-pip
```

**Verification:**
```bash
python --version
# or
python3 --version
```

Expected: `Python 3.11.x` or higher

### 4. Git Installation

**Windows:**
```powershell
# Download Git for Windows from: https://git-scm.com/download/win
# Or using Chocolatey:
choco install git
```

**macOS:**
```bash
# Git comes with Xcode Command Line Tools
xcode-select --install

# Or using Homebrew:
brew install git
```

**Linux:**
```bash
sudo apt update
sudo apt install git
```

**Configuration:**
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

**Verification:**
```bash
git --version
```

Expected: `git version 2.38.0` or higher

## 🔑 cuenta Setup

### 1. GitHub cuenta

1. Create a GitHub cuenta at [https://github.com/signup](https://github.com/signup)
2. Verify your email address
3. Set up two-factor authentication (recommended)

### 2. GitHub Copilot suscripción

1. Sign in to GitHub
2. Go to [https://github.com/features/copilot](https://github.com/features/copilot)
3. Click "Start free trial" or "Subscribe"
4. Choose Individual ($10/month) or Business ($19/month)
5. Completar payment setup

**Note**: 30-day free trial available for new users

### 3. Authenticate VS Code with GitHub

1. Abrir VS Code
2. Click the cuentas icon (bottom left)
3. Select "Sign in to Sync Configuraciones"
4. Choose "Sign in with GitHub"
5. Completar authentication in browser
6. Return to VS Code

**Verification:**
```bash
gh auth status
```

If `gh` CLI is not instalado:
```bash
# Windows (Chocolatey)
choco install gh

# macOS (Homebrew)
brew install gh

# Linux
sudo apt install gh
```

## 📦 Módulo-Specific Setup

### 1. Create Working Directory

```bash
# Create a dedicated workspace
mkdir -p ~/copilot-workshop/module-01
cd ~/copilot-workshop/module-01
```

### 2. Install Python Dependencies

Create a virtual ambiente:
```bash
# Windows
python -m venv venv
.\venv\Scripts\activate

# macOS/Linux
python3 -m venv venv
source venv/bin/activate
```

Install required packages:
```bash
pip install --upgrade pip
pip install pytest black flake8 mypy requests click rich
```

### 3. VS Code Extensions

Install these additional extensions for the best experience:

1. **Python** by Microsoft
2. **Pylance** by Microsoft
3. **Python Indent** by Kevin Rose
4. **GitLens** by GitKraken
5. **Error Lens** by Alexander

Install via command:
```bash
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension KevinRose.vsc-python-indent
code --install-extension eamodio.gitlens
code --install-extension usernamehw.errorlens
```

## ✅ Validation Script

Run this script to verify your setup:

```python
#!/usr/bin/env python3
"""Module 01 Prerequisites Checker"""

import sys
import subprocess
import importlib

def check_python():
    """Check Python version."""
    version = sys.version_info
    if version.major == 3 and version.minor &gt;= 11:
        print("✅ Python 3.11+ installed")
        return True
    else:
        print(f"❌ Python {version.major}.{version.minor} found. Need 3.11+")
        return False

def check_git():
    """Check Git installation."""
    try:
        result = subprocess.run(['git', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ Git installed: {result.stdout.strip()}")
            return True
    except FileNotFoundError:
        pass
    print("❌ Git not found")
    return False

def check_vscode():
    """Check VS Code installation."""
    try:
        result = subprocess.run(['code', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            print("✅ VS Code installed")
            return True
    except FileNotFoundError:
        pass
    print("❌ VS Code not found")
    return False

def check_packages():
    """Check required Python packages."""
    packages = ['pytest', 'black', 'flake8', 'mypy', 'requests', 'click', 'rich']
    all_installed = True
    
    for package in packages:
        try:
            importlib.import_module(package)
            print(f"✅ {package} installed")
        except ImportError:
            print(f"❌ {package} not installed")
            all_installed = False
    
    return all_installed

def main():
    """Run all checks."""
    print("🔍 Module 01 Prerequisites Checker")
    print("=" * 40)
    
    checks = [
        check_python(),
        check_git(),
        check_vscode(),
        check_packages()
    ]
    
    print("=" * 40)
    
    if all(checks):
        print("✅ All prerequisites satisfied!")
        print("\n🎉 You're ready to start Module 01!")
        print("Next step: Open exercise1-easy/README.md")
    else:
        print("❌ Some prerequisites are missing.")
        print("Please install missing components and run again.")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

Guardar this as `check_prerequisites.py` and run:
```bash
python check_prerequisites.py
```

## 🆘 Common Issues

### Copilot Not Activating

1. Ensure you're signed into GitHub in VS Code
2. Verificar suscripción status at [https://github.com/settings/copilot](https://github.com/settings/copilot)
3. Restart VS Code
4. Verificar firewall/proxy settings

### Python Command Not Found

- **Windows**: Add Python to PATH during installation
- **macOS**: Use `python3` instead of `python`
- **Linux**: Create alias: `alias python=python3`

### Permission Errors

- **Windows**: Run as Administrator
- **macOS/Linux**: Use `sudo` for system-wide installs
- **Virtual Environment**: Always activate before installing packages

## 📚 Additional Recursos

1. [VS Code Python Tutorial](https://code.visualstudio.com/docs/python/python-tutorial)
2. [GitHub Copilot Comenzando](https://docs.github.com/copilot/getting-started)
3. [Python Virtual Environments Guía](https://realpython.com/python-virtual-ambientes-a-primer/)
4. [Git Basics](https://git-scm.com/book/en/v2/Getting-Started-Git-Basics)

## ✅ Ready to Start?

If all checks pass:
1. Navigate to the exercises folder
2. Abrir `exercise1-easy/README.md`
3. Seguir the step-by-step instructions
4. Start coding with AI!

---

**Need help?** Check the [troubleshooting guide](/docs/guias/troubleshooting) or ask in #module-01-setup