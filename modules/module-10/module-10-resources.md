# Module 10: Additional Resources

## 📚 Reference Implementations

### 1. Production WebSocket Server Template
```python
# production_websocket_server.py
"""
Production-ready WebSocket server with all best practices
"""
import asyncio
import logging
import signal
import json
import jwt
import time
from typing import Dict, Set, Optional
from dataclasses import dataclass
from datetime import datetime, timedelta

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import uvicorn

logger = logging.getLogger(__name__)

@dataclass
class Client:
    id: str
    websocket: WebSocket
    subscriptions: Set[str]
    rate_limiter: 'RateLimiter'
    connected_at: datetime
    last_activity: datetime

class RateLimiter:
    def __init__(self, rate: int = 100, window: int = 60):
        self.rate = rate
        self.window = window
        self.requests = []
    
    def is_allowed(self) -> bool:
        now = time.time()
        # Remove old requests
        self.requests = [req for req in self.requests if now - req < self.window]
        
        if len(self.requests) < self.rate:
            self.requests.append(now)
            return True
        return False

class WebSocketServer:
    def __init__(self, app: FastAPI, secret_key: str):
        self.app = app
        self.secret_key = secret_key
        self.clients: Dict[str, Client] = {}
        self.topics: Dict[str, Set[str]] = {}  # topic -> client_ids
        
        # Graceful shutdown
        signal.signal(signal.SIGTERM, self._signal_handler)
        signal.signal(signal.SIGINT, self._signal_handler)
        self.shutdown_event = asyncio.Event()
        
    def _signal_handler(self, signum, frame):
        logger.info(f"Received signal {signum}, starting graceful shutdown...")
        self.shutdown_event.set()
    
    async def authenticate(self, token: str) -> Optional[str]:
        """Authenticate WebSocket connection"""
        try:
            payload = jwt.decode(token, self.secret_key, algorithms=["HS256"])
            return payload.get("user_id")
        except jwt.InvalidTokenError:
            return None
    
    async def connect(self, websocket: WebSocket, client_id: str):
        """Handle new WebSocket connection"""
        await websocket.accept()
        
        client = Client(
            id=client_id,
            websocket=websocket,
            subscriptions=set(),
            rate_limiter=RateLimiter(),
            connected_at=datetime.utcnow(),
            last_activity=datetime.utcnow()
        )
        
        self.clients[client_id] = client
        
        # Send welcome message
        await self.send_to_client(client_id, {
            "type": "connected",
            "client_id": client_id,
            "timestamp": datetime.utcnow().isoformat()
        })
        
        # Start heartbeat
        asyncio.create_task(self._heartbeat(client_id))
        
        logger.info(f"Client {client_id} connected")
    
    async def disconnect(self, client_id: str):
        """Handle WebSocket disconnection"""
        if client_id not in self.clients:
            return
            
        client = self.clients[client_id]
        
        # Unsubscribe from all topics
        for topic in client.subscriptions:
            if topic in self.topics:
                self.topics[topic].discard(client_id)
                if not self.topics[topic]:
                    del self.topics[topic]
        
        # Remove client
        del self.clients[client_id]
        
        logger.info(f"Client {client_id} disconnected")
    
    async def handle_message(self, client_id: str, message: dict):
        """Process incoming WebSocket message"""
        client = self.clients.get(client_id)
        if not client:
            return
        
        # Rate limiting
        if not client.rate_limiter.is_allowed():
            await self.send_to_client(client_id, {
                "type": "error",
                "code": "RATE_LIMITED",
                "message": "Too many requests"
            })
            return
        
        # Update activity
        client.last_activity = datetime.utcnow()
        
        # Handle message types
        msg_type = message.get("type")
        
        if msg_type == "subscribe":
            await self._handle_subscribe(client_id, message.get("topics", []))
        elif msg_type == "unsubscribe":
            await self._handle_unsubscribe(client_id, message.get("topics", []))
        elif msg_type == "publish":
            await self._handle_publish(client_id, message.get("topic"), message.get("data"))
        elif msg_type == "ping":
            await self.send_to_client(client_id, {"type": "pong"})
        else:
            await self.send_to_client(client_id, {
                "type": "error",
                "code": "INVALID_MESSAGE_TYPE",
                "message": f"Unknown message type: {msg_type}"
            })
    
    async def _handle_subscribe(self, client_id: str, topics: list):
        """Handle subscription request"""
        client = self.clients[client_id]
        
        for topic in topics:
            if topic not in self.topics:
                self.topics[topic] = set()
            
            self.topics[topic].add(client_id)
            client.subscriptions.add(topic)
        
        await self.send_to_client(client_id, {
            "type": "subscribed",
            "topics": list(client.subscriptions)
        })
    
    async def _handle_unsubscribe(self, client_id: str, topics: list):
        """Handle unsubscription request"""
        client = self.clients[client_id]
        
        for topic in topics:
            if topic in self.topics:
                self.topics[topic].discard(client_id)
                if not self.topics[topic]:
                    del self.topics[topic]
            
            client.subscriptions.discard(topic)
        
        await self.send_to_client(client_id, {
            "type": "unsubscribed",
            "topics": list(client.subscriptions)
        })
    
    async def _handle_publish(self, client_id: str, topic: str, data: any):
        """Handle publish request"""
        if topic not in self.topics:
            return
        
        message = {
            "type": "message",
            "topic": topic,
            "data": data,
            "from": client_id,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # Broadcast to all subscribers
        tasks = []
        for subscriber_id in self.topics[topic]:
            if subscriber_id != client_id:  # Don't echo back
                tasks.append(self.send_to_client(subscriber_id, message))
        
        await asyncio.gather(*tasks, return_exceptions=True)
    
    async def send_to_client(self, client_id: str, message: dict):
        """Send message to specific client"""
        client = self.clients.get(client_id)
        if not client:
            return
        
        try:
            await client.websocket.send_json(message)
        except Exception as e:
            logger.error(f"Error sending to client {client_id}: {e}")
            await self.disconnect(client_id)
    
    async def broadcast(self, topic: str, message: dict):
        """Broadcast message to all subscribers of a topic"""
        if topic not in self.topics:
            return
        
        tasks = []
        for client_id in self.topics[topic]:
            tasks.append(self.send_to_client(client_id, message))
        
        await asyncio.gather(*tasks, return_exceptions=True)
    
    async def _heartbeat(self, client_id: str):
        """Send periodic heartbeat to client"""
        while client_id in self.clients:
            try:
                await self.send_to_client(client_id, {"type": "heartbeat"})
                await asyncio.sleep(30)
            except:
                break
    
    async def cleanup_inactive_clients(self):
        """Remove inactive clients"""
        while not self.shutdown_event.is_set():
            try:
                now = datetime.utcnow()
                inactive_threshold = timedelta(minutes=5)
                
                to_remove = []
                for client_id, client in self.clients.items():
                    if now - client.last_activity > inactive_threshold:
                        to_remove.append(client_id)
                
                for client_id in to_remove:
                    logger.info(f"Removing inactive client {client_id}")
                    await self.disconnect(client_id)
                
                await asyncio.sleep(60)  # Check every minute
            except:
                pass

# Create FastAPI app
app = FastAPI(title="Production WebSocket Server")
security = HTTPBearer()

# Initialize server
ws_server = WebSocketServer(app, secret_key="your-secret-key")

@app.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: str = None
):
    """WebSocket endpoint with authentication"""
    if not token:
        await websocket.close(code=1008, reason="Missing authentication")
        return
    
    client_id = await ws_server.authenticate(token)
    if not client_id:
        await websocket.close(code=1008, reason="Invalid authentication")
        return
    
    await ws_server.connect(websocket, client_id)
    
    try:
        while True:
            data = await websocket.receive_json()
            await ws_server.handle_message(client_id, data)
    except WebSocketDisconnect:
        await ws_server.disconnect(client_id)

@app.on_event("startup")
async def startup_event():
    """Start background tasks"""
    asyncio.create_task(ws_server.cleanup_inactive_clients())

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "clients": len(ws_server.clients),
        "topics": len(ws_server.topics)
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### 2. Event Sourcing Implementation
```python
# event_sourcing.py
"""
Complete event sourcing implementation
"""
from typing import List, Dict, Any, Optional
from datetime import datetime
from dataclasses import dataclass, asdict
import json
import asyncio
from abc import ABC, abstractmethod

