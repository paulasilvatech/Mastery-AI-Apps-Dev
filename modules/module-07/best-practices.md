# Module 07: Web Application Best Practices

## 🎯 Overview

This guide contains production-ready patterns and best practices for building web applications with AI assistance. These practices have been refined through real-world deployments and will help you build scalable, maintainable, and secure applications.

## 🏗️ Architecture Best Practices

### 1. Separation of Concerns

**Frontend/Backend Separation**
```typescript
// ❌ Bad: Mixing concerns
const UserProfile = () => {
  const [user, setUser] = useState(null);
  
  useEffect(() => {
    // Direct database query in component
    fetch(`mongodb://localhost/users/${id}`)
      .then(res => res.json())
      .then(setUser);
  }, []);
};

// ✅ Good: Clear separation
// Frontend: api/users.ts
export const userApi = {
  getProfile: (id: string) => 
    apiClient.get<User>(`/users/${id}`).then(res => res.data)
};

// Frontend: components/UserProfile.tsx
const UserProfile = () => {
  const { data: user } = useQuery(['user', id], () => userApi.getProfile(id));
};

// Backend: api/users.py
@router.get("/users/{user_id}")
async def get_user(user_id: int, db: Session = Depends(get_db)):
    return db.query(User).filter(User.id == user_id).first()
```

### 2. API Design Patterns

**RESTful Conventions**
```python
# ✅ Good: Consistent RESTful API design
@router.get("/agents", response_model=List[AgentResponse])
async def list_agents():
    """GET /agents - List all agents"""

@router.post("/agents", response_model=AgentResponse, status_code=201)
async def create_agent():
    """POST /agents - Create new agent"""

@router.get("/agents/{agent_id}", response_model=AgentResponse)
async def get_agent():
    """GET /agents/:id - Get single agent"""

@router.put("/agents/{agent_id}", response_model=AgentResponse)
async def update_agent():
    """PUT /agents/:id - Update agent"""

@router.delete("/agents/{agent_id}", status_code=204)
async def delete_agent():
    """DELETE /agents/:id - Delete agent"""
```

**Response Consistency**
```python
# ✅ Good: Consistent response format
class APIResponse(BaseModel):
    success: bool
    data: Optional[Any] = None
    error: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)

@router.get("/agents/{agent_id}")
async def get_agent(agent_id: int) -> APIResponse:
    try:
        agent = await agent_service.get_agent(agent_id)
        return APIResponse(success=True, data=agent)
    except NotFoundError:
        return APIResponse(success=False, error="Agent not found")
```

### 3. State Management

**Frontend State Architecture**
```typescript
// ✅ Good: Structured state management
// stores/index.ts
export const useStore = create<AppState>((set, get) => ({
  // UI State
  theme: 'light',
  sidebarOpen: true,
  
  // Domain State (cached from API)
  agents: [],
  currentUser: null,
  
  // Application State
  isLoading: false,
  error: null,
  
  // Actions
  toggleTheme: () => set(state => ({ 
    theme: state.theme === 'light' ? 'dark' : 'light' 
  })),
  
  setAgents: (agents) => set({ agents }),
}));

// Use React Query for server state
const { data: agents } = useQuery(['agents'], agentApi.getAll, {
  onSuccess: (data) => useStore.setState({ agents: data }),
  staleTime: 5 * 60 * 1000, // 5 minutes
});
```

## 🔒 Security Best Practices

### 1. Authentication & Authorization

**JWT Implementation**
```python
# ✅ Good: Secure JWT handling
from datetime import datetime, timedelta
import secrets

class SecurityConfig:
    SECRET_KEY = secrets.token_urlsafe(32)  # Generate once, store securely
    ALGORITHM = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES = 30
    REFRESH_TOKEN_EXPIRE_DAYS = 7

def create_tokens(user_id: int, role: str) -> TokenPair:
    # Access token with minimal claims
    access_payload = {
        "sub": str(user_id),
        "role": role,
        "type": "access",
        "exp": datetime.utcnow() + timedelta(minutes=30)
    }
    
    # Refresh token with extended expiry
    refresh_payload = {
        "sub": str(user_id),
        "type": "refresh",
        "exp": datetime.utcnow() + timedelta(days=7)
    }
    
    return TokenPair(
        access_token=jwt.encode(access_payload, SECRET_KEY, ALGORITHM),
        refresh_token=jwt.encode(refresh_payload, SECRET_KEY, ALGORITHM)
    )
```

**Role-Based Access Control**
```python
# ✅ Good: Granular permissions
class Permission(Enum):
    AGENT_READ = "agent:read"
    AGENT_WRITE = "agent:write"
    AGENT_DELETE = "agent:delete"
    ADMIN_ACCESS = "admin:*"

