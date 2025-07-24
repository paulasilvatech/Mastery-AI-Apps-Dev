---
sidebar_position: 3
title: "Exercise 2: Part 2"
description: "## 🎯 Part 2 Overview"
---

# Exercise 2: CQRS with Event Sourcing - Part 2 (⭐⭐ Application)

## 🎯 Part 2 Overview

**Duration**: 35 minutes  
**Focus**: Query side implementation with projections and read models

In Part 2, you'll complete the CQRS system by implementing event projections that build optimized read models from the event stream, creating query handlers, and adding caching for performance.

## 🎓 Learning Objectives - Part 2

By completing Part 2, you will:
- Build event projections and processors
- Create denormalized read models
- Implement efficient query handlers
- Add caching with Redis
- Handle eventual consistency
- Monitor projection lag

## 🚀 Part 2: Query Side Implementation

### Step 9: Projection Infrastructure

Create `projections/base.py`:

**🤖 Copilot Prompt Suggestion #8:**
```python
# Create a projection base class that:
# - Subscribes to specific event types
# - Processes events in order
# - Tracks projection position/checkpoint
# - Handles replay from specific position
# - Supports parallel processing
# - Implements error handling and retry
# - Monitors projection lag
# Make it resilient and observable
```

**Expected Implementation:**
```python
from abc import ABC, abstractmethod
from typing import List, Dict, Any, Set, Type
import asyncio
import logging
from datetime import datetime

from domain.events.base import DomainEvent
from infrastructure.event_store import EventStore

logger = logging.getLogger(__name__)

class Projection(ABC):
    """Base class for event projections."""
    
    def __init__(
        self, 
        name: str,
        event_store: EventStore,
        checkpoint_store: 'CheckpointStore'
    ):
        self.name = name
        self.event_store = event_store
        self.checkpoint_store = checkpoint_store
        self._is_running = False
        self._event_handlers = self._register_event_handlers()
        
    @abstractmethod
    def _register_event_handlers(self) -&gt; Dict[Type[DomainEvent], callable]:
        """Register handlers for specific event types."""
        pass
    
    @property
    @abstractmethod
    def subscribed_events(self) -&gt; Set[str]:
        """Get event types this projection subscribes to."""
        pass
    
    async def start(self) -&gt; None:
        """Start processing events."""
        self._is_running = True
        logger.info(f"Starting projection {self.name}")
        
        # Get last checkpoint
        checkpoint = await self.checkpoint_store.get_checkpoint(self.name)
        last_position = checkpoint.position if checkpoint else 0
        
        while self._is_running:
            try:
                # Get next batch of events
                events = await self._get_events_batch(last_position)
                
                if events:
                    # Process events
                    for event in events:
                        await self._process_event(event)
                        last_position = event.metadata.sequence_number
                    
                    # Update checkpoint
                    await self.checkpoint_store.update_checkpoint(
                        self.name, 
                        last_position
                    )
                    
                    logger.debug(
                        f"Projection {self.name} processed {len(events)} events"
                    )
                else:
                    # No new events, wait
                    await asyncio.sleep(1)
                    
            except Exception as e:
                logger.error(f"Error in projection {self.name}: {str(e)}")
                await asyncio.sleep(5)  # Back off on error
    
    async def stop(self) -&gt; None:
        """Stop processing events."""
        self._is_running = False
        logger.info(f"Stopping projection {self.name}")
    
    async def _get_events_batch(
        self, 
        from_position: int, 
        batch_size: int = 100
    ) -&gt; List[DomainEvent]:
        """Get next batch of events to process."""
        # In production, this would query across all aggregates
        # For now, simplified to demonstrate the pattern
        return await self.event_store.get_all_events(
            from_sequence=from_position,
            limit=batch_size,
            event_types=self.subscribed_events
        )
    
    async def _process_event(self, event: DomainEvent) -&gt; None:
        """Process a single event."""
        event_type = type(event)
        handler = self._event_handlers.get(event_type)
        
        if handler:
            try:
                await handler(event)
            except Exception as e:
                logger.error(
                    f"Failed to process event {event.metadata.event_id}: {str(e)}"
                )
                raise
    
    async def rebuild(self) -&gt; None:
        """Rebuild projection from beginning."""
        logger.info(f"Rebuilding projection {self.name}")
        
        # Reset checkpoint
        await self.checkpoint_store.reset_checkpoint(self.name)
        
        # Clear existing data
        await self._clear_projection_data()
        
        # Start processing from beginning
        await self.start()
    
    @abstractmethod
    async def _clear_projection_data(self) -&gt; None:
        """Clear all projection data for rebuild."""
        pass
    
    def get_lag_metrics(self) -&gt; Dict[str, Any]:
        """Get projection lag metrics."""
        # Implementation would track actual lag
        return {
            "projection": self.name,
            "last_processed": datetime.utcnow().isoformat(),
            "lag_seconds": 0,
            "events_behind": 0
        }

class CheckpointStore:
    """Store projection checkpoints."""
    
    def __init__(self, redis_client):
        self.redis = redis_client
        self.prefix = "projection:checkpoint:"
        
    async def get_checkpoint(self, projection_name: str) -&gt; Optional['Checkpoint']:
        """Get checkpoint for projection."""
        key = f"{self.prefix}{projection_name}"
        data = await self.redis.get(key)
        
        if data:
            return Checkpoint.from_json(data)
        return None
    
    async def update_checkpoint(
        self, 
        projection_name: str, 
        position: int
    ) -&gt; None:
        """Update projection checkpoint."""
        checkpoint = Checkpoint(
            projection_name=projection_name,
            position=position,
            timestamp=datetime.utcnow()
        )
        
        key = f"{self.prefix}{projection_name}"
        await self.redis.set(key, checkpoint.to_json())
    
    async def reset_checkpoint(self, projection_name: str) -&gt; None:
        """Reset checkpoint to start."""
        key = f"{self.prefix}{projection_name}"
        await self.redis.delete(key)

@dataclass
class Checkpoint:
    """Projection checkpoint."""
    projection_name: str
    position: int
    timestamp: datetime
    
    def to_json(self) -&gt; str:
        return json.dumps({
            "projection_name": self.projection_name,
            "position": self.position,
            "timestamp": self.timestamp.isoformat()
        })
    
    @classmethod
    def from_json(cls, data: str) -&gt; 'Checkpoint':
        obj = json.loads(data)
        return cls(
            projection_name=obj["projection_name"],
            position=obj["position"],
            timestamp=datetime.fromisoformat(obj["timestamp"])
        )
```

