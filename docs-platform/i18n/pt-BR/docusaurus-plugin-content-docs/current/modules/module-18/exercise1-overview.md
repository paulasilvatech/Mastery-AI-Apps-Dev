---
sidebar_position: 2
title: "Exercise 1: Overview"
description: "## 🎯 Exercise Overview"
---

# Exercício 1: Empresarial Service Bus Implementation (⭐ Foundation)

## 🎯 Visão Geral do Exercício

**Duração**: 30-45 minutos  
**Difficulty**: ⭐ (Fácil)  
**Success Rate**: 95%

In this foundation exercise, you'll build an Empresarial Service Bus (ESB) using Azure Service Bus. You'll implement message routing, transformation, protocol adaptation, and reliable message delivery patterns that form the backbone of enterprise integration.

## 🎓 Objetivos de Aprendizagem

Ao completar este exercício, você irá:
- Design message-based integration architecture
- Implement content-based routing
- Build protocol adapters (HTTP to AMQP)
- Create message transformation pipelines
- Handle poison messages and retries
- Monitor message flow and performance

## 📋 Pré-requisitos

- ✅ Módulo 18 ambiente set up
- ✅ Azure Service Bus namespace created
- ✅ Python virtual ambiente activated
- ✅ Docker services running

## 🏗️ What You'll Build

An ESB system that routes and transforms messages between services:

```mermaid
graph TB
    subgraph "Message Sources"
        HTTP[HTTP API]
        GRPC[gRPC Service]
        FILE[File Watcher]
    end
    
    subgraph "Enterprise Service Bus"
        ADAPT[Protocol Adapters]
        ROUTE[Message Router]
        TRANS[Transformer]
        QUEUE[Message Queues]
        DLQ[Dead Letter Queue]
    end
    
    subgraph "Message Consumers"
        SVC1[Order Service]
        SVC2[Inventory Service]
        SVC3[Notification Service]
    end
    
    HTTP --&gt; ADAPT
    GRPC --&gt; ADAPT
    FILE --&gt; ADAPT
    
    ADAPT --&gt; ROUTE
    ROUTE --&gt; TRANS
    TRANS --&gt; QUEUE
    
    QUEUE --&gt; SVC1
    QUEUE --&gt; SVC2
    QUEUE --&gt; SVC3
    
    QUEUE -.-&gt;|Failed| DLQ
    
    style ROUTE fill:#f96,stroke:#333,stroke-width:4px
    style TRANS fill:#9f9,stroke:#333,stroke-width:2px
    style DLQ fill:#f99,stroke:#333,stroke-width:2px
```

## 🚀 Implementation Steps

### Step 1: Project Structure

Create the following structure:

```
exercise1-esb/
├── esb/
│   ├── __init__.py
│   ├── router.py           # Message routing logic
│   ├── transformer.py      # Message transformation
│   ├── adapters/          # Protocol adapters
│   │   ├── __init__.py
│   │   ├── http_adapter.py
│   │   ├── grpc_adapter.py
│   │   └── file_adapter.py
│   ├── handlers/          # Message handlers
│   │   ├── __init__.py
│   │   ├── base_handler.py
│   │   └── order_handler.py
│   └── monitoring.py      # Metrics and tracing
├── api/
│   ├── __init__.py
│   ├── app.py            # FastAPI application
│   └── models.py         # Message models
├── config/
│   ├── __init__.py
│   ├── settings.py       # Configuration
│   └── routes.yaml       # Routing rules
├── tests/
│   ├── test_routing.py
│   └── test_transformation.py
└── docker-compose.yml    # Local services
```

### Step 2: Configuration and Models

Create `config/settings.py`:

**🤖 Copilot Prompt Suggestion #1:**
```python
# Create a configuration class that:
# - Loads Azure Service Bus connection settings
# - Configures message routing rules from YAML
# - Sets retry policies and timeouts
# - Defines dead letter queue settings
# - Includes monitoring configuration
# - Supports environment-specific settings
# Use pydantic settings with validation
```

