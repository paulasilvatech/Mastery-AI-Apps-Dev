# Module 10: Troubleshooting Guide

## 🔍 Common Issues and Solutions

### WebSocket Connection Issues

#### Problem: WebSocket fails to connect
```
WebSocket connection to 'ws://localhost:8000/ws' failed: Connection refused
```

**Solutions:**
1. **Check if server is running:**
   ```bash
   curl http://localhost:8000/health
   ```

2. **Verify WebSocket endpoint:**
   ```python
   # Test with simple client
   import websockets
   import asyncio
   
   async def test():
       try:
           async with websockets.connect("ws://localhost:8000/ws") as ws:
               print("Connected!")
       except Exception as e:
           print(f"Error: {e}")
   
   asyncio.run(test())
   ```

3. **Check firewall/proxy settings:**
   - Some proxies don't support WebSocket
   - Try direct connection without proxy
   - Check if port 8000 is open

#### Problem: WebSocket disconnects frequently
**Solutions:**
1. **Implement reconnection logic:**
   ```javascript
   class ReconnectingWebSocket {
       constructor(url) {
           this.url = url;
           this.reconnectInterval = 1000;
           this.maxReconnectInterval = 30000;
           this.reconnectDecay = 1.5;
           this.connect();
       }
       
       connect() {
           this.ws = new WebSocket(this.url);
           
           this.ws.onclose = () => {
               setTimeout(() => {
                   this.reconnectInterval = Math.min(
                       this.reconnectInterval * this.reconnectDecay,
                       this.maxReconnectInterval
                   );
                   this.connect();
               }, this.reconnectInterval);
           };
           
           this.ws.onopen = () => {
               this.reconnectInterval = 1000;
           };
       }
   }
   ```

2. **Add heartbeat mechanism:**
   ```python
   async def websocket_with_heartbeat(websocket: WebSocket):
       async def heartbeat():
           while True:
               try:
                   await websocket.send_json({"type": "ping"})
                   await asyncio.sleep(30)
               except:
                   break
       
       heartbeat_task = asyncio.create_task(heartbeat())
       try:
           # Handle messages
           await handle_messages(websocket)
       finally:
           heartbeat_task.cancel()
   ```

### Event Processing Issues

#### Problem: Events not being processed
**Diagnosis:**
```python
# Add debug logging
import logging
logging.basicConfig(level=logging.DEBUG)

# Check buffer stats
@app.get("/debug/buffer")
async def debug_buffer():
    return {
        "size": len(buffer.buffer),
        "capacity": buffer.capacity,
        "dropped": buffer.total_dropped,
        "workers": stream_processor.num_workers
    }
```

**Solutions:**
1. **Check if workers are running:**
   ```python
   # Add worker health check
   @app.get("/debug/workers")
   async def debug_workers():
       return {
           "running": stream_processor.running,
           "worker_count": len(stream_processor.workers),
           "stats": stream_processor.stats.dict()
       }
   ```

2. **Verify event format:**
   ```python
   # Add validation
   try:
       event = StreamEvent.from_bytes(data)
   except Exception as e:
       logger.error(f"Invalid event format: {e}")
       # Log the raw data for debugging
       logger.debug(f"Raw data: {data[:100]}")
   ```

#### Problem: High memory usage
**Solutions:**
1. **Limit buffer size:**
   ```python
   # Use bounded collections
   from collections import deque
   
   class BoundedBuffer:
       def __init__(self, maxsize=10000):
           self.buffer = deque(maxlen=maxsize)
           self.dropped = 0
           
       def add(self, item):
           if len(self.buffer) >= self.buffer.maxlen:
               self.dropped += 1
           self.buffer.append(item)
   ```

2. **Implement memory monitoring:**
   ```python
   import psutil
   import gc
   
   @app.get("/debug/memory")
   async def debug_memory():
       process = psutil.Process()
       
       # Force garbage collection
       gc.collect()
       
       return {
           "memory_mb": process.memory_info().rss / 1024 / 1024,
           "memory_percent": process.memory_percent(),
           "open_files": len(process.open_files()),
           "connections": len(process.connections()),
           "gc_stats": gc.get_stats()
       }
   ```

