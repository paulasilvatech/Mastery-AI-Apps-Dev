#!/bin/bash

# ========================================================================
# Mastery AI Apps and Development Workshop - Fix Naming and Links Script
# ========================================================================
# This script ensures all files follow the correct naming pattern and
# fixes all broken links in the repository
# ========================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Counters
TOTAL_FILES_RENAMED=0
TOTAL_LINKS_FIXED=0
TOTAL_ERRORS=0

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
    ((TOTAL_ERRORS++))
}

# Function to fix file naming patterns
fix_file_naming() {
    print_header "Fixing File Naming Patterns"
    
    # Process each module
    for module_dir in modules/module-*/; do
        if [[ ! -d "$module_dir" ]]; then
            continue
        fi
        
        module_num=$(basename "$module_dir" | sed 's/module-//')
        print_info "Checking Module $module_num..."
        
        # Check and rename files in module root
        # Prerequisites
        for old_file in "$module_dir"module-*-prerequisites.md; do
            if [[ -f "$old_file" ]]; then
                new_file="$module_dir/prerequisites.md"
                mv "$old_file" "$new_file"
                print_success "Renamed: $(basename "$old_file") → prerequisites.md"
                ((TOTAL_FILES_RENAMED++))
            fi
        done
        
        # Best practices
        for old_file in "$module_dir"module-*-best-practices.md; do
            if [[ -f "$old_file" ]]; then
                new_file="$module_dir/best-practices.md"
                mv "$old_file" "$new_file"
                print_success "Renamed: $(basename "$old_file") → best-practices.md"
                ((TOTAL_FILES_RENAMED++))
            fi
        done
        
        # Troubleshooting
        for old_file in "$module_dir"module-*-troubleshooting.md; do
            if [[ -f "$old_file" ]]; then
                new_file="$module_dir/troubleshooting.md"
                mv "$old_file" "$new_file"
                print_success "Renamed: $(basename "$old_file") → troubleshooting.md"
                ((TOTAL_FILES_RENAMED++))
            fi
        done
        
        # Common patterns
        for old_file in "$module_dir"module-*-common-patterns.md; do
            if [[ -f "$old_file" ]]; then
                new_file="$module_dir/common-patterns.md"
                mv "$old_file" "$new_file"
                print_success "Renamed: $(basename "$old_file") → common-patterns.md"
                ((TOTAL_FILES_RENAMED++))
            fi
        done
        
        # Prompt templates
        for old_file in "$module_dir"module-*-prompt-templates.md; do
            if [[ -f "$old_file" ]]; then
                new_file="$module_dir/prompt-templates.md"
                mv "$old_file" "$new_file"
                print_success "Renamed: $(basename "$old_file") → prompt-templates.md"
                ((TOTAL_FILES_RENAMED++))
            fi
        done
        
        # Setup
        for old_file in "$module_dir"module-*-setup.md; do
            if [[ -f "$old_file" ]]; then
                new_file="$module_dir/setup.md"
                mv "$old_file" "$new_file"
                print_success "Renamed: $(basename "$old_file") → setup.md"
                ((TOTAL_FILES_RENAMED++))
            fi
        done
        
        # Check docs directory
        if [[ -d "$module_dir/docs" ]]; then
            for file in "$module_dir/docs/"*.md; do
                if [[ -f "$file" ]]; then
                    basename=$(basename "$file")
                    # Remove module prefix from docs files
                    new_name=$(echo "$basename" | sed "s/module-${module_num}-//")
                    if [[ "$basename" != "$new_name" ]]; then
                        mv "$file" "$module_dir/docs/$new_name"
                        print_success "Renamed: docs/$basename → docs/$new_name"
                        ((TOTAL_FILES_RENAMED++))
                    fi
                fi
            done
        fi
        
        # Check resources directory
        if [[ -d "$module_dir/resources" ]]; then
            for file in "$module_dir/resources/"*; do
                if [[ -f "$file" ]]; then
                    basename=$(basename "$file")
                    # Remove module prefix from resource files
                    new_name=$(echo "$basename" | sed "s/module-${module_num}-//")
                    if [[ "$basename" != "$new_name" ]]; then
                        mv "$file" "$module_dir/resources/$new_name"
                        print_success "Renamed: resources/$basename → resources/$new_name"
                        ((TOTAL_FILES_RENAMED++))
                    fi
                fi
            done
        fi
        
        # Check scripts directory
        if [[ -d "$module_dir/scripts" ]]; then
            for file in "$module_dir/scripts/"*; do
                if [[ -f "$file" ]]; then
                    basename=$(basename "$file")
                    # Remove module prefix from script files
                    new_name=$(echo "$basename" | sed "s/module-${module_num}-//")
                    if [[ "$basename" != "$new_name" ]]; then
                        mv "$file" "$module_dir/scripts/$new_name"
                        print_success "Renamed: scripts/$basename → scripts/$new_name"
                        ((TOTAL_FILES_RENAMED++))
                    fi
                fi
            done
        fi
        
        # Check exercises directory
        for exercise_num in 1 2 3; do
            exercise_dir="$module_dir/exercises/exercise$exercise_num"
            if [[ -d "$exercise_dir" ]]; then
                for file in "$exercise_dir"/*; do
                    if [[ -f "$file" ]]; then
                        basename=$(basename "$file")
                        # Remove module and exercise prefixes
                        new_name=$(echo "$basename" | sed "s/module-${module_num}-//")
                        new_name=$(echo "$new_name" | sed "s/exercise${exercise_num}-//")
                        if [[ "$basename" != "$new_name" ]]; then
                            mv "$file" "$exercise_dir/$new_name"
                            print_success "Renamed: exercise$exercise_num/$basename → exercise$exercise_num/$new_name"
                            ((TOTAL_FILES_RENAMED++))
                        fi
                    fi
                done
            fi
        done
    done
}

# Function to update links in markdown files
update_links_in_file() {
    local file=$1
    local temp_file="${file}.tmp"
    local links_fixed=0
    
    # Create a copy for processing
    cp "$file" "$temp_file"
    
    # Fix links to renamed files
    # Prerequisites links
    sed -i '' 's/module-[0-9][0-9]-prerequisites\.md/prerequisites.md/g' "$temp_file"
    
    # Best practices links
    sed -i '' 's/module-[0-9][0-9]-best-practices\.md/best-practices.md/g' "$temp_file"
    
    # Troubleshooting links
    sed -i '' 's/module-[0-9][0-9]-troubleshooting\.md/troubleshooting.md/g' "$temp_file"
    
    # Common patterns links
    sed -i '' 's/module-[0-9][0-9]-common-patterns\.md/common-patterns.md/g' "$temp_file"
    
    # Prompt templates links
    sed -i '' 's/module-[0-9][0-9]-prompt-templates\.md/prompt-templates.md/g' "$temp_file"
    
    # Setup links
    sed -i '' 's/module-[0-9][0-9]-setup\.md/setup.md/g' "$temp_file"
    
    # Fix docs directory links
    sed -i '' 's/\(docs\/\)module-[0-9][0-9]-/\1/g' "$temp_file"
    
    # Fix resources directory links
    sed -i '' 's/\(resources\/\)module-[0-9][0-9]-/\1/g' "$temp_file"
    
    # Fix scripts directory links
    sed -i '' 's/\(scripts\/\)module-[0-9][0-9]-/\1/g' "$temp_file"
    
    # Fix exercise links
    sed -i '' 's/\(exercise[0-9]\/\)module-[0-9][0-9]-exercise[0-9]-/\1/g' "$temp_file"
    
    # Count changes
    if ! diff -q "$file" "$temp_file" > /dev/null; then
        mv "$temp_file" "$file"
        links_fixed=1
        ((TOTAL_LINKS_FIXED++))
    else
        rm "$temp_file"
    fi
    
    return $links_fixed
}

# Function to fix all links
fix_all_links() {
    print_header "Fixing Links in All Files"
    
    # Process all markdown files
    find . -name "*.md" -type f ! -path "./.git/*" | while read -r file; do
        if update_links_in_file "$file"; then
            print_success "Updated links in: $file"
        fi
    done
}

# Function to verify link integrity
verify_links() {
    print_header "Verifying Link Integrity"
    
    local broken_links=0
    
    # Check all markdown files for broken internal links
    find . -name "*.md" -type f ! -path "./.git/*" | while read -r file; do
        # Extract all markdown links
        grep -oE '\[([^]]+)\]\(([^)]+)\)' "$file" | grep -oE '\]\(([^)]+)\)' | sed 's/](\(.*\))/\1/' | while read -r link; do
            # Skip external links
            if [[ "$link" =~ ^https?:// ]] || [[ "$link" =~ ^mailto: ]]; then
                continue
            fi
            
            # Skip anchors
            if [[ "$link" =~ ^# ]]; then
                continue
            fi
            
            # Get the directory of the current file
            file_dir=$(dirname "$file")
            
            # Resolve the link path
            if [[ "$link" =~ ^/ ]]; then
                # Absolute path from repo root
                target_path=".$link"
            else
                # Relative path
                target_path="$file_dir/$link"
            fi
            
            # Remove anchor if present
            target_path=$(echo "$target_path" | sed 's/#.*//')
            
            # Normalize path
            target_path=$(cd "$(dirname "$target_path")" 2>/dev/null && pwd)/$(basename "$target_path") 2>/dev/null || echo "$target_path"
            
            # Check if target exists
            if [[ ! -f "$target_path" ]] && [[ ! -d "$target_path" ]]; then
                print_warning "Broken link in $file: $link"
                ((broken_links++))
            fi
        done
    done
    
    if [[ $broken_links -eq 0 ]]; then
        print_success "All internal links are valid!"
    else
        print_warning "Found $broken_links broken links"
    fi
}

