---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 15"
---

# Módulo 15: Pré-requisitos and Setup

## 📋 Required Knowledge

Before starting Módulo 15, you should have completed:

### Anterior Módulos
- ✅ **Módulo 11**: Microservices Architecture
- ✅ **Módulo 12**: Cloud-Native Development  
- ✅ **Módulo 13**: Infrastructure as Code
- ✅ **Módulo 14**: CI/CD with GitHub Actions

### Technical Concepts
You should be comfortable with:
- Distributed systems principles
- Async programming in Python
- Basic database operations
- HTTP/REST API concepts
- Container orchestration basics
- Cloud resource management

## 🛠️ Software Requirements

### Local desenvolvimento ambiente

```bash
# Check Python version (3.11+ required)
python --version

# Check Node.js (for some tooling)
node --version  # Should be 18+

# Check Docker
docker --version  # Should be 24+

# Check Redis
redis-cli --version  # Should be 6+
```

### Required Python Packages

```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows
.\venv\Scripts\activate
# macOS/Linux
source venv/bin/activate

# Install requirements
pip install -r requirements.txt
```

**requirements.txt**:
```txt
# Core dependencies
fastapi==0.104.1
uvicorn[standard]==0.24.0
redis==5.0.1
aioredis==2.0.1
httpx==0.25.1

# Performance monitoring
prometheus-client==0.19.0
py-spy==0.3.14
memory-profiler==0.61.0
psutil==5.9.6

# Database
asyncpg==0.29.0
sqlalchemy[asyncio]==2.0.23
alembic==1.12.1

# Testing and benchmarking
pytest==7.4.3
pytest-asyncio==0.21.1
pytest-benchmark==4.0.0
locust==2.17.0

# Utilities
python-dotenv==1.0.0
pydantic==2.5.0
pydantic-settings==2.1.0
tenacity==8.2.3
```

### VS Code Extensions
Ensure these extensions are instalado:
- GitHub Copilot
- Python
- Pylance
- Docker
- Thunder Client (API testing)
- Redis

## ☁️ Azure Recursos Setup

### 1. Azure Cache for Redis

```bash
# Create Redis cache
az redis create \
  --name "redis-module15-$RANDOM" \
  --resource-group "rg-workshop-module15" \
  --location "eastus" \
  --sku "Basic" \
  --vm-size "C0"

# Get connection string
az redis list-keys \
  --name "redis-module15-xxxxx" \
  --resource-group "rg-workshop-module15"
```

### 2. Application Insights

```bash
# Create Application Insights
az monitor app-insights component create \
  --app "appinsights-module15" \
  --location "eastus" \
  --resource-group "rg-workshop-module15" \
  --application-type "web"

# Get instrumentation key
az monitor app-insights component show \
  --app "appinsights-module15" \
  --resource-group "rg-workshop-module15" \
  --query "instrumentationKey"
```

### 3. Container Registry (for Exercício 3)

```bash
# Create container registry
az acr create \
  --name "acrmodule15$RANDOM" \
  --resource-group "rg-workshop-module15" \
  --sku "Basic" \
  --admin-enabled true
```

## 🔧 Local Setup Scripts

### setup-Módulo15.sh
```bash
#!/bin/bash

echo "🚀 Setting up Module 15 environment..."

# Check prerequisites
command -v python3 &gt;/dev/null 2>&1 || { echo "Python 3 is required"; exit 1; }
command -v docker &gt;/dev/null 2>&1 || { echo "Docker is required"; exit 1; }
command -v redis-cli &gt;/dev/null 2>&1 || { echo "Redis is required"; exit 1; }

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Start local Redis if not running
if ! pgrep -x "redis-server" &gt; /dev/null; then
    echo "Starting Redis server..."
    redis-server --daemonize yes
fi

# Create .env file template
cat &gt; .env.template &lt;&lt; EOF
# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
AZURE_REDIS_CONNECTION_STRING=

# Application Insights
APPLICATIONINSIGHTS_CONNECTION_STRING=

# Database
DATABASE_URL=postgresql+asyncpg://user:password@localhost/workshop

# Performance Settings
CACHE_TTL_SECONDS=300
MAX_CONNECTIONS_PER_HOST=100
CONNECTION_POOL_SIZE=20
EOF

echo "✅ Setup complete!"
echo "📝 Copy .env.template to .env and fill in your values"
```

