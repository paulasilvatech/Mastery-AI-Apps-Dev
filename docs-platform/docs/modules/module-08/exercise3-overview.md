---
sidebar_position: 2
title: "Exercise 3: Overview"
description: "## 📋 Overview"
---

# Exercise 3: Enterprise API Gateway (⭐⭐⭐ Hard)

## 📋 Overview

Build a production-ready API gateway that integrates multiple backend services, handles authentication centrally, implements intelligent rate limiting, provides comprehensive monitoring, and ensures high availability. This exercise combines everything you've learned about API development into an enterprise-grade solution.

**Duration:** 60-90 minutes  
**Difficulty:** ⭐⭐⭐ Hard  
**Success Rate:** 60%

## 🎯 Learning Objectives

By completing this exercise, you will:
- Design and implement an API gateway pattern
- Integrate multiple backend services (REST & GraphQL)
- Implement centralized authentication and authorization
- Add intelligent rate limiting and circuit breaking
- Build comprehensive monitoring and observability
- Handle service discovery and load balancing
- Implement API versioning and transformation
- Deploy with high availability considerations

## 🏗️ Architecture

```mermaid
graph TB
    subgraph "Clients"
        A[Web App]
        B[Mobile App]
        C[Third-party Apps]
    end
    
    subgraph "API Gateway"
        D[Load Balancer]
        E[Auth Middleware]
        F[Rate Limiter]
        G[Circuit Breaker]
        H[Request Router]
        I[Response Cache]
        J[Monitoring]
        
        D --&gt; E
        E --&gt; F
        F --&gt; G
        G --&gt; H
        H --&gt; I
        I --&gt; J
    end
    
    subgraph "Backend Services"
        K[User Service<br/>REST]
        L[Task Service<br/>REST]
        M[Social Service<br/>GraphQL]
        N[Notification Service<br/>gRPC]
        O[Analytics Service<br/>REST]
    end
    
    subgraph "Infrastructure"
        P[(Redis Cache)]
        Q[(PostgreSQL)]
        R[Service Registry]
        S[Prometheus]
        T[Jaeger]
    end
    
    A --&gt; D
    B --&gt; D
    C --&gt; D
    
    H --&gt; K
    H --&gt; L
    H --&gt; M
    H --&gt; N
    H --&gt; O
    
    F --&gt; P
    I --&gt; P
    K --&gt; Q
    L --&gt; Q
    M --&gt; Q
    
    J --&gt; S
    J --&gt; T
    H --&gt; R
    
    style D fill:#f96,stroke:#333,stroke-width:4px
    style H fill:#69f,stroke:#333,stroke-width:4px
    style P fill:#9f9,stroke:#333,stroke-width:2px
```

## 🚀 Implementation Steps

### Step 1: Gateway Core Setup

Create the project structure:
```bash
cd exercises/exercise3-api-gateway
mkdir -p gateway/{middleware,routers,services,monitoring}
mkdir -p tests
mkdir -p config
```

Create `gateway/main.py`:

**Copilot Prompt Suggestion:**
```python
# Create an enterprise API gateway with:
# - FastAPI as the core framework
# - Multiple backend service integration
# - Centralized error handling
# - Request/response transformation
# - Service health checking
# - Graceful shutdown handling
# Include comprehensive logging and metrics
```

