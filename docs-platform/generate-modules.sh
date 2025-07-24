#!/bin/bash

# Script to generate all 30 modules based on Module 01 template
# This script creates the basic structure for all modules

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Mastery AI Apps & Development - Module Generator${NC}"
echo -e "${BLUE}===================================================${NC}"

# Base directory
DOCS_DIR="docs/modules"
TEMPLATE_DIR="$DOCS_DIR/module-01"

# Check if template exists
if [ ! -d "$TEMPLATE_DIR" ]; then
    echo -e "${RED}❌ Error: Template module (module-01) not found at $TEMPLATE_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found template at $TEMPLATE_DIR${NC}"

# Module configurations (Track assignments and difficulty)
declare -A module_tracks=(
    # Fundamentals Track (Modules 1-5)
    [1]="fundamentals"
    [2]="fundamentals"
    [3]="fundamentals"
    [4]="fundamentals"
    [5]="fundamentals"
    
    # Intermediate Track (Modules 6-10)
    [6]="intermediate"
    [7]="intermediate"
    [8]="intermediate"
    [9]="intermediate"
    [10]="intermediate"
    
    # Advanced Track (Modules 11-15)
    [11]="advanced"
    [12]="advanced"
    [13]="advanced"
    [14]="advanced"
    [15]="advanced"
    
    # Enterprise Track (Modules 16-20)
    [16]="enterprise"
    [17]="enterprise"
    [18]="enterprise"
    [19]="enterprise"
    [20]="enterprise"
    
    # AI Agents & MCP Track (Modules 21-25)
    [21]="ai-agents"
    [22]="ai-agents"
    [23]="ai-agents"
    [24]="ai-agents"
    [25]="ai-agents"
    
    # Enterprise Mastery Track (Modules 26-30)
    [26]="mastery"
    [27]="mastery"
    [28]="mastery"
    [29]="mastery"
    [30]="mastery"
)

declare -A module_titles=(
    [1]="GitHub Copilot Foundations"
    [2]="Advanced Code Generation"
    [3]="Testing with AI Assistance"
    [4]="Documentation & Code Review"
    [5]="Development Workflow Optimization"
    [6]="API Development with AI"
    [7]="Database Design & Integration"
    [8]="Frontend Framework Mastery"
    [9]="State Management Patterns"
    [10]="Performance Optimization"
    [11]="Microservices Architecture"
    [12]="Cloud-Native Development"
    [13]="DevOps & CI/CD Integration"
    [14]="Security & Best Practices"
    [15]="Monitoring & Observability"
    [16]="Enterprise Architecture Patterns"
    [17]="Scalability & Load Management"
    [18]="Data Pipeline Development"
    [19]="Machine Learning Integration"
    [20]="Enterprise Security Framework"
    [21]="AI Agent Fundamentals"
    [22]="Model Context Protocol (MCP)"
    [23]="Agent Orchestration Patterns"
    [24]="Custom Tool Development"
    [25]="Multi-Agent Systems"
    [26]="Enterprise AI Strategy"
    [27]="AI Governance & Ethics"
    [28]="Production AI Systems"
    [29]="AI Performance Optimization"
    [30]="Future-Proof AI Architecture"
)

