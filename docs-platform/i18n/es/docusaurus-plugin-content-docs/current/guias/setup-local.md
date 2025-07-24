---
id: setup-local
title: Local Development Setup
sidebar_label: Setup Local
sidebar_position: 4
---

# Local desarrollo Setup

Completar guide to setting up a professional AI desarrollo ambiente on your local machine.

## Resumen

This guide covers:
- Completar desarrollo ambiente setup
- Tool installation and configuration  
- Local model setup (optional)
- IDE optimization
- Testing your setup

## 🖥️ Operating System Setup

### Windows

#### 1. Enable Windows Subsystem for Linux (WSL) - Optional but Recommended

```powershell
# Run as Administrator
wsl --install

# Install Ubuntu
wsl --install -d Ubuntu-22.04

# Set WSL 2 as default
wsl --set-default-version 2
```

#### 2. Install Windows Terminal

Descargar from [Microsoft Store](https://aka.ms/terminal) for better command line experience.

#### 3. Install Chocolatey Package Manager

```powershell
# Run as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

### macOS

#### 1. Install Iniciobrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 2. Install Xcode Command Line Tools

```bash
xcode-select --install
```

### Linux (Ubuntu/Debian)

#### 1. Actualizar System

```bash
sudo apt update && sudo apt upgrade -y
```

#### 2. Install Essential Build Tools

```bash
sudo apt install build-essential curl wget git -y
```

## 🐍 Python ambiente Setup

### Install Python

#### Windows
```powershell
# Using Chocolatey
choco install python3 -y

# Or download from python.org
```

#### macOS
```bash
# Using Homebrew
brew install python@3.11
```

#### Linux
```bash
sudo apt install python3.11 python3.11-venv python3-pip -y
```

### Configure Python

```bash
# Verify installation
python --version
pip --version

# Upgrade pip
python -m pip install --upgrade pip

# Install virtual environment tools
pip install virtualenv virtualenvwrapper
```

### Configurar pyenv (Recommended for Multiple Python Versións)

#### macOS/Linux
```bash
# Install pyenv
curl https://pyenv.run | bash

# Add to shell profile (~/.bashrc, ~/.zshrc)
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc

# Reload shell
source ~/.bashrc

# Install Python versions
pyenv install 3.11.7
pyenv global 3.11.7
```

## 🛠️ Essential desarrollo Tools

### Git Configuration

```bash
# Install Git (if not already installed)
# Windows: choco install git
# macOS: brew install git
# Linux: sudo apt install git

# Configure Git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global init.defaultBranch main

# Set up SSH key for GitHub
ssh-keygen -t ed25519 -C "your.email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Display public key to add to GitHub
cat ~/.ssh/id_ed25519.pub
```

### VS Code Setup

#### 1. Install VS Code

- Descargar from [code.visualstudio.com](https://code.visualstudio.com/)
- Or use package manager:
  ```bash
  # Windows
  choco install vscode
  
  # macOS
  brew install --cask visual-studio-code
  
  # Linux
  sudo snap install code --classic
  ```

#### 2. Install Essential Extensions

```bash
# Install via command line
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension ms-toolsai.jupyter
code --install-extension ms-vscode.makefile-tools
code --install-extension GitHub.copilot
code --install-extension eamodio.gitlens
code --install-extension ms-azuretools.vscode-docker
code --install-extension esbenp.prettier-vscode
```

#### 3. Configure VS Code Configuraciones

Create/update `~/.config/Code/User/settings.json`:

```json
{
    "python.defaultInterpreterPath": "~/.pyenv/shims/python",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "python.formatting.provider": "black",
    "python.formatting.blackArgs": ["--line-length", "88"],
    "python.sortImports.args": ["--profile", "black"],
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.organizeImports": true
    },
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000,
    "terminal.integrated.defaultProfile.windows": "PowerShell",
    "terminal.integrated.defaultProfile.linux": "bash",
    "terminal.integrated.defaultProfile.osx": "zsh"
}
```

## 🏗️ Project Structure Setup

### Create Standard Project Template

```bash
# Create project structure
mkdir -p ~/ai-projects/template
cd ~/ai-projects/template

# Create directories
mkdir -p {src,tests,data,models,notebooks,docs,scripts}

