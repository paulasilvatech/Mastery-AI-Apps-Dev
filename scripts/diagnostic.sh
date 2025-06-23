#!/bin/bash
# ============================================
# diagnostic.sh - System diagnostic script
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🔧 Workshop Diagnostic Report"
echo "============================="
echo ""

# System Information
echo -e "${BLUE}System Information:${NC}"
echo "-------------------"
echo "OS: $(uname -s) $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Hostname: $(hostname)"
echo "User: $(whoami)"
echo ""

# Memory and Disk
echo -e "${BLUE}Resources:${NC}"
echo "----------"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Memory: $(sysctl -n hw.memsize | awk '{print $1/1024/1024/1024 " GB"}')"
    echo "Disk Space:"
    df -h . | tail -1 | awk '{print "  Available: " $4 " / " $2}'
else
    echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
    echo "Disk Space:"
    df -h . | tail -1 | awk '{print "  Available: " $4 " / " $2}'
fi
echo ""

# Tool Versions
echo -e "${BLUE}Development Tools:${NC}"
echo "------------------"

# Git
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    echo -e "Git: ${GREEN}✓${NC} (v$GIT_VERSION)"
else
    echo -e "Git: ${RED}✗${NC}"
fi

# Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    echo -e "Python: ${GREEN}✓${NC} (v$PYTHON_VERSION)"
    
    # Check for pip
    if python3 -m pip --version &> /dev/null; then
        PIP_VERSION=$(python3 -m pip --version | awk '{print $2}')
        echo -e "  pip: ${GREEN}✓${NC} (v$PIP_VERSION)"
    else
        echo -e "  pip: ${RED}✗${NC}"
    fi
else
    echo -e "Python: ${RED}✗${NC}"
fi

# Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "Node.js: ${GREEN}✓${NC} ($NODE_VERSION)"
    
    # Check for npm
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        echo -e "  npm: ${GREEN}✓${NC} (v$NPM_VERSION)"
    else
        echo -e "  npm: ${RED}✗${NC}"
    fi
else
    echo -e "Node.js: ${YELLOW}⚠${NC} (Required for agent modules)"
fi

# .NET
if command -v dotnet &> /dev/null; then
    DOTNET_VERSION=$(dotnet --version)
    echo -e ".NET SDK: ${GREEN}✓${NC} (v$DOTNET_VERSION)"
else
    echo -e ".NET SDK: ${YELLOW}⚠${NC} (Required for modules 26, 29)"
fi

# Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    echo -e "Docker: ${GREEN}✓${NC} (v$DOCKER_VERSION)"
    
    # Check if Docker daemon is running
    if docker info &> /dev/null; then
        echo -e "  Docker daemon: ${GREEN}Running${NC}"
    else
        echo -e "  Docker daemon: ${RED}Not running${NC}"
    fi
else
    echo -e "Docker: ${YELLOW}⚠${NC} (Required for containerized modules)"
fi

# VS Code
if command -v code &> /dev/null; then
    echo -e "VS Code: ${GREEN}✓${NC}"
else
    echo -e "VS Code: ${YELLOW}⚠${NC} (Recommended IDE)"
fi

# Azure CLI
if command -v az &> /dev/null; then
    AZ_VERSION=$(az --version | head -1 | awk '{print $2}')
    echo -e "Azure CLI: ${GREEN}✓${NC} (v$AZ_VERSION)"
    
    # Check if logged in
    if az account show &> /dev/null; then
        SUBSCRIPTION=$(az account show --query name -o tsv)
        echo -e "  Logged in: ${GREEN}✓${NC} ($SUBSCRIPTION)"
    else
        echo -e "  Logged in: ${YELLOW}⚠${NC} (Run 'az login')"
    fi
else
    echo -e "Azure CLI: ${YELLOW}⚠${NC} (Required for cloud modules)"
fi

# GitHub CLI
if command -v gh &> /dev/null; then
    GH_VERSION=$(gh --version | head -1 | awk '{print $3}')
    echo -e "GitHub CLI: ${GREEN}✓${NC} (v$GH_VERSION)"
    
    # Check GitHub auth
    if gh auth status &> /dev/null; then
        echo -e "  Authenticated: ${GREEN}✓${NC}"
        
        # Check Copilot status
        if gh copilot status &> /dev/null; then
            echo -e "  Copilot: ${GREEN}✓${NC}"
        else
            echo -e "  Copilot: ${YELLOW}⚠${NC} (No active subscription)"
        fi
    else
        echo -e "  Authenticated: ${RED}✗${NC} (Run 'gh auth login')"
    fi
else
    echo -e "GitHub CLI: ${RED}✗${NC} (Required for GitHub features)"
fi

echo ""

# Workshop Structure Check
echo -e "${BLUE}Workshop Structure:${NC}"
echo "-------------------"

# Check directories
for dir in modules scripts infrastructure docs; do
    if [[ -d "$dir" ]]; then
        echo -e "$dir/: ${GREEN}✓${NC}"
    else
        echo -e "$dir/: ${RED}✗${NC}"
    fi
done

# Check key files
for file in README.md PREREQUISITES.md QUICKSTART.md; do
    if [[ -f "$file" ]]; then
        echo -e "$file: ${GREEN}✓${NC}"
    else
        echo -e "$file: ${RED}✗${NC}"
    fi
done

# Count modules
if [[ -d "modules" ]]; then
    MODULE_COUNT=$(ls -1 modules/ | grep -c "^module-" || true)
    echo -e "Modules found: ${GREEN}$MODULE_COUNT${NC}"
fi

echo ""

# Network connectivity
echo -e "${BLUE}Network Connectivity:${NC}"
echo "---------------------"

# Check internet connectivity
echo -n "Internet connection: "
if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
fi

# Check GitHub access
echo -n "GitHub.com: "
if curl -s --head --request GET https://github.com | grep "200 OK" > /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
fi

# Check Azure access
echo -n "Azure.com: "
if curl -s --head --request GET https://azure.microsoft.com | grep "200 OK" > /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
fi

echo ""
echo "============================="
echo "Diagnostic report complete!"
echo ""

# Summary
ISSUES=0

# Check critical tools
command -v git &> /dev/null || ((ISSUES++))
command -v python3 &> /dev/null || ((ISSUES++))
command -v gh &> /dev/null || ((ISSUES++))

if [[ $ISSUES -eq 0 ]]; then
    echo -e "${GREEN}✅ System is ready for the workshop!${NC}"
else
    echo -e "${YELLOW}⚠️  Found $ISSUES critical issues. Please review above.${NC}"
    echo "Run './scripts/setup-workshop.sh' to install missing components."
fi