**Expected Output:**
```python
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import httpx
import asyncio
from typing import Dict, Any
import logging
import os
from prometheus_client import Counter, Histogram, generate_latest
import time

# Metrics
request_count = Counter('gateway_requests_total', 'Total requests', ['method', 'endpoint', 'status'])
request_duration = Histogram('gateway_request_duration_seconds', 'Request duration', ['method', 'endpoint'])

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Service registry
SERVICES = {
    "users": {
        "url": os.getenv("USER_SERVICE_URL", "http://localhost:8001"),
        "health": "/health",
        "timeout": 30
    },
    "tasks": {
        "url": os.getenv("TASK_SERVICE_URL", "http://localhost:8002"),
        "health": "/health",
        "timeout": 30
    },
    "social": {
        "url": os.getenv("SOCIAL_SERVICE_URL", "http://localhost:8003"),
        "health": "/health",
        "type": "graphql"
    }
}

class ServiceRegistry:
    def __init__(self):
        self.services = SERVICES.copy()
        self.health_status = {}
        self.http_client = None
    
    async def start(self):
        self.http_client = httpx.AsyncClient(timeout=5.0)
        # Start health checking
        asyncio.create_task(self._health_check_loop())
    
    async def stop(self):
        if self.http_client:
            await self.http_client.aclose()
    
    async def _health_check_loop(self):
        while True:
            for name, config in self.services.items():
                try:
                    response = await self.http_client.get(
                        f"{config['url']}{config['health']}"
                    )
                    self.health_status[name] = response.status_code == 200
                except Exception as e:
                    logger.error(f"Health check failed for {name}: {e}")
                    self.health_status[name] = False
            
            await asyncio.sleep(10)  # Check every 10 seconds
    
    def get_service(self, name: str) -&gt; Dict[str, Any]:
        if name not in self.services:
            raise ValueError(f"Service {name} not found")
        
        if not self.health_status.get(name, False):
            raise Exception(f"Service {name} is unhealthy")
        
        return self.services[name]

# Global service registry
service_registry = ServiceRegistry()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("API Gateway starting up...")
    await service_registry.start()
    
    # Initialize other services
    from gateway.middleware.auth import init_auth
    from gateway.middleware.rate_limit import init_rate_limiter
    from gateway.services.cache import init_cache
    
    await init_auth()
    await init_rate_limiter()
    await init_cache()
    
    yield
    
    # Shutdown
    logger.info("API Gateway shutting down...")
    await service_registry.stop()

app = FastAPI(
    title="Enterprise API Gateway",
    description="Central entry point for all microservices",
    version="1.0.0",
    lifespan=lifespan
)

# Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Import and register middleware
from gateway.middleware.auth import AuthMiddleware
from gateway.middleware.rate_limit import RateLimitMiddleware
from gateway.middleware.circuit_breaker import CircuitBreakerMiddleware
from gateway.middleware.monitoring import MonitoringMiddleware

app.add_middleware(MonitoringMiddleware)
app.add_middleware(CircuitBreakerMiddleware)
app.add_middleware(RateLimitMiddleware)
app.add_middleware(AuthMiddleware)

# Import routers
from gateway.routers import proxy, graphql, health

app.include_router(health.router, tags=["health"])
app.include_router(proxy.router, prefix="/api/v1")
app.include_router(graphql.router, prefix="/graphql")

# Metrics endpoint
@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type="text/plain")
```

### Step 2: Authentication Middleware

Create `gateway/middleware/auth.py`:

**Copilot Prompt Suggestion:**
```python
# Create authentication middleware that:
# - Validates JWT tokens
# - Checks token expiration
# - Extracts user claims
# - Handles multiple auth schemes (Bearer, API Key)
# - Integrates with external auth service
# - Caches auth decisions
# Include role-based access control
```

