---
sidebar_position: 2
title: "Exercise 1: Part 2"
description: "## 🐳 Part 3: Docker Compose Development"
---

# Exercício 1: Containerize a Python Microservice ⭐ (Partee 2)

## 🐳 Partee 3: Docker Compose desenvolvimento

### Step 6: Create Docker Compose Configuration

**Copilot Prompt Suggestion:**
```yaml
# Create docker-compose.yml that includes:
# - The FastAPI service with build context
# - PostgreSQL database with health check
# - Redis cache with persistence
# - Proper networking and volume mounts
# - Environment variable configuration
# - Health checks for all services
# - Restart policies
```

**Expected Output:**
```yaml
version: '3.9'

services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
      cache_from:
        - python:3.11-slim
    image: product-catalog:latest
    container_name: product-catalog-api
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/products
      - REDIS_URL=redis://redis:6379
      - LOG_LEVEL=info
      - ENVIRONMENT=development
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    restart: unless-stopped
    networks:
      - app-network
    volumes:
      - ./src:/app:ro

  db:
    image: postgres:16-alpine
    container_name: product-catalog-db
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=products
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    networks:
      - app-network
    volumes:
      - postgres-data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    container_name: product-catalog-redis
    command: redis-server --appendonly yes
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    networks:
      - app-network
    volumes:
      - redis-data:/data

networks:
  app-network:
    driver: bridge

volumes:
  postgres-data:
  redis-data:
```

### Step 7: Create ambiente Configuration

**Copilot Prompt Suggestion:**
```python
# Create a .env.example file with all required environment variables
# Include descriptions and default values
# Group by service (API, Database, Redis, Monitoring)
```

**Expected Output:**
```env
# API Configuration
API_VERSION=1.0.0
API_TITLE=Product Catalog Service
API_HOST=0.0.0.0
API_PORT=8000
LOG_LEVEL=info
ENVIRONMENT=development

# Database Configuration
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/products
DB_POOL_SIZE=10
DB_MAX_OVERFLOW=20
DB_POOL_TIMEOUT=30

# Redis Configuration
REDIS_URL=redis://localhost:6379
REDIS_MAX_CONNECTIONS=50
REDIS_DECODE_RESPONSES=true
CACHE_TTL=300

# Security
SECRET_KEY=your-secret-key-here
CORS_ORIGINS=["http://localhost:3000"]
TRUSTED_HOSTS=["localhost", "127.0.0.1"]

# Monitoring
METRICS_ENABLED=true
METRICS_PORT=9090
TRACING_ENABLED=false
TRACING_ENDPOINT=http://jaeger:14268/api/traces

# Feature Flags
ENABLE_CACHE=true
ENABLE_RATE_LIMITING=true
RATE_LIMIT_MAX_REQUESTS=100
RATE_LIMIT_WINDOW_SECONDS=60
```

## 🔒 Partee 4: Container Security

### Step 8: Implement Security Scanning

**Copilot Prompt Suggestion:**
```yaml
# Create docker-compose.security.yml for security scanning that includes:
# - Trivy for vulnerability scanning
# - Docker Scout integration
# - Security benchmarks with docker-bench
# - Secret scanning
# Run with: docker compose -f docker-compose.security.yml up
```

**Expected Output:**
```yaml
version: '3.9'

services:
  trivy-scan:
    image: aquasec/trivy:latest
    container_name: security-scan-trivy
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./security-reports:/reports
    command: image --format json --output /reports/trivy-report.json product-catalog:latest
    
  docker-bench:
    image: docker/docker-bench-security:latest
    container_name: security-scan-bench
    network_mode: host
    pid: host
    cap_add:
      - AUDIT_CONTROL
    labels:
      - docker.bench.security=true
    volumes:
      - /var/lib:/var/lib:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /etc:/etc:ro
      - ./security-reports:/reports
    command: -l /reports/docker-bench-report.log

  secret-scanner:
    image: trufflesecurity/trufflehog:latest
    container_name: security-scan-secrets
    volumes:
      - .:/repo:ro
      - ./security-reports:/reports
    command: filesystem /repo --json &gt; /reports/secrets-report.json
```

