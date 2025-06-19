# Module 30: Challenge Troubleshooting Guide

## 🚨 Common Issues and Quick Fixes

### Hour 1: Foundation Issues

#### FastAPI Not Starting
```bash
# Error: "Module not found: fastapi"
pip install fastapi uvicorn[standard]

# Error: "Port already in use"
lsof -i :8000  # Find process
kill -9 <PID>  # Kill process

# Or use different port
uvicorn main:app --port 8080
```

#### Database Connection Failed
```python
# Error: "could not connect to server"
# Fix 1: Check PostgreSQL is running
docker-compose up -d postgres

# Fix 2: Verify connection string
DATABASE_URL = "postgresql://user:password@localhost:5432/dbname"
# NOT: postgres://... (use postgresql://)

# Fix 3: Create database if missing
CREATE DATABASE mastery_ed;
```

#### Alembic Migration Issues
```bash
# Error: "Can't locate revision identifier"
# Reset migrations
rm -rf alembic/versions/*
alembic revision --autogenerate -m "Initial"
alembic upgrade head

# Error: "Table already exists"
alembic stamp head  # Mark current state as migrated
```

#### WebSocket Connection Failing
```python
# Common CORS issue with WebSockets
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development only!
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Client-side connection
const ws = new WebSocket('ws://localhost:8000/ws');  # Note: ws:// not http://
```

### Hour 2: Enterprise Issues

#### Microservices Can't Communicate
```python
# Issue: Services can't reach each other
# Fix 1: Use service names in Docker Compose
AUTH_SERVICE_URL = "http://auth-service:8001"  # Not localhost!

# Fix 2: Ensure services are on same network
# docker-compose.yml
services:
  api-gateway:
    networks:
      - mastery-net
  auth-service:
    networks:
      - mastery-net

networks:
  mastery-net:
    driver: bridge
```

#### JWT Token Issues
```python
# Error: "Could not validate credentials"
# Fix: Ensure same secret across services
JWT_SECRET = os.getenv("JWT_SECRET", "your-secret-key")

# Verify token manually
import jwt
try:
    payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
    print(payload)
except jwt.ExpiredSignatureError:
    print("Token expired")
except jwt.InvalidTokenError:
    print("Invalid token")
```

#### Azure Deployment Failures
```bash
# Error: "The subscription is not registered"
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.ContainerRegistry

# Error: "Insufficient quota"
# Use smaller SKUs for the challenge
az aks create --node-count 1 --node-vm-size Standard_B2s

# Error: "Login to registry failed"
az acr login --name masteryedacr
docker tag myimage masteryedacr.azurecr.io/myimage
docker push masteryedacr.azurecr.io/myimage
```

#### Kubernetes Pods Not Starting
```bash
# Check pod status
kubectl describe pod <pod-name> -n mastery-ed

# Common fixes:
# 1. Image pull error
kubectl create secret docker-registry acr-secret \
  --docker-server=masteryedacr.azurecr.io \
  --docker-username=<username> \
  --docker-password=<password>

# 2. Environment variables missing
kubectl create secret generic app-secrets \
  --from-literal=DATABASE_URL=postgresql://... \
  --from-literal=JWT_SECRET=...

# 3. Resource limits too low
# Reduce limits in deployment.yaml
resources:
  limits:
    memory: "256Mi"
    cpu: "250m"
```

### Hour 3: AI & Integration Issues

#### Agent Not Responding
```typescript
// Error: "Agent timeout"
// Add timeout handling
const AGENT_TIMEOUT = 30000; // 30 seconds

async function callAgent(agent: Agent, input: any) {
  const timeoutPromise = new Promise((_, reject) => 
    setTimeout(() => reject(new Error('Agent timeout')), AGENT_TIMEOUT)
  );
  
  try {
    return await Promise.race([
      agent.process(input),
      timeoutPromise
    ]);
  } catch (error) {
    console.error(`Agent ${agent.name} failed:`, error);
    // Return fallback response
    return { error: true, message: "Agent temporarily unavailable" };
  }
}
```

#### MCP Server Connection Issues
```typescript
// Error: "ECONNREFUSED"
// Ensure MCP server is running
npm run start:mcp

// Check server is listening
netstat -an | grep 8005

// Test with curl
curl -X POST http://localhost:8005/v1/tools/list \
  -H "Content-Type: application/json" \
  -d '{}'
```

#### OpenAI Rate Limits
```python
# Error: "Rate limit exceeded"
import time
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=4, max=10)
)
async def call_openai(prompt: str):
    try:
        return await openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=150  # Reduce token usage
        )
    except RateLimitError:
        # Use cached response or fallback
        return get_cached_response(prompt)
```

