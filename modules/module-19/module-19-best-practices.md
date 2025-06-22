# Module 19: Monitoring and Observability Best Practices

## 🎯 Production Monitoring Patterns

This guide provides enterprise-grade patterns and best practices for implementing monitoring and observability in production systems.

## 📊 The Three Pillars of Observability

### 1. Metrics
```python
# Best Practice: Use standardized metric naming
class MetricNaming:
    """Consistent metric naming convention."""
    
    @staticmethod
    def format_metric_name(
        namespace: str,
        subsystem: str,
        name: str,
        unit: str = None
    ) -> str:
        """
        Format: namespace_subsystem_name_unit
        Example: api_orders_processing_duration_seconds
        """
        parts = [namespace, subsystem, name]
        if unit:
            parts.append(unit)
        return "_".join(parts)

# Implementation
from prometheus_client import Counter, Histogram, Gauge

# Good metric definitions
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    ['method', 'endpoint'],
    buckets=[.005, .01, .025, .05, .1, .25, .5, 1, 2.5, 5, 10]
)

active_connections = Gauge(
    'active_connections',
    'Number of active connections',
    ['service']
)
```

### 2. Logs
```python
# Best Practice: Structured logging with context
import structlog
from typing import Any, Dict
import json

def configure_structured_logging(
    service_name: str,
    environment: str,
    log_level: str = "INFO"
) -> structlog.BoundLogger:
    """Configure structured logging with best practices."""
    
    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            add_service_context,
            sanitize_sensitive_data,
            structlog.processors.JSONRenderer()
        ],
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,
    )
    
    logger = structlog.get_logger()
    logger = logger.bind(
        service=service_name,
        environment=environment,
        version=get_service_version()
    )
    
    return logger

def add_service_context(logger, method_name, event_dict):
    """Add service context to all logs."""
    event_dict["correlation_id"] = get_correlation_id()
    event_dict["user_id"] = get_current_user_id()
    event_dict["request_id"] = get_request_id()
    return event_dict

def sanitize_sensitive_data(logger, method_name, event_dict):
    """Remove sensitive data from logs."""
    sensitive_fields = ["password", "token", "api_key", "credit_card"]
    
    for field in sensitive_fields:
        if field in event_dict:
            event_dict[field] = "***REDACTED***"
            
    return event_dict
```

### 3. Traces
```python
# Best Practice: Rich trace context
from opentelemetry import trace
from opentelemetry.trace import Status, StatusCode
from typing import Optional, Dict, Any
import functools

def traced_operation(
    operation_name: str,
    attributes: Optional[Dict[str, Any]] = None,
    track_exceptions: bool = True
):
    """Decorator for traced operations with best practices."""
    def decorator(func):
        @functools.wraps(func)
        async def async_wrapper(*args, **kwargs):
            tracer = trace.get_tracer(__name__)
            
            with tracer.start_as_current_span(
                operation_name,
                kind=trace.SpanKind.INTERNAL
            ) as span:
                # Add standard attributes
                span.set_attribute("operation.name", operation_name)
                span.set_attribute("operation.version", "1.0")
                
                # Add custom attributes
                if attributes:
                    for key, value in attributes.items():
                        span.set_attribute(key, str(value))
                
                # Add function arguments as attributes
                if args:
                    span.set_attribute("args.count", len(args))
                if kwargs:
                    for k, v in kwargs.items():
                        if not _is_sensitive(k):
                            span.set_attribute(f"arg.{k}", str(v))
                
                try:
                    result = await func(*args, **kwargs)
                    span.set_status(Status(StatusCode.OK))
                    return result
                    
                except Exception as e:
                    if track_exceptions:
                        span.record_exception(e)
                        span.set_status(
                            Status(StatusCode.ERROR, str(e))
                        )
                    raise
                    
        @functools.wraps(func)
        def sync_wrapper(*args, **kwargs):
            # Similar implementation for sync functions
            pass
            
        return async_wrapper if asyncio.iscoroutinefunction(func) else sync_wrapper
    return decorator
```

