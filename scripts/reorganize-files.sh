#!/bin/bash

# ========================================================================
# Mastery AI Apps and Development Workshop - Reorganize Module Files
# ========================================================================
# This script moves existing module files to the new organized structure
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
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Create directory structure for a module
create_module_dirs() {
    local module_num=$1
    local module_dir="modules/module-$(printf "%02d" $module_num)"
    
    # Create all necessary directories
    mkdir -p "$module_dir/exercises/exercise1/starter"
    mkdir -p "$module_dir/exercises/exercise1/solution"
    mkdir -p "$module_dir/exercises/exercise1/tests"
    mkdir -p "$module_dir/exercises/exercise1/instructions"
    
    mkdir -p "$module_dir/exercises/exercise2/starter"
    mkdir -p "$module_dir/exercises/exercise2/solution"
    mkdir -p "$module_dir/exercises/exercise2/tests"
    mkdir -p "$module_dir/exercises/exercise2/instructions"
    
    mkdir -p "$module_dir/exercises/exercise3/starter"
    mkdir -p "$module_dir/exercises/exercise3/solution"
    mkdir -p "$module_dir/exercises/exercise3/tests"
    mkdir -p "$module_dir/exercises/exercise3/instructions"
    
    mkdir -p "$module_dir/docs"
    mkdir -p "$module_dir/resources"
    mkdir -p "$module_dir/scripts"
    mkdir -p "$module_dir/project"
}

# Reorganize files for a module
reorganize_module() {
    local module_num=$1
    local module_dir="modules/module-$(printf "%02d" $module_num)"
    
    print_info "Reorganizing Module $module_num..."
    
    # Create directory structure
    create_module_dirs $module_num
    
    # Move exercise files
    for exercise in 1 2 3; do
        # Move exercise instruction parts
        for part in 1 2 3; do
            local file="module-$(printf "%02d" $module_num)-exercise${exercise}-part${part}.md"
            if [[ -f "$module_dir/$file" ]]; then
                mv "$module_dir/$file" "$module_dir/exercises/exercise${exercise}/instructions/part${part}.md" 2>/dev/null || true
                print_success "Moved $file to exercise${exercise}/instructions/"
            fi
        done
        
        # Create exercise README if parts exist
        if ls "$module_dir/exercises/exercise${exercise}/instructions/"*.md 1> /dev/null 2>&1; then
            create_exercise_readme $module_num $exercise
        fi
    done
    
    # Move documentation files
    local docs_files=(
        "best-practices"
        "troubleshooting"
        "common-patterns"
        "prompt-templates"
    )
    
    for doc in "${docs_files[@]}"; do
        local file="module-$(printf "%02d" $module_num)-${doc}.md"
        if [[ -f "$module_dir/$file" ]]; then
            # Remove module prefix when moving
            mv "$module_dir/$file" "$module_dir/docs/${doc}.md" 2>/dev/null || true
            print_success "Moved $file to docs/"
        fi
    done
    
    # Move other files
    if [[ -f "$module_dir/module-$(printf "%02d" $module_num)-prerequisites.md" ]]; then
        mv "$module_dir/module-$(printf "%02d" $module_num)-prerequisites.md" "$module_dir/prerequisites.md" 2>/dev/null || true
        print_success "Moved prerequisites to root"
    fi
    
    if [[ -f "$module_dir/module-$(printf "%02d" $module_num)-project-readme.md" ]]; then
        mv "$module_dir/module-$(printf "%02d" $module_num)-project-readme.md" "$module_dir/project/README.md" 2>/dev/null || true
        print_success "Moved project readme"
    fi
    
    # Move scripts
    for script in "$module_dir"/module-$(printf "%02d" $module_num)-*.sh; do
        if [[ -f "$script" ]]; then
            basename_script=$(basename "$script" | sed "s/module-$(printf "%02d" $module_num)-//")
            mv "$script" "$module_dir/scripts/$basename_script" 2>/dev/null || true
            print_success "Moved script to scripts/"
        fi
    done
    
    # Move Python files
    for pyfile in "$module_dir"/module-$(printf "%02d" $module_num)-*.py; do
        if [[ -f "$pyfile" ]]; then
            basename_py=$(basename "$pyfile" | sed "s/module-$(printf "%02d" $module_num)-//")
            
            # Determine destination based on filename
            if [[ "$basename_py" == *"solution"* ]]; then
                # Try to determine which exercise
                for ex in 1 2 3; do
                    if [[ "$basename_py" == *"exercise${ex}"* ]] || [[ "$basename_py" == *"ex${ex}"* ]]; then
                        mv "$pyfile" "$module_dir/exercises/exercise${ex}/solution/$basename_py" 2>/dev/null || true
                        print_success "Moved $basename_py to exercise${ex}/solution/"
                        break
                    fi
                done
            elif [[ "$basename_py" == *"test"* ]]; then
                # Test files go to tests directory
                for ex in 1 2 3; do
                    if [[ "$basename_py" == *"exercise${ex}"* ]] || [[ "$basename_py" == *"ex${ex}"* ]]; then
                        mv "$pyfile" "$module_dir/exercises/exercise${ex}/tests/$basename_py" 2>/dev/null || true
                        print_success "Moved $basename_py to exercise${ex}/tests/"
                        break
                    fi
                done
                # If not exercise specific, move to resources
                if [[ -f "$pyfile" ]]; then
                    mv "$pyfile" "$module_dir/resources/$basename_py" 2>/dev/null || true
                    print_success "Moved $basename_py to resources/"
                fi
            else
                # Other Python files go to resources
                mv "$pyfile" "$module_dir/resources/$basename_py" 2>/dev/null || true
                print_success "Moved $basename_py to resources/"
            fi
        fi
    done
}

