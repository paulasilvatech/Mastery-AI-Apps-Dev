# Exercise 1: Complete Solution - Multi-Level Caching System

import asyncio
from typing import Optional, Any, Dict, List, Callable
from datetime import datetime, timedelta
from collections import OrderedDict
import threading
import json
import logging
import redis.asyncio as redis
from fastapi import FastAPI, Depends, HTTPException, Response
from pydantic import BaseModel
from prometheus_client import Counter, Histogram, Gauge, generate_latest
from contextlib import asynccontextmanager
import time
from functools import wraps

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ============= Models =============
class Product(BaseModel):
    id: int
    name: str
    description: str
    price: float
    category: str
    in_stock: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

class CacheStats(BaseModel):
    total_requests: int
    cache_hits: int
    cache_misses: int
    hit_rate: float
    avg_response_time_ms: float
    local_cache_size: int
    redis_connected: bool

# ============= Monitoring =============
cache_hits = Counter('cache_hits_total', 'Total cache hits', ['cache_type'])
cache_misses = Counter('cache_misses_total', 'Total cache misses', ['cache_type'])
request_duration = Histogram('request_duration_seconds', 'Request duration', ['endpoint'])
cache_size = Gauge('cache_size_bytes', 'Current cache size', ['cache_type'])

def track_performance(endpoint: str):
    """Decorator to track endpoint performance."""
    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            start_time = time.time()
            try:
                result = await func(*args, **kwargs)
                return result
            finally:
                duration = time.time() - start_time
                request_duration.labels(endpoint=endpoint).observe(duration)
        return wrapper
    return decorator

