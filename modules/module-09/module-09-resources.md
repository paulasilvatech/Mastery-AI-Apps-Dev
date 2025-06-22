# Module 09: Database Design and Optimization - Resources

## 📚 Essential Learning Resources

### Official Documentation

#### PostgreSQL
- [PostgreSQL 15 Documentation](https://www.postgresql.org/docs/15/)
- [PostgreSQL Performance Tips](https://www.postgresql.org/docs/current/performance-tips.html)
- [PostgreSQL Index Types](https://www.postgresql.org/docs/current/indexes-types.html)
- [EXPLAIN Documentation](https://www.postgresql.org/docs/current/sql-explain.html)
- [pgvector Documentation](https://github.com/pgvector/pgvector)

#### Redis
- [Redis Documentation](https://redis.io/documentation)
- [Redis Data Types](https://redis.io/docs/data-types/)
- [Redis Best Practices](https://redis.io/docs/manual/patterns/)
- [Redis Performance](https://redis.io/docs/manual/performance/)

#### Azure Services
- [Azure Cosmos DB Documentation](https://learn.microsoft.com/azure/cosmos-db/)
- [Azure AI Search](https://learn.microsoft.com/azure/search/)
- [Azure Database for PostgreSQL](https://learn.microsoft.com/azure/postgresql/)

#### Python Libraries
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
- [Alembic Documentation](https://alembic.sqlalchemy.org/)
- [asyncpg Documentation](https://magicstack.github.io/asyncpg/)
- [FastAPI SQL Databases](https://fastapi.tiangolo.com/tutorial/sql-databases/)

### 📖 Recommended Books

1. **"Designing Data-Intensive Applications"** by Martin Kleppmann
   - Essential reading for understanding distributed data systems
   - Covers consistency, scalability, and reliability

2. **"PostgreSQL: Up and Running"** by Regina Obe and Leo Hsu
   - Comprehensive PostgreSQL guide
   - Advanced features and optimization techniques

3. **"SQL Performance Explained"** by Markus Winand
   - Deep dive into SQL optimization
   - Index strategies and query planning

4. **"Database Internals"** by Alex Petrov
   - How databases work under the hood
   - Storage engines and distributed systems

5. **"High Performance PostgreSQL for Rails"** by Andrew Atkinson
   - Performance optimization patterns
   - Real-world scaling strategies

### 🎥 Video Tutorials

#### PostgreSQL Performance
- [PostgreSQL Performance Tuning Tutorial](https://www.youtube.com/watch?v=QnR3xAwWRbQ)
- [Understanding EXPLAIN ANALYZE](https://www.youtube.com/watch?v=M-E_eSG5zRo)
- [Index Optimization Strategies](https://www.youtube.com/watch?v=clrtT_4WBAw)

#### Redis
- [Redis Crash Course](https://www.youtube.com/watch?v=jgpVdJB2sKQ)
- [Redis as a Cache](https://www.youtube.com/watch?v=sVCZo5B8ghE)
- [Redis Data Structures](https://www.youtube.com/watch?v=rP9EKvWt0zo)

#### Database Design
- [Database Design Course](https://www.youtube.com/watch?v=ztHopE5Wnpc)
- [Normalization Explained](https://www.youtube.com/watch?v=UrYLYV7WSHM)
- [NoSQL vs SQL](https://www.youtube.com/watch?v=ruz-vK8IesE)

### 🛠️ Tools and Utilities

#### Database Management
1. **pgAdmin 4**
   - GUI for PostgreSQL management
   - [Download](https://www.pgadmin.org/download/)

2. **DBeaver**
   - Universal database tool
   - [Download](https://dbeaver.io/download/)

3. **TablePlus**
   - Modern database management
   - [Download](https://tableplus.com/)

#### Performance Analysis
1. **pg_stat_statements**
   ```sql
   CREATE EXTENSION pg_stat_statements;
   ```

2. **pgBadger**
   - PostgreSQL log analyzer
   - [GitHub](https://github.com/darold/pgbadger)

3. **pg_top**
   - Real-time PostgreSQL monitoring
   - [GitHub](https://github.com/markwkm/pg_top)

#### Redis Tools
1. **RedisInsight**
   - Official Redis GUI
   - [Download](https://redis.com/redis-enterprise/redis-insight/)

2. **redis-cli**
   - Command-line interface
   - Included with Redis installation

### 📊 Performance Benchmarking

#### Tools
1. **pgbench**
   ```bash
   pgbench -i -s 50 workshop_db
   pgbench -c 10 -j 2 -t 1000 workshop_db
   ```

2. **Apache JMeter**
   - Load testing for APIs
   - [Download](https://jmeter.apache.org/)

3. **Locust**
   - Python-based load testing
   ```python
   from locust import HttpUser, task
   
   class DatabaseUser(HttpUser):
       @task
       def query_products(self):
           self.client.get("/products/featured")
   ```

### 🔍 Query Optimization Resources

#### EXPLAIN Visualization
1. **Dalibo EXPLAIN Visualizer**
   - [explain.dalibo.com](https://explain.dalibo.com/)
   - Paste EXPLAIN output for visualization

2. **pgMustard**
   - Query performance insights
   - [pgmustard.com](https://www.pgmustard.com/)

#### Index Strategies
```sql
-- B-tree indexes (default)
CREATE INDEX idx_users_email ON users(email);

-- Partial indexes
CREATE INDEX idx_orders_pending ON orders(created_at) 
WHERE status = 'pending';

-- Covering indexes
CREATE INDEX idx_products_search ON products(name, category_id) 
INCLUDE (price, image_url);

-- GIN indexes for full-text search
CREATE INDEX idx_products_fts ON products 
USING gin(to_tsvector('english', name || ' ' || description));

-- GiST indexes for geometric data
CREATE INDEX idx_locations_geo ON locations 
USING gist(location);
```

### 🏗️ Database Design Patterns

#### 1. Audit Trail Pattern
```sql
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(50),
    operation VARCHAR(10),
    user_id INTEGER,
    timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    old_data JSONB,
    new_data JSONB
);

CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (table_name, operation, user_id, old_data, new_data)
    VALUES (
        TG_TABLE_NAME,
        TG_OP,
        current_setting('app.current_user_id', true)::INTEGER,
        to_jsonb(OLD),
        to_jsonb(NEW)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

#### 2. Soft Delete Pattern
```sql
ALTER TABLE users ADD COLUMN deleted_at TIMESTAMPTZ;
CREATE INDEX idx_users_active ON users(id) WHERE deleted_at IS NULL;

-- View for active records
CREATE VIEW active_users AS
SELECT * FROM users WHERE deleted_at IS NULL;
```

#### 3. Versioning Pattern
```sql
CREATE TABLE products (
    id INTEGER,
    version INTEGER,
    name VARCHAR(255),
    price DECIMAL(10,2),
    valid_from TIMESTAMPTZ,
    valid_to TIMESTAMPTZ,
    PRIMARY KEY (id, version)
);

-- Current version view
CREATE VIEW current_products AS
SELECT * FROM products WHERE valid_to IS NULL;
```

### 🚀 Advanced Topics

#### TimescaleDB for Time-Series
```sql
CREATE EXTENSION timescaledb;

CREATE TABLE metrics (
    time TIMESTAMPTZ NOT NULL,
    metric_name TEXT,
    value DOUBLE PRECISION
);

SELECT create_hypertable('metrics', 'time');

-- Continuous aggregate
CREATE MATERIALIZED VIEW metrics_hourly
WITH (timescaledb.continuous) AS
SELECT 
    time_bucket('1 hour', time) AS hour,
    metric_name,
    AVG(value) as avg_value,
    MAX(value) as max_value
FROM metrics
GROUP BY hour, metric_name;
```

#### Vector Similarity Search
```sql
CREATE EXTENSION vector;

CREATE TABLE items (
    id SERIAL PRIMARY KEY,
    embedding vector(384)
);

-- Create index for similarity search
CREATE INDEX ON items USING ivfflat (embedding vector_cosine_ops);

-- Find similar items
SELECT * FROM items
ORDER BY embedding <=> '[0.1, 0.2, ...]'::vector
LIMIT 10;
```

### 📈 Monitoring and Observability

#### Key Metrics to Track
1. **Query Performance**
   - Average query time
   - Slow query count
   - Cache hit ratio

2. **Connection Metrics**
   - Active connections
   - Connection pool usage
   - Failed connections

3. **Resource Usage**
   - CPU utilization
   - Memory usage
   - Disk I/O

#### Monitoring Queries
```sql
-- Current activity
SELECT pid, usename, application_name, state, query
FROM pg_stat_activity
WHERE state != 'idle';

-- Slow queries
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC;

-- Table statistics
SELECT 
    schemaname,
    tablename,
    n_live_tup,
    n_dead_tup,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;
```

### 🌐 Community Resources

#### Forums and Q&A
- [PostgreSQL Mailing Lists](https://www.postgresql.org/list/)
- [Stack Overflow - PostgreSQL](https://stackoverflow.com/questions/tagged/postgresql)
- [Reddit r/PostgreSQL](https://www.reddit.com/r/PostgreSQL/)
- [DBA Stack Exchange](https://dba.stackexchange.com/)

#### Slack Communities
- [PostgreSQL Slack](https://postgres-slack.herokuapp.com/)
- [Redis Slack](https://redis.com/community/)

#### Conferences
- **PostgreSQL Conference (PGConf)**
- **Redis Day**
- **DataEngConf**

### 📝 Cheat Sheets

#### PostgreSQL Performance Tuning
```sql
-- Key configuration parameters
shared_buffers = 25% of RAM
effective_cache_size = 75% of RAM
work_mem = RAM / max_connections / 2
maintenance_work_mem = RAM / 8
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1  # For SSD
```

#### Redis Performance Tips
```bash
# Persistence settings for performance
CONFIG SET save ""  # Disable RDB
CONFIG SET appendonly no  # Disable AOF

# Memory optimization
CONFIG SET maxmemory-policy allkeys-lru
CONFIG SET maxmemory 2gb

# Connection handling
CONFIG SET tcp-keepalive 60
CONFIG SET timeout 300
```

### 🎯 Practice Projects

1. **E-Commerce Database**
   - Design from scratch
   - Implement caching layer
   - Add search functionality
   - Performance optimization

2. **Real-time Analytics**
   - Time-series data storage
   - Aggregation pipelines
   - Dashboard queries
   - Anomaly detection

3. **Social Media Platform**
   - User relationships
   - Feed generation
   - Notification system
   - Content recommendations

### 🔗 Additional Resources

#### GitHub Repositories
- [Awesome PostgreSQL](https://github.com/dhamaniasad/awesome-postgres)
- [Awesome Redis](https://github.com/JamzyWang/awesome-redis)
- [Database Design Examples](https://github.com/datacharmer/test_db)

#### Online Courses
- [The Complete SQL Bootcamp](https://www.udemy.com/course/the-complete-sql-bootcamp/)
- [PostgreSQL for Everybody](https://www.pg4e.com/)
- [Redis University](https://university.redis.com/)

Remember: The best way to master database optimization is through practice. Start with the exercises, experiment with different approaches, and always measure the results!