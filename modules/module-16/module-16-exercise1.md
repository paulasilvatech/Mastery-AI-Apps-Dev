# Exercise 1: Zero Trust API Gateway (⭐ Easy - 30 minutes)

## 🎯 Objective

Build a secure API gateway that implements Zero Trust principles including authentication, authorization, rate limiting, and audit logging. This gateway will serve as the security perimeter for all enterprise API calls.

## 🔑 What You'll Learn

- Implement JWT-based authentication
- Apply role-based access control (RBAC)
- Configure rate limiting per user/API key
- Create comprehensive audit logs
- Handle security errors gracefully

## 📋 Requirements

- Python 3.11+ with FastAPI
- Azure Key Vault for secrets
- Redis for rate limiting
- Application Insights for monitoring

## 📝 Instructions

### Step 1: Project Setup

Create the project structure:

```bash
mkdir zero-trust-gateway
cd zero-trust-gateway

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install fastapi==0.104.0 uvicorn==0.24.0 python-jose[cryptography]==3.3.0
pip install azure-keyvault-secrets==4.7.0 azure-identity==1.15.0
pip install redis==5.0.0 python-multipart==0.0.6
pip install opencensus-ext-azure==1.1.9
```

### Step 2: Create Security Configuration

**Copilot Prompt Suggestion:**
```
Create a Python configuration class for Zero Trust security that:
- Loads JWT secret from Azure Key Vault
- Configures allowed origins for CORS
- Sets up rate limiting parameters (100 requests per minute per user)
- Defines role-based permissions mapping
- Includes audit log settings
Use environment variables with secure defaults and proper type hints.
```

**Expected Output:**
```python
import os
from typing import Dict, List, Optional
from azure.keyvault.secrets import SecretClient
from azure.identity import DefaultAzureCredential
from functools import lru_cache

class SecurityConfig:
    """Zero Trust security configuration."""
    
    def __init__(self):
        self.key_vault_name = os.getenv("KEY_VAULT_NAME", "")
        self.jwt_algorithm = "HS256"
        self.access_token_expire_minutes = 30
        self.rate_limit_requests = 100
        self.rate_limit_window = 60  # seconds
        
        # CORS settings
        self.allowed_origins = os.getenv(
            "ALLOWED_ORIGINS", 
            "https://localhost:3000"
        ).split(",")
        
        # Role permissions mapping
        self.role_permissions: Dict[str, List[str]] = {
            "admin": ["read", "write", "delete", "admin"],
            "user": ["read", "write"],
            "viewer": ["read"]
        }
        
        # Audit settings
        self.enable_audit_logs = os.getenv("ENABLE_AUDIT", "true").lower() == "true"
        self.audit_retention_days = int(os.getenv("AUDIT_RETENTION_DAYS", "90"))
    
    @lru_cache()
    def get_jwt_secret(self) -> str:
        """Retrieve JWT secret from Azure Key Vault."""
        if not self.key_vault_name:
            # Development fallback - NEVER use in production
            return os.getenv("JWT_SECRET", "dev-secret-change-me")
        
        credential = DefaultAzureCredential()
        client = SecretClient(
            vault_url=f"https://{self.key_vault_name}.vault.azure.net/",
            credential=credential
        )
        
        secret = client.get_secret("jwt-secret")
        return secret.value
    
    def has_permission(self, role: str, permission: str) -> bool:
        """Check if role has specific permission."""
        return permission in self.role_permissions.get(role, [])

@lru_cache()
def get_security_config() -> SecurityConfig:
    """Get cached security configuration instance."""
    return SecurityConfig()
```

### Step 3: Implement Authentication Middleware

**Copilot Prompt Suggestion:**
```
Create FastAPI authentication middleware that:
- Validates JWT tokens from Authorization header
- Extracts user claims (sub, roles, permissions)
- Implements token refresh mechanism
- Handles expired tokens with proper error messages
- Logs all authentication attempts
Include proper exception handling and security headers.
```

**Expected Output:**
```python
from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
import logging

logger = logging.getLogger(__name__)
security = HTTPBearer()

class TokenData:
    """Token payload data."""
    def __init__(self, username: str, roles: List[str], permissions: List[str]):
        self.username = username
        self.roles = roles
        self.permissions = permissions

async def verify_token(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    config: SecurityConfig = Depends(get_security_config)
) -> TokenData:
    """Verify JWT token and extract user data."""
    token = credentials.credentials
    
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = jwt.decode(
            token, 
            config.get_jwt_secret(), 
            algorithms=[config.jwt_algorithm]
        )
        username: str = payload.get("sub")
        roles: List[str] = payload.get("roles", [])
        
        if username is None:
            logger.warning("Token validation failed: missing username")
            raise credentials_exception
        
        # Extract permissions based on roles
        permissions = []
        for role in roles:
            permissions.extend(config.role_permissions.get(role, []))
        
        logger.info(f"Successful authentication for user: {username}")
        return TokenData(username=username, roles=roles, permissions=permissions)
        
    except JWTError as e:
        logger.error(f"JWT validation error: {str(e)}")
        raise credentials_exception

def create_access_token(
    data: Dict[str, Any], 
    config: SecurityConfig = get_security_config()
) -> str:
    """Create a new JWT access token."""
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=config.access_token_expire_minutes)
    to_encode.update({"exp": expire})
    
    encoded_jwt = jwt.encode(
        to_encode, 
        config.get_jwt_secret(), 
        algorithm=config.jwt_algorithm
    )
    return encoded_jwt
```

