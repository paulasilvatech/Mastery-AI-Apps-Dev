---
sidebar_position: 7
title: "Exercise 1: Part 1"
description: "## Overview"
---

# Ejercicio 1: Containerize a Python Microservice ⭐

## Resumen

In this foundational exercise, you'll containerize a Python microservice using Docker, leveraging GitHub Copilot to generate optimized Dockerfiles, implement health checks, and ensure graceful shutdown. This exercise establishes the containerization patterns you'll use throughout your cloud-native journey.

**Duración**: 30-45 minutos  
**Difficulty**: Fácil (⭐)  
**Success Rate**: 95%

## 🎯 Objetivos de Aprendizaje

Al completar este ejercicio, usted:

1. Create multi-stage Dockerfiles with Copilot assistance
2. Implement container health checks and readiness probes
3. Optimize container size and build times
4. Handle graceful shutdown and signal management
5. Use Docker Compose for local desarrollo
6. Implement container security best practices

## 📋 Prerrequisitos

- Docker Desktop running
- Python 3.11+ instalado
- VS Code with GitHub Copilot
- Basic understanding of REST APIs
- Completard Módulo 11

## 🏗️ Architecture

```mermaid
graph TD
    A[Python FastAPI Service] --&gt; B[Multi-stage Dockerfile]
    B --&gt; C[Optimized Container Image]
    C --&gt; D[Health Check Endpoint]
    C --&gt; E[Graceful Shutdown]
    C --&gt; F[Security Scanning]
    
    G[Docker Compose] --&gt; H[Local PostgreSQL]
    G --&gt; I[Local Redis]
    G --&gt; C
    
    style A fill:#f9f,stroke:#333,stroke-width:2px
    style C fill:#9ff,stroke:#333,stroke-width:2px
    style G fill:#ff9,stroke:#333,stroke-width:2px
```

## 📝 Scenario

You're tasked with containerizing a product catalog microservice that:
- Serves product information via REST API
- Connects to PostgreSQL for data storage
- Uses Redis for caching
- Must handle 1000+ requests per second
- Requires zero-downtime despliegues
- Needs security compliance

## 🚀 Partee 1: Project Setup

### Step 1: Initialize Project Structure

```bash
# Create exercise directory
mkdir -p exercise1-containerize/src
cd exercise1-containerize

# Initialize Python project
python -m venv venv
source venv/bin/activate  # Windows: .\venv\Scripts\activate
```

### Step 2: Create the Microservice

**Copilot Prompt Suggestion:**
```python
# Create a FastAPI microservice for product catalog that:
# - Has endpoints for CRUD operations on products
# - Implements health and readiness checks
# - Uses Pydantic for data validation
# - Includes proper error handling
# - Has OpenAPI documentation
# - Implements logging with structured format
# File: src/main.py
```

**Expected Output:**
```python
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
import logging
import sys
import signal
import asyncio
import os
from contextlib import asynccontextmanager

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)

# Pydantic models
class Product(BaseModel):
    id: Optional[int] = None
    name: str = Field(..., min_length=1, max_length=100)
    description: str = Field(..., max_length=500)
    price: float = Field(..., gt=0)
    stock: int = Field(..., ge=0)
    category: str
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

class HealthCheck(BaseModel):
    status: str
    timestamp: datetime
    version: str
    uptime: float

# Global state
app_start_time = datetime.now()
shutdown_event = asyncio.Event()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting Product Catalog Service")
    yield
    # Shutdown
    logger.info("Shutting down Product Catalog Service")

# Create FastAPI app
app = FastAPI(
    title="Product Catalog Service",
    description="Cloud-native microservice for product management",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory storage (will be replaced with database)
products_db = {}
product_counter = 0

# Health check endpoint
@app.get("/health", response_model=HealthCheck)
async def health_check():
    """Health check endpoint for container orchestration"""
    uptime = (datetime.now() - app_start_time).total_seconds()
    return HealthCheck(
        status="healthy",
        timestamp=datetime.now(),
        version="1.0.0",
        uptime=uptime
    )

# Readiness check endpoint
@app.get("/ready")
async def readiness_check():
    """Readiness probe for Kubernetes"""
    # Check database connection (placeholder)
    # Check Redis connection (placeholder)
    return {{"status": "ready", "timestamp": datetime.now()}}

# CRUD Operations
@app.get("/products", response_model=List[Product])
async def list_products(skip: int = 0, limit: int = 100):
    """List all products with pagination"""
    logger.info(f"Listing products: skip={skip}, limit={limit}")
    products = list(products_db.values())[skip:skip + limit]
    return products

@app.get("/products/{product_id}", response_model=Product)
async def get_product(product_id: int):
    """Get a specific product by ID"""
    if product_id not in products_db:
        logger.warning(f"Product not found: {product_id}")
        raise HTTPException(status_code=404, detail="Product not found")
    return products_db[product_id]

@app.post("/products", response_model=Product, status_code=201)
async def create_product(product: Product):
    """Create a new product"""
    global product_counter
    product_counter += 1
    product.id = product_counter
    product.created_at = datetime.now()
    product.updated_at = product.created_at
    products_db[product.id] = product
    logger.info(f"Created product: {product.id}")
    return product

@app.put("/products/{product_id}", response_model=Product)
async def update_product(product_id: int, product: Product):
    """Update an existing product"""
    if product_id not in products_db:
        raise HTTPException(status_code=404, detail="Product not found")
    
    existing = products_db[product_id]
    product.id = product_id
    product.created_at = existing.created_at
    product.updated_at = datetime.now()
    products_db[product_id] = product
    logger.info(f"Updated product: {product_id}")
    return product

@app.delete("/products/{product_id}")
async def delete_product(product_id: int):
    """Delete a product"""
    if product_id not in products_db:
        raise HTTPException(status_code=404, detail="Product not found")
    
    del products_db[product_id]
    logger.info(f"Deleted product: {product_id}")
    return {{"message": "Product deleted successfully"}}

# Graceful shutdown handler
def handle_sigterm(signum, frame):
    logger.info("Received SIGTERM, initiating graceful shutdown")
    shutdown_event.set()

signal.signal(signal.SIGTERM, handle_sigterm)

if __name__ == "__main__":
    import uvicorn
    
    # Run with Uvicorn
    config = uvicorn.Config(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info",
        access_log=True
    )
    server = uvicorn.Server(config)
    
    try:
        server.run()
    except KeyboardInterrupt:
        logger.info("Received interrupt, shutting down gracefully")
```

