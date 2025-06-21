#!/bin/bash

# ========================================================================
# Mastery AI Apps and Development Workshop - Setup Script
# ========================================================================
# This script sets up the complete workshop environment
# Supports: macOS, Linux, WSL2
# ========================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Workshop variables
WORKSHOP_NAME="Mastery AI Apps and Development Workshop"
REQUIRED_PYTHON_VERSION="3.11"
REQUIRED_NODE_VERSION="18"
REQUIRED_DOTNET_VERSION="8"

# Functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
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

check_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    print_success "Detected OS: $OS"
}

check_command() {
    if command -v $1 &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_error "$1 is not installed"
        return 1
    fi
}

check_python() {
    if check_command python3; then
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
        REQUIRED_VERSION=$(echo $REQUIRED_PYTHON_VERSION | cut -d'.' -f1,2)
        
        if [[ $(echo "$PYTHON_VERSION >= $REQUIRED_VERSION" | bc -l) -eq 1 ]]; then
            print_success "Python $PYTHON_VERSION meets requirement (>= $REQUIRED_PYTHON_VERSION)"
        else
            print_error "Python $PYTHON_VERSION does not meet requirement (>= $REQUIRED_PYTHON_VERSION)"
            return 1
        fi
    else
        return 1
    fi
}

check_node() {
    if check_command node; then
        NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        
        if [[ $NODE_VERSION -ge $REQUIRED_NODE_VERSION ]]; then
            print_success "Node.js v$NODE_VERSION meets requirement (>= $REQUIRED_NODE_VERSION)"
        else
            print_error "Node.js v$NODE_VERSION does not meet requirement (>= $REQUIRED_NODE_VERSION)"
            return 1
        fi
    else
        return 1
    fi
}

check_dotnet() {
    if check_command dotnet; then
        DOTNET_VERSION=$(dotnet --version | cut -d'.' -f1)
        
        if [[ $DOTNET_VERSION -ge $REQUIRED_DOTNET_VERSION ]]; then
            print_success ".NET SDK $DOTNET_VERSION meets requirement (>= $REQUIRED_DOTNET_VERSION)"
        else
            print_error ".NET SDK $DOTNET_VERSION does not meet requirement (>= $REQUIRED_DOTNET_VERSION)"
            return 1
        fi
    else
        return 1
    fi
}

install_python() {
    print_header "Installing Python $REQUIRED_PYTHON_VERSION"
    
    case $OS in
        macos)
            if check_command brew; then
                brew install python@$REQUIRED_PYTHON_VERSION
            else
                print_error "Homebrew not found. Please install from https://brew.sh"
                exit 1
            fi
            ;;
        linux)
            sudo apt update
            sudo apt install -y python$REQUIRED_PYTHON_VERSION python3-pip python3-venv
            ;;
        *)
            print_error "Please install Python $REQUIRED_PYTHON_VERSION manually"
            exit 1
            ;;
    esac
}

install_node() {
    print_header "Installing Node.js $REQUIRED_NODE_VERSION"
    
    # Install using Node Version Manager (nvm)
    if [[ ! -d "$HOME/.nvm" ]]; then
        print_warning "Installing NVM (Node Version Manager)..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
    
    nvm install $REQUIRED_NODE_VERSION
    nvm use $REQUIRED_NODE_VERSION
    nvm alias default $REQUIRED_NODE_VERSION
}

install_dotnet() {
    print_header "Installing .NET SDK $REQUIRED_DOTNET_VERSION"
    
    case $OS in
        macos)
            if check_command brew; then
                brew install --cask dotnet-sdk
            else
                print_error "Please install .NET SDK from https://dotnet.microsoft.com/download"
                exit 1
            fi
            ;;
        linux)
            # Microsoft package repository
            wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
            sudo dpkg -i packages-microsoft-prod.deb
            rm packages-microsoft-prod.deb
            
            sudo apt update
            sudo apt install -y dotnet-sdk-$REQUIRED_DOTNET_VERSION.0
            ;;
        *)
            print_error "Please install .NET SDK from https://dotnet.microsoft.com/download"
            exit 1
            ;;
    esac
}

install_docker() {
    print_header "Installing Docker"
    
    case $OS in
        macos)
            print_warning "Please install Docker Desktop from https://www.docker.com/products/docker-desktop"
            ;;
        linux)
            # Docker installation for Ubuntu/Debian
            sudo apt update
            sudo apt install -y \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
            
            # Add Docker's official GPG key
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            
            # Set up repository
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
              $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Install Docker Engine
            sudo apt update
            sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            
            # Add user to docker group
            sudo usermod -aG docker $USER
            print_warning "Please log out and back in for docker group changes to take effect"
            ;;
        *)
            print_error "Please install Docker from https://www.docker.com/get-started"
            exit 1
            ;;
    esac
}

install_azure_cli() {
    print_header "Installing Azure CLI"
    
    case $OS in
        macos)
            if check_command brew; then
                brew install azure-cli
            fi
            ;;
        linux)
            curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
            ;;
        *)
            print_error "Please install Azure CLI from https://docs.microsoft.com/cli/azure/install-azure-cli"
            exit 1
            ;;
    esac
}

install_github_cli() {
    print_header "Installing GitHub CLI"
    
    case $OS in
        macos)
            if check_command brew; then
                brew install gh
            fi
            ;;
        linux)
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt update
            sudo apt install gh -y
            ;;
        *)
            print_error "Please install GitHub CLI from https://cli.github.com/"
            exit 1
            ;;
    esac
}