# Function to create missing standard files
create_missing_files() {
    print_header "Creating Missing Standard Files"
    
    for module_dir in modules/module-*/; do
        if [[ ! -d "$module_dir" ]]; then
            continue
        fi
        
        module_num=$(basename "$module_dir" | sed 's/module-//')
        module_title=$(get_module_title $module_num)
        
        # Create missing prerequisites.md
        if [[ ! -f "$module_dir/prerequisites.md" ]]; then
            cat > "$module_dir/prerequisites.md" << EOF
# Prerequisites - Module $module_num: $module_title

## Required Knowledge
- Previous modules completed
- Basic understanding of concepts covered so far

## Required Tools
- GitHub account
- VS Code with GitHub Copilot
- Git installed and configured

## Setup Instructions
1. Ensure all tools are installed
2. Complete previous module exercises
3. Review the module overview

[← Back to Module](README.md)
EOF
            print_success "Created prerequisites.md for Module $module_num"
        fi
        
        # Create missing best-practices.md
        if [[ ! -f "$module_dir/best-practices.md" ]] && [[ ! -f "$module_dir/docs/best-practices.md" ]]; then
            mkdir -p "$module_dir/docs"
            cat > "$module_dir/docs/best-practices.md" << EOF
# Best Practices - Module $module_num: $module_title

## Key Principles
1. Follow established patterns
2. Write clean, maintainable code
3. Use AI assistance effectively

## Common Patterns
- Pattern 1: Description
- Pattern 2: Description
- Pattern 3: Description

## Tips for Success
- Tip 1
- Tip 2
- Tip 3

[← Back to Module](../README.md)
EOF
            print_success "Created docs/best-practices.md for Module $module_num"
        fi
        
        # Create missing troubleshooting.md
        if [[ ! -f "$module_dir/troubleshooting.md" ]] && [[ ! -f "$module_dir/docs/troubleshooting.md" ]]; then
            mkdir -p "$module_dir/docs"
            cat > "$module_dir/docs/troubleshooting.md" << EOF
# Troubleshooting - Module $module_num: $module_title

## Common Issues

### Issue 1: Description
**Solution:** Steps to resolve

### Issue 2: Description
**Solution:** Steps to resolve

### Issue 3: Description
**Solution:** Steps to resolve

## Getting Help
- Check the [FAQ](../../../FAQ.md)
- Review [Prerequisites](../prerequisites.md)
- Ask in discussions

[← Back to Module](../README.md)
EOF
            print_success "Created docs/troubleshooting.md for Module $module_num"
        fi
    done
}

