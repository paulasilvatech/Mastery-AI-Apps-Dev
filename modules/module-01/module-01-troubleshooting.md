# Module 01 Troubleshooting Guide

## 🔧 Common Issues and Solutions

### 🚫 Copilot Not Working

#### Issue: No Suggestions Appearing

**Symptoms:**
- No ghost text appears when typing
- Tab key doesn't complete anything
- No Copilot icon in status bar

**Solutions:**

1. **Check Copilot Status**
   ```bash
   # In VS Code, check bottom status bar
   # Should show "GitHub Copilot" icon
   
   # From terminal:
   gh copilot status
   ```

2. **Verify Extension Installation**
   - Press `Ctrl+Shift+X` (Windows/Linux) or `Cmd+Shift+X` (macOS)
   - Search "GitHub Copilot"
   - Ensure it's installed and enabled

3. **Re-authenticate**
   ```bash
   # Sign out and sign in again
   # Click accounts icon (bottom left VS Code)
   # Sign out of GitHub
   # Sign in again
   ```

4. **Check Subscription**
   - Visit: https://github.com/settings/copilot
   - Verify active subscription
   - Check payment method if trial expired

5. **Restart VS Code**
   - Close all VS Code windows
   - Restart VS Code
   - Open your project again

#### Issue: Copilot Suggestions Are Poor Quality

**Symptoms:**
- Irrelevant suggestions
- Incorrect code patterns
- Mixing languages/frameworks

**Solutions:**

1. **Improve Context**
   ```python
   # ❌ Poor context
   def calc():
       pass
   
   # ✅ Better context
   def calculate_monthly_payment(principal: float, rate: float, years: int) -> float:
       """Calculate monthly payment for a loan."""
       pass
   ```

2. **Clear File Focus**
   - Keep related code in same file
   - Remove unrelated code
   - Use clear, consistent naming

3. **Check File Type**
   - Ensure correct file extension (.py for Python)
   - VS Code should show "Python" in bottom right

### 🐍 Python Environment Issues

#### Issue: Module Import Errors

**Symptoms:**
```
ModuleNotFoundError: No module named 'click'
```

**Solutions:**

1. **Activate Virtual Environment**
   ```bash
   # Windows
   .\venv\Scripts\activate
   
   # macOS/Linux
   source venv/bin/activate
   ```

2. **Install Missing Packages**
   ```bash
   pip install click pytest rich
   ```

3. **Check Python Version**
   ```bash
   python --version
   # Should be 3.11 or higher
   ```

#### Issue: Wrong Python Interpreter

**Symptoms:**
- Import errors despite packages installed
- Different Python version than expected

**Solutions:**

1. **Select Correct Interpreter in VS Code**
   - Press `Ctrl+Shift+P` (Cmd+Shift+P on macOS)
   - Type "Python: Select Interpreter"
   - Choose the one in your `venv` folder

2. **Verify Interpreter**
   ```python
   import sys
   print(sys.executable)
   # Should point to venv/bin/python
   ```

### 💻 VS Code Issues

#### Issue: Extensions Not Loading

**Symptoms:**
- Python features not working
- No syntax highlighting
- Missing IntelliSense

**Solutions:**

1. **Reload Window**
   - Press `Ctrl+Shift+P` (Cmd+Shift+P on macOS)
   - Type "Developer: Reload Window"

2. **Check Extension Host**
   - View → Output
   - Select "Extension Host" from dropdown
   - Look for errors

3. **Reset VS Code Settings**
   ```bash
   # Backup settings first
   cp ~/.config/Code/User/settings.json ~/.config/Code/User/settings.backup.json
   
   # Reset to defaults
   rm ~/.config/Code/User/settings.json
   ```

### 🧪 Testing Issues

#### Issue: Pytest Not Found

**Symptoms:**
```
pytest: command not found
```

**Solutions:**

1. **Install pytest**
   ```bash
   pip install pytest
   ```

