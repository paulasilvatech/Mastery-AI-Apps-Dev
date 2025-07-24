---
sidebar_position: 4
title: "Exercise 2: Part 1"
description: "## 🎯 Exercise Overview"
---

# Ejercicio 2: CQRS with Event Sourcing - Partee 1 (⭐⭐ Application)

## 🎯 Resumen del Ejercicio

**Duración**: 45-60 minutos (Partee 1: 25 minutos, Partee 2: 35 minutos)  
**Difficulty**: ⭐⭐ (Medio)  
**Success Rate**: 80%

In this application-level exercise, you'll build a CQRS (Command Query Responsibility Segregation) system with Event Sourcing for an e-commerce platform. Partee 1 focuses on the command side and event store, while Partee 2 covers projections and query models.

## 🎓 Objetivos de Aprendizaje - Partee 1

By completing Partee 1, you will:
- Implement command handlers and validation
- Build an event store with Cosmos DB
- Create domain aggregates with event sourcing
- Handle concurrent command processing
- Implement event versioning
- Design compensating events

## 📋 Prerrequisitos

- ✅ Completard Ejercicio 1 (ESB)
- ✅ Understanding of DDD concepts
- ✅ Familiarity with event-driven patterns
- ✅ Azure Cosmos DB configurado

## 🏗️ What You'll Build

A complete CQRS/ES system for order management:

```mermaid
graph TB
    subgraph "Part 1: Command Side"
        API[Command API] --&gt; VALIDATE[Command Validator]
        VALIDATE --&gt; HANDLER[Command Handler]
        HANDLER --&gt; AGG[Aggregate]
        AGG --&gt; EVENTS[Domain Events]
        EVENTS --&gt; STORE[Event Store]
        
        STORE --&gt; PUBLISH[Event Publisher]
        PUBLISH --&gt; BUS[Service Bus]
    end
    
    subgraph "Part 2: Query Side"
        BUS --&gt; PROJ[Projections]
        PROJ --&gt; READ[Read Models]
        
        QAPI[Query API] --&gt; QHANDLER[Query Handler]
        QHANDLER --&gt; READ
        READ --&gt; CACHE[Redis Cache]
    end
    
    style HANDLER fill:#f96,stroke:#333,stroke-width:4px
    style STORE fill:#9f9,stroke:#333,stroke-width:2px
    style AGG fill:#99f,stroke:#333,stroke-width:2px
```

## 🚀 Partee 1: Command Side Implementation

### Step 1: Project Structure

Create the following structure:

```
exercise2-cqrs-es/
├── domain/
│   ├── __init__.py
│   ├── aggregates/        # Domain aggregates
│   │   ├── __init__.py
│   │   ├── base.py
│   │   └── order.py
│   ├── events/           # Domain events
│   │   ├── __init__.py
│   │   ├── base.py
│   │   └── order_events.py
│   └── commands/         # Commands
│       ├── __init__.py
│       ├── base.py
│       └── order_commands.py
├── infrastructure/
│   ├── __init__.py
│   ├── event_store.py    # Event store implementation
│   ├── event_bus.py      # Event publishing
│   └── repositories.py   # Aggregate repositories
├── application/
│   ├── __init__.py
│   ├── command_handlers.py
│   ├── command_bus.py
│   └── validators.py
├── api/
│   ├── __init__.py
│   ├── command_api.py    # Command endpoints
│   └── models.py
├── projections/          # Part 2
├── queries/              # Part 2
└── tests/
```

### Step 2: Domain Events

Create `domain/events/base.py`:

**🤖 Copilot Prompt Suggestion #1:**
```python
# Create base event classes that:
# - Define event metadata (id, timestamp, version)
# - Support event serialization/deserialization
# - Include aggregate information
# - Handle event causation and correlation
# - Support event upcasting for versioning
# - Implement event validation
# - Track event sequence numbers
# Use dataclasses and proper typing
```