@dataclass
class Event:
    aggregate_id: str
    event_type: str
    event_data: Dict[str, Any]
    event_version: int
    timestamp: datetime
    metadata: Dict[str, Any] = None

class EventStore(ABC):
    @abstractmethod
    async def append(self, event: Event) -> None:
        pass
    
    @abstractmethod
    async def get_events(self, aggregate_id: str, from_version: int = 0) -> List[Event]:
        pass
    
    @abstractmethod
    async def get_snapshot(self, aggregate_id: str) -> Optional[Dict[str, Any]]:
        pass
    
    @abstractmethod
    async def save_snapshot(self, aggregate_id: str, version: int, state: Dict[str, Any]) -> None:
        pass

class InMemoryEventStore(EventStore):
    def __init__(self):
        self.events: Dict[str, List[Event]] = {}
        self.snapshots: Dict[str, Dict[str, Any]] = {}
    
    async def append(self, event: Event) -> None:
        if event.aggregate_id not in self.events:
            self.events[event.aggregate_id] = []
        self.events[event.aggregate_id].append(event)
    
    async def get_events(self, aggregate_id: str, from_version: int = 0) -> List[Event]:
        if aggregate_id not in self.events:
            return []
        return [e for e in self.events[aggregate_id] if e.event_version > from_version]
    
    async def get_snapshot(self, aggregate_id: str) -> Optional[Dict[str, Any]]:
        return self.snapshots.get(aggregate_id)
    
    async def save_snapshot(self, aggregate_id: str, version: int, state: Dict[str, Any]) -> None:
        self.snapshots[aggregate_id] = {
            "version": version,
            "state": state,
            "timestamp": datetime.utcnow()
        }

