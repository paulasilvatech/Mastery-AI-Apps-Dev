# Module 08 Troubleshooting Guide

## 🔧 Common Issues and Solutions

### FastAPI Issues

#### Issue: "ImportError: cannot import name 'FastAPI' from 'fastapi'"
**Symptoms:**
```
ImportError: cannot import name 'FastAPI' from 'fastapi'
```

**Solution:**
```bash
# Ensure FastAPI is installed in your virtual environment
pip install fastapi

# If already installed, try reinstalling
pip uninstall fastapi
pip install fastapi==0.109.0

# Verify installation
python -c "import fastapi; print(fastapi.__version__)"
```

#### Issue: "No module named 'uvicorn'"
**Symptoms:**
- Can't run the server with `uvicorn app.main:app`

**Solution:**
```bash
# Install uvicorn with standard extras
pip install "uvicorn[standard]"

# Or install specific version
pip install uvicorn==0.27.0
```

#### Issue: "RuntimeError: asyncio.run() cannot be called from a running event loop"
**Symptoms:**
- Error when running async code in Jupyter notebooks

**Solution:**
```python
# For Jupyter notebooks, use nest_asyncio
import nest_asyncio
nest_asyncio.apply()

# Or use await directly instead of asyncio.run()
await your_async_function()
```

### Database Connection Issues

#### Issue: "sqlalchemy.exc.OperationalError: (sqlite3.OperationalError) unable to open database file"
**Symptoms:**
- Database connection fails
- File permissions error

**Solution:**
```python
# Ensure database directory exists
import os
os.makedirs(os.path.dirname("./test.db"), exist_ok=True)

# Check file permissions
# Linux/Mac:
chmod 666 test.db

# Use absolute path
DATABASE_URL = f"sqlite+aiosqlite:///{os.path.abspath('test.db')}"
```

#### Issue: "This session is in 'inactive' state"
**Symptoms:**
- SQLAlchemy session errors
- Database operations fail after first request

**Solution:**
```python
# Ensure proper session management
async def get_db():
    async with async_session() as session:
        try:
            yield session
            await session.commit()  # Commit if no errors
        except Exception:
            await session.rollback()  # Rollback on error
            raise
        finally:
            await session.close()  # Always close
```

### API Testing Issues

#### Issue: "httpx.ConnectError: [Errno 111] Connection refused"
**Symptoms:**
- Tests fail to connect to API
- Connection refused errors

**Solution:**
```python
# Use TestClient for testing instead of real server
from fastapi.testclient import TestClient

client = TestClient(app)
response = client.get("/api/v1/tasks")

# For async tests, use httpx.AsyncClient
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_api():
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/api/v1/tasks")
```

#### Issue: "ValueError: The future belongs to a different loop"
**Symptoms:**
- Async test failures
- Event loop errors

**Solution:**
```python
# Use pytest-asyncio properly
import pytest

@pytest.fixture
async def client():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

@pytest.mark.asyncio
async def test_endpoint(client):
    response = await client.get("/endpoint")
    assert response.status_code == 200
```

### GraphQL Issues

#### Issue: "Cannot query field 'X' on type 'Y'"
**Symptoms:**
- GraphQL queries fail
- Field not found errors

**Solution:**
```python
# Ensure field is properly decorated
@strawberry.type
class User:
    id: UUID
    username: str
    
    @strawberry.field  # Don't forget this decorator
    async def posts(self, info: Info) -> List[Post]:
        return await get_user_posts(self.id)
```

#### Issue: "DataLoader not found in context"
**Symptoms:**
- N+1 query problems
- Missing context errors

**Solution:**
```python
# Ensure DataLoaders are added to context
async def get_context(request):
    return {
        "dataloaders": {
            "user": UserLoader(db_session),
            "posts": PostLoader(db_session)
        }
    }

# In GraphQL setup
graphql_app = GraphQLRouter(
    schema,
    context_getter=get_context
)
```

### Authentication Issues

#### Issue: "401 Unauthorized" on all requests
**Symptoms:**
- All authenticated endpoints return 401
- Token validation fails

**Solution:**
```python
# Check token format
# Correct: Authorization: Bearer <token>
# Wrong: Authorization: <token>

# Verify secret key matches
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key")

# Debug token
def debug_token(token: str):
    try:
        # Decode without verification first
        unverified = jwt.decode(token, options={"verify_signature": False})
        print("Token payload:", unverified)
        
        # Now verify
        verified = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        print("Token is valid")
    except jwt.ExpiredSignatureError:
        print("Token expired")
    except jwt.InvalidTokenError as e:
        print(f"Invalid token: {e}")
```

#### Issue: "CORS error: No 'Access-Control-Allow-Origin' header"
**Symptoms:**
- Browser blocks API requests
- CORS errors in console

**Solution:**
```python
# Configure CORS properly
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],  # Specific origins in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# For development, allow all origins
allow_origins=["*"]
```