**Expected Implementation:**
```python
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from typing import Dict, Any, Optional, Type, TypeVar
import uuid
import json

T = TypeVar('T', bound='DomainEvent')

@dataclass
class EventMetadata:
    """Metadata for domain events."""
    event_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    event_type: str = ""
    event_version: int = 1
    timestamp: datetime = field(default_factory=datetime.utcnow)
    aggregate_id: str = ""
    aggregate_type: str = ""
    aggregate_version: int = 0
    sequence_number: int = 0
    causation_id: Optional[str] = None
    correlation_id: Optional[str] = None
    user_id: Optional[str] = None
    
@dataclass
class DomainEvent(ABC):
    """Base class for all domain events."""
    metadata: EventMetadata = field(default_factory=EventMetadata)
    
    def __post_init__(self):
        """Set event type after initialization."""
        if not self.metadata.event_type:
            self.metadata.event_type = self.__class__.__name__
    
    @abstractmethod
    def get_event_data(self) -&gt; Dict[str, Any]:
        """Get event-specific data."""
        pass
    
    def to_dict(self) -&gt; Dict[str, Any]:
        """Convert event to dictionary."""
        return {
            "metadata": {
                "event_id": self.metadata.event_id,
                "event_type": self.metadata.event_type,
                "event_version": self.metadata.event_version,
                "timestamp": self.metadata.timestamp.isoformat(),
                "aggregate_id": self.metadata.aggregate_id,
                "aggregate_type": self.metadata.aggregate_type,
                "aggregate_version": self.metadata.aggregate_version,
                "sequence_number": self.metadata.sequence_number,
                "causation_id": self.metadata.causation_id,
                "correlation_id": self.metadata.correlation_id,
                "user_id": self.metadata.user_id
            },
            "data": self.get_event_data()
        }
    
    @classmethod
    def from_dict(cls: Type[T], data: Dict[str, Any]) -&gt; T:
        """Create event from dictionary."""
        metadata_dict = data["metadata"]
        metadata = EventMetadata(
            event_id=metadata_dict["event_id"],
            event_type=metadata_dict["event_type"],
            event_version=metadata_dict["event_version"],
            timestamp=datetime.fromisoformat(metadata_dict["timestamp"]),
            aggregate_id=metadata_dict["aggregate_id"],
            aggregate_type=metadata_dict["aggregate_type"],
            aggregate_version=metadata_dict["aggregate_version"],
            sequence_number=metadata_dict["sequence_number"],
            causation_id=metadata_dict.get("causation_id"),
            correlation_id=metadata_dict.get("correlation_id"),
            user_id=metadata_dict.get("user_id")
        )
        
        # Create event instance
        event = cls(**data["data"])
        event.metadata = metadata
        return event
    
    def with_aggregate_info(
        self, 
        aggregate_id: str, 
        aggregate_type: str,
        aggregate_version: int
    ) -&gt; 'DomainEvent':
        """Set aggregate information."""
        self.metadata.aggregate_id = aggregate_id
        self.metadata.aggregate_type = aggregate_type
        self.metadata.aggregate_version = aggregate_version
        return self
    
    def with_causation(
        self,
        causation_id: str,
        correlation_id: Optional[str] = None
    ) -&gt; 'DomainEvent':
        """Set causation information."""
        self.metadata.causation_id = causation_id
        self.metadata.correlation_id = correlation_id or causation_id
        return self
```

Create `domain/events/order_events.py`:

```python
from dataclasses import dataclass
from datetime import datetime
from typing import Dict, Any, List, Optional
from decimal import Decimal

from .base import DomainEvent

@dataclass
class OrderCreated(DomainEvent):
    """Order created event."""
    order_id: str
    customer_id: str
    items: List[Dict[str, Any]]
    total_amount: Decimal
    shipping_address: Dict[str, str]
    
    def get_event_data(self) -&gt; Dict[str, Any]:
        return {
            "order_id": self.order_id,
            "customer_id": self.customer_id,
            "items": self.items,
            "total_amount": str(self.total_amount),
            "shipping_address": self.shipping_address
        }

@dataclass
class OrderItemAdded(DomainEvent):
    """Item added to order."""
    order_id: str
    product_id: str
    quantity: int
    unit_price: Decimal
    
    def get_event_data(self) -&gt; Dict[str, Any]:
        return {
            "order_id": self.order_id,
            "product_id": self.product_id,
            "quantity": self.quantity,
            "unit_price": str(self.unit_price)
        }

@dataclass
class OrderShipped(DomainEvent):
    """Order shipped event."""
    order_id: str
    tracking_number: str
    shipped_at: datetime
    carrier: str
    
    def get_event_data(self) -&gt; Dict[str, Any]:
        return {
            "order_id": self.order_id,
            "tracking_number": self.tracking_number,
            "shipped_at": self.shipped_at.isoformat(),
            "carrier": self.carrier
        }

@dataclass
class OrderCancelled(DomainEvent):
    """Order cancelled event."""
    order_id: str
    reason: str
    cancelled_at: datetime
    refund_amount: Optional[Decimal] = None
    
    def get_event_data(self) -&gt; Dict[str, Any]:
        return {
            "order_id": self.order_id,
            "reason": self.reason,
            "cancelled_at": self.cancelled_at.isoformat(),
            "refund_amount": str(self.refund_amount) if self.refund_amount else None
        }
```

### Step 3: Domain Commands

Create `domain/commands/base.py`:

**🤖 Copilot Prompt Suggestion #2:**
```python
# Create base command classes that:
# - Define command metadata and validation
# - Support command routing
# - Include idempotency keys
# - Track command source and authorization
# - Support command versioning
# - Implement command validation interface
# - Handle command timeout settings
# Use abstract base classes and validation
```

### Step 4: Domain Aggregates

Create `domain/aggregates/base.py`:

**🤖 Copilot Prompt Suggestion #3:**
```python
# Build an event-sourced aggregate base class that:
# - Manages aggregate state through events
# - Tracks uncommitted events
# - Implements event replay from history
# - Supports snapshots for performance
# - Handles concurrency with version checking
# - Provides event application interface
# - Validates business rules before events
# Make it generic and reusable
```

**Expected Implementation Pattern:**
```python
from abc import ABC, abstractmethod
from typing import List, Dict, Any, Optional, Type
import logging

from domain.events.base import DomainEvent

logger = logging.getLogger(__name__)

class AggregateRoot(ABC):
    """Base class for event-sourced aggregates."""
    
    def __init__(self, aggregate_id: str):
        self.aggregate_id = aggregate_id
        self.version = 0
        self._uncommitted_events: List[DomainEvent] = []
        self._event_handlers = self._register_event_handlers()
        
    @abstractmethod
    def _register_event_handlers(self) -&gt; Dict[Type[DomainEvent], callable]:
        """Register event handlers for the aggregate."""
        pass
    
    @property
    @abstractmethod
    def aggregate_type(self) -&gt; str:
        """Get the aggregate type name."""
        pass
    
    def apply_event(self, event: DomainEvent, is_new: bool = True) -&gt; None:
        """
        Apply an event to the aggregate.
        
        Args:
            event: The domain event to apply
            is_new: Whether this is a new event (vs replay)
        """
        # Get handler for event type
        event_type = type(event)
        handler = self._event_handlers.get(event_type)
        
        if not handler:
            logger.warning(
                f"No handler registered for event type {event_type.__name__}"
            )
            return
        
        # Apply event to update state
        handler(event)
        
        # Track new events
        if is_new:
            # Set aggregate information
            event.with_aggregate_info(
                aggregate_id=self.aggregate_id,
                aggregate_type=self.aggregate_type,
                aggregate_version=self.version + 1
            )
            
            self._uncommitted_events.append(event)
            self.version += 1
    
    def load_from_history(self, events: List[DomainEvent]) -&gt; None:
        """Rebuild aggregate state from event history."""
        for event in events:
            self.apply_event(event, is_new=False)
            self.version = event.metadata.aggregate_version
    
    def get_uncommitted_events(self) -&gt; List[DomainEvent]:
        """Get events that haven't been persisted."""
        return self._uncommitted_events.copy()
    
    def mark_events_as_committed(self) -&gt; None:
        """Clear uncommitted events after persistence."""
        self._uncommitted_events.clear()
    
    def take_snapshot(self) -&gt; Dict[str, Any]:
        """Create a snapshot of current state."""
        return {
            "aggregate_id": self.aggregate_id,
            "aggregate_type": self.aggregate_type,
            "version": self.version,
            "state": self._get_state_for_snapshot()
        }
    
    @abstractmethod
    def _get_state_for_snapshot(self) -&gt; Dict[str, Any]:
        """Get aggregate state for snapshot."""
        pass
    
    def load_from_snapshot(
        self, 
        snapshot: Dict[str, Any], 
        events_since_snapshot: List[DomainEvent]
    ) -&gt; None:
        """Load aggregate from snapshot and subsequent events."""
        # Restore state from snapshot
        self.aggregate_id = snapshot["aggregate_id"]
        self.version = snapshot["version"]
        self._restore_state_from_snapshot(snapshot["state"])
        
        # Apply events since snapshot
        for event in events_since_snapshot:
            self.apply_event(event, is_new=False)
            self.version = event.metadata.aggregate_version
    
    @abstractmethod
    def _restore_state_from_snapshot(self, state: Dict[str, Any]) -&gt; None:
        """Restore aggregate state from snapshot."""
        pass
```