**Expected Output Structure:**
```python
from pydantic_settings import BaseSettings
from typing import Dict, List, Optional
import yaml
from pathlib import Path

class RetryPolicy(BaseSettings):
    max_retries: int = 3
    backoff_multiplier: float = 2.0
    max_backoff_seconds: int = 60

class ServiceBusSettings(BaseSettings):
    connection_string: str
    max_concurrent_messages: int = 10
    prefetch_count: int = 20
    lock_duration_seconds: int = 60
    
class Settings(BaseSettings):
    # Service Bus
    service_bus: ServiceBusSettings
    retry_policy: RetryPolicy
    
    # Routing
    routing_config_path: Path = Path("config/routes.yaml")
    
    # Monitoring
    enable_tracing: bool = True
    enable_metrics: bool = True
    log_level: str = "INFO"
    
    # Dead Letter Queue
    max_delivery_count: int = 3
    dead_letter_reason_header: str = "DeadLetterReason"
    
    @property
    def routing_rules(self) -&gt; Dict:
        """Load routing rules from YAML."""
        with open(self.routing_config_path) as f:
            return yaml.safe_load(f)
    
    class Config:
        env_file = ".env"
        env_nested_delimiter = "__"
```

Create `config/routes.yaml`:

```yaml
routes:
  - name: "order_route"
    description: "Route order messages to appropriate services"
    conditions:
      - field: "message_type"
        operator: "equals"
        value: "order"
    transformations:
      - type: "add_header"
        header: "X-Message-Version"
        value: "1.0"
    destinations:
      - queue: "order-processing"
        filters:
          - field: "order_type"
            operator: "in"
            values: ["standard", "express"]
      - topic: "order-events"
        subscription: "inventory-updates"
        
  - name: "inventory_route"
    description: "Route inventory updates"
    conditions:
      - field: "message_type"
        operator: "equals"
        value: "inventory"
    transformations:
      - type: "json_to_xml"
        when:
          field: "target_format"
          equals: "xml"
    destinations:
      - queue: "inventory-updates"
```

### Step 3: Message Models

Create `api/models.py`:

```python
from pydantic import BaseModel, Field
from typing import Dict, Any, Optional, List
from datetime import datetime
from enum import Enum

class MessageType(str, Enum):
    ORDER = "order"
    INVENTORY = "inventory"
    NOTIFICATION = "notification"
    COMMAND = "command"
    EVENT = "event"

class MessagePriority(str, Enum):
    LOW = "low"
    NORMAL = "normal"
    HIGH = "high"
    CRITICAL = "critical"

class Message(BaseModel):
    id: str = Field(description="Unique message ID")
    correlation_id: Optional[str] = Field(None, description="Correlation ID for tracking")
    message_type: MessageType
    priority: MessagePriority = MessagePriority.NORMAL
    payload: Dict[str, Any]
    headers: Dict[str, str] = {}
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    source: str = Field(description="Source system/service")
    target: Optional[str] = Field(None, description="Target system/service")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }

class RoutingDecision(BaseModel):
    message_id: str
    route_name: str
    destinations: List[str]
    transformations_applied: List[str]
    routing_time_ms: float

class TransformationRule(BaseModel):
    type: str
    parameters: Dict[str, Any]
    condition: Optional[Dict[str, Any]] = None
```

### Step 4: Message Router Implementation

Create `esb/router.py`:

**🤖 Copilot Prompt Suggestion #2:**
```python
# Create a message router that:
# - Evaluates routing rules based on message content
# - Supports complex conditions (AND, OR, nested)
# - Routes to multiple destinations
# - Tracks routing decisions for observability
# - Implements circuit breaker for destinations
# - Handles routing failures gracefully
# - Provides routing statistics
# Make it async and thread-safe
```

