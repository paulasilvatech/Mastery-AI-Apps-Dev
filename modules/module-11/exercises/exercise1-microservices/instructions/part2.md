# Exercise 1: Foundation - Service Decomposition (Part 2) ⭐

## Step 4: Create the Order Service (Continued)

### 4.1 Create Service Clients

The Order Service needs to communicate with User and Product services.

Create `app/clients/user_client.py`:

**Copilot Prompt Suggestion:**
```python
# Create an async HTTP client for the User Service that:
# - Uses httpx for async requests
# - Has base URL configurable via environment variable
# - Includes get_user(user_id) method
# - Has proper error handling and returns None if user not found
# - Includes retry logic with exponential backoff
```

**Expected Output:**
```python
import httpx
import os
from typing import Optional, Dict, Any
from uuid import UUID
import asyncio
import logging

logger = logging.getLogger(__name__)

class UserServiceClient:
    def __init__(self):
        self.base_url = os.getenv("USER_SERVICE_URL", "http://user-service:8000")
        self.client = httpx.AsyncClient(timeout=10.0)
    
    async def get_user(self, user_id: UUID) -> Optional[Dict[str, Any]]:
        """Get user by ID from User Service"""
        max_retries = 3
        retry_delay = 1
        
        for attempt in range(max_retries):
            try:
                response = await self.client.get(f"{self.base_url}/api/users/{user_id}")
                if response.status_code == 404:
                    return None
                response.raise_for_status()
                return response.json()
            except httpx.RequestError as e:
                logger.warning(f"Request to User Service failed (attempt {attempt + 1}): {e}")
                if attempt < max_retries - 1:
                    await asyncio.sleep(retry_delay)
                    retry_delay *= 2
                else:
                    logger.error(f"Failed to contact User Service after {max_retries} attempts")
                    raise
    
    async def close(self):
        await self.client.aclose()
```

Create `app/clients/product_client.py`:

**Copilot Prompt Suggestion:**
```python
# Create an async HTTP client for the Product Service that:
# - Similar structure to UserServiceClient
# - Has get_product(product_id) method
# - Has check_stock(product_id, quantity) method that returns boolean
# - Has update_stock(product_id, quantity_change) method
```

**Expected Output:**
```python
import httpx
import os
from typing import Optional, Dict, Any
from uuid import UUID
import asyncio
import logging

logger = logging.getLogger(__name__)

class ProductServiceClient:
    def __init__(self):
        self.base_url = os.getenv("PRODUCT_SERVICE_URL", "http://product-service:8000")
        self.client = httpx.AsyncClient(timeout=10.0)
    
    async def get_product(self, product_id: UUID) -> Optional[Dict[str, Any]]:
        """Get product by ID from Product Service"""
        max_retries = 3
        retry_delay = 1
        
        for attempt in range(max_retries):
            try:
                response = await self.client.get(f"{self.base_url}/api/products/{product_id}")
                if response.status_code == 404:
                    return None
                response.raise_for_status()
                return response.json()
            except httpx.RequestError as e:
                logger.warning(f"Request to Product Service failed (attempt {attempt + 1}): {e}")
                if attempt < max_retries - 1:
                    await asyncio.sleep(retry_delay)
                    retry_delay *= 2
                else:
                    logger.error(f"Failed to contact Product Service after {max_retries} attempts")
                    raise
    
    async def check_stock(self, product_id: UUID, quantity: int) -> bool:
        """Check if product has sufficient stock"""
        product = await self.get_product(product_id)
        if not product:
            return False
        return product.get("stock_quantity", 0) >= quantity
    
    async def update_stock(self, product_id: UUID, quantity_change: int) -> bool:
        """Update product stock (negative for decrease)"""
        try:
            response = await self.client.patch(
                f"{self.base_url}/api/products/{product_id}/stock",
                json={"quantity_change": quantity_change}
            )
            response.raise_for_status()
            return True
        except httpx.RequestError as e:
            logger.error(f"Failed to update stock: {e}")
            return False
    
    async def close(self):
        await self.client.aclose()
```

### 4.2 Create Order Models

Create `app/models.py`:

**Copilot Prompt Suggestion:**
```python
# Create Pydantic models for order service:
# - OrderItem with product_id, quantity, price
# - OrderCreate with user_id and list of items (product_id, quantity)
# - Order with id, user_id, items, total_amount, status (pending/completed/cancelled), 
#   created_at, updated_at
# - Include order status enum
# - Add validation for positive quantities
```

