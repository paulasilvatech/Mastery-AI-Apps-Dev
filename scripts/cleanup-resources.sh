#!/bin/bash

# Mastery AI Code Development Workshop - Cleanup Resources Script
# This script helps clean up Azure resources to avoid unnecessary costs

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLEANUP_LOG="cleanup-$(date +%Y%m%d%H%M%S).log"
DRY_RUN=false
FORCE=false
MODULE_NUMBER=""
ENVIRONMENT=""

# Functions for colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$CLEANUP_LOG"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$CLEANUP_LOG"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$CLEANUP_LOG"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$CLEANUP_LOG"
}

print_banner() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║         🧹 Workshop Resources Cleanup Tool 🧹                   ║
║                                                                  ║
║    Safely remove Azure resources to avoid unwanted costs        ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -m, --module NUMBER    Clean up specific module (1-30)"
    echo "  -e, --environment ENV  Clean up specific environment (dev/staging/prod)"
    echo "  -a, --all             Clean up all workshop resources"
    echo "  -d, --dry-run         Show what would be deleted without deleting"
    echo "  -f, --force           Skip confirmation prompts"
    echo "  -h, --help            Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --module 5 --environment dev     # Clean up Module 5 dev resources"
    echo "  $0 --environment staging --dry-run  # Preview staging cleanup"
    echo "  $0 --all --force                    # Clean up everything without prompts"
    echo
}

# Parse command line arguments
parse_arguments() {
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
            -a|--all)
                MODULE_NUMBER="all"
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Check Azure authentication
check_azure_auth() {
    print_status "Checking Azure authentication..."
    
    if ! az account show >/dev/null 2>&1; then
        print_error "Not logged into Azure. Please run: az login"
        exit 1
    fi
    
    local subscription=$(az account show --query name -o tsv)
    local subscription_id=$(az account show --query id -o tsv)
    print_success "Authenticated with subscription: $subscription ($subscription_id)"
}

# Find workshop resource groups
find_resource_groups() {
    print_status "Finding workshop resource groups..."
    
    local rg_pattern="rg-workshop"
    
    if [ "$MODULE_NUMBER" != "all" ] && [ -n "$MODULE_NUMBER" ]; then
        rg_pattern="${rg_pattern}-module${MODULE_NUMBER}"
    fi
    
    if [ -n "$ENVIRONMENT" ]; then
        rg_pattern="${rg_pattern}-${ENVIRONMENT}"
    fi
    
    local resource_groups=$(az group list --query "[?starts_with(name, '${rg_pattern}')].{Name:name, Location:location, State:properties.provisioningState}" -o table --output tsv)
    
    if [ -z "$resource_groups" ]; then
        print_warning "No resource groups found matching pattern: ${rg_pattern}*"
        return 1
    fi
    
    echo "$resource_groups"
    return 0
}

# Get resource group details and costs
get_resource_group_details() {
    local rg_name=$1
    
    print_status "Analyzing resource group: $rg_name"
    
    # Get resources in the group
    local resources=$(az resource list -g "$rg_name" --query "[].{Name:name, Type:type, Location:location}" -o table 2>/dev/null || echo "")
    local resource_count=$(az resource list -g "$rg_name" --query "length([])" -o tsv 2>/dev/null || echo "0")
    
    # Get tags
    local tags=$(az group show -n "$rg_name" --query "tags" -o json 2>/dev/null || echo "{}")
    
    echo "  Resources: $resource_count"
    echo "  Tags: $tags"
    
    if [ "$resource_count" -gt 0 ]; then
        echo "  Resource Types:"
        az resource list -g "$rg_name" --query "[].type" -o tsv | sort | uniq -c | while read count type; do
            echo "    $count x $type"
        done
    fi
    echo
}

# Calculate estimated costs
calculate_costs() {
    local rg_name=$1
    
    print_status "Estimating costs for resource group: $rg_name"
    
    # Get cost data (requires Cost Management API access)
    local cost_data=$(az consumption usage list --billing-period-name $(date +%Y%m) --resource-group "$rg_name" --query "[].{pretaxCost:pretaxCost, currency:currency}" -o json 2>/dev/null || echo "[]")
    
    if [ "$cost_data" != "[]" ] && [ -n "$cost_data" ]; then
        local total_cost=$(echo "$cost_data" | jq -r 'map(.pretaxCost | tonumber) | add' 2>/dev/null || echo "0")
        local currency=$(echo "$cost_data" | jq -r '.[0].currency // "USD"' 2>/dev/null || echo "USD")
        print_status "Estimated current month cost: $total_cost $currency"
    else
        print_warning "Cost data not available for $rg_name"
    fi
}

