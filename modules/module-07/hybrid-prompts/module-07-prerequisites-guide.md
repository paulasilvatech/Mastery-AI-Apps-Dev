# Module 07 - Comprehensive Prerequisites & Setup Guide

## 🎯 Overview

This guide ensures you have everything needed to successfully complete Module 07's web application exercises using both GitHub Copilot approaches.

## 🖥️ System Requirements

### Hardware Requirements

| Component | Minimum | Recommended | Optimal |
|-----------|---------|-------------|---------|
| **CPU** | 4 cores | 8 cores | 16+ cores |
| **RAM** | 8GB | 16GB | 32GB |
| **Storage** | 20GB free | 50GB free | 100GB SSD |
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
   - Node.js (18+ LTS)
   - Python (3.11+)
   - Git (2.38+)
   - VS Code (latest)
   - Docker Desktop
   
3. Configures VS Code extensions:
   - GitHub Copilot
   - GitHub Copilot Chat
   - Python
   - Prettier
   - ESLint
   - Live Server
   - React snippets
   
4. Validates installations
5. Sets up development environment

Make it idempotent and handle errors gracefully.
```

### Language-Specific Installation

#### Windows (PowerShell as Administrator)
```powershell
# Install Chocolatey if not present
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install development tools
choco install nodejs-lts python3 git vscode docker-desktop -y

# Install VS Code extensions
code --install-extension GitHub.copilot
code --install-extension GitHub.copilot-chat
code --install-extension ms-python.python
code --install-extension esbenp.prettier-vscode
code --install-extension dbaeumer.vscode-eslint
```

#### macOS (Terminal)
```bash
# Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install development tools
brew install node@18 python@3.11 git
brew install --cask visual-studio-code docker

# Install VS Code extensions
code --install-extension GitHub.copilot
code --install-extension GitHub.copilot-chat
code --install-extension ms-python.python
code --install-extension esbenp.prettier-vscode
```

#### Linux (Ubuntu/Debian)
```bash
# Update package manager
sudo apt update && sudo apt upgrade -y

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install nodejs -y

# Install Python 3.11
sudo apt install python3.11 python3.11-venv python3-pip -y

# Install other tools
sudo apt install git code docker.io -y
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
   - Clone to local machine
   - Set up SSH keys for easier access

### API Keys and Services

