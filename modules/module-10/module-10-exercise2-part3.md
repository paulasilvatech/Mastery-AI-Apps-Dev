# Exercise 2: Event-Driven Order Processing System (Part 3)

### Step 8: Create JavaScript Client

Create `static/app.js`:

**Copilot Prompt Suggestion:**
```javascript
// Create an order management client that:
// - Handles form submission to create orders
// - Connects via WebSocket for real-time updates
// - Displays order status with visual timeline
// - Shows event history
// - Updates UI based on status changes
// - Handles errors gracefully
// Include sample product data and status animations
```

**Expected Output:**
```javascript
// static/app.js
let currentOrderId = null;
let ws = null;

// Sample products
const products = [
    { id: "PROD-001", name: "Laptop", price: 999.99 },
    { id: "PROD-002", name: "Mouse", price: 29.99 },
    { id: "PROD-003", name: "Keyboard", price: 79.99 },
    { id: "PROD-004", name: "Monitor", price: 299.99 }
];

// Status flow
const statusFlow = [
    { status: "pending", label: "Order Placed", icon: "📝" },
    { status: "validating", label: "Validating", icon: "🔍" },
    { status: "payment_processing", label: "Processing Payment", icon: "💳" },
    { status: "inventory_check", label: "Checking Inventory", icon: "📦" },
    { status: "shipping", label: "Shipping", icon: "🚚" },
    { status: "completed", label: "Completed", icon: "✅" },
    { status: "failed", label: "Failed", icon: "❌" }
];

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    document.getElementById('order-form').addEventListener('submit', createOrder);
    addItem(); // Add first item by default
});

// Add item to order form
function addItem() {
    const container = document.getElementById('items-container');
    const itemDiv = document.createElement('div');
    itemDiv.className = 'flex gap-2 items-center';
    
    // Product select
    const select = document.createElement('select');
    select.className = 'flex-1 px-4 py-2 border rounded-lg';
    select.innerHTML = '<option value="">Select Product</option>';
    products.forEach(p => {
        select.innerHTML += `<option value="${p.id}" data-price="${p.price}">${p.name} - $${p.price}</option>`;
    });
    
    // Quantity input
    const quantity = document.createElement('input');
    quantity.type = 'number';
    quantity.min = '1';
    quantity.value = '1';
    quantity.placeholder = 'Qty';
    quantity.className = 'w-20 px-4 py-2 border rounded-lg';
    
    // Remove button
    const removeBtn = document.createElement('button');
    removeBtn.type = 'button';
    removeBtn.textContent = 'Remove';
    removeBtn.className = 'px-3 py-2 bg-red-500 text-white rounded hover:bg-red-600';
    removeBtn.onclick = () => itemDiv.remove();
    
    itemDiv.appendChild(select);
    itemDiv.appendChild(quantity);
    itemDiv.appendChild(removeBtn);
    container.appendChild(itemDiv);
}

// Create order
async function createOrder(e) {
    e.preventDefault();
    
    const email = document.getElementById('email').value;
    const itemDivs = document.querySelectorAll('#items-container > div');
    const items = [];
    let total = 0;
    
    // Collect items
    itemDivs.forEach(div => {
        const select = div.querySelector('select');
        const quantity = div.querySelector('input[type="number"]');
        
        if (select.value) {
            const option = select.options[select.selectedIndex];
            const price = parseFloat(option.dataset.price);
            const qty = parseInt(quantity.value);
            const product = products.find(p => p.id === select.value);
            
            items.push({
                product_id: select.value,
                name: product.name,
                quantity: qty,
                price: price
            });
            
            total += price * qty;
        }
    });
    
    if (items.length === 0) {
        alert('Please add at least one item');
        return;
    }
    
    // Create order object
    const order = {
        customer_email: email,
        items: items,
        total_amount: total
    };
    
    try {
        // Send order
        const response = await fetch('/orders', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(order)
        });
        
        if (!response.ok) throw new Error('Failed to create order');
        
        const createdOrder = await response.json();
        currentOrderId = createdOrder.id;
        
        // Show order status section
        document.getElementById('order-status').classList.remove('hidden');
        
        // Connect WebSocket for updates
        connectWebSocket(currentOrderId);
        
        // Update UI
        updateOrderInfo(createdOrder);
        
        // Reset form
        document.getElementById('order-form').reset();
        document.getElementById('items-container').innerHTML = '';
        addItem();
        
    } catch (error) {
        alert('Error creating order: ' + error.message);
    }
}

// Connect WebSocket for real-time updates
function connectWebSocket(orderId) {
    if (ws) ws.close();
    
    ws = new WebSocket(`ws://localhost:8000/ws/orders/${orderId}`);
    
    ws.onopen = () => {
        console.log('WebSocket connected for order:', orderId);
    };
    
    ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        if (data.type === 'status_update') {
            updateOrderInfo(data.order);
            updateStatusTimeline(data.order.status);
            loadEventHistory(orderId);
        }
    };
    
    ws.onerror = (error) => {
        console.error('WebSocket error:', error);
    };
    
    ws.onclose = () => {
        console.log('WebSocket disconnected');
    };
}