class Aggregate(ABC):
    def __init__(self, aggregate_id: str):
        self.aggregate_id = aggregate_id
        self.version = 0
        self.uncommitted_events: List[Event] = []
    
    def apply_event(self, event: Event) -> None:
        """Apply event to update state"""
        handler_name = f"_handle_{event.event_type}"
        handler = getattr(self, handler_name, None)
        if handler:
            handler(event.event_data)
        self.version = event.event_version
    
    def raise_event(self, event_type: str, event_data: Dict[str, Any]) -> None:
        """Raise new event"""
        event = Event(
            aggregate_id=self.aggregate_id,
            event_type=event_type,
            event_data=event_data,
            event_version=self.version + 1,
            timestamp=datetime.utcnow()
        )
        self.apply_event(event)
        self.uncommitted_events.append(event)
    
    def mark_events_committed(self) -> None:
        """Clear uncommitted events after saving"""
        self.uncommitted_events.clear()
    
    @abstractmethod
    def get_state(self) -> Dict[str, Any]:
        """Get current state for snapshotting"""
        pass
    
    @abstractmethod
    def restore_from_snapshot(self, state: Dict[str, Any], version: int) -> None:
        """Restore state from snapshot"""
        pass

# Example: Order Aggregate
class Order(Aggregate):
    def __init__(self, order_id: str):
        super().__init__(order_id)
        self.customer_id = None
        self.items = []
        self.total = 0
        self.status = "pending"
    
    def create(self, customer_id: str, items: List[Dict[str, Any]]):
        """Create new order"""
        self.raise_event("order_created", {
            "customer_id": customer_id,
            "items": items,
            "total": sum(item["price"] * item["quantity"] for item in items)
        })
    
    def add_item(self, item: Dict[str, Any]):
        """Add item to order"""
        self.raise_event("item_added", item)
    
    def remove_item(self, item_id: str):
        """Remove item from order"""
        self.raise_event("item_removed", {"item_id": item_id})
    
    def confirm(self):
        """Confirm order"""
        self.raise_event("order_confirmed", {})
    
    def ship(self, tracking_number: str):
        """Ship order"""
        self.raise_event("order_shipped", {"tracking_number": tracking_number})
    
    def cancel(self, reason: str):
        """Cancel order"""
        self.raise_event("order_cancelled", {"reason": reason})
    
    # Event handlers
    def _handle_order_created(self, data: Dict[str, Any]):
        self.customer_id = data["customer_id"]
        self.items = data["items"]
        self.total = data["total"]
        self.status = "created"
    
    def _handle_item_added(self, data: Dict[str, Any]):
        self.items.append(data)
        self.total += data["price"] * data["quantity"]
    
    def _handle_item_removed(self, data: Dict[str, Any]):
        self.items = [item for item in self.items if item.get("id") != data["item_id"]]
        # Recalculate total
        self.total = sum(item["price"] * item["quantity"] for item in self.items)
    
    def _handle_order_confirmed(self, data: Dict[str, Any]):
        self.status = "confirmed"
    
    def _handle_order_shipped(self, data: Dict[str, Any]):
        self.status = "shipped"
    
    def _handle_order_cancelled(self, data: Dict[str, Any]):
        self.status = "cancelled"
    
    def get_state(self) -> Dict[str, Any]:
        return {
            "customer_id": self.customer_id,
            "items": self.items,
            "total": self.total,
            "status": self.status
        }
    
    def restore_from_snapshot(self, state: Dict[str, Any], version: int):
        self.customer_id = state["customer_id"]
        self.items = state["items"]
        self.total = state["total"]
        self.status = state["status"]
        self.version = version

