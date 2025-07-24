---
sidebar_position: 1
title: "Module 07: Building Web Applications with AI"
description: "## 🎯 Overview"
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Módulo 07: Building Web Applications with AI

<div className="module-header">
  <div className="module-info">
    <span className="difficulty-badge intermediate">🔵 Intermediate</span>
    <span className="duration-badge">⏱️ 3 hours</span>
  </div>
</div>

# Módulo 07: Building Web Applications with AI

## 🎯 Visão Geral

Learn to build full-stack web applications rapidly using GitHub Copilot in GitHub Codespaces. Zero setup required - just click and code!

**Duração:** 3 horas  
**Level:** Intermediário  
**Pré-requisitos:** Completard Módulos 1-6

## 🚀 Quick Start

1. **Fork this repository** to your GitHub conta
2. **Click the green "Code" button** → "Create codespace on main"
3. **Wait 2-3 minutos** for ambiente setup
4. **You're ready to code!** Everything is pre-configurado

## 📋 What You'll Build

### Exercício 1: Rapid Todo App (45 minutos)
Build a functional todo application showcasing Copilot's speed
- React + Vite frontend
- FastAPI backend
- SQLite database
- Real-time updates

### Exercício 2: Smart Notes Platform (60 minutos)
Create an intelligent note-taking app with advanced features
- Markdown editor with preview
- Auto-tagging system
- Full-text search
- Local persistence

### Exercício 3: AI Recipe Assistant (60 minutos)
Develop an AI-powered recipe platform
- AbrirAI integration
- Recipe generation from ingredients
- Image upload
- Smart suggestions

## 🏗️ Architecture Visão Geral

```mermaid
graph TB
    subgraph "GitHub Codespaces Environment"
        A[VS Code Browser] --&gt; B[GitHub Copilot]
        B --&gt; C[Your Code]
        
        subgraph "Exercise 1: Todo App"
            D[React Frontend<br/>Port: 5173] --&gt; E[FastAPI Backend<br/>Port: 8000]
            E --&gt; F[SQLite DB]
        end
        
        subgraph "Exercise 2: Notes App"
            G[React + Markdown] --&gt; H[LocalStorage]
            G --&gt; I[Search Engine]
        end
        
        subgraph "Exercise 3: Recipe AI"
            J[React Frontend] --&gt; K[FastAPI + OpenAI]
            K --&gt; L[Recipe Generation]
            K --&gt; M[Image Storage]
        end
    end
    
    style A fill:#f9f,stroke:#333,stroke-width:4px
    style B fill:#bbf,stroke:#333,stroke-width:2px
```

## 📁 Repository Structure

```
module-07-web-applications/
├── README.md                    # This file
├── .devcontainer/              # Codespaces configuration
│   └── devcontainer.json       # Pre-configured environment
├── exercises/
│   ├── exercise-1-todo/        # Todo app exercise
│   │   ├── README.md           # Instructions
│   │   ├── starter/            # Starting code
│   │   └── solution/           # Complete solution
│   ├── exercise-2-notes/       # Notes app exercise
│   │   ├── README.md
│   │   ├── starter/
│   │   └── solution/
│   └── exercise-3-recipes/     # Recipe AI exercise
│       ├── README.md
│       ├── starter/
│       └── solution/
├── docs/
│   ├── best-practices.md       # Production patterns
│   └── troubleshooting.md      # Common issues
└── resources/
    └── copilot-prompts.md      # Effective prompts
```

## 🎯 Caminho de Aprendizagem

```mermaid
flowchart LR
    A[Start Module] --&gt; B{Setup Complete?}
    B --&gt;|Yes| C[Exercise 1: Todo App]
    B --&gt;|No| D[Create Codespace]
    D --&gt; C
    
    C --&gt; E[Learn: Rapid Prototyping]
    E --&gt; F[Exercise 2: Notes App]
    
    F --&gt; G[Learn: Smart Features]
    G --&gt; H[Exercise 3: Recipe AI]
    
    H --&gt; I[Learn: AI Integration]
    I --&gt; J[Module Complete!]
    
    style A fill:#e1f5fe
    style J fill:#c8e6c9
    style C fill:#fff3e0
    style F fill:#fff3e0
    style H fill:#fff3e0
```

## 💻 Working in Codespaces

### Ports & URLs
When you run services, Codespaces automatically forwards ports:
- **Frontend (5173)**: Click the popup or check PORTS tab
- **Voltarend (8000)**: Available at `/api` through proxy
- **All ports**: Visible in the PORTS tab in VS Code

### Terminal Layout
Split terminals for better workflow:
```bash
# Terminal 1: Frontend
cd exercises/exercise-1-todo/starter/frontend
npm run dev

# Terminal 2: Backend
cd exercises/exercise-1-todo/starter/backend
uvicorn main:app --reload

# Terminal 3: General commands
# Keep free for git, testing, etc.
```

## 🤖 GitHub Copilot Tips

### Effective Prompting
```javascript
// 🎯 Be specific with comments
// Create a React component that displays a todo item with:
// - Checkbox to mark complete (strikethrough when checked)
// - Delete button with trash icon
// - Edit mode on double-click
// - Tailwind styling with hover effects

// 💡 Copilot will generate the entire component!
```

### Quick Patterns
1. **Component Generation**: Describe UI in comments
2. **API Creation**: Specify endpoints and data structure
3. **Styling**: Mention Tailwind classes wanted
4. **Logic**: Explain business rules clearly

## 📊 Success Metrics

Trilha your progress:

- [ ] Exercício 1 completed in 45 minutos
- [ ] Exercício 2 completed in 60 minutos  
- [ ] Exercício 3 completed in 60 minutos
- [ ] Used Copilot for 70%+ of code
- [ ] All apps running successfully
- [ ] Deployed at least one app

## 🚢 implantação Options

From Codespaces, deploy directly to:
- **Vercel**: Frontend apps (React)
- **Railway**: Voltarend APIs (FastAPI)
- **Netlify**: Static sites
- **GitHub Pages**: Simple demos

## 🆘 Getting Ajuda

1. **Verificar troubleshooting guide**: `docs/troubleshooting.md`
2. **Revisar solutions**: Compare with solution folders
3. **GitHub Discussions**: Ask questions in repo discussions
4. **Copilot Chat**: Use for debugging help

## ⏭️ Próximos Passos

After completing this module:
1. Enhance your apps with additional features
2. Combine exercises into one mega-app
3. Proceed to Módulo 08: API Development
4. Compartilhar your creations!

---

**Remember**: The goal is rapid development. Let Copilot handle the boilerplate while you focus on features. Happy coding! 🚀