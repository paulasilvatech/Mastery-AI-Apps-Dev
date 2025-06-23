#!/bin/bash
# Setup script for Module 13 - Infrastructure as Code

echo "🚀 Setting up Module 13 - Infrastructure as Code"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check prerequisites
print_message "$YELLOW" "\n📋 Checking prerequisites..."

# Check Azure CLI
if ! command -v az &> /dev/null; then
    print_message "$RED" "❌ Azure CLI not found. Please install it first."
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    print_message "$RED" "❌ Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

# Check Bicep CLI
if ! az bicep version &> /dev/null; then
    print_message "$YELLOW" "Installing Bicep CLI..."
    az bicep install
fi

# Check VS Code
if ! command -v code &> /dev/null; then
    print_message "$YELLOW" "⚠️  VS Code not found. Please install it for the best experience."
    echo "Visit: https://code.visualstudio.com/"
fi

# Install VS Code extensions
if command -v code &> /dev/null; then
    print_message "$YELLOW" "\n📦 Installing VS Code extensions..."
    code --install-extension ms-azuretools.vscode-bicep
    code --install-extension ms-vscode.azure-account
    code --install-extension ms-azuretools.vscode-azureresourcegroups
fi

# Create working directory structure
print_message "$YELLOW" "\n📁 Creating directory structure..."
mkdir -p workspace/{dev,staging,prod}
mkdir -p modules/shared
mkdir -p .github/workflows

# Set Azure subscription (optional)
print_message "$YELLOW" "\n🔧 Current Azure subscription:"
az account show --query "{Name:name, ID:id}" -o table

print_message "$GREEN" "\n✅ Module 13 setup complete!"
print_message "$YELLOW" "\n📚 Next steps:"
echo "1. Navigate to exercises/exercise1-bicep-basics"
echo "2. Start with the instructions in instructions/part1.md"
echo "3. Use 'code .' to open VS Code in the exercise directory"