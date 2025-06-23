#!/bin/bash

# Quick Start Script for Mastery AI Code Development Workshop
# Gets you coding with AI in 5 minutes!

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     🚀 Mastery AI Code Development - Quick Start 🚀       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Function to print colored status
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check critical requirements only
print_status "Checking critical requirements..."

# Check Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    print_success "Python installed: $PYTHON_VERSION"
else
    print_error "Python 3 is required but not installed!"
    echo "Please install Python 3.11 or later from https://python.org"
    exit 1
fi

# Check Git
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    print_success "Git installed: $GIT_VERSION"
else
    print_error "Git is required but not installed!"
    echo "Please install Git from https://git-scm.com"
    exit 1
fi

# Check VS Code
if command -v code &> /dev/null; then
    print_success "VS Code is installed"
else
    print_warning "VS Code not found in PATH. Make sure it's installed!"
    echo "Download from: https://code.visualstudio.com"
fi

# Check GitHub CLI (optional but helpful)
if command -v gh &> /dev/null; then
    print_success "GitHub CLI is installed"
    
    # Check Copilot status
    if gh copilot status &> /dev/null; then
        print_success "GitHub Copilot is active!"
    else
        print_warning "GitHub Copilot not configured. Run: gh auth login"
    fi
else
    print_warning "GitHub CLI not installed (optional)"
fi

echo ""
print_status "Setting up Module 01..."

# Navigate to module 01
cd "$(dirname "$0")/.."
MODULE_PATH="modules/module-01"

if [ ! -d "$MODULE_PATH" ]; then
    print_error "Module 01 directory not found!"
    exit 1
fi

cd "$MODULE_PATH"

# Create Python virtual environment
print_status "Creating Python virtual environment..."
python3 -m venv venv
print_success "Virtual environment created"

# Activate virtual environment
print_status "Activating virtual environment..."
source venv/bin/activate
print_success "Virtual environment activated"

# Create a simple requirements.txt if it doesn't exist
if [ ! -f "requirements.txt" ]; then
    cat > requirements.txt << EOF
# Basic requirements for Module 01
pytest>=7.0.0
black>=23.0.0
flake8>=6.0.0
EOF
    print_success "Created requirements.txt"
fi

# Install basic packages
print_status "Installing Python packages..."
pip install --quiet --upgrade pip
pip install --quiet -r requirements.txt
print_success "Packages installed"

# Create VS Code settings if not exists
mkdir -p .vscode
if [ ! -f ".vscode/settings.json" ]; then
    cat > .vscode/settings.json << 'EOF'
{
    "python.defaultInterpreterPath": "./venv/bin/python",
    "python.terminal.activateEnvironment": true,
    "github.copilot.enable": {
        "*": true,
        "yaml": true,
        "plaintext": true,
        "markdown": true
    },
    "editor.inlineSuggest.enabled": true,
    "editor.suggestOnTriggerCharacters": true,
    "python.linting.enabled": true,
    "python.linting.flake8Enabled": true,
    "python.formatting.provider": "black"
}
EOF
    print_success "Created VS Code settings"
fi

# Create a quick reference file
cat > QUICK_REFERENCE.md << 'EOF'
# 🚀 Quick Reference - Module 01

## GitHub Copilot Shortcuts

| Action | Windows/Linux | macOS |
|--------|--------------|-------|
| Accept suggestion | `Tab` | `Tab` |
| Dismiss suggestion | `Esc` | `Esc` |
| Next suggestion | `Alt + ]` | `Option + ]` |
| Previous suggestion | `Alt + [` | `Option + [` |
| Open Copilot | `Ctrl + Enter` | `Cmd + Enter` |
| Copilot Chat | `Ctrl + Shift + I` | `Cmd + Shift + I` |

## Quick Commands

```bash
# Run your first AI file
cd exercises/exercise1-easy/starter
python hello_ai.py

# Run tests
cd ../tests
python -m pytest test_hello_ai.py

# Format code with Black
black hello_ai.py

# Check code style
flake8 hello_ai.py
```

## Tips for Success

1. **Write clear comments** before coding
2. **Be specific** in your prompts
3. **Iterate** - first suggestion isn't always best
4. **Review** generated code before using

Happy coding with AI! 🤖
EOF

print_success "Created quick reference guide"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✨ Quick Start Complete! ✨${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "📁 You're in: $MODULE_PATH"
echo "📝 Virtual environment: activated"
echo "📦 Packages: installed"
echo "⚙️  VS Code: configured"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Open VS Code: ${BLUE}code .${NC}"
echo "2. Open the exercise: ${BLUE}exercises/exercise1-easy/starter/hello_ai.py${NC}"
echo "3. Start coding with Copilot!"
echo ""
echo "💡 See QUICK_REFERENCE.md for shortcuts and tips"
echo ""
echo -e "${GREEN}Happy AI coding! 🚀${NC}"