declare -A module_descriptions=(
    [1]="Master the fundamentals of GitHub Copilot for efficient code generation"
    [2]="Advanced techniques for generating complex code structures and patterns"
    [3]="Leverage AI to write comprehensive tests and improve code quality"
    [4]="Create excellent documentation and conduct effective code reviews with AI"
    [5]="Optimize your development workflow using AI-powered tools and techniques"
    [6]="Build robust APIs with AI assistance and best practices"
    [7]="Design and integrate databases efficiently with AI-powered development"
    [8]="Master modern frontend frameworks with AI-accelerated development"
    [9]="Implement effective state management patterns in complex applications"
    [10]="Optimize application performance using AI-driven analysis and solutions"
    [11]="Architect and implement microservices with AI development assistance"
    [12]="Develop cloud-native applications with AI-powered tools and practices"
    [13]="Integrate AI development into DevOps and CI/CD pipelines"
    [14]="Implement security best practices with AI assistance and automation"
    [15]="Build comprehensive monitoring and observability solutions"
    [16]="Design enterprise-grade architecture patterns and solutions"
    [17]="Implement scalable systems that handle enterprise-level loads"
    [18]="Build efficient data pipelines with AI-assisted development"
    [19]="Integrate machine learning models into production applications"
    [20]="Implement comprehensive enterprise security frameworks"
    [21]="Understand AI agents, their capabilities, and fundamental concepts"
    [22]="Master the Model Context Protocol for AI agent communication"
    [23]="Design and implement sophisticated agent orchestration patterns"
    [24]="Develop custom tools and extensions for AI agent systems"
    [25]="Build and manage complex multi-agent collaborative systems"
    [26]="Develop enterprise-wide AI adoption and implementation strategies"
    [27]="Implement AI governance, ethics, and responsible AI practices"
    [28]="Deploy and manage AI systems in production environments"
    [29]="Optimize AI system performance for enterprise-scale operations"
    [30]="Design future-proof AI architectures for long-term success"
)

declare -A module_difficulty=(
    [1]="foundation"
    [2]="foundation"
    [3]="foundation"
    [4]="application"
    [5]="application"
    [6]="application"
    [7]="application"
    [8]="application"
    [9]="application"
    [10]="mastery"
    [11]="mastery"
    [12]="mastery"
    [13]="mastery"
    [14]="mastery"
    [15]="mastery"
    [16]="mastery"
    [17]="mastery"
    [18]="mastery"
    [19]="mastery"
    [20]="mastery"
    [21]="foundation"
    [22]="application"
    [23]="application"
    [24]="mastery"
    [25]="mastery"
    [26]="mastery"
    [27]="mastery"
    [28]="mastery"
    [29]="mastery"
    [30]="mastery"
)

declare -A module_duration=(
    [1]="120"
    [2]="135"
    [3]="150"
    [4]="135"
    [5]="165"
    [6]="150"
    [7]="165"
    [8]="180"
    [9]="165"
    [10]="195"
    [11]="210"
    [12]="225"
    [13]="210"
    [14]="195"
    [15]="225"
    [16]="240"
    [17]="255"
    [18]="240"
    [19]="270"
    [20]="255"
    [21]="180"
    [22]="195"
    [23]="210"
    [24]="225"
    [25]="255"
    [26]="270"
    [27]="255"
    [28]="285"
    [29]="270"
    [30]="300"
)

# Function to get difficulty stars
get_difficulty_stars() {
    case $1 in
        "foundation") echo "⭐" ;;
        "application") echo "⭐⭐" ;;
        "mastery") echo "⭐⭐⭐" ;;
        *) echo "⭐" ;;
    esac
}

# Function to get track display name
get_track_name() {
    case $1 in
        "fundamentals") echo "Fundamentals" ;;
        "intermediate") echo "Intermediate Development" ;;
        "advanced") echo "Advanced Patterns" ;;
        "enterprise") echo "Enterprise Solutions" ;;
        "ai-agents") echo "AI Agents & MCP" ;;
        "mastery") echo "Enterprise Mastery" ;;
        *) echo "General" ;;
    esac
}

