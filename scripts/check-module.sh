#!/bin/bash
# ============================================
# check-module.sh - Module-specific checker
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if module number is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <module-number>"
    echo "Example: $0 5"
    exit 1
fi

MODULE_NUMBER=$1
MODULE_DIR="modules/module-$(printf "%02d" $MODULE_NUMBER)"

echo "🔍 Checking Module $MODULE_NUMBER"
echo "================================"
echo ""

# Check if module exists
if [ ! -d "$MODULE_DIR" ]; then
    echo -e "${RED}❌ Module $MODULE_NUMBER not found!${NC}"
    echo "Expected directory: $MODULE_DIR"
    exit 1
fi

cd "$MODULE_DIR"

echo -e "${BLUE}Module Structure:${NC}"
echo "-----------------"

# Check required files
REQUIRED_FILES=(
    "README.md"
    "prerequisites.md"
    "best-practices.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "$file: ${GREEN}✓${NC}"
    else
        echo -e "$file: ${RED}✗ Missing${NC}"
    fi
done

# Check exercises directory
if [ -d "exercises" ]; then
    echo -e "exercises/: ${GREEN}✓${NC}"
    
    # Check individual exercises
    for i in 1 2 3; do
        EXERCISE_DIR="exercises/exercise$i-"
        if ls -d ${EXERCISE_DIR}* 2>/dev/null | head -1 > /dev/null; then
            FOUND_DIR=$(ls -d ${EXERCISE_DIR}* 2>/dev/null | head -1)
            echo -e "  $(basename $FOUND_DIR): ${GREEN}✓${NC}"
            
            # Check exercise components
            if [ -d "$FOUND_DIR/instructions" ]; then
                echo -e "    instructions/: ${GREEN}✓${NC}"
            else
                echo -e "    instructions/: ${YELLOW}⚠${NC}"
            fi
            
            if [ -d "$FOUND_DIR/starter" ]; then
                echo -e "    starter/: ${GREEN}✓${NC}"
            else
                echo -e "    starter/: ${YELLOW}⚠${NC}"
            fi
            
            if [ -d "$FOUND_DIR/solution" ]; then
                echo -e "    solution/: ${GREEN}✓${NC}"
            else
                echo -e "    solution/: ${YELLOW}⚠${NC}"
            fi
        else
            echo -e "  exercise$i: ${RED}✗ Missing${NC}"
        fi
    done
else
    echo -e "exercises/: ${RED}✗ Missing${NC}"
fi

# Check resources directory
if [ -d "resources" ]; then
    echo -e "resources/: ${GREEN}✓${NC}"
    FILE_COUNT=$(find resources -type f | wc -l)
    echo -e "  Files: $FILE_COUNT"
else
    echo -e "resources/: ${YELLOW}⚠ Optional${NC}"
fi

echo ""
echo -e "${BLUE}Module Content Analysis:${NC}"
echo "------------------------"

# Check README.md content
if [ -f "README.md" ]; then
    # Check for required sections
    echo "README.md sections:"
    
    if grep -q "## Overview" README.md; then
        echo -e "  Overview: ${GREEN}✓${NC}"
    else
        echo -e "  Overview: ${YELLOW}⚠${NC}"
    fi
    
    if grep -q "## Learning Objectives" README.md; then
        echo -e "  Learning Objectives: ${GREEN}✓${NC}"
    else
        echo -e "  Learning Objectives: ${YELLOW}⚠${NC}"
    fi
    
    if grep -q "## Exercises" README.md; then
        echo -e "  Exercises: ${GREEN}✓${NC}"
    else
        echo -e "  Exercises: ${YELLOW}⚠${NC}"
    fi
    
    # Count lines
    LINE_COUNT=$(wc -l < README.md)
    echo -e "  Total lines: $LINE_COUNT"
fi

# Module-specific checks based on number
echo ""
echo -e "${BLUE}Module-Specific Requirements:${NC}"
echo "-----------------------------"

case $MODULE_NUMBER in
    1|2|3|4|5)
        echo "Track: Fundamentals"
        # Check for Python files
        PYTHON_FILES=$(find . -name "*.py" | wc -l)
        echo -e "Python files found: $PYTHON_FILES"
        ;;
    6|7|8|9|10)
        echo "Track: Intermediate"
        # Check for web-related files
        WEB_FILES=$(find . -name "*.html" -o -name "*.js" -o -name "*.css" | wc -l)
        echo -e "Web files found: $WEB_FILES"
        ;;
    11|12|13|14|15)
        echo "Track: Advanced"
        # Check for Docker/K8s files
        if [ -f "Dockerfile" ] || find . -name "*.yaml" -o -name "*.yml" | grep -q .; then
            echo -e "Container/K8s files: ${GREEN}✓${NC}"
        else
            echo -e "Container/K8s files: ${YELLOW}⚠${NC}"
        fi
        ;;
    16|17|18|19|20)
        echo "Track: Enterprise"
        # Check for security/monitoring related content
        if grep -q -i "security\|monitor\|observability" README.md; then
            echo -e "Enterprise topics: ${GREEN}✓${NC}"
        else
            echo -e "Enterprise topics: ${YELLOW}⚠${NC}"
        fi
        ;;
    21|22|23|24|25)
        echo "Track: AI Agents & MCP"
        # Check for agent-related files
        AGENT_FILES=$(find . -name "*agent*" -o -name "*mcp*" | wc -l)
        echo -e "Agent-related files: $AGENT_FILES"
        ;;
    26)
        echo "Track: Enterprise Mastery (.NET)"
        # Check for .NET files
        DOTNET_FILES=$(find . -name "*.cs" -o -name "*.csproj" | wc -l)
        echo -e ".NET files found: $DOTNET_FILES"
        ;;
    27)
        echo "Track: Enterprise Mastery (COBOL)"
        # Check for COBOL content
        if grep -q -i "cobol" README.md; then
            echo -e "COBOL content: ${GREEN}✓${NC}"
        else
            echo -e "COBOL content: ${YELLOW}⚠${NC}"
        fi
        ;;
    28)
        echo "Track: Enterprise Mastery (DevSecOps)"
        # Check for security content
        if grep -q -i "security\|devsecops" README.md; then
            echo -e "Security content: ${GREEN}✓${NC}"
        else
            echo -e "Security content: ${YELLOW}⚠${NC}"
        fi
        ;;
    29|30)
        echo "Track: Mastery Validation"
        # Check for comprehensive content
        if [ -f "exercises/exercise3-hard/instructions/part1.md" ]; then
            echo -e "Challenge exercise: ${GREEN}✓${NC}"
        else
            echo -e "Challenge exercise: ${YELLOW}⚠${NC}"
        fi
        ;;