**Expected Implementation Pattern:**
```python
import asyncio
from typing import List, Dict, Any, Optional
import logging
from datetime import datetime
import re
from circuit_breaker import CircuitBreaker

from api.models import Message, RoutingDecision
from config.settings import Settings

logger = logging.getLogger(__name__)

class MessageRouter:
    """Routes messages based on content and rules."""
    
    def __init__(self, settings: Settings):
        self.settings = settings
        self.routing_rules = settings.routing_rules['routes']
        self.circuit_breakers = {}
        self._routing_stats = {
            'total_routed': 0,
            'routing_errors': 0,
            'routes_hit': {{}}
        }
        
    async def route_message(self, message: Message) -&gt; RoutingDecision:
        """
        Route a message based on configured rules.
        
        Args:
            message: The message to route
            
        Returns:
            RoutingDecision with destinations and applied transformations
        """
        start_time = datetime.utcnow()
        destinations = []
        transformations = []
        matched_route = None
        
        try:
            # Evaluate each routing rule
            for rule in self.routing_rules:
                if await self._evaluate_conditions(message, rule['conditions']):
                    matched_route = rule['name']
                    
                    # Apply transformations
                    if 'transformations' in rule:
                        for transform in rule['transformations']:
                            await self._apply_transformation(message, transform)
                            transformations.append(transform['type'])
                    
                    # Determine destinations
                    for dest in rule['destinations']:
                        if await self._evaluate_destination_filter(message, dest):
                            destination = self._format_destination(dest)
                            
                            # Check circuit breaker
                            if self._is_destination_healthy(destination):
                                destinations.append(destination)
                            else:
                                logger.warning(f"Destination {destination} is unhealthy")
                    
                    break  # First matching rule wins
            
            # Update statistics
            self._update_stats(matched_route, len(destinations) &gt; 0)
            
            # Calculate routing time
            routing_time_ms = (datetime.utcnow() - start_time).total_seconds() * 1000
            
            return RoutingDecision(
                message_id=message.id,
                route_name=matched_route or "no_match",
                destinations=destinations,
                transformations_applied=transformations,
                routing_time_ms=routing_time_ms
            )
            
        except Exception as e:
            logger.error(f"Routing error for message {message.id}: {str(e)}")
            self._routing_stats['routing_errors'] += 1
            raise
    
    async def _evaluate_conditions(
        self, 
        message: Message, 
        conditions: List[Dict[str, Any]]
    ) -&gt; bool:
        """Evaluate routing conditions against message."""
        for condition in conditions:
            field_value = self._get_field_value(message, condition['field'])
            operator = condition['operator']
            expected = condition['value']
            
            if not self._evaluate_condition(field_value, operator, expected):
                return False
                
        return True
    
    def _get_field_value(self, message: Message, field_path: str) -&gt; Any:
        """Extract field value from message using dot notation."""
        # Support nested field access like "payload.order.total"
        parts = field_path.split('.')
        value = message
        
        for part in parts:
            if hasattr(value, part):
                value = getattr(value, part)
            elif isinstance(value, dict) and part in value:
                value = value[part]
            else:
                return None
                
        return value
    
    def _evaluate_condition(self, value: Any, operator: str, expected: Any) -&gt; bool:
        """Evaluate a single condition."""
        if operator == "equals":
            return value == expected
        elif operator == "not_equals":
            return value != expected
        elif operator == "in":
            return value in expected
        elif operator == "not_in":
            return value not in expected
        elif operator == "contains":
            return expected in str(value)
        elif operator == "regex":
            return re.match(expected, str(value)) is not None
        elif operator == "greater_than":
            return float(value) &gt; float(expected)
        elif operator == "less_than":
            return float(value) &lt; float(expected)
        else:
            logger.warning(f"Unknown operator: {operator}")
            return False
    
    async def _apply_transformation(
        self, 
        message: Message, 
        transform: Dict[str, Any]
    ) -&gt; None:
        """Apply transformation to message."""
        transform_type = transform['type']
        
        if transform_type == "add_header":
            message.headers[transform['header']] = transform['value']
        elif transform_type == "remove_header":
            message.headers.pop(transform['header'], None)
        elif transform_type == "set_priority":
            message.priority = transform['priority']
        # Add more transformation types as needed
    
    def _format_destination(self, dest: Dict[str, Any]) -&gt; str:
        """Format destination as string."""
        if 'queue' in dest:
            return f"queue://{dest['queue']}"
        elif 'topic' in dest:
            return f"topic://{dest['topic']}/{dest.get('subscription', 'default')}"
        else:
            return "unknown://unknown"
    
    def _is_destination_healthy(self, destination: str) -&gt; bool:
        """Check if destination is healthy using circuit breaker."""
        if destination not in self.circuit_breakers:
            self.circuit_breakers[destination] = CircuitBreaker(
                failure_threshold=5,
                recovery_timeout=60,
                expected_exception=Exception
            )
        
        return self.circuit_breakers[destination].state != "OPEN"
    
    def _update_stats(self, route_name: Optional[str], success: bool) -&gt; None:
        """Update routing statistics."""
        self._routing_stats['total_routed'] += 1
        
        if route_name:
            if route_name not in self._routing_stats['routes_hit']:
                self._routing_stats['routes_hit'][route_name] = 0
            self._routing_stats['routes_hit'][route_name] += 1
    
    def get_stats(self) -&gt; Dict[str, Any]:
        """Get routing statistics."""
        return self._routing_stats.copy()
```

