# Exercise 2: Application - Real-World E-Commerce Platform
# Starter Code for API Gateway

from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import httpx
import logging
from typing import Dict, Any, Optional
import time

# TODO: Import additional modules for service discovery, circuit breaker, etc.

app = FastAPI(
    title="API Gateway",
    description="Central entry point for microservices",
    version="1.0.0"
)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# TODO: Configure CORS middleware
# Hint: Allow all origins for development, restrict in production

# TODO: Create ServiceDiscovery class
# Hint: Should maintain registry of services and perform health checks
class ServiceDiscovery:
    def __init__(self):
        self.services = {}
        # TODO: Implement service registry
    
    async def register_service(self, name: str, host: str, port: int):
        # TODO: Register a service
        pass
    
    async def get_service(self, name: str) -> Optional[Dict[str, Any]]:
        # TODO: Get a healthy service instance
        pass

# TODO: Create middleware for request logging and correlation ID
@app.middleware("http")
async def add_correlation_id(request: Request, call_next):
    # TODO: Add correlation ID to requests
    # Hint: Check if X-Correlation-ID exists, otherwise generate new UUID
    response = await call_next(request)
    return response

# TODO: Implement rate limiting middleware
# Hint: Use Redis or in-memory store to track request counts

# TODO: Create circuit breaker decorator
# Hint: Track failures and open circuit after threshold

# Health check endpoint
@app.get("/health")
async def health_check():
    """Gateway health check with service status"""
    # TODO: Check health of all registered services
    return {
        "status": "healthy",
        "services": {},
        "timestamp": time.time()
    }

# TODO: Implement service proxy routes
@app.api_route("/{service_name}/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def proxy_request(service_name: str, path: str, request: Request):
    """Proxy requests to appropriate microservices"""
    # TODO: Implement request proxying logic
    # 1. Get service from discovery
    # 2. Forward request with headers
    # 3. Handle errors gracefully
    # 4. Return response
    pass

# TODO: Implement aggregation endpoint
@app.get("/api/orders/{order_id}/full")
async def get_order_with_details(order_id: str):
    """Aggregate data from multiple services"""
    # TODO: Call order service, user service, and product service
    # Combine responses into single response
    pass

# TODO: Add WebSocket support for real-time updates
# Hint: Use WebSocket to push order status updates

# TODO: Implement caching layer
# Hint: Use Redis to cache frequently accessed data

# TODO: Add authentication and authorization
# Hint: Validate JWT tokens and check permissions

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)