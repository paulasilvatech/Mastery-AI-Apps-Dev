---
sidebar_position: 7
title: "Exercise 3: Part 1"
description: "## 🎯 Exercise Overview"
---

# Ejercicio 3: Real-time Streaming Análisis Platform (⭐⭐⭐)

## 🎯 Resumen del Ejercicio

Build a production-grade streaming analytics platform that processes high-volume data streams, performs real-time aggregations, and provides live dashboards. This advanced exercise combines WebSockets, Server-Sent Events (SSE), stream processing, and complex async patterns to create a system capable of handling thousands of events per second.

### Duración: 60-90 minutos

### Objectives
- Implement high-performance data ingestion pipeline
- Build real-time stream processing with windowing
- Create live analytics dashboard with multiple visualizations
- Handle backpressure and flow control
- Implement distributed aggregations
- Scale to handle 10,000+ events/second

### Success Metrics
- ✅ Process 10,000+ events per second
- ✅ Sub-100ms latency for aggregations
- ✅ Real-time dashboard updates
- ✅ Graceful handling of traffic spikes
- ✅ Data accuracy under load
- ✅ Memory-efficient stream processing

## 🏗️ Architecture Resumen

```mermaid
graph TB
    subgraph "Data Sources"
        DS1[IoT Sensors]
        DS2[Application Logs]
        DS3[User Events]
    end
    
    subgraph "Ingestion Layer"
        WS[WebSocket Gateway]
        HTTP[HTTP API]
        Buffer[Ring Buffer]
    end
    
    subgraph "Processing Layer"
        SP[Stream Processor]
        AGG[Aggregation Engine]
        ML[ML Pipeline]
    end
    
    subgraph "Storage Layer"
        TS[(Time Series DB)]
        Cache[(Redis Cache)]
        S3[(Object Storage)]
    end
    
    subgraph "Delivery Layer"
        SSE[SSE Stream]
        WSOut[WebSocket Out]
        API[Query API]
    end
    
    subgraph "UI Layer"
        Dash[Live Dashboard]
        Alerts[Alert Manager]
    end
    
    DS1 --&gt; WS
    DS2 --&gt; HTTP
    DS3 --&gt; HTTP
    
    WS --&gt; Buffer
    HTTP --&gt; Buffer
    
    Buffer --&gt; SP
    SP --&gt; AGG
    SP --&gt; ML
    
    AGG --&gt; TS
    AGG --&gt; Cache
    ML --&gt; S3
    
    Cache --&gt; SSE
    Cache --&gt; WSOut
    TS --&gt; API
    
    SSE --&gt; Dash
    WSOut --&gt; Dash
    API --&gt; Dash
    Cache --&gt; Alerts
```

## 📝 Step-by-Step Instructions

### Step 1: Project Setup

Create the project structure:
```bash
mkdir exercise3-streaming-platform
cd exercise3-streaming-platform

# Create directories
mkdir processors
mkdir aggregators
mkdir models
mkdir static
mkdir utils

# Create files
touch main.py
touch models/events.py
touch models/metrics.py
touch processors/stream_processor.py
touch processors/ml_processor.py
touch aggregators/time_window.py
touch aggregators/statistics.py
touch utils/buffer.py
touch utils/rate_limiter.py
touch data_generator.py
touch requirements.txt
```

Create `requirements.txt`:
```text
fastapi==0.104.1
uvicorn[standard]==0.24.0
websockets==12.0
aioredis==2.0.1
numpy==1.24.3
pandas==2.1.4
asyncio-throttle==1.0.2
prometheus-client==0.19.0
msgpack==1.0.7
orjson==3.9.10
```

### Step 2: Define Data Models

**Copilot Prompt Suggestion:**
```python
# Create high-performance data models for streaming that:
# 1. Event model with: id, source, type, timestamp, data (dict), metadata
# 2. Metric model for aggregations: name, value, tags, timestamp
# 3. WindowedAggregate: window_start, window_end, aggregates (dict)
# 4. StreamStats: count, sum, min, max, avg, p50, p95, p99
# Use orjson for fast serialization
# Include validation but optimize for performance
```

