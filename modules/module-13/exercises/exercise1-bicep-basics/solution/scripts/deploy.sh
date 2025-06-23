#!/bin/bash
# deploy.sh - Complete deployment script for Bicep template

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
RESOURCE_GROUP="rg-bicep-exercise1"
LOCATION="eastus2"
ENVIRONMENT="${1:-dev}"
TEMPLATE_FILE="../main.bicep"
PARAMETERS_DIR="../parameters"

# Usage function
usage() {
    echo "Usage: $0 [environment]"
    echo "  environment: dev, staging, or prod (default: dev)"
    echo ""
    echo "Example:"
    echo "  $0 dev"
    echo "  $0 staging"
    echo "  $0 prod"
    exit 1
}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo -e "${RED}❌ Invalid environment: $ENVIRONMENT${NC}"
    usage
fi

# Set deployment name
DEPLOYMENT_NAME="bicep-exercise1-${ENVIRONMENT}-$(date +%Y%m%d%H%M%S)"
PARAMETERS_FILE="${PARAMETERS_DIR}/${ENVIRONMENT}.parameters.json"

# Header
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Bicep Deployment Script            ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📍 Configuration:${NC}"
echo -e "   Environment: ${BLUE}$ENVIRONMENT${NC}"
echo -e "   Resource Group: ${BLUE}$RESOURCE_GROUP${NC}"
echo -e "   Location: ${BLUE}$LOCATION${NC}"
echo -e "   Template: ${BLUE}$TEMPLATE_FILE${NC}"
echo -e "   Parameters: ${BLUE}$PARAMETERS_FILE${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not installed${NC}"
    exit 1
fi

# Check Bicep
if ! az bicep version &> /dev/null; then
    echo -e "${YELLOW}📦 Installing Bicep...${NC}"
    az bicep install
fi

# Check Azure login
echo -e "${YELLOW}🔐 Checking Azure login...${NC}"
if ! az account show &>/dev/null; then
    echo -e "${RED}❌ Not logged in to Azure. Please run 'az login' first.${NC}"
    exit 1
fi

SUBSCRIPTION=$(az account show --query name -o tsv)
echo -e "${GREEN}✅ Logged in to subscription: $SUBSCRIPTION${NC}"

# Check if template exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo -e "${RED}❌ Template file not found: $TEMPLATE_FILE${NC}"
    exit 1
fi

# Check if parameters file exists
if [ ! -f "$PARAMETERS_FILE" ]; then
    echo -e "${RED}❌ Parameters file not found: $PARAMETERS_FILE${NC}"
    exit 1
fi

# Create resource group
echo -e "\n${YELLOW}📦 Creating resource group...${NC}"
if az group exists --name $RESOURCE_GROUP | grep -q true; then
    echo -e "${GREEN}✅ Resource group already exists${NC}"
else
    az group create \
        --name $RESOURCE_GROUP \
        --location $LOCATION \
        --tags Environment=$ENVIRONMENT Module=13 Exercise=1 \
        --output none
    echo -e "${GREEN}✅ Resource group created${NC}"
fi

# Build Bicep template
echo -e "\n${YELLOW}🔨 Building Bicep template...${NC}"
az bicep build --file $TEMPLATE_FILE
echo -e "${GREEN}✅ Template built successfully${NC}"

# Validate template
echo -e "\n${YELLOW}✅ Validating deployment...${NC}"
VALIDATION_RESULT=$(az deployment group validate \
    --resource-group $RESOURCE_GROUP \
    --template-file $TEMPLATE_FILE \
    --parameters @$PARAMETERS_FILE \
    --query error \
    --output tsv)

if [ -n "$VALIDATION_RESULT" ]; then
    echo -e "${RED}❌ Validation failed: $VALIDATION_RESULT${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Validation passed${NC}"

# Preview deployment (What-If)
echo -e "\n${YELLOW}🔮 Preview deployment changes...${NC}"
echo -e "${BLUE}Running what-if analysis...${NC}"
az deployment group what-if \
    --resource-group $RESOURCE_GROUP \
    --template-file $TEMPLATE_FILE \
    --parameters @$PARAMETERS_FILE \
    --no-pretty-print

# Confirm deployment
echo ""
read -p "Do you want to proceed with the deployment? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⏹️  Deployment cancelled${NC}"
    exit 0
fi

# Deploy template
echo -e "\n${YELLOW}🚀 Deploying template...${NC}"
DEPLOYMENT_OUTPUT=$(az deployment group create \
    --name $DEPLOYMENT_NAME \
    --resource-group $RESOURCE_GROUP \
    --template-file $TEMPLATE_FILE \
    --parameters @$PARAMETERS_FILE \
    --query properties.outputs \
    --output json)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
else
    echo -e "${RED}❌ Deployment failed${NC}"
    exit 1
fi

# Show outputs
echo -e "\n${YELLOW}📋 Deployment outputs:${NC}"
echo "$DEPLOYMENT_OUTPUT" | jq '.'

# Extract specific outputs
WEB_APP_URL=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.webAppUrl.value // empty')
WEB_APP_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.webAppName.value // empty')
APP_INSIGHTS_KEY=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.appInsightsInstrumentationKey.value // empty')

# Display summary
echo -e "\n${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Deployment Summary               ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo -e "${GREEN}✅ Environment: $ENVIRONMENT${NC}"
echo -e "${GREEN}✅ Resource Group: $RESOURCE_GROUP${NC}"
echo -e "${GREEN}✅ Web App Name: $WEB_APP_NAME${NC}"
if [ -n "$WEB_APP_URL" ]; then
    echo -e "${GREEN}✅ Web App URL: $WEB_APP_URL${NC}"
fi
if [ -n "$APP_INSIGHTS_KEY" ] && [ "$APP_INSIGHTS_KEY" != "Not enabled" ]; then
    echo -e "${GREEN}✅ Application Insights: Enabled${NC}"
fi

# Test the deployment
echo -e "\n${YELLOW}🧪 Testing deployment...${NC}"
if [ -n "$WEB_APP_URL" ]; then
    echo -e "Checking if web app is responding..."
    sleep 10  # Give the app time to start
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$WEB_APP_URL" || echo "000")
    
    if [[ "$HTTP_CODE" =~ ^[23] ]]; then
        echo -e "${GREEN}✅ Web app is responding (HTTP $HTTP_CODE)${NC}"
    else
        echo -e "${YELLOW}⚠️  Web app returned HTTP $HTTP_CODE (may still be starting)${NC}"
    fi
fi

# Show next steps
echo -e "\n${YELLOW}📌 Next steps:${NC}"
echo "1. Visit your web app: $WEB_APP_URL"
echo "2. View resources in Azure Portal:"
echo "   https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP"
echo "3. Check Application Insights (if enabled)"
echo "4. Configure custom domain and SSL"

echo -e "\n${GREEN}🎉 Deployment complete!${NC}" 