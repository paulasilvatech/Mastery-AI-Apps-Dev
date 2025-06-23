# Exercise 3: AI Dashboard - Troubleshooting Guide

## Common Issues and Solutions

### 📈 Chart Rendering Issues

#### Charts Not Displaying
```
Error: Canvas is already in use. Chart with ID '0' must be destroyed before the canvas can be reused.
```

**Solution:**
```typescript
// Properly cleanup charts in useEffect
useEffect(() => {
  const chart = new Chart(ctx, config);
  
  return () => {
    chart.destroy();
  };
}, [data]);
```

#### Data Not Updating in Real-time
```
Warning: Charts not reflecting WebSocket updates
```

**Solution:**
```typescript
// Use React state properly
const [chartData, setChartData] = useState(initialData);

useEffect(() => {
  socket.on('data-update', (newData) => {
    setChartData(prev => ({
      ...prev,
      datasets: [{
        ...prev.datasets[0],
        data: [...prev.datasets[0].data, newData]
      }]
    }));
  });
}, []);
```

### 🌐 WebSocket Connection Issues

#### Connection Refused
```
WebSocket connection to 'ws://localhost:8000/ws' failed
```

**Solution:**
1. Ensure WebSocket endpoint is correct:
   ```python
   @app.websocket("/ws")
   async def websocket_endpoint(websocket: WebSocket):
       await websocket.accept()
   ```

2. Check CORS for WebSocket:
   ```python
   app.add_middleware(
       CORSMiddleware,
       allow_origins=["http://localhost:5173"],
       allow_methods=["*"],
       allow_headers=["*"],
   )
   ```

#### Frequent Disconnections
```
WebSocket is already in CLOSING or CLOSED state
```

**Solution:**
```typescript
// Implement reconnection logic
const useWebSocket = (url: string) => {
  const [socket, setSocket] = useState<Socket | null>(null);
  
  useEffect(() => {
    const connect = () => {
      const newSocket = io(url, {
        reconnection: true,
        reconnectionDelay: 1000,
        reconnectionAttempts: 5
      });
      
      newSocket.on('connect', () => {
        console.log('Connected');
      });
      
      newSocket.on('disconnect', () => {
        console.log('Disconnected, attempting reconnect...');
      });
      
      setSocket(newSocket);
    };
    
    connect();
    
    return () => {
      socket?.disconnect();
    };
  }, [url]);
  
  return socket;
};
```

### 🤖 AI Integration Issues

#### OpenAI Rate Limiting
```
Error: Rate limit reached for requests
```

**Solution:**
1. Implement request queuing:
   ```python
   from asyncio import Queue
   import asyncio
   
   request_queue = Queue(maxsize=10)
   
   async def process_ai_requests():
       while True:
           request = await request_queue.get()
           try:
               result = await call_openai_api(request)
               request['callback'](result)
           except RateLimitError:
               await asyncio.sleep(60)  # Wait before retry
               await request_queue.put(request)  # Re-queue
   ```

2. Use caching:
   ```python
   from functools import lru_cache
   import hashlib
   
   @lru_cache(maxsize=1000)
   def get_ai_insight(data_hash: str):
       # Cache results based on data hash
       return generate_insight(data_hash)
   ```

#### AI Response Timeout
```
Error: OpenAI API request timed out
```

**Solution:**
```python
import asyncio
from typing import Optional

async def get_ai_insight_with_timeout(
    prompt: str, 
    timeout: int = 30
) -> Optional[str]:
    try:
        return await asyncio.wait_for(
            generate_ai_insight(prompt),
            timeout=timeout
        )
    except asyncio.TimeoutError:
        # Return fallback or cached response
        return get_fallback_insight()
```

### 📋 Data Processing Issues

#### Memory Overflow with Large Datasets
```
Error: JavaScript heap out of memory
```

**Solution:**
1. Implement data pagination:
   ```typescript
   const usePaginatedData = (pageSize = 1000) => {
     const [currentPage, setCurrentPage] = useState(0);
     const [data, setData] = useState([]);
     
     const loadPage = async (page: number) => {
       const response = await fetch(
         `/api/data?page=${page}&size=${pageSize}`
       );
       const pageData = await response.json();
       setData(pageData);
     };
     
     return { data, currentPage, loadPage };
   };
   ```

