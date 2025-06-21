# API Development Best Practices

## 🏗️ API Design Principles

### 1. RESTful Design

**Resource-Oriented Architecture**
```python
# ✅ Good - Nouns for resources
GET /api/v1/users
GET /api/v1/users/{id}
POST /api/v1/users
PUT /api/v1/users/{id}
DELETE /api/v1/users/{id}

# ❌ Bad - Verbs in URLs
GET /api/v1/getUsers
POST /api/v1/createUser
POST /api/v1/deleteUser/{id}
```

**HTTP Status Codes**
```python
# Use appropriate status codes
200 OK              # Successful GET, PUT
201 Created         # Successful POST
204 No Content      # Successful DELETE
400 Bad Request     # Invalid request data
401 Unauthorized    # Missing/invalid authentication
403 Forbidden       # Authenticated but not authorized
404 Not Found       # Resource doesn't exist
409 Conflict        # Resource already exists
422 Unprocessable   # Validation errors
429 Too Many Requests # Rate limit exceeded
500 Internal Error  # Server error
503 Service Unavailable # Temporary outage
```

**Consistent Error Responses**
```python
@app.exception_handler(ValidationError)
async def validation_exception_handler(request: Request, exc: ValidationError):
    return JSONResponse(
        status_code=422,
        content={
            "error": {
                "code": "VALIDATION_ERROR",
                "message": "Validation failed",
                "details": exc.errors()
            }
        }
    )
```

### 2. GraphQL Design

**Schema-First Development**
```graphql
# Define clear types with descriptions
"""
Represents a user in the system
"""
type User {
  """Unique identifier"""
  id: ID!
  
  """User's display name"""
  username: String!
  
  """User's email address"""
  email: String!
  
  """Posts created by this user"""
  posts(limit: Int = 10, offset: Int = 0): [Post!]!
}
```

**Avoid N+1 Queries**
```python
# Always use DataLoader for relationships
class UserLoader(DataLoader):
    async def batch_load_fn(self, user_ids):
        # Batch load all users in one query
        users = await get_users_by_ids(user_ids)
        user_map = {user.id: user for user in users}
        return [user_map.get(uid) for uid in user_ids]

# In resolver
@strawberry.field
async def author(self, info: Info) -> User:
    return await info.context["loaders"]["user"].load(self.user_id)
```

## 🔒 Security Best Practices

### 1. Authentication & Authorization

**JWT Best Practices**
```python
def create_access_token(user_id: str, roles: List[str]) -> str:
    payload = {
        "sub": user_id,
        "roles": roles,
        "exp": datetime.utcnow() + timedelta(minutes=15),  # Short-lived
        "iat": datetime.utcnow(),
        "jti": str(uuid.uuid4())  # Unique token ID
    }
    return jwt.encode(payload, SECRET_KEY, algorithm="HS256")

# Always validate tokens
def verify_token(token: str) -> dict:
    try:
        payload = jwt.decode(
            token, 
            SECRET_KEY, 
            algorithms=["HS256"],
            options={"verify_exp": True}
        )
        
        # Check if token is blacklisted
        if is_token_blacklisted(payload["jti"]):
            raise InvalidTokenError()
            
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
```

**API Key Management**
```python
class APIKeyAuth:
    async def __call__(self, request: Request) -> Optional[str]:
        api_key = request.headers.get("X-API-Key")
        
        if not api_key:
            raise HTTPException(status_code=401, detail="API key required")
        
        # Hash API keys in database
        key_hash = hashlib.sha256(api_key.encode()).hexdigest()
        
        # Check against database with caching
        if not await is_valid_api_key(key_hash):
            raise HTTPException(status_code=401, detail="Invalid API key")
        
        return api_key
```

### 2. Input Validation

**Comprehensive Validation**
```python
from pydantic import BaseModel, validator, Field
from typing import Optional
import re

class UserCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=30)
    email: str = Field(..., regex=r'^[\w\.-]+@[\w\.-]+\.\w+$')
    password: str = Field(..., min_length=8)
    age: Optional[int] = Field(None, ge=13, le=150)
    
    @validator('username')
    def username_alphanumeric(cls, v):
        if not re.match(r'^[a-zA-Z0-9_]+$', v):
            raise ValueError('Username must be alphanumeric')
        return v
    
    @validator('password')
    def password_strength(cls, v):
        if not any(char.isdigit() for char in v):
            raise ValueError('Password must contain at least one digit')
        if not any(char.isupper() for char in v):
            raise ValueError('Password must contain at least one uppercase letter')
        return v
```

