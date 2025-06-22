#!/bin/bash

# Mastery AI Code Development Workshop - Setup Script
# This script sets up the complete workshop environment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Workshop configuration
WORKSHOP_NAME="Mastery AI Code Development"
REQUIRED_TOOLS=("git" "node" "python3" "docker" "az" "code")
REQUIRED_VERSIONS=(
    "git:2.38.0"
    "node:18.0.0"
    "python3:3.11.0"
    "docker:24.0.0"
    "az:2.50.0"
)

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_banner() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║           🤖 Mastery AI Code Development Workshop 🤖             ║
║                                                                  ║
║    Complete 30-Module Journey to AI Development Mastery         ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get version of a command
get_version() {
    local cmd=$1
    case $cmd in
        "git")
            git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
            ;;
        "node")
            node --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
            ;;
        "python3")
            python3 --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
            ;;
        "docker")
            docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
            ;;
        "az")
            az version --output tsv | grep azure-cli | cut -f2
            ;;
        "code")
            code --version | head -1
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Function to compare versions
version_compare() {
    local version1=$1
    local version2=$2
    
    # Convert versions to comparable format
    v1=$(echo "$version1" | tr '.' ' ' | awk '{printf "%03d%03d%03d", $1, $2, $3}')
    v2=$(echo "$version2" | tr '.' ' ' | awk '{printf "%03d%03d%03d", $1, $2, $3}')
    
    if [ "$v1" -ge "$v2" ]; then
        return 0  # version1 >= version2
    else
        return 1  # version1 < version2
    fi
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    local all_good=true
    
    # Check OS
    case "$(uname -s)" in
        Linux*)     OS="Linux";;
        Darwin*)    OS="macOS";;
        CYGWIN*|MINGW*|MSYS*) OS="Windows";;
        *)          OS="Unknown";;
    esac
    print_status "Operating System: $OS"
    
    # Check required tools
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if command_exists "$tool"; then
            local version=$(get_version "$tool")
            print_success "$tool is installed (version: $version)"
        else
            print_error "$tool is not installed"
            all_good=false
        fi
    done
    
    # Check versions
    for requirement in "${REQUIRED_VERSIONS[@]}"; do
        local tool=$(echo "$requirement" | cut -d':' -f1)
        local min_version=$(echo "$requirement" | cut -d':' -f2)
        
        if command_exists "$tool"; then
            local current_version=$(get_version "$tool")
            if version_compare "$current_version" "$min_version"; then
                print_success "$tool version $current_version meets requirement (>= $min_version)"
            else
                print_warning "$tool version $current_version is below requirement ($min_version)"
                print_status "Please update $tool to version $min_version or higher"
            fi
        fi
    done
    
    if [ "$all_good" = false ]; then
        print_error "Some prerequisites are missing. Please install them before continuing."
        print_status "See PREREQUISITES.md for installation instructions."
        exit 1
    fi
    
    print_success "All prerequisites check passed!"
}

# Function to check Azure authentication
check_azure_auth() {
    print_status "Checking Azure authentication..."
    
    if ! az account show &>/dev/null; then
        print_warning "Not logged into Azure. Starting login process..."
        az login
        
        if ! az account show &>/dev/null; then
            print_error "Azure login failed"
            exit 1
        fi
    fi
    
    local subscription=$(az account show --query name -o tsv)
    local tenant=$(az account show --query tenantId -o tsv)
    print_success "Logged into Azure subscription: $subscription"
    print_status "Tenant ID: $tenant"
}

# Function to check GitHub authentication
check_github_auth() {
    print_status "Checking GitHub authentication..."
    
    if command_exists "gh"; then
        if ! gh auth status &>/dev/null; then
            print_warning "Not authenticated with GitHub CLI"
            print_status "Please run: gh auth login"
        else
            local user=$(gh api user --jq .login)
            print_success "Authenticated with GitHub as: $user"
        fi
    else
        print_warning "GitHub CLI (gh) not installed"
        print_status "You can install it later if needed"
    fi
}

# Function to check GitHub Copilot
check_copilot() {
    print_status "Checking GitHub Copilot..."
    
    if command_exists "code"; then
        # Check if Copilot extension is installed
        local copilot_installed=$(code --list-extensions | grep -c "github.copilot" || true)
        
        if [ "$copilot_installed" -gt 0 ]; then
            print_success "GitHub Copilot extension is installed in VS Code"
        else
            print_warning "GitHub Copilot extension not found in VS Code"
            print_status "Please install the GitHub Copilot extension"
        fi
    fi
}

# Function to setup Python environment
setup_python_env() {
    print_status "Setting up Python environment..."
    
    # Create virtual environment
    if [ ! -d "venv" ]; then
        print_status "Creating Python virtual environment..."
        python3 -m venv venv
        print_success "Virtual environment created"
    else
        print_status "Virtual environment already exists"
    fi
    
    # Activate virtual environment
    source venv/bin/activate
    print_status "Activated virtual environment"
    
    # Upgrade pip
    print_status "Upgrading pip..."
    pip install --upgrade pip
    
    # Install common packages
    print_status "Installing common Python packages..."
    pip install -r requirements.txt 2>/dev/null || {
        print_status "requirements.txt not found, installing basic packages..."
        pip install requests azure-identity azure-keyvault azure-storage-blob
        pip install fastapi uvicorn pandas numpy matplotlib
        pip install pytest pytest-cov black flake8 mypy
        pip install python-dotenv pydantic
    }
    
    print_success "Python environment setup complete"
}

