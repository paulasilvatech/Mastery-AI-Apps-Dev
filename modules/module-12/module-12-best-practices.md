# Cloud-Native Development Best Practices

## 🏗️ Architecture Principles

### 1. Design for Failure
```yaml
# Always implement health checks
livenessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 30
  periodSeconds: 30

readinessProbe:
  httpGet:
    path: /ready
    port: 8000
  initialDelaySeconds: 10
  periodSeconds: 10

# Implement circuit breakers
from circuitbreaker import circuit

@circuit(failure_threshold=5, recovery_timeout=60)
async def call_external_service():
    # Service call with automatic circuit breaking
    pass
```

### 2. Stateless Services
- Store state in external systems (Redis, Cosmos DB)
- Use sticky sessions only when absolutely necessary
- Design for horizontal scaling from day one

### 3. Configuration Externalization
```python
# Use environment variables and config maps
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    api_key: str
    database_url: str
    redis_url: str
    
    class Config:
        env_file = ".env"
        case_sensitive = False

settings = Settings()
```

## 🐳 Container Best Practices

### 1. Minimize Image Size
```dockerfile
# Multi-stage builds
FROM python:3.11-slim AS builder
# Build dependencies
COPY requirements.txt .
RUN pip install --user -r requirements.txt

FROM python:3.11-slim AS runtime
# Copy only necessary files
COPY --from=builder /root/.local /root/.local
COPY ./app /app

# Use distroless for ultimate security
FROM gcr.io/distroless/python3-debian12
COPY --from=builder /app /app
```

### 2. Security Hardening
```dockerfile
# Run as non-root user
RUN useradd -r -u 1001 appuser
USER 1001

# Read-only root filesystem
RUN chmod -R 755 /app

# No shell in production
ENTRYPOINT ["python", "-m", "app"]
```

### 3. Layer Caching Optimization
```dockerfile
# Order matters - least changing first
COPY requirements.txt .
RUN pip install -r requirements.txt

# Frequently changing files last
COPY . .
```

### 4. Health Check Implementation
```python
# Comprehensive health check
@app.get("/health")
async def health_check():
    checks = {
        "database": await check_database(),
        "redis": await check_redis(),
        "disk_space": check_disk_space(),
        "memory": check_memory_usage()
    }
    
    status = "healthy" if all(checks.values()) else "unhealthy"
    return {
        "status": status,
        "checks": checks,
        "timestamp": datetime.utcnow(),
        "version": APP_VERSION
    }
```

## ☸️ Kubernetes Best Practices

### 1. Resource Management
```yaml
resources:
  requests:
    memory: "256Mi"  # Guaranteed resources
    cpu: "250m"
  limits:
    memory: "512Mi"  # Maximum allowed
    cpu: "500m"

# Use Vertical Pod Autoscaler for right-sizing
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: app-vpa
spec:
  updatePolicy:
    updateMode: "Auto"
```

### 2. Pod Disruption Budgets
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: product-catalog
```

### 3. Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-netpol
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - port: 8000
```

### 4. Secrets Management
```bash
# Use Azure Key Vault with CSI driver
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-keyvault
spec:
  provider: azure
  parameters:
    keyvaultName: "myKeyVault"
    objects: |
      - |
        objectName: database-password
        objectType: secret
```

## ⚡ Serverless Best Practices

### 1. Cold Start Optimization
```python
# Pre-warm dependencies
import azure.functions as func
from azure.cosmos import CosmosClient

# Initialize outside handler
cosmos_client = CosmosClient.from_connection_string(
    os.environ['COSMOS_CONNECTION']
)

async def main(req: func.HttpRequest) -> func.HttpResponse:
    # Use pre-warmed client
    database = cosmos_client.get_database_client('MyDB')
```

### 2. Idempotency
```python
# Implement idempotent operations
async def process_order(order_id: str, idempotency_key: str):
    # Check if already processed
    existing = await get_by_idempotency_key(idempotency_key)
    if existing:
        return existing
    
    # Process with idempotency key
    result = await create_order(order_id)
    await save_idempotency_key(idempotency_key, result)
    return result
```

