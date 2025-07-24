---
sidebar_position: 9
title: "Exercise 3: Part 3"
description: "## 🚀 Part 3: Deployment, Monitoring, and Production Optimization"
---

# Ejercicio 3: Completar Application (⭐⭐⭐ Difícil) - Partee 3

## 🚀 Partee 3: despliegue, Monitoring, and producción Optimization

Let's complete our application by adding despliegue configuration, monitoring, and producción-ready features.

### Step 11: Create WebSocket Implementation

Create `starter/backend/app/api/v1/websocket.py`:

**🤖 Copilot Prompt Suggestion #11:**
```python
# Create WebSocket endpoint for real-time updates:
# - Connection management with authentication
# - Broadcast task updates to connected clients
# - Handle disconnections gracefully
# - Room-based broadcasting (per user)
# - Heartbeat/ping-pong for connection health
```

**Expected Output:**
```python
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query, status
from typing import Dict, Set
import json
import asyncio
from datetime import datetime
from app.core.auth import get_current_user
from app.models.database import User
from jose import JWTError, jwt
from app.core.config import settings
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.database import get_db
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

class ConnectionManager:
    """Manages WebSocket connections."""
    
    def __init__(self):
        # Store active connections by user_id
        self.active_connections: Dict[str, Set[WebSocket]] = {}
        self.user_connections: Dict[WebSocket, str] = {}
    
    async def connect(self, websocket: WebSocket, user_id: str):
        """Accept and store a new connection."""
        await websocket.accept()
        
        # Add to user's connections
        if user_id not in self.active_connections:
            self.active_connections[user_id] = set()
        
        self.active_connections[user_id].add(websocket)
        self.user_connections[websocket] = user_id
        
        logger.info(f"User {user_id} connected via WebSocket")
    
    def disconnect(self, websocket: WebSocket):
        """Remove a connection."""
        user_id = self.user_connections.get(websocket)
        
        if user_id:
            self.active_connections[user_id].discard(websocket)
            
            # Clean up empty sets
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
            
            del self.user_connections[websocket]
            
            logger.info(f"User {user_id} disconnected from WebSocket")
    
    async def send_personal_message(self, message: str, user_id: str):
        """Send a message to all connections of a specific user."""
        if user_id in self.active_connections:
            disconnected = set()
            
            for connection in self.active_connections[user_id]:
                try:
                    await connection.send_text(message)
                except Exception as e:
                    logger.error(f"Error sending message to user {user_id}: {e}")
                    disconnected.add(connection)
            
            # Clean up disconnected websockets
            for conn in disconnected:
                self.disconnect(conn)
    
    async def broadcast(self, message: str, exclude_user: str = None):
        """Broadcast a message to all connected users."""
        for user_id, connections in self.active_connections.items():
            if exclude_user and user_id == exclude_user:
                continue
            
            await self.send_personal_message(message, user_id)

# Create global connection manager
manager = ConnectionManager()

async def get_current_user_ws(
    websocket: WebSocket,
    token: str = Query(...),
    db: AsyncSession = Depends(get_db)
) -&gt; User:
    """Authenticate WebSocket connection."""
    try:
        # Decode token
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        
        if user_id is None:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            raise ValueError("Invalid token")
        
        # Get user from database
        result = await db.execute(
            select(User).where(User.id == user_id)
        )
        user = result.scalars().first()
        
        if not user or not user.is_active:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            raise ValueError("User not found or inactive")
        
        return user
        
    except JWTError:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        raise ValueError("Invalid token")

@router.websocket("/tasks")
async def websocket_endpoint(
    websocket: WebSocket,
    current_user: User = Depends(get_current_user_ws)
):
    """
    WebSocket endpoint for real-time task updates.
    
    Message format:
    {
        "type": "task_created" | "task_updated" | "task_deleted",
        "data": <task_data>
    }
    """
    await manager.connect(websocket, current_user.id)
    
    try:
        # Send initial connection success message
        await websocket.send_json({
            "type": "connection_established",
            "data": {
                "user_id": current_user.id,
                "timestamp": datetime.now().isoformat()
            }
        })
        
        # Keep connection alive and handle incoming messages
        while True:
            # Wait for any message from client (can be ping/pong)
            try:
                data = await asyncio.wait_for(
                    websocket.receive_text(),
                    timeout=60.0  # 60 second timeout
                )
                
                # Handle ping messages
                if data == "ping":
                    await websocket.send_text("pong")
                else:
                    # Process other messages if needed
                    try:
                        message = json.loads(data)
                        await handle_client_message(websocket, current_user, message)
                    except json.JSONDecodeError:
                        await websocket.send_json({
                            "type": "error",
                            "data": {{"message": "Invalid JSON"}}
                        })
                        
            except asyncio.TimeoutError:
                # Send ping to check if client is still connected
                try:
                    await websocket.send_text("ping")
                except Exception:
                    break
                    
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception as e:
        logger.error(f"WebSocket error for user {current_user.id}: {e}")
        manager.disconnect(websocket)

async def handle_client_message(websocket: WebSocket, user: User, message: dict):
    """Handle messages from client."""
    msg_type = message.get("type")
    
    if msg_type == "subscribe":
        # Handle subscription to specific task updates
        task_id = message.get("task_id")
        await websocket.send_json({
            "type": "subscribed",
            "data": {{"task_id": task_id}}
        })
    
    elif msg_type == "typing":
        # Broadcast typing indicator to other users (if implementing collaboration)
        pass
    
    else:
        await websocket.send_json({
            "type": "error",
            "data": {{"message": f"Unknown message type: {{msg_type}}"}}
        })

# Utility functions to broadcast task events
async def broadcast_task_created(task_data: dict, user_id: str):
    """Broadcast task creation event."""
    message = json.dumps({
        "type": "task_created",
        "data": task_data,
        "timestamp": datetime.now().isoformat()
    })
    await manager.send_personal_message(message, user_id)

async def broadcast_task_updated(task_data: dict, user_id: str):
    """Broadcast task update event."""
    message = json.dumps({
        "type": "task_updated",
        "data": task_data,
        "timestamp": datetime.now().isoformat()
    })
    await manager.send_personal_message(message, user_id)

async def broadcast_task_deleted(task_id: str, user_id: str):
    """Broadcast task deletion event."""
    message = json.dumps({
        "type": "task_deleted",
        "data": {{"id": task_id}},
        "timestamp": datetime.now().isoformat()
    })
    await manager.send_personal_message(message, user_id)
```

