[🏠 Workshop](../../README.md) > [📚 Modules](../README.md) > [Module 6](README.md)

<div align="center">

[⬅️ Module 05: Documentation and Code Quality](../module-05/README.md) | **📖 Module 6: Multi-File Projects and Workspaces** | [Module 07: Building Web Applications with AI ➡️](../module-07/README.md)

</div>

---

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

See [prerequisites.md](./prerequisites.md) for detailed setup instructions.

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

