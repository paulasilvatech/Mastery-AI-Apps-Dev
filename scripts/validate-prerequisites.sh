#!/bin/bash

# Validate Prerequisites Script
set -e

echo "🔍 Validating Workshop Prerequisites..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Counters
passed=0
failed=0

# Function to check requirement
check_requirement() {
    local name=$1
    local check_command=$2
    local min_version=$3
    local install_hint=$4
    
    echo -n "Checking $name... "
    
    if eval $check_command &> /dev/null; then
        if [ -n "$min_version" ]; then
            version=$(eval $check_command 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
            echo -e "${GREEN}✓${NC} (version: $version)"
        else
            echo -e "${GREEN}✓${NC}"
        fi
        ((passed++))
    else
        echo -e "${RED}✗${NC}"
        echo -e "  ${YELLOW}Install hint:${NC} $install_hint"
        ((failed++))
    fi
}

echo -e "\n${YELLOW}=== System Requirements ===${NC}"

# Git
check_requirement "Git" \
    "git --version" \
    "2.34" \
    "Visit https://git-scm.com/downloads"

# Node.js
check_requirement "Node.js" \
    "node --version" \
    "18.0" \
    "Visit https://nodejs.org/ or use nvm"

# npm
check_requirement "npm" \
    "npm --version" \
    "8.0" \
    "Comes with Node.js"

# Python
check_requirement "Python 3" \
    "python3 --version" \
    "3.9" \
    "Visit https://python.org/downloads"

# pip
check_requirement "pip3" \
    "pip3 --version" \
    "" \
    "Usually comes with Python 3"

# Docker
check_requirement "Docker" \
    "docker --version" \
    "20.0" \
    "Visit https://docker.com/get-started"

echo -e "\n${YELLOW}=== IDE/Editor ===${NC}"

# VS Code or Cursor
if command -v code &> /dev/null; then
    check_requirement "VS Code" "code --version" "" ""
elif command -v cursor &> /dev/null; then
    check_requirement "Cursor" "cursor --version" "" ""
else
    echo -e "IDE Check... ${RED}✗${NC}"
    echo -e "  ${YELLOW}Install:${NC} VS Code (https://code.visualstudio.com) or Cursor (https://cursor.sh)"
    ((failed++))
fi

echo -e "\n${YELLOW}=== AI Tool Access ===${NC}"

# Check for environment variables
env_vars=(
    "OPENAI_API_KEY:OpenAI API key for GPT models"
    "ANTHROPIC_API_KEY:Anthropic API key for Claude"
    "GITHUB_TOKEN:GitHub personal access token"
)

for var_desc in "${env_vars[@]}"; do
    IFS=':' read -r var_name var_description <<< "$var_desc"
    echo -n "Checking $var_description... "
    
    if [ -n "${!var_name}" ]; then
        echo -e "${GREEN}✓${NC} (configured)"
        ((passed++))
    else
        echo -e "${YELLOW}⚠${NC} (not set)"
        echo "  Set in .env file or export $var_name"
    fi
done

echo -e "\n${YELLOW}=== Optional Tools ===${NC}"

# Azure CLI
check_requirement "Azure CLI" \
    "az --version" \
    "" \
    "Visit https://docs.microsoft.com/cli/azure/install"

# GitHub CLI
check_requirement "GitHub CLI" \
    "gh --version" \
    "" \
    "Visit https://cli.github.com"

# jq
check_requirement "jq" \
    "jq --version" \
    "" \
    "brew install jq (Mac) or apt install jq (Linux)"

echo -e "\n${YELLOW}=== Project Structure ===${NC}"

# Check required directories
directories=(
    "modules"
    "scripts"
    "infrastructure"
    "docs"
)

for dir in "${directories[@]}"; do
    echo -n "Checking directory $dir... "
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC}"
        ((passed++))
    else
        echo -e "${RED}✗${NC} (run ./scripts/setup-workshop.sh)"
        ((failed++))
    fi
done

echo -e "\n${YELLOW}=== Module Structure ===${NC}"

# Check if all 30 modules exist
module_count=$(ls -d modules/Module-* 2>/dev/null | wc -l)
echo -n "Checking modules (expected 30)... "
if [ $module_count -eq 30 ]; then
    echo -e "${GREEN}✓${NC} ($module_count modules found)"
    ((passed++))
else
    echo -e "${RED}✗${NC} (only $module_count modules found)"
    ((failed++))
fi

echo -e "\n${YELLOW}=== Summary ===${NC}"
echo -e "Passed: ${GREEN}$passed${NC}"
echo -e "Failed: ${RED}$failed${NC}"

if [ $failed -eq 0 ]; then
    echo -e "\n${GREEN}✅ All prerequisites satisfied! You're ready to start the workshop.${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some prerequisites are missing. Please install them before continuing.${NC}"
    exit 1
fi 