class Repository:
    def __init__(self, event_store: EventStore, aggregate_class: type):
        self.event_store = event_store
        self.aggregate_class = aggregate_class
        self.snapshot_frequency = 10  # Snapshot every 10 events
    
    async def get(self, aggregate_id: str) -> Aggregate:
        """Load aggregate from events"""
        aggregate = self.aggregate_class(aggregate_id)
        
        # Try to load from snapshot
        snapshot = await self.event_store.get_snapshot(aggregate_id)
        from_version = 0
        
        if snapshot:
            aggregate.restore_from_snapshot(snapshot["state"], snapshot["version"])
            from_version = snapshot["version"]
        
        # Load events after snapshot
        events = await self.event_store.get_events(aggregate_id, from_version)
        for event in events:
            aggregate.apply_event(event)
        
        return aggregate
    
    async def save(self, aggregate: Aggregate) -> None:
        """Save aggregate events"""
        for event in aggregate.uncommitted_events:
            await self.event_store.append(event)
        
        # Create snapshot if needed
        if aggregate.version % self.snapshot_frequency == 0:
            await self.event_store.save_snapshot(
                aggregate.aggregate_id,
                aggregate.version,
                aggregate.get_state()
            )
        
        aggregate.mark_events_committed()

# Example usage
async def example_usage():
    # Create event store and repository
    event_store = InMemoryEventStore()
    order_repo = Repository(event_store, Order)
    
    # Create new order
    order = Order("order-123")
    order.create("customer-456", [
        {"id": "item-1", "name": "Widget", "price": 10.00, "quantity": 2},
        {"id": "item-2", "name": "Gadget", "price": 25.00, "quantity": 1}
    ])
    
    # Save order
    await order_repo.save(order)
    
    # Load order from events
    loaded_order = await order_repo.get("order-123")
    print(f"Order status: {loaded_order.status}")
    print(f"Order total: ${loaded_order.total}")
    
    # Modify order
    loaded_order.add_item({"id": "item-3", "name": "Tool", "price": 15.00, "quantity": 1})
    loaded_order.confirm()
    
    # Save changes
    await order_repo.save(loaded_order)
    
    # Ship order
    loaded_order.ship("TRACK-123456")
    await order_repo.save(loaded_order)
    
    print(f"Final status: {loaded_order.status}")
