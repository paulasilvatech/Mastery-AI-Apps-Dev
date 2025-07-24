---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 17"
---

# Módulo 17: Prerrequisitos and Setup

## 📋 Required Knowledge

Before starting Módulo 17, you should have completed:

### Anterior Módulos
- ✅ **Módulo 16**: Security Implementation
- ✅ **Módulo 14**: CI/CD with GitHub Actions
- ✅ **Módulo 12**: Cloud-Native Development
- ✅ **Módulo 8**: API Development and Integration

### Technical Concepts
You should be comfortable with:
- RESTful API design and implementation
- Asynchronous programming in Python
- JSON data manipulation
- Basic understanding of machine learning concepts
- Cloud service integration
- Security best practices (API keys, authentication)

## 🛠️ Software Requirements

### Local desarrollo ambiente

```bash
# Check Python version (3.11+ required)
python --version

# Check pip version
pip --version

# Check Git
git --version  # Should be 2.38+

# Check Docker
docker --version  # Should be 24+

# Check Node.js (for some tools)
node --version  # Should be 18+
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

# Upgrade pip
pip install --upgrade pip

# Install requirements
pip install -r requirements.txt
```

**requirements.txt**:
```txt
# Core AI/ML packages
openai==1.3.0
langchain==0.0.350
semantic-kernel==0.4.0
tiktoken==0.5.2
numpy==1.26.2
pandas==2.1.4

# Vector databases and search
chromadb==0.4.22
faiss-cpu==1.7.4
azure-search-documents==11.4.0

# API and web frameworks
fastapi==0.104.1
uvicorn[standard]==0.24.0
streamlit==1.29.0
gradio==4.10.0

# Azure integration
azure-identity==1.15.0
azure-storage-blob==12.19.0
azure-cosmos==4.5.1
azure-monitor-opentelemetry==1.1.1

# Utilities
python-dotenv==1.0.0
pydantic==2.5.0
httpx==0.25.2
tenacity==8.2.3
rich==13.7.0

# Testing and development
pytest==7.4.3
pytest-asyncio==0.21.1
pytest-mock==3.12.0
black==23.12.0
ruff==0.1.9

# Documentation and evaluation
rouge-score==0.1.2
bert-score==0.3.13
ragas==0.0.22
```

### VS Code Extensions
Ensure these extensions are instalado:
- GitHub Copilot
- GitHub Copilot Chat
- Python
- Pylance
- Jupyter
- REST Client
- Docker
- Azure Tools
- GitHub Pull Requests and Issues

## 🔑 API Access Setup

### 1. GitHub Models Access

```bash
# Verify GitHub CLI is installed
gh --version

# Authenticate with GitHub
gh auth login

# Check authentication status
gh auth status
```