# ============= Local Cache Implementation =============
class LocalCache:
    def __init__(self, max_size: int = 1000, default_ttl: int = 300):
        """Initialize local cache with size limit and default TTL."""
        self.max_size = max_size
        self.default_ttl = default_ttl
        self.cache: OrderedDict[str, Dict[str, Any]] = OrderedDict()
        self.lock = threading.RLock()
        self.stats = {
            "hits": 0,
            "misses": 0,
            "sets": 0,
            "deletes": 0,
            "evictions": 0
        }
    
    async def get(self, key: str) -> Optional[Any]:
        """Get value from cache with TTL check."""
        with self.lock:
            if key in self.cache:
                entry = self.cache[key]
                if not self._is_expired(entry):
                    self.cache.move_to_end(key)
                    self.stats["hits"] += 1
                    logger.debug(f"Local cache hit for key: {key}")
                    return entry["value"]
                else:
                    del self.cache[key]
                    logger.debug(f"Expired entry removed for key: {key}")
            
            self.stats["misses"] += 1
            return None
    
    async def set(self, key: str, value: Any, ttl: Optional[int] = None) -> None:
        """Set value in cache with optional TTL."""
        with self.lock:
            if len(self.cache) >= self.max_size and key not in self.cache:
                self._evict_lru()
            
            expire_at = datetime.utcnow() + timedelta(seconds=ttl or self.default_ttl)
            self.cache[key] = {
                "value": value,
                "expire_at": expire_at
            }
            self.cache.move_to_end(key)
            self.stats["sets"] += 1
            cache_size.labels(cache_type="local").set(len(self.cache))
    
    async def delete(self, key: str) -> bool:
        """Delete key from cache."""
        with self.lock:
            if key in self.cache:
                del self.cache[key]
                self.stats["deletes"] += 1
                cache_size.labels(cache_type="local").set(len(self.cache))
                return True
            return False
    
    async def clear(self) -> None:
        """Clear all cache entries."""
        with self.lock:
            self.cache.clear()
            cache_size.labels(cache_type="local").set(0)
    
    def _evict_lru(self) -> None:
        """Evict least recently used item."""
        if self.cache:
            lru_key = next(iter(self.cache))
            del self.cache[lru_key]
            self.stats["evictions"] += 1
    
    def _is_expired(self, entry: Dict[str, Any]) -> bool:
        """Check if cache entry has expired."""
        return datetime.utcnow() > entry["expire_at"]
    
    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics."""
        with self.lock:
            total_requests = self.stats["hits"] + self.stats["misses"]
            hit_rate = self.stats["hits"] / total_requests if total_requests > 0 else 0
            
            return {
                "size": len(self.cache),
                "max_size": self.max_size,
                "hits": self.stats["hits"],
                "misses": self.stats["misses"],
                "hit_rate": hit_rate,
                "sets": self.stats["sets"],
                "deletes": self.stats["deletes"],
                "evictions": self.stats["evictions"]
            }

# ============= Redis Cache Implementation =============
class RedisCache:
    def __init__(self, redis_url: str, prefix: str = "cache:"):
        """Initialize Redis cache with connection pooling."""
        self.redis_url = redis_url
        self.prefix = prefix
        self.pool = None
        self.redis_client = None
        self._connected = False
    
    async def connect(self):
        """Establish connection to Redis with retry logic."""
        max_retries = 3
        retry_delay = 1
        
        for attempt in range(max_retries):
            try:
                self.pool = redis.ConnectionPool.from_url(
                    self.redis_url,
                    decode_responses=True,
                    max_connections=50
                )
                self.redis_client = redis.Redis(connection_pool=self.pool)
                await self.redis_client.ping()
                self._connected = True
                logger.info("Connected to Redis successfully")
                return
            except Exception as e:
                logger.error(f"Redis connection attempt {attempt + 1} failed: {e}")
                if attempt < max_retries - 1:
                    await asyncio.sleep(retry_delay)
                    retry_delay *= 2
        
        logger.error("Failed to connect to Redis after all retries")
    
    async def disconnect(self):
        """Close Redis connection."""
        if self.redis_client:
            await self.redis_client.close()
            self._connected = False
    
    async def get(self, key: str) -> Optional[Any]:
        """Get value from Redis with automatic deserialization."""
        if not self._connected:
            return None
        
        try:
            value = await self.redis_client.get(f"{self.prefix}{key}")
            if value:
                return json.loads(value)
            return None
        except Exception as e:
            logger.error(f"Redis get error: {e}")
            return None
    
    async def set(self, key: str, value: Any, ttl: Optional[int] = None) -> None:
        """Set value in Redis with optional TTL."""
        if not self._connected:
            return
        
        try:
            serialized = json.dumps(value, default=str)
            full_key = f"{self.prefix}{key}"
            
            if ttl:
                await self.redis_client.setex(full_key, ttl, serialized)
            else:
                await self.redis_client.set(full_key, serialized)
        except Exception as e:
            logger.error(f"Redis set error: {e}")
    
    async def delete(self, key: str) -> bool:
        """Delete key from Redis."""
        if not self._connected:
            return False
        
        try:
            result = await self.redis_client.delete(f"{self.prefix}{key}")
            return result > 0
        except Exception as e:
            logger.error(f"Redis delete error: {e}")
            return False
    
    async def delete_pattern(self, pattern: str) -> int:
        """Delete all keys matching pattern."""
        if not self._connected:
            return 0
        
        try:
            full_pattern = f"{self.prefix}{pattern}"
            keys = []
            async for key in self.redis_client.scan_iter(match=full_pattern):
                keys.append(key)
            
            if keys:
                return await self.redis_client.delete(*keys)
            return 0
        except Exception as e:
            logger.error(f"Redis delete pattern error: {e}")
            return 0
    
    async def clear(self) -> None:
        """Clear all cache entries with prefix."""
        await self.delete_pattern("*")
    
    async def get_stats(self) -> Dict[str, Any]:
        """Get Redis statistics."""
        if not self._connected:
            return {"connected": False}
        
        try:
            info = await self.redis_client.info()
            return {
                "connected": True,
                "used_memory": info.get("used_memory_human", "unknown"),
                "connected_clients": info.get("connected_clients", 0),
                "total_commands": info.get("total_commands_processed", 0)
            }
        except Exception as e:
            logger.error(f"Redis stats error: {e}")
            return {"connected": False, "error": str(e)}

# ============= Cache Manager =============
class CacheManager:
    def __init__(self, local_cache: LocalCache, redis_cache: RedisCache, namespace: str = "app"):
        """Initialize cache manager with two-level caching."""
        self.local_cache = local_cache
        self.redis_cache = redis_cache
        self.namespace = namespace
    
    def _make_key(self, key: str) -> str:
        """Create namespaced cache key."""
        return f"{self.namespace}:{key}"
    
    async def get(self, key: str, fetch_func: Optional[Callable] = None) -> Optional[Any]:
        """Get value from cache with fallback to fetch function."""
        full_key = self._make_key(key)
        
        # Try L1 cache first
        value = await self.local_cache.get(full_key)
        if value is not None:
            cache_hits.labels(cache_type="local").inc()
            return value
        
        cache_misses.labels(cache_type="local").inc()
        
        # Try L2 cache
        value = await self.redis_cache.get(full_key)
        if value is not None:
            cache_hits.labels(cache_type="redis").inc()
            await self.local_cache.set(full_key, value)
            return value
        
        cache_misses.labels(cache_type="redis").inc()
        
        # Fetch from source if provided
        if fetch_func:
            try:
                value = await fetch_func()
                if value is not None:
                    await self.set(key, value)
                return value
            except Exception as e:
                logger.error(f"Error fetching data for key {key}: {e}")
                raise
        
        return None
    
    async def set(self, key: str, value: Any, ttl: Optional[int] = None) -> None:
        """Set value in both cache levels."""
        full_key = self._make_key(key)
        
        await asyncio.gather(
            self.local_cache.set(full_key, value, ttl),
            self.redis_cache.set(full_key, value, ttl),
            return_exceptions=True
        )
    
    async def delete(self, key: str) -> None:
        """Delete from both cache levels."""
        full_key = self._make_key(key)
        
        await asyncio.gather(
            self.local_cache.delete(full_key),
            self.redis_cache.delete(full_key),
            return_exceptions=True
        )
    
    async def delete_pattern(self, pattern: str) -> int:
        """Delete all keys matching pattern."""
        full_pattern = self._make_key(pattern)
        count = await self.redis_cache.delete_pattern(full_pattern)
        await self.local_cache.clear()
        return count

# ============= FastAPI Application =============
# Global cache instances
local_cache = LocalCache(max_size=1000, default_ttl=300)
redis_cache = RedisCache(redis_url="redis://localhost:6379")
cache_manager = CacheManager(local_cache, redis_cache, namespace="products")

# Simulated database
PRODUCTS_DB = {}

async def init_sample_data():
    """Initialize sample product data."""
    for i in range(1, 101):
        PRODUCTS_DB[i] = Product(
            id=i,
            name=f"Product {i}",
            description=f"Description for product {i}",
            price=round(10 + (i * 1.5), 2),
            category=["electronics", "books", "clothing", "food"][i % 4],
            in_stock=i % 5 != 0,
            created_at=datetime.utcnow()
        )

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting up...")
    await init_sample_data()
    await redis_cache.connect()
    yield
    # Shutdown
    logger.info("Shutting down...")
    await redis_cache.disconnect()

app = FastAPI(
    title="Product Catalog API",
    description="High-performance API with multi-level caching",
    version="1.0.0",
    lifespan=lifespan
)

@app.get("/products/{product_id}", response_model=Product)
@track_performance("get_product")
async def get_product(product_id: int) -> Product:
    """Get product by ID with caching."""
    cache_key = f"product:{product_id}"
    
    async def fetch_product():
        # Simulate database query
        await asyncio.sleep(0.1)  # Simulate DB latency
        return PRODUCTS_DB.get(product_id)
    
    product = await cache_manager.get(cache_key, fetch_product)
    
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    return product

@app.get("/products", response_model=List[Product])
@track_performance("list_products")
async def list_products(
    category: Optional[str] = None,
    limit: int = 20,
    offset: int = 0
) -> List[Product]:
    """List products with optional filtering."""
    cache_key = f"products:list:{category}:{limit}:{offset}"
    
    async def fetch_products():
        # Simulate database query
        await asyncio.sleep(0.15)  # Simulate DB latency
        products = list(PRODUCTS_DB.values())
        
        if category:
            products = [p for p in products if p.category == category]
        
        return products[offset:offset + limit]
    
    return await cache_manager.get(cache_key, fetch_products)

@app.post("/products/{product_id}/invalidate")
async def invalidate_product_cache(product_id: int):
    """Invalidate cache for a specific product."""
    await cache_manager.delete(f"product:{product_id}")
    await cache_manager.delete_pattern("products:list:*")
    return {"message": f"Cache invalidated for product {product_id}"}

@app.get("/cache/stats", response_model=CacheStats)
async def get_cache_stats():
    """Get cache performance statistics."""
    local_stats = local_cache.get_stats()
    redis_stats = await redis_cache.get_stats()
    
    total_requests = local_stats["hits"] + local_stats["misses"]
    
    # Calculate average response time from Prometheus data
    avg_response_time = 50.0  # Mock value, would come from metrics
    
    return CacheStats(
        total_requests=total_requests,
        cache_hits=local_stats["hits"],
        cache_misses=local_stats["misses"],
        hit_rate=local_stats["hit_rate"],
        avg_response_time_ms=avg_response_time,
        local_cache_size=local_stats["size"],
        redis_connected=redis_stats.get("connected", False)
    )

@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint."""
    return Response(
        generate_latest(),
        media_type="text/plain"
    )

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    redis_stats = await redis_cache.get_stats()
    
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow(),
        "cache_status": {
            "local": "active",
            "redis": "connected" if redis_stats.get("connected") else "disconnected"
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)