**SQL Injection Prevention**
```python
# Always use parameterized queries
async def get_user_by_email(db: AsyncSession, email: str):
    # ✅ Safe
    result = await db.execute(
        select(User).where(User.email == email)
    )
    
    # ❌ Never do this
    # query = f"SELECT * FROM users WHERE email = '{email}'"
```

## 🚀 Performance Optimization

### 1. Caching Strategies

**Response Caching**
```python
from fastapi_cache import FastAPICache
from fastapi_cache.decorator import cache
from fastapi_cache.backends.redis import RedisBackend

@router.get("/posts/popular")
@cache(expire=300)  # Cache for 5 minutes
async def get_popular_posts(limit: int = 10):
    return await fetch_popular_posts(limit)

# Cache invalidation
async def create_post(post_data: PostCreate):
    post = await save_post(post_data)
    # Invalidate related caches
    await FastAPICache.clear(namespace="posts")
    return post
```

**Database Query Optimization**
```python
# Use select_related for joins
query = select(Post).options(
    selectinload(Post.author),
    selectinload(Post.comments).selectinload(Comment.author)
).limit(20)

# Index frequently queried fields
class Post(Base):
    __tablename__ = "posts"
    
    created_at = Column(DateTime, index=True)
    user_id = Column(UUID, ForeignKey("users.id"), index=True)
    status = Column(String, index=True)
    
    __table_args__ = (
        Index('idx_user_status', 'user_id', 'status'),
    )
```

### 2. Connection Pooling

**Database Connection Pool**
```python
from sqlalchemy.pool import NullPool, QueuePool

# For production
engine = create_async_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=20,
    max_overflow=40,
    pool_timeout=30,
    pool_recycle=1800  # Recycle connections after 30 minutes
)

# HTTP Client Connection Pool
http_client = httpx.AsyncClient(
    limits=httpx.Limits(
        max_keepalive_connections=20,
        max_connections=100,
        keepalive_expiry=30
    )
)
```

### 3. Rate Limiting

**Tiered Rate Limiting**
```python
rate_limits = {
    "anonymous": {"requests": 100, "window": 3600},      # 100/hour
    "authenticated": {"requests": 1000, "window": 3600},  # 1000/hour
    "premium": {"requests": 10000, "window": 3600},      # 10000/hour
}

async def get_rate_limit(request: Request) -> dict:
    if hasattr(request.state, "user"):
        tier = request.state.user.get("tier", "authenticated")
        return rate_limits.get(tier, rate_limits["authenticated"])
    return rate_limits["anonymous"]
```

## 📊 Monitoring and Observability

### 1. Structured Logging

```python
import structlog

logger = structlog.get_logger()

@router.post("/orders")
async def create_order(order: OrderCreate, request: Request):
    logger.info(
        "order_creation_started",
        user_id=request.state.user["id"],
        order_data=order.dict(),
        request_id=request.headers.get("X-Request-ID")
    )
    
    try:
        result = await process_order(order)
        logger.info(
            "order_creation_completed",
            order_id=result.id,
            duration_ms=elapsed_time
        )
        return result
    except Exception as e:
        logger.error(
            "order_creation_failed",
            error=str(e),
            error_type=type(e).__name__
        )
        raise
```

### 2. Metrics Collection

```python
from prometheus_client import Counter, Histogram, Gauge

# Define metrics
request_count = Counter(
    'api_requests_total',
    'Total API requests',
    ['method', 'endpoint', 'status']
)

request_duration = Histogram(
    'api_request_duration_seconds',
    'API request duration',
    ['method', 'endpoint']
)

active_connections = Gauge(
    'api_active_connections',
    'Number of active connections'
)

# Middleware to collect metrics
@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start_time = time.time()
    active_connections.inc()
    
    try:
        response = await call_next(request)
        duration = time.time() - start_time
        
        request_count.labels(
            method=request.method,
            endpoint=request.url.path,
            status=response.status_code
        ).inc()
        
        request_duration.labels(
            method=request.method,
            endpoint=request.url.path
        ).observe(duration)
        
        return response
    finally:
        active_connections.dec()
```

