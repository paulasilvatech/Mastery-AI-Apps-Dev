---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 24"
---

# Prerequisites for Module 24: Multi-Agent Orchestration

## 🎯 Required Knowledge

Before starting this module, ensure you have:

### From Previous Modules
- ✅ **Module 21**: Agent fundamentals and tool integration
- ✅ **Module 22**: Custom agent development
- ✅ **Module 23**: Model Context Protocol (MCP)
- ✅ **Agent Communication**: Understanding of agent messaging
- ✅ **State Management**: Experience with distributed state

### System Design Knowledge
- ✅ **Distributed Systems**: Basic concepts (CAP theorem, consensus)
- ✅ **Message Patterns**: Pub/sub, request/reply, streaming
- ✅ **Workflow Concepts**: DAGs, state machines, orchestration
- ✅ **Concurrency**: Async patterns, race conditions, locks

### Programming Skills
- ✅ **TypeScript/JavaScript**: Advanced async programming
- ✅ **Python**: For alternative implementations
- ✅ **System Design**: Microservices patterns
- ✅ **Testing**: Unit and integration testing

## 🛠️ Required Software

### Core Requirements
```bash
# Node.js and npm
node --version  # Must be 18.0.0 or higher
npm --version   # Must be 8.0.0 or higher

# Python (for Python examples)
python --version  # Must be 3.11 or higher

# Docker
docker --version  # Must be 24.0.0 or higher
docker-compose --version  # Must be 2.20.0 or higher

# Redis (for state management)
redis-server --version  # Must be 7.0.0 or higher
```

### Development Tools
```bash
# VS Code with extensions
code --list-extensions | grep -E "(copilot|typescript|python|docker)"

# Required VS Code extensions:
# - GitHub.copilot
# - GitHub.copilot-chat
# - ms-python.python
# - ms-vscode.vscode-typescript-next
# - ms-azuretools.vscode-docker
# - redhat.vscode-yaml
```

## 📦 Package Installation

### TypeScript/JavaScript Setup
```bash
# Create project directory
mkdir module-24-orchestration && cd module-24-orchestration

# Initialize npm project
npm init -y

# Install orchestration dependencies
npm install \
  @modelcontextprotocol/sdk \
  bull \
  ioredis \
  p-queue \
  eventemitter3 \
  axios \
  winston

# Install workflow dependencies
npm install \
  @temporalio/client \
  @temporalio/worker \
  graphlib \
  node-cron

# Install monitoring dependencies
npm install \
  prom-client \
  @opentelemetry/api \
  @opentelemetry/sdk-node \
  @opentelemetry/auto-instrumentations-node

# Install development dependencies
npm install --save-dev \
  typescript \
  @types/node \
  ts-node \
  nodemon \
  jest \
  @types/jest \
  concurrently
```

### Python Setup
```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install orchestration dependencies
pip install \
  celery[redis]&gt;=5.3.0 \
  kombu>=5.3.0 \
  redis>=5.0.0 \
  asyncio>=3.11.0

# Install workflow dependencies  
pip install \
  prefect>=2.14.0 \
  networkx>=3.2.0 \
  apscheduler>=3.10.0

# Install monitoring dependencies
pip install \
  prometheus-client>=0.19.0 \
  opentelemetry-api>=1.21.0 \
  opentelemetry-sdk>=1.21.0 \
  structlog>=24.0.0

# Install testing dependencies
pip install \
  pytest>=7.4.0 \
  pytest-asyncio>=0.21.0 \
  pytest-mock>=3.12.0
```

## 🔧 Infrastructure Setup

### 1. Redis Setup
```bash
# Using Docker
docker run -d --name redis-orchestration \
  -p 6379:6379 \
  redis:7-alpine \
  redis-server --appendonly yes

# Verify Redis is running
redis-cli ping  # Should return PONG
```

### 2. Message Queue Setup (RabbitMQ)
```bash
# Start RabbitMQ
docker run -d --name rabbitmq-orchestration \
  -p 5672:5672 \
  -p 15672:15672 \
  -e RABBITMQ_DEFAULT_USER=admin \
  -e RABBITMQ_DEFAULT_PASS=admin \
  rabbitmq:3-management-alpine

# Access management UI at http://localhost:15672
# Username: admin, Password: admin
```

### 3. Monitoring Stack
```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/dashboards:/var/lib/grafana/dashboards
      - ./grafana/provisioning:/etc/grafana/provisioning

  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686"
      - "14268:14268"
    environment:
      - COLLECTOR_ZIPKIN_HOST_PORT=:9411

volumes:
  prometheus_data:
  grafana_data:
```

### 4. Start Monitoring Stack
```bash
# Save the above as docker-compose.monitoring.yml
docker-compose -f docker-compose.monitoring.yml up -d

# Verify services
curl http://localhost:9090  # Prometheus
curl http://localhost:3000  # Grafana (admin/admin)
curl http://localhost:16686 # Jaeger UI
```

## 🔧 Environment Configuration

### 1. Create `.env` file
```bash
# Orchestration Configuration
ORCHESTRATOR_PORT=4000
ORCHESTRATOR_HOST=localhost

# Agent Configuration
MAX_AGENTS_PER_WORKFLOW=10
AGENT_TIMEOUT_MS=30000
AGENT_RETRY_ATTEMPTS=3

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0

# RabbitMQ Configuration
RABBITMQ_URL=amqp://admin:admin@localhost:5672

# State Management
STATE_SYNC_INTERVAL_MS=1000
STATE_STORE_TTL_SECONDS=3600

# Monitoring
METRICS_PORT=9091
ENABLE_TRACING=true
JAEGER_ENDPOINT=http://localhost:14268/api/traces

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

### 3. Create Prometheus Configuration
Create `prometheus.yml`:
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'orchestrator'
    static_configs:
      - targets: ['host.docker.internal:9091']
    
  - job_name: 'agents'
    static_configs:
      - targets: 
        - 'host.docker.internal:9092'
        - 'host.docker.internal:9093'
        - 'host.docker.internal:9094'
```

