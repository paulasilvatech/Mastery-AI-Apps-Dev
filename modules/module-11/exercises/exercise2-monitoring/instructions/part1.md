# Exercise 2: Application - Real-World E-Commerce Platform ⭐⭐

## Overview
**Duration**: 45-60 minutes  
**Difficulty**: ⭐⭐ (Medium)  
**Success Rate**: 80%

In this exercise, you'll build a complete e-commerce microservices platform with advanced patterns including API Gateway, service discovery, event-driven communication, and distributed caching. This represents a real-world scenario with proper separation of concerns and scalable architecture.

## 🎯 Learning Objectives

By completing this exercise, you will:
1. Implement an API Gateway pattern for unified entry point
2. Add event-driven communication with RabbitMQ
3. Implement service discovery and health checking
4. Add distributed caching with Redis
5. Handle distributed transactions
6. Implement async communication patterns
7. Add comprehensive logging and monitoring

## 📋 Prerequisites

- Completed Exercise 1
- Understanding of message queues
- Basic knowledge of Redis
- Familiarity with event-driven architecture

## 🏗️ Architecture Overview

```mermaid
graph TB
    Client[Client Application]
    
    subgraph API Layer
        AG[API Gateway :8000]
        SD[Service Discovery]
    end
    
    subgraph Core Services
        US[User Service :8001]
        PS[Product Service :8002]
        OS[Order Service :8003]
        NS[Notification Service :8004]
        IS[Inventory Service :8005]
    end
    
    subgraph Infrastructure
        MQ[RabbitMQ :5672]
        Cache[Redis Cache :6379]
        SD_Store[(Service Registry)]
    end
    
    Client --> AG
    AG --> SD
    SD --> SD_Store
    
    AG --> US
    AG --> PS
    AG --> OS
    
    OS --> MQ
    MQ --> NS
    MQ --> IS
    
    US --> Cache
    PS --> Cache
    OS --> Cache
    
    US --> USD[(Users DB)]
    PS --> PSD[(Products DB)]
    OS --> OSD[(Orders DB)]
    IS --> ISD[(Inventory DB)]
```

## 📁 Enhanced Project Structure

```
exercise2-application/
├── api-gateway/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py
│   │   ├── routes.py
│   │   ├── service_discovery.py
│   │   └── middleware/
│   │       ├── auth.py
│   │       ├── rate_limit.py
│   │       └── logging.py
│   ├── Dockerfile
│   └── requirements.txt
├── services/
│   ├── user-service/
│   ├── product-service/
│   ├── order-service/
│   ├── notification-service/
│   └── inventory-service/
├── infrastructure/
│   ├── rabbitmq/
│   │   └── definitions.json
│   ├── redis/
│   │   └── redis.conf
│   └── monitoring/
│       ├── prometheus.yml
│       └── grafana/
├── shared/
│   ├── events/
│   │   └── schemas.py
│   ├── cache/
│   │   └── client.py
│   └── messaging/
│       └── publisher.py
├── docker-compose.yml
├── .env.example
└── README.md
```

## 🚀 Step-by-Step Instructions

### Step 1: Set Up the Enhanced Project Structure

```bash
mkdir -p exercise2-application/{api-gateway,services,infrastructure,shared}
cd exercise2-application

# Create service directories
mkdir -p services/{user-service,product-service,order-service,notification-service,inventory-service}

# Create infrastructure directories
mkdir -p infrastructure/{rabbitmq,redis,monitoring/grafana}

# Create shared libraries
mkdir -p shared/{events,cache,messaging}
```

### Step 2: Create Shared Components

#### 2.1 Event Schemas

Create `shared/events/schemas.py`:

**Copilot Prompt Suggestion:**
```python
# Create Pydantic models for event-driven communication:
# - BaseEvent with event_id, event_type, timestamp, version
# - OrderCreatedEvent with order details
# - OrderCancelledEvent with order_id and reason
# - InventoryUpdatedEvent with product_id and quantity changes
# - UserRegisteredEvent with user details
# Include event type enum and validation
```

