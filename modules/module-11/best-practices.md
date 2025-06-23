# Microservices Best Practices

## 🏗️ Service Design Principles

### 1. Domain-Driven Design (DDD)
Define service boundaries based on business capabilities, not technical layers.

```python
# ✅ Good: Service aligned with business domain
class OrderService:
    """Handles complete order lifecycle including payment and fulfillment"""
    
# ❌ Bad: Service based on technical layer
class DatabaseService:
    """Generic database operations for all domains"""
```

### 2. Single Responsibility
Each microservice should do one thing well.

```python
# ✅ Good: Focused service
class InventoryService:
    async def check_availability(self, product_id: str) -> int:
        """Check product availability"""
    
    async def reserve_items(self, order_items: List[OrderItem]) -> bool:
        """Reserve items for an order"""

# ❌ Bad: Service doing too much
class SuperService:
    async def process_order(self): pass
    async def handle_payment(self): pass
    async def manage_inventory(self): pass
    async def send_notifications(self): pass
```

### 3. Database per Service
Each service owns its data and schema.

```python
# ✅ Good: Service-specific database connection
class ProductService:
    def __init__(self):
        self.db = Database("postgresql://localhost/products_db")
    
    async def get_product(self, product_id: str):
        # Direct database access only within service
        return await self.db.fetch_one(
            "SELECT * FROM products WHERE id = $1", 
            product_id
        )
```

## 🔌 Communication Patterns

### 1. Synchronous Communication (REST/gRPC)

```python
# REST client with circuit breaker
from circuit_breaker import CircuitBreaker
import httpx

class ServiceClient:
    def __init__(self, base_url: str):
        self.client = httpx.AsyncClient(base_url=base_url)
        self.circuit_breaker = CircuitBreaker(
            failure_threshold=5,
            recovery_timeout=30,
            expected_exception=httpx.RequestError
        )
    
    @circuit_breaker
    async def get_user(self, user_id: str):
        response = await self.client.get(f"/users/{user_id}")
        response.raise_for_status()
        return response.json()
```

### 2. Asynchronous Communication (Message Queues)

```python
# Event-driven communication with RabbitMQ
import aio_pika
from typing import Dict, Any

class EventPublisher:
    def __init__(self, rabbitmq_url: str):
        self.url = rabbitmq_url
        self.connection = None
        self.channel = None
    
    async def connect(self):
        self.connection = await aio_pika.connect_robust(self.url)
        self.channel = await self.connection.channel()
    
    async def publish_event(self, event_type: str, data: Dict[str, Any]):
        exchange = await self.channel.declare_exchange(
            "events", 
            aio_pika.ExchangeType.TOPIC
        )
        
        message = aio_pika.Message(
            body=json.dumps({
                "event_type": event_type,
                "timestamp": datetime.utcnow().isoformat(),
                "data": data
            }).encode()
        )
        
        await exchange.publish(message, routing_key=event_type)
```

## 🛡️ Resilience Patterns

### 1. Circuit Breaker Pattern

```python
# Copilot Prompt Suggestion:
"Create a circuit breaker decorator that:
- Tracks failure rate
- Opens circuit after 5 consecutive failures
- Half-opens after 30 seconds
- Includes metrics logging"

# Expected Output:
import time
from functools import wraps
from enum import Enum
from typing import Callable
import logging

class CircuitState(Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"

class CircuitBreaker:
    def __init__(
        self, 
        failure_threshold: int = 5,
        recovery_timeout: int = 30,
        expected_exception: type = Exception
    ):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.expected_exception = expected_exception
        self.failure_count = 0
        self.last_failure_time = None
        self.state = CircuitState.CLOSED
        
    def __call__(self, func: Callable):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            if self.state == CircuitState.OPEN:
                if self._should_attempt_reset():
                    self.state = CircuitState.HALF_OPEN
                else:
                    raise Exception("Circuit breaker is OPEN")
            
            try:
                result = await func(*args, **kwargs)
                self._on_success()
                return result
            except self.expected_exception as e:
                self._on_failure()
                raise e
                
        return wrapper
    
    def _should_attempt_reset(self) -> bool:
        return (
            self.last_failure_time and 
            time.time() - self.last_failure_time >= self.recovery_timeout
        )
    
    def _on_success(self):
        self.failure_count = 0
        self.state = CircuitState.CLOSED
        logging.info(f"Circuit breaker state: {self.state.value}")
    
    def _on_failure(self):
        self.failure_count += 1
        self.last_failure_time = time.time()
        if self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN
            logging.warning(f"Circuit breaker opened after {self.failure_count} failures")
```

