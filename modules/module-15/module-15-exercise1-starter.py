# Exercise 1: Caching Fundamentals - Starter Code
# TODO: Complete this implementation using GitHub Copilot

from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# TODO: Import your cache modules
# from .cache.local_cache import LocalCache
# from .cache.redis_cache import RedisCache
# from .cache.cache_manager import CacheManager

app = FastAPI(
    title="Product Catalog API",
    description="High-performance API with multi-level caching",
    version="1.0.0"
)

# Data Models
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

# TODO: Initialize cache instances
# Copilot Prompt: Create cache instances for local and Redis caching

# TODO: Implement startup and shutdown events
# Copilot Prompt: Add lifespan context manager for cache initialization

@app.get("/products/{product_id}", response_model=Product)
async def get_product(product_id: int):
    """
    Get product by ID with caching.
    
    TODO: Implement caching logic
    Copilot Prompt: Add cache lookup with fallback to database
    """
    # Placeholder implementation
    raise HTTPException(status_code=501, detail="Not implemented")

@app.get("/products", response_model=List[Product])
async def list_products(
    category: Optional[str] = None,
    limit: int = 100,
    offset: int = 0
):
    """
    List products with optional filtering.
    
    TODO: Implement with caching
    Copilot Prompt: Cache product lists by category with pagination
    """
    # Placeholder implementation
    return []

@app.post("/products/{product_id}/invalidate")
async def invalidate_product_cache(product_id: int):
    """
    Invalidate cache for a specific product.
    
    TODO: Implement cache invalidation
    Copilot Prompt: Clear product from all cache levels
    """
    return {"message": "Not implemented"}

@app.get("/cache/stats", response_model=CacheStats)
async def get_cache_stats():
    """
    Get cache performance statistics.
    
    TODO: Implement stats collection
    Copilot Prompt: Aggregate stats from both cache levels
    """
    # Placeholder stats
    return CacheStats(
        total_requests=0,
        cache_hits=0,
        cache_misses=0,
        hit_rate=0.0,
        avg_response_time_ms=0.0
    )

@app.get("/health")
async def health_check():
    """
    Health check endpoint.
    
    TODO: Add cache health status
    Copilot Prompt: Check connectivity to Redis and local cache status
    """
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow(),
        "cache_status": "unknown"
    }

# TODO: Add metrics endpoint for Prometheus
# Copilot Prompt: Create /metrics endpoint that returns Prometheus formatted metrics

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)