esac

# Dependencies check
echo ""
echo -e "${BLUE}Dependencies Check:${NC}"
echo "-------------------"

# Python requirements
if [ -f "requirements.txt" ]; then
    echo -e "requirements.txt: ${GREEN}✓${NC}"
    REQ_COUNT=$(grep -v '^#' requirements.txt | grep -v '^$' | wc -l)
    echo -e "  Dependencies: $REQ_COUNT"
elif [ $MODULE_NUMBER -le 25 ]; then
    echo -e "requirements.txt: ${YELLOW}⚠ Expected for Python modules${NC}"
fi

# Node.js package.json
if [ -f "package.json" ]; then
    echo -e "package.json: ${GREEN}✓${NC}"
    if [ -f "package-lock.json" ]; then
        echo -e "package-lock.json: ${GREEN}✓${NC}"
    fi
elif [ $MODULE_NUMBER -ge 21 ] && [ $MODULE_NUMBER -le 25 ]; then
    echo -e "package.json: ${YELLOW}⚠ Expected for agent modules${NC}"
fi

# .NET project files
if [ $MODULE_NUMBER -eq 26 ] || [ $MODULE_NUMBER -eq 29 ]; then
    if find . -name "*.csproj" | grep -q .; then
        echo -e ".NET project files: ${GREEN}✓${NC}"
    else
        echo -e ".NET project files: ${YELLOW}⚠ Expected for .NET modules${NC}"
    fi
fi

echo ""
echo "================================"
echo -e "${GREEN}✅ Module check complete!${NC}"
echo ""

# Summary
ISSUES=0
[ ! -f "README.md" ] && ((ISSUES++))
[ ! -f "prerequisites.md" ] && ((ISSUES++))
[ ! -d "exercises" ] && ((ISSUES++))

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}Module $MODULE_NUMBER is properly structured!${NC}"
else
    echo -e "${YELLOW}Found $ISSUES structural issues. Please review above.${NC}"
fi
