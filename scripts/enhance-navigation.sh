#!/bin/bash

# ========================================================================
# Mastery AI Apps and Development Workshop - Add Navigation Links Script
# ========================================================================
# This script adds navigation links and breadcrumbs to all documents
# ========================================================================

# Remove set -e to prevent exit on warnings
# set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Workshop structure
TOTAL_MODULES=30

# Function to get module title by number (compatible with older bash)
get_module_title() {
    local module_num=$1
    case $module_num in
        1) echo "Introduction to AI-Powered Development" ;;
        2) echo "GitHub Copilot Core Features" ;;
        3) echo "Effective Prompting Techniques" ;;
        4) echo "AI-Assisted Debugging and Testing" ;;
        5) echo "Documentation and Code Quality" ;;
        6) echo "Multi-File Projects and Workspaces" ;;
        7) echo "Building Web Applications with AI" ;;
        8) echo "API Development and Integration" ;;
        9) echo "Database Design and Optimization" ;;
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

# Generate breadcrumb navigation
generate_breadcrumb() {
    local module_num=$1
    local doc_type=$2
    local exercise_num=$3
    
    local breadcrumb="[🏠 Workshop](../../README.md) > "
    breadcrumb+="[📚 Modules](../README.md) > "
    breadcrumb+="[Module $module_num](README.md)"
    
    case $doc_type in
        "exercise")
            breadcrumb+=" > [Exercises](README.md#exercises) > Exercise $exercise_num"
            ;;
        "docs")
            breadcrumb+=" > Documentation"
            ;;
        "resources")
            breadcrumb+=" > Resources"
            ;;
    esac
    
    echo "$breadcrumb"
}

# Generate module navigation bar
generate_module_nav() {
    local module_num=$1
    local prev_module=$((module_num - 1))
    local next_module=$((module_num + 1))
    
    local nav="<div align=\"center\">\n\n"
    
    # Previous module
    if [[ $prev_module -ge 1 ]]; then
        local prev_title=$(get_module_title $prev_module)
        nav+="[⬅️ Module $(printf "%02d" $prev_module): $prev_title](../module-$(printf "%02d" $prev_module)/README.md) | "
    fi
    
    # Current module
    local curr_title=$(get_module_title $module_num)
    nav+="**📖 Module $module_num: $curr_title** "
    
    # Next module
    if [[ $next_module -le $TOTAL_MODULES ]]; then
        local next_title=$(get_module_title $next_module)
        nav+="| [Module $(printf "%02d" $next_module): $next_title ➡️](../module-$(printf "%02d" $next_module)/README.md)"
    fi
    
    nav+="\n\n</div>\n\n---"
    
    echo -e "$nav"
}

# Generate quick navigation sidebar
generate_quick_nav() {
    local module_num=$1
    
    cat << EOF

## 🧭 Quick Navigation

<table>
<tr>
<td valign="top">

### 📖 Module Content
- [Overview](README.md)
- [Prerequisites](prerequisites.md)
- [Setup Guide](docs/setup.md)
- [Troubleshooting](docs/troubleshooting.md)

</td>
<td valign="top">

### 💻 Exercises
- [Exercise 1 - Foundation ⭐](exercises/exercise1/README.md)
- [Exercise 2 - Application ⭐⭐](exercises/exercise2/README.md)
- [Exercise 3 - Mastery ⭐⭐⭐](exercises/exercise3/README.md)
- [Independent Project](project/README.md)

</td>
<td valign="top">

### 📚 Resources
- [Best Practices](docs/best-practices.md)
- [Common Patterns](docs/common-patterns.md)
- [Prompt Templates](docs/prompt-templates.md)
- [Additional Resources](resources/README.md)

</td>
</tr>
</table>

EOF
}

