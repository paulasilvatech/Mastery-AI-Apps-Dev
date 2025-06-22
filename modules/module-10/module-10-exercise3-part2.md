# Exercise 3: Real-time Streaming Analytics Platform (Part 2)

### Step 5: Create Time Window Aggregator

**Copilot Prompt Suggestion:**
```python
# Create a time window aggregator that:
# - Implements tumbling, sliding, and session windows
# - Performs incremental aggregations for efficiency
# - Handles late-arriving events with watermarks
# - Supports multiple aggregation functions (sum, avg, min, max, percentiles)
# - Emits results at window boundaries
# - Manages memory efficiently with window eviction
# Include support for out-of-order events
```

**Expected Output:**
```python
# aggregators/time_window.py
import asyncio
from typing import Dict, List, Callable, Any, Optional
from datetime import datetime, timedelta
from collections import defaultdict
import heapq
import time
import logging
from models.events import StreamEvent
from models.metrics import WindowedAggregate

logger = logging.getLogger(__name__)

class WindowType:
    TUMBLING = "tumbling"
    SLIDING = "sliding"
    SESSION = "session"

class TimeWindow:
    def __init__(
        self,
        window_type: str,
        window_size: int,  # seconds
        slide_interval: Optional[int] = None,  # for sliding windows
        session_timeout: Optional[int] = None,  # for session windows
        late_event_delay: int = 30  # seconds to wait for late events
    ):
        self.window_type = window_type
        self.window_size = window_size
        self.slide_interval = slide_interval or window_size
        self.session_timeout = session_timeout or 300  # 5 minutes default
        self.late_event_delay = late_event_delay
        
        # Windows storage
        self.windows: Dict[float, WindowedAggregate] = {}
        self.closed_windows: List[WindowedAggregate] = []
        
        # Watermark tracking
        self.current_watermark = 0
        self.event_time_max = 0
        
        # Output callback
        self.output_callback: Optional[Callable] = None
        
    def set_output_callback(self, callback: Callable):
        """Set callback for window results"""
        self.output_callback = callback
    
    async def process_event(self, event: StreamEvent):
        """Process event into appropriate windows"""
        event_time = event.timestamp
        
        # Update watermark
        self.event_time_max = max(self.event_time_max, event_time)
        new_watermark = self.event_time_max - self.late_event_delay
        
        if new_watermark > self.current_watermark:
            self.current_watermark = new_watermark
            await self._close_windows()
        
        # Assign event to windows
        if self.window_type == WindowType.TUMBLING:
            await self._process_tumbling(event)
        elif self.window_type == WindowType.SLIDING:
            await self._process_sliding(event)
        elif self.window_type == WindowType.SESSION:
            await self._process_session(event)
    
    async def _process_tumbling(self, event: StreamEvent):
        """Process event in tumbling window"""
        window_start = (event.timestamp // self.window_size) * self.window_size
        
        if window_start not in self.windows:
            self.windows[window_start] = WindowedAggregate(
                window_start=window_start,
                window_end=window_start + self.window_size
            )
        
        self.windows[window_start].add_event(event)
    
    async def _process_sliding(self, event: StreamEvent):
        """Process event in sliding windows"""
        # Event can belong to multiple sliding windows
        window_start = (event.timestamp // self.slide_interval) * self.slide_interval
        
        # Add to all applicable windows
        for i in range(self.window_size // self.slide_interval):
            ws = window_start - (i * self.slide_interval)
            we = ws + self.window_size
            
            if ws <= event.timestamp < we and ws >= 0:
                if ws not in self.windows:
                    self.windows[ws] = WindowedAggregate(
                        window_start=ws,
                        window_end=we
                    )
                self.windows[ws].add_event(event)
    
    async def _process_session(self, event: StreamEvent):
        """Process event in session window"""
        # Find or create session for this source
        session_key = f"{event.source}_session"
        
        # Check if event extends existing session
        extended = False
        for window_start, window in list(self.windows.items()):
            if (window.window_start <= event.timestamp <= window.window_end + self.session_timeout and
                session_key in str(window_start)):
                # Extend session
                window.window_end = event.timestamp + self.session_timeout
                window.add_event(event)
                extended = True
                break
        
        if not extended:
            # Create new session
            window_start = event.timestamp
            session_id = f"{session_key}_{window_start}"
            self.windows[session_id] = WindowedAggregate(
                window_start=window_start,
                window_end=event.timestamp + self.session_timeout
            )
            self.windows[session_id].add_event(event)
    
    async def _close_windows(self):
        """Close windows that are past watermark"""
        to_close = []
        
        for window_id, window in self.windows.items():
            if window.window_end < self.current_watermark:
                to_close.append(window_id)
        
        for window_id in to_close:
            window = self.windows.pop(window_id)
            window.finalize()
            self.closed_windows.append(window)
            
            # Emit results
            if self.output_callback:
                await self.output_callback(window)
            
            logger.debug(f"Closed window: {window.window_start} - {window.window_end}")

class MultiKeyAggregator:
    """Aggregate by multiple keys simultaneously"""
    
    def __init__(self, keys: List[str], window_size: int = 60):
        self.keys = keys
        self.aggregators: Dict[str, TimeWindow] = {}
        self.window_size = window_size
        
    async def process_event(self, event: StreamEvent):
        """Process event for all key combinations"""
        # Extract key values
        key_values = {}
        for key in self.keys:
            value = event.data.get(key) or event.metadata.get(key)
            if value:
                key_values[key] = value
        
        # Create aggregations for each key and combination
        for i in range(1, len(key_values) + 1):
            for combo in self._get_combinations(list(key_values.keys()), i):
                key_str = "_".join([f"{k}:{key_values[k]}" for k in combo])
                
                if key_str not in self.aggregators:
                    self.aggregators[key_str] = TimeWindow(
                        WindowType.TUMBLING,
                        self.window_size
                    )
                
                await self.aggregators[key_str].process_event(event)
    
    def _get_combinations(self, items: List[str], n: int) -> List[List[str]]:
        """Get all combinations of n items"""
        from itertools import combinations
        return list(combinations(items, n))
```

