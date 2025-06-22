#!/bin/bash
# ============================================
# quick-verify.sh - Quick verification script
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "🔍 Quick Workshop Verification"
echo "=============================="

# Check if main directories exist
echo -n "Checking workshop structure... "
if [[ -d "modules" ]] && [[ -d "scripts" ]] && [[ -d "infrastructure" ]]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Missing core directories. Please run setup-workshop.sh first."
    exit 1
fi

# Check if key tools are available
echo -n "Checking GitHub Copilot... "
if command -v gh &> /dev/null && gh copilot status &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC} (Optional for early modules)"
fi

echo -n "Checking Python... "
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    echo -e "${GREEN}✓${NC} ($PYTHON_VERSION)"
else
    echo -e "${RED}✗${NC}"
fi

echo -n "Checking Node.js... "
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✓${NC} ($NODE_VERSION)"
else
    echo -e "${YELLOW}⚠${NC} (Required for agent modules)"
fi

echo -n "Checking VS Code... "
if command -v code &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC} (Recommended IDE)"
fi

echo ""
echo "✅ Quick verification complete!"
echo "Ready to start with: cd modules/module-01 && code ."