# Function to create module directory and files
create_module() {
    local num=$1
    local module_dir="$DOCS_DIR/module-$(printf "%02d" $num)"
    
    # Skip if already exists and user doesn't want to overwrite
    if [ -d "$module_dir" ] && [ $num -ne 1 ]; then
        echo -e "${YELLOW}⚠️  Module $num already exists at $module_dir${NC}"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}⏭️  Skipping Module $num${NC}"
            return
        fi
        rm -rf "$module_dir"
    fi
    
    if [ $num -eq 1 ]; then
        echo -e "${BLUE}📄 Module 1 is the template - skipping${NC}"
        return
    fi
    
    echo -e "${GREEN}📁 Creating Module $num...${NC}"
    
    # Create directory structure
    mkdir -p "$module_dir"
    
    # Get module metadata
    local track=${module_tracks[$num]}
    local title=${module_titles[$num]}
    local description=${module_descriptions[$num]}
    local difficulty=${module_difficulty[$num]}
    local duration=${module_duration[$num]}
    local stars=$(get_difficulty_stars $difficulty)
    local track_name=$(get_track_name $track)
    
    # Create main index.md file
    cat > "$module_dir/index.md" << EOF
---
title: "Module $(printf "%02d" $num): $title"
description: "$description"
sidebar_position: $num
tags: [$track, $difficulty, ai-development]
---

# Module $(printf "%02d" $num): $title

<div className="module-header">
  <span className="module-badge track-$track">Track: $track_name</span>
  <span className="difficulty-badge difficulty-$difficulty">$difficulty: $stars</span>
  <span className="duration-badge">Duration: $duration minutes</span>
</div>

## 🎯 Learning Objectives

By the end of this module, you will:

- [ ] Understand the core concepts and principles of $title
- [ ] Implement practical solutions using AI-powered development tools
- [ ] Apply best practices for $title in real-world scenarios
- [ ] Evaluate and optimize your implementation for production use

## 📋 Prerequisites

**Required:**
- Completion of previous modules in the $track_name track
- Active GitHub Copilot subscription
- Development environment setup (VS Code with extensions)
- Basic understanding of AI-assisted development principles

**Recommended:**
- Familiarity with the technologies covered in this module
- Prior experience with related development patterns
- Understanding of software engineering best practices

## 📚 Module Overview

This module focuses on **$title**, providing comprehensive coverage of:

### 🔍 Core Concepts
- Fundamental principles and theoretical foundation
- Key terminology and concepts
- Industry standards and best practices
- Common patterns and anti-patterns

### 🛠️ Practical Implementation
- Hands-on exercises with progressive difficulty
- Real-world scenarios and use cases
- AI-assisted development techniques
- Code optimization and refactoring

### 🎯 Advanced Applications
- Production-ready implementations
- Performance optimization strategies
- Scalability considerations
- Monitoring and maintenance

## 🚀 Getting Started

### Environment Setup

Before beginning this module, ensure your development environment is properly configured:

1. **Required Tools:**
   - VS Code with GitHub Copilot extension
   - Git for version control
   - Node.js (latest LTS version)
   - Relevant language/framework tools

2. **Optional Tools:**
   - Docker for containerization
   - Cloud CLI tools (Azure, AWS, GCP)
   - Database management tools
   - Testing frameworks

### Module Structure

This module is organized into three progressive exercises:

1. **🛠️ Exercise 1: Foundation** ($stars) - 30-45 minutes
2. **🛠️ Exercise 2: Application** (⭐⭐) - 45-60 minutes  
3. **🛠️ Exercise 3: Mastery** (⭐⭐⭐) - 60-90 minutes

---

## 🛠️ Exercise 1: Foundation ⭐

**Duration**: 30-45 minutes  
**Objective**: Build foundational understanding of $title concepts

### Scenario

You're starting a new project that requires implementation of $title. This exercise will guide you through the fundamental concepts and basic implementation patterns.

### Learning Focus

- Core concept understanding
- Basic implementation patterns
- AI-assisted code generation
- Initial setup and configuration

### Instructions

#### Step 1: Project Setup
1. Create a new project directory
2. Initialize the necessary configuration
3. Set up the basic project structure
4. Configure development tools

#### Step 2: Basic Implementation
1. Implement the core functionality
2. Use GitHub Copilot for code generation
3. Follow established patterns and conventions
4. Add basic error handling