**Expected Output:**
```python
from pydantic import BaseModel, Field, validator
from datetime import datetime
from typing import List, Optional
from uuid import UUID, uuid4
from enum import Enum
from decimal import Decimal

class OrderStatus(str, Enum):
    PENDING = "pending"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class OrderItemBase(BaseModel):
    product_id: UUID
    quantity: int = Field(..., gt=0)

class OrderItemCreate(OrderItemBase):
    pass

class OrderItem(OrderItemBase):
    price: Decimal = Field(..., gt=0)
    subtotal: Decimal = Field(default=0)
    
    @validator('subtotal', always=True)
    def calculate_subtotal(cls, v, values):
        return values.get('price', 0) * values.get('quantity', 0)

class OrderCreate(BaseModel):
    user_id: UUID
    items: List[OrderItemCreate] = Field(..., min_items=1)

class Order(BaseModel):
    id: UUID = Field(default_factory=uuid4)
    user_id: UUID
    items: List[OrderItem]
    total_amount: Decimal = Field(default=0)
    status: OrderStatus = OrderStatus.PENDING
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    @validator('total_amount', always=True)
    def calculate_total(cls, v, values):
        items = values.get('items', [])
        return sum(item.subtotal for item in items)
    
    class Config:
        from_attributes = True
```

### 4.3 Create Order Database

Create `app/database.py`:

**Copilot Prompt Suggestion:**
```python
# Create in-memory database for orders with:
# - Store orders by ID
# - Create order (should validate user and products exist)
# - Get order by ID
# - List orders with optional user_id filter
# - Update order status
# - Thread-safe with asyncio locks
```

### 4.4 Create Order Routes

Create `app/routers/orders.py`:

**Copilot Prompt Suggestion:**
```python
# Create FastAPI router for order operations:
# - POST /orders - create order (validate user exists, check product stock)
# - GET /orders - list orders with optional user_id filter
# - GET /orders/{order_id} - get specific order
# - PUT /orders/{order_id}/status - update order status
# Include dependency injection for service clients
```

**Expected Output:**
```python
from fastapi import APIRouter, HTTPException, Query, Depends
from typing import List, Optional
from uuid import UUID
from ..models import Order, OrderCreate, OrderStatus, OrderItem
from ..database import db
from ..clients.user_client import UserServiceClient
from ..clients.product_client import ProductServiceClient
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/orders", tags=["orders"])

# Dependency injection for service clients
async def get_user_client():
    client = UserServiceClient()
    try:
        yield client
    finally:
        await client.close()

async def get_product_client():
    client = ProductServiceClient()
    try:
        yield client
    finally:
        await client.close()

@router.post("/", response_model=Order, status_code=201)
async def create_order(
    order_data: OrderCreate,
    user_client: UserServiceClient = Depends(get_user_client),
    product_client: ProductServiceClient = Depends(get_product_client)
):
    # Validate user exists
    user = await user_client.get_user(order_data.user_id)
    if not user:
        raise HTTPException(status_code=400, detail="User not found")
    
    # Validate products and check stock
    order_items = []
    for item in order_data.items:
        product = await product_client.get_product(item.product_id)
        if not product:
            raise HTTPException(
                status_code=400, 
                detail=f"Product {item.product_id} not found"
            )
        
        if not await product_client.check_stock(item.product_id, item.quantity):
            raise HTTPException(
                status_code=400,
                detail=f"Insufficient stock for product {product['name']}"
            )
        
        order_items.append(OrderItem(
            product_id=item.product_id,
            quantity=item.quantity,
            price=product['price']
        ))
    
    # Create order
    order = await db.create_order(order_data.user_id, order_items)
    
    # Update stock for each product
    for item in order_items:
        await product_client.update_stock(item.product_id, -item.quantity)
    
    return order

@router.get("/", response_model=List[Order])
async def list_orders(
    user_id: Optional[UUID] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000)
):
    return await db.list_orders(user_id=user_id, skip=skip, limit=limit)

@router.get("/{order_id}", response_model=Order)
async def get_order(order_id: UUID):
    order = await db.get_order(order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return order

@router.put("/{order_id}/status")
async def update_order_status(order_id: UUID, status: OrderStatus):
    order = await db.update_order_status(order_id, status)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return order
```

### 4.5 Create Main Application

Create `app/main.py` for Order Service (similar to User Service but on port 8003).

## Step 5: Create Docker Compose Configuration

