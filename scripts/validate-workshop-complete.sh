#!/bin/bash
# ============================================
# validate-workshop-complete.sh
# Complete validation of the workshop structure
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
WARNINGS=0
ERRORS=0

echo "🔍 Complete Workshop Validation"
echo "================================"
echo ""

# Function to check if file/directory exists
check_exists() {
    local path=$1
    local type=$2
    local description=$3
    
    ((TOTAL_CHECKS++))
    
    if [ "$type" = "file" ]; then
        if [ -f "$path" ]; then
            echo -e "${GREEN}✓${NC} $description"
            ((PASSED_CHECKS++))
            return 0
        else
            echo -e "${RED}✗${NC} $description (missing)"
            ((ERRORS++))
            return 1
        fi
    else
        if [ -d "$path" ]; then
            echo -e "${GREEN}✓${NC} $description"
            ((PASSED_CHECKS++))
            return 0
        else
            echo -e "${RED}✗${NC} $description (missing)"
            ((ERRORS++))
            return 1
        fi
    fi
}

# Function to check file content
check_content() {
    local file=$1
    local pattern=$2
    local description=$3
    
    ((TOTAL_CHECKS++))
    
    if [ -f "$file" ] && grep -q "$pattern" "$file" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $description"
        ((PASSED_CHECKS++))
        return 0
    else
        echo -e "${YELLOW}⚠${NC} $description"
        ((WARNINGS++))
        return 1
    fi
}

echo -e "${BLUE}=== Repository Root Documents ===${NC}"
check_exists "README.md" "file" "README.md - Main workshop overview"
check_exists "PREREQUISITES.md" "file" "PREREQUISITES.md - Setup requirements"
check_exists "QUICKSTART.md" "file" "QUICKSTART.md - Quick start guide"
check_exists "TROUBLESHOOTING.md" "file" "TROUBLESHOOTING.md - Common issues"
check_exists "FAQ.md" "file" "FAQ.md - Frequently asked questions"
check_exists "PROMPT-GUIDE.md" "file" "PROMPT-GUIDE.md - AI prompting guide"
check_exists "GITOPS-GUIDE.md" "file" "GITOPS-GUIDE.md - GitOps patterns"

echo ""
echo -e "${BLUE}=== Core Directories ===${NC}"
check_exists "scripts" "dir" "scripts/ - Workshop scripts"
check_exists "infrastructure" "dir" "infrastructure/ - IaC templates"
check_exists "docs" "dir" "docs/ - Additional documentation"
check_exists "modules" "dir" "modules/ - 30 workshop modules"
check_exists ".github" "dir" ".github/ - GitHub configuration"

echo ""
echo -e "${BLUE}=== Scripts Directory ===${NC}"
check_exists "scripts/setup-workshop.sh" "file" "setup-workshop.sh"
check_exists "scripts/validate-prerequisites.sh" "file" "validate-prerequisites.sh"
check_exists "scripts/cleanup-resources.sh" "file" "cleanup-resources.sh"
check_exists "scripts/quick-start.sh" "file" "quick-start.sh"
check_exists "scripts/quick-verify.sh" "file" "quick-verify.sh"
check_exists "scripts/diagnostic.sh" "file" "diagnostic.sh"
check_exists "scripts/check-module.sh" "file" "check-module.sh"
check_exists "scripts/README.md" "file" "Scripts documentation"

echo ""
echo -e "${BLUE}=== Infrastructure Directory ===${NC}"
check_exists "infrastructure/bicep" "dir" "bicep/ - Bicep templates"
check_exists "infrastructure/bicep/main.bicep" "file" "main.bicep"
check_exists "infrastructure/bicep/modules" "dir" "bicep/modules/"
check_exists "infrastructure/bicep/parameters" "dir" "bicep/parameters/"
check_exists "infrastructure/terraform" "dir" "terraform/ - Terraform files"
check_exists "infrastructure/github-actions" "dir" "github-actions/ - Workflows"
check_exists "infrastructure/arm-templates" "dir" "arm-templates/ - ARM legacy"