# Create files
touch README.md requirements.txt .env.example .gitignore
touch src/__init__.py tests/__init__.py
```

### Standard .gitignore

```gitignore
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
.venv

# Environment
.env
.env.local
*.env

# IDEs
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Project specific
data/raw/
models/
*.log
.ipynb_checkpoints/
*.db
*.sqlite3

# API Keys and Secrets
*_secret*
*.key
*.pem
config/secrets.json
```

### Project Requirements Template

Create `requirements.txt`:

```txt
# Core AI/ML
openai>=1.0.0
anthropic>=0.3.0
langchain>=0.1.0
transformers>=4.35.0
torch>=2.0.0

# Data Processing
numpy>=1.24.0
pandas>=2.0.0
scikit-learn>=1.3.0

# Web Development
fastapi>=0.104.0
streamlit>=1.28.0
gradio>=4.0.0
uvicorn>=0.24.0

# Database and Vector Stores
chromadb>=0.4.0
pinecone-client>=2.2.0
qdrant-client>=1.6.0
sqlalchemy>=2.0.0

# Utilities
python-dotenv>=1.0.0
requests>=2.31.0
httpx>=0.25.0
pydantic>=2.4.0
rich>=13.6.0

# Development Tools
pytest>=7.4.0
black>=23.10.0
pylint>=3.0.0
ipython>=8.16.0
jupyter>=1.0.0
notebook>=7.0.0

# Monitoring and Logging
loguru>=0.7.0
sentry-sdk>=1.34.0
```

### ambiente Variables Template

Create `.env.example`:

```bash
# API Keys
OPENAI_API_KEY=your-openai-key-here
ANTHROPIC_API_KEY=your-anthropic-key-here
HUGGINGFACE_TOKEN=your-hf-token-here

# Database
DATABASE_URL=postgresql://user:password@localhost/dbname
REDIS_URL=redis://localhost:6379

# Application Settings
APP_ENV=development
DEBUG=true
LOG_LEVEL=info

# Vector Database
PINECONE_API_KEY=your-pinecone-key
PINECONE_ENV=your-environment

# Monitoring
SENTRY_DSN=your-sentry-dsn

# Model Settings
MODEL_NAME=gpt-3.5-turbo
TEMPERATURE=0.7
MAX_TOKENS=150
```

## 🤖 Local Model Setup (Optional)

### Option 1: Ollama (Recommended Para Principiantes)

#### Install Ollama

```bash
# macOS
brew install ollama

# Linux
curl -fsSL https://ollama.ai/install.sh | sh

# Windows
# Download from https://ollama.ai/download
```

#### Descargar and Run Models

```bash
# Start Ollama service
ollama serve

# In another terminal, pull models
ollama pull llama2
ollama pull codellama
ollama pull mistral

# Run a model
ollama run llama2

# List installed models
ollama list
```

#### Use with Python

```python
import requests
import json

def query_ollama(prompt, model="llama2"):
    url = "http://localhost:11434/api/generate"
    data = {
        "model": model,
        "prompt": prompt,
        "stream": False
    }
    
    response = requests.post(url, json=data)
    return response.json()["response"]

# Test it
result = query_ollama("Explain quantum computing in simple terms")
print(result)
```

### Option 2: LocalAI

```bash
# Using Docker
docker run -p 8080:8080 -v $PWD/models:/models -ti --rm quay.io/go-skynet/local-ai:latest

# Download models
curl http://localhost:8080/models/apply -H "Content-Type: application/json" -d '{
  "id": "model-gallery@mistral"
}'
```

### Option 3: Text Generation WebUI

```bash
# Clone repository
git clone https://github.com/oobabooga/text-generation-webui
cd text-generation-webui

# Install
python -m pip install -r requirements.txt

# Run
python server.py --listen
```

## 🧪 Testing Your Setup

### Create Test Script

Create `test_setup.py`:

```python
#!/usr/bin/env python3
"""Test script to verify AI development environment setup"""

import sys
import subprocess
import importlib
from pathlib import Path

def print_status(message, success=True):
    """Print colored status message"""
    color = '\033[92m' if success else '\033[91m'
    symbol = '✓' if success else '✗'
    reset = '\033[0m'
    print(f"{color}{symbol}{reset} {message}")