### Step 4: Implement Rate Limiting

**Copilot Prompt Suggestion:**
```
Create a Redis-based rate limiter for the API gateway that:
- Tracks requests per user using sliding window
- Allows different limits for different roles
- Returns remaining requests in response headers
- Handles Redis connection failures gracefully
- Supports both API key and user-based limiting
Include decorator for easy route protection.
```

**Expected Output:**
```python
import redis
from functools import wraps
from fastapi import Request, HTTPException, status
import time
import hashlib

class RateLimiter:
    """Redis-based rate limiter with sliding window."""
    
    def __init__(self, redis_url: str = "redis://localhost:6379"):
        try:
            self.redis_client = redis.from_url(redis_url)
            self.redis_client.ping()
            self.available = True
        except Exception as e:
            logger.warning(f"Redis not available: {e}. Rate limiting disabled.")
            self.available = False
    
    def check_rate_limit(
        self, 
        identifier: str, 
        limit: int, 
        window: int
    ) -> tuple[bool, int]:
        """Check if request is within rate limit."""
        if not self.available:
            return True, limit  # Allow all requests if Redis is down
        
        try:
            # Create unique key for this identifier
            key = f"rate_limit:{hashlib.md5(identifier.encode()).hexdigest()}"
            current_time = int(time.time())
            window_start = current_time - window
            
            # Remove old entries
            self.redis_client.zremrangebyscore(key, 0, window_start)
            
            # Count requests in current window
            request_count = self.redis_client.zcard(key)
            
            if request_count < limit:
                # Add current request
                self.redis_client.zadd(key, {str(current_time): current_time})
                self.redis_client.expire(key, window)
                remaining = limit - request_count - 1
                return True, remaining
            else:
                remaining = 0
                return False, remaining
                
        except Exception as e:
            logger.error(f"Rate limit check failed: {e}")
            return True, limit  # Fail open

rate_limiter = RateLimiter(os.getenv("REDIS_URL", "redis://localhost:6379"))

def rate_limit(requests_per_minute: int = 100):
    """Decorator to apply rate limiting to routes."""
    def decorator(func):
        @wraps(func)
        async def wrapper(request: Request, *args, **kwargs):
            # Get user identifier from token or IP
            token_data = kwargs.get('current_user')
            if token_data:
                identifier = f"user:{token_data.username}"
                # Admin users get higher limits
                if "admin" in token_data.roles:
                    requests_per_minute = 1000
            else:
                identifier = f"ip:{request.client.host}"
            
            allowed, remaining = rate_limiter.check_rate_limit(
                identifier, 
                requests_per_minute, 
                60
            )
            
            # Add rate limit headers
            request.state.rate_limit_remaining = remaining
            request.state.rate_limit_limit = requests_per_minute
            
            if not allowed:
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail="Rate limit exceeded. Please try again later."
                )
            
            return await func(request, *args, **kwargs)
        return wrapper
    return decorator
```

### Step 5: Create the API Gateway

**Copilot Prompt Suggestion:**
```
Create a FastAPI application that serves as a Zero Trust API gateway with:
- Health check endpoint (no auth required)
- Login endpoint for token generation
- Protected endpoints with role-based access
- Audit logging for all requests
- Security headers (HSTS, CSP, etc.)
- CORS configuration
- Request ID tracking
Include proper error handling and OpenAPI documentation.
```

