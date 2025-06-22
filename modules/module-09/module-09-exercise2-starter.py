"""
Query Performance Optimization - Starter Code
Module 09, Exercise 2

This file contains the starter code for optimizing database queries.
You'll analyze slow queries, add indexes, implement caching, and improve performance.

Current Performance Issues:
- Homepage query: 3.2 seconds
- Product search: 4.5 seconds
- Order history: 6.1 seconds
- Database CPU: 85%

Goal: Achieve <200ms response times and handle 10x more load
"""

import time
import asyncio
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from decimal import Decimal
import json

from sqlalchemy import create_engine, text, Index, func
from sqlalchemy.orm import sessionmaker, joinedload, selectinload
from sqlalchemy.sql import exists
import redis
import asyncpg
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel
import logging

# Import models from Exercise 1
from models import (
    Base, User, Product, ProductVariant, Category, 
    Order, OrderItem, Review, Inventory
)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database configuration
DATABASE_URL = "postgresql://workshop_user:workshop_pass@localhost/ecommerce_db"
REDIS_URL = "redis://localhost:6379/0"

# Initialize connections
engine = create_engine(DATABASE_URL, pool_size=20, max_overflow=40)
Session = sessionmaker(bind=engine)
redis_client = redis.from_url(REDIS_URL, decode_responses=True)

# FastAPI app
app = FastAPI(title="E-Commerce Performance API")

# ========================================
# CURRENT SLOW QUERIES (TO BE OPTIMIZED)
# ========================================

class SlowQueries:
    """Current implementation with performance issues"""
    
    @staticmethod
    def get_homepage_products(session):
        """
        SLOW: Homepage featured products query
        Current time: 3.2 seconds
        """
        start_time = time.time()
        
        # TODO: This query needs optimization
        # Problems: Multiple aggregations, no proper indexes, N+1 for inventory
        query = text("""
            SELECT p.*, 
                   COUNT(r.id) as review_count,
                   AVG(r.rating) as avg_rating,
                   i.quantity_available
            FROM products p
            LEFT JOIN reviews r ON r.product_id = p.id
            LEFT JOIN inventory i ON i.product_variant_id IN (
                SELECT id FROM product_variants WHERE product_id = p.id
            )
            WHERE p.is_featured = true
            GROUP BY p.id, i.quantity_available
            ORDER BY p.created_at DESC
            LIMIT 12
        """)
        
        results = session.execute(query).fetchall()
        
        elapsed = time.time() - start_time
        logger.info(f"Homepage query took {elapsed:.2f} seconds")
        
        return results
    
    @staticmethod
    def search_products(session, search_term: str, min_price: float = 0, max_price: float = 10000):
        """
        SLOW: Product search with filters
        Current time: 4.5 seconds
        """
        start_time = time.time()
        
        # TODO: Optimize this search query
        # Problems: ILIKE on multiple columns, no FTS, inefficient joins
        query = text("""
            SELECT DISTINCT p.*, c.name as category_name
            FROM products p
            JOIN categories c ON p.category_id = c.id
            JOIN product_variants pv ON pv.product_id = p.id
            WHERE 
                (p.name ILIKE :search OR p.description ILIKE :search)
                AND p.is_active = true
                AND pv.stock_quantity > 0
                AND p.base_price BETWEEN :min_price AND :max_price
            ORDER BY p.base_price ASC
        """)
        
        results = session.execute(
            query,
            {
                "search": f"%{search_term}%",
                "min_price": min_price,
                "max_price": max_price
            }
        ).fetchall()
        
        elapsed = time.time() - start_time
        logger.info(f"Search query took {elapsed:.2f} seconds")
        
        return results
    
    @staticmethod
    def get_user_order_history(session, user_id: int):
        """
        SLOW: User order history with details
        Current time: 6.1 seconds for users with many orders
        """
        start_time = time.time()
        
        # TODO: Fix this N+1 query nightmare
        # Problems: Fetches everything at once, no pagination, multiple joins
        query = text("""
            SELECT o.*, 
                   u.email, u.first_name, u.last_name,
                   oi.*, 
                   p.name as product_name,
                   pv.size, pv.color
            FROM orders o
            JOIN users u ON o.user_id = u.id
            JOIN order_items oi ON oi.order_id = o.id
            JOIN product_variants pv ON oi.product_variant_id = pv.id
            JOIN products p ON pv.product_id = p.id
            WHERE o.user_id = :user_id
            ORDER BY o.created_at DESC
        """)
        
        results = session.execute(query, {"user_id": user_id}).fetchall()
        
        elapsed = time.time() - start_time
        logger.info(f"Order history query took {elapsed:.2f} seconds")
        
        return results

