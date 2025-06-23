#!/bin/bash

# Module 07 Validation Script
# This script validates all prerequisites and setup for Module 07

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "🔍 Validating Module 07: Building Web Applications with AI"
echo "======================================================"

# Check prerequisites from previous modules
echo -e "\n📋 Checking prerequisites from previous modules..."

if [ -f "../module-06/completed.flag" ]; then
    print_status "Module 6 completed"
else
    print_warning "Module 6 completion flag not found. Ensure you've completed Module 6."
fi

# Check required tools
echo -e "\n🔧 Checking required tools..."

# Python
if command -v python3 &> /dev/null; then
    py_version=$(python3 --version 2>&1 | grep -oE '[0-9]+\.[0-9]+')
    if [ "$(echo "$py_version >= 3.11" | bc)" -eq 1 ]; then
        print_status "Python $py_version found"
    else
        print_error "Python 3.11+ required, found $py_version"
        exit 1
    fi
else
    print_error "Python 3 not found"
    exit 1
fi

# Node.js
if command -v node &> /dev/null; then
    node_version=$(node --version | grep -oE '[0-9]+' | head -1)
    if [ "$node_version" -ge 18 ]; then
        print_status "Node.js $(node --version) found"
    else
        print_error "Node.js 18+ required"
        exit 1
    fi
else
    print_error "Node.js not found"
    exit 1
fi

# npm
if command -v npm &> /dev/null; then
    print_status "npm $(npm --version) found"
else
    print_error "npm not found"
    exit 1
fi

# Docker
if command -v docker &> /dev/null; then
    print_status "Docker $(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') found"
else
    print_error "Docker not found (required for deployment exercise)"
    exit 1
fi

# Git
if command -v git &> /dev/null; then
    print_status "Git $(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') found"
else
    print_error "Git not found"
    exit 1
fi

# Check VS Code extensions
echo -e "\n📦 Checking VS Code extensions..."

if command -v code &> /dev/null; then
    extensions=$(code --list-extensions 2>/dev/null || echo "")
    
    if echo "$extensions" | grep -q "GitHub.copilot"; then
        print_status "GitHub Copilot extension installed"
    else
        print_warning "GitHub Copilot extension not found. Please install it."
    fi
    
    if echo "$extensions" | grep -q "ms-python.python"; then
        print_status "Python extension installed"
    else
        print_warning "Python extension not found. Please install it."
    fi
else
    print_warning "VS Code CLI not found. Please ensure VS Code is installed with CLI support."
fi

# Check Python packages
echo -e "\n🐍 Checking Python environment..."

if python3 -c "import fastapi" 2>/dev/null; then
    print_status "FastAPI available globally"
else
    print_warning "FastAPI not installed globally (will be installed per exercise)"
fi

# Check Node.js global packages
echo -e "\n📦 Checking Node.js environment..."

if npm list -g @types/node &>/dev/null; then
    print_status "TypeScript types for Node.js installed"
else
    print_warning "@types/node not installed globally (OK - will be installed per project)"
fi

# Check GitHub authentication
echo -e "\n🔐 Checking GitHub authentication..."

if git config --get user.email &>/dev/null; then
    print_status "Git user email configured: $(git config --get user.email)"
else
    print_error "Git user email not configured"
    echo "    Run: git config --global user.email 'your.email@example.com'"
    exit 1
fi

# Check GitHub Copilot status
echo -e "\n🤖 Checking GitHub Copilot status..."

if command -v gh &> /dev/null; then
    if gh copilot status &>/dev/null; then
        print_status "GitHub Copilot authenticated"
    else
        print_warning "GitHub Copilot not authenticated. Run: gh auth login"
    fi
else
    print_warning "GitHub CLI not found. Install it for better Copilot integration."
fi

# Validate exercise structure
echo -e "\n📁 Validating module structure..."

required_dirs=("exercises/exercise1-todo-app" "exercises/exercise2-blog-platform" "exercises/exercise3-ai-dashboard")
for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        print_status "$dir exists"
    else
        print_error "$dir not found"
        exit 1
    fi
done

# Check disk space
echo -e "\n💾 Checking disk space..."

available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$available_space" -ge 5 ]; then
    print_status "Sufficient disk space available: ${available_space}GB"
else
    print_warning "Low disk space: ${available_space}GB (recommend 5GB+)"
fi

# Network connectivity
echo -e "\n🌐 Checking network connectivity..."

if curl -s --head https://api.github.com > /dev/null; then
    print_status "GitHub API accessible"
else
    print_error "Cannot reach GitHub API"
    exit 1
fi

if curl -s --head https://pypi.org > /dev/null; then
    print_status "PyPI accessible"
else
    print_error "Cannot reach PyPI"
    exit 1
fi

if curl -s --head https://registry.npmjs.org > /dev/null; then
    print_status "npm registry accessible"
else
    print_error "Cannot reach npm registry"
    exit 1
fi

# Summary
echo -e "\n🏁 Validation Summary"
echo "=================="

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! You're ready to start Module 07.${NC}"
    echo -e "\nNext steps:"
    echo "1. Navigate to an exercise: cd exercises/exercise1-todo-app"
    echo "2. Run the setup script: ./setup.sh"
    echo "3. Start coding with GitHub Copilot!"
else
    echo -e "${RED}❌ Some checks failed. Please fix the issues above.${NC}"
    exit 1
fi