#!/bin/bash

# ========================================================================
# Add Content to Modules Script
# This script adds content from the content/ directory to the correct module files
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

# Function to add content to a specific module
add_content_to_module() {
    local module_num=$1
    local content_dir="content"
    local module_dir="modules/module-${module_num}"
    local files_added=0
    
    print_info "Processing Module ${module_num}..."
    
    # Process each type of file
    # Main README
    if [ -f "$content_dir/module-${module_num}-README.md" ] || [ -f "$content_dir/module-${module_num}.md" ]; then
        local source_file=""
        if [ -f "$content_dir/module-${module_num}-README.md" ]; then
            source_file="$content_dir/module-${module_num}-README.md"
        else
            source_file="$content_dir/module-${module_num}.md"
        fi
        
        cp "$source_file" "$module_dir/README.md"
        print_success "Added README.md"
        ((files_added++))
    fi
    
    # Prerequisites
    if [ -f "$content_dir/module-${module_num}-prerequisites.md" ]; then
        cp "$content_dir/module-${module_num}-prerequisites.md" "$module_dir/prerequisites.md"
        print_success "Added prerequisites.md"
        ((files_added++))
    fi
    
    # Best Practices
    if [ -f "$content_dir/module-${module_num}-best-practices.md" ]; then
        cp "$content_dir/module-${module_num}-best-practices.md" "$module_dir/best-practices.md"
        print_success "Added best-practices.md"
        ((files_added++))
    fi
    
    # Troubleshooting
    if [ -f "$content_dir/module-${module_num}-troubleshooting.md" ]; then
        cp "$content_dir/module-${module_num}-troubleshooting.md" "$module_dir/troubleshooting.md"
        print_success "Added troubleshooting.md"
        ((files_added++))
    fi
    
    # Exercise 1 (Easy) - Instructions
    for part in 1 2 3; do
        if [ -f "$content_dir/module-${module_num}-exercise1-part${part}.md" ]; then
            mkdir -p "$module_dir/exercises/exercise1-easy/instructions"
            cp "$content_dir/module-${module_num}-exercise1-part${part}.md" \
               "$module_dir/exercises/exercise1-easy/instructions/part${part}.md"
            print_success "Added exercise1/part${part}.md"
            ((files_added++))
        fi
    done
    
    # Exercise 2 (Medium) - Instructions
    for part in 1 2 3; do
        if [ -f "$content_dir/module-${module_num}-exercise2-part${part}.md" ]; then
            mkdir -p "$module_dir/exercises/exercise2-medium/instructions"
            cp "$content_dir/module-${module_num}-exercise2-part${part}.md" \
               "$module_dir/exercises/exercise2-medium/instructions/part${part}.md"
            print_success "Added exercise2/part${part}.md"
            ((files_added++))
        fi
    done
    
    # Exercise 3 (Hard) - Instructions
    for part in 1 2 3; do
        if [ -f "$content_dir/module-${module_num}-exercise3-part${part}.md" ]; then
            mkdir -p "$module_dir/exercises/exercise3-hard/instructions"
            cp "$content_dir/module-${module_num}-exercise3-part${part}.md" \
               "$module_dir/exercises/exercise3-hard/instructions/part${part}.md"
            print_success "Added exercise3/part${part}.md"
            ((files_added++))
        fi
    done
    
    # Python files - Exercise 1
    if [ -f "$content_dir/module-${module_num}-exercise1-solution.py" ]; then
        mkdir -p "$module_dir/exercises/exercise1-easy/solution"
        cp "$content_dir/module-${module_num}-exercise1-solution.py" \
           "$module_dir/exercises/exercise1-easy/solution/solution.py"
        print_success "Added exercise1 solution"
        ((files_added++))
    fi
    
    if [ -f "$content_dir/module-${module_num}-exercise1-starter.py" ]; then
        mkdir -p "$module_dir/exercises/exercise1-easy/starter"
        cp "$content_dir/module-${module_num}-exercise1-starter.py" \
           "$module_dir/exercises/exercise1-easy/starter/starter.py"
        print_success "Added exercise1 starter"
        ((files_added++))
    fi
    
    # Python files - Exercise 2
    for file in "$content_dir"/module-${module_num}-exercise2-solution*.py; do
        if [ -f "$file" ]; then
            mkdir -p "$module_dir/exercises/exercise2-medium/solution"
            cp "$file" "$module_dir/exercises/exercise2-medium/solution/"
            print_success "Added exercise2 solution: $(basename "$file")"
            ((files_added++))
        fi
    done
    
    for file in "$content_dir"/module-${module_num}-exercise2-starter*.py; do
        if [ -f "$file" ]; then
            mkdir -p "$module_dir/exercises/exercise2-medium/starter"
            cp "$file" "$module_dir/exercises/exercise2-medium/starter/"
            print_success "Added exercise2 starter: $(basename "$file")"
            ((files_added++))
        fi
    done
    
    # Python files - Exercise 3
    for file in "$content_dir"/module-${module_num}-exercise3-solution*.py; do
        if [ -f "$file" ]; then
            mkdir -p "$module_dir/exercises/exercise3-hard/solution"
            cp "$file" "$module_dir/exercises/exercise3-hard/solution/"
            print_success "Added exercise3 solution: $(basename "$file")"
            ((files_added++))
        fi
    done
    
    for file in "$content_dir"/module-${module_num}-exercise3-starter*.py; do
        if [ -f "$file" ]; then
            mkdir -p "$module_dir/exercises/exercise3-hard/starter"
            cp "$file" "$module_dir/exercises/exercise3-hard/starter/"
            print_success "Added exercise3 starter: $(basename "$file")"
            ((files_added++))
        fi
    done
    
    # Test files
    for file in "$content_dir"/module-${module_num}-*test*.py; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            if [[ "$filename" == *"exercise1"* ]]; then
                mkdir -p "$module_dir/exercises/exercise1-easy/tests"
                cp "$file" "$module_dir/exercises/exercise1-easy/tests/"
            elif [[ "$filename" == *"exercise2"* ]]; then
                mkdir -p "$module_dir/exercises/exercise2-medium/tests"
                cp "$file" "$module_dir/exercises/exercise2-medium/tests/"
            elif [[ "$filename" == *"exercise3"* ]]; then
                mkdir -p "$module_dir/exercises/exercise3-hard/tests"
                cp "$file" "$module_dir/exercises/exercise3-hard/tests/"
            else
                mkdir -p "$module_dir/resources"
                cp "$file" "$module_dir/resources/"
            fi
            print_success "Added test file: $(basename "$file")"
            ((files_added++))
        fi
    done
    
    # Resources
    for pattern in "common-patterns" "prompt-templates" "project-readme" "utils" "setup-script"; do
        for file in "$content_dir"/module-${module_num}-${pattern}*; do
            if [ -f "$file" ]; then
                mkdir -p "$module_dir/resources"
                filename=$(basename "$file")
                # Special case for project-readme
                if [[ "$pattern" == "project-readme" ]]; then
                    cp "$file" "$module_dir/resources/project-template.md"
                else
                    cp "$file" "$module_dir/resources/"
                fi
                # Make shell scripts executable
                if [[ "$file" == *.sh ]]; then
                    chmod +x "$module_dir/resources/$filename"
                fi
                print_success "Added resource: $filename"
                ((files_added++))
            fi
        done
    done
    
    if [ "$files_added" -eq 0 ]; then
        print_warning "No files found for Module ${module_num}"
    else
        print_success "Added $files_added files to Module ${module_num}"
    fi
    
    return 0
}

