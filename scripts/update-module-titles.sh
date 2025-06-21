#!/bin/bash

# Script to update module titles in README files

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to get module title
get_module_title() {
    local module_num=$1
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

echo -e "${BLUE}Updating module titles...${NC}"

# Update all module README files
for module_dir in modules/module-*/; do
    if [[ -d "$module_dir" ]]; then
        module_num=$(basename "$module_dir" | sed 's/module-//')
        module_title=$(get_module_title $module_num)
        
        # Update README.md
        if [[ -f "$module_dir/README.md" ]]; then
            # Update title line
            sed -i '' "s/# Module [0-9]*: Unknown Module/# Module $module_num: $module_title/" "$module_dir/README.md"
            sed -i '' "s/# Module [0-9]*: .*/# Module $module_num: $module_title/" "$module_dir/README.md"
            
            echo -e "${GREEN}✓ Updated Module $module_num: $module_title${NC}"
        fi
        
        # Update prerequisites.md
        if [[ -f "$module_dir/prerequisites.md" ]]; then
            sed -i '' "s/# Prerequisites - Module [0-9]*: Unknown Module/# Prerequisites - Module $module_num: $module_title/" "$module_dir/prerequisites.md"
            sed -i '' "s/# Prerequisites - Module [0-9]*: .*/# Prerequisites - Module $module_num: $module_title/" "$module_dir/prerequisites.md"
        fi
        
        # Update docs files
        for doc_file in "$module_dir/docs/"*.md; do
            if [[ -f "$doc_file" ]]; then
                sed -i '' "s/Module [0-9]*: Unknown Module/Module $module_num: $module_title/g" "$doc_file"
                sed -i '' "s/Module [0-9]*: $module_title/Module $module_num: $module_title/g" "$doc_file"
            fi
        done
        
        # Update exercise files
        for exercise_dir in "$module_dir/exercises/"*/; do
            if [[ -d "$exercise_dir" ]]; then
                for file in "$exercise_dir"*.md; do
                    if [[ -f "$file" ]]; then
                        sed -i '' "s/Module [0-9]*: Unknown Module/Module $module_num: $module_title/g" "$file"
                    fi
                done
            fi
        done
        
        # Update project files
        for file in "$module_dir/project/"*.md; do
            if [[ -f "$file" ]]; then
                sed -i '' "s/Module [0-9]* Project: Unknown Module/Module $module_num Project: $module_title/g" "$file"
                sed -i '' "s/Module [0-9]* Project: .*/Module $module_num Project: $module_title/" "$file"
            fi
        done
        
        # Update resources files
        for file in "$module_dir/resources/"*.md; do
            if [[ -f "$file" ]]; then
                sed -i '' "s/Module [0-9]*: Unknown Module/Module $module_num: $module_title/g" "$file"
            fi
        done
    fi
done

echo -e "${GREEN}✅ All module titles updated successfully!${NC}" 