echo ""
echo -e "${BLUE}=== Documentation Directory ===${NC}"
check_exists "docs/architecture-decisions.md" "file" "Architecture decisions"
check_exists "docs/security-guidelines.md" "file" "Security guidelines"
check_exists "docs/cost-optimization.md" "file" "Cost optimization"
check_exists "docs/monitoring-setup.md" "file" "Monitoring setup"

echo ""
echo -e "${BLUE}=== Modules Structure ===${NC}"

# Check all 30 modules
MODULES_FOUND=0
MODULES_COMPLETE=0

for i in $(seq -f "%02g" 1 30); do
    MODULE_DIR="modules/module-$i"
    
    if [ -d "$MODULE_DIR" ]; then
        ((MODULES_FOUND++))
        
        # Check if module has required files
        MODULE_COMPLETE=true
        
        if [ ! -f "$MODULE_DIR/README.md" ]; then
            MODULE_COMPLETE=false
        fi
        
        if [ ! -f "$MODULE_DIR/prerequisites.md" ]; then
            MODULE_COMPLETE=false
        fi
        
        if [ ! -d "$MODULE_DIR/exercises" ]; then
            MODULE_COMPLETE=false
        fi
        
        if [ "$MODULE_COMPLETE" = true ]; then
            ((MODULES_COMPLETE++))
        fi
    fi
done

((TOTAL_CHECKS++))
if [ $MODULES_FOUND -eq 30 ]; then
    echo -e "${GREEN}✓${NC} All 30 modules exist"
    ((PASSED_CHECKS++))
else
    echo -e "${RED}✗${NC} Only $MODULES_FOUND/30 modules found"
    ((ERRORS++))
fi

((TOTAL_CHECKS++))
if [ $MODULES_COMPLETE -eq 30 ]; then
    echo -e "${GREEN}✓${NC} All modules have required structure"
    ((PASSED_CHECKS++))
else
    echo -e "${YELLOW}⚠${NC} Only $MODULES_COMPLETE/30 modules are complete"
    ((WARNINGS++))
fi

# Sample module structure check (Module 01)
echo ""
echo -e "${BLUE}=== Sample Module Check (Module 01) ===${NC}"
if [ -d "modules/module-01" ]; then
    check_exists "modules/module-01/README.md" "file" "Module README"
    check_exists "modules/module-01/prerequisites.md" "file" "Prerequisites"
    check_exists "modules/module-01/best-practices.md" "file" "Best practices"
    check_exists "modules/module-01/exercises" "dir" "Exercises directory"
    
    # Check for 3 exercises
    for level in "easy" "medium" "hard"; do
        EXERCISE_EXISTS=false
        for dir in modules/module-01/exercises/exercise*-$level*; do
            if [ -d "$dir" ]; then
                EXERCISE_EXISTS=true
                break
            fi
        done
        
        ((TOTAL_CHECKS++))
        if [ "$EXERCISE_EXISTS" = true ]; then
            echo -e "${GREEN}✓${NC} Exercise ($level) exists"
            ((PASSED_CHECKS++))
        else
            echo -e "${YELLOW}⚠${NC} Exercise ($level) missing"
            ((WARNINGS++))
        fi
    done
fi

echo ""
echo -e "${BLUE}=== GitHub Actions Workflows ===${NC}"
check_exists ".github/workflows" "dir" "Workflows directory"

# Check for common workflow files
if [ -d ".github/workflows" ]; then
    WORKFLOW_COUNT=$(find .github/workflows -name "*.yml" -o -name "*.yaml" | wc -l)
    ((TOTAL_CHECKS++))
    if [ $WORKFLOW_COUNT -gt 0 ]; then
        echo -e "${GREEN}✓${NC} Found $WORKFLOW_COUNT workflow file(s)"
        ((PASSED_CHECKS++))
    else
        echo -e "${YELLOW}⚠${NC} No workflow files found"
        ((WARNINGS++))
    fi
fi

echo ""
echo -e "${BLUE}=== Content Validation ===${NC}"

# Check README.md content
check_content "README.md" "30 modules" "README mentions 30 modules"
check_content "README.md" "GitHub Copilot" "README mentions GitHub Copilot"
check_content "README.md" "Azure" "README mentions Azure"

