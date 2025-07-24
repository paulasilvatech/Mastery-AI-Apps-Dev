---
sidebar_position: 1
title: "Module 06: Multi-File Projects and Workspaces"
description: "## 🎯 Module Overview"
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Module 06: Multi-File Projects and Workspaces

<div className="module-header">
  <div className="module-info">
    <span className="difficulty-badge intermediate">🔵 Intermediate</span>
    <span className="duration-badge">⏱️ 3 hours</span>
  </div>
</div>

# Module 06: Multi-File Projects and Workspaces

## 🎯 Module Overview

Welcome to Module 06! This module marks your transition from single-file development to managing complex, multi-file projects with GitHub Copilot. You'll learn how to leverage workspace-level AI features, manage context across multiple files, and use advanced Copilot capabilities for real-world application development.

## 📋 Learning Objectives

By the end of this module, you will:

1. **Master workspace-level context management** with GitHub Copilot
2. **Navigate multi-file editing** using Chat, Edit, and Agent modes
3. **Optimize AI suggestions** across project boundaries
4. **Structure projects** for maximum AI assistance effectiveness
5. **Implement cross-file refactoring** with AI guidance
6. **Build a complete multi-component application** using workspace features

## ⏱️ Time Commitment

- **Total Duration**: 3 hours
- **Lecture/Concepts**: 30 minutes
- **Hands-on Exercises**: 2 hours
- **Best Practices Review**: 30 minutes

## 🚀 What You'll Build

Throughout this module, you'll create:

1. **Task Management System** (Exercise 1 - Easy)
   - Multi-file Python application
   - Separate concerns with modules
   - Basic workspace navigation

2. **E-Commerce Microservice** (Exercise 2 - Medium)
   - RESTful API with multiple components
   - Database models and migrations
   - Service layer architecture

3. **Real-time Collaboration Platform** (Exercise 3 - Hard)
   - Complex multi-component system
   - WebSocket integration
   - Frontend-backend coordination

## 🛠️ Key Technologies

- **GitHub Copilot Features**:
  - `@workspace` context
  - Multi-file editing (Edit mode)
  - Agent mode for complex tasks
  - Cross-file navigation
  
- **Development Stack**:
  - Python 3.11+
  - FastAPI/Flask
  - SQLAlchemy
  - pytest
  - Optional: TypeScript/React for Exercise 3

## 📚 Module Structure

```
module-06-multi-file-projects/
├── README.md                    # This file
├── prerequisites.md             # Setup requirements
├── exercises/
│   ├── exercise1-easy/         # Task Management System
│   │   ├── instructions/
│   │   ├── starter/
│   │   ├── solution/
│   │   └── tests/
│   ├── exercise2-medium/       # E-Commerce Microservice
│   │   ├── instructions/
│   │   ├── starter/
│   │   ├── solution/
│   │   └── tests/
│   └── exercise3-hard/         # Collaboration Platform
│       ├── instructions/
│       ├── starter/
│       ├── solution/
│       └── tests/
├── best-practices.md           # Production patterns
├── resources/                  # Additional materials
│   ├── workspace-tips.md
│   ├── project-templates/
│   └── context-strategies.md
└── troubleshooting.md         # Common issues
```

## 🎓 Prerequisites

Before starting this module, ensure you have:

- ✅ Completed Modules 1-5
- ✅ GitHub Copilot extension installed and active
- ✅ VS Code with workspace features enabled
- ✅ Python 3.11+ environment set up
- ✅ Basic understanding of project structure patterns

See [prerequisites.md](./prerequisites) for detailed setup instructions.

## 🔑 Key Concepts

### 1. Workspace Context Management

```python
# Using @workspace to search across all files
# Type in Copilot Chat: "@workspace find all database models"

# Copilot will search through your entire project
# and provide relevant context from multiple files
```

### 2. Multi-File Editing Modes

- **Chat Mode**: Ask questions about your codebase
- **Edit Mode**: Developer-led multi-file modifications
- **Agent Mode**: Copilot-led complex transformations

### 3. Context Optimization Strategies

- Keep related files open in tabs
- Use meaningful file and folder names
- Leverage `.copilot` instructions
- Strategic use of comments for context

## 💡 Quick Tips

1. **Start Small**: Begin with Exercise 1 to understand workspace basics
2. **Use @workspace**: This is your power tool for multi-file context
3. **Organize Well**: Good project structure = better AI suggestions
4. **Iterate**: Don't expect perfect results on first try
5. **Review Generated Code**: Always validate cross-file changes

## 📊 Success Metrics

You'll know you've mastered this module when you can:

- [ ] Navigate a 10+ file project efficiently with Copilot
- [ ] Use all three Copilot modes (Chat, Edit, Agent) effectively
- [ ] Refactor code across multiple files simultaneously
- [ ] Manage context to get relevant suggestions
- [ ] Build a complete application using workspace features

## 🚦 Getting Started

1. **Set up your environment**:
   ```bash
   cd exercises/exercise1-easy
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

2. **Open the workspace**:
   ```bash
   code .
   ```

3. **Start with Exercise 1** and progress through each challenge

## 🤝 Community and Support

- **GitHub Discussions**: Share your multi-file project strategies
- **Issues**: Report problems or suggest improvements
- **Show & Tell**: Share your completed projects

## 📈 Next Steps

After completing this module, you'll be ready for:
- **Module 07**: Building Web Applications with AI
- **Module 08**: API Development and Integration
- **Module 09**: Database Design and Optimization

---

**Remember**: Multi-file projects are where Copilot truly shines. The more context you provide, the better the suggestions. Happy coding! 🚀