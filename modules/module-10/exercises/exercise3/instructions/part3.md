# Exercise 3: Real-time Streaming Analytics Platform (Part 3)

### Step 7: Create Data Generator (continued)

**Expected Output:**
```python
# data_generator.py
import asyncio
import websockets
import json
import time
import random
import math
import argparse
import logging
from datetime import datetime
import numpy as np
from models.events import StreamEvent, EventType

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DataGenerator:
    def __init__(self, target_rate: int = 1000, num_sources: int = 100):
        self.target_rate = target_rate
        self.num_sources = num_sources
        self.running = False
        
        # Source configurations
        self.sensors = [f"sensor_{i:04d}" for i in range(num_sources)]
        self.users = [f"user_{i:06d}" for i in range(num_sources * 10)]
        
        # Pattern generators
        self.time_offset = time.time()
        
    def generate_sensor_data(self, sensor_id: str) -> StreamEvent:
        """Generate realistic sensor data with patterns"""
        current_time = time.time() - self.time_offset
        
        # Base value with daily pattern
        base_value = 50 + 20 * math.sin(2 * math.pi * current_time / 86400)
        
        # Add hourly variation
        hourly_var = 5 * math.sin(2 * math.pi * current_time / 3600)
        
        # Add noise
        noise = np.random.normal(0, 2)
        
        # Occasional anomalies (1% chance)
        if random.random() < 0.01:
            noise += random.choice([-20, 20])
        
        value = base_value + hourly_var + noise
        
        return StreamEvent(
            source=sensor_id,
            type=EventType.SENSOR_DATA,
            data={
                "value": round(value, 2),
                "unit": "celsius",
                "quality": random.choice(["good", "good", "good", "degraded"]),
                "location": f"zone_{hash(sensor_id) % 10}"
            },
            metadata={
                "sensor_type": "temperature",
                "firmware": "v2.1.3"
            }
        )
    
    def generate_user_event(self) -> StreamEvent:
        """Generate user behavior events"""
        user_id = random.choice(self.users)
        
        # Event types with weights
        event_weights = {
            "page_view": 0.4,
            "click": 0.3,
            "purchase": 0.05,
            "search": 0.15,
            "logout": 0.1
        }
        
        event_type = random.choices(
            list(event_weights.keys()),
            weights=list(event_weights.values())
        )[0]
        
        event_data = {
            "user_id": user_id,
            "event": event_type,
            "session_id": f"session_{hash(user_id) % 1000}",
            "platform": random.choice(["web", "mobile", "tablet"])
        }
        
        # Add event-specific data
        if event_type == "page_view":
            event_data["page"] = random.choice(["/home", "/products", "/about", "/contact"])
            event_data["duration"] = random.randint(5, 300)
        elif event_type == "purchase":
            event_data["amount"] = round(random.uniform(10, 500), 2)
            event_data["items"] = random.randint(1, 5)
        elif event_type == "search":
            event_data["query"] = f"product_{random.randint(1, 1000)}"
            event_data["results"] = random.randint(0, 100)
        
        return StreamEvent(
            source="web_app",
            type=EventType.USER_ACTION,
            data=event_data
        )
    
    def generate_system_metric(self) -> StreamEvent:
        """Generate system performance metrics"""
        host = f"server_{random.randint(1, 20):02d}"
        
        # CPU follows a pattern with spikes
        base_cpu = 30 + 20 * random.random()
        if random.random() < 0.05:  # 5% chance of spike
            base_cpu = 80 + 15 * random.random()
        
        return StreamEvent(
            source=host,
            type=EventType.SYSTEM_METRIC,
            data={
                "cpu_percent": round(base_cpu, 1),
                "memory_percent": round(40 + 30 * random.random(), 1),
                "disk_io_read": random.randint(0, 1000000),
                "disk_io_write": random.randint(0, 500000),
                "network_in": random.randint(0, 10000000),
                "network_out": random.randint(0, 5000000),
                "active_connections": random.randint(10, 1000)
            },
            metadata={
                "datacenter": f"dc_{hash(host) % 3}",
                "rack": f"rack_{hash(host) % 10}"
            }
        )
    
    async def generate_events(self, batch_size: int = 100) -> list:
        """Generate a batch of mixed events"""
        events = []
        
        # Event type distribution
        for _ in range(batch_size):
            rand = random.random()
            if rand < 0.6:  # 60% sensor data
                sensor = random.choice(self.sensors)
                events.append(self.generate_sensor_data(sensor))
            elif rand < 0.85:  # 25% user events
                events.append(self.generate_user_event())
            else:  # 15% system metrics
                events.append(self.generate_system_metric())
        
        return events
    
    async def run(self, websocket_url: str):
        """Run the data generator"""
        self.running = True
        total_sent = 0
        start_time = time.time()
        
        async with websockets.connect(websocket_url) as websocket:
            logger.info(f"Connected to {websocket_url}")
            
            while self.running:
                try:
                    # Calculate batch size based on target rate
                    elapsed = time.time() - start_time
                    expected = self.target_rate * elapsed
                    behind = expected - total_sent
                    
                    # Adaptive batch sizing
                    batch_size = min(max(int(behind), 10), 1000)
                    
                    # Generate and send events
                    events = await self.generate_events(batch_size)
                    
                    for event in events:
                        await websocket.send(event.to_bytes())
                        total_sent += 1
                    
                    # Calculate actual rate
                    actual_rate = total_sent / elapsed if elapsed > 0 else 0
                    
                    # Log progress every 1000 events
                    if total_sent % 1000 == 0:
                        logger.info(
                            f"Sent {total_sent} events, "
                            f"Rate: {actual_rate:.0f}/sec "
                            f"(target: {self.target_rate}/sec)"
                        )
                    
                    # Micro-sleep to control rate
                    if actual_rate > self.target_rate:
                        await asyncio.sleep(0.001)
                        
                except websockets.exceptions.ConnectionClosed:
                    logger.error("Connection closed")
                    break
                except Exception as e:
                    logger.error(f"Error: {e}")
                    await asyncio.sleep(1)

class LoadPatternGenerator(DataGenerator):
    """Generate data with specific load patterns"""
    
    def __init__(self, pattern: str = "steady", **kwargs):
        super().__init__(**kwargs)
        self.pattern = pattern
        self.pattern_start = time.time()
    
    def get_current_rate(self) -> int:
        """Get rate based on pattern"""
        elapsed = time.time() - self.pattern_start
        
        if self.pattern == "steady":
            return self.target_rate
            
        elif self.pattern == "ramp":
            # Ramp up over 5 minutes
            ramp_duration = 300
            progress = min(elapsed / ramp_duration, 1.0)
            return int(self.target_rate * progress)
            
        elif self.pattern == "spike":
            # Normal rate with periodic spikes
            spike_interval = 60  # Every minute
            spike_duration = 10  # 10 seconds
            
            if elapsed % spike_interval < spike_duration:
                return self.target_rate * 5  # 5x spike
            return self.target_rate
            
        elif self.pattern == "wave":
            # Sinusoidal pattern
            period = 300  # 5-minute waves
            amplitude = 0.5
            base = 1 - amplitude
            multiplier = base + amplitude * math.sin(2 * math.pi * elapsed / period)
            return int(self.target_rate * multiplier)
    
    async def run(self, websocket_url: str):
        """Run with dynamic rate adjustment"""
        self.running = True
        total_sent = 0
        
        async with websockets.connect(websocket_url) as websocket:
            logger.info(f"Connected with {self.pattern} pattern")
            
            while self.running:
                try:
                    # Get current target rate
                    current_rate = self.get_current_rate()
                    
                    # Generate appropriate batch
                    batch_size = max(1, current_rate // 100)  # 10ms batches
                    events = await self.generate_events(batch_size)
                    
                    for event in events:
                        await websocket.send(event.to_bytes())
                        total_sent += 1
                    
                    # Brief sleep
                    await asyncio.sleep(0.01)
                    
                    # Log pattern changes
                    if total_sent % 1000 == 0:
                        logger.info(
                            f"Pattern: {self.pattern}, "
                            f"Current rate: {current_rate}/sec, "
                            f"Total sent: {total_sent}"
                        )
                        
                except Exception as e:
                    logger.error(f"Error: {e}")
                    await asyncio.sleep(1)

async def main():
    parser = argparse.ArgumentParser(description="Stream data generator")
    parser.add_argument("--url", default="ws://localhost:8000/ws/ingest", help="WebSocket URL")
    parser.add_argument("--rate", type=int, default=1000, help="Target events per second")
    parser.add_argument("--sources", type=int, default=100, help="Number of data sources")
    parser.add_argument("--pattern", choices=["steady", "ramp", "spike", "wave"], 
                       default="steady", help="Load pattern")
    parser.add_argument("--duration", type=int, default=0, help="Duration in seconds (0=infinite)")
    
    args = parser.parse_args()
    
    # Create generator based on pattern
    if args.pattern == "steady":
        generator = DataGenerator(args.rate, args.sources)
    else:
        generator = LoadPatternGenerator(args.pattern, target_rate=args.rate, 
                                       num_sources=args.sources)
    
    # Run with optional duration limit
    if args.duration > 0:
        task = asyncio.create_task(generator.run(args.url))
        await asyncio.sleep(args.duration)
        generator.running = False
        await task
    else:
        await generator.run(args.url)

if __name__ == "__main__":
    asyncio.run(main())
```