**Expected Output:**
```python
from fastapi import FastAPI, Request, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import uuid
import logging
from datetime import datetime
from typing import Optional

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifecycle manager."""
    logger.info("Starting Zero Trust API Gateway")
    yield
    logger.info("Shutting down Zero Trust API Gateway")

app = FastAPI(
    title="Zero Trust API Gateway",
    description="Secure API Gateway with Zero Trust principles",
    version="1.0.0",
    lifespan=lifespan
)

# Security configuration
config = get_security_config()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.middleware("http")
async def security_headers(request: Request, call_next):
    """Add security headers to all responses."""
    # Generate request ID
    request_id = str(uuid.uuid4())
    request.state.request_id = request_id
    
    # Process request
    response = await call_next(request)
    
    # Add security headers
    response.headers["X-Request-ID"] = request_id
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["Content-Security-Policy"] = "default-src 'self'"
    
    # Add rate limit headers if available
    if hasattr(request.state, "rate_limit_remaining"):
        response.headers["X-RateLimit-Remaining"] = str(request.state.rate_limit_remaining)
        response.headers["X-RateLimit-Limit"] = str(request.state.rate_limit_limit)
    
    return response

@app.middleware("http")
async def audit_logging(request: Request, call_next):
    """Log all requests for audit purposes."""
    start_time = datetime.utcnow()
    
    # Log request
    audit_entry = {
        "timestamp": start_time.isoformat(),
        "request_id": getattr(request.state, "request_id", "unknown"),
        "method": request.method,
        "path": request.url.path,
        "client_ip": request.client.host,
        "user": None
    }
    
    try:
        response = await call_next(request)
        audit_entry["status_code"] = response.status_code
        audit_entry["duration_ms"] = (datetime.utcnow() - start_time).total_seconds() * 1000
        
        # Log successful request
        logger.info(f"Audit: {audit_entry}")
        return response
        
    except Exception as e:
        audit_entry["status_code"] = 500
        audit_entry["error"] = str(e)
        logger.error(f"Audit: {audit_entry}")
        raise

# Health check endpoint (no auth required)
@app.get("/health", tags=["Health"])
async def health_check():
    """Health check endpoint for monitoring."""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0"
    }

# Authentication endpoints
@app.post("/auth/login", tags=["Authentication"])
async def login(username: str, password: str):
    """Login endpoint to obtain JWT token."""
    # In production, verify against identity provider
    # This is a simplified example
    if username == "admin" and password == "secure-password":
        token_data = {
            "sub": username,
            "roles": ["admin"]
        }
        access_token = create_access_token(token_data)
        return {
            "access_token": access_token,
            "token_type": "bearer"
        }
    
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid credentials"
    )

# Protected endpoints
@app.get("/api/users", tags=["Users"])
@rate_limit(requests_per_minute=100)
async def get_users(
    request: Request,
    current_user: TokenData = Depends(verify_token)
):
    """Get all users (requires 'read' permission)."""
    if "read" not in current_user.permissions:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Insufficient permissions"
        )
    
    # Audit log with user context
    logger.info(f"User {current_user.username} accessed /api/users")
    
    return {
        "users": ["user1", "user2", "user3"],
        "request_id": request.state.request_id
    }

@app.post("/api/secure-action", tags=["Admin"])
@rate_limit(requests_per_minute=10)
async def secure_action(
    request: Request,
    action: str,
    current_user: TokenData = Depends(verify_token)
):
    """Perform secure action (requires 'admin' permission)."""
    if "admin" not in current_user.permissions:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    
    logger.warning(f"Admin action performed by {current_user.username}: {action}")
    
    return {
        "status": "success",
        "action": action,
        "performed_by": current_user.username,
        "timestamp": datetime.utcnow().isoformat()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### Step 6: Test Your Implementation

Create a test script:

```python
# test_gateway.py
import requests
import time

BASE_URL = "http://localhost:8000"

# Test health check
print("Testing health check...")
response = requests.get(f"{BASE_URL}/health")
print(f"Health: {response.json()}")

# Test login
print("\nTesting login...")
response = requests.post(
    f"{BASE_URL}/auth/login",
    params={"username": "admin", "password": "secure-password"}
)
token = response.json()["access_token"]
print(f"Token obtained: {token[:20]}...")

# Test protected endpoint
print("\nTesting protected endpoint...")
headers = {"Authorization": f"Bearer {token}"}
response = requests.get(f"{BASE_URL}/api/users", headers=headers)
print(f"Users: {response.json()}")

# Test rate limiting
print("\nTesting rate limiting...")
for i in range(5):
    response = requests.get(f"{BASE_URL}/api/users", headers=headers)
    remaining = response.headers.get("X-RateLimit-Remaining", "N/A")
    print(f"Request {i+1}: Status={response.status_code}, Remaining={remaining}")
    time.sleep(0.1)
```

## ✅ Validation

Your Zero Trust API Gateway implementation should:

1. **Authentication**: Successfully validate JWT tokens
2. **Authorization**: Enforce role-based access control
3. **Rate Limiting**: Limit requests per user/minute
4. **Security Headers**: Include all required security headers
5. **Audit Logging**: Log all requests with user context
6. **Error Handling**: Return appropriate error messages

## 🎯 Success Criteria

- [ ] All endpoints return appropriate security headers
- [ ] Invalid tokens result in 401 Unauthorized
- [ ] Insufficient permissions result in 403 Forbidden
- [ ] Rate limit exceeded results in 429 Too Many Requests
- [ ] All requests are logged with audit information
- [ ] Health check works without authentication

## 🚀 Extension Challenges

1. **Add OAuth2 Support**: Integrate with Azure AD for enterprise SSO
2. **Implement API Versioning**: Support multiple API versions with different security policies
3. **Add Request Signing**: Implement HMAC request signing for additional security
4. **Create Admin Dashboard**: Build a real-time monitoring dashboard for the gateway

## 📚 Additional Resources

- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)
- [Zero Trust Architecture](https://www.nist.gov/publications/zero-trust-architecture)

---

🎉 Congratulations! You've built a production-ready Zero Trust API Gateway. Continue to Exercise 2 to implement encrypted AI pipelines!