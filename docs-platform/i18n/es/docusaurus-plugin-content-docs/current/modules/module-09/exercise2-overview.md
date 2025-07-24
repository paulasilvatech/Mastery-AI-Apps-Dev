---
sidebar_position: 2
title: "Exercise 2: Overview"
description: "## 🎯 Objective"
---

# Ejercicio 2: Query Performance Optimization (⭐⭐ Medio)

## 🎯 Objective

Optimize a poorly performing e-commerce application by analyzing slow queries, implementing proper indexes, adding caching strategies, and using GitHub Copilot to generate efficient database queries.

**Duración**: 45-60 minutos  
**Difficulty**: ⭐⭐ Medio  
**Success Rate**: 80%

## 📚 Concepts Covered

- Query execution plan analysis
- Index optimization strategies
- Query rewriting techniques
- Redis caching patterns
- Connection pooling
- N+1 query prevention
- Database monitoring

## 🏗️ What You'll Build

A performance optimization solution that includes:
- Query performance analyzer
- Automatic index recommendations
- Redis caching layer
- Query optimization utilities
- Performance monitoring dashboard
- Load testing framework

## 📋 Scenario

You've inherited an e-commerce application that's experiencing severe performance issues:
- Iniciopage takes 5+ seconds to load
- Product search timeouts under load
- Order history pages crash for power users
- Database CPU constantly at 80%+
- Customer complaints about slow checkout

Your mission: Reduce response times by 90% and handle 10x more concurrent users.

## 🔨 Step-by-Step Instructions

### Step 1: Setup Performance Testing ambiente (10 minutos)

1. Create project structure:
```bash
mkdir query-optimization
cd query-optimization
mkdir -p {analyzers,optimizers,cache,monitoring,tests}
```

2. Install dependencies:
```bash
pip install sqlalchemy psycopg2-binary redis py-redis asyncpg
pip install fastapi uvicorn prometheus-client
pip install pytest pytest-benchmark locust
```

3. Setup monitoring tools:

**Copilot Prompt Suggestion:**
```python
# Create a query performance analyzer that:
# - Captures slow queries (>100ms)
# - Logs query execution plans
# - Tracks query frequency
# - Identifies missing indexes
# - Generates performance reports
# Use PostgreSQL's pg_stat_statements
```

### Step 2: Identify Performance Bottlenecks (10 minutos)

**Current Slow Queries to Analyze:**

1. **Iniciopage Query** (currently 3.2s):
```sql
-- Fetch featured products with reviews and inventory
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
LIMIT 12;
```

2. **Product Buscar** (currently 4.5s):
```sql
-- Full-text search with filters
SELECT DISTINCT p.*, c.name as category_name
FROM products p
JOIN categories c ON p.category_id = c.id
JOIN product_variants pv ON pv.product_id = p.id
WHERE 
    (p.name ILIKE '%laptop%' OR p.description ILIKE '%laptop%')
    AND p.is_active = true
    AND pv.stock_quantity &gt; 0
    AND p.base_price BETWEEN 500 AND 2000
ORDER BY p.base_price ASC;
```

3. **User Order Historial** (currently 6.1s for power users):
```sql
-- Orders with all details
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
ORDER BY o.created_at DESC;
```

**Copilot Prompt Suggestion:**
```python
# Analyze these queries and:
# 1. Generate EXPLAIN ANALYZE output
# 2. Identify missing indexes
# 3. Suggest query rewrites
# 4. Calculate potential performance gains
# Create a QueryAnalyzer class with these methods
```

### Step 3: Implement Index Optimization (10 minutos)

**Copilot Prompt Suggestion:**
```python
# Create index recommendations based on:
# - WHERE clause columns
# - JOIN conditions  
# - ORDER BY columns
# - Composite indexes for covering queries
# Generate CREATE INDEX statements with:
# - Partial indexes where appropriate
# - Include columns for covering indexes
# - Proper naming conventions
```

Expected indexes to create:
1. Composite indexes for common query patterns
2. Parteeial indexes for filtered queries
3. GIN indexes for full-text search
4. Covering indexes to avoid table lookups

### Step 4: Implement Query Optimization (10 minutos)

**Copilot Prompt Suggestion:**
```python
# Rewrite the slow queries to:
# 1. Use CTEs for better readability
# 2. Eliminate subqueries where possible
# 3. Use window functions for aggregations
# 4. Implement pagination properly
# 5. Add query hints where beneficial
# Create optimized versions of all three queries
```

Key optimizations:
- Replace correlated subqueries with JOINs
- Use materialized views for complex aggregations
- Implement proper pagination with cursors
- Batch N+1 queries

### Step 5: Add Redis Caching Layer (10 minutos)