Create `domain/aggregates/order.py`:

**🤖 Copilot Prompt Suggestion #4:**
```python
# Create an Order aggregate that:
# - Manages order lifecycle (create, add items, ship, cancel)
# - Enforces business rules (can't ship cancelled order)
# - Calculates order totals
# - Tracks order items and status
# - Handles order state transitions
# - Validates shipping addresses
# - Implements idempotent operations
# Include all event handlers and business logic
```

### Step 5: Event Store Implementation

Create `infrastructure/event_store.py`:

**🤖 Copilot Prompt Suggestion #5:**
```python
# Build an event store using Cosmos DB that:
# - Stores events with optimistic concurrency
# - Supports event streaming by aggregate
# - Implements snapshots for performance
# - Handles event versioning and upcasting
# - Provides event replay capabilities
# - Supports event queries by metadata
# - Implements transactional event saving
# Include connection pooling and retry logic
```

**Expected Implementation Pattern:**
```python
from typing import List, Optional, Dict, Any
import logging
from datetime import datetime
from azure.cosmos import CosmosClient, PartitionKey
from azure.cosmos.exceptions import CosmosResourceExistsError, CosmosHttpResponseError

from domain.events.base import DomainEvent
from domain.aggregates.base import AggregateRoot

logger = logging.getLogger(__name__)

class EventStore:
    """Cosmos DB based event store."""
    
    def __init__(self, connection_string: str, database_name: str):
        self.client = CosmosClient.from_connection_string(connection_string)
        self.database = self.client.get_database_client(database_name)
        self.events_container = self.database.get_container_client("Events")
        self.snapshots_container = self.database.get_container_client("Snapshots")
        
    async def save_events(
        self, 
        aggregate_id: str,
        events: List[DomainEvent],
        expected_version: int
    ) -&gt; None:
        """
        Save events with optimistic concurrency control.
        
        Args:
            aggregate_id: The aggregate ID
            events: Events to save
            expected_version: Expected current version for concurrency
        """
        if not events:
            return
        
        # Verify expected version
        current_version = await self._get_aggregate_version(aggregate_id)
        if current_version != expected_version:
            raise ConcurrencyException(
                f"Expected version {expected_version}, but current is {current_version}"
            )
        
        # Save events transactionally
        try:
            for i, event in enumerate(events):
                event.metadata.sequence_number = current_version + i + 1
                
                event_doc = {
                    "id": event.metadata.event_id,
                    "aggregateId": aggregate_id,
                    "eventType": event.metadata.event_type,
                    "eventVersion": event.metadata.event_version,
                    "sequenceNumber": event.metadata.sequence_number,
                    "timestamp": event.metadata.timestamp.isoformat(),
                    "data": event.to_dict(),
                    # Partition by aggregate ID for efficient queries
                    "partitionKey": aggregate_id
                }
                
                self.events_container.create_item(
                    body=event_doc,
                    enable_automatic_id_generation=False
                )
                
            logger.info(
                f"Saved {len(events)} events for aggregate {aggregate_id}"
            )
            
        except CosmosHttpResponseError as e:
            logger.error(f"Failed to save events: {str(e)}")
            raise
    
    async def get_events(
        self,
        aggregate_id: str,
        from_version: int = 0,
        to_version: Optional[int] = None
    ) -&gt; List[DomainEvent]:
        """Get events for an aggregate."""
        query = """
        SELECT * FROM c 
        WHERE c.aggregateId = @aggregateId 
        AND c.sequenceNumber &gt; @fromVersion
        """
        
        parameters = [
            {{"name": "@aggregateId", "value": aggregate_id}},
            {{"name": "@fromVersion", "value": from_version}}
        ]
        
        if to_version:
            query += " AND c.sequenceNumber &lt;= @toVersion"
            parameters.append({{"name": "@toVersion", "value": to_version}})
        
        query += " ORDER BY c.sequenceNumber"
        
        items = list(self.events_container.query_items(
            query=query,
            parameters=parameters,
            partition_key=aggregate_id
        ))
        
        # Convert to domain events
        events = []
        for item in items:
            event_data = item["data"]
            event_type = self._get_event_class(event_data["metadata"]["event_type"])
            if event_type:
                event = event_type.from_dict(event_data)
                events.append(event)
        
        return events
    
    async def save_snapshot(
        self,
        aggregate: AggregateRoot
    ) -&gt; None:
        """Save aggregate snapshot."""
        snapshot = aggregate.take_snapshot()
        snapshot_doc = {
            "id": f"{{aggregate.aggregate_id}}-v{{aggregate.version}}",
            "aggregateId": aggregate.aggregate_id,
            "aggregateType": aggregate.aggregate_type,
            "version": aggregate.version,
            "timestamp": datetime.utcnow().isoformat(),
            "data": snapshot,
            "partitionKey": aggregate.aggregate_id
        }
        
        self.snapshots_container.upsert_item(
            body=snapshot_doc,
            partition_key=aggregate.aggregate_id
        )
        
        logger.info(
            f"Saved snapshot for {aggregate.aggregate_id} at version {aggregate.version}"
        )
    
    async def get_snapshot(
        self,
        aggregate_id: str
    ) -&gt; Optional[Dict[str, Any]]:
        """Get latest snapshot for aggregate."""
        query = """
        SELECT TOP 1 * FROM c 
        WHERE c.aggregateId = @aggregateId 
        ORDER BY c.version DESC
        """
        
        items = list(self.snapshots_container.query_items(
            query=query,
            parameters=[{{"name": "@aggregateId", "value": aggregate_id}}],
            partition_key=aggregate_id
        ))
        
        if items:
            return items[0]["data"]
        return None
    
    async def _get_aggregate_version(self, aggregate_id: str) -&gt; int:
        """Get current version of aggregate."""
        query = """
        SELECT TOP 1 c.sequenceNumber FROM c 
        WHERE c.aggregateId = @aggregateId 
        ORDER BY c.sequenceNumber DESC
        """
        
        items = list(self.events_container.query_items(
            query=query,
            parameters=[{{"name": "@aggregateId", "value": aggregate_id}}],
            partition_key=aggregate_id
        ))
        
        if items:
            return items[0]["sequenceNumber"]
        return 0
    
    def _get_event_class(self, event_type: str) -&gt; Optional[Type[DomainEvent]]:
        """Get event class by name."""
        # Import and cache event classes
        # This is simplified - in production use a proper registry
        from domain.events.order_events import (
            OrderCreated, OrderItemAdded, OrderShipped, OrderCancelled
        )
        
        event_classes = {
            "OrderCreated": OrderCreated,
            "OrderItemAdded": OrderItemAdded,
            "OrderShipped": OrderShipped,
            "OrderCancelled": OrderCancelled
        }
        
        return event_classes.get(event_type)

class ConcurrencyException(Exception):
    """Raised when optimistic concurrency check fails."""
    pass
```

