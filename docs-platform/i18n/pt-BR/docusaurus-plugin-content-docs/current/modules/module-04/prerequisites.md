---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 04"
---

# Pré-requisitos for Módulo 04: AI-Assisted Debugging and Testing

## 📋 Required Knowledge

### From Anterior Módulos
- ✅ **Módulo 01**: Basic Copilot usage and prompting
- ✅ **Módulo 02**: Code completion and suggestions
- ✅ **Módulo 03**: Context optimization and custom instructions

### Programming Concepts
- ✅ Understanding of functions and classes
- ✅ Basic error handling (try/except)
- ✅ Knowledge of assertions
- ✅ Familiarity with debugging concepts

## 💻 Software Requirements

### Python ambiente
```bash
# Verify Python version (3.11+ required)
python --version

# Should output: Python 3.11.x or higher
```

### Required Packages
Create a virtual ambiente and install dependencies:

```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows
venv\Scripts\activate
# macOS/Linux
source venv/bin/activate

# Install required packages
pip install pytest==7.4.3
pip install pytest-cov==4.1.0
pip install pytest-mock==3.12.0
pip install pytest-benchmark==4.0.0
pip install requests==2.31.0
pip install flask==3.0.0
pip install black==23.11.0
pip install pylint==3.0.2
```

### VS Code Extensions
Ensure these extensions are instalado and configurado:

1. **GitHub Copilot** (required)
   - Should be authenticated and active
   - Verificar status in bottom right corner

2. **Python** (required)
   - Microsoft's official Python extension
   - Select correct interpreter (your venv)

3. **Python Test Explorer** (recommended)
   - Visual test runner
   - Integrates with pytest

4. **Error Lens** (recommended)
   - Highlights errors inline
   - Ajudas with debugging

## 🔧 ambiente Setup

### 1. Configure pytest
Create `pytest.ini` in your workspace:

```ini
[tool:pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = -v --cov=src --cov-report=html --cov-report=term
```

### 2. VS Code Configurações
Add to `.vscode/settings.json`:

```json
{
    "python.testing.pytestEnabled": true,
    "python.testing.unittestEnabled": false,
    "python.testing.pytestArgs": [
        "tests"
    ],
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "python.formatting.provider": "black",
    "editor.formatOnSave": true,
    "github.copilot.enable": {
        "*": true,
        "yaml": true,
        "plaintext": true,
        "markdown": true,
        "python": true
    }
}
```

### 3. Copilot Configuration
Verify Copilot settings:

1. Abrir Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`)
2. Run "GitHub Copilot: Abrir Configurações"
3. Ensure:
   - ✅ Enable Copilot
   - ✅ Show inline suggestions
   - ✅ Enable auto-completions

## 📁 Módulo Structure

Create this directory structure:

```
module-04-testing-debugging/
├── exercises/
│   ├── exercise1-easy/
│   ├── exercise2-medium/
│   └── exercise3-hard/
├── scripts/
│   └── validate_setup.py
├── resources/
├── tests/
└── requirements.txt
```

## ✅ Validation Script

Run this script to verify your setup:

```python
#!/usr/bin/env python3
"""Setup validation for Module 04"""

import sys
import subprocess
import importlib

def check_python_version():
    """Check Python version is 3.11+"""
    version = sys.version_info
    if version.major == 3 and version.minor &gt;= 11:
        print("✅ Python version: {}.{}.{}".format(*version[:3]))
        return True
    else:
        print("❌ Python 3.11+ required, found: {}.{}.{}".format(*version[:3]))
        return False

def check_package(package_name, min_version=None):
    """Check if a package is installed"""
    try:
        module = importlib.import_module(package_name.replace('-', '_'))
        version = getattr(module, '__version__', 'unknown')
        print(f"✅ {package_name}: {version}")
        return True
    except ImportError:
        print(f"❌ {package_name}: not installed")
        return False

def check_copilot():
    """Check if Copilot is available"""
    try:
        result = subprocess.run(['code', '--list-extensions'], 
                              capture_output=True, text=True)
        if 'GitHub.copilot' in result.stdout:
            print("✅ GitHub Copilot: installed")
            return True
        else:
            print("❌ GitHub Copilot: not found")
            return False
    except:
        print("⚠️  Could not verify Copilot (VS Code CLI not available)")
        return True  # Don't fail if we can't check

def main():
    """Run all checks"""
    print("🔍 Validating Module 04 Prerequisites\n")
    
    checks = [
        check_python_version(),
        check_package('pytest'),
        check_package('pytest_cov'),
        check_package('pytest_mock'),
        check_package('requests'),
        check_package('flask'),
        check_copilot()
    ]
    
    if all(checks):
        print("\n✅ All prerequisites satisfied! Ready for Module 04")
        return 0
    else:
        print("\n❌ Some prerequisites missing. Please install missing components.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
```

## 🚦 Pre-Módulo Verificarlist

Before starting the module, ensure:

- [ ] Python 3.11+ is instalado and active
- [ ] Virtual ambiente is created and activated
- [ ] All required packages are instalado
- [ ] VS Code is configurado with extensions
- [ ] GitHub Copilot is authenticated
- [ ] Validation script passes all checks
- [ ] You're familiar with basic Python syntax
- [ ] You understand the concept of automated testing

## 🆘 Troubleshooting

### Issue: pytest not found
```bash
# Ensure virtual environment is activated
# Reinstall pytest
pip install --upgrade pytest
```

### Issue: Copilot not suggesting test code
1. Verificar Copilot status (bottom right of VS Code)
2. Ensure you're in a Python file
3. Try manual trigger: `Alt+\` (Windows/Linux) or `Option+\` (Mac)

### Issue: Coverage Relatórios not generating
```bash
# Install coverage separately
pip install coverage
# Run with explicit coverage
pytest --cov=. --cov-report=html
```

## 📚 Recommended Reading

Before starting, review:
- [Python unittest basics](https://docs.python.org/3/library/unittest.html)
- [pytest quick start](https://docs.pytest.org/en/stable/getting-started.html)
- [Test-Driven Development concepts](https://en.wikipedia.org/wiki/Test-driven_desenvolvimento)

---

Ready? Let's master AI-assisted testing! 🚀