### Performance Issues

#### Issue: "504 Gateway Timeout"
**Symptoms:**
- Requests timeout after 30 seconds
- Slow database queries

**Solution:**
```python
# 1. Add database indexes
class Task(Base):
    created_at = Column(DateTime, index=True)
    user_id = Column(UUID, index=True)
    status = Column(String, index=True)

# 2. Use pagination
@router.get("/tasks")
async def list_tasks(
    page: int = Query(1, ge=1),
    size: int = Query(10, ge=1, le=100)
):
    offset = (page - 1) * size
    query = select(Task).offset(offset).limit(size)

# 3. Add query timeout
engine = create_async_engine(
    DATABASE_URL,
    connect_args={"timeout": 30}
)
```

#### Issue: "429 Too Many Requests"
**Symptoms:**
- Rate limit errors
- Requests blocked

**Solution:**
```python
# Check rate limit headers
response.headers["X-RateLimit-Remaining"]
response.headers["X-RateLimit-Reset"]

# For testing, disable rate limiting
@router.get("/test", dependencies=[])  # Remove rate limit dependency

# Or increase limits for testing
rate_limits = {
    "default": 1000,  # Increase for testing
}
```

### Redis Connection Issues

#### Issue: "redis.exceptions.ConnectionError: Error -2 connecting to localhost:6379"
**Symptoms:**
- Redis connection fails
- Caching doesn't work

**Solution:**
```bash
# 1. Start Redis server
# Docker:
docker run -d -p 6379:6379 redis:7-alpine

# Ubuntu/Debian:
sudo apt-get install redis-server
sudo systemctl start redis

# macOS:
brew install redis
brew services start redis

# 2. Test connection
redis-cli ping
# Should return: PONG

# 3. Use fallback if Redis unavailable
try:
    redis_client = await redis.from_url("redis://localhost:6379")
    await redis_client.ping()
except:
    logger.warning("Redis unavailable, using in-memory cache")
    redis_client = None
```

### Docker Issues

#### Issue: "python: can't open file '/app/main.py': [Errno 2] No such file or directory"
**Symptoms:**
- Docker container fails to start
- File not found errors

**Solution:**
```dockerfile
# Ensure correct working directory and file structure
FROM python:3.11-slim

WORKDIR /app

# Copy requirements first
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy application code
COPY ./app ./app

# Use correct module path
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## 🔍 Debugging Tools

### API Debugging

```python
# 1. Enable SQL query logging
engine = create_async_engine(
    DATABASE_URL,
    echo=True  # See all SQL queries
)

# 2. Add request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    
    # Log request
    logger.info(f"{request.method} {request.url.path}")
    
    response = await call_next(request)
    
    # Log response
    process_time = time.time() - start_time
    logger.info(f"Completed in {process_time:.3f}s - Status: {response.status_code}")
    
    return response

# 3. Interactive debugging
import pdb; pdb.set_trace()  # Breakpoint
# Or for async code:
import asyncio
await asyncio.create_task(asyncio.sleep(0))  # Allow debugger to work
```

### Performance Profiling

```python
# 1. Profile slow endpoints
from line_profiler import LineProfiler

lp = LineProfiler()
lp.add_function(your_slow_function)

@router.get("/slow-endpoint")
async def slow_endpoint():
    lp.enable()
    result = await your_slow_function()
    lp.disable()
    lp.print_stats()
    return result

# 2. Memory profiling
from memory_profiler import profile

@profile
async def memory_intensive_function():
    # Your code here
    pass
```

### Load Testing

```bash
# Using Apache Bench
ab -n 1000 -c 10 http://localhost:8000/api/v1/tasks

# Using httpie with GNU parallel
seq 1 100 | parallel -j 10 "http GET localhost:8000/api/v1/tasks"

# Using locust
locust -f locustfile.py --host=http://localhost:8000
```

## 🆘 Getting Help

### 1. Check Logs
```python
# Enable detailed logging
import logging
logging.basicConfig(level=logging.DEBUG)

# FastAPI logs
uvicorn app.main:app --log-level debug
```

### 2. Verify Dependencies
```bash
# Check installed packages
pip list

# Verify versions match requirements
pip install -r requirements.txt --upgrade
```

### 3. Community Resources
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
- [Strawberry GraphQL Documentation](https://strawberry.rocks/)
- [GitHub Discussions](https://github.com/tiangolo/fastapi/discussions)

### 4. Common Debug Commands
```bash
# Check Python path
python -c "import sys; print(sys.path)"

# Verify module can be imported
python -c "from app.main import app; print('Import successful')"

# Test database connection
python -c "from app.database import engine; import asyncio; asyncio.run(engine.connect())"

# Check environment variables
python -c "import os; print(os.environ.get('DATABASE_URL'))"
```

---

💡 **Pro Tip**: When debugging, start with the simplest possible test case and gradually add complexity until you reproduce the issue. This helps isolate the root cause.