# Check if scripts are executable
echo ""
echo -e "${BLUE}=== Script Permissions ===${NC}"
for script in scripts/*.sh; do
    if [ -f "$script" ]; then
        ((TOTAL_CHECKS++))
        if [ -x "$script" ]; then
            echo -e "${GREEN}✓${NC} $(basename $script) is executable"
            ((PASSED_CHECKS++))
        else
            echo -e "${YELLOW}⚠${NC} $(basename $script) is not executable"
            ((WARNINGS++))
        fi
    fi
done

echo ""
echo -e "${BLUE}=== Missing/Incomplete Items ===${NC}"

# Create a list of items that need attention
NEEDS_ATTENTION=()

# Check Bicep modules
if [ -d "infrastructure/bicep/modules" ]; then
    BICEP_MODULE_COUNT=$(find infrastructure/bicep/modules -name "*.bicep" | wc -l)
    if [ $BICEP_MODULE_COUNT -eq 0 ]; then
        NEEDS_ATTENTION+=("Bicep modules are empty - need module templates")
    fi
fi

# Check Terraform modules
if [ -d "infrastructure/terraform" ]; then
    TERRAFORM_FILE_COUNT=$(find infrastructure/terraform -name "*.tf" | wc -l)
    if [ $TERRAFORM_FILE_COUNT -eq 0 ]; then
        NEEDS_ATTENTION+=("Terraform directory is empty - need .tf files")
    fi
fi

# Check GitHub Actions
if [ -d "infrastructure/github-actions" ]; then
    ACTION_FILE_COUNT=$(find infrastructure/github-actions -name "*.yml" -o -name "*.yaml" | wc -l)
    if [ $ACTION_FILE_COUNT -eq 0 ]; then
        NEEDS_ATTENTION+=("GitHub Actions directory is empty - need workflow templates")
    fi
fi

# Check module content
for i in $(seq -f "%02g" 1 30); do
    MODULE_DIR="modules/module-$i"
    if [ -d "$MODULE_DIR" ]; then
        if [ -d "$MODULE_DIR/exercises" ]; then
            EXERCISE_COUNT=$(find "$MODULE_DIR/exercises" -mindepth 1 -maxdepth 1 -type d | wc -l)
            if [ $EXERCISE_COUNT -lt 3 ]; then
                NEEDS_ATTENTION+=("Module $i needs $((3 - EXERCISE_COUNT)) more exercise(s)")
            fi
        fi
    else
        NEEDS_ATTENTION+=("Module $i directory is completely missing")
    fi
done

# Display items needing attention
if [ ${#NEEDS_ATTENTION[@]} -gt 0 ]; then
    echo -e "${YELLOW}Items needing attention:${NC}"
    for item in "${NEEDS_ATTENTION[@]}"; do
        echo -e "  ${YELLOW}•${NC} $item"
    done
else
    echo -e "${GREEN}All major components are in place!${NC}"
fi

echo ""
echo "================================"
echo -e "${CYAN}Validation Summary${NC}"
echo "================================"
echo -e "Total checks: $TOTAL_CHECKS"
echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo -e "Errors: ${RED}$ERRORS${NC}"
echo ""

# Calculate percentage
if [ $TOTAL_CHECKS -gt 0 ]; then
    PERCENTAGE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    
    if [ $PERCENTAGE -eq 100 ]; then
        echo -e "${GREEN}✨ Perfect! Workshop structure is 100% complete!${NC}"
    elif [ $PERCENTAGE -ge 90 ]; then
        echo -e "${GREEN}✅ Excellent! Workshop is $PERCENTAGE% complete.${NC}"
    elif [ $PERCENTAGE -ge 75 ]; then
        echo -e "${BLUE}🔧 Good progress! Workshop is $PERCENTAGE% complete.${NC}"
    elif [ $PERCENTAGE -ge 50 ]; then
        echo -e "${YELLOW}⚠️  Workshop is $PERCENTAGE% complete. More work needed.${NC}"
    else
        echo -e "${RED}❌ Workshop is only $PERCENTAGE% complete. Significant work required.${NC}"
    fi
fi

echo ""
echo "Run './scripts/check-module.sh <number>' for detailed module validation"

# Exit with appropriate code
if [ $ERRORS -gt 0 ]; then
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    exit 0
else
    exit 0
fi
