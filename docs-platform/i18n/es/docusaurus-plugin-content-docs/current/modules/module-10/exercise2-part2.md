---
sidebar_position: 6
title: "Exercise 2: Part 2"
description: "### Step 5: Create Workers"
---

# Ejercicio 2: Event-Driven Order Processing System (Partee 2)

### Step 5: Create Workers

**Copilot Prompt Suggestion:**
```python
# Create a validation worker that:
# - Subscribes to 'order_created' events
# - Validates order data (email, items, amounts)
# - Publishes 'order_validated' or 'order_failed' events
# - Updates order status in database
# - Simulates processing time (1-2 seconds)
# - Handles errors gracefully
# Include logging and retry logic
```

**Expected Output:**

```python
# workers/validation_worker.py
import asyncio
import random
import logging
from datetime import datetime
from models.order import OrderStatus
from models.events import OrderEvent, EventType

logger = logging.getLogger(__name__)

class ValidationWorker:
    def __init__(self, event_bus, database):
        self.event_bus = event_bus
        self.database = database
        self.name = "ValidationWorker"
        
    async def start(self):
        """Start worker and subscribe to events"""
        self.event_bus.subscribe("order_created", self.handle_order_created)
        logger.info(f"{self.name} started")
        
    async def handle_order_created(self, event: dict):
        """Handle order created event"""
        order_id = event.get("order_id")
        logger.info(f"{self.name}: Processing order {order_id}")
        
        try:
            # Simulate processing time
            await asyncio.sleep(random.uniform(1, 2))
            
            # Get order from database
            order = await self.database.get_order(order_id)
            if not order:
                logger.error(f"Order {order_id} not found")
                return
            
            # Validate order
            is_valid, validation_message = await self._validate_order(order)
            
            if is_valid:
                # Update status
                await self.database.update_order(
                    order_id,
                    OrderStatus.PAYMENT_PROCESSING,
                    OrderEvent(
                        order_id=order_id,
                        event_type=EventType.ORDER_VALIDATED,
                        status="success",
                        message=validation_message
                    )
                )
                
                # Publish next event
                await self.event_bus.publish("order_validated", {
                    "order_id": order_id,
                    "event_type": "order_validated",
                    "status": "success",
                    "message": validation_message
                })
            else:
                # Mark as failed
                await self.database.update_order(
                    order_id,
                    OrderStatus.FAILED,
                    OrderEvent(
                        order_id=order_id,
                        event_type=EventType.ORDER_FAILED,
                        status="failed",
                        message=f"Validation failed: {validation_message}"
                    )
                )
                
                await self.event_bus.publish("order_failed", {
                    "order_id": order_id,
                    "event_type": "order_failed",
                    "status": "failed",
                    "message": validation_message
                })
                
        except Exception as e:
            logger.error(f"{self.name} error processing order {order_id}: {e}")
            await self._handle_error(order_id, str(e))
    
    async def _validate_order(self, order):
        """Validate order details"""
        # Check email format
        if "@" not in order.customer_email:
            return False, "Invalid email format"
        
        # Check items
        if not order.items:
            return False, "Order has no items"
        
        # Check quantities
        for item in order.items:
            if item.quantity &lt;= 0:
                return False, f"Invalid quantity for {item.name}"
        
        # Check total
        calculated_total = order.calculate_total()
        if abs(calculated_total - order.total_amount) &gt; 0.01:
            return False, "Total amount mismatch"
        
        return True, "Order validation successful"
    
    async def _handle_error(self, order_id: str, error_message: str):
        """Handle processing errors"""
        await self.database.update_order(
            order_id,
            OrderStatus.FAILED,
            OrderEvent(
                order_id=order_id,
                event_type=EventType.ORDER_FAILED,
                status="error",
                message=f"{self.name} error: {error_message}"
            )
        )
```

