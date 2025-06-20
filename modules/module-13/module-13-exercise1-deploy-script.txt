#!/bin/bash
# exercises/exercise1-bicep-basics/solution/deploy.sh
# Deploy Bicep template with validation and error handling

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-workshop-module13}"
LOCATION="${LOCATION:-eastus2}"
TEMPLATE_FILE="main.bicep"
PARAMETERS_FILE="main.parameters.dev.json"
DEPLOYMENT_NAME="workshop-deploy-$(date +%Y%m%d-%H%M%S)"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed"
        exit 1
    fi
    
    # Check if logged in
    if ! az account show &> /dev/null; then
        log_error "Not logged into Azure. Run 'az login'"
        exit 1
    fi
    
    # Check Bicep
    if ! az bicep version &> /dev/null; then
        log_warn "Bicep not installed. Installing..."
        az bicep install
    fi
    
    log_info "Prerequisites check passed"
}

create_resource_group() {
    log_info "Creating resource group: $RESOURCE_GROUP"
    
    if az group exists --name $RESOURCE_GROUP | grep -q true; then
        log_info "Resource group already exists"
    else
        az group create \
            --name $RESOURCE_GROUP \
            --location $LOCATION \
            --tags "Module=13" "Purpose=Workshop" "Environment=dev"
        log_info "Resource group created"
    fi
}

validate_template() {
    log_info "Validating Bicep template..."
    
    # Build Bicep to ARM
    if ! az bicep build --file $TEMPLATE_FILE; then
        log_error "Bicep build failed"
        exit 1
    fi
    
    # Validate deployment
    if az deployment group validate \
        --resource-group $RESOURCE_GROUP \
        --template-file $TEMPLATE_FILE \
        --parameters @$PARAMETERS_FILE; then
        log_info "Template validation successful"
    else
        log_error "Template validation failed"
        exit 1
    fi
}

run_what_if() {
    log_info "Running what-if analysis..."
    
    az deployment group what-if \
        --resource-group $RESOURCE_GROUP \
        --template-file $TEMPLATE_FILE \
        --parameters @$PARAMETERS_FILE \
        --no-pretty-print
    
    echo ""
    read -p "Do you want to proceed with deployment? (y/N) " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warn "Deployment cancelled by user"
        exit 0
    fi
}

deploy_template() {
    log_info "Deploying resources..."
    
    # Deploy with progress
    DEPLOYMENT_OUTPUT=$(az deployment group create \
        --resource-group $RESOURCE_GROUP \
        --template-file $TEMPLATE_FILE \
        --parameters @$PARAMETERS_FILE \
        --name $DEPLOYMENT_NAME \
        --output json)
    
    if [ $? -eq 0 ]; then
        log_info "Deployment successful!"
        
        # Extract outputs
        WEB_APP_URL=$(echo $DEPLOYMENT_OUTPUT | jq -r '.properties.outputs.webAppUrl.value')
        WEB_APP_NAME=$(echo $DEPLOYMENT_OUTPUT | jq -r '.properties.outputs.webAppName.value')
        STORAGE_ACCOUNT=$(echo $DEPLOYMENT_OUTPUT | jq -r '.properties.outputs.storageAccountName.value')
        KEY_VAULT_URI=$(echo $DEPLOYMENT_OUTPUT | jq -r '.properties.outputs.keyVaultUri.value')
        
        log_info "Deployment outputs:"
        echo "  Web App URL: $WEB_APP_URL"
        echo "  Web App Name: $WEB_APP_NAME"
        echo "  Storage Account: $STORAGE_ACCOUNT"
        echo "  Key Vault URI: $KEY_VAULT_URI"
        
        # Save outputs to file
        echo $DEPLOYMENT_OUTPUT | jq '.properties.outputs' > deployment-outputs.json
        log_info "Outputs saved to deployment-outputs.json"
    else
        log_error "Deployment failed"
        
        # Show error details
        az deployment operation group list \
            --resource-group $RESOURCE_GROUP \
            --name $DEPLOYMENT_NAME \
            --query "[?properties.provisioningState=='Failed']"
        
        exit 1
    fi
}

test_deployment() {
    log_info "Testing deployment..."
    
    # Get web app URL from outputs
    if [ -f deployment-outputs.json ]; then
        WEB_APP_URL=$(jq -r '.webAppUrl.value' deployment-outputs.json)
        
        log_info "Testing web app: $WEB_APP_URL"
        
        # Wait for app to be ready
        for i in {1..30}; do
            if curl -s -o /dev/null -w "%{http_code}" "$WEB_APP_URL" | grep -q "200\|404"; then
                log_info "Web app is responding"
                break
            fi
            echo -n "."
            sleep 10
        done
        echo ""
        
        # Run basic tests
        if command -v python3 &> /dev/null; then
            python3 ../tests/test_deployment.py
        else
            log_warn "Python not installed, skipping detailed tests"
        fi
    else
        log_warn "No deployment outputs found, skipping tests"
    fi
}

show_resources() {
    log_info "Deployed resources:"
    
    az resource list \
        --resource-group $RESOURCE_GROUP \
        --output table \
        --query "[].{Name:name, Type:type, Location:location}"
}

# Main execution
main() {
    echo "🚀 Bicep Deployment Script for Module 13 - Exercise 1"
    echo "=================================================="
    echo ""
    
    check_prerequisites
    create_resource_group
    validate_template
    run_what_if
    deploy_template
    test_deployment
    show_resources
    
    echo ""
    log_info "🎉 Deployment complete!"
    log_info "Next steps:"
    echo "  - Review the deployed resources in Azure Portal"
    echo "  - Check Application Insights for monitoring data"
    echo "  - Try modifying the template and redeploying"
}

# Run main function
main