### Step 9: Create Security Policy

**Copilot Prompt Suggestion:**
```dockerfile
# Create Dockerfile.security with additional security hardening:
# - Distroless base image
# - Read-only root filesystem
# - No shell access
# - Minimal attack surface
# - Security headers
```

**Expected Output:**
```dockerfile
# Security-hardened Dockerfile
FROM python:3.11-slim AS builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --target /app/deps

# Use distroless for runtime
FROM gcr.io/distroless/python3-debian12

# Copy Python dependencies
COPY --from=builder /app/deps /app/deps
ENV PYTHONPATH=/app/deps

# Copy application
COPY --from=builder /app/src /app

# Set up non-root user (distroless includes nonroot user)
USER nonroot

# No shell, no package manager, minimal attack surface
WORKDIR /app
EXPOSE 8000

# Health check using Python
HEALTHCHECK --interval=30s --timeout=3s \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"]

ENTRYPOINT ["python", "-m", "uvicorn"]
CMD ["main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## 🧪 Partee 5: Testing and Validation

### Step 10: Create Container Tests

**Copilot Prompt Suggestion:**
```python
# Create tests/test_container.py that validates:
# - Container builds successfully
# - Health check endpoint responds
# - Service starts within timeout
# - Graceful shutdown works
# - Resource limits are respected
# - Security policies are enforced
```

**Expected Output:**
```python
import pytest
import docker
import requests
import time
import signal
import os
from typing import Generator

@pytest.fixture(scope="module")
def docker_client():
    """Create Docker client"""
    return docker.from_env()

@pytest.fixture(scope="module")
def built_image(docker_client):
    """Build the Docker image"""
    image, logs = docker_client.images.build(
        path=".",
        tag="product-catalog:test",
        rm=True,
        forcerm=True
    )
    yield image
    # Cleanup
    docker_client.images.remove(image.id, force=True)

@pytest.fixture
def running_container(docker_client, built_image):
    """Run container for testing"""
    container = docker_client.containers.run(
        "product-catalog:test",
        detach=True,
        ports={{'8000/tcp': 8000}},
        environment={
            'LOG_LEVEL': 'debug'
        },
        remove=True
    )
    
    # Wait for container to be healthy
    timeout = time.time() + 60
    while time.time() &lt; timeout:
        container.reload()
        if container.status == 'running':
            try:
                response = requests.get('http://localhost:8000/health')
                if response.status_code == 200:
                    break
            except requests.exceptions.ConnectionError:
                pass
        time.sleep(1)
    
    yield container
    
    # Cleanup
    try:
        container.stop(timeout=10)
    except:
        container.kill()

def test_image_builds(built_image):
    """Test that image builds successfully"""
    assert built_image is not None
    assert 'product-catalog:test' in [tag for tag in built_image.tags]

def test_container_starts(running_container):
    """Test that container starts and becomes healthy"""
    assert running_container.status == 'running'
    
    # Check health endpoint
    response = requests.get('http://localhost:8000/health')
    assert response.status_code == 200
    health_data = response.json()
    assert health_data['status'] == 'healthy'
    assert 'uptime' in health_data

def test_api_endpoints(running_container):
    """Test basic API functionality"""
    # Test product creation
    product_data = {
        "name": "Test Product",
        "description": "A test product",
        "price": 99.99,
        "stock": 10,
        "category": "test"
    }
    
    response = requests.post(
        'http://localhost:8000/products',
        json=product_data
    )
    assert response.status_code == 201
    created_product = response.json()
    assert created_product['name'] == product_data['name']
    
    # Test product retrieval
    product_id = created_product['id']
    response = requests.get(f'http://localhost:8000/products/{product_id}')
    assert response.status_code == 200
    assert response.json()['id'] == product_id

def test_graceful_shutdown(docker_client, built_image):
    """Test graceful shutdown handling"""
    container = docker_client.containers.run(
        "product-catalog:test",
        detach=True,
        remove=False
    )
    
    # Wait for container to start
    time.sleep(5)
    
    # Send SIGTERM
    container.kill(signal.SIGTERM)
    
    # Wait for graceful shutdown
    exit_code = container.wait(timeout=30)['StatusCode']
    
    # Check logs for graceful shutdown message
    logs = container.logs().decode('utf-8')
    assert 'graceful shutdown' in logs.lower()
    
    # Cleanup
    container.remove()