### Step 10: Order Read Model

Create `projections/order_projection.py`:

**🤖 Copilot Prompt Suggestion #9:**
```python
# Create an order projection that:
# - Builds denormalized order view
# - Updates on order events
# - Calculates running totals
# - Maintains order status history
# - Stores in PostgreSQL for queries
# - Updates search index
# - Handles out-of-order events
# Include proper indexes for performance
```

**Expected Implementation Pattern:**
```python
from typing import Dict, Type, Set
import logging
from datetime import datetime
from decimal import Decimal
import asyncpg

from projections.base import Projection
from domain.events.base import DomainEvent
from domain.events.order_events import (
    OrderCreated, OrderItemAdded, OrderShipped, OrderCancelled
)

logger = logging.getLogger(__name__)

class OrderProjection(Projection):
    """Projects order events to read model."""
    
    def __init__(self, event_store, checkpoint_store, db_pool):
        super().__init__("OrderProjection", event_store, checkpoint_store)
        self.db_pool = db_pool
        
    def _register_event_handlers(self) -&gt; Dict[Type[DomainEvent], callable]:
        return {
            OrderCreated: self._handle_order_created,
            OrderItemAdded: self._handle_item_added,
            OrderShipped: self._handle_order_shipped,
            OrderCancelled: self._handle_order_cancelled
        }
    
    @property
    def subscribed_events(self) -&gt; Set[str]:
        return {
            "OrderCreated", 
            "OrderItemAdded", 
            "OrderShipped", 
            "OrderCancelled"
        }
    
    async def _handle_order_created(self, event: OrderCreated) -&gt; None:
        """Handle order created event."""
        async with self.db_pool.acquire() as conn:
            # Insert order
            await conn.execute("""
                INSERT INTO orders (
                    order_id, customer_id, status, total_amount,
                    shipping_street, shipping_city, shipping_state, shipping_zip,
                    created_at, updated_at, version
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
                ON CONFLICT (order_id) DO NOTHING
            """, 
                event.order_id,
                event.customer_id,
                'CREATED',
                event.total_amount,
                event.shipping_address.get('street'),
                event.shipping_address.get('city'),
                event.shipping_address.get('state'),
                event.shipping_address.get('zip'),
                event.metadata.timestamp,
                event.metadata.timestamp,
                event.metadata.aggregate_version
            )
            
            # Insert order items
            for item in event.items:
                await conn.execute("""
                    INSERT INTO order_items (
                        order_id, product_id, quantity, unit_price
                    ) VALUES ($1, $2, $3, $4)
                """,
                    event.order_id,
                    item['product_id'],
                    item['quantity'],
                    Decimal(str(item['unit_price']))
                )
            
            # Insert status history
            await conn.execute("""
                INSERT INTO order_status_history (
                    order_id, status, changed_at, details
                ) VALUES ($1, $2, $3, $4)
            """,
                event.order_id,
                'CREATED',
                event.metadata.timestamp,
                f"Order created with {len(event.items)} items"
            )
            
            logger.info(f"Projected OrderCreated for {event.order_id}")
    
    async def _handle_item_added(self, event: OrderItemAdded) -&gt; None:
        """Handle item added event."""
        async with self.db_pool.acquire() as conn:
            # Add item
            await conn.execute("""
                INSERT INTO order_items (
                    order_id, product_id, quantity, unit_price
                ) VALUES ($1, $2, $3, $4)
                ON CONFLICT (order_id, product_id) 
                DO UPDATE SET 
                    quantity = order_items.quantity + EXCLUDED.quantity
            """,
                event.order_id,
                event.product_id,
                event.quantity,
                event.unit_price
            )
            
            # Update order total
            await conn.execute("""
                UPDATE orders 
                SET total_amount = total_amount + ($1 * $2),
                    updated_at = $3,
                    version = $4
                WHERE order_id = $5
            """,
                event.quantity,
                event.unit_price,
                event.metadata.timestamp,
                event.metadata.aggregate_version,
                event.order_id
            )
            
            logger.info(f"Projected OrderItemAdded for {event.order_id}")
    
    async def _handle_order_shipped(self, event: OrderShipped) -&gt; None:
        """Handle order shipped event."""
        async with self.db_pool.acquire() as conn:
            # Update order status
            await conn.execute("""
                UPDATE orders 
                SET status = 'SHIPPED',
                    tracking_number = $1,
                    carrier = $2,
                    shipped_at = $3,
                    updated_at = $4,
                    version = $5
                WHERE order_id = $6
            """,
                event.tracking_number,
                event.carrier,
                event.shipped_at,
                event.metadata.timestamp,
                event.metadata.aggregate_version,
                event.order_id
            )
            
            # Add to status history
            await conn.execute("""
                INSERT INTO order_status_history (
                    order_id, status, changed_at, details
                ) VALUES ($1, $2, $3, $4)
            """,
                event.order_id,
                'SHIPPED',
                event.metadata.timestamp,
                f"Shipped via {event.carrier}, tracking: {event.tracking_number}"
            )
            
            logger.info(f"Projected OrderShipped for {event.order_id}")
    
    async def _handle_order_cancelled(self, event: OrderCancelled) -&gt; None:
        """Handle order cancelled event."""
        async with self.db_pool.acquire() as conn:
            # Update order status
            await conn.execute("""
                UPDATE orders 
                SET status = 'CANCELLED',
                    cancelled_at = $1,
                    cancellation_reason = $2,
                    updated_at = $3,
                    version = $4
                WHERE order_id = $5
            """,
                event.cancelled_at,
                event.reason,
                event.metadata.timestamp,
                event.metadata.aggregate_version,
                event.order_id
            )
            
            # Add to status history
            await conn.execute("""
                INSERT INTO order_status_history (
                    order_id, status, changed_at, details
                ) VALUES ($1, $2, $3, $4)
            """,
                event.order_id,
                'CANCELLED',
                event.metadata.timestamp,
                f"Cancelled: {event.reason}"
            )
            
            logger.info(f"Projected OrderCancelled for {event.order_id}")
    
    async def _clear_projection_data(self) -&gt; None:
        """Clear projection data for rebuild."""
        async with self.db_pool.acquire() as conn:
            await conn.execute("TRUNCATE TABLE orders CASCADE")
            await conn.execute("TRUNCATE TABLE order_items CASCADE")
            await conn.execute("TRUNCATE TABLE order_status_history CASCADE")
```

