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
RESOURCE_PREFIX="module13"
DRY_RUN=false
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --prefix)
            RESOURCE_PREFIX="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --prefix PREFIX    Resource prefix (default: module13)"
            echo "  --dry-run         Show what would be deleted without deleting"
            echo "  --force           Skip confirmation prompts"
            echo "  --help            Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "🧹 Module 13: Infrastructure as Code - Resource Cleanup"
echo "====================================================="
echo ""

# Check Azure login
if ! az account show &> /dev/null; then
    log_error "Not logged into Azure. Please run: az login"
    exit 1
fi

ACCOUNT=$(az account show --query name -o tsv)
SUBSCRIPTION=$(az account show --query id -o tsv)

log_info "Azure Account: $ACCOUNT"
log_info "Subscription: $SUBSCRIPTION"
log_info "Resource Prefix: $RESOURCE_PREFIX"

if [ "$DRY_RUN" = true ]; then
    log_warn "DRY RUN MODE - No resources will be deleted"
fi

echo ""

# Find resource groups
log_info "Finding resource groups to clean up..."

RESOURCE_GROUPS=$(az group list --query "[?starts_with(name, '$RESOURCE_PREFIX')].name" -o tsv)

if [ -z "$RESOURCE_GROUPS" ]; then
    log_info "No resource groups found with prefix: $RESOURCE_PREFIX"
    echo ""
    log_info "✅ Cleanup complete - nothing to do!"
    exit 0
fi

echo ""
log_info "Found the following resource groups:"
echo "$RESOURCE_GROUPS" | while read -r rg; do
    echo "  - $rg"
    
    # Show resources in group
    if [ "$DRY_RUN" = true ]; then
        RESOURCES=$(az resource list --resource-group "$rg" --query "[].{name:name, type:type}" -o table 2>/dev/null || echo "Unable to list resources")
        if [ -n "$RESOURCES" ] && [ "$RESOURCES" != "Unable to list resources" ]; then
            echo "$RESOURCES" | sed 's/^/    /'
        fi
    fi
done

# Also check for storage accounts (they might be in different RGs)
log_info "\nFinding storage accounts..."
STORAGE_ACCOUNTS=$(az storage account list --query "[?starts_with(name, '$RESOURCE_PREFIX')].{name:name, resourceGroup:resourceGroup}" -o tsv)

if [ -n "$STORAGE_ACCOUNTS" ]; then
    echo "$STORAGE_ACCOUNTS" | while read -r sa rg; do
        echo "  - $sa (in resource group: $rg)"
    done
fi

# Check for Key Vaults (soft-deleted)
log_info "\nChecking for soft-deleted Key Vaults..."
DELETED_KEYVAULTS=$(az keyvault list-deleted --query "[?contains(name, '$RESOURCE_PREFIX')].name" -o tsv 2>/dev/null || echo "")

if [ -n "$DELETED_KEYVAULTS" ]; then
    echo "Found soft-deleted Key Vaults:"
    echo "$DELETED_KEYVAULTS" | while read -r kv; do
        echo "  - $kv"
    done
fi

# Confirmation
if [ "$FORCE" != true ] && [ "$DRY_RUN" != true ]; then
    echo ""
    log_warn "⚠️  This will DELETE all resources listed above!"
    read -p "Are you sure you want to continue? (yes/no): " -n 3 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Cleanup cancelled."
        exit 0
    fi
fi

echo ""

# Delete resource groups
if [ -n "$RESOURCE_GROUPS" ]; then
    echo "$RESOURCE_GROUPS" | while read -r rg; do
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would delete resource group: $rg"
        else
            log_info "Deleting resource group: $rg"
            az group delete --name "$rg" --yes --no-wait || log_error "Failed to delete resource group: $rg"
        fi
    done
fi

# Purge soft-deleted Key Vaults
if [ -n "$DELETED_KEYVAULTS" ]; then
    echo ""
    echo "$DELETED_KEYVAULTS" | while read -r kv; do
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would purge Key Vault: $kv"
        else
            log_info "Purging soft-deleted Key Vault: $kv"
            LOCATION=$(az keyvault list-deleted --query "[?name=='$kv'].location" -o tsv)
            az keyvault purge --name "$kv" --location "$LOCATION" || log_error "Failed to purge Key Vault: $kv"
        fi
    done
fi

# Clean up Terraform state files
log_info "\nCleaning up Terraform state files..."
if [ -d "exercises" ]; then
    if [ "$DRY_RUN" = true ]; then
        find exercises -name "*.tfstate*" -o -name ".terraform" -type d | while read -r file; do
            log_info "[DRY RUN] Would remove: $file"
        done
    else
        find exercises -name "*.tfstate*" -delete 2>/dev/null || true
        find exercises -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
        log_info "Terraform state files cleaned"
    fi
fi

# Clean up generated files
log_info "\nCleaning up generated files..."
if [ "$DRY_RUN" = true ]; then
    [ -d ".venv" ] && log_info "[DRY RUN] Would remove: .venv"
    [ -f ".env" ] && log_info "[DRY RUN] Would remove: .env"
    find . -name "__pycache__" -type d 2>/dev/null | while read -r file; do
        log_info "[DRY RUN] Would remove: $file"
    done
else
    [ -d ".venv" ] && rm -rf .venv && log_info "Removed .venv"
    [ -f ".env" ] && rm -f .env && log_info "Removed .env"
    find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    log_info "Generated files cleaned"
fi

echo ""

if [ "$DRY_RUN" = true ]; then
    log_info "✅ Dry run complete - no resources were deleted"
    log_info "Run without --dry-run to actually delete resources"
else
    log_info "✅ Cleanup initiated!"
    log_info "Note: Resource group deletion happens asynchronously."
    log_info "You can monitor progress in the Azure Portal or with:"
    echo "  az group list --query \"[?starts_with(name, '$RESOURCE_PREFIX')].{name:name, provisioningState:properties.provisioningState}\" -o table"
fi

echo ""
log_info "Thank you for completing Module 13!"