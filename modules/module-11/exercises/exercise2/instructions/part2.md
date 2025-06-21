# Exercise 2: Application - Real-World E-Commerce Platform (Part 2) ⭐⭐

## Step 3: Create the API Gateway (Continued)

### 3.2 API Gateway Main Application

Create `api-gateway/app/main.py`:

**Copilot Prompt Suggestion:**
```python
# Create a FastAPI API Gateway that:
# - Routes requests to appropriate microservices
# - Implements request/response logging
# - Adds correlation IDs to requests
# - Handles service discovery
# - Implements circuit breaker pattern
# - Adds authentication middleware
# - Includes rate limiting
# - Aggregates responses from multiple services
```

**Expected Output:**
```python
from fastapi import FastAPI, Request, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import httpx
import logging
from typing import Dict, Any, Optional
from uuid import uuid4
import time
from .service_discovery import ServiceDiscovery
from .middleware.auth import AuthMiddleware
from .middleware.rate_limit import RateLimitMiddleware
from .middleware.logging import LoggingMiddleware
from contextvars import ContextVar

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Context variable for correlation ID
correlation_id_var: ContextVar[str] = ContextVar("correlation_id", default="")

app = FastAPI(
    title="API Gateway",
    description="Central entry point for microservices",
    version="1.0.0"
)

# Service discovery
service_discovery = ServiceDiscovery()

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add custom middleware
app.add_middleware(LoggingMiddleware)
app.add_middleware(RateLimitMiddleware, calls=100, period=60)
app.add_middleware(AuthMiddleware)

@app.on_event("startup")
async def startup_event():
    await service_discovery.start()
    
    # Register known services
    await service_discovery.register_service("user-service", "user-service", 8000)
    await service_discovery.register_service("product-service", "product-service", 8000)
    await service_discovery.register_service("order-service", "order-service", 8000)
    
    logger.info("API Gateway started")

@app.on_event("shutdown")
async def shutdown_event():
    await service_discovery.stop()
    logger.info("API Gateway shutting down")

async def get_service_client(service_name: str) -> httpx.AsyncClient:
    """Get HTTP client for a service"""
    service = await service_discovery.get_service(service_name)
    if not service:
        raise HTTPException(status_code=503, detail=f"Service {service_name} unavailable")
    
    return httpx.AsyncClient(
        base_url=f"http://{service.host}:{service.port}",
        timeout=30.0,
        headers={"X-Correlation-ID": correlation_id_var.get()}
    )

@app.middleware("http")
async def add_correlation_id(request: Request, call_next):
    correlation_id = request.headers.get("X-Correlation-ID", str(uuid4()))
    correlation_id_var.set(correlation_id)
    
    response = await call_next(request)
    response.headers["X-Correlation-ID"] = correlation_id
    return response

# API Routes

@app.get("/health")
async def health_check():
    """Gateway health check with service status"""
    services_status = {}
    
    for service_name in ["user-service", "product-service", "order-service"]:
        service = await service_discovery.get_service(service_name)
        services_status[service_name] = "healthy" if service else "unhealthy"
    
    return {
        "status": "healthy",
        "services": services_status,
        "timestamp": time.time()
    }

# User Service Routes
@app.post("/api/users")
async def create_user(user_data: Dict[str, Any]):
    async with await get_service_client("user-service") as client:
        response = await client.post("/api/users", json=user_data)
        return response.json()

@app.get("/api/users/{user_id}")
async def get_user(user_id: str):
    async with await get_service_client("user-service") as client:
        response = await client.get(f"/api/users/{user_id}")
        if response.status_code == 404:
            raise HTTPException(status_code=404, detail="User not found")
        return response.json()

# Product Service Routes
@app.get("/api/products")
async def list_products(
    category: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    skip: int = 0,
    limit: int = 20
):
    params = {
        "skip": skip,
        "limit": limit
    }
    if category:
        params["category"] = category
    if min_price is not None:
        params["min_price"] = min_price
    if max_price is not None:
        params["max_price"] = max_price
    
    async with await get_service_client("product-service") as client:
        response = await client.get("/api/products", params=params)
        return response.json()

@app.get("/api/products/{product_id}")
async def get_product(product_id: str):
    async with await get_service_client("product-service") as client:
        response = await client.get(f"/api/products/{product_id}")
        if response.status_code == 404:
            raise HTTPException(status_code=404, detail="Product not found")
        return response.json()

# Order Service Routes with Aggregation
@app.post("/api/orders")
async def create_order(order_data: Dict[str, Any]):
    """Create order with validation across services"""
    # Validate user exists
    user_id = order_data.get("user_id")
    async with await get_service_client("user-service") as client:
        user_response = await client.get(f"/api/users/{user_id}")
        if user_response.status_code == 404:
            raise HTTPException(status_code=400, detail="User not found")
    
    # Validate products and calculate total
    validated_items = []
    total_amount = 0
    
    async with await get_service_client("product-service") as client:
        for item in order_data.get("items", []):
            product_response = await client.get(f"/api/products/{item['product_id']}")
            if product_response.status_code == 404:
                raise HTTPException(
                    status_code=400, 
                    detail=f"Product {item['product_id']} not found"
                )
            
            product = product_response.json()
            if product["stock_quantity"] < item["quantity"]:
                raise HTTPException(
                    status_code=400,
                    detail=f"Insufficient stock for {product['name']}"
                )
            
            validated_items.append({
                "product_id": item["product_id"],
                "quantity": item["quantity"],
                "price": product["price"]
            })
            total_amount += product["price"] * item["quantity"]
    
    # Create order
    async with await get_service_client("order-service") as client:
        response = await client.post("/api/orders", json={
            **order_data,
            "items": validated_items,
            "total_amount": total_amount
        })
        return response.json()

@app.get("/api/orders/{order_id}/details")
async def get_order_details(order_id: str):
    """Get order with enriched user and product information"""
    # Get order
    async with await get_service_client("order-service") as client:
        order_response = await client.get(f"/api/orders/{order_id}")
        if order_response.status_code == 404:
            raise HTTPException(status_code=404, detail="Order not found")
        order = order_response.json()
    
    # Enrich with user information
    async with await get_service_client("user-service") as client:
        user_response = await client.get(f"/api/users/{order['user_id']}")
        user = user_response.json() if user_response.status_code == 200 else None
    
    # Enrich with product information
    enriched_items = []
    async with await get_service_client("product-service") as client:
        for item in order["items"]:
            product_response = await client.get(f"/api/products/{item['product_id']}")
            if product_response.status_code == 200:
                product = product_response.json()
                enriched_items.append({
                    **item,
                    "product_name": product["name"],
                    "product_description": product["description"]
                })
            else:
                enriched_items.append(item)
    
    return {
        **order,
        "user": user,
        "items": enriched_items
    }
```