**Expected Output:**
```python
# models/events.py
from pydantic import BaseModel, Field
from typing import Dict, Any, Optional, List
from datetime import datetime
import orjson
import uuid
from enum import Enum

def orjson_dumps(v, *, default):
    return orjson.dumps(v, default=default).decode()

class EventType(str, Enum):
    SENSOR_DATA = "sensor_data"
    USER_ACTION = "user_action"
    SYSTEM_METRIC = "system_metric"
    ERROR_LOG = "error_log"

class StreamEvent(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    source: str
    type: EventType
    timestamp: float = Field(default_factory=lambda: datetime.utcnow().timestamp())
    data: Dict[str, Any]
    metadata: Optional[Dict[str, Any]] = {}
    
    class Config:
        json_loads = orjson.loads
        json_dumps = orjson_dumps
        
    def to_bytes(self) -&gt; bytes:
        """Serialize to bytes for high-speed processing"""
        return orjson.dumps(self.dict())
    
    @classmethod
    def from_bytes(cls, data: bytes) -&gt; 'StreamEvent':
        """Deserialize from bytes"""
        return cls(**orjson.loads(data))
```

```python
# models/metrics.py
from pydantic import BaseModel, Field
from typing import Dict, List, Optional
from datetime import datetime
import numpy as np
import orjson

class StreamMetric(BaseModel):
    name: str
    value: float
    tags: Dict[str, str] = {}
    timestamp: float = Field(default_factory=lambda: datetime.utcnow().timestamp())
    
    class Config:
        json_loads = orjson.loads
        json_dumps = lambda v, *, default: orjson.dumps(v, default=default).decode()

class WindowedAggregate(BaseModel):
    window_start: float
    window_end: float
    event_count: int = 0
    aggregates: Dict[str, Dict[str, float]] = {}
    
    def add_event(self, event: StreamEvent):
        """Add event to window aggregation"""
        self.event_count += 1
        
        # Extract numeric values for aggregation
        for key, value in event.data.items():
            if isinstance(value, (int, float)):
                if key not in self.aggregates:
                    self.aggregates[key] = {
                        "count": 0,
                        "sum": 0,
                        "min": float('inf'),
                        "max": float('-inf'),
                        "values": []
                    }
                
                agg = self.aggregates[key]
                agg["count"] += 1
                agg["sum"] += value
                agg["min"] = min(agg["min"], value)
                agg["max"] = max(agg["max"], value)
                agg["values"].append(value)
    
    def finalize(self):
        """Calculate final statistics"""
        for key, agg in self.aggregates.items():
            values = np.array(agg["values"])
            agg["avg"] = np.mean(values)
            agg["std"] = np.std(values)
            agg["p50"] = np.percentile(values, 50)
            agg["p95"] = np.percentile(values, 95)
            agg["p99"] = np.percentile(values, 99)
            del agg["values"]  # Remove raw values to save memory

class StreamStats(BaseModel):
    total_events: int = 0
    events_per_second: float = 0
    bytes_processed: int = 0
    processing_time_ms: float = 0
    error_count: int = 0
    backpressure_events: int = 0
    
    def update(self, events: int, bytes: int, time_ms: float):
        self.total_events += events
        self.bytes_processed += bytes
        self.processing_time_ms = time_ms
```

### Step 3: Create High-Performance Buffer

**Copilot Prompt Suggestion:**
```python
# Create a lock-free ring buffer for high-speed event processing that:
# - Uses fixed-size circular buffer with atomic operations
# - Supports multiple producers, single consumer pattern
# - Implements backpressure handling
# - Provides batch read operations
# - Monitors buffer utilization
# - Zero-copy where possible
# Include memory-efficient implementation
```