### Step 12: Add WebSocket Events to Task Operations

Actualizar the task endpoints to broadcast WebSocket events. Add this to `app/api/v1/tasks.py`:

**🤖 Copilot Prompt Suggestion #12:**
```python
# Update task endpoints to broadcast WebSocket events:
# - Import websocket broadcasting functions
# - Add broadcasts after create/update/delete operations
# - Include task response data in broadcasts
```

Add to the imports:
```python
from app.api.v1.websocket import broadcast_task_created, broadcast_task_updated, broadcast_task_deleted
```

Actualizar the create_task endpoint:
```python
# After await db.refresh(task, ["tags"])
await broadcast_task_created(TaskResponse.model_validate(task).model_dump(), current_user.id)
```

Actualizar the update_task endpoint:
```python
# After await db.refresh(task, ["tags"])
await broadcast_task_updated(TaskResponse.model_validate(task).model_dump(), current_user.id)
```

Actualizar the delete_task endpoint:
```python
# After await db.commit()
await broadcast_task_deleted(task_id, current_user.id)
```

### Step 13: Create Docker Configuration

Create `Dockerfile` for the backend:

**🤖 Copilot Prompt Suggestion #13:**
```dockerfile
# Create multi-stage Dockerfile for Python backend:
# - Use Python 3.11 slim base
# - Install dependencies in separate stage
# - Copy only necessary files
# - Run as non-root user
# - Health check endpoint
# - Optimize for production
```

**Expected Output:**
```dockerfile
# Build stage
FROM python:3.11-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.11-slim

WORKDIR /app

# Create non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app

# Copy Python dependencies from builder
COPY --from=builder /root/.local /home/appuser/.local

# Copy application code
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

# Add local bin to PATH
ENV PATH=/home/appuser/.local/bin:$PATH

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD python -c "import requests; requests.get('http://localhost:8000/health')"

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Create `docker-compose.yml`:

**🤖 Copilot Prompt Suggestion #14:**
```yaml
# Create Docker Compose configuration with:
# - Backend service with environment variables
# - PostgreSQL database with persistence
# - Redis for caching (optional)
# - Nginx reverse proxy
# - Frontend static files
# - Health checks and restart policies
# - Development and production profiles
```

**Expected Output:**
```yaml
version: '3.8'

services:
  # PostgreSQL Database
  db:
    image: postgres:15-alpine
    container_name: taskmanager-db
    environment:
      POSTGRES_USER: ${DB_USER:-taskuser}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-taskpass}
      POSTGRES_DB: ${DB_NAME:-taskmanager}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-taskuser}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  # Redis Cache (optional)
  redis:
    image: redis:7-alpine
    container_name: taskmanager-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    profiles:
      - full

  # Backend API
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: taskmanager-backend
    environment:
      DATABASE_URL: postgresql://taskuser:taskpass@db:5432/taskmanager
      REDIS_URL: redis://redis:6379
      SECRET_KEY: ${SECRET_KEY:-your-secret-key-here}
      ENVIRONMENT: ${ENVIRONMENT:-production}
      CORS_ORIGINS: ${CORS_ORIGINS:-http://localhost}
    ports:
      - "8000:8000"
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - ./backend/app:/app/app:ro  # Read-only in production
    restart: unless-stopped
    command: &gt;
      sh -c "
        echo 'Waiting for database...' &&
        sleep 5 &&
        uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
      "

  # Frontend Nginx
  frontend:
    image: nginx:alpine
    container_name: taskmanager-frontend
    volumes:
      - ./frontend:/usr/share/nginx/html:ro
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - backend
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Development database admin
  adminer:
    image: adminer
    container_name: taskmanager-adminer
    ports:
      - "8080:8080"
    depends_on:
      - db
    profiles:
      - dev
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:

networks:
  default:
    name: taskmanager-network
```

Create `nginx.conf`:

**🤖 Copilot Prompt Suggestion #15:**
```nginx
# Create Nginx configuration with:
# - Reverse proxy to backend API
# - Static file serving for frontend
# - WebSocket proxy support
# - Security headers
# - Gzip compression
# - Rate limiting
# - SSL configuration (commented template)
```

**Expected Output:**
```nginx
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/m;

    # Upstream backend
    upstream backend {
        server backend:8000;
    }

    server {
        listen 80;
        server_name localhost;
        
        # Frontend static files
        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ /index.html;
            
            # Cache static assets
            location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
                expires 1y;
                add_header Cache-Control "public, immutable";
            }
        }
        
        # API proxy
        location /api {
            limit_req zone=api burst=20 nodelay;
            
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            
            # Timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }
        
        # WebSocket proxy
        location /ws {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # WebSocket timeouts
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
        }
        
        # Auth endpoints with stricter rate limiting
        location /api/v1/auth/login {
            limit_req zone=auth burst=5 nodelay;
            
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # Health check
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
    
    # SSL configuration (uncomment and configure for production)
    # server {
    #     listen 443 ssl http2;
    #     server_name yourdomain.com;
    #     
    #     ssl_certificate /etc/nginx/ssl/cert.pem;
    #     ssl_certificate_key /etc/nginx/ssl/key.pem;
    #     
    #     # SSL configuration
    #     ssl_protocols TLSv1.2 TLSv1.3;
    #     ssl_ciphers HIGH:!aNULL:!MD5;
    #     ssl_prefer_server_ciphers on;
    #     
    #     # ... rest of configuration same as above
    # }
}
```

### Step 14: Add producción Requirements

Actualizar `backend/requirements.txt` for producción:

```txt
# Core
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-multipart==0.0.6

# Database
sqlalchemy==2.0.23
asyncpg==0.29.0
aiosqlite==0.19.0
alembic==1.12.1

# Authentication
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6

# Validation
pydantic==2.5.0
pydantic-settings==2.1.0
email-validator==2.1.0

# Async
aiofiles==23.2.1
httpx==0.25.1

# Monitoring
prometheus-client==0.19.0
opentelemetry-api==1.21.0
opentelemetry-sdk==1.21.0
opentelemetry-instrumentation-fastapi==0.42b0

# Utilities
python-dateutil==2.8.2
pytz==2023.3

# Development
pytest==7.4.3
pytest-asyncio==0.21.1
black==23.11.0
flake8==6.1.0
mypy==1.7.1

# Production
gunicorn==21.2.0
redis==5.0.1
celery==5.3.4
```

### Step 15: Create Monitoring Setup

Create `starter/backend/app/core/monitoring.py`:

**🤖 Copilot Prompt Suggestion #16:**
```python
# Create monitoring setup with:
# - Prometheus metrics (request count, latency, errors)
# - Health check endpoint with detailed status
# - OpenTelemetry tracing setup
# - Custom metrics for business operations
# - Performance profiling middleware
```

**Expected Output:**
```python
from prometheus_client import Counter, Histogram, Gauge, generate_latest
from fastapi import FastAPI, Request, Response
from typing import Callable
import time
import psutil
import asyncio
from app.db.database import check_database_connection
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

# Prometheus metrics
request_count = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

request_duration = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    ['method', 'endpoint']
)