## 🏗️ Architecture Patterns

### 1. Centralized Telemetry Pipeline
```yaml
# Best Practice: Use OpenTelemetry Collector
# otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  prometheus:
    config:
      scrape_configs:
        - job_name: 'services'
          scrape_interval: 30s
          static_configs:
            - targets: ['service1:8080', 'service2:8080']

processors:
  batch:
    timeout: 10s
    send_batch_size: 1024
  
  memory_limiter:
    check_interval: 1s
    limit_mib: 512
    spike_limit_mib: 128
  
  attributes:
    actions:
      - key: environment
        value: production
        action: upsert
      - key: sensitive.data
        action: delete

exporters:
  azuremonitor:
    connection_string: ${APPLICATIONINSIGHTS_CONNECTION_STRING}
  
  prometheus:
    endpoint: "0.0.0.0:8889"
    
  logging:
    loglevel: info

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch, attributes]
      exporters: [azuremonitor, logging]
    
    metrics:
      receivers: [otlp, prometheus]
      processors: [memory_limiter, batch]
      exporters: [azuremonitor, prometheus]
```

### 2. Service Mesh Observability
```python
# Best Practice: Automatic instrumentation with service mesh
class ServiceMeshObservability:
    """Integrate with service mesh for automatic observability."""
    
    def __init__(self):
        self.mesh_headers = [
            "x-request-id",
            "x-b3-traceid",
            "x-b3-spanid",
            "x-b3-parentspanid",
            "x-b3-sampled",
            "x-b3-flags",
            "x-ot-span-context"
        ]
    
    def extract_trace_context(self, headers: Dict[str, str]) -> Dict[str, str]:
        """Extract trace context from service mesh headers."""
        context = {}
        
        for header in self.mesh_headers:
            if header in headers:
                context[header] = headers[header]
                
        return context
    
    def propagate_context(
        self,
        outgoing_request: httpx.Request,
        incoming_headers: Dict[str, str]
    ):
        """Propagate trace context to downstream services."""
        context = self.extract_trace_context(incoming_headers)
        
        for header, value in context.items():
            outgoing_request.headers[header] = value
```

## 📈 Monitoring Strategies

### 1. Golden Signals (Google SRE)
```python
class GoldenSignals:
    """Monitor the four golden signals."""
    
    def __init__(self, metrics_client):
        self.metrics = metrics_client
    
    def track_latency(self, operation: str, duration: float):
        """Track request latency."""
        self.metrics.histogram(
            "latency",
            duration,
            tags={"operation": operation}
        )
    
    def track_traffic(self, operation: str):
        """Track request rate."""
        self.metrics.increment(
            "requests",
            tags={"operation": operation}
        )
    
    def track_errors(self, operation: str, error_type: str):
        """Track error rate."""
        self.metrics.increment(
            "errors",
            tags={
                "operation": operation,
                "error_type": error_type
            }
        )
    
    def track_saturation(self, resource: str, utilization: float):
        """Track resource saturation."""
        self.metrics.gauge(
            "saturation",
            utilization,
            tags={"resource": resource}
        )
```

### 2. RED Method (Rate, Errors, Duration)
```python
class REDMetrics:
    """Implement RED method for service monitoring."""
    
    def __init__(self):
        self.request_rate = Counter(
            'service_request_rate',
            'Request rate',
            ['service', 'method', 'endpoint']
        )
        
        self.error_rate = Counter(
            'service_error_rate',
            'Error rate',
            ['service', 'method', 'endpoint', 'error_type']
        )
        
        self.request_duration = Histogram(
            'service_request_duration_seconds',
            'Request duration',
            ['service', 'method', 'endpoint']
        )
    
    def record_request(
        self,
        service: str,
        method: str,
        endpoint: str,
        duration: float,
        error: Optional[str] = None
    ):
        """Record RED metrics for a request."""
        # Rate
        self.request_rate.labels(
            service=service,
            method=method,
            endpoint=endpoint
        ).inc()
        
        # Errors
        if error:
            self.error_rate.labels(
                service=service,
                method=method,
                endpoint=endpoint,
                error_type=error
            ).inc()
        
        # Duration
        self.request_duration.labels(
            service=service,
            method=method,
            endpoint=endpoint
        ).observe(duration)
```

