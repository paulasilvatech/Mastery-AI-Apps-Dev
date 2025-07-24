---
sidebar_position: 4
title: "Exercise 1: Part 2"
description: "## 🛠️ Implementing the Caching System"
---

# Ejercicio 1: Partee 2 - Implementation

## 🛠️ Implementing the Caching System

### Step 8: Completar the Local Cache Implementation

Actualizar `app/cache/local_cache.py` with the full implementation:

**🤖 Copilot Prompt Suggestion #4:**
```python
# Complete the LocalCache implementation:
# Add methods for:
# - _evict_lru(): Remove least recently used items when full
# - _is_expired(): Check if cache entry has expired
# - get_stats(): Return cache statistics
# - clear_expired(): Remove all expired entries
# - warmup(): Pre-populate cache with frequently accessed items
```

**Expected Completar Implementation:**
```python
import asyncio
from typing import Optional, Any, Dict, List
from datetime import datetime, timedelta
from collections import OrderedDict
import threading
import json
import logging

logger = logging.getLogger(__name__)

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
    
    async def get(self, key: str) -&gt; Optional[Any]:
        """Get value from cache with TTL check."""
        with self.lock:
            if key in self.cache:
                entry = self.cache[key]
                if not self._is_expired(entry):
                    # Move to end (most recently used)
                    self.cache.move_to_end(key)
                    self.stats["hits"] += 1
                    logger.debug(f"Local cache hit for key: {key}")
                    return entry["value"]
                else:
                    # Remove expired entry
                    del self.cache[key]
                    logger.debug(f"Expired entry removed for key: {key}")
            
            self.stats["misses"] += 1
            return None
    
    async def set(self, key: str, value: Any, ttl: Optional[int] = None) -&gt; None:
        """Set value in cache with optional TTL."""
        with self.lock:
            # Check if we need to evict
            if len(self.cache) &gt;= self.max_size and key not in self.cache:
                self._evict_lru()
            
            expire_at = datetime.utcnow() + timedelta(seconds=ttl or self.default_ttl)
            self.cache[key] = {
                "value": value,
                "expire_at": expire_at
            }
            self.cache.move_to_end(key)
            self.stats["sets"] += 1
            logger.debug(f"Set key: {key} with TTL: {ttl or self.default_ttl}s")
    
    async def delete(self, key: str) -&gt; bool:
        """Delete key from cache."""
        with self.lock:
            if key in self.cache:
                del self.cache[key]
                self.stats["deletes"] += 1
                return True
            return False
    
    def _evict_lru(self) -&gt; None:
        """Evict least recently used item."""
        if self.cache:
            lru_key = next(iter(self.cache))
            del self.cache[lru_key]
            self.stats["evictions"] += 1
            logger.debug(f"Evicted LRU key: {lru_key}")
    
    def _is_expired(self, entry: Dict[str, Any]) -&gt; bool:
        """Check if cache entry has expired."""
        return datetime.utcnow() &gt; entry["expire_at"]
    
    async def clear(self) -&gt; None:
        """Clear all cache entries."""
        with self.lock:
            self.cache.clear()
            logger.info("Local cache cleared")
    
    async def clear_expired(self) -&gt; int:
        """Remove all expired entries."""
        with self.lock:
            expired_keys = [
                key for key, entry in self.cache.items() 
                if self._is_expired(entry)
            ]
            for key in expired_keys:
                del self.cache[key]
            logger.info(f"Cleared {len(expired_keys)} expired entries")
            return len(expired_keys)
    
    def get_stats(self) -&gt; Dict[str, Any]:
        """Get cache statistics."""
        with self.lock:
            total_requests = self.stats["hits"] + self.stats["misses"]
            hit_rate = self.stats["hits"] / total_requests if total_requests &gt; 0 else 0
            
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
```

### Step 9: Completar Redis Cache Implementation

Actualizar `app/cache/redis_cache.py`:

**🤖 Copilot Prompt Suggestion #5:**
```python
# Complete the Redis cache with:
# - Automatic retry with exponential backoff
# - Connection health checks
# - Batch get/set operations for efficiency
# - Cache tagging for group invalidation
# - Async context manager for connection lifecycle
```

### Step 10: Implement the Cache Manager

Completar `app/cache/cache_manager.py`:

```python
from typing import Optional, Any, Callable, List
import logging
from .local_cache import LocalCache
from .redis_cache import RedisCache
from ..monitoring import cache_hits, cache_misses
import asyncio
import json

logger = logging.getLogger(__name__)

class CacheManager:
    def __init__(
        self, 
        local_cache: LocalCache,
        redis_cache: RedisCache,
        namespace: str = "app"
    ):
        """
        Initialize cache manager with two-level caching.
        
        Args:
            local_cache: L1 cache (in-memory)
            redis_cache: L2 cache (Redis)
            namespace: Cache key namespace
        """
        self.local_cache = local_cache
        self.redis_cache = redis_cache
        self.namespace = namespace
        
    def _make_key(self, key: str) -&gt; str:
        """Create namespaced cache key."""
        return f"{self.namespace}:{key}"
    
    async def get(
        self, 
        key: str, 
        fetch_func: Optional[Callable] = None
    ) -&gt; Optional[Any]:
        """
        Get value from cache with fallback to fetch function.
        
        Args:
            key: Cache key
            fetch_func: Async function to fetch data if cache miss
            
        Returns:
            Cached value or fetched value
        """
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
            # Populate L1 cache
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
    
    async def set(
        self, 
        key: str, 
        value: Any, 
        ttl: Optional[int] = None
    ) -&gt; None:
        """Set value in both cache levels."""
        full_key = self._make_key(key)
        
        # Set in both caches concurrently
        await asyncio.gather(
            self.local_cache.set(full_key, value, ttl),
            self.redis_cache.set(full_key, value, ttl),
            return_exceptions=True
        )
    
    async def delete(self, key: str) -&gt; None:
        """Delete from both cache levels."""
        full_key = self._make_key(key)
        
        await asyncio.gather(
            self.local_cache.delete(full_key),
            self.redis_cache.delete(full_key),
            return_exceptions=True
        )
    
    async def delete_pattern(self, pattern: str) -&gt; int:
        """Delete all keys matching pattern."""
        # Only Redis supports pattern deletion
        full_pattern = self._make_key(pattern)
        count = await self.redis_cache.delete_pattern(full_pattern)
        
        # Clear local cache to ensure consistency
        await self.local_cache.clear()
        
        return count
    
    async def warmup(self, keys: List[str], fetch_func: Callable) -&gt; None:
        """Pre-populate cache with frequently accessed data."""
        logger.info(f"Warming up cache with {len(keys)} keys")
        
        tasks = []
        for key in keys:
            task = self.get(key, lambda k=key: fetch_func(k))
            tasks.append(task)
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        success_count = sum(1 for r in results if not isinstance(r, Exception))
        logger.info(f"Cache warmup complete. Success: {success_count}/{len(keys)}")
```

### Step 11: Create the FastAPI Application

Create `app/main.py`:

**🤖 Copilot Prompt Suggestion #6:**
```python
# Create a FastAPI application with:
# - Product CRUD endpoints with caching
# - Cache statistics endpoint
# - Cache invalidation endpoints
# - Health check with cache status
# - Prometheus metrics endpoint
# - Request ID tracking
# - Comprehensive error handling
# Use dependency injection for cache and database
```

**Expected Implementation Structure:**
```python
from fastapi import FastAPI, Depends, HTTPException, Request
from fastapi.responses import JSONResponse
from prometheus_client import generate_latest
from typing import List, Optional
import logging
import os
from contextlib import asynccontextmanager

from .models import Product, CacheStats
from .database import get_db, init_db, ProductDB
from .cache.local_cache import LocalCache
from .cache.redis_cache import RedisCache
from .cache.cache_manager import CacheManager
from .monitoring import track_performance

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global cache instances
local_cache = LocalCache(max_size=1000, default_ttl=300)
redis_cache = RedisCache(
    redis_url=os.getenv("REDIS_URL", "redis://localhost:6379")
)
cache_manager = CacheManager(local_cache, redis_cache, namespace="products")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting up...")
    await init_db()
    await redis_cache.connect()
    
    # Warmup cache with popular products
    # await warmup_cache()
    
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

# Add your endpoints here...
```

### Step 12: Implement API Endpoints

Add these endpoints to `app/main.py`:

```python
@app.get("/products/{product_id}", response_model=Product)
@track_performance("get_product")
async def get_product(
    product_id: int,
    db: AsyncSession = Depends(get_db)
) -&gt; Product:
    """Get product by ID with caching."""
    cache_key = f"product:{product_id}"
    
    # Define fetch function for cache miss
    async def fetch_product():
        result = await db.execute(
            select(ProductDB).where(ProductDB.id == product_id)
        )
        product_db = result.scalar_one_or_none()
        if not product_db:
            return None
        return Product.from_orm(product_db)
    
    # Get from cache or fetch
    product = await cache_manager.get(cache_key, fetch_product)
    
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    return product

@app.get("/products", response_model=List[Product])
@track_performance("list_products")
async def list_products(
    category: Optional[str] = None,
    limit: int = 100,
    offset: int = 0,
    db: AsyncSession = Depends(get_db)
) -&gt; List[Product]:
    """List products with optional filtering."""
    cache_key = f"products:list:{category}:{limit}:{offset}"
    
    async def fetch_products():
        query = select(ProductDB)
        if category:
            query = query.where(ProductDB.category == category)
        query = query.limit(limit).offset(offset)
        
        result = await db.execute(query)
        products_db = result.scalars().all()
        return [Product.from_orm(p) for p in products_db]
    
    return await cache_manager.get(cache_key, fetch_products)

@app.post("/products/{product_id}/invalidate")
async def invalidate_product_cache(product_id: int):
    """Invalidate cache for a specific product."""
    await cache_manager.delete(f"product:{product_id}")
    # Also invalidate related list caches
    await cache_manager.delete_pattern("products:list:*")
    return {{"message": f"Cache invalidated for product {{product_id}}"}}

@app.get("/cache/stats", response_model=CacheStats)
async def get_cache_stats():
    """Get cache performance statistics."""
    local_stats = local_cache.get_stats()
    redis_stats = await redis_cache.get_stats()
    
    total_requests = local_stats["hits"] + local_stats["misses"]
    
    return CacheStats(
        total_requests=total_requests,
        cache_hits=local_stats["hits"],
        cache_misses=local_stats["misses"],
        hit_rate=local_stats["hit_rate"],
        avg_response_time_ms=0  # Calculate from monitoring data
    )

@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint."""
    return Response(
        generate_latest(),
        media_type="text/plain"
    )
```

## 🧪 Testing Your Implementation

Continuar to [Partee 3: Testing and Validation](./exercise1-part3) →