1. **OpenAI API (Exercise 3)**
   - Sign up at [platform.openai.com](https://platform.openai.com)
   - Add payment method (required)
   - Generate API key
   - Set spending limits ($5-10 for workshop)

2. **Azure Account (Optional for Deployment)**
   - Free account: $200 credit for 30 days
   - Student account: $100 credit
   - Keep services in free tier

## 🚀 Environment Setup

### Step 1: Clone Workshop Repository

```bash
# Clone the repository
git clone https://github.com/your-org/mastery-ai-workshop.git
cd mastery-ai-workshop/modules/module-07

# Create your working branch
git checkout -b module-07-work
```

### Step 2: Frontend Setup (React/Vite)

```bash
# Navigate to exercise directory
cd exercises/exercise-1-todo

# Install dependencies
npm install

# Verify setup
npm run dev
# Should start on http://localhost:5173
```

### Step 3: Backend Setup (Python/FastAPI)

```bash
# Create Python virtual environment
python3 -m venv venv

# Activate virtual environment
# Windows
.\venv\Scripts\activate
# macOS/Linux
source venv/bin/activate

# Install dependencies
pip install fastapi uvicorn sqlalchemy python-dotenv openai

# Verify setup
uvicorn main:app --reload
# Should start on http://localhost:8000
```

### Step 4: Environment Variables

Create `.env` files for sensitive data:

```bash
# Backend .env
OPENAI_API_KEY=sk-... # Your OpenAI API key
DATABASE_URL=sqlite:///./todos.db
ENVIRONMENT=development

# Frontend .env
VITE_API_URL=http://localhost:8000
VITE_ENABLE_ANALYTICS=false
```

### Step 5: VS Code Configuration

```json
// .vscode/settings.json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true,
  "python.formatting.provider": "black",
  "emmet.includeLanguages": {
    "javascript": "javascriptreact"
  },
  "github.copilot.enable": {
    "*": true,
    "yaml": true,
    "plaintext": true,
    "markdown": true
  }
}
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

echo "🔍 Validating Module 07 Prerequisites..."
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

# Function to check npm package
check_npm_package() {
    if npm list -g $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} NPM Package: $1"
        return 0
    else
        echo -e "${YELLOW}!${NC} NPM Package: $1 (Not installed globally)"
        return 1
    fi
}

# Check tools
echo -e "\n📦 Checking Required Tools:"
check_command "node" "node --version"
check_command "npm" "npm --version"
check_command "python3" "python3 --version"
check_command "pip" "pip --version"
check_command "git" "git --version"
check_command "code" "code --version | head -n 1"
check_command "docker" "docker --version"

# Check Node version
NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ $NODE_VERSION -lt 18 ]; then
    echo -e "${RED}✗${NC} Node.js version must be 18 or higher"
fi

# Check Python version
PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1-2)
if (( $(echo "$PYTHON_VERSION < 3.11" | bc -l) )); then
    echo -e "${RED}✗${NC} Python version must be 3.11 or higher"
fi

# Check VS Code extensions
echo -e "\n🔌 Checking VS Code Extensions:"
for ext in "GitHub.copilot" "GitHub.copilot-chat" "ms-python.python" "esbenp.prettier-vscode" "dbaeumer.vscode-eslint"; do
    if code --list-extensions | grep -q $ext; then
        echo -e "${GREEN}✓${NC} VS Code Extension: $ext"
    else
        echo -e "${YELLOW}!${NC} VS Code Extension: $ext (Not installed)"
    fi
done

# Check GitHub CLI (optional but helpful)
echo -e "\n🐙 Checking GitHub Configuration:"
if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    echo -e "${GREEN}✓${NC} GitHub CLI: Authenticated"
else
    echo -e "${YELLOW}!${NC} GitHub CLI: Not authenticated (optional)"
fi

# Check for .env files
echo -e "\n🔐 Checking Environment Files:"
if [ -f ".env" ] || [ -f ".env.example" ]; then
    echo -e "${GREEN}✓${NC} Environment file template found"
else
    echo -e "${YELLOW}!${NC} No .env file found - create one from .env.example"
fi

# Check ports
echo -e "\n🔌 Checking Port Availability:"
for port in 3000 5173 8000 8080; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}!${NC} Port $port is in use"
    else
        echo -e "${GREEN}✓${NC} Port $port is available"
    fi
done

# Summary
echo -e "\n📊 Summary:"
echo "If any items show ✗ or !, please install them before proceeding."
echo "Run the setup script to install missing components."
```

## 🎯 Exercise-Specific Prerequisites

### Exercise 1 (Todo App) Additional Requirements
- Basic understanding of REST APIs
- Familiarity with state management in React
- Knowledge of SQL basics helpful

### Exercise 2 (Smart Notes) Additional Requirements
- Markdown syntax knowledge
- Understanding of localStorage API
- Basic search algorithms

### Exercise 3 (AI Recipes) Additional Requirements
- OpenAI API key with credits
- Understanding of prompt engineering
- Basic knowledge of AI/ML concepts

## 🆘 Troubleshooting Common Setup Issues

### Issue: "npm: command not found"
```bash
# Solution: Install Node.js which includes npm
# Visit: https://nodejs.org/
# Or use package manager as shown above
```

### Issue: "Python not found"
```bash
# Solution: Install Python 3.11+
# Windows: Use installer from python.org
# Mac: brew install python@3.11
# Linux: sudo apt install python3.11
```

### Issue: "GitHub Copilot not working"
```bash
# Solution:
1. Check subscription at github.com/settings/copilot
2. Sign out and back in VS Code
3. Ensure extension is enabled for workspace
4. Check internet connection
```

### Issue: "Port already in use"
```bash
# Find and kill process using port
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Mac/Linux
lsof -ti:8000 | xargs kill -9
```

## 📚 Additional Learning Resources

### Pre-Module Learning
1. **React Fundamentals**: [React Docs](https://react.dev/learn)
2. **FastAPI Basics**: [FastAPI Tutorial](https://fastapi.tiangolo.com/tutorial/)
3. **REST API Concepts**: [MDN Web Docs](https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Client-side_web_APIs/Introduction)

### Recommended Videos
- "GitHub Copilot in 100 Seconds" by Fireship
- "FastAPI Course" by freeCodeCamp
- "React in 2024" by Traversy Media

## ✅ Pre-Module Checklist

Before starting Module 07, ensure:

- [ ] All development tools installed
- [ ] VS Code configured with extensions
- [ ] GitHub Copilot subscription active
- [ ] Repository cloned locally
- [ ] Can run both frontend and backend
- [ ] Understand basic React concepts
- [ ] Familiar with REST APIs
- [ ] Completed Modules 1-6
- [ ] Have 3 hours available
- [ ] Ready to explore and experiment!

## 🚀 Ready to Start?

Once all prerequisites are met:
1. Open VS Code in the module directory
2. Review the exercise overviews
3. Choose your preferred approach (Code Suggestions or Agent Mode)
4. Start with Exercise 1
5. Don't forget to explore beyond the requirements!

**Pro Tip**: Keep this guide open in a browser tab for quick reference during the exercises!

---

**Need Help?** Check the [Module 07 Troubleshooting Guide](./TROUBLESHOOTING.md) or post in the workshop discussions.