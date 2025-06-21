#!/bin/bash

# ========================================================================
# Mastery AI Apps and Development Workshop - Standardize All Modules
# ========================================================================
# This script ensures all 30 modules follow the standard structure:
# - Correct directory structure
# - Proper file naming conventions
# - All required files present
# - Updated navigation and links
# ========================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
TOTAL_MODULES_PROCESSED=0
TOTAL_FILES_CREATED=0
TOTAL_FILES_MOVED=0
TOTAL_LINKS_UPDATED=0

# Standard module structure
STANDARD_STRUCTURE=(
    "docs"
    "exercises/exercise1"
    "exercises/exercise2"
    "exercises/exercise3"
    "project"
    "resources"
    "scripts"
    "solutions"
)

# Required files in root
ROOT_FILES=(
    "README.md"
    "prerequisites.md"
)

# Required files in docs
DOCS_FILES=(
    "setup.md"
    "best-practices.md"
    "common-patterns.md"
    "troubleshooting.md"
    "prompt-templates.md"
)

# Required files in exercises
EXERCISE_FILES=(
    "README.md"
    "instructions.md"
    "starter-code.py"
    "solution.py"
    "tests.py"
)

# Required files in project
PROJECT_FILES=(
    "README.md"
    "requirements.md"
    "evaluation-criteria.md"
)

# Required files in resources
RESOURCES_FILES=(
    "README.md"
    "additional-reading.md"
    "useful-links.md"
    "cheat-sheet.md"
)

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

print_progress() {
    echo -e "${CYAN}⏳ $1${NC}"
}

