#!/bin/bash
# Complete workshop setup script
# Sets up the entire Mastery AI Code Development Workshop environment

set -e

# Script metadata
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="Workshop Complete Setup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
WORKSHOP_DIR="$HOME/mastery-ai-workshop"
PYTHON_VERSION="3.11"
NODE_VERSION="18"
DOTNET_VERSION="8.0"
SKIP_DEPENDENCIES=false
INSTALL_OPTIONAL=false
CONFIGURE_AZURE=true
SETUP_GITHUB=true
VERBOSE=false

# Installation progress
TOTAL_STEPS=20
CURRENT_STEP=0

# Function to print colored output
print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print step
print_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local step_name="$1"
    print_colored $BLUE "[$CURRENT_STEP/$TOTAL_STEPS] $step_name"
}

# Function to print header
print_header() {
    clear
    echo ""
    print_colored $PURPLE "╔══════════════════════════════════════════════════════════════╗"
    print_colored $PURPLE "║          🚀 Mastery AI Code Development Workshop            ║"
    print_colored $PURPLE "║                    Complete Setup Script                    ║"
    print_colored $PURPLE "║                     Version $SCRIPT_VERSION                          ║"
    print_colored $PURPLE "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    print_colored $CYAN "Welcome to the most comprehensive AI development workshop!"
    print_colored $CYAN "This script will set up everything you need for all 30 modules."
    echo ""
}

# Function to show help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Set up the complete Mastery AI Code Development Workshop environment.

OPTIONS:
    --skip-deps         Skip dependency installation
    --install-optional  Install optional tools (Docker Desktop, VS Code extensions)
    --no-azure         Skip Azure CLI setup
    --no-github        Skip GitHub setup
    -v, --verbose      Enable verbose output
    -h, --help         Show this help message

WHAT THIS SCRIPT DOES:
    ✅ Checks system requirements
    ✅ Installs development tools (Python, Node.js, .NET)
    ✅ Sets up Azure CLI and authentication
    ✅ Configures GitHub CLI and Copilot
    ✅ Installs VS Code extensions
    ✅ Creates workspace structure
    ✅ Downloads workshop materials
    ✅ Configures environment variables
    ✅ Sets up development environment
    ✅ Validates installation

SUPPORTED PLATFORMS:
    - Windows 10/11 (with WSL2)
    - macOS 12+ (Intel & Apple Silicon)
    - Ubuntu 20.04+ / Debian 11+
    - Red Hat Enterprise Linux 8+

EOF
}

# Function to detect OS
detect_os() {
    print_step "Detecting operating system"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$NAME
            VER=$VERSION_ID
        else
            OS="Unknown Linux"
        fi
        PACKAGE_MANAGER="apt"
        [ -f /etc/redhat-release ] && PACKAGE_MANAGER="yum"
        [ -f /etc/arch-release ] && PACKAGE_MANAGER="pacman"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
        VER=$(sw_vers -productVersion)
        PACKAGE_MANAGER="brew"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="Windows"
        VER="10/11"
        PACKAGE_MANAGER="choco"
    else
        OS="Unknown"
    fi
    
    print_colored $GREEN "✅ Detected: $OS $VER"
    
    if [ "$OS" == "Unknown" ]; then
        print_colored $RED "❌ Unsupported operating system"
        exit 1
    fi
}

# Function to check system requirements
check_system_requirements() {
    print_step "Checking system requirements"
    
    # Check available memory
    if [[ "$OS" == "Linux"* ]]; then
        MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
    elif [[ "$OS" == "macOS" ]]; then
        MEMORY_GB=$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))
    else
        MEMORY_GB=16  # Assume sufficient on Windows
    fi
    
    if [ "$MEMORY_GB" -lt 8 ]; then
        print_colored $YELLOW "⚠️  Warning: Only ${MEMORY_GB}GB RAM detected. 16GB+ recommended."
    else
        print_colored $GREEN "✅ Memory: ${MEMORY_GB}GB"
    fi
    
    # Check available disk space
    DISK_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$DISK_SPACE" -lt 50 ]; then
        print_colored $YELLOW "⚠️  Warning: Only ${DISK_SPACE}GB free space. 100GB+ recommended."
    else
        print_colored $GREEN "✅ Disk space: ${DISK_SPACE}GB available"
    fi
    
    # Check internet connectivity
    if ping -c 1 google.com &> /dev/null; then
        print_colored $GREEN "✅ Internet connectivity"
    else
        print_colored $RED "❌ No internet connectivity"
        exit 1
    fi
}