ROLE_PERMISSIONS = {
    UserRole.VIEWER: [Permission.AGENT_READ],
    UserRole.DEVELOPER: [
        Permission.AGENT_READ, 
        Permission.AGENT_WRITE
    ],
    UserRole.ADMIN: [Permission.ADMIN_ACCESS]
}

def require_permission(permission: Permission):
    async def check_permission(
        current_user: User = Depends(get_current_user)
    ):
        user_permissions = ROLE_PERMISSIONS.get(current_user.role, [])
        
        if Permission.ADMIN_ACCESS in user_permissions:
            return current_user
            
        if permission not in user_permissions:
            raise HTTPException(403, "Insufficient permissions")
            
        return current_user
    return check_permission
```

### 2. Input Validation

**Comprehensive Validation**
```python
# ✅ Good: Strong input validation
from pydantic import BaseModel, validator, Field
import re

class UserCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=20)
    email: EmailStr
    password: str = Field(..., min_length=8)
    
    @validator('username')
    def validate_username(cls, v):
        if not re.match(r'^[a-zA-Z0-9_-]+$', v):
            raise ValueError('Username can only contain letters, numbers, _ and -')
        return v
    
    @validator('password')
    def validate_password(cls, v):
        if not re.search(r'[A-Z]', v):
            raise ValueError('Password must contain uppercase letter')
        if not re.search(r'[a-z]', v):
            raise ValueError('Password must contain lowercase letter')
        if not re.search(r'\d', v):
            raise ValueError('Password must contain digit')
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', v):
            raise ValueError('Password must contain special character')
        return v
```

### 3. SQL Injection Prevention

**Safe Database Queries**
```python
# ❌ Bad: SQL injection vulnerable
@router.get("/search")
async def search(q: str, db: Session = Depends(get_db)):
    query = f"SELECT * FROM agents WHERE name LIKE '%{q}%'"
    return db.execute(query).fetchall()

# ✅ Good: Parameterized queries
@router.get("/search")
async def search(q: str, db: Session = Depends(get_db)):
    return db.query(Agent).filter(
        Agent.name.ilike(f"%{q}%")
    ).all()
```

## ⚡ Performance Best Practices

### 1. Database Optimization

**Efficient Queries**
```python
# ❌ Bad: N+1 query problem
agents = db.query(Agent).all()
for agent in agents:
    agent.metrics = db.query(Metric).filter(
        Metric.agent_id == agent.id
    ).all()

# ✅ Good: Eager loading
agents = db.query(Agent).options(
    joinedload(Agent.metrics),
    joinedload(Agent.deployments)
).all()

# ✅ Good: Query only needed fields
agent_summaries = db.query(
    Agent.id, 
    Agent.name, 
    Agent.status
).filter(Agent.owner_id == user_id).all()
```

**Database Indexing**
```python
# ✅ Good: Strategic indexes
class Agent(Base):
    __tablename__ = "agents"
    
    id = Column(Integer, primary_key=True)
    owner_id = Column(Integer, ForeignKey("users.id"), index=True)
    status = Column(Enum(AgentStatus), index=True)
    created_at = Column(DateTime, index=True)
    
    __table_args__ = (
        Index('idx_owner_status', 'owner_id', 'status'),
        Index('idx_created_status', 'created_at', 'status'),
    )
```

### 2. Caching Strategies

**API Response Caching**
```python
# ✅ Good: Redis caching for expensive operations
from functools import wraps
import json

def cache_result(expire_seconds: int = 300):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Generate cache key
            cache_key = f"{func.__name__}:{json.dumps(args)}:{json.dumps(kwargs)}"
            
            # Check cache
            cached = await redis_client.get(cache_key)
            if cached:
                return json.loads(cached)
            
            # Compute result
            result = await func(*args, **kwargs)
            
            # Store in cache
            await redis_client.setex(
                cache_key, 
                expire_seconds, 
                json.dumps(result, default=str)
            )
            
            return result
        return wrapper
    return decorator

@router.get("/dashboard/metrics")
@cache_result(expire_seconds=60)
async def get_dashboard_metrics():
    # Expensive aggregation query
    return await metrics_service.calculate_dashboard_metrics()
```

### 3. Frontend Optimization

**Code Splitting**
```typescript
// ✅ Good: Lazy loading routes
import { lazy, Suspense } from 'react';

const Dashboard = lazy(() => import('./pages/Dashboard'));
const AgentDetails = lazy(() => import('./pages/AgentDetails'));

