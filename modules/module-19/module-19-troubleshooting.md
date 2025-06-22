# Module 19: Monitoring and Observability Troubleshooting Guide

## 🔍 Common Issues and Solutions

This guide helps you diagnose and resolve common monitoring and observability issues encountered in Module 19.

## 🚨 Application Insights Issues

### 1. No Data Appearing in Application Insights

**Symptoms:**
- Empty Application Insights dashboard
- No metrics or traces visible
- Connection appears successful but no data

**Diagnosis Steps:**

```python
# 1. Verify connection string
import os
from applicationinsights import TelemetryClient

def test_app_insights_connection():
    """Test Application Insights connectivity."""
    connection_string = os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING")
    
    if not connection_string:
        print("❌ No connection string found in environment")
        return False
    
    try:
        # Test connection
        client = TelemetryClient(connection_string)
        client.track_event("ConnectionTest", {"test": "true"})
        client.flush()
        print("✅ Test event sent successfully")
        return True
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return False

# 2. Check instrumentation key format
def validate_connection_string(conn_str):
    """Validate connection string format."""
    required_parts = ["InstrumentationKey", "IngestionEndpoint"]
    
    for part in required_parts:
        if part not in conn_str:
            print(f"❌ Missing {part} in connection string")
            return False
    
    return True
```

**Common Solutions:**

| Issue | Solution |
|-------|----------|
| Wrong connection string | Get from Azure Portal → Application Insights → Overview |
| Firewall blocking | Allow outbound HTTPS to `*.applicationinsights.azure.com` |
| Local testing | Use Live Metrics Stream to see real-time data |
| Sampling too aggressive | Set `SAMPLING_RATE=1.0` for testing |
| Data delay | Wait 2-5 minutes for data to appear |

### 2. Missing Distributed Traces

**Symptoms:**
- Individual service traces visible but not connected
- No end-to-end transaction view
- Broken trace correlation

**Diagnosis:**

```python
# Check trace propagation
def verify_trace_propagation(request_headers):
    """Verify trace context headers are present."""
    required_headers = [
        "traceparent",  # W3C Trace Context
        "tracestate"    # W3C Trace State
    ]
    
    missing = []
    for header in required_headers:
        if header not in request_headers:
            missing.append(header)
    
    if missing:
        print(f"❌ Missing trace headers: {missing}")
        return False
    
    # Validate traceparent format
    traceparent = request_headers.get("traceparent", "")
    parts = traceparent.split("-")
    
    if len(parts) != 4:
        print("❌ Invalid traceparent format")
        return False
    
    print(f"✅ Valid trace context: {traceparent}")
    return True
```

**Solutions:**

```python
# 1. Ensure proper instrumentation order
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor

# CORRECT ORDER - Instrument before creating app
FastAPIInstrumentor.instrument()
HTTPXClientInstrumentor.instrument()

app = FastAPI()  # Create app AFTER instrumentation

# 2. Manual context propagation
from opentelemetry import propagate

async def call_downstream_service(url: str, headers: dict):
    """Manually propagate trace context."""
    # Inject current context into headers
    propagate.inject(headers)
    
    async with httpx.AsyncClient() as client:
        response = await client.get(url, headers=headers)
    
    return response
```

### 3. High Monitoring Costs

**Symptoms:**
- Unexpectedly high Azure bill
- Data ingestion exceeding limits
- Cost alerts firing

**Diagnosis:**

```kql
// Query to analyze data volume by type
union *
| where timestamp > ago(24h)
| summarize 
    Count = count(),
    SizeInMB = sum(_BilledSize) / (1024*1024)
    by itemType
| order by SizeInMB desc

// Find high-volume operations
requests
| where timestamp > ago(1h)
| summarize Count = count() by operation_Name, cloud_RoleName
| order by Count desc
| take 20
```

**Cost Optimization Solutions:**

```python
# 1. Implement intelligent sampling
class CostOptimizedSampler:
    def should_sample(self, span_context, parent_context):
        # Always sample errors
        if span_context.attributes.get("error", False):
            return True
            
        # Sample health checks at very low rate
        if span_context.attributes.get("http.route") == "/health":
            return random.random() < 0.001  # 0.1%
        
        # Sample based on operation importance
        operation = span_context.attributes.get("operation")
        sampling_rates = {
            "critical": 1.0,     # 100%
            "important": 0.1,    # 10%
            "normal": 0.01,      # 1%
            "verbose": 0.001     # 0.1%
        }
        
        rate = sampling_rates.get(
            self.get_operation_importance(operation), 
            0.01
        )
        return random.random() < rate

# 2. Reduce log verbosity
import logging

def configure_cost_optimized_logging():
    # Set appropriate log levels
    logging.getLogger("azure").setLevel(logging.WARNING)
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("httpx").setLevel(logging.WARNING)
    
    # Filter out noisy logs
    class NoiseFilter(logging.Filter):
        def filter(self, record):
            # Skip health check logs
            if "/health" in record.getMessage():
                return False
            return True
    
    logging.getLogger().addFilter(NoiseFilter())
```

