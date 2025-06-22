# Module 30: Resources and Quick Reference

## 🚀 Quick Command Reference

### Project Setup Commands
```bash
# Python FastAPI project setup
mkdir mastery-ed && cd mastery-ed
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install fastapi uvicorn sqlalchemy alembic psycopg2-binary redis
pip install openai langchain pytest httpx python-jose passlib

# TypeScript agent project
npm init -y
npm install typescript @types/node tsx
npm install @modelcontextprotocol/server @modelcontextprotocol/client
npm install openai langchain

# Database setup
alembic init alembic
alembic revision --autogenerate -m "Initial models"
alembic upgrade head
```

### Docker Commands
```bash
# Build services
docker-compose build

# Run all services
docker-compose up -d

# Check service health
docker-compose ps
docker-compose logs -f service-name

# Quick rebuild and restart
docker-compose down && docker-compose up -d --build
```

### Kubernetes Commands
```bash
# Deploy to AKS
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/deployments/
kubectl apply -f k8s/services/

# Check deployment status
kubectl get pods -n mastery-ed
kubectl get svc -n mastery-ed
kubectl describe pod <pod-name> -n mastery-ed

# Quick debugging
kubectl logs -f deployment/auth-service -n mastery-ed
kubectl exec -it <pod-name> -n mastery-ed -- /bin/bash
```

### Azure CLI Commands
```bash
# Login and set subscription
az login
az account set --subscription "Your Subscription"

# Create resource group
az group create --name rg-mastery-ed --location eastus

# Deploy Bicep template
az deployment group create \
  --resource-group rg-mastery-ed \
  --template-file main.bicep \
  --parameters environment=dev

# Get AKS credentials
az aks get-credentials --resource-group rg-mastery-ed --name aks-mastery-ed
```

## 📋 Service Port Reference

| Service | Port | Purpose |
|---------|------|---------|
| API Gateway | 8000 | Main entry point |
| Auth Service | 8001 | Authentication/Authorization |
| Course Service | 8002 | Course management |
| AI Service | 8003 | AI operations |
| Analytics Service | 8004 | Metrics and reporting |
| MCP Server | 8005 | Model Context Protocol |
| Redis | 6379 | Caching |
| PostgreSQL | 5432 | Primary database |
| Prometheus | 9090 | Metrics collection |
| Grafana | 3000 | Dashboards |

## 🔧 Common Code Snippets

### FastAPI Service Template
```python
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

app = FastAPI(title="Service Name", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.on_event("startup")
async def startup_event():
    # Initialize connections
    pass

@app.on_event("shutdown")
async def shutdown_event():
    # Cleanup connections
    pass

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
```

### Agent Template
```typescript
import { Agent } from './interfaces/Agent'

export class CustomAgent implements Agent {
  name = 'CustomAgent'
  description = 'Agent purpose'
  
  async initialize(): Promise<void> {
    // Setup agent resources
  }
  
  async process(input: any): Promise<any> {
    try {
      // Agent logic here
      return result
    } catch (error) {
      console.error(`${this.name} error:`, error)
      throw new Error(`Agent processing failed: ${error.message}`)
    }
  }
  
  async cleanup(): Promise<void> {
    // Cleanup resources
  }
}
```

### MCP Tool Template
```typescript
export const customTool = {
  name: 'tool_name',
  description: 'What this tool does',
  parameters: {
    param1: {
      type: 'string',
      description: 'Parameter description',
      required: true
    }
  },
  handler: async (params: any) => {
    try {
      // Tool implementation
      return { success: true, data: result }
    } catch (error) {
      return { success: false, error: error.message }
    }
  }
}
```

### Docker Compose Service Template
```yaml
service-name:
  build: ./services/service-name
  container_name: service-name
  ports:
    - "8001:8001"
  environment:
    - DATABASE_URL=postgresql://user:pass@postgres:5432/db
    - REDIS_URL=redis://redis:6379
    - JWT_SECRET=${JWT_SECRET}
  depends_on:
    - postgres
    - redis
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8001/health"]
    interval: 30s
    timeout: 10s
    retries: 3
```

### Kubernetes Deployment Template
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: service-name
  namespace: mastery-ed
spec:
  replicas: 2
  selector:
    matchLabels:
      app: service-name
  template:
    metadata:
      labels:
        app: service-name
    spec:
      containers:
      - name: service-name
        image: masteryai.azurecr.io/service-name:latest
        ports:
        - containerPort: 8001
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: connection-string
        livenessProbe:
          httpGet:
            path: /health
            port: 8001
          initialDelaySeconds: 30
          periodSeconds: 10
```

## 🎯 Architecture Patterns

### API Gateway Pattern
```python
# Simple API Gateway implementation
class APIGateway:
    def __init__(self):
        self.services = {
            "auth": "http://auth-service:8001",
            "course": "http://course-service:8002",
            "ai": "http://ai-service:8003"
        }
    
    async def route_request(self, path: str, method: str, **kwargs):
        service = path.split("/")[2]  # /api/auth/login -> auth
        if service not in self.services:
            raise HTTPException(404, "Service not found")
        
        url = self.services[service] + path.replace(f"/api/{service}", "")
        async with httpx.AsyncClient() as client:
            response = await client.request(method, url, **kwargs)
            return response.json()
