#!/bin/bash
# scripts/cleanup-resources.sh - Clean up Azure resources created in Module 13

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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

# Default values
MODULE_NUMBER=${1:-13}
ENVIRONMENT=${2:-all}
FORCE=${3:-false}

# Resource group patterns
RG_PATTERNS=(
    "rg-workshop-module13"
    "rg-workshop13-dev"
    "rg-workshop13-staging"
    "rg-workshop13-prod"
    "rg-terraform-state"
)

# Show usage
usage() {
    echo "Usage: $0 [MODULE_NUMBER] [ENVIRONMENT] [FORCE]"
    echo ""
    echo "Arguments:"
    echo "  MODULE_NUMBER - Module number (default: 13)"
    echo "  ENVIRONMENT   - Environment to clean (dev|staging|prod|all) (default: all)"
    echo "  FORCE        - Skip confirmation (true|false) (default: false)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Clean all Module 13 resources"
    echo "  $0 13 dev             # Clean only dev environment"
    echo "  $0 13 all true        # Clean all without confirmation"
    exit 1
}

# Check Azure login
check_azure_login() {
    if ! az account show &> /dev/null; then
        log_error "Not logged into Azure. Please run 'az login'"
        exit 1
    fi
    
    SUBSCRIPTION=$(az account show --query name -o tsv)
    log_info "Using subscription: $SUBSCRIPTION"
}

