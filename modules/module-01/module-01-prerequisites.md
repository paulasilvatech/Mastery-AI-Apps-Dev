# Prerequisites for Module 01: Introduction to AI-Powered Development

## 🎓 Knowledge Prerequisites

### Required Knowledge
- **Basic Programming Concepts**: Variables, functions, loops, conditionals
- **Any Programming Language**: Python preferred, but JavaScript, Java, or C# knowledge is sufficient
- **Text Editor Usage**: Basic familiarity with any code editor
- **Command Line Basics**: How to navigate directories and run commands

### Nice to Have (Not Required)
- Experience with Git version control
- Familiarity with VS Code
- Understanding of API concepts

## 💻 System Requirements

### Hardware
- **Minimum**: 8GB RAM, 2-core processor
- **Recommended**: 16GB RAM, 4-core processor
- **Storage**: 10GB free space
- **Internet**: Stable broadband connection (for Copilot)

### Operating System
- ✅ Windows 10/11
- ✅ macOS 10.15 or later
- ✅ Ubuntu 20.04 or later
- ✅ Other Linux distributions (with adjustments)

## 🛠️ Software Installation

### 1. Visual Studio Code
Download and install VS Code from [code.visualstudio.com](https://code.visualstudio.com/)

```bash
# Verify installation
code --version
```

### 2. GitHub Copilot Extension
1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X / Cmd+Shift+X)
3. Search for "GitHub Copilot"
4. Click Install
5. Sign in with your GitHub account

### 3. Python Installation
Install Python 3.8 or later from [python.org](https://www.python.org/)

```bash
# Windows
python --version

# macOS/Linux
python3 --version
```

### 4. Git Installation
Install Git from [git-scm.com](https://git-scm.com/)

```bash
# Configure Git (one-time setup)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Verify installation
git --version
```

## 🔑 Account Requirements

### GitHub Account
1. Create a free account at [github.com](https://github.com)
2. Verify your email address
3. Set up two-factor authentication (recommended)

### GitHub Copilot Subscription
1. Go to [github.com/copilot](https://github.com/features/copilot)
2. Choose subscription type:
   - **Individual**: $10/month or $100/year
   - **Business**: $19/user/month
3. Start free 30-day trial if available
4. Verify subscription is active

## 📋 Setup Verification

### Quick Setup Script
Run this script to verify all prerequisites:

```bash
#!/bin/bash
echo "🔍 Checking Module 01 Prerequisites..."

# Check VS Code
if command -v code &> /dev/null; then
    echo "✅ VS Code installed: $(code --version | head -1)"
else
    echo "❌ VS Code not found. Please install from code.visualstudio.com"
fi

# Check Python
if command -v python3 &> /dev/null; then
    echo "✅ Python installed: $(python3 --version)"
elif command -v python &> /dev/null; then
    echo "✅ Python installed: $(python --version)"
else
    echo "❌ Python not found. Please install from python.org"
fi

# Check Git
if command -v git &> /dev/null; then
    echo "✅ Git installed: $(git --version)"
else
    echo "❌ Git not found. Please install from git-scm.com"
fi

# Check GitHub Copilot Extension
if code --list-extensions | grep -q "GitHub.copilot"; then
    echo "✅ GitHub Copilot extension installed"
else
    echo "❌ GitHub Copilot extension not found. Please install from VS Code"
fi

echo "🎯 Setup verification complete!"
```

### Manual Verification Steps

1. **Open VS Code**
   - You should see the welcome screen
   - GitHub Copilot icon should appear in the status bar

2. **Test Python**
   ```python
   # Create test.py
   print("Python is working!")
   
   # Run it
   python test.py  # or python3 test.py
   ```

3. **Test GitHub Copilot**
   - Create a new file called `test.py`
   - Type: `# Function to calculate the area of a circle`
   - Press Enter and wait for suggestions
   - You should see code suggestions appear

## 🚧 Troubleshooting

### Copilot Not Working?
1. Check subscription status: [github.com/settings/copilot](https://github.com/settings/copilot)
2. Sign out and sign in again in VS Code
3. Restart VS Code
4. Check internet connection

### Python Issues?
- **Windows**: Use Python Launcher `py -3 --version`
- **macOS**: Install via Homebrew `brew install python3`
- **Linux**: Use package manager `sudo apt install python3`

### VS Code Extensions Missing?
1. Open Command Palette (Ctrl+Shift+P / Cmd+Shift+P)
2. Type "Install Extensions"
3. Search and install:
   - GitHub Copilot
   - Python
   - Pylance

## 📚 Optional Enhancements

### Recommended VS Code Extensions
- **Python**: Microsoft's Python extension
- **Pylance**: Fast, feature-rich language support
- **GitLens**: Supercharge Git capabilities
- **Error Lens**: Inline error highlighting

### Recommended VS Code Settings
```json
{
    "github.copilot.enable": {
        "*": true,
        "yaml": true,
        "plaintext": true,
        "markdown": true
    },
    "editor.inlineSuggest.enabled": true,
    "editor.suggestSelection": "first",
    "python.defaultInterpreterPath": "python3",
    "editor.formatOnSave": true
}
```

## ✅ Ready Checklist

Before starting Module 01, confirm:
- [ ] VS Code is installed and running
- [ ] GitHub Copilot extension is installed
- [ ] GitHub Copilot subscription is active
- [ ] Python 3.8+ is installed
- [ ] Git is installed and configured
- [ ] You can create and run a simple Python file
- [ ] Copilot shows suggestions when you type comments

## 🆘 Getting Help

If you encounter issues:
1. Check the [Troubleshooting Guide](../../TROUBLESHOOTING.md)
2. Search [GitHub Copilot Discussions](https://github.com/orgs/community/discussions/categories/copilot)
3. Ask in the workshop Discord channel
4. Email workshop support

---

🎉 Once everything is checked, you're ready to begin your AI-powered development journey!