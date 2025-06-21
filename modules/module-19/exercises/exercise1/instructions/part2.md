# Exercise 1: Part 2 - Dashboards and Alerting

## 🛠️ Creating Dashboards and Alerts

### Step 8: Create KQL Queries for Monitoring

Create `monitoring/queries/performance_queries.kql`:

**🤖 Copilot Prompt Suggestion #4:**
```kql
// Create KQL queries for:
// 1. Request success rate by endpoint (last 24h)
// 2. P50, P90, P95, P99 latency percentiles
// 3. Top 10 slowest operations
// 4. Error rate trending over time
// 5. Dependency performance (external calls)
// 6. Custom business metrics aggregation
// Include time-based filtering and service filtering
```

**Expected KQL Queries:**
```kql
// 1. Request Success Rate by Endpoint
requests
| where timestamp > ago(24h)
| where cloud_RoleName == "api-gateway"
| summarize 
    TotalRequests = count(),
    SuccessfulRequests = countif(success == true),
    FailedRequests = countif(success == false)
    by operation_Name, bin(timestamp, 5m)
| extend SuccessRate = round(100.0 * SuccessfulRequests / TotalRequests, 2)
| project timestamp, operation_Name, SuccessRate, TotalRequests
| render timechart

// 2. Latency Percentiles
requests
| where timestamp > ago(1h)
| summarize 
    P50 = percentile(duration, 50),
    P90 = percentile(duration, 90),
    P95 = percentile(duration, 95),
    P99 = percentile(duration, 99)
    by cloud_RoleName, bin(timestamp, 1m)
| render timechart

// 3. Top 10 Slowest Operations
requests
| where timestamp > ago(1h)
| where duration > 1000  // Over 1 second
| top 10 by duration desc
| project 
    timestamp,
    operation_Name,
    duration,
    resultCode,
    cloud_RoleName,
    customDimensions

// 4. Error Rate Trending
requests
| where timestamp > ago(24h)
| summarize 
    ErrorCount = countif(success == false),
    TotalCount = count()
    by bin(timestamp, 5m), cloud_RoleName
| extend ErrorRate = round(100.0 * ErrorCount / TotalCount, 2)
| render timechart

// 5. Dependency Performance
dependencies
| where timestamp > ago(1h)
| summarize 
    AvgDuration = avg(duration),
    MaxDuration = max(duration),
    FailureCount = countif(success == false)
    by target, type, bin(timestamp, 5m)
| render barchart
```

### Step 9: Create Custom Metrics Dashboard

Create `monitoring/dashboards/dashboard_config.json`:

**🤖 Copilot Prompt Suggestion #5:**
```json
// Create an Azure Dashboard configuration that includes:
// - Service health overview (traffic lights)
// - Request rate and error rate charts
// - Latency distribution heatmap
// - Business metrics (orders, revenue)
// - Infrastructure metrics (CPU, memory)
// - Live dependency map
// Use Azure Dashboard JSON format
```

### Step 10: Implement Health Check Endpoint

Update `services/api_gateway/monitoring.py`:

```python
from fastapi import APIRouter
from typing import Dict, Any, List
import httpx
import asyncio
from datetime import datetime

router = APIRouter(prefix="/health", tags=["monitoring"])

@router.get("/status")
async def health_status() -> Dict[str, Any]:
    """Comprehensive health check with dependency status."""
    health_checks = []
    
    # Check each downstream service
    for service_name, service_url in SERVICES.items():
        check_result = await check_service_health(service_name, service_url)
        health_checks.append(check_result)
    
    # Check Application Insights connectivity
    ai_status = check_application_insights()
    health_checks.append(ai_status)
    
    # Overall status
    all_healthy = all(check["status"] == "healthy" for check in health_checks)
    
    return {
        "status": "healthy" if all_healthy else "degraded",
        "timestamp": datetime.utcnow().isoformat(),
        "services": health_checks,
        "metrics": await get_current_metrics()
    }

async def check_service_health(name: str, url: str) -> Dict[str, Any]:
    """Check individual service health."""
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            start = datetime.utcnow()
            response = await client.get(f"{url}/health")
            duration = (datetime.utcnow() - start).total_seconds()
            
            return {
                "name": name,
                "status": "healthy" if response.status_code == 200 else "unhealthy",
                "response_time": duration,
                "status_code": response.status_code
            }
    except Exception as e:
        return {
            "name": name,
            "status": "unhealthy",
            "error": str(e)
        }

def check_application_insights() -> Dict[str, Any]:
    """Check Application Insights connectivity."""
    if telemetry._initialized and telemetry.telemetry_client:
        try:
            # Try to send a test event
            telemetry.telemetry_client.track_event("HealthCheck")
            telemetry.telemetry_client.flush()
            return {
                "name": "application_insights",
                "status": "healthy"
            }
        except Exception as e:
            return {
                "name": "application_insights",
                "status": "unhealthy",
                "error": str(e)
            }
    else:
        return {
            "name": "application_insights",
            "status": "not_configured"
        }

async def get_current_metrics() -> Dict[str, float]:
    """Get current system metrics."""
    # In production, these would come from actual metrics
    return {
        "requests_per_minute": 1250.5,
        "average_latency_ms": 45.3,
        "error_rate_percent": 0.05,
        "active_users": 342
    }
```

### Step 11: Configure Alerts

Create `monitoring/alerts/alert_rules.py`:

**🤖 Copilot Prompt Suggestion #6:**
```python
# Create alert configuration that:
# - Defines alert rules for high error rate (>5%)
# - Sets up latency alerts (P95 > 1 second)
# - Monitors service availability (<99.9%)
# - Tracks business anomalies (sudden order drop)
# - Implements smart alerting with anomaly detection
# - Includes action groups for notifications
# Use Azure Monitor Alert Rules API format
```

### Step 12: Create Performance Test

Create `tests/test_monitoring.py`:

```python
import asyncio
import httpx
import random
from datetime import datetime
from typing import List
import uuid

class MonitoringTest:
    def __init__(self, base_url: str = "http://localhost:8000"):
        self.base_url = base_url
        self.results = []
        
    async def simulate_user_journey(self, user_id: str):
        """Simulate a complete user journey with monitoring."""
        async with httpx.AsyncClient() as client:
            journey_id = str(uuid.uuid4())
            
            try:
                # 1. Browse products
                start = datetime.utcnow()
                response = await client.get(
                    f"{self.base_url}/products",
                    headers={"X-Journey-ID": journey_id}
                )
                browse_time = (datetime.utcnow() - start).total_seconds()
                
                # 2. Get user details
                start = datetime.utcnow()
                response = await client.get(
                    f"{self.base_url}/users/{user_id}",
                    headers={"X-Journey-ID": journey_id}
                )
                user_time = (datetime.utcnow() - start).total_seconds()
                
                # 3. Create order
                start = datetime.utcnow()
                order_data = {
                    "user_id": user_id,
                    "product_id": f"prod-{random.randint(1, 100)}",
                    "quantity": random.randint(1, 5),
                    "total_amount": round(random.uniform(10, 500), 2)
                }
                response = await client.post(
                    f"{self.base_url}/orders",
                    json=order_data,
                    headers={"X-Journey-ID": journey_id}
                )
                order_time = (datetime.utcnow() - start).total_seconds()
                
                self.results.append({
                    "journey_id": journey_id,
                    "user_id": user_id,
                    "status": "success",
                    "browse_time": browse_time,
                    "user_time": user_time,
                    "order_time": order_time,
                    "total_time": browse_time + user_time + order_time
                })
                
            except Exception as e:
                self.results.append({
                    "journey_id": journey_id,
                    "user_id": user_id,
                    "status": "failed",
                    "error": str(e)
                })
    
    async def run_load_test(self, num_users: int = 100, duration_seconds: int = 60):
        """Run load test with monitoring metrics."""
        print(f"Starting load test: {num_users} users over {duration_seconds} seconds")
        
        start_time = datetime.utcnow()
        tasks = []
        
        while (datetime.utcnow() - start_time).total_seconds() < duration_seconds:
            # Create new user sessions
            for _ in range(num_users // duration_seconds):
                user_id = f"user-{random.randint(1, 1000)}"
                task = asyncio.create_task(self.simulate_user_journey(user_id))
                tasks.append(task)
            
            await asyncio.sleep(1)
        
        # Wait for all tasks to complete
        await asyncio.gather(*tasks)
        
        # Generate report
        self.generate_report()
    
    def generate_report(self):
        """Generate performance test report."""
        successful = [r for r in self.results if r["status"] == "success"]
        failed = [r for r in self.results if r["status"] == "failed"]
        
        if successful:
            avg_total = sum(r["total_time"] for r in successful) / len(successful)
            p95_total = sorted([r["total_time"] for r in successful])[int(len(successful) * 0.95)]
            
            print("\n📊 Performance Test Results:")
            print(f"Total Requests: {len(self.results)}")
            print(f"Successful: {len(successful)} ({len(successful)/len(self.results)*100:.1f}%)")
            print(f"Failed: {len(failed)} ({len(failed)/len(self.results)*100:.1f}%)")
            print(f"Average Total Time: {avg_total:.3f}s")
            print(f"P95 Total Time: {p95_total:.3f}s")
            
            # Check if monitoring captured the load
            print("\n🔍 Check Application Insights for:")
            print("- Request rate spike")
            print("- Latency distribution")
            print("- Error patterns")
            print("- Custom metrics")

# Run the test
if __name__ == "__main__":
    test = MonitoringTest()
    asyncio.run(test.run_load_test(num_users=50, duration_seconds=30))
```