# Function to setup Node.js environment
setup_node_env() {
    print_status "Setting up Node.js environment..."
    
    if [ -f "package.json" ]; then
        print_status "Installing Node.js dependencies..."
        npm install
        print_success "Node.js dependencies installed"
    else
        print_status "No package.json found, creating basic setup..."
        npm init -y >/dev/null
        npm install --save-dev typescript @types/node
        npm install express axios dotenv
        print_success "Basic Node.js setup complete"
    fi
}

# Function to setup Docker environment
setup_docker_env() {
    print_status "Setting up Docker environment..."
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        print_warning "Docker is not running. Please start Docker Desktop."
        print_status "Skipping Docker setup for now..."
        return
    fi
    
    # Pull common base images
    print_status "Pulling common Docker images..."
    docker pull python:3.11-slim
    docker pull node:18-alpine
    docker pull nginx:alpine
    docker pull redis:alpine
    
    print_success "Docker environment setup complete"
}

# Function to create workspace structure
create_workspace() {
    print_status "Creating workspace structure..."
    
    # Create directories
    local dirs=(
        "workspace"
        "workspace/projects"
        "workspace/templates"
        "workspace/data"
        "workspace/docs"
        "workspace/logs"
        ".vscode"
    )
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_status "Created directory: $dir"
        fi
    done
    
    # Create VS Code settings
    cat > .vscode/settings.json << 'EOF'
{
    "github.copilot.enable": {
        "*": true,
        "yaml": false,
        "plaintext": false,
        "markdown": false
    },
    "python.defaultInterpreterPath": "./venv/bin/python",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": false,
    "python.linting.flake8Enabled": true,
    "python.formatting.provider": "black",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.organizeImports": true
    },
    "files.associations": {
        "*.bicep": "bicep"
    }
}
EOF
    
    # Create .gitignore
    cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
venv/
env/

# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.npm
.yarn/

# IDEs
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Azure
.azure/
*.bicep.json

# Logs
logs/
*.log

# Environment variables
.env
.env.local
.env.*.local

# Temporary files
tmp/
temp/
*.tmp
EOF
    
    print_success "Workspace structure created"
}

# Function to setup Azure resources
setup_azure_resources() {
    print_status "Setting up Azure resources..."
    
    # Get user input for resource group
    read -p "Enter resource group name (or press Enter for default): " rg_name
    rg_name=${rg_name:-"rg-workshop-dev-$(date +%s)"}
    
    read -p "Enter Azure region (default: eastus2): " location
    location=${location:-"eastus2"}
    
    # Create resource group
    print_status "Creating resource group: $rg_name in $location"
    az group create --name "$rg_name" --location "$location" --output table
    
    # Store configuration
    cat > .azure-config << EOF
RESOURCE_GROUP=$rg_name
LOCATION=$location
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
EOF
    
    print_success "Azure resources setup complete"
    print_status "Configuration saved to .azure-config"
}

# Function to verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    local issues=0
    
    # Check Python environment
    if [ -d "venv" ] && source venv/bin/activate && python -c "import requests, azure.identity" 2>/dev/null; then
        print_success "Python environment is working"
    else
        print_error "Python environment has issues"
        issues=$((issues + 1))
    fi
    
    # Check Node.js environment
    if [ -f "package.json" ] && npm list >/dev/null 2>&1; then
        print_success "Node.js environment is working"
    else
        print_warning "Node.js environment has issues (optional)"
    fi
    
    # Check Docker
    if docker info >/dev/null 2>&1; then
        print_success "Docker is working"
    else
        print_warning "Docker is not available (optional for some modules)"
    fi
    
    # Check Azure CLI
    if az account show >/dev/null 2>&1; then
        print_success "Azure CLI is authenticated"
    else
        print_error "Azure CLI authentication issues"
        issues=$((issues + 1))
    fi
    
    if [ $issues -eq 0 ]; then
        print_success "All verifications passed!"
        return 0
    else
        print_error "$issues verification(s) failed"
        return 1
    fi
}

# Function to show next steps
show_next_steps() {
    print_success "Workshop setup complete! 🎉"
    echo
    print_status "Next steps:"
    echo "1. 📖 Read the README.md for workshop overview"
    echo "2. 🚀 Start with Module 1: cd modules/module-01-introduction"
    echo "3. 💻 Open VS Code: code ."
    echo "4. 🤖 Ensure GitHub Copilot is working"
    echo "5. 📚 Check out the documentation in docs/"
    echo
    print_status "Useful commands:"
    echo "• Activate Python environment: source venv/bin/activate"
    echo "• Check Azure status: az account show"
    echo "• Validate environment: ./scripts/validate-prerequisites.sh"
    echo "• Clean up resources: ./scripts/cleanup-resources.sh"
    echo
    print_status "Need help? Check:"
    echo "• TROUBLESHOOTING.md for common issues"
    echo "• FAQ.md for frequently asked questions"
    echo "• GitHub Discussions for community support"
    echo
    print_success "Happy coding with AI! 🤖✨"
}

# Main execution
main() {
    print_banner
    
    print_status "Starting workshop setup..."
    print_status "This will take a few minutes..."
    echo
    
    # Run setup steps
    check_prerequisites
    check_azure_auth
    check_github_auth
    check_copilot
    create_workspace
    setup_python_env
    setup_node_env
    setup_docker_env
    
    # Ask if user wants to setup Azure resources
    echo
    read -p "Do you want to setup Azure resources now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_azure_resources
    else
        print_status "Skipping Azure resource setup. You can run this later if needed."
    fi
    
    echo
    if verify_installation; then
        show_next_steps
    else
        print_error "Setup completed with some issues. Please check the output above."
        print_status "You can try running the setup again or check TROUBLESHOOTING.md"
        exit 1
    fi
}

# Run main function
main "$@"
