# Exercise 3: AI Operations Dashboard (Part 3)

## 📋 Step 3: API Implementation (15 minutes)

### 3.1 Authentication API with Roles

Create `backend/app/api/v1/auth.py`:

**Copilot Prompt Suggestion:**
```python
# Create authentication API with role-based access:
# - POST /register - Register with role assignment
# - POST /login - Login returns JWT with role
# - GET /me - Get current user with permissions
# - POST /api-key - Generate API key for programmatic access
# - Role-based middleware for admin endpoints
# Include audit logging for security events
```

**Expected Copilot Output:**
```python
from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import timedelta
import secrets

from ...core.database import get_async_db
from ...core.security import (
    get_password_hash, 
    verify_password, 
    create_access_token,
    get_current_user
)
from ...models.models import User, UserRole, AuditLog
from ...schemas.schemas import (
    UserCreate, UserResponse, Token, 
    UserWithRole, APIKeyResponse
)

router = APIRouter(prefix="/auth", tags=["authentication"])

async def log_audit(
    db: AsyncSession,
    user_id: int,
    action: str,
    details: dict,
    request: Request
):
    """Log security audit event"""
    audit = AuditLog(
        user_id=user_id,
        action=action,
        resource_type="auth",
        details=details,
        ip_address=request.client.host,
        user_agent=request.headers.get("user-agent")
    )
    db.add(audit)
    await db.commit()

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(
    user_data: UserCreate,
    request: Request,
    db: AsyncSession = Depends(get_async_db)
):
    """Register new user with role"""
    # Check if user exists
    result = await db.execute(
        select(User).where(
            (User.username == user_data.username) | 
            (User.email == user_data.email)
        )
    )
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username or email already registered"
        )
    
    # Create user with default viewer role
    db_user = User(
        username=user_data.username,
        email=user_data.email,
        hashed_password=get_password_hash(user_data.password),
        role=user_data.role if hasattr(user_data, 'role') else UserRole.VIEWER
    )
    
    db.add(db_user)
    await db.commit()
    await db.refresh(db_user)
    
    # Log registration
    await log_audit(
        db, db_user.id, "user_registered", 
        {"username": db_user.username, "role": db_user.role},
        request
    )
    
    return db_user

@router.post("/login", response_model=Token)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    request: Request = None,
    db: AsyncSession = Depends(get_async_db)
):
    """Login and get access token with role"""
    # Authenticate user
    result = await db.execute(
        select(User).where(User.username == form_data.username)
    )
    user = result.scalar_one_or_none()
    
    if not user or not verify_password(form_data.password, user.hashed_password):
        # Log failed attempt
        if user:
            await log_audit(
                db, user.id, "login_failed", 
                {"reason": "invalid_password"},
                request
            )
        
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    
    # Create access token with role
    access_token = create_access_token(
        data={
            "sub": user.username,
            "role": user.role,
            "user_id": user.id
        }
    )
    
    # Update last login
    user.last_login = datetime.utcnow()
    await db.commit()
    
    # Log successful login
    await log_audit(
        db, user.id, "login_success", 
        {"role": user.role},
        request
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "role": user.role
    }

@router.get("/me", response_model=UserWithRole)
async def get_current_user_info(
    current_user: User = Depends(get_current_user)
):
    """Get current user with permissions"""
    permissions = {
        UserRole.ADMIN: [
            "agents:*", "deployments:*", "users:*", 
            "alerts:*", "settings:*"
        ],
        UserRole.DEVELOPER: [
            "agents:create", "agents:read", "agents:update", 
            "agents:delete:own", "deployments:*", "alerts:read"
        ],
        UserRole.VIEWER: [
            "agents:read", "deployments:read", "alerts:read"
        ]
    }
    
    return UserWithRole(
        **current_user.__dict__,
        permissions=permissions.get(current_user.role, [])
    )

@router.post("/api-key", response_model=APIKeyResponse)
async def generate_api_key(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db)
):
    """Generate API key for programmatic access"""
    # Generate secure API key
    api_key = secrets.token_urlsafe(32)
    
    # Store hashed version
    current_user.api_key = get_password_hash(api_key)
    await db.commit()
    
    # Log API key generation
    await log_audit(
        db, current_user.id, "api_key_generated", 
        {"purpose": "programmatic_access"},
        None
    )
    
    return APIKeyResponse(
        api_key=api_key,
        message="Store this key securely. It won't be shown again."
    )

# Role-based dependency
def require_role(allowed_roles: List[UserRole]):
    async def role_checker(current_user: User = Depends(get_current_user)):
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions"
            )
        return current_user
    return role_checker

# Admin only dependency
require_admin = require_role([UserRole.ADMIN])
require_developer = require_role([UserRole.ADMIN, UserRole.DEVELOPER])
```