def test_resource_limits(docker_client, built_image):
    """Test container resource constraints"""
    container = docker_client.containers.run(
        "product-catalog:test",
        detach=True,
        mem_limit='256m',
        cpus=0.5,
        remove=True
    )
    
    # Check container stats
    stats = container.stats(stream=False)
    
    # Verify memory limit
    memory_limit = stats['memory_stats']['limit']
    assert memory_limit &lt;= 256 * 1024 * 1024  # 256MB
    
    # Cleanup
    container.stop()

def test_security_policies(built_image):
    """Test security configurations"""
    # Check image metadata
    assert built_image.attrs['Config']['User'] != 'root'
    
    # Verify no shell
    entrypoint = built_image.attrs['Config']['Entrypoint']
    assert '/bin/sh' not in str(entrypoint)
    assert '/bin/bash' not in str(entrypoint)

def test_health_check_configuration(built_image):
    """Test health check is properly configured"""
    healthcheck = built_image.attrs['Config'].get('Healthcheck')
    assert healthcheck is not None
    assert healthcheck['Test'] is not None
    assert healthcheck['Interval'] == 30000000000  # 30 seconds in nanoseconds
```

### Step 11: Create Build and Test Script

**Copilot Prompt Suggestion:**
```bash
# Create build-and-test.sh script that:
# - Builds the Docker image with proper tags
# - Runs security scans
# - Executes container tests
# - Generates test reports
# - Handles cleanup on failure
# - Returns appropriate exit codes
```

**Expected Output:**
```bash
#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="product-catalog"
IMAGE_TAG="${\`1:-latest\`}"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

echo -e "${YELLOW}Building container image: ${FULL_IMAGE_NAME}${NC}"

# Build the image
if docker build -t "${FULL_IMAGE_NAME}" .; then
    echo -e "${GREEN}✓ Image built successfully${NC}"
else
    echo -e "${RED}✗ Image build failed${NC}"
    exit 1
fi

# Run security scan
echo -e "${YELLOW}Running security scan...${NC}"
mkdir -p security-reports

if docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$(pwd)/security-reports:/reports" \
    aquasec/trivy:latest image \
    --format json \
    --output /reports/trivy-report.json \
    "${FULL_IMAGE_NAME}"; then
    echo -e "${GREEN}✓ Security scan completed${NC}"
    
    # Check for critical vulnerabilities
    CRITICAL_COUNT=$(docker run --rm -v "$(pwd)/security-reports:/reports" \
        alpine:latest sh -c \
        'apk add --no-cache jq &gt; /dev/null 2>&1 && jq ".Results[].Vulnerabilities[]? | select(.Severity==\"CRITICAL\")" /reports/trivy-report.json | jq -s "length"')
    
    if [ "${CRITICAL_COUNT}" -gt 0 ]; then
        echo -e "${RED}✗ Found ${CRITICAL_COUNT} critical vulnerabilities${NC}"
        echo "See security-reports/trivy-report.json for details"
    else
        echo -e "${GREEN}✓ No critical vulnerabilities found${NC}"
    fi
else
    echo -e "${RED}✗ Security scan failed${NC}"
fi

# Run container tests
echo -e "${YELLOW}Running container tests...${NC}"
if python -m pytest tests/test_container.py -v --tb=short; then
    echo -e "${GREEN}✓ All container tests passed${NC}"
else
    echo -e "${RED}✗ Container tests failed${NC}"
    exit 1
fi

# Test Docker Compose setup
echo -e "${YELLOW}Testing Docker Compose configuration...${NC}"
if docker compose config &gt; /dev/null 2>&1; then
    echo -e "${GREEN}✓ Docker Compose configuration valid${NC}"
else
    echo -e "${RED}✗ Docker Compose configuration invalid${NC}"
    exit 1
fi

