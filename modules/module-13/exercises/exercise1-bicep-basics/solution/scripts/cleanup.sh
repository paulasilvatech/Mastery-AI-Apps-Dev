#!/bin/bash
# cleanup.sh - Script to clean up resources created by Exercise 1

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
RESOURCE_GROUP="rg-bicep-exercise1"

# Header
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Resource Cleanup Script           ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# Check Azure login
echo -e "${YELLOW}🔐 Checking Azure login...${NC}"
if ! az account show &>/dev/null; then
    echo -e "${RED}❌ Not logged in to Azure. Please run 'az login' first.${NC}"
    exit 1
fi

SUBSCRIPTION=$(az account show --query name -o tsv)
echo -e "${GREEN}✅ Logged in to subscription: $SUBSCRIPTION${NC}"

# Check if resource group exists
echo -e "\n${YELLOW}🔍 Checking resource group...${NC}"
if ! az group exists --name $RESOURCE_GROUP | grep -q true; then
    echo -e "${YELLOW}⚠️  Resource group '$RESOURCE_GROUP' does not exist${NC}"
    exit 0
fi

# List resources in the group
echo -e "\n${YELLOW}📋 Resources in '$RESOURCE_GROUP':${NC}"
az resource list \
    --resource-group $RESOURCE_GROUP \
    --output table

# Confirm deletion
echo -e "\n${RED}⚠️  WARNING: This will delete all resources in the resource group!${NC}"
echo -e "${RED}⚠️  Resource Group: $RESOURCE_GROUP${NC}"
echo ""
read -p "Are you sure you want to delete all resources? Type 'yes' to confirm: " -r
echo ""

if [[ ! $REPLY == "yes" ]]; then
    echo -e "${YELLOW}⏹️  Cleanup cancelled${NC}"
    exit 0
fi

# Delete resource group
echo -e "\n${YELLOW}🗑️  Deleting resource group...${NC}"
echo -e "${BLUE}This may take a few minutes...${NC}"

if az group delete --name $RESOURCE_GROUP --yes --no-wait; then
    echo -e "${GREEN}✅ Resource group deletion initiated${NC}"
    
    # Monitor deletion progress
    echo -e "\n${YELLOW}⏳ Waiting for deletion to complete...${NC}"
    
    while az group exists --name $RESOURCE_GROUP | grep -q true; do
        echo -n "."
        sleep 5
    done
    
    echo -e "\n${GREEN}✅ Resource group deleted successfully!${NC}"
else
    echo -e "${RED}❌ Failed to delete resource group${NC}"
    exit 1
fi

# Clean up local files
echo -e "\n${YELLOW}🧹 Cleaning up local files...${NC}"

# Remove generated ARM templates
if ls ../*.json 2>/dev/null | grep -q .; then
    rm -f ../*.json
    echo -e "${GREEN}✅ Removed generated ARM templates${NC}"
fi

# Summary
echo -e "\n${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Cleanup Complete! 🎉            ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo -e "${GREEN}✅ All resources have been deleted${NC}"
echo -e "${GREEN}✅ Local files cleaned up${NC}" 