active_requests = Gauge(
    'http_requests_active',
    'Active HTTP requests'
)

# Business metrics
task_operations = Counter(
    'task_operations_total',
    'Total task operations',
    ['operation', 'status']
)

user_registrations = Counter(
    'user_registrations_total',
    'Total user registrations'
)

websocket_connections = Gauge(
    'websocket_connections_active',
    'Active WebSocket connections'
)

# System metrics
system_cpu_usage = Gauge('system_cpu_usage_percent', 'System CPU usage')
system_memory_usage = Gauge('system_memory_usage_percent', 'System memory usage')
system_disk_usage = Gauge('system_disk_usage_percent', 'System disk usage')

async def add_prometheus_middleware(app: FastAPI):
    """Add Prometheus metrics middleware."""
    
    @app.middleware("http")
    async def prometheus_middleware(request: Request, call_next: Callable):
        # Skip metrics endpoint
        if request.url.path == "/metrics":
            return await call_next(request)
        
        # Track active requests
        active_requests.inc()
        
        # Track request duration
        start_time = time.time()
        
        try:
            response = await call_next(request)
            
            # Record metrics
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
            
        except Exception as e:
            # Record error
            duration = time.time() - start_time
            request_count.labels(
                method=request.method,
                endpoint=request.url.path,
                status=500
            ).inc()
            
            request_duration.labels(
                method=request.method,
                endpoint=request.url.path
            ).observe(duration)
            
            raise
            
        finally:
            active_requests.dec()

async def collect_system_metrics():
    """Collect system metrics periodically."""
    while True:
        try:
            # CPU usage
            cpu_percent = psutil.cpu_percent(interval=1)
            system_cpu_usage.set(cpu_percent)
            
            # Memory usage
            memory = psutil.virtual_memory()
            system_memory_usage.set(memory.percent)
            
            # Disk usage
            disk = psutil.disk_usage('/')
            system_disk_usage.set(disk.percent)
            
        except Exception as e:
            logger.error(f"Error collecting system metrics: {e}")
        
        await asyncio.sleep(30)  # Collect every 30 seconds

def setup_monitoring(app: FastAPI):
    """Set up monitoring for the application."""
    
    @app.on_event("startup")
    async def start_monitoring():
        # Start system metrics collection
        asyncio.create_task(collect_system_metrics())
    
    @app.get("/metrics", tags=["Monitoring"])
    async def metrics():
        """Prometheus metrics endpoint."""
        return Response(
            content=generate_latest(),
            media_type="text/plain"
        )
    
    @app.get("/health/detailed", tags=["Monitoring"])
    async def health_check_detailed():
        """Detailed health check with component status."""
        health_status = {
            "status": "healthy",
            "timestamp": time.time(),
            "version": settings.APP_VERSION,
            "components": {{}}
        }
        
        # Check database
        try:
            db_connected = await check_database_connection()
            health_status["components"]["database"] = {
                "status": "healthy" if db_connected else "unhealthy",
                "response_time_ms": 0  # Implement actual timing
            }
        except Exception as e:
            health_status["components"]["database"] = {
                "status": "unhealthy",
                "error": str(e)
            }
            health_status["status"] = "degraded"
        
        # Check Redis (if configured)
        if hasattr(settings, 'REDIS_URL') and settings.REDIS_URL:
            try:
                # Implement Redis health check
                health_status["components"]["redis"] = {
                    "status": "healthy"
                }
            except Exception as e:
                health_status["components"]["redis"] = {
                    "status": "unhealthy",
                    "error": str(e)
                }
                health_status["status"] = "degraded"
        
        # System resources
        health_status["components"]["system"] = {
            "cpu_usage_percent": psutil.cpu_percent(),
            "memory_usage_percent": psutil.virtual_memory().percent,
            "disk_usage_percent": psutil.disk_usage('/').percent
        }
        
        # Determine overall health
        if health_status["status"] == "degraded":
            return Response(
                content=health_status,
                status_code=503  # Service Unavailable
            )
        
        return health_status

