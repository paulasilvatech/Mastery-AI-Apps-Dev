#!/bin/bash

# Module 02 Setup Validation Script
# Checks all prerequisites and validates exercise setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0

# Function to print colored output
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
        ((PASSED_CHECKS++))
    else
        echo -e "${RED}❌ $2${NC}"
    fi
    ((TOTAL_CHECKS++))
}

# Function to check command exists
check_command() {
    if command -v $1 &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to check version
check_version() {
    local cmd=$1
    local flag=$2
    local required=$3
    local current=$($cmd $flag 2>&1 | head -n 1)
    echo "  Current: $current"
    echo "  Required: $required"
}

echo "========================================="
echo "Module 02 - GitHub Copilot Core Features"
echo "Setup Validation Script"
echo "========================================="
echo ""

# Check Python
echo "Checking Python installation..."
if check_command python3; then
    python_version=$(python3 --version 2>&1 | awk '{print $2}')
    major=$(echo $python_version | cut -d. -f1)
    minor=$(echo $python_version | cut -d. -f2)
    
    if [ $major -eq 3 ] && [ $minor -ge 11 ]; then
        print_status 0 "Python 3.11+ installed ($python_version)"
    else
        print_status 1 "Python 3.11+ required (found $python_version)"
    fi
else
    print_status 1 "Python not found"
fi

# Check VS Code
echo ""
echo "Checking VS Code installation..."
if check_command code; then
    print_status 0 "VS Code installed"
    check_version "code" "--version" "Latest"
else
    print_status 1 "VS Code not found"
fi

# Check Git
echo ""
echo "Checking Git installation..."
if check_command git; then
    git_version=$(git --version | awk '{print $3}')
    print_status 0 "Git installed ($git_version)"
else
    print_status 1 "Git not found"
fi

# Check GitHub CLI and Copilot
echo ""
echo "Checking GitHub CLI and Copilot..."
if check_command gh; then
    print_status 0 "GitHub CLI installed"
    
    # Check Copilot status
    echo "  Checking Copilot subscription..."
    if gh copilot status &> /dev/null; then
        print_status 0 "GitHub Copilot active"
    else
        print_status 1 "GitHub Copilot not active or not authenticated"
        echo "  Run: gh auth login && gh extension install github/gh-copilot"
    fi
else
    print_status 1 "GitHub CLI not found"
    echo "  Install: https://cli.github.com/"
fi

# Check VS Code Extensions
echo ""
echo "Checking VS Code extensions..."
if check_command code; then
    extensions=$(code --list-extensions 2>/dev/null)
    
    # Check GitHub Copilot
    if echo "$extensions" | grep -q "GitHub.copilot"; then
        print_status 0 "GitHub Copilot extension installed"
    else
        print_status 1 "GitHub Copilot extension not found"
        echo "  Install: code --install-extension GitHub.copilot"
    fi
    
    # Check GitHub Copilot Chat
    if echo "$extensions" | grep -q "GitHub.copilot-chat"; then
        print_status 0 "GitHub Copilot Chat extension installed"
    else
        print_status 1 "GitHub Copilot Chat extension not found"
        echo "  Install: code --install-extension GitHub.copilot-chat"
    fi
    
    # Check Python extension
    if echo "$extensions" | grep -q "ms-python.python"; then
        print_status 0 "Python extension installed"
    else
        print_status 1 "Python extension not found"
        echo "  Install: code --install-extension ms-python.python"
    fi
fi

# Check module directory structure
echo ""
echo "Checking module directory structure..."
MODULE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

if [ -d "$MODULE_DIR/exercises" ]; then
    print_status 0 "Exercises directory exists"
    
    # Check individual exercises
    for i in 1 2 3; do
        if [ -d "$MODULE_DIR/exercises/exercise$i-"* ]; then
            print_status 0 "Exercise $i directory found"
        else
            print_status 1 "Exercise $i directory missing"
        fi
    done
else
    print_status 1 "Exercises directory not found"
fi

# Check for required files
echo ""
echo "Checking required files..."
required_files=(
    "README.md"
    "prerequisites.md"
    "best-practices.md"
    "troubleshooting.md"
)

for file in "${required_files[@]}"; do
    if [ -f "$MODULE_DIR/$file" ]; then
        print_status 0 "$file exists"
    else
        print_status 1 "$file missing"
    fi
done

# Check Python environment
echo ""
echo "Checking Python environment setup..."
if [ -f "$MODULE_DIR/requirements.txt" ]; then
    print_status 0 "requirements.txt found"
    
    # Check if virtual environment exists
    if [ -d "$MODULE_DIR/venv" ] || [ -d "$MODULE_DIR/.venv" ]; then
        print_status 0 "Virtual environment exists"
    else
        print_status 1 "Virtual environment not found"
        echo "  Create with: python3 -m venv venv"
    fi
else
    print_status 1 "requirements.txt not found"
fi

# Test Copilot functionality
echo ""
echo "Testing Copilot functionality..."
TEST_FILE="$MODULE_DIR/.copilot_test.py"
cat > "$TEST_FILE" << 'EOF'
# Test file for Copilot
# Create a function that calculates the factorial of a number

EOF

echo "  Created test file: $TEST_FILE"
echo "  Open this file in VS Code and check if Copilot provides suggestions"
echo "  Delete after testing: rm $TEST_FILE"

# Check network connectivity
echo ""
echo "Checking network connectivity..."
if ping -c 1 github.com &> /dev/null; then
    print_status 0 "Can reach github.com"
else
    print_status 1 "Cannot reach github.com"
fi

if curl -s --head https://api.github.com | head -n 1 | grep "HTTP/[12].[01] [23].." > /dev/null; then
    print_status 0 "GitHub API accessible"
else
    print_status 1 "GitHub API not accessible"
fi

# Summary
echo ""
echo "========================================="
echo "Validation Summary"
echo "========================================="
echo "Total checks: $TOTAL_CHECKS"
echo "Passed: $PASSED_CHECKS"
echo "Failed: $((TOTAL_CHECKS - PASSED_CHECKS))"

if [ $PASSED_CHECKS -eq $TOTAL_CHECKS ]; then
    echo -e "${GREEN}✅ All prerequisites satisfied!${NC}"
    echo "You're ready to start Module 02 exercises."
    exit 0
else
    echo -e "${YELLOW}⚠️  Some prerequisites are missing.${NC}"
    echo "Please address the issues above before starting."
    exit 1
fi