// Update order information display
function updateOrderInfo(order) {
    const infoDiv = document.getElementById('order-info');
    const statusClass = order.status === 'failed' ? 'text-red-600' : 
                       order.status === 'completed' ? 'text-green-600' : 'text-blue-600';
    
    infoDiv.innerHTML = `
        <div class="grid grid-cols-2 gap-4">
            <div>
                <p class="text-gray-600">Order ID:</p>
                <p class="font-mono">${order.id}</p>
            </div>
            <div>
                <p class="text-gray-600">Status:</p>
                <p class="font-semibold ${statusClass}">${order.status.toUpperCase()}</p>
            </div>
            <div>
                <p class="text-gray-600">Customer:</p>
                <p>${order.customer_email}</p>
            </div>
            <div>
                <p class="text-gray-600">Total:</p>
                <p class="font-semibold">$${order.total_amount.toFixed(2)}</p>
            </div>
        </div>
    `;
}

// Update status timeline
function updateStatusTimeline(currentStatus) {
    const timelineDiv = document.getElementById('status-timeline');
    timelineDiv.innerHTML = '<h3 class="font-semibold mb-4">Processing Timeline</h3>';
    
    const timeline = document.createElement('div');
    timeline.className = 'flex items-center justify-between';
    
    let reachedCurrent = false;
    let isFailed = currentStatus === 'failed';
    
    statusFlow.forEach((step, index) => {
        if (step.status === 'failed' && !isFailed) return; // Skip failed unless order failed
        
        const stepDiv = document.createElement('div');
        stepDiv.className = 'flex flex-col items-center';
        
        // Icon
        const iconDiv = document.createElement('div');
        iconDiv.className = `w-12 h-12 rounded-full flex items-center justify-center text-xl ${
            step.status === currentStatus ? 'bg-blue-500 text-white animate-pulse' :
            !reachedCurrent && !isFailed ? 'bg-green-500 text-white' :
            'bg-gray-300 text-gray-600'
        }`;
        iconDiv.textContent = step.icon;
        
        // Label
        const labelDiv = document.createElement('div');
        labelDiv.className = 'text-xs mt-2 text-center';
        labelDiv.textContent = step.label;
        
        stepDiv.appendChild(iconDiv);
        stepDiv.appendChild(labelDiv);
        timeline.appendChild(stepDiv);
        
        // Line between steps (except last)
        if (index < statusFlow.length - 2 || (isFailed && index < statusFlow.length - 1)) {
            const line = document.createElement('div');
            line.className = `flex-1 h-1 ${
                !reachedCurrent && !isFailed ? 'bg-green-500' : 'bg-gray-300'
            }`;
            timeline.appendChild(line);
        }
        
        if (step.status === currentStatus) reachedCurrent = true;
    });
    
    timelineDiv.appendChild(timeline);
}

// Load event history
async function loadEventHistory(orderId) {
    try {
        const response = await fetch(`/orders/${orderId}`);
        const data = await response.json();
        
        const eventsDiv = document.getElementById('events-log');
        eventsDiv.innerHTML = '<h3 class="font-semibold mb-4">Event History</h3>';
        
        const eventsList = document.createElement('div');
        eventsList.className = 'space-y-2 max-h-64 overflow-y-auto';
        
        data.events.reverse().forEach(event => {
            const eventDiv = document.createElement('div');
            eventDiv.className = 'border-l-4 pl-4 py-2 ' + (
                event.status === 'failed' ? 'border-red-500 bg-red-50' :
                event.status === 'success' ? 'border-green-500 bg-green-50' :
                'border-blue-500 bg-blue-50'
            );
            
            const time = new Date(event.timestamp).toLocaleTimeString();
            eventDiv.innerHTML = `
                <div class="flex justify-between">
                    <span class="font-semibold">${event.event_type}</span>
                    <span class="text-sm text-gray-600">${time}</span>
                </div>
                <p class="text-sm text-gray-700">${event.message}</p>
            `;
            
            eventsList.appendChild(eventDiv);
        });
        
        eventsDiv.appendChild(eventsList);
        
    } catch (error) {
        console.error('Error loading events:', error);
    }
}
```

### Step 9: Testing the System

1. **Start Redis:**
```bash
docker run -d -p 6379:6379 redis:alpine
```

2. **Start the application:**
```bash
python main.py
```

3. **Test order flow:**
   - Open http://localhost:8000
   - Create an order with multiple items
   - Watch real-time status updates
   - Create multiple orders simultaneously
   - Test with "PROD-004" to see inventory failure

### Step 10: Create Integration Tests

Create `test_event_system.py`:

```python
# test_event_system.py
import pytest
import asyncio
import json
from httpx import AsyncClient
from main import app
from models.order import Order, OrderStatus

