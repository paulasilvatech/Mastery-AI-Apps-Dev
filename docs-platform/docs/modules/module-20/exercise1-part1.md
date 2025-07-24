---
sidebar_position: 2
title: "Exercise 1: Part 1"
description: "## 🎯 Exercise Overview"
---

# Exercise 1: Blue-Green Deployment (⭐ Foundation)

## 🎯 Exercise Overview

In this foundational exercise, you'll implement a complete blue-green deployment system with zero-downtime switching. You'll use GitHub Copilot to accelerate development of deployment scripts, health checks, and traffic management.

**Duration**: 30-45 minutes  
**Difficulty**: ⭐ Foundation  
**Success Rate**: 95%

## 🎓 Learning Objectives

By completing this exercise, you will:

1. Build a blue-green deployment infrastructure
2. Implement health check endpoints
3. Create automated traffic switching
4. Handle database migrations safely
5. Implement rollback procedures
6. Monitor deployment status

## 📚 Concepts Covered

### Blue-Green Deployment Pattern

Blue-green deployment maintains two identical production environments:
- **Blue**: Current live environment serving traffic
- **Green**: New version being deployed and tested

```mermaid
sequenceDiagram
    participant User
    participant LB as Load Balancer
    participant Blue as Blue Environment
    participant Green as Green Environment
    participant DB as Database
    
    Note over Blue: v1.0 (Live)
    Note over Green: v2.0 (Staging)
    
    User-&gt;>LB: Request
    LB-&gt;>Blue: Route Traffic
    Blue-&gt;>DB: Query
    Blue--&gt;>User: Response
    
    Note over Green: Deploy & Test v2.0
    Green-&gt;>DB: Compatibility Check
    
    Note over LB: Switch Traffic
    User-&gt;>LB: Request
    LB-&gt;>Green: Route Traffic
    Green-&gt;>DB: Query
    Green--&gt;>User: Response
    
    Note over Blue: Now Standby
```

## 🛠️ Part 1: Infrastructure Setup

### Step 1: Create the Application Structure

**Copilot Prompt Suggestion:**
```python
# Create a FastAPI application with:
# - Health check endpoint returning version and status
# - Database connection with health check
# - Metrics endpoint for monitoring
# - Configurable version number from environment
# Include proper error handling and logging
```

**Expected Output:**
```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, BaseSettings
from typing import Dict, Any
import logging
import asyncpg
import os
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class Settings(BaseSettings):
    app_version: str = os.getenv("APP_VERSION", "1.0.0")
    environment: str = os.getenv("ENVIRONMENT", "blue")
    database_url: str = os.getenv("DATABASE_URL", "postgresql://localhost/app")
    port: int = int(os.getenv("PORT", "8000"))
    
    class Config:
        env_file = ".env"

settings = Settings()

app = FastAPI(title=f"Blue-Green App - {settings.environment}", version=settings.app_version)

class HealthStatus(BaseModel):
    status: str
    version: str
    environment: str
    timestamp: datetime
    database: str
    details: Dict[str, Any] = {}

@app.get("/health", response_model=HealthStatus)
async def health_check():
    """
    Health check endpoint for load balancer
    """
    health_status = {
        "status": "healthy",
        "version": settings.app_version,
        "environment": settings.environment,
        "timestamp": datetime.utcnow(),
        "database": "checking"
    }
    
    try:
        # Check database connection
        conn = await asyncpg.connect(settings.database_url)
        await conn.fetchval("SELECT 1")
        await conn.close()
        health_status["database"] = "connected"
        logger.info(f"Health check passed for {settings.environment}")
    except Exception as e:
        health_status["status"] = "unhealthy"
        health_status["database"] = "disconnected"
        health_status["details"]["error"] = str(e)
        logger.error(f"Health check failed: {e}")
        raise HTTPException(status_code=503, detail=health_status)
    
    return health_status

@app.get("/metrics")
async def metrics():
    """
    Metrics endpoint for monitoring
    """
    return {
        "requests_total": 0,  # Would be tracked in production
        "errors_total": 0,
        "latency_seconds": 0.0,
        "version": settings.app_version,
        "environment": settings.environment
    }

@app.get("/")
async def root():
    return {
        "message": f"Hello from {{settings.environment}} environment",
        "version": settings.app_version
    }
```

