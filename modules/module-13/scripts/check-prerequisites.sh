#!/bin/bash
# scripts/check-prerequisites.sh - Check prerequisites for Module 13

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Functions
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "🔍 Module 13: Infrastructure as Code - Prerequisites Check"
echo "========================================================"
echo ""

# Track overall status
ALL_PASS=true

# Check Azure CLI
echo "Checking Azure CLI..."
if command -v az &> /dev/null; then
    AZ_VERSION=$(az version --query '"azure-cli"' -o tsv)
    check_pass "Azure CLI installed: $AZ_VERSION"
    
    # Check if logged in
    if az account show &> /dev/null; then
        ACCOUNT=$(az account show --query name -o tsv)
        check_pass "Logged into Azure: $ACCOUNT"
    else
        check_fail "Not logged into Azure. Run: az login"
        ALL_PASS=false
    fi
else
    check_fail "Azure CLI not installed"
    ALL_PASS=false
fi

# Check Terraform
echo -e "\nChecking Terraform..."
if command -v terraform &> /dev/null; then
    TF_VERSION=$(terraform version -json 2>/dev/null | jq -r .terraform_version || terraform version | head -n1)
    check_pass "Terraform installed: $TF_VERSION"
else
    check_fail "Terraform not installed"
    ALL_PASS=false
fi

# Check Bicep
echo -e "\nChecking Bicep..."
if command -v az &> /dev/null && az bicep version &> /dev/null; then
    BICEP_VERSION=$(az bicep version)
    check_pass "Bicep installed: $BICEP_VERSION"
else
    check_fail "Bicep not installed. Run: az bicep install"
    ALL_PASS=false
fi

# Check GitHub CLI
echo -e "\nChecking GitHub CLI..."
if command -v gh &> /dev/null; then
    GH_VERSION=$(gh version | head -n1)
    check_pass "GitHub CLI installed: $GH_VERSION"
    
    # Check authentication
    if gh auth status &> /dev/null; then
        check_pass "GitHub CLI authenticated"
    else
        check_warn "GitHub CLI not authenticated. Run: gh auth login"
    fi
else
    check_fail "GitHub CLI not installed"
    ALL_PASS=false
fi

# Check Git
echo -e "\nChecking Git..."
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version)
    check_pass "Git installed: $GIT_VERSION"
else
    check_fail "Git not installed"
    ALL_PASS=false
fi

# Check Python
echo -e "\nChecking Python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    check_pass "Python installed: $PYTHON_VERSION"
else
    check_warn "Python 3 not installed. Some features may not work."
fi

# Check VS Code
echo -e "\nChecking VS Code..."
if command -v code &> /dev/null; then
    check_pass "VS Code CLI available"
    
    # Check extensions
    EXTENSIONS=$(code --list-extensions 2>/dev/null || echo "")
    
    if echo "$EXTENSIONS" | grep -q "ms-azuretools.vscode-bicep"; then
        check_pass "Bicep extension installed"
    else
        check_warn "Bicep extension not installed"
    fi
    
    if echo "$EXTENSIONS" | grep -q "hashicorp.terraform"; then
        check_pass "Terraform extension installed"
    else
        check_warn "Terraform extension not installed"
    fi
    
    if echo "$EXTENSIONS" | grep -q "github.copilot"; then
        check_pass "GitHub Copilot extension installed"
    else
        check_warn "GitHub Copilot extension not installed"
    fi
else
    check_warn "VS Code CLI not found. VS Code extensions cannot be verified."
fi

# Check Docker (optional but recommended)
echo -e "\nChecking Docker (optional)..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    check_pass "Docker installed: $DOCKER_VERSION"
    
    if docker info &> /dev/null; then
        check_pass "Docker daemon running"
    else
        check_warn "Docker daemon not running"
    fi
else
    check_warn "Docker not installed (optional for this module)"
fi

# Summary
echo -e "\n========================================================"
if [ "$ALL_PASS" = true ]; then
    echo -e "${GREEN}✅ All required prerequisites are met!${NC}"
    echo -e "\nYou're ready to start Module 13!"
else
    echo -e "${RED}❌ Some prerequisites are missing.${NC}"
    echo -e "\nPlease install missing components before proceeding."
    echo "Run './scripts/setup-module.sh' to install missing tools."
    exit 1
fi

echo ""
echo "📚 Next steps:"
echo "  1. Review the module README.md"
echo "  2. Check the prerequisites.md for detailed requirements"
echo "  3. Start with Exercise 1"

exit 0