### Step 8: Create Live Dashboard

Create `static/dashboard.html`:

**Copilot Prompt Suggestion:**
```html
<!-- Create a real-time analytics dashboard that:
- Shows live event rate with sparkline chart
- Displays aggregation results in real-time
- Shows system health metrics
- Implements auto-reconnecting SSE client
- Uses Chart.js for visualizations
- Responsive grid layout
- Updates smoothly without flicker
Include performance optimizations for high update rates -->
```

**Expected Output:**
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Streaming Analytics Dashboard</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        .metric-card {
            transition: all 0.3s ease;
        }
        .metric-value {
            transition: all 0.5s ease;
        }
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.5; }
            100% { opacity: 1; }
        }
        .updating {
            animation: pulse 1s infinite;
        }
    </style>
</head>
<body class="bg-gray-900 text-white">
    <div class="container mx-auto p-4">
        <h1 class="text-3xl font-bold mb-6">Streaming Analytics Dashboard</h1>
        
        <!-- System Status -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
            <div class="metric-card bg-gray-800 rounded-lg p-4">
                <h3 class="text-sm text-gray-400">Events/Second</h3>
                <p class="metric-value text-3xl font-bold" id="event-rate">0</p>
                <canvas id="rate-sparkline" height="50"></canvas>
            </div>
            
            <div class="metric-card bg-gray-800 rounded-lg p-4">
                <h3 class="text-sm text-gray-400">Buffer Utilization</h3>
                <p class="metric-value text-3xl font-bold" id="buffer-util">0%</p>
                <div class="w-full bg-gray-700 rounded-full h-2 mt-2">
                    <div id="buffer-bar" class="bg-blue-600 h-2 rounded-full" style="width: 0%"></div>
                </div>
            </div>
            
            <div class="metric-card bg-gray-800 rounded-lg p-4">
                <h3 class="text-sm text-gray-400">Total Processed</h3>
                <p class="metric-value text-3xl font-bold" id="total-events">0</p>
                <p class="text-xs text-gray-500" id="drop-rate">0% dropped</p>
            </div>
            
            <div class="metric-card bg-gray-800 rounded-lg p-4">
                <h3 class="text-sm text-gray-400">Processing Latency</h3>
                <p class="metric-value text-3xl font-bold" id="latency">0ms</p>
                <p class="text-xs text-gray-500">p99: <span id="p99-latency">0ms</span></p>
            </div>
        </div>
        
        <!-- Charts Row -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
            <!-- Real-time Line Chart -->
            <div class="bg-gray-800 rounded-lg p-4">
                <h3 class="text-lg font-semibold mb-2">Real-time Sensor Data</h3>
                <canvas id="realtime-chart"></canvas>
            </div>
            
            <!-- Aggregation Bar Chart -->
            <div class="bg-gray-800 rounded-lg p-4">
                <h3 class="text-lg font-semibold mb-2">Window Aggregations</h3>
                <canvas id="aggregation-chart"></canvas>
            </div>
        </div>
        
        <!-- Event Type Distribution -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="bg-gray-800 rounded-lg p-4">
                <h3 class="text-lg font-semibold mb-2">Event Distribution</h3>
                <canvas id="distribution-chart"></canvas>
            </div>
            
            <!-- Top Sources -->
            <div class="bg-gray-800 rounded-lg p-4">
                <h3 class="text-lg font-semibold mb-2">Top Sources</h3>
                <div id="top-sources" class="space-y-2">
                    <!-- Dynamically populated -->
                </div>
            </div>
            
            <!-- Alerts -->
            <div class="bg-gray-800 rounded-lg p-4">
                <h3 class="text-lg font-semibold mb-2">Alerts</h3>
                <div id="alerts" class="space-y-2 max-h-64 overflow-y-auto">
                    <!-- Dynamically populated -->
                </div>
            </div>
        </div>
    </div>
    
    <script src="/static/dashboard.js"></script>