## 🚨 Alerting Best Practices

### 1. Alert Design
```python
class AlertDesign:
    """Best practices for alert design."""
    
    @staticmethod
    def create_slo_based_alert(
        slo_target: float,
        window_minutes: int,
        burn_rate_threshold: float
    ) -> Dict[str, Any]:
        """Create SLO-based alerts using error budget burn rate."""
        return {
            "name": "SLO Burn Rate Alert",
            "condition": f"""
                error_rate_1h > {(100 - slo_target) * burn_rate_threshold}
                AND
                error_rate_5m > {(100 - slo_target) * burn_rate_threshold * 2}
            """,
            "description": f"Error budget burn rate exceeds {burn_rate_threshold}x",
            "severity": "critical" if burn_rate_threshold > 10 else "warning",
            "actions": ["page_oncall", "create_incident"]
        }
    
    @staticmethod
    def create_predictive_alert(
        metric: str,
        forecast_window: str,
        threshold: float
    ) -> Dict[str, Any]:
        """Create predictive alerts using forecasting."""
        return {
            "name": f"Predictive {metric} Alert",
            "condition": f"""
                predict_linear({metric}[1h], {forecast_window}) > {threshold}
            """,
            "description": f"{metric} predicted to exceed {threshold} in {forecast_window}",
            "severity": "warning",
            "actions": ["notify_team", "auto_scale"]
        }
```

### 2. Alert Fatigue Prevention
```python
class AlertFatiguePrevention:
    """Prevent alert fatigue with intelligent alerting."""
    
    def __init__(self):
        self.alert_history = {}
        self.suppression_rules = []
    
    def should_alert(
        self,
        alert_name: str,
        severity: str,
        context: Dict[str, Any]
    ) -> bool:
        """Determine if alert should fire."""
        # Check suppression rules
        if self._is_suppressed(alert_name, context):
            return False
        
        # Check recent alert frequency
        if self._is_too_frequent(alert_name):
            return False
        
        # Check business hours for non-critical
        if severity != "critical" and not self._is_business_hours():
            return False
        
        # Check maintenance windows
        if self._in_maintenance_window():
            return False
        
        return True
    
    def _is_too_frequent(self, alert_name: str) -> bool:
        """Check if alert is firing too frequently."""
        history = self.alert_history.get(alert_name, [])
        recent_alerts = [
            alert for alert in history
            if alert > datetime.utcnow() - timedelta(hours=1)
        ]
        
        # Suppress if more than 5 alerts in last hour
        return len(recent_alerts) > 5
```

## 💰 Cost Optimization

### 1. Sampling Strategies
```python
class SamplingStrategy:
    """Intelligent sampling for cost optimization."""
    
    def __init__(self):
        self.base_sample_rate = 0.1  # 10% default
        self.rules = []
    
    def should_sample(self, context: Dict[str, Any]) -> bool:
        """Determine if request should be sampled."""
        # Always sample errors
        if context.get("error"):
            return True
        
        # Always sample slow requests
        if context.get("duration", 0) > 1000:  # 1 second
            return True
        
        # Higher sampling for critical endpoints
        if context.get("endpoint") in CRITICAL_ENDPOINTS:
            return random.random() < 0.5  # 50% sampling
        
        # Adaptive sampling based on traffic
        traffic_rate = context.get("traffic_rate", 0)
        if traffic_rate > 1000:  # High traffic
            sample_rate = max(0.01, 100 / traffic_rate)  # At least 100 samples/sec
        else:
            sample_rate = self.base_sample_rate
        
        return random.random() < sample_rate
```