To get GitHub Models access:
1. Visit [GitHub Models](https://github.com/marketplace/models)
2. Join the waitlist if needed
3. Once approved, get your API token:
   ```bash
   gh auth token
   ```

### 2. Azure AbrirAI Setup

```bash
# Login to Azure
az login

# Create resource group
az group create \
  --name "rg-workshop-module17" \
  --location "eastus"

# Create Azure OpenAI resource
az cognitiveservices account create \
  --name "openai-module17-$RANDOM" \
  --resource-group "rg-workshop-module17" \
  --kind "OpenAI" \
  --sku "S0" \
  --location "eastus" \
  --yes

# Deploy models
# Deploy GPT-4
az cognitiveservices account deployment create \
  --name "openai-module17-xxxxx" \
  --resource-group "rg-workshop-module17" \
  --deployment-name "gpt-4" \
  --model-name "gpt-4" \
  --model-version "0613" \
  --model-format "OpenAI" \
  --scale-settings-scale-type "Standard"

# Deploy embeddings model
az cognitiveservices account deployment create \
  --name "openai-module17-xxxxx" \
  --resource-group "rg-workshop-module17" \
  --deployment-name "text-embedding-ada-002" \
  --model-name "text-embedding-ada-002" \
  --model-version "2" \
  --model-format "OpenAI" \
  --scale-settings-scale-type "Standard"
```

### 3. Azure AI Buscar Setup (for vector Buscar)

```bash
# Create Azure AI Search service
az search service create \
  --name "search-module17-$RANDOM" \
  --resource-group "rg-workshop-module17" \
  --sku "basic" \
  --location "eastus"

# Get admin key
az search admin-key show \
  --service-name "search-module17-xxxxx" \
  --resource-group "rg-workshop-module17"
```

### 4. Cosmos DB Setup (alternative vector store)

```bash
# Create Cosmos DB account with MongoDB API
az cosmosdb create \
  --name "cosmos-module17-$RANDOM" \
  --resource-group "rg-workshop-module17" \
  --kind MongoDB \
  --server-version "6.0" \
  --default-consistency-level "Session" \
  --enable-free-tier false \
  --capabilities EnableMongoDBVectorSearch

# Get connection string
az cosmosdb keys list \
  --name "cosmos-module17-xxxxx" \
  --resource-group "rg-workshop-module17" \
  --type connection-strings
```

## 🔧 ambiente Configuration

### Create .env file

```bash
# Copy template
cp .env.example .env
```

**.env.example**:
```env
# GitHub Models
GITHUB_TOKEN=your_github_token_here
GITHUB_MODELS_ENDPOINT=https://models.inference.ai.azure.com

# Azure OpenAI
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_API_KEY=your_api_key_here
AZURE_OPENAI_API_VERSION=2023-12-01-preview
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4
AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT=text-embedding-ada-002

# Azure AI Search
AZURE_SEARCH_ENDPOINT=https://your-search-service.search.windows.net
AZURE_SEARCH_KEY=your_admin_key_here
AZURE_SEARCH_INDEX_NAME=module17-vectors

# Cosmos DB (optional)
COSMOS_CONNECTION_STRING=your_connection_string_here
COSMOS_DATABASE_NAME=module17
COSMOS_COLLECTION_NAME=vectors

# Application Settings
EMBEDDING_MODEL=text-embedding-ada-002
CHUNK_SIZE=1000
CHUNK_OVERLAP=200
VECTOR_DIMENSION=1536
CACHE_TTL_SECONDS=3600

# Monitoring
APPLICATIONINSIGHTS_CONNECTION_STRING=your_connection_string_here
LOG_LEVEL=INFO
```

## 🐳 Docker Setup

### docker-compose.yml
```yaml
version: '3.8'

services:
  # Local vector database for development
  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
    volumes:
      - qdrant_data:/qdrant/storage

  # Redis for caching
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  # PostgreSQL for metadata
  postgres:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_USER: workshop
      POSTGRES_PASSWORD: workshop123
      POSTGRES_DB: ai_workshop
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  # Streamlit app
  streamlit:
    build:
      context: .
      dockerfile: Dockerfile.streamlit
    ports:
      - "8501:8501"
    environment:
      - GITHUB_TOKEN=${GITHUB_TOKEN}
      - AZURE_OPENAI_ENDPOINT=${AZURE_OPENAI_ENDPOINT}
      - AZURE_OPENAI_API_KEY=${AZURE_OPENAI_API_KEY}
    volumes:
      - ./app:/app
    depends_on:
      - redis
      - qdrant

volumes:
  qdrant_data:
  redis_data:
  postgres_data:
```

## 🔍 Verification Scripts

### setup-Módulo17.sh
```bash
#!/bin/bash

echo "🚀 Setting up Module 17 environment..."

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Check prerequisites
check_command() {
    if command -v $1 &&gt; /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is not installed"
        return 1
    fi
}

echo "Checking prerequisites..."
check_command python3
check_command pip
check_command docker
check_command git
check_command az

# Create virtual environment
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install requirements
echo "Installing Python packages..."
pip install -r requirements.txt

# Create directories
mkdir -p data/documents
mkdir -p data/embeddings
mkdir -p logs
mkdir -p models

# Start Docker services
echo "Starting Docker services..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 10

# Verify services
echo -e "\n${GREEN}Checking service health...${NC}"
curl -s http://localhost:6333/health | jq . || echo "Qdrant not ready"
redis-cli ping || echo "Redis not ready"

echo -e "\n${GREEN}✅ Setup complete!${NC}"
echo "Next steps:"
echo "1. Copy .env.example to .env and fill in your API keys"
echo "2. Run 'python scripts/verify-setup.py' to verify everything is working"
echo "3. Start with Exercise 1"
```

### verify-setup.py
```python
#!/usr/bin/env python3
"""Verify Module 17 setup and prerequisites."""

import sys
import os
import importlib.util
from typing import Tuple
import httpx
import asyncio
from rich.console import Console
from rich.table import Table
from dotenv import load_dotenv

console = Console()
load_dotenv()

def check_python_package(package: str) -&gt; Tuple[bool, str]:
    """Check if a Python package is installed."""
    spec = importlib.util.find_spec(package)
    if spec is not None:
        try:
            module = importlib.import_module(package)
            version = getattr(module, "__version__", "unknown")
            return True, f"v{version}"
        except:
            return True, "installed"
    return False, "not installed"

def check_env_var(var_name: str) -&gt; Tuple[bool, str]:
    """Check if an environment variable is set."""
    value = os.getenv(var_name)
    if value and value != f"your_{var_name.lower()}_here":
        return True, "configured"
    return False, "not configured"

async def check_github_models() -&gt; Tuple[bool, str]:
    """Check GitHub Models API access."""
    token = os.getenv("GITHUB_TOKEN")
    if not token:
        return False, "No token"
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                "https://api.github.com/user",
                headers={"Authorization": f"Bearer {token}"}
            )
            if response.status_code == 200:
                return True, "authenticated"
            return False, f"Error {response.status_code}"
    except Exception as e:
        return False, str(e)

async def check_azure_openai() -&gt; Tuple[bool, str]:
    """Check Azure OpenAI connectivity."""
    endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
    key = os.getenv("AZURE_OPENAI_API_KEY")
    
    if not endpoint or not key:
        return False, "Not configured"
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{endpoint}/openai/models?api-version=2023-12-01-preview",
                headers={"api-key": key}
            )
            if response.status_code == 200:
                return True, "connected"
            return False, f"Error {response.status_code}"
    except Exception as e:
        return False, str(e)

async def check_vector_db() -&gt; Tuple[bool, str]:
    """Check vector database connectivity."""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get("http://localhost:6333/health")
            if response.status_code == 200:
                return True, "healthy"
            return False, f"Error {response.status_code}"
    except:
        return False, "not running"

async def main():
    """Run all verification checks."""
    console.print("\n[bold cyan]🔍 Verifying Module 17 Prerequisites[/bold cyan]\n")
    
    # Create results table
    table = Table(title="Setup Status")
    table.add_column("Component", style="cyan")
    table.add_column("Status", style="green")
    table.add_column("Details", style="yellow")
    
    # Check Python packages
    packages = [
        "openai", "langchain", "fastapi", 
        "chromadb", "streamlit", "semantic_kernel"
    ]
    
    console.print("[bold]Checking Python packages...[/bold]")
    all_packages_ok = True
    for package in packages:
        success, version = check_python_package(package)
        status = "✅" if success else "❌"
        table.add_row(f"Python: {package}", status, version)
        if not success:
            all_packages_ok = False
    
    # Check environment variables
    console.print("\n[bold]Checking environment variables...[/bold]")
    env_vars = [
        "GITHUB_TOKEN",
        "AZURE_OPENAI_ENDPOINT",
        "AZURE_OPENAI_API_KEY",
        "AZURE_SEARCH_ENDPOINT",
        "AZURE_SEARCH_KEY"
    ]
    
    all_env_ok = True
    for var in env_vars:
        success, status = check_env_var(var)
        icon = "✅" if success else "❌"
        table.add_row(f"Env: {var}", icon, status)
        if not success:
            all_env_ok = False
    
    # Check services
    console.print("\n[bold]Checking services...[/bold]")
    
    # GitHub Models
    success, status = await check_github_models()
    icon = "✅" if success else "❌"
    table.add_row("GitHub Models API", icon, status)
    
    # Azure OpenAI
    success, status = await check_azure_openai()
    icon = "✅" if success else "❌"
    table.add_row("Azure OpenAI", icon, status)
    
    # Vector DB
    success, status = await check_vector_db()
    icon = "✅" if success else "❌"
    table.add_row("Vector Database", icon, status)
    
    # Display results
    console.print("\n")
    console.print(table)
    
    # Summary
    console.print("\n[bold]Summary:[/bold]")
    if all_packages_ok and all_env_ok:
        console.print("✅ [green]All prerequisites satisfied! You're ready to start Module 17.[/green]")
    else:
        console.print("❌ [red]Some prerequisites are missing. Please check the setup guide.[/red]")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())
```

## 🚨 Common Setup Issues

### Issue: GitHub Models Access Denied
```bash
# Solution: Ensure you're on the waitlist
# Visit: https://github.com/marketplace/models
# Check your access status
```

### Issue: Azure AbrirAI Quota Exceeded
```bash
# Solution: Check your quota
az cognitiveservices account show \
  --name "your-openai-resource" \
  --resource-group "rg-workshop-module17" \
  --query "properties.quota"

# Request quota increase if needed
```

### Issue: Vector Database Connection Failed
```bash
# Solution: Ensure Docker is running
docker ps

# Restart services
docker-compose down
docker-compose up -d

# Check logs
docker-compose logs qdrant
```

## ✅ Ready to Start?

Once all prerequisites are satisfied:

1. Ensure all services are running:
   ```bash
   docker-compose ps
   python scripts/verify-setup.py
   ```

2. Test API connections:
   ```bash
   # Test GitHub Models
   python scripts/test-github-models.py

   # Test Azure OpenAI
   python scripts/test-azure-openai.py
   ```

3. Comience con Ejercicio 1:
   ```bash
   cd exercises/exercise1-foundation
   code .
   ```

Happy learning! 🚀