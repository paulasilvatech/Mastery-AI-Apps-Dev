#!/bin/bash
# deploy.sh - Deployment script for Bicep template

set -e

# Variables
RESOURCE_GROUP="rg-bicep-exercise1"
LOCATION="eastus2"
DEPLOYMENT_NAME="bicep-exercise1-$(date +%Y%m%d%H%M%S)"

echo "🚀 Starting Bicep deployment..."

# TODO: Complete this script
# Steps to implement:
# 1. Check if logged in to Azure
# 2. Create resource group if it doesn't exist
# 3. Validate the Bicep template
# 4. Deploy the template
# 5. Show deployment outputs

# Check Azure login
echo "🔐 Checking Azure login..."
if ! az account show &>/dev/null; then
    echo "❌ Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

# TODO: Create resource group
# echo "📦 Creating resource group..."
# az group create --name $RESOURCE_GROUP --location $LOCATION

# TODO: Validate template
# echo "✅ Validating Bicep template..."
# az deployment group validate \
#   --resource-group $RESOURCE_GROUP \
#   --template-file ../main.bicep

# TODO: Deploy template
# echo "🚀 Deploying template..."
# az deployment group create \
#   --name $DEPLOYMENT_NAME \
#   --resource-group $RESOURCE_GROUP \
#   --template-file ../main.bicep

# TODO: Show outputs
# echo "📋 Deployment outputs:"
# az deployment group show \
#   --name $DEPLOYMENT_NAME \
#   --resource-group $RESOURCE_GROUP \
#   --query properties.outputs

echo "❗ Script not implemented yet. Complete the TODOs!" 