### 3.2 Agent API Endpoints

Create `backend/app/api/v1/agents.py`:

**Copilot Prompt Suggestion:**
```python
# Create agent management API:
# - GET /agents - List agents with filtering
# - POST /agents - Create new agent
# - GET /agents/{id} - Get agent details with health
# - PUT /agents/{id} - Update agent configuration
# - DELETE /agents/{id} - Delete agent
# - POST /agents/{id}/start - Start agent
# - POST /agents/{id}/stop - Stop agent
# - POST /agents/{id}/scale - Scale agent replicas
# - GET /agents/{id}/metrics - Get agent metrics
# - GET /agents/{id}/logs - Stream agent logs
# Include role-based access and ownership checks
```

**Expected Copilot Output:**
```python
from fastapi import APIRouter, Depends, HTTPException, status, Query, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from typing import List, Optional
from datetime import datetime, timedelta

from ...core.database import get_async_db
from ...models.models import Agent, AgentStatus, User, UserRole, Metric
from ...schemas.schemas import (
    AgentCreate, AgentUpdate, AgentResponse, 
    AgentListResponse, AgentHealth, MetricsResponse,
    ScaleRequest
)
from ...services.agent_service import agent_service
from ...services.metrics_service import metrics_service
from ..v1.auth import get_current_user, require_developer

router = APIRouter(prefix="/agents", tags=["agents"])

@router.get("", response_model=AgentListResponse)
async def list_agents(
    status: Optional[AgentStatus] = None,
    type: Optional[str] = None,
    owner_id: Optional[int] = None,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db)
):
    """List agents with filtering"""
    # Build query
    query = select(Agent)
    
    # Apply filters based on user role
    if current_user.role == UserRole.VIEWER:
        # Viewers see all agents
        pass
    elif current_user.role == UserRole.DEVELOPER:
        # Developers see their own agents
        query = query.where(Agent.owner_id == current_user.id)
    
    # Apply additional filters
    if status:
        query = query.where(Agent.status == status)
    if type:
        query = query.where(Agent.type == type)
    if owner_id and current_user.role == UserRole.ADMIN:
        query = query.where(Agent.owner_id == owner_id)
    
    # Get total count
    count_result = await db.execute(
        select(func.count()).select_from(query.subquery())
    )
    total = count_result.scalar()
    
    # Apply pagination
    query = query.offset((page - 1) * per_page).limit(per_page)
    
    # Execute query
    result = await db.execute(query)
    agents = result.scalars().all()
    
    # Get health status for each agent
    agent_responses = []
    for agent in agents:
        health = await agent_service.get_agent_health(agent)
        agent_responses.append(
            AgentResponse(
                **agent.__dict__,
                health=health
            )
        )
    
    return AgentListResponse(
        agents=agent_responses,
        total=total,
        page=page,
        per_page=per_page
    )

@router.post("", response_model=AgentResponse, status_code=status.HTTP_201_CREATED)
async def create_agent(
    agent_data: AgentCreate,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_developer),
    db: AsyncSession = Depends(get_async_db)
):
    """Create new agent"""
    # Check agent limit
    user_agent_count = await db.execute(
        select(func.count()).select_from(Agent).where(
            Agent.owner_id == current_user.id
        )
    )
    
    if user_agent_count.scalar() >= settings.MAX_AGENTS_PER_USER:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Agent limit reached ({settings.MAX_AGENTS_PER_USER})"
        )
    
    # Create agent
    db_agent = Agent(
        name=agent_data.name,
        type=agent_data.type,
        config=agent_data.config,
        owner_id=current_user.id,
        cpu_limit=agent_data.cpu_limit or "500m",
        memory_limit=agent_data.memory_limit or "512Mi",
        replica_count=agent_data.replica_count or 1
    )
    
    db.add(db_agent)
    await db.commit()
    await db.refresh(db_agent)
    
    # Deploy agent in background
    background_tasks.add_task(
        agent_service.create_agent,
        db,
        db_agent
    )
    
    return AgentResponse(
        **db_agent.__dict__,
        health={"status": "deploying", "healthy": False}
    )

@router.get("/{agent_id}", response_model=AgentResponse)
async def get_agent(
    agent_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db)
):
    """Get agent details with health status"""
    # Get agent
    result = await db.execute(
        select(Agent).where(Agent.id == agent_id)
    )
    agent = result.scalar_one_or_none()
    
    if not agent:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Agent not found"
        )
    
    # Check permissions
    if (current_user.role == UserRole.DEVELOPER and 
        agent.owner_id != current_user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )
    
    # Get health status
    health = await agent_service.get_agent_health(agent)
    
    return AgentResponse(
        **agent.__dict__,
        health=health
    )

@router.put("/{agent_id}", response_model=AgentResponse)
async def update_agent(
    agent_id: int,
    agent_update: AgentUpdate,
    current_user: User = Depends(require_developer),
    db: AsyncSession = Depends(get_async_db)
):
    """Update agent configuration"""
    # Get agent
    result = await db.execute(
        select(Agent).where(Agent.id == agent_id)
    )
    agent = result.scalar_one_or_none()
    
    if not agent:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Agent not found"
        )
    
    # Check ownership
    if (current_user.role != UserRole.ADMIN and 
        agent.owner_id != current_user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )
    
    # Update fields
    update_data = agent_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(agent, field, value)
    
    agent.updated_at = datetime.utcnow()
    await db.commit()
    
    # Get updated health
    health = await agent_service.get_agent_health(agent)
    
    return AgentResponse(
        **agent.__dict__,
        health=health
    )

@router.delete("/{agent_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_agent(
    agent_id: int,
    current_user: User = Depends(require_developer),
    db: AsyncSession = Depends(get_async_db)
):
    """Delete agent"""
    # Get agent
    result = await db.execute(
        select(Agent).where(Agent.id == agent_id)
    )
    agent = result.scalar_one_or_none()
    
    if not agent:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Agent not found"
        )
    
    # Check ownership
    if (current_user.role != UserRole.ADMIN and 
        agent.owner_id != current_user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )
    
    # Delete from Kubernetes
    try:
        await agent_service.delete_agent(agent)
    except Exception as e:
        print(f"Error deleting from k8s: {e}")
    
    # Delete from database
    await db.delete(agent)
    await db.commit()

@router.post("/{agent_id}/start", response_model=dict)
async def start_agent(
    agent_id: int,
    current_user: User = Depends(require_developer),
    db: AsyncSession = Depends(get_async_db)
):
    """Start agent"""
    agent = await _get_agent_with_permission_check(
        agent_id, current_user, db
    )
    
    await agent_service.start_agent(agent)
    await db.commit()
    
    return {"message": "Agent started", "status": agent.status}

@router.post("/{agent_id}/stop", response_model=dict)
async def stop_agent(
    agent_id: int,
    current_user: User = Depends(require_developer),
    db: AsyncSession = Depends(get_async_db)
):
    """Stop agent"""
    agent = await _get_agent_with_permission_check(
        agent_id, current_user, db
    )
    
    await agent_service.stop_agent(agent)
    await db.commit()
    
    return {"message": "Agent stopped", "status": agent.status}

@router.post("/{agent_id}/scale", response_model=dict)
async def scale_agent(
    agent_id: int,
    scale_request: ScaleRequest,
    current_user: User = Depends(require_developer),
    db: AsyncSession = Depends(get_async_db)
):
    """Scale agent replicas"""
    agent = await _get_agent_with_permission_check(
        agent_id, current_user, db
    )
    
    # Validate replica count
    if scale_request.replicas < 0 or scale_request.replicas > 20:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Replica count must be between 0 and 20"
        )
    
    await agent_service.scale_agent(agent, scale_request.replicas)
    await db.commit()
    
    return {
        "message": f"Agent scaled to {scale_request.replicas} replicas",
        "replicas": agent.replica_count
    }

@router.get("/{agent_id}/metrics", response_model=MetricsResponse)
async def get_agent_metrics(
    agent_id: int,
    metric_type: str = Query(..., regex="^(cpu|memory|requests|errors|latency)$"),
    period: str = Query("1h", regex="^(5m|15m|1h|6h|24h|7d)$"),
    aggregation: Optional[str] = Query(None, regex="^(mean|max|min|sum)$"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db)
):
    """Get agent metrics"""
    # Verify agent exists and user has access
    await _get_agent_with_permission_check(
        agent_id, current_user, db, read_only=True
    )
    
    # Parse period
    period_map = {
        "5m": 5,
        "15m": 15,
        "1h": 60,
        "6h": 360,
        "24h": 1440,
        "7d": 10080
    }
    
    start_time = datetime.utcnow() - timedelta(
        minutes=period_map[period]
    )
    
    # Get metrics
    metrics = await metrics_service.get_metrics(
        agent_id, metric_type, start_time, 
        aggregation=aggregation
    )
    
    # Get aggregations
    aggregations = await metrics_service.calculate_aggregations(
        agent_id, metric_type, period_map[period]
    )
    
    return MetricsResponse(
        agent_id=agent_id,
        metric_type=metric_type,
        period=period,
        data=metrics,
        aggregations=aggregations
    )

async def _get_agent_with_permission_check(
    agent_id: int,
    user: User,
    db: AsyncSession,
    read_only: bool = False
) -> Agent:
    """Helper to get agent with permission check"""
    result = await db.execute(
        select(Agent).where(Agent.id == agent_id)
    )
    agent = result.scalar_one_or_none()
    
    if not agent:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Agent not found"
        )
    
    # Check permissions
    if read_only:
        # All authenticated users can read
        pass
    else:
        # Only owner or admin can modify
        if (user.role != UserRole.ADMIN and 
            agent.owner_id != user.id):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied"
            )
    
    return agent
```

