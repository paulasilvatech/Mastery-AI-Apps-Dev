---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 08"
---

# Prerrequisitos for Módulo 08: API desarrollo and Integration

## 📋 Required Knowledge

Before starting this module, you should have completed:

- ✅ **Módulo 1-5**: GitHub Copilot fundamentals and core features
- ✅ **Módulo 6**: Multi-file project management
- ✅ **Módulo 7**: Web application desarrollo basics

You should be comfortable with:
- Python async/await programming
- Basic HTTP concepts (methods, headers, status codes)
- JSON data format
- Database basics (CRUD operations)
- Git version control

## 🛠️ ambiente Setup

### 1. Python ambiente
```bash
# Ensure Python 3.11+ is installed
python --version

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
# Core API frameworks
pip install fastapi==0.109.0
pip install strawberry-graphql==0.217.1
pip install uvicorn[standard]==0.27.0
pip install httpx==0.26.0

# Authentication & Security
pip install python-jose[cryptography]==3.3.0
pip install passlib[bcrypt]==1.7.4
pip install python-multipart==0.0.6

# Database & Caching
pip install sqlalchemy==2.0.25
pip install alembic==1.13.1
pip install redis==5.0.1
pip install aiocache==0.12.2

# Testing
pip install pytest==7.4.4
pip install pytest-asyncio==0.23.3
pip install pytest-cov==4.1.0

# Monitoring & Documentation
pip install prometheus-client==0.19.0
pip install opentelemetry-api==1.22.0
pip install opentelemetry-sdk==1.22.0
```

### 3. Install desarrollo Tools
```bash
# API testing tools
pip install httpie

# Code formatting
pip install black isort

# Type checking
pip install mypy
```

### 4. Docker Setup (Optional but Recommended)
```bash
# Verify Docker installation
docker --version
docker-compose --version

# Pull required images
docker pull redis:7-alpine
docker pull postgres:16-alpine
```

### 5. VS Code Extensions
Ensure these extensions are instalado:
- **GitHub Copilot** (required)
- **Python** (Microsoft)
- **Thunder Client** or **REST Client**
- **Docker** (Microsoft)
- **SQLite Viewer** (for local desarrollo)

## 🔧 Configuration

### 1. Create Project Structure
```bash
mkdir module-08-workspace
cd module-08-workspace

# Create necessary directories
mkdir -p apis/rest
mkdir -p apis/graphql
mkdir -p tests
mkdir -p docs
```

### 2. ambiente Variables
Create `.env` file in your workspace:
```env
# API Configuration
API_HOST=localhost
API_PORT=8000
API_ENV=development

# Security
SECRET_KEY=your-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Database
DATABASE_URL=sqlite:///./test.db
# For PostgreSQL: postgresql://user:password@localhost/dbname

# Redis Cache
REDIS_URL=redis://localhost:6379

# External APIs (for integration exercises)
GITHUB_API_TOKEN=your-github-token
OPENWEATHER_API_KEY=your-weather-api-key
```

### 3. GitHub Copilot Configuration
Configure Copilot for API desarrollo:
1. Abrir VS Code settings (Cmd/Ctrl + ,)
2. Buscar for "GitHub Copilot"
3. Enable these settings:
   - `github.copilot.enable`: `true`
   - `github.copilot.advanced_autosuggest.enable`: `true`

## 🧪 Verification Script

Run this script to verify your setup:

```python
# verify_setup.py
import sys
import importlib
import subprocess

def check_python_version():
    version = sys.version_info
    if version.major == 3 and version.minor &gt;= 11:
        print("✅ Python version OK:", sys.version)
        return True
    else:
        print("❌ Python 3.11+ required. Current:", sys.version)
        return False

def check_packages():
    packages = [
        'fastapi', 'strawberry', 'uvicorn', 'httpx',
        'jose', 'passlib', 'sqlalchemy', 'redis',
        'pytest', 'prometheus_client'
    ]
    
    missing = []
    for package in packages:
        try:
            importlib.import_module(package)
            print(f"✅ {package} installed")
        except ImportError:
            print(f"❌ {package} not found")
            missing.append(package)
    
    return len(missing) == 0

def check_tools():
    tools = ['git', 'docker']
    all_found = True
    
    for tool in tools:
        try:
            subprocess.run([tool, '--version'], 
                         capture_output=True, check=True)
            print(f"✅ {tool} installed")
        except:
            print(f"⚠️  {tool} not found (optional)")
            all_found = False
    
    return all_found

def main():
    print("🔍 Verifying Module 08 Prerequisites...\n")
    
    checks = [
        ("Python Version", check_python_version()),
        ("Required Packages", check_packages()),
        ("Development Tools", check_tools())
    ]
    
    if all(check[1] for check in checks):
        print("\n✅ All prerequisites satisfied! Ready for Module 08.")
    else:
        print("\n❌ Some prerequisites missing. Please install missing components.")
        print("Run: pip install -r requirements.txt")

if __name__ == "__main__":
    main()
```

## 📚 Recommended Reading

Before starting the exercises, review:

1. **HTTP Fundamentos**
   - [MDN HTTP Resumen](https://developer.mozilla.org/en-US/docs/Web/HTTP/Resumen)
   - [HTTP Status Codes](https://httpstatuses.com/)

2. **API Design Principles**
   - [Microsoft REST API Guíalines](https://github.com/microsoft/api-guidelines)
   - [GraphQL Mejores Prácticas](https://graphql.org/learn/best-practices/)

3. **Python Async Programming**
   - [Python asyncio documentation](https://docs.python.org/3/library/asyncio.html)
   - [FastAPI async guide](https://fastapi.tiangolo.com/async/)

## 🆘 Troubleshooting

### Common Issues

**Issue**: Import errors when running FastAPI
```bash
# Solution: Ensure virtual environment is activated
which python  # Should show venv path
```

**Issue**: Port 8000 already in use
```bash
# Find and kill process
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# macOS/Linux
lsof -i :8000
kill -9 <PID>
```

**Issue**: Redis connection failed
```bash
# Start Redis with Docker
docker run -d -p 6379:6379 redis:7-alpine
```

## ✅ Ready to Start!

Once all prerequisites are satisfied:
1. Navigate to `exercises/exercise1-rest-api/`
2. Abrir the instructions
3. Start building your first AI-assisted API!

---

Need help? Check the [troubleshooting guide](/docs/guias/troubleshooting) or reach out in the workshop discussions.