# 📝 Module Template Example - Module 23: Model Context Protocol (MCP)

This example demonstrates how to structure a module following the updated workshop instructions.

## Module Directory Structure

```
module-23-model-context-protocol/
├── README.md                    # Module overview
├── prerequisites.md             # Setup requirements
├── exercises/
│   ├── exercise1-easy/
│   │   ├── README.md           # Exercise instructions
│   │   ├── starter/            # Starting code
│   │   ├── solution/           # Complete solution
│   │   └── tests/              # Validation tests
│   ├── exercise2-medium/
│   │   └── [same structure]
│   └── exercise3-hard/
│       └── [same structure]
├── best-practices.md           # Production patterns
├── resources/
│   ├── mcp-server-template/
│   ├── mcp-client-examples/
│   ├── security-configs/
│   └── deployment-scripts/
└── project/                    # Independent project
    └── README.md
```

## Sample Module README.md

```markdown
# Module 23: Model Context Protocol (MCP)

## 🎯 Module Overview

Welcome to Module 23! This module provides deep expertise in Model Context Protocol (MCP), the standard for AI agent communication. You'll learn to build MCP servers, implement clients, and create secure, production-ready integrations that enable AI agents to interact with any system.

### Duration
- **Total Time**: 3 hours
- **Lecture/Demo**: 45 minutes
- **Hands-on Exercises**: 2 hours 15 minutes

### Track
- 🟣 AI Agents & MCP Track (Modules 21-25)

## 🎓 Learning Objectives

By the end of this module, you will be able to:

1. **Understand MCP Architecture** - Master the protocol specification and design principles
2. **Build MCP Servers** - Create production-ready servers for any integration
3. **Implement MCP Clients** - Connect to MCP servers securely and efficiently
4. **Handle Security** - Implement authentication, authorization, and encryption
5. **Deploy to Production** - Scale MCP systems for enterprise use

## 🔧 Prerequisites

- ✅ Completed Modules 1-22
- ✅ Understanding of agent architectures (Module 21)
- ✅ Experience with async programming
- ✅ Basic knowledge of network protocols
- ✅ Azure subscription with AI services enabled

See [prerequisites.md](prerequisites.md) for detailed setup instructions.

## 📚 Key Concepts

### What is MCP?

Model Context Protocol (MCP) is a standardized protocol that enables:
- **Universal Integration**: Any AI can talk to any system
- **Tool Standardization**: Consistent interface for all tools
- **Security by Design**: Built-in authentication and encryption
- **Scalability**: From single tools to enterprise systems

### MCP Architecture

\```mermaid
graph TB
    subgraph "AI Agents"
        A[GitHub Copilot]
        B[Custom Agent]
        C[Enterprise Agent]
    end
    
    subgraph "MCP Layer"
        D[MCP Client]
        E[MCP Server]
        F[Security Gateway]
    end
    
    subgraph "Systems"
        G[Databases]
        H[APIs]
        I[File Systems]
    end
    
    A --> D
    B --> D
    C --> D
    D --> F
    F --> E
    E --> G
    E --> H
    E --> I
    
    style D fill:#4CAF50
    style E fill:#2196F3
    style F fill:#FF9800
\```

## 🚀 What You'll Build

In this module, you'll create:
1. **MCP Server** - Handle requests from AI agents
2. **MCP Client** - Connect to existing MCP servers
3. **Security Layer** - Implement enterprise authentication
4. **Production System** - Deploy and monitor MCP infrastructure

## 📊 Module Resources

- **Documentation**: [MCP Specification](https://github.com/anthropics/model-context-protocol)
- **Azure Integration**: [Azure MCP Documentation](https://learn.microsoft.com/azure/ai)
- **GitHub MCP**: [GitHub MCP Guide](https://docs.github.com/mcp)
- **Video Tutorial**: [Module 23 Walkthrough](https://workshop.com/module-23)

## ⏭️ Next Steps

After completing this module, you'll be ready for:
- **Module 24**: Multi-Agent Orchestration
- **Module 25**: Advanced Agent Patterns

Let's master MCP and unlock the full potential of AI agents!
```

## Sample Exercise Structure

```markdown
# Exercise 1: Basic MCP Server (⭐ Easy - 30 minutes)

## Objective
Create your first MCP server that exposes a simple tool to AI agents.

## What You'll Learn
- MCP server basics
- Request/response handling
- Tool registration
- Error management

## Prerequisites
- Node.js or Python installed
- Basic understanding of async programming

## Instructions

### Step 1: Set Up Project Structure

\```bash
mkdir mcp-calculator-server
cd mcp-calculator-server
npm init -y
npm install @anthropic/mcp express
\```

### Step 2: Create Basic Server

**Copilot Prompt Suggestion:**
"Create an MCP server in TypeScript that:
- Implements a calculator tool with add, subtract, multiply, divide
- Handles tool listing requests
- Validates input parameters
- Returns proper MCP responses
Include error handling and logging."

**Expected Output:**
A complete MCP server implementation with all basic operations.

### Step 3: Implement Tool Registration

\```typescript
// Complete implementation provided in solution/
\```

### Step 4: Test Your Server

\```bash
npm test
\```

## Validation

Run the automated tests to verify your implementation:
\```bash
npm run validate
\```

## Extension Challenge

Add these features to your server:
- Advanced math operations
- Input validation
- Rate limiting
- Metrics collection
```

## Best Practices Document Example

```markdown
# MCP Best Practices

## Design Principles

### 1. Stateless Servers
- Don't maintain session state
- Use tokens for context
- Enable horizontal scaling

### 2. Security First
- Always authenticate requests
- Validate all inputs
- Use TLS for transport
- Implement rate limiting

### 3. Error Handling
\```python
def handle_request(request):
    try:
        # Validate request
        if not validate_request(request):
            return error_response(400, "Invalid request")
        
        # Process request
        result = process(request)
        return success_response(result)
        
    except AuthenticationError:
        return error_response(401, "Authentication required")
    except RateLimitError:
        return error_response(429, "Rate limit exceeded")
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return error_response(500, "Internal server error")
\```

## Production Checklist

- [ ] Authentication implemented
- [ ] Rate limiting configured
- [ ] Monitoring enabled
- [ ] Logging structured
- [ ] Error handling comprehensive
- [ ] Performance optimized
- [ ] Security scanned
- [ ] Documentation complete
```

---

This template demonstrates the complete structure expected for each module in the Mastery AI Code Development Workshop.