### Step 3: Create Requirements File

**Copilot Prompt Suggestion:**
```python
# Create requirements.txt for the FastAPI microservice with:
# - FastAPI and Uvicorn for web framework
# - Pydantic for validation
# - PostgreSQL and Redis clients
# - Testing dependencies
# - Monitoring/metrics libraries
# Use specific versions for reproducibility
```

**Expected Output:**
```txt
# Web framework
fastapi==0.109.0
uvicorn[standard]==0.27.0
pydantic==2.5.3
pydantic-settings==2.1.0

# Database
asyncpg==0.29.0
sqlalchemy==2.0.25
alembic==1.13.1

# Caching
redis==5.0.1
hiredis==2.3.2

# Monitoring
prometheus-client==0.19.0
opentelemetry-api==1.22.0
opentelemetry-sdk==1.22.0
opentelemetry-instrumentation-fastapi==0.43b0

# Testing
pytest==7.4.4
pytest-asyncio==0.23.3
pytest-cov==4.1.0
httpx==0.26.0

# Development
python-dotenv==1.0.0
black==23.12.1
isort==5.13.2
mypy==1.8.0

# Security
python-multipart==0.0.6
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
```

## 🔨 Partee 2: Dockerfile Creation

### Step 4: Create Multi-Stage Dockerfile

**Copilot Prompt Suggestion:**
```dockerfile
# Create a multi-stage Dockerfile for Python FastAPI service that:
# - Uses official Python 3.11 slim image
# - Implements security best practices (non-root user)
# - Optimizes for size with multi-stage build
# - Includes health check instruction
# - Sets proper signals for graceful shutdown
# - Uses build cache efficiently
# - Handles pip dependencies with cache mount
# File: Dockerfile
```

**Expected Output:**
```dockerfile
# syntax=docker/dockerfile:1

# Build stage
FROM python:3.11-slim AS builder

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better cache utilization
COPY requirements.txt .

# Install Python dependencies with cache mount
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.11-slim AS runtime

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY --chown=appuser:appuser ./src .

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/app \
    PORT=8000

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Use exec form for proper signal handling
ENTRYPOINT ["python", "-m", "uvicorn"]
CMD ["main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Step 5: Create .dockerignore

**Copilot Prompt Suggestion:**
```
# Create .dockerignore file that excludes:
# - Python cache and virtual environments
# - IDE and editor files
# - Test files and coverage reports
# - Version control files
# - Documentation
# - Local environment files
```

**Expected Output:**
```dockerignore
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
ENV/
.venv
pip-log.txt
pip-delete-this-directory.txt
.pytest_cache/
.coverage
htmlcov/
.tox/
*.egg-info/
dist/
build/

# IDEs
.vscode/
.idea/
*.swp
*.swo
.DS_Store

# Project
.git/
.gitignore
README.md
docs/
tests/
.env
.env.*
docker-compose*.yml
Dockerfile*

# CI/CD
.github/
.gitlab-ci.yml
.travis.yml
```

---

**Continue to Part 2** for Docker Compose setup, security scanning, and testing...