# Main execution
main() {
    print_header "Adding Content to All Modules"
    
    # Check if content directory exists
    if [ ! -d "content" ]; then
        print_error "Content directory not found!"
        print_info "Please create a 'content' directory with your module files"
        exit 1
    fi
    
    # Count files in content directory
    file_count=$(find content -type f \( -name "*.md" -o -name "*.py" -o -name "*.sh" \) | wc -l)
    
    if [ "$file_count" -eq 1 ]; then
        print_warning "Only README.md found in content directory!"
        print_info "Please add your module content files to the 'content' directory"
        print_info "Expected format: module-XX-filename.ext"
        exit 1
    fi
    
    print_info "Found $file_count files in content directory"
    
    # Process all modules
    total_files_added=0
    for i in $(seq -f "%02g" 1 30); do
        add_content_to_module "$i"
    done
    
    # Generate summary report
    print_header "Generating Content Addition Report"
    
    cat > "CONTENT_ADDITION_REPORT.md" << EOF
# 📝 Content Addition Report

**Date**: $(date)

## Summary

Content has been added from the 'content' directory to all modules.

## Module Status

| Module | Files Count | Status |
|--------|-------------|--------|
EOF

    # Check each module
    for i in $(seq -f "%02g" 1 30); do
        module_dir="modules/module-$i"
        if [ -d "$module_dir" ]; then
            # Count actual content files (excluding empty placeholders)
            content_files=$(find "$module_dir" -type f \( -name "*.md" -o -name "*.py" -o -name "*.sh" \) -size +100c | wc -l)
            if [ "$content_files" -gt 5 ]; then
                echo "| Module $i | $content_files | ✅ Complete |" >> "CONTENT_ADDITION_REPORT.md"
            elif [ "$content_files" -gt 0 ]; then
                echo "| Module $i | $content_files | ⚠️  Partial |" >> "CONTENT_ADDITION_REPORT.md"
            else
                echo "| Module $i | $content_files | ❌ Empty |" >> "CONTENT_ADDITION_REPORT.md"
            fi
        fi
    done
    
    cat >> "CONTENT_ADDITION_REPORT.md" << EOF

## Next Steps

1. Review the module content
2. Test navigation between modules
3. Verify exercise solutions work
4. Commit and push changes:
   \`\`\`bash
   git add .
   git commit -m "Add content to all modules"
   git push origin main
   \`\`\`

## Verification

To verify content was added correctly:
1. Open any module README: \`modules/module-01/README.md\`
2. Check exercise instructions: \`modules/module-01/exercises/exercise1-easy/instructions/part1.md\`
3. Verify solutions exist: \`modules/module-01/exercises/exercise1-easy/solution/\`
EOF

    print_success "Report generated: CONTENT_ADDITION_REPORT.md"
    
    print_header "✅ Content Addition Complete!"
    print_info "All available content has been added to the modules"
    print_info "Check CONTENT_ADDITION_REPORT.md for details"
}

# Check if we're in the right directory
if [[ ! -f "README.md" ]] || [[ ! -d "modules" ]]; then
    print_error "Please run this script from the workshop root directory"
    exit 1
fi

# Run main function
main