### Step 5: Message Transformer

Create `esb/transformer.py`:

**🤖 Copilot Prompt Suggestion #3:**
```python
# Create a message transformer that:
# - Converts between formats (JSON, XML, CSV, Avro)
# - Enriches messages with additional data
# - Validates message schemas
# - Applies data mapping rules
# - Handles transformation errors gracefully
# - Supports custom transformation plugins
# - Logs all transformations for audit
# Include performance metrics
```

### Step 6: HTTP Protocol Adapter

Create `esb/adapters/http_adapter.py`:

**🤖 Copilot Prompt Suggestion #4:**
```python
# Build an HTTP to AMQP adapter that:
# - Receives HTTP requests and converts to messages
# - Maps HTTP headers to message properties
# - Handles different content types
# - Implements request validation
# - Provides synchronous and asynchronous modes
# - Returns appropriate HTTP status codes
# - Tracks adapter metrics
# Make it compatible with FastAPI
```

### Step 7: Service Bus Integration

Create `esb/service_bus_client.py`:

```python
from azure.servicebus.aio import ServiceBusClient, ServiceBusMessage
from azure.servicebus import ServiceBusReceiveMode
from typing import List, Optional, Dict, Any
import json
import logging
from datetime import datetime

from config.settings import Settings
from api.models import Message

logger = logging.getLogger(__name__)

class ServiceBusManager:
    """Manages Azure Service Bus operations."""
    
    def __init__(self, settings: Settings):
        self.settings = settings
        self._client = None
        self._senders = {}
        self._receivers = {}
        
    async def __aenter__(self):
        """Initialize Service Bus client."""
        self._client = ServiceBusClient.from_connection_string(
            self.settings.service_bus.connection_string,
            logging_enable=True
        )
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Clean up resources."""
        for sender in self._senders.values():
            await sender.close()
        for receiver in self._receivers.values():
            await receiver.close()
        await self._client.close()
    
    async def send_message(
        self, 
        destination: str, 
        message: Message,
        scheduled_enqueue_time: Optional[datetime] = None
    ) -&gt; None:
        """
        Send message to Service Bus destination.
        
        Args:
            destination: Destination in format "queue://name" or "topic://name"
            message: Message to send
            scheduled_enqueue_time: Optional scheduled delivery time
        """
        # Parse destination
        dest_type, dest_name = destination.split("://")
        
        # Get or create sender
        if destination not in self._senders:
            if dest_type == "queue":
                self._senders[destination] = self._client.get_queue_sender(dest_name)
            elif dest_type == "topic":
                self._senders[destination] = self._client.get_topic_sender(dest_name)
            else:
                raise ValueError(f"Unknown destination type: {dest_type}")
        
        sender = self._senders[destination]
        
        # Create Service Bus message
        sb_message = ServiceBusMessage(
            body=json.dumps(message.dict()),
            message_id=message.id,
            correlation_id=message.correlation_id,
            application_properties=message.headers,
            content_type="application/json",
            scheduled_enqueue_time_utc=scheduled_enqueue_time
        )
        
        # Send message
        try:
            await sender.send_messages(sb_message)
            logger.info(f"Sent message {message.id} to {destination}")
        except Exception as e:
            logger.error(f"Failed to send message {message.id}: {str(e)}")
            raise
    
    async def receive_messages(
        self,
        source: str,
        max_messages: int = 10,
        max_wait_time: int = 5
    ) -&gt; List[Message]:
        """
        Receive messages from Service Bus.
        
        Args:
            source: Source in format "queue://name" or "subscription://topic/name"
            max_messages: Maximum messages to receive
            max_wait_time: Maximum wait time in seconds
            
        Returns:
            List of received messages
        """
        # Parse source
        source_parts = source.split("://")
        source_type = source_parts[0]
        
        # Get or create receiver
        if source not in self._receivers:
            if source_type == "queue":
                queue_name = source_parts[1]
                self._receivers[source] = self._client.get_queue_receiver(
                    queue_name=queue_name,
                    receive_mode=ServiceBusReceiveMode.PEEK_LOCK,
                    prefetch_count=self.settings.service_bus.prefetch_count
                )
            elif source_type == "subscription":
                topic_name, sub_name = source_parts[1].split("/")
                self._receivers[source] = self._client.get_subscription_receiver(
                    topic_name=topic_name,
                    subscription_name=sub_name,
                    receive_mode=ServiceBusReceiveMode.PEEK_LOCK,
                    prefetch_count=self.settings.service_bus.prefetch_count
                )
        
        receiver = self._receivers[source]
        
        # Receive messages
        messages = []
        async with receiver:
            received = await receiver.receive_messages(
                max_message_count=max_messages,
                max_wait_time=max_wait_time
            )
            
            for sb_message in received:
                try:
                    # Convert to our Message model
                    message_data = json.loads(str(sb_message))
                    message = Message(**message_data)
                    messages.append(message)
                    
                    # Complete the message
                    await receiver.complete_message(sb_message)
                    
                except Exception as e:
                    logger.error(f"Failed to process message: {str(e)}")
                    # Move to dead letter queue
                    await receiver.dead_letter_message(
                        sb_message,
                        reason="ProcessingError",
                        error_description=str(e)
                    )
        
        return messages
```