### Redis Connection Issues

#### Problem: Redis connection lost
```
aioredis.exceptions.ConnectionError: Connection lost
```

**Solutions:**
1. **Implement retry logic:**
   ```python
   class RedisReconnector:
       def __init__(self, url, max_retries=5):
           self.url = url
           self.max_retries = max_retries
           self.redis = None
           
       async def connect(self):
           for attempt in range(self.max_retries):
               try:
                   self.redis = await aioredis.from_url(self.url)
                   await self.redis.ping()
                   logger.info("Redis connected")
                   return
               except Exception as e:
                   wait_time = 2 ** attempt
                   logger.warning(f"Redis connection failed, retry in {wait_time}s")
                   await asyncio.sleep(wait_time)
           
           raise Exception("Failed to connect to Redis")
   ```

2. **Use connection pool:**
   ```python
   # Create connection pool
   redis_pool = await aioredis.create_pool(
       "redis://localhost:6379",
       minsize=5,
       maxsize=20,
       timeout=5
   )
   ```

### Performance Issues

#### Problem: Low throughput
**Diagnosis:**
```python
# Performance profiling
import cProfile
import pstats
from io import StringIO

profiler = cProfile.Profile()

@app.get("/debug/profile")
async def profile_endpoint():
    profiler.enable()
    
    # Run for 10 seconds
    await asyncio.sleep(10)
    
    profiler.disable()
    
    # Get stats
    s = StringIO()
    ps = pstats.Stats(profiler, stream=s).sort_stats('cumulative')
    ps.print_stats(20)
    
    return {"profile": s.getvalue()}
```

**Solutions:**
1. **Increase worker count:**
   ```python
   # Dynamic worker scaling
   class AutoScalingProcessor:
       def __init__(self, buffer):
           self.buffer = buffer
           self.min_workers = 2
           self.max_workers = 16
           self.workers = []
           
       async def scale_workers(self):
           while True:
               buffer_util = len(self.buffer.buffer) / self.buffer.capacity
               
               if buffer_util > 0.8 and len(self.workers) < self.max_workers:
                   # Add worker
                   worker = asyncio.create_task(self._process_worker())
                   self.workers.append(worker)
                   
               elif buffer_util < 0.2 and len(self.workers) > self.min_workers:
                   # Remove worker
                   worker = self.workers.pop()
                   worker.cancel()
               
               await asyncio.sleep(5)
   ```

2. **Optimize serialization:**
   ```python
   # Use faster serialization
   import orjson
   import msgpack
   
   # Benchmark different methods
   async def benchmark_serialization():
       event = create_test_event()
       
       # JSON
       start = time.time()
       for _ in range(10000):
           json.dumps(event.dict())
       json_time = time.time() - start
       
       # orjson
       start = time.time()
       for _ in range(10000):
           orjson.dumps(event.dict())
       orjson_time = time.time() - start
       
       # msgpack
       start = time.time()
       for _ in range(10000):
           msgpack.packb(event.dict())
       msgpack_time = time.time() - start
       
       return {
           "json": json_time,
           "orjson": orjson_time,
           "msgpack": msgpack_time
       }
   ```

#### Problem: Event processing lag
**Solutions:**
1. **Monitor processing time:**
   ```python
   class TimingProcessor:
       async def process_event(self, event):
           start = time.time()
           
           try:
               result = await self._process(event)
               duration = time.time() - start
               
               # Alert if slow
               if duration > 0.1:  # 100ms threshold
                   logger.warning(f"Slow processing: {duration:.3f}s for {event.id}")
               
               return result
           finally:
               # Record metric
               metrics.record_processing_time(duration)
   ```