# Function to get module title (same as in enhance-navigation.sh)
get_module_title() {
    local module_num=$1
    case $module_num in
        01) echo "Introduction to AI-Powered Development" ;;
        02) echo "GitHub Copilot Core Features" ;;
        03) echo "Effective Prompting Techniques" ;;
        04) echo "AI-Assisted Debugging and Testing" ;;
        05) echo "Documentation and Code Quality" ;;
        06) echo "Multi-File Projects and Workspaces" ;;
        07) echo "Building Web Applications with AI" ;;
        08) echo "API Development and Integration" ;;
        09) echo "Database Design and Optimization" ;;
        10) echo "Real-time and Event-Driven Systems" ;;
        11) echo "Microservices Architecture" ;;
        12) echo "Cloud-Native Development" ;;
        13) echo "Infrastructure as Code" ;;
        14) echo "CI/CD with GitHub Actions" ;;
        15) echo "Performance and Scalability" ;;
        16) echo "Security Implementation" ;;
        17) echo "GitHub Models and AI Integration" ;;
        18) echo "Enterprise Integration Patterns" ;;
        19) echo "Monitoring and Observability" ;;
        20) echo "Production Deployment Strategies" ;;
        21) echo "Introduction to AI Agents" ;;
        22) echo "Building Custom Agents" ;;
        23) echo "Model Context Protocol (MCP)" ;;
        24) echo "Multi-Agent Orchestration" ;;
        25) echo "Advanced Agent Patterns" ;;
        26) echo "Enterprise .NET Development" ;;
        27) echo "COBOL Modernization" ;;
        28) echo "Shift-Left Security & DevOps" ;;
        29) echo "Complete Enterprise Review" ;;
        30) echo "Ultimate Mastery Challenge" ;;
        *) echo "Unknown Module" ;;
    esac
}

# Main execution
main() {
    print_header "Fixing File Naming and Links"
    
    # Step 1: Fix file naming patterns
    fix_file_naming
    
    # Step 2: Create missing standard files
    create_missing_files
    
    # Step 3: Fix all links
    fix_all_links
    
    # Step 4: Verify link integrity
    verify_links
    
    # Summary
    print_header "Summary"
    print_success "Files renamed: $TOTAL_FILES_RENAMED"
    print_success "Files with updated links: $TOTAL_LINKS_FIXED"
    
    if [[ $TOTAL_ERRORS -gt 0 ]]; then
        print_error "Total errors: $TOTAL_ERRORS"
    else
        print_success "No errors found!"
    fi
}

# Check if we're in the right directory
if [[ ! -f "README.md" ]] || [[ ! -d "modules" ]]; then
    print_error "Please run this script from the workshop root directory"
    exit 1
fi

# Run main function
main 