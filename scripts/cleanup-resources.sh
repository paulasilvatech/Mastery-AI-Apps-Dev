#!/bin/bash

# ========================================================================
# Mastery AI Apps and Development Workshop - Azure Resource Cleanup
# ========================================================================
# This script helps clean up Azure resources created during the workshop
# ========================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RESOURCE_PREFIX="mastery-ai-workshop"
DRY_RUN=false
MODULE=""
ALL_MODULES=false

# Functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Clean up Azure resources created during the Mastery AI Apps Development Workshop.

OPTIONS:
    -m, --module NUMBER     Clean resources for specific module (1-30)
    -a, --all              Clean all workshop resources
    -p, --prefix PREFIX    Resource prefix (default: mastery-ai-workshop)
    -g, --resource-group   Specific resource group to clean
    -d, --dry-run          Show what would be deleted without deleting
    -y, --yes              Skip confirmation prompts
    -h, --help             Show this help message

EXAMPLES:
    # Clean resources from module 5
    $0 --module 5

    # Clean all workshop resources (dry run)
    $0 --all --dry-run

    # Clean specific resource group
    $0 --resource-group my-workshop-rg

    # Clean with custom prefix
    $0 --prefix myworkshop --module 10

EOF
    exit 1
}

check_azure_cli() {
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed"
        print_info "Please install Azure CLI: https://docs.microsoft.com/cli/azure/install-azure-cli"
        exit 1
    fi
}

check_azure_login() {
    print_info "Checking Azure authentication..."
    
    if ! az account show &> /dev/null; then
        print_error "Not logged in to Azure"
        print_info "Please run: az login"
        exit 1
    fi
    
    SUBSCRIPTION=$(az account show --query name -o tsv)
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    print_success "Using subscription: $SUBSCRIPTION"
}

get_module_resources() {
    local module_num=$1
    local prefix=$2
    
    # Define resource patterns for each module
    case $module_num in
        1|2|3|4|5)
            # Fundamentals - minimal resources
            echo "${prefix}-module${module_num}-*"
            ;;
        6|7|8|9|10)
            # Intermediate - web apps, databases
            echo "${prefix}-module${module_num}-*"
            echo "${prefix}-webapp-${module_num}"
            echo "${prefix}-sql-${module_num}"
            ;;
        11|12|13|14|15)
            # Advanced - containers, AKS
            echo "${prefix}-module${module_num}-*"
            echo "${prefix}-aks-${module_num}"
            echo "${prefix}-acr-${module_num}"
            ;;
        16|17|18|19|20)
            # Enterprise - full infrastructure
            echo "${prefix}-module${module_num}-*"
            echo "${prefix}-vnet-${module_num}"
            echo "${prefix}-kv-${module_num}"
            ;;
        21|22|23|24|25)
            # AI Agents - AI services
            echo "${prefix}-module${module_num}-*"
            echo "${prefix}-openai-${module_num}"
            echo "${prefix}-search-${module_num}"
            ;;
        26|27|28|29|30)
            # Mastery - complex resources
            echo "${prefix}-module${module_num}-*"
            echo "${prefix}-enterprise-${module_num}"
            ;;
        *)
            echo "${prefix}-module${module_num}-*"
            ;;
    esac
}

list_resource_groups() {
    local pattern=$1
    
    if [[ -z "$pattern" ]]; then
        pattern="$RESOURCE_PREFIX"
    fi
    
    az group list --query "[?contains(name, '$pattern')].name" -o tsv
}

list_resources_in_group() {
    local rg=$1
    az resource list --resource-group "$rg" --query "[].{Name:name, Type:type}" -o table
}

delete_resource_group() {
    local rg=$1
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_warning "[DRY RUN] Would delete resource group: $rg"
        list_resources_in_group "$rg"
    else
        print_info "Deleting resource group: $rg"
        az group delete --name "$rg" --yes --no-wait
        print_success "Delete initiated for: $rg"
    fi
}