### 3.3 Middleware Components

Create `api-gateway/app/middleware/rate_limit.py`:

**Copilot Prompt Suggestion:**
```python
# Create a rate limiting middleware that:
# - Uses sliding window algorithm
# - Stores counts in Redis
# - Configurable per IP or per user
# - Returns 429 with retry-after header
# - Excludes health check endpoint
```

### Step 4: Create Enhanced Services

#### 4.1 Enhanced Order Service with Events

Update the Order Service to publish events:

**Copilot Prompt Suggestion:**
```python
# Enhance the order service to:
# - Publish OrderCreatedEvent when order is created
# - Publish OrderCancelledEvent when order is cancelled
# - Include event publisher as dependency
# - Add saga pattern for distributed transactions
# - Include compensation logic for failures
```

#### 4.2 Create Notification Service

Create `services/notification-service/app/main.py`:

**Copilot Prompt Suggestion:**
```python
# Create a notification service that:
# - Subscribes to order events
# - Sends email notifications (mock implementation)
# - Sends SMS notifications (mock implementation)
# - Maintains notification history
# - Implements retry logic for failed notifications
# - Uses template system for messages
```

**Expected Output:**
```python
from fastapi import FastAPI
import asyncio
import logging
from datetime import datetime
from typing import Dict, List
import aio_pika
import json
from shared.events.schemas import OrderCreatedEvent, UserRegisteredEvent

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Notification Service",
    description="Handle notifications for various events",
    version="1.0.0"
)

class NotificationService:
    def __init__(self):
        self.amqp_url = "amqp://guest:guest@rabbitmq:5672/"
        self.connection = None
        self.channel = None
        self.notifications_sent: List[Dict] = []
    
    async def start(self):
        """Start consuming events"""
        self.connection = await aio_pika.connect_robust(self.amqp_url)
        self.channel = await self.connection.channel()
        
        # Declare exchange
        exchange = await self.channel.declare_exchange(
            "events",
            aio_pika.ExchangeType.TOPIC,
            durable=True
        )
        
        # Create queue for notifications
        queue = await self.channel.declare_queue(
            "notification_service_queue",
            durable=True
        )
        
        # Bind to relevant events
        await queue.bind(exchange, routing_key="order.created")
        await queue.bind(exchange, routing_key="order.cancelled")
        await queue.bind(exchange, routing_key="user.registered")
        
        # Start consuming
        await queue.consume(self.process_message, no_ack=False)
        
        logger.info("Notification service started consuming events")
    
    async def process_message(self, message: aio_pika.IncomingMessage):
        """Process incoming event messages"""
        async with message.process():
            try:
                # Parse message
                event_data = json.loads(message.body.decode())
                event_type = event_data.get("event_type")
                
                logger.info(f"Received event: {event_type}")
                
                # Route to appropriate handler
                if event_type == "order.created":
                    await self.handle_order_created(OrderCreatedEvent(**event_data))
                elif event_type == "order.cancelled":
                    await self.handle_order_cancelled(event_data)
                elif event_type == "user.registered":
                    await self.handle_user_registered(UserRegisteredEvent(**event_data))
                
            except Exception as e:
                logger.error(f"Error processing message: {e}")
                # In production, might want to dead-letter the message
    
    async def handle_order_created(self, event: OrderCreatedEvent):
        """Send notifications for new orders"""
        # Mock email notification
        email_sent = await self.send_email(
            to="user@example.com",  # In real app, fetch from user service
            subject="Order Confirmation",
            template="order_confirmation",
            data={
                "order_id": str(event.order_id),
                "total_amount": event.total_amount,
                "items": event.items
            }
        )
        
        # Mock SMS notification
        sms_sent = await self.send_sms(
            to="+1234567890",  # In real app, fetch from user service
            message=f"Your order {event.order_id} has been confirmed. Total: ${event.total_amount}"
        )
        
        # Record notification
        self.notifications_sent.append({
            "event_id": str(event.event_id),
            "event_type": event.event_type,
            "timestamp": datetime.utcnow().isoformat(),
            "channels": {
                "email": email_sent,
                "sms": sms_sent
            }
        })
    
    async def send_email(
        self, 
        to: str, 
        subject: str, 
        template: str, 
        data: Dict
    ) -> bool:
        """Mock email sending"""
        logger.info(f"Sending email to {to}: {subject}")
        # Simulate email sending delay
        await asyncio.sleep(0.5)
        # In production, integrate with email service (SendGrid, SES, etc.)
        return True
    
    async def send_sms(self, to: str, message: str) -> bool:
        """Mock SMS sending"""
        logger.info(f"Sending SMS to {to}: {message}")
        # Simulate SMS sending delay
        await asyncio.sleep(0.3)
        # In production, integrate with SMS service (Twilio, SNS, etc.)
        return True

# Global service instance
notification_service = NotificationService()

@app.on_event("startup")
async def startup_event():
    asyncio.create_task(notification_service.start())

@app.on_event("shutdown")
async def shutdown_event():
    if notification_service.connection:
        await notification_service.connection.close()

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "notification-service",
        "notifications_sent": len(notification_service.notifications_sent)
    }

@app.get("/api/notifications/history")
async def get_notification_history():
    return {
        "total": len(notification_service.notifications_sent),
        "notifications": notification_service.notifications_sent[-100:]  # Last 100
    }
```

