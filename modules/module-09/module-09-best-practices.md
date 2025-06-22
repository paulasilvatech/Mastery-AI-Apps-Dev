# Database Design and Optimization Best Practices

## 🏗️ Schema Design Best Practices

### 1. Naming Conventions

**Tables**
```sql
-- ✅ Good: Plural, lowercase, underscores
CREATE TABLE users (...);
CREATE TABLE order_items (...);

-- ❌ Bad: Mixed case, spaces, prefixes
CREATE TABLE tbl_Users (...);
CREATE TABLE "Order Items" (...);
```

**Columns**
```sql
-- ✅ Good: Descriptive, consistent
id, created_at, updated_at, is_active, user_id

-- ❌ Bad: Ambiguous, inconsistent
userid, date, flag, status
```

**Copilot Prompt for Naming:**
```python
# Generate consistent table and column names following:
# - Tables: plural, snake_case
# - Columns: singular, snake_case
# - Foreign keys: {table}_id
# - Booleans: is_ or has_ prefix
# - Timestamps: _at suffix
```

### 2. Data Types Selection

**Money/Currency**
```sql
-- ✅ Good: DECIMAL for precision
price DECIMAL(10, 2)  -- Up to 99,999,999.99

-- ❌ Bad: FLOAT loses precision
price FLOAT  -- Rounding errors!
```

**Timestamps**
```sql
-- ✅ Good: TIMESTAMPTZ for time zones
created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP

-- ❌ Bad: String dates
created_at VARCHAR(20)  -- '2024-01-15 10:30:00'
```

**IDs and Keys**
```sql
-- ✅ Good: Multiple strategies based on needs
id SERIAL PRIMARY KEY,                    -- Auto-increment
id UUID DEFAULT gen_random_uuid(),        -- UUID for distribution
id BIGSERIAL PRIMARY KEY,                 -- Large datasets

-- ❌ Bad: Predictable or small
id SMALLINT,  -- Only 32,767 values!
```

### 3. Normalization Guidelines

**Third Normal Form (3NF)**
```python
# ✅ Good: Normalized structure
class User:
    id, email, name

class Address:
    id, user_id, street, city, country

# ❌ Bad: Denormalized with redundancy
class User:
    id, email, name, 
    home_street, home_city, home_country,
    work_street, work_city, work_country
```

**When to Denormalize**
- Read-heavy workloads
- Complex aggregations
- Real-time requirements
- Use materialized views instead

### 4. Relationship Design

**Many-to-Many**
```sql
-- ✅ Good: Junction table with composite key
CREATE TABLE user_roles (
    user_id INTEGER REFERENCES users(id),
    role_id INTEGER REFERENCES roles(id),
    assigned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id)
);

-- Add indexes for both directions
CREATE INDEX idx_user_roles_role_id ON user_roles(role_id);
```

**Soft Deletes**
```sql
-- ✅ Good: Maintain referential integrity
ALTER TABLE users ADD COLUMN deleted_at TIMESTAMPTZ;
CREATE INDEX idx_users_active ON users(id) WHERE deleted_at IS NULL;
```

## 🚀 Query Optimization Best Practices

### 1. Index Strategy

**Copilot Prompt for Index Analysis:**
```python
# Analyze query and suggest indexes:
# - WHERE clause columns (high selectivity first)
# - JOIN columns (foreign keys)
# - ORDER BY columns
# - Consider covering indexes with INCLUDE
# - Suggest partial indexes for filtered queries
```

**Index Guidelines**
```sql
-- ✅ Good: Targeted indexes
CREATE INDEX idx_orders_user_status ON orders(user_id, status) 
WHERE status IN ('pending', 'processing');

CREATE INDEX idx_products_search ON products(name, category_id) 
INCLUDE (price, image_url);  -- Covering index

-- ❌ Bad: Over-indexing
CREATE INDEX idx_users_firstname ON users(first_name);
CREATE INDEX idx_users_lastname ON users(last_name);
-- Better: CREATE INDEX idx_users_name ON users(last_name, first_name);
```

### 2. Query Patterns

**Pagination**
```sql
-- ✅ Good: Cursor-based pagination
SELECT * FROM products 
WHERE id > :last_id 
ORDER BY id 
LIMIT 20;

-- ❌ Bad: OFFSET for large datasets
SELECT * FROM products 
ORDER BY id 
LIMIT 20 OFFSET 10000;  -- Scans 10,020 rows!
```

**Existence Checks**
```sql
-- ✅ Good: EXISTS for existence
SELECT * FROM orders o
WHERE EXISTS (
    SELECT 1 FROM order_items oi 
    WHERE oi.order_id = o.id AND oi.product_id = 123
);

-- ❌ Bad: COUNT for existence
SELECT * FROM orders o
WHERE (
    SELECT COUNT(*) FROM order_items oi 
    WHERE oi.order_id = o.id AND oi.product_id = 123
) > 0;
```

### 3. Join Optimization

**Join Order**
```sql
-- ✅ Good: Filter early, join less
WITH active_users AS (
    SELECT id, email FROM users 
    WHERE is_active = true AND created_at > '2024-01-01'
)
SELECT au.*, COUNT(o.id) as order_count
FROM active_users au
LEFT JOIN orders o ON o.user_id = au.id
GROUP BY au.id, au.email;

-- ❌ Bad: Join everything, filter later
SELECT u.*, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.is_active = true AND u.created_at > '2024-01-01'
GROUP BY u.id;
```

