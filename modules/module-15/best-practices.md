# Module 15: Performance and Scalability Best Practices

## 🎯 Overview

This guide provides production-tested best practices for building high-performance, scalable systems. These patterns have been proven in systems handling millions of requests per day.

## 📊 Performance Optimization Best Practices

### 1. Measure First, Optimize Second

**❌ Don't:**
```python
# Premature optimization
def get_user(user_id):
    # Complex caching logic for a rarely-used endpoint
    cache_key = f"user:{user_id}:data:v2:compressed"
    # ... 50 lines of optimization code
```

**✅ Do:**
```python
# Profile first
@profile_performance
def get_user(user_id):
    # Simple implementation
    return db.query(User).filter_by(id=user_id).first()

# After profiling shows it's a bottleneck, then optimize
```

### 2. Database Query Optimization

**❌ Don't:**
```python
# N+1 query problem
orders = db.query(Order).all()
for order in orders:
    # This executes a query for each order!
    customer = db.query(Customer).filter_by(id=order.customer_id).first()
```

**✅ Do:**
```python
# Eager loading with JOIN
orders = db.query(Order).options(
    joinedload(Order.customer),
    selectinload(Order.items)
).all()

# Or use DataLoader pattern for GraphQL
```

### 3. Caching Strategy

**The Cache Hierarchy:**

```python
class CacheStrategy:
    """
    L1: Application Memory (microseconds)
    L2: Redis Local (milliseconds)
    L3: Redis Cluster (milliseconds)
    L4: CDN (tens of milliseconds)
    """
    
    async def get_with_fallback(self, key: str):
        # Try each level with circuit breakers
        value = await self.l1_cache.get(key)
        if value:
            return value
            
        value = await self.l2_cache.get(key)
        if value:
            await self.l1_cache.set(key, value, ttl=60)
            return value
            
        # Continue through levels...
```

**Cache Key Design:**
```python
# ❌ Bad: Unclear versioning, no namespace
cache_key = f"{user_id}"

# ✅ Good: Versioned, namespaced, descriptive
cache_key = f"api:v2:user:{user_id}:profile:2024-01-15"
```

### 4. Async/Await Patterns

**❌ Don't:**
```python
# Sequential async calls
async def get_dashboard_data(user_id):
    profile = await get_user_profile(user_id)
    orders = await get_user_orders(user_id)
    recommendations = await get_recommendations(user_id)
    return {
        "profile": profile,
        "orders": orders,
        "recommendations": recommendations
    }
```

**✅ Do:**
```python
# Concurrent async calls
async def get_dashboard_data(user_id):
    profile_task = asyncio.create_task(get_user_profile(user_id))
    orders_task = asyncio.create_task(get_user_orders(user_id))
    recommendations_task = asyncio.create_task(get_recommendations(user_id))
    
    return {
        "profile": await profile_task,
        "orders": await orders_task,
        "recommendations": await recommendations_task
    }
```

### 5. Connection Pooling

**Best Practice Configuration:**
```python
# Database connection pool
engine = create_async_engine(
    DATABASE_URL,
    pool_size=20,          # Base pool size
    max_overflow=10,       # Additional connections under load
    pool_timeout=30,       # Timeout waiting for connection
    pool_recycle=3600,     # Recycle connections after 1 hour
    pool_pre_ping=True,    # Test connections before use
)

# Redis connection pool
redis_pool = await aioredis.create_pool(
    'redis://localhost',
    minsize=10,
    maxsize=50,
    timeout=10,
    encoding='utf-8'
)
```

## 🚀 Scalability Best Practices

### 1. Horizontal Scaling Design

**Design Principles:**
- **Stateless Services**: Store session data in Redis/database
- **Shared Nothing Architecture**: Each instance is independent
- **Database Per Service**: Microservices own their data
- **Event-Driven Communication**: Use message queues for async operations

```python
# Stateless service example
class OrderService:
    def __init__(self, db, cache, message_queue):
        self.db = db
        self.cache = cache
        self.mq = message_queue
    
    async def create_order(self, order_data: dict, session_id: str):
        # Get session from cache, not memory
        session = await self.cache.get(f"session:{session_id}")
        
        # Process order
        order = await self.db.create_order(order_data)
        
        # Emit event for other services
        await self.mq.publish("order.created", order.to_dict())
        
        return order
```

### 2. Load Balancing Strategies

**Choose the Right Algorithm:**