# ========================================
# QUERY ANALYZER (TO BE IMPLEMENTED)
# ========================================

class QueryAnalyzer:
    """Analyze query performance and suggest optimizations"""
    
    def __init__(self, session):
        self.session = session
    
    def explain_query(self, query: str, params: dict = None):
        """
        TODO: Implement EXPLAIN ANALYZE for queries
        Should return execution plan and identify issues
        """
        # Copilot Prompt: Create a method that runs EXPLAIN ANALYZE on a query
        # and parses the output to identify performance issues like:
        # - Sequential scans on large tables
        # - Missing indexes
        # - High cost operations
        # - Poor join strategies
        pass
    
    def suggest_indexes(self, query: str):
        """
        TODO: Analyze query and suggest missing indexes
        Should return CREATE INDEX statements
        """
        # Copilot Prompt: Parse the query to find WHERE, JOIN, and ORDER BY columns
        # then suggest appropriate indexes including:
        # - Single column indexes for high selectivity
        # - Composite indexes for common patterns  
        # - Partial indexes for filtered queries
        # - Include columns for covering indexes
        pass
    
    def find_missing_indexes(self):
        """
        TODO: Query pg_stat_user_tables to find missing indexes
        """
        # Copilot Prompt: Query PostgreSQL statistics to find tables with
        # high sequential scan counts that would benefit from indexes
        pass

# ========================================
# CACHE MANAGER (TO BE IMPLEMENTED)
# ========================================

class CacheManager:
    """Redis caching implementation"""
    
    def __init__(self, redis_client):
        self.redis = redis_client
        self.default_ttl = 300  # 5 minutes
    
    def generate_cache_key(self, prefix: str, **kwargs) -> str:
        """
        TODO: Generate consistent cache keys
        Example: "products:featured:page:1:limit:12"
        """
        # Copilot Prompt: Create a cache key generator that:
        # - Uses consistent naming patterns
        # - Includes all relevant parameters
        # - Handles versioning
        # - Sorts parameters for consistency
        pass
    
    async def get_or_set(self, key: str, fetch_func, ttl: int = None):
        """
        TODO: Implement cache-aside pattern
        1. Check cache
        2. If miss, fetch from database
        3. Store in cache with TTL
        4. Return result
        """
        # Copilot Prompt: Implement async cache-aside pattern with:
        # - Proper error handling
        # - JSON serialization for complex objects
        # - Configurable TTL
        # - Logging for cache hits/misses
        pass
    
    def invalidate_pattern(self, pattern: str):
        """
        TODO: Invalidate all keys matching a pattern
        Example: invalidate_pattern("user:123:*")
        """
        # Copilot Prompt: Use Redis SCAN to find and delete keys matching pattern
        # Handle large keyspaces efficiently without blocking
        pass

# ========================================
# OPTIMIZED QUERIES (TO BE IMPLEMENTED)
# ========================================

class OptimizedQueries:
    """Optimized versions of the slow queries"""
    
    def __init__(self, session, cache_manager):
        self.session = session
        self.cache = cache_manager
    
    async def get_homepage_products(self):
        """
        TODO: Optimize homepage query to <100ms
        Strategies:
        1. Add proper indexes
        2. Use materialized view for aggregations
        3. Implement caching
        4. Reduce data fetched
        """
        # Copilot Prompt: Rewrite the homepage query to:
        # - Use a CTE for better optimization
        # - Fetch review stats from a materialized view
        # - Only get necessary columns
        # - Use covering indexes
        # - Cache the results
        pass
    
    async def search_products(self, search_term: str, filters: dict):
        """
        TODO: Optimize search to <200ms
        Strategies:
        1. Implement PostgreSQL full-text search
        2. Use GIN indexes
        3. Add search results caching
        4. Implement pagination
        """
        # Copilot Prompt: Create an optimized search that:
        # - Uses PostgreSQL tsvector for full-text search
        # - Implements faceted search with filters
        # - Uses proper indexes for range queries
        # - Caches common search terms
        # - Returns paginated results
        pass
    
    async def get_user_order_history(self, user_id: int, page: int = 1, limit: int = 20):
        """
        TODO: Optimize order history to <200ms
        Strategies:
        1. Implement proper pagination
        2. Use eager loading to prevent N+1
        3. Cache recent orders
        4. Create covering indexes
        """
        # Copilot Prompt: Optimize the order history query by:
        # - Using window functions for efficient pagination  
        # - Joining only necessary data
        # - Creating a summary view for order counts
        # - Caching user's recent orders
        # - Using batch loading for related data
        pass