setup_vscode() {
    print_header "Setting up VS Code"
    
    if ! check_command code; then
        print_warning "VS Code not found in PATH"
        print_warning "Please install from https://code.visualstudio.com/"
        print_warning "Make sure to add 'code' to PATH during installation"
        return
    fi
    
    print_success "Installing VS Code extensions..."
    
    # Essential extensions for the workshop
    extensions=(
        "GitHub.copilot"
        "GitHub.copilot-chat"
        "ms-python.python"
        "ms-python.vscode-pylance"
        "ms-dotnettools.csharp"
        "ms-dotnettools.vscode-dotnet-runtime"
        "ms-azuretools.vscode-docker"
        "ms-vscode.azure-account"
        "ms-azuretools.vscode-azureappservice"
        "ms-azuretools.vscode-azurefunctions"
        "ms-kubernetes-tools.vscode-kubernetes-tools"
        "hashicorp.terraform"
        "ms-vscode.vscode-typescript-next"
        "esbenp.prettier-vscode"
        "dbaeumer.vscode-eslint"
        "eamodio.gitlens"
    )
    
    for ext in "${extensions[@]}"; do
        code --install-extension "$ext" --force
        print_success "Installed: $ext"
    done
}

setup_python_environment() {
    print_header "Setting up Python environment"
    
    # Create virtual environment for the workshop
    python3 -m venv .venv
    print_success "Created Python virtual environment"
    
    # Activate and upgrade pip
    source .venv/bin/activate
    pip install --upgrade pip
    
    # Install base packages
    pip install -r requirements.txt 2>/dev/null || {
        print_warning "No requirements.txt found, installing base packages..."
        pip install \
            requests \
            python-dotenv \
            pytest \
            black \
            flake8 \
            mypy \
            ipython \
            notebook
    }
    
    print_success "Python environment setup complete"
    print_warning "Run 'source .venv/bin/activate' to activate the environment"
}

configure_git() {
    print_header "Configuring Git"
    
    # Check if git config is already set
    if [[ -z $(git config --global user.name) ]]; then
        read -p "Enter your Git username: " git_username
        git config --global user.name "$git_username"
    fi
    
    if [[ -z $(git config --global user.email) ]]; then
        read -p "Enter your Git email: " git_email
        git config --global user.email "$git_email"
    fi
    
    # Set useful Git aliases for the workshop
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.st status
    git config --global alias.last 'log -1 HEAD'
    
    print_success "Git configuration complete"
}

setup_azure() {
    print_header "Setting up Azure"
    
    if check_command az; then
        print_warning "Please login to Azure:"
        az login
        
        # List subscriptions
        print_success "Available Azure subscriptions:"
        az account list --output table
        
        # Set default subscription if multiple
        read -p "Enter subscription ID to use (press Enter to skip): " sub_id
        if [[ ! -z "$sub_id" ]]; then
            az account set --subscription "$sub_id"
            print_success "Set default subscription"
        fi
    else
        print_warning "Azure CLI not installed, skipping Azure setup"
    fi
}

setup_github() {
    print_header "Setting up GitHub"
    
    if check_command gh; then
        print_warning "Please authenticate with GitHub:"
        gh auth login
        
        # Check GitHub Copilot status
        if gh copilot status &>/dev/null; then
            print_success "GitHub Copilot is active"
        else
            print_warning "GitHub Copilot is not active. Please ensure you have an active subscription"
        fi
    else
        print_warning "GitHub CLI not installed, skipping GitHub setup"
    fi
}

create_workshop_directories() {
    print_header "Creating workshop directories"
    
    directories=(
        "infrastructure/bicep"
        "infrastructure/terraform"
        "infrastructure/github-actions"
        "infrastructure/arm-templates"
        "docs"
        ".github/workflows"
    )
    
    for dir in "${directories[@]}"; do
        mkdir -p "$dir"
        print_success "Created: $dir"
    done
}

main() {
    clear
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║     Mastery AI Apps and Development Workshop Setup          ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Check OS
    check_os
    
    # Check and install prerequisites
    print_header "Checking prerequisites"
    
    check_command git || {
        print_error "Git is required. Please install git first."
        exit 1
    }
    
    # Python
    check_python || install_python
    
    # Node.js
    check_node || install_node
    
    # .NET
    check_dotnet || install_dotnet
    
    # Docker
    check_command docker || install_docker
    
    # Azure CLI
    check_command az || install_azure_cli
    
    # GitHub CLI
    check_command gh || install_github_cli
    
    # Setup environments
    setup_vscode
    setup_python_environment
    configure_git
    setup_azure
    setup_github
    create_workshop_directories
    
    # Final summary
    print_header "Setup Complete!"
    
    echo -e "${GREEN}✓ Workshop environment is ready!${NC}"
    echo -e "\nNext steps:"
    echo -e "1. Activate Python environment: ${YELLOW}source .venv/bin/activate${NC}"
    echo -e "2. Start with Module 1: ${YELLOW}cd modules/module-01${NC}"
    echo -e "3. Open in VS Code: ${YELLOW}code .${NC}"
    echo -e "\nRun ${YELLOW}./scripts/validate-prerequisites.sh${NC} to verify everything is working"
    echo -e "\nHappy learning! 🚀"
}

# Run main function
main