# Function to install package manager
install_package_manager() {
    print_step "Setting up package manager"
    
    case $PACKAGE_MANAGER in
        "brew")
            if ! command -v brew &> /dev/null; then
                print_colored $YELLOW "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                
                # Add to PATH for M1 Macs
                if [[ $(uname -m) == "arm64" ]]; then
                    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                fi
            fi
            print_colored $GREEN "✅ Homebrew ready"
            ;;
        "choco")
            if ! command -v choco &> /dev/null; then
                print_colored $YELLOW "Installing Chocolatey..."
                powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
            fi
            print_colored $GREEN "✅ Chocolatey ready"
            ;;
        "apt")
            sudo apt update
            print_colored $GREEN "✅ APT ready"
            ;;
        "yum")
            sudo yum update -y
            print_colored $GREEN "✅ YUM ready"
            ;;
    esac
}

# Function to install development tools
install_development_tools() {
    if [ "$SKIP_DEPENDENCIES" = true ]; then
        print_colored $YELLOW "⏭️  Skipping dependency installation"
        return
    fi
    
    print_step "Installing core development tools"
    
    case $PACKAGE_MANAGER in
        "brew")
            brew install git python@${PYTHON_VERSION} node@${NODE_VERSION} dotnet azure-cli
            brew install --cask visual-studio-code
            ;;
        "choco")
            choco install -y git python nodejs dotnet-sdk azure-cli vscode
            ;;
        "apt")
            # Python
            sudo apt install -y software-properties-common
            sudo add-apt-repository -y ppa:deadsnakes/ppa
            sudo apt update
            sudo apt install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-pip python${PYTHON_VERSION}-venv
            
            # Node.js
            curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
            sudo apt install -y nodejs
            
            # .NET
            wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
            sudo dpkg -i packages-microsoft-prod.deb
            sudo apt update
            sudo apt install -y dotnet-sdk-${DOTNET_VERSION}
            
            # Other tools
            sudo apt install -y git curl wget
            
            # Azure CLI
            curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
            
            # VS Code
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
            sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
            sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
            sudo apt update
            sudo apt install -y code
            ;;
    esac
    
    print_colored $GREEN "✅ Core development tools installed"
}

# Function to install GitHub CLI
install_github_cli() {
    print_step "Installing GitHub CLI"
    
    case $PACKAGE_MANAGER in
        "brew")
            brew install gh
            ;;
        "choco")
            choco install -y gh
            ;;
        "apt")
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt update
            sudo apt install -y gh
            ;;
    esac
    
    print_colored $GREEN "✅ GitHub CLI installed"
}

# Function to install optional tools
install_optional_tools() {
    if [ "$INSTALL_OPTIONAL" = false ]; then
        print_colored $YELLOW "⏭️  Skipping optional tools"
        return
    fi
    
    print_step "Installing optional tools"
    
    case $PACKAGE_MANAGER in
        "brew")
            brew install --cask docker
            brew install terraform kubectl helm
            ;;
        "choco")
            choco install -y docker-desktop terraform kubernetes-cli kubernetes-helm
            ;;
        "apt")
            # Docker
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo usermod -aG docker $USER
            
            # Terraform
            wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
            sudo apt update && sudo apt install -y terraform
            
            # kubectl
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            ;;
    esac
    
    print_colored $GREEN "✅ Optional tools installed"
}

# Function to configure Azure CLI
configure_azure() {
    if [ "$CONFIGURE_AZURE" = false ]; then
        print_colored $YELLOW "⏭️  Skipping Azure configuration"
        return
    fi
    
    print_step "Configuring Azure CLI"
    
    # Check if already logged in
    if az account show &> /dev/null; then
        print_colored $GREEN "✅ Already logged into Azure"
        SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
        print_colored $BLUE "Current subscription: $SUBSCRIPTION_NAME"
    else
        print_colored $YELLOW "Azure login required..."
        print_colored $CYAN "Please complete the login process in your browser."
        az login
        
        if az account show &> /dev/null; then
            print_colored $GREEN "✅ Azure login successful"
        else
            print_colored $RED "❌ Azure login failed"
            exit 1
        fi
    fi
    
    # Install Azure extensions
    print_colored $YELLOW "Installing Azure CLI extensions..."
    az extension add --name bicep --yes 2>/dev/null || true
    az extension add --name containerapp --yes 2>/dev/null || true
    az extension add --name k8s-extension --yes 2>/dev/null || true
    
    print_colored $GREEN "✅ Azure CLI configured"
}

