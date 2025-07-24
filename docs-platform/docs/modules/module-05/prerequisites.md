---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 05"
---

# Prerequisites for Module 05: Documentation and Code Quality

## 📋 Required Knowledge

Before starting this module, you should have:

### ✅ Completed Modules
- **Module 01**: Introduction to AI-Powered Development
- **Module 02**: GitHub Copilot Core Features  
- **Module 03**: Effective Prompting Techniques
- **Module 04**: AI-Assisted Debugging and Testing

### ✅ Programming Skills
- **Python Proficiency**:
  - Functions and classes
  - Modules and packages
  - Basic type hints
  - File I/O operations

- **Documentation Awareness**:
  - Comments vs documentation
  - Basic markdown syntax
  - API documentation concepts

- **Code Quality Understanding**:
  - Clean code principles
  - DRY (Don't Repeat Yourself)
  - Basic refactoring concepts

## 🛠️ Required Software

### Development Environment
```bash
# Verify Python version
python --version  # Must be 3.11 or higher

# Verify pip is updated
python -m pip --version
python -m pip install --upgrade pip
```

### VS Code Extensions
Ensure these extensions are installed and enabled:
- ✅ GitHub Copilot
- ✅ Python (Microsoft)
- ✅ Pylance
- ✅ Python Docstring Generator
- ✅ Better Comments
- ✅ Markdown All in One

### Python Packages
Install required packages:
```bash
# Create and activate virtual environment
python -m venv venv
# Windows
.\venv\Scripts\activate
# macOS/Linux
source venv/bin/activate

# Install documentation tools
pip install sphinx==7.2.6
pip install sphinx-autodoc-typehints==2.0.0
pip install sphinx-rtd-theme==2.0.0

# Install code quality tools
pip install black==24.3.0
pip install flake8==7.0.0
pip install mypy==1.9.0
pip install pylint==3.1.0

# Install testing tools
pip install pytest==8.1.1
pip install pytest-cov==5.0.0

# Install utility packages
pip install pydantic==2.6.4
pip install rich==13.7.1
pip install click==8.1.7
```

## 📁 Module Setup

### 1. Clone Module Repository
```bash
# If not already cloned
git clone https://github.com/your-org/mastery-ai-workshop.git
cd mastery-ai-workshop/modules/module-05-documentation-quality
```

### 2. Verify Directory Structure
```
module-05-documentation-quality/
├── README.md
├── prerequisites.md (this file)
├── exercises/
│   ├── exercise1-easy/
│   ├── exercise2-medium/
│   └── exercise3-hard/
├── best-practices.md
├── resources/
└── troubleshooting.md
```

### 3. Test Your Setup
Run the verification script:
```bash
python scripts/verify-setup.py
```

Expected output:
```
✅ Python 3.11+ detected
✅ All required packages installed
✅ VS Code extensions verified
✅ GitHub Copilot active
✅ Documentation tools ready
✅ Code quality tools configured
✅ Ready for Module 05!
```

## 🔧 Configuration Files

### 1. Create `.flake8` Configuration
```ini
[flake8]
max-line-length = 88
extend-ignore = E203, W503
exclude = 
    .git,
    __pycache__,
    venv,
    .venv,
    build,
    dist
```

### 2. Create `pyproject.toml` for Black
```toml
[tool.black]
line-length = 88
target-version = ['py311']
include = '\.pyi?$'
extend-exclude = '''
/(
  # directories
  \.git
  | venv
  | build
  | dist
)/
'''
```

### 3. Create `mypy.ini` Configuration
```ini
[mypy]
python_version = 3.11
warn_return_any = True
warn_unused_configs = True
disallow_untyped_defs = True
disallow_incomplete_defs = True
check_untyped_defs = True
no_implicit_optional = True
warn_redundant_casts = True
warn_unused_ignores = True
```

## 🎯 Pre-Module Checklist

Before starting the exercises, ensure you can:

### Knowledge Check
- [ ] Write Python functions with parameters and return values
- [ ] Create and use Python classes
- [ ] Understand basic type hints (str, int, List, Dict)
- [ ] Write basic markdown documents
- [ ] Explain what code refactoring means

### Technical Check
- [ ] GitHub Copilot shows suggestions in VS Code
- [ ] Python virtual environment is activated
- [ ] All required packages are installed
- [ ] Configuration files are created
- [ ] Verification script passes

### Copilot Check
- [ ] Can trigger suggestions with comments
- [ ] Know how to accept/reject suggestions
- [ ] Understand how to cycle through suggestions
- [ ] Can use Copilot chat for questions

## 🚨 Common Setup Issues

### Issue: Sphinx Import Error
```bash
# Solution: Ensure virtual environment is activated
which python  # Should show venv path
pip install sphinx --force-reinstall
```

### Issue: Black Formatting Conflicts
```bash
# Solution: Use consistent configuration
black --check .
# If issues, run:
black .
```

### Issue: MyPy Type Errors
```bash
# Solution: Install type stubs
pip install types-requests types-PyYAML
```

## 📚 Recommended Reading

Before starting, review these resources:
1. [PEP 257 - Docstring Conventions](https://peps.python.org/pep-0257/)
2. [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html)
3. [Refactoring Guru - Code Smells](https://refactoring.guru/refactoring/smells)
4. [Real Python - Documenting Python Code](https://realpython.com/documenting-python-code/)

## ✅ Ready to Start?

If you've completed all checks above:
1. Open the module README.md
2. Start with Exercise 1 (Documentation Generator)
3. Follow the step-by-step instructions
4. Use Copilot actively throughout

**Remember**: This module focuses on making your code professional and maintainable. Take time to understand each concept!

---

**Need help?** Check the [troubleshooting guide](/docs/guias/troubleshooting) or ask in #module-05-documentation