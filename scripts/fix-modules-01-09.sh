#!/bin/bash

# Script to fix modules 01-09 specifically

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Processing Modules 01-09...${NC}"

# Process modules 01-09
for i in 01 02 03 04 05 06 07 08 09; do
    if [[ -d "modules/module-$i" ]]; then
        echo -e "${YELLOW}Processing Module $i...${NC}"
        
        # Run the standardize script with the correct format
        module_num=$(echo $i | sed 's/^0//')  # Remove leading zero for processing
        
        # Create directories
        mkdir -p "modules/module-$i/docs"
        mkdir -p "modules/module-$i/exercises/exercise1"
        mkdir -p "modules/module-$i/exercises/exercise2"
        mkdir -p "modules/module-$i/exercises/exercise3"
        mkdir -p "modules/module-$i/project"
        mkdir -p "modules/module-$i/resources"
        mkdir -p "modules/module-$i/scripts"
        mkdir -p "modules/module-$i/solutions"
        
        echo -e "${GREEN}✓ Created directory structure for Module $i${NC}"
    fi
done

echo -e "${BLUE}Now running the standardize script...${NC}"

# Temporarily create symlinks for modules 1-9 to work with the script
for i in 1 2 3 4 5 6 7 8 9; do
    if [[ -d "modules/module-0$i" ]] && [[ ! -d "modules/module-$i" ]]; then
        ln -s "module-0$i" "modules/module-$i"
    fi
done

# Run the standardize script
./scripts/standardize-all-modules.sh

# Remove temporary symlinks
for i in 1 2 3 4 5 6 7 8 9; do
    if [[ -L "modules/module-$i" ]]; then
        rm "modules/module-$i"
    fi
done

echo -e "${GREEN}✅ Modules 01-09 processed successfully!${NC}" 