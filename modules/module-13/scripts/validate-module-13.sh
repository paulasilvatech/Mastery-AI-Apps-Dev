#!/bin/bash
# Module 13: Complete Validation Script
# This script validates all exercises and deployments for Module 13

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Default values
EXERCISE=""
RESOURCE_GROUP=""
VERBOSE=false
CHECK_ALL=false

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -e, --exercise <1|2|3>    Validate specific exercise"
    echo "  -g, --resource-group <rg>  Resource group to validate"
    echo "  -a, --all                  Validate all exercises"
    echo "  -v, --verbose             Enable verbose output"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -e 1 -g rg-module13-exercise1"
    echo "  $0 --all"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--exercise)
            EXERCISE="$2"
            shift 2
            ;;
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -a|--all)
            CHECK_ALL=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

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

# Function to display info
show_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Function to display test header
show_test_header() {
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Validation summary
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to record test result
record_test() {
    local test_name=$1
    local result=$2
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$result" == "pass" ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        show_success "$test_name"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        show_error "$test_name"
    fi
}

# Function to check if logged in to Azure
check_azure_login() {
    if az account show &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to validate Exercise 1
validate_exercise1() {
    local rg=${1:-"rg-module13-exercise1"}
    
    show_test_header "Exercise 1: Bicep Basics Validation"
    
    # Check if resource group exists
    show_progress "Checking resource group..."
    if az group exists --name "$rg" | grep -q true; then
        record_test "Resource group exists" "pass"
    else
        record_test "Resource group exists" "fail"
        show_error "Resource group $rg not found"
        return 1
    fi
    
    # Check App Service Plan
    show_progress "Checking App Service Plan..."
    ASP=$(az appservice plan list --resource-group "$rg" --query "[0].name" -o tsv 2>/dev/null)
    if [ ! -z "$ASP" ]; then
        record_test "App Service Plan deployed" "pass"
        if [ "$VERBOSE" == true ]; then
            show_info "App Service Plan: $ASP"
        fi
    else
        record_test "App Service Plan deployed" "fail"
    fi
    
    # Check Web App
    show_progress "Checking Web App..."
    WEBAPP=$(az webapp list --resource-group "$rg" --query "[0].name" -o tsv 2>/dev/null)
    if [ ! -z "$WEBAPP" ]; then
        record_test "Web App deployed" "pass"
        if [ "$VERBOSE" == true ]; then
            show_info "Web App: $WEBAPP"
            # Check if web app is running
            STATE=$(az webapp show --name "$WEBAPP" --resource-group "$rg" --query "state" -o tsv)
            show_info "Web App State: $STATE"
        fi
    else
        record_test "Web App deployed" "fail"
    fi
    
    # Check Application Insights
    show_progress "Checking Application Insights..."
    AI=$(az monitor app-insights component list --resource-group "$rg" --query "[0].name" -o tsv 2>/dev/null)
    if [ ! -z "$AI" ]; then
        record_test "Application Insights deployed" "pass"
    else
        record_test "Application Insights deployed" "fail"
    fi
    
    # Check Storage Account
    show_progress "Checking Storage Account..."
    STORAGE=$(az storage account list --resource-group "$rg" --query "[0].name" -o tsv 2>/dev/null)
    if [ ! -z "$STORAGE" ]; then
        record_test "Storage Account deployed" "pass"
    else
        record_test "Storage Account deployed" "fail"
    fi
    
    # Check Tags
    show_progress "Checking resource tags..."
    TAGS=$(az resource list --resource-group "$rg" --query "[0].tags" -o json 2>/dev/null)
    if [ "$TAGS" != "null" ] && [ "$TAGS" != "{}" ]; then
        record_test "Resources are tagged" "pass"
    else
        record_test "Resources are tagged" "fail"
    fi
}

# Function to validate Exercise 2
validate_exercise2() {
    show_test_header "Exercise 2: GitOps Automation Validation"
    
    # Check GitHub repository
    show_progress "Checking GitHub repository..."
    if command -v gh &> /dev/null && gh auth status &> /dev/null; then
        # Check for workflows
        if gh workflow list 2>/dev/null | grep -q "Deploy"; then
            record_test "GitHub Actions workflow exists" "pass"
        else
            record_test "GitHub Actions workflow exists" "fail"
        fi
        
        # Check for environments
        show_progress "Checking GitHub environments..."
        # Note: This requires gh cli extension or API call
        show_info "Manual verification required for GitHub environments"
    else
        show_info "GitHub CLI not available - skipping repository checks"
    fi
    
    # Check for multiple resource groups (dev, staging, prod)
    show_progress "Checking multi-environment setup..."
    for env in dev staging prod; do
        rg="rg-module13-$env"
        if az group exists --name "$rg" | grep -q true; then
            record_test "Environment '$env' exists" "pass"
        else
            record_test "Environment '$env' exists" "fail"
        fi
    done
}

# Function to validate Exercise 3
validate_exercise3() {
    show_test_header "Exercise 3: Enterprise Infrastructure Validation"
    
    # Check for hub network
    show_progress "Checking hub network..."
    HUB_VNET=$(az network vnet list --query "[?contains(name, 'hub')].name" -o tsv 2>/dev/null | head -1)
    if [ ! -z "$HUB_VNET" ]; then
        record_test "Hub VNet exists" "pass"
        
        # Check for firewall
        FW=$(az network firewall list --query "[0].name" -o tsv 2>/dev/null)
        if [ ! -z "$FW" ]; then
            record_test "Azure Firewall deployed" "pass"
        else
            record_test "Azure Firewall deployed" "fail"
        fi
    else
        record_test "Hub VNet exists" "fail"
    fi
    
    # Check for spoke networks
    show_progress "Checking spoke networks..."
    SPOKE_VNETS=$(az network vnet list --query "[?contains(name, 'spoke')].name" -o tsv 2>/dev/null | wc -l)
    if [ "$SPOKE_VNETS" -ge 2 ]; then
        record_test "Spoke VNets exist" "pass"
    else
        record_test "Spoke VNets exist" "fail"
    fi
    
    # Check for VNet peering
    show_progress "Checking VNet peering..."
    if [ ! -z "$HUB_VNET" ]; then
        PEERINGS=$(az network vnet peering list --resource-group rg-module13-network --vnet-name "$HUB_VNET" --query "length(@)" -o tsv 2>/dev/null || echo 0)
        if [ "$PEERINGS" -gt 0 ]; then
            record_test "VNet peering configured" "pass"
        else
            record_test "VNet peering configured" "fail"
        fi
    fi
    
    # Check monitoring setup
    show_progress "Checking monitoring infrastructure..."
    LAW=$(az monitor log-analytics workspace list --query "[?contains(name, 'module13')].name" -o tsv 2>/dev/null | head -1)
    if [ ! -z "$LAW" ]; then
        record_test "Log Analytics Workspace exists" "pass"
    else
        record_test "Log Analytics Workspace exists" "fail"
    fi
    
    # Check Key Vault
    show_progress "Checking security infrastructure..."
    KV=$(az keyvault list --query "[?contains(name, 'module13')].name" -o tsv 2>/dev/null | head -1)
    if [ ! -z "$KV" ]; then
        record_test "Key Vault exists" "pass"
    else
        record_test "Key Vault exists" "fail"
    fi
}

# Function to validate Bicep files
validate_bicep_files() {
    show_test_header "Bicep Files Validation"
    
    show_progress "Checking for Bicep files..."
    
    # Check main.bicep
    if [ -f "main.bicep" ]; then
        record_test "main.bicep exists" "pass"
        
        # Lint the file
        if bicep lint main.bicep &> /dev/null; then
            record_test "main.bicep passes linting" "pass"
        else
            record_test "main.bicep passes linting" "fail"
        fi
    else
        record_test "main.bicep exists" "fail"
    fi
    
    # Check for modules
    if [ -d "modules" ]; then
        MODULE_COUNT=$(find modules -name "*.bicep" -type f | wc -l)
        if [ "$MODULE_COUNT" -gt 0 ]; then
            record_test "Bicep modules exist ($MODULE_COUNT found)" "pass"
        else
            record_test "Bicep modules exist" "fail"
        fi
    else
        show_info "No modules directory found"
    fi
}

# Main validation logic
echo -e "${BLUE}======================================"
echo "Module 13: Infrastructure Validation"
echo "======================================${NC}"
echo ""

# Check Azure login
show_progress "Checking Azure login status..."
if ! check_azure_login; then
    show_error "Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

CURRENT_SUB=$(az account show --query name -o tsv)
show_success "Connected to Azure subscription: $CURRENT_SUB"

# Validate based on options
if [ "$CHECK_ALL" == true ]; then
    validate_exercise1
    validate_exercise2
    validate_exercise3
    validate_bicep_files
elif [ ! -z "$EXERCISE" ]; then
    case $EXERCISE in
        1)
            validate_exercise1 "$RESOURCE_GROUP"
            ;;
        2)
            validate_exercise2
            ;;
        3)
            validate_exercise3
            ;;
        *)
            show_error "Invalid exercise number: $EXERCISE"
            usage
            exit 1
            ;;
    esac
else
    # If no specific exercise, run all validations
    validate_exercise1
    validate_exercise2
    validate_exercise3
    validate_bicep_files
fi

# Display summary
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PURPLE}Validation Summary${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Total Tests:  ${TOTAL_TESTS}"
echo -e "Passed:       ${GREEN}${PASSED_TESTS}${NC}"
echo -e "Failed:       ${RED}${FAILED_TESTS}${NC}"
echo ""

if [ "$FAILED_TESTS" -eq 0 ]; then
    echo -e "${GREEN}✨ All validations passed! Great job! ✨${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some validations failed. Review the errors above.${NC}"
    exit 1
fi 