**Expected Output:**
```python
from pydantic import BaseModel, Field
from datetime import datetime
from typing import List, Optional, Dict, Any
from uuid import UUID, uuid4
from enum import Enum

class EventType(str, Enum):
    ORDER_CREATED = "order.created"
    ORDER_CANCELLED = "order.cancelled"
    ORDER_COMPLETED = "order.completed"
    INVENTORY_UPDATED = "inventory.updated"
    USER_REGISTERED = "user.registered"
    PAYMENT_PROCESSED = "payment.processed"

class BaseEvent(BaseModel):
    event_id: UUID = Field(default_factory=uuid4)
    event_type: EventType
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    version: str = "1.0"
    correlation_id: Optional[UUID] = None
    metadata: Dict[str, Any] = Field(default_factory=dict)

class OrderItem(BaseModel):
    product_id: UUID
    quantity: int
    price: float

class OrderCreatedEvent(BaseEvent):
    event_type: EventType = EventType.ORDER_CREATED
    order_id: UUID
    user_id: UUID
    items: List[OrderItem]
    total_amount: float
    shipping_address: Dict[str, str]

class OrderCancelledEvent(BaseEvent):
    event_type: EventType = EventType.ORDER_CANCELLED
    order_id: UUID
    user_id: UUID
    reason: str
    cancelled_by: str

class InventoryUpdatedEvent(BaseEvent):
    event_type: EventType = EventType.INVENTORY_UPDATED
    product_id: UUID
    quantity_change: int
    current_quantity: int
    reason: str

class UserRegisteredEvent(BaseEvent):
    event_type: EventType = EventType.USER_REGISTERED
    user_id: UUID
    username: str
    email: str
    registration_source: str
```

#### 2.2 Cache Client

Create `shared/cache/client.py`:

**Copilot Prompt Suggestion:**
```python
# Create a Redis cache client with:
# - Async Redis connection pool
# - Generic get/set methods with TTL
# - JSON serialization for complex objects
# - Key prefix support for namespacing
# - Decorator for caching function results
# - Circuit breaker for Redis failures
```

**Expected Output:**
```python
import redis.asyncio as redis
import json
import pickle
from typing import Any, Optional, Union, Callable
from datetime import timedelta
from functools import wraps
import logging
from uuid import UUID

logger = logging.getLogger(__name__)

class CacheClient:
    def __init__(self, redis_url: str = "redis://localhost:6379", prefix: str = ""):
        self.redis_url = redis_url
        self.prefix = prefix
        self.pool = None
        self._client = None
    
    async def connect(self):
        self.pool = redis.ConnectionPool.from_url(
            self.redis_url,
            max_connections=50,
            decode_responses=True
        )
        self._client = redis.Redis(connection_pool=self.pool)
        
    async def disconnect(self):
        if self._client:
            await self._client.close()
        if self.pool:
            await self.pool.disconnect()
    
    def _make_key(self, key: str) -> str:
        return f"{self.prefix}:{key}" if self.prefix else key
    
    async def get(self, key: str) -> Optional[Any]:
        try:
            full_key = self._make_key(key)
            value = await self._client.get(full_key)
            if value:
                return json.loads(value)
            return None
        except Exception as e:
            logger.error(f"Cache get error: {e}")
            return None
    
    async def set(
        self, 
        key: str, 
        value: Any, 
        ttl: Optional[Union[int, timedelta]] = None
    ) -> bool:
        try:
            full_key = self._make_key(key)
            
            # Handle UUID serialization
            if isinstance(value, dict):
                value = {k: str(v) if isinstance(v, UUID) else v 
                        for k, v in value.items()}
            
            json_value = json.dumps(value)
            
            if ttl:
                if isinstance(ttl, timedelta):
                    ttl = int(ttl.total_seconds())
                await self._client.setex(full_key, ttl, json_value)
            else:
                await self._client.set(full_key, json_value)
            return True
        except Exception as e:
            logger.error(f"Cache set error: {e}")
            return False
    
    async def delete(self, key: str) -> bool:
        try:
            full_key = self._make_key(key)
            result = await self._client.delete(full_key)
            return result > 0
        except Exception as e:
            logger.error(f"Cache delete error: {e}")
            return False
    
    async def exists(self, key: str) -> bool:
        try:
            full_key = self._make_key(key)
            return await self._client.exists(full_key) > 0
        except Exception as e:
            logger.error(f"Cache exists error: {e}")
            return False

def cached(ttl: Union[int, timedelta] = 300, key_prefix: str = ""):
    """Decorator for caching function results"""
    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(self, *args, **kwargs):
            # Generate cache key from function name and arguments
            cache_key = f"{key_prefix}:{func.__name__}:{str(args)}:{str(kwargs)}"
            
            # Try to get from cache
            if hasattr(self, 'cache'):
                cached_value = await self.cache.get(cache_key)
                if cached_value is not None:
                    logger.info(f"Cache hit for {cache_key}")
                    return cached_value
            
            # Execute function
            result = await func(self, *args, **kwargs)
            
            # Store in cache
            if hasattr(self, 'cache') and result is not None:
                await self.cache.set(cache_key, result, ttl)
                logger.info(f"Cached result for {cache_key}")
            
            return result
        
        return wrapper
    return decorator
```