### 3. Batch Processing
```python
# Process events in batches
async def main(events: List[func.EventGridEvent]):
    # Batch database operations
    batch_operations = []
    
    for event in events:
        operation = create_operation(event)
        batch_operations.append(operation)
    
    # Execute batch
    await cosmos_container.execute_batch(batch_operations)
```

### 4. Timeout and Retry Configuration
```json
{
  "extensions": {
    "durableTask": {
      "maxConcurrentActivityFunctions": 10,
      "maxConcurrentOrchestratorFunctions": 5
    }
  },
  "retry": {
    "strategy": "exponentialBackoff",
    "maxRetryCount": 3,
    "minimumInterval": "00:00:05",
    "maximumInterval": "00:01:00"
  }
}
```

## 📊 Monitoring and Observability

### 1. Structured Logging
```python
import structlog

logger = structlog.get_logger()

# Log with context
logger.info(
    "order_processed",
    order_id=order_id,
    customer_id=customer_id,
    amount=total_amount,
    duration_ms=processing_time
)
```

### 2. Distributed Tracing
```python
from opentelemetry import trace
from opentelemetry.trace import Status, StatusCode

tracer = trace.get_tracer(__name__)

with tracer.start_as_current_span("process_order") as span:
    span.set_attribute("order.id", order_id)
    span.set_attribute("order.amount", amount)
    
    try:
        result = await process_order_logic()
        span.set_status(Status(StatusCode.OK))
    except Exception as e:
        span.record_exception(e)
        span.set_status(Status(StatusCode.ERROR))
        raise
```

### 3. Custom Metrics
```python
from prometheus_client import Counter, Histogram, Gauge

# Define metrics
order_counter = Counter(
    'orders_processed_total',
    'Total orders processed',
    ['status', 'payment_method']
)

order_value = Histogram(
    'order_value_dollars',
    'Order value distribution',
    buckets=[10, 50, 100, 500, 1000, 5000]
)

active_orders = Gauge(
    'orders_active',
    'Currently processing orders'
)

# Use metrics
order_counter.labels(status='success', payment_method='credit_card').inc()
order_value.observe(order.total_amount)
active_orders.inc()
```

### 4. SLO Definition
```yaml
# Service Level Objectives
apiVersion: sloth.slok.dev/v1
kind: PrometheusServiceLevel
metadata:
  name: product-catalog-slo
spec:
  service: "product-catalog"
  labels:
    team: "platform"
  slos:
    - name: "availability"
      objective: 99.9
      sli:
        events:
          error_query: |
            sum(rate(http_requests_total{job="product-catalog",status=~"5.."}[5m]))
          total_query: |
            sum(rate(http_requests_total{job="product-catalog"}[5m]))
```

## 🔒 Security Best Practices

### 1. Zero Trust Security
```yaml
# Pod Security Policy
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
```

### 2. Secrets Rotation
```python
# Implement automatic secret rotation
async def rotate_secrets():
    # Get new secrets from Key Vault
    new_secrets = await get_latest_secrets()
    
    # Update application configuration
    update_config(new_secrets)
    
    # Gracefully restart connections
    await restart_database_connections()
    await restart_redis_connections()
```

### 3. Network Security
```bash
# Use Private Endpoints
az network private-endpoint create \
    --name pe-cosmos \
    --resource-group $RG \
    --vnet-name $VNET \
    --subnet $SUBNET \
    --private-connection-resource-id $COSMOS_ID \
    --connection-name cosmos-connection
```

## 🚀 Performance Optimization

### 1. Connection Pooling
```python
# Database connection pool
from sqlalchemy.pool import NullPool, QueuePool

engine = create_async_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=20,
    max_overflow=40,
    pool_timeout=30,
    pool_recycle=3600
)
```

