# Exercise 1: Application Performance Monitoring - Starter Code
# TODO: Complete the implementation following the exercise instructions

from fastapi import FastAPI, Request, Response
from typing import Dict, Any
import os
from datetime import datetime
import uuid

# TODO: Import telemetry and logging modules from shared
# from shared.telemetry import TelemetryManager
# from shared.logging_config import configure_logging

app = FastAPI(title="API Gateway - Starter")

# TODO: Initialize logging and telemetry
# logger = configure_logging("api-gateway")
# telemetry = TelemetryManager()
# telemetry.initialize("api-gateway")

# Service endpoints
SERVICES = {
    "orders": "http://order-service:8001",
    "products": "http://product-service:8002", 
    "users": "http://user-service:8003"
}

@app.middleware("http")
async def monitoring_middleware(request: Request, call_next):
    """TODO: Add monitoring to all requests."""
    # Step 1: Generate correlation ID
    correlation_id = str(uuid.uuid4())
    
    # TODO: Add correlation ID to request state
    # request.state.correlation_id = correlation_id
    
    # TODO: Start telemetry span
    # Use telemetry.tracer.start_as_current_span()
    
    # TODO: Track request start time
    start_time = datetime.utcnow()
    
    # TODO: Process request and handle errors
    response = await call_next(request)
    
    # TODO: Calculate duration and log request
    duration = (datetime.utcnow() - start_time).total_seconds()
    
    # TODO: Track custom metrics
    # Use telemetry.telemetry_client.track_metric()
    
    return response

@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": "API Gateway Running", "version": "1.0.0"}

@app.get("/health")
async def health():
    """TODO: Implement health check endpoint."""
    # Return basic health status for now
    return {"status": "healthy"}

@app.get("/api/{service}/{path:path}")
async def proxy_request(service: str, path: str, request: Request):
    """TODO: Implement service proxy with monitoring."""
    # Step 1: Validate service exists
    if service not in SERVICES:
        return Response(content="Service not found", status_code=404)
    
    # TODO: Add distributed tracing
    # - Extract trace context from headers
    # - Create child span for proxy operation
    # - Add service and path attributes
    
    # TODO: Make request to downstream service
    # - Use httpx with timeout
    # - Propagate headers including trace context
    # - Handle errors gracefully
    
    # TODO: Track dependency metrics
    # - Record latency
    # - Track success/failure
    # - Log with correlation ID
    
    # Placeholder response
    return {"message": f"Proxy to {service}/{path} not implemented"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)