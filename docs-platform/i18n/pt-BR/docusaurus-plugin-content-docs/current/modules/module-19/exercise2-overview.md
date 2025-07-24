---
sidebar_position: 5
title: "Exercise 2: Overview"
description: "## 🎯 Exercise Overview"
---

# Exercício 2: Distributed Tracing System (⭐⭐ Application)

## 🎯 Visão Geral do Exercício

**Duração**: 45-60 minutos  
**Difficulty**: ⭐⭐ (Médio)  
**Success Rate**: 80%

In this application-level exercise, you'll implement end-to-end distributed tracing across microservices using AbrirTelemetry and Azure Monitor. You'll learn to track requests across service boundaries, visualize complex workflows, and diagnose performance issues in distributed systems.

## 🎓 Objetivos de Aprendizagem

Ao completar este exercício, você irá:
- Implement AbrirTelemetry instrumentation across services
- Configure trace context propagation
- Build custom spans with rich attributes
- Visualize traces in Application Insights
- Diagnose performance bottlenecks
- Implement trace sampling for cost optimization

## 📋 Pré-requisitos

- ✅ Completard Exercício 1
- ✅ Understanding of distributed systems
- ✅ Basic knowledge of async programming
- ✅ Microservices running from Exercício 1

## 🏗️ What You'll Build

A distributed tracing system that tracks requests across multiple services:

```mermaid
graph LR
    Client[Client App] --&gt;|TraceID: abc123| Gateway[API Gateway]
    
    Gateway --&gt;|SpanID: 001| Auth[Auth Service]
    Gateway --&gt;|SpanID: 002| Order[Order Service]
    
    Order --&gt;|SpanID: 003| Inventory[Inventory Service]
    Order --&gt;|SpanID: 004| Payment[Payment Service]
    Order --&gt;|SpanID: 005| Cache[(Redis Cache)]
    
    Inventory --&gt;|SpanID: 006| DB1[(Inventory DB)]
    Payment --&gt;|SpanID: 007| ExtAPI[External Payment API]
    
    Auth --&gt; AI[Application Insights]
    Order --&gt; AI
    Inventory --&gt; AI
    Payment --&gt; AI
    
    AI --&gt; TraceView[Trace Timeline View]
    
    style AI fill:#f96,stroke:#333,stroke-width:2px
    style TraceView fill:#9f9,stroke:#333,stroke-width:2px
```

## 🚀 Implementation Steps

### Step 1: Enhanced Telemetry Configuration

Atualizar `services/shared/telemetry.py`:

**🤖 Copilot Prompt Suggestion #1:**
```python
# Enhance telemetry configuration to:
# - Set up OpenTelemetry with W3C TraceContext propagation
# - Configure batch span processor for efficiency
# - Implement dynamic sampling based on endpoint and error status
# - Add baggage propagation for cross-service context
# - Include resource attributes (service.name, deployment.environment)
# - Set up metrics and traces correlation
# Include retry logic and circuit breaker for exporter
```