#### Multi-Agent Coordination Failing
```python
# Issue: Agents not coordinating properly
# Solution: Add proper message queue
import asyncio
from asyncio import Queue

class AgentCoordinator:
    def __init__(self):
        self.message_queue = Queue()
        self.agents = {}
    
    async def route_message(self, message):
        agent_name = message.get("target_agent")
        if agent_name in self.agents:
            try:
                result = await asyncio.wait_for(
                    self.agents[agent_name].process(message),
                    timeout=10.0
                )
                return result
            except asyncio.TimeoutError:
                return {"error": "Agent timeout"}
        return {"error": "Agent not found"}
```

## 🔥 Emergency Fixes

### "I'm Running Out of Time!"

#### Quick Database Setup
```python
# Use SQLite for fastest setup
DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})

# Quick models without relationships
class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    email = Column(String, unique=True)
    password_hash = Column(String)

# Skip migrations, create directly
Base.metadata.create_all(bind=engine)
```

#### Minimal Microservices
```python
# Combine services if running out of time
# Put auth + courses in one service temporarily
@app.post("/auth/login")
async def login(credentials: LoginCredentials):
    # Auth logic
    pass

@app.get("/courses")
async def get_courses():
    # Course logic
    pass
```

#### Skip Complex Features
```python
# Use simple in-memory cache instead of Redis
cache = {}

async def get_cached(key: str):
    return cache.get(key)

async def set_cached(key: str, value: any, ttl: int = 300):
    cache[key] = value
    # Ignore TTL for simplicity
```

### "My Deployment Won't Work!"

#### Local Deployment Alternative
```bash
# If Azure fails, prove it works locally
docker-compose up -d

# Document in README
echo "## Deployment
Due to time constraints, the application is demonstrated locally.
For production deployment, see deployment/ folder for:
- Kubernetes manifests
- Bicep templates
- GitHub Actions workflows" >> README.md
```

#### Use ngrok for Public Access
```bash
# Install ngrok
brew install ngrok  # or download from ngrok.com

# Expose your local service
ngrok http 8000

# Document the public URL
# https://abc123.ngrok.io
```

## 🎯 Performance Quick Wins

### Disable Unnecessary Validation
```python
# During development/demo only
app = FastAPI(docs_url="/docs", redoc_url=None)  # Disable redoc

# Skip complex validation temporarily
# @validate_input(ComplexSchema)  # Comment out
async def endpoint(data: dict):  # Use dict instead
    pass
```

### Simple Caching
```python
# Quick caching decorator
from functools import lru_cache

@lru_cache(maxsize=100)
def expensive_operation(param: str):
    # Cached automatically
    return result
```

### Reduce AI Calls
```python
# Use cheaper/faster models
model = "gpt-3.5-turbo"  # Instead of gpt-4
max_tokens = 100  # Reduce token limit

# Cache AI responses aggressively
ai_cache = {}

async def get_ai_response(prompt: str):
    if prompt in ai_cache:
        return ai_cache[prompt]
    
    response = await call_ai(prompt)
    ai_cache[prompt] = response
    return response
```

## 📝 Last Resort Strategies

### Document What You Would Do
```markdown
## Production Considerations

Given more time, I would implement:

1. **Security Enhancements**
   - Implement OAuth2 with Auth0/Okta
   - Add rate limiting with Redis
   - Enable HTTPS with Let's Encrypt

2. **Performance Optimizations**
   - Implement database connection pooling
   - Add Redis caching layer
   - Use CDN for static assets

3. **Monitoring**
   - Full APM with Application Insights
   - Custom dashboards in Grafana
   - Alerts via PagerDuty
```

### Show Your Knowledge
```python
# Add comments showing awareness
async def process_payment(amount: float):
    # TODO: In production, would use Stripe/PayPal SDK
    # TODO: Implement idempotency keys
    # TODO: Add webhook for async confirmation
    # Simulated for demo
    return {"payment_id": str(uuid.uuid4()), "status": "success"}
```

## 🆘 Final Tips

1. **Don't Panic**: A partially working solution is better than nothing
2. **Show Progress**: Commit frequently to show your work
3. **Document Issues**: Note what you would fix with more time
4. **Focus on Core**: Get main features working first
5. **Ask for Help**: Use allowed resources wisely

Remember: The evaluators understand time constraints. Show your problem-solving process and technical knowledge even if everything isn't perfect!

Good luck! You've got this! 🚀