# Find resource groups
find_resource_groups() {
    log_info "Finding resource groups to clean..."
    
    FOUND_GROUPS=()
    
    for pattern in "${RG_PATTERNS[@]}"; do
        # Handle environment-specific cleanup
        if [[ "$ENVIRONMENT" != "all" && "$pattern" == *"-$ENVIRONMENT" ]] || [[ "$ENVIRONMENT" == "all" ]]; then
            if az group exists --name "$pattern" | grep -q true; then
                FOUND_GROUPS+=("$pattern")
            fi
        fi
    done
    
    # Also find any groups tagged with Module=13
    TAGGED_GROUPS=$(az group list --query "[?tags.Module=='13' || tags.Module=='Module-13'].name" -o tsv)
    for group in $TAGGED_GROUPS; do
        if [[ ! " ${FOUND_GROUPS[@]} " =~ " ${group} " ]]; then
            FOUND_GROUPS+=("$group")
        fi
    done
    
    if [ ${#FOUND_GROUPS[@]} -eq 0 ]; then
        log_info "No Module 13 resource groups found to clean"
        exit 0
    fi
    
    log_info "Found ${#FOUND_GROUPS[@]} resource group(s) to clean:"
    for group in "${FOUND_GROUPS[@]}"; do
        echo "  - $group"
    done
}

# Show resources that will be deleted
show_resources() {
    log_info "Resources that will be deleted:"
    echo ""
    
    for group in "${FOUND_GROUPS[@]}"; do
        echo "Resource Group: $group"
        echo "----------------------------------------"
        
        # Get resource count and estimated cost
        RESOURCE_COUNT=$(az resource list --resource-group "$group" --query "length(@)" -o tsv 2>/dev/null || echo "0")
        
        if [ "$RESOURCE_COUNT" -gt 0 ]; then
            az resource list --resource-group "$group" \
                --query "[].{Name:name, Type:type}" \
                --output table 2>/dev/null || echo "Unable to list resources"
        else
            echo "  (No resources in this group)"
        fi
        echo ""
    done
}

# Backup important data
backup_data() {
    log_info "Backing up important data..."
    
    BACKUP_DIR="backups/module13-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup deployment outputs if they exist
    if [ -f "deployment-outputs.json" ]; then
        cp deployment-outputs.json "$BACKUP_DIR/"
    fi
    
    # Export resource group configurations
    for group in "${FOUND_GROUPS[@]}"; do
        if [[ "$group" != "rg-terraform-state" ]]; then  # Don't export state RG
            az group export --name "$group" \
                --output-folder "$BACKUP_DIR" \
                2>/dev/null || log_warn "Failed to export $group"
        fi
    done
    
    log_info "Backup saved to: $BACKUP_DIR"
}

# Clean Terraform state
clean_terraform_state() {
    if [[ " ${FOUND_GROUPS[@]} " =~ " rg-terraform-state " ]]; then
        log_warn "Terraform state resource group found!"
        echo ""
        echo "⚠️  WARNING: Deleting the Terraform state will make it impossible to"
        echo "manage existing infrastructure with Terraform. Only proceed if you're"
        echo "sure all managed resources have been destroyed."
        echo ""
        
        if [[ "$FORCE" != "true" ]]; then
            read -p "Are you SURE you want to delete Terraform state? (yes/no): " -r
            if [[ ! $REPLY == "yes" ]]; then
                log_info "Skipping Terraform state deletion"
                # Remove from array
                FOUND_GROUPS=("${FOUND_GROUPS[@]/rg-terraform-state}")
            fi
        fi
    fi
}

# Delete resource groups
delete_resource_groups() {
    log_info "Starting resource deletion..."
    
    for group in "${FOUND_GROUPS[@]}"; do
        if [ -n "$group" ]; then
            log_info "Deleting resource group: $group"
            
            # Delete with no-wait for parallel deletion
            az group delete --name "$group" --yes --no-wait || {
                log_error "Failed to delete $group"
            }
        fi
    done
    
    log_info "Deletion commands issued. Monitoring progress..."
    
    # Monitor deletion progress
    TOTAL_GROUPS=${#FOUND_GROUPS[@]}
    while true; do
        REMAINING=0
        for group in "${FOUND_GROUPS[@]}"; do
            if [ -n "$group" ] && az group exists --name "$group" | grep -q true; then
                ((REMAINING++))
            fi
        done
        
        if [ $REMAINING -eq 0 ]; then
            break
        fi
        
        log_info "Waiting for deletion to complete... ($REMAINING/$TOTAL_GROUPS remaining)"
        sleep 10
    done
    
    log_info "All resource groups deleted successfully!"
}

# Clean local files
clean_local_files() {
    log_info "Cleaning local files..."
    
    # Terraform files
    find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.tfstate*" -type f -delete 2>/dev/null || true
    find . -name "*.tfplan" -type f -delete 2>/dev/null || true
    find . -name ".terraform.lock.hcl" -type f -delete 2>/dev/null || true
    
    # Bicep compiled files
    find . -name "*.azrm.json" -type f -delete 2>/dev/null || true
    
    # Deployment outputs
    find . -name "deployment-outputs.json" -type f -delete 2>/dev/null || true
    
    log_info "Local files cleaned"
}

# Main cleanup function
main() {
    echo "🧹 Module 13: Resource Cleanup Script"
    echo "===================================="
    echo ""
    
    # Parse arguments
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        usage
    fi
    
    check_azure_login
    find_resource_groups
    
    if [ ${#FOUND_GROUPS[@]} -eq 0 ]; then
        log_info "No resources to clean"
        exit 0
    fi
    
    show_resources
    clean_terraform_state
    
    # Confirm deletion
    if [[ "$FORCE" != "true" ]]; then
        echo ""
        log_warn "This will DELETE all resources shown above!"
        read -p "Are you sure you want to continue? (y/N): " -n 1 -r
        echo ""
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Cleanup cancelled"
            exit 0
        fi
    fi
    
    backup_data
    delete_resource_groups
    
    # Ask about local files
    if [[ "$FORCE" != "true" ]]; then
        echo ""
        read -p "Do you also want to clean local state files? (y/N): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            clean_local_files
        fi
    else
        clean_local_files
    fi
    
    echo ""
    log_info "✅ Cleanup complete!"
    log_info "All Module 13 resources have been removed."
}

# Run main
main "$@"