**Expected Enhanced Implementation:**
```python
from opentelemetry import trace, baggage, context
from opentelemetry.propagate import set_global_textmap
from opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagator
from opentelemetry.sdk.trace import TracerProvider, SpanProcessor
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.resources import Resource, SERVICE_NAME, SERVICE_VERSION
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
from azure.monitor.opentelemetry.exporter import AzureMonitorTraceExporter
import logging

class DistributedTelemetry:
    def __init__(self):
        self.tracer_provider = None
        self.tracer = None
        self._initialized = False
        
    def initialize(
        self, 
        service_name: str,
        service_version: str = "1.0.0",
        environment: str = "development",
        connection_string: str = None
    ):
        """Initialize distributed tracing with OpenTelemetry."""
        try:
            # Create resource with service information
            resource = Resource.create({
                SERVICE_NAME: service_name,
                SERVICE_VERSION: service_version,
                "deployment.environment": environment,
                "service.namespace": "workshop",
                "telemetry.sdk.language": "python",
                "telemetry.sdk.name": "opentelemetry",
                "cloud.provider": "azure",
                "cloud.platform": "azure_app_service"
            })
            
            # Create and configure tracer provider
            self.tracer_provider = TracerProvider(resource=resource)
            
            # Set up Azure Monitor exporter with retry
            if connection_string:
                exporter = AzureMonitorTraceExporter(
                    connection_string=connection_string
                )
                
                # Use batch processor for better performance
                span_processor = BatchSpanProcessor(
                    exporter,
                    max_queue_size=2048,
                    max_export_batch_size=512,
                    schedule_delay_millis=5000
                )
                
                self.tracer_provider.add_span_processor(span_processor)
            
            # Set as global tracer provider
            trace.set_tracer_provider(self.tracer_provider)
            
            # Set up W3C trace context propagation
            set_global_textmap(TraceContextTextMapPropagator())
            
            # Get tracer
            self.tracer = trace.get_tracer(
                service_name,
                service_version,
                tracer_provider=self.tracer_provider
            )
            
            # Auto-instrument frameworks
            FastAPIInstrumentor.instrument(tracer_provider=self.tracer_provider)
            HTTPXClientInstrumentor.instrument(tracer_provider=self.tracer_provider)
            
            self._initialized = True
            logging.info(f"Distributed tracing initialized for {service_name}")
            
        except Exception as e:
            logging.error(f"Failed to initialize tracing: {e}")
            
    def create_span(self, name: str, kind=trace.SpanKind.INTERNAL):
        """Create a new span with the service tracer."""
        if self.tracer:
            return self.tracer.start_as_current_span(name, kind=kind)
        return None
```

### Step 2: Implement Trace Context Propagation

Create `services/shared/trace_context.py`:

**🤖 Copilot Prompt Suggestion #2:**
```python
# Create trace context utilities that:
# - Extract trace context from incoming HTTP headers
# - Inject trace context into outgoing requests
# - Propagate baggage items (user_id, session_id, feature_flags)
# - Handle both W3C TraceContext and B3 formats
# - Add custom correlation headers
# - Implement trace ID logging for correlation
```

### Step 3: Create Order Processing Workflow

Atualizar `services/order_service/workflows.py`:

```python
from typing import Dict, Any, Optional
import asyncio
import httpx
from datetime import datetime
from shared.telemetry import telemetry
from opentelemetry import trace, baggage
from opentelemetry.trace import Status, StatusCode
import structlog

logger = structlog.get_logger()

class OrderWorkflow:
    def __init__(self):
        self.inventory_url = "http://inventory-service:8004"
        self.payment_url = "http://payment-service:8005"
        
    async def process_order(self, order_data: Dict[str, Any]) -&gt; Dict[str, Any]:
        """Process order with distributed tracing."""
        # Create main span for order processing
        with telemetry.create_span(
            "process_order",
            kind=trace.SpanKind.SERVER
        ) as span:
            if not span:
                return await self._process_order_no_trace(order_data)
                
            # Add order attributes to span
            span.set_attribute("order.id", order_data["id"])
            span.set_attribute("order.user_id", order_data["user_id"])
            span.set_attribute("order.total_amount", order_data["total_amount"])
            span.set_attribute("order.items_count", len(order_data.get("items", [])))
            
            # Set baggage for propagation
            baggage.set_baggage("user.id", order_data["user_id"])
            baggage.set_baggage("order.id", order_data["id"])
            
            try:
                # Step 1: Validate inventory
                with telemetry.create_span("validate_inventory") as inv_span:
                    inventory_result = await self._check_inventory(order_data)
                    inv_span.set_attribute("inventory.available", inventory_result["available"])
                    
                if not inventory_result["available"]:
                    span.set_status(Status(StatusCode.ERROR, "Inventory not available"))
                    return {{"status": "failed", "reason": "inventory_unavailable"}}
                
                # Step 2: Reserve inventory
                with telemetry.create_span("reserve_inventory") as res_span:
                    reservation = await self._reserve_inventory(order_data)
                    res_span.set_attribute("reservation.id", reservation["reservation_id"])
                
                # Step 3: Process payment
                with telemetry.create_span("process_payment") as pay_span:
                    payment_result = await self._process_payment(order_data)
                    pay_span.set_attribute("payment.status", payment_result["status"])
                    pay_span.set_attribute("payment.transaction_id", payment_result.get("transaction_id", ""))
                    
                if payment_result["status"] != "success":
                    # Rollback inventory reservation
                    with telemetry.create_span("rollback_inventory"):
                        await self._rollback_inventory(reservation["reservation_id"])
                    
                    span.set_status(Status(StatusCode.ERROR, "Payment failed"))
                    return {{"status": "failed", "reason": "payment_failed"}}
                
                # Step 4: Confirm order
                with telemetry.create_span("confirm_order") as conf_span:
                    confirmation = await self._confirm_order(order_data, payment_result)
                    conf_span.set_attribute("confirmation.number", confirmation["confirmation_number"])
                
                span.set_status(Status(StatusCode.OK))
                
                # Log with trace context
                logger.info(
                    "Order processed successfully",
                    order_id=order_data["id"],
                    trace_id=trace.get_current_span().get_span_context().trace_id,
                    duration=(datetime.utcnow() - start_time).total_seconds()
                )
                
                return {
                    "status": "success",
                    "order_id": order_data["id"],
                    "confirmation_number": confirmation["confirmation_number"],
                    "estimated_delivery": confirmation["estimated_delivery"]
                }
                
            except Exception as e:
                span.record_exception(e)
                span.set_status(Status(StatusCode.ERROR, str(e)))
                logger.error("Order processing failed", error=str(e))
                raise
```