# Generate size report
echo -e "${YELLOW}Analyzing image size...${NC}"
docker images "${FULL_IMAGE_NAME}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Success
echo -e "${GREEN}✓ All checks passed! Image ${FULL_IMAGE_NAME} is ready for deployment${NC}"
```

## 📊 Partee 6: Optimization and Monitoring

### Step 12: Add Prometheus Metrics

**Copilot Prompt Suggestion:**
```python
# Update src/main.py to add Prometheus metrics:
# - Request count by endpoint and status
# - Request duration histogram
# - Active requests gauge
# - Custom business metrics (products created/deleted)
# - Expose metrics on /metrics endpoint
```

**Expected Output (additions to main.py):**
```python
from prometheus_client import Counter, Histogram, Gauge, generate_latest
from fastapi import Response
import time

# Prometheus metrics
request_count = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

request_duration = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    ['method', 'endpoint']
)

active_requests = Gauge(
    'http_requests_active',
    'Number of active HTTP requests'
)

products_created = Counter(
    'products_created_total',
    'Total number of products created'
)

products_deleted = Counter(
    'products_deleted_total',
    'Total number of products deleted'
)

# Metrics middleware
@app.middleware("http")
async def prometheus_middleware(request, call_next):
    start_time = time.time()
    active_requests.inc()
    
    try:
        response = await call_next(request)
        duration = time.time() - start_time
        
        # Record metrics
        request_count.labels(
            method=request.method,
            endpoint=request.url.path,
            status=response.status_code
        ).inc()
        
        request_duration.labels(
            method=request.method,
            endpoint=request.url.path
        ).observe(duration)
        
        return response
    finally:
        active_requests.dec()

# Metrics endpoint
@app.get("/metrics", include_in_schema=False)
async def metrics():
    """Prometheus metrics endpoint"""
    return Response(
        content=generate_latest(),
        media_type="text/plain"
    )

# Update create_product to increment counter
# In the create_product function, add:
products_created.inc()

# Update delete_product to increment counter  
# In the delete_product function, add:
products_deleted.inc()
```

## ✅ Validation and Completion

### Final Verificarlist

Run through this checklist to ensure your containerization is complete:

```bash
# 1. Build the image
docker build -t product-catalog:latest .

# 2. Run security scan
docker run --rm aquasec/trivy:latest image product-catalog:latest

# 3. Start services with Docker Compose
docker compose up -d

# 4. Verify health checks
curl http://localhost:8000/health
curl http://localhost:8000/ready

# 5. Test API functionality
curl -X POST http://localhost:8000/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","description":"Test product","price":9.99,"stock":100,"category":"test"}'

# 6. Check metrics
curl http://localhost:8000/metrics

# 7. Test graceful shutdown
docker compose stop

# 8. Clean up
docker compose down -v
```

## 🎯 Success Criteria

Your containerized microservice is complete when:

- [ ] Docker image builds successfully
- [ ] Container starts and passes health checks
- [ ] API endpoints respond correctly
- [ ] Graceful shutdown works properly
- [ ] Security scan shows no critical vulnerabilities
- [ ] Image size is under 150MB
- [ ] All tests pass
- [ ] Metrics are exposed properly
- [ ] Docker Compose setup works

## 🚀 Extension Challenges

1. **Multi-Architecture Build**: Create images for both AMD64 and ARM64
2. **GitOps Ready**: Add Kubernetes manifests for implantação
3. **CI/CD Pipeline**: Create GitHub Actions workflow for automated builds
4. **Avançado Monitoring**: Add distributed tracing with AbrirTelemetry
5. **Performance Optimization**: Implement connection pooling and caching

## 📚 Additional Recursos

- [Docker Melhores Práticas](https://docs.docker.com/develop/dev-best-practices/)
- [FastAPI Docker Deployment](https://fastapi.tiangolo.com/implantação/docker/)
- [Container Security Verificarlist](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Prometheus Python Client](https://github.com/prometheus/client_python)

---

Congratulations! You've successfully containerized a Python microservice with production-ready features. Proceed to Exercise 2 to deploy this container to Kubernetes! 🎉