## 📊 Verifying Your Implementation

### Step 13: Check Application Insights

1. Navigate to Azure Portal
2. Open your Application Insights resource
3. Check the following views:
   - **Overview**: Request rate, failed requests, response time
   - **Application Map**: Service dependencies
   - **Performance**: Operation performance breakdown
   - **Failures**: Error analysis
   - **Metrics**: Custom metrics you've tracked

### Step 14: Create Your First Alert

1. In Application Insights, go to **Alerts**
2. Click **+ New alert rule**
3. Configure:
   ```yaml
   Scope: Your Application Insights resource
   Condition: 
     Signal: Failed requests
     Threshold: Greater than 10
     Aggregation: 5 minutes
   Action:
     Action group: Create new
     Notification: Email/SMS
   Alert rule details:
     Name: High Error Rate Alert
     Severity: 2 (Warning)
   ```

### Step 15: Build a Dashboard

1. Go to **Azure Dashboards**
2. Create new dashboard
3. Add tiles:
   - Application Insights metrics
   - Log Analytics queries
   - Service health
   - Custom KQL visualizations

## ✅ Exercise Completion Criteria

Your monitoring implementation is complete when:

1. **Auto-instrumentation works**: All HTTP requests are tracked
2. **Custom metrics appear**: Business metrics show in portal
3. **Logs are structured**: JSON format with correlation IDs
4. **Dashboard displays data**: Real-time metrics visible
5. **Alerts fire correctly**: Test by simulating failures
6. **Health check passes**: All services report healthy

## 🏆 Extension Challenges

If you finish early, try these additional challenges:

1. **Implement Distributed Tracing**: Add trace context propagation
2. **Add Performance Profiling**: Use Application Insights Profiler
3. **Create SLO Dashboard**: Track Service Level Objectives
4. **Implement Anomaly Detection**: Use AI to detect unusual patterns

## 📚 Key Takeaways

- Application Insights provides comprehensive APM out of the box
- Structured logging with correlation IDs is essential
- Custom metrics help track business KPIs
- Dashboards should tell a story, not just show data
- Proactive alerting prevents outages

## Next Steps

Congratulations on completing Exercise 1! You've built a foundation for monitoring. Proceed to Exercise 2 where you'll implement distributed tracing across microservices.

[Continue to Exercise 2 →](../exercise2-application/instructions.md)