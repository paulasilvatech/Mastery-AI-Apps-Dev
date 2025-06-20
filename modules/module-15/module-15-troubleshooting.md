# Module 15: Troubleshooting Guide

## 🔍 Common Issues and Solutions

This guide helps you diagnose and resolve common performance and scalability issues encountered in Module 15.

## 🚨 Performance Issues

### 1. Slow API Response Times

**Symptoms:**
- Response times > 1 second
- Timeouts under load
- Users reporting sluggish interface

**Diagnosis Steps:**

```python
# 1. Enable detailed logging
import logging
logging.basicConfig(level=logging.DEBUG)

# 2. Add request timing middleware
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    
    if process_time > 1.0:
        logger.warning(f"Slow request: {request.url.path} took {process_time}s")
    
    return response

# 3. Profile specific endpoints
from line_profiler import LineProfiler
lp = LineProfiler()
lp.add_function(your_slow_function)

# 4. Check database queries
# Enable query logging in PostgreSQL
# log_statement = 'all'
# log_duration = on
```

**Common Causes and Solutions:**

| Cause | Solution |
|-------|----------|
| N+1 queries | Use eager loading or DataLoader pattern |
| Missing indexes | Run `EXPLAIN ANALYZE` and add indexes |
| Large payload | Implement pagination and field filtering |
| Synchronous I/O | Convert to async operations |
| No caching | Add Redis caching layer |

**Quick Fix:**
```python
# Add caching to slow endpoints
@app.get("/api/products")
@cache(expire=300)  # Cache for 5 minutes
async def get_products():
    # Expensive operation
    return await db.fetch_products()
```

### 2. High Memory Usage

**Symptoms:**
- Memory usage constantly increasing
- OOM (Out of Memory) errors
- Server crashes under load

**Diagnosis:**

```python
# Memory profiling
from memory_profiler import profile

@profile
def memory_intensive_function():
    # Your code here
    pass

# Or use tracemalloc
import tracemalloc
tracemalloc.start()

# Your code here

current, peak = tracemalloc.get_traced_memory()
print(f"Current memory usage: {current / 10**6:.1f} MB")
print(f"Peak memory usage: {peak / 10**6:.1f} MB")
tracemalloc.stop()
```

**Common Memory Leaks:**

```python
# ❌ Bad: Global cache without limits
cache = {}  # Grows indefinitely

def cache_result(key, value):
    cache[key] = value  # Never cleaned up

# ✅ Good: LRU cache with size limit
from functools import lru_cache

@lru_cache(maxsize=1000)
def cached_function(param):
    return expensive_computation(param)

# Or use proper cache implementation
from cachetools import TTLCache
cache = TTLCache(maxsize=1000, ttl=300)
```

### 3. Database Connection Errors

**Symptoms:**
- "Too many connections" errors
- Connection timeouts
- Intermittent database failures

**Solutions:**

```python
# 1. Implement connection pooling
from sqlalchemy.pool import QueuePool

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=20,
    max_overflow=0,
    pool_pre_ping=True,  # Test connections before use
)

# 2. Use connection context manager
async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()

# 3. Monitor connection usage
@app.on_event("startup")
async def startup_event():
    # Log pool statistics periodically
    async def log_pool_stats():
        while True:
            pool = engine.pool
            logger.info(f"DB Pool - Size: {pool.size()}, Checked out: {pool.checked_out_connections}")
            await asyncio.sleep(60)
    
    asyncio.create_task(log_pool_stats())
```

## 🔄 Caching Issues

### 1. Cache Inconsistency

**Symptoms:**
- Stale data being served
- Updates not reflecting immediately
- Different users seeing different data

**Solutions:**

```python
# 1. Implement cache versioning
def make_cache_key(resource: str, id: str, version: str):
    return f"{resource}:{id}:v{version}"

# 2. Use cache tags for bulk invalidation
class TaggedCache:
    def __init__(self, redis_client):
        self.redis = redis_client
    
    async def set_with_tags(self, key: str, value: Any, tags: List[str]):
        # Store value
        await self.redis.set(key, json.dumps(value))
        
        # Store tags
        for tag in tags:
            await self.redis.sadd(f"tag:{tag}", key)
    
    async def invalidate_tag(self, tag: str):
        # Get all keys with this tag
        keys = await self.redis.smembers(f"tag:{tag}")
        
        # Delete all keys
        if keys:
            await self.redis.delete(*keys)
        
        # Delete the tag set
        await self.redis.delete(f"tag:{tag}")

# 3. Implement cache-aside with proper invalidation
async def get_product(product_id: int):
    cache_key = f"product:{product_id}"
    
    # Try cache first
    cached = await cache.get(cache_key)
    if cached:
        return cached
    
    # Fetch from database
    product = await db.get_product(product_id)
    
    # Cache with TTL
    await cache.set(cache_key, product, ttl=300)
    
    return product

async def update_product(product_id: int, updates: dict):
    # Update database
    await db.update_product(product_id, updates)
    
    # Invalidate cache
    await cache.delete(f"product:{product_id}")
    
    # Invalidate related caches
    await cache.delete_pattern(f"products:list:*")
```

