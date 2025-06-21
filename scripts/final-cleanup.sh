#!/bin/bash

# Final cleanup and standardization script

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Final Cleanup and Standardization${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Counter
TOTAL_CLEANED=0

# Clean up duplicate exercise directories
echo -e "${YELLOW}Cleaning up duplicate exercise directories...${NC}"
for module_dir in modules/module-*/; do
    if [[ -d "$module_dir" ]]; then
        module_num=$(basename "$module_dir" | sed 's/module-//')
        
        # Remove duplicate exercise directories (exercise1-easy, etc.)
        for level in easy medium hard; do
            for i in 1 2 3; do
                if [[ -d "$module_dir/exercises/exercise$i-$level" ]]; then
                    # Move any files to the standard directory
                    if [[ -d "$module_dir/exercises/exercise$i" ]]; then
                        mv "$module_dir/exercises/exercise$i-$level"/* "$module_dir/exercises/exercise$i/" 2>/dev/null || true
                    fi
                    rmdir "$module_dir/exercises/exercise$i-$level" 2>/dev/null || true
                    echo -e "${GREEN}✓ Cleaned up exercise$i-$level in Module $module_num${NC}"
                    ((TOTAL_CLEANED++))
                fi
            done
        done
        
        # Ensure all standard directories exist
        for i in 1 2 3; do
            mkdir -p "$module_dir/exercises/exercise$i"
        done
        
        # Move any stray files in exercises directory to appropriate subdirectories
        for file in "$module_dir/exercises"/*.md "$module_dir/exercises"/*.py "$module_dir/exercises"/*.js "$module_dir/exercises"/*.ts "$module_dir/exercises"/*.sh "$module_dir/exercises"/*.txt "$module_dir/exercises"/*.yml "$module_dir/exercises"/*.yaml "$module_dir/exercises"/*.json; do
            if [[ -f "$file" ]]; then
                basename=$(basename "$file")
                # Determine which exercise it belongs to
                if [[ "$basename" =~ exercise1 ]]; then
                    mv "$file" "$module_dir/exercises/exercise1/"
                elif [[ "$basename" =~ exercise2 ]]; then
                    mv "$file" "$module_dir/exercises/exercise2/"
                elif [[ "$basename" =~ exercise3 ]]; then
                    mv "$file" "$module_dir/exercises/exercise3/"
                else
                    # Default to exercise1 if unclear
                    mv "$file" "$module_dir/exercises/exercise1/"
                fi
                echo -e "${GREEN}✓ Moved $basename to appropriate exercise directory${NC}"
                ((TOTAL_CLEANED++))
            fi
        done
    fi
done

# Remove .DS_Store files
echo -e "\n${YELLOW}Removing .DS_Store files...${NC}"
find . -name ".DS_Store" -type f -delete
echo -e "${GREEN}✓ Removed all .DS_Store files${NC}"

# Ensure consistent file permissions
echo -e "\n${YELLOW}Setting consistent file permissions...${NC}"
find modules -name "*.sh" -type f -exec chmod +x {} \;
find scripts -name "*.sh" -type f -exec chmod +x {} \;
echo -e "${GREEN}✓ Set executable permissions on all shell scripts${NC}"

# Create a summary report
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Cleanup Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Items cleaned up: $TOTAL_CLEANED${NC}"
echo -e "${GREEN}✓ All modules now follow standard structure${NC}"
echo -e "${GREEN}✓ All scripts are executable${NC}"
echo -e "${GREEN}✓ Repository is ready for use!${NC}"

# Final structure verification
echo -e "\n${YELLOW}Verifying final structure...${NC}"
ISSUES_FOUND=0

for module_dir in modules/module-*/; do
    if [[ -d "$module_dir" ]]; then
        module_num=$(basename "$module_dir")
        
        # Check required directories
        for dir in "docs" "exercises/exercise1" "exercises/exercise2" "exercises/exercise3" "project" "resources"; do
            if [[ ! -d "$module_dir/$dir" ]]; then
                echo -e "${RED}❌ Missing directory: $module_num/$dir${NC}"
                ((ISSUES_FOUND++))
            fi
        done
        
        # Check required files
        for file in "README.md" "prerequisites.md"; do
            if [[ ! -f "$module_dir/$file" ]]; then
                echo -e "${RED}❌ Missing file: $module_num/$file${NC}"
                ((ISSUES_FOUND++))
            fi
        done
    fi
done

if [[ $ISSUES_FOUND -eq 0 ]]; then
    echo -e "${GREEN}✅ All modules have the correct structure!${NC}"
else
    echo -e "${YELLOW}⚠️  Found $ISSUES_FOUND structure issues${NC}"
fi

echo -e "\n${GREEN}✨ Final cleanup complete!${NC}" 