# Function to configure GitHub
configure_github() {
    if [ "$SETUP_GITHUB" = false ]; then
        print_colored $YELLOW "⏭️  Skipping GitHub configuration"
        return
    fi
    
    print_step "Configuring GitHub CLI and Copilot"
    
    # Check if already authenticated
    if gh auth status &> /dev/null; then
        print_colored $GREEN "✅ Already authenticated with GitHub"
    else
        print_colored $YELLOW "GitHub authentication required..."
        print_colored $CYAN "Please complete the authentication process."
        gh auth login
        
        if gh auth status &> /dev/null; then
            print_colored $GREEN "✅ GitHub authentication successful"
        else
            print_colored $RED "❌ GitHub authentication failed"
            exit 1
        fi
    fi
    
    # Check Copilot status
    if gh copilot status &> /dev/null; then
        print_colored $GREEN "✅ GitHub Copilot is active"
    else
        print_colored $YELLOW "⚠️  GitHub Copilot not active. Please ensure you have a subscription."
    fi
}

# Function to install VS Code extensions
install_vscode_extensions() {
    print_step "Installing VS Code extensions"
    
    # Essential extensions for the workshop
    local extensions=(
        "ms-python.python"
        "ms-python.pylint"
        "ms-python.black-formatter"
        "ms-toolsai.jupyter"
        "GitHub.copilot"
        "GitHub.copilot-chat"
        "ms-vscode.azure-account"
        "ms-azuretools.vscode-azureresourcegroups"
        "ms-azuretools.vscode-azurefunctions"
        "ms-azuretools.vscode-docker"
        "ms-kubernetes-tools.vscode-kubernetes-tools"
        "ms-dotnettools.csharp"
        "ms-dotnettools.vscode-dotnet-runtime"
        "bradlc.vscode-tailwindcss"
        "esbenp.prettier-vscode"
        "ms-vscode.vscode-json"
        "redhat.vscode-yaml"
        "formulahendry.auto-rename-tag"
        "ms-vscode.powershell"
    )
    
    for extension in "${extensions[@]}"; do
        if code --list-extensions | grep -q "$extension"; then
            if [ "$VERBOSE" = true ]; then
                print_colored $GREEN "  ✓ $extension (already installed)"
            fi
        else
            print_colored $YELLOW "  Installing $extension..."
            code --install-extension "$extension" --force &> /dev/null
        fi
    done
    
    print_colored $GREEN "✅ VS Code extensions installed"
}

# Function to create workspace structure
create_workspace() {
    print_step "Creating workshop workspace"
    
    # Create main workshop directory
    mkdir -p "$WORKSHOP_DIR"
    cd "$WORKSHOP_DIR"
    
    # Create subdirectories
    mkdir -p {
        projects,
        resources,
        exercises,
        solutions,
        notes,
        scripts,
        config,
        data,
        temp
    }
    
    # Create track-specific directories
    local tracks=("fundamentals" "intermediate" "advanced" "enterprise" "ai-agents" "enterprise-mastery")
    for track in "${tracks[@]}"; do
        mkdir -p "projects/$track"
        mkdir -p "exercises/$track"
        mkdir -p "solutions/$track"
    done
    
    print_colored $GREEN "✅ Workspace structure created at $WORKSHOP_DIR"
}

# Function to download workshop materials
download_workshop_materials() {
    print_step "Downloading workshop materials"
    
    cd "$WORKSHOP_DIR"
    
    # Clone the workshop repository
    if [ ! -d "Mastery-AI-Apps-Dev" ]; then
        print_colored $YELLOW "Cloning workshop repository..."
        git clone https://github.com/paulasilvatech/Mastery-AI-Apps-Dev.git
    else
        print_colored $YELLOW "Updating workshop repository..."
        cd Mastery-AI-Apps-Dev
        git pull origin main
        cd ..
    fi
    
    # Create symbolic links for easy access
    ln -sf Mastery-AI-Apps-Dev/modules exercises/workshop-modules 2>/dev/null || true
    ln -sf Mastery-AI-Apps-Dev/infrastructure scripts/infrastructure 2>/dev/null || true
    ln -sf Mastery-AI-Apps-Dev/docs resources/docs 2>/dev/null || true
    
    print_colored $GREEN "✅ Workshop materials downloaded"
}