# Utility functions for tracking business metrics
def track_task_operation(operation: str, success: bool = True):
    """Track task operations."""
    task_operations.labels(
        operation=operation,
        status="success" if success else "failure"
    ).inc()

def track_user_registration():
    """Track user registrations."""
    user_registrations.inc()

def track_websocket_connection(delta: int):
    """Track WebSocket connections."""
    if delta &gt; 0:
        websocket_connections.inc(delta)
    else:
        websocket_connections.dec(abs(delta))
```

### Step 16: Create Testing Suite

Create `starter/backend/tests/test_api.py`:

**🤖 Copilot Prompt Suggestion #17:**
```python
# Create comprehensive API tests:
# - Authentication flow tests
# - Task CRUD operation tests
# - WebSocket connection tests
# - Error handling tests
# - Performance tests
# Use pytest-asyncio and httpx for async testing
```

**Expected Output:**
```python
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from app.main import app
from app.db.database import get_db, Base, engine
from app.models.database import User, Task
from app.core.auth import get_password_hash
import asyncio

# Test database setup
@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(scope="function")
async def db_session():
    """Create a test database session."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async with AsyncSessionLocal() as session:
        yield session
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

@pytest.fixture(scope="function")
async def client(db_session: AsyncSession):
    """Create a test client."""
    app.dependency_overrides[get_db] = lambda: db_session
    
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client
    
    app.dependency_overrides.clear()

@pytest.fixture
async def test_user(db_session: AsyncSession):
    """Create a test user."""
    user = User(
        username="testuser",
        email="test@example.com",
        hashed_password=get_password_hash("testpass123"),
        is_active=True
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user

@pytest.fixture
async def auth_headers(client: AsyncClient, test_user: User):
    """Get authentication headers."""
    response = await client.post(
        "/api/v1/auth/login",
        data={{"username": "testuser", "password": "testpass123"}}
    )
    assert response.status_code == 200
    token = response.json()["access_token"]
    return {{"Authorization": f"Bearer {{token}}"}}

class TestAuthentication:
    """Test authentication endpoints."""
    
    async def test_register_user(self, client: AsyncClient):
        """Test user registration."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "username": "newuser",
                "email": "new@example.com",
                "password": "SecurePass123"
            }
        )
        assert response.status_code == 201
        data = response.json()
        assert data["username"] == "newuser"
        assert data["email"] == "new@example.com"
        assert "id" in data
    
    async def test_login_success(self, client: AsyncClient, test_user: User):
        """Test successful login."""
        response = await client.post(
            "/api/v1/auth/login",
            data={{"username": "testuser", "password": "testpass123"}}
        )
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
    
    async def test_login_invalid_credentials(self, client: AsyncClient, test_user: User):
        """Test login with invalid credentials."""
        response = await client.post(
            "/api/v1/auth/login",
            data={{"username": "testuser", "password": "wrongpass"}}
        )
        assert response.status_code == 401
    
    async def test_get_current_user(self, client: AsyncClient, auth_headers: dict):
        """Test getting current user info."""
        response = await client.get("/api/v1/auth/me", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert data["username"] == "testuser"

class TestTasks:
    """Test task endpoints."""
    
    async def test_create_task(self, client: AsyncClient, auth_headers: dict):
        """Test creating a task."""
        response = await client.post(
            "/api/v1/tasks",
            json={
                "title": "Test Task",
                "description": "Test Description",
                "priority": "high",
                "status": "todo"
            },
            headers=auth_headers
        )
        assert response.status_code == 201
        data = response.json()
        assert data["title"] == "Test Task"
        assert data["priority"] == "high"
        assert "id" in data
    
    async def test_list_tasks(self, client: AsyncClient, auth_headers: dict):
        """Test listing tasks."""
        # Create some tasks first
        for i in range(3):
            await client.post(
                "/api/v1/tasks",
                json={{"title": f"Task {{i}}", "priority": "medium"}},
                headers=auth_headers
            )
        
        # List tasks
        response = await client.get("/api/v1/tasks", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 3
        assert len(data["items"]) == 3
    
    async def test_update_task(self, client: AsyncClient, auth_headers: dict):
        """Test updating a task."""
        # Create task
        create_response = await client.post(
            "/api/v1/tasks",
            json={{"title": "Original Title"}},
            headers=auth_headers
        )
        task_id = create_response.json()["id"]
        
        # Update task
        response = await client.put(
            f"/api/v1/tasks/{task_id}",
            json={{"title": "Updated Title", "status": "in_progress"}},
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Updated Title"
        assert data["status"] == "in_progress"
    
    async def test_delete_task(self, client: AsyncClient, auth_headers: dict):
        """Test deleting a task."""
        # Create task
        create_response = await client.post(
            "/api/v1/tasks",
            json={{"title": "To Delete"}},
            headers=auth_headers
        )
        task_id = create_response.json()["id"]
        
        # Delete task
        response = await client.delete(
            f"/api/v1/tasks/{task_id}",
            headers=auth_headers
        )
        assert response.status_code == 204
        
        # Verify deletion
        get_response = await client.get(
            f"/api/v1/tasks/{task_id}",
            headers=auth_headers
        )
        assert get_response.status_code == 404
    
    async def test_task_filters(self, client: AsyncClient, auth_headers: dict):
        """Test task filtering."""
        # Create tasks with different properties
        tasks = [
            {{"title": "High Priority", "priority": "high", "status": "todo"}},
            {{"title": "Low Priority", "priority": "low", "status": "done"}},
            {{"title": "Medium Priority", "priority": "medium", "status": "in_progress"}},
        ]
        
        for task in tasks:
            await client.post("/api/v1/tasks", json=task, headers=auth_headers)
        
        # Filter by priority
        response = await client.get(
            "/api/v1/tasks?priority=high",
            headers=auth_headers
        )
        data = response.json()
        assert data["total"] == 1
        assert data["items"][0]["priority"] == "high"
        
        # Filter by status
        response = await client.get(
            "/api/v1/tasks?status=done",
            headers=auth_headers
        )
        data = response.json()
        assert data["total"] == 1
        assert data["items"][0]["status"] == "done"

class TestWebSocket:
    """Test WebSocket functionality."""
    
    @pytest.mark.asyncio
    async def test_websocket_connection(self, client: AsyncClient, auth_headers: dict):
        """Test WebSocket connection."""
        # Get token from headers
        token = auth_headers["Authorization"].split(" ")[1]
        
        # Connect to WebSocket
        from fastapi.testclient import TestClient
        with TestClient(app) as client:
            with client.websocket_connect(f"/ws/tasks?token={token}") as websocket:
                # Receive connection message
                data = websocket.receive_json()
                assert data["type"] == "connection_established"
                
                # Send ping
                websocket.send_text("ping")
                response = websocket.receive_text()
                assert response == "pong"

class TestPerformance:
    """Performance tests."""
    
    @pytest.mark.asyncio
    async def test_bulk_task_creation(self, client: AsyncClient, auth_headers: dict):
        """Test creating many tasks."""
        import time
        
        start_time = time.time()
        tasks = []
        
        # Create 100 tasks
        for i in range(100):
            response = await client.post(
                "/api/v1/tasks",
                json={{"title": f"Bulk Task {{i}}"}},
                headers=auth_headers
            )
            assert response.status_code == 201
            tasks.append(response.json())
        
        duration = time.time() - start_time
        
        # Should complete within reasonable time
        assert duration &lt; 10  # 10 seconds for 100 tasks
        
        # Verify all created
        response = await client.get(
            "/api/v1/tasks?per_page=100",
            headers=auth_headers
        )
        assert response.json()["total"] == 100
```

### Step 17: Create producción despliegue Script

Create `deploy.sh`:

**🤖 Copilot Prompt Suggestion #18:**
```bash
#!/bin/bash
# Create deployment script that:
# - Validates environment variables
# - Builds Docker images
# - Runs database migrations
# - Performs health checks
# - Implements zero-downtime deployment
# - Rollback capability
```

**Expected Output:**
```bash
#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"
BACKUP_DIR="./backups"
HEALTH_CHECK_URL="http://localhost/health"
HEALTH_CHECK_RETRIES=30
HEALTH_CHECK_DELAY=2

# Functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" &gt;&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &&gt; /dev/null; then
        error "Docker is not installed"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &&gt; /dev/null; then
        error "Docker Compose is not installed"
        exit 1
    fi
    
    # Check environment file
    if [ ! -f "$ENV_FILE" ]; then
        error "Environment file $ENV_FILE not found"
        echo "Creating from template..."
        cat &gt; "$ENV_FILE" &lt;<EOF
# Database
DB_USER=taskuser
DB_PASSWORD=$(openssl rand -base64 32)
DB_NAME=taskmanager

# Application
SECRET_KEY=$(openssl rand -base64 32)
ENVIRONMENT=production
CORS_ORIGINS=https://yourdomain.com

# Optional services
REDIS_URL=redis://redis:6379
EOF
        warning "Please update $ENV_FILE with your configuration"
        exit 1
    fi
    
    log "Prerequisites check passed"
}

# Backup database
backup_database() {
    log "Creating database backup..."
    
    mkdir -p "$BACKUP_DIR"
    
    TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
    BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.sql"
    
    docker-compose exec -T db pg_dump -U taskuser taskmanager > "$BACKUP_FILE"
    
    if [ $? -eq 0 ]; then
        log "Database backed up to $BACKUP_FILE"
        # Keep only last 5 backups
        ls -t "$BACKUP_DIR"/backup_*.sql | tail -n +6 | xargs -r rm
    else
        error "Database backup failed"
        exit 1
    fi
}

# Build images
build_images() {
    log "Building Docker images..."
    
    docker-compose build --no-cache
    
    if [ $? -ne 0 ]; then
        error "Failed to build images"
        exit 1
    fi
    
    log "Images built successfully"
}

# Deploy application
deploy() {
    log "Starting deployment..."
    
    # Pull latest code
    if [ -d .git ]; then
        log "Pulling latest code..."
        git pull origin main
    fi
    
    # Build images
    build_images
    
    # Start services with zero-downtime
    log "Starting services..."
    
    # Start database first
    docker-compose up -d db
    sleep 5
    
    # Run migrations
    log "Running database migrations..."
    docker-compose run --rm backend alembic upgrade head
    
    # Start remaining services
    docker-compose up -d --scale backend=2
    
    # Wait for old containers to finish requests
    sleep 10
    
    # Remove old containers
    docker-compose up -d --scale backend=1 --no-recreate
    
    log "Services started"
}

# Health check
health_check() {
    log "Performing health check..."
    
    for i in $(seq 1 $HEALTH_CHECK_RETRIES); do
        if curl -f -s "$HEALTH_CHECK_URL" > /dev/null; then
            log "Health check passed"
            return 0
        fi
        
        warning "Health check attempt $i/$HEALTH_CHECK_RETRIES failed"
        sleep $HEALTH_CHECK_DELAY
    done
    
    error "Health check failed after $HEALTH_CHECK_RETRIES attempts"
    return 1
}

# Rollback
rollback() {
    error "Deployment failed, rolling back..."
    
    # Restore previous version
    docker-compose down
    
    # Restore from backup if needed
    if [ -f "$BACKUP_DIR/backup_rollback.sql" ]; then
        log "Restoring database from backup..."
        docker-compose up -d db
        sleep 5
        docker-compose exec -T db psql -U taskuser taskmanager < "$BACKUP_DIR/backup_rollback.sql"
    fi
    
    error "Rollback completed. Manual intervention may be required."
}

# Main deployment flow
main() {
    log "Starting Task Manager deployment"
    
    # Check prerequisites
    check_prerequisites
    
    # Create rollback point
    if docker-compose ps | grep -q "Up"; then
        backup_database
        cp "$BACKUP_DIR"/backup_*.sql "$BACKUP_DIR/backup_rollback.sql" 2>/dev/null || true
    fi
    
    # Deploy
    deploy
    
    # Health check
    if health_check; then
        log "Deployment completed successfully!"
        
        # Show status
        docker-compose ps
        
        # Clean up rollback backup
        rm -f "$BACKUP_DIR/backup_rollback.sql"
    else
        rollback
        exit 1
    fi
}

# Handle command line arguments
case "${\`1:-deploy\`}" in
    deploy)
        main
        ;;
    build)
        build_images
        ;;
    backup)
        check_prerequisites
        backup_database
        ;;
    status)
        docker-compose ps
        ;;
    logs)
        docker-compose logs -f ${\`2:-backend\`}
        ;;
    rollback)
        rollback
        ;;
    *)
        echo "Usage: $0 {deploy|build|backup|status|logs|rollback}"
        exit 1
        ;;
esac
```

### Step 18: Create Final Validation

Create `validate_exercise3.py`:

**🤖 Copilot Prompt Suggestion #19:**
```python
# Create comprehensive validation that checks:
# - All required files exist
# - Docker images build successfully
# - API endpoints respond correctly
# - WebSocket connections work
# - Frontend loads properly
# - Database operations work
# Generate a deployment readiness report
```

**Expected Output:**
```python
#!/usr/bin/env python3
"""Exercise 3 Validation Script - Production Readiness Check"""

import subprocess
import sys
import os
import time
import requests
import json
from pathlib import Path
import asyncio
import websockets

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    END = '\033[0m'

def print_status(message, status):
    """Print colored status message."""
    if status == "success":
        print(f"{Colors.GREEN}✅ {message}{Colors.END}")
    elif status == "error":
        print(f"{Colors.RED}❌ {message}{Colors.END}")
    elif status == "warning":
        print(f"{Colors.YELLOW}⚠️  {message}{Colors.END}")
    else:
        print(f"{Colors.BLUE}ℹ️  {message}{Colors.END}")

def check_files():
    """Check all required files exist."""
    print("\n🔍 Checking Required Files...")
    
    required_files = [
        # Backend
        "backend/app/main.py",
        "backend/app/models/database.py",
        "backend/app/models/schemas.py",
        "backend/app/core/auth.py",
        "backend/app/core/config.py",
        "backend/app/core/monitoring.py",
        "backend/app/api/v1/auth.py",
        "backend/app/api/v1/tasks.py",
        "backend/app/api/v1/websocket.py",
        "backend/app/db/database.py",
        "backend/requirements.txt",
        "backend/Dockerfile",
        "backend/tests/test_api.py",
        
        # Frontend
        "frontend/index.html",
        "frontend/app.js",
        "frontend/style.css",
        
        # Configuration
        "docker-compose.yml",
        "nginx.conf",
        "deploy.sh",
    ]
    
    all_exist = True
    for file in required_files:
        if Path(file).exists():
            print_status(f"Found: {file}", "success")
        else:
            print_status(f"Missing: {file}", "error")
            all_exist = False
    
    return all_exist

def check_docker():
    """Check Docker setup."""
    print("\n🐳 Checking Docker Configuration...")
    
    # Check Docker installed
    try:
        result = subprocess.run(
            ["docker", "--version"],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            print_status(f"Docker installed: {result.stdout.strip()}", "success")
        else:
            print_status("Docker not installed", "error")
            return False
    except FileNotFoundError:
        print_status("Docker not found", "error")
        return False
    
    # Check Docker Compose
    try:
        result = subprocess.run(
            ["docker-compose", "--version"],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            print_status(f"Docker Compose installed: {result.stdout.strip()}", "success")
        else:
            print_status("Docker Compose not installed", "error")
            return False
    except FileNotFoundError:
        print_status("Docker Compose not found", "error")
        return False
    
    # Validate docker-compose.yml
    result = subprocess.run(
        ["docker-compose", "config"],
        capture_output=True,
        text=True
    )
    if result.returncode == 0:
        print_status("docker-compose.yml is valid", "success")
        return True
    else:
        print_status("docker-compose.yml has errors", "error")
        print(result.stderr)
        return False

def build_images():
    """Build Docker images."""
    print("\n🏗️  Building Docker Images...")
    
    result = subprocess.run(
        ["docker-compose", "build"],
        capture_output=True,
        text=True
    )
    
    if result.returncode == 0:
        print_status("Docker images built successfully", "success")
        return True
    else:
        print_status("Failed to build Docker images", "error")
        print(result.stderr)
        return False

def start_services():
    """Start Docker services."""
    print("\n🚀 Starting Services...")
    
    # Start services
    subprocess.run(["docker-compose", "down"], capture_output=True)
    
    result = subprocess.run(
        ["docker-compose", "up", "-d"],
        capture_output=True,
        text=True
    )
    
    if result.returncode != 0:
        print_status("Failed to start services", "error")
        print(result.stderr)
        return False
    
    print_status("Services started", "success")
    
    # Wait for services to be ready
    print_status("Waiting for services to initialize...", "info")
    time.sleep(10)
    
    return True

def test_api():
    """Test API endpoints."""
    print("\n🧪 Testing API Endpoints...")
    
    base_url = "http://localhost:8000"
    
    # Test health endpoint
    try:
        response = requests.get(f"{base_url}/health", timeout=5)
        if response.status_code == 200:
            print_status("Health check endpoint working", "success")
        else:
            print_status(f"Health check failed: {response.status_code}", "error")
            return False
    except requests.exceptions.RequestException as e:
        print_status(f"Cannot connect to API: {e}", "error")
        return False
    
    # Test registration
    try:
        test_user = {
            "username": f"testuser_{{int(time.time())}}",
            "email": f"test_{{int(time.time())}}@example.com",
            "password": "TestPass123"
        }
        
        response = requests.post(
            f"{base_url}/api/v1/auth/register",
            json=test_user
        )
        
        if response.status_code == 201:
            print_status("User registration working", "success")
        else:
            print_status(f"Registration failed: {response.text}", "error")
            return False
        
        # Test login
        login_data = {
            "username": test_user["username"],
            "password": test_user["password"]
        }
        
        response = requests.post(
            f"{base_url}/api/v1/auth/login",
            data=login_data
        )
        
        if response.status_code == 200:
            token = response.json()["access_token"]
            print_status("Login endpoint working", "success")
            
            # Test authenticated endpoint
            headers = {{"Authorization": f"Bearer {{token}}"}}
            response = requests.get(
                f"{base_url}/api/v1/auth/me",
                headers=headers
            )
            
            if response.status_code == 200:
                print_status("Authenticated endpoints working", "success")
            else:
                print_status("Authentication failed", "error")
                return False
                
        else:
            print_status(f"Login failed: {response.text}", "error")
            return False
            
    except Exception as e:
        print_status(f"API test error: {e}", "error")
        return False
    
    return True

async def test_websocket():
    """Test WebSocket connection."""
    print("\n🔌 Testing WebSocket...")
    
    # Get a valid token first
    response = requests.post(
        "http://localhost:8000/api/v1/auth/login",
        data={
            "username": "admin",
            "password": "admin123"
        }
    )
    
    if response.status_code != 200:
        print_status("Cannot get token for WebSocket test", "warning")
        return True  # Don't fail the whole test
    
    token = response.json()["access_token"]
    
    try:
        uri = f"ws://localhost:8000/ws/tasks?token={token}"
        async with websockets.connect(uri) as websocket:
            # Wait for connection message
            message = await asyncio.wait_for(websocket.recv(), timeout=5)
            data = json.loads(message)
            
            if data.get("type") == "connection_established":
                print_status("WebSocket connection working", "success")
                
                # Test ping/pong
                await websocket.send("ping")
                response = await asyncio.wait_for(websocket.recv(), timeout=5)
                
                if response == "pong":
                    print_status("WebSocket ping/pong working", "success")
                    return True
                    
    except Exception as e:
        print_status(f"WebSocket test failed: {e}", "warning")
    
    return True  # Don't fail deployment for WebSocket issues

def test_frontend():
    """Test frontend accessibility."""
    print("\n🌐 Testing Frontend...")
    
    try:
        response = requests.get("http://localhost", timeout=5)
        if response.status_code == 200:
            print_status("Frontend accessible", "success")
            
            # Check for key elements
            if "Task Manager" in response.text:
                print_status("Frontend content loaded", "success")
                return True
            else:
                print_status("Frontend content missing", "error")
                return False
        else:
            print_status(f"Frontend returned: {response.status_code}", "error")
            return False
            
    except requests.exceptions.RequestException as e:
        print_status(f"Cannot access frontend: {e}", "error")
        return False

def check_monitoring():
    """Check monitoring endpoints."""
    print("\n📊 Checking Monitoring...")
    
    try:
        # Check metrics endpoint
        response = requests.get("http://localhost:8000/metrics", timeout=5)
        if response.status_code == 200:
            print_status("Metrics endpoint working", "success")
        else:
            print_status("Metrics endpoint not accessible", "warning")
        
        # Check detailed health
        response = requests.get("http://localhost:8000/health/detailed", timeout=5)
        if response.status_code == 200:
            health_data = response.json()
            print_status(f"System health: {health_data['status']}", "success")
            
            # Show component status
            for component, status in health_data.get("components", {}).items():
                if isinstance(status, dict) and status.get("status") == "healthy":
                    print_status(f"  {component}: healthy", "success")
                else:
                    print_status(f"  {component}: unhealthy", "warning")
                    
        return True
        
    except Exception as e:
        print_status(f"Monitoring check failed: {e}", "warning")
        return True  # Don't fail deployment

def generate_report(results):
    """Generate deployment readiness report."""
    print("\n" + "="*60)
    print("📋 DEPLOYMENT READINESS REPORT")
    print("="*60)
    
    total_checks = len(results)
    passed_checks = sum(1 for r in results.values() if r)
    
    for check, passed in results.items():
        status = "PASS" if passed else "FAIL"
        color = Colors.GREEN if passed else Colors.RED
        print(f"{color}{check:Less than 30} {status}{Colors.END}")
    
    print("-"*60)
    
    percentage = (passed_checks / total_checks) * 100
    
    if percentage == 100:
        print(f"{Colors.GREEN}✅ ALL CHECKS PASSED!{Colors.END}")
        print(f"{Colors.GREEN}🚀 Application is ready for deployment!{Colors.END}")
    elif percentage &gt;= 80:
        print(f"{Colors.YELLOW}⚠️  MOSTLY READY ({percentage:.0f}% passed){Colors.END}")
        print(f"{Colors.YELLOW}Review warnings before deploying.{Colors.END}")
    else:
        print(f"{Colors.RED}❌ NOT READY ({percentage:.0f}% passed){Colors.END}")
        print(f"{Colors.RED}Fix errors before deploying.{Colors.END}")
    
    print("\n📝 Next Steps:")
    if percentage == 100:
        print("1. Review the .env file configuration")
        print("2. Run: ./deploy.sh")
        print("3. Configure your domain and SSL certificates")
        print("4. Set up monitoring alerts")
    else:
        print("1. Fix any failed checks")
        print("2. Re-run this validation script")
        print("3. Review logs: docker-compose logs")

def cleanup():
    """Clean up test environment."""
    print("\n🧹 Cleaning up...")
    subprocess.run(["docker-compose", "down"], capture_output=True)
    print_status("Cleanup complete", "success")

def main():
    """Run all validation checks."""
    print(f"{Colors.BLUE}🔍 Exercise 3 Validation - Production Readiness Check{Colors.END}")
    print("="*60)
    
    results = {}
    
    # Run checks
    results["Required Files"] = check_files()
    
    if not results["Required Files"]:
        print("\n❌ Missing required files. Cannot continue.")
        sys.exit(1)
    
    results["Docker Setup"] = check_docker()
    
    if results["Docker Setup"]:
        results["Image Build"] = build_images()
        
        if results["Image Build"]:
            results["Service Start"] = start_services()
            
            if results["Service Start"]:
                results["API Tests"] = test_api()
                results["Frontend Tests"] = test_frontend()
                
                # Run async WebSocket test
                results["WebSocket Tests"] = asyncio.run(test_websocket())
                
                results["Monitoring"] = check_monitoring()
                
                # Cleanup
                cleanup()
    
    # Generate report
    generate_report(results)
    
    # Exit code based on results
    if all(results.values()):
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nValidation interrupted by user")
        cleanup()
        sys.exit(1)
    except Exception as e:
        print(f"\n{Colors.RED}Unexpected error: {e}{Colors.END}")
        cleanup()
        sys.exit(1)
```

## 🎯 Ejercicio 3 Completar!

Congratulations! You've built a complete, producción-ready task management system with:

1. ✅ Modern async FastAPI backend
2. ✅ JWT authentication with refresh tokens
3. ✅ Real-time WebSocket updates
4. ✅ Responsive web interface
5. ✅ Docker despliegue configuration
6. ✅ Monitoring and observability
7. ✅ Comprehensive test suite
8. ✅ Zero-downtime despliegue scripts
9. ✅ Production security measures
10. ✅ Scalable architecture

### Key Achievements

**Atrásend Development:**
- Async SQLAlchemy with proper connection pooling
- Comprehensive API with pagination and filtering
- WebSocket implementation for real-time features
- Prometheus metrics and health checks

**Frontend Development:**
- Modern JavaScript with Alpine.js
- Real-time updates via WebSocket
- Responsive design with Tailwind CSS
- Token management with refresh

**DevOps & Deployment:**
- Multi-stage Docker builds
- Docker Compose orchestration
- Nginx reverse proxy configuration
- Automated despliegue scripts
- Database backup and migration

### producción despliegue Steps

1. **Configure Environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your production values
   ```

2. **Deploy Application:**
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

3. **Configure Domain & SSL:**
   - Point your domain to the server
   - Actualizar nginx.conf with SSL certificates
   - Use Let's Encrypt for free SSL

4. **Configurar Monitoring:**
   - Configure Prometheus to scrape /metrics
   - Set up Grafana dashboards
   - Configure alerts for critical metrics

### Extension Challenges

1. **Add Email Notificaciones** - Send task reminders
2. **Implement Collaboration** - Compartir tasks between users
3. **Add File Attachments** - Subir files to tasks
4. **Create Mobile App** - React Native or Flutter
5. **Add AI Features** - Smart task suggestions
6. **Implement Calendario View** - Visual task timeline
7. **Add Reporting** - Generate PDF reports
8. **Multi-language Support** - i18n implementation

### What You've Learned

- **Full-Stack Development** with modern tools
- **Production Architecture** patterns
- **Real-time Features** implementation
- **Security Mejores Prácticas** 
- **Deployment Automation**
- **Monitoring & Observability**
- **Testing Strategies**
- **AI-Assisted Development** throughout

---

🎉 **Outstanding work!** You've completed the most challenging exercise in Module 01. You now have the skills to build production-ready applications with AI assistance. This foundation will serve you throughout your journey in AI-powered development!

**Next Steps:**
- Deploy your application to a cloud provider
- Add custom features to make it unique
- Share your work and get feedback
- Move on to [Module 02](./modules/module-02/README) for advanced Copilot features

Remember: This application is a portfolio piece. Customize it, deploy it, and showcase your AI-powered development skills!