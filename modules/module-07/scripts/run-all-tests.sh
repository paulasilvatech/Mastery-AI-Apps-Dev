#!/bin/bash

# Run tests for all exercises in Module 07

set -e

echo "🧪 Running all Module 07 tests"
echo "=========================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test results
total_tests=0
passed_tests=0
failed_tests=0

# Function to run tests for an exercise
run_exercise_tests() {
    local exercise_dir=$1
    local exercise_name=$2
    
    echo -e "\n📝 Testing $exercise_name..."
    
    if [ -d "exercises/$exercise_dir" ]; then
        cd "exercises/$exercise_dir"
        
        # Backend tests
        if [ -d "backend" ] && [ -d "tests/backend" ]; then
            echo "  Running backend tests..."
            cd backend
            if [ -d "venv" ]; then
                source venv/bin/activate || source venv/Scripts/activate
                if python -m pytest ../tests/backend -v; then
                    ((passed_tests++))
                    echo -e "  ${GREEN}✓${NC} Backend tests passed"
                else
                    ((failed_tests++))
                    echo -e "  ${RED}✗${NC} Backend tests failed"
                fi
                deactivate
            else
                echo -e "  ${YELLOW}⚠${NC} Backend venv not found, skipping tests"
            fi
            cd ..
        fi
        
        # Frontend tests
        if [ -d "frontend" ] && [ -f "frontend/package.json" ]; then
            echo "  Running frontend tests..."
            cd frontend
            if [ -d "node_modules" ]; then
                if npm test -- --run 2>/dev/null; then
                    ((passed_tests++))
                    echo -e "  ${GREEN}✓${NC} Frontend tests passed"
                else
                    echo -e "  ${YELLOW}⚠${NC} No frontend tests found"
                fi
            else
                echo -e "  ${YELLOW}⚠${NC} Frontend node_modules not found, skipping tests"
            fi
            cd ..
        fi
        
        ((total_tests++))
        cd ../..
    else
        echo -e "  ${YELLOW}⚠${NC} $exercise_dir not found"
    fi
}

# Run tests for each exercise
run_exercise_tests "exercise1-todo-app" "Exercise 1: Todo Application"
run_exercise_tests "exercise2-blog-platform" "Exercise 2: Blog Platform"
run_exercise_tests "exercise3-ai-dashboard" "Exercise 3: AI Dashboard"

# Summary
echo -e "\n📊 Test Summary"
echo "============="
echo "Total exercises: $total_tests"
echo -e "Passed: ${GREEN}$passed_tests${NC}"
echo -e "Failed: ${RED}$failed_tests${NC}"

if [ $failed_tests -eq 0 ]; then
    echo -e "\n${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed. Please check the output above.${NC}"
    exit 1
fi