### 2. Redis Connection Issues

**Symptoms:**
- "Connection refused" errors
- Redis timeouts
- Intermittent cache failures

**Diagnosis and Solutions:**

```bash
# Check Redis server status
redis-cli ping

# Monitor Redis performance
redis-cli --stat

# Check Redis logs
tail -f /var/log/redis/redis-server.log
```

```python
# Implement Redis connection retry
class ResilientRedisCache:
    def __init__(self, redis_url: str, max_retries: int = 3):
        self.redis_url = redis_url
        self.max_retries = max_retries
        self._redis = None
    
    async def _get_connection(self):
        if self._redis is None:
            for attempt in range(self.max_retries):
                try:
                    self._redis = await aioredis.create_redis_pool(
                        self.redis_url,
                        minsize=10,
                        maxsize=20
                    )
                    return self._redis
                except Exception as e:
                    if attempt == self.max_retries - 1:
                        raise
                    await asyncio.sleep(2 ** attempt)
        return self._redis
    
    async def get(self, key: str) -> Optional[Any]:
        try:
            redis = await self._get_connection()
            value = await redis.get(key)
            return json.loads(value) if value else None
        except Exception as e:
            logger.error(f"Redis get error: {e}")
            # Fallback to database
            return None
```

## ⚖️ Load Balancing Issues

### 1. Uneven Load Distribution

**Symptoms:**
- Some servers overloaded while others idle
- Inconsistent response times
- Hot spots in the cluster

**Solutions:**

```python
# 1. Implement least connections algorithm
class LeastConnectionsBalancer:
    def __init__(self, servers: List[Server]):
        self.servers = servers
        self.connections = {s.id: 0 for s in servers}
    
    async def select_server(self) -> Server:
        # Get healthy servers
        healthy = [s for s in self.servers if await s.is_healthy()]
        
        if not healthy:
            raise NoHealthyServersError()
        
        # Select server with least connections
        return min(healthy, key=lambda s: self.connections[s.id])
    
    async def request(self, server: Server):
        self.connections[server.id] += 1
        try:
            result = await server.process_request()
            return result
        finally:
            self.connections[server.id] -= 1

# 2. Add request routing based on load
class SmartLoadBalancer:
    def __init__(self):
        self.metrics = {}
    
    async def select_server(self, request_type: str) -> Server:
        if request_type == "cpu_intensive":
            # Route to servers with low CPU usage
            return self._select_by_metric("cpu_usage", ascending=True)
        elif request_type == "memory_intensive":
            # Route to servers with available memory
            return self._select_by_metric("memory_available", ascending=False)
        else:
            # Default round-robin
            return self._round_robin_select()
```

### 2. Health Check Failures

**Symptoms:**
- Servers marked unhealthy incorrectly
- Flapping health status
- All servers marked as unhealthy

**Solutions:**

```python
# Implement robust health checking
class HealthChecker:
    def __init__(self, threshold: int = 3, timeout: int = 5):
        self.threshold = threshold  # Failures before marking unhealthy
        self.timeout = timeout
        self.failure_counts = {}
    
    async def check_health(self, server: Server) -> bool:
        try:
            async with asyncio.timeout(self.timeout):
                response = await server.health_check()
                
                if response.status_code == 200:
                    # Reset failure count on success
                    self.failure_counts[server.id] = 0
                    return True
                
        except Exception as e:
            logger.warning(f"Health check failed for {server.id}: {e}")
        
        # Increment failure count
        self.failure_counts[server.id] = self.failure_counts.get(server.id, 0) + 1
        
        # Only mark unhealthy after threshold
        return self.failure_counts[server.id] < self.threshold
```

## 🔧 Debugging Tools

### 1. Performance Profiling