function App() {
  return (
    <Suspense fallback={<LoadingSpinner />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/agents/:id" element={<AgentDetails />} />
      </Routes>
    </Suspense>
  );
}
```

**Optimistic Updates**
```typescript
// ✅ Good: Optimistic UI updates
const updateAgentMutation = useMutation({
  mutationFn: agentApi.update,
  onMutate: async (newData) => {
    // Cancel in-flight queries
    await queryClient.cancelQueries(['agent', newData.id]);
    
    // Save current state
    const previousAgent = queryClient.getQueryData(['agent', newData.id]);
    
    // Optimistically update
    queryClient.setQueryData(['agent', newData.id], old => ({
      ...old,
      ...newData
    }));
    
    return { previousAgent };
  },
  onError: (err, newData, context) => {
    // Rollback on error
    queryClient.setQueryData(
      ['agent', newData.id], 
      context.previousAgent
    );
  },
  onSettled: () => {
    // Refetch to ensure consistency
    queryClient.invalidateQueries(['agent']);
  }
});
```

## 🔄 Real-time Best Practices

### 1. WebSocket Management

**Connection Resilience**
```typescript
// ✅ Good: Robust WebSocket connection
class WebSocketManager {
  private ws: WebSocket | null = null;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;
  private reconnectDelay = 1000;
  private messageQueue: Message[] = [];
  
  connect(url: string, token: string) {
    this.ws = new WebSocket(`${url}?token=${token}`);
    
    this.ws.onopen = () => {
      this.reconnectAttempts = 0;
      this.reconnectDelay = 1000;
      
      // Send queued messages
      while (this.messageQueue.length > 0) {
        const message = this.messageQueue.shift();
        this.send(message);
      }
    };
    
    this.ws.onclose = () => {
      if (this.reconnectAttempts < this.maxReconnectAttempts) {
        setTimeout(() => {
          this.reconnectAttempts++;
          this.reconnectDelay *= 2;
          this.connect(url, token);
        }, this.reconnectDelay);
      }
    };
    
    this.ws.onerror = (error) => {
      console.error('WebSocket error:', error);
    };
  }
  
  send(message: Message) {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(message));
    } else {
      // Queue message for later
      this.messageQueue.push(message);
    }
  }
}
```

### 2. Event Handling

**Efficient Event Processing**
```typescript
// ✅ Good: Debounced event handling
import { debounce } from 'lodash';

function MetricsDisplay({ agentId }: Props) {
  const [metrics, setMetrics] = useState<Metric[]>([]);
  
  // Batch metric updates
  const updateMetrics = useMemo(
    () => debounce((newMetrics: Metric[]) => {
      setMetrics(current => {
        // Keep last 100 metrics
        const updated = [...current, ...newMetrics].slice(-100);
        return updated;
      });
    }, 100),
    []
  );
  
  useEffect(() => {
    const unsubscribe = wsManager.subscribe(
      `metrics:${agentId}`,
      updateMetrics
    );
    
    return unsubscribe;
  }, [agentId, updateMetrics]);
}
```

## 🚀 Deployment Best Practices

### 1. Environment Configuration

**Environment Management**
```python
# ✅ Good: Environment-specific configuration
from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    # Required in all environments
    app_name: str
    database_url: str
    secret_key: str
    
    # Environment-specific
    debug: bool = False
    log_level: str = "INFO"
    
    # Feature flags
    enable_metrics: bool = True
    enable_profiling: bool = False
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

@lru_cache()
def get_settings() -> Settings:
    return Settings()

# Usage
settings = get_settings()
```

### 2. Containerization

**Multi-stage Dockerfile**
```dockerfile
# ✅ Good: Optimized Docker image
# Build stage
FROM node:18-alpine AS frontend-build
WORKDIR /app
COPY frontend/package*.json ./
RUN npm ci --only=production
COPY frontend/ ./
RUN npm run build

# Python build stage
FROM python:3.11-slim AS python-build
WORKDIR /app
COPY backend/requirements.txt ./
RUN pip install --user -r requirements.txt

# Runtime stage
FROM python:3.11-slim
WORKDIR /app

# Copy Python dependencies
COPY --from=python-build /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH

# Copy frontend build
COPY --from=frontend-build /app/dist ./static

# Copy application
COPY backend/ ./

# Non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 3. Health Checks

**Comprehensive Health Checks**
```python
# ✅ Good: Detailed health checks
@router.get("/health/ready")
async def readiness_probe():
    checks = {
        "database": await check_database(),
        "redis": await check_redis(),
        "external_api": await check_external_api(),
    }
    
    status = all(checks.values())
    status_code = 200 if status else 503
    
    return JSONResponse(
        status_code=status_code,
        content={
            "status": "ready" if status else "not ready",
            "checks": checks,
            "timestamp": datetime.utcnow().isoformat()
        }
    )

async def check_database() -> bool:
    try:
        await db.execute("SELECT 1")
        return True
    except Exception:
        return False
```