# Create exercise README from parts
create_exercise_readme() {
    local module_num=$1
    local exercise_num=$2
    local module_dir="modules/module-$(printf "%02d" $module_num)"
    local exercise_dir="$module_dir/exercises/exercise${exercise_num}"
    
    cat > "$exercise_dir/README.md" << EOF
# Module $module_num - Exercise $exercise_num

## 📚 Instructions

This exercise is divided into parts for better organization:

EOF
    
    # List all instruction parts
    for part in "$exercise_dir/instructions/"*.md; do
        if [[ -f "$part" ]]; then
            local part_name=$(basename "$part" .md)
            echo "- [${part_name^}]($part)" >> "$exercise_dir/README.md"
        fi
    done
    
    cat >> "$exercise_dir/README.md" << EOF

## 🚀 Getting Started

1. Read through all instruction parts
2. Open the starter code in \`starter/\`
3. Follow the instructions to complete the exercise
4. Run tests in \`tests/\` to validate your solution
5. Compare with the solution in \`solution/\` (try on your own first!)

## 📁 Exercise Structure

\`\`\`
exercise${exercise_num}/
├── README.md              # This file
├── instructions/          # Detailed instructions
│   ├── part1.md
│   ├── part2.md
│   └── part3.md
├── starter/              # Starting code templates
├── solution/             # Complete solutions
└── tests/               # Validation tests
\`\`\`

## ✅ Success Criteria

- [ ] All parts completed
- [ ] Tests passing
- [ ] Code follows best practices
- [ ] Solution works end-to-end

## 💡 Tips

- Use GitHub Copilot actively
- Test incrementally
- Check hints if stuck
- Review best practices in module docs

---

[⬅️ Back to Module $module_num](../../README.md) | [📚 All Modules](../../../README.md)
EOF
    
    print_success "Created README for Exercise $exercise_num"
}

# Create starter code templates
create_starter_templates() {
    local module_num=$1
    local module_dir="modules/module-$(printf "%02d" $module_num)"
    
    # Create Python starter for exercise 1
    cat > "$module_dir/exercises/exercise1/starter/main.py" << 'EOF'
#!/usr/bin/env python3
"""
Module Exercise 1 - Starter Code

TODO: Follow the instructions to complete this exercise.
Use GitHub Copilot to help you implement the solution.
"""

# TODO: Import required modules


# TODO: Implement the required functions


def main():
    """Main function to run the exercise."""
    # TODO: Implement main logic
    pass


if __name__ == "__main__":
    main()
EOF
    
    # Create requirements.txt
    cat > "$module_dir/exercises/exercise1/starter/requirements.txt" << 'EOF'
# Add required packages here
EOF
    
    print_success "Created starter templates"
}

# Main execution
main() {
    print_header "Reorganizing Module Files"
    
    # Check if we're in the right directory
    if [[ ! -f "README.md" ]] || [[ ! -d "modules" ]]; then
        echo -e "${RED}Error: Please run this script from the workshop root directory${NC}"
        exit 1
    fi
    
    # Process each module
    for i in {1..30}; do
        module_dir="modules/module-$(printf "%02d" $i)"
        
        # Skip if module doesn't exist
        if [[ ! -d "$module_dir" ]]; then
            print_warning "Module $i directory not found, skipping..."
            continue
        fi
        
        # Check if module has files to reorganize
        if ls "$module_dir"/module-*.md 1> /dev/null 2>&1 || ls "$module_dir"/module-*.py 1> /dev/null 2>&1 || ls "$module_dir"/module-*.sh 1> /dev/null 2>&1; then
            reorganize_module $i
            create_starter_templates $i
        else
            print_info "Module $i has no files to reorganize"
        fi
    done
    
    print_header "Creating Index Files"
    
    # Create docs index for modules that have docs
    for i in {1..30}; do
        docs_dir="modules/module-$(printf "%02d" $i)/docs"
        if [[ -d "$docs_dir" ]] && ls "$docs_dir"/*.md 1> /dev/null 2>&1; then
            create_docs_index $i
        fi
    done
    
    print_header "Reorganization Complete!"
    print_success "All module files have been reorganized"
    print_info "Next steps:"
    echo "  1. Review the new structure"
    echo "  2. Update any broken links"
    echo "  3. Run navigation enhancement script"
}

# Create docs index
create_docs_index() {
    local module_num=$1
    local docs_dir="modules/module-$(printf "%02d" $module_num)/docs"
    
    cat > "$docs_dir/README.md" << EOF
# Module $module_num Documentation

## 📚 Available Documents

EOF
    
    # List all docs
    for doc in "$docs_dir"/*.md; do
        if [[ -f "$doc" ]] && [[ "$(basename "$doc")" != "README.md" ]]; then
            local doc_name=$(basename "$doc" .md | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g')
            echo "- [$doc_name]($(basename "$doc"))" >> "$docs_dir/README.md"
        fi
    done
    
    cat >> "$docs_dir/README.md" << EOF

## 📖 Document Descriptions

### Best Practices
Production-ready patterns and recommendations for this module's concepts.

### Troubleshooting
Common issues and solutions specific to this module.

### Common Patterns
Reusable code patterns and templates.

### Prompt Templates
Effective AI prompting examples for this module's exercises.

---

[⬅️ Back to Module $module_num](../README.md)
EOF
    
    print_success "Created docs index for Module $module_num"
}

# Run main function
main
