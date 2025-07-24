---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 09"
---

# Pré-requisitos for Módulo 09: Database Design and Optimization

## 📋 Required Knowledge

### From Anterior Módulos
- ✅ **Módulo 7**: Web application desenvolvimento fundamentals
- ✅ **Módulo 8**: API design and REST principles  
- ✅ **GitHub Copilot**: Proficiency with suggestions and prompting
- ✅ **Python**: Intermediate level with async/await understanding

### Database Concepts
- Basic understanding of relational databases
- SQL fundamentals (SELECT, INSERT, UPDATE, DELETE)
- Primary keys and foreign keys
- Basic understanding of indexes

## 🛠️ Software Requirements

### Database Servers
```bash
# PostgreSQL 15+
postgres --version
# Expected: postgres (PostgreSQL) 15.x or higher

# Redis 7+
redis-server --version
# Expected: Redis server v=7.x.x or higher
```

### desenvolvimento Tools
```bash
# Python 3.11+
python --version

# pip (latest)
pip --version

# Git
git --version

# Docker (optional but recommended)
docker --version
```

### VS Code Extensions
- GitHub Copilot
- Python extension pack
- PostgreSQL extension
- Redis extension
- Database Client JDBC

## 📦 Python Dependencies

### Required Packages
```bash
# Create virtual environment
python -m venv venv

# Activate environment
# Windows
.\venv\Scripts\activate
# Linux/macOS
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### requirements.txt
```text
# Database
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
alembic==1.13.0
redis==5.0.1

# Azure
azure-cosmos==4.5.1
azure-search-documents==11.4.0

# Web framework
fastapi==0.104.1
uvicorn==0.24.0

# Utilities
python-dotenv==1.0.0
pydantic==2.5.0
pydantic-settings==2.1.0

# Development
pytest==7.4.3
pytest-asyncio==0.21.1
black==23.11.0
mypy==1.7.0

# Monitoring
prometheus-client==0.19.0
```

## 🔧 ambiente Setup

### 1. PostgreSQL Setup

#### Option A: Local Installation
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql postgresql-contrib

# macOS
brew install postgresql
brew services start postgresql

# Windows
# Download installer from https://www.postgresql.org/download/windows/
```

#### Option B: Docker
```bash
# Run PostgreSQL container
docker run --name postgres-module09 \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -e POSTGRES_DB=workshop_db \
  -p 5432:5432 \
  -d postgres:15-alpine
```

### 2. Redis Setup

#### Option A: Local Installation
```bash
# Ubuntu/Debian
sudo apt install redis-server

# macOS
brew install redis
brew services start redis

# Windows
# Use WSL2 or Docker
```

#### Option B: Docker
```bash
# Run Redis container
docker run --name redis-module09 \
  -p 6379:6379 \
  -d redis:7-alpine
```

### 3. Create Databases
```sql
-- Connect to PostgreSQL
psql -U postgres

-- Create workshop database
CREATE DATABASE workshop_db;
CREATE DATABASE workshop_test;

-- Create user
CREATE USER workshop_user WITH PASSWORD 'workshop_pass';
GRANT ALL PRIVILEGES ON DATABASE workshop_db TO workshop_user;
GRANT ALL PRIVILEGES ON DATABASE workshop_test TO workshop_user;

-- Enable extensions
\c workshop_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgvector";
```

## 🔑 Azure Setup (Optional)

### Azure Cosmos DB
1. Create Azure Cosmos DB conta
2. Select Core (SQL) API
3. Enable vector search preview
4. Note connection string

### Azure AI Pesquisar
1. Create Azure AI Pesquisar service
2. Choose Basic tier or higher
3. Note admin key and endpoint

### ambiente Variables
Create `.env` file:
```env
# PostgreSQL
DATABASE_URL=postgresql://workshop_user:workshop_pass@localhost/workshop_db
TEST_DATABASE_URL=postgresql://workshop_user:workshop_pass@localhost/workshop_test

# Redis
REDIS_URL=redis://localhost:6379/0

# Azure (optional)
AZURE_COSMOS_ENDPOINT=https://your-cosmos.documents.azure.com:443/
AZURE_COSMOS_KEY=your-key-here
AZURE_SEARCH_ENDPOINT=https://your-search.search.windows.net
AZURE_SEARCH_KEY=your-key-here

# GitHub
GITHUB_TOKEN=your-token-here

# Application
APP_ENV=development
LOG_LEVEL=INFO
```

