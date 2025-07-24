---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 23"
---

# Pré-requisitos for Módulo 23: Model Context Protocol (MCP)

## 🎯 Required Knowledge

Before starting this module, ensure you have:

### From Anterior Módulos
- ✅ **Módulo 21**: Agent fundamentals and tool integration
- ✅ **Módulo 22**: Custom agent desenvolvimento patterns
- ✅ **State Management**: Understanding of agent state patterns
- ✅ **Tool Systems**: Experience with tool registries and execution

### Protocol Knowledge
- ✅ **JSON-RPC 2.0**: Understanding of the protocol basics
- ✅ **WebSocket**: Real-time bidirectional communication
- ✅ **HTTP/REST**: RESTful API principles
- ✅ **JSON Schema**: Schema definition and validation

### Programming Skills
- ✅ **TypeScript/JavaScript**: For reference implementation
- ✅ **Python**: For Python MCP implementation
- ✅ **Async Programming**: Promises, async/await
- ✅ **Event-Driven**: Event emitters and handlers

## 🛠️ Required Software

### Core Requirements
```bash
# Node.js and npm (for TypeScript implementation)
node --version  # Must be 18.0.0 or higher
npm --version   # Must be 8.0.0 or higher

# Python (for Python implementation)
python --version  # Must be 3.11 or higher

# Docker
docker --version  # Must be 24.0.0 or higher

# Git
git --version  # Must be 2.38.0 or higher
```

### desenvolvimento Tools
```bash
# VS Code with extensions
code --list-extensions | grep -E "(mcp|copilot|typescript|python)"

# Required VS Code extensions:
# - GitHub.copilot
# - GitHub.copilot-chat
# - ms-python.python
# - ms-vscode.vscode-typescript-next
# - dbaeumer.vscode-eslint
# - esbenp.prettier-vscode
```

## 📦 Package Installation

### TypeScript/JavaScript Dependencies
```bash
# Create project directory
mkdir module-23-mcp && cd module-23-mcp

# Initialize npm project
npm init -y

# Install MCP dependencies
npm install @modelcontextprotocol/sdk
npm install @modelcontextprotocol/server
npm install @modelcontextprotocol/client

# Install development dependencies
npm install --save-dev \
  typescript \
  @types/node \
  @types/ws \
  ts-node \
  nodemon \
  jest \
  @types/jest \
  eslint \
  prettier

# Install additional packages
npm install \
  ws \
  express \
  jsonrpc-lite \
  ajv \
  winston \
  dotenv
```

### Python Dependencies
```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install MCP Python SDK
pip install model-context-protocol

# Install additional dependencies
pip install \
  websockets>=12.0 \
  aiohttp>=3.9.0 \
  jsonrpc-requests>=0.7.0 \
  jsonschema>=4.20.0 \
  python-dotenv>=1.0.0 \
  structlog>=24.0.0 \
  pytest>=7.4.0 \
  pytest-asyncio>=0.21.0
```

## 🔧 ambiente Setup

### 1. MCP Configuration
Create `.env` file:
```bash
# MCP Server Configuration
MCP_SERVER_HOST=localhost
MCP_SERVER_PORT=3000
MCP_SERVER_SECRET=your-secret-key-here

# MCP Client Configuration
MCP_CLIENT_TIMEOUT=30000
MCP_CLIENT_RETRY_ATTEMPTS=3

# Security Configuration
MCP_USE_TLS=false
MCP_TLS_CERT=./certs/server.crt
MCP_TLS_KEY=./certs/server.key

# Database Configuration (for Exercise 2)
DATABASE_URL=postgresql://postgres:password@localhost:5432/mcp_demo
REDIS_URL=redis://localhost:6379

# Logging
LOG_LEVEL=info
LOG_FORMAT=json
```

### 2. TypeScript Configuration
Create `tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
```

### 3. Docker Services
```bash
# Start PostgreSQL for Exercise 2
docker run -d --name postgres-mcp \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=mcp_demo \
  -p 5432:5432 \
  postgres:16-alpine

# Start Redis for caching
docker run -d --name redis-mcp \
  -p 6379:6379 \
  redis:7-alpine

# Verify services are running
docker ps | grep -E "(postgres-mcp|redis-mcp)"
```

## 🧪 Validation Script