**Copilot Prompt Suggestion:**
```python
# Implement a caching strategy with:
# - Cache key generation based on query parameters
# - TTL management (5 min for featured, 1 hour for search)
# - Cache invalidation on updates
# - Fallback to database on cache miss
# - Cache warming for popular queries
# Use Redis with proper serialization
```

Caching patterns to implement:
1. **Cache-aside**: Read from cache, fallback to DB
2. **Write-through**: Actualizar cache on writes
3. **Cache invalidation**: Clear related caches
4. **Batch loading**: Reduce round trips

### Step 6: Implement Connection Pooling (5 minutos)

**Copilot Prompt Suggestion:**
```python
# Create a connection pool manager that:
# - Maintains a pool of database connections
# - Implements health checks
# - Handles connection recycling
# - Provides metrics on pool usage
# - Supports async operations
# Use SQLAlchemy's QueuePool with proper settings
```

### Step 7: Add Performance Monitoring (10 minutos)

**Copilot Prompt Suggestion:**
```python
# Create a monitoring system that tracks:
# - Query execution times (p50, p95, p99)
# - Cache hit rates
# - Connection pool metrics
# - Database load (CPU, memory, I/O)
# - Application response times
# Export metrics to Prometheus format
```

## 🧪 Performance Tests

Create `tests/test_performance.py`:

**Copilot Prompt Suggestion:**
```python
# Create performance tests that:
# - Measure query times before/after optimization
# - Simulate concurrent users (100, 1000, 5000)
# - Test cache effectiveness
# - Validate response times &lt; 100ms
# - Check database connection limits
# Use pytest-benchmark and locust
```

Run performance tests:
```bash
# Unit performance tests
pytest tests/test_performance.py -v --benchmark-only

# Load testing
locust -f tests/load_test.py --host=http://localhost:8000
```

## 📊 Expected Results

### Before Optimization
```
Homepage Load: 3,200ms
Product Search: 4,500ms  
Order History: 6,100ms
Concurrent Users: 50 max
Database CPU: 85%
```

### After Optimization
```
Homepage Load: 45ms (98.6% improvement)
Product Search: 120ms (97.3% improvement)
Order History: 200ms (96.7% improvement)
Concurrent Users: 500+ 
Database CPU: 15%
Cache Hit Rate: 92%
```

## ✅ Success Criteria

Your optimization is complete when:

1. **Query Performance** ✓
   - All queries execute in &lt; 200ms
   - P95 response time &lt; 300ms
   - No timeouts under load

2. **Scalability** ✓
   - Handle 500+ concurrent users
   - Database CPU &lt; 40% under load
   - Connection pool never exhausted

3. **Caching** ✓
   - Cache hit rate &gt; 85%
   - Proper cache invalidation
   - No stale data issues

4. **Monitoring** ✓
   - All metrics exported
   - Alerts configurado
   - Panel functional

5. **Code Quality** ✓
   - Queries are maintainable
   - Proper error handling
   - Comprehensive tests

## 🚀 Extension Challenges

1. **Read Replicas**: Implement read/write splitting
2. **Query Cache**: Add application-level query caching
3. **Auto-scaling**: Scale based on load metrics
4. **GraphQL**: Optimize for GraphQL query patterns
5. **Real-time Actualizars**: Add WebSocket for live data

## 💡 Optimization Tips

### Query Optimization
- Use `EXPLAIN ANALYZE` to understand query plans
- Avoid `SELECT *` - only fetch needed columns
- Use `EXISTS` instead of `COUNT` for existence checks
- Batch operations to reduce round trips

### Index Mejores Prácticas
- Index foreign keys for JOINs
- Use partial indexes for filtered queries
- Consider index-only scans with INCLUDE
- Monitor index usage and bloat

### Caching Strategies
- Cache computed results, not raw data
- Use appropriate TTLs for data volatility  
- Implement cache warming for critical queries
- Monitor cache memory usage

### Connection Management
- Pool size = (CPU cores * 2) + disk spindles
- Set connection timeout appropriately
- Implement connection retry logic
- Monitor for connection leaks

## 📚 Recursos

- [PostgreSQL Performance Tuning](https://www.postgresql.org/docs/current/performance-tips.html)
- [Redis Mejores Prácticas](https://redis.io/docs/manual/patterns/)
- [Query Optimization Guía](https://use-the-index-luke.com/)
- [Database Monitoring](https://www.datadoghq.com/blog/postgresql-monitoring/)

## 🎯 Próximos Pasos

After completing this exercise:
1. Document your optimization strategies
2. Create a performance runbook
3. Set up automated performance regression tests
4. Move on to Ejercicio 3: Real-time Análisis System

Remember: Performance optimization is iterative. Measure, optimize, and measure again!