**Expected Output:**
```python
# utils/buffer.py
import asyncio
from typing import List, Optional, Callable
from collections import deque
import time
import logging

logger = logging.getLogger(__name__)

class RingBuffer:
    def __init__(self, capacity: int = 100000):
        self.capacity = capacity
        self.buffer = deque(maxlen=capacity)
        self.lock = asyncio.Lock()
        self.not_empty = asyncio.Condition(self.lock)
        self.not_full = asyncio.Condition(self.lock)
        
        # Statistics
        self.total_added = 0
        self.total_dropped = 0
        self.high_water_mark = 0
        
    async def add(self, item: bytes, timeout: float = 0.1) -&gt; bool:
        """Add item to buffer with backpressure handling"""
        async with self.not_full:
            try:
                # Wait if buffer is full
                while len(self.buffer) &gt;= self.capacity:
                    await asyncio.wait_for(self.not_full.wait(), timeout)
                    
                self.buffer.append(item)
                self.total_added += 1
                self.high_water_mark = max(self.high_water_mark, len(self.buffer))
                self.not_empty.notify()
                return True
                
            except asyncio.TimeoutError:
                self.total_dropped += 1
                logger.warning(f"Buffer full, dropped event. Total dropped: {self.total_dropped}")
                return False
    
    async def add_batch(self, items: List[bytes]) -&gt; int:
        """Add multiple items efficiently"""
        added = 0
        async with self.lock:
            available_space = self.capacity - len(self.buffer)
            to_add = items[:available_space]
            
            self.buffer.extend(to_add)
            added = len(to_add)
            self.total_added += added
            
            dropped = len(items) - added
            if dropped &gt; 0:
                self.total_dropped += dropped
                logger.warning(f"Buffer overflow, dropped {dropped} events")
            
            if added &gt; 0:
                self.not_empty.notify_all()
                
            self.high_water_mark = max(self.high_water_mark, len(self.buffer))
            
        return added
    
    async def get_batch(self, max_items: int = 1000, timeout: float = 1.0) -&gt; List[bytes]:
        """Get batch of items for processing"""
        async with self.not_empty:
            try:
                # Wait for at least one item
                while len(self.buffer) == 0:
                    await asyncio.wait_for(self.not_empty.wait(), timeout)
                
                # Get up to max_items
                batch = []
                for _ in range(min(max_items, len(self.buffer))):
                    batch.append(self.buffer.popleft())
                
                # Notify producers if buffer was full
                if len(self.buffer) &lt; self.capacity:
                    self.not_full.notify_all()
                
                return batch
                
            except asyncio.TimeoutError:
                return []
    
    def get_stats(self) -&gt; dict:
        """Get buffer statistics"""
        return {
            "current_size": len(self.buffer),
            "capacity": self.capacity,
            "utilization": len(self.buffer) / self.capacity,
            "total_added": self.total_added,
            "total_dropped": self.total_dropped,
            "high_water_mark": self.high_water_mark,
            "drop_rate": self.total_dropped / max(1, self.total_added + self.total_dropped)
        }

class AdaptiveBuffer(RingBuffer):
    """Ring buffer with adaptive capacity based on load"""
    
    def __init__(self, initial_capacity: int = 100000, max_capacity: int = 1000000):
        super().__init__(initial_capacity)
        self.max_capacity = max_capacity
        self.resize_threshold = 0.9
        self.last_resize = time.time()
        self.resize_cooldown = 60  # seconds
        
    async def add(self, item: bytes, timeout: float = 0.1) -&gt; bool:
        """Add with adaptive resizing"""
        result = await super().add(item, timeout)
        
        # Check if resize needed
        if (len(self.buffer) / self.capacity &gt; self.resize_threshold and
            self.capacity &lt; self.max_capacity and
            time.time() - self.last_resize &gt; self.resize_cooldown):
            
            await self._resize()
            
        return result
    
    async def _resize(self):
        """Increase buffer capacity"""
        async with self.lock:
            new_capacity = min(int(self.capacity * 1.5), self.max_capacity)
            logger.info(f"Resizing buffer from {self.capacity} to {new_capacity}")
            
            # Create new deque with larger capacity
            new_buffer = deque(self.buffer, maxlen=new_capacity)
            self.buffer = new_buffer
            self.capacity = new_capacity
            self.last_resize = time.time()
```

### Step 4: Create Stream Processor

**Copilot Prompt Suggestion:**
```python
# Create a high-performance stream processor that:
# - Processes events in batches for efficiency
# - Implements parallel processing pipelines
# - Handles different event types with type-specific processors
# - Monitors processing latency and throughput
# - Implements error handling with dead letter queue
# - Supports hot-reload of processing rules
# Use async/await throughout for maximum concurrency
```