#### Step 3: Testing and Validation
1. Write basic tests for your implementation
2. Validate functionality against requirements
3. Use AI assistance for test generation
4. Document your implementation

### 🎯 Expected Outcomes

- ✅ Basic project structure created and configured
- ✅ Core functionality implemented and working
- ✅ Basic tests written and passing
- ✅ Code documented and commented

### 💡 AI Assistance Tips

- Use Copilot chat to explain complex concepts
- Generate boilerplate code with specific prompts
- Ask for code reviews and suggestions
- Get help with debugging and error resolution

### ✅ Validation Checklist

- [ ] Project initializes without errors
- [ ] Core functionality works as expected
- [ ] Basic tests pass successfully
- [ ] Code follows established conventions
- [ ] Documentation is clear and complete

---

## 🛠️ Exercise 2: Application ⭐⭐

**Duration**: 45-60 minutes  
**Objective**: Apply concepts in real-world scenarios with moderate complexity

### Scenario

Building on the foundation from Exercise 1, you'll now implement a more complex, real-world application that demonstrates practical use of $title concepts.

### Learning Focus

- Integration with other systems
- Error handling and edge cases
- Performance considerations
- Real-world application patterns

### Instructions

#### Step 1: Requirements Analysis
1. Analyze the provided requirements
2. Design the solution architecture
3. Identify integration points
4. Plan the implementation approach

#### Step 2: Enhanced Implementation
1. Extend the basic implementation from Exercise 1
2. Add advanced features and functionality
3. Implement proper error handling
4. Optimize for performance

#### Step 3: Integration and Testing
1. Integrate with external systems or APIs
2. Write comprehensive tests
3. Perform integration testing
4. Document the enhanced functionality

### 🎯 Expected Outcomes

- ✅ Enhanced application with advanced features
- ✅ Proper integration with external systems
- ✅ Comprehensive error handling implemented
- ✅ Performance optimized and tested

### 💡 Advanced Techniques

- Use AI for architectural decisions
- Generate integration code patterns
- Optimize code with AI suggestions
- Create comprehensive test suites

### ✅ Validation Checklist

- [ ] Advanced features implemented and working
- [ ] Integration points functioning correctly
- [ ] Error handling covers edge cases
- [ ] Performance meets requirements
- [ ] Tests cover critical functionality

---

## 🛠️ Exercise 3: Mastery ⭐⭐⭐

**Duration**: 60-90 minutes  
**Objective**: Create production-ready, optimized implementation

### Scenario

You're tasked with creating a production-ready system that showcases mastery of $title concepts. This implementation should be scalable, maintainable, and ready for enterprise deployment.

### Learning Focus

- Production-ready code quality
- Scalability and performance optimization
- Security considerations
- Monitoring and observability
- Deployment strategies

### Instructions

#### Step 1: Architecture Design
1. Design a scalable, production-ready architecture
2. Consider security implications
3. Plan for monitoring and observability
4. Design for maintainability and extensibility

#### Step 2: Production Implementation
1. Implement the complete solution
2. Add comprehensive logging and monitoring
3. Implement security best practices
4. Optimize for production performance

#### Step 3: Deployment and Operations
1. Create deployment scripts and configuration
2. Set up monitoring and alerting
3. Implement backup and recovery procedures
4. Document operational procedures

### 🎯 Expected Outcomes

- ✅ Production-ready, scalable implementation
- ✅ Comprehensive monitoring and logging
- ✅ Security best practices implemented
- ✅ Complete deployment and operations documentation

### 🏆 Mastery Indicators

- Code quality suitable for production deployment
- Performance optimized for scale
- Security considerations fully addressed
- Operational excellence demonstrated

### ✅ Validation Checklist

- [ ] Code passes all quality gates
- [ ] Performance benchmarks met
- [ ] Security review completed
- [ ] Monitoring and alerting configured
- [ ] Deployment documentation complete
- [ ] Operational runbooks created

