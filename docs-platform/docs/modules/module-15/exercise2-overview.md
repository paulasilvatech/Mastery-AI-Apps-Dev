---
sidebar_position: 5
title: "Exercise 2: Overview"
description: "## 🎯 Exercise Overview"
---

# Exercise 2: Load Balancing at Scale (⭐⭐ Application)

## 🎯 Exercise Overview

**Duration**: 45-60 minutes  
**Difficulty**: ⭐⭐ (Medium)  
**Success Rate**: 80%

In this application-level exercise, you'll build a sophisticated load balancer with multiple algorithms, health checking, and auto-scaling capabilities. You'll use GitHub Copilot to implement production-grade load balancing patterns.

## 🎓 Learning Objectives

By completing this exercise, you will:
- Implement multiple load balancing algorithms (round-robin, least connections, weighted)
- Build health checking and circuit breaker patterns
- Create auto-scaling based on metrics
- Monitor load distribution and performance
- Handle failover scenarios gracefully

## 📋 Prerequisites

- ✅ Completed Exercise 1 (Caching Fundamentals)
- ✅ Understanding of HTTP and distributed systems
- ✅ Docker containers running
- ✅ Basic knowledge of load balancing concepts

## 🏗️ What You'll Build

A complete load balancing solution:

```mermaid
graph TB
    Client[Clients] --&gt; LB[Load Balancer]
    LB --&gt; HC[Health Checker]
    HC --&gt; S1[Server 1]
    HC --&gt; S2[Server 2]
    HC --&gt; S3[Server 3]
    HC --&gt; S4[Server 4]
    
    LB --&gt;|Algorithm Selection| RR[Round Robin]
    LB --&gt;|Algorithm Selection| LC[Least Connections]
    LB --&gt;|Algorithm Selection| WRR[Weighted Round Robin]
    
    S1 --&gt; CB1[Circuit Breaker]
    S2 --&gt; CB2[Circuit Breaker]
    S3 --&gt; CB3[Circuit Breaker]
    S4 --&gt; CB4[Circuit Breaker]
    
    style LB fill:#f96,stroke:#333,stroke-width:4px
    style HC fill:#9f9,stroke:#333,stroke-width:2px
```

## 🚀 Implementation Steps

### Step 1: Project Structure

```
exercise2-application/
├── load_balancer/
│   ├── __init__.py
│   ├── algorithms.py
│   ├── health_check.py
│   ├── circuit_breaker.py
│   └── balancer.py
├── backend_services/
│   ├── __init__.py
│   └── app.py
├── tests/
│   ├── test_algorithms.py
│   ├── test_health_check.py
│   └── test_load_distribution.py
├── monitoring/
│   └── metrics.py
├── docker-compose.yml
└── main.py
```

### Step 2: Create Backend Service

Create `backend_services/app.py`:

**🤖 Copilot Prompt Suggestion #1:**
```python
# Create a FastAPI backend service that:
# - Has a unique server ID
# - Tracks number of active connections
# - Simulates variable response times
# - Can be configured to fail for testing
# - Exposes health and metrics endpoints
# - Supports graceful shutdown
# Include connection counting and request tracking
```

**Expected Implementation Structure:**
```python
from fastapi import FastAPI, Request, Response
import asyncio
import random
import os
from datetime import datetime
import uuid

app = FastAPI()

# Server configuration
SERVER_ID = os.getenv("SERVER_ID", str(uuid.uuid4())[:8])
SERVER_PORT = int(os.getenv("SERVER_PORT", 8001))
FAILURE_RATE = float(os.getenv("FAILURE_RATE", 0.0))

# Metrics
active_connections = 0
total_requests = 0
start_time = datetime.utcnow()

@app.middleware("http")
async def count_connections(request: Request, call_next):
    global active_connections, total_requests
    active_connections += 1
    total_requests += 1
    
    try:
        response = await call_next(request)
        return response
    finally:
        active_connections -= 1

@app.get("/")
async def root():
    # Simulate variable processing time
    await asyncio.sleep(random.uniform(0.01, 0.1))
    
    # Simulate failures based on failure rate
    if random.random() &lt; FAILURE_RATE:
        return Response(status_code=503)
    
    return {
        "server_id": SERVER_ID,
        "timestamp": datetime.utcnow(),
        "active_connections": active_connections
    }

# Additional endpoints will be added by Copilot...
```

### Step 3: Implement Load Balancing Algorithms

Create `load_balancer/algorithms.py`:

**🤖 Copilot Prompt Suggestion #2:**
```python
# Create load balancing algorithm classes:
# 1. RoundRobinBalancer - distributes requests evenly
# 2. LeastConnectionsBalancer - routes to server with fewest connections
# 3. WeightedRoundRobinBalancer - distributes based on server weights
# 4. IPHashBalancer - consistent hashing based on client IP
# 5. RandomBalancer - random server selection
# Each should track metrics and handle server availability
# Include thread-safe operations
```

### Step 4: Implement Health Checking

Create `load_balancer/health_check.py`:

**🤖 Copilot Prompt Suggestion #3:**
```python
# Create a health checker that:
# - Performs periodic health checks on all backend servers
# - Supports multiple check types (HTTP, TCP, custom)
# - Implements exponential backoff for failed servers
# - Maintains server status (healthy, unhealthy, draining)
# - Emits events for status changes
# - Configurable check intervals and thresholds
# Make it async and efficient
```

### Step 5: Implement Circuit Breaker

Create `load_balancer/circuit_breaker.py`:

**🤖 Copilot Prompt Suggestion #4:**
```python
# Implement a circuit breaker with three states:
# - CLOSED: Normal operation, requests pass through
# - OPEN: Failures exceeded threshold, requests blocked
# - HALF_OPEN: Testing if service recovered
# Include:
# - Configurable failure threshold and timeout
# - Success/failure counting with sliding window
# - Automatic state transitions
# - Metrics for each state
# Thread-safe implementation
```

### Step 6: Create the Main Load Balancer

Create `load_balancer/balancer.py`:

```python
from typing import List, Optional, Dict, Any
import asyncio
import httpx
import logging
from datetime import datetime
from .algorithms import (
    RoundRobinBalancer, 
    LeastConnectionsBalancer,
    WeightedRoundRobinBalancer
)
from .health_check import HealthChecker
from .circuit_breaker import CircuitBreaker

logger = logging.getLogger(__name__)

class LoadBalancer:
    def __init__(self, 
                 servers: List[Dict[str, Any]], 
                 algorithm: str = "round_robin",
                 health_check_interval: int = 5):
        """
        Initialize load balancer with servers and algorithm.
        
        Args:
            servers: List of server configurations
            algorithm: Load balancing algorithm to use
            health_check_interval: Health check interval in seconds
        """
        self.servers = servers
        self.algorithm = self._create_algorithm(algorithm)
        self.health_checker = HealthChecker(servers, interval=health_check_interval)
        self.circuit_breakers = {
            server["id"]: CircuitBreaker(
                failure_threshold=5,
                recovery_timeout=30,
                expected_exception=httpx.HTTPError
            )
            for server in servers
        }
        self.client = httpx.AsyncClient(timeout=10.0)
        self.metrics = {
            "total_requests": 0,
            "successful_requests": 0,
            "failed_requests": 0,
            "request_distribution": {{{{s["id"]: 0 for s in servers}}}}
        }
    
    def _create_algorithm(self, algorithm: str):
        """Create load balancing algorithm instance."""
        algorithms = {
            "round_robin": RoundRobinBalancer,
            "least_connections": LeastConnectionsBalancer,
            "weighted": WeightedRoundRobinBalancer
        }
        return algorithms.get(algorithm, RoundRobinBalancer)(self.servers)
    
    async def start(self):
        """Start the load balancer and health checker."""
        await self.health_checker.start()
        logger.info(f"Load balancer started with {len(self.servers)} servers")
    
    async def stop(self):
        """Stop the load balancer gracefully."""
        await self.health_checker.stop()
        await self.client.aclose()
    
    async def handle_request(self, 
                           path: str, 
                           method: str = "GET", 
                           **kwargs) -&gt; httpx.Response:
        """
        Handle incoming request and route to appropriate server.
        
        Args:
            path: Request path
            method: HTTP method
            **kwargs: Additional request parameters
            
        Returns:
            Response from backend server
        """
        self.metrics["total_requests"] += 1
        
        # Get healthy servers
        healthy_servers = await self.health_checker.get_healthy_servers()
        if not healthy_servers:
            self.metrics["failed_requests"] += 1
            raise Exception("No healthy servers available")
        
        # Select server using algorithm
        server = await self.algorithm.select_server(healthy_servers)
        if not server:
            self.metrics["failed_requests"] += 1
            raise Exception("Failed to select server")
        
        # Update metrics
        self.metrics["request_distribution"][server["id"]] += 1
        
        # Execute request with circuit breaker
        circuit_breaker = self.circuit_breakers[server["id"]]
        
        try:
            async with circuit_breaker:
                url = f"{server['url']}{path}"
                response = await self.client.request(method, url, **kwargs)
                response.raise_for_status()
                
                self.metrics["successful_requests"] += 1
                return response
                
        except Exception as e:
            self.metrics["failed_requests"] += 1
            logger.error(f"Request failed for server {server['id']}: {e}")
            
            # Try another server
            return await self._retry_request(path, method, server["id"], **kwargs)
    
    async def _retry_request(self, path: str, method: str, 
                           failed_server_id: str, **kwargs) -&gt; httpx.Response:
        """Retry request on different server."""
        healthy_servers = await self.health_checker.get_healthy_servers()
        available_servers = [s for s in healthy_servers if s["id"] != failed_server_id]
        
        if not available_servers:
            raise Exception("No alternative servers available")
        
        server = await self.algorithm.select_server(available_servers)
        url = f"{server['url']}{path}"
        
        response = await self.client.request(method, url, **kwargs)
        response.raise_for_status()
        
        return response
    
    def get_metrics(self) -&gt; Dict[str, Any]:
        """Get load balancer metrics."""
        return {
            **self.metrics,
            "success_rate": (
                self.metrics["successful_requests"] / self.metrics["total_requests"]
                if self.metrics["total_requests"] &gt; 0 else 0
            ),
            "server_status": self.health_checker.get_server_status(),
            "circuit_breaker_status": {
                server_id: cb.state 
                for server_id, cb in self.circuit_breakers.items()
            }
        }
```