clean_module_resources() {
    local module_num=$1
    
    print_header "Cleaning Module $module_num Resources"
    
    # Get resource patterns for this module
    local patterns=$(get_module_resources "$module_num" "$RESOURCE_PREFIX")
    
    # Find matching resource groups
    local found_groups=()
    for pattern in $patterns; do
        while IFS= read -r group; do
            if [[ ! " ${found_groups[@]} " =~ " ${group} " ]]; then
                found_groups+=("$group")
            fi
        done < <(list_resource_groups "$pattern")
    done
    
    if [[ ${#found_groups[@]} -eq 0 ]]; then
        print_info "No resources found for module $module_num"
        return
    fi
    
    print_info "Found ${#found_groups[@]} resource group(s) for module $module_num:"
    for group in "${found_groups[@]}"; do
        echo "  - $group"
    done
    
    # Delete each group
    for group in "${found_groups[@]}"; do
        delete_resource_group "$group"
    done
}

clean_all_resources() {
    print_header "Cleaning All Workshop Resources"
    
    local all_groups=($(list_resource_groups "$RESOURCE_PREFIX"))
    
    if [[ ${#all_groups[@]} -eq 0 ]]; then
        print_info "No workshop resources found"
        return
    fi
    
    print_warning "Found ${#all_groups[@]} resource group(s) to clean:"
    for group in "${all_groups[@]}"; do
        echo "  - $group"
    done
    
    if [[ "$YES_FLAG" != "true" ]] && [[ "$DRY_RUN" != "true" ]]; then
        read -p "Are you sure you want to delete all these resources? (y/N): " confirm
        if [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]]; then
            print_warning "Cleanup cancelled"
            exit 0
        fi
    fi
    
    # Delete all groups
    for group in "${all_groups[@]}"; do
        delete_resource_group "$group"
    done
}

clean_specific_group() {
    local rg=$1
    
    print_header "Cleaning Resource Group: $rg"
    
    # Check if group exists
    if ! az group exists --name "$rg" &> /dev/null; then
        print_error "Resource group '$rg' does not exist"
        exit 1
    fi
    
    # Show resources in the group
    print_info "Resources in group:"
    list_resources_in_group "$rg"
    
    if [[ "$YES_FLAG" != "true" ]] && [[ "$DRY_RUN" != "true" ]]; then
        read -p "Delete this resource group? (y/N): " confirm
        if [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]]; then
            print_warning "Cleanup cancelled"
            exit 0
        fi
    fi
    
    delete_resource_group "$rg"
}

check_deletions() {
    print_header "Checking Deletion Status"
    
    # Get all workshop-related groups
    local remaining_groups=($(list_resource_groups "$RESOURCE_PREFIX"))
    
    if [[ ${#remaining_groups[@]} -eq 0 ]]; then
        print_success "All workshop resources have been cleaned up!"
    else
        print_warning "The following resource groups are still being deleted:"
        for group in "${remaining_groups[@]}"; do
            local state=$(az group show --name "$group" --query properties.provisioningState -o tsv 2>/dev/null || echo "Unknown")
            echo "  - $group (State: $state)"
        done
        print_info "Deletion can take several minutes. Check again later with: $0 --check"
    fi
}

cleanup_other_resources() {
    print_header "Cleaning Other Resources"
    
    # Clean up Key Vault soft-deleted vaults
    print_info "Checking for soft-deleted Key Vaults..."
    local deleted_vaults=$(az keyvault list-deleted --query "[?contains(name, '$RESOURCE_PREFIX')].name" -o tsv)
    
    if [[ -n "$deleted_vaults" ]]; then
        print_warning "Found soft-deleted Key Vaults:"
        echo "$deleted_vaults"
        
        if [[ "$DRY_RUN" != "true" ]]; then
            for vault in $deleted_vaults; do
                print_info "Purging Key Vault: $vault"
                az keyvault purge --name "$vault" --no-wait
            done
        fi
    fi
    
    # Clean up orphaned disks
    print_info "Checking for orphaned managed disks..."
    local orphaned_disks=$(az disk list --query "[?contains(name, '$RESOURCE_PREFIX') && diskState=='Unattached'].name" -o tsv)
    
    if [[ -n "$orphaned_disks" ]]; then
        print_warning "Found orphaned disks:"
        echo "$orphaned_disks"
        
        if [[ "$DRY_RUN" != "true" ]]; then
            for disk in $orphaned_disks; do
                local rg=$(az disk show --name "$disk" --query resourceGroup -o tsv)
                print_info "Deleting disk: $disk"
                az disk delete --name "$disk" --resource-group "$rg" --yes --no-wait
            done
        fi
    fi
}

main() {
    clear
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║   Mastery AI Apps and Development Workshop                  ║"
    echo "║              Azure Resource Cleanup                          ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Check Azure CLI
    check_azure_cli
    check_azure_login
    
    # Process based on options
    if [[ -n "$SPECIFIC_RG" ]]; then
        clean_specific_group "$SPECIFIC_RG"
    elif [[ "$CHECK_FLAG" == "true" ]]; then
        check_deletions
    elif [[ "$ALL_MODULES" == "true" ]]; then
        clean_all_resources
        cleanup_other_resources
    elif [[ -n "$MODULE" ]]; then
        clean_module_resources "$MODULE"
    else
        print_error "No action specified. Use --help for usage information."
        exit 1
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_warning "This was a dry run. No resources were actually deleted."
        print_info "Remove --dry-run flag to perform actual cleanup."
    else
        print_success "Cleanup process initiated!"
        print_info "Note: Resource deletion happens asynchronously and may take several minutes."
        print_info "Run '$0 --check' to verify completion."
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--module)
            MODULE="$2"
            if [[ ! "$MODULE" =~ ^[0-9]+$ ]] || [[ $MODULE -lt 1 ]] || [[ $MODULE -gt 30 ]]; then
                print_error "Invalid module number: $MODULE (must be 1-30)"
                exit 1
            fi
            shift 2
            ;;
        -a|--all)
            ALL_MODULES=true
            shift
            ;;
        -p|--prefix)
            RESOURCE_PREFIX="$2"
            shift 2
            ;;
        -g|--resource-group)
            SPECIFIC_RG="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -y|--yes)
            YES_FLAG=true
            shift
            ;;
        --check)
            CHECK_FLAG=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Run main function
main
