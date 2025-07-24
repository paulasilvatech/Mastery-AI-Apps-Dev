---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 10"
---

# Módulo 10 Pré-requisitos

## 🎯 Required Knowledge

### From Anterior Módulos
- Python async/await syntax (Módulo 6)
- Basic web application structure (Módulo 7)
- API desenvolvimento concepts (Módulo 8)
- Database connections (Módulo 9)

### Additional Requirements
- Understanding of HTTP protocol
- Basic JavaScript for client-side code
- Command line proficiency
- Docker basics

## 🛠️ ambiente Setup

### 1. Python ambiente
```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows
.\venv\Scripts\activate
# macOS/Linux
source venv/bin/activate

# Upgrade pip
python -m pip install --upgrade pip
```

### 2. Install Required Packages
```bash
# Core packages
pip install fastapi==0.104.1
pip install uvicorn[standard]==0.24.0
pip install websockets==12.0
pip install aioredis==2.0.1
pip install asyncio-mqtt==0.16.1
pip install httpx==0.25.1
pip install pytest-asyncio==0.21.1

# Additional utilities
pip install python-multipart==0.0.6
pip install python-dotenv==1.0.0
pip install pydantic==2.5.0
```

### 3. External Services Setup

#### Redis (Message Broker)
```bash
# Using Docker
docker run -d \
  --name redis-module10 \
  -p 6379:6379 \
  redis:7-alpine

# Verify Redis is running
docker exec -it redis-module10 redis-cli ping
# Should return: PONG
```

#### RabbitMQ (Alternative Message Broker)
```bash
# Using Docker with management UI
docker run -d \
  --name rabbitmq-module10 \
  -p 5672:5672 \
  -p 15672:15672 \
  rabbitmq:3-management

# Access management UI at http://localhost:15672
# Default credentials: guest/guest
```

### 4. VS Code Extensions
Ensure these extensions are instalado:
- Python
- Pylance
- GitHub Copilot
- Thunder Client (for API testing)
- WebSocket Client (for testing)

### 5. Browser Requirements
- Modern browser with WebSocket support
- Developer tools enabled
- WebSocket testing extension (optional)

## 📋 Verification Script

Create `verify_setup.py`:

```python
#!/usr/bin/env python3
"""
Module 10 Prerequisites Verification Script
"""

import sys
import subprocess
import importlib

def check_python_version():
    """Verify Python version is 3.11+"""
    version = sys.version_info
    if version.major == 3 and version.minor &gt;= 11:
        print("✅ Python version: {}.{}.{}".format(version.major, version.minor, version.micro))
        return True
    else:
        print("❌ Python 3.11+ required, found: {}.{}.{}".format(version.major, version.minor, version.micro))
        return False

def check_packages():
    """Verify all required packages are installed"""
    packages = [
        'fastapi',
        'uvicorn',
        'websockets',
        'aioredis',
        'asyncio_mqtt',
        'httpx',
        'pytest_asyncio'
    ]
    
    all_installed = True
    for package in packages:
        try:
            importlib.import_module(package.replace('-', '_'))
            print(f"✅ {package} installed")
        except ImportError:
            print(f"❌ {package} not installed")
            all_installed = False
    
    return all_installed

def check_services():
    """Check if Redis is accessible"""
    try:
        import aioredis
        import asyncio
        
        async def test_redis():
            try:
                redis = await aioredis.from_url("redis://localhost:6379")
                await redis.ping()
                await redis.close()
                return True
            except Exception:
                return False
        
        if asyncio.run(test_redis()):
            print("✅ Redis is running")
            return True
        else:
            print("❌ Redis is not accessible")
            return False
    except Exception as e:
        print(f"❌ Could not test Redis: {e}")
        return False

def main():
    """Run all verification checks"""
    print("Module 10 Prerequisites Verification")
    print("=" * 40)
    
    checks = [
        check_python_version(),
        check_packages(),
        check_services()
    ]
    
    if all(checks):
        print("\n✅ All prerequisites satisfied!")
        print("You're ready to start Module 10!")
    else:
        print("\n❌ Some prerequisites are missing.")
        print("Please install missing components before proceeding.")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

Run the verification:
```bash
python verify_setup.py
```

## 🚨 Common Setup Issues

### Issue: Package installation fails
```bash
# Solution: Upgrade pip and setuptools
python -m pip install --upgrade pip setuptools wheel

# Try installing packages one by one
pip install fastapi
pip install "uvicorn[standard]"
```

### Issue: Redis connection refused
```bash
# Check if Docker is running
docker ps

# Check Redis logs
docker logs redis-module10

# Restart Redis
docker restart redis-module10
```

### Issue: Port already in use
```bash
# Find process using port 8000
# Windows
netstat -ano | findstr :8000
# macOS/Linux
lsof -i :8000

# Use alternative port
uvicorn main:app --port 8001
```

## 📚 Recommended Reading

Before starting the exercises, review:
1. [Python AsyncIO basics](https://docs.python.org/3/library/asyncio.html)
2. [WebSocket protocol overview](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API)
3. [Event-driven architecture concepts](https://docs.microsoft.com/en-us/azure/architecture/guide/architecture-styles/event-driven)

## ✅ Verificarlist

- [ ] Python 3.11+ instalado
- [ ] Virtual ambiente created and activated
- [ ] All Python packages instalado
- [ ] Redis running in Docker
- [ ] VS Code with required extensions
- [ ] Verification script passes
- [ ] Revisared recommended reading

Once all items are checked, proceed to [Exercício 1](./exercise1-overview)!