Create `scripts/validate-prerequisites.js`:
```javascript
#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🔍 Validating Module 23 Prerequisites...\n');

const checks = {
  'Node.js 18+': () =&gt; {
    const version = execSync('node --version').toString().trim();
    const major = parseInt(version.split('.')[0].substring(1));
    return major &gt;= 18 ? { pass: true, version } : { pass: false, version };
  },
  
  'Python 3.11+': () =&gt; {
    try {
      const version = execSync('python --version').toString().trim();
      const [major, minor] = version.split(' ')[1].split('.');
      return parseInt(major) === 3 && parseInt(minor) &gt;= 11 
        ? { pass: true, version } 
        : { pass: false, version };
    } catch {
      return { pass: false, version: 'Not found' };
    }
  },
  
  'Docker': () =&gt; {
    try {
      const version = execSync('docker --version').toString().trim();
      return { pass: true, version };
    } catch {
      return { pass: false, version: 'Not found' };
    }
  },
  
  'MCP SDK': () =&gt; {
    const packageJson = path.join(process.cwd(), 'package.json');
    if (!fs.existsSync(packageJson)) {
      return { pass: false, version: 'package.json not found' };
    }
    
    const pkg = JSON.parse(fs.readFileSync(packageJson, 'utf8'));
    const hasMCP = pkg.dependencies && 
      pkg.dependencies['@modelcontextprotocol/sdk'];
    
    return hasMCP 
      ? { pass: true, version: pkg.dependencies['@modelcontextprotocol/sdk'] }
      : { pass: false, version: 'Not installed' };
  },
  
  'PostgreSQL Container': () =&gt; {
    try {
      const result = execSync('docker ps --filter name=postgres-mcp --format "{{.Status}}"')
        .toString().trim();
      return result.includes('Up') 
        ? { pass: true, version: 'Running' }
        : { pass: false, version: 'Not running' };
    } catch {
      return { pass: false, version: 'Docker error' };
    }
  }
};

let allPassed = true;

Object.entries(checks).forEach(([name, check]) =&gt; {
  const result = check();
  const status = result.pass ? '✅' : '❌';
  console.log(`${status} ${name}: ${result.version}`);
  allPassed = allPassed && result.pass;
});

console.log(`\n${allPassed ? '✅ All prerequisites met!' : '❌ Some prerequisites missing.'}`);
process.exit(allPassed ? 0 : 1);
```

### 4. Run Validation
```bash
# Make script executable
chmod +x scripts/validate-prerequisites.js

# Run validation
node scripts/validate-prerequisites.js
```

## 🚨 Common Setup Issues

### Issue: MCP SDK Installation Fails
```bash
# Clear npm cache
npm cache clean --force

# Try with legacy peer deps
npm install @modelcontextprotocol/sdk --legacy-peer-deps

# Or use yarn
yarn add @modelcontextprotocol/sdk
```

### Issue: TypeScript Compilation Errors
```bash
# Ensure TypeScript is installed globally
npm install -g typescript

# Check TypeScript version
tsc --version  # Should be 5.0+

# Clear TypeScript cache
rm -rf node_modules/.cache/
```

### Issue: WebSocket Connection Fails
```bash
# Check if port is in use
lsof -i :3000  # macOS/Linux
netstat -ano | findstr :3000  # Windows

# Kill process using port
kill -9 <PID>  # macOS/Linux
taskkill /PID <PID> /F  # Windows
```

### Issue: Python MCP Import Error
```bash
# Ensure you're in virtual environment
which python  # Should show venv path

# Reinstall MCP
pip uninstall model-context-protocol
pip install model-context-protocol --no-cache-dir

# Check installation
python -c "import mcp; print(mcp.__version__)"
```

## 📚 Pre-Módulo Learning Recursos

### MCP Fundamentos
1. [MCP Specification](https://github.com/modelcontextprotocol/specification)
2. [JSON-RPC 2.0 Spec](https://www.jsonrpc.org/specification)
3. [WebSocket Protocol RFC](https://datatracker.ietf.org/doc/html/rfc6455)

### TypeScript/JavaScript
1. [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html)
2. [Async/Await Guia](https://javascript.info/async-await)
3. [WebSocket Programming](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket)

### Python Async
1. [Python asyncio](https://docs.python.org/3/library/asyncio.html)
2. [aiohttp Documentação](https://docs.aiohttp.org/)
3. [websockets Library](https://websockets.readthedocs.io/)

## ✅ Pre-Módulo Verificarlist

Before starting the exercises, ensure:

- [ ] All software versions meet requirements
- [ ] npm packages instalado successfully
- [ ] Python packages instalado in virtual ambiente
- [ ] Docker containers running
- [ ] Environment variables configurado
- [ ] Validation script passes
- [ ] VS Code extensions instalado
- [ ] Basic understanding of JSON-RPC
- [ ] Familiarity with WebSocket concepts

## 🎯 Ready to Start?

Once all prerequisites are met:

1. Revisar the [MCP Architecture](README.md#-what-is-mcp) section
2. Set up your project structure
3. Comece com [Exercício 1: File System MCP Server](./exercise1-overview)
4. Join the discussion in GitHub Discussions for help

---

**Need Help?** Check the [Module 23 Troubleshooting Guide](/docs/guias/troubleshooting) or post in the module discussions.