#### 2.3 Message Publisher

Create `shared/messaging/publisher.py`:

**Copilot Prompt Suggestion:**
```python
# Create a RabbitMQ event publisher with:
# - Async connection management
# - Publish to topic exchange
# - Automatic reconnection
# - Message persistence
# - Correlation ID tracking
# - Error handling and retry logic
```

**Expected Output:**
```python
import aio_pika
import json
from typing import Any, Dict, Optional
from datetime import datetime
import logging
from uuid import UUID
from ..events.schemas import BaseEvent

logger = logging.getLogger(__name__)

class EventPublisher:
    def __init__(self, amqp_url: str = "amqp://guest:guest@localhost:5672/"):
        self.amqp_url = amqp_url
        self.connection = None
        self.channel = None
        self.exchange = None
    
    async def connect(self):
        """Establish connection to RabbitMQ"""
        try:
            self.connection = await aio_pika.connect_robust(
                self.amqp_url,
                reconnect_interval=5,
                fail_fast=False
            )
            self.channel = await self.connection.channel()
            
            # Declare topic exchange
            self.exchange = await self.channel.declare_exchange(
                "events",
                aio_pika.ExchangeType.TOPIC,
                durable=True
            )
            
            logger.info("Connected to RabbitMQ")
        except Exception as e:
            logger.error(f"Failed to connect to RabbitMQ: {e}")
            raise
    
    async def disconnect(self):
        """Close RabbitMQ connection"""
        if self.connection and not self.connection.is_closed:
            await self.connection.close()
    
    async def publish_event(
        self, 
        event: BaseEvent,
        routing_key: Optional[str] = None
    ):
        """Publish event to RabbitMQ"""
        if not self.exchange:
            await self.connect()
        
        try:
            # Use event type as routing key if not provided
            if not routing_key:
                routing_key = event.event_type.value
            
            # Serialize event
            message_body = event.json().encode()
            
            # Create message with persistence
            message = aio_pika.Message(
                body=message_body,
                content_type="application/json",
                delivery_mode=aio_pika.DeliveryMode.PERSISTENT,
                correlation_id=str(event.correlation_id) if event.correlation_id else None,
                timestamp=datetime.utcnow(),
                headers={
                    "event_type": event.event_type.value,
                    "version": event.version
                }
            )
            
            # Publish message
            await self.exchange.publish(
                message,
                routing_key=routing_key
            )
            
            logger.info(f"Published event: {event.event_type.value} with ID: {event.event_id}")
            
        except Exception as e:
            logger.error(f"Failed to publish event: {e}")
            raise
    
    async def create_queue(
        self,
        queue_name: str,
        routing_patterns: list[str],
        durable: bool = True
    ) -> aio_pika.Queue:
        """Create and bind queue to exchange"""
        if not self.channel:
            await self.connect()
        
        # Declare queue
        queue = await self.channel.declare_queue(
            queue_name,
            durable=durable,
            exclusive=False,
            auto_delete=False
        )
        
        # Bind to exchange with routing patterns
        for pattern in routing_patterns:
            await queue.bind(self.exchange, routing_key=pattern)
        
        logger.info(f"Created queue: {queue_name} with patterns: {routing_patterns}")
        return queue
```

### Step 3: Create the API Gateway

#### 3.1 Service Discovery

Create `api-gateway/app/service_discovery.py`:

**Copilot Prompt Suggestion:**
```python
# Create a service discovery mechanism that:
# - Maintains registry of available services
# - Performs health checks every 30 seconds
# - Removes unhealthy services
# - Supports round-robin load balancing
# - Allows dynamic service registration
# - Thread-safe operations
```