### 3.3 WebSocket Endpoints

Create `backend/app/api/websocket/ws.py`:

**Copilot Prompt Suggestion:**
```python
# Create WebSocket endpoint that:
# - Authenticates users via query parameter token
# - Manages subscriptions to agent channels
# - Handles real-time metric streaming
# - Implements heartbeat/ping-pong
# - Rate limits messages per connection
# Include error handling and graceful disconnection
```

**Expected Copilot Output:**
```python
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, Depends
from sqlalchemy.ext.asyncio import AsyncSession
import json
import asyncio
from datetime import datetime

from ...core.database import get_async_db
from ...core.security import verify_token
from ...services.websocket_manager import websocket_manager
from ...models.models import User

router = APIRouter()

@router.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: str = Query(...),
    db: AsyncSession = Depends(get_async_db)
):
    """WebSocket endpoint for real-time updates"""
    # Verify token
    try:
        payload = verify_token(token)
        user_id = payload.get("user_id")
        
        if not user_id:
            await websocket.close(code=4001, reason="Invalid token")
            return
            
    except Exception:
        await websocket.close(code=4001, reason="Authentication failed")
        return
    
    # Connect
    connected = await websocket_manager.connect(websocket, user_id)
    if not connected:
        return
    
    try:
        # Start heartbeat task
        heartbeat_task = asyncio.create_task(
            send_heartbeat(websocket)
        )
        
        # Handle messages
        while True:
            try:
                # Receive message with timeout
                message = await asyncio.wait_for(
                    websocket.receive_text(),
                    timeout=60.0
                )
                
                await websocket_manager.handle_message(
                    websocket, message
                )
                
            except asyncio.TimeoutError:
                # Send ping to check connection
                await websocket.send_json({"type": "ping"})
                
    except WebSocketDisconnect:
        await websocket_manager.disconnect(websocket)
        heartbeat_task.cancel()
        
    except Exception as e:
        print(f"WebSocket error: {e}")
        await websocket_manager.disconnect(websocket)
        heartbeat_task.cancel()
        
        try:
            await websocket.close(code=4002, reason="Internal error")
        except:
            pass

async def send_heartbeat(websocket: WebSocket):
    """Send periodic heartbeat to keep connection alive"""
    try:
        while True:
            await asyncio.sleep(30)
            await websocket.send_json({
                "type": "heartbeat",
                "timestamp": datetime.utcnow().isoformat()
            })
    except Exception:
        pass
```

