#!/bin/bash
# ============================================
# make-scripts-executable.sh
# Make all scripts in the scripts directory executable
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "🔧 Making all scripts executable..."
echo "==================================="

# Get the scripts directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Counter for scripts
count=0

# Make all .sh files executable
for script in "$SCRIPT_DIR"/*.sh; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        echo -e "${GREEN}✓${NC} $(basename "$script")"
        ((count++))
    fi
done

# Make all .ps1 files executable (for Git, though Windows handles differently)
for script in "$SCRIPT_DIR"/*.ps1; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        echo -e "${GREEN}✓${NC} $(basename "$script")"
        ((count++))
    fi
done

# Make Python scripts executable
for script in "$SCRIPT_DIR"/*.py; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        echo -e "${GREEN}✓${NC} $(basename "$script")"
        ((count++))
    fi
done

echo ""
echo -e "${GREEN}✅ Made $count scripts executable!${NC}"
echo ""
echo "You can now run any script directly:"
echo "  ./scripts/quick-start.sh"
echo "  ./scripts/diagnostic.sh"
echo "  ./scripts/check-module.sh 5"
