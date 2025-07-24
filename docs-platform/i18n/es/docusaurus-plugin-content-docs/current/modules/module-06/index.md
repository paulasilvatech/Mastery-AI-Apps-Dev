---
sidebar_position: 1
title: "Module 06: Multi-File Projects and Workspaces"
description: "## 🎯 Module Overview"
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Módulo 06: Multi-File Proyectos and Workspaces

<div className="module-header">
  <div className="module-info">
    <span className="difficulty-badge intermediate">🔵 Intermediate</span>
    <span className="duration-badge">⏱️ 3 hours</span>
  </div>
</div>

# Módulo 06: Multi-File Proyectos and Workspaces

## 🎯 Resumen del Módulo

Welcome to Módulo 06! This module marks your transition from single-file desarrollo to managing complex, multi-file projects with GitHub Copilot. You'll learn how to leverage workspace-level AI features, manage context across multiple files, and use advanced Copilot capabilities for real-world application desarrollo.

## 📋 Objetivos de Aprendizaje

By the end of this module, you will:

1. **Master workspace-level context management** with GitHub Copilot
2. **Navigate multi-file editing** using Chat, Editar, and Agent modes
3. **Optimize AI suggestions** across project boundaries
4. **Structure projects** for maximum AI assistance effectiveness
5. **Implement cross-file refactoring** with AI guidance
6. **Build a complete multi-component application** using workspace features

## ⏱️ Time Commitment

- **Total Duración**: 3 horas
- **Lecture/Concepts**: 30 minutos
- **Hands-on Ejercicios**: 2 horas
- **Mejores Prácticas Revisar**: 30 minutos

## 🚀 What You'll Build

Throughout this module, you'll create:

1. **Task Management System** (Ejercicio 1 - Fácil)
   - Multi-file Python application
   - Separate concerns with modules
   - Basic workspace navigation

2. **E-Commerce Microservice** (Ejercicio 2 - Medio)
   - RESTful API with multiple components
   - Database models and migrations
   - Service layer architecture

3. **Real-time Collaboration Platform** (Ejercicio 3 - Difícil)
   - Complex multi-component system
   - WebSocket integration
   - Frontend-backend coordination

## 🛠️ Key Technologies

- **GitHub Copilot Features**:
  - `@workspace` context
  - Multi-file editing (Editar mode)
  - Agent mode for complex tasks
  - Cross-file navigation
  
- **Development Stack**:
  - Python 3.11+
  - FastAPI/Flask
  - SQLAlchemy
  - pytest
  - Optional: TypeScript/React for Ejercicio 3

## 📚 Módulo Structure

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

## 🎓 Prerrequisitos

Before starting this module, ensure you have:

- ✅ Completard Módulos 1-5
- ✅ GitHub Copilot extension instalado and active
- ✅ VS Code with workspace features enabled
- ✅ Python 3.11+ ambiente set up
- ✅ Basic understanding of project structure patterns

See [prerequisites.md](./prerequisites) for detailed setup instructions.

## 🔑 Conceptos Clave

### 1. Workspace Context Management

```python
# Using @workspace to search across all files
# Type in Copilot Chat: "@workspace find all database models"

# Copilot will search through your entire project
# and provide relevant context from multiple files
```

### 2. Multi-File Editaring Modes

- **Chat Mode**: Ask questions about your codebase
- **Editar Mode**: Developer-led multi-file modifications
- **Agent Mode**: Copilot-led complex transformations

### 3. Context Optimization Strategies

- Keep related files open in tabs
- Use meaningful file and folder names
- Leverage `.copilot` instructions
- Strategic use of comments for context

## 💡 Quick Tips

1. **Start Small**: Comience con Ejercicio 1 to understand workspace basics
2. **Use @workspace**: This is your power tool for multi-file context
3. **Organize Well**: Good project structure = better AI suggestions
4. **Iterate**: Don't expect perfect results on first try
5. **Revisar Generated Code**: Always validate cross-file changes

## 📊 Success Metrics

You'll know you've mastered this module when you can:

- [ ] Navigate a 10+ file project efficiently with Copilot
- [ ] Use all three Copilot modes (Chat, Editar, Agent) effectively
- [ ] Refactor code across multiple files simultaneously
- [ ] Manage context to get relevant suggestions
- [ ] Build a complete application using workspace features

## 🚦 Comenzando

1. **Set up your ambiente**:
   ```bash
   cd exercises/exercise1-easy
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

2. **Abrir the workspace**:
   ```bash
   code .
   ```

3. **Comience con Ejercicio 1** and progress through each challenge

## 🤝 Community and Support

- **GitHub Discussions**: Compartir your multi-file project strategies
- **Issues**: Report problems or suggest improvements
- **Show & Tell**: Compartir your completed projects

## 📈 Próximos Pasos

After completing this module, you'll be ready for:
- **Módulo 07**: Building Web Applications with AI
- **Módulo 08**: API Development and Integration
- **Módulo 09**: Database Design and Optimization

---

**Remember**: Multi-file projects are where Copilot truly shines. The more context you provide, the better the suggestions. Happy coding! 🚀