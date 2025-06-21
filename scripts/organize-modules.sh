#!/bin/bash

# ========================================================================
# Mastery AI Apps and Development Workshop - Module Organization Script
# ========================================================================
# This script organizes module structure and creates navigation links
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

# Create standard module structure
create_module_structure() {
    local module_num=$1
    local module_dir="modules/module-$(printf "%02d" $module_num)"
    
    print_info "Creating structure for Module $module_num..."
    
    # Create directories
    mkdir -p "$module_dir/exercises/exercise1/starter"
    mkdir -p "$module_dir/exercises/exercise1/solution"
    mkdir -p "$module_dir/exercises/exercise1/tests"
    mkdir -p "$module_dir/exercises/exercise2/starter"
    mkdir -p "$module_dir/exercises/exercise2/solution"
    mkdir -p "$module_dir/exercises/exercise2/tests"
    mkdir -p "$module_dir/exercises/exercise3/starter"
    mkdir -p "$module_dir/exercises/exercise3/solution"
    mkdir -p "$module_dir/exercises/exercise3/tests"
    mkdir -p "$module_dir/docs"
    mkdir -p "$module_dir/resources"
    mkdir -p "$module_dir/scripts"
    
    print_success "Created directory structure for Module $module_num"
}

# Create navigation header for markdown files
create_nav_header() {
    local module_num=$1
    local prev_module=$((module_num - 1))
    local next_module=$((module_num + 1))
    
    local nav_header="[🏠 Home](../../README.md)"
    
    if [[ $prev_module -ge 1 ]]; then
        nav_header="$nav_header | [⬅️ Module $(printf "%02d" $prev_module)](../module-$(printf "%02d" $prev_module)/README.md)"
    fi
    
    nav_header="$nav_header | [📚 Module $module_num](README.md)"
    
    if [[ $next_module -le 30 ]]; then
        nav_header="$nav_header | [➡️ Module $(printf "%02d" $next_module)](../module-$(printf "%02d" $next_module)/README.md)"
    fi
    
    nav_header="$nav_header\n\n---\n"
    
    echo -e "$nav_header"
}

