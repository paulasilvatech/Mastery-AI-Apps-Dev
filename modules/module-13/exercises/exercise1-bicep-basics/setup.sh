#!/bin/bash
# Exercise 1: Bicep Basics Setup Script
# This script sets up the environment for the Bicep basics exercise

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================"
echo "Exercise 1: Bicep Basics Setup"
echo "======================================${NC}"
echo ""

# Function to display progress
show_progress() {
    echo -e "${YELLOW}→${NC} $1"
}

# Function to display success
show_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to display error
show_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check prerequisites
show_progress "Checking prerequisites..."

if ! command -v az &> /dev/null; then
    show_error "Azure CLI is not installed"
    echo "Please install Azure CLI first: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

if ! az account show &> /dev/null; then
    show_error "Not logged in to Azure"
    echo "Please run: az login"
    exit 1
fi

if ! az bicep version &> /dev/null; then
    show_progress "Installing Bicep..."
    az bicep install
fi

show_success "Prerequisites checked"
echo ""

# Create directory structure
show_progress "Creating directory structure..."

# Create necessary directories
mkdir -p starter/modules
mkdir -p solution/modules
mkdir -p tests
mkdir -p .github/workflows

show_success "Directory structure created"
echo ""

# Create starter template
show_progress "Creating starter templates..."

# Create basic starter Bicep file if it doesn't exist
if [ ! -f "starter/main.bicep" ]; then
    cat > starter/main.bicep << 'EOF'
// Bicep Basics - Starter Template
// TODO: Add your parameters here

@description('The name of the web app')
param webAppName string

@description('The location for all resources')
param location string = resourceGroup().location

@description('The SKU for the App Service Plan')
@allowed([
  'F1'
  'B1'
  'B2'
  'S1'
])
param appServicePlanSku string = 'F1'

// TODO: Add your variables here

// TODO: Create App Service Plan resource

// TODO: Create Web App resource

// TODO: Create Application Insights resource

// TODO: Create Storage Account resource

// TODO: Add outputs
EOF
    show_success "Created starter/main.bicep"
fi

# Create parameters template
if [ ! -f "starter/parameters.json" ]; then
    cat > starter/parameters.json << 'EOF'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "webAppName": {
      "value": "app-module13-dev"
    }
  }
}
EOF
    show_success "Created starter/parameters.json"
fi

# Create deployment script template
if [ ! -f "starter/deploy.sh" ]; then
    cat > starter/deploy.sh << 'EOF'
#!/bin/bash
# Deployment script for Bicep template

RESOURCE_GROUP="rg-module13-exercise1"
LOCATION="westeurope"

# Create resource group if it doesn't exist
if [ $(az group exists --name $RESOURCE_GROUP) = false ]; then
    echo "Creating resource group..."
    az group create --name $RESOURCE_GROUP --location $LOCATION
fi

# Deploy Bicep template
echo "Deploying Bicep template..."
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file main.bicep \
    --parameters parameters.json \
    --name "deployment-$(date +%Y%m%d%H%M%S)"
EOF
    chmod +x starter/deploy.sh
    show_success "Created starter/deploy.sh"
fi

# Create GitHub Actions workflow template
show_progress "Creating GitHub Actions workflow template..."

cat > .github/workflows/deploy-infrastructure.yml << 'EOF'
name: Deploy Infrastructure

on:
  push:
    branches: [ main ]
    paths:
      - 'exercises/exercise1-bicep-basics/**'
  workflow_dispatch:

env:
  AZURE_RESOURCEGROUP_NAME: rg-module13-exercise1
  DEPLOYMENT_NAME: deploy-${{ github.run_number }}

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Validate Bicep
        uses: azure/arm-deploy@v1
        with:
          resourceGroupName: ${{ env.AZURE_RESOURCEGROUP_NAME }}
          template: ./solution/main.bicep
          parameters: ./solution/parameters.dev.json
          deploymentMode: Validate
  
  deploy:
    needs: validate
    runs-on: ubuntu-latest
    environment: development
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Deploy Bicep
        uses: azure/arm-deploy@v1
        with:
          resourceGroupName: ${{ env.AZURE_RESOURCEGROUP_NAME }}
          template: ./solution/main.bicep
          parameters: ./solution/parameters.dev.json
          deploymentName: ${{ env.DEPLOYMENT_NAME }}
EOF
show_success "Created GitHub Actions workflow"
echo ""

# Create test script
show_progress "Creating test framework..."

cat > tests/validate-deployment.sh << 'EOF'
#!/bin/bash
# Validate deployment script

RESOURCE_GROUP="rg-module13-exercise1"

echo "Validating deployment..."

# Check if resource group exists
if [ $(az group exists --name $RESOURCE_GROUP) = true ]; then
    echo "✓ Resource group exists"
else
    echo "✗ Resource group not found"
    exit 1
fi

# Check deployed resources
RESOURCES=$(az resource list --resource-group $RESOURCE_GROUP --query "[].{name:name, type:type}" -o table)
echo "Deployed resources:"
echo "$RESOURCES"

# Validate specific resources
WEB_APP=$(az webapp list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv)
if [ ! -z "$WEB_APP" ]; then
    echo "✓ Web App deployed: $WEB_APP"
    
    # Check web app status
    STATUS=$(az webapp show --name $WEB_APP --resource-group $RESOURCE_GROUP --query "state" -o tsv)
    echo "  Status: $STATUS"
else
    echo "✗ Web App not found"
fi

echo ""
echo "Validation complete!"
EOF
chmod +x tests/validate-deployment.sh
show_success "Created test framework"
echo ""

# Create environment file template
show_progress "Creating environment configuration..."

cat > .env.example << 'EOF'
# Azure Configuration
AZURE_SUBSCRIPTION_ID=your-subscription-id
AZURE_TENANT_ID=your-tenant-id
RESOURCE_GROUP_NAME=rg-module13-exercise1
LOCATION=westeurope

# Application Configuration
APP_NAME_PREFIX=app-module13
ENVIRONMENT=dev

# GitHub Configuration
GITHUB_REPO=your-github-username/your-repo-name
EOF
show_success "Created .env.example"
echo ""

# Create README for the exercise
show_progress "Creating exercise documentation..."

cat > starter/README.md << 'EOF'
# Exercise 1: Bicep Basics - Starter

## Overview

This exercise will teach you the fundamentals of Azure Bicep by creating a basic web application infrastructure.

## Your Task

Complete the `main.bicep` file to deploy:
1. An App Service Plan
2. A Web App
3. Application Insights
4. A Storage Account

## Getting Started

1. Review the starter template in `main.bicep`
2. Add the required resources following the TODO comments
3. Test your deployment locally:
   ```bash
   ./deploy.sh
   ```

## Validation

Run the validation script to check your deployment:
```bash
../tests/validate-deployment.sh
```

## Tips

- Use Copilot to help generate Bicep resources
- Reference the Bicep documentation for syntax
- Start with simple configurations and add complexity

## Success Criteria

- [ ] All resources deploy successfully
- [ ] Resources are properly connected
- [ ] Proper naming conventions used
- [ ] Parameters are utilized effectively
- [ ] Outputs are defined for integration
EOF
show_success "Created documentation"
echo ""

# Summary
echo -e "${GREEN}======================================"
echo "Setup Complete!"
echo "======================================${NC}"
echo ""
echo "Next steps:"
echo "1. cd starter"
echo "2. Review the main.bicep template"
echo "3. Complete the TODOs with Copilot's help"
echo "4. Run ./deploy.sh to test your solution"
echo ""
echo "For the complete solution, check the 'solution' directory."
echo ""
echo -e "${BLUE}Happy learning!${NC}" 