**Expected Output:**
```python
from fastapi import Request, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response
import jwt
from typing import Optional, Dict, Any
import httpx
from datetime import datetime, timedelta
import redis.asyncio as redis
import json

# Configuration
JWT_SECRET = os.getenv("JWT_SECRET", "your-secret-key")
JWT_ALGORITHM = "HS256"
AUTH_SERVICE_URL = os.getenv("AUTH_SERVICE_URL", "http://localhost:8000")

# Redis client for caching
redis_client = None

async def init_auth():
    global redis_client
    redis_client = await redis.from_url("redis://localhost:6379")

class AuthMiddleware(BaseHTTPMiddleware):
    def __init__(self, app):
        super().__init__(app)
        self.public_paths = [
            "/health",
            "/metrics",
            "/docs",
            "/openapi.json",
            "/api/v1/auth/login",
            "/api/v1/auth/register"
        ]
    
    async def dispatch(self, request: Request, call_next):
        # Skip auth for public paths
        if any(request.url.path.startswith(path) for path in self.public_paths):
            return await call_next(request)
        
        # Extract token
        auth_header = request.headers.get("Authorization")
        if not auth_header or not auth_header.startswith("Bearer "):
            return Response(
                content=json.dumps({{"detail": "Missing authentication"}}),
                status_code=401,
                media_type="application/json"
            )
        
        token = auth_header.split(" ")[1]
        
        # Check cache
        cached = await self._get_cached_auth(token)
        if cached:
            request.state.user = cached
            return await call_next(request)
        
        # Validate token
        try:
            # Decode JWT
            payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
            
            # Check expiration
            if payload.get("exp", 0) &lt; datetime.utcnow().timestamp():
                raise jwt.ExpiredSignatureError()
            
            # Validate with auth service
            user = await self._validate_with_service(token)
            
            # Cache the result
            await self._cache_auth(token, user, ttl=300)  # 5 minutes
            
            # Add user to request state
            request.state.user = user
            
            response = await call_next(request)
            return response
            
        except jwt.ExpiredSignatureError:
            return Response(
                content=json.dumps({{"detail": "Token expired"}}),
                status_code=401,
                media_type="application/json"
            )
        except jwt.InvalidTokenError:
            return Response(
                content=json.dumps({{"detail": "Invalid token"}}),
                status_code=401,
                media_type="application/json"
            )
        except Exception as e:
            logger.error(f"Auth error: {e}")
            return Response(
                content=json.dumps({{"detail": "Authentication failed"}}),
                status_code=401,
                media_type="application/json"
            )
    
    async def _get_cached_auth(self, token: str) -&gt; Optional[Dict[str, Any]]:
        try:
            cached = await redis_client.get(f"auth:{token}")
            if cached:
                return json.loads(cached)
        except Exception as e:
            logger.error(f"Cache error: {e}")
        return None
    
    async def _cache_auth(self, token: str, user: Dict[str, Any], ttl: int):
        try:
            await redis_client.setex(
                f"auth:{token}",
                ttl,
                json.dumps(user)
            )
        except Exception as e:
            logger.error(f"Cache error: {e}")
    
    async def _validate_with_service(self, token: str) -&gt; Dict[str, Any]:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{AUTH_SERVICE_URL}/validate",
                headers={{"Authorization": f"Bearer {{token}}"}}
            )
            
            if response.status_code != 200:
                raise Exception("Invalid token")
            
            return response.json()

# Authorization decorator
def require_role(role: str):
    def decorator(func):
        async def wrapper(request: Request, *args, **kwargs):
            user = getattr(request.state, "user", None)
            if not user or role not in user.get("roles", []):
                raise HTTPException(status_code=403, detail="Insufficient permissions")
            return await func(request, *args, **kwargs)
        return wrapper
    return decorator
```

### Step 3: Rate Limiting

Create `gateway/middleware/rate_limit.py`:

**Copilot Prompt Suggestion:**
```python
# Create intelligent rate limiting middleware with:
# - Token bucket algorithm
# - Per-user and per-IP limits
# - Different limits for different endpoints
# - Distributed rate limiting with Redis
# - Graceful degradation
# - Rate limit headers in responses
```