```python
# workers/payment_worker.py
import asyncio
import random
import logging
from models.order import OrderStatus
from models.events import OrderEvent, EventType

logger = logging.getLogger(__name__)

class PaymentWorker:
    def __init__(self, event_bus, database):
        self.event_bus = event_bus
        self.database = database
        self.name = "PaymentWorker"
        
    async def start(self):
        """Start worker and subscribe to events"""
        self.event_bus.subscribe("order_validated", self.handle_order_validated)
        logger.info(f"{self.name} started")
        
    async def handle_order_validated(self, event: dict):
        """Handle order validated event"""
        order_id = event.get("order_id")
        logger.info(f"{self.name}: Processing payment for order {order_id}")
        
        try:
            # Simulate payment processing
            await asyncio.sleep(random.uniform(2, 3))
            
            # Simulate 90% success rate
            payment_success = random.random() &lt; 0.9
            
            if payment_success:
                await self.database.update_order(
                    order_id,
                    OrderStatus.INVENTORY_CHECK,
                    OrderEvent(
                        order_id=order_id,
                        event_type=EventType.PAYMENT_PROCESSED,
                        status="success",
                        message="Payment processed successfully",
                        metadata={{"transaction_id": f"TXN-{{order_id[:8]}}"}}
                    )
                )
                
                await self.event_bus.publish("payment_processed", {
                    "order_id": order_id,
                    "event_type": "payment_processed",
                    "status": "success",
                    "transaction_id": f"TXN-{{order_id[:8]}}"
                })
            else:
                await self.database.update_order(
                    order_id,
                    OrderStatus.FAILED,
                    OrderEvent(
                        order_id=order_id,
                        event_type=EventType.ORDER_FAILED,
                        status="failed",
                        message="Payment declined"
                    )
                )
                
                await self.event_bus.publish("order_failed", {
                    "order_id": order_id,
                    "event_type": "payment_failed",
                    "status": "failed",
                    "message": "Payment declined"
                })
                
        except Exception as e:
            logger.error(f"{self.name} error: {e}")
```

```python
# workers/inventory_worker.py
import asyncio
import random
import logging
from models.order import OrderStatus
from models.events import OrderEvent, EventType

logger = logging.getLogger(__name__)

class InventoryWorker:
    def __init__(self, event_bus, database):
        self.event_bus = event_bus
        self.database = database
        self.name = "InventoryWorker"
        # Simulated inventory
        self.inventory = {
            "PROD-001": 100,
            "PROD-002": 50,
            "PROD-003": 25,
            "PROD-004": 0  # Out of stock
        }
        
    async def start(self):
        """Start worker and subscribe to events"""
        self.event_bus.subscribe("payment_processed", self.handle_payment_processed)
        logger.info(f"{self.name} started")
        
    async def handle_payment_processed(self, event: dict):
        """Handle payment processed event"""
        order_id = event.get("order_id")
        logger.info(f"{self.name}: Checking inventory for order {order_id}")
        
        try:
            # Simulate processing
            await asyncio.sleep(random.uniform(1, 2))
            
            # Get order
            order = await self.database.get_order(order_id)
            if not order:
                return
            
            # Check inventory
            available = True
            for item in order.items:
                stock = self.inventory.get(item.product_id, 0)
                if stock &lt; item.quantity:
                    available = False
                    break
            
            if available:
                # Reserve inventory
                for item in order.items:
                    self.inventory[item.product_id] -= item.quantity
                
                await self.database.update_order(
                    order_id,
                    OrderStatus.SHIPPING,
                    OrderEvent(
                        order_id=order_id,
                        event_type=EventType.INVENTORY_RESERVED,
                        status="success",
                        message="Inventory reserved"
                    )
                )
                
                await self.event_bus.publish("inventory_reserved", {
                    "order_id": order_id,
                    "event_type": "inventory_reserved",
                    "status": "success"
                })
            else:
                await self.database.update_order(
                    order_id,
                    OrderStatus.FAILED,
                    OrderEvent(
                        order_id=order_id,
                        event_type=EventType.ORDER_FAILED,
                        status="failed",
                        message="Insufficient inventory"
                    )
                )
                
        except Exception as e:
            logger.error(f"{self.name} error: {e}")
```

### Step 6: Create Main API Application

**Copilot Prompt Suggestion:**
```python
# Create a FastAPI application that:
# - POST /orders endpoint to create orders
# - GET /orders/{order_id} to retrieve order with events
# - WebSocket /ws/orders/{order_id} for real-time updates
# - Initializes database and event bus
# - Starts all workers in background tasks
# - Provides health check endpoint
# - Serves static files for UI
# Include proper error handling and logging setup
```

**Expected Output:**

