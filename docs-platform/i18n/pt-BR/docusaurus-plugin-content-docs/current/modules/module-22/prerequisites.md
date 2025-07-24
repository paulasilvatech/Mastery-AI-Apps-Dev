---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 22"
---

# Pré-requisitos for Módulo 22: Building Custom Agents

## 🎯 Required Knowledge

Before starting this module, ensure you have:

### From Módulo 21
- ✅ **Agent Fundamentos**: Base agent class implementation
- ✅ **Tool Calling**: Experience with agent-tool integration
- ✅ **Error Handling**: Basic agent error management
- ✅ **Testing Agents**: Unit and integration testing

### Avançado Python Skills
- ✅ **Design Patterns**: Factory, Strategy, Observer, State
- ✅ **Async/Await**: Avançado asyncio patterns
- ✅ **Type System**: Generic types, protocols, type vars
- ✅ **Memory Management**: Understanding of Python memory model

### Software Architecture
- ✅ **State Management**: Finite state machines, state patterns
- ✅ **Event-Driven Architecture**: Pub/sub, event sourcing
- ✅ **Domain-Driven Design**: Bounded contexts, aggregates
- ✅ **SOLID Principles**: Applied to agent design

## 🛠️ Ferramentas Necessárias

### desenvolvimento ambiente
```bash
# Verify Python version
python --version  # Must be 3.11 or higher

# Verify Node.js (for some integrations)
node --version    # Should be 18.0 or higher

# Verify Docker
docker --version  # For containerized agents
```

### Python Packages
```bash
# Create and activate virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install required packages
pip install -r requirements.txt
```

**requirements.txt**:
```txt
# Core agent frameworks
semantic-kernel>=0.9.0
langchain>=0.1.0
autogen>=0.2.0
crewai>=0.1.0

# State management
transitions>=0.9.0
pydantic>=2.5.0
redis>=5.0.0

# Memory systems
chromadb>=0.4.0
faiss-cpu>=1.7.4
numpy>=1.24.0

# Tool development
httpx>=0.25.0
aiofiles>=23.0.0
jinja2>=3.1.0
sqlalchemy>=2.0.0

# Async utilities
asyncio>=3.11.0
aiohttp>=3.9.0
aiodns>=3.1.0

# Testing
pytest>=7.4.0
pytest-asyncio>=0.21.0
pytest-mock>=3.12.0
pytest-benchmark>=4.0.0

# Monitoring
opentelemetry-api>=1.21.0
opentelemetry-sdk>=1.21.0
prometheus-client>=0.19.0

# Development
black>=23.0.0
mypy>=1.7.0
ruff>=0.1.0
rich>=13.7.0
```

### VS Code Extensions
Ensure these extensions are instalado:
- ✅ GitHub Copilot
- ✅ GitHub Copilot Chat
- ✅ Python
- ✅ Pylance
- ✅ Python Test Explorer
- ✅ Docker
- ✅ Remote - Containers
- ✅ Thunder Client (API testing)

### Infrastructure Requirements
```bash
# Docker for containerization
docker pull python:3.11-slim
docker pull redis:7-alpine
docker pull postgres:16-alpine

# Optional: Local LLM for testing
# docker pull ollama/ollama
```

## 📋 Pre-Módulo Setup

### 1. Clone Módulo Repository
```bash
git clone https://github.com/workshop/module-22-custom-agents.git
cd module-22-custom-agents
```

### 2. Configurar Databases
```bash
# Start Redis for state management
docker run -d --name redis-agents -p 6379:6379 redis:7-alpine

# Start PostgreSQL for persistent storage
docker run -d --name postgres-agents \
  -e POSTGRES_PASSWORD=agentpass \
  -e POSTGRES_DB=agents \
  -p 5432:5432 \
  postgres:16-alpine
```

### 3. Configure ambiente
```bash
# Copy environment template
cp .env.example .env

# Edit .env with your values
# Required variables:
# - OPENAI_API_KEY
# - AZURE_OPENAI_ENDPOINT (optional)
# - REDIS_URL=redis://localhost:6379
# - DATABASE_URL=postgresql://postgres:agentpass@localhost:5432/agents
```

### 4. Validate Setup
```bash
# Run validation script
python scripts/validate-module-22.py
```

