---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 03"
---

# Pré-requisitos for Módulo 03: Effective Prompting Techniques

## 📋 Required Knowledge

Before starting this module, you should have:

### ✅ Completard Módulos
- **Módulo 01**: Introdução to AI-Powered Development
  - Understanding of GitHub Copilot basics
  - Initial setup completed
  - First AI-assisted code written

- **Módulo 02**: GitHub Copilot Core Features
  - Familiarity with suggestion types
  - Experience with basic completions
  - Understanding of Copilot UI

### ✅ Programming Skills
- **Python Fundamentos**:
  - Variables and data types
  - Functions and classes
  - Basic control structures
  - File operations

- **General Programming Concepts**:
  - Code organization principles
  - Basic software design patterns
  - Documentação practices
  - Versão control basics

## 🛠️ Required Software

### desenvolvimento ambiente
```bash
# Verify installations
python --version      # Should be 3.8 or higher
code --version       # VS Code latest stable
git --version        # Git 2.0 or higher
```

### VS Code Extensions
Ensure these are instalado and configurado:
- ✅ GitHub Copilot (v1.140.0 or higher)
- ✅ GitHub Copilot Chat
- ✅ Python extension (Microsoft)
- ✅ Pylance
- ✅ GitLens (optional but recommended)

### Verify GitHub Copilot
```bash
# Check Copilot status
gh copilot status

# If not authenticated:
gh auth login
gh extension install github/gh-copilot
```

## 📁 Módulo Setup

### 1. Create Módulo Directory
```bash
# Navigate to workshop directory
cd mastery-ai-workshop/modules

# Enter module 03
cd module-03-effective-prompting
```

### 2. Install Python Dependencies
```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
.\venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Install required packages
pip install -r requirements.txt
```

### 3. Verify Setup
Run the setup verification script:
```bash
python scripts/verify-setup.py
```

Expected output:
```
✅ Python 3.8+ detected
✅ Virtual environment active
✅ All required packages installed
✅ VS Code detected
✅ GitHub Copilot extension installed
✅ GitHub Copilot authenticated
✅ Ready for Module 03!
```

## 🔧 VS Code Configuration

### 1. Copilot Configurações
Abrir VS Code settings (Ctrl/Cmd + ,) and verify:

```json
{
  "github.copilot.enable": {
    "*": true,
    "plaintext": true,
    "markdown": true,
    "scminput": false
  },
  "github.copilot.advanced": {
    "length": 500,
    "temperature": 0.1,
    "top_p": 1,
    "stops": ["\\n\\n"]
  }
}
```

### 2. Workspace Configurações
Create `.vscode/settings.json` in the module directory:

```json
{
  "editor.inlineSuggest.enabled": true,
  "editor.suggestOnTriggerCharacters": true,
  "python.defaultInterpreterPath": "./venv/bin/python",
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true,
  "files.exclude": {
    "**/__pycache__": true,
    "**/*.pyc": true
  }
}
```

## 📝 Knowledge Verificar

Before proceeding, ensure you can:

1. **Use Basic Copilot Features**
   - [ ] Accept suggestions with Tab
   - [ ] Cycle through suggestions with Alt+]
   - [ ] Dismiss suggestions with Esc
   - [ ] Abrir Copilot panel

2. **Understand Copilot Behavior**
   - [ ] Know what triggers suggestions
   - [ ] Understand suggestion sources
   - [ ] Recognize different suggestion types
   - [ ] Know when Copilot is active

3. **Write Basic Python Code**
   - [ ] Create functions with parameters
   - [ ] Write and use classes
   - [ ] Handle basic file I/O
   - [ ] Use common data structures

## 🚨 Common Setup Issues

### Issue: Copilot not showing suggestions
```bash
# Solution 1: Restart VS Code
code --disable-extensions
code .

# Solution 2: Re-authenticate
gh auth refresh
gh copilot status
```

### Issue: Python ambiente not recognized
```bash
# Solution: Select interpreter
# In VS Code: Ctrl/Cmd + Shift + P
# Type: "Python: Select Interpreter"
# Choose: ./venv/bin/python
```

### Issue: Import errors in Exercícios
```bash
# Solution: Ensure venv is activated
deactivate  # If another env is active
source venv/bin/activate  # macOS/Linux
# or
.\venv\Scripts\activate  # Windows

# Reinstall requirements
pip install -r requirements.txt
```

## ✅ Final Verificarlist

Before starting the exercises:
- [ ] All software instalado and verified
- [ ] GitHub Copilot working in VS Code
- [ ] Python ambiente set up
- [ ] Módulo files accessible
- [ ] Verification script passes
- [ ] Comfortable with Módulo 1 & 2 concepts

## 🎯 Ready to Start!

Once all prerequisites are met:
1. Abrir the first exercise: `exercises/exercise1-easy/`
2. Read the exercise README
3. Seguir the step-by-step instructions
4. Use the validation scripts to check your work

---

💡 **Tip**: Keep this prerequisites guide handy. You may need to reference it during the exercises!