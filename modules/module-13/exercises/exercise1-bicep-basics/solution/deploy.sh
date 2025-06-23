#!/bin/bash
# Deploy script for Exercise 1 - Bicep Basics

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
RESOURCE_GROUP="rg-module13-exercise1"
LOCATION="eastus"
SKU="F1"
ENVIRONMENT="dev"

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -s|--sku)
            SKU="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -g, --resource-group  Resource group name (default: rg-module13-exercise1)"
            echo "  -l, --location        Azure region (default: eastus)"
            echo "  -s, --sku            App Service Plan SKU (default: F1)"
            echo "  -e, --environment    Environment tag (default: dev)"
            echo "  -h, --help           Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

print_message "$YELLOW" "Starting deployment of Exercise 1 - Bicep Basics"
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "SKU: $SKU"
echo "Environment: $ENVIRONMENT"

# Check if logged in to Azure
print_message "$YELLOW" "\nChecking Azure login status..."
if ! az account show &> /dev/null; then
    print_message "$RED" "Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

# Create resource group
print_message "$YELLOW" "\nCreating resource group..."
if az group create --name $RESOURCE_GROUP --location $LOCATION; then
    print_message "$GREEN" "Resource group created successfully."
else
    print_message "$RED" "Failed to create resource group."
    exit 1
fi

# Deploy Bicep template
print_message "$YELLOW" "\nDeploying Bicep template..."
DEPLOYMENT_OUTPUT=$(az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file main.bicep \
    --parameters sku=$SKU environment=$ENVIRONMENT \
    --query properties.outputs \
    --output json)

if [ $? -eq 0 ]; then
    print_message "$GREEN" "Deployment completed successfully!"
    
    # Extract outputs
    WEB_APP_URL=$(echo $DEPLOYMENT_OUTPUT | jq -r '.webAppUrl.value')
    WEB_APP_NAME=$(echo $DEPLOYMENT_OUTPUT | jq -r '.webAppName.value')
    APP_SERVICE_PLAN=$(echo $DEPLOYMENT_OUTPUT | jq -r '.appServicePlanName.value')
    
    print_message "$GREEN" "\nDeployment Outputs:"
    echo "Web App URL: $WEB_APP_URL"
    echo "Web App Name: $WEB_APP_NAME"
    echo "App Service Plan: $APP_SERVICE_PLAN"
    
    print_message "$YELLOW" "\nYou can view your resources in the Azure Portal:"
    echo "https://portal.azure.com/#resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP"
else
    print_message "$RED" "Deployment failed. Check the error messages above."
    exit 1
fi

print_message "$GREEN" "\nExercise 1 deployment complete!"