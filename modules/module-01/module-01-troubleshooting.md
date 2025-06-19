# Module 01: Troubleshooting Guide 🔧

## Common Issues and Solutions

This guide addresses the most common problems encountered in Module 01. If you can't find your issue here, check the main [workshop troubleshooting guide](../../TROUBLESHOOTING.md) or ask in the Discord channel.

## 🚫 GitHub Copilot Issues

### Issue: "GitHub Copilot is not providing any suggestions"

#### Symptoms
- No code suggestions appear when typing
- Copilot icon shows as inactive
- Comments don't generate code

#### Solutions

1. **Check Copilot Status**
   ```bash
   # In VS Code, open Command Palette (Ctrl/Cmd + Shift + P)
   > GitHub Copilot: Status
   ```

2. **Verify Subscription**
   - Visit [github.com/settings/copilot](https://github.com/settings/copilot)
   - Ensure subscription is active
   - Check payment method if trial expired

3. **Re-authenticate**
   ```bash
   # Command Palette
   > GitHub Copilot: Sign Out
   > GitHub Copilot: Sign In
   ```

4. **Check File Type**
   - Copilot works best with `.py`, `.js`, `.ts` files
   - May not work in `.txt` or unsupported formats

5. **Network Issues**
   - Check internet connection
   - Try disabling VPN/proxy
   - Check firewall settings

### Issue: "Copilot suggestions are irrelevant or wrong"

#### Solutions

1. **Improve Context**
   ```python
   # Bad context
   # function
   
   # Good context
   # Create a function that calculates the area of a circle given its radius
   # The function should validate that radius is positive and return float
   ```

2. **Clear File Context**
   - Close and reopen the file
   - Clear VS Code cache: `Ctrl/Cmd + Shift + P` > "Clear Editor History"

3. **Check Language Settings**
   - Ensure file has correct extension
   - Set language mode explicitly in VS Code

## 🐍 Python Issues

### Issue: "Python command not found"

#### Windows Solutions
```bash
# Try these commands in order:
python --version
python3 --version
py --version
py -3 --version

# If none work, add Python to PATH:
# 1. Find Python installation (usually C:\Users\{username}\AppData\Local\Programs\Python\Python3x)
# 2. Add to System PATH in Environment Variables
```

#### macOS Solutions
```bash
# Install via Homebrew
brew install python3

# Or download from python.org
# Then verify:
python3 --version
```

#### Linux Solutions
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install python3 python3-pip

# Fedora
sudo dnf install python3 python3-pip

# Verify
python3 --version
```

### Issue: "pip install fails"

#### Solutions
```bash
# Upgrade pip first
python -m pip install --upgrade pip

# If permission denied:
# Windows (run as administrator)
python -m pip install --user package_name

# macOS/Linux
pip3 install --user package_name

# If SSL error:
pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org package_name
```

## 💻 VS Code Issues

### Issue: "Copilot extension not found"

#### Solutions
1. **Manual Install**
   - Open VS Code
   - Go to Extensions (Ctrl/Cmd + Shift + X)
   - Search "GitHub Copilot"
   - Click Install
   - Reload VS Code

2. **Command Line Install**
   ```bash
   code --install-extension GitHub.copilot
   ```

3. **Check VS Code Version**
   - Copilot requires VS Code 1.60+
   - Update VS Code: Help > Check for Updates

### Issue: "IntelliSense not working with Python"

#### Solutions
1. **Install Python Extension**
   ```bash
   code --install-extension ms-python.python
   ```

2. **Select Python Interpreter**
   - Ctrl/Cmd + Shift + P
   - "Python: Select Interpreter"
   - Choose your Python installation

3. **Install Pylance**
   ```bash
   code --install-extension ms-python.vscode-pylance
   ```

## 📝 Exercise-Specific Issues

### Exercise 1: Hello AI World

#### Issue: "Copilot doesn't suggest greeting functions"
```python
# Solution: Be more specific
# Instead of:
# greeting function

# Use:
# Create a function that generates a personalized greeting based on:
# - User's name (string parameter)
# - Current time of day (morning, afternoon, evening)
# - Returns a formatted greeting message

def generate_greeting(name: str) -> str:
    # Now Copilot will provide better suggestions
```

#### Issue: "Time detection not working correctly"
```python
# Common timezone issue
import datetime

# Problem: Uses server time
current_hour = datetime.datetime.now().hour

# Solution: Use local time
from datetime import datetime
import pytz

# Get user's timezone (or use a default)
user_tz = pytz.timezone('US/Eastern')  # Example
current_hour = datetime.now(user_tz).hour
```

### Exercise 2: Smart Calculator

#### Issue: "Natural language parsing fails"
```python
# Solution: Build incrementally
# Step 1: Handle numbers
def parse_number(text: str) -> float:
    # Handle "twenty-five" -> 25
    pass

# Step 2: Handle operations
def parse_operation(text: str) -> str:
    # Handle "plus" -> "+"
    pass

# Step 3: Combine
def parse_expression(text: str) -> dict:
    # Use previous functions
    pass
```

#### Issue: "Word to number conversion complex"
```python
# Use a library instead of building from scratch
# Install: pip install word2number
from word2number import w2n

# Example usage
result = w2n.word_to_num("twenty-five")  # Returns: 25
```

### Exercise 3: Personal Assistant

#### Issue: "File not saving data"
```python
# Common issue: Directory doesn't exist
import os
import json
from pathlib import Path

def save_data(data: dict, filename: str):
    # Ensure directory exists
    data_dir = Path("data")
    data_dir.mkdir(exist_ok=True)
    
    # Save with error handling
    filepath = data_dir / filename
    try:
        with open(filepath, 'w') as f:
            json.dump(data, f, indent=2)
    except Exception as e:
        print(f"Error saving data: {e}")
```

#### Issue: "Natural language date parsing difficult"
```python
# Use a library
# Install: pip install python-dateutil
from dateutil import parser
from dateutil.relativedelta import relativedelta
from datetime import datetime

# Examples
date1 = parser.parse("tomorrow at 5pm")
date2 = parser.parse("next Monday")
date3 = datetime.now() + relativedelta(weeks=1)
```

## 🔍 Debugging Tips

### 1. Use Print Debugging
```python
def complex_function(data):
    print(f"DEBUG: Input data: {data}")
    
    # Processing step 1
    result1 = process_step1(data)
    print(f"DEBUG: After step 1: {result1}")
    
    # Processing step 2
    result2 = process_step2(result1)
    print(f"DEBUG: After step 2: {result2}")
    
    return result2
```

### 2. Use Python Debugger
```python
import pdb

def problematic_function(data):
    # Set breakpoint
    pdb.set_trace()
    
    # Code continues here
    # In debugger: n (next), c (continue), l (list), p variable (print)
```

### 3. VS Code Debugging
1. Set breakpoints by clicking left of line numbers
2. Press F5 to start debugging
3. Use Debug Console for interactive debugging

## 🚨 Emergency Fixes

### "Nothing is working!"
1. **Restart Everything**
   ```bash
   # Close VS Code
   # Restart computer
   # Open VS Code
   # Try again
   ```

2. **Clean Install**
   ```bash
   # Uninstall Copilot extension
   # Clear VS Code cache
   # Reinstall Copilot
   # Re-authenticate
   ```

3. **Minimal Test**
   ```python
   # Create test.py with just:
   # Function to add two numbers
   
   # If this doesn't trigger Copilot, the issue is with setup
   ```

### "I'm running out of time!"
1. **Skip Complex Features**
   - Get basic version working first
   - Add features incrementally
   - Comment what you'd add with more time

2. **Use Simpler Solutions**
   ```python
   # Instead of complex parsing
   # Use simple string splitting
   
   # Instead of database
   # Use JSON file
   
   # Instead of CLI framework
   # Use basic input()
   ```

## 📞 Getting Help

### Self-Help Resources
1. Check this troubleshooting guide
2. Search in Discord channel
3. Check GitHub Discussions
4. Review exercise solutions

### Asking for Help
When asking for help, provide:
1. **Error message** (complete text)
2. **Code snippet** (relevant portion)
3. **What you tried** (solutions attempted)
4. **Environment** (OS, Python version, VS Code version)

### Example Help Request
```
I'm getting "ModuleNotFoundError: No module named 'colorama'" in Exercise 3.

Environment:
- Windows 11
- Python 3.11.0
- VS Code 1.84.0
- Copilot 1.126.0

I tried:
1. pip install colorama
2. python -m pip install colorama
3. Running as administrator

Error occurs at:
import colorama

Full error:
[paste complete error]
```

## ✅ Prevention Tips

1. **Test Early**: Don't wait until the end
2. **Save Often**: Use version control
3. **Read Errors**: They usually tell you what's wrong
4. **Stay Updated**: Keep tools current
5. **Take Breaks**: Fresh eyes spot issues faster

---

Remember: Every developer faces these issues. You're not alone, and these problems are part of the learning process! 🌟