### Step 11: Query Handlers

Create `queries/order_queries.py`:

**🤖 Copilot Prompt Suggestion #10:**
```python
# Create query handlers that:
# - Query read models efficiently
# - Support filtering and pagination
# - Implement caching strategies
# - Handle stale data gracefully
# - Provide different view models
# - Support full-text search
# - Include query performance metrics
# Use async database queries
```

### Step 12: Query API

Create `api/query_api.py`:

```python
from fastapi import FastAPI, HTTPException, Query
from contextlib import asynccontextmanager
import logging
from typing import List, Optional, Dict, Any
import redis.asyncio as redis
import asyncpg
import json

from queries.order_queries import OrderQueryHandler
from queries.models import OrderView, OrderListView, OrderStatusHistory

logger = logging.getLogger(__name__)

# Global instances
settings = None
db_pool = None
redis_client = None
query_handler = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize services on startup."""
    global settings, db_pool, redis_client, query_handler
    
    logger.info("Starting Query API...")
    
    settings = Settings()
    
    # Initialize database pool
    db_pool = await asyncpg.create_pool(
        settings.postgres_dsn,
        min_size=10,
        max_size=20
    )
    
    # Initialize Redis
    redis_client = redis.from_url(settings.redis_url)
    
    # Initialize query handler
    query_handler = OrderQueryHandler(db_pool, redis_client)
    
    yield
    
    # Cleanup
    await db_pool.close()
    await redis_client.close()
    logger.info("Shutting down Query API...")

app = FastAPI(
    title="CQRS Query API",
    description="Query side of CQRS implementation",
    version="1.0.0",
    lifespan=lifespan
)

@app.get("/orders/{order_id}", response_model=OrderView)
async def get_order(order_id: str):
    """Get order by ID."""
    # Check cache first
    cache_key = f"order:{order_id}"
    cached = await redis_client.get(cache_key)
    
    if cached:
        logger.debug(f"Cache hit for order {order_id}")
        return OrderView(**json.loads(cached))
    
    # Query database
    order = await query_handler.get_order_by_id(order_id)
    
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    # Cache for 5 minutes
    await redis_client.setex(
        cache_key, 
        300, 
        json.dumps(order.dict())
    )
    
    return order

@app.get("/orders", response_model=OrderListView)
async def list_orders(
    customer_id: Optional[str] = None,
    status: Optional[str] = None,
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100)
):
    """List orders with filtering and pagination."""
    filters = {
        "customer_id": customer_id,
        "status": status,
        "from_date": from_date,
        "to_date": to_date
    }
    
    # Remove None values
    filters = {k: v for k, v in filters.items() if v is not None}
    
    # Get orders
    result = await query_handler.list_orders(
        filters=filters,
        page=page,
        page_size=page_size
    )
    
    return result

@app.get("/orders/{order_id}/history", response_model=List[OrderStatusHistory])
async def get_order_history(order_id: str):
    """Get order status history."""
    history = await query_handler.get_order_history(order_id)
    
    if not history:
        raise HTTPException(status_code=404, detail="Order not found")
    
    return history

@app.get("/orders/search")
async def search_orders(
    q: str = Query(..., min_length=3),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100)
):
    """Full-text search orders."""
    results = await query_handler.search_orders(
        query=q,
        page=page,
        page_size=page_size
    )
    
    return results

@app.get("/customers/{customer_id}/order-summary")
async def get_customer_order_summary(customer_id: str):
    """Get customer order summary."""
    # Complex aggregation query
    summary = await query_handler.get_customer_summary(customer_id)
    
    if not summary:
        raise HTTPException(status_code=404, detail="Customer not found")
    
    return summary

@app.get("/reports/daily-orders")
async def get_daily_order_report(
    date: str = Query(..., regex="^\d{\`4\`}-\d{\`2\`}-\d{\`2\`}$")
):
    """Get daily order report."""
    # Check cache first
    cache_key = f"report:daily:{date}"
    cached = await redis_client.get(cache_key)
    
    if cached:
        return json.loads(cached)
    
    # Generate report
    report = await query_handler.get_daily_report(date)
    
    # Cache until next day
    await redis_client.setex(
        cache_key,
        86400,  # 24 hours
        json.dumps(report)
    )
    
    return report

@app.get("/health")
async def health_check():
    """Check API health."""
    # Check database
    try:
        async with db_pool.acquire() as conn:
            await conn.fetchval("SELECT 1")
        db_status = "connected"
    except:
        db_status = "error"
    
    # Check Redis
    try:
        await redis_client.ping()
        redis_status = "connected"
    except:
        redis_status = "error"
    
    return {
        "status": "healthy" if db_status == "connected" else "degraded",
        "components": {
            "database": db_status,
            "cache": redis_status
        }
    }

@app.get("/metrics")
async def get_metrics():
    """Get query performance metrics."""
    return await query_handler.get_query_metrics()
```

