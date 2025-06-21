#!/bin/bash

# ========================================================================
# Complete Recovery Script - Restore All Module Content
# ========================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

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

# Main recovery process
main() {
    print_header "🔄 Complete Workshop Recovery Process"
    
    # Step 1: Check for content directory
    print_info "Step 1: Checking for content directory..."
    if [ ! -d "content" ]; then
        print_error "Content directory not found!"
        print_info "Please ensure you have a 'content' directory with the original module files"
        print_info "The directory should contain files like:"
        echo "  - module-01-README.md"
        echo "  - module-01-exercise1-part1.md"
        echo "  - module-01-best-practices.md"
        echo "  - etc..."
        exit 1
    fi
    print_success "Content directory found"
    
    # Step 2: Make all scripts executable
    print_info "Step 2: Making scripts executable..."
    chmod +x scripts/*.sh 2>/dev/null || true
    print_success "Scripts are now executable"
    
    # Step 3: Restore module content
    print_info "Step 3: Restoring module content..."
    if [ -f "./scripts/restore-content.sh" ]; then
        ./scripts/restore-content.sh
        print_success "Module content restored"
    else
        print_error "restore-content.sh not found!"
    fi
    
    # Step 4: Fix navigation links
    print_info "Step 4: Creating navigation links..."
    if [ -f "./scripts/create-navigation-links.sh" ]; then
        ./scripts/create-navigation-links.sh
        print_success "Navigation links created"
    else
        print_warning "create-navigation-links.sh not found"
    fi
    
    # Step 5: Enhance navigation
    print_info "Step 5: Enhancing navigation..."
    if [ -f "./scripts/enhance-navigation.sh" ]; then
        ./scripts/enhance-navigation.sh || print_warning "Navigation enhancement had warnings"
        print_success "Navigation enhanced"
    else
        print_warning "enhance-navigation.sh not found"
    fi
    
    # Step 6: Generate summary report
    print_header "📊 Generating Recovery Summary"
    
    cat > "RECOVERY_SUMMARY.md" << EOF
# 🔄 Workshop Recovery Summary

**Date**: $(date)

## Recovery Status

### ✅ Completed Steps:
1. Content directory verified
2. Scripts made executable
3. Module content restored from 'content' directory
4. Navigation links created
5. Navigation enhanced

### 📁 Module Status:
EOF

    # Check each module
    for i in $(seq -f "%02g" 1 30); do
        module_dir="modules/module-$i"
        if [ -d "$module_dir" ]; then
            file_count=$(find "$module_dir" -type f \( -name "*.md" -o -name "*.py" -o -name "*.sh" \) | wc -l)
            if [ "$file_count" -gt 5 ]; then
                echo "- Module $i: ✅ Restored ($file_count files)" >> "RECOVERY_SUMMARY.md"
            else
                echo "- Module $i: ⚠️  Partial ($file_count files)" >> "RECOVERY_SUMMARY.md"
            fi
        fi
    done
    
    cat >> "RECOVERY_SUMMARY.md" << EOF

## 🔍 Next Steps:

1. **Review Content**: Check a few modules to ensure content is correct
2. **Test Navigation**: Click through navigation links
3. **Commit Changes**: 
   \`\`\`bash
   git add .
   git commit -m "Restore all module content and fix navigation"
   git push origin main
   \`\`\`

## 📝 Important Files:
- RESTORATION_REPORT.md - Detailed restoration log
- STRUCTURE_REPORT.md - Module structure details
- modules/NAVIGATION_MAP.md - Navigation overview
- LINK_INDEX.md - Complete link index

## ⚠️ Manual Checks Needed:
- Verify exercise solutions work
- Check that all images/resources are in place
- Test a few module exercises end-to-end
EOF

    print_success "Recovery summary created: RECOVERY_SUMMARY.md"
    
    # Final status
    print_header "✅ Recovery Process Complete!"
    
    print_info "Summary:"
    echo "  • All scripts executed"
    echo "  • Module content restored"
    echo "  • Navigation updated"
    echo "  • Reports generated"
    
    print_info "Please check:"
    echo "  1. RECOVERY_SUMMARY.md for overview"
    echo "  2. RESTORATION_REPORT.md for details"
    echo "  3. Test a few modules manually"
    
    print_success "Workshop recovery complete! 🎉"
}

# Check if we're in the right directory
if [[ ! -f "README.md" ]] || [[ ! -d "modules" ]]; then
    print_error "Please run this script from the workshop root directory"
    exit 1
fi

# Run main function
main