def check_python():
    """Check Python version"""
    version = sys.version_info
    if version.major == 3 and version.minor >= 8:
        print_status(f"Python {version.major}.{version.minor}.{version.micro}")
        return True
    else:
        print_status(f"Python version {version.major}.{version.minor} (need 3.8+)", False)
        return False

def check_package(package_name):
    """Check if package is installed"""
    try:
        importlib.import_module(package_name)
        print_status(f"Package '{package_name}' installed")
        return True
    except ImportError:
        print_status(f"Package '{package_name}' not found", False)
        return False

def check_command(command):
    """Check if command is available"""
    try:
        subprocess.run([command, "--version"], capture_output=True, check=True)
        print_status(f"Command '{command}' available")
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        print_status(f"Command '{command}' not found", False)
        return False

def check_env_file():
    """Check if .env file exists"""
    if Path(".env").exists():
        print_status(".env file exists")
        return True
    else:
        print_status(".env file not found", False)
        return False

def check_api_keys():
    """Check if API keys are set"""
    import os
    from dotenv import load_dotenv
    
    load_dotenv()
    
    keys = ["OPENAI_API_KEY", "ANTHROPIC_API_KEY"]
    all_good = True
    
    for key in keys:
        if os.getenv(key):
            print_status(f"{key} is set")
        else:
            print_status(f"{key} not found", False)
            all_good = False
    
    return all_good

def main():
    """Run all checks"""
    print("🔍 Checking AI Development Environment Setup\n")
    
    checks = [
        ("Python Version", check_python),
        ("Git", lambda: check_command("git")),
        ("Essential Packages", lambda: all([
            check_package("openai"),
            check_package("dotenv"),
            check_package("requests"),
            check_package("numpy"),
            check_package("pandas")
        ])),
        ("Environment File", check_env_file),
        ("API Keys", check_api_keys)
    ]
    
    results = []
    for name, check in checks:
        print(f"\n{name}:")
        results.append(check())
    
    print("\n" + "="*50)
    if all(results):
        print("✅ All checks passed! Your environment is ready.")
    else:
        print("❌ Some checks failed. Please fix the issues above.")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

Run the test:

```bash
python test_setup.py
```

## 🔧 Avanzado Configuration

### Docker Setup

```bash
# Install Docker
# Windows/macOS: Download Docker Desktop
# Linux:
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group (Linux)
sudo usermod -aG docker $USER

# Test Docker
docker run hello-world
```

### GPU Setup (NVIDIA)

```bash
# Check NVIDIA GPU
nvidia-smi

# Install CUDA Toolkit
# Follow instructions at https://developer.nvidia.com/cuda-downloads

# Install cuDNN
# Download from https://developer.nvidia.com/cudnn

# Install PyTorch with CUDA
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```

### Performance Monitoring

```bash
# Install monitoring tools
pip install gpustat py-spy memory-profiler

# Monitor GPU
gpustat -i

# Profile Python code
py-spy record -o profile.svg -- python your_script.py
```

## 📝 Maintenance Tips

### Regular Actualizars

```bash
# Update pip packages
pip list --outdated
pip install --upgrade package-name

# Update all packages (careful!)
pip freeze | grep -v "^-e" | cut -d = -f 1 | xargs -n1 pip install -U

# Clean pip cache
pip cache purge
```

### Atrásup Configuration

```bash
# Backup VS Code settings
cp ~/.config/Code/User/settings.json ~/backup/

# Export installed extensions
code --list-extensions > vscode-extensions.txt

# Backup dotfiles
cp ~/.bashrc ~/.zshrc ~/.gitconfig ~/backup/
```

## 🎯 Próximos Pasos

1. **Test Your Setup**: Run the test script to ensure everything is working
2. **Create Your First Project**: Use the template structure
3. **Explore Tools**: Try different IDEs and tools
4. **Join Community**: Connect with other developers

## 🆘 Troubleshooting

See our [Troubleshooting Guía](./troubleshooting.md) for common issues and solutions.

---

**Ready to build? Continue to [Module 1: Fundamentals](../modules/module-01-fundamentals.md) →**