### 3.4 Main Application

Create `backend/app/main.py`:

**Copilot Prompt Suggestion:**
```python
# Create main FastAPI application that:
# - Configures all routers and middleware
# - Sets up CORS for dashboard frontend
# - Initializes services on startup
# - Handles global exceptions
# - Exposes Prometheus metrics endpoint
# - Includes health checks
# - Sets up background tasks for monitoring
# Include proper logging and error handling
```

**Expected Copilot Output:**
```python
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from prometheus_client import Counter, Histogram, generate_latest
import time
import logging
import asyncio

from .core.config import settings
from .core.database import init_db
from .api.v1 import auth, agents, deployments, alerts, metrics
from .api.websocket import ws
from .services.websocket_manager import websocket_manager
from .services.monitoring_service import start_monitoring_tasks

# Configure logging
logging.basicConfig(
    level=logging.INFO if settings.DEBUG else logging.WARNING,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter(
    'http_requests_total', 
    'Total HTTP requests', 
    ['method', 'endpoint', 'status']
)
REQUEST_DURATION = Histogram(
    'http_request_duration_seconds', 
    'HTTP request duration', 
    ['method', 'endpoint']
)

# Create FastAPI app
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.VERSION,
    description="AI Operations Dashboard - Monitor and manage AI agents",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request timing middleware
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    
    response = await call_next(request)
    
    # Record metrics
    process_time = time.time() - start_time
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    REQUEST_DURATION.labels(
        method=request.method,
        endpoint=request.url.path
    ).observe(process_time)
    
    response.headers["X-Process-Time"] = str(process_time)
    return response

# Include routers
app.include_router(auth.router, prefix=settings.API_PREFIX)
app.include_router(agents.router, prefix=settings.API_PREFIX)
app.include_router(deployments.router, prefix=settings.API_PREFIX)
app.include_router(alerts.router, prefix=settings.API_PREFIX)
app.include_router(metrics.router, prefix=settings.API_PREFIX)
app.include_router(ws.router, prefix="/api")

# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Global exception: {str(exc)}", exc_info=True)
    
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "detail": "Internal server error",
            "type": type(exc).__name__
        }
    )

# Startup event
@app.on_event("startup")
async def startup_event():
    """Initialize application on startup"""
    logger.info(f"Starting {settings.APP_NAME} v{settings.VERSION}")
    
    # Initialize database
    await init_db()
    logger.info("Database initialized")
    
    # Initialize WebSocket manager
    await websocket_manager.initialize()
    logger.info("WebSocket manager initialized")
    
    # Start background monitoring tasks
    if settings.ENABLE_METRICS:
        asyncio.create_task(start_monitoring_tasks())
        logger.info("Monitoring tasks started")
    
    logger.info("Application startup complete")

# Shutdown event
@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    logger.info("Shutting down application...")
    
    # Close WebSocket connections
    for user_connections in websocket_manager.active_connections.values():
        for ws in user_connections:
            try:
                await ws.close()
            except:
                pass
    
    logger.info("Shutdown complete")

# Health endpoints
@app.get("/health")
async def health_check():
    """Basic health check"""
    return {
        "status": "healthy",
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT
    }

@app.get("/health/ready")
async def readiness_check(db: AsyncSession = Depends(get_async_db)):
    """Readiness check - verifies all services are ready"""
    checks = {
        "database": False,
        "redis": False,
        "kubernetes": False
    }
    
    # Check database
    try:
        await db.execute("SELECT 1")
        checks["database"] = True
    except:
        pass
    
    # Check Redis
    try:
        if websocket_manager.redis_client:
            await websocket_manager.redis_client.ping()
            checks["redis"] = True
    except:
        pass
    
    # Check Kubernetes
    try:
        from .services.agent_service import agent_service
        agent_service.k8s_core.list_namespace()
        checks["kubernetes"] = True
    except:
        pass
    
    all_ready = all(checks.values())
    
    return JSONResponse(
        status_code=200 if all_ready else 503,
        content={
            "ready": all_ready,
            "checks": checks
        }
    )

# Metrics endpoint
@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    if not settings.ENABLE_METRICS:
        return JSONResponse(
            status_code=404,
            content={"detail": "Metrics disabled"}
        )
    
    return Response(
        content=generate_latest(),
        media_type="text/plain"
    )

# Root endpoint
@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "name": settings.APP_NAME,
        "version": settings.VERSION,
        "docs": "/api/docs",
        "health": "/health",
        "metrics": "/metrics" if settings.ENABLE_METRICS else None,
        "websocket": "/api/ws"
    }
```

## ✅ Checkpoint 3

Before proceeding to frontend, verify:
- [ ] All API endpoints are implemented
- [ ] WebSocket connection works
- [ ] Role-based access control is enforced
- [ ] Metrics collection is functioning
- [ ] Health checks pass

### Test the Backend

1. Start required services:
   ```bash
   docker-compose up -d postgres redis influxdb
   ```

2. Run the application:
   ```bash
   cd backend
   python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

3. Access API documentation: http://localhost:8000/api/docs

4. Test WebSocket connection:
   ```javascript
   const ws = new WebSocket('ws://localhost:8000/api/ws?token=YOUR_TOKEN');
   ws.onmessage = (event) => console.log(JSON.parse(event.data));
   ```

## 🎯 Next Steps

Continue to Part 4 for:
- React frontend setup
- Real-time dashboard components
- Chart visualizations
- WebSocket integration
- Deployment interface

The backend is now a production-ready monitoring system with real-time capabilities!

Proceed to [Part 4](./part4.md)
