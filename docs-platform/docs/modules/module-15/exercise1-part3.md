---
sidebar_position: 6
title: "Exercise 1: Part 3"
description: "## 🧪 Testing Your Caching Implementation"
---

# Exercise 1: Part 3 - Testing and Validation

## 🧪 Testing Your Caching Implementation

### Step 13: Create Unit Tests

Create `tests/test_cache.py`:

**🤖 Copilot Prompt Suggestion #7:**
```python
# Create comprehensive tests for the caching system:
# - Test cache hit/miss scenarios
# - Test TTL expiration
# - Test LRU eviction
# - Test concurrent access
# - Test cache invalidation
# - Test performance improvements
# Use pytest with async support
```

**Expected Test Implementation:**
```python
import pytest
import asyncio
from datetime import datetime, timedelta
import time
from app.cache.local_cache import LocalCache
from app.cache.redis_cache import RedisCache
from app.cache.cache_manager import CacheManager

@pytest.fixture
async def local_cache():
    """Create a local cache instance for testing."""
    cache = LocalCache(max_size=5, default_ttl=2)
    yield cache
    await cache.clear()

@pytest.fixture
async def redis_cache():
    """Create a Redis cache instance for testing."""
    cache = RedisCache("redis://localhost:6379", prefix="test:")
    await cache.connect()
    yield cache
    await cache.clear()
    await cache.disconnect()

@pytest.fixture
async def cache_manager(local_cache, redis_cache):
    """Create a cache manager for testing."""
    return CacheManager(local_cache, redis_cache, namespace="test")

class TestLocalCache:
    """Test local cache functionality."""
    
    @pytest.mark.asyncio
    async def test_basic_get_set(self, local_cache):
        """Test basic cache operations."""
        # Test set and get
        await local_cache.set("key1", "value1")
        assert await local_cache.get("key1") == "value1"
        
        # Test cache miss
        assert await local_cache.get("nonexistent") is None
    
    @pytest.mark.asyncio
    async def test_ttl_expiration(self, local_cache):
        """Test TTL expiration."""
        # Set with 1 second TTL
        await local_cache.set("expire_key", "value", ttl=1)
        
        # Should exist immediately
        assert await local_cache.get("expire_key") == "value"
        
        # Wait for expiration
        await asyncio.sleep(1.1)
        
        # Should be expired
        assert await local_cache.get("expire_key") is None
    
    @pytest.mark.asyncio
    async def test_lru_eviction(self, local_cache):
        """Test LRU eviction when cache is full."""
        # Fill cache to capacity
        for i in range(5):
            await local_cache.set(f"key{i}", f"value{i}")
        
        # Access some keys to update LRU order
        await local_cache.get("key1")  # Move key1 to end
        await local_cache.get("key3")  # Move key3 to end
        
        # Add new item, should evict key0 (least recently used)
        await local_cache.set("key5", "value5")
        
        # key0 should be evicted
        assert await local_cache.get("key0") is None
        # Others should still exist
        assert await local_cache.get("key1") == "value1"
        assert await local_cache.get("key5") == "value5"
    
    @pytest.mark.asyncio
    async def test_cache_stats(self, local_cache):
        """Test cache statistics tracking."""
        # Generate some cache activity
        await local_cache.set("key1", "value1")
        await local_cache.get("key1")  # Hit
        await local_cache.get("key2")  # Miss
        await local_cache.delete("key1")
        
        stats = local_cache.get_stats()
        assert stats["hits"] == 1
        assert stats["misses"] == 1
        assert stats["sets"] == 1
        assert stats["deletes"] == 1
        assert stats["hit_rate"] == 0.5

class TestCacheManager:
    """Test cache manager with two-level caching."""
    
    @pytest.mark.asyncio
    async def test_two_level_caching(self, cache_manager):
        """Test L1 and L2 cache coordination."""
        # Set value
        await cache_manager.set("test_key", {{"data": "test_value"}})
        
        # First get should hit L1
        value = await cache_manager.get("test_key")
        assert value == {{"data": "test_value"}}
        
        # Clear L1 to force L2 lookup
        await cache_manager.local_cache.clear()
        
        # Should still get from L2 and repopulate L1
        value = await cache_manager.get("test_key")
        assert value == {{"data": "test_value"}}
        
        # Verify L1 was repopulated
        l1_value = await cache_manager.local_cache.get("test:test_key")
        assert l1_value == {{"data": "test_value"}}
    
    @pytest.mark.asyncio
    async def test_cache_aside_pattern(self, cache_manager):
        """Test cache-aside pattern with fetch function."""
        fetch_count = 0
        
        async def fetch_data():
            nonlocal fetch_count
            fetch_count += 1
            return {{"fetched": "data", "count": fetch_count}}
        
        # First call should fetch and cache
        result1 = await cache_manager.get("fetch_key", fetch_data)
        assert result1["count"] == 1
        assert fetch_count == 1
        
        # Second call should use cache
        result2 = await cache_manager.get("fetch_key", fetch_data)
        assert result2["count"] == 1  # Same data
        assert fetch_count == 1  # Fetch not called again
    
    @pytest.mark.asyncio
    async def test_concurrent_access(self, cache_manager):
        """Test cache under concurrent access."""
        async def access_cache(key: str, value: str):
            await cache_manager.set(key, value)
            result = await cache_manager.get(key)
            return result
        
        # Run concurrent operations
        tasks = [
            access_cache(f"concurrent_{i}", f"value_{i}")
            for i in range(20)
        ]
        
        results = await asyncio.gather(*tasks)
        
        # Verify all operations succeeded
        assert len(results) == 20
        for i, result in enumerate(results):
            assert result == f"value_{i}"
```