### Step 7: Create Main Application

Create `main.py`:

**🤖 Copilot Prompt Suggestion #5:**
```python
# Create a FastAPI application that:
# - Acts as the load balancer frontend
# - Forwards all requests to backend servers
# - Exposes load balancer metrics and configuration
# - Supports dynamic server addition/removal
# - Implements request tracing and logging
# - Provides admin endpoints for management
# Include WebSocket support for real-time metrics
```

### Step 8: Docker Compose Configuration

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  # Backend servers
  backend1:
    build: ./backend_services
    environment:
      - SERVER_ID=backend1
      - SERVER_PORT=8001
      - FAILURE_RATE=0.05  # 5% failure rate for testing
    ports:
      - "8001:8001"
  
  backend2:
    build: ./backend_services
    environment:
      - SERVER_ID=backend2
      - SERVER_PORT=8002
      - FAILURE_RATE=0.02
    ports:
      - "8002:8002"
  
  backend3:
    build: ./backend_services
    environment:
      - SERVER_ID=backend3
      - SERVER_PORT=8003
      - FAILURE_RATE=0.01
    ports:
      - "8003:8003"
  
  backend4:
    build: ./backend_services
    environment:
      - SERVER_ID=backend4
      - SERVER_PORT=8004
      - FAILURE_RATE=0.0  # Always healthy
    ports:
      - "8004:8004"
  
  # Load balancer
  load_balancer:
    build: .
    ports:
      - "8000:8000"
    depends_on:
      - backend1
      - backend2
      - backend3
      - backend4
    environment:
      - ALGORITHM=least_connections
      - HEALTH_CHECK_INTERVAL=5
```

## 📊 Testing and Validation

### Load Testing Script

Create `tests/load_test.py`:

**🤖 Copilot Prompt Suggestion #6:**
```python
# Create a load testing script that:
# - Generates concurrent requests to test load distribution
# - Measures response times and success rates
# - Tests failover behavior by killing backend servers
# - Validates even distribution for round-robin
# - Checks least-connections accuracy
# - Generates a performance report
# Use asyncio for high concurrency
```

### Run Tests

```bash
# Start all services
docker-compose up -d

# Run load tests
python tests/load_test.py

# Monitor metrics
curl http://localhost:8000/metrics

# Test failover
docker-compose stop backend1
# Observe traffic redistribution
```

## ✅ Success Criteria

Your implementation is successful when:

1. **Load Distribution**: Traffic is evenly distributed according to algorithm
2. **Health Checking**: Failed servers are automatically removed
3. **Circuit Breaking**: Prevents cascading failures
4. **Performance**: Less than 100ms average response time under load
5. **Reliability**: Greater than 99.9% success rate with healthy servers
6. **Failover**: Less than 1 second detection and rerouting

## 🏆 Extension Challenges

1. **Sticky Sessions**: Implement session affinity
2. **Rate Limiting**: Add per-client rate limiting
3. **Geographic Routing**: Route based on client location
4. **A/B Testing**: Implement percentage-based routing

## 💡 Key Takeaways

- Load balancing is critical for scalability
- Health checking prevents routing to failed servers
- Circuit breakers protect against cascading failures
- Different algorithms suit different use cases
- Monitoring is essential for production systems

Continue to [Exercise 3: Production Performance Optimization →](../exercise3-mastery/instructions.md)