```python
# CPU profiling with cProfile
import cProfile
import pstats

def profile_endpoint():
    profiler = cProfile.Profile()
    profiler.enable()
    
    # Run your code
    result = your_function()
    
    profiler.disable()
    stats = pstats.Stats(profiler)
    stats.strip_dirs()
    stats.sort_stats('cumulative')
    stats.print_stats(10)  # Top 10 functions
    
    return result

# Async profiling with py-spy
# Run from command line:
# py-spy record -o profile.svg --duration 30 python app.py
```

### 2. Query Analysis

```sql
-- Find slow queries in PostgreSQL
SELECT 
    query,
    mean_exec_time,
    calls,
    total_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 100  -- Queries taking >100ms
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Analyze specific query
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM orders 
WHERE customer_id = 123 
AND created_at > '2024-01-01';
```

### 3. Real-time Monitoring

```python
# Add custom metrics endpoint
@app.get("/debug/metrics")
async def debug_metrics():
    return {
        "memory": {
            "rss": process.memory_info().rss / 1024 / 1024,  # MB
            "vms": process.memory_info().vms / 1024 / 1024,  # MB
        },
        "cpu": {
            "percent": process.cpu_percent(),
            "threads": process.num_threads(),
        },
        "connections": {
            "database": engine.pool.checked_out_connections,
            "redis": await redis.client_info()["connected_clients"],
        },
        "cache": {
            "local_size": local_cache.size(),
            "hit_rate": local_cache.get_hit_rate(),
        },
        "requests": {
            "active": active_requests,
            "total": total_requests,
            "errors": error_count,
        }
    }
```

## 🚑 Emergency Procedures

### 1. Service is Down

```bash
# 1. Check service status
systemctl status api-service

# 2. Check recent logs
journalctl -u api-service -n 100

# 3. Check resource usage
htop
df -h
free -m

# 4. Restart service
systemctl restart api-service

# 5. If still failing, check dependencies
redis-cli ping
psql -c "SELECT 1"
```

### 2. Database Overloaded

```sql
-- Kill long-running queries
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'active'
  AND query_start < now() - interval '5 minutes'
  AND query NOT LIKE '%pg_stat_activity%';

-- Check lock contention
SELECT 
    blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocked_activity.query AS blocked_statement,
    blocking_activity.query AS blocking_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

### 3. Cache Stampede

```python
# Emergency cache stampede prevention
class EmergencyCache:
    def __init__(self):
        self.locks = {}
    
    async def get_with_lock(self, key: str, fetch_func):
        # Check if someone is already fetching
        if key in self.locks:
            # Wait for the other request to complete
            return await self.locks[key]
        
        # Try to get from cache
        value = await cache.get(key)
        if value is not None:
            return value
        
        # Create a future for this key
        future = asyncio.Future()
        self.locks[key] = future
        
        try:
            # Fetch the value
            value = await fetch_func()
            
            # Update cache
            await cache.set(key, value)
            
            # Set the result
            future.set_result(value)
            
            return value
        except Exception as e:
            future.set_exception(e)
            raise
        finally:
            # Clean up lock after a delay
            asyncio.create_task(self._cleanup_lock(key))
    
    async def _cleanup_lock(self, key: str):
        await asyncio.sleep(0.1)
        self.locks.pop(key, None)
```

## 📊 Performance Monitoring Commands

```bash
# Monitor real-time performance
# CPU and Memory
htop

# Network connections
netstat -tuln

# Disk I/O
iotop

# Database connections
psql -c "SELECT count(*) FROM pg_stat_activity"

# Redis monitoring
redis-cli monitor

# API response times
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:8000/api/health

# Where curl-format.txt contains:
# time_namelookup:  %{time_namelookup}s\n
# time_connect:  %{time_connect}s\n
# time_appconnect:  %{time_appconnect}s\n
# time_pretransfer:  %{time_pretransfer}s\n
# time_redirect:  %{time_redirect}s\n
# time_starttransfer:  %{time_starttransfer}s\n
# time_total:  %{time_total}s\n
```

## 🎯 Quick Reference

| Issue | Quick Check | Quick Fix |
|-------|-------------|-----------|
| Slow API | Check `/debug/metrics` | Add caching |
| High memory | `ps aux | grep python` | Restart service |
| DB errors | `psql -c "SELECT 1"` | Check connection pool |
| Cache miss | `redis-cli INFO stats` | Warm cache |
| Load imbalance | Check server metrics | Adjust weights |

Remember: **When in doubt, check the logs!**