### Step 13: Database Schema

Create `schema/read_models.sql`:

```sql
-- Orders read model
CREATE TABLE IF NOT EXISTS orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    
    -- Denormalized shipping address
    shipping_street VARCHAR(255),
    shipping_city VARCHAR(100),
    shipping_state VARCHAR(50),
    shipping_zip VARCHAR(20),
    
    -- Shipping info
    tracking_number VARCHAR(100),
    carrier VARCHAR(50),
    shipped_at TIMESTAMP,
    
    -- Cancellation info
    cancelled_at TIMESTAMP,
    cancellation_reason TEXT,
    
    -- Metadata
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    version INT NOT NULL,
    
    -- Indexes for common queries
    INDEX idx_customer_id (customer_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    INDEX idx_shipped_at (shipped_at)
);

-- Order items
CREATE TABLE IF NOT EXISTS order_items (
    order_id VARCHAR(50),
    product_id VARCHAR(50),
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);

-- Order status history
CREATE TABLE IF NOT EXISTS order_status_history (
    id SERIAL PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL,
    changed_at TIMESTAMP NOT NULL,
    details TEXT,
    
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    INDEX idx_order_status (order_id, changed_at)
);

-- Full-text search
CREATE FULLTEXT INDEX ft_orders ON orders(order_id, customer_id, shipping_city);

-- Materialized view for reporting
CREATE MATERIALIZED VIEW daily_order_summary AS
SELECT 
    DATE(created_at) as order_date,
    COUNT(*) as total_orders,
    COUNT(DISTINCT customer_id) as unique_customers,
    SUM(total_amount) as revenue,
    COUNT(CASE WHEN status = 'SHIPPED' THEN 1 END) as shipped_orders,
    COUNT(CASE WHEN status = 'CANCELLED' THEN 1 END) as cancelled_orders
FROM orders
GROUP BY DATE(created_at);

-- Refresh materialized view daily
CREATE EVENT refresh_daily_summary
ON SCHEDULE EVERY 1 DAY
DO REFRESH MATERIALIZED VIEW daily_order_summary;
```