| Algorithm | Use Case | Pros | Cons |
|-----------|----------|------|------|
| Round Robin | Uniform servers | Simple, fair distribution | Ignores server load |
| Least Connections | Variable request duration | Balances active load | Requires connection tracking |
| Weighted | Different server capacities | Handles heterogeneous servers | Manual weight management |
| IP Hash | Session affinity needed | Consistent routing | Uneven distribution possible |

### 3. Database Sharding

**Sharding Strategies:**

```python
class ShardingStrategy:
    @staticmethod
    def by_user_id(user_id: int) -> str:
        """Geographic/alphabetic sharding"""
        shard_count = 4
        return f"shard_{user_id % shard_count}"
    
    @staticmethod
    def by_tenant(tenant_id: str) -> str:
        """Tenant-based sharding for B2B"""
        return f"shard_{hash(tenant_id) % 8}"
    
    @staticmethod
    def by_date(timestamp: datetime) -> str:
        """Time-based sharding for logs/analytics"""
        return f"shard_{timestamp.year}_{timestamp.month}"
```

### 4. Rate Limiting

**Implement Multiple Strategies:**

```python
class RateLimiter:
    def __init__(self, redis_client):
        self.redis = redis_client
    
    async def check_rate_limit(self, key: str, limit: int, window: int):
        """Sliding window rate limiter"""
        now = time.time()
        pipeline = self.redis.pipeline()
        
        # Remove old entries
        pipeline.zremrangebyscore(key, 0, now - window)
        
        # Count current entries
        pipeline.zcard(key)
        
        # Add current request
        pipeline.zadd(key, now, now)
        
        # Set expiry
        pipeline.expire(key, window)
        
        results = await pipeline.execute()
        current_count = results[1]
        
        return current_count < limit
```

## 🔍 Monitoring and Observability

### 1. The Four Golden Signals

Monitor these for every service:

1. **Latency**: Response time distribution
2. **Traffic**: Requests per second
3. **Errors**: Error rate and types
4. **Saturation**: Resource utilization

```python
# Comprehensive monitoring decorator
def monitor_endpoint(name: str):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            start_time = time.time()
            
            try:
                # Increment traffic counter
                traffic_counter.labels(endpoint=name).inc()
                
                # Execute function
                result = await func(*args, **kwargs)
                
                # Record success latency
                latency = time.time() - start_time
                latency_histogram.labels(
                    endpoint=name,
                    status="success"
                ).observe(latency)
                
                return result
                
            except Exception as e:
                # Record error
                error_counter.labels(
                    endpoint=name,
                    error_type=type(e).__name__
                ).inc()
                
                # Record error latency
                latency = time.time() - start_time
                latency_histogram.labels(
                    endpoint=name,
                    status="error"
                ).observe(latency)
                
                raise
                
        return wrapper
    return decorator
```

### 2. Distributed Tracing

```python
# OpenTelemetry integration
from opentelemetry import trace
from opentelemetry.trace import Status, StatusCode

tracer = trace.get_tracer(__name__)

async def process_order(order_id: str):
    with tracer.start_as_current_span("process_order") as span:
        span.set_attribute("order.id", order_id)
        
        # Validate order
        with tracer.start_span("validate_order"):
            validation_result = await validate_order(order_id)
            
        # Process payment
        with tracer.start_span("process_payment"):
            payment_result = await process_payment(order_id)
            
        # Update inventory
        with tracer.start_span("update_inventory"):
            inventory_result = await update_inventory(order_id)
            
        span.set_status(Status(StatusCode.OK))
        return {"status": "completed"}
```

## 🛡️ Resilience Patterns

### 1. Circuit Breaker Pattern

```python
class CircuitBreaker:
    def __init__(self, failure_threshold=5, recovery_timeout=60):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.failure_count = 0
        self.last_failure_time = None
        self.state = "CLOSED"  # CLOSED, OPEN, HALF_OPEN
    
    async def call(self, func, *args, **kwargs):
        if self.state == "OPEN":
            if time.time() - self.last_failure_time > self.recovery_timeout:
                self.state = "HALF_OPEN"
            else:
                raise Exception("Circuit breaker is OPEN")
        
        try:
            result = await func(*args, **kwargs)
            if self.state == "HALF_OPEN":
                self.state = "CLOSED"
                self.failure_count = 0
            return result
            
        except Exception as e:
            self.failure_count += 1
            self.last_failure_time = time.time()
            
            if self.failure_count >= self.failure_threshold:
                self.state = "OPEN"
                
            raise
```

### 2. Bulkhead Pattern