---

## 🔧 Troubleshooting Guide

### Common Issues

#### Issue 1: Setup Problems
**Problem**: Difficulty with initial environment setup  
**Solution**: Verify all prerequisites are installed and properly configured

#### Issue 2: Integration Failures
**Problem**: Issues connecting to external systems  
**Solution**: Check network connectivity, credentials, and API compatibility

#### Issue 3: Performance Issues
**Problem**: Application performance below expectations  
**Solution**: Profile the application, identify bottlenecks, optimize critical paths

### Getting Help

- **GitHub Copilot Chat**: Ask for specific help with code issues
- **Community Forums**: Discuss complex problems with peers
- **Documentation**: Refer to official documentation for detailed guidance
- **Support Channels**: Use designated support channels for critical issues

---

## 📊 Assessment & Validation

### Self-Assessment Questions

1. Can you explain the core concepts of $title clearly?
2. Are you confident implementing these concepts in real projects?
3. Can you identify and resolve common issues independently?
4. Do you understand the production considerations?

### Practical Validation

- Complete all three exercises successfully
- Demonstrate understanding through working implementations
- Show ability to troubleshoot and resolve issues
- Apply concepts to novel scenarios

### Knowledge Check

Test your understanding with these concepts:
- [ ] Core principles and patterns
- [ ] Integration strategies
- [ ] Performance optimization
- [ ] Security considerations
- [ ] Operational excellence

---

## 🎯 Next Steps

### Immediate Actions
1. Review and refactor your exercise implementations
2. Explore additional resources and documentation
3. Practice concepts in personal projects
4. Share learnings with the community

### Advanced Learning
- Explore advanced patterns and techniques
- Study related technologies and frameworks
- Contribute to open-source projects
- Attend relevant conferences and workshops

### Career Development
- Add new skills to your professional profile
- Apply concepts in current work projects
- Mentor others learning these concepts
- Consider specialization opportunities

---

## 📚 Additional Resources

### Official Documentation
- [Technology specific documentation links]
- [Framework guides and tutorials]
- [Best practices and patterns]

### Community Resources
- [Relevant GitHub repositories]
- [Community forums and discussions]
- [Blog posts and articles]

### Learning Materials
- [Recommended books and courses]
- [Video tutorials and workshops]
- [Practice exercises and challenges]

---

**Module Complete!** 🎉

You've successfully completed Module $(printf "%02d" $num): $title. The knowledge and skills gained here will serve as a foundation for more advanced topics in subsequent modules.

**Continue Learning**: Proceed to [Module $(printf "%02d" $((num + 1)))](../module-$(printf "%02d" $((num + 1)))/) or explore other modules in the $track_name track.
EOF

    echo -e "${GREEN}✅ Module $num created successfully${NC}"
}

# Main execution
echo -e "${YELLOW}📋 This script will create modules 2-30 based on the Module 01 template${NC}"
echo -e "${YELLOW}📋 Each module will have customized content based on its track and difficulty${NC}"
echo

read -p "Continue? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo -e "${BLUE}❌ Operation cancelled${NC}"
    exit 0
fi

echo -e "${GREEN}🚀 Starting module generation...${NC}"
echo

# Create modules 2-30
for i in {2..30}; do
    create_module $i
    echo
done

echo -e "${GREEN}🎉 Module generation completed!${NC}"
echo -e "${BLUE}📁 Created modules in: $DOCS_DIR${NC}"
echo
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo -e "${YELLOW}   1. Update sidebars.ts to include all modules${NC}"
echo -e "${YELLOW}   2. Review and customize individual module content${NC}"
echo -e "${YELLOW}   3. Test the site with: npm start${NC}"
echo -e "${YELLOW}   4. Build for production: npm run build${NC}"
echo
echo -e "${GREEN}✅ All modules are ready for customization!${NC}"