Create `docker-compose.yml` in the root of exercise1-foundation:

**Copilot Prompt Suggestion:**
```yaml
# Create a Docker Compose file that:
# - Defines three services: user-service, product-service, order-service
# - Each service builds from its directory
# - Exposes ports 8001, 8002, 8003 respectively
# - Sets environment variables for service URLs
# - Creates a custom network
# - Includes health checks
# - Sets restart policy
```

**Expected Output:**
```yaml
version: '3.8'

services:
  user-service:
    build:
      context: ./user-service
      dockerfile: Dockerfile
    container_name: user-service
    ports:
      - "8001:8000"
    environment:
      - SERVICE_NAME=user-service
      - LOG_LEVEL=INFO
    networks:
      - microservices-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    restart: unless-stopped

  product-service:
    build:
      context: ./product-service
      dockerfile: Dockerfile
    container_name: product-service
    ports:
      - "8002:8000"
    environment:
      - SERVICE_NAME=product-service
      - LOG_LEVEL=INFO
    networks:
      - microservices-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    restart: unless-stopped

  order-service:
    build:
      context: ./order-service
      dockerfile: Dockerfile
    container_name: order-service
    ports:
      - "8003:8000"
    environment:
      - SERVICE_NAME=order-service
      - USER_SERVICE_URL=http://user-service:8000
      - PRODUCT_SERVICE_URL=http://product-service:8000
      - LOG_LEVEL=INFO
    networks:
      - microservices-network
    depends_on:
      user-service:
        condition: service_healthy
      product-service:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    restart: unless-stopped

networks:
  microservices-network:
    driver: bridge
    name: microservices-network
```

## Step 6: Build and Run the Services

### 6.1 Build All Services

```bash
docker compose build
```

### 6.2 Start All Services

```bash
docker compose up -d
```

### 6.3 Verify Services are Running

```bash
# Check service health
curl http://localhost:8001/health
curl http://localhost:8002/health
curl http://localhost:8003/health

# Check logs
docker compose logs -f
```

## Step 7: Test the Microservices

### 7.1 Create Test Script

Create `test_services.py`:

**Copilot Prompt Suggestion:**
```python
# Create a test script that:
# - Creates a user via User Service
# - Creates products via Product Service
# - Creates an order via Order Service
# - Verifies the order includes correct user and product information
# - Uses httpx for async requests
# - Includes colored output for success/failure
```

### 7.2 Run Tests

```bash
python test_services.py
```

## 📝 Validation Checklist

- [ ] All three services start successfully
- [ ] Health endpoints return healthy status
- [ ] User can be created and retrieved
- [ ] Products can be created and retrieved
- [ ] Order can be created with valid user and products
- [ ] Order service correctly validates user existence
- [ ] Order service correctly checks product stock
- [ ] Services communicate successfully

## 🎯 Success Criteria

You have successfully completed this exercise when:
1. All three microservices are running independently
2. Services can communicate with each other
3. Order creation validates against other services
4. All health checks pass
5. The test script runs successfully

## 📚 Additional Challenges

1. **Add Pagination**: Implement proper pagination for all list endpoints
2. **Add Filtering**: Add query parameters for filtering products by category
3. **Add Search**: Implement search functionality for users and products
4. **Add Caching**: Implement Redis caching for frequently accessed data
5. **Add Metrics**: Add Prometheus metrics to each service

## 🔧 Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   # Find process using port
   lsof -i :8001
   # Kill process or change port in docker-compose.yml
   ```

2. **Service Can't Connect to Other Services**
   - Ensure services are on the same network
   - Check environment variables for service URLs
   - Verify service names in docker-compose.yml

3. **Build Failures**
   - Check Docker daemon is running
   - Verify Dockerfile syntax
   - Ensure all required files are present

## 🎉 Congratulations!

You've successfully decomposed a monolithic application into microservices! You've learned:
- How to identify service boundaries
- How to implement inter-service communication
- How to handle distributed system challenges
- How to containerize and orchestrate services

Proceed to Exercise 2 to build a more complex real-world e-commerce platform!
---

## 🔗 Navigation

[← Previous: Part 1](part1.md) | [🏠 Module Home](../../../../README.md) | [Next Exercise →](../../exercise2-monitoring/README.md)

## 📚 Quick Links

- [Prerequisites](../../../../prerequisites.md)
- [Module Resources](../../../../README.md#resources)
- [Troubleshooting Guide](../../../../troubleshooting.md)
- [Solution Code](../solution/)