### Step 6: Command Handlers

Create `application/command_handlers.py`:

**🤖 Copilot Prompt Suggestion #6:**
```python
# Create command handlers that:
# - Load aggregates from event store
# - Execute business logic via aggregates
# - Save resulting events
# - Publish events to service bus
# - Handle command validation
# - Implement idempotency checks
# - Track command execution metrics
# Include proper error handling and logging
```

### Step 7: Command API

Create `api/command_api.py`:

```python
from fastapi import FastAPI, HTTPException, Depends
from contextlib import asynccontextmanager
import logging
from typing import Dict, Any
import uuid

from domain.commands.order_commands import (
    CreateOrderCommand, AddOrderItemCommand, 
    ShipOrderCommand, CancelOrderCommand
)
from application.command_bus import CommandBus
from application.command_handlers import OrderCommandHandler
from infrastructure.event_store import EventStore
from infrastructure.event_bus import EventBus
from config import Settings

logger = logging.getLogger(__name__)

# Global instances
settings = None
command_bus = None
event_store = None
event_bus = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize services on startup."""
    global settings, command_bus, event_store, event_bus
    
    logger.info("Starting Command API...")
    
    settings = Settings()
    event_store = EventStore(
        settings.cosmos_connection_string,
        settings.cosmos_database_name
    )
    event_bus = EventBus(settings)
    
    # Register command handlers
    command_bus = CommandBus()
    order_handler = OrderCommandHandler(event_store, event_bus)
    
    command_bus.register_handler(CreateOrderCommand, order_handler.handle_create_order)
    command_bus.register_handler(AddOrderItemCommand, order_handler.handle_add_item)
    command_bus.register_handler(ShipOrderCommand, order_handler.handle_ship_order)
    command_bus.register_handler(CancelOrderCommand, order_handler.handle_cancel_order)
    
    yield
    
    logger.info("Shutting down Command API...")

app = FastAPI(
    title="CQRS Command API",
    description="Command side of CQRS implementation",
    version="1.0.0",
    lifespan=lifespan
)

@app.post("/orders", response_model=Dict[str, Any])
async def create_order(
    customer_id: str,
    items: List[Dict[str, Any]],
    shipping_address: Dict[str, str]
):
    """Create a new order."""
    command = CreateOrderCommand(
        order_id=str(uuid.uuid4()),
        customer_id=customer_id,
        items=items,
        shipping_address=shipping_address
    )
    
    try:
        await command_bus.send(command)
        return {
            "order_id": command.order_id,
            "status": "created",
            "message": "Order created successfully"
        }
    except Exception as e:
        logger.error(f"Failed to create order: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/orders/{order_id}/items", response_model=Dict[str, Any])
async def add_order_item(
    order_id: str,
    product_id: str,
    quantity: int,
    unit_price: float
):
    """Add item to existing order."""
    command = AddOrderItemCommand(
        order_id=order_id,
        product_id=product_id,
        quantity=quantity,
        unit_price=unit_price
    )
    
    try:
        await command_bus.send(command)
        return {
            "order_id": order_id,
            "status": "item_added",
            "message": f"Added {{quantity}} of {{product_id}} to order"
        }
    except Exception as e:
        logger.error(f"Failed to add item: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/orders/{order_id}/ship", response_model=Dict[str, Any])
async def ship_order(
    order_id: str,
    tracking_number: str,
    carrier: str
):
    """Mark order as shipped."""
    command = ShipOrderCommand(
        order_id=order_id,
        tracking_number=tracking_number,
        carrier=carrier
    )
    
    try:
        await command_bus.send(command)
        return {
            "order_id": order_id,
            "status": "shipped",
            "tracking_number": tracking_number,
            "message": "Order shipped successfully"
        }
    except Exception as e:
        logger.error(f"Failed to ship order: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/orders/{order_id}/cancel", response_model=Dict[str, Any])
async def cancel_order(
    order_id: str,
    reason: str
):
    """Cancel an order."""
    command = CancelOrderCommand(
        order_id=order_id,
        reason=reason
    )
    
    try:
        await command_bus.send(command)
        return {
            "order_id": order_id,
            "status": "cancelled",
            "message": "Order cancelled successfully"
        }
    except Exception as e:
        logger.error(f"Failed to cancel order: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/health")
async def health_check():
    """Check API health."""
    return {
        "status": "healthy",
        "components": {
            "event_store": "connected",
            "event_bus": "active",
            "command_bus": "ready"
        }
    }
```