## 📊 Monitoring Best Practices

### 1. Structured Logging

**Comprehensive Logging**
```python
# ✅ Good: Structured logging with context
import structlog

logger = structlog.get_logger()

@router.post("/agents")
async def create_agent(
    agent_data: AgentCreate,
    current_user: User = Depends(get_current_user)
):
    log = logger.bind(
        user_id=current_user.id,
        action="create_agent",
        agent_type=agent_data.type
    )
    
    try:
        log.info("Creating agent")
        agent = await agent_service.create(agent_data, current_user)
        
        log.info("Agent created successfully", agent_id=agent.id)
        return agent
        
    except ValidationError as e:
        log.warning("Validation failed", error=str(e))
        raise HTTPException(400, detail=str(e))
        
    except Exception as e:
        log.error("Failed to create agent", error=str(e), exc_info=True)
        raise HTTPException(500, detail="Internal server error")
```

### 2. Metrics Collection

**Application Metrics**
```python
# ✅ Good: Comprehensive metrics
from prometheus_client import Counter, Histogram, Gauge

# Request metrics
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

# Business metrics
active_agents = Gauge(
    'active_agents_total',
    'Number of active agents',
    ['type']
)

agent_operations = Counter(
    'agent_operations_total',
    'Agent operations',
    ['operation', 'status']
)

# Middleware to collect metrics
@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start_time = time.time()
    
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
```

## 🤖 AI-Assisted Development Best Practices

### 1. Effective Prompting

**Component Generation**
```typescript
// ✅ Good: Detailed prompts for complex components
/**
 * Copilot Prompt:
 * Create a React component for displaying agent metrics that:
 * - Uses Recharts for visualization
 * - Shows CPU, memory, and request rate
 * - Updates in real-time via WebSocket
 * - Has time range selector (5m, 1h, 24h)
 * - Displays current value with trend indicator
 * - Uses TypeScript with proper types
 * - Handles loading and error states
 * - Supports dark mode with Tailwind
 * - Memoizes expensive calculations
 * - Props: agentId (number), metricType (string)
 */
```

### 2. Code Review with AI

**AI-Assisted Reviews**
```python
# When reviewing code with Copilot, ask specific questions:
# 1. "Are there any security vulnerabilities in this authentication flow?"
# 2. "How can I optimize this database query for better performance?"
# 3. "What edge cases am I missing in this error handling?"
# 4. "Is this following REST API best practices?"
```

### 3. Documentation Generation

**Comprehensive Documentation**
```python
# ✅ Good: Let AI help with documentation
"""
Copilot Prompt:
Generate comprehensive docstring for this function including:
- Description of what it does
- Args with types and descriptions
- Returns with type and description
- Raises with possible exceptions
- Example usage
- Note about any side effects
"""

async def deploy_agent(
    agent_id: int,
    config: DeploymentConfig,
    user: User,
    background_tasks: BackgroundTasks
) -> Deployment:
    """
    Deploy an AI agent to Kubernetes cluster.
    
    This function creates a new deployment for the specified agent,
    applying the provided configuration and ensuring proper resource
    allocation and security policies.
    
    Args:
        agent_id: The unique identifier of the agent to deploy
        config: Deployment configuration including replicas, resources, and env vars
        user: The user initiating the deployment (for audit logging)
        background_tasks: FastAPI background tasks for async monitoring
        
    Returns:
        Deployment: The created deployment object with status and metadata
        
    Raises:
        NotFoundError: If the agent with agent_id doesn't exist
        ValidationError: If the configuration is invalid
        DeploymentError: If Kubernetes deployment fails
        PermissionError: If user lacks deployment permissions
        
    Example:
        >>> config = DeploymentConfig(replicas=3, cpu="500m", memory="1Gi")
        >>> deployment = await deploy_agent(123, config, current_user, tasks)
        >>> print(f"Deployed with ID: {deployment.id}")
        
    Note:
        This function triggers background monitoring tasks that will
        update the deployment status asynchronously.
    """
```

## 📋 Summary

Remember these key principles:

1. **Separation of Concerns**: Keep your layers clean and independent
2. **Security First**: Never trust user input, always validate and sanitize
3. **Performance Matters**: Optimize queries, cache wisely, load lazily
4. **Error Handling**: Fail gracefully, log comprehensively, recover automatically
5. **Real-time Reliability**: Handle disconnections, queue messages, debounce updates
6. **Monitor Everything**: You can't improve what you don't measure
7. **AI as Assistant**: Use AI to accelerate, but always review and understand

Following these best practices will help you build web applications that are not just functional, but truly production-ready.