# Function to setup Python environment
setup_python_environment() {
    print_step "Setting up Python environment"
    
    cd "$WORKSHOP_DIR"
    
    # Create virtual environment
    python${PYTHON_VERSION} -m venv venv
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install common packages
    pip install -r Mastery-AI-Apps-Dev/requirements.txt 2>/dev/null || pip install \
        requests \
        pandas \
        numpy \
        matplotlib \
        seaborn \
        jupyter \
        pytest \
        black \
        flake8 \
        mypy \
        azure-cli \
        azure-identity \
        azure-mgmt-resource \
        openai \
        python-dotenv
    
    print_colored $GREEN "✅ Python environment configured"
}

# Function to setup Node.js environment
setup_nodejs_environment() {
    print_step "Setting up Node.js environment"
    
    cd "$WORKSHOP_DIR"
    
    # Install global packages
    npm install -g \
        typescript \
        ts-node \
        @types/node \
        eslint \
        prettier \
        nodemon \
        create-react-app \
        @angular/cli \
        @azure/static-web-apps-cli
    
    print_colored $GREEN "✅ Node.js environment configured"
}

# Function to configure environment variables
configure_environment() {
    print_step "Configuring environment variables"
    
    cd "$WORKSHOP_DIR"
    
    # Create .env file
    cat > .env << EOF
# Mastery AI Workshop Environment Configuration
WORKSHOP_DIR=$WORKSHOP_DIR
PYTHON_VERSION=$PYTHON_VERSION
NODE_VERSION=$NODE_VERSION
DOTNET_VERSION=$DOTNET_VERSION

# Azure Configuration
AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv 2>/dev/null || echo "")
AZURE_TENANT_ID=$(az account show --query tenantId -o tsv 2>/dev/null || echo "")

# Workshop Settings
WORKSHOP_TRACK=fundamentals
CURRENT_MODULE=1
COPILOT_ENABLED=true

# Development Settings
DEBUG=true
LOG_LEVEL=info
EOF
    
    # Create shell aliases
    cat > config/aliases.sh << 'EOF'
# Workshop aliases
alias workshop="cd $WORKSHOP_DIR"
alias wactivate="source $WORKSHOP_DIR/venv/bin/activate"
alias wmodule="cd $WORKSHOP_DIR/exercises/workshop-modules"
alias wdeploy="$WORKSHOP_DIR/Mastery-AI-Apps-Dev/scripts/deploy-infrastructure.sh"
alias wvalidate="$WORKSHOP_DIR/Mastery-AI-Apps-Dev/scripts/validate-modules.sh"
alias wcleanup="$WORKSHOP_DIR/Mastery-AI-Apps-Dev/scripts/cleanup-resources.sh"

# Development aliases
alias ll="ls -la"
alias la="ls -A"
alias l="ls -CF"
alias ..="cd .."
alias ...="cd ../.."

# Git aliases
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline"

# Python aliases
alias py="python"
alias pip="python -m pip"
alias pytest="python -m pytest"
alias black="python -m black"
alias flake8="python -m flake8"

# Azure aliases
alias azlogin="az login"
alias azlist="az account list"
alias azset="az account set"
alias azrg="az group list -o table"
EOF
    
    # Add to shell profile
    if [ -f ~/.bashrc ]; then
        echo "source $WORKSHOP_DIR/config/aliases.sh" >> ~/.bashrc
    fi
    if [ -f ~/.zshrc ]; then
        echo "source $WORKSHOP_DIR/config/aliases.sh" >> ~/.zshrc
    fi
    
    print_colored $GREEN "✅ Environment variables configured"
}