# Check for protected resources
check_protected_resources() {
    local rg_name=$1
    
    print_status "Checking for protected resources in: $rg_name"
    
    local protected_found=false
    
    # Check for locks
    local locks=$(az lock list --resource-group "$rg_name" --query "length([])" -o tsv 2>/dev/null || echo "0")
    if [ "$locks" -gt 0 ]; then
        print_warning "Found $locks resource lock(s) in $rg_name"
        protected_found=true
    fi
    
    # Check for backup items
    local backup_items=$(az backup item list --vault-name "*" --resource-group "$rg_name" --query "length([])" -o tsv 2>/dev/null || echo "0")
    if [ "$backup_items" -gt 0 ]; then
        print_warning "Found $backup_items backup item(s) in $rg_name"
        protected_found=true
    fi
    
    # Check for resources with specific tags that indicate production
    local prod_resources=$(az resource list -g "$rg_name" --query "[?tags.Environment=='prod' || tags.environment=='prod' || tags.Critical=='true'].name" -o tsv 2>/dev/null || echo "")
    if [ -n "$prod_resources" ]; then
        print_warning "Found production or critical resources in $rg_name:"
        echo "$prod_resources" | while read resource; do
            echo "  - $resource"
        done
        protected_found=true
    fi
    
    if [ "$protected_found" = true ]; then
        return 1
    fi
    return 0
}

# Stop running resources
stop_running_resources() {
    local rg_name=$1
    
    if [ "$DRY_RUN" = true ]; then
        print_status "[DRY RUN] Would stop running resources in: $rg_name"
        return
    fi
    
    print_status "Stopping running resources in: $rg_name"
    
    # Stop Virtual Machines
    local vms=$(az vm list -g "$rg_name" --query "[?powerState=='VM running'].name" -o tsv 2>/dev/null || echo "")
    if [ -n "$vms" ]; then
        echo "$vms" | while read vm; do
            print_status "Stopping VM: $vm"
            az vm stop -n "$vm" -g "$rg_name" --no-wait
        done
    fi
    
    # Scale down AKS clusters
    local aks_clusters=$(az aks list -g "$rg_name" --query "[].name" -o tsv 2>/dev/null || echo "")
    if [ -n "$aks_clusters" ]; then
        echo "$aks_clusters" | while read cluster; do
            print_status "Scaling down AKS cluster: $cluster"
            az aks scale -n "$cluster" -g "$rg_name" --node-count 0 --no-wait
        done
    fi
    
    # Stop App Services
    local webapps=$(az webapp list -g "$rg_name" --query "[].name" -o tsv 2>/dev/null || echo "")
    if [ -n "$webapps" ]; then
        echo "$webapps" | while read webapp; do
            print_status "Stopping Web App: $webapp"
            az webapp stop -n "$webapp" -g "$rg_name"
        done
    fi
    
    # Stop Function Apps
    local functionapps=$(az functionapp list -g "$rg_name" --query "[].name" -o tsv 2>/dev/null || echo "")
    if [ -n "$functionapps" ]; then
        echo "$functionapps" | while read functionapp; do
            print_status "Stopping Function App: $functionapp"
            az functionapp stop -n "$functionapp" -g "$rg_name"
        done
    fi
}

# Delete resource group
delete_resource_group() {
    local rg_name=$1
    
    if [ "$DRY_RUN" = true ]; then
        print_status "[DRY RUN] Would delete resource group: $rg_name"
        return
    fi
    
    print_status "Deleting resource group: $rg_name"
    
    # Remove locks first
    local locks=$(az lock list --resource-group "$rg_name" --query "[].name" -o tsv 2>/dev/null || echo "")
    if [ -n "$locks" ]; then
        echo "$locks" | while read lock; do
            print_status "Removing lock: $lock"
            az lock delete --name "$lock" --resource-group "$rg_name"
        done
    fi
    
    # Delete the resource group
    az group delete --name "$rg_name" --yes --no-wait
    print_success "Initiated deletion of resource group: $rg_name"
}

