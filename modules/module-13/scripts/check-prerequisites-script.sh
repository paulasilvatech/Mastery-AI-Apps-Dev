#!/bin/bash
# Module 13: Prerequisites Check Script
# This script verifies all required tools and configurations for Infrastructure as Code with Bicep

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "======================================"
echo "Module 13: Prerequisites Check"
echo "======================================"
echo ""

# Track overall status
PREREQUISITES_MET=true

# Function to check if a command exists
check_command() {
    local cmd=$1
    local name=$2
    local install_hint=$3
    
    if command -v $cmd &> /dev/null; then
        echo -e "${GREEN}✓${NC} $name is installed"
        $cmd --version 2>/dev/null || echo "  Version information not available"
    else
        echo -e "${RED}✗${NC} $name is not installed"
        echo -e "  ${YELLOW}Install hint:${NC} $install_hint"
        PREREQUISITES_MET=false
    fi
    echo ""
}

# Function to check Azure CLI extensions
check_az_extension() {
    local extension=$1
    local name=$2
    
    if az extension show --name $extension &> /dev/null; then
        echo -e "${GREEN}✓${NC} Azure CLI extension '$name' is installed"
    else
        echo -e "${YELLOW}!${NC} Azure CLI extension '$name' is not installed"
        echo -e "  Installing extension..."
        az extension add --name $extension --yes
    fi
}

# Check for required tools
echo "Checking required tools..."
echo "------------------------"

# Azure CLI
check_command "az" "Azure CLI" "brew install azure-cli (macOS) or curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash (Linux)"

# Git
check_command "git" "Git" "https://git-scm.com/downloads"

# Visual Studio Code (optional but recommended)
check_command "code" "Visual Studio Code" "https://code.visualstudio.com/download"

# GitHub CLI (optional but recommended)
check_command "gh" "GitHub CLI" "brew install gh (macOS) or https://cli.github.com/"

# Check Azure CLI configuration
echo "Checking Azure configuration..."
echo "------------------------------"

if command -v az &> /dev/null; then
    # Check if logged in
    if az account show &> /dev/null; then
        echo -e "${GREEN}✓${NC} Azure CLI is logged in"
        CURRENT_SUB=$(az account show --query name -o tsv)
        echo "  Current subscription: $CURRENT_SUB"
    else
        echo -e "${RED}✗${NC} Azure CLI is not logged in"
        echo -e "  ${YELLOW}Run:${NC} az login"
        PREREQUISITES_MET=false
    fi
    echo ""
    
    # Check for Bicep
    echo "Checking Bicep installation..."
    if az bicep version &> /dev/null; then
        echo -e "${GREEN}✓${NC} Bicep is installed"
        az bicep version
    else
        echo -e "${YELLOW}!${NC} Bicep is not installed"
        echo "  Installing Bicep..."
        az bicep install
    fi
    echo ""
    
    # Check for required extensions
    echo "Checking Azure CLI extensions..."
    check_az_extension "account" "Account Management"
    check_az_extension "resource-graph" "Resource Graph"
else
    echo -e "${YELLOW}!${NC} Skipping Azure configuration check (Azure CLI not installed)"
fi
echo ""

# Check GitHub configuration
echo "Checking GitHub configuration..."
echo "--------------------------------"

if command -v gh &> /dev/null; then
    if gh auth status &> /dev/null; then
        echo -e "${GREEN}✓${NC} GitHub CLI is authenticated"
    else
        echo -e "${YELLOW}!${NC} GitHub CLI is not authenticated"
        echo -e "  ${YELLOW}Run:${NC} gh auth login"
    fi
else
    echo -e "${YELLOW}!${NC} GitHub CLI not installed (optional)"
fi
echo ""

# Check VS Code extensions
echo "Checking VS Code extensions..."
echo "------------------------------"

if command -v code &> /dev/null; then
    # Check for Bicep extension
    if code --list-extensions | grep -q "ms-azuretools.vscode-bicep"; then
        echo -e "${GREEN}✓${NC} Bicep VS Code extension is installed"
    else
        echo -e "${YELLOW}!${NC} Bicep VS Code extension is not installed"
        echo -e "  ${YELLOW}Install:${NC} code --install-extension ms-azuretools.vscode-bicep"
    fi
    
    # Check for Azure Tools extension
    if code --list-extensions | grep -q "ms-vscode.vscode-node-azure-pack"; then
        echo -e "${GREEN}✓${NC} Azure Tools extension is installed"
    else
        echo -e "${YELLOW}!${NC} Azure Tools extension is not installed (recommended)"
        echo -e "  ${YELLOW}Install:${NC} code --install-extension ms-vscode.vscode-node-azure-pack"
    fi
    
    # Check for GitHub Copilot
    if code --list-extensions | grep -q "GitHub.copilot"; then
        echo -e "${GREEN}✓${NC} GitHub Copilot extension is installed"
    else
        echo -e "${YELLOW}!${NC} GitHub Copilot extension is not installed"
        echo -e "  ${YELLOW}Install:${NC} code --install-extension GitHub.copilot"
    fi
else
    echo -e "${YELLOW}!${NC} VS Code not installed (recommended)"
fi
echo ""

# Check environment
echo "Checking environment..."
echo "----------------------"

# Check for .env file
if [ -f "../.env.example" ]; then
    if [ -f "../.env" ]; then
        echo -e "${GREEN}✓${NC} .env file exists"
    else
        echo -e "${YELLOW}!${NC} .env file not found"
        echo -e "  ${YELLOW}Create from template:${NC} cp ../.env.example ../.env"
    fi
else
    echo -e "${YELLOW}!${NC} No .env.example template found"
fi

# Check for resource group
if command -v az &> /dev/null && az account show &> /dev/null; then
    echo ""
    echo "Checking Azure resources..."
    RG_EXISTS=$(az group exists --name rg-module13-shared 2>/dev/null || echo "false")
    if [ "$RG_EXISTS" == "true" ]; then
        echo -e "${GREEN}✓${NC} Shared resource group exists"
    else
        echo -e "${YELLOW}!${NC} Shared resource group does not exist"
        echo -e "  ${YELLOW}Will be created during setup${NC}"
    fi
fi

# Summary
echo ""
echo "======================================"
echo "Prerequisites Check Summary"
echo "======================================"

if [ "$PREREQUISITES_MET" = true ]; then
    echo -e "${GREEN}✓ All required prerequisites are met!${NC}"
    echo ""
    echo "You're ready to start Module 13!"
    echo "Run './setup-module.sh' to set up the module environment."
    exit 0
else
    echo -e "${RED}✗ Some prerequisites are missing.${NC}"
    echo ""
    echo "Please install the missing tools and run this script again."
    echo "For detailed requirements, see prerequisites.md"
    exit 1
fi 