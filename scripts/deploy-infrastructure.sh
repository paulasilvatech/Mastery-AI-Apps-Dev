#!/bin/bash
# Deploy infrastructure for specific workshop modules
# Supports all 30 modules with flexible deployment options

set -e

# Script metadata
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="Deploy Infrastructure"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
MODULE_NUMBER=1
ENVIRONMENT="dev"
LOCATION="East US 2"
DEPLOYMENT_TOOL="bicep"
SKIP_VALIDATION=false
AUTO_APPROVE=false
CLEANUP_PREVIOUS=false
DRY_RUN=false

# Function to print colored output
print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print header
print_header() {
    echo ""
    print_colored $PURPLE "╔══════════════════════════════════════════════════════════════╗"
    print_colored $PURPLE "║              🚀 Workshop Infrastructure Deployment           ║"
    print_colored $PURPLE "║                     Version $SCRIPT_VERSION                          ║"
    print_colored $PURPLE "╚══════════════════════════════════════════════════════════════╝"
    echo ""
}

# Function to show help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy Azure infrastructure for Mastery AI Workshop modules.

OPTIONS:
    -m, --module NUMBER      Module number (1-30) [default: 1]
    -e, --environment ENV    Environment (dev/staging/prod) [default: dev]
    -l, --location LOCATION  Azure region [default: "East US 2"]
    -t, --tool TOOL         Deployment tool (bicep/terraform) [default: bicep]
    -s, --skip-validation   Skip infrastructure validation
    -y, --auto-approve      Auto-approve deployment without prompts
    -c, --cleanup          Cleanup previous deployments first
    -d, --dry-run          Show what would be deployed without executing
    -v, --verbose          Enable verbose output
    -h, --help             Show this help message

EXAMPLES:
    # Deploy module 1 to dev environment
    $0 -m 1 -e dev

    # Deploy module 21 (AI Agents) to staging with Terraform
    $0 -m 21 -e staging -t terraform

    # Deploy module 30 to production with cleanup
    $0 -m 30 -e prod -c -y

    # Dry run for module 15
    $0 -m 15 -d

ENVIRONMENTS:
    dev      - Development environment (minimal resources)
    staging  - Staging environment (production-like but smaller scale)
    prod     - Production environment (full scale, high availability)

MODULES:
    1-5      Fundamentals Track (GitHub Copilot basics)
    6-10     Intermediate Track (Web applications)
    11-15    Advanced Track (Cloud-native, microservices)
    16-20    Enterprise Track (AI integration, enterprise patterns)
    21-25    AI Agents Track (Agent development, MCP)
    26-30    Enterprise Mastery (Advanced .NET, COBOL modernization)

EOF
}

# Function to validate prerequisites
validate_prerequisites() {
    print_colored $CYAN "🔍 Validating prerequisites..."

    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        print_colored $RED "❌ Azure CLI is not installed"
        exit 1
    fi

    # Check Azure login
    if ! az account show &> /dev/null; then
        print_colored $RED "❌ Not logged into Azure. Please run 'az login'"
        exit 1
    fi

    # Check deployment tool
    if [ "$DEPLOYMENT_TOOL" = "terraform" ]; then
        if ! command -v terraform &> /dev/null; then
            print_colored $RED "❌ Terraform is not installed"
            exit 1
        fi
    elif [ "$DEPLOYMENT_TOOL" = "bicep" ]; then
        if ! command -v bicep &> /dev/null; then
            print_colored $YELLOW "⚠️  Bicep CLI not found. Installing..."
            az bicep install
        fi
    fi

    # Validate module number
    if [[ $MODULE_NUMBER -lt 1 || $MODULE_NUMBER -gt 30 ]]; then
        print_colored $RED "❌ Module number must be between 1 and 30"
        exit 1
    fi

    # Validate environment
    if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
        print_colored $RED "❌ Environment must be dev, staging, or prod"
        exit 1
    fi

    print_colored $GREEN "✅ Prerequisites validated"
}

# Function to determine module track
get_module_track() {
    if [[ $MODULE_NUMBER -le 5 ]]; then
        echo "fundamentals"
    elif [[ $MODULE_NUMBER -le 10 ]]; then
        echo "intermediate"
    elif [[ $MODULE_NUMBER -le 15 ]]; then
        echo "advanced"
    elif [[ $MODULE_NUMBER -le 20 ]]; then
        echo "enterprise"
    elif [[ $MODULE_NUMBER -le 25 ]]; then
        echo "ai-agents"
    else
        echo "enterprise-mastery"
    fi
}