### Step 14: Complete System Test

Create `tests/test_cqrs_integration.py`:

**🤖 Copilot Prompt Suggestion #11:**
```python
# Create integration tests that:
# - Send commands and verify events
# - Check projections are updated
# - Query read models
# - Verify eventual consistency
# - Test concurrent operations
# - Measure end-to-end latency
# - Validate cache behavior
# Include performance benchmarks
```

## 📊 Complete System Testing

### Run Both APIs

```bash
# Terminal 1: Run Command API
uvicorn api.command_api:app --port 8001 --reload

# Terminal 2: Run Query API  
uvicorn api.query_api:app --port 8002 --reload

# Terminal 3: Run Projection Worker
python run_projections.py
```

### End-to-End Test

```bash
# Create order (Command API)
ORDER_ID=$(curl -X POST "http://localhost:8001/orders" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "CUST-001",
    "items": [
      {"product_id": "PROD-001", "quantity": 2, "unit_price": 49.99},
      {"product_id": "PROD-002", "quantity": 1, "unit_price": 29.99}
    ],
    "shipping_address": {
      "street": "123 Main St",
      "city": "Seattle",
      "state": "WA",
      "zip": "98101"
    }
  }' | jq -r '.order_id')

echo "Created order: $ORDER_ID"

# Wait for projection
sleep 2

# Query order (Query API)
curl "http://localhost:8002/orders/$ORDER_ID" | jq

# Get order history
curl "http://localhost:8002/orders/$ORDER_ID/history" | jq

# Search orders
curl "http://localhost:8002/orders/search?q=Seattle" | jq
```