**Expected Output:**
```python
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response
import redis.asyncio as redis
import time
import json
from typing import Tuple
import ipaddress

redis_client = None

async def init_rate_limiter():
    global redis_client
    redis_client = await redis.from_url("redis://localhost:6379")

class RateLimitMiddleware(BaseHTTPMiddleware):
    def __init__(self, app):
        super().__init__(app)
        # Configure limits: requests per minute
        self.limits = {
            "default": 60,
            "auth": 10,
            "api": 100,
            "graphql": 50
        }
        self.window = 60  # 1 minute window
    
    async def dispatch(self, request: Request, call_next):
        # Get identifier (user ID or IP)
        identifier = self._get_identifier(request)
        
        # Get limit for endpoint
        limit = self._get_limit(request.url.path)
        
        # Check rate limit
        allowed, remaining, reset = await self._check_rate_limit(identifier, limit)
        
        if not allowed:
            return Response(
                content=json.dumps({
                    "detail": "Rate limit exceeded",
                    "retry_after": reset
                }),
                status_code=429,
                headers={
                    "X-RateLimit-Limit": str(limit),
                    "X-RateLimit-Remaining": "0",
                    "X-RateLimit-Reset": str(reset),
                    "Retry-After": str(reset)
                }
            )
        
        # Process request
        response = await call_next(request)
        
        # Add rate limit headers
        response.headers["X-RateLimit-Limit"] = str(limit)
        response.headers["X-RateLimit-Remaining"] = str(remaining)
        response.headers["X-RateLimit-Reset"] = str(reset)
        
        return response
    
    def _get_identifier(self, request: Request) -&gt; str:
        # Use user ID if authenticated
        if hasattr(request.state, "user"):
            return f"user:{request.state.user['id']}"
        
        # Otherwise use IP
        client_ip = request.client.host
        return f"ip:{client_ip}"
    
    def _get_limit(self, path: str) -&gt; int:
        if path.startswith("/api/v1/auth"):
            return self.limits["auth"]
        elif path.startswith("/api"):
            return self.limits["api"]
        elif path.startswith("/graphql"):
            return self.limits["graphql"]
        return self.limits["default"]
    
    async def _check_rate_limit(self, identifier: str, limit: int) -&gt; Tuple[bool, int, int]:
        key = f"rate_limit:{identifier}"
        now = int(time.time())
        window_start = now - self.window
        
        # Use Redis sorted set for sliding window
        pipe = redis_client.pipeline()
        
        # Remove old entries
        pipe.zremrangebyscore(key, 0, window_start)
        
        # Count requests in window
        pipe.zcard(key)
        
        # Add current request
        pipe.zadd(key, {str(now): now})
        
        # Set expiry
        pipe.expire(key, self.window + 1)
        
        results = await pipe.execute()
        count = results[1]
        
        if count &gt; limit:
            # Remove the request we just added
            await redis_client.zrem(key, str(now))
            remaining = 0
            allowed = False
        else:
            remaining = limit - count
            allowed = True
        
        # Calculate reset time
        if count &gt; 0:
            oldest = await redis_client.zrange(key, 0, 0, withscores=True)
            if oldest:
                reset = int(oldest[0][1]) + self.window
            else:
                reset = now + self.window
        else:
            reset = now + self.window
        
        return allowed, remaining, reset
```

### Step 4: Circuit Breaker

Create `gateway/middleware/circuit_breaker.py`:

**Copilot Prompt Suggestion:**
```python
# Implement circuit breaker pattern:
# - Track failures per service
# - Open circuit after threshold
# - Half-open state for testing
# - Automatic recovery
# - Fallback responses
# - Metrics integration
```

