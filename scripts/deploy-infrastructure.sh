#!/bin/bash

# Deploy Infrastructure Script
set -e

echo "🚀 Deploying Workshop Infrastructure..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
    echo -e "${GREEN}✓${NC} Loaded environment variables"
else
    echo -e "${RED}✗${NC} .env file not found"
    echo "Please create .env from .env.example and configure it"
    exit 1
fi

# Validate required environment variables
required_vars=(
    "AZURE_SUBSCRIPTION_ID"
    "AZURE_RESOURCE_GROUP"
    "AZURE_LOCATION"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}✗${NC} Missing required variable: $var"
        exit 1
    fi
done

echo -e "\n${YELLOW}Deployment Configuration:${NC}"
echo "  Subscription: $AZURE_SUBSCRIPTION_ID"
echo "  Resource Group: $AZURE_RESOURCE_GROUP"
echo "  Location: $AZURE_LOCATION"
echo "  Environment: ${WORKSHOP_ENVIRONMENT:-development}"

# Function to deploy with Bicep
deploy_bicep() {
    echo -e "\n${BLUE}Deploying with Bicep...${NC}"
    
    if ! command -v az &> /dev/null; then
        echo -e "${RED}✗${NC} Azure CLI not found"
        return 1
    fi
    
    # Login check
    if ! az account show &> /dev/null; then
        echo "Please login to Azure:"
        az login
    fi
    
    # Set subscription
    az account set --subscription "$AZURE_SUBSCRIPTION_ID"
    echo -e "${GREEN}✓${NC} Set Azure subscription"
    
    # Create resource group
    az group create \
        --name "$AZURE_RESOURCE_GROUP" \
        --location "$AZURE_LOCATION" \
        --tags "workshop=ai-code-dev" "environment=${WORKSHOP_ENVIRONMENT:-development}"
    echo -e "${GREEN}✓${NC} Created resource group"
    
    # Deploy main template
    if [ -f "infrastructure/bicep/main.bicep" ]; then
        echo "Deploying Bicep template..."
        az deployment group create \
            --resource-group "$AZURE_RESOURCE_GROUP" \
            --template-file "infrastructure/bicep/main.bicep" \
            --parameters "infrastructure/bicep/parameters/main.parameters.json" \
            --name "workshop-deployment-$(date +%Y%m%d%H%M%S)"
        echo -e "${GREEN}✓${NC} Bicep deployment complete"
    else
        echo -e "${YELLOW}⚠${NC} Bicep template not found, creating sample..."
        create_sample_bicep
    fi
}

# Function to deploy with Terraform
deploy_terraform() {
    echo -e "\n${BLUE}Deploying with Terraform...${NC}"
    
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}✗${NC} Terraform not found"
        return 1
    fi
    
    cd infrastructure/terraform
    
    # Initialize Terraform
    terraform init
    echo -e "${GREEN}✓${NC} Terraform initialized"
    
    # Create plan
    terraform plan -out=tfplan
    echo -e "${GREEN}✓${NC} Terraform plan created"
    
    # Apply plan
    if confirm "Apply Terraform plan?"; then
        terraform apply tfplan
        echo -e "${GREEN}✓${NC} Terraform deployment complete"
    fi
    
    cd ../..
}

# Function to create sample Bicep template
create_sample_bicep() {
    mkdir -p infrastructure/bicep/parameters
    
    cat > infrastructure/bicep/main.bicep << 'EOF'
// Main Bicep template for AI Code Development Workshop

@description('The name of the resource group')
param resourceGroupName string = resourceGroup().name

@description('The location of resources')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['development', 'staging', 'production'])
param environment string = 'development'

@description('Tags to apply to all resources')
param tags object = {
  workshop: 'ai-code-dev'
  environment: environment
  createdBy: 'bicep'
}

// Storage Account for workshop artifacts
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: 'aiworkshop${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

// Container Registry for workshop images
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: 'aiworkshop${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

// Key Vault for secrets
resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: 'aiworkshop-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: []
    enableRbacAuthorization: true
  }
}

// Outputs
output storageAccountName string = storageAccount.name
output containerRegistryName string = containerRegistry.name
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
EOF

    cat > infrastructure/bicep/parameters/main.parameters.json << EOF
{
  "\$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environment": {
      "value": "${WORKSHOP_ENVIRONMENT:-development}"
    }
  }
}
EOF

    echo -e "${GREEN}✓${NC} Created sample Bicep templates"
}

# Function to confirm action
confirm() {
    read -p "$1 [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Main deployment menu
echo -e "\n${YELLOW}Select deployment method:${NC}"
echo "1) Azure Bicep (recommended)"
echo "2) Terraform"
echo "3) Both"
echo "4) Skip infrastructure"

read -p "Enter choice (1-4): " choice

case $choice in
    1)
        deploy_bicep
        ;;
    2)
        deploy_terraform
        ;;
    3)
        deploy_bicep
        deploy_terraform
        ;;
    4)
        echo "Skipping infrastructure deployment"
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo -e "\n${YELLOW}Post-deployment steps:${NC}"

# Create GitHub Actions secrets
if command -v gh &> /dev/null && confirm "Configure GitHub Actions secrets?"; then
    echo "Setting GitHub secrets..."
    gh secret set AZURE_SUBSCRIPTION_ID --body "$AZURE_SUBSCRIPTION_ID"
    gh secret set AZURE_RESOURCE_GROUP --body "$AZURE_RESOURCE_GROUP"
    gh secret set OPENAI_API_KEY --body "${OPENAI_API_KEY:-not-set}"
    gh secret set ANTHROPIC_API_KEY --body "${ANTHROPIC_API_KEY:-not-set}"
    echo -e "${GREEN}✓${NC} GitHub secrets configured"
fi

# Create local development environment file
cat > .env.local << EOF
# Local Development Environment
# Auto-generated by deploy-infrastructure.sh on $(date)

# Azure Resources (deployed)
AZURE_RESOURCE_GROUP=$AZURE_RESOURCE_GROUP
AZURE_LOCATION=$AZURE_LOCATION

# Add deployed resource names here after deployment
# STORAGE_ACCOUNT_NAME=
# CONTAINER_REGISTRY_NAME=
# KEY_VAULT_NAME=

# Workshop Configuration
WORKSHOP_ENVIRONMENT=${WORKSHOP_ENVIRONMENT:-development}
WORKSHOP_DEPLOYED=$(date +%Y-%m-%d)
EOF

echo -e "${GREEN}✓${NC} Created .env.local with deployment details"

echo -e "\n${GREEN}✅ Infrastructure deployment complete!${NC}"
echo -e "\nNext steps:"
echo "1. Check deployed resources in Azure Portal"
echo "2. Update .env.local with resource names"
echo "3. Run module-specific setup scripts as needed"
echo "4. Start developing with the workshop modules" 