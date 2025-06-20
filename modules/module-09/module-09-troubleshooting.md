# Module 09: Database Design and Optimization - Troubleshooting Guide

## 🚨 Common Issues and Solutions

### 🔴 Connection Issues

#### Problem: "FATAL: password authentication failed"
```bash
psql: FATAL:  password authentication failed for user "workshop_user"
```

**Solutions:**
1. Verify credentials in `.env` file
2. Check PostgreSQL authentication method:
```bash
# Edit pg_hba.conf
sudo nano /etc/postgresql/15/main/pg_hba.conf

# Change from 'peer' to 'md5' for local connections
local   all   all   md5

# Restart PostgreSQL
sudo systemctl restart postgresql
```

3. Reset user password:
```sql
sudo -u postgres psql
ALTER USER workshop_user WITH PASSWORD 'workshop_pass';
```

#### Problem: "could not connect to server: Connection refused"
```
psycopg2.OperationalError: could not connect to server: Connection refused
```

**Solutions:**
1. Check if PostgreSQL is running:
```bash
# Linux
sudo systemctl status postgresql
sudo systemctl start postgresql

# macOS
brew services list
brew services start postgresql

# Docker
docker ps
docker start postgres-module09
```

2. Verify port availability:
```bash
# Check if port 5432 is listening
netstat -an | grep 5432
lsof -i :5432
```

3. Check PostgreSQL configuration:
```bash
# postgresql.conf
listen_addresses = 'localhost'  # or '*' for all interfaces
port = 5432
```

### 🟡 Performance Issues

#### Problem: "Query timeout" or slow queries
```python
psycopg2.OperationalError: timeout expired
```

**Solutions:**
1. Analyze query execution plan:
```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM your_slow_query;
```

2. Add missing indexes:
```python
# Copilot prompt to analyze and suggest indexes
# Find missing indexes for this query:
# [paste your slow query]
# Consider selectivity and covering indexes
```

3. Increase timeout temporarily for analysis:
```python
conn = psycopg2.connect(
    DATABASE_URL,
    options='-c statement_timeout=300000'  # 5 minutes
)
```

#### Problem: "too many connections"
```
FATAL: remaining connection slots are reserved for non-replication superuser connections
```

**Solutions:**
1. Check current connections:
```sql
SELECT count(*) FROM pg_stat_activity;
SELECT pid, usename, application_name, state 
FROM pg_stat_activity 
WHERE state != 'idle';
```

2. Terminate idle connections:
```sql
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE state = 'idle' 
AND state_change < CURRENT_TIMESTAMP - INTERVAL '10 minutes';
```

3. Configure connection pooling:
```python
# Use connection pooling
from sqlalchemy.pool import QueuePool
engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=20,
    max_overflow=0
)
```

### 🔵 Schema Issues

#### Problem: "relation does not exist"
```
psycopg2.errors.UndefinedTable: relation "users" does not exist
```

**Solutions:**
1. Run migrations:
```bash
# Using Alembic
alembic upgrade head

# Or create tables directly
python -c "from models import Base, engine; Base.metadata.create_all(engine)"
```

2. Check schema search path:
```sql
SHOW search_path;
SET search_path TO public;
```

#### Problem: "violates foreign key constraint"
```
psycopg2.errors.ForeignKeyViolation: insert or update on table "orders" violates foreign key constraint
```

**Solutions:**
1. Check referenced data exists:
```sql
-- Verify user exists before creating order
SELECT id FROM users WHERE id = 123;
```

2. Use proper cascade options:
```python
user_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'))
```

3. Defer constraints in transactions:
```python
with engine.begin() as conn:
    conn.execute("SET CONSTRAINTS ALL DEFERRED")
    # Perform operations
```

### 🟢 Data Issues

#### Problem: "duplicate key value violates unique constraint"
```
psycopg2.errors.UniqueViolation: duplicate key value violates unique constraint "users_email_key"
```

**Solutions:**
1. Check for existing data:
```python
existing = session.query(User).filter_by(email=email).first()
if existing:
    # Update existing instead of insert
    pass
```

2. Use INSERT ... ON CONFLICT:
```sql
INSERT INTO users (email, name) 
VALUES ('user@example.com', 'John')
ON CONFLICT (email) DO UPDATE 
SET name = EXCLUDED.name;
```

