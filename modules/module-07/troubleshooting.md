# Module 07: Troubleshooting Guide

## 🔧 Common Issues and Solutions

This guide addresses the most common issues encountered while building web applications in Module 07. Each issue includes symptoms, root causes, and step-by-step solutions.

## 🚫 Exercise 1: Todo Application Issues

### Issue 1.1: CORS Errors

**Symptoms:**
```
Access to fetch at 'http://localhost:8000/api/v1/todos' from origin 'http://localhost:5173' has been blocked by CORS policy
```

**Solution:**
```python
# backend/app/main.py
# Ensure CORS middleware is configured correctly
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],  # Add both
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Also check that middleware is added BEFORE routes
```

### Issue 1.2: Database Connection Failed

**Symptoms:**
```
sqlalchemy.exc.OperationalError: (sqlite3.OperationalError) unable to open database file
```

**Solution:**
```python
# Ensure database directory exists
import os
os.makedirs("backend", exist_ok=True)

# Check database URL
SQLALCHEMY_DATABASE_URL = "sqlite:///./todos.db"  # Note the ./

# Initialize database on startup
@app.on_event("startup")
def startup():
    Base.metadata.create_all(bind=engine)
```

### Issue 1.3: React Query Not Updating

**Symptoms:**
- Data not refreshing after mutations
- Stale data shown after updates

**Solution:**
```typescript
// Ensure proper invalidation
const createMutation = useMutation({
  mutationFn: todoApi.createTodo,
  onSuccess: () => {
    // Invalidate and refetch
    queryClient.invalidateQueries({ queryKey: ['todos'] });
  },
});

// Or use setQueryData for optimistic updates
queryClient.setQueryData(['todos'], (old) => [...old, newTodo]);
```

## 🚫 Exercise 2: Blog Platform Issues

### Issue 2.1: Authentication Token Not Persisting

**Symptoms:**
- User logged out after page refresh
- 401 errors after login

**Solution:**
```typescript
// Frontend: Properly store and retrieve token
const login = async (credentials) => {
  const response = await authApi.login(credentials);
  
  // Store in localStorage
  localStorage.setItem('access_token', response.access_token);
  
  // Update axios defaults
  apiClient.defaults.headers.common['Authorization'] = `Bearer ${response.access_token}`;
};

// On app initialization
const token = localStorage.getItem('access_token');
if (token) {
  apiClient.defaults.headers.common['Authorization'] = `Bearer ${token}`;
}
```

### Issue 2.2: File Upload Failing

**Symptoms:**
```
413 Request Entity Too Large
Failed to upload image
```

**Solution:**
```python
# Backend: Increase upload limits
# In backend/app/core/config.py
MAX_UPLOAD_SIZE: int = 10 * 1024 * 1024  # 10MB

# In backend/app/services/upload.py
def validate_file(self, file: UploadFile) -> None:
    # Check file size
    file.file.seek(0, 2)
    file_size = file.file.tell()
    file.file.seek(0)  # Reset position!
    
    if file_size > settings.MAX_UPLOAD_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"File too large. Max: {settings.MAX_UPLOAD_SIZE // 1024 // 1024}MB"
        )
```

**Nginx Configuration (if using):**
```nginx
client_max_body_size 10M;
```

### Issue 2.3: PostgreSQL Connection Issues

**Symptoms:**
```
psycopg2.OperationalError: FATAL: password authentication failed
asyncpg.exceptions.ConnectionDoesNotExistError
```

**Solution:**
```python
# Check connection string format
DATABASE_URL = "postgresql+asyncpg://user:password@localhost:5432/dbname"
                          #  ^^^^^^^ Important for async

# Ensure PostgreSQL is running
# Docker:
docker run -d \
  --name postgres \
  -e POSTGRES_USER=bloguser \
  -e POSTGRES_PASSWORD=blogpass \
  -e POSTGRES_DB=blogdb \
  -p 5432:5432 \
  postgres:15

# Test connection
import asyncpg
conn = await asyncpg.connect('postgresql://bloguser:blogpass@localhost/blogdb')
```

## 🚫 Exercise 3: AI Dashboard Issues

### Issue 3.1: WebSocket Connection Dropping