**Expected Output:**
```python
# processors/stream_processor.py
import asyncio
from typing import Dict, List, Callable, Any, Optional
from datetime import datetime
import time
import logging
from models.events import StreamEvent, EventType
from models.metrics import StreamStats

logger = logging.getLogger(__name__)

class StreamProcessor:
    def __init__(self, buffer, num_workers: int = 4):
        self.buffer = buffer
        self.num_workers = num_workers
        self.processors: Dict[EventType, List[Callable]] = {
            EventType.SENSOR_DATA: [],
            EventType.USER_ACTION: [],
            EventType.SYSTEM_METRIC: [],
            EventType.ERROR_LOG: []
        }
        self.stats = StreamStats()
        self.running = False
        self.workers = []
        
        # Output queues
        self.output_queues: Dict[str, asyncio.Queue] = {}
        
    def register_processor(self, event_type: EventType, processor: Callable):
        """Register a processor for specific event type"""
        self.processors[event_type].append(processor)
        logger.info(f"Registered processor for {event_type}")
    
    def register_output_queue(self, name: str, queue: asyncio.Queue):
        """Register output queue for processed data"""
        self.output_queues[name] = queue
    
    async def start(self):
        """Start processing workers"""
        self.running = True
        
        # Start worker tasks
        for i in range(self.num_workers):
            worker = asyncio.create_task(self._process_worker(i))
            self.workers.append(worker)
        
        # Start stats reporter
        asyncio.create_task(self._stats_reporter())
        
        logger.info(f"Started {self.num_workers} stream processing workers")
    
    async def stop(self):
        """Stop all workers"""
        self.running = False
        await asyncio.gather(*self.workers, return_exceptions=True)
    
    async def _process_worker(self, worker_id: int):
        """Worker coroutine for processing events"""
        logger.info(f"Worker {worker_id} started")
        
        while self.running:
            try:
                # Get batch of events
                start_time = time.time()
                batch = await self.buffer.get_batch(max_items=100, timeout=1.0)
                
                if not batch:
                    continue
                
                # Process batch
                processed = 0
                total_bytes = 0
                
                for item in batch:
                    try:
                        # Deserialize event
                        event = StreamEvent.from_bytes(item)
                        total_bytes += len(item)
                        
                        # Apply processors
                        await self._process_event(event)
                        processed += 1
                        
                    except Exception as e:
                        logger.error(f"Error processing event: {e}")
                        self.stats.error_count += 1
                
                # Update stats
                processing_time = (time.time() - start_time) * 1000
                self.stats.update(processed, total_bytes, processing_time)
                
                # Calculate events per second
                if processing_time &gt; 0:
                    self.stats.events_per_second = processed / (processing_time / 1000)
                
            except Exception as e:
                logger.error(f"Worker {worker_id} error: {e}")
                await asyncio.sleep(0.1)
    
    async def _process_event(self, event: StreamEvent):
        """Process single event through pipeline"""
        # Get processors for event type
        processors = self.processors.get(event.type, [])
        
        # Apply each processor
        result = event
        for processor in processors:
            try:
                if asyncio.iscoroutinefunction(processor):
                    result = await processor(result)
                else:
                    result = processor(result)
                    
                # Allow processors to return None to filter events
                if result is None:
                    return
                    
            except Exception as e:
                logger.error(f"Processor error for {event.type}: {e}")
                raise
        
        # Send to output queues
        for queue in self.output_queues.values():
            try:
                await queue.put(result)
            except asyncio.QueueFull:
                self.stats.backpressure_events += 1
    
    async def _stats_reporter(self):
        """Report processing statistics periodically"""
        while self.running:
            await asyncio.sleep(5)
            
            stats = self.stats.dict()
            stats.update(self.buffer.get_stats())
            
            logger.info(
                f"Stream stats - Events/sec: {stats['events_per_second']:.0f}, "
                f"Total: {stats['total_events']}, "
                f"Errors: {stats['error_count']}, "
                f"Buffer: {stats['current_size']}/{stats['capacity']}"
            )

class EventEnricher:
    """Enrich events with additional data"""
    
    def __init__(self, cache):
        self.cache = cache
        
    async def __call__(self, event: StreamEvent) -&gt; StreamEvent:
        """Enrich event with cached data"""
        # Add processing timestamp
        event.metadata["processed_at"] = datetime.utcnow().timestamp()
        
        # Enrich based on event type
        if event.type == EventType.USER_ACTION:
            # Add user profile data from cache
            user_id = event.data.get("user_id")
            if user_id:
                profile = await self.cache.get(f"user:{user_id}")
                if profile:
                    event.metadata["user_profile"] = profile
        
        elif event.type == EventType.SENSOR_DATA:
            # Add sensor metadata
            sensor_id = event.source
            sensor_info = await self.cache.get(f"sensor:{sensor_id}")
            if sensor_info:
                event.metadata["sensor_info"] = sensor_info
        
        return event

class EventFilter:
    """Filter events based on rules"""
    
    def __init__(self, rules: Dict[str, Any]):
        self.rules = rules
        
    def __call__(self, event: StreamEvent) -&gt; Optional[StreamEvent]:
        """Apply filtering rules"""
        # Example: Filter by value threshold
        if event.type == EventType.SENSOR_DATA:
            threshold = self.rules.get("sensor_threshold", 0)
            value = event.data.get("value", 0)
            if value &lt; threshold:
                return None  # Filter out
        
        # Example: Filter by event age
        max_age = self.rules.get("max_age_seconds", float('inf'))
        age = datetime.utcnow().timestamp() - event.timestamp
        if age &gt; max_age:
            return None
        
        return event
```

[Continuar to Partee 2 for Aggregation Engine and Time Windows...]