@pytest.fixture
async def client():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

@pytest.mark.asyncio
async def test_create_order(client):
    """Test order creation"""
    order_data = {
        "customer_email": "test@example.com",
        "items": [
            {
                "product_id": "PROD-001",
                "name": "Test Product",
                "quantity": 2,
                "price": 10.00
            }
        ],
        "total_amount": 20.00
    }
    
    response = await client.post("/orders", json=order_data)
    assert response.status_code == 200
    
    order = response.json()
    assert order["customer_email"] == "test@example.com"
    assert order["status"] == "pending"
    assert "id" in order

@pytest.mark.asyncio
async def test_order_processing_flow(client):
    """Test complete order processing flow"""
    # Create order
    order_data = {
        "customer_email": "flow@test.com",
        "items": [
            {
                "product_id": "PROD-002",
                "name": "Flow Test",
                "quantity": 1,
                "price": 50.00
            }
        ],
        "total_amount": 50.00
    }
    
    response = await client.post("/orders", json=order_data)
    order = response.json()
    order_id = order["id"]
    
    # Wait for processing
    await asyncio.sleep(10)
    
    # Check final status
    response = await client.get(f"/orders/{order_id}")
    data = response.json()
    
    # Order should have progressed through states
    assert len(data["events"]) > 1
    assert data["order"]["status"] in ["shipping", "completed", "failed"]

@pytest.mark.asyncio
async def test_websocket_updates(client):
    """Test WebSocket real-time updates"""
    # Create order first
    order_data = {
        "customer_email": "ws@test.com",
        "items": [{"product_id": "PROD-001", "name": "WS Test", "quantity": 1, "price": 10.00}],
        "total_amount": 10.00
    }
    
    response = await client.post("/orders", json=order_data)
    order = response.json()
    
    # Connect WebSocket
    async with client.websocket_connect(f"/ws/orders/{order['id']}") as websocket:
        # Should receive initial status
        data = await websocket.receive_json()
        assert data["type"] == "status_update"
        assert data["order"]["id"] == order["id"]
```

## 🏆 Success Criteria

- ✅ Orders flow through multiple processing stages
- ✅ Each worker processes events independently
- ✅ Real-time updates via WebSocket
- ✅ System handles failures gracefully
- ✅ Events are logged for audit trail
- ✅ Multiple orders process concurrently

## 🔧 Troubleshooting

### Redis Connection Issues
```bash
# Check Redis is running
docker ps | grep redis

# Test Redis connection
redis-cli ping
```

### Worker Not Processing
- Check worker subscriptions in logs
- Verify event channel names match
- Ensure event bus is listening

### WebSocket Not Updating
- Check browser console for errors
- Verify order ID matches
- Check database callback registration

## 🚀 Enhancement Challenges

1. **Add Saga Pattern:**
   - Implement compensating transactions
   - Handle partial failures

2. **Add Dead Letter Queue:**
   - Store failed events
   - Implement retry mechanism

3. **Add Monitoring Dashboard:**
   - Show worker health
   - Display processing metrics

4. **Implement Event Replay:**
   - Rebuild state from events
   - Time-travel debugging

## 📊 Performance Optimization

- Use Redis Streams instead of Pub/Sub for persistence
- Implement worker pools for scaling
- Add circuit breakers for external services
- Use connection pooling for database

## 🎯 Key Takeaways

1. Event-driven architecture enables loose coupling
2. Asynchronous processing improves scalability
3. Event sourcing provides audit trail
4. Workers can scale independently
5. Real-time updates enhance user experience

---

Excellent work! You've built a production-ready event-driven system. Ready for [Exercise 3: Streaming Analytics Platform](../exercise3-streaming-platform/README.md)?