# Function to validate installation
validate_installation() {
    print_step "Validating installation"
    
    local validation_errors=0
    
    # Check Python
    if python${PYTHON_VERSION} --version &> /dev/null; then
        print_colored $GREEN "  ✓ Python ${PYTHON_VERSION}"
    else
        print_colored $RED "  ✗ Python ${PYTHON_VERSION}"
        validation_errors=$((validation_errors + 1))
    fi
    
    # Check Node.js
    if node --version | grep -q "v${NODE_VERSION}"; then
        print_colored $GREEN "  ✓ Node.js ${NODE_VERSION}"
    else
        print_colored $RED "  ✗ Node.js ${NODE_VERSION}"
        validation_errors=$((validation_errors + 1))
    fi
    
    # Check .NET
    if dotnet --version | grep -q "^${DOTNET_VERSION}"; then
        print_colored $GREEN "  ✓ .NET ${DOTNET_VERSION}"
    else
        print_colored $RED "  ✗ .NET ${DOTNET_VERSION}"
        validation_errors=$((validation_errors + 1))
    fi
    
    # Check Azure CLI
    if az --version &> /dev/null; then
        print_colored $GREEN "  ✓ Azure CLI"
    else
        print_colored $RED "  ✗ Azure CLI"
        validation_errors=$((validation_errors + 1))
    fi
    
    # Check GitHub CLI
    if gh --version &> /dev/null; then
        print_colored $GREEN "  ✓ GitHub CLI"
    else
        print_colored $RED "  ✗ GitHub CLI"
        validation_errors=$((validation_errors + 1))
    fi
    
    # Check VS Code
    if code --version &> /dev/null; then
        print_colored $GREEN "  ✓ VS Code"
    else
        print_colored $RED "  ✗ VS Code"
        validation_errors=$((validation_errors + 1))
    fi
    
    # Check workspace
    if [ -d "$WORKSHOP_DIR" ]; then
        print_colored $GREEN "  ✓ Workshop directory"
    else
        print_colored $RED "  ✗ Workshop directory"
        validation_errors=$((validation_errors + 1))
    fi
    
    if [ $validation_errors -eq 0 ]; then
        print_colored $GREEN "✅ All validations passed"
    else
        print_colored $RED "❌ $validation_errors validation(s) failed"
        return 1
    fi
}

# Function to show completion summary
show_completion_summary() {
    print_colored $PURPLE "╔══════════════════════════════════════════════════════════════╗"
    print_colored $PURPLE "║                    🎉 SETUP COMPLETE!                       ║"
    print_colored $PURPLE "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    print_colored $GREEN "Workshop environment successfully configured!"
    echo ""
    print_colored $BLUE "📁 Workshop directory: $WORKSHOP_DIR"
    print_colored $BLUE "🐍 Python: $PYTHON_VERSION"
    print_colored $BLUE "📦 Node.js: $NODE_VERSION"
    print_colored $BLUE "🔷 .NET: $DOTNET_VERSION"
    echo ""
    print_colored $YELLOW "Next steps:"
    print_colored $YELLOW "1. Open VS Code: code $WORKSHOP_DIR"
    print_colored $YELLOW "2. Activate Python environment: source $WORKSHOP_DIR/venv/bin/activate"
    print_colored $YELLOW "3. Start with Module 1: cd $WORKSHOP_DIR/exercises/workshop-modules/module-01"
    print_colored $YELLOW "4. Read the workshop guide: cat $WORKSHOP_DIR/Mastery-AI-Apps-Dev/README.md"
    echo ""
    print_colored $CYAN "Happy coding with AI! 🚀"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-deps)
            SKIP_DEPENDENCIES=true
            shift
            ;;
        --install-optional)
            INSTALL_OPTIONAL=true
            shift
            ;;
        --no-azure)
            CONFIGURE_AZURE=false
            shift
            ;;
        --no-github)
            SETUP_GITHUB=false
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_colored $RED "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_header
    
    # System checks
    detect_os
    check_system_requirements
    
    # Installation steps
    install_package_manager
    install_development_tools
    install_github_cli
    install_optional_tools
    
    # Configuration steps
    configure_azure
    configure_github
    install_vscode_extensions
    
    # Workshop setup
    create_workspace
    download_workshop_materials
    setup_python_environment
    setup_nodejs_environment
    configure_environment
    
    # Validation and completion
    if validate_installation; then
        show_completion_summary
    else
        print_colored $RED "Setup completed with errors. Please review the output above."
        exit 1
    fi
}

# Execute main function
main "$@"