### Step 5: Docker Compose Configuration

Create `docker-compose.yml`:

**Copilot Prompt Suggestion:**
```yaml
# Create Docker Compose with:
# - All 5 services (user, product, order, notification, inventory)
# - API Gateway
# - RabbitMQ with management plugin
# - Redis with persistence
# - Prometheus for metrics
# - Grafana for visualization
# - Proper health checks and dependencies
# - Volume mounts for data persistence
# - Environment variables from .env file
```

**Expected Output:**
```yaml
version: '3.8'

services:
  # Infrastructure Services
  rabbitmq:
    image: rabbitmq:3.12-management-alpine
    container_name: rabbitmq
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      RABBITMQ_DEFAULT_USER: admin
      RABBITMQ_DEFAULT_PASS: admin123
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
      - ./infrastructure/rabbitmq/definitions.json:/etc/rabbitmq/definitions.json:ro
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - microservices-network

  redis:
    image: redis:7.2-alpine
    container_name: redis
    ports:
      - "6379:6379"
    command: redis-server /usr/local/etc/redis/redis.conf
    volumes:
      - redis_data:/data
      - ./infrastructure/redis/redis.conf:/usr/local/etc/redis/redis.conf:ro
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - microservices-network

  # API Gateway
  api-gateway:
    build:
      context: ./api-gateway
      dockerfile: Dockerfile
    container_name: api-gateway
    ports:
      - "8000:8000"
    environment:
      - SERVICE_NAME=api-gateway
      - LOG_LEVEL=INFO
      - REDIS_URL=redis://redis:6379
    depends_on:
      redis:
        condition: service_healthy
    networks:
      - microservices-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Microservices
  user-service:
    build:
      context: ./services/user-service
      dockerfile: Dockerfile
    container_name: user-service
    expose:
      - "8000"
    environment:
      - SERVICE_NAME=user-service
      - REDIS_URL=redis://redis:6379
      - AMQP_URL=amqp://admin:admin123@rabbitmq:5672/
    depends_on:
      redis:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
    networks:
      - microservices-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  product-service:
    build:
      context: ./services/product-service
      dockerfile: Dockerfile
    container_name: product-service
    expose:
      - "8000"
    environment:
      - SERVICE_NAME=product-service
      - REDIS_URL=redis://redis:6379
      - AMQP_URL=amqp://admin:admin123@rabbitmq:5672/
    depends_on:
      redis:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
    networks:
      - microservices-network

  order-service:
    build:
      context: ./services/order-service
      dockerfile: Dockerfile
    container_name: order-service
    expose:
      - "8000"
    environment:
      - SERVICE_NAME=order-service
      - USER_SERVICE_URL=http://user-service:8000
      - PRODUCT_SERVICE_URL=http://product-service:8000
      - REDIS_URL=redis://redis:6379
      - AMQP_URL=amqp://admin:admin123@rabbitmq:5672/
    depends_on:
      user-service:
        condition: service_healthy
      product-service:
        condition: service_healthy
    networks:
      - microservices-network

  notification-service:
    build:
      context: ./services/notification-service
      dockerfile: Dockerfile
    container_name: notification-service
    expose:
      - "8000"
    environment:
      - SERVICE_NAME=notification-service
      - AMQP_URL=amqp://admin:admin123@rabbitmq:5672/
    depends_on:
      rabbitmq:
        condition: service_healthy
    networks:
      - microservices-network

  inventory-service:
    build:
      context: ./services/inventory-service
      dockerfile: Dockerfile
    container_name: inventory-service
    expose:
      - "8000"
    environment:
      - SERVICE_NAME=inventory-service
      - REDIS_URL=redis://redis:6379
      - AMQP_URL=amqp://admin:admin123@rabbitmq:5672/
    depends_on:
      redis:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
    networks:
      - microservices-network

  # Monitoring
  prometheus:
    image: prom/prometheus:v2.45.0
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./infrastructure/monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    networks:
      - microservices-network

  grafana:
    image: grafana/grafana:10.0.0
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana_data:/var/lib/grafana
      - ./infrastructure/monitoring/grafana/dashboards:/etc/grafana/provisioning/dashboards:ro
      - ./infrastructure/monitoring/grafana/datasources:/etc/grafana/provisioning/datasources:ro
    depends_on:
      - prometheus
    networks:
      - microservices-network

networks:
  microservices-network:
    driver: bridge
    name: microservices-network

volumes:
  rabbitmq_data:
  redis_data:
  prometheus_data:
  grafana_data:
```