### Step 8: Testing Command Side

Create `tests/test_event_sourcing.py`:

**🤖 Copilot Prompt Suggestion #7:**
```python
# Create tests for event sourcing:
# - Test aggregate event application
# - Verify state after event replay
# - Test optimistic concurrency
# - Validate event ordering
# - Test snapshot creation and loading
# - Verify idempotent operations
# - Test compensating events
# Use pytest with async support and mocking
```

## 📊 Partee 1 Validation

### Test Event Store

```python
# Create test_event_store.py
import asyncio
from infrastructure.event_store import EventStore
from domain.events.order_events import OrderCreated
from decimal import Decimal

async def test_event_store():
    """Test basic event store operations."""
    store = EventStore(
        connection_string="your_cosmos_connection",
        database_name="EventStore"
    )
    
    # Create test event
    event = OrderCreated(
        order_id="TEST-001",
        customer_id="CUST-001",
        items=[{{"product_id": "PROD-001", "quantity": 2}}],
        total_amount=Decimal("99.99"),
        shipping_address={{"street": "123 Main St", "city": "Test City"}}
    )
    
    # Save event
    await store.save_events("TEST-001", [event], expected_version=0)
    
    # Retrieve events
    events = await store.get_events("TEST-001")
    assert len(events) == 1
    assert events[0].order_id == "TEST-001"
    
    print("✅ Event store test passed!")

asyncio.run(test_event_store())
```

