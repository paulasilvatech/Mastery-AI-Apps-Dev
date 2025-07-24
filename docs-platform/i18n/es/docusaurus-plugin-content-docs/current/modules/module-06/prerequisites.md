---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 06"
---

# Prerrequisitos for Módulo 06: Multi-File Proyectos and Workspaces

## 🎯 Módulo-Specific Requirements

This module requires a solid foundation from previous modules and specific tools for managing complex projects.

## ✅ Required Knowledge

### From Anterior Módulos
- **Módulo 1-2**: Basic Copilot usage and suggestions
- **Módulo 3**: Effective prompting techniques
- **Módulo 4**: Testing and debugging with AI
- **Módulo 5**: Documentación and code quality

### Programming Concepts
- Object-oriented programming basics
- Módulo/package organization
- Basic design patterns (MVC, Repository)
- Understanding of separation of concerns

## 💻 Software Requirements

### Essential Tools
```bash
# Verify versions
python --version          # 3.11 or higher
git --version            # 2.38 or higher
code --version           # Latest VS Code
```

### VS Code Extensions
Ensure these extensions are instalado and active:
1. **GitHub Copilot** (required)
2. **GitHub Copilot Chat** (required)
3. **Python** (ms-python.python)
4. **Pylance** (ms-python.vscode-pylance)
5. **GitLens** (optional but recommended)

### Python Packages
Core packages for this module:
```bash
# Create requirements.txt
fastapi==0.104.1
uvicorn==0.24.0
sqlalchemy==2.0.23
pytest==7.4.3
black==23.11.0
flake8==6.1.0
mypy==1.7.1
pydantic==2.5.0
python-multipart==0.0.6
aiofiles==23.2.1
```

## 🔧 ambiente Setup

### 1. Create Módulo Workspace
```bash
# Clone or create module directory
mkdir -p module-06-multi-file-projects
cd module-06-multi-file-projects

# Initialize git (if not cloned)
git init
```

### 2. Configure VS Code Workspace
Create `.vscode/settings.json`:
```json
{
  "python.linting.enabled": true,
  "python.linting.flake8Enabled": true,
  "python.formatting.provider": "black",
  "editor.formatOnSave": true,
  "python.testing.pytestEnabled": true,
  "files.exclude": {
    "**/__pycache__": true,
    "**/*.pyc": true
  },
  "github.copilot.enable": {
    "*": true
  }
}
```

### 3. Configurar Copilot Workspace Instructions
Create `.github/copilot-instructions.md`:
```markdown
# Project Context for GitHub Copilot

This is a multi-file Python project focusing on:
- Clean architecture with separation of concerns
- Type hints throughout the codebase
- Comprehensive error handling
- Async/await patterns where applicable
- pytest for testing
- SQLAlchemy for database operations

Follow PEP 8 standards and use descriptive variable names.
```

### 4. Python Virtual ambiente
```bash
# Create and activate virtual environment
python -m venv venv

# Activation
# Linux/macOS:
source venv/bin/activate

# Windows:
.\venv\Scripts\activate

# Upgrade pip
python -m pip install --upgrade pip
```

## 🏗️ Project Structure Template

Create this structure for exercises:
```
exercise-workspace/
├── .vscode/
│   └── settings.json
├── .github/
│   └── copilot-instructions.md
├── src/
│   ├── __init__.py
│   ├── models/
│   │   └── __init__.py
│   ├── services/
│   │   └── __init__.py
│   ├── api/
│   │   └── __init__.py
│   └── utils/
│       └── __init__.py
├── tests/
│   ├── __init__.py
│   └── conftest.py
├── requirements.txt
├── .gitignore
└── README.md
```

## 🔍 Validation Verificarlist

Run this checklist before starting exercises:

### 1. Copilot Functionality
- [ ] Abrir VS Code and create a test file
- [ ] Type a comment and verify Copilot suggestions appear
- [ ] Abrir Copilot Chat (Ctrl+I or Cmd+I)
- [ ] Test @workspace command in chat

### 2. Python ambiente
```bash
# Should show your virtual environment path
which python

# Should list installed packages
pip list

# Test imports
python -c "import fastapi, sqlalchemy, pytest; print('All imports successful')"
```

### 3. Workspace Features
- [ ] Multiple files open in tabs
- [ ] Explorer sidebar shows project structure
- [ ] Terminal integrated in VS Code
- [ ] Git integration working

## ⚠️ Common Setup Issues

### Issue: Copilot not recognizing workspace
**Solution**: Ensure you opened VS Code at the project root:
```bash
code .  # From project root directory
```

### Issue: Import errors in Python
**Solution**: Verify virtual ambiente is activated:
```bash
# Should show (venv) in prompt
which python
# Should point to venv/bin/python or venv\Scripts\python
```

### Issue: @workspace not working in Copilot Chat
**Solution**: Actualizar VS Code and Copilot extensions:
1. Abrir Extensions sidebar (Ctrl+Shift+X)
2. Buscar for "GitHub Copilot"
3. Click Actualizar if available
4. Restart VS Code

## 📚 Recommended Reading

Before starting the exercises, review:
1. [Python Project Structure Mejores Prácticas](https://docs.python-guide.org/writing/structure/)
2. [VS Code Multi-root Workspaces](https://code.visualstudio.com/docs/editor/multi-root-workspaces)
3. [GitHub Copilot Documentación](https://docs.github.com/en/copilot)

## ✨ Pro Tips

1. **Keep related files open**: Copilot uses open tabs for context
2. **Use descriptive file names**: Better names = better suggestions
3. **Organize imports**: Clear imports help Copilot understand dependencies
4. **Comment your intentions**: Strategic comments guide AI assistance

## 🚀 Ready to Start?

Once you've completed all prerequisites:
1. Navigate to `exercises/exercise1-easy/`
2. Read the instructions carefully
3. Comience con the starter code
4. Use Copilot features as you progress

---

**Need Help?** Check the [troubleshooting guide](/docs/guias/troubleshooting) or open an issue in the repository.