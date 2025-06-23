#!/bin/bash
# Cleanup script for Module 13 resources

echo "🧹 Cleaning up Module 13 resources"

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

# Default resource groups
RESOURCE_GROUPS=(
    "rg-module13-exercise1"
    "rg-module13-exercise2"
    "rg-module13-exercise3"
    "rg-module13-dev"
    "rg-module13-staging"
    "rg-module13-prod"
)

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--resource-group)
            SPECIFIC_RG="$2"
            shift 2
            ;;
        --all)
            DELETE_ALL=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -g, --resource-group  Specific resource group to delete"
            echo "  --all                Delete all module 13 resource groups"
            echo "  -h, --help           Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check Azure login
if ! az account show &> /dev/null; then
    print_message "$RED" "❌ Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

# Function to delete resource group
delete_resource_group() {
    local rg=$1
    if az group exists --name "$rg" | grep -q true; then
        print_message "$YELLOW" "Deleting resource group: $rg"
        if az group delete --name "$rg" --yes --no-wait; then
            print_message "$GREEN" "✅ Deletion initiated for: $rg"
        else
            print_message "$RED" "❌ Failed to delete: $rg"
        fi
    else
        print_message "$YELLOW" "Resource group not found: $rg"
    fi
}

# Delete specific resource group
if [ ! -z "$SPECIFIC_RG" ]; then
    delete_resource_group "$SPECIFIC_RG"
    exit 0
fi

# Delete all module resource groups
if [ "$DELETE_ALL" = true ]; then
    print_message "$YELLOW" "⚠️  This will delete all Module 13 resource groups!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        for rg in "${RESOURCE_GROUPS[@]}"; do
            delete_resource_group "$rg"
        done
        print_message "$GREEN" "\n✅ Cleanup initiated for all resource groups"
    else
        print_message "$YELLOW" "Cleanup cancelled"
    fi
else
    # List existing resource groups
    print_message "$YELLOW" "\n📋 Module 13 resource groups:"
    for rg in "${RESOURCE_GROUPS[@]}"; do
        if az group exists --name "$rg" | grep -q true; then
            echo "  - $rg"
        fi
    done
    
    print_message "$YELLOW" "\nTo delete resources, use:"
    echo "  $0 -g <resource-group-name>  # Delete specific group"
    echo "  $0 --all                      # Delete all groups"
fi