## 📊 Dashboard and Query Issues

### 1. KQL Queries Timing Out

**Symptoms:**
- Query timeout errors
- Slow dashboard loading
- "Query exceeded resource limits"

**Solutions:**

```kql
// Optimize queries with time filters and limits
// ❌ BAD - Scans all data
requests
| where success == false
| order by timestamp desc

// ✅ GOOD - Uses index efficiently
requests
| where timestamp > ago(1h)
| where success == false
| project timestamp, operation_Name, duration, resultCode
| order by timestamp desc
| take 100

// Use summarize instead of sorting large datasets
// ❌ BAD
requests
| where timestamp > ago(24h)
| order by duration desc
| take 10

// ✅ GOOD
requests
| where timestamp > ago(24h)
| summarize MaxDuration = max(duration) by operation_Name
| order by MaxDuration desc
| take 10
```

### 2. Dashboard Not Updating

**Symptoms:**
- Stale data in dashboards
- Refresh not working
- Missing recent metrics

**Diagnosis:**

```python
# Check data freshness
async def check_data_freshness():
    """Verify recent data is being ingested."""
    query = """
    union *
    | where timestamp > ago(10m)
    | summarize Count = count() by bin(timestamp, 1m), itemType
    | order by timestamp desc
    """
    
    results = await execute_kql_query(query)
    
    if not results:
        print("❌ No recent data found")
        return False
    
    latest_timestamp = results[0]["timestamp"]
    delay = datetime.utcnow() - latest_timestamp
    
    if delay.total_seconds() > 300:  # 5 minutes
        print(f"⚠️ Data delay: {delay.total_seconds()}s")
    else:
        print(f"✅ Data is current (delay: {delay.total_seconds()}s)")
    
    return True
```

## 🔗 Integration Issues

### 1. Prometheus Metrics Not Exporting

**Symptoms:**
- Metrics endpoint returns empty
- Azure Monitor not receiving Prometheus metrics
- Grafana shows no data

**Solutions:**

```python
# 1. Verify Prometheus endpoint
from prometheus_client import generate_latest, REGISTRY
import asyncio

@app.get("/metrics")
async def metrics():
    """Expose Prometheus metrics."""
    # Force collection of all metrics
    for collector in list(REGISTRY._collector_to_names.keys()):
        try:
            collector.collect()
        except Exception as e:
            logger.error(f"Collector error: {e}")
    
    return Response(
        generate_latest(REGISTRY),
        media_type="text/plain; charset=utf-8"
    )

# 2. Debug metric registration
def debug_prometheus_metrics():
    """List all registered metrics."""
    print("Registered metrics:")
    for collector in REGISTRY._collector_to_names:
        for metric in collector.collect():
            print(f"- {metric.name}: {metric.documentation}")
```

### 2. Log Analytics Query Issues

**Symptoms:**
- No logs in Log Analytics
- Query syntax errors
- Permission denied errors

**Solutions:**

```python
# Verify Log Analytics connection
from azure.monitor.query import LogsQueryClient
from azure.identity import DefaultAzureCredential

async def test_log_analytics():
    """Test Log Analytics connectivity."""
    credential = DefaultAzureCredential()
    client = LogsQueryClient(credential)
    
    workspace_id = os.getenv("AZURE_LOG_ANALYTICS_WORKSPACE_ID")
    
    query = """
    AppRequests
    | take 1
    """
    
    try:
        response = await client.query_workspace(
            workspace_id=workspace_id,
            query=query,
            timespan="PT1H"  # Last 1 hour
        )
        
        if response.tables:
            print("✅ Log Analytics connection successful")
            return True
        else:
            print("⚠️ No data found in Log Analytics")
            return False
            
    except Exception as e:
        print(f"❌ Log Analytics error: {e}")
        return False
```

## 🚦 Performance Issues

### 1. High Telemetry Overhead

**Symptoms:**
- Application performance degradation
- High CPU usage from telemetry
- Memory leaks

**Solutions:**

