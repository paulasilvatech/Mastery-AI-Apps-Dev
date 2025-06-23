#!/bin/bash

# Setup all exercises for Module 07
# This script prepares all three exercises

set -e

echo "🚀 Setting up all Module 07 exercises"
echo "==================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to setup exercise
setup_exercise() {
    local exercise_dir=$1
    local exercise_name=$2
    
    echo -e "\n📦 Setting up $exercise_name..."
    
    if [ -d "exercises/$exercise_dir" ]; then
        cd "exercises/$exercise_dir"
        
        if [ -f "setup.sh" ]; then
            chmod +x setup.sh
            ./setup.sh
            echo -e "${GREEN}✓${NC} $exercise_name setup complete"
        else
            echo -e "${YELLOW}⚠${NC} No setup script found for $exercise_name"
        fi
        
        cd ../..
    else
        echo -e "${YELLOW}⚠${NC} $exercise_dir not found"
    fi
}

# Setup each exercise
setup_exercise "exercise1-todo-app" "Exercise 1: Todo Application"
setup_exercise "exercise2-blog-platform" "Exercise 2: Blog Platform"
setup_exercise "exercise3-ai-dashboard" "Exercise 3: AI Dashboard"

echo -e "\n${GREEN}✅ All exercises setup complete!${NC}"
echo -e "\nYou can now start any exercise:"
echo "- Exercise 1: cd exercises/exercise1-todo-app"
echo "- Exercise 2: cd exercises/exercise2-blog-platform"
echo "- Exercise 3: cd exercises/exercise3-ai-dashboard"