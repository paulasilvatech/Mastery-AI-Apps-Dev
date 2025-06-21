# Exercise 1: Caching Fundamentals (⭐ Foundation)

## 🎯 Exercise Overview

**Duration**: 30-45 minutes  
**Difficulty**: ⭐ (Easy)  
**Success Rate**: 95%

In this foundation exercise, you'll implement a multi-level caching system for a product catalog API using GitHub Copilot's assistance. You'll learn caching fundamentals including local memory caching, distributed Redis caching, and cache invalidation strategies.

## 🎓 Learning Objectives

By completing this exercise, you will:
- Implement in-memory caching with TTL (Time To Live)
- Set up Redis for distributed caching
- Create cache invalidation strategies
- Monitor cache performance metrics
- Use GitHub Copilot to generate optimized caching code

## 📋 Prerequisites

- ✅ Module 15 environment set up
- ✅ Redis running locally or in Azure
- ✅ Python virtual environment activated
- ✅ GitHub Copilot enabled in VS Code

## 🏗️ What You'll Build

A product catalog API with a sophisticated caching system:

```mermaid
graph TB
    Client[API Client] --> API[FastAPI Server]
    API --> LocalCache{Local Cache}
    LocalCache -->|Hit| Response1[Return Cached Data]
    LocalCache -->|Miss| RedisCache{Redis Cache}
    RedisCache -->|Hit| Response2[Return & Update Local]
    RedisCache -->|Miss| DB[(PostgreSQL)]
    DB --> UpdateCaches[Update Both Caches]
    UpdateCaches --> Response3[Return Fresh Data]
    
    style LocalCache fill:#f9f,stroke:#333,stroke-width:2px
    style RedisCache fill:#f96,stroke:#333,stroke-width:2px
    style DB fill:#69f,stroke:#333,stroke-width:2px
```

## 🚀 Part 1: Setting Up the Foundation

### Step 1: Project Structure

Create the following directory structure:

```
exercise1-foundation/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── models.py
│   ├── cache/
│   │   ├── __init__.py
│   │   ├── local_cache.py
│   │   ├── redis_cache.py
│   │   └── cache_manager.py
│   └── database.py
├── tests/
│   ├── test_cache.py
│   └── test_performance.py
├── requirements.txt
├── .env
└── docker-compose.yml
```

### Step 2: Install Dependencies

Create `requirements.txt`:

```txt
fastapi==0.104.1
uvicorn[standard]==0.24.0
redis==5.0.1
aioredis==2.0.1
sqlalchemy[asyncio]==2.0.23
asyncpg==0.29.0
pydantic==2.5.0
prometheus-client==0.19.0
python-dotenv==1.0.0
httpx==0.25.1
pytest==7.4.3
pytest-asyncio==0.21.1
pytest-benchmark==4.0.0
```

Install dependencies:
```bash
pip install -r requirements.txt
```

### Step 3: Create the Data Model

Create `app/models.py`:

```python
from pydantic import BaseModel
from datetime import datetime
from typing import Optional

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
```

### Step 4: Implement Local Cache

Create `app/cache/local_cache.py`:

**🤖 Copilot Prompt Suggestion #1:**
```python
# Create a thread-safe in-memory cache class with:
# - TTL support for automatic expiration
# - LRU eviction when size limit is reached
# - Methods: get, set, delete, clear
# - Cache statistics tracking
# - Async support
# Include comprehensive error handling and type hints
```

**Expected Output Structure:**
```python
import asyncio
from typing import Optional, Any, Dict
from datetime import datetime, timedelta
from collections import OrderedDict
import threading

class LocalCache:
    def __init__(self, max_size: int = 1000, default_ttl: int = 300):
        """
        Initialize local cache with size limit and default TTL.
        
        Args:
            max_size: Maximum number of items in cache
            default_ttl: Default time-to-live in seconds
        """
        self.max_size = max_size
        self.default_ttl = default_ttl
        self.cache: OrderedDict[str, Dict[str, Any]] = OrderedDict()
        self.lock = threading.RLock()
        self.stats = {
            "hits": 0,
            "misses": 0,
            "sets": 0,
            "deletes": 0
        }
    
    async def get(self, key: str) -> Optional[Any]:
        """Get value from cache with TTL check."""
        # Implementation will be provided by Copilot
        pass
    
    async def set(self, key: str, value: Any, ttl: Optional[int] = None) -> None:
        """Set value in cache with optional TTL."""
        # Implementation will be provided by Copilot
        pass
    
    # Additional methods...
```

### Step 5: Implement Redis Cache Layer

Create `app/cache/redis_cache.py`:

**🤖 Copilot Prompt Suggestion #2:**
```python
# Create an async Redis cache wrapper with:
# - Connection pooling for performance
# - Automatic reconnection on failure
# - JSON serialization for complex objects
# - Batch operations support
# - Pipeline for multiple operations
# - Pub/sub for cache invalidation
# Include error handling and logging
```

**Expected Output Structure:**
```python
import redis.asyncio as redis
import json
from typing import Optional, Any, List, Dict
import logging
from datetime import timedelta

logger = logging.getLogger(__name__)

class RedisCache:
    def __init__(self, redis_url: str, prefix: str = "cache:"):
        """
        Initialize Redis cache with connection pooling.
        
        Args:
            redis_url: Redis connection URL
            prefix: Key prefix for namespacing
        """
        self.redis_url = redis_url
        self.prefix = prefix
        self.pool = None
        self.redis_client = None
    
    async def connect(self):
        """Establish connection to Redis with retry logic."""
        # Implementation will be provided by Copilot
        pass
    
    async def get(self, key: str) -> Optional[Any]:
        """Get value from Redis with automatic deserialization."""
        # Implementation will be provided by Copilot
        pass
    
    # Additional methods...
```

### Step 6: Create Cache Manager

Create `app/cache/cache_manager.py`:

**🤖 Copilot Prompt Suggestion #3:**
```python
# Create a cache manager that coordinates local and Redis caches:
# - Two-level caching (L1: local, L2: Redis)
# - Cache-aside pattern implementation
# - Write-through and write-behind strategies
# - Cache warming capabilities
# - Invalidation across all cache levels
# - Performance metrics collection
# Make it generic to work with any data type
```

### Step 7: Database Setup

Create `app/database.py`:

```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime
import os
from datetime import datetime

# Database URL from environment
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+asyncpg://workshop:workshop123@localhost/performance_db")

# Create async engine
engine = create_async_engine(DATABASE_URL, echo=False)

# Create async session factory
AsyncSessionLocal = sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)

# Base class for models
Base = declarative_base()

# Product model
class ProductDB(Base):
    __tablename__ = "products"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(String)
    price = Column(Float)
    category = Column(String, index=True)
    in_stock = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, onupdate=datetime.utcnow)

# Create tables
async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

# Dependency to get DB session
async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
```

## 📊 Performance Monitoring Setup

Create `app/monitoring.py`:

```python
from prometheus_client import Counter, Histogram, Gauge
import time
from functools import wraps
from typing import Callable

# Metrics
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
```

## ✅ Checkpoint

Before proceeding to Part 2, ensure you have:
- [ ] Created all file structure
- [ ] Installed all dependencies
- [ ] Implemented basic models
- [ ] Set up database configuration
- [ ] Created monitoring metrics

Continue to [Part 2: Implementation](./part2.md) →