### Performance Test

```python
# Create performance_test_cqrs.py
import asyncio
import httpx
import time
import statistics

async def test_cqrs_performance():
    """Test CQRS system performance."""
    async with httpx.AsyncClient() as client:
        # Create 100 orders
        create_times = []
        order_ids = []
        
        for i in range(100):
            start = time.time()
            response = await client.post(
                "http://localhost:8001/orders",
                json={
                    "customer_id": f"CUST-{{{{i:03d}}}}",
                    "items": [{{{{"product_id": "PROD-001", "quantity": 1, "unit_price": 99.99}}}}],
                    "shipping_address": {{{{"street": f"{{{{i}}}} Test St", "city": "Seattle", "state": "WA", "zip": "98101"}}}}
                }
            )
            create_times.append(time.time() - start)
            order_ids.append(response.json()["order_id"])
        
        print(f"Command processing: avg {statistics.mean(create_times)*1000:.2f}ms")
        
        # Wait for projections
        await asyncio.sleep(5)
        
        # Query orders
        query_times = []
        for order_id in order_ids[:20]:  # Sample 20
            start = time.time()
            response = await client.get(f"http://localhost:8002/orders/{order_id}")
            query_times.append(time.time() - start)
        
        print(f"Query processing: avg {statistics.mean(query_times)*1000:.2f}ms")
        
        # Test listing
        start = time.time()
        response = await client.get("http://localhost:8002/orders?page_size=50")
        print(f"List 50 orders: {(time.time() - start)*1000:.2f}ms")

asyncio.run(test_cqrs_performance())
```

## ✅ Exercise 2 Success Criteria

Your CQRS/ES system is complete when:

1. **Commands**: Process and generate events correctly
2. **Event Store**: Persists with versioning
3. **Projections**: Build read models accurately
4. **Queries**: Return data efficiently
5. **Consistency**: Eventually consistent
6. **Performance**: Less than 50ms query response

## 🏆 Extension Challenges

1. **Add Snapshots**: Implement aggregate snapshots
2. **Multiple Projections**: Add inventory projection
3. **Event Replay**: Build admin UI for replays
4. **Saga Integration**: Connect to Exercise 3

## 💡 Key Takeaways

- CQRS separates read and write concerns
- Event sourcing provides audit trail
- Projections create optimized views
- Eventual consistency is acceptable
- Caching improves query performance

## 📚 Additional Resources

- [Event Sourcing](https://martinfowler.com/eaaDev/EventSourcing.html)
- [CQRS Journey](https://docs.microsoft.com/en-us/previous-versions/msp-n-p/jj554200(v=pandp.10))
- [Greg Young - CQRS Documents](https://cqrs.files.wordpress.com/2010/11/cqrs_documents.pdf)

## Next Steps

Congratulations on implementing CQRS with Event Sourcing! Continue to Exercise 3 where you'll build a distributed saga.

[Continue to Exercise 3 →](../exercise3-saga/instructions.md)