### Step 2: Create Docker Configuration

**Copilot Prompt Suggestion:**
```dockerfile
# Create a multi-stage Dockerfile for a Python FastAPI app that:
# - Uses Python 3.11 slim base
# - Installs dependencies efficiently with caching
# - Runs as non-root user
# - Exposes port 8000
# - Includes health check command
# - Sets proper environment defaults
```

**Expected Output:**
```dockerfile
# Build stage
FROM python:3.11-slim as builder

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.11-slim

WORKDIR /app

# Create non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app

# Copy dependencies from builder
COPY --from=builder /root/.local /home/appuser/.local

# Copy application code
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

# Add .local/bin to PATH
ENV PATH=/home/appuser/.local/bin:$PATH

# Set environment defaults
ENV APP_VERSION=1.0.0
ENV ENVIRONMENT=blue
ENV PORT=8000

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

# Run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Step 3: Create Kubernetes Manifests

**Copilot Prompt Suggestion:**
```yaml
# Create Kubernetes manifests for blue-green deployment with:
# - Two deployments (blue and green) with 2 replicas each
# - Service that can switch between them using selectors
# - ConfigMaps for environment-specific configuration
# - Horizontal Pod Autoscaler
# - PodDisruptionBudget for high availability
# Include proper resource limits and health checks
```

**Expected Output:**
Create `kubernetes/blue-deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-blue
  labels:
    app: deployment-demo
    version: blue
spec:
  replicas: 2
  selector:
    matchLabels:
      app: deployment-demo
      version: blue
  template:
    metadata:
      labels:
        app: deployment-demo
        version: blue
    spec:
      containers:
      - name: app
        image: module20.azurecr.io/deployment-demo:1.0.0
        ports:
        - containerPort: 8000
        env:
        - name: APP_VERSION
          value: "1.0.0"
        - name: ENVIRONMENT
          value: "blue"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database-url
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-blue-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: deployment-demo
      version: blue
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-blue-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app-blue
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

## 💻 Part 2: Deployment Automation

### Step 4: Create Deployment Script

**Copilot Prompt Suggestion:**
```python
# Create a Python script for blue-green deployment that:
# - Checks health of new environment before switching
# - Updates Kubernetes service selector
# - Waits for pods to be ready
# - Verifies traffic is routing correctly
# - Provides rollback capability
# - Logs all actions with timestamps
# Use kubernetes Python client and include error handling
```