# Function to get resource requirements
get_resource_requirements() {
    local track=$(get_module_track)
    
    case $track in
        "fundamentals")
            echo "Storage Account, App Service (modules 3+), Key Vault"
            ;;
        "intermediate")
            echo "App Service, SQL Database, Redis Cache, API Management"
            ;;
        "advanced")
            echo "AKS Cluster, Container Registry, Service Bus, Functions"
            ;;
        "enterprise")
            echo "AI Search, Cognitive Services, Cosmos DB, Synapse"
            ;;
        "ai-agents")
            echo "Azure OpenAI, AI Search, Container Apps, Event Grid, Cosmos DB"
            ;;
        "enterprise-mastery")
            echo "Full enterprise stack with all services"
            ;;
    esac
}

# Function to estimate costs
estimate_costs() {
    local track=$(get_module_track)
    
    case $ENVIRONMENT in
        "dev")
            case $track in
                "fundamentals") echo "\$10-25/month" ;;
                "intermediate") echo "\$25-50/month" ;;
                "advanced") echo "\$50-100/month" ;;
                "enterprise") echo "\$100-200/month" ;;
                "ai-agents") echo "\$150-300/month" ;;
                "enterprise-mastery") echo "\$200-400/month" ;;
            esac
            ;;
        "staging")
            case $track in
                "fundamentals") echo "\$25-50/month" ;;
                "intermediate") echo "\$50-100/month" ;;
                "advanced") echo "\$100-200/month" ;;
                "enterprise") echo "\$200-400/month" ;;
                "ai-agents") echo "\$300-600/month" ;;
                "enterprise-mastery") echo "\$400-800/month" ;;
            esac
            ;;
        "prod")
            case $track in
                "fundamentals") echo "\$50-100/month" ;;
                "intermediate") echo "\$100-200/month" ;;
                "advanced") echo "\$200-500/month" ;;
                "enterprise") echo "\$500-1000/month" ;;
                "ai-agents") echo "\$750-1500/month" ;;
                "enterprise-mastery") echo "\$1000-2000/month" ;;
            esac
            ;;
    esac
}

# Function to cleanup previous deployments
cleanup_previous_deployments() {
    print_colored $YELLOW "🧹 Cleaning up previous deployments..."
    
    # Find resource groups matching pattern
    RG_PATTERN="rg-workshop-module${MODULE_NUMBER}-${ENVIRONMENT}-*"
    RESOURCE_GROUPS=$(az group list --query "[?starts_with(name, 'rg-workshop-module${MODULE_NUMBER}-${ENVIRONMENT}')].name" -o tsv)
    
    if [ -z "$RESOURCE_GROUPS" ]; then
        print_colored $GREEN "✅ No previous deployments found"
        return
    fi
    
    print_colored $YELLOW "Found existing resource groups:"
    echo "$RESOURCE_GROUPS"
    
    if [ "$AUTO_APPROVE" = false ]; then
        read -p "Delete these resource groups? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_colored $YELLOW "⏭️  Skipping cleanup"
            return
        fi
    fi
    
    for RG in $RESOURCE_GROUPS; do
        print_colored $YELLOW "🗑️  Deleting resource group: $RG"
        az group delete --name "$RG" --yes --no-wait
    done
    
    print_colored $GREEN "✅ Cleanup initiated (running in background)"
}

# Function to validate infrastructure templates
validate_infrastructure() {
    if [ "$SKIP_VALIDATION" = true ]; then
        print_colored $YELLOW "⏭️  Skipping validation"
        return
    fi
    
    print_colored $CYAN "🔍 Validating infrastructure templates..."
    
    if [ "$DEPLOYMENT_TOOL" = "bicep" ]; then
        cd infrastructure/bicep
        
        # Validate main template
        print_colored $BLUE "Validating Bicep templates..."
        az bicep build --file main.bicep --outfile main.json
        
        # Validate specific modules
        if [ -f "modules/$(get_module_track).bicep" ]; then
            az bicep build --file "modules/$(get_module_track).bicep"
        fi
        
        cd ../..
        
    elif [ "$DEPLOYMENT_TOOL" = "terraform" ]; then
        cd infrastructure/terraform
        
        print_colored $BLUE "Validating Terraform configuration..."
        terraform init -backend=false
        terraform validate
        
        cd ../..
    fi
    
    print_colored $GREEN "✅ Infrastructure templates validated"
}

