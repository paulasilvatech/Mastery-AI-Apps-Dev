#!/bin/bash

# ========================================================================
# Restore Module Content Script
# ========================================================================
# This script restores module content from the content directory
# ========================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${PURPLE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to restore content for a specific module
restore_module_content() {
    local module_num=$1
    local module_dir="modules/module-${module_num}"
    local content_dir="content"
    
    print_info "Restoring content for Module ${module_num}..."
    
    # Check if content directory exists
    if [ ! -d "$content_dir" ]; then
        print_error "Content directory not found! Please ensure 'content' directory exists in the repository root."
        return 1
    fi
    
    # Look for content files for this module
    # Pattern 1: module-XX-*.md files
    for content_file in "$content_dir"/module-${module_num}-*.md; do
        if [ -f "$content_file" ]; then
            filename=$(basename "$content_file")
            
            # Determine destination based on filename
            case "$filename" in
                *"exercise1-part1"*)
                    dest_dir="${module_dir}/exercises/exercise1-easy/instructions"
                    dest_file="part1.md"
                    ;;
                *"exercise1-part2"*)
                    dest_dir="${module_dir}/exercises/exercise1-easy/instructions"
                    dest_file="part2.md"
                    ;;
                *"exercise1-part3"*)
                    dest_dir="${module_dir}/exercises/exercise1-easy/instructions"
                    dest_file="part3.md"
                    ;;
                *"exercise2-part1"*)
                    dest_dir="${module_dir}/exercises/exercise2-medium/instructions"
                    dest_file="part1.md"
                    ;;
                *"exercise2-part2"*)
                    dest_dir="${module_dir}/exercises/exercise2-medium/instructions"
                    dest_file="part2.md"
                    ;;
                *"exercise2-part3"*)
                    dest_dir="${module_dir}/exercises/exercise2-medium/instructions"
                    dest_file="part3.md"
                    ;;
                *"exercise3-part1"*)
                    dest_dir="${module_dir}/exercises/exercise3-hard/instructions"
                    dest_file="part1.md"
                    ;;
                *"exercise3-part2"*)
                    dest_dir="${module_dir}/exercises/exercise3-hard/instructions"
                    dest_file="part2.md"
                    ;;
                *"exercise3-part3"*)
                    dest_dir="${module_dir}/exercises/exercise3-hard/instructions"
                    dest_file="part3.md"
                    ;;
                *"prerequisites"*)
                    dest_dir="${module_dir}"
                    dest_file="prerequisites.md"
                    ;;
                *"best-practices"*)
                    dest_dir="${module_dir}"
                    dest_file="best-practices.md"
                    ;;
                *"troubleshooting"*)
                    dest_dir="${module_dir}"
                    dest_file="troubleshooting.md"
                    ;;
                *"common-patterns"*)
                    dest_dir="${module_dir}/resources"
                    dest_file="common-patterns.md"
                    ;;
                *"prompt-templates"*)
                    dest_dir="${module_dir}/resources"
                    dest_file="prompt-templates.md"
                    ;;
                *"project-readme"*)
                    dest_dir="${module_dir}/resources"
                    dest_file="project-template.md"
                    ;;
                module-${module_num}.md | *"README"*)
                    dest_dir="${module_dir}"
                    dest_file="README.md"
                    ;;
                *)
                    # For other files, put in resources
                    dest_dir="${module_dir}/resources"
                    dest_file="$filename"
                    ;;
            esac
            
            # Create destination directory if needed
            mkdir -p "$dest_dir"
            
            # Copy the file
            cp "$content_file" "$dest_dir/$dest_file"
            print_success "Restored: $filename → $dest_dir/$dest_file"
        fi
    done
    
    # Look for Python files
    for content_file in "$content_dir"/module-${module_num}-*.py; do
        if [ -f "$content_file" ]; then
            filename=$(basename "$content_file")
            
            # Determine destination based on filename
            case "$filename" in
                *"exercise1"*"solution"*)
                    dest_dir="${module_dir}/exercises/exercise1-easy/solution"
                    ;;
                *"exercise2"*"solution"*)
                    dest_dir="${module_dir}/exercises/exercise2-medium/solution"
                    ;;
                *"exercise3"*"solution"*)
                    dest_dir="${module_dir}/exercises/exercise3-hard/solution"
                    ;;
                *"exercise1"*"starter"*)
                    dest_dir="${module_dir}/exercises/exercise1-easy/starter"
                    ;;
                *"exercise2"*"starter"*)
                    dest_dir="${module_dir}/exercises/exercise2-medium/starter"
                    ;;
                *"exercise3"*"starter"*)
                    dest_dir="${module_dir}/exercises/exercise3-hard/starter"
                    ;;
                *"test"*)
                    if [[ "$filename" == *"exercise1"* ]]; then
                        dest_dir="${module_dir}/exercises/exercise1-easy/tests"
                    elif [[ "$filename" == *"exercise2"* ]]; then
                        dest_dir="${module_dir}/exercises/exercise2-medium/tests"
                    elif [[ "$filename" == *"exercise3"* ]]; then
                        dest_dir="${module_dir}/exercises/exercise3-hard/tests"
                    else
                        dest_dir="${module_dir}/resources"
                    fi
                    ;;
                *"utils"* | *"setup"*)
                    dest_dir="${module_dir}/resources"
                    ;;
                *)
                    dest_dir="${module_dir}/resources"
                    ;;
            esac
            
            # Create destination directory if needed
            mkdir -p "$dest_dir"
            
            # Copy the file
            cp "$content_file" "$dest_dir/"
            print_success "Restored: $filename → $dest_dir/"
        fi
    done
    
    # Look for shell scripts
    for content_file in "$content_dir"/module-${module_num}-*.sh; do
        if [ -f "$content_file" ]; then
            filename=$(basename "$content_file")
            dest_dir="${module_dir}/resources"
            mkdir -p "$dest_dir"
            cp "$content_file" "$dest_dir/"
            chmod +x "$dest_dir/$filename"
            print_success "Restored: $filename → $dest_dir/ (executable)"
        fi
    done
}

