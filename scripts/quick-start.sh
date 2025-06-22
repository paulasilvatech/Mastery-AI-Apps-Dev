#!/bin/bash

# Mastery AI Code Development Workshop - Quick Start Script
# Get up and running in 5 minutes or less!

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
START_TIME=$(date +%s)
QUICK_MODE=true

# Functions for colored output
print_status() {
    echo -e "${BLUE}[QUICK]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_step() {
    echo -e "${CYAN}[STEP $1/5]${NC} $2"
}

print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║       🚀 5-Minute Quick Start - AI Workshop 🚀                  ║
║                                                                  ║
║      Get coding with AI in just a few minutes!                  ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get elapsed time
get_elapsed_time() {
    local current_time=$(date +%s)
    local elapsed=$((current_time - START_TIME))
    echo "${elapsed}s"
}

# Quick prerequisites check
quick_prereq_check() {
    print_step 1 "Quick Prerequisites Check (30s)"
    
    local critical_tools=("git" "python3" "code")
    local missing_tools=()
    
    for tool in "${critical_tools[@]}"; do
        if command_exists "$tool"; then
            print_success "$tool found"
        else
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing critical tools: ${missing_tools[*]}"
        print_status "Please install these tools first:"
        echo "• Git: https://git-scm.com/downloads"
        echo "• Python 3.11+: https://python.org/downloads"
        echo "• VS Code: https://code.visualstudio.com/download"
        exit 1
    fi
    
    # Check for GitHub Copilot in VS Code
    if code --list-extensions | grep -q "github.copilot"; then
        print_success "GitHub Copilot extension found"
    else
        print_warning "GitHub Copilot extension not found - install it after setup"
    fi
    
    print_success "Prerequisites check completed ($(get_elapsed_time))"
}

# Minimal environment setup
quick_env_setup() {
    print_step 2 "Environment Setup (60s)"
    
    # Create minimal directory structure
    mkdir -p workspace/{projects,templates,data}
    mkdir -p .vscode
    print_success "Created workspace directories"
    
    # Create Python virtual environment
    if [ ! -d "venv" ]; then
        print_status "Creating Python virtual environment..."
        python3 -m venv venv
        print_success "Virtual environment created"
    else
        print_success "Virtual environment already exists"
    fi
    
    # Activate and install minimal packages
    source venv/bin/activate
    print_status "Installing essential packages..."
    pip install --quiet --upgrade pip
    pip install --quiet requests azure-identity python-dotenv
    print_success "Essential packages installed"
    
    # Create minimal VS Code settings
    cat > .vscode/settings.json << 'EOF'
{
    "github.copilot.enable": {
        "*": true
    },
    "python.defaultInterpreterPath": "./venv/bin/python",
    "editor.formatOnSave": true
}
EOF
    print_success "VS Code settings created"
    
    # Create .env template
    cat > .env.template << 'EOF'
# Workshop Configuration
WORKSHOP_MODULE=1
ENVIRONMENT=dev

# Azure Configuration (fill these in)
AZURE_SUBSCRIPTION_ID=your-subscription-id
AZURE_TENANT_ID=your-tenant-id

# GitHub Configuration (optional)
GITHUB_TOKEN=your-github-token

# OpenAI Configuration (for later modules)
OPENAI_API_KEY=your-openai-key
EOF
    print_success "Environment template created"
    
    print_success "Environment setup completed ($(get_elapsed_time))"
}

# Download first module
download_first_module() {
    print_step 3 "First Module Setup (30s)"
    
    # Create Module 1 structure
    mkdir -p modules/module-01-introduction/{exercises,resources}
    
    # Create a simple first exercise
    cat > modules/module-01-introduction/exercises/hello_ai.py << 'EOF'
"""
Module 1 - Introduction to AI-Powered Development
Your first AI-assisted code!

Try these Copilot exercises:
1. Type a comment describing what you want to do
2. Press Tab to accept Copilot suggestions
3. Experiment with different prompts
"""

# Exercise 1: Create a function that generates a personalized welcome message
# Hint: Ask Copilot to create this function by typing a descriptive comment

def welcome_to_workshop(name, experience_level="beginner"):
    """
    Generate a personalized welcome message for the workshop participant.
    
    Args:
        name (str): Participant's name
        experience_level (str): Their coding experience level
    
    Returns:
        str: Personalized welcome message
    """
    # TODO: Let Copilot help you implement this function
    pass

# Exercise 2: Create a function to validate email addresses
# Type: "def validate_email(email):" and let Copilot suggest the implementation

# Exercise 3: Create a simple calculator function
# Comment: "Create a calculator function that can add, subtract, multiply, and divide"

if __name__ == "__main__":
    # Test your functions here
    print("Welcome to the AI Workshop!")
    print("Edit this file and let Copilot help you code!")
    
    # Uncomment and test your functions:
    # print(welcome_to_workshop("Your Name", "beginner"))
EOF
    
    # Create module README
    cat > modules/module-01-introduction/README.md << 'EOF'
# Module 1: Introduction to AI-Powered Development

## Objectives
- Set up your AI development environment
- Learn basic GitHub Copilot usage
- Write your first AI-assisted code
- Understand AI prompting principles

## Quick Start
1. Open `exercises/hello_ai.py` in VS Code
2. Follow the comments and let Copilot help you
3. Experiment with different prompts
4. See how AI can accelerate your coding

## Next Steps
- Complete all exercises in this module
- Read the full module documentation
- Move to Module 2 when ready

## Time: ~30 minutes
EOF
    
    print_success "Module 1 setup completed"
    print_success "First module ready ($(get_elapsed_time))"
}