**Expected Output:**
```python
import asyncio
import httpx
from typing import Dict, List, Optional, Set
from dataclasses import dataclass
from datetime import datetime, timedelta
import logging
from collections import defaultdict
import random

logger = logging.getLogger(__name__)

@dataclass
class ServiceInstance:
    name: str
    host: str
    port: int
    health_check_url: str
    last_check: Optional[datetime] = None
    is_healthy: bool = True
    metadata: Dict = None

class ServiceDiscovery:
    def __init__(self, health_check_interval: int = 30):
        self.services: Dict[str, List[ServiceInstance]] = defaultdict(list)
        self.health_check_interval = health_check_interval
        self._health_check_task = None
        self._lock = asyncio.Lock()
        self._round_robin_counters = defaultdict(int)
    
    async def start(self):
        """Start the health check background task"""
        self._health_check_task = asyncio.create_task(self._health_check_loop())
        logger.info("Service discovery started")
    
    async def stop(self):
        """Stop the health check background task"""
        if self._health_check_task:
            self._health_check_task.cancel()
            try:
                await self._health_check_task
            except asyncio.CancelledError:
                pass
    
    async def register_service(
        self,
        name: str,
        host: str,
        port: int,
        health_check_path: str = "/health",
        metadata: Dict = None
    ):
        """Register a new service instance"""
        async with self._lock:
            instance = ServiceInstance(
                name=name,
                host=host,
                port=port,
                health_check_url=f"http://{host}:{port}{health_check_path}",
                metadata=metadata or {}
            )
            
            # Check if instance already exists
            existing = [s for s in self.services[name] 
                       if s.host == host and s.port == port]
            
            if not existing:
                self.services[name].append(instance)
                logger.info(f"Registered service: {name} at {host}:{port}")
                
                # Perform initial health check
                await self._check_service_health(instance)
    
    async def deregister_service(self, name: str, host: str, port: int):
        """Remove a service instance"""
        async with self._lock:
            self.services[name] = [
                s for s in self.services[name]
                if not (s.host == host and s.port == port)
            ]
            logger.info(f"Deregistered service: {name} at {host}:{port}")
    
    async def get_service(self, name: str) -> Optional[ServiceInstance]:
        """Get a healthy service instance using round-robin"""
        async with self._lock:
            healthy_instances = [
                s for s in self.services.get(name, [])
                if s.is_healthy
            ]
            
            if not healthy_instances:
                return None
            
            # Round-robin selection
            index = self._round_robin_counters[name] % len(healthy_instances)
            self._round_robin_counters[name] += 1
            
            return healthy_instances[index]
    
    async def get_all_services(self, name: str) -> List[ServiceInstance]:
        """Get all healthy instances of a service"""
        async with self._lock:
            return [
                s for s in self.services.get(name, [])
                if s.is_healthy
            ]
    
    async def _health_check_loop(self):
        """Background task to check service health"""
        while True:
            try:
                await asyncio.sleep(self.health_check_interval)
                await self._check_all_services()
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Error in health check loop: {e}")
    
    async def _check_all_services(self):
        """Check health of all registered services"""
        async with self._lock:
            tasks = []
            for service_list in self.services.values():
                for instance in service_list:
                    tasks.append(self._check_service_health(instance))
            
            if tasks:
                await asyncio.gather(*tasks, return_exceptions=True)
    
    async def _check_service_health(self, instance: ServiceInstance) -> bool:
        """Check health of a single service instance"""
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                response = await client.get(instance.health_check_url)
                instance.is_healthy = response.status_code == 200
                instance.last_check = datetime.utcnow()
                
                if not instance.is_healthy:
                    logger.warning(
                        f"Service {instance.name} at {instance.host}:{instance.port} "
                        f"is unhealthy (status: {response.status_code})"
                    )
                
                return instance.is_healthy
                
        except Exception as e:
            instance.is_healthy = False
            instance.last_check = datetime.utcnow()
            logger.error(
                f"Health check failed for {instance.name} "
                f"at {instance.host}:{instance.port}: {e}"
            )
            return False
```

This continues in Part 2...
---

## 🔗 Navigation

[← Back to Exercise](../README.md) | [🏠 Module Home](../../../../README.md) | [Next: Part 2 →](part2.md)

## 📚 Quick Links

- [Prerequisites](../../../../prerequisites.md)
- [Module Resources](../../../../README.md#resources)
- [Troubleshooting Guide](../../../../troubleshooting.md)
- [Solution Code](../solution/)
