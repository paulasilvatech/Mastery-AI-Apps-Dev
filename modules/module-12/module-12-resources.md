# Module 12: Scripts and Resources Collection

## 🚀 Quick Setup Script

Save as `scripts/setup-module-12.sh`:

```bash
#!/bin/bash
set -euo pipefail

# Module 12 Complete Setup Script
echo "🚀 Setting up Module 12: Cloud-Native Development"

# Configuration
export RESOURCE_GROUP="rg-workshop-module12"
export LOCATION="eastus2"
export UNIQUE_SUFFIX=$RANDOM

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    local missing=0
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker not installed${NC}"
        missing=$((missing + 1))
    else
        echo -e "${GREEN}✓ Docker installed$(docker --version)${NC}"
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}❌ kubectl not installed${NC}"
        missing=$((missing + 1))
    else
        echo -e "${GREEN}✓ kubectl installed$(kubectl version --client --short)${NC}"
    fi
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        echo -e "${RED}❌ Azure CLI not installed${NC}"
        missing=$((missing + 1))
    else
        echo -e "${GREEN}✓ Azure CLI installed$(az --version | head -n 1)${NC}"
    fi
    
    # Check Python
    if ! python3 --version &> /dev/null; then
        echo -e "${RED}❌ Python 3 not installed${NC}"
        missing=$((missing + 1))
    else
        echo -e "${GREEN}✓ Python installed$(python3 --version)${NC}"
    fi
    
    # Check Azure Functions Core Tools
    if ! command -v func &> /dev/null; then
        echo -e "${RED}❌ Azure Functions Core Tools not installed${NC}"
        missing=$((missing + 1))
    else
        echo -e "${GREEN}✓ Azure Functions Core Tools installed$(func --version)${NC}"
    fi
    
    if [ $missing -gt 0 ]; then
        echo -e "${RED}Please install missing prerequisites before continuing.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ All prerequisites met!${NC}"
}

# Setup Python environment
setup_python_env() {
    echo -e "${YELLOW}Setting up Python environment...${NC}"
    
    python3 -m venv venv
    source venv/bin/activate
    
    pip install --upgrade pip
    pip install -r requirements.txt
    
    echo -e "${GREEN}✓ Python environment ready${NC}"
}

# Create directory structure
create_directories() {
    echo -e "${YELLOW}Creating project structure...${NC}"
    
    mkdir -p {exercises,scripts,kubernetes,docker,functions,tests,docs}
    mkdir -p exercises/{exercise1-containerize,exercise2-kubernetes,exercise3-serverless}
    mkdir -p exercises/exercise1-containerize/{src,tests,starter,solution}
    mkdir -p exercises/exercise2-kubernetes/{manifests,scripts}
    mkdir -p exercises/exercise3-serverless/{functions,shared,tests}
    
    echo -e "${GREEN}✓ Directory structure created${NC}"
}

# Login to Azure
azure_login() {
    echo -e "${YELLOW}Checking Azure login...${NC}"
    
    if ! az account show &> /dev/null; then
        echo "Please login to Azure:"
        az login
    fi
    
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    echo -e "${GREEN}✓ Logged in to Azure (Subscription: $SUBSCRIPTION_ID)${NC}"
}

# Create resource group
create_resource_group() {
    echo -e "${YELLOW}Creating resource group...${NC}"
    
    az group create \
        --name $RESOURCE_GROUP \
        --location $LOCATION \
        --output none
    
    echo -e "${GREEN}✓ Resource group created: $RESOURCE_GROUP${NC}"
}

# Main setup
main() {
    echo "======================================"
    echo "Module 12: Cloud-Native Development"
    echo "======================================"
    echo ""
    
    check_prerequisites
    create_directories
    azure_login
    create_resource_group
    setup_python_env
    
    echo ""
    echo -e "${GREEN}✅ Module 12 setup complete!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. cd exercises/exercise1-containerize"
    echo "2. Start with Exercise 1: Containerization"
    echo ""
    echo "Resource Group: $RESOURCE_GROUP"
    echo "Location: $LOCATION"
    echo ""
}

# Run main
main
```

## 📦 Python Requirements

Save as `requirements.txt`:

```txt
# Web Framework
fastapi==0.109.0
uvicorn[standard]==0.27.0
pydantic==2.5.3
pydantic-settings==2.1.0

# Azure SDKs
azure-functions==1.17.0
azure-storage-blob==12.19.0
azure-identity==1.15.0
azure-cosmos==4.5.1
azure-servicebus==7.11.4
azure-eventgrid==4.16.0
azure-eventhub==5.11.5
azure-monitor-opentelemetry==1.2.0

# Database
asyncpg==0.29.0
sqlalchemy[asyncio]==2.0.25
alembic==1.13.1

# Caching
redis==5.0.1
hiredis==2.3.2

# Monitoring
prometheus-client==0.19.0
opentelemetry-api==1.22.0
opentelemetry-sdk==1.22.0
opentelemetry-instrumentation-fastapi==0.43b0
opencensus-ext-azure==1.1.13

# Testing
pytest==7.4.4
pytest-asyncio==0.23.3
pytest-cov==4.1.0
pytest-mock==3.12.0
httpx==0.26.0

# Development
python-dotenv==1.0.0
black==23.12.1
isort==5.13.2
mypy==1.8.0
pre-commit==3.6.0

# Utilities
pyyaml==6.0.1
python-multipart==0.0.6
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
tenacity==8.2.3
circuitbreaker==2.0.0
```

## 🐳 Docker Compose Override

Save as `docker-compose.override.yml` for development:

```yaml
version: '3.9'

services:
  api:
    build:
      context: .
      target: development
      cache_from:
        - python:3.11-slim
    environment:
      - ENVIRONMENT=development
      - LOG_LEVEL=debug
      - RELOAD=true
    volumes:
      - ./src:/app:ro
      - ./tests:/tests:ro
    command: ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

  db:
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_PASSWORD=devpassword123!

  redis:
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes --requirepass devpassword123!

  # Development tools
  pgadmin:
    image: dpage/pgadmin4:latest
    environment:
      - PGADMIN_DEFAULT_EMAIL=admin@example.com
      - PGADMIN_DEFAULT_PASSWORD=admin
    ports:
      - "8080:80"
    depends_on:
      - db
    networks:
      - app-network

  redis-commander:
    image: rediscommander/redis-commander:latest
    environment:
      - REDIS_HOSTS=local:redis:6379:0:devpassword123!
    ports:
      - "8081:8081"
    depends_on:
      - redis
    networks:
      - app-network
```

## ⚙️ GitHub Actions Workflow

Save as `.github/workflows/module-12-ci-cd.yml`:

```yaml
name: Module 12 CI/CD

on:
  push:
    branches: [main, develop]
    paths:
      - 'modules/module-12/**'
  pull_request:
    branches: [main]
    paths:
      - 'modules/module-12/**'

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}/module-12-product-catalog
  PYTHON_VERSION: '3.11'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}
    
    - name: Cache dependencies
      uses: actions/cache@v3
      with:
        path: ~/.cache/pip
        key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install pytest-cov
    
    - name: Run tests
      run: |
        pytest tests/ -v --cov=src --cov-report=xml
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml

  build:
    needs: test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Log in to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=semver,pattern={{version}}
          type=sha
    
    - name: Build and push
      uses: docker/build-push-action@v5
      with:
        context: ./modules/module-12
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache
        cache-to: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache,mode=max

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Set up kubectl
      uses: azure/setup-kubectl@v3
    
    - name: Get AKS credentials
      run: |
        az aks get-credentials \
          --resource-group rg-workshop-module12 \
          --name aks-workshop-module12
    
    - name: Deploy to AKS
      run: |
        kubectl apply -f ./modules/module-12/kubernetes/
        kubectl rollout status deployment/product-catalog -n production
```

## 🧪 Test Utilities

Save as `tests/test_helpers.py`:

```python
import asyncio
import pytest
from typing import AsyncGenerator
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from src.main import app
from src.database import Base

# Test database URL
TEST_DATABASE_URL = "postgresql+asyncpg://postgres:postgres@localhost:5432/test_db"

@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(scope="session")
async def engine():
    """Create test database engine."""
    engine = create_async_engine(TEST_DATABASE_URL, echo=True)
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    yield engine
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    
    await engine.dispose()

@pytest.fixture
async def db_session(engine) -> AsyncGenerator[AsyncSession, None]:
    """Create a test database session."""
    async_session_maker = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )
    
    async with async_session_maker() as session:
        yield session

@pytest.fixture
async def client(db_session) -> AsyncGenerator[AsyncClient, None]:
    """Create a test client."""
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

@pytest.fixture
def sample_product():
    """Sample product data for testing."""
    return {
        "name": "Test Product",
        "description": "A product for testing",
        "price": 99.99,
        "stock": 100,
        "category": "test"
    }

# Helper functions
async def create_test_product(client: AsyncClient, product_data: dict):
    """Create a product and return the response."""
    response = await client.post("/products", json=product_data)
    assert response.status_code == 201
    return response.json()

async def wait_for_condition(condition_func, timeout=30, interval=1):
    """Wait for a condition to be true."""
    start_time = asyncio.get_event_loop().time()
    while asyncio.get_event_loop().time() - start_time < timeout:
        if await condition_func():
            return True
        await asyncio.sleep(interval)
    return False
```

## 🔍 Monitoring Queries

Save as `monitoring/queries.md`:

```markdown
# Prometheus Queries for Module 12

## Request Rate
```promql
sum(rate(http_requests_total[5m])) by (endpoint)
```

## Error Rate
```promql
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))
```

## P95 Latency
```promql
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, endpoint))
```

## Active Requests
```promql
http_requests_active
```

## Pod CPU Usage
```promql
sum(rate(container_cpu_usage_seconds_total{namespace="production",pod=~"product-catalog-.*"}[5m])) by (pod)
```

## Pod Memory Usage
```promql
sum(container_memory_usage_bytes{namespace="production",pod=~"product-catalog-.*"}) by (pod)
```

# Grafana Dashboard JSON

```json
{
  "dashboard": {
    "title": "Module 12 - Product Catalog Service",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total[5m])) by (endpoint)"
          }
        ]
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m]))"
          }
        ]
      }
    ]
  }
}
```
```

## 🚦 Validation Script

Save as `scripts/validate-deployment.sh`:

```bash
#!/bin/bash
set -euo pipefail

# Validation script for Module 12 deployment
echo "🔍 Validating Module 12 Deployment..."

# Configuration
NAMESPACE="production"
SERVICE_NAME="product-catalog-service"
EXPECTED_REPLICAS=3

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check Kubernetes deployment
check_kubernetes() {
    echo -e "${YELLOW}Checking Kubernetes resources...${NC}"
    
    # Check deployment
    READY_REPLICAS=$(kubectl get deployment product-catalog -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
    if [ "$READY_REPLICAS" -ge "$EXPECTED_REPLICAS" ]; then
        echo -e "${GREEN}✓ Deployment ready: $READY_REPLICAS/$EXPECTED_REPLICAS replicas${NC}"
    else
        echo -e "${RED}✗ Deployment not ready: $READY_REPLICAS/$EXPECTED_REPLICAS replicas${NC}"
        return 1
    fi
    
    # Check service
    if kubectl get svc $SERVICE_NAME -n $NAMESPACE &> /dev/null; then
        echo -e "${GREEN}✓ Service exists${NC}"
    else
        echo -e "${RED}✗ Service not found${NC}"
        return 1
    fi
    
    # Check ingress
    INGRESS_IP=$(kubectl get ingress product-catalog-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -n "$INGRESS_IP" ]; then
        echo -e "${GREEN}✓ Ingress configured: $INGRESS_IP${NC}"
    else
        echo -e "${YELLOW}⚠ Ingress IP not yet assigned${NC}"
    fi
}

# Check application health
check_application() {
    echo -e "${YELLOW}Checking application health...${NC}"
    
    # Port forward to test
    kubectl port-forward -n $NAMESPACE svc/$SERVICE_NAME 8080:80 &
    PF_PID=$!
    sleep 5
    
    # Test health endpoint
    if curl -s http://localhost:8080/health | grep -q "healthy"; then
        echo -e "${GREEN}✓ Health check passed${NC}"
    else
        echo -e "${RED}✗ Health check failed${NC}"
    fi
    
    # Test API endpoint
    if curl -s http://localhost:8080/products | grep -q "\["; then
        echo -e "${GREEN}✓ API responding${NC}"
    else
        echo -e "${RED}✗ API not responding${NC}"
    fi
    
    # Clean up port forward
    kill $PF_PID 2>/dev/null || true
}

# Check Azure Functions
check_functions() {
    echo -e "${YELLOW}Checking Azure Functions...${NC}"
    
    FUNCTION_APP=$(az functionapp list -g rg-workshop-module12 --query "[0].name" -o tsv)
    if [ -n "$FUNCTION_APP" ]; then
        echo -e "${GREEN}✓ Function App found: $FUNCTION_APP${NC}"
        
        # Check function status
        STATE=$(az functionapp show -n $FUNCTION_APP -g rg-workshop-module12 --query "state" -o tsv)
        if [ "$STATE" = "Running" ]; then
            echo -e "${GREEN}✓ Function App running${NC}"
        else
            echo -e "${RED}✗ Function App not running: $STATE${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ No Function App found (OK if not at Exercise 3)${NC}"
    fi
}

# Main validation
main() {
    local errors=0
    
    check_kubernetes || ((errors++))
    check_application || ((errors++))
    check_functions || ((errors++))
    
    echo ""
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}✅ All validation checks passed!${NC}"
        return 0
    else
        echo -e "${RED}❌ Validation failed with $errors errors${NC}"
        return 1
    fi
}

main
```