### Step 6: Testing the Complete System

Create `test_platform.py`:

**Copilot Prompt Suggestion:**
```python
# Create comprehensive test script that:
# - Tests all endpoints through API Gateway
# - Verifies event publishing and consumption
# - Tests caching behavior
# - Simulates service failures
# - Measures response times
# - Tests concurrent requests
# - Validates data consistency
```

## 📝 Validation Checklist

- [ ] API Gateway routes requests correctly
- [ ] Service discovery detects healthy/unhealthy services
- [ ] Events are published and consumed properly
- [ ] Cache improves response times
- [ ] Rate limiting works correctly
- [ ] Distributed tracing shows request flow
- [ ] Metrics are collected in Prometheus
- [ ] Grafana dashboards show system health
- [ ] Services handle failures gracefully

## 🎯 Success Criteria

You have successfully completed this exercise when:
1. All services communicate through the API Gateway
2. Events flow correctly between services
3. Caching reduces database load
4. System handles service failures gracefully
5. Monitoring shows system health
6. Load tests pass without errors

## 📚 Additional Challenges

1. **Add Authentication**: Implement JWT-based authentication
2. **Add GraphQL**: Create a GraphQL endpoint in the API Gateway
3. **Add WebSocket**: Implement real-time order updates
4. **Add Distributed Tracing**: Integrate OpenTelemetry
5. **Add Chaos Engineering**: Implement failure injection

## 🎉 Congratulations!

You've built a production-ready microservices platform! You've implemented:
- API Gateway pattern for unified access
- Event-driven architecture for loose coupling
- Caching for performance
- Service discovery for resilience
- Comprehensive monitoring

Proceed to Exercise 3 for the ultimate production-ready challenge!