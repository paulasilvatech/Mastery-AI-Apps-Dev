#!/bin/bash
# scripts/smoke-tests.sh - Run smoke tests for Module 13 exercises

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
PASSED=0
FAILED=0
SKIPPED=0

# Functions
test_pass() {
    echo -e "  ${GREEN}✓${NC} $1"
    ((PASSED++))
}

test_fail() {
    echo -e "  ${RED}✗${NC} $1"
    ((FAILED++))
}

test_skip() {
    echo -e "  ${YELLOW}⊘${NC} $1 (skipped)"
    ((SKIPPED++))
}

test_section() {
    echo -e "\n${BLUE}▶ $1${NC}"
}

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    if eval "$test_command" &> /dev/null; then
        test_pass "$test_name"
        return 0
    else
        test_fail "$test_name"
        return 1
    fi
}

echo "🧪 Module 13: Infrastructure as Code - Smoke Tests"
echo "================================================"
echo ""
echo "Running basic validation tests for all exercises..."

# Check prerequisites first
test_section "Prerequisites Check"

if command -v az &> /dev/null; then
    test_pass "Azure CLI installed"
else
    test_fail "Azure CLI not installed"
    echo -e "\n${RED}Prerequisites not met. Please run setup-module.sh first.${NC}"
    exit 1
fi

if command -v terraform &> /dev/null; then
    test_pass "Terraform installed"
else
    test_fail "Terraform not installed"
fi

if command -v gh &> /dev/null; then
    test_pass "GitHub CLI installed"
else
    test_fail "GitHub CLI not installed"
fi

# Exercise 1: Bicep Basics Tests
test_section "Exercise 1: Bicep Basics"

EX1_DIR="exercises/exercise1-bicep-basics"

if [ -d "$EX1_DIR" ]; then
    # Check for required files
    run_test "Exercise 1 directory structure" "[ -d '$EX1_DIR/starter' ] && [ -d '$EX1_DIR/solution' ]"
    
    # Validate Bicep files if they exist
    if [ -f "$EX1_DIR/solution/main.bicep" ]; then
        if az bicep build --file "$EX1_DIR/solution/main.bicep" &> /dev/null; then
            test_pass "Bicep template validation"
        else
            test_fail "Bicep template validation"
        fi
    else
        test_skip "Bicep template validation - no solution file"
    fi
    
    # Check for parameter file
    if [ -f "$EX1_DIR/solution/parameters.json" ]; then
        test_pass "Parameter file exists"
    else
        test_skip "Parameter file check"
    fi
else
    test_skip "Exercise 1 tests - directory not found"
fi

# Exercise 2: Terraform Multi-Environment Tests
test_section "Exercise 2: Terraform Multi-Environment"

EX2_DIR="exercises/exercise2-terraform-multienv"

if [ -d "$EX2_DIR" ]; then
    # Check directory structure
    run_test "Exercise 2 directory structure" "[ -d '$EX2_DIR/starter' ] && [ -d '$EX2_DIR/solution' ]"
    
    # Validate Terraform configuration
    if [ -d "$EX2_DIR/solution" ]; then
        cd "$EX2_DIR/solution" 2>/dev/null || test_skip "Cannot enter solution directory"
        
        if [ -f "main.tf" ]; then
            if terraform init -backend=false &> /dev/null; then
                test_pass "Terraform initialization"
                
                if terraform validate &> /dev/null; then
                    test_pass "Terraform validation"
                else
                    test_fail "Terraform validation"
                fi
            else
                test_fail "Terraform initialization"
            fi
        else
            test_skip "Terraform validation - no main.tf"
        fi
        
        cd - > /dev/null
    else
        test_skip "Exercise 2 Terraform tests"
    fi
else
    test_skip "Exercise 2 tests - directory not found"
fi

# Exercise 3: GitOps Automation Tests
test_section "Exercise 3: GitOps Automation"

EX3_DIR="exercises/exercise3-gitops-automation"

if [ -d "$EX3_DIR" ]; then
    # Check directory structure
    run_test "Exercise 3 directory structure" "[ -d '$EX3_DIR/starter' ] && [ -d '$EX3_DIR/solution' ]"
    
    # Check for GitHub Actions workflows
    if [ -d "$EX3_DIR/solution/.github/workflows" ]; then
        WORKFLOW_COUNT=$(find "$EX3_DIR/solution/.github/workflows" -name "*.yml" -o -name "*.yaml" | wc -l)
        if [ "$WORKFLOW_COUNT" -gt 0 ]; then
            test_pass "GitHub Actions workflows found ($WORKFLOW_COUNT)"
        else
            test_fail "No GitHub Actions workflows found"
        fi
    else
        test_skip "GitHub Actions workflow check"
    fi
    
    # Check for policy files
    if [ -d "$EX3_DIR/solution/policies" ]; then
        test_pass "Policy directory exists"
    else
        test_skip "Policy directory check"
    fi
else
    test_skip "Exercise 3 tests - directory not found"
fi

# Module-level validation
test_section "Module Structure Validation"

# Check for required module files
run_test "README.md exists" "[ -f 'README.md' ]"
run_test "prerequisites.md exists" "[ -f 'prerequisites.md' ]"
run_test "troubleshooting.md exists" "[ -f 'troubleshooting.md' ]"
run_test "best-practices.md exists" "[ -f 'best-practices.md' ]"

# Check scripts directory
run_test "Scripts directory exists" "[ -d 'scripts' ]"
run_test "Setup script executable" "[ -x 'scripts/setup-module.sh' ]"

# Test Azure connectivity (if logged in)
test_section "Azure Connectivity"

if az account show &> /dev/null; then
    test_pass "Azure CLI authenticated"
    
    # Test resource provider registration
    PROVIDERS=("Microsoft.Resources" "Microsoft.Web" "Microsoft.Storage")
    for provider in "${PROVIDERS[@]}"; do
        STATE=$(az provider show --namespace "$provider" --query registrationState -o tsv 2>/dev/null || echo "NotFound")
        if [ "$STATE" = "Registered" ]; then
            test_pass "Provider $provider registered"
        else
            test_fail "Provider $provider not registered"
        fi
    done
else
    test_skip "Azure connectivity tests - not logged in"
fi

# Test Python environment (if exists)
test_section "Python Environment"

if [ -d ".venv" ]; then
    if [ -f ".venv/bin/python" ] || [ -f ".venv/Scripts/python.exe" ]; then
        test_pass "Python virtual environment exists"
    else
        test_fail "Python virtual environment corrupted"
    fi
else
    test_skip "Python environment - not created"
fi

# Summary
echo -e "\n================================================"
echo "Test Summary:"
echo -e "  ${GREEN}Passed:${NC} $PASSED"
echo -e "  ${RED}Failed:${NC} $FAILED"
echo -e "  ${YELLOW}Skipped:${NC} $SKIPPED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    EXIT_CODE=0
else
    echo -e "${RED}❌ Some tests failed.${NC}"
    echo "Please check the failed tests and ensure all prerequisites are met."
    EXIT_CODE=1
fi

if [ $SKIPPED -gt 0 ]; then
    echo -e "${YELLOW}Note: Some tests were skipped. This is normal if exercises haven't been completed yet.${NC}"
fi

exit $EXIT_CODE