## 🧪 Verification Script

Run the verification script to ensure everything is set up correctly:

```python
# scripts/verify_setup.py
import sys
import subprocess
import importlib
import psycopg2
import redis
from dotenv import load_dotenv
import os

load_dotenv()

def check_python_version():
    version = sys.version_info
    if version.major &gt;= 3 and version.minor &gt;= 11:
        print("✅ Python 3.11+ installed")
        return True
    else:
        print(f"❌ Python {version.major}.{version.minor} found, need 3.11+")
        return False

def check_postgresql():
    try:
        conn = psycopg2.connect(os.getenv("DATABASE_URL"))
        cursor = conn.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        print(f"✅ PostgreSQL connected: {version.split(',')[0]}")
        
        # Check for required extensions
        cursor.execute("SELECT * FROM pg_extension WHERE extname = 'uuid-ossp';")
        if cursor.fetchone():
            print("✅ UUID extension installed")
        else:
            print("⚠️  UUID extension not installed")
            
        conn.close()
        return True
    except Exception as e:
        print(f"❌ PostgreSQL connection failed: {e}")
        return False

def check_redis():
    try:
        r = redis.from_url(os.getenv("REDIS_URL", "redis://localhost:6379/0"))
        r.ping()
        info = r.info()
        print(f"✅ Redis connected: v{info['redis_version']}")
        return True
    except Exception as e:
        print(f"❌ Redis connection failed: {e}")
        return False

def check_packages():
    required = [
        'sqlalchemy', 'psycopg2', 'alembic', 'redis',
        'fastapi', 'uvicorn', 'pydantic'
    ]
    
    all_installed = True
    for package in required:
        try:
            importlib.import_module(package.replace('-', '_'))
            print(f"✅ {package} installed")
        except ImportError:
            print(f"❌ {package} not installed")
            all_installed = False
    
    return all_installed

def check_github_copilot():
    try:
        result = subprocess.run(['gh', 'copilot', 'status'], 
                              capture_output=True, text=True)
        if result.returncode == 0:
            print("✅ GitHub Copilot active")
            return True
        else:
            print("❌ GitHub Copilot not active")
            return False
    except FileNotFoundError:
        print("❌ GitHub CLI not installed")
        return False

if __name__ == "__main__":
    print("🔍 Verifying Module 09 Prerequisites\n")
    
    checks = [
        check_python_version(),
        check_postgresql(),
        check_redis(),
        check_packages(),
        check_github_copilot()
    ]
    
    if all(checks):
        print("\n✅ All prerequisites satisfied! Ready to start Module 09")
    else:
        print("\n❌ Some prerequisites are missing. Please install missing components.")
        sys.exit(1)
```

## 🆘 Troubleshooting

### PostgreSQL Connection Issues
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql  # Linux
brew services list  # macOS

# Check PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-*.log
```

### Redis Connection Issues
```bash
# Check if Redis is running
redis-cli ping
# Should return: PONG

# Check Redis configuration
redis-cli CONFIG GET bind
redis-cli CONFIG GET protected-mode
```

### Python Package Issues
```bash
# Upgrade pip
python -m pip install --upgrade pip

# Clear pip cache
pip cache purge

# Install with verbose output
pip install -v sqlalchemy
```

## 📚 Pre-Módulo Learning

If you're new to databases, consider reviewing:
1. [SQL Tutorial - W3Schools](https://www.w3schools.com/sql/)
2. [PostgreSQL Tutorial](https://www.postgresqltutorial.com/)
3. [Redis Crash Course](https://www.youtube.com/watch?v=jgpVdJB2sKQ)
4. [Database Design Fundamentos](https://learn.microsoft.com/training/modules/design-a-database/)

## ✅ Ready to Start?

Once all prerequisites are satisfied:
1. Navigate to the exercises folder
2. Abrir VS Code in the module directory
3. Activate GitHub Copilot
4. Comece com Exercício 1!

```bash
cd exercises/exercise1-easy
code .
```

Happy learning! 🚀