# ========================================
# INDEX CREATION (TO BE IMPLEMENTED)
# ========================================

def create_performance_indexes():
    """
    TODO: Create all indexes needed for optimization
    """
    # Copilot Prompt: Generate CREATE INDEX statements for:
    # 1. Homepage query optimization
    # 2. Search query optimization  
    # 3. Order history optimization
    # 4. Common join patterns
    # 5. Foreign key indexes
    # Include partial indexes and covering indexes where appropriate
    
    indexes = [
        # Example format:
        # "CREATE INDEX idx_products_featured ON products(is_featured, created_at DESC) WHERE is_featured = true",
    ]
    
    return indexes

# ========================================
# CONNECTION POOL MANAGER (TO BE IMPLEMENTED)
# ========================================

class ConnectionPoolManager:
    """Manage database connection pooling"""
    
    def __init__(self, database_url: str):
        self.database_url = database_url
        self.pool = None
    
    async def init_pool(self):
        """
        TODO: Initialize asyncpg connection pool
        """
        # Copilot Prompt: Create an asyncpg connection pool with:
        # - Min size: 10 connections
        # - Max size: 50 connections  
        # - Connection timeout: 10 seconds
        # - Command timeout: 30 seconds
        # - Statement cache size: 1000
        pass
    
    async def execute_query(self, query: str, *args):
        """
        TODO: Execute query using connection from pool
        """
        # Copilot Prompt: Get connection from pool, execute query,
        # handle errors, return connection to pool
        pass

# ========================================
# MONITORING (TO BE IMPLEMENTED)
# ========================================

class PerformanceMonitor:
    """Monitor query and application performance"""
    
    def __init__(self):
        self.metrics = {}
    
    def track_query_time(self, query_name: str, duration: float):
        """
        TODO: Track query execution times
        """
        # Copilot Prompt: Track query performance metrics including:
        # - Count of executions
        # - Total time
        # - Average time
        # - Min/max time
        # - P50, P95, P99 percentiles
        pass
    
    def export_prometheus_metrics(self):
        """
        TODO: Export metrics in Prometheus format
        """
        # Copilot Prompt: Format metrics for Prometheus including:
        # - Query execution times (histogram)
        # - Cache hit rates (gauge)
        # - Connection pool usage (gauge)
        # - Error rates (counter)
        pass

# ========================================
# API ENDPOINTS
# ========================================

@app.get("/products/featured")
async def get_featured_products():
    """Homepage featured products endpoint"""
    # TODO: Use optimized query with caching
    session = Session()
    try:
        # Currently using slow query
        products = SlowQueries.get_homepage_products(session)
        return {"products": products}
    finally:
        session.close()

@app.get("/products/search")
async def search_products(
    q: str = Query(..., description="Search term"),
    min_price: float = Query(0, description="Minimum price"),
    max_price: float = Query(10000, description="Maximum price")
):
    """Product search endpoint"""
    # TODO: Use optimized search with caching
    session = Session()
    try:
        # Currently using slow query
        products = SlowQueries.search_products(session, q, min_price, max_price)
        return {"products": products, "count": len(products)}
    finally:
        session.close()

@app.get("/users/{user_id}/orders")
async def get_user_orders(user_id: int, page: int = 1, limit: int = 20):
    """User order history endpoint"""
    # TODO: Use optimized query with pagination and caching
    session = Session()
    try:
        # Currently using slow query
        orders = SlowQueries.get_user_order_history(session, user_id)
        return {"orders": orders, "total": len(orders)}
    finally:
        session.close()

@app.get("/performance/metrics")
async def get_performance_metrics():
    """Performance monitoring endpoint"""
    # TODO: Return actual performance metrics
    return {
        "status": "Not implemented",
        "message": "Implement performance monitoring"
    }

# ========================================
# MAIN EXECUTION
# ========================================

if __name__ == "__main__":
    import uvicorn
    
    print("Starting performance optimization exercise...")
    print("\nCurrent performance issues:")
    print("- Homepage: 3.2s")
    print("- Search: 4.5s") 
    print("- Order History: 6.1s")
    print("\nYour goal: <200ms for all queries!")
    
    # TODO: Initialize connection pool
    # TODO: Create missing indexes
    # TODO: Warm up cache
    
    uvicorn.run(app, host="0.0.0.0", port=8000)