Expected output:
```
✅ Python version: 3.11.6
✅ All packages installed correctly
✅ Redis connection successful
✅ PostgreSQL connection successful
✅ Agent frameworks available
✅ VS Code extensions detected
✅ Ready for Module 22!
```

## 🧪 Test Your Knowledge

Before starting, you should be able to:

### 1. Implement a Basic State Machine
```python
from enum import Enum
from typing import Dict, List, Callable

class AgentState(Enum):
    IDLE = "idle"
    PROCESSING = "processing"
    WAITING = "waiting"
    ERROR = "error"

class StateMachine:
    def __init__(self):
        self.state = AgentState.IDLE
        self.transitions: Dict[AgentState, List[AgentState]] = {
            AgentState.IDLE: [AgentState.PROCESSING],
            AgentState.PROCESSING: [AgentState.WAITING, AgentState.ERROR],
            AgentState.WAITING: [AgentState.IDLE, AgentState.ERROR],
            AgentState.ERROR: [AgentState.IDLE]
        }
    
    def transition_to(self, new_state: AgentState) -&gt; bool:
        if new_state in self.transitions.get(self.state, []):
            self.state = new_state
            return True
        return False
```

### 2. Create an Async Context Manager
```python
class AgentContext:
    async def __aenter__(self):
        await self.initialize()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.cleanup()
        if exc_type:
            await self.handle_error(exc_val)
    
    async def initialize(self):
        # Setup resources
        pass
    
    async def cleanup(self):
        # Clean up resources
        pass
```

### 3. Implement a Simple Memory System
```python
from collections import deque
from datetime import datetime
from typing import Any, Optional

class MemorySystem:
    def __init__(self, capacity: int = 1000):
        self.short_term = deque(maxlen=100)
        self.long_term = {}
        self.capacity = capacity
    
    def store(self, key: str, value: Any, ttl: Optional[int] = None):
        entry = {
            "value": value,
            "timestamp": datetime.now(),
            "ttl": ttl,
            "access_count": 0
        }
        self.long_term[key] = entry
    
    def retrieve(self, key: str) -&gt; Optional[Any]:
        if key in self.long_term:
            entry = self.long_term[key]
            entry["access_count"] += 1
            return entry["value"]
        return None
```

## 🚨 Common Setup Issues

### Issue: Package Versão Conflicts
```bash
# Solution: Use virtual environment
python -m venv venv_module22
source venv_module22/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### Issue: Redis Connection Failed
```bash
# Check if Redis is running
docker ps | grep redis

# If not running, start it
docker start redis-agents

# Test connection
python -c "import redis; r = redis.Redis(); print(r.ping())"
```

### Issue: Import Errors with Frameworks
```bash
# Reinstall specific framework
pip uninstall semantic-kernel langchain
pip install semantic-kernel langchain --no-cache-dir
```

## 📚 Recommended Pre-Reading

1. **State Management Patterns**
   - [Finite State Machines in Python](https://github.com/pytransitions/transitions)
   - [State Pattern Implementation](https://refactoring.guru/design-patterns/state)

2. **Memory Systems**
   - [Building AI Memory](https://www.pinecone.io/learn/vector-database/)
   - [Episodic Memory for Agents](https://arxiv.org/abs/2303.11366)

3. **Agent Frameworks**
   - [Semantic Kernel Agents](https://learn.microsoft.com/semantic-kernel/agents/)
   - [LangChain Agent Types](https://python.langchain.com/docs/modules/agents/agent_types/)

## ✅ Pre-Módulo Verificarlist

Before starting the exercises:

- [ ] Módulo 21 completed successfully
- [ ] Python ambiente set up
- [ ] All packages instalado
- [ ] Docker services running
- [ ] Environment variables configurado
- [ ] Validation script passes
- [ ] Comfortable with async programming
- [ ] Understanding of state machines
- [ ] Basic memory management concepts clear

## 🎯 Ready to Start?

Once all prerequisites are met:
1. Revisar the module overview in [README.md](./index)
2. Comece com [Exercício 1: Documentação Generation Agent](./exercise1-overview)
3. Progress through all three exercises
4. Build your custom agent in the independent project

---

**Need Help?** Check the [Module 22 Troubleshooting Guide](/docs/guias/troubleshooting) or post in GitHub Discussions.