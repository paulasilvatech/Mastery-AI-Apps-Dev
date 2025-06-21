#!/bin/bash

# Reorganize Module Structure Script
# This script reorganizes all modules to follow the standard structure

set -e

echo "🔄 Starting module reorganization..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to create standard module structure
create_module_structure() {
    local module_num=$1
    local module_dir="modules/module-${module_num}"
    
    echo -e "${BLUE}Processing Module ${module_num}...${NC}"
    
    # Create standard directories
    mkdir -p "${module_dir}/exercises/exercise1-easy/instructions"
    mkdir -p "${module_dir}/exercises/exercise1-easy/starter"
    mkdir -p "${module_dir}/exercises/exercise1-easy/solution"
    mkdir -p "${module_dir}/exercises/exercise1-easy/tests"
    
    mkdir -p "${module_dir}/exercises/exercise2-medium/instructions"
    mkdir -p "${module_dir}/exercises/exercise2-medium/starter"
    mkdir -p "${module_dir}/exercises/exercise2-medium/solution"
    mkdir -p "${module_dir}/exercises/exercise2-medium/tests"
    
    mkdir -p "${module_dir}/exercises/exercise3-hard/instructions"
    mkdir -p "${module_dir}/exercises/exercise3-hard/starter"
    mkdir -p "${module_dir}/exercises/exercise3-hard/solution"
    mkdir -p "${module_dir}/exercises/exercise3-hard/tests"
    
    mkdir -p "${module_dir}/resources"
    
    # Move existing files to new structure if they exist
    if [ -f "${module_dir}/module-${module_num}-exercise1-part1.md" ]; then
        mv "${module_dir}/module-${module_num}-exercise1-part1.md" "${module_dir}/exercises/exercise1-easy/instructions/part1.md" 2>/dev/null || true
    fi
    if [ -f "${module_dir}/module-${module_num}-exercise1-part2.md" ]; then
        mv "${module_dir}/module-${module_num}-exercise1-part2.md" "${module_dir}/exercises/exercise1-easy/instructions/part2.md" 2>/dev/null || true
    fi
    if [ -f "${module_dir}/module-${module_num}-exercise1-part3.md" ]; then
        mv "${module_dir}/module-${module_num}-exercise1-part3.md" "${module_dir}/exercises/exercise1-easy/instructions/part3.md" 2>/dev/null || true
    fi
    
    if [ -f "${module_dir}/module-${module_num}-exercise2-part1.md" ]; then
        mv "${module_dir}/module-${module_num}-exercise2-part1.md" "${module_dir}/exercises/exercise2-medium/instructions/part1.md" 2>/dev/null || true
    fi
    if [ -f "${module_dir}/module-${module_num}-exercise2-part2.md" ]; then
        mv "${module_dir}/module-${module_num}-exercise2-part2.md" "${module_dir}/exercises/exercise2-medium/instructions/part2.md" 2>/dev/null || true
    fi
    if [ -f "${module_dir}/module-${module_num}-exercise2-part3.md" ]; then
        mv "${module_dir}/module-${module_num}-exercise2-part3.md" "${module_dir}/exercises/exercise2-medium/instructions/part3.md" 2>/dev/null || true
    fi
    
    if [ -f "${module_dir}/module-${module_num}-exercise3-part1.md" ]; then
        mv "${module_dir}/module-${module_num}-exercise3-part1.md" "${module_dir}/exercises/exercise3-hard/instructions/part1.md" 2>/dev/null || true
    fi
    if [ -f "${module_dir}/module-${module_num}-exercise3-part2.md" ]; then
        mv "${module_dir}/module-${module_num}-exercise3-part2.md" "${module_dir}/exercises/exercise3-hard/instructions/part2.md" 2>/dev/null || true
    fi
    if [ -f "${module_dir}/module-${module_num}-exercise3-part3.md" ]; then
        mv "${module_dir}/module-${module_num}-exercise3-part3.md" "${module_dir}/exercises/exercise3-hard/instructions/part3.md" 2>/dev/null || true
    fi
    
    # Rename standard files
    if [ -f "${module_dir}/module-${module_num}-prerequisites.md" ]; then
        mv "${module_dir}/module-${module_num}-prerequisites.md" "${module_dir}/prerequisites.md" 2>/dev/null || true
    fi
    if [ -f "${module_dir}/module-${module_num}-best-practices.md" ]; then
        mv "${module_dir}/module-${module_num}-best-practices.md" "${module_dir}/best-practices.md" 2>/dev/null || true
    fi
    if [ -f "${module_dir}/module-${module_num}-troubleshooting.md" ]; then
        mv "${module_dir}/module-${module_num}-troubleshooting.md" "${module_dir}/troubleshooting.md" 2>/dev/null || true
    fi
    
    # Move utility files to resources
    if [ -f "${module_dir}/module-${module_num}-utils-solution.py" ]; then
        mv "${module_dir}/module-${module_num}-utils-solution.py" "${module_dir}/resources/utils.py" 2>/dev/null || true
    fi
    if [ -f "${module_dir}/module-${module_num}-tests-example.py" ]; then
        mv "${module_dir}/module-${module_num}-tests-example.py" "${module_dir}/resources/tests-example.py" 2>/dev/null || true
    fi
    if [ -f "${module_dir}/module-${module_num}-setup-script.sh" ]; then
        mv "${module_dir}/module-${module_num}-setup-script.sh" "${module_dir}/resources/setup.sh" 2>/dev/null || true
    fi
    if [ -f "${module_dir}/module-${module_num}-prompt-templates.md" ]; then
        mv "${module_dir}/module-${module_num}-prompt-templates.md" "${module_dir}/resources/prompt-templates.md" 2>/dev/null || true
    fi
    if [ -f "${module_dir}/module-${module_num}-common-patterns.md" ]; then
        mv "${module_dir}/module-${module_num}-common-patterns.md" "${module_dir}/resources/common-patterns.md" 2>/dev/null || true
    fi
    if [ -f "${module_dir}/module-${module_num}-project-readme.md" ]; then
        mv "${module_dir}/module-${module_num}-project-readme.md" "${module_dir}/resources/project-template.md" 2>/dev/null || true
    fi
    
    # Create placeholder files if they don't exist
    if [ ! -f "${module_dir}/README.md" ]; then
        echo "# Module ${module_num}" > "${module_dir}/README.md"
    fi
    if [ ! -f "${module_dir}/prerequisites.md" ]; then
        echo "# Prerequisites for Module ${module_num}" > "${module_dir}/prerequisites.md"
    fi
    if [ ! -f "${module_dir}/best-practices.md" ]; then
        echo "# Best Practices for Module ${module_num}" > "${module_dir}/best-practices.md"
    fi
    if [ ! -f "${module_dir}/troubleshooting.md" ]; then
        echo "# Troubleshooting Guide for Module ${module_num}" > "${module_dir}/troubleshooting.md"
    fi
    
    echo -e "${GREEN}✓ Module ${module_num} reorganized${NC}"
}