### Step 8: FastAPI Application

Create `api/app.py`:

```python
from fastapi import FastAPI, HTTPException, BackgroundTasks, Depends
from contextlib import asynccontextmanager
import logging
from typing import Dict, Any, List
import uuid

from api.models import Message, MessageType, RoutingDecision
from esb.router import MessageRouter
from esb.service_bus_client import ServiceBusManager
from esb.monitoring import MetricsCollector
from config.settings import Settings

logger = logging.getLogger(__name__)

# Global instances
settings = None
router = None
service_bus = None
metrics = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize services on startup."""
    global settings, router, service_bus, metrics
    
    logger.info("Starting ESB...")
    
    settings = Settings()
    router = MessageRouter(settings)
    service_bus = ServiceBusManager(settings)
    metrics = MetricsCollector()
    
    yield
    
    logger.info("Shutting down ESB...")

app = FastAPI(
    title="Enterprise Service Bus",
    description="Message routing and transformation service",
    version="1.0.0",
    lifespan=lifespan
)

@app.post("/messages", response_model=Dict[str, Any])
async def send_message(
    message_type: MessageType,
    payload: Dict[str, Any],
    headers: Dict[str, str] = {},
    priority: str = "normal",
    source: str = "http-adapter",
    background_tasks: BackgroundTasks = BackgroundTasks()
):
    """
    Send a message through the ESB.
    
    The message will be routed based on configured rules.
    """
    # Create message
    message = Message(
        id=str(uuid.uuid4()),
        message_type=message_type,
        payload=payload,
        headers=headers,
        priority=priority,
        source=source
    )
    
    try:
        # Route message
        routing_decision = await router.route_message(message)
        
        # Send to destinations asynchronously
        background_tasks.add_task(
            _send_to_destinations,
            message,
            routing_decision
        )
        
        # Record metrics
        await metrics.record_message_routed(
            message_type=message_type.value,
            route=routing_decision.route_name,
            destinations=len(routing_decision.destinations)
        )
        
        return {
            "message_id": message.id,
            "status": "accepted",
            "routing": routing_decision.dict()
        }
        
    except Exception as e:
        logger.error(f"Failed to process message: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

async def _send_to_destinations(
    message: Message,
    routing_decision: RoutingDecision
) -&gt; None:
    """Send message to all destinations."""
    async with service_bus:
        for destination in routing_decision.destinations:
            try:
                await service_bus.send_message(destination, message)
                await metrics.record_message_sent(destination)
            except Exception as e:
                logger.error(f"Failed to send to {destination}: {str(e)}")
                await metrics.record_message_failed(destination)

@app.get("/routing/rules")
async def get_routing_rules():
    """Get current routing rules."""
    return settings.routing_rules

@app.get("/routing/stats")
async def get_routing_stats():
    """Get routing statistics."""
    return router.get_stats()

@app.get("/health")
async def health_check():
    """Check ESB health."""
    return {
        "status": "healthy",
        "components": {
            "router": "active",
            "service_bus": "connected",
            "metrics": "collecting"
        }
    }

@app.get("/metrics")
async def get_metrics():
    """Get ESB metrics."""
    return await metrics.get_metrics()
```

### Step 9: Testing

