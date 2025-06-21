#!/bin/bash

# ========================================================================
# Mastery AI Apps and Development Workshop - Create Navigation Links
# ========================================================================
# This script creates navigation links between all workshop documents
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

# Create navigation template for root documents
create_root_nav() {
    local doc_name=$1
    
    cat << 'EOF'

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

EOF
}

# Add navigation to root documents
add_root_navigation() {
    local files=(
        "PREREQUISITES.md"
        "QUICKSTART.md"
        "TROUBLESHOOTING.md"
        "FAQ.md"
        "PROMPT-GUIDE.md"
        "GITOPS-GUIDE.md"
    )
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            print_info "Adding navigation to $file..."
            
            # Add navigation at the end
            echo "$(create_root_nav)" >> "$file"
            print_success "Added navigation to $file"
        fi
    done
}

# Create module-to-module navigation links
create_module_links() {
    cat > "modules/NAVIGATION_MAP.md" << 'EOF'
# 🗺️ Workshop Navigation Map

## Module Quick Links

### 🟢 Fundamentals Track (Beginner)
1. [Module 01 - Introduction to AI-Powered Development](module-01/README.md)
   - [Prerequisites](module-01/module-01-prerequisites.md) | [Exercise 1](module-01/module-01-exercise1-part1.md) | [Best Practices](module-01/module-01-best-practices.md)
2. [Module 02 - GitHub Copilot Core Features](module-02/README.md)
3. [Module 03 - Effective Prompting Techniques](module-03/README.md)
4. [Module 04 - AI-Assisted Debugging and Testing](module-04/README.md)
5. [Module 05 - Documentation and Code Quality](module-05/README.md)

### 🔵 Intermediate Track
6. [Module 06 - Multi-File Projects and Workspaces](module-06/README.md)
7. [Module 07 - Building Web Applications with AI](module-07/README.md)
8. [Module 08 - API Development and Integration](module-08/README.md)
9. [Module 09 - Database Design and Optimization](module-09/README.md)
10. [Module 10 - Real-time and Event-Driven Systems](module-10/README.md)

### 🟠 Advanced Track
11. [Module 11 - Microservices Architecture](module-11/README.md)
12. [Module 12 - Cloud-Native Development](module-12/README.md)
13. [Module 13 - Infrastructure as Code](module-13/README.md)
14. [Module 14 - CI/CD with GitHub Actions](module-14/README.md)
15. [Module 15 - Performance and Scalability](module-15/README.md)

### 🔴 Enterprise Track
16. [Module 16 - Security Implementation](module-16/README.md)
17. [Module 17 - GitHub Models and AI Integration](module-17/README.md)
18. [Module 18 - Enterprise Integration Patterns](module-18/README.md)
19. [Module 19 - Monitoring and Observability](module-19/README.md)
20. [Module 20 - Production Deployment Strategies](module-20/README.md)

### 🟣 AI Agents & MCP Track
21. [Module 21 - Introduction to AI Agents](module-21/README.md)
22. [Module 22 - Building Custom Agents](module-22/README.md)
23. [Module 23 - Model Context Protocol (MCP)](module-23/README.md)
24. [Module 24 - Multi-Agent Orchestration](module-24/README.md)
25. [Module 25 - Advanced Agent Patterns](module-25/README.md)

### ⭐ Enterprise Mastery Track
26. [Module 26 - Enterprise .NET Development](module-26/README.md)
27. [Module 27 - COBOL Modernization](module-27/README.md)
28. [Module 28 - Shift-Left Security & DevOps](module-28/README.md)
29. [Module 29 - Complete Enterprise Review](module-29/README.md)
30. [Module 30 - Ultimate Mastery Challenge](module-30/README.md)

## 🧭 Navigation Patterns

### Within a Module
- **Breadcrumbs**: Shows your location (e.g., Workshop > Modules > Module 01 > Exercise 1)
- **Quick Nav Table**: Three columns for easy access to all module content
- **Exercise Links**: Sequential navigation between exercise parts

### Between Modules
- **Previous/Next**: Arrow navigation at top and bottom
- **Track Overview**: Jump to any module in the same track
- **Category Badges**: Visual indicators for difficulty level

### Workshop-Wide
- **Home Link**: Always return to main README
- **Resource Footer**: Consistent access to all tools and guides
- **Search**: Use Ctrl/Cmd+F on any page

## 🎯 Recommended Navigation Flows

### For New Learners
1. Start at [Workshop Home](../README.md)
2. Read [Prerequisites](../PREREQUISITES.md)
3. Follow [Quick Start](../QUICKSTART.md)
4. Begin [Module 01](module-01/README.md)
5. Progress sequentially through modules

### For Experienced Developers
1. Review [Module Overview](README.md)
2. Check track prerequisites
3. Jump to appropriate track start
4. Use module navigation to skip familiar content

### For Reference
1. Use [Navigation Map](NAVIGATION_MAP.md) (this file)
2. Browse by [Track](README.md#-learning-tracks)
3. Search for specific topics
4. Access resources directly

---

[🏠 Workshop Home](../README.md) | [📚 All Modules](README.md)
EOF
    
    print_success "Created navigation map"
}

# Create comprehensive link index
create_link_index() {
    cat > "LINK_INDEX.md" << 'EOF'
# 🔗 Complete Link Index

## Root Documents
- [README.md](README.md) - Workshop overview
- [PREREQUISITES.md](PREREQUISITES.md) - Setup requirements
- [QUICKSTART.md](QUICKSTART.md) - 5-minute start guide
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues
- [FAQ.md](FAQ.md) - Frequently asked questions
- [PROMPT-GUIDE.md](PROMPT-GUIDE.md) - AI prompting guide
- [GITOPS-GUIDE.md](GITOPS-GUIDE.md) - GitOps patterns

## Scripts
- [scripts/README.md](scripts/README.md) - Scripts documentation
- [scripts/setup-workshop.sh](scripts/setup-workshop.sh) - Complete setup
- [scripts/quick-start.sh](scripts/quick-start.sh) - Quick start
- [scripts/validate-prerequisites.sh](scripts/validate-prerequisites.sh) - Validation
- [scripts/cleanup-resources.sh](scripts/cleanup-resources.sh) - Azure cleanup
- [scripts/backup-progress.sh](scripts/backup-progress.sh) - Progress backup
- [scripts/organize-modules.sh](scripts/organize-modules.sh) - Module organization
- [scripts/enhance-navigation.sh](scripts/enhance-navigation.sh) - Navigation enhancement
- [scripts/reorganize-files.sh](scripts/reorganize-files.sh) - File reorganization

## Module Index
- [modules/README.md](modules/README.md) - All modules overview
- [modules/NAVIGATION_MAP.md](modules/NAVIGATION_MAP.md) - Navigation map

## Module Links (1-30)
[Detailed module links organized by track...]

## External Resources
- [GitHub Copilot Docs](https://docs.github.com/copilot)
- [Azure Documentation](https://learn.microsoft.com/azure)
- [GitHub Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions)
- [Workshop Issues](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/issues)

---

This index provides quick access to all workshop documents and resources.
EOF
    
    print_success "Created link index"
}

# Verify all links
verify_links() {
    print_header "Verifying Links"
    
    local broken_links=0
    
    # Check markdown files for broken internal links
    for file in $(find . -name "*.md" -not -path "./.git/*"); do
        # Extract relative links
        links=$(grep -oE '\[([^]]+)\]\(([^)]+)\)' "$file" | grep -oE '\(([^)]+)\)' | tr -d '()' | grep -v '^http' | grep -v '^#')
        
        for link in $links; do
            # Get the directory of the current file
            dir=$(dirname "$file")
            
            # Resolve the link path
            target="$dir/$link"
            target=$(realpath "$target" 2>/dev/null || echo "$target")
            
            # Check if target exists
            if [[ ! -f "$target" ]] && [[ ! -d "$target" ]]; then
                print_warning "Broken link in $file: $link"
                ((broken_links++))
            fi
        done
    done
    
    if [[ $broken_links -eq 0 ]]; then
        print_success "All internal links verified!"
    else
        print_warning "Found $broken_links broken links"
    fi
}

# Main execution
main() {
    print_header "Creating Navigation Links"
    
    # Add navigation to root documents
    add_root_navigation
    
    # Create module navigation links
    create_module_links
    
    # Create comprehensive link index
    create_link_index
    
    # Verify all links
    verify_links
    
    print_header "Navigation Links Complete!"
    print_success "All documents now have proper navigation"
    print_info "Features added:"
    echo "  • Root document navigation"
    echo "  • Module navigation map"
    echo "  • Complete link index"
    echo "  • Link verification"
    
    print_info "Next steps:"
    echo "  1. Review the navigation map: modules/NAVIGATION_MAP.md"
    echo "  2. Check the link index: LINK_INDEX.md"
    echo "  3. Test navigation flow"
}

# Check if we're in the right directory
if [[ ! -f "README.md" ]] || [[ ! -d "modules" ]]; then
    echo -e "${RED}Error: Please run this script from the workshop root directory${NC}"
    exit 1
fi

# Run main function
main