### 2. Retry with Exponential Backoff

```python
# Copilot Prompt Suggestion:
"Implement a retry decorator with:
- Exponential backoff starting at 1 second
- Maximum 5 retries
- Jitter to prevent thundering herd
- Specific exception handling"

# Expected Output:
import asyncio
import random
from functools import wraps
from typing import Type, Tuple

def retry_with_backoff(
    max_retries: int = 5,
    base_delay: float = 1.0,
    max_delay: float = 60.0,
    exceptions: Tuple[Type[Exception], ...] = (Exception,)
):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            for attempt in range(max_retries):
                try:
                    return await func(*args, **kwargs)
                except exceptions as e:
                    if attempt == max_retries - 1:
                        raise
                    
                    delay = min(
                        base_delay * (2 ** attempt) + random.uniform(0, 1),
                        max_delay
                    )
                    logging.warning(
                        f"Retry {attempt + 1}/{max_retries} after {delay:.2f}s: {e}"
                    )
                    await asyncio.sleep(delay)
        
        return wrapper
    return decorator
```

### 3. Timeout Pattern

```python
# Always set timeouts for external calls
class ServiceClient:
    def __init__(self):
        self.timeout = httpx.Timeout(
            connect=5.0,  # Connection timeout
            read=10.0,    # Read timeout
            write=5.0,    # Write timeout
            pool=1.0      # Pool timeout
        )
        self.client = httpx.AsyncClient(timeout=self.timeout)
```

## 📊 Observability

### 1. Structured Logging

```python
import structlog
from contextvars import ContextVar

request_id_var: ContextVar[str] = ContextVar("request_id", default="")

# Configure structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.dict_tracebacks,
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
)

logger = structlog.get_logger()

# Use in service
async def process_order(order_id: str):
    logger.info("processing_order", order_id=order_id, request_id=request_id_var.get())
```

### 2. Distributed Tracing

```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Configure tracing
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

otlp_exporter = OTLPSpanExporter(endpoint="http://localhost:4317")
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

# Use in service
async def get_product_details(product_id: str):
    with tracer.start_as_current_span("get_product_details") as span:
        span.set_attribute("product.id", product_id)
        # Service logic here
```

### 3. Metrics Collection

```python
from prometheus_client import Counter, Histogram, Gauge
import time

# Define metrics
request_count = Counter(
    'service_requests_total', 
    'Total requests',
    ['method', 'endpoint', 'status']
)

request_duration = Histogram(
    'service_request_duration_seconds',
    'Request duration',
    ['method', 'endpoint']
)

active_connections = Gauge(
    'service_active_connections',
    'Active connections'
)

# Middleware for automatic metrics
@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start_time = time.time()
    active_connections.inc()
    
    try:
        response = await call_next(request)
        request_count.labels(
            method=request.method,
            endpoint=request.url.path,
            status=response.status_code
        ).inc()
        return response
    finally:
        duration = time.time() - start_time
        request_duration.labels(
            method=request.method,
            endpoint=request.url.path
        ).observe(duration)
        active_connections.dec()
```

## 🔐 Security Best Practices

### 1. Service-to-Service Authentication

```python
# JWT-based service authentication
from jose import jwt, JWTError
from datetime import datetime, timedelta

class ServiceAuth:
    def __init__(self, secret_key: str, algorithm: str = "HS256"):
        self.secret_key = secret_key
        self.algorithm = algorithm
    
    def create_service_token(self, service_name: str) -> str:
        payload = {
            "service": service_name,
            "iat": datetime.utcnow(),
            "exp": datetime.utcnow() + timedelta(minutes=5)
        }
        return jwt.encode(payload, self.secret_key, algorithm=self.algorithm)
    
    async def verify_service_token(self, token: str) -> dict:
        try:
            payload = jwt.decode(token, self.secret_key, algorithms=[self.algorithm])
            return payload
        except JWTError:
            raise ValueError("Invalid token")
```