2. **Implement batching:**
   ```python
   class BatchProcessor:
       def __init__(self, batch_size=100, batch_timeout=0.1):
           self.batch_size = batch_size
           self.batch_timeout = batch_timeout
           self.batch = []
           self.last_flush = time.time()
           
       async def add_event(self, event):
           self.batch.append(event)
           
           if (len(self.batch) >= self.batch_size or 
               time.time() - self.last_flush > self.batch_timeout):
               await self.flush()
       
       async def flush(self):
           if not self.batch:
               return
               
           # Process entire batch at once
           await self.process_batch(self.batch)
           self.batch = []
           self.last_flush = time.time()
   ```

### Dashboard Issues

#### Problem: SSE connection drops
**Solutions:**
1. **Add reconnection:**
   ```javascript
   class RobustEventSource {
       constructor(url) {
           this.url = url;
           this.reconnectInterval = 1000;
           this.connect();
       }
       
       connect() {
           this.eventSource = new EventSource(this.url);
           
           this.eventSource.onerror = () => {
               this.eventSource.close();
               setTimeout(() => this.connect(), this.reconnectInterval);
           };
           
           this.eventSource.onmessage = (event) => {
               this.handleMessage(JSON.parse(event.data));
           };
       }
   }
   ```

2. **Prevent proxy timeouts:**
   ```python
   async def sse_endpoint():
       async def generate():
           while True:
               # Send actual data or heartbeat
               data = await get_next_data(timeout=30)
               
               if data:
                   yield f"data: {json.dumps(data)}\n\n"
               else:
                   # Send heartbeat to keep connection alive
                   yield f": heartbeat\n\n"
       
       return StreamingResponse(
           generate(),
           media_type="text/event-stream",
           headers={
               "X-Accel-Buffering": "no",  # Disable Nginx buffering
               "Cache-Control": "no-cache"
           }
       )
   ```

## 🛠️ Debugging Tools

### 1. WebSocket Testing
```bash
# wscat - WebSocket testing tool
npm install -g wscat
wscat -c ws://localhost:8000/ws

# Send test message
> {"type": "test", "data": {"value": 42}}
```

### 2. Load Testing
```bash
# Use wrk for HTTP endpoints
wrk -t12 -c400 -d30s http://localhost:8000/api/stats

# Use custom script for WebSocket load testing
python load_test.py --clients 100 --rate 10000 --duration 60
```

### 3. Memory Profiling
```python
# Use memory_profiler
from memory_profiler import profile

@profile
def memory_intensive_function():
    # Your code here
    pass

# Run with: python -m memory_profiler your_script.py
```

### 4. Async Debugging
```python
# Debug async task states
import asyncio

@app.get("/debug/tasks")
async def debug_tasks():
    tasks = asyncio.all_tasks()
    return {
        "total_tasks": len(tasks),
        "tasks": [
            {
                "name": task.get_name(),
                "done": task.done(),
                "cancelled": task.cancelled()
            }
            for task in tasks
        ]
    }
```

## 📋 Diagnostic Checklist

When troubleshooting issues:

1. **Check logs:**
   ```bash
   tail -f app.log | grep ERROR
   ```

2. **Monitor system resources:**
   ```bash
   htop  # CPU and memory
   iotop  # Disk I/O
   iftop  # Network traffic
   ```

3. **Check connection counts:**
   ```bash
   netstat -an | grep :8000 | wc -l
   ```

4. **Verify Redis:**
   ```bash
   redis-cli ping
   redis-cli info stats
   ```

5. **Test endpoints:**
   ```bash
   # Health check
   curl http://localhost:8000/health
   
   # Stats
   curl http://localhost:8000/api/stats
   
   # Debug info
   curl http://localhost:8000/debug/buffer
   ```

## 🚑 Emergency Procedures

### System Overload
1. **Immediate:** Enable rate limiting
2. **Short-term:** Scale horizontally
3. **Long-term:** Optimize processing pipeline

### Memory Leak
1. **Identify:** Use memory profiler
2. **Mitigate:** Set memory limits and restart
3. **Fix:** Find and fix the leak

### Data Loss
1. **Stop:** Pause incoming traffic
2. **Diagnose:** Check buffers and queues
3. **Recover:** Replay from event store if available

---

Remember: Good logging and monitoring prevent most troubleshooting needs. When in doubt, add more observability!