### verify-setup.py
```python
#!/usr/bin/env python3
"""Verify Module 15 setup and prerequisites."""

import sys
import subprocess
import importlib.util
from typing import Tuple, List

def check_command(command: str) -&gt; Tuple[bool, str]:
    """Check if a command is available."""
    try:
        result = subprocess.run(
            [command, "--version"], 
            capture_output=True, 
            text=True
        )
        return True, result.stdout.strip()
    except FileNotFoundError:
        return False, "Not installed"

def check_python_package(package: str) -&gt; Tuple[bool, str]:
    """Check if a Python package is installed."""
    spec = importlib.util.find_spec(package)
    if spec is not None:
        return True, "Installed"
    return False, "Not installed"

def check_redis_connection() -&gt; Tuple[bool, str]:
    """Check Redis connectivity."""
    try:
        import redis
        r = redis.Redis(host='localhost', port=6379, decode_responses=True)
        r.ping()
        return True, "Connected"
    except Exception as e:
        return False, f"Connection failed: {str(e)}"

def main():
    """Run all verification checks."""
    print("🔍 Verifying Module 15 Prerequisites\n")
    
    all_good = True
    
    # Check commands
    commands = ["python3", "docker", "redis-cli", "git"]
    print("Checking required commands:")
    for cmd in commands:
        success, version = check_command(cmd)
        status = "✅" if success else "❌"
        print(f"  {status} {cmd}: {version}")
        if not success:
            all_good = False
    
    # Check Python packages
    packages = [
        "fastapi", "redis", "prometheus_client", 
        "pytest", "locust", "asyncpg"
    ]
    print("\nChecking Python packages:")
    for pkg in packages:
        success, status = check_python_package(pkg)
        icon = "✅" if success else "❌"
        print(f"  {icon} {pkg}: {status}")
        if not success:
            all_good = False
    
    # Check Redis connection
    print("\nChecking services:")
    success, status = check_redis_connection()
    icon = "✅" if success else "❌"
    print(f"  {icon} Redis: {status}")
    if not success:
        all_good = False
    
    # Check GitHub Copilot
    print("\nChecking GitHub Copilot:")
    print("  ℹ️  Please ensure GitHub Copilot is active in VS Code")
    
    # Final result
    print("\n" + "="*50)
    if all_good:
        print("✅ All prerequisites satisfied! You're ready to start.")
    else:
        print("❌ Some prerequisites are missing. Please install them.")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

## 🐳 Docker Setup

### docker-compose.yml
```yaml
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: workshop
      POSTGRES_PASSWORD: workshop123
      POSTGRES_DB: performance_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

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

volumes:
  redis_data:
  postgres_data:
  prometheus_data:
  grafana_data:
```

## 🔍 Troubleshooting Setup Issues

### Redis Connection Issues
```bash
# Check if Redis is running
ps aux | grep redis

# Start Redis manually
redis-server --port 6379

# Test connection
redis-cli ping
```

### Python ambiente Issues
```bash
# Recreate virtual environment
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### Docker Issues
```bash
# Reset Docker environment
docker-compose down -v
docker system prune -a
docker-compose up -d
```

## ✅ Ready to Start?

Once all prerequisites are satisfied:

1. Ensure all services are running:
   ```bash
   docker-compose up -d
   python scripts/verify-setup.py
   ```

2. Configure your ambiente:
   ```bash
   cp .env.template .env
   # Edit .env with your Azure credentials
   ```

3. Comece com Exercício 1:
   ```bash
   cd exercises/exercise1-foundation
   code .
   ```

Happy learning! 🚀