**Expected Output:**
```python
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse
import asyncio
from typing import Dict
from datetime import datetime, timedelta
from enum import Enum
import logging

logger = logging.getLogger(__name__)

class CircuitState(Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"

class CircuitBreaker:
    def __init__(self, failure_threshold: int = 5, timeout: int = 60):
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.failure_count = 0
        self.last_failure_time = None
        self.state = CircuitState.CLOSED
        self.success_count = 0
        self.lock = asyncio.Lock()
    
    async def call(self, func, *args, **kwargs):
        async with self.lock:
            if self.state == CircuitState.OPEN:
                if self._should_attempt_reset():
                    self.state = CircuitState.HALF_OPEN
                    self.success_count = 0
                else:
                    raise Exception("Circuit breaker is OPEN")
        
        try:
            result = await func(*args, **kwargs)
            await self._on_success()
            return result
        except Exception as e:
            await self._on_failure()
            raise e
    
    async def _on_success(self):
        async with self.lock:
            if self.state == CircuitState.HALF_OPEN:
                self.success_count += 1
                if self.success_count &gt;= 3:  # Require 3 successes
                    self.state = CircuitState.CLOSED
                    self.failure_count = 0
                    logger.info("Circuit breaker closed")
    
    async def _on_failure(self):
        async with self.lock:
            self.failure_count += 1
            self.last_failure_time = datetime.now()
            
            if self.state == CircuitState.HALF_OPEN:
                self.state = CircuitState.OPEN
                logger.warning("Circuit breaker opened from half-open")
            elif self.failure_count &gt;= self.failure_threshold:
                self.state = CircuitState.OPEN
                logger.warning(f"Circuit breaker opened after {self.failure_count} failures")
    
    def _should_attempt_reset(self) -&gt; bool:
        if not self.last_failure_time:
            return True
        return datetime.now() - self.last_failure_time &gt; timedelta(seconds=self.timeout)

class CircuitBreakerMiddleware(BaseHTTPMiddleware):
    def __init__(self, app):
        super().__init__(app)
        self.breakers: Dict[str, CircuitBreaker] = {}
    
    async def dispatch(self, request: Request, call_next):
        # Extract service name from path
        service = self._extract_service(request.url.path)
        
        if service:
            if service not in self.breakers:
                self.breakers[service] = CircuitBreaker()
            
            breaker = self.breakers[service]
            
            try:
                # Use circuit breaker for service calls
                if breaker.state == CircuitState.OPEN:
                    return JSONResponse(
                        status_code=503,
                        content={
                            "detail": f"Service {{service}} is temporarily unavailable",
                            "service": service,
                            "retry_after": 60
                        }
                    )
                
                response = await call_next(request)
                
                # Consider 5xx responses as failures
                if response.status_code &gt;= 500:
                    await breaker._on_failure()
                else:
                    await breaker._on_success()
                
                return response
                
            except Exception as e:
                await breaker._on_failure()
                raise
        
        return await call_next(request)
    
    def _extract_service(self, path: str) -&gt; str:
        parts = path.split("/")
        if len(parts) &gt;= 4 and parts[1] == "api":
            return parts[3]  # /api/v1/{service}/...
        return None
```

### Step 5: Service Proxy Router

Create `gateway/routers/proxy.py`:

**Copilot Prompt Suggestion:**
```python
# Create service proxy router that:
# - Routes requests to appropriate backend services
# - Transforms requests and responses
# - Handles service discovery
# - Implements retry logic
# - Aggregates responses from multiple services
# - Handles different protocols (REST, GraphQL, gRPC)
```