2. **Use Python Module**
   ```bash
   python -m pytest test_utils.py
   ```

3. **Add to PATH**
   ```bash
   # Find pytest location
   which pytest
   # Or
   pip show pytest
   ```

#### Issue: Tests Failing

**Symptoms:**
- Import errors in tests
- Assertion errors

**Solutions:**

1. **Check Import Paths**
   ```python
   # In test file, add:
   import sys
   sys.path.insert(0, '.')
   
   from utils import validate_email
   ```

2. **Run from Correct Directory**
   ```bash
   # Must be in exercise directory
   cd exercises/exercise1-easy
   pytest starter/test_utils.py
   ```

### 🔌 Network and Firewall Issues

#### Issue: Copilot Can't Connect

**Symptoms:**
- "GitHub Copilot could not connect to server"
- Timeout errors

**Solutions:**

1. **Check Internet Connection**
   ```bash
   ping github.com
   ```

2. **Corporate Firewall/Proxy**
   - Check with IT about GitHub access
   - May need proxy configuration:
   ```bash
   # In VS Code settings.json
   {
     "http.proxy": "http://proxy.company.com:8080",
     "https.proxy": "http://proxy.company.com:8080"
   }
   ```

3. **VPN Interference**
   - Try disconnecting VPN
   - Some VPNs block GitHub

### 🎯 Exercise-Specific Issues

#### Issue: CLI App Not Running

**Symptoms:**
```
python: can't open file 'cli_app.py': [Errno 2] No such file or directory
```

**Solutions:**

1. **Check Current Directory**
   ```bash
   pwd  # Should be in exercise directory
   ls   # Should see cli_app.py
   ```

2. **File Permissions (Linux/macOS)**
   ```bash
   chmod +x cli_app.py
   ```

#### Issue: Validation Script Fails

**Symptoms:**
- "Functions missing" errors
- Import errors

**Solutions:**

1. **Ensure All Functions Implemented**
   - Check utils.py has all required functions
   - Function names must match exactly

2. **Run Individual Checks**
   ```python
   # Test just the imports
   python -c "from utils import validate_email"
   ```

### 🆘 Getting Additional Help

#### Diagnostic Commands

Run these to gather information for support:

```bash
# System info
python --version
code --version
gh --version

# Extension info
code --list-extensions | grep -i copilot

# Python environment
pip list
which python

# Git status
git status
git remote -v
```

#### Create Diagnostic Report

```python
# Save as diagnostic.py and run
import sys
import subprocess
import platform

print("=== System Diagnostic Report ===")
print(f"Platform: {platform.platform()}")
print(f"Python: {sys.version}")
print(f"Python Path: {sys.executable}")

try:
    vs_version = subprocess.check_output(['code', '--version'], text=True)
    print(f"VS Code: {vs_version.split()[0]}")
except:
    print("VS Code: Not found in PATH")

try:
    gh_status = subprocess.check_output(['gh', 'copilot', 'status'], text=True)
    print(f"Copilot Status: Active")
except:
    print("Copilot Status: Check required")

print("\nInstalled packages:")
subprocess.run([sys.executable, '-m', 'pip', 'list'])
```

#### Support Resources

1. **GitHub Copilot Community**
   - https://github.com/community/community/discussions/categories/copilot

2. **VS Code Issues**
   - https://github.com/microsoft/vscode/issues

3. **Workshop Support**
   - Slack: #module-01-support
   - GitHub Discussions: [Workshop Repo]/discussions

#### Emergency Checklist

If nothing works:

1. [ ] Complete fresh VS Code install
2. [ ] Create new Python virtual environment
3. [ ] Re-clone workshop repository
4. [ ] Sign out/in GitHub account
5. [ ] Disable all other VS Code extensions
6. [ ] Try on different network (mobile hotspot)
7. [ ] Contact workshop support with diagnostic report

---

Remember: Most issues are related to environment setup or authentication. Stay calm, work through the solutions systematically, and don't hesitate to ask for help!