# Clean up orphaned resources
cleanup_orphaned_resources() {
    print_status "Checking for orphaned workshop resources..."
    
    if [ "$DRY_RUN" = true ]; then
        print_status "[DRY RUN] Would check for orphaned resources"
        return
    fi
    
    # Clean up orphaned disks
    local orphaned_disks=$(az disk list --query "[?managedBy==null && starts_with(name, 'workshop')].{Name:name, ResourceGroup:resourceGroup}" -o tsv 2>/dev/null || echo "")
    if [ -n "$orphaned_disks" ]; then
        echo "$orphaned_disks" | while read disk rg; do
            print_status "Deleting orphaned disk: $disk"
            az disk delete --name "$disk" --resource-group "$rg" --yes --no-wait
        done
    fi
    
    # Clean up orphaned NICs
    local orphaned_nics=$(az network nic list --query "[?virtualMachine==null && starts_with(name, 'workshop')].{Name:name, ResourceGroup:resourceGroup}" -o tsv 2>/dev/null || echo "")
    if [ -n "$orphaned_nics" ]; then
        echo "$orphaned_nics" | while read nic rg; do
            print_status "Deleting orphaned NIC: $nic"
            az network nic delete --name "$nic" --resource-group "$rg" --no-wait
        done
    fi
    
    # Clean up orphaned public IPs
    local orphaned_ips=$(az network public-ip list --query "[?ipConfiguration==null && starts_with(name, 'workshop')].{Name:name, ResourceGroup:resourceGroup}" -o tsv 2>/dev/null || echo "")
    if [ -n "$orphaned_ips" ]; then
        echo "$orphaned_ips" | while read ip rg; do
            print_status "Deleting orphaned public IP: $ip"
            az network public-ip delete --name "$ip" --resource-group "$rg" --no-wait
        done
    fi
}

# Main cleanup function
perform_cleanup() {
    local resource_groups=$(find_resource_groups)
    
    if [ $? -ne 0 ]; then
        print_warning "No resources found to clean up"
        return 0
    fi
    
    echo "Found workshop resource groups:"
    echo "$resource_groups" | while read rg location state; do
        echo "  - $rg ($location) [$state]"
    done
    echo
    
    # Get detailed information for each resource group
    echo "$resource_groups" | while read rg location state; do
        get_resource_group_details "$rg"
        calculate_costs "$rg"
    done
    
    # Confirmation prompt
    if [ "$FORCE" != true ] && [ "$DRY_RUN" != true ]; then
        echo
        read -p "Are you sure you want to delete these resource groups? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            print_status "Cleanup cancelled by user"
            exit 0
        fi
    fi
    
    # Process each resource group
    echo "$resource_groups" | while read rg location state; do
        echo
        print_status "Processing resource group: $rg"
        
        # Check for protected resources
        if ! check_protected_resources "$rg"; then
            if [ "$FORCE" != true ]; then
                read -p "Resource group $rg has protected resources. Continue? (y/N): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    print_status "Skipping $rg"
                    continue
                fi
            fi
        fi
        
        # Stop running resources first to save costs
        stop_running_resources "$rg"
        
        # Delete the resource group
        delete_resource_group "$rg"
    done
    
    # Clean up orphaned resources
    cleanup_orphaned_resources
}

# Generate cleanup report
generate_report() {
    print_status "Cleanup completed. Log file: $CLEANUP_LOG"
    
    if [ "$DRY_RUN" = true ]; then
        print_success "Dry run completed successfully. No resources were deleted."
    else
        print_success "Resource cleanup initiated. Check Azure portal for deletion progress."
        print_warning "Note: Resource deletion may take several minutes to complete."
    fi
    
    echo
    print_status "Useful commands to check status:"
    echo "• Check running deletions: az group list --query \"[?properties.provisioningState=='Deleting']\""
    echo "• List remaining workshop resources: az resource list --query \"[?contains(name, 'workshop')]\""
    echo "• Check costs: az consumption usage list --billing-period-name \$(date +%Y%m)"
    echo
}

# Main execution
main() {
    parse_arguments "$@"
    
    print_banner
    print_status "Starting workshop cleanup process..."
    print_status "Log file: $CLEANUP_LOG"
    
    if [ "$DRY_RUN" = true ]; then
        print_warning "DRY RUN MODE - No resources will be deleted"
    fi
    
    check_azure_auth
    perform_cleanup
    generate_report
}

# Run main function with all arguments
main "$@"