### Test Command Processing

```bash
# Create order
curl -X POST "http://localhost:8000/orders" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "CUST-123",
    "items": [
      {
        "product_id": "PROD-001",
        "quantity": 2,
        "unit_price": 49.99
      }
    ],
    "shipping_address": {
      "street": "123 Main St",
      "city": "Seattle",
      "state": "WA",
      "zip": "98101"
    }
  }'

# Add item to order
curl -X POST "http://localhost:8000/orders/{order_id}/items" \
  -H "Content-Type: application/json" \
  -d '{
    "product_id": "PROD-002",
    "quantity": 1,
    "unit_price": 29.99
  }'
```

## ✅ Partee 1 Success Criteria

Before proceeding to Partee 2:

1. **Event Store**: Events saved and retrieved correctly
2. **Aggregates**: State rebuilt from events accurately
3. **Commands**: Processed with validation
4. **Concurrency**: Optimistic locking working
5. **Events Published**: To Service Bus for projections
6. **API**: All endpoints functional

## 💡 Partee 1 Key Takeaways

- Event sourcing provides complete audit trail
- Aggregates enforce business rules
- Commands represent intentions
- Events represent facts
- Optimistic concurrency prevents conflicts

## Próximos Pasos

You've successfully built the command side! Continuar to Partee 2 where you'll implement projections and query models.

[Continuar to Partee 2 →](./exercise1-part2)