# Create navigation footer
create_nav_footer() {
    local module_num=$1
    
    cat << EOF

---

## 🔗 Quick Links

### Module Resources
- [📋 Prerequisites](prerequisites.md)
- [📖 Best Practices](docs/best-practices.md)
- [🔧 Troubleshooting](docs/troubleshooting.md)
- [💡 Prompt Templates](docs/prompt-templates.md)

### Exercises
- [⭐ Exercise 1 - Foundation](exercises/exercise1/README.md)
- [⭐⭐ Exercise 2 - Application](exercises/exercise2/README.md)
- [⭐⭐⭐ Exercise 3 - Mastery](exercises/exercise3/README.md)

### Workshop Resources
- [🏠 Workshop Home](../../README.md)
- [📚 All Modules](../../README.md#-complete-module-overview)
- [🚀 Quick Start](../../QUICKSTART.md)
- [❓ FAQ](../../FAQ.md)
- [🤖 Prompt Guide](../../PROMPT-GUIDE.md)
- [🔧 Troubleshooting](../../TROUBLESHOOTING.md)

EOF
}

# Update module README with navigation
update_module_readme() {
    local module_num=$1
    local module_dir="modules/module-$(printf "%02d" $module_num)"
    local readme_file="$module_dir/README.md"
    
    if [[ -f "$readme_file" ]]; then
        print_info "Updating README for Module $module_num..."
        
        # Create temporary file with navigation
        local temp_file="$readme_file.tmp"
        
        # Add navigation header
        create_nav_header $module_num > "$temp_file"
        
        # Add original content (skip first line if it's a title)
        if head -1 "$readme_file" | grep -q "^#"; then
            cat "$readme_file" >> "$temp_file"
        else
            echo "" >> "$temp_file"
            cat "$readme_file" >> "$temp_file"
        fi
        
        # Add navigation footer
        create_nav_footer $module_num >> "$temp_file"
        
        # Replace original file
        mv "$temp_file" "$readme_file"
        
        print_success "Updated README for Module $module_num"
    fi
}

# Create exercise README template
create_exercise_readme() {
    local module_num=$1
    local exercise_num=$2
    local module_dir="modules/module-$(printf "%02d" $module_num)"
    local exercise_dir="$module_dir/exercises/exercise$exercise_num"
    
    cat > "$exercise_dir/README.md" << EOF
$(create_nav_header $module_num)

# Module $module_num - Exercise $exercise_num

## 🎯 Objectives

This exercise focuses on [specific objectives].

## 📋 Prerequisites

- Completed Module $module_num overview
- Understanding of [concepts]
- VS Code with GitHub Copilot enabled

## 🚀 Getting Started

1. Open the starter code:
   \`\`\`bash
   cd starter/
   code .
   \`\`\`

2. Follow the instructions in the code comments

3. Use GitHub Copilot to help implement the solutions

## 📝 Instructions

### Part 1: Setup
[Instructions for part 1]

### Part 2: Implementation
[Instructions for part 2]

### Part 3: Testing
[Instructions for part 3]

## ✅ Success Criteria

- [ ] All functions implemented
- [ ] Tests passing
- [ ] Code follows best practices
- [ ] Documentation complete

## 💡 Tips

- Use descriptive comments for better Copilot suggestions
- Break complex problems into smaller parts
- Test incrementally

## 🆘 Need Help?

- Check the [hints](hints.md) file
- Review [Module $module_num Best Practices](../../docs/best-practices.md)
- See the [solution](solution/) (try on your own first!)

$(create_nav_footer $module_num)
EOF
}

# Create module index
create_module_index() {
    cat > "modules/README.md" << 'EOF'
# 📚 Workshop Modules

Welcome to the Mastery AI Apps and Development Workshop modules!

## 🗂️ Module Directory

### 🟢 Fundamentals Track (Modules 1-5)
- [Module 01 - Introduction to AI-Powered Development](module-01/README.md)
- [Module 02 - GitHub Copilot Core Features](module-02/README.md)
- [Module 03 - Effective Prompting Techniques](module-03/README.md)
- [Module 04 - AI-Assisted Debugging and Testing](module-04/README.md)
- [Module 05 - Documentation and Code Quality](module-05/README.md)

### 🔵 Intermediate Track (Modules 6-10)
- [Module 06 - Multi-File Projects and Workspaces](module-06/README.md)
- [Module 07 - Building Web Applications with AI](module-07/README.md)
- [Module 08 - API Development and Integration](module-08/README.md)
- [Module 09 - Database Design and Optimization](module-09/README.md)
- [Module 10 - Real-time and Event-Driven Systems](module-10/README.md)

### 🟠 Advanced Track (Modules 11-15)
- [Module 11 - Microservices Architecture](module-11/README.md)
- [Module 12 - Cloud-Native Development](module-12/README.md)
- [Module 13 - Infrastructure as Code](module-13/README.md)
- [Module 14 - CI/CD with GitHub Actions](module-14/README.md)
- [Module 15 - Performance and Scalability](module-15/README.md)

### 🔴 Enterprise Track (Modules 16-20)
- [Module 16 - Security Implementation](module-16/README.md)
- [Module 17 - GitHub Models and AI Integration](module-17/README.md)
- [Module 18 - Enterprise Integration Patterns](module-18/README.md)
- [Module 19 - Monitoring and Observability](module-19/README.md)
- [Module 20 - Production Deployment Strategies](module-20/README.md)

### 🟣 AI Agents & MCP Track (Modules 21-25)
- [Module 21 - Introduction to AI Agents](module-21/README.md)
- [Module 22 - Building Custom Agents](module-22/README.md)
- [Module 23 - Model Context Protocol (MCP)](module-23/README.md)
- [Module 24 - Multi-Agent Orchestration](module-24/README.md)
- [Module 25 - Advanced Agent Patterns](module-25/README.md)

### ⭐ Enterprise Mastery Track (Modules 26-28)
- [Module 26 - Enterprise .NET Development](module-26/README.md)
- [Module 27 - COBOL Modernization](module-27/README.md)
- [Module 28 - Shift-Left Security & DevOps](module-28/README.md)

### 🏆 Mastery Validation (Modules 29-30)
- [Module 29 - Complete Enterprise Review](module-29/README.md)
- [Module 30 - Ultimate Mastery Challenge](module-30/README.md)

## 📋 Module Structure

Each module follows this standard structure:

```
module-XX/
├── README.md                # Module overview and navigation
├── prerequisites.md         # Module-specific requirements
├── exercises/              
│   ├── exercise1/          # Foundation exercise (⭐)
│   │   ├── README.md
│   │   ├── starter/
│   │   ├── solution/
│   │   └── tests/
│   ├── exercise2/          # Application exercise (⭐⭐)
│   │   ├── README.md
│   │   ├── starter/
│   │   ├── solution/
│   │   └── tests/
│   └── exercise3/          # Mastery exercise (⭐⭐⭐)
│       ├── README.md
│       ├── starter/
│       ├── solution/
│       └── tests/
├── docs/
│   ├── best-practices.md
│   ├── troubleshooting.md
│   ├── prompt-templates.md
│   └── common-patterns.md
├── resources/              # Additional resources
├── scripts/               # Module-specific scripts
└── project/              # Independent project

```

## 🔗 Navigation Tips

- Each document includes navigation links at the top and bottom
- Use the breadcrumb navigation to move between sections
- Quick links sidebar available in each module

## 🚀 Getting Started

1. Start with [Module 01](module-01/README.md)
2. Follow the prerequisites for each module
3. Complete exercises in order
4. Use the navigation links to progress

---

[🏠 Back to Main README](../README.md) | [🚀 Quick Start](../QUICKSTART.md)
EOF
}

# Main execution
main() {
    print_header "Module Organization Script"
    
    # Create module index
    create_module_index
    print_success "Created module index"
    
    # Process each module
    for i in {1..30}; do
        create_module_structure $i
        update_module_readme $i
        
        # Create exercise READMEs
        for j in {1..3}; do
            create_exercise_readme $i $j
        done
    done
    
    print_header "Organization Complete!"
    print_success "All modules have been organized with proper structure and navigation"
    print_info "Next steps:"
    echo "1. Move existing files to appropriate directories"
    echo "2. Update file references in documentation"
    echo "3. Test all navigation links"
}

# Check if we're in the right directory
if [[ ! -f "README.md" ]] || [[ ! -d "modules" ]]; then
    echo -e "${RED}Error: Please run this script from the workshop root directory${NC}"
    exit 1
fi

# Run main function
main
