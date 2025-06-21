# Module 07 Prerequisites

## 🔧 Required Software

### Development Environment
```bash
# Check versions
node --version          # >= 18.0.0
python --version        # >= 3.11.0
docker --version        # >= 24.0.0
git --version          # >= 2.38.0
```

### VS Code Extensions
Ensure these extensions are installed and configured:
- ✅ GitHub Copilot
- ✅ GitHub Copilot Chat
- ✅ Python
- ✅ Pylance
- ✅ ES7+ React/Redux/React-Native snippets
- ✅ Tailwind CSS IntelliSense
- ✅ Thunder Client (API testing)

## 📦 Package Installation

### Backend Dependencies
```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows
.\venv\Scripts\activate
# macOS/Linux
source venv/bin/activate

# Install required packages
pip install fastapi==0.104.1
pip install uvicorn[standard]==0.24.0
pip install sqlalchemy==2.0.23
pip install alembic==1.12.1
pip install python-jose[cryptography]==3.3.0
pip install passlib[bcrypt]==1.7.4
pip install python-multipart==0.0.6
pip install pydantic==2.5.0
pip install pydantic-settings==2.1.0
pip install aiofiles==23.2.1
```

### Frontend Dependencies
```bash
# Install Node.js packages globally
npm install -g create-vite@latest
npm install -g typescript@latest
```

## 🔑 Account Requirements

### GitHub
- Active GitHub account
- GitHub Copilot subscription (Individual or Business)
- Personal access token with repo scope

### Azure (for deployment - Exercise 3)
- Azure account with active subscription
- Azure CLI installed and configured
```bash
# Install Azure CLI
# Windows
winget install Microsoft.AzureCLI
# macOS
brew install azure-cli
# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login
az login
```

## 📚 Knowledge Prerequisites

### Required Knowledge
- ✅ Basic HTML/CSS understanding
- ✅ JavaScript fundamentals (ES6+)
- ✅ Python basics (functions, classes, async)
- ✅ REST API concepts
- ✅ Basic SQL knowledge
- ✅ Git version control

### Helpful but Not Required
- React basics (will be guided)
- TypeScript familiarity
- Docker basics
- Cloud deployment experience

## 🛠️ Environment Setup

### 1. Project Directory Structure
```bash
# Create module workspace
mkdir module-07-workspace
cd module-07-workspace

# Clone module materials (if not already done)
git clone https://github.com/your-org/mastery-ai-workshop.git
cd mastery-ai-workshop/modules/module-07-web-applications
```

### 2. Database Setup
```bash
# Install SQLite (if not present)
# Windows - comes pre-installed with Python
# macOS
brew install sqlite3
# Linux
sudo apt-get install sqlite3
```

### 3. Verify Copilot Configuration
```bash
# In VS Code, open Command Palette (Ctrl/Cmd + Shift + P)
# Run: "GitHub Copilot: Status"
# Should show "GitHub Copilot: Ready"
```

### 4. Test API Setup
```python
# test_setup.py
from fastapi import FastAPI
import uvicorn

app = FastAPI()

@app.get("/")
def read_root():
    return {"status": "Module 07 Ready!"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

Run test:
```bash
python test_setup.py
# Visit http://localhost:8000
# Should see: {"status": "Module 07 Ready!"}
```

## 🚨 Common Setup Issues

### Issue 1: Copilot Not Suggesting
**Solution:**
```bash
# Restart VS Code
# Check Copilot status
# Re-authenticate if needed
```

### Issue 2: Python Package Conflicts
**Solution:**
```bash
# Use fresh virtual environment
deactivate
rm -rf venv
python -m venv venv
# Reinstall packages
```

### Issue 3: Port Already in Use
**Solution:**
```bash
# Find process using port 8000
# Windows
netstat -ano | findstr :8000
# macOS/Linux
lsof -i :8000
# Kill the process or use different port
```

## ✅ Pre-Module Checklist

Before starting the exercises, ensure:

- [ ] All software versions meet requirements
- [ ] Python virtual environment is activated
- [ ] All Python packages installed successfully
- [ ] VS Code extensions are installed
- [ ] GitHub Copilot is active and working
- [ ] Test API runs successfully
- [ ] You have 3 hours of uninterrupted time
- [ ] You've reviewed Module 6 concepts

## 🎯 Quick Validation Script

Run this script to validate your setup:

```python
# validate_setup.py
import sys
import subprocess
import importlib

def check_python_version():
    version = sys.version_info
    if version.major >= 3 and version.minor >= 11:
        print("✅ Python version OK")
        return True
    else:
        print("❌ Python 3.11+ required")
        return False

def check_packages():
    packages = ['fastapi', 'uvicorn', 'sqlalchemy', 'pydantic']
    all_good = True
    
    for package in packages:
        try:
            importlib.import_module(package)
            print(f"✅ {package} installed")
        except ImportError:
            print(f"❌ {package} not installed")
            all_good = False
    
    return all_good

def check_node():
    try:
        result = subprocess.run(['node', '--version'], 
                              capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ Node.js installed: {result.stdout.strip()}")
            return True
    except FileNotFoundError:
        pass
    
    print("❌ Node.js not found")
    return False

def main():
    print("🔍 Validating Module 07 Setup...\n")
    
    checks = [
        check_python_version(),
        check_packages(),
        check_node()
    ]
    
    if all(checks):
        print("\n✅ All checks passed! Ready for Module 07")
    else:
        print("\n❌ Some checks failed. Please fix issues above.")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

## 📞 Getting Help

If you encounter setup issues:
1. Check the [TROUBLESHOOTING.md](../../TROUBLESHOOTING.md) guide
2. Search existing GitHub Issues
3. Post in Module 07 Discussions
4. Tag instructors with @mention

Ready? Let's build amazing web applications with AI! 🚀