```python
# Isolate resources to prevent cascading failures
class BulkheadExecutor:
    def __init__(self, max_concurrent=10):
        self.semaphore = asyncio.Semaphore(max_concurrent)
    
    async def execute(self, func, *args, **kwargs):
        async with self.semaphore:
            return await func(*args, **kwargs)

# Usage
bulkhead_db = BulkheadExecutor(max_concurrent=20)
bulkhead_api = BulkheadExecutor(max_concurrent=50)

# Database operations limited to 20 concurrent
result = await bulkhead_db.execute(db.query, "SELECT * FROM users")

# External API calls limited to 50 concurrent
response = await bulkhead_api.execute(httpx.get, "https://api.example.com")
```

### 3. Retry with Backoff

```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=4, max=10)
)
async def call_external_api(url: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        response.raise_for_status()
        return response.json()
```

## 📈 Performance Testing Best Practices

### 1. Realistic Load Testing

```python
# Simulate realistic user behavior
class RealisticLoadTest:
    def __init__(self):
        self.user_scenarios = [
            (0.6, self.browse_products),    # 60% just browse
            (0.3, self.add_to_cart),        # 30% add to cart
            (0.1, self.complete_purchase)    # 10% complete purchase
        ]
    
    async def simulate_user(self):
        # Random think time between actions
        await asyncio.sleep(random.uniform(1, 5))
        
        # Choose scenario based on probability
        rand = random.random()
        cumulative = 0
        
        for probability, scenario in self.user_scenarios:
            cumulative += probability
            if rand <= cumulative:
                await scenario()
                break
```

### 2. Capacity Planning

```python
# Calculate required resources
def capacity_planning(
    expected_rps: int,
    avg_response_time_ms: float,
    cpu_per_request: float,
    memory_per_request_mb: float
) -> dict:
    # Little's Law: N = λ * W
    concurrent_requests = expected_rps * (avg_response_time_ms / 1000)
    
    # Resource calculation with 20% headroom
    required_cpu = concurrent_requests * cpu_per_request * 1.2
    required_memory_gb = (concurrent_requests * memory_per_request_mb / 1024) * 1.2
    
    # Assuming 4 CPU cores and 16GB RAM per instance
    instances_needed = max(
        math.ceil(required_cpu / 4),
        math.ceil(required_memory_gb / 16)
    )
    
    return {
        "concurrent_requests": concurrent_requests,
        "required_cpu_cores": required_cpu,
        "required_memory_gb": required_memory_gb,
        "instances_needed": instances_needed
    }
```

## 🚨 Common Pitfalls and Solutions

### 1. Memory Leaks

**Prevention:**
```python
# Use weak references for caches
import weakref

class CacheWithCleanup:
    def __init__(self):
        self._cache = weakref.WeakValueDictionary()
    
    def set(self, key, value):
        self._cache[key] = value
    
    def get(self, key):
        return self._cache.get(key)
```

### 2. Connection Leaks

**Prevention:**
```python
# Always use context managers
async def safe_database_operation():
    async with get_db_session() as session:
        # Session automatically closed
        result = await session.query(User).all()
        return result

# For manual management, ensure cleanup
session = None
try:
    session = await create_session()
    result = await session.query(User).all()
finally:
    if session:
        await session.close()
```

### 3. Thundering Herd

**Prevention:**
```python
# Add jitter to prevent synchronized requests
async def cache_with_jitter(key: str, fetch_func):
    value = await cache.get(key)
    if value is None:
        # Add random jitter to TTL
        ttl = 300 + random.randint(-30, 30)
        value = await fetch_func()
        await cache.set(key, value, ttl=ttl)
    return value
```

## 🎯 Optimization Checklist

Before deploying to production, ensure:

- [ ] **Profiling**: Identified actual bottlenecks with data
- [ ] **Caching**: Implemented multi-level caching where appropriate
- [ ] **Database**: Optimized queries, added proper indexes
- [ ] **Async**: Using concurrent operations where possible
- [ ] **Monitoring**: Full observability stack in place
- [ ] **Load Testing**: Validated performance under expected load
- [ ] **Resilience**: Circuit breakers and retry logic implemented
- [ ] **Documentation**: Performance characteristics documented
- [ ] **Alerts**: Set up for performance degradation
- [ ] **Capacity**: Planned for 2x expected load

## 📚 Recommended Reading

1. **"High Performance Python"** - Gorelick & Ozsvald
2. **"Designing Data-Intensive Applications"** - Martin Kleppmann
3. **"Site Reliability Engineering"** - Google SRE Team
4. **"Release It!"** - Michael Nygard
5. **"The Art of Scalability"** - Abbott & Fisher

Remember: **Premature optimization is the root of all evil, but prepared optimization is the key to success.**