#!/bin/bash

# Cleanup script for Module 07
# Removes generated files, dependencies, and databases

set -e

echo "🧹 Cleaning up Module 07"
echo "====================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Confirm cleanup
read -p "This will remove all generated files and dependencies. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Clean each exercise
for exercise in exercise1-todo-app exercise2-blog-platform exercise3-ai-dashboard; do
    echo -e "\nCleaning $exercise..."
    
    if [ -d "exercises/$exercise" ]; then
        cd "exercises/$exercise"
        
        # Clean backend
        if [ -d "backend" ]; then
            echo "  Cleaning backend..."
            rm -rf backend/venv
            rm -rf backend/__pycache__
            rm -rf backend/app/__pycache__
            rm -f backend/*.db
            rm -f backend/.env
            print_status "Backend cleaned"
        fi
        
        # Clean frontend
        if [ -d "frontend" ]; then
            echo "  Cleaning frontend..."
            rm -rf frontend/node_modules
            rm -rf frontend/dist
            rm -rf frontend/.vite
            rm -f frontend/package-lock.json
            print_status "Frontend cleaned"
        fi
        
        # Clean test artifacts
        rm -rf .pytest_cache
        rm -rf htmlcov
        rm -rf .coverage
        
        cd ../..
    else
        print_warning "$exercise not found"
    fi
done

# Clean module-level artifacts
echo -e "\nCleaning module-level files..."
rm -rf .pytest_cache
rm -rf __pycache__
rm -f *.pyc
rm -f .DS_Store

echo -e "\n${GREEN}✅ Cleanup complete!${NC}"
echo "The module is now in a clean state."