# Function to check if content directory has files
check_content_directory() {
    if [ ! -d "content" ]; then
        print_error "Content directory not found!"
        print_info "Please create a 'content' directory with your original module files."
        print_info "Expected structure:"
        echo "  content/"
        echo "    ├── module-01-README.md"
        echo "    ├── module-01-exercise1-part1.md"
        echo "    ├── module-01-exercise1-part2.md"
        echo "    ├── module-01-best-practices.md"
        echo "    └── ... (other module files)"
        return 1
    fi
    
    # Count files in content directory
    file_count=$(find content -type f -name "*.md" -o -name "*.py" -o -name "*.sh" | wc -l)
    
    if [ "$file_count" -eq 0 ]; then
        print_warning "No content files found in 'content' directory!"
        return 1
    fi
    
    print_success "Found $file_count files in content directory"
    return 0
}

# Main execution
main() {
    print_header "Module Content Restoration"
    
    # Check if content directory exists and has files
    if ! check_content_directory; then
        exit 1
    fi
    
    # Restore content for all modules
    for i in $(seq -f "%02g" 1 30); do
        restore_module_content "$i"
    done
    
    # Create a restoration report
    print_header "Creating Restoration Report"
    
    cat > "RESTORATION_REPORT.md" << EOF
# Content Restoration Report

Generated on: $(date)

## Summary

This report documents the content restoration process for all workshop modules.

## Restoration Status

| Module | Files Restored | Status |
|--------|---------------|---------|
EOF

    # Add status for each module
    for i in $(seq -f "%02g" 1 30); do
        file_count=$(find "modules/module-$i" -type f -name "*.md" -o -name "*.py" -o -name "*.sh" | wc -l)
        if [ "$file_count" -gt 5 ]; then
            echo "| Module $i | $file_count | ✅ Complete |" >> "RESTORATION_REPORT.md"
        else
            echo "| Module $i | $file_count | ⚠️  Partial |" >> "RESTORATION_REPORT.md"
        fi
    done
    
    cat >> "RESTORATION_REPORT.md" << EOF

## Next Steps

1. Review each module to ensure content is properly restored
2. Update any broken internal links
3. Verify exercise solutions work correctly
4. Test navigation between modules

## Notes

- Original content was restored from the 'content' directory
- File organization follows the new standardized structure
- Some manual adjustments may be needed for complex modules
EOF

    print_success "Created restoration report: RESTORATION_REPORT.md"
    
    print_header "Restoration Complete!"
    print_success "All module content has been restored"
    print_info "Next steps:"
    echo "  1. Review RESTORATION_REPORT.md"
    echo "  2. Check each module for completeness"
    echo "  3. Commit the restored content"
    echo "  4. Test navigation and links"
}

# Check if we're in the right directory
if [[ ! -f "README.md" ]] || [[ ! -d "modules" ]]; then
    print_error "Please run this script from the workshop root directory"
    exit 1
fi

# Run main function
main