### 2. API Rate Limiting

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.get("/api/products")
@limiter.limit("100/minute")
async def get_products():
    # Implementation
    pass
```

## 🚀 Deployment Best Practices

### 1. Health Checks

```python
from enum import Enum
from typing import Dict

class HealthStatus(Enum):
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNHEALTHY = "unhealthy"

@app.get("/health")
async def health_check() -> Dict:
    checks = {
        "database": await check_database(),
        "redis": await check_redis(),
        "rabbitmq": await check_rabbitmq()
    }
    
    overall_status = HealthStatus.HEALTHY
    if any(check["status"] == "unhealthy" for check in checks.values()):
        overall_status = HealthStatus.UNHEALTHY
    elif any(check["status"] == "degraded" for check in checks.values()):
        overall_status = HealthStatus.DEGRADED
    
    return {
        "status": overall_status.value,
        "checks": checks,
        "timestamp": datetime.utcnow().isoformat()
    }
```

### 2. Graceful Shutdown

```python
import signal
import asyncio

class GracefulShutdown:
    def __init__(self):
        self.should_exit = False
        signal.signal(signal.SIGTERM, self._signal_handler)
        signal.signal(signal.SIGINT, self._signal_handler)
    
    def _signal_handler(self, signum, frame):
        self.should_exit = True
    
    async def cleanup(self):
        # Close database connections
        await db.disconnect()
        # Close message queue connections
        await mq.close()
        # Wait for ongoing requests
        await asyncio.sleep(5)
```

### 3. Configuration Management

```python
from pydantic import BaseSettings
from functools import lru_cache

class ServiceConfig(BaseSettings):
    service_name: str
    service_port: int = 8000
    database_url: str
    redis_url: str
    rabbitmq_url: str
    jwt_secret: str
    log_level: str = "INFO"
    
    class Config:
        env_file = ".env"
        case_sensitive = False

@lru_cache()
def get_config() -> ServiceConfig:
    return ServiceConfig()

# Usage
config = get_config()
```

## 📏 Testing Strategies

### 1. Contract Testing

```python
# Copilot Prompt Suggestion:
"Create a contract test that:
- Validates API response schema
- Tests all status codes
- Includes error scenarios
- Uses pytest fixtures"

# Expected Output:
import pytest
from pydantic import BaseModel
from typing import List

class ProductSchema(BaseModel):
    id: str
    name: str
    price: float
    available: bool

@pytest.mark.asyncio
async def test_product_service_contract(client):
    # Test successful response
    response = await client.get("/api/products/123")
    assert response.status_code == 200
    
    # Validate schema
    product = ProductSchema(**response.json())
    assert product.id == "123"
    
    # Test 404
    response = await client.get("/api/products/nonexistent")
    assert response.status_code == 404
    assert "error" in response.json()
    
    # Test validation error
    response = await client.post("/api/products", json={"invalid": "data"})
    assert response.status_code == 422
```

### 2. Chaos Testing Readiness

```python
# Implement fallbacks for chaos scenarios
class ResilientService:
    async def get_user_preferences(self, user_id: str):
        try:
            # Try to get from preference service
            return await self.preference_client.get_preferences(user_id)
        except Exception as e:
            logger.warning(f"Failed to get preferences: {e}")
            # Fallback to cached or default preferences
            return await self.get_cached_preferences(user_id) or DEFAULT_PREFERENCES
```

## 🎯 Production Checklist

- [ ] Each service has health endpoints
- [ ] Distributed tracing implemented
- [ ] Metrics exposed for Prometheus
- [ ] Circuit breakers on all external calls
- [ ] Retry logic with backoff
- [ ] Timeouts configured
- [ ] Graceful shutdown implemented
- [ ] Security headers added
- [ ] Rate limiting configured
- [ ] API versioning strategy defined
- [ ] Database migrations automated
- [ ] Service dependencies documented
- [ ] SLOs defined and monitored
- [ ] Runbooks created for operations

Remember: Start simple, measure everything, and evolve based on actual needs!