**Expected Output:**
```python
from fastapi import APIRouter, Request, Response, HTTPException
from fastapi.responses import StreamingResponse
import httpx
import json
from typing import Dict, Any, List
import asyncio
from gateway.main import service_registry

router = APIRouter()

class ServiceProxy:
    def __init__(self):
        self.http_client = httpx.AsyncClient(timeout=30.0)
    
    async def proxy_request(
        self,
        service_name: str,
        path: str,
        request: Request,
        transform_request=None,
        transform_response=None
    ):
        # Get service configuration
        try:
            service = service_registry.get_service(service_name)
        except Exception as e:
            raise HTTPException(status_code=503, detail=str(e))
        
        # Build target URL
        target_url = f"{service['url']}{path}"
        
        # Get request data
        headers = dict(request.headers)
        headers.pop("host", None)
        
        # Add internal headers
        if hasattr(request.state, "user"):
            headers["X-User-Id"] = str(request.state.user["id"])
            headers["X-User-Roles"] = ",".join(request.state.user.get("roles", []))
        
        # Transform request if needed
        body = await request.body()
        if transform_request:
            body = transform_request(body)
        
        # Make request with retry
        for attempt in range(3):
            try:
                response = await self.http_client.request(
                    method=request.method,
                    url=target_url,
                    headers=headers,
                    content=body,
                    params=request.query_params
                )
                
                # Transform response if needed
                content = response.content
                if transform_response:
                    content = transform_response(content)
                
                return Response(
                    content=content,
                    status_code=response.status_code,
                    headers=dict(response.headers)
                )
                
            except httpx.TimeoutException:
                if attempt == 2:
                    raise HTTPException(status_code=504, detail="Service timeout")
                await asyncio.sleep(1 * (attempt + 1))
            except Exception as e:
                logger.error(f"Proxy error: {e}")
                raise HTTPException(status_code=502, detail="Service error")

proxy = ServiceProxy()

# User service routes
@router.api_route("/users/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def proxy_users(path: str, request: Request):
    return await proxy.proxy_request("users", f"/{path}", request)

# Task service routes
@router.api_route("/tasks/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def proxy_tasks(path: str, request: Request):
    return await proxy.proxy_request("tasks", f"/{path}", request)

# Aggregation endpoint
@router.get("/dashboard")
async def get_dashboard(request: Request):
    """Aggregate data from multiple services"""
    user_id = request.state.user["id"]
    
    # Parallel requests to multiple services
    async def get_user_data():
        response = await proxy.http_client.get(
            f"{service_registry.get_service('users')['url']}/users/{user_id}"
        )
        return response.json()
    
    async def get_user_tasks():
        response = await proxy.http_client.get(
            f"{service_registry.get_service('tasks')['url']}/tasks",
            params={{"user_id": user_id, "limit": 5}}
        )
        return response.json()
    
    async def get_user_stats():
        response = await proxy.http_client.get(
            f"{service_registry.get_service('tasks')['url']}/tasks/stats",
            headers={{"X-User-Id": str(user_id)}}
        )
        return response.json()
    
    # Execute in parallel
    try:
        user, tasks, stats = await asyncio.gather(
            get_user_data(),
            get_user_tasks(),
            get_user_stats()
        )
        
        return {
            "user": user,
            "recent_tasks": tasks,
            "statistics": stats
        }
    except Exception as e:
        logger.error(f"Dashboard aggregation error: {e}")
        raise HTTPException(status_code=500, detail="Failed to load dashboard")
```

### Step 6: Monitoring and Tests

Create `gateway/monitoring/metrics.py`:

**Copilot Prompt Suggestion:**
```python
# Create comprehensive monitoring:
# - Request/response metrics
# - Service health metrics
# - Performance tracking
# - Error rate monitoring
# - Distributed tracing
# - Custom business metrics
```

Create `tests/test_gateway.py`:

**Copilot Prompt Suggestion:**
```python
# Create comprehensive gateway tests:
# - Test authentication flow
# - Test rate limiting
# - Test circuit breaker behavior
# - Test service routing
# - Test response aggregation
# - Load testing scenarios
```

## 🎉 Exercise Complete!

You've built an enterprise-grade API gateway with:
- ✅ Multiple service integration
- ✅ Centralized authentication
- ✅ Intelligent rate limiting
- ✅ Circuit breaker pattern
- ✅ Service discovery
- ✅ Response aggregation
- ✅ Comprehensive monitoring

## 📊 Success Criteria

- Gateway handles 10,000+ requests/second
- Zero downtime during service failures
- Sub-100ms latency overhead
- Complete observability
- Secure by default

## 🚀 Production Deployment

1. **Containerize the gateway**
2. **Deploy with Kubernetes**
3. **Setup auto-scaling**
4. **Configure monitoring alerts**
5. **Implement blue-green deployment**

## 🎯 Key Takeaways

- **API Gateway Pattern**: Central control point for microservices
- **Resilience Patterns**: Circuit breakers, retries, timeouts
- **Security**: Centralized auth, rate limiting
- **Observability**: Metrics, logging, tracing
- **Performance**: Caching, connection pooling

---

🏆 **Congratulations!** You've completed Module 8 and built production-ready APIs! Ready to continue with Module 9: Database Design and Optimization?