# Generate workshop resources footer
generate_workshop_footer() {
    cat << 'EOF'

---

## 🌐 Workshop Resources

<div align="center">

| Core Documentation | Learning Resources | Tools & Scripts |
|:------------------:|:-----------------:|:---------------:|
| [🏠 Home](../../README.md) | [🚀 Quick Start](../../QUICKSTART.md) | [🛠️ Scripts](../../scripts/README.md) |
| [📋 Prerequisites](../../PREREQUISITES.md) | [❓ FAQ](../../FAQ.md) | [🔧 Setup](../../scripts/setup-workshop.sh) |
| [📚 All Modules](../README.md) | [🤖 Prompt Guide](../../PROMPT-GUIDE.md) | [✅ Validate](../../scripts/validate-prerequisites.sh) |
| [🗺️ Learning Paths](../../README.md#-learning-paths) | [🔧 Troubleshooting](../../TROUBLESHOOTING.md) | [🧹 Cleanup](../../scripts/cleanup-resources.sh) |

</div>

### 🏷️ Module Categories

<div align="center">

| 🟢 Fundamentals | 🔵 Intermediate | 🟠 Advanced | 🔴 Enterprise | 🟣 AI Agents | ⭐ Mastery |
|:---------------:|:---------------:|:-----------:|:-------------:|:------------:|:----------:|
| Modules 1-5 | Modules 6-10 | Modules 11-15 | Modules 16-20 | Modules 21-25 | Modules 26-30 |

</div>

EOF
}

# Update module README with enhanced navigation
update_module_readme_nav() {
    local module_num=$1
    local module_dir="modules/module-$(printf "%02d" $module_num)"
    local readme_file="$module_dir/README.md"
    
    if [[ ! -f "$readme_file" ]]; then
        print_info "README not found for Module $module_num, skipping..."
        return
    fi
    
    print_info "Adding navigation to Module $module_num README..."
    
    # Create temporary file
    local temp_file="$readme_file.nav.tmp"
    
    # Add breadcrumb and navigation
    echo "$(generate_breadcrumb $module_num)" > "$temp_file"
    echo "" >> "$temp_file"
    echo "$(generate_module_nav $module_num)" >> "$temp_file"
    echo "" >> "$temp_file"
    
    # Add original content (skip existing navigation if present)
    local skip_lines=0
    if grep -q "^\[🏠 Workshop\]" "$readme_file"; then
        # Find where the actual content starts
        skip_lines=$(grep -n "^#" "$readme_file" | head -1 | cut -d: -f1)
        skip_lines=$((skip_lines - 1))
    fi
    
    if [[ $skip_lines -gt 0 ]]; then
        tail -n +$((skip_lines + 1)) "$readme_file" >> "$temp_file"
    else
        cat "$readme_file" >> "$temp_file"
    fi
    
    # Add quick navigation before the footer
    echo "" >> "$temp_file"
    generate_quick_nav $module_num >> "$temp_file"
    
    # Add workshop resources footer
    generate_workshop_footer >> "$temp_file"
    
    # Replace original file
    mv "$temp_file" "$readme_file"
    
    print_success "Updated navigation for Module $module_num"
}

# Update exercise README with navigation
update_exercise_readme_nav() {
    local module_num=$1
    local exercise_num=$2
    local module_dir="modules/module-$(printf "%02d" $module_num)"
    local exercise_file="$module_dir/exercises/exercise$exercise_num/README.md"
    
    if [[ ! -f "$exercise_file" ]]; then
        return
    fi
    
    print_info "Adding navigation to Module $module_num Exercise $exercise_num..."
    
    # Create temporary file
    local temp_file="$exercise_file.nav.tmp"
    
    # Add breadcrumb
    echo "$(generate_breadcrumb $module_num "exercise" $exercise_num)" > "$temp_file"
    echo "" >> "$temp_file"
    echo "---" >> "$temp_file"
    echo "" >> "$temp_file"
    
    # Add content
    cat "$exercise_file" >> "$temp_file"
    
    # Add footer navigation
    cat >> "$temp_file" << EOF

---

## 🔗 Exercise Navigation

<div align="center">

EOF
    
    # Previous exercise
    if [[ $exercise_num -gt 1 ]]; then
        echo "[⬅️ Exercise $((exercise_num - 1))](../exercise$((exercise_num - 1))/README.md) | " >> "$temp_file"
    fi
    
    echo "**Exercise $exercise_num** " >> "$temp_file"
    
    # Next exercise
    if [[ $exercise_num -lt 3 ]]; then
        echo "| [Exercise $((exercise_num + 1)) ➡️](../exercise$((exercise_num + 1))/README.md)" >> "$temp_file"
    fi
    
    echo "" >> "$temp_file"
    echo "</div>" >> "$temp_file"
    
    # Add module navigation
    echo "$(generate_module_nav $module_num)" >> "$temp_file"
    
    # Add workshop footer
    generate_workshop_footer >> "$temp_file"
    
    # Replace original file
    mv "$temp_file" "$exercise_file"
}

# Create module navigation index
create_navigation_index() {
    cat > "modules/NAVIGATION.md" << 'EOF'
# 🧭 Workshop Navigation Guide

## 📍 Navigation Structure

The workshop uses a consistent navigation system across all documents:

### 1. Breadcrumb Navigation
Shows your current location in the workshop hierarchy:
```
[🏠 Workshop](../README.md) > [📚 Modules](README.md) > [Module X](module-XX/README.md) > Current Page
```

### 2. Module Navigation Bar
Quick access to previous and next modules:
```
[⬅️ Previous Module] | **📖 Current Module** | [Next Module ➡️]
```

### 3. Quick Navigation Sidebar
Three-column layout for easy access to module resources:
- Module Content (overview, prerequisites, setup)
- Exercises (all three exercises + project)
- Resources (best practices, patterns, templates)

### 4. Workshop Resources Footer
Consistent footer with links to all workshop resources:
- Core Documentation
- Learning Resources
- Tools & Scripts

## 🔍 Finding Your Way

### From Any Module Page
- **Go to Workshop Home**: Click [🏠 Workshop] in breadcrumb
- **Browse All Modules**: Click [📚 Modules] in breadcrumb
- **Previous/Next Module**: Use navigation bar arrows
- **Jump to Exercise**: Use Quick Navigation sidebar
- **Access Tools**: Use Workshop Resources footer

### From Exercise Pages
- **Back to Module**: Click module name in breadcrumb
- **Other Exercises**: Use Exercise Navigation section
- **View Solution**: Link in exercise instructions
- **Get Help**: Links to troubleshooting and FAQ

## 🎯 Navigation Tips

1. **Use Breadcrumbs**: Always know where you are
2. **Quick Navigation**: Jump to any section within a module
3. **Module Categories**: Color-coded by difficulty level
4. **Keyboard Shortcuts**: Use browser back/forward
5. **Bookmarks**: Save frequently accessed pages

## 📊 Module Category Colors

| Color | Track | Modules | Difficulty |
|:-----:|:------|:-------:|:-----------|
| 🟢 | Fundamentals | 1-5 | Beginner |
| 🔵 | Intermediate | 6-10 | Intermediate |
| 🟠 | Advanced | 11-15 | Advanced |
| 🔴 | Enterprise | 16-20 | Expert |
| 🟣 | AI Agents | 21-25 | Expert |
| ⭐ | Mastery | 26-30 | Master |

---

[🏠 Back to Workshop](../README.md) | [📚 All Modules](README.md)
EOF
}

# Main execution
main() {
    print_header "Adding Navigation Links to All Documents"
    
    # Create navigation guide
    create_navigation_index
    print_success "Created navigation guide"
    
    # Process each module
    for i in {1..30}; do
        # Update module README
        update_module_readme_nav $i
        
        # Update exercise READMEs
        for j in {1..3}; do
            update_exercise_readme_nav $i $j
        done
    done
    
    print_header "Navigation Enhancement Complete!"
    print_success "All documents now have enhanced navigation"
    print_info "Features added:"
    echo "  • Breadcrumb navigation"
    echo "  • Module navigation bars"
    echo "  • Quick navigation sidebars"
    echo "  • Workshop resource footers"
    echo "  • Exercise navigation"
}

# Check if we're in the right directory
if [[ ! -f "README.md" ]] || [[ ! -d "modules" ]]; then
    echo -e "${RED}Error: Please run this script from the workshop root directory${NC}"
    exit 1
fi

# Run main function
main