### Step 14: Create Performance Tests

Create `tests/test_performance.py`:

**🤖 Copilot Prompt Suggestion #8:**
```python
# Create performance benchmarks that demonstrate:
# - Response time improvement with caching
# - Throughput increase under load
# - Cache hit rate under various scenarios
# - Memory usage efficiency
# Use pytest-benchmark for measurements
```

### Step 15: Load Testing Script

Create `tests/load_test.py`:

```python
from locust import HttpUser, task, between
import random

class ProductAPIUser(HttpUser):
    wait_time = between(0.1, 0.5)
    
    def on_start(self):
        """Initialize user session."""
        self.product_ids = list(range(1, 101))
        self.categories = ["electronics", "books", "clothing", "food"]
    
    @task(3)
    def get_product(self):
        """Simulate getting a specific product."""
        product_id = random.choice(self.product_ids)
        self.client.get(f"/products/{product_id}")
    
    @task(2)
    def list_products(self):
        """Simulate listing products."""
        category = random.choice(self.categories)
        self.client.get(f"/products?category={category}&limit=20")
    
    @task(1)
    def get_cache_stats(self):
        """Check cache statistics."""
        self.client.get("/cache/stats")
```

Run load test:
```bash
locust -f tests/load_test.py --host http://localhost:8000
```

## 📊 Validation and Metrics

### Step 16: Run the Application

1. Start the services:
```bash
docker-compose up -d
```

2. Run the FastAPI application:
```bash
uvicorn app.main:app --reload --port 8000
```

3. Seed the database with test data:
```python
# Create seed_data.py
import asyncio
from app.database import init_db, get_db, ProductDB
from sqlalchemy.ext.asyncio import AsyncSession
from faker import Faker
import random

fake = Faker()

async def seed_products(session: AsyncSession, count: int = 100):
    """Seed database with test products."""
    categories = ["electronics", "books", "clothing", "food", "toys"]
    
    for i in range(count):
        product = ProductDB(
            name=fake.word().capitalize() + " " + fake.word().capitalize(),
            description=fake.text(max_nb_chars=200),
            price=round(random.uniform(10, 1000), 2),
            category=random.choice(categories),
            in_stock=random.choice([True, True, True, False])  # 75% in stock
        )
        session.add(product)
    
    await session.commit()
    print(f"Seeded {count} products")

async def main():
    await init_db()
    async for session in get_db():
        await seed_products(session)
        break

if __name__ == "__main__":
    asyncio.run(main())
```

### Step 17: Verify Cache Performance

**Without Cache:**
```bash
# Disable cache temporarily and test
curl -w "@curl-format.txt" http://localhost:8000/products/1
```

**With Cache:**
```bash
# Multiple requests to same endpoint
for i in {\`1..10\`}; do
    curl -w "Time: %{time_total}s\n" http://localhost:8000/products/1
done
```

### Step 18: Monitor Metrics

1. Check cache statistics:
```bash
curl http://localhost:8000/cache/stats | jq
```

2. View Prometheus metrics:
```bash
curl http://localhost:8000/metrics | grep cache
```

3. Access Grafana dashboard:
   - Open http://localhost:3000
   - Login with admin/admin
   - Import the cache performance dashboard

## ✅ Exercise Completion Checklist

Ensure you have successfully:

- [ ] Implemented a two-level caching system
- [ ] Achieved Greater than 80% cache hit rate under load
- [ ] Reduced average response time by Greater than 50%
- [ ] Passed all unit tests
- [ ] Handled cache invalidation correctly
- [ ] Monitored cache performance metrics
- [ ] Documented any issues in troubleshooting

## 🎯 Success Criteria

Your implementation is successful when:

1. **Performance**: Response time &lt; 50ms for cached requests
2. **Reliability**: No cache-related errors under load
3. **Efficiency**: Memory usage remains stable
4. **Correctness**: Data consistency maintained
5. **Observability**: All metrics properly tracked

## 🚀 Extension Challenges

If you finish early, try these additional challenges:

1. **Cache Warming Strategy**: Implement intelligent cache pre-warming based on access patterns
2. **Advanced Invalidation**: Add tag-based cache invalidation
3. **Compression**: Add compression for large cached objects
4. **Circuit Breaker**: Implement circuit breaker for Redis failures

## 📚 Key Takeaways

- Multi-level caching significantly improves performance
- Cache invalidation is crucial for data consistency
- Monitoring helps identify optimization opportunities
- GitHub Copilot accelerates cache implementation
- TTL and eviction policies prevent memory issues

## Next Steps

Congratulations on completing Exercise 1! You've built a production-ready caching system. Proceed to Exercise 2 where you'll implement load balancing at scale.

[Continue to Exercise 2 →](../exercise2-application/instructions.md)