#### Problem: Data type mismatch
```
psycopg2.errors.DatatypeMismatch: column "price" is of type numeric but expression is of type text
```

**Solutions:**
1. Ensure proper type conversion:
```python
# Convert to Decimal for money
from decimal import Decimal
price = Decimal('19.99')

# Don't use float for money!
price = 19.99  # ❌ Bad
```

2. Use proper parameterized queries:
```python
# ✅ Good - let driver handle types
cursor.execute("UPDATE products SET price = %s WHERE id = %s", (price, product_id))

# ❌ Bad - string formatting
cursor.execute(f"UPDATE products SET price = {price} WHERE id = {product_id}")
```

### 🟣 Redis/Cache Issues

#### Problem: "Connection refused" to Redis
```
redis.exceptions.ConnectionError: Error 111 connecting to localhost:6379. Connection refused.
```

**Solutions:**
1. Start Redis:
```bash
# Local
redis-server

# Docker
docker run -d -p 6379:6379 redis:7-alpine

# Check if running
redis-cli ping
```

2. Configure Redis connection:
```python
import redis
r = redis.Redis(
    host='localhost',
    port=6379,
    decode_responses=True,
    socket_connect_timeout=5,
    retry_on_timeout=True
)
```

#### Problem: Cache inconsistency
```
# Data in cache doesn't match database
```

**Solutions:**
1. Implement proper cache invalidation:
```python
def update_user(user_id, data):
    # Update database
    db.update_user(user_id, data)
    
    # Invalidate cache
    cache.delete(f"user:{user_id}")
    cache.delete(f"user_orders:{user_id}")
```

2. Use cache versioning:
```python
CACHE_VERSION = "v2"  # Increment to invalidate all
cache_key = f"user:{CACHE_VERSION}:{user_id}"
```

### 🔧 Development Environment Issues

#### Problem: "Module not found" errors
```
ModuleNotFoundError: No module named 'psycopg2'
```

**Solutions:**
1. Activate virtual environment:
```bash
# Windows
.\venv\Scripts\activate

# Linux/macOS
source venv/bin/activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt

# For psycopg2 on macOS
brew install postgresql
pip install psycopg2-binary
```

#### Problem: Migration conflicts
```
alembic.util.exc.CommandError: Target database is not up to date.
```

**Solutions:**
1. Check current revision:
```bash
alembic current
alembic history
```

2. Resolve conflicts:
```bash
# Mark current state
alembic stamp head

# Or downgrade and re-upgrade
alembic downgrade -1
alembic upgrade head
```

## 🔍 Debugging Tools

### PostgreSQL Debugging

```sql
-- Current queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query, state
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';

-- Lock information
SELECT blocked_locks.pid AS blocked_pid,
       blocked_activity.usename AS blocked_user,
       blocking_locks.pid AS blocking_pid,
       blocking_activity.usename AS blocking_user,
       blocked_activity.query AS blocked_statement,
       blocking_activity.query AS current_statement_in_blocking_process
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks 
    ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;

-- Table sizes
SELECT
    schemaname AS table_schema,
    tablename AS table_name,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS data_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS external_size
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Python Debugging

```python
# Enable SQL query logging
import logging
logging.basicConfig()
logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)

# Profile query performance
import time
from contextlib import contextmanager

@contextmanager
def timed_query(description):
    start = time.time()
    yield
    duration = time.time() - start
    print(f"{description}: {duration:.3f}s")

# Usage
with timed_query("Fetch user orders"):
    orders = session.query(Order).filter_by(user_id=123).all()
```

## 🆘 Getting Help

1. **Check logs**:
```bash
# PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-*.log

# Application logs
tail -f app.log
```

2. **Enable debug mode**:
```python
# SQLAlchemy
engine = create_engine(DATABASE_URL, echo=True)

# Django
DEBUG = True
LOGGING = {
    'version': 1,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'loggers': {
        'django.db.backends': {
            'level': 'DEBUG',
            'handlers': ['console'],
        }
    }
}
```

3. **Community resources**:
- PostgreSQL Slack: https://postgres-slack.herokuapp.com/
- Stack Overflow: Tag with [postgresql] [python]
- GitHub Discussions: Module-specific issues

Remember: Most database issues can be debugged by carefully reading error messages and checking logs!