**Symptoms:**
- "WebSocket is already in CLOSING or CLOSED state"
- Frequent reconnections
- Missing real-time updates

**Solution:**
```typescript
// Frontend: Implement robust reconnection
const useWebSocket = (url: string) => {
  const [socket, setSocket] = useState<WebSocket | null>(null);
  const reconnectTimeoutRef = useRef<NodeJS.Timeout>();
  const reconnectAttempts = useRef(0);

  const connect = useCallback(() => {
    try {
      const ws = new WebSocket(url);
      
      ws.onopen = () => {
        console.log('WebSocket connected');
        reconnectAttempts.current = 0;
        setSocket(ws);
      };

      ws.onclose = (event) => {
        console.log('WebSocket closed:', event.code, event.reason);
        setSocket(null);
        
        // Reconnect with exponential backoff
        if (reconnectAttempts.current < 5) {
          const timeout = Math.min(1000 * Math.pow(2, reconnectAttempts.current), 30000);
          reconnectTimeoutRef.current = setTimeout(() => {
            reconnectAttempts.current++;
            connect();
          }, timeout);
        }
      };

      ws.onerror = (error) => {
        console.error('WebSocket error:', error);
      };

    } catch (error) {
      console.error('Failed to create WebSocket:', error);
    }
  }, [url]);

  useEffect(() => {
    connect();
    
    return () => {
      if (reconnectTimeoutRef.current) {
        clearTimeout(reconnectTimeoutRef.current);
      }
      socket?.close();
    };
  }, [connect]);

  return socket;
};
```

### Issue 3.2: Kubernetes Connection Failed

**Symptoms:**
```
kubernetes.config.config_exception.ConfigException: Invalid kube-config file
urllib3.exceptions.MaxRetryError: HTTPSConnectionPool(host='localhost', port=6443)
```

**Solution:**
```python
# Backend: Flexible Kubernetes configuration
from kubernetes import client, config
import os

def init_k8s_client():
    try:
        # Try in-cluster config first (for deployed apps)
        config.load_incluster_config()
        print("Using in-cluster Kubernetes config")
    except:
        try:
            # Try local kubeconfig
            config_file = os.environ.get('KUBECONFIG', '~/.kube/config')
            config.load_kube_config(config_file=config_file)
            print(f"Using kubeconfig from {config_file}")
        except:
            print("WARNING: No Kubernetes config found. Agent deployment disabled.")
            return None, None
    
    return client.AppsV1Api(), client.CoreV1Api()

# For local development without K8s
if settings.ENVIRONMENT == "development":
    # Mock K8s operations
    class MockK8sClient:
        def create_namespaced_deployment(self, *args, **kwargs):
            return {"metadata": {"name": "mock-deployment"}}
```

### Issue 3.3: InfluxDB Write Failures

**Symptoms:**
```
influxdb_client.rest.ApiException: (400)
Unable to write metrics
```

**Solution:**
```python
# Ensure InfluxDB is properly configured
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS

# Create bucket if it doesn't exist
def init_influxdb():
    client = InfluxDBClient(
        url=settings.INFLUXDB_URL,
        token=settings.INFLUXDB_TOKEN,
        org=settings.INFLUXDB_ORG
    )
    
    buckets_api = client.buckets_api()
    
    try:
        buckets_api.find_bucket_by_name(settings.INFLUXDB_BUCKET)
    except:
        # Create bucket
        buckets_api.create_bucket(
            bucket_name=settings.INFLUXDB_BUCKET,
            org_id=settings.INFLUXDB_ORG,
            retention_rules=[{
                "type": "expire",
                "everySeconds": 86400 * 30  # 30 days
            }]
        )

# Validate data before writing
def write_metric(metric_data):
    try:
        point = Point("metrics") \
            .tag("agent_id", str(metric_data.agent_id)) \
            .field("value", float(metric_data.value)) \
            .time(metric_data.timestamp)
        
        write_api.write(bucket=settings.INFLUXDB_BUCKET, record=point)
    except Exception as e:
        logger.error(f"Failed to write metric: {e}")
        # Don't fail the request
```

## 🐛 General Debugging Tips

### 1. Backend Debugging

**Enable Detailed Logging:**
```python
# backend/app/main.py
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Log all SQL queries
logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)

# Add request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    
    logger.info(
        f"{request.method} {request.url.path} "
        f"Status: {response.status_code} "
        f"Duration: {process_time:.3f}s"
    )
    
    return response
```

### 2. Frontend Debugging

**React Query DevTools:**
```typescript
// main.tsx
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'

<QueryClientProvider client={queryClient}>
  <App />
  <ReactQueryDevtools initialIsOpen={false} position="bottom-right" />
</QueryClientProvider>
```

**Network Request Debugging:**
```typescript
// Add axios interceptors for debugging
apiClient.interceptors.request.use(request => {
  console.log('Starting Request:', request.method, request.url);
  console.log('Request Data:', request.data);
  return request;
});

apiClient.interceptors.response.use(
  response => {
    console.log('Response:', response.status, response.data);
    return response;
  },
  error => {
    console.error('Error Response:', error.response?.status, error.response?.data);
    return Promise.reject(error);
  }
);
```

### 3. WebSocket Debugging

**Browser DevTools:**
1. Open Chrome DevTools
2. Go to Network tab
3. Filter by "WS"
4. Click on WebSocket connection
5. View Messages tab for real-time data

**Backend WebSocket Logging:**
```python
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    client_id = id(websocket)
    logger.info(f"Client {client_id} connected")
    
    try:
        while True:
            data = await websocket.receive_text()
            logger.debug(f"Received from {client_id}: {data}")
            
            # Echo for testing
            await websocket.send_text(f"Echo: {data}")
            
    except WebSocketDisconnect:
        logger.info(f"Client {client_id} disconnected")
```

## 🚀 Performance Issues

### Slow API Responses

**Diagnosis:**
```python
# Add timing to identify bottlenecks
import time
from functools import wraps

def timeit(func):
    @wraps(func)
    async def wrapper(*args, **kwargs):
        start = time.time()
        result = await func(*args, **kwargs)
        duration = time.time() - start
        logger.info(f"{func.__name__} took {duration:.3f}s")
        return result
    return wrapper

@router.get("/agents")
@timeit
async def get_agents(db: Session = Depends(get_db)):
    # Your code here
```

**Common Solutions:**
1. Add database indexes
2. Use eager loading for relationships
3. Implement pagination
4. Add caching layer

### Memory Leaks

**Frontend:**
```typescript
// Clean up subscriptions and timers
useEffect(() => {
  const subscription = observable.subscribe();
  const timer = setInterval(() => {}, 1000);
  
  return () => {
    subscription.unsubscribe();
    clearInterval(timer);
  };
}, []);
```

**Backend:**
```python
# Close connections properly
async def get_data():
    conn = await asyncpg.connect(DATABASE_URL)
    try:
        return await conn.fetch("SELECT * FROM agents")
    finally:
        await conn.close()  # Always close!
```

## 🔍 Validation Tools

### 1. API Testing
```bash
# Test endpoints with curl
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser&password=Test1234!"

# Test WebSocket with wscat
npm install -g wscat
wscat -c ws://localhost:8000/ws?token=YOUR_TOKEN
```

### 2. Database Verification
```sql
-- Check PostgreSQL connections
SELECT pid, usename, application_name, client_addr, state
FROM pg_stat_activity
WHERE datname = 'blogdb';

-- Check table structure
\d+ agents

-- Verify data
SELECT * FROM agents ORDER BY created_at DESC LIMIT 10;
```

### 3. Docker Debugging
```bash
# View logs
docker-compose logs -f backend

# Execute commands in container
docker-compose exec backend python -c "from app.models import *; print(Agent.query.count())"

# Check resource usage
docker stats
```

## 📞 Getting Help

If these solutions don't resolve your issue:

1. **Check Logs** - Both frontend console and backend logs
2. **Isolate the Problem** - Test each component separately
3. **Review the Working Solution** - Compare with the provided solution code
4. **Search Error Messages** - Often others have encountered the same issue
5. **Ask for Help** - Post in the module discussion with:
   - Error message
   - What you've tried
   - Relevant code snippets
   - Environment details

Remember: Every error is a learning opportunity!