# Function to get module title
get_module_title() {
    local module_num=$1
    # Remove leading zeros for comparison
    module_num=$(echo $module_num | sed 's/^0*//')
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

# Function to get module difficulty
get_module_difficulty() {
    local module_num=$1
    # Remove leading zeros for comparison
    module_num=$(echo $module_num | sed 's/^0*//')
    if [[ $module_num -le 5 ]]; then
        echo "🟢 Fundamentals"
    elif [[ $module_num -le 10 ]]; then
        echo "🔵 Intermediate"
    elif [[ $module_num -le 15 ]]; then
        echo "🟠 Advanced"
    elif [[ $module_num -le 20 ]]; then
        echo "🔴 Enterprise"
    elif [[ $module_num -le 25 ]]; then
        echo "🟣 AI Agents"
    else
        echo "⭐ Mastery"
    fi
}

# Function to create directory structure
create_module_structure() {
    local module_dir=$1
    
    for dir in "${STANDARD_STRUCTURE[@]}"; do
        mkdir -p "$module_dir/$dir"
    done
}

# Function to move files to correct locations
organize_module_files() {
    local module_dir=$1
    local module_num=$2
    
    # Move exercise files
    for i in 1 2 3; do
        # Move all exercise-related files
        for file in "$module_dir"/*exercise${i}*.md "$module_dir"/*exercise${i}*.py "$module_dir"/*exercise${i}*.js "$module_dir"/*exercise${i}*.ts "$module_dir"/*exercise${i}*.sh "$module_dir"/*exercise${i}*.yml "$module_dir"/*exercise${i}*.yaml "$module_dir"/*exercise${i}*.json "$module_dir"/*exercise${i}*.txt; do
            if [[ -f "$file" ]]; then
                basename=$(basename "$file")
                # Clean the filename
                new_name=$(echo "$basename" | sed "s/module-${module_num}-//g")
                new_name=$(echo "$new_name" | sed "s/exercise${i}-//g")
                
                # Determine file type and destination
                if [[ "$new_name" =~ part[0-9] ]]; then
                    # Multi-part exercise
                    mv "$file" "$module_dir/exercises/exercise${i}/$new_name"
                elif [[ "$new_name" =~ solution ]]; then
                    mv "$file" "$module_dir/exercises/exercise${i}/solution.py"
                elif [[ "$new_name" =~ starter ]]; then
                    mv "$file" "$module_dir/exercises/exercise${i}/starter-code.py"
                elif [[ "$new_name" =~ test ]]; then
                    mv "$file" "$module_dir/exercises/exercise${i}/tests.py"
                else
                    mv "$file" "$module_dir/exercises/exercise${i}/$new_name"
                fi
                print_success "Moved: $basename → exercises/exercise${i}/"
                ((TOTAL_FILES_MOVED++))
            fi
        done
    done
    
    # Move project files
    for file in "$module_dir"/*project*.md "$module_dir"/*project*.py "$module_dir"/*project*.js "$module_dir"/*project*.ts "$module_dir"/*project*.sh "$module_dir"/*project*.yml "$module_dir"/*project*.yaml "$module_dir"/*project*.json "$module_dir"/*project*.txt; do
        if [[ -f "$file" ]]; then
            basename=$(basename "$file")
            new_name=$(echo "$basename" | sed "s/module-${module_num}-//g")
            new_name=$(echo "$new_name" | sed "s/project-//g")
            mv "$file" "$module_dir/project/$new_name"
            print_success "Moved: $basename → project/"
            ((TOTAL_FILES_MOVED++))
        fi
    done
    
    # Move script files
    for file in "$module_dir"/*-script.sh "$module_dir"/*-script.py "$module_dir"/*-script.js "$module_dir"/*-script.ps1 "$module_dir"/*setup*.sh "$module_dir"/*setup*.py "$module_dir"/*validate*.sh "$module_dir"/*validate*.py; do
        if [[ -f "$file" ]]; then
            basename=$(basename "$file")
            new_name=$(echo "$basename" | sed "s/module-${module_num}-//g")
            mv "$file" "$module_dir/scripts/$new_name"
            print_success "Moved: $basename → scripts/"
            ((TOTAL_FILES_MOVED++))
        fi
    done
    
    # Move resource files
    for file in "$module_dir"/*utils*.* "$module_dir"/*helper*.* "$module_dir"/*example*.* "$module_dir"/*sample*.* "$module_dir"/*template*.*; do
        if [[ -f "$file" ]]; then
            basename=$(basename "$file")
            new_name=$(echo "$basename" | sed "s/module-${module_num}-//g")
            mv "$file" "$module_dir/resources/$new_name"
            print_success "Moved: $basename → resources/"
            ((TOTAL_FILES_MOVED++))
        fi
    done
    
    # Move solution files
    for file in "$module_dir"/*solution*.py "$module_dir"/*solution*.js "$module_dir"/*solution*.ts "$module_dir"/*solution*.md; do
        if [[ -f "$file" ]]; then
            basename=$(basename "$file")
            # Skip if already moved to exercises
            if [[ ! "$basename" =~ exercise ]]; then
                new_name=$(echo "$basename" | sed "s/module-${module_num}-//g")
                mv "$file" "$module_dir/solutions/$new_name"
                print_success "Moved: $basename → solutions/"
                ((TOTAL_FILES_MOVED++))
            fi
        fi
    done
}

# Function to create missing required files
create_missing_files() {
    local module_dir=$1
    local module_num=$2
    local module_title=$(get_module_title $module_num)
    local module_difficulty=$(get_module_difficulty $module_num)
    
    # Create README.md if missing
    if [[ ! -f "$module_dir/README.md" ]]; then
        cat > "$module_dir/README.md" << EOF
# Module $module_num: $module_title

$module_difficulty

## 📋 Module Overview

Welcome to Module $module_num! This module covers $module_title.

## 🎯 Learning Objectives

By the end of this module, you will be able to:
- Objective 1
- Objective 2
- Objective 3
- Objective 4

## 📚 Prerequisites

Before starting this module, ensure you have:
- Completed previous modules
- Reviewed [prerequisites](prerequisites.md)
- Set up your development environment

## 🗂️ Module Structure

\`\`\`
module-$module_num/
├── README.md (this file)
├── prerequisites.md
├── docs/
│   ├── setup.md
│   ├── best-practices.md
│   ├── common-patterns.md
│   ├── troubleshooting.md
│   └── prompt-templates.md
├── exercises/
│   ├── exercise1/ (⭐ Foundation)
│   ├── exercise2/ (⭐⭐ Application)
│   └── exercise3/ (⭐⭐⭐ Mastery)
├── project/
├── resources/
├── scripts/
└── solutions/
\`\`\`

## 🚀 Getting Started

1. Review the [prerequisites](prerequisites.md)
2. Follow the [setup guide](docs/setup.md)
3. Start with [Exercise 1](exercises/exercise1/README.md)

## 💡 Tips for Success

- Read the instructions carefully
- Use AI assistance effectively
- Test your code frequently
- Don't hesitate to consult the documentation

## 📖 Additional Resources

- [Best Practices](docs/best-practices.md)
- [Common Patterns](docs/common-patterns.md)
- [Troubleshooting Guide](docs/troubleshooting.md)
- [Additional Resources](resources/README.md)
EOF
        print_success "Created README.md for Module $module_num"
        ((TOTAL_FILES_CREATED++))
    fi
    
    # Create prerequisites.md if missing
    if [[ ! -f "$module_dir/prerequisites.md" ]]; then
        cat > "$module_dir/prerequisites.md" << EOF
# Prerequisites - Module $module_num: $module_title

## 📋 Required Knowledge

Before starting this module, you should have:

### From Previous Modules
- Completed Modules 1-$(($module_num - 1))
- Understanding of concepts covered in previous modules
- Hands-on experience with exercises

### Technical Skills
- Basic programming knowledge
- Familiarity with Git and GitHub
- Understanding of software development concepts

## 🛠️ Required Tools

Ensure you have the following tools installed:

### Development Environment
- [ ] Visual Studio Code (latest version)
- [ ] GitHub Copilot extension
- [ ] Git (2.34+)
- [ ] Python (3.8+) or Node.js (16+)

### Additional Tools
- [ ] Terminal/Command Prompt
- [ ] Web browser (Chrome/Firefox/Edge)
- [ ] GitHub account

## 🔧 Setup Instructions

1. **Verify installations:**
   \`\`\`bash
   git --version
   python --version  # or node --version
   code --version
   \`\`\`

2. **Clone the repository:**
   \`\`\`bash
   git clone <repository-url>
   cd Mastery-AI-Apps-Dev
   \`\`\`

3. **Navigate to this module:**
   \`\`\`bash
   cd modules/module-$module_num
   \`\`\`

4. **Run setup script:**
   \`\`\`bash
   ./scripts/setup.sh  # if available
   \`\`\`

## ✅ Validation Checklist

- [ ] All tools installed and working
- [ ] Repository cloned successfully
- [ ] Can navigate to module directory
- [ ] Understand module objectives
- [ ] Ready to start exercises

## 🆘 Getting Help

If you encounter issues:
1. Check the [Troubleshooting Guide](docs/troubleshooting.md)
2. Review the [FAQ](../../FAQ.md)
3. Ask in the discussion forum

[← Back to Module](README.md) | [Continue to Setup →](docs/setup.md)
EOF
        print_success "Created prerequisites.md for Module $module_num"
        ((TOTAL_FILES_CREATED++))
    fi
    
    # Create docs files
    mkdir -p "$module_dir/docs"
    
    # setup.md
    if [[ ! -f "$module_dir/docs/setup.md" ]]; then
        cat > "$module_dir/docs/setup.md" << EOF
# Setup Guide - Module $module_num: $module_title

## 🚀 Quick Setup

Follow these steps to set up your environment for this module:

### 1. Environment Setup

\`\`\`bash
# Navigate to module directory
cd modules/module-$module_num

# Create virtual environment (Python)
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Or for Node.js projects
npm init -y
\`\`\`

### 2. Install Dependencies

\`\`\`bash
# Python
pip install -r requirements.txt  # if exists

# Node.js
npm install  # if package.json exists
\`\`\`

### 3. Configure AI Tools

Ensure GitHub Copilot is:
- ✅ Installed in VS Code
- ✅ Signed in with your GitHub account
- ✅ Enabled for this workspace

### 4. Verify Setup

Run the verification script:
\`\`\`bash
# If available
./scripts/verify-setup.sh
\`\`\`

## 📁 Module Structure

Familiarize yourself with the module structure:
- \`docs/\` - Documentation and guides
- \`exercises/\` - Hands-on exercises
- \`project/\` - Module project
- \`resources/\` - Additional materials
- \`scripts/\` - Utility scripts
- \`solutions/\` - Exercise solutions (use sparingly!)

## 🎯 Ready to Start

Once setup is complete:
1. Read the module [README](../README.md)
2. Review [best practices](best-practices.md)
3. Start with [Exercise 1](../exercises/exercise1/README.md)

[← Back to Prerequisites](../prerequisites.md) | [Module Overview →](../README.md)
EOF
        print_success "Created docs/setup.md for Module $module_num"
        ((TOTAL_FILES_CREATED++))
    fi
    
    # best-practices.md
    if [[ ! -f "$module_dir/docs/best-practices.md" ]]; then
        cat > "$module_dir/docs/best-practices.md" << EOF
# Best Practices - Module $module_num: $module_title

## 🎯 Core Principles

### 1. AI-Assisted Development
- Use GitHub Copilot as a pair programmer
- Review and understand generated code
- Don't rely blindly on suggestions

### 2. Code Quality
- Write clean, readable code
- Follow consistent naming conventions
- Add meaningful comments

### 3. Testing
- Test code frequently
- Write unit tests when applicable
- Validate edge cases

## 💡 Module-Specific Best Practices

### For This Module
1. **Practice 1**: Description
2. **Practice 2**: Description
3. **Practice 3**: Description

### Common Patterns
- Pattern 1: When and how to use
- Pattern 2: When and how to use
- Pattern 3: When and how to use

## 🚀 Productivity Tips

### With GitHub Copilot
- Write clear comments first
- Use descriptive function names
- Break complex problems into smaller parts

### General Development
- Commit changes frequently
- Use meaningful commit messages
- Keep functions small and focused

## ⚠️ Common Pitfalls

### Avoid These Mistakes
1. **Mistake 1**: Why it's problematic
2. **Mistake 2**: Why it's problematic
3. **Mistake 3**: Why it's problematic

## 📚 Further Reading

- [Common Patterns](common-patterns.md)
- [Troubleshooting Guide](troubleshooting.md)
- [Module Resources](../resources/README.md)

[← Back to Module](../README.md) | [Common Patterns →](common-patterns.md)
EOF
        print_success "Created docs/best-practices.md for Module $module_num"
        ((TOTAL_FILES_CREATED++))
    fi
    
    # Create exercise directories and files
    for i in 1 2 3; do
        local exercise_dir="$module_dir/exercises/exercise$i"
        mkdir -p "$exercise_dir"
        
        # Exercise README
        if [[ ! -f "$exercise_dir/README.md" ]]; then
            local difficulty_stars=""
            case $i in
                1) difficulty_stars="⭐" ;;
                2) difficulty_stars="⭐⭐" ;;
                3) difficulty_stars="⭐⭐⭐" ;;
            esac
            
            cat > "$exercise_dir/README.md" << EOF
# Exercise $i: Title $difficulty_stars

## 🎯 Objectives

In this exercise, you will:
- Objective 1
- Objective 2
- Objective 3

## 📋 Instructions

1. Read the [detailed instructions](instructions.md)
2. Review the [starter code](starter-code.py)
3. Implement the required functionality
4. Run the [tests](tests.py) to validate

## 🚀 Getting Started

\`\`\`bash
# Navigate to exercise directory
cd exercises/exercise$i

# Review the starter code
code starter-code.py

# Run tests
python tests.py
\`\`\`

## 💡 Tips

- Tip 1
- Tip 2
- Tip 3

## ✅ Success Criteria

- [ ] All tests pass
- [ ] Code follows best practices
- [ ] Solution is efficient

## 📚 Resources

- [Module Best Practices](../../docs/best-practices.md)
- [Common Patterns](../../docs/common-patterns.md)
- [Troubleshooting](../../docs/troubleshooting.md)

[← Back to Module](../../README.md) | [View Solution](solution.py)
EOF
            print_success "Created exercise$i/README.md"
            ((TOTAL_FILES_CREATED++))
        fi
    done
    
    # Create project README
    if [[ ! -f "$module_dir/project/README.md" ]]; then
        cat > "$module_dir/project/README.md" << EOF
# Module $module_num Project: $module_title

## 🎯 Project Overview

This project allows you to apply everything you've learned in Module $module_num.

## 📋 Requirements

See [requirements.md](requirements.md) for detailed specifications.

## 🏗️ Getting Started

1. Review all requirements carefully
2. Plan your approach
3. Implement incrementally
4. Test thoroughly

## 📊 Evaluation Criteria

Your project will be evaluated based on:
- Functionality (40%)
- Code Quality (30%)
- Best Practices (20%)
- Documentation (10%)

See [evaluation-criteria.md](evaluation-criteria.md) for details.

## 💡 Tips for Success

- Start with a clear plan
- Use AI assistance effectively
- Test as you build
- Document your code

[← Back to Module](../README.md)
EOF
        print_success "Created project/README.md"
        ((TOTAL_FILES_CREATED++))
    fi
    
    # Create resources README
    if [[ ! -f "$module_dir/resources/README.md" ]]; then
        cat > "$module_dir/resources/README.md" << EOF
# Resources - Module $module_num: $module_title

## 📚 Additional Learning Materials

### Documentation
- [Official Documentation](#)
- [API Reference](#)
- [Best Practices Guide](#)

### Tutorials
- [Video Tutorial 1](#)
- [Interactive Tutorial](#)
- [Step-by-Step Guide](#)

### Articles
- [In-depth Article 1](#)
- [Case Study](#)
- [Technical Deep Dive](#)

## 🛠️ Tools and Libraries

- **Tool 1**: Description and link
- **Tool 2**: Description and link
- **Library 1**: Description and link

## 📖 Recommended Reading

1. **Book/Article Title**
   - Author
   - Key concepts covered

2. **Book/Article Title**
   - Author
   - Key concepts covered

## 🔗 Useful Links

- [Link 1](useful-links.md)
- [Link 2](useful-links.md)
- [Link 3](useful-links.md)

## 💡 Quick Reference

See our [cheat sheet](cheat-sheet.md) for quick reference.

[← Back to Module](../README.md)
EOF
        print_success "Created resources/README.md"
        ((TOTAL_FILES_CREATED++))
    fi
}

# Function to update all links in a module
update_module_links() {
    local module_dir=$1
    local module_num=$2
    
    # Find all markdown files in the module
    find "$module_dir" -name "*.md" -type f | while read -r file; do
        # Create temporary file
        local temp_file="${file}.tmp"
        cp "$file" "$temp_file"
        
        # Update various link patterns
        # Fix module-XX- prefixes in links
        sed -i '' "s/module-${module_num}-//g" "$temp_file"
        
        # Fix exercise links
        sed -i '' 's/\(exercises\/\)module-[0-9][0-9]-exercise/\1exercise/g' "$temp_file"
        
        # Fix docs links
        sed -i '' 's/\(docs\/\)module-[0-9][0-9]-/\1/g' "$temp_file"
        
        # Fix relative paths
        sed -i '' 's/\.\.\//..\//' "$temp_file"
        
        # Update if changes were made
        if ! diff -q "$file" "$temp_file" > /dev/null 2>&1; then
            mv "$temp_file" "$file"
            ((TOTAL_LINKS_UPDATED++))
        else
            rm "$temp_file"
        fi
    done
}

# Function to process a single module
process_module() {
    local module_num=$1
    local module_dir="modules/module-$module_num"
    local module_title=$(get_module_title $module_num)
    
    print_header "Processing Module $module_num: $module_title"
    
    # Create standard structure
    print_progress "Creating directory structure..."
    create_module_structure "$module_dir"
    
    # Organize existing files
    print_progress "Organizing existing files..."
    organize_module_files "$module_dir" "$module_num"
    
    # Create missing files
    print_progress "Creating missing files..."
    create_missing_files "$module_dir" "$module_num"
    
    # Update all links
    print_progress "Updating links..."
    update_module_links "$module_dir" "$module_num"
    
    print_success "Module $module_num standardized successfully!"
    ((TOTAL_MODULES_PROCESSED++))
}

# Main execution
main() {
    print_header "Standardizing All 30 Modules"
    
    # Process each module
    for i in {01..30}; do
        if [[ -d "modules/module-$i" ]]; then
            process_module "$i"
        else
            print_warning "Module $i directory not found, skipping..."
        fi
    done
    
    # Summary
    print_header "Standardization Complete!"
    echo -e "${GREEN}✅ Modules processed: $TOTAL_MODULES_PROCESSED${NC}"
    echo -e "${GREEN}✅ Files created: $TOTAL_FILES_CREATED${NC}"
    echo -e "${GREEN}✅ Files moved: $TOTAL_FILES_MOVED${NC}"
    echo -e "${GREEN}✅ Links updated: $TOTAL_LINKS_UPDATED${NC}"
    
    # Next steps
    print_header "Next Steps"
    echo "1. Review the changes: git status"
    echo "2. Test navigation: open any module README"
    echo "3. Commit changes: git add . && git commit -m 'Standardize all modules'"
    echo "4. Run link verification: ./scripts/create-navigation-links.sh"
}

# Check if we're in the right directory
if [[ ! -f "README.md" ]] || [[ ! -d "modules" ]]; then
    print_error "Please run this script from the workshop root directory"
    exit 1
fi

# Run main function
main 