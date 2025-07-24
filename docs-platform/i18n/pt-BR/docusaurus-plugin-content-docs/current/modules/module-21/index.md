---
sidebar_position: 1
title: "Module 21: Introduction to AI Agents"
description: "## 🎯 Module Overview"
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Módulo 21: Introdução to AI Agents

<div className="module-header">
  <div className="module-info">
    <span className="difficulty-badge ai-agents">🟣 AI Agents</span>
    <span className="duration-badge">⏱️ 3 hours</span>
  </div>
</div>

# Módulo 21: Introdução to AI Agents

## 🎯 Visão Geral do Módulo

Welcome to Módulo 21! This module marks the beginning of the AI Agents & MCP Trilha, where you'll dive deep into the world of AI agents. You'll understand agent architectures, master GitHub Copilot agent features, and create your first autonomous agents that can perform complex tasks independently.

### Duração
- **Tempo Total**: 3 horas
- **Lecture/Demo**: 45 minutos
- **Hands-on Exercícios**: 2 horas 15 minutos

### Trilha
- 🟣 AI Agents & MCP Trilha (Módulos 21-25)

## 🎓 Objetivos de Aprendizagem

Ao final deste módulo, você será capaz de:

1. **Understand Agent Architectures** - Master different agent patterns and their use cases
2. **Master GitHub Copilot Agents** - Leverage Copilot's agent capabilities effectively
3. **Create Simple Autonomous Agents** - Build agents that can work independently
4. **Implement Tool-Calling Patterns** - Enable agents to use external tools and APIs
5. **Design Agent Communication Flows** - Create effective agent interaction patterns

## 🔧 Pré-requisitos

- ✅ Completard Módulos 1-20
- ✅ Strong Python programming skills
- ✅ Understanding of async programming concepts
- ✅ Experience with REST APIs
- ✅ GitHub Copilot assinatura active
- ✅ Azure assinatura with AI services enabled

See [prerequisites.md](prerequisites.md) for detailed setup instructions.

## 📚 Conceitos-Chave

### What are AI Agents?

AI Agents are autonomous systems that can:
- **Perceive**: Understand their ambiente and context
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
    
    A --&gt; E
    B --&gt; F
    C --&gt; F
    D --&gt; H
    F --&gt; G
    G --&gt; I
    G --&gt; J
    G --&gt; K
    
    style A fill:#4CAF50
    style B fill:#2196F3
    style C fill:#FF9800
    style D fill:#9C27B0
```

## 🚀 What You'll Build

In this module, you'll create:
1. **Copilot Agent Extension** - Enhance GitHub Copilot with custom capabilities
2. **Code Revisar Agent** - Automated code analysis with custom rules
3. **Refactoring Agent** - Multi-step code transformation agent

## 📊 Módulo Recursos

- **Documentação**: [GitHub Copilot Agents](https://docs.github.com/copilot/agents)
- **Azure AI**: [Azure AI Agent Service](https://learn.microsoft.com/azure/ai-services/agents)
- **Semantic Kernel**: [Agent Framework](https://learn.microsoft.com/semantic-kernel)
- **Video Tutorial**: [Módulo 21 Walkthrough](https://workshop.com/module-21)

## ⏭️ Próximos Passos

After completing this module, you'll be ready for:
- **Módulo 22**: Building Custom Agents
- **Módulo 23**: Model Context Protocol (MCP)

Let's begin your journey into the fascinating world of AI agents!