**Expected Output:**
Create `scripts/deploy_blue_green.py`:
```python
import os
import sys
import time
import logging
from typing import Dict, Optional
from kubernetes import client, config
import requests
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class BlueGreenDeployer:
    def __init__(self, namespace: str = "default"):
        """Initialize the blue-green deployer"""
        try:
            # Try to load in-cluster config first, fall back to kubeconfig
            try:
                config.load_incluster_config()
            except:
                config.load_kube_config()
            
            self.v1 = client.CoreV1Api()
            self.apps_v1 = client.AppsV1Api()
            self.namespace = namespace
            
        except Exception as e:
            logger.error(f"Failed to initialize Kubernetes client: {e}")
            raise

    def get_current_environment(self, service_name: str) -&gt; Optional[str]:
        """Get the current active environment (blue/green)"""
        try:
            service = self.v1.read_namespaced_service(
                name=service_name,
                namespace=self.namespace
            )
            return service.spec.selector.get('version')
        except Exception as e:
            logger.error(f"Failed to get current environment: {e}")
            return None

    def check_deployment_health(self, deployment_name: str, expected_replicas: int = 2) -&gt; bool:
        """Check if deployment is healthy and ready"""
        try:
            deployment = self.apps_v1.read_namespaced_deployment(
                name=deployment_name,
                namespace=self.namespace
            )
            
            # Check if deployment has minimum replicas ready
            ready_replicas = deployment.status.ready_replicas or 0
            
            if ready_replicas &lt; expected_replicas:
                logger.warning(f"Deployment {deployment_name} has {ready_replicas}/{expected_replicas} ready replicas")
                return False
                
            logger.info(f"Deployment {deployment_name} is healthy with {ready_replicas} ready replicas")
            return True
            
        except Exception as e:
            logger.error(f"Failed to check deployment health: {e}")
            return False

    def verify_endpoint_health(self, endpoint_url: str, expected_version: str) -&gt; bool:
        """Verify the health endpoint returns expected version"""
        max_retries = 5
        retry_delay = 2
        
        for attempt in range(max_retries):
            try:
                response = requests.get(f"{endpoint_url}/health", timeout=5)
                if response.status_code == 200:
                    data = response.json()
                    if data.get('version') == expected_version:
                        logger.info(f"Health check passed for version {expected_version}")
                        return True
                    else:
                        logger.warning(f"Version mismatch: expected {expected_version}, got {data.get('version')}")
                else:
                    logger.warning(f"Health check returned status {response.status_code}")
                    
            except Exception as e:
                logger.warning(f"Health check attempt {attempt + 1} failed: {e}")
                
            if attempt &lt; max_retries - 1:
                time.sleep(retry_delay)
                
        return False

    def switch_traffic(self, service_name: str, target_environment: str) -&gt; bool:
        """Switch traffic to target environment by updating service selector"""
        try:
            # Get current service
            service = self.v1.read_namespaced_service(
                name=service_name,
                namespace=self.namespace
            )
            
            # Update selector
            service.spec.selector['version'] = target_environment
            
            # Apply update
            self.v1.patch_namespaced_service(
                name=service_name,
                namespace=self.namespace,
                body=service
            )
            
            logger.info(f"Successfully switched traffic to {target_environment} environment")
            return True
            
        except Exception as e:
            logger.error(f"Failed to switch traffic: {e}")
            return False

    def deploy(self, service_name: str, new_environment: str, 
              new_version: str, health_check_url: str) -&gt; bool:
        """
        Execute blue-green deployment
        """
        logger.info(f"Starting blue-green deployment to {new_environment} with version {new_version}")
        
        # Step 1: Determine current environment
        current_env = self.get_current_environment(service_name)
        if not current_env:
            logger.error("Could not determine current environment")
            return False
            
        logger.info(f"Current environment: {current_env}")
        
        if current_env == new_environment:
            logger.error(f"Target environment {new_environment} is already active")
            return False
            
        # Step 2: Check new deployment health
        deployment_name = f"app-{new_environment}"
        logger.info(f"Checking health of {deployment_name}")
        
        if not self.check_deployment_health(deployment_name):
            logger.error(f"Deployment {deployment_name} is not healthy")
            return False
            
        # Step 3: Verify endpoint health
        logger.info("Verifying endpoint health")
        if not self.verify_endpoint_health(health_check_url, new_version):
            logger.error("Endpoint health check failed")
            return False
            
        # Step 4: Switch traffic
        logger.info(f"Switching traffic from {current_env} to {new_environment}")
        if not self.switch_traffic(service_name, new_environment):
            logger.error("Failed to switch traffic")
            return False
            
        # Step 5: Verify switch
        time.sleep(5)  # Allow time for switch to propagate
        
        final_env = self.get_current_environment(service_name)
        if final_env == new_environment:
            logger.info(f"Deployment successful! Traffic now routing to {new_environment}")
            return True
        else:
            logger.error(f"Deployment verification failed. Expected {new_environment}, got {final_env}")
            return False

def main():
    """Main deployment function"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Blue-Green Deployment Tool')
    parser.add_argument('--service', required=True, help='Service name')
    parser.add_argument('--environment', required=True, choices=['blue', 'green'], help='Target environment')
    parser.add_argument('--version', required=True, help='Application version')
    parser.add_argument('--health-url', required=True, help='Health check URL')
    parser.add_argument('--namespace', default='default', help='Kubernetes namespace')
    
    args = parser.parse_args()
    
    deployer = BlueGreenDeployer(namespace=args.namespace)
    
    success = deployer.deploy(
        service_name=args.service,
        new_environment=args.environment,
        new_version=args.version,
        health_check_url=args.health_url
    )
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
```

## 🧪 Part 3: Testing and Validation

Continue to [Part 2](./exercise1-part2) for testing, validation, and advanced scenarios...