</body>
</html>
```

Create `static/dashboard.js`:

```javascript
// Dashboard JavaScript
class StreamingDashboard {
    constructor() {
        this.eventSource = null;
        this.charts = {};
        this.metrics = {
            eventRate: [],
            bufferUtil: [],
            latencies: []
        };
        this.maxDataPoints = 60;  // 1 minute of data
        
        this.initializeCharts();
        this.connectEventStream();
        this.startMetricsPolling();
    }
    
    initializeCharts() {
        // Rate sparkline
        const sparklineCtx = document.getElementById('rate-sparkline').getContext('2d');
        this.charts.sparkline = new Chart(sparklineCtx, {
            type: 'line',
            data: {
                labels: Array(30).fill(''),
                datasets: [{
                    data: Array(30).fill(0),
                    borderColor: 'rgb(59, 130, 246)',
                    borderWidth: 2,
                    fill: false,
                    tension: 0.4,
                    pointRadius: 0
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: false } },
                scales: {
                    x: { display: false },
                    y: { display: false }
                }
            }
        });
        
        // Real-time line chart
        const realtimeCtx = document.getElementById('realtime-chart').getContext('2d');
        this.charts.realtime = new Chart(realtimeCtx, {
            type: 'line',
            data: {
                labels: [],
                datasets: [{
                    label: 'Sensor Value',
                    data: [],
                    borderColor: 'rgb(34, 197, 94)',
                    backgroundColor: 'rgba(34, 197, 94, 0.1)',
                    tension: 0.1
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: { display: true }
                },
                scales: {
                    x: {
                        type: 'time',
                        time: { unit: 'second' }
                    },
                    y: { beginAtZero: true }
                }
            }
        });
        
        // Aggregation chart
        const aggCtx = document.getElementById('aggregation-chart').getContext('2d');
        this.charts.aggregation = new Chart(aggCtx, {
            type: 'bar',
            data: {
                labels: [],
                datasets: [{
                    label: 'Event Count',
                    data: [],
                    backgroundColor: 'rgba(239, 68, 68, 0.5)'
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: { beginAtZero: true }
                }
            }
        });
        
        // Distribution chart
        const distCtx = document.getElementById('distribution-chart').getContext('2d');
        this.charts.distribution = new Chart(distCtx, {
            type: 'doughnut',
            data: {
                labels: ['Sensor Data', 'User Actions', 'System Metrics'],
                datasets: [{
                    data: [0, 0, 0],
                    backgroundColor: [
                        'rgba(59, 130, 246, 0.8)',
                        'rgba(34, 197, 94, 0.8)',
                        'rgba(239, 68, 68, 0.8)'
                    ]
                }]
            }
        });
    }
    
    connectEventStream() {
        this.eventSource = new EventSource('/stream/metrics');
        
        this.eventSource.onmessage = (event) => {
            const data = JSON.parse(event.data);
            this.handleAggregation(data);
        };
        
        this.eventSource.onerror = () => {
            console.error('EventSource error, reconnecting...');
            setTimeout(() => this.connectEventStream(), 5000);
        };
    }
    
    async startMetricsPolling() {
        setInterval(async () => {
            try {
                const response = await fetch('/api/stats');
                const stats = await response.json();
                this.updateMetrics(stats);
            } catch (error) {
                console.error('Failed to fetch stats:', error);
            }
        }, 1000);
    }
    
    updateMetrics(stats) {
        // Update event rate
        const eventRate = Math.round(stats.processor.events_per_second);
        document.getElementById('event-rate').textContent = eventRate.toLocaleString();
        
        // Update sparkline
        this.metrics.eventRate.push(eventRate);
        if (this.metrics.eventRate.length > 30) {
            this.metrics.eventRate.shift();
        }
        this.charts.sparkline.data.datasets[0].data = this.metrics.eventRate;
        this.charts.sparkline.update('none');
        
        // Update buffer utilization
        const bufferUtil = Math.round(stats.buffer.utilization * 100);
        document.getElementById('buffer-util').textContent = `${bufferUtil}%`;
        document.getElementById('buffer-bar').style.width = `${bufferUtil}%`;
        
        // Color code buffer bar
        const bufferBar = document.getElementById('buffer-bar');
        if (bufferUtil > 90) {
            bufferBar.className = 'bg-red-600 h-2 rounded-full transition-all';
        } else if (bufferUtil > 70) {
            bufferBar.className = 'bg-yellow-600 h-2 rounded-full transition-all';
        } else {
            bufferBar.className = 'bg-green-600 h-2 rounded-full transition-all';
        }
        
        // Update total events
        document.getElementById('total-events').textContent = 
            stats.processor.total_events.toLocaleString();
        
        // Update drop rate
        const dropRate = (stats.buffer.drop_rate * 100).toFixed(2);
        document.getElementById('drop-rate').textContent = `${dropRate}% dropped`;
        
        // Update latency
        const latency = Math.round(stats.processor.processing_time_ms);
        document.getElementById('latency').textContent = `${latency}ms`;
    }
    
    handleAggregation(data) {
        // Update aggregation chart
        const chart = this.charts.aggregation;
        const time = new Date(data.window_start * 1000).toLocaleTimeString();
        
        chart.data.labels.push(time);
        chart.data.datasets[0].data.push(data.event_count);
        
        // Keep only last 10 windows
        if (chart.data.labels.length > 10) {
            chart.data.labels.shift();
            chart.data.datasets[0].data.shift();
        }
        
        chart.update();
        
        // Update real-time chart if sensor data
        if (data.aggregates.value) {
            const rtChart = this.charts.realtime;
            const avgValue = data.aggregates.value.avg || 0;
            
            rtChart.data.labels.push(new Date());
            rtChart.data.datasets[0].data.push(avgValue);
            
            // Keep only last 60 points
            if (rtChart.data.labels.length > 60) {
                rtChart.data.labels.shift();
                rtChart.data.datasets[0].data.shift();
            }
            
            rtChart.update('none');
        }
        
        // Check for alerts
        this.checkAlerts(data);
    }
    
    checkAlerts(data) {
        const alerts = [];
        
        // Check for anomalies
        if (data.aggregates.value) {
            const stats = data.aggregates.value;
            if (stats.max > 80) {
                alerts.push({
                    level: 'warning',
                    message: `High sensor value detected: ${stats.max.toFixed(1)}`
                });
            }
            if (stats.std > 10) {
                alerts.push({
                    level: 'info',
                    message: `High variance detected: σ=${stats.std.toFixed(1)}`
                });
            }
        }
        
        // Display alerts
        if (alerts.length > 0) {
            const alertsDiv = document.getElementById('alerts');
            alerts.forEach(alert => {
                const alertEl = document.createElement('div');
                alertEl.className = `p-2 rounded text-sm ${
                    alert.level === 'warning' ? 'bg-yellow-900' : 'bg-blue-900'
                }`;
                alertEl.textContent = `${new Date().toLocaleTimeString()}: ${alert.message}`;
                alertsDiv.insertBefore(alertEl, alertsDiv.firstChild);
                
                // Keep only last 10 alerts
                while (alertsDiv.children.length > 10) {
                    alertsDiv.removeChild(alertsDiv.lastChild);
                }
            });
        }
    }
}

// Initialize dashboard
document.addEventListener('DOMContentLoaded', () => {
    new StreamingDashboard();
});
```

### Step 9: Performance Testing

Create `test_streaming_performance.py`:

```python
# test_streaming_performance.py
import asyncio
import time
import statistics
import websockets
import json
from concurrent.futures import ProcessPoolExecutor
import multiprocessing as mp

async def load_test_client(client_id: int, url: str, duration: int, rate: int):
    """Single load test client"""
    sent = 0
    errors = 0
    latencies = []
    
    start_time = time.time()
    
    try:
        async with websockets.connect(url) as ws:
            while time.time() - start_time < duration:
                # Generate batch
                batch_size = rate // 100  # 10ms batches
                
                for _ in range(batch_size):
                    event_time = time.time()
                    event = {
                        "source": f"load_test_{client_id}",
                        "type": "sensor_data",
                        "timestamp": event_time,
                        "data": {"value": 50 + 10 * (client_id % 10)}
                    }
                    
                    try:
                        send_start = time.time()
                        await ws.send(json.dumps(event).encode())
                        latencies.append((time.time() - send_start) * 1000)
                        sent += 1
                    except Exception:
                        errors += 1
                
                await asyncio.sleep(0.01)
                
    except Exception as e:
        print(f"Client {client_id} error: {e}")
    
    return {
        "client_id": client_id,
        "sent": sent,
        "errors": errors,
        "latencies": latencies
    }

async def run_load_test(num_clients: int, duration: int, total_rate: int):
    """Run distributed load test"""
    url = "ws://localhost:8000/ws/ingest"
    rate_per_client = total_rate // num_clients
    
    print(f"Starting load test with {num_clients} clients")
    print(f"Target rate: {total_rate} events/sec ({rate_per_client}/client)")
    print(f"Duration: {duration} seconds")
    
    # Run clients
    tasks = []
    for i in range(num_clients):
        task = asyncio.create_task(
            load_test_client(i, url, duration, rate_per_client)
        )
        tasks.append(task)
    
    # Wait for completion
    results = await asyncio.gather(*tasks)
    
    # Aggregate results
    total_sent = sum(r["sent"] for r in results)
    total_errors = sum(r["errors"] for r in results)
    all_latencies = []
    for r in results:
        all_latencies.extend(r["latencies"])
    
    # Calculate statistics
    actual_rate = total_sent / duration
    error_rate = total_errors / (total_sent + total_errors) if total_sent > 0 else 0
    
    print("\n=== Load Test Results ===")
    print(f"Total events sent: {total_sent:,}")
    print(f"Total errors: {total_errors:,}")
    print(f"Actual rate: {actual_rate:,.0f} events/sec")
    print(f"Error rate: {error_rate:.2%}")
    
    if all_latencies:
        print(f"\nLatency Statistics (ms):")
        print(f"  Min: {min(all_latencies):.2f}")
        print(f"  Avg: {statistics.mean(all_latencies):.2f}")
        print(f"  Med: {statistics.median(all_latencies):.2f}")
        print(f"  P95: {statistics.quantiles(all_latencies, n=20)[18]:.2f}")
        print(f"  P99: {statistics.quantiles(all_latencies, n=100)[98]:.2f}")
        print(f"  Max: {max(all_latencies):.2f}")

if __name__ == "__main__":
    # Test configurations
    tests = [
        {"clients": 10, "duration": 30, "rate": 1000},
        {"clients": 20, "duration": 30, "rate": 5000},
        {"clients": 50, "duration": 30, "rate": 10000},
        {"clients": 100, "duration": 30, "rate": 25000},
    ]
    
    for test in tests:
        print(f"\n{'='*50}")
        asyncio.run(run_load_test(**test))
        time.sleep(5)  # Cool down between tests
```

## 🏆 Success Criteria

Your streaming platform should:
- ✅ Handle 10,000+ events per second
- ✅ Maintain <100ms processing latency
- ✅ Display real-time analytics dashboard
- ✅ Handle backpressure gracefully
- ✅ Provide accurate aggregations
- ✅ Scale with multiple workers

## 🔧 Troubleshooting

### Performance Issues
```python
# Profile the system
import cProfile
import pstats

profiler = cProfile.Profile()
profiler.enable()
# ... run code ...
profiler.disable()
stats = pstats.Stats(profiler).sort_stats('cumulative')
stats.print_stats()
```

### Memory Leaks
- Monitor object counts
- Use weak references for caches
- Implement proper cleanup

### WebSocket Disconnections
- Implement exponential backoff
- Use connection pooling
- Monitor connection health

## 🚀 Production Deployment

1. **Horizontal Scaling:**
   - Deploy multiple processor instances
   - Use Redis Streams for durability
   - Implement service discovery

2. **Monitoring:**
   - Export Prometheus metrics
   - Set up Grafana dashboards
   - Configure alerting

3. **Security:**
   - Add authentication to WebSocket
   - Implement rate limiting
   - Use TLS for connections

## 📊 Performance Optimization

1. **Buffer Tuning:**
   - Adjust buffer size based on load
   - Implement multi-level buffering
   - Use memory-mapped files for overflow

2. **Processing Optimization:**
   - Use PyPy for better performance
   - Implement Cython for hot paths
   - Consider Rust for critical components

3. **Network Optimization:**
   - Enable TCP_NODELAY
   - Use binary protocols (MessagePack)
   - Implement compression

## 🎯 Key Takeaways

1. **Streaming requires careful resource management**
2. **Backpressure handling is critical at scale**
3. **Time windows enable real-time analytics**
4. **Async programming maximizes throughput**
5. **Monitoring is essential for production systems**

---

## 🎉 Congratulations!

You've built a production-grade streaming analytics platform capable of processing millions of events! This system demonstrates advanced concepts in:

- High-performance async programming
- Real-time data processing
- Distributed system design
- Production monitoring
- Scalable architectures

### Next Steps

1. Try implementing additional features:
   - Machine learning pipelines
   - Complex event processing (CEP)
   - Distributed state management

2. Explore advanced topics:
   - Apache Kafka integration
   - Kubernetes deployment
   - Multi-region distribution

3. Review the [best practices](../../best-practices.md) for production deployment

You've mastered Module 10! Ready to move on to [Module 11: Microservices Architecture](../../module-11-microservices/README.md)?