### 2. Caching Strategy
```python
# Multi-layer caching
from functools import lru_cache
import redis

redis_client = redis.Redis(decode_responses=True)

@lru_cache(maxsize=1000)
def get_from_memory_cache(key: str):
    return expensive_computation(key)

async def get_with_cache(key: str):
    # L1: Memory cache
    result = get_from_memory_cache(key)
    if result:
        return result
    
    # L2: Redis cache
    result = await redis_client.get(key)
    if result:
        return json.loads(result)
    
    # L3: Database
    result = await fetch_from_database(key)
    
    # Update caches
    await redis_client.setex(key, 300, json.dumps(result))
    return result
```

### 3. Async Processing
```python
# Use async/await throughout
import asyncio
import aiohttp

async def process_batch(items):
    async with aiohttp.ClientSession() as session:
        tasks = [process_item(session, item) for item in items]
        results = await asyncio.gather(*tasks)
    return results
```

## 📦 Deployment Best Practices

### 1. Progressive Delivery
```yaml
# Canary deployment with Flagger
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: product-catalog
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: product-catalog
  progressDeadlineSeconds: 600
  service:
    port: 80
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m
```

### 2. Feature Flags
```python
# Implement feature toggles
from azure.appconfiguration import AzureAppConfigurationClient
from azure.identity import DefaultAzureCredential

config_client = AzureAppConfigurationClient(
    base_url=APP_CONFIG_URL,
    credential=DefaultAzureCredential()
)

def is_feature_enabled(feature_name: str, user_context: dict = None) -> bool:
    feature_flag = config_client.get_configuration_setting(
        key=f".appconfig.featureflag/{feature_name}"
    )
    
    if user_context:
        # Evaluate targeting rules
        return evaluate_targeting(feature_flag, user_context)
    
    return feature_flag.value.get("enabled", False)

# Usage
if is_feature_enabled("new-checkout-flow", {"user_id": user.id}):
    return new_checkout_process()
else:
    return legacy_checkout_process()
```

### 3. Blue-Green Deployment
```bash
# Switch traffic between blue and green
kubectl patch service product-catalog -p '{"spec":{"selector":{"version":"green"}}}'

# Rollback if needed
kubectl patch service product-catalog -p '{"spec":{"selector":{"version":"blue"}}}'
```

## 💰 Cost Optimization

### 1. Right-Sizing
```bash
# Use Azure Advisor recommendations
az advisor recommendation list \
    --category Cost \
    --query "[?impactedField=='Microsoft.Compute/virtualMachineScaleSets']"
```

### 2. Spot Instances
```yaml
# Use spot instances for non-critical workloads
apiVersion: v1
kind: Node
metadata:
  labels:
    kubernetes.azure.com/scalesetpriority: spot
spec:
  taints:
  - key: kubernetes.azure.com/scalesetpriority
    value: spot
    effect: NoSchedule
```

### 3. Autoscaling Policies
```yaml
# Scale down during off-hours
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: product-catalog-hpa
spec:
  behavior:
    scaleDown:
      policies:
      - type: Pods
        value: 1
        periodSeconds: 300
    scaleUp:
      policies:
      - type: Percent
        value: 100
        periodSeconds: 60
```

## 🎯 Key Takeaways

1. **Design for Failure**: Assume everything will fail and plan accordingly
2. **Observability First**: You can't fix what you can't see
3. **Security by Default**: Security is not an afterthought
4. **Automate Everything**: Manual processes don't scale
5. **Cost-Aware Architecture**: Optimize for both performance and cost
6. **Progressive Rollouts**: Minimize blast radius of changes
7. **Idempotent Operations**: Handle retries gracefully
8. **Stateless Services**: State is the enemy of scale

## 📚 Recommended Reading

- [The Twelve-Factor App](https://12factor.net/)
- [Cloud Native Patterns](https://www.manning.com/books/cloud-native-patterns)
- [Site Reliability Engineering](https://sre.google/books/)
- [Kubernetes Patterns](https://k8spatterns.io/)
- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)

---

Remember: These practices are guidelines, not rules. Always consider your specific context and requirements when making architectural decisions.