Create `tests/test_routing.py`:

**🤖 Copilot Prompt Suggestion #5:**
```python
# Create comprehensive tests for ESB:
# - Test message routing with various conditions
# - Verify transformations are applied correctly
# - Test destination filtering
# - Validate circuit breaker behavior
# - Test concurrent message processing
# - Verify dead letter queue handling
# - Measure routing performance
# Use pytest with async support and mocking
```

### Step 10: Run and Test

Create `run_esb.py`:

```python
import asyncio
import uvicorn
from api.app import app

if __name__ == "__main__":
    # Run the ESB
    uvicorn.run(
        "api.app:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
```

Test with sample requests:

```bash
# Send an order message
curl -X POST "http://localhost:8000/messages" \
  -H "Content-Type: application/json" \
  -d '{
    "message_type": "order",
    "payload": {
      "order_id": "ORD-123",
      "customer_id": "CUST-456",
      "total": 99.99,
      "order_type": "express"
    },
    "headers": {
      "X-Source-System": "web-store",
      "X-Priority": "high"
    }
  }'

# Check routing statistics
curl "http://localhost:8000/routing/stats"

# View routing rules
curl "http://localhost:8000/routing/rules"
```

## 📊 Testing and Validation

### Integration Test

```python
# Create test_integration.py
import asyncio
import pytest
from httpx import AsyncClient
from api.app import app

@pytest.mark.asyncio
async def test_message_routing():
    """Test end-to-end message routing."""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Send order message
        response = await client.post("/messages", json={
            "message_type": "order",
            "payload": {
                "order_id": "TEST-001",
                "total": 100.00
            }
        })
        
        assert response.status_code == 200
        result = response.json()
        assert result["status"] == "accepted"
        assert "routing" in result
        
        # Verify routing decision
        routing = result["routing"]
        assert routing["route_name"] == "order_route"
        assert len(routing["destinations"]) &gt; 0
```

### Performance Test

```python
# Create performance_test.py
import asyncio
import time
from concurrent.futures import ThreadPoolExecutor
import httpx

async def send_message(client, i):
    """Send a single message."""
    response = await client.post("/messages", json={
        "message_type": "order",
        "payload": {{"order_id": f"PERF-{{i}}"}}
    })
    return response.status_code == 200

async def performance_test():
    """Test ESB performance."""
    async with httpx.AsyncClient() as client:
        start_time = time.time()
        
        # Send 1000 messages concurrently
        tasks = []
        for i in range(1000):
            task = send_message(client, i)
            tasks.append(task)
        
        results = await asyncio.gather(*tasks)
        
        end_time = time.time()
        duration = end_time - start_time
        
        success_count = sum(results)
        print(f"Sent {len(results)} messages in {duration:.2f} seconds")
        print(f"Success rate: {success_count/len(results)*100:.1f}%")
        print(f"Throughput: {len(results)/duration:.1f} messages/second")

asyncio.run(performance_test())
```

## ✅ Success Criteria

Your ESB implementation is complete when:

1. **Message Routing**: Routes based on content correctly
2. **Transformations**: Applied as configurado
3. **Protocol Adaptation**: HTTP to AMQP working
4. **Error Handling**: Failed messages go to DLQ
5. **Performance**: Greater than 100 messages/second throughput
6. **Monitoring**: Metrics and tracing enabled

## 🏆 Extension Challenges

1. **Add gRPC Adapter**: Implement gRPC protocol support
2. **Complex Routing**: Add support for nested conditions
3. **Message Enrichment**: Fetch additional data during routing
4. **Saga Support**: Trilha long-running message flows

## 💡 Key Takeaways

- ESB provides decoupling between services
- Content-based routing enables flexibility
- Protocol adaptation simplifies integration
- Circuit breakers prevent cascade failures
- Monitoring is essential for troubleshooting

## 📚 Additional Recursos

- [Empresarial Integration Patterns](https://www.enterpriseintegrationpatterns.com/)
- [Azure Service Bus Melhores Práticas](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-performance-improvements)
- [Message Router Pattern](https://www.enterpriseintegrationpatterns.com/patterns/messaging/MessageRouter.html)

## Próximos Passos

Congratulations on building your ESB! Continuar to Exercício 2 where you'll implement CQRS with Event Sourcing.

[Continuar to Exercício 2 →](../exercise2-cqrs-es/instructions/part1.md)