### Step 6: Create Main Streaming Application

**Copilot Prompt Suggestion:**
```python
# Create a FastAPI streaming application that:
# - Provides WebSocket endpoint for high-speed data ingestion
# - Implements Server-Sent Events for real-time dashboard updates
# - Exposes metrics endpoint for Prometheus
# - Manages stream processor and aggregator lifecycle
# - Provides REST API for querying historical data
# - Implements graceful shutdown with drain
# Include monitoring and health checks
```

**Expected Output:**
```python
# main.py
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.responses import StreamingResponse, HTMLResponse
from fastapi.staticfiles import StaticFiles
import asyncio
import json
import time
import logging
from typing import Dict, List
from contextlib import asynccontextmanager
from datetime import datetime
import aioredis

from models.events import StreamEvent, EventType
from models.metrics import StreamStats
from utils.buffer import AdaptiveBuffer
from processors.stream_processor import StreamProcessor, EventEnricher, EventFilter
from aggregators.time_window import TimeWindow, WindowType, MultiKeyAggregator

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global components
buffer = AdaptiveBuffer(initial_capacity=100000, max_capacity=1000000)
stream_processor = StreamProcessor(buffer, num_workers=8)
redis_client = None

# Queues for different outputs
metrics_queue = asyncio.Queue(maxsize=10000)
alerts_queue = asyncio.Queue(maxsize=1000)
dashboard_clients: List[asyncio.Queue] = []

# Aggregators
realtime_aggregator = TimeWindow(WindowType.TUMBLING, window_size=10)  # 10-second windows
minute_aggregator = TimeWindow(WindowType.TUMBLING, window_size=60)  # 1-minute windows
sliding_aggregator = TimeWindow(WindowType.SLIDING, window_size=300, slide_interval=60)  # 5-min sliding

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifecycle management"""
    global redis_client
    
    # Startup
    logger.info("Starting streaming analytics platform...")
    
    # Connect Redis
    redis_client = await aioredis.from_url("redis://localhost:6379")
    
    # Set up processors
    enricher = EventEnricher(redis_client)
    filter_rules = {"sensor_threshold": 10, "max_age_seconds": 3600}
    event_filter = EventFilter(filter_rules)
    
    # Register processors
    stream_processor.register_processor(EventType.SENSOR_DATA, enricher)
    stream_processor.register_processor(EventType.SENSOR_DATA, event_filter)
    stream_processor.register_output_queue("metrics", metrics_queue)
    
    # Set up aggregator callbacks
    async def emit_aggregation(window):
        result = {
            "window_start": window.window_start,
            "window_end": window.window_end,
            "event_count": window.event_count,
            "aggregates": window.aggregates
        }
        
        # Send to all dashboard clients
        for client_queue in dashboard_clients[:]:
            try:
                await client_queue.put(json.dumps(result))
            except:
                dashboard_clients.remove(client_queue)
    
    realtime_aggregator.set_output_callback(emit_aggregation)
    minute_aggregator.set_output_callback(emit_aggregation)
    
    # Start components
    await stream_processor.start()
    
    # Start aggregation workers
    asyncio.create_task(aggregation_worker())
    
    logger.info("Platform started successfully")
    
    yield
    
    # Shutdown
    logger.info("Shutting down platform...")
    await stream_processor.stop()
    await redis_client.close()

app = FastAPI(title="Streaming Analytics Platform", lifespan=lifespan)

# Serve static files
app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/")
async def home():
    """Serve dashboard"""
    with open("static/dashboard.html", "r") as f:
        return HTMLResponse(content=f.read())

@app.websocket("/ws/ingest")
async def ingest_endpoint(websocket: WebSocket):
    """High-speed data ingestion endpoint"""
    await websocket.accept()
    client_id = f"client_{time.time()}"
    logger.info(f"Ingestion client connected: {client_id}")
    
    try:
        while True:
            # Receive data
            data = await websocket.receive_bytes()
            
            # Add to buffer
            success = await buffer.add(data, timeout=0.01)
            
            if not success:
                # Send backpressure signal
                await websocket.send_json({
                    "type": "backpressure",
                    "message": "Buffer full, slow down"
                })
    
    except WebSocketDisconnect:
        logger.info(f"Ingestion client disconnected: {client_id}")

@app.get("/stream/metrics")
async def metrics_stream():
    """Server-Sent Events stream for metrics"""
    async def event_generator():
        client_queue = asyncio.Queue(maxsize=100)
        dashboard_clients.append(client_queue)
        
        try:
            while True:
                # Get next metric
                data = await client_queue.get()
                yield f"data: {data}\n\n"
                
        except asyncio.CancelledError:
            dashboard_clients.remove(client_queue)
            raise
    
    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no"
        }
    )

@app.get("/api/stats")
async def get_stats():
    """Get current system statistics"""
    processor_stats = stream_processor.stats.dict()
    buffer_stats = buffer.get_stats()
    
    return {
        "processor": processor_stats,
        "buffer": buffer_stats,
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/api/aggregates/{window_type}")
async def get_aggregates(window_type: str, limit: int = 10):
    """Get recent aggregation results"""
    if window_type == "realtime":
        windows = realtime_aggregator.closed_windows[-limit:]
    elif window_type == "minute":
        windows = minute_aggregator.closed_windows[-limit:]
    else:
        raise HTTPException(status_code=400, detail="Invalid window type")
    
    return [
        {
            "window_start": w.window_start,
            "window_end": w.window_end,
            "event_count": w.event_count,
            "aggregates": w.aggregates
        }
        for w in windows
    ]

@app.post("/api/rules")
async def update_rules(rules: Dict[str, Any]):
    """Update processing rules dynamically"""
    # Update filter rules
    new_filter = EventFilter(rules)
    
    # Replace processor
    stream_processor.processors[EventType.SENSOR_DATA] = [
        p for p in stream_processor.processors[EventType.SENSOR_DATA]
        if not isinstance(p, EventFilter)
    ]
    stream_processor.register_processor(EventType.SENSOR_DATA, new_filter)
    
    return {"status": "rules updated", "rules": rules}

async def aggregation_worker():
    """Process events through aggregation pipeline"""
    while True:
        try:
            # Get event from metrics queue
            event = await metrics_queue.get()
            
            # Process through aggregators
            await realtime_aggregator.process_event(event)
            await minute_aggregator.process_event(event)
            await sliding_aggregator.process_event(event)
            
        except Exception as e:
            logger.error(f"Aggregation error: {e}")

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "components": {
            "buffer": "ok" if buffer.total_added > 0 else "idle",
            "processor": "ok" if stream_processor.running else "stopped",
            "redis": "ok" if redis_client else "disconnected"
        }
    }

# Prometheus metrics endpoint
@app.get("/metrics")
async def prometheus_metrics():
    """Export metrics in Prometheus format"""
    stats = stream_processor.stats
    buffer_stats = buffer.get_stats()
    
    metrics = f"""
# HELP events_processed_total Total events processed
# TYPE events_processed_total counter
events_processed_total {stats.total_events}

# HELP events_per_second Current events per second
# TYPE events_per_second gauge
events_per_second {stats.events_per_second}

# HELP buffer_utilization Buffer utilization ratio
# TYPE buffer_utilization gauge
buffer_utilization {buffer_stats['utilization']}

# HELP buffer_dropped_total Total events dropped
# TYPE buffer_dropped_total counter
buffer_dropped_total {buffer_stats['total_dropped']}

# HELP processing_errors_total Total processing errors
# TYPE processing_errors_total counter
processing_errors_total {stats.error_count}
"""
    
    return metrics
```

### Step 7: Create Data Generator for Testing

**Copilot Prompt Suggestion:**
```python
# Create a high-performance data generator that:
# - Generates realistic sensor data, user events, and system metrics
# - Supports configurable event rate (up to 50k events/sec)
# - Simulates multiple data sources
# - Includes realistic patterns (trends, seasonality, anomalies)
# - Can generate bursts and varying load patterns
# - Connects via WebSocket for streaming
# Include command line arguments for configuration
```

[Continue to Part 3 for Data Generator, Dashboard, and Testing...]
