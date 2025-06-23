#!/bin/bash
# deploy.sh - Deploy Bicep template for Exercise 1

set -e

# Configuration
RESOURCE_GROUP="rg-module13-exercise1-${1:-dev}"
LOCATION="eastus2"
ENVIRONMENT="${1:-dev}"
DEPLOYMENT_NAME="exercise1-deployment-$(date +%Y%m%d%H%M%S)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "🚀 Deploying Exercise 1 Infrastructure"
echo "===================================="
echo "Environment: $ENVIRONMENT"
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo ""

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo -e "${RED}Error: Not logged in to Azure${NC}"
    echo "Please run: az login"
    exit 1
fi

# Create resource group
echo "Creating resource group..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --tags "Module=13" "Exercise=1" "Environment=$ENVIRONMENT"

# Validate template
echo -e "\nValidating Bicep template..."
az deployment group validate \
    --resource-group "$RESOURCE_GROUP" \
    --template-file main.bicep \
    --parameters "@parameters.$ENVIRONMENT.json" \
    --parameters sqlAdminPassword="P@ssw0rd123!"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Template validation passed${NC}"
else
    echo -e "${RED}✗ Template validation failed${NC}"
    exit 1
fi

# Deploy template
echo -e "\nDeploying infrastructure..."
az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --template-file main.bicep \
    --parameters "@parameters.$ENVIRONMENT.json" \
    --parameters sqlAdminPassword="P@ssw0rd123!" \
    --verbose

# Get outputs
echo -e "\n${GREEN}Deployment completed successfully!${NC}"
echo -e "\nOutputs:"
az deployment group show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --query properties.outputs -o yaml

# Get web app URL
WEB_APP_URL=$(az deployment group show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --query properties.outputs.webAppUrl.value -o tsv)

echo -e "\n🌐 Web App URL: $WEB_APP_URL"
echo -e "\n✅ Deployment complete!"