```

## 🔗 Useful Links

### Official Documentation
- [WebSocket Protocol RFC 6455](https://datatracker.ietf.org/doc/html/rfc6455)
- [FastAPI WebSockets Guide](https://fastapi.tiangolo.com/advanced/websockets/)
- [Python AsyncIO Documentation](https://docs.python.org/3/library/asyncio.html)
- [Redis Pub/Sub Documentation](https://redis.io/docs/manual/pubsub/)
- [Server-Sent Events Specification](https://html.spec.whatwg.org/multipage/server-sent-events.html)

### Learning Resources
- [Building Real-time Applications with WebSockets](https://www.fullstackpython.com/websockets.html)
- [Event-Driven Architecture Patterns](https://martinfowler.com/articles/201701-event-driven.html)
- [CQRS and Event Sourcing](https://docs.microsoft.com/en-us/azure/architecture/patterns/cqrs)
- [Streaming Systems Book](http://www.streamingbook.net/)

### Tools and Libraries
- [websockets](https://websockets.readthedocs.io/) - Python WebSocket library
- [aioredis](https://aioredis.readthedocs.io/) - Async Redis client
- [Channels](https://channels.readthedocs.io/) - Django async framework
- [Socket.IO](https://socket.io/) - Real-time engine
- [Apache Kafka](https://kafka.apache.org/) - Distributed streaming platform
- [RabbitMQ](https://www.rabbitmq.com/) - Message broker

### Performance Testing Tools
- [wrk](https://github.com/wg/wrk) - HTTP benchmarking tool
- [Artillery](https://artillery.io/) - Load testing toolkit
- [Locust](https://locust.io/) - Python load testing
- [wscat](https://github.com/websockets/wscat) - WebSocket testing

### Monitoring and Observability
- [Prometheus](https://prometheus.io/) - Metrics collection
- [Grafana](https://grafana.com/) - Metrics visualization
- [Jaeger](https://www.jaegertracing.io/) - Distributed tracing
- [ELK Stack](https://www.elastic.co/elastic-stack) - Logging and search

## 📖 Recommended Reading

### Books
1. **"Designing Data-Intensive Applications"** by Martin Kleppmann
   - Chapter 11: Stream Processing
   
2. **"Building Event-Driven Microservices"** by Adam Bellemare
   - Real-world patterns and implementations

3. **"Streaming Systems"** by Tyler Akidau, Slava Chernyak, Reuven Lax
   - The definitive guide to streaming

4. **"Enterprise Integration Patterns"** by Gregor Hohpe
   - Messaging and integration patterns

### Articles
- [The Log: What every software engineer should know](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying)
- [Event Sourcing](https://martinfowler.com/eaaDev/EventSourcing.html)
- [How Discord Handles Millions of Concurrent Users](https://discord.com/blog/how-discord-handles-two-and-half-million-concurrent-voice-users-using-webrtc)

## 💡 Project Ideas

### 1. Real-time Collaboration Tool
Build a collaborative editor with:
- Live cursor tracking
- Operational transformation
- Conflict resolution
- Presence awareness

### 2. IoT Dashboard
Create an IoT monitoring system:
- Device registration
- Real-time telemetry
- Alert management
- Historical analysis

### 3. Live Sports Tracker
Implement a sports event tracker:
- Live score updates
- Player statistics
- Commentary stream
- Betting odds updates

### 4. Financial Trading Platform
Build a trading system with:
- Real-time price feeds
- Order matching engine
- Portfolio tracking
- Risk analytics

### 5. Gaming Leaderboard
Create a multiplayer game backend:
- Match making
- Real-time game state
- Leaderboard updates
- Chat system

## 🎓 Certification Preparation

### Key Concepts to Master
1. **WebSocket Protocol**
   - Handshake process
   - Frame structure
   - Close codes
   - Security considerations

2. **Async Programming**
   - Event loops
   - Coroutines
   - Concurrent execution
   - Error propagation

3. **Event-Driven Patterns**
   - Pub/Sub
   - Event sourcing
   - CQRS
   - Saga pattern

4. **Stream Processing**
   - Windows and watermarks
   - Exactly-once semantics
   - State management
   - Backpressure

5. **Production Considerations**
   - Scaling strategies
   - Monitoring approaches
   - Security best practices
   - Disaster recovery

### Practice Questions
1. How would you handle 1 million concurrent WebSocket connections?
2. Design a system that guarantees message ordering
3. Implement exactly-once delivery in a distributed system
4. How do you handle clock skew in event timestamps?
5. Design a circuit breaker for WebSocket connections

---

Remember: Real-time systems are complex. Start simple, test thoroughly, and scale gradually!