### Step 4: Implement Service-to-Service Communication

Create `services/shared/http_client.py`:

**🤖 Copilot Prompt Suggestion #3:**
```python
# Create an HTTP client wrapper that:
# - Automatically propagates trace context headers
# - Adds service mesh headers (X-Service-Name, X-Service-Version)
# - Implements retry with exponential backoff
# - Records spans for each HTTP call with detailed attributes
# - Handles circuit breaking for failed services
# - Adds request/response logging with correlation
# Include timeout handling and connection pooling
```

### Step 5: Create Trace Visualization Endpoint

Add to `services/api_gateway/monitoring.py`:

```python
@router.get("/traces/{trace_id}")
async def get_trace_details(trace_id: str) -&gt; Dict[str, Any]:
    """Get detailed trace information from Application Insights."""
    # Query Application Insights for trace details
    query = f"""
    union *
    | where operation_Id == '{trace_id}'
    | project 
        timestamp,
        itemType,
        name,
        operation_Name,
        operation_ParentId,
        duration,
        success,
        resultCode,
        cloud_RoleName,
        customDimensions
    | order by timestamp asc
    """
    
    # Execute query (in production, use Azure Monitor Query SDK)
    # This is a simplified example
    spans = await execute_application_insights_query(query)
    
    # Build trace tree
    trace_tree = build_trace_tree(spans)
    
    # Calculate critical path
    critical_path = calculate_critical_path(trace_tree)
    
    # Identify bottlenecks
    bottlenecks = identify_bottlenecks(spans)
    
    return {
        "trace_id": trace_id,
        "total_duration": calculate_total_duration(spans),
        "service_count": len(set(span["cloud_RoleName"] for span in spans)),
        "span_count": len(spans),
        "critical_path": critical_path,
        "bottlenecks": bottlenecks,
        "timeline": build_timeline(spans),
        "service_map": build_service_dependencies(spans)
    }

def build_trace_tree(spans: List[Dict]) -&gt; Dict:
    """Build hierarchical trace tree from flat spans."""
    # Implementation details here
    pass

def calculate_critical_path(trace_tree: Dict) -&gt; List[str]:
    """Calculate the critical path through the trace."""
    # Implementation details here
    pass

def identify_bottlenecks(spans: List[Dict]) -&gt; List[Dict]:
    """Identify performance bottlenecks in the trace."""
    bottlenecks = []
    
    for span in spans:
        if span["duration"] &gt; 1000:  # Over 1 second
            bottlenecks.append({
                "operation": span["name"],
                "service": span["cloud_RoleName"],
                "duration": span["duration"],
                "percentage_of_total": calculate_percentage(span["duration"], total_duration)
            })
    
    return sorted(bottlenecks, key=lambda x: x["duration"], reverse=True)
```

### Step 6: Implement Trace Sampling

Create `services/shared/sampling.py`:

