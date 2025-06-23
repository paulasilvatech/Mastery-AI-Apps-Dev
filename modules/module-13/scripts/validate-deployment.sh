#!/bin/bash
# Validation script for Module 13 deployments

echo "🔍 Validating Module 13 deployments"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Default values
RESOURCE_GROUP=""
DEPLOYMENT_NAME=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -d|--deployment)
            DEPLOYMENT_NAME="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -g, --resource-group  Resource group name"
            echo "  -d, --deployment      Deployment name"
            echo "  -h, --help           Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check required parameters
if [ -z "$RESOURCE_GROUP" ]; then
    print_message "$RED" "❌ Resource group name is required. Use -g flag."
    exit 1
fi

# Check Azure login
if ! az account show &> /dev/null; then
    print_message "$RED" "❌ Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

# Check if resource group exists
print_message "$YELLOW" "\n📋 Checking resource group..."
if ! az group exists --name "$RESOURCE_GROUP" | grep -q true; then
    print_message "$RED" "❌ Resource group '$RESOURCE_GROUP' does not exist."
    exit 1
fi
print_message "$GREEN" "✅ Resource group exists"

# List deployments if no specific deployment name provided
if [ -z "$DEPLOYMENT_NAME" ]; then
    print_message "$YELLOW" "\n📋 Recent deployments:"
    az deployment group list \
        --resource-group "$RESOURCE_GROUP" \
        --query "[?properties.provisioningState!='Failed'].{Name:name, State:properties.provisioningState, Timestamp:properties.timestamp}" \
        --output table
    
    # Get the latest successful deployment
    DEPLOYMENT_NAME=$(az deployment group list \
        --resource-group "$RESOURCE_GROUP" \
        --query "[?properties.provisioningState=='Succeeded'] | [0].name" \
        --output tsv)
fi

if [ -z "$DEPLOYMENT_NAME" ]; then
    print_message "$YELLOW" "No successful deployments found."
    exit 0
fi

print_message "$YELLOW" "\n🔍 Validating deployment: $DEPLOYMENT_NAME"

# Check deployment status
DEPLOYMENT_STATE=$(az deployment group show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --query "properties.provisioningState" \
    --output tsv)

if [ "$DEPLOYMENT_STATE" != "Succeeded" ]; then
    print_message "$RED" "❌ Deployment state: $DEPLOYMENT_STATE"
    exit 1
fi
print_message "$GREEN" "✅ Deployment state: Succeeded"

# Get deployment outputs
print_message "$YELLOW" "\n📋 Deployment outputs:"
az deployment group show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --query "properties.outputs" \
    --output json | jq '.'

# List deployed resources
print_message "$YELLOW" "\n📋 Deployed resources:"
az resource list \
    --resource-group "$RESOURCE_GROUP" \
    --query "[].{Name:name, Type:type, Location:location}" \
    --output table

# Validate specific resources
print_message "$YELLOW" "\n🔍 Validating resources..."

# Check for App Service Plans
APP_PLANS=$(az appservice plan list \
    --resource-group "$RESOURCE_GROUP" \
    --query "[].name" \
    --output tsv)

if [ ! -z "$APP_PLANS" ]; then
    print_message "$GREEN" "✅ App Service Plan(s) found"
    for plan in $APP_PLANS; do
        SKU=$(az appservice plan show \
            --name "$plan" \
            --resource-group "$RESOURCE_GROUP" \
            --query "sku.name" \
            --output tsv)
        echo "   - $plan (SKU: $SKU)"
    done
fi

# Check for Web Apps
WEB_APPS=$(az webapp list \
    --resource-group "$RESOURCE_GROUP" \
    --query "[].name" \
    --output tsv)

if [ ! -z "$WEB_APPS" ]; then
    print_message "$GREEN" "✅ Web App(s) found"
    for app in $WEB_APPS; do
        URL="https://${app}.azurewebsites.net"
        STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
        if [ "$STATUS" -eq 200 ] || [ "$STATUS" -eq 403 ]; then
            echo "   - $app: ✅ Accessible ($STATUS)"
        else
            echo "   - $app: ⚠️  Status code: $STATUS"
        fi
    done
fi

# Check for Application Insights
APP_INSIGHTS=$(az monitor app-insights component list \
    --resource-group "$RESOURCE_GROUP" \
    --query "[].name" \
    --output tsv 2>/dev/null)

if [ ! -z "$APP_INSIGHTS" ]; then
    print_message "$GREEN" "✅ Application Insights found"
    for ai in $APP_INSIGHTS; do
        echo "   - $ai"
    done
fi

print_message "$GREEN" "\n✅ Validation complete!"