## 🧪 Validation Script

Create `scripts/validate-prerequisites.js`:
```javascript
#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🔍 Validating Module 24 Prerequisites...\n');

const checks = {
  'Node.js 18+': () =&gt; {
    const version = execSync('node --version').toString().trim();
    const major = parseInt(version.split('.')[0].substring(1));
    return major &gt;= 18 ? { pass: true, version } : { pass: false, version };
  },
  
  'Redis': () =&gt; {
    try {
      execSync('redis-cli ping', { stdio: 'pipe' });
      return { pass: true, version: 'Connected' };
    } catch {
      return { pass: false, version: 'Not running' };
    }
  },
  
  'RabbitMQ': () =&gt; {
    try {
      const response = execSync('curl -s http://admin:admin@localhost:15672/api/overview')
        .toString();
      return { pass: true, version: 'Running' };
    } catch {
      return { pass: false, version: 'Not accessible' };
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
  
  'TypeScript': () =&gt; {
    try {
      const version = execSync('tsc --version').toString().trim();
      return { pass: true, version };
    } catch {
      return { pass: false, version: 'Not installed' };
    }
  },
  
  'MCP SDK': () =&gt; {
    const packageJson = path.join(process.cwd(), 'package.json');
    if (!fs.existsSync(packageJson)) {
      return { pass: false, version: 'package.json not found' };
    }
    
    const pkg = JSON.parse(fs.readFileSync(packageJson, 'utf8'));
    const hasMCP = pkg.dependencies?.['@modelcontextprotocol/sdk'];
    
    return hasMCP 
      ? { pass: true, version: pkg.dependencies['@modelcontextprotocol/sdk'] }
      : { pass: false, version: 'Not installed' };
  },
  
  'Monitoring Stack': () =&gt; {
    try {
      execSync('curl -s http://localhost:9090', { stdio: 'pipe' });
      execSync('curl -s http://localhost:3000', { stdio: 'pipe' });
      return { pass: true, version: 'Running' };
    } catch {
      return { pass: false, version: 'Not all services running' };
    }
  }
};

let allPassed = true;

Object.entries(checks).forEach(([name, check]) =&gt; {
  try {
    const result = check();
    const status = result.pass ? '✅' : '❌';
    console.log(`${status} ${name}: ${result.version}`);
    allPassed = allPassed && result.pass;
  } catch (error) {
    console.log(`❌ ${name}: Error checking`);
    allPassed = false;
  }
});

console.log(`\n${allPassed ? '✅ All prerequisites met!' : '❌ Some prerequisites missing.'}`);

if (!allPassed) {
  console.log('\n📝 Next steps:');
  console.log('1. Install missing dependencies');
  console.log('2. Start required services (Redis, RabbitMQ)');
  console.log('3. Run monitoring stack: docker-compose -f docker-compose.monitoring.yml up -d');
  console.log('4. Run this script again to verify');
}

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

### Issue: Redis Connection Failed
```bash
# Start Redis if not running
docker start redis-orchestration

# Or install locally
brew install redis  # macOS
sudo apt install redis-server  # Ubuntu
```

### Issue: RabbitMQ Not Accessible
```bash
# Check if container is running
docker ps | grep rabbitmq

# View logs
docker logs rabbitmq-orchestration

# Restart if needed
docker restart rabbitmq-orchestration
```

### Issue: TypeScript Compilation Errors
```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install

# Update TypeScript
npm install -g typescript@latest
```

### Issue: Port Conflicts
```bash
# Find process using port
lsof -i :4000  # macOS/Linux
netstat -ano | findstr :4000  # Windows

# Change port in .env file
ORCHESTRATOR_PORT=4001
```

## 📚 Pre-Module Learning Resources

### Multi-Agent Systems
1. [Distributed Systems Concepts](https://www.distributed-systems.net/)
2. [Consensus Protocols](https://raft.github.io/)
3. [Actor Model](https://www.brianstorti.com/the-actor-model/)

### Workflow Orchestration
1. [Workflow Patterns](https://www.workflowpatterns.com/)
2. [Apache Airflow Concepts](https://airflow.apache.org/docs/apache-airflow/stable/concepts/index.html)
3. [Temporal.io Documentation](https://docs.temporal.io/)

### State Management
1. [Event Sourcing](https://martinfowler.com/eaaDev/EventSourcing.html)
2. [CQRS Pattern](https://martinfowler.com/bliki/CQRS.html)
3. [Distributed State Machines](https://www.allthingsdistributed.com/2008/12/eventually_consistent.html)

## ✅ Pre-Module Checklist

Before starting the exercises, ensure:

- [ ] All software versions meet requirements
- [ ] npm/pip packages installed successfully
- [ ] Redis is running and accessible
- [ ] RabbitMQ is running with management UI
- [ ] Monitoring stack is operational
- [ ] Environment variables configured
- [ ] Validation script passes
- [ ] Basic understanding of distributed systems
- [ ] Familiarity with async programming patterns

## 🎯 Ready to Start?

Once all prerequisites are met:

1. Review the [Multi-Agent Architecture](README.md#-what-is-multi-agent-orchestration) section
2. Set up your project structure
3. Start with [Exercise 1: Research Assistant System](./exercise1-overview)
4. Join the discussion in GitHub Discussions for help

---

**Need Help?** Check the [Module 24 Troubleshooting Guide](/docs/guias/troubleshooting) or post in the module discussions.