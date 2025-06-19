#!/bin/bash

# Cleanup Resources Script
set -e

echo "🧹 Cleaning up workshop resources..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Function to confirm action
confirm() {
    read -p "$1 [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

echo -e "${YELLOW}This script will clean up workshop resources.${NC}"
echo "It will remove:"
echo "  - Temporary files"
echo "  - Build artifacts"
echo "  - Docker containers and images"
echo "  - Cloud resources (if configured)"

if ! confirm "Do you want to continue?"; then
    echo "Cleanup cancelled."
    exit 0
fi

echo -e "\n${YELLOW}Cleaning temporary files...${NC}"

# Clean node_modules in all modules
find modules -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true
echo -e "${GREEN}✓${NC} Removed node_modules directories"

# Clean Python cache
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
echo -e "${GREEN}✓${NC} Removed Python cache files"

# Clean build artifacts
find . -name "dist" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "build" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name ".next" -type d -exec rm -rf {} + 2>/dev/null || true
echo -e "${GREEN}✓${NC} Removed build artifacts"

# Clean log files
find . -name "*.log" -type f -delete 2>/dev/null || true
echo -e "${GREEN}✓${NC} Removed log files"

echo -e "\n${YELLOW}Cleaning Docker resources...${NC}"

if command -v docker &> /dev/null; then
    # Stop all workshop containers
    workshop_containers=$(docker ps -a --filter "label=workshop=ai-code-dev" -q)
    if [ -n "$workshop_containers" ]; then
        docker stop $workshop_containers 2>/dev/null || true
        docker rm $workshop_containers 2>/dev/null || true
        echo -e "${GREEN}✓${NC} Stopped and removed workshop containers"
    fi
    
    # Remove workshop images
    workshop_images=$(docker images --filter "label=workshop=ai-code-dev" -q)
    if [ -n "$workshop_images" ]; then
        docker rmi $workshop_images 2>/dev/null || true
        echo -e "${GREEN}✓${NC} Removed workshop images"
    fi
    
    # Optional: Clean all unused Docker resources
    if confirm "Remove ALL unused Docker resources (not just workshop)?"; then
        docker system prune -af --volumes
        echo -e "${GREEN}✓${NC} Cleaned all unused Docker resources"
    fi
else
    echo -e "${YELLOW}⚠${NC} Docker not found, skipping Docker cleanup"
fi

echo -e "\n${YELLOW}Cleaning cloud resources...${NC}"

# Azure cleanup
if command -v az &> /dev/null && [ -n "$AZURE_RESOURCE_GROUP" ]; then
    if confirm "Delete Azure resource group '$AZURE_RESOURCE_GROUP'?"; then
        az group delete --name "$AZURE_RESOURCE_GROUP" --yes --no-wait
        echo -e "${GREEN}✓${NC} Azure resource group deletion initiated"
    fi
fi

# GitHub cleanup
if command -v gh &> /dev/null; then
    echo -e "${YELLOW}GitHub resources (repos, gists) must be cleaned manually${NC}"
fi

echo -e "\n${YELLOW}Cleaning local Git resources...${NC}"

# Clean Git hooks
if confirm "Remove Git hooks?"; then
    rm -f .git/hooks/pre-commit
    rm -f .git/hooks/commit-msg
    echo -e "${GREEN}✓${NC} Removed Git hooks"
fi

# Clean untracked files
if confirm "Remove all untracked files (git clean)?"; then
    git clean -fdx -e .env -e .env.local
    echo -e "${GREEN}✓${NC} Removed untracked files"
fi

echo -e "\n${YELLOW}Final cleanup...${NC}"

# Clean test outputs
find . -name "coverage" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name ".nyc_output" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "junit.xml" -type f -delete 2>/dev/null || true
echo -e "${GREEN}✓${NC} Removed test outputs"

# Clean IDE files (optional)
if confirm "Remove IDE configuration files (.vscode, .idea)?"; then
    rm -rf .vscode .idea
    echo -e "${GREEN}✓${NC} Removed IDE files"
fi

echo -e "\n${GREEN}✅ Cleanup complete!${NC}"
echo -e "\nRemaining items to clean manually:"
echo "  - Cloud resources (if any remain)"
echo "  - GitHub repositories/gists"
echo "  - API keys and secrets"
echo "  - Custom environment variables" 