```python
# main.py
from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
import asyncio
import logging
from typing import Dict
from contextlib import asynccontextmanager

from models.order import Order, OrderStatus
from models.events import OrderEvent, EventType
from event_bus import EventBus
from database import Database
from workers.validation_worker import ValidationWorker
from workers.payment_worker import PaymentWorker
from workers.inventory_worker import InventoryWorker

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Global instances
event_bus = EventBus()
database = Database()
workers = []
websocket_connections: Dict[str, WebSocket] = {}

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle"""
    # Startup
    logger.info("Starting application...")
    
    # Initialize database
    await database.init_db()
    
    # Connect event bus
    await event_bus.connect()
    
    # Set up database callback for WebSocket updates
    database.set_update_callback(notify_order_update)
    
    # Initialize workers
    validation_worker = ValidationWorker(event_bus, database)
    payment_worker = PaymentWorker(event_bus, database)
    inventory_worker = InventoryWorker(event_bus, database)
    
    # Start workers
    await validation_worker.start()
    await payment_worker.start()
    await inventory_worker.start()
    
    # Start event bus listener
    listener_task = asyncio.create_task(event_bus.start_listening())
    
    logger.info("Application started successfully")
    
    yield
    
    # Shutdown
    logger.info("Shutting down application...")
    event_bus.stop()
    listener_task.cancel()
    await event_bus.disconnect()

app = FastAPI(title="Event-Driven Order System", lifespan=lifespan)

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/")
async def home():
    """Serve the main UI"""
    with open("static/index.html", "r") as f:
        return HTMLResponse(content=f.read())

@app.post("/orders", response_model=Order)
async def create_order(order: Order):
    """Create a new order"""
    try:
        # Save to database
        saved_order = await database.create_order(order)
        
        # Create initial event
        event = OrderEvent(
            order_id=order.id,
            event_type=EventType.ORDER_CREATED,
            status="created",
            message="Order created successfully"
        )
        
        # Log event
        await database.update_order(
            order.id,
            OrderStatus.VALIDATING,
            event
        )
        
        # Publish to event bus
        await event_bus.publish("order_created", {
            "order_id": order.id,
            "event_type": "order_created",
            "customer_email": order.customer_email,
            "total_amount": order.total_amount
        })
        
        logger.info(f"Order created: {order.id}")
        return saved_order
        
    except Exception as e:
        logger.error(f"Error creating order: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/orders/{order_id}")
async def get_order(order_id: str):
    """Get order details with events"""
    order = await database.get_order(order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    events = await database.get_order_events(order_id)
    
    return {
        "order": order,
        "events": events
    }

@app.websocket("/ws/orders/{order_id}")
async def websocket_endpoint(websocket: WebSocket, order_id: str):
    """WebSocket for real-time order updates"""
    await websocket.accept()
    websocket_connections[order_id] = websocket
    
    try:
        # Send current order status
        order = await database.get_order(order_id)
        if order:
            await websocket.send_json({
                "type": "status_update",
                "order": order.dict()
            })
        
        # Keep connection alive
        while True:
            await websocket.receive_text()
            
    except WebSocketDisconnect:
        del websocket_connections[order_id]

async def notify_order_update(order: Order):
    """Notify WebSocket clients of order updates"""
    if order.id in websocket_connections:
        ws = websocket_connections[order.id]
        try:
            await ws.send_json({
                "type": "status_update",
                "order": order.dict()
            })
        except Exception as e:
            logger.error(f"Error sending WebSocket update: {e}")

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "event_bus": "connected" if event_bus.redis else "disconnected",
        "active_orders": len(websocket_connections)
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### Step 7: Create UI for Order Rutaing

Create `static/index.html`:
```html
&lt;!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Event-Driven Order System</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100">
    <div class="container mx-auto p-4 max-w-6xl">
        <h1 class="text-3xl font-bold mb-6">Event-Driven Order Processing</h1>
        
        &lt;!-- Create Order Section --&gt;
        <div class="bg-white rounded-lg shadow-md p-6 mb-6">
            <h2 class="text-xl font-semibold mb-4">Create New Order</h2>
            <form id="order-form" class="space-y-4">
                <input type="email" id="email" placeholder="Customer Email" required
                    class="w-full px-4 py-2 border rounded-lg">
                
                <div id="items-container" class="space-y-2">
                    <!-- Items will be added here -->
                </div>
                
                <button type="button" onclick="addItem()"
                    class="px-4 py-2 bg-gray-500 text-white rounded hover:bg-gray-600">
                    Add Item
                </button>
                
                <button type="submit"
                    class="px-6 py-2 bg-blue-500 text-white rounded hover:bg-blue-600">
                    Create Order
                </button>
            </form>
        </div>
        
        &lt;!-- Order Status Section --&gt;
        <div id="order-status" class="hidden bg-white rounded-lg shadow-md p-6">
            <h2 class="text-xl font-semibold mb-4">Order Status</h2>
            <div id="order-info"></div>
            <div id="status-timeline" class="mt-6"></div>
            <div id="events-log" class="mt-6"></div>
        </div>
    </div>
    
    <script src="/static/app.js"></script>
</body>
</html>
```

[Continuar to Partee 3 for JavaScript client and testing...]