### 2. Data Retention Policies
```python
class RetentionPolicy:
    """Optimize storage costs with intelligent retention."""
    
    RETENTION_RULES = {
        "raw_logs": {
            "hot": 7,      # Days in hot storage
            "warm": 30,    # Days in warm storage
            "cold": 90,    # Days in cold storage
            "archive": 365 # Days in archive
        },
        "metrics": {
            "1m_resolution": 7,
            "5m_resolution": 30,
            "1h_resolution": 90,
            "1d_resolution": 365
        },
        "traces": {
            "detailed": 3,
            "sampled": 30
        }
    }
    
    def apply_retention(self, data_type: str, age_days: int) -> str:
        """Determine storage tier based on data age."""
        rules = self.RETENTION_RULES.get(data_type, {})
        
        if age_days <= rules.get("hot", 7):
            return "hot"
        elif age_days <= rules.get("warm", 30):
            return "warm"
        elif age_days <= rules.get("cold", 90):
            return "cold"
        else:
            return "archive"
```

## 🔍 Debugging Production Issues

### 1. Distributed Debugging
```python
class DistributedDebugger:
    """Tools for debugging distributed systems."""
    
    async def trace_request_path(self, trace_id: str) -> Dict[str, Any]:
        """Reconstruct complete request path."""
        # Gather all spans for trace
        spans = await self.get_spans_for_trace(trace_id)
        
        # Build service graph
        service_graph = self.build_service_graph(spans)
        
        # Identify critical path
        critical_path = self.find_critical_path(spans)
        
        # Find bottlenecks
        bottlenecks = self.identify_bottlenecks(spans)
        
        return {
            "trace_id": trace_id,
            "total_duration": self.calculate_total_duration(spans),
            "services_involved": list(service_graph.nodes()),
            "critical_path": critical_path,
            "bottlenecks": bottlenecks,
            "errors": self.extract_errors(spans)
        }
```

### 2. Correlation Analysis
```python
class CorrelationAnalysis:
    """Correlate events across different data sources."""
    
    async def correlate_incident(
        self,
        incident_time: datetime,
        window_minutes: int = 30
    ) -> Dict[str, Any]:
        """Correlate all events around an incident."""
        start_time = incident_time - timedelta(minutes=window_minutes/2)
        end_time = incident_time + timedelta(minutes=window_minutes/2)
        
        # Gather all data sources
        tasks = [
            self.get_metrics_anomalies(start_time, end_time),
            self.get_error_logs(start_time, end_time),
            self.get_deployment_events(start_time, end_time),
            self.get_infrastructure_changes(start_time, end_time),
            self.get_traffic_patterns(start_time, end_time)
        ]
        
        results = await asyncio.gather(*tasks)
        
        # Correlate events
        correlations = self.find_correlations(results)
        
        return {
            "incident_time": incident_time,
            "anomalies": results[0],
            "errors": results[1],
            "deployments": results[2],
            "infra_changes": results[3],
            "traffic": results[4],
            "correlations": correlations,
            "probable_cause": self.determine_probable_cause(correlations)
        }
```

## 📚 Recommended Reading

1. **"Observability Engineering"** - Charity Majors, Liz Fong-Jones, George Miranda
2. **"Distributed Tracing in Practice"** - Austin Parker, Daniel Spoonhower
3. **"Site Reliability Engineering"** - Google SRE Team
4. **"The Art of Monitoring"** - James Turnbull
5. **"Practical Monitoring"** - Mike Julian

## 🎯 Monitoring Maturity Model

### Level 1: Basic Monitoring
- Health checks and uptime monitoring
- Basic metrics (CPU, memory, disk)
- Log aggregation

### Level 2: Application Monitoring
- APM implementation
- Custom business metrics
- Basic alerting

### Level 3: Distributed Tracing
- End-to-end request tracing
- Service dependency mapping
- Performance profiling

### Level 4: Proactive Monitoring
- Predictive alerting
- Anomaly detection
- Automated remediation

### Level 5: Business-Aligned Observability
- Business KPI tracking
- User journey analytics
- Cost optimization
- Full AIOps implementation

Remember: **You can't improve what you don't measure, but measuring everything doesn't mean understanding anything.**