### 3. Distributed Tracing

```python
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

tracer = trace.get_tracer(__name__)

@router.get("/users/{user_id}/profile")
async def get_user_profile(user_id: str):
    with tracer.start_as_current_span("get_user_profile") as span:
        span.set_attribute("user.id", user_id)
        
        # Trace database call
        with tracer.start_as_current_span("fetch_user"):
            user = await get_user(user_id)
        
        # Trace external API call
        with tracer.start_as_current_span("fetch_user_posts"):
            posts = await get_user_posts(user_id)
        
        return {"user": user, "posts": posts}
```

## 🔄 API Versioning

### URL Path Versioning
```python
# Recommended approach
app = FastAPI()

# Version 1
v1_router = APIRouter(prefix="/api/v1")
v1_router.include_router(users_v1.router, prefix="/users")
v1_router.include_router(posts_v1.router, prefix="/posts")

# Version 2 with breaking changes
v2_router = APIRouter(prefix="/api/v2")
v2_router.include_router(users_v2.router, prefix="/users")
v2_router.include_router(posts_v2.router, prefix="/posts")

app.include_router(v1_router)
app.include_router(v2_router)
```

### Header-Based Versioning
```python
@app.middleware("http")
async def version_middleware(request: Request, call_next):
    version = request.headers.get("API-Version", "1.0")
    request.state.api_version = version
    return await call_next(request)
```

## 📝 Documentation

### OpenAPI Customization
```python
app = FastAPI(
    title="Task Management API",
    description="""
    ## Features
    * **Tasks** - Create and manage tasks
    * **Users** - User management
    * **Auth** - JWT authentication
    
    ## Authentication
    Use Bearer token in Authorization header
    """,
    version="1.0.0",
    contact={
        "name": "API Support",
        "email": "api@example.com"
    },
    license_info={
        "name": "MIT",
        "url": "https://opensource.org/licenses/MIT"
    }
)

# Add security scheme
app.openapi_schema["components"]["securitySchemes"] = {
    "bearerAuth": {
        "type": "http",
        "scheme": "bearer",
        "bearerFormat": "JWT"
    }
}
```

## 🎯 Production Checklist

- [ ] **Security**
  - [ ] Authentication implemented
  - [ ] Authorization checks in place
  - [ ] Input validation comprehensive
  - [ ] SQL injection prevention
  - [ ] XSS protection
  - [ ] CORS properly configured

- [ ] **Performance**
  - [ ] Database queries optimized
  - [ ] Caching strategy implemented
  - [ ] Connection pooling configured
  - [ ] Rate limiting enabled
  - [ ] Response compression

- [ ] **Reliability**
  - [ ] Error handling comprehensive
  - [ ] Circuit breakers implemented
  - [ ] Retry logic for external calls
  - [ ] Graceful degradation
  - [ ] Health checks

- [ ] **Observability**
  - [ ] Structured logging
  - [ ] Metrics collection
  - [ ] Distributed tracing
  - [ ] Error tracking
  - [ ] Performance monitoring

- [ ] **Documentation**
  - [ ] OpenAPI/Swagger complete
  - [ ] README comprehensive
  - [ ] API changelog maintained
  - [ ] Example requests provided
  - [ ] Error codes documented

## 🚀 Deployment Best Practices

### Container Optimization
```dockerfile
# Multi-stage build
FROM python:3.11-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .
ENV PATH=/root/.local/bin:$PATH
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Environment Configuration
```python
from pydantic import BaseSettings

class Settings(BaseSettings):
    # API Settings
    api_title: str = "My API"
    api_version: str = "1.0.0"
    
    # Security
    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    
    # Database
    database_url: str
    
    # Redis
    redis_url: str = "redis://localhost:6379"
    
    # External Services
    auth_service_url: str
    
    class Config:
        env_file = ".env"
        case_sensitive = False

settings = Settings()
```

---

Remember: These best practices should be adapted to your specific use case. Always prioritize security, performance, and maintainability in your API development.