```

### Circuit Breaker Pattern
```python
class CircuitBreaker:
    def __init__(self, failure_threshold=5, recovery_timeout=60):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.failure_count = 0
        self.last_failure_time = None
        self.state = "CLOSED"  # CLOSED, OPEN, HALF_OPEN
    
    async def call(self, func, *args, **kwargs):
        if self.state == "OPEN":
            if time.time() - self.last_failure_time > self.recovery_timeout:
                self.state = "HALF_OPEN"
            else:
                raise Exception("Circuit breaker is OPEN")
        
        try:
            result = await func(*args, **kwargs)
            if self.state == "HALF_OPEN":
                self.state = "CLOSED"
                self.failure_count = 0
            return result
        except Exception as e:
            self.failure_count += 1
            self.last_failure_time = time.time()
            if self.failure_count >= self.failure_threshold:
                self.state = "OPEN"
            raise e
```

### Saga Pattern for Distributed Transactions
```python
class EnrollmentSaga:
    async def execute(self, student_id: str, course_id: str):
        saga_id = str(uuid.uuid4())
        steps = []
        
        try:
            # Step 1: Check prerequisites
            await self.check_prerequisites(student_id, course_id)
            steps.append("prerequisites_checked")
            
            # Step 2: Check capacity
            await self.check_capacity(course_id)
            steps.append("capacity_checked")
            
            # Step 3: Process payment
            payment_id = await self.process_payment(student_id, course_id)
            steps.append(("payment_processed", payment_id))
            
            # Step 4: Create enrollment
            enrollment_id = await self.create_enrollment(student_id, course_id)
            steps.append(("enrollment_created", enrollment_id))
            
            # Step 5: Send notifications
            await self.send_notifications(student_id, course_id)
            steps.append("notifications_sent")
            
            return {"success": True, "enrollment_id": enrollment_id}
            
        except Exception as e:
            # Compensate in reverse order
            await self.compensate(steps)
            raise e
```

## 📊 Monitoring Queries

### Prometheus Queries
```promql
# Request rate per service
rate(http_requests_total[5m])

# Error rate
rate(http_requests_total{status=~"5.."}[5m])

# 95th percentile latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# AI token usage rate
rate(ai_tokens_used_total[1h])
```

### Application Insights Queries
```kusto
// Failed requests in last hour
requests
| where timestamp > ago(1h)
| where success == false
| summarize count() by operation_Name

// Average response time by operation
requests
| where timestamp > ago(1h)
| summarize avg(duration) by operation_Name
| order by avg_duration desc

// AI agent performance
customEvents
| where name == "AgentResponse"
| extend agent = tostring(customDimensions.agent)
| summarize avg(todouble(customDimensions.duration)) by agent
```

## 🔗 Essential Links

### Documentation
- [FastAPI Docs](https://fastapi.tiangolo.com/)
- [MCP Specification](https://github.com/modelcontextprotocol/specification)
- [Azure AI Services](https://learn.microsoft.com/en-us/azure/ai-services/)
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [GitHub Actions](https://docs.github.com/en/actions)

### AI/ML Resources
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [LangChain Documentation](https://python.langchain.com/docs/)
- [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/)

### Tools
- [Postman](https://www.postman.com/) - API testing
- [k9s](https://k9scli.io/) - Kubernetes CLI UI
- [Lens](https://k8slens.dev/) - Kubernetes IDE
- [Azure Storage Explorer](https://azure.microsoft.com/en-us/features/storage-explorer/)

## 💡 Performance Tips

### Database Optimization
```sql
-- Create indexes for common queries
CREATE INDEX idx_enrollments_student_course 
ON enrollments(student_id, course_id);

CREATE INDEX idx_lessons_course_order 
ON lessons(course_id, order_num);

-- Materialized view for analytics
CREATE MATERIALIZED VIEW student_progress_summary AS
SELECT 
    s.id as student_id,
    c.id as course_id,
    COUNT(DISTINCT l.id) as total_lessons,
    COUNT(DISTINCT p.lesson_id) as completed_lessons,
    ROUND(COUNT(DISTINCT p.lesson_id)::numeric / COUNT(DISTINCT l.id) * 100, 2) as progress_percentage
FROM students s
CROSS JOIN courses c
LEFT JOIN enrollments e ON s.id = e.student_id AND c.id = e.course_id
LEFT JOIN lessons l ON c.id = l.course_id
LEFT JOIN progress p ON s.id = p.student_id AND l.id = p.lesson_id
GROUP BY s.id, c.id;
```

### Caching Strategy
```python
# Cache decorator with TTL
def cache_result(ttl_seconds=300):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            cache_key = f"{func.__name__}:{str(args)}:{str(kwargs)}"
            
            # Try cache first
            cached = await redis.get(cache_key)
            if cached:
                return json.loads(cached)
            
            # Compute and cache
            result = await func(*args, **kwargs)
            await redis.setex(cache_key, ttl_seconds, json.dumps(result))
            return result
        return wrapper
    return decorator

# Usage
@cache_result(ttl_seconds=600)
async def get_course_statistics(course_id: str):
    # Expensive computation
    return statistics
```

## 🎓 Final Tips

1. **Keep It Simple**: Start with the simplest solution that works
2. **Use What You Know**: Stick to familiar technologies under pressure
3. **Test Early**: Catch issues before they compound
4. **Document Intent**: Quick comments save debugging time
5. **Stay Calm**: You have the skills, trust your training

Good luck with your Ultimate Mastery Challenge! 🚀