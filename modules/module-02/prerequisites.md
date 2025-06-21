# Prerequisites for Module 02: GitHub Copilot Core Features

## 🎯 Module-Specific Requirements

### Required from Previous Module
- ✅ Completed Module 01 successfully
- ✅ GitHub Copilot activated and working
- ✅ Basic understanding of AI-assisted coding

### Software Requirements
```bash
# Verify installations
python --version      # Should be 3.11+
code --version       # Latest VS Code
gh copilot status    # Should show active subscription
```

### VS Code Extensions
Ensure these extensions are installed and updated:
1. **GitHub Copilot** (v1.140.0 or later)
2. **GitHub Copilot Chat** (latest)
3. **Python** (Microsoft)
4. **Pylance** (for better Python IntelliSense)

### Workspace Setup
```bash
# Create module workspace
mkdir -p ~/copilot-workshop/module-02
cd ~/copilot-workshop/module-02

# Clone exercise materials
git clone https://github.com/workshop/module-02-exercises.git exercises
```

## 🛠️ Configuration Check

### 1. Copilot Settings
Open VS Code settings (Ctrl/Cmd + ,) and verify:
- `github.copilot.enable`: `true`
- `github.copilot.inlineSuggest.enable`: `true`
- `github.copilot.chat.enabled`: `true`

### 2. Python Environment
```bash
# Create virtual environment
python -m venv venv

# Activate environment
# Windows
.\venv\Scripts\activate
# macOS/Linux
source venv/bin/activate

# Install required packages
pip install -r requirements.txt
```

### 3. Test Copilot Features
Create a test file `test_copilot.py`:
```python
# Type this comment and wait for suggestions
# Create a function that calculates fibonacci numbers

# You should see Copilot suggestions appear
```

## 📋 Knowledge Prerequisites

### Programming Concepts
- Functions and classes
- Basic data structures (lists, dictionaries)
- Control flow (if/else, loops)
- Error handling basics

### Python Specifics
- Function definitions
- Type hints (basic understanding)
- Import statements
- File I/O operations

### Git Basics
- Clone repositories
- Basic commit/push operations
- Understanding of version control

## 🔍 Validation Script

Run this script to verify your setup:
```bash
cd ~/copilot-workshop/module-02
./scripts/validate-module-02-setup.sh
```

Expected output:
```
✅ Python 3.11+ installed
✅ VS Code installed
✅ GitHub Copilot active
✅ Required extensions installed
✅ Virtual environment created
✅ All prerequisites satisfied!
```

## ⚠️ Common Issues

### Issue: Copilot not showing suggestions
**Solution**:
1. Check subscription: `gh copilot status`
2. Restart VS Code
3. Re-authenticate: `gh auth refresh -s copilot`

### Issue: Python environment errors
**Solution**:
1. Ensure Python 3.11+ is in PATH
2. Delete and recreate virtual environment
3. Use `python3` command on macOS/Linux

### Issue: Extension conflicts
**Solution**:
1. Disable other AI/autocomplete extensions
2. Check for VS Code updates
3. Reinstall Copilot extensions

## 📚 Recommended Reading

Before starting the exercises, review:
1. [GitHub Copilot Getting Started](https://docs.github.com/copilot/getting-started)
2. [Understanding Copilot Suggestions](https://docs.github.com/copilot/using-github-copilot/getting-suggestions)
3. Module 01 best practices document

## ✅ Final Checklist

Before proceeding to exercises:
- [ ] All software installed and versions verified
- [ ] Copilot showing suggestions in test file
- [ ] Virtual environment activated
- [ ] Validation script passes all checks
- [ ] Comfortable with basic VS Code operations

---

**Ready?** Once all prerequisites are met, proceed to the exercises!