## 🔄 Caching Best Practices

### 1. Cache Key Design

```python
# ✅ Good: Versioned, namespaced keys
def get_cache_key(entity_type: str, entity_id: int, version: str = "v1"):
    return f"{entity_type}:{version}:{entity_id}"

# Examples:
# "user:v1:12345"
# "product:v2:67890:inventory"

# ❌ Bad: Ambiguous keys
cache_key = str(user_id)  # Collision risk!
```

### 2. Cache Strategies

**Cache-Aside Pattern**
```python
async def get_user(user_id: int):
    # Check cache first
    cache_key = f"user:v1:{user_id}"
    cached = await redis.get(cache_key)
    if cached:
        return json.loads(cached)
    
    # Load from database
    user = await db.fetch_one("SELECT * FROM users WHERE id = $1", user_id)
    
    # Cache with TTL
    await redis.setex(cache_key, 3600, json.dumps(user))
    return user
```

**Write-Through Pattern**
```python
async def update_user(user_id: int, data: dict):
    # Update database
    await db.execute("UPDATE users SET ... WHERE id = $1", user_id)
    
    # Update cache
    cache_key = f"user:v1:{user_id}"
    await redis.setex(cache_key, 3600, json.dumps(data))
    
    # Invalidate related caches
    await redis.delete(f"user_orders:v1:{user_id}")
```

### 3. Cache Invalidation

```python
# Copilot Prompt:
# Create a cache invalidation strategy that:
# - Invalidates related caches on updates
# - Uses pub/sub for distributed invalidation  
# - Implements tag-based invalidation
# - Handles race conditions
# - Provides cache warming
```

## 🔒 Connection Management

### 1. Connection Pooling

```python
# ✅ Good: Proper pool configuration
from sqlalchemy.pool import QueuePool

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=20,          # Base connections
    max_overflow=40,       # Additional when needed
    pool_timeout=30,       # Wait before error
    pool_recycle=3600,     # Recycle old connections
    pool_pre_ping=True     # Test connections
)

# ❌ Bad: No pooling
conn = psycopg2.connect(DATABASE_URL)  # New connection each time
```

### 2. Async Database Access

```python
# ✅ Good: Async with connection management
import asyncpg

class DatabasePool:
    def __init__(self):
        self._pool = None
    
    async def init(self):
        self._pool = await asyncpg.create_pool(
            DATABASE_URL,
            min_size=10,
            max_size=50,
            command_timeout=60,
            max_inactive_connection_lifetime=300
        )
    
    async def fetch_user(self, user_id: int):
        async with self._pool.acquire() as conn:
            return await conn.fetchrow(
                "SELECT * FROM users WHERE id = $1", 
                user_id
            )
```

## 📊 Monitoring and Maintenance

### 1. Query Performance Monitoring

```sql
-- Enable query stats
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Find slow queries
SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    stddev_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 100  -- Over 100ms
ORDER BY mean_exec_time DESC
LIMIT 20;
```

### 2. Index Maintenance

```sql
-- Find unused indexes
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE idx_scan = 0
AND indexname NOT LIKE 'pg_%'
ORDER BY schemaname, tablename;

-- Find index bloat
WITH index_bloat AS (
    -- Complex query to calculate bloat
)
SELECT * FROM index_bloat WHERE bloat_ratio > 20;
```

### 3. Vacuum and Analyze

```python
# Automated maintenance script
async def database_maintenance():
    """Run regular maintenance tasks"""
    
    # Analyze tables for query planner
    await db.execute("ANALYZE;")
    
    # Vacuum to reclaim space
    await db.execute("VACUUM (VERBOSE, ANALYZE);")
    
    # Reindex if needed
    tables_to_reindex = await find_bloated_indexes()
    for table in tables_to_reindex:
        await db.execute(f"REINDEX TABLE {table};")
```

## 🎯 Production Checklist

### Before Deployment

- [ ] All foreign keys have indexes
- [ ] No missing primary keys
- [ ] Appropriate data types chosen
- [ ] Constraints validate business rules
- [ ] Indexes support common queries
- [ ] Connection pooling configured
- [ ] Monitoring queries ready
- [ ] Backup strategy tested
- [ ] Migration rollback plan
- [ ] Performance benchmarks met

### Ongoing Maintenance

- [ ] Weekly: Review slow query log
- [ ] Monthly: Check index usage
- [ ] Monthly: Analyze table statistics  
- [ ] Quarterly: Review schema design
- [ ] Quarterly: Capacity planning
- [ ] Yearly: Major version upgrades

## 🚨 Common Pitfalls to Avoid

1. **N+1 Queries**: Use eager loading or batch queries
2. **Missing Indexes**: Monitor and add as needed
3. **Incorrect Types**: Especially for money and dates
4. **No Monitoring**: You can't optimize what you don't measure
5. **Over-normalization**: Balance with performance needs
6. **Under-caching**: Cache expensive computations
7. **Connection Leaks**: Always close/return connections
8. **No Backups**: Test restore procedures regularly

## 📚 Recommended Reading

- "Designing Data-Intensive Applications" by Martin Kleppmann
- "PostgreSQL High Performance" by Gregory Smith
- "SQL Performance Explained" by Markus Winand
- PostgreSQL Official Documentation
- Redis Design Patterns

Remember: The best database design is one that balances normalization, performance, and maintainability for your specific use case!