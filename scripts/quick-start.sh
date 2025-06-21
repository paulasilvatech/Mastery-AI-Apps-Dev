#!/bin/bash

# ========================================================================
# Mastery AI Apps and Development Workshop - Quick Start Script
# ========================================================================
# Get started with the workshop in 5 minutes!
# ========================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Workshop variables
WORKSHOP_NAME="Mastery AI Apps and Development Workshop"
FIRST_MODULE="module-01"

# Timer
START_TIME=$(date +%s)

# Functions
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${PURPLE}ℹ $1${NC}"
}

show_progress() {
    local current=$1
    local total=$2
    local percent=$((current * 100 / total))
    local filled=$((percent / 5))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '█'
    printf "%$((20 - filled))s" | tr ' ' '░'
    printf "] %d%%" $percent
    
    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

check_critical_requirements() {
    print_header "🚀 Quick Requirements Check"
    
    local requirements_met=true
    
    # Check Git
    print_step "Checking Git..."
    if command -v git &> /dev/null; then
        print_success "Git installed"
    else
        print_error "Git not found - required for workshop"
        requirements_met=false
    fi
    
    # Check Python
    print_step "Checking Python..."
    if command -v python3 &> /dev/null; then
        version=$(python3 --version | awk '{print $2}')
        print_success "Python $version found"
    else
        print_warning "Python 3 not found - will need for exercises"
    fi
    
    # Check VS Code
    print_step "Checking VS Code..."
    if command -v code &> /dev/null; then
        print_success "VS Code installed"
    else
        print_warning "VS Code not found - recommended editor"
    fi
    
    # Check GitHub CLI
    print_step "Checking GitHub CLI..."
    if command -v gh &> /dev/null; then
        if gh auth status &> /dev/null; then
            print_success "GitHub CLI authenticated"
        else
            print_warning "GitHub CLI not authenticated - run 'gh auth login'"
        fi
    else
        print_warning "GitHub CLI not found - useful for workshop"
    fi
    
    if [[ "$requirements_met" == "false" ]]; then
        print_error "Critical requirements missing!"
        print_info "Run ./scripts/setup-workshop.sh for complete setup"
        exit 1
    fi
}

setup_first_module() {
    print_header "📁 Setting Up Your First Module"
    
    # Navigate to first module
    cd "modules/$FIRST_MODULE" 2>/dev/null || {
        print_error "Cannot find modules directory"
        print_info "Make sure you're in the workshop root directory"
        exit 1
    }
    
    print_success "Navigated to Module 1"
    
    # Create starter files if they don't exist
    if [[ ! -f "hello_ai.py" ]]; then
        print_step "Creating your first AI-powered Python file..."
        
        cat > hello_ai.py << 'EOF'
#!/usr/bin/env python3
"""
Your first AI-powered code!
Type comments to get GitHub Copilot suggestions.
"""

# TODO: Create a function that generates a personalized welcome message
# Hint: Press Tab to accept Copilot's suggestion!


# TODO: Create a function that returns the current date and time in a friendly format


# TODO: Create a main function that uses both functions above


if __name__ == "__main__":
    # TODO: Call the main function
    pass
EOF
        
        print_success "Created hello_ai.py"
    fi
    
    # Create a simple exercise
    if [[ ! -f "exercise1.py" ]]; then
        cat > exercise1.py << 'EOF'
"""
Exercise 1: AI-Assisted Calculator

Use GitHub Copilot to help you create a simple calculator.
Follow the TODOs and let Copilot assist you!
"""

# TODO: Create a Calculator class with methods for:
# - add(a, b)
# - subtract(a, b)  
# - multiply(a, b)
# - divide(a, b) - handle division by zero!


# TODO: Create a function that takes user input and performs calculations


# TODO: Add a main function with a simple menu


if __name__ == "__main__":
    print("Welcome to your AI-assisted calculator!")
    # TODO: Run the calculator
EOF
        
        print_success "Created exercise1.py"
    fi
}

create_quick_reference() {
    print_header "📚 Creating Quick Reference"
    
    cat > QUICK_REFERENCE.md << 'EOF'
# Quick Reference Guide

## 🎯 GitHub Copilot Shortcuts

### VS Code
- **Accept suggestion**: `Tab`
- **Next suggestion**: `Alt + ]`
- **Previous suggestion**: `Alt + [`
- **Open Copilot**: `Ctrl + Shift + I` (Cmd on Mac)

## 💡 Effective Copilot Prompts

### For Functions
```python
# Create a function that validates email addresses using regex
# It should return True for valid emails, False otherwise
# Handle edge cases like missing @ or invalid domains
```

### For Classes
```python
# Create a User class with:
# - Properties: name, email, age
# - Method to validate email
# - Method to check if user is adult (18+)
# - String representation method
```

### For Error Handling
```python
# Add try-except blocks to handle:
# - File not found errors
# - Network connection errors
# - Invalid input errors
# Return meaningful error messages
```

## 🚀 Quick Commands

```bash
# Activate Python environment
source .venv/bin/activate  # Linux/Mac
.venv\Scripts\activate     # Windows

# Run Python file
python3 hello_ai.py

# Open in VS Code
code .

# Check Copilot status
gh copilot status
```

## 📋 Module Progress Tracker

- [ ] Module 1: Introduction to AI-Powered Development
- [ ] Module 2: GitHub Copilot Core Features
- [ ] Module 3: Effective Prompting Techniques
- [ ] Module 4: AI-Assisted Debugging and Testing
- [ ] Module 5: Documentation and Code Quality

## 🔗 Useful Links

- [Workshop Repository](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev)
- [GitHub Copilot Docs](https://docs.github.com/copilot)
- [VS Code Shortcuts](https://code.visualstudio.com/shortcuts/keyboard-shortcuts-windows.pdf)

## 💬 Getting Help

1. Check module README files
2. Review exercise solutions
3. Consult troubleshooting guide
4. Ask Copilot for help!

---
Happy coding with AI! 🤖✨
EOF
    
    print_success "Created QUICK_REFERENCE.md"
}

setup_vscode_workspace() {
    print_header "⚙️ Configuring VS Code Workspace"
    
    # Create VS Code workspace settings
    mkdir -p .vscode
    
    cat > .vscode/settings.json << 'EOF'
{
    "github.copilot.enable": {
        "*": true,
        "yaml": true,
        "plaintext": true,
        "markdown": true
    },
    "editor.inlineSuggest.enabled": true,
    "editor.suggestSelection": "first",
    "python.defaultInterpreterPath": ".venv/bin/python",
    "python.terminal.activateEnvironment": true,
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "files.autoSave": "onFocusChange",
    "editor.formatOnSave": true,
    "editor.wordWrap": "on",
    "terminal.integrated.defaultProfile.osx": "bash",
    "terminal.integrated.defaultProfile.linux": "bash",
    "terminal.integrated.defaultProfile.windows": "PowerShell"
}
EOF
    
    # Create recommended extensions
    cat > .vscode/extensions.json << 'EOF'
{
    "recommendations": [
        "GitHub.copilot",
        "GitHub.copilot-chat",
        "ms-python.python",
        "ms-python.vscode-pylance",
        "ms-toolsai.jupyter",
        "esbenp.prettier-vscode"
    ]
}
EOF
    
    print_success "VS Code workspace configured"
}

show_tips() {
    print_header "💡 Pro Tips for Getting Started"
    
    tips=(
        "Press Tab to accept Copilot suggestions"
        "Write descriptive comments to get better suggestions"
        "Use Ctrl+Enter to see multiple suggestions"
        "Break complex problems into smaller functions"
        "Review Copilot suggestions before accepting"
        "Use type hints for better Python suggestions"
        "Experiment with different comment styles"
        "Try pair programming with Copilot!"
    )
    
    for i in "${!tips[@]}"; do
        echo -e "${CYAN}$((i+1)).${NC} ${tips[$i]}"
        sleep 0.3
    done
}

final_setup() {
    print_header "🎉 Final Steps"
    
    # Calculate elapsed time
    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    MINUTES=$((ELAPSED / 60))
    SECONDS=$((ELAPSED % 60))
    
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}║            🎊 Quick Start Complete! 🎊                       ║${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}║         Time taken: ${MINUTES}m ${SECONDS}s                              ║${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${PURPLE}📂 Your workshop structure:${NC}"
    echo "mastery-ai-apps-dev/"
    echo "├── modules/"
    echo "│   ├── module-01/ ${GREEN}← You are here${NC}"
    echo "│   │   ├── hello_ai.py"
    echo "│   │   └── exercise1.py"
    echo "│   └── ... (29 more modules)"
    echo "├── scripts/"
    echo "├── QUICK_REFERENCE.md"
    echo "└── README.md"
    
    echo -e "\n${YELLOW}🚀 Next Steps:${NC}"
    echo "1. Open VS Code: ${CYAN}code .${NC}"
    echo "2. Open hello_ai.py and start coding with Copilot!"
    echo "3. Try the exercises in exercise1.py"
    echo "4. Check QUICK_REFERENCE.md for tips"
    
    echo -e "\n${GREEN}Happy learning with AI! 🤖✨${NC}"
}

interactive_mode() {
    clear
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║   🚀 Mastery AI Apps and Development Workshop               ║"
    echo "║              5-Minute Quick Start                            ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${CYAN}Welcome! Let's get you started with AI-powered development in 5 minutes.${NC}\n"
    
    read -p "Press Enter to begin the quick setup... "
    
    # Run setup steps with progress
    local steps=5
    local current=0
    
    echo -e "\n${YELLOW}Starting quick setup...${NC}\n"
    
    # Step 1
    ((current++))
    show_progress $current $steps
    check_critical_requirements
    
    # Step 2
    ((current++))
    show_progress $current $steps
    setup_first_module
    
    # Step 3
    ((current++))
    show_progress $current $steps
    create_quick_reference
    
    # Step 4
    ((current++))
    show_progress $current $steps
    setup_vscode_workspace
    
    # Step 5
    ((current++))
    show_progress $current $steps
    show_tips
    
    # Final
    final_setup
}

# Main execution
main() {
    # Check if we're in the right directory
    if [[ ! -f "README.md" ]] || [[ ! -d "modules" ]]; then
        print_error "Please run this script from the workshop root directory"
        exit 1
    fi
    
    # Run interactive setup
    interactive_mode
}

# Run main function
main
