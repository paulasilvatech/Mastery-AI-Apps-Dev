# Module 09: Database Design and Optimization - Quick Reference

## 🎯 Module Overview
**Duration**: 3 hours  
**Track**: 🔵 Intermediate  
**Prerequisites**: Modules 1-8 completed

## 🗺️ Learning Path

### Part 1: Database Design Fundamentals (45 min)
- ✅ Entity-Relationship modeling with AI assistance
- ✅ Normalization strategies (1NF, 2NF, 3NF, BCNF)
- ✅ Schema design patterns and anti-patterns
- ✅ Using GitHub Copilot for schema generation

### Part 2: Query Optimization (45 min)
- ✅ Writing efficient queries with Copilot
- ✅ Understanding EXPLAIN ANALYZE
- ✅ Index strategies and optimization
- ✅ Caching patterns with Redis

### Part 3: Advanced Topics (45 min)
- ✅ Vector databases and similarity search
- ✅ Database migrations with Alembic
- ✅ Connection pooling and scaling
- ✅ Monitoring and performance tuning

### Part 4: Hands-on Exercises (45 min)
- ✅ Exercise 1: E-Commerce Schema (⭐ Easy)
- ✅ Exercise 2: Query Optimization (⭐⭐ Medium)
- ✅ Exercise 3: Real-time Analytics (⭐⭐⭐ Hard)

## 🔑 Key Concepts

### Database Design Principles
1. **Normalization**: Eliminate redundancy
2. **Denormalization**: Strategic duplication for performance
3. **Indexes**: Speed up queries at write cost
4. **Constraints**: Enforce data integrity
5. **Relationships**: Model real-world connections

### Performance Optimization
1. **Query Planning**: Understand execution paths
2. **Index Selection**: B-tree, Hash, GIN, GiST
3. **Caching Strategy**: Redis for hot data
4. **Connection Pooling**: Reuse database connections
5. **Partitioning**: Split large tables

### Best Practices
1. **Use proper data types** (DECIMAL for money, not FLOAT)
2. **Index foreign keys** for JOIN performance
3. **Avoid SELECT *** in production
4. **Use EXPLAIN ANALYZE** before optimization
5. **Monitor slow query logs**

## 💻 Essential Commands

### PostgreSQL
```sql
-- Check query performance
EXPLAIN (ANALYZE, BUFFERS) SELECT ...;

-- Find missing indexes
SELECT schemaname, tablename, attname, n_distinct, correlation
FROM pg_stats
WHERE tablename = 'your_table'
AND n_distinct > 100;

-- Current connections
SELECT * FROM pg_stat_activity;

-- Table sizes
SELECT pg_size_pretty(pg_total_relation_size('table_name'));

-- Index usage
SELECT * FROM pg_stat_user_indexes
WHERE idx_scan = 0;
```

### Redis
```bash
# Monitor real-time commands
redis-cli monitor

# Check memory usage
redis-cli info memory

# Get all keys (careful in production!)
redis-cli keys "*"

# Set key with expiration
SET key value EX 3600

# Increment counter
INCR counter_name
```

### Python/SQLAlchemy
```python
# Connection pooling
engine = create_engine(
    DATABASE_URL,
    pool_size=20,
    max_overflow=40,
    pool_pre_ping=True
)

# Bulk operations
session.bulk_insert_mappings(Model, data)

# Query with index hint
query = session.query(Product).with_hint(
    Product, 'USE INDEX (idx_products_category)'
)

# Async queries
async with AsyncSession(engine) as session:
    result = await session.execute(select(User))
```

## 🚀 GitHub Copilot Prompts

### Schema Design
```python
# Create a database schema for an e-commerce platform with:
# - Users with authentication and profiles
# - Products with categories and variants
# - Orders with status tracking
# - Inventory management
# - Reviews and ratings
# Include proper relationships, constraints, and indexes
```

### Query Optimization
```python
# Optimize this slow query that fetches featured products:
# - Use proper joins instead of subqueries
# - Add appropriate indexes
# - Implement caching strategy
# - Handle N+1 query problems
# Current execution time: 3.2 seconds
# Target: <100ms
```

### Performance Analysis
```python
# Create a query analyzer that:
# - Captures slow queries (>100ms)
# - Generates EXPLAIN plans
# - Suggests missing indexes
# - Tracks query frequency
# - Produces optimization reports
```

## 📊 Performance Targets

| Operation | Target Time | Optimization Strategy |
|-----------|-------------|----------------------|
| Simple SELECT | <10ms | Proper indexes |
| Complex JOIN | <100ms | Covering indexes |
| Aggregation | <200ms | Materialized views |
| Full-text search | <50ms | GIN indexes |
| Bulk insert | <1ms/row | Batch operations |

## 🔧 Troubleshooting Quick Fixes

### Slow Queries
1. Run EXPLAIN ANALYZE
2. Check for sequential scans
3. Add missing indexes
4. Rewrite using CTEs
5. Consider denormalization

### Connection Issues
1. Check connection limits
2. Implement pooling
3. Close idle connections
4. Monitor connection leaks
5. Scale horizontally

### High Memory Usage
1. Tune work_mem
2. Reduce cache sizes
3. VACUUM regularly
4. Check for bloat
5. Partition large tables

## 📈 Monitoring Checklist

- [ ] Query execution times
- [ ] Cache hit rates
- [ ] Connection pool usage
- [ ] Index effectiveness
- [ ] Table/index bloat
- [ ] Replication lag
- [ ] Lock contention
- [ ] Disk I/O patterns

## 🎓 Skills Mastered

After completing this module, you can:
- ✅ Design normalized database schemas
- ✅ Write optimized queries that scale
- ✅ Implement effective caching strategies
- ✅ Perform migrations without downtime
- ✅ Use AI to accelerate database tasks
- ✅ Monitor and optimize performance

## 🔗 Quick Links

### Documentation
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [Redis Docs](https://redis.io/docs/)
- [SQLAlchemy Docs](https://docs.sqlalchemy.org/)

### Tools
- [pgAdmin](https://www.pgadmin.org/)
- [RedisInsight](https://redis.com/redis-enterprise/redis-insight/)
- [EXPLAIN Visualizer](https://explain.dalibo.com/)

### Learning Resources
- [Use The Index, Luke](https://use-the-index-luke.com/)
- [PostgreSQL Performance](https://www.2ndquadrant.com/en/blog/)
- [Redis University](https://university.redis.com/)

## 🏆 Module Completion

To complete this module:
1. ✅ Complete all three exercises
2. ✅ Pass the validation tests
3. ✅ Implement the independent project
4. ✅ Review best practices
5. ✅ Share your learnings

## 💡 Remember

> "The best database design is one that balances normalization, performance, and maintainability for your specific use case."

**Next Module**: [Module 10: Real-time and Event-Driven Systems](../module-10-realtime-systems/)

---

**Pro Tip**: Keep this reference handy during development. Database optimization is an iterative process - measure, optimize, and measure again! 🚀