# Azure quick check
quick_azure_check() {
    print_step 4 "Azure Quick Check (30s)"
    
    if command_exists "az"; then
        if az account show >/dev/null 2>&1; then
            local subscription=$(az account show --query name -o tsv)
            print_success "Azure CLI authenticated: $subscription"
        else
            print_warning "Azure CLI not authenticated (run 'az login' later)"
        fi
    else
        print_warning "Azure CLI not installed (install later for cloud modules)"
    fi
    
    print_success "Azure check completed ($(get_elapsed_time))"
}

# Final setup and instructions
final_setup() {
    print_step 5 "Final Setup & Next Steps (30s)"
    
    # Create quick reference
    cat > QUICK_REFERENCE.md << 'EOF'
# Quick Reference - AI Workshop

## Getting Started
1. **Activate Python environment**: `source venv/bin/activate`
2. **Open VS Code**: `code .`
3. **Start with Module 1**: `code modules/module-01-introduction/exercises/hello_ai.py`

## Essential Commands
- **Validate setup**: `./scripts/validate-prerequisites.sh`
- **Full setup**: `./scripts/setup-workshop.sh`
- **Clean up Azure**: `./scripts/cleanup-resources.sh`

## GitHub Copilot Tips
- Type descriptive comments for better suggestions
- Use `Ctrl+Space` to trigger suggestions manually
- Press `Tab` to accept, `Esc` to reject
- Try `Ctrl+Shift+P` → "GitHub Copilot: Open Chat"

## Next Steps
1. Complete Module 1 exercises
2. Install missing tools (see PREREQUISITES.md)
3. Set up Azure account (for modules 12+)
4. Configure GitHub Copilot if needed

## Need Help?
- Check TROUBLESHOOTING.md
- Read FAQ.md
- Visit GitHub Discussions
EOF
    
    # Create simple .gitignore
    cat > .gitignore << 'EOF'
# Python
__pycache__/
*.pyc
venv/
.env

# VS Code
.vscode/settings.json

# OS
.DS_Store
Thumbs.db

# Logs
*.log
EOF
    
    print_success "Quick reference created"
    print_success "Final setup completed ($(get_elapsed_time))"
}

# Show success message and next steps
show_success() {
    local total_time=$(get_elapsed_time)
    
    echo
    print_success "🎉 Quick start completed in $total_time! 🎉"
    echo
    print_status "You're ready to start coding with AI!"
    echo
    echo -e "${CYAN}Next Steps:${NC}"
    echo "1. 📖 Open VS Code: ${GREEN}code .${NC}"
    echo "2. 🤖 Start coding: ${GREEN}code modules/module-01-introduction/exercises/hello_ai.py${NC}"
    echo "3. 🚀 Activate Python: ${GREEN}source venv/bin/activate${NC}"
    echo "4. 📚 Read: ${GREEN}QUICK_REFERENCE.md${NC}"
    echo
    echo -e "${YELLOW}Pro Tips:${NC}"
    echo "• Type comments describing what you want → Press Tab"
    echo "• Use Ctrl+Shift+P → 'GitHub Copilot: Open Chat'"
    echo "• Experiment with different prompting styles"
    echo
    echo -e "${BLUE}When you're ready for more:${NC}"
    echo "• Run full setup: ${GREEN}./scripts/setup-workshop.sh${NC}"
    echo "• Validate everything: ${GREEN}./scripts/validate-prerequisites.sh${NC}"
    echo "• Read complete docs: ${GREEN}README.md${NC}"
    echo
    print_success "Happy coding with AI! 🤖✨"
}

# Main execution
main() {
    print_banner
    
    print_status "Starting 5-minute quick setup..."
    print_status "Perfect for getting a taste of AI-powered development!"
    echo
    
    quick_prereq_check
    quick_env_setup
    download_first_module
    quick_azure_check
    final_setup
    
    show_success
}

# Error handling
trap 'print_error "Quick start failed at step $current_step. See TROUBLESHOOTING.md for help."' ERR

# Run main function
main "$@"