```python
# 1. Use batch processing
from opentelemetry.sdk.trace.export import BatchSpanProcessor

def configure_efficient_telemetry():
    """Configure telemetry for minimal overhead."""
    # Use batch processor instead of simple
    span_processor = BatchSpanProcessor(
        exporter,
        max_queue_size=2048,
        max_export_batch_size=512,
        schedule_delay_millis=5000,  # 5 seconds
        export_timeout_millis=30000
    )
    
    # Limit cardinality
    resource = Resource.create({
        "service.name": SERVICE_NAME,
        "service.version": VERSION,
        # Don't include high-cardinality attributes here
    })

# 2. Async telemetry operations
class AsyncTelemetry:
    def __init__(self):
        self.queue = asyncio.Queue(maxsize=10000)
        self.task = asyncio.create_task(self._process_queue())
    
    async def track_event_async(self, event_name, properties):
        """Non-blocking event tracking."""
        try:
            await self.queue.put_nowait({
                "name": event_name,
                "properties": properties,
                "timestamp": datetime.utcnow()
            })
        except asyncio.QueueFull:
            logger.warning("Telemetry queue full, dropping event")
    
    async def _process_queue(self):
        """Process telemetry queue in background."""
        while True:
            try:
                # Batch process events
                events = []
                for _ in range(min(100, self.queue.qsize())):
                    event = await self.queue.get()
                    events.append(event)
                
                if events:
                    await self._send_batch(events)
                    
            except Exception as e:
                logger.error(f"Telemetry processing error: {e}")
            
            await asyncio.sleep(1)
```

## 🛠️ Debugging Tools

### 1. Local Debugging Setup

```python
# Enable detailed telemetry logging
import logging

logging.basicConfig(level=logging.DEBUG)
logging.getLogger("opentelemetry").setLevel(logging.DEBUG)
logging.getLogger("azure").setLevel(logging.DEBUG)

# Trace HTTP requests
import httpx

class DebugTransport(httpx.HTTPTransport):
    def handle_request(self, request):
        print(f"📤 Request: {request.method} {request.url}")
        print(f"Headers: {dict(request.headers)}")
        response = super().handle_request(request)
        print(f"📥 Response: {response.status_code}")
        return response

# Use debug transport
client = httpx.Client(transport=DebugTransport())
```

### 2. Validation Scripts

Create `scripts/validate-monitoring.py`:

```python
#!/usr/bin/env python3
"""Validate monitoring setup."""

import asyncio
import sys
from datetime import datetime

async def validate_all():
    """Run all validation checks."""
    checks = [
        ("Application Insights", validate_app_insights),
        ("Trace Propagation", validate_traces),
        ("Metrics Export", validate_metrics),
        ("Log Analytics", validate_logs),
        ("Dashboards", validate_dashboards),
        ("Alerts", validate_alerts)
    ]
    
    print("🔍 Validating Monitoring Setup\n")
    
    failed = 0
    for name, check_func in checks:
        print(f"Checking {name}...", end=" ")
        try:
            result = await check_func()
            if result:
                print("✅")
            else:
                print("❌")
                failed += 1
        except Exception as e:
            print(f"❌ ({e})")
            failed += 1
    
    print(f"\n{'='*50}")
    if failed == 0:
        print("✅ All checks passed!")
        return 0
    else:
        print(f"❌ {failed} checks failed")
        return 1

if __name__ == "__main__":
    sys.exit(asyncio.run(validate_all()))
```

## 📝 Quick Reference

### Common Commands

```bash
# Check Application Insights ingestion
curl -X POST https://dc.applicationinsights.azure.com/v2/track \
  -H "Content-Type: application/json" \
  -d '{"name":"test","time":"'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'"}'

# Test OpenTelemetry collector
curl http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{"resourceSpans":[]}'

# View Prometheus metrics
curl http://localhost:8000/metrics

# Check service health
curl http://localhost:8000/health/status
```

### Environment Variables Checklist

```bash
# Required
APPLICATIONINSIGHTS_CONNECTION_STRING=
AZURE_LOG_ANALYTICS_WORKSPACE_ID=
AZURE_LOG_ANALYTICS_WORKSPACE_KEY=

# Optional but recommended
OTEL_SERVICE_NAME=
OTEL_RESOURCE_ATTRIBUTES=
OTEL_EXPORTER_OTLP_ENDPOINT=
OTEL_TRACES_SAMPLER=
OTEL_TRACES_SAMPLER_ARG=
```

Remember: **Good monitoring is like insurance - you hope you never need it, but you're glad it's there when you do!**