# Process all 30 modules
for i in $(seq -f "%02g" 1 30); do
    create_module_structure "$i"
done

# Create a structure report
echo -e "\n${YELLOW}📋 Creating structure report...${NC}"
cat > modules/STRUCTURE_REPORT.md << 'EOF'
# Module Structure Report

This report shows the standardized structure for all workshop modules.

## Standard Module Structure

```
module-XX/
├── README.md                 # Module overview and objectives
├── prerequisites.md          # Module-specific requirements
├── exercises/               # Three progressive exercises
│   ├── exercise1-easy/      # 30-45 minutes
│   │   ├── instructions/    # Step-by-step guide
│   │   │   ├── part1.md    # Setup and basics
│   │   │   ├── part2.md    # Implementation
│   │   │   └── part3.md    # Testing and validation
│   │   ├── starter/        # Starting code templates
│   │   ├── solution/       # Complete solution
│   │   └── tests/          # Unit tests
│   ├── exercise2-medium/    # 45-60 minutes
│   │   └── (same structure as exercise1)
│   └── exercise3-hard/      # 60-90 minutes
│       └── (same structure as exercise1)
├── best-practices.md        # Production-ready patterns
├── resources/              # Additional resources
│   ├── utils.py           # Utility functions
│   ├── setup.sh           # Setup script
│   ├── prompt-templates.md # AI prompting examples
│   └── common-patterns.md  # Common code patterns
└── troubleshooting.md      # Common issues and solutions
```

## Reorganization Complete

All 30 modules have been reorganized to follow this standard structure.

### Next Steps

1. Review each module's content
2. Ensure all exercises have complete solutions
3. Verify navigation links work correctly
4. Test setup scripts for each module

Generated on: $(date)
EOF

echo -e "${GREEN}✅ Module reorganization complete!${NC}"
echo -e "${BLUE}📄 See modules/STRUCTURE_REPORT.md for details${NC}"

# Make the script executable
chmod +x "$0"