## 📝 VS Code Settings

Save as `.vscode/settings.json`:

```json
{
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": false,
  "python.linting.flake8Enabled": true,
  "python.linting.mypyEnabled": true,
  "python.formatting.provider": "black",
  "python.testing.pytestEnabled": true,
  "python.testing.pytestArgs": [
    "tests"
  ],
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.organizeImports": true
  },
  "[python]": {
    "editor.rulers": [88]
  },
  "files.exclude": {
    "**/__pycache__": true,
    "**/*.pyc": true,
    ".pytest_cache": true,
    ".coverage": true,
    "htmlcov": true
  },
  "docker.defaultRegistryPath": "acrworkshop.azurecr.io",
  "kubernetes.enable-helm": true,
  "azure.tenant": "${env:AZURE_TENANT_ID}",
  "github.copilot.enable": {
    "*": true,
    "yaml": true,
    "plaintext": true,
    "markdown": true,
    "dockerfile": true
  }
}
```

## 🎯 Module Completion Checklist

Save as `CHECKLIST.md`:

```markdown
# Module 12 Completion Checklist

## Exercise 1: Containerization ⭐
- [ ] FastAPI microservice created
- [ ] Multi-stage Dockerfile implemented
- [ ] Health checks working
- [ ] Docker Compose running locally
- [ ] Security scan passing
- [ ] All tests passing

## Exercise 2: Kubernetes Deployment ⭐⭐
- [ ] AKS cluster created
- [ ] Application deployed to Kubernetes
- [ ] Ingress configured and accessible
- [ ] HPA scaling based on load
- [ ] Monitoring with Prometheus/Grafana
- [ ] Zero-downtime deployment tested

## Exercise 3: Serverless Events ⭐⭐⭐
- [ ] Azure Functions deployed
- [ ] Event Grid routing configured
- [ ] Order processing flow working
- [ ] Durable orchestration tested
- [ ] Analytics pipeline operational
- [ ] End-to-end integration verified

## Best Practices Applied
- [ ] Container security hardening
- [ ] Resource limits configured
- [ ] Secrets managed properly
- [ ] Monitoring implemented
- [ ] Documentation complete
- [ ] CI/CD pipeline working

## Performance Targets Met
- [ ] Container size < 150MB
- [ ] Cold start < 3 seconds
- [ ] API response time < 200ms (p95)
- [ ] Can handle 1000+ RPS
- [ ] 99.9% uptime achieved
- [ ] Auto-scaling working

## Learning Objectives Achieved
- [ ] Understand containerization principles
- [ ] Can deploy to Kubernetes confidently
- [ ] Know serverless patterns
- [ ] Can build event-driven systems
- [ ] Understand cloud-native architecture
- [ ] Ready for production workloads

## Final Project Submitted
- [ ] All code committed to GitHub
- [ ] README with architecture diagram
- [ ] Performance test results included
- [ ] Cost analysis documented
- [ ] Lessons learned summarized
```

---

## 🎉 Congratulations!

You now have all the resources needed to complete Module 12. These scripts and configurations will help you build production-ready cloud-native applications. Remember to clean up Azure resources after completing the module to avoid unnecessary charges.

**Happy Cloud-Native Development!** 🚀