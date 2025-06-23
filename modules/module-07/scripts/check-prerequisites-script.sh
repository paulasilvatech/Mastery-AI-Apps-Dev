#!/bin/bash
# Module 07: Prerequisites Check Script
# Validates all requirements for web application development

set -e

echo "🔍 Checking Module 07 Prerequisites..."
echo "====================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track if all checks pass
ALL_PASS=true

# Function to check command exists
check_command() {
    local cmd=$1
    local min_version=$2
    local version_flag=${3:-"--version"}
    
    if command -v $cmd &> /dev/null; then
        version=$($cmd $version_flag 2>&1 | head -1)
        echo -e "${GREEN}✓${NC} $cmd installed: $version"
        
        # TODO: Add version comparison
        return 0
    else
        echo -e "${RED}✗${NC} $cmd not found"
        ALL_PASS=false
        return 1
    fi
}

# Function to check VS Code extension
check_vscode_extension() {
    local extension=$1
    
    if code --list-extensions 2>/dev/null | grep -q "$extension"; then
        echo -e "${GREEN}✓${NC} VS Code extension: $extension"
        return 0
    else
        echo -e "${RED}✗${NC} VS Code extension not found: $extension"
        ALL_PASS=false
        return 1
    fi
}

# Function to check Python package
check_python_package() {
    local package=$1
    
    if python -c "import $package" 2>/dev/null; then
        version=$(python -c "import $package; print($package.__version__)" 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✓${NC} Python package $package: $version"
        return 0
    else
        echo -e "${YELLOW}!${NC} Python package $package not installed globally"
        return 1
    fi
}

# Function to check Node package
check_node_package() {
    local package=$1
    
    if npm list -g $package &>/dev/null; then
        echo -e "${GREEN}✓${NC} Node package: $package (global)"
        return 0
    else
        echo -e "${YELLOW}!${NC} Node package $package not installed globally"
        return 1
    fi
}

echo ""
echo "1. Checking System Requirements..."
echo "---------------------------------"

# Check Node.js
check_command "node" "18.0.0" "--version"
NODE_VERSION=$(node --version 2>/dev/null | sed 's/v//')
if [ -n "$NODE_VERSION" ]; then
    MAJOR_VERSION=$(echo $NODE_VERSION | cut -d. -f1)
    if [ $MAJOR_VERSION -lt 18 ]; then
        echo -e "${YELLOW}⚠${NC}  Node.js version $NODE_VERSION is below recommended 18.x"
        ALL_PASS=false
    fi
fi

# Check Python
check_command "python3" "3.11.0" "--version"
PYTHON_VERSION=$(python3 --version 2>/dev/null | awk '{print $2}')
if [ -n "$PYTHON_VERSION" ]; then
    MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
    MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
    if [ $MAJOR -eq 3 ] && [ $MINOR -lt 11 ]; then
        echo -e "${YELLOW}⚠${NC}  Python version $PYTHON_VERSION is below recommended 3.11+"
        ALL_PASS=false
    fi
fi

# Check other tools
check_command "git" "2.38.0" "--version"
check_command "docker" "24.0.0" "--version"
check_command "code" "" "--version"

echo ""
echo "2. Checking VS Code Extensions..."
echo "---------------------------------"

check_vscode_extension "GitHub.copilot"
check_vscode_extension "GitHub.copilot-chat"
check_vscode_extension "ms-python.python"
check_vscode_extension "dbaeumer.vscode-eslint"
check_vscode_extension "esbenp.prettier-vscode"

echo ""
echo "3. Checking GitHub Authentication..."
echo "-----------------------------------"

if gh auth status &>/dev/null; then
    echo -e "${GREEN}✓${NC} GitHub CLI authenticated"
    
    # Check Copilot status
    if gh copilot status &>/dev/null; then
        echo -e "${GREEN}✓${NC} GitHub Copilot active"
    else
        echo -e "${RED}✗${NC} GitHub Copilot not active"
        echo "  Run: gh copilot status"
        ALL_PASS=false
    fi
else
    echo -e "${RED}✗${NC} GitHub CLI not authenticated"
    echo "  Run: gh auth login"
    ALL_PASS=false
fi

echo ""
echo "4. Checking Global Packages..."
echo "------------------------------"

# Check Node packages
check_node_package "typescript"
check_node_package "pnpm"

echo ""
echo "5. Checking Docker..."
echo "--------------------"

if docker ps &>/dev/null; then
    echo -e "${GREEN}✓${NC} Docker daemon is running"
else
    echo -e "${RED}✗${NC} Docker daemon not running"
    echo "  Start Docker Desktop"
    ALL_PASS=false
fi

echo ""
echo "6. Checking Port Availability..."
echo "--------------------------------"

# Check if common ports are available
for port in 8000 5173 5432 6379; do
    if lsof -i:$port &>/dev/null; then
        echo -e "${YELLOW}⚠${NC}  Port $port is in use"
        # Don't fail for this, just warn
    else
        echo -e "${GREEN}✓${NC} Port $port is available"
    fi
done

echo ""
echo "====================================="
if [ "$ALL_PASS" = true ]; then
    echo -e "${GREEN}✅ All prerequisites satisfied!${NC}"
    echo "You're ready to start Module 07!"
    exit 0
else
    echo -e "${RED}❌ Some prerequisites are missing${NC}"
    echo ""
    echo "Please install missing requirements:"
    echo "- Node.js 18+: https://nodejs.org/"
    echo "- Python 3.11+: https://www.python.org/"
    echo "- Docker Desktop: https://www.docker.com/products/docker-desktop"
    echo "- VS Code Extensions: Open VS Code and install from Extensions panel"
    echo ""
    echo "For detailed setup instructions, see prerequisites.md"
    exit 1
fi