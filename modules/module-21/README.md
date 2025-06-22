# Module 21: Introduction to AI Agents

## 🎯 Module Overview

Welcome to Module 21! This module marks the beginning of the AI Agents & MCP Track, where you'll dive deep into the world of AI agents. You'll understand agent architectures, master GitHub Copilot agent features, and create your first autonomous agents that can perform complex tasks independently.

### Duration
- **Total Time**: 3 hours
- **Lecture/Demo**: 45 minutes
- **Hands-on Exercises**: 2 hours 15 minutes

### Track
- 🟣 AI Agents & MCP Track (Modules 21-25)

## 🎓 Learning Objectives

By the end of this module, you will be able to:

1. **Understand Agent Architectures** - Master different agent patterns and their use cases
2. **Master GitHub Copilot Agents** - Leverage Copilot's agent capabilities effectively
3. **Create Simple Autonomous Agents** - Build agents that can work independently
4. **Implement Tool-Calling Patterns** - Enable agents to use external tools and APIs
5. **Design Agent Communication Flows** - Create effective agent interaction patterns

## 🔧 Prerequisites

- ✅ Completed Modules 1-20
- ✅ Strong Python programming skills
- ✅ Understanding of async programming concepts
- ✅ Experience with REST APIs
- ✅ GitHub Copilot subscription active
- ✅ Azure subscription with AI services enabled

See [prerequisites.md](prerequisites.md) for detailed setup instructions.

## 📚 Key Concepts

### What are AI Agents?

AI Agents are autonomous systems that can:
- **Perceive**: Understand their environment and context
- **Reason**: Make decisions based on goals and constraints
- **Act**: Execute actions to achieve objectives
- **Learn**: Improve performance over time

### Agent Architecture Patterns

```mermaid
graph TB
    subgraph "Agent Types"
        A[Reactive Agent]
        B[Goal-Based Agent]
        C[Utility-Based Agent]
        D[Learning Agent]
    end
    
    subgraph "Components"
        E[Perception]
        F[Decision Making]
        G[Action Execution]
        H[Memory/State]
    end
    
    subgraph "Tools & APIs"
        I[GitHub APIs]
        J[Azure Services]
        K[External Tools]
    end
    
    A --> E
    B --> F
    C --> F
    D --> H
    F --> G
    G --> I
    G --> J
    G --> K
    
    style A fill:#4CAF50
    style B fill:#2196F3
    style C fill:#FF9800
    style D fill:#9C27B0
```

## 🚀 What You'll Build

In this module, you'll create:
1. **Copilot Agent Extension** - Enhance GitHub Copilot with custom capabilities
2. **Code Review Agent** - Automated code analysis with custom rules
3. **Refactoring Agent** - Multi-step code transformation agent

## 📊 Module Resources

- **Documentation**: [GitHub Copilot Agents](https://docs.github.com/copilot/agents)
- **Azure AI**: [Azure AI Agent Service](https://learn.microsoft.com/azure/ai-services/agents)
- **Semantic Kernel**: [Agent Framework](https://learn.microsoft.com/semantic-kernel)
- **Video Tutorial**: [Module 21 Walkthrough](https://workshop.com/module-21)

## ⏭️ Next Steps

After completing this module, you'll be ready for:
- **Module 22**: Building Custom Agents
- **Module 23**: Model Context Protocol (MCP)

Let's begin your journey into the fascinating world of AI agents!