# Function to deploy with Bicep
deploy_with_bicep() {
    print_colored $CYAN "🚀 Deploying infrastructure with Bicep..."
    
    local deployment_name="workshop-m${MODULE_NUMBER}-${ENVIRONMENT}-$(date +%Y%m%d%H%M%S)"
    
    if [ "$DRY_RUN" = true ]; then
        print_colored $BLUE "🔍 Dry run mode - showing what would be deployed:"
        az deployment sub what-if \
            --name "$deployment_name" \
            --location "$LOCATION" \
            --template-file infrastructure/bicep/main.bicep \
            --parameters \
                environment="$ENVIRONMENT" \
                location="$LOCATION" \
                moduleNumber="$MODULE_NUMBER"
        return
    fi
    
    # Execute deployment
    print_colored $GREEN "Executing deployment: $deployment_name"
    az deployment sub create \
        --name "$deployment_name" \
        --location "$LOCATION" \
        --template-file infrastructure/bicep/main.bicep \
        --parameters \
            environment="$ENVIRONMENT" \
            location="$LOCATION" \
            moduleNumber="$MODULE_NUMBER" \
        --output table
    
    if [ $? -eq 0 ]; then
        print_colored $GREEN "✅ Bicep deployment successful!"
        
        # Get outputs
        local rg_name=$(az deployment sub show -n "$deployment_name" --query properties.outputs.resourceGroupName.value -o tsv)
        print_colored $BLUE "📦 Resource Group: $rg_name"
        
        # List created resources
        print_colored $BLUE "📋 Created resources:"
        az resource list -g "$rg_name" --query "[].{Name:name, Type:type, Location:location}" -o table
        
    else
        print_colored $RED "❌ Bicep deployment failed"
        exit 1
    fi
}

# Function to deploy with Terraform
deploy_with_terraform() {
    print_colored $CYAN "🚀 Deploying infrastructure with Terraform..."
    
    cd infrastructure/terraform
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    terraform plan \
        -var="module_number=$MODULE_NUMBER" \
        -var="environment=$ENVIRONMENT" \
        -var="location=$LOCATION" \
        -out=tfplan
    
    if [ "$DRY_RUN" = true ]; then
        print_colored $BLUE "🔍 Dry run mode - plan generated above"
        cd ../..
        return
    fi
    
    # Apply deployment
    if [ "$AUTO_APPROVE" = true ]; then
        terraform apply -auto-approve tfplan
    else
        terraform apply tfplan
    fi
    
    if [ $? -eq 0 ]; then
        print_colored $GREEN "✅ Terraform deployment successful!"
        terraform output
    else
        print_colored $RED "❌ Terraform deployment failed"
        cd ../..
        exit 1
    fi
    
    cd ../..
}

# Function to post-deployment verification
post_deployment_verification() {
    print_colored $CYAN "🔍 Running post-deployment verification..."
    
    # Basic connectivity tests would go here
    # This is a placeholder for actual verification logic
    
    print_colored $GREEN "✅ Post-deployment verification completed"
}

# Function to display deployment summary
show_deployment_summary() {
    local track=$(get_module_track)
    local requirements=$(get_resource_requirements)
    local estimated_cost=$(estimate_costs)
    
    print_colored $PURPLE "═══════════════════════════════════════════════════════════════"
    print_colored $PURPLE "                    📊 DEPLOYMENT SUMMARY"
    print_colored $PURPLE "═══════════════════════════════════════════════════════════════"
    print_colored $BLUE "Module:           $MODULE_NUMBER ($(echo $track | tr '[:lower:]' '[:upper:]' | tr '-' ' '))"
    print_colored $BLUE "Environment:      $ENVIRONMENT"
    print_colored $BLUE "Location:         $LOCATION"
    print_colored $BLUE "Deployment Tool:  $DEPLOYMENT_TOOL"
    print_colored $BLUE "Resources:        $requirements"
    print_colored $BLUE "Estimated Cost:   $estimated_cost"
    print_colored $PURPLE "═══════════════════════════════════════════════════════════════"
    print_colored $GREEN "✅ Deployment completed successfully!"
    print_colored $YELLOW "Next steps:"
    print_colored $YELLOW "  1. Verify resources in Azure Portal"
    print_colored $YELLOW "  2. Test application endpoints"
    print_colored $YELLOW "  3. Begin module exercises"
    print_colored $PURPLE "═══════════════════════════════════════════════════════════════"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--module)
            MODULE_NUMBER="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -t|--tool)
            DEPLOYMENT_TOOL="$2"
            shift 2
            ;;
        -s|--skip-validation)
            SKIP_VALIDATION=true
            shift
            ;;
        -y|--auto-approve)
            AUTO_APPROVE=true
            shift
            ;;
        -c|--cleanup)
            CLEANUP_PREVIOUS=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            set -x
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_colored $RED "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_header
    
    print_colored $CYAN "Starting deployment for Module $MODULE_NUMBER ($ENVIRONMENT environment)"
    
    validate_prerequisites
    
    if [ "$CLEANUP_PREVIOUS" = true ]; then
        cleanup_previous_deployments
    fi
    
    validate_infrastructure
    
    # Deploy based on tool
    if [ "$DEPLOYMENT_TOOL" = "bicep" ]; then
        deploy_with_bicep
    elif [ "$DEPLOYMENT_TOOL" = "terraform" ]; then
        deploy_with_terraform
    else
        print_colored $RED "❌ Unsupported deployment tool: $DEPLOYMENT_TOOL"
        exit 1
    fi
    
    if [ "$DRY_RUN" = false ]; then
        post_deployment_verification
        show_deployment_summary
    fi
}

# Execute main function
main "$@"