**🤖 Copilot Prompt Suggestion #4:**
```python
# Create a custom sampler that:
# - Always samples error traces (100%)
# - Samples health checks at 0.1%
# - Implements adaptive sampling based on traffic volume
# - Uses parent-based sampling for distributed traces
# - Allows override via HTTP headers (X-Trace-Sampling)
# - Implements tail-based sampling for slow requests
# Include configuration for different environments
```

### Step 7: Test Distributed Tracing

Create `tests/test_distributed_tracing.py`:

```python
import asyncio
import httpx
import uuid
from datetime import datetime

async def test_distributed_trace():
    """Test complete distributed trace flow."""
    # Create a unique trace ID for correlation
    trace_id = str(uuid.uuid4())
    
    # Create order with trace header
    async with httpx.AsyncClient() as client:
        # Send request with trace context
        headers = {
            "traceparent": f"00-{{trace_id.replace('-', '')}}-0000000000000001-01"
        }
        
        order_data = {
            "user_id": "user-123",
            "items": [
                {{"product_id": "prod-1", "quantity": 2, "price": 29.99}},
                {{"product_id": "prod-2", "quantity": 1, "price": 49.99}}
            ],
            "total_amount": 109.97
        }
        
        # Create order
        response = await client.post(
            "http://localhost:8000/api/orders",
            json=order_data,
            headers=headers
        )
        
        order_result = response.json()
        print(f"Order created: {order_result}")
        
        # Wait for traces to be exported
        await asyncio.sleep(10)
        
        # Fetch trace details
        trace_response = await client.get(
            f"http://localhost:8000/monitoring/traces/{trace_id}"
        )
        
        trace_details = trace_response.json()
        
        print("\n📊 Trace Analysis:")
        print(f"Total Duration: {trace_details['total_duration']}ms")
        print(f"Services Involved: {trace_details['service_count']}")
        print(f"Total Spans: {trace_details['span_count']}")
        
        print("\n🔥 Bottlenecks:")
        for bottleneck in trace_details['bottlenecks'][:3]:
            print(f"- {bottleneck['operation']} ({bottleneck['service']}): {bottleneck['duration']}ms")
        
        print("\n🛤️ Critical Path:")
        for step in trace_details['critical_path']:
            print(f"- {step}")

if __name__ == "__main__":
    asyncio.run(test_distributed_trace())
```

## 📊 Viewing Traces in Application Insights

### Step 8: Navigate to Transaction Pesquisar

1. Abrir Application Insights in Azure Portal
2. Go to **Transaction search**
3. Filtrar by:
   - Time range: Last 30 minutos
   - Event types: All
   - Add filter: `operation_Id = "your-trace-id"`

### Step 9: Analyze End-to-End Transaction

1. Click on any request to see details
2. Click **View end-to-end transaction**
3. Observe:
   - Linha do Tempo view of all operations
   - Service dependencies
   - Duração breakdown
   - Any exceptions or errors

### Step 10: Create Performance Investigation

1. Go to **Performance**
2. Select **Dependencies**
3. Identify slow dependencies
4. Drill into specific operations
5. View sample traces

## ✅ Success Criteria

Your distributed tracing is complete when:

1. **Traces span services**: End-to-end visibility across all services
2. **Context propagates**: TraceID consistent across services
3. **Rich attributes**: Business context in spans
4. **Performance visible**: Can identify bottlenecks
5. **Sampling works**: Not all requests traced (cost control)
6. **Errors traced**: 100% of errors captured

## 🏆 Extension Challenges

1. **Implement Trace Análises**: Build custom KQL queries for trace analysis
2. **Add Baggage Items**: Propagate feature flags and A/B test info
3. **Create SLO Monitoring**: Trilha traces against SLO targets
4. **Build Dependency Map**: Visualize service dependencies from traces

## 💡 Key Takeaways

- Distributed tracing is essential for microservices debugging
- Context propagation must be automatic and consistent
- Rich span attributes enable powerful analysis
- Sampling strategies balance visibility with cost
- Trace analysis helps identify optimization opportunities

## Próximos Passos

Excellent work! You've implemented distributed tracing. Proceed to Exercício 3 where you'll build a complete enterprise observability platform.

[Continuar to Exercício 3 →](../exercise3-mastery/instructions.md)