2. Use data virtualization:
   ```typescript
   import { FixedSizeList } from 'react-window';
   
   const VirtualizedDataList = ({ data }) => (
     <FixedSizeList
       height={600}
       itemCount={data.length}
       itemSize={50}
       width='100%'
     >
       {({ index, style }) => (
         <div style={style}>
           {renderDataRow(data[index])}
         </div>
       )}
     </FixedSizeList>
   );
   ```

#### Slow Analytics Calculations
```
Warning: Analytics endpoint taking >5 seconds
```

**Solution:**
1. Pre-calculate metrics:
   ```python
   # Use background tasks
   @app.on_event("startup")
   async def startup_event():
       asyncio.create_task(precalculate_metrics())
   
   async def precalculate_metrics():
       while True:
           await calculate_and_cache_metrics()
           await asyncio.sleep(300)  # Every 5 minutes
   ```

2. Use database aggregations:
   ```python
   # Instead of Python calculations
   def get_average_slow():
       data = session.query(Metric).all()
       return sum(m.value for m in data) / len(data)
   
   # Use database aggregation
   def get_average_fast():
       return session.query(func.avg(Metric.value)).scalar()
   ```

### 🎨 UI/Layout Issues

#### Grid Layout Not Responsive
```
Error: React Grid Layout - Collision detection failed
```

**Solution:**
```typescript
const ResponsiveDashboard = () => {
  const layouts = {
    lg: [
      { i: 'chart1', x: 0, y: 0, w: 6, h: 4 },
      { i: 'chart2', x: 6, y: 0, w: 6, h: 4 },
    ],
    md: [
      { i: 'chart1', x: 0, y: 0, w: 6, h: 4 },
      { i: 'chart2', x: 0, y: 4, w: 6, h: 4 },
    ],
    sm: [
      { i: 'chart1', x: 0, y: 0, w: 12, h: 4 },
      { i: 'chart2', x: 0, y: 4, w: 12, h: 4 },
    ]
  };
  
  return (
    <ResponsiveGridLayout
      layouts={layouts}
      breakpoints={{ lg: 1200, md: 996, sm: 768 }}
      cols={{ lg: 12, md: 12, sm: 12 }}
    >
      {/* Dashboard widgets */}
    </ResponsiveGridLayout>
  );
};
```

### 🔍 Performance Optimization

#### Slow Initial Load
```
Lighthouse Score: Performance 45/100
```

**Solution:**
1. Code splitting:
   ```typescript
   const Dashboard = lazy(() => import('./components/Dashboard'));
   const Analytics = lazy(() => import('./components/Analytics'));
   ```

2. Optimize bundle:
   ```javascript
   // vite.config.js
   export default {
     build: {
       rollupOptions: {
         output: {
           manualChunks: {
             vendor: ['react', 'react-dom'],
             charts: ['chart.js', 'recharts'],
           }
         }
       }
     }
   };
   ```

### 🛠️ Development Environment

#### Port Conflicts
```bash
# Check and kill processes
lsof -ti:8000 | xargs kill -9  # Backend
lsof -ti:5173 | xargs kill -9  # Frontend
lsof -ti:6379 | xargs kill -9  # Redis
```

#### Environment Variables Not Loading
```python
# Ensure .env file is in correct location
from pathlib import Path
from dotenv import load_dotenv

# Explicitly specify path
env_path = Path(__file__).parent.parent / '.env'
load_dotenv(dotenv_path=env_path)
```

### 🆘 Getting Help

1. **Enable Debug Mode**:
   ```python
   # Backend
   app = FastAPI(debug=True)
   logging.basicConfig(level=logging.DEBUG)
   
   // Frontend
   console.log('Component state:', state);
   console.log('WebSocket status:', socket.connected);
   ```

2. **Check Browser Console** for JavaScript errors
3. **Monitor Network Tab** for failed requests
4. **Use React DevTools** to inspect component state
5. **Enable SQL logging** to debug queries

Remember: Most dashboard issues are related to state management, data flow, or WebSocket connections!