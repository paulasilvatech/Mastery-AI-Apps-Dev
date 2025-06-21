#!/bin/bash

# Update All Workshop Script
# This script updates and organizes the entire workshop structure

set -e

echo "🚀 Starting Complete Workshop Update..."
echo "======================================"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Function to check if script exists and is executable
check_script() {
    if [ ! -f "$1" ]; then
        echo -e "${RED}❌ Script not found: $1${NC}"
        return 1
    fi
    if [ ! -x "$1" ]; then
        echo -e "${YELLOW}⚠️  Making script executable: $1${NC}"
        chmod +x "$1"
    fi
    return 0
}

# Function to run script with status
run_script() {
    local script=$1
    local description=$2
    
    echo -e "\n${BLUE}▶️  $description${NC}"
    echo "Running: $script"
    
    if check_script "$script"; then
        if $script; then
            echo -e "${GREEN}✅ $description completed successfully${NC}"
        else
            echo -e "${RED}❌ $description failed${NC}"
            return 1
        fi
    else
        return 1
    fi
}

# Main execution
echo -e "${YELLOW}📋 Pre-flight checks...${NC}"

# Check if we're in the right directory
if [ ! -d "scripts" ] || [ ! -d "modules" ]; then
    echo -e "${RED}❌ Error: Must be run from the repository root directory${NC}"
    exit 1
fi

# Make all scripts executable
echo -e "${BLUE}Setting permissions...${NC}"
chmod +x scripts/*.sh 2>/dev/null || true

# Run organization scripts in order
run_script "./scripts/reorganize-modules.sh" "Module Reorganization"
run_script "./scripts/organize-modules.sh" "File Organization"
run_script "./scripts/reorganize-files.sh" "File Reorganization"
run_script "./scripts/create-navigation-links.sh" "Navigation Links Creation"
run_script "./scripts/enhance-navigation.sh" "Navigation Enhancement"

# Optional: Validate prerequisites
echo -e "\n${YELLOW}🔍 Validating prerequisites...${NC}"
if [ -f "./scripts/validate-prerequisites.sh" ]; then
    ./scripts/validate-prerequisites.sh || echo -e "${YELLOW}⚠️  Some prerequisites missing (optional)${NC}"
fi

# Create a summary report
echo -e "\n${GREEN}📊 Update Summary${NC}"
echo "=================="
echo "✅ Module structure reorganized"
echo "✅ Files organized by type"
echo "✅ Navigation links created"
echo "✅ Enhanced navigation added"

# Check module count
module_count=$(find modules -type d -name "module-*" | wc -l)
echo -e "\n📦 Total modules found: ${GREEN}$module_count${NC}"

# Git status
echo -e "\n${YELLOW}📝 Git Status:${NC}"
git status --short

echo -e "\n${GREEN}✨ Workshop update complete!${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo "1. Review the changes: git status"
echo "2. Commit the updates: git add . && git commit -m 'Reorganize workshop structure'"
echo "3. Push to GitHub: git push origin main"

# Optional: Create backup before committing
echo -e "\n${YELLOW}💡 Tip: Create a backup before committing changes:${NC}"
echo "./scripts/backup-progress.sh --modules all"
