# Exercise 1: Application Performance Monitoring - Complete Solution

from fastapi import FastAPI, Request, Response, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import httpx
import asyncio
from typing import Dict, Any, Optional
import uuid
from datetime import datetime
import os
import json

from shared.telemetry import TelemetryManager
from shared.logging_config import configure_logging
from monitoring import create_health_router

# Initialize logging and telemetry
logger = configure_logging("api-gateway")
telemetry = TelemetryManager()
telemetry.initialize("api-gateway")

app = FastAPI(
    title="API Gateway",
    description="Central API Gateway with comprehensive monitoring",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Service endpoints
SERVICES = {
    "orders": os.getenv("ORDER_SERVICE_URL", "http://order-service:8001"),
    "products": os.getenv("PRODUCT_SERVICE_URL", "http://product-service:8002"),
    "users": os.getenv("USER_SERVICE_URL", "http://user-service:8003")
}

# Include health router
app.include_router(create_health_router(SERVICES), prefix="/health", tags=["monitoring"])

@app.middleware("http")
async def monitoring_middleware(request: Request, call_next):
    """Comprehensive monitoring middleware."""
    # Generate correlation ID
    correlation_id = request.headers.get("X-Correlation-ID", str(uuid.uuid4()))
    request.state.correlation_id = correlation_id
    
    # Extract trace context
    trace_parent = request.headers.get("traceparent")
    
    # Start span
    with telemetry.tracer.start_as_current_span(
        f"{request.method} {request.url.path}",
        attributes={
            "http.method": request.method,
            "http.url": str(request.url),
            "http.scheme": request.url.scheme,
            "http.host": request.url.hostname,
            "http.target": request.url.path,
            "correlation_id": correlation_id,
            "user_agent": request.headers.get("user-agent", ""),
            "client_ip": request.client.host if request.client else "unknown"
        }
    ) as span:
        # Track custom metric for request rate
        telemetry.track_metric(
            "request_rate",
            1,
            properties={
                "endpoint": request.url.path,
                "method": request.method
            }
        )
        
        # Track request start
        start_time = datetime.utcnow()
        
        try:
            # Process request
            response = await call_next(request)
            
            # Calculate duration
            duration = (datetime.utcnow() - start_time).total_seconds()
            
            # Add telemetry headers to response
            response.headers["X-Correlation-ID"] = correlation_id
            response.headers["X-Response-Time"] = f"{duration:.3f}"
            
            # Log successful request
            logger.info(
                "request_completed",
                method=request.method,
                path=request.url.path,
                status_code=response.status_code,
                duration=duration,
                correlation_id=correlation_id,
                trace_id=span.get_span_context().trace_id.to_bytes(16, 'big').hex()
            )
            
            # Track metrics
            telemetry.track_request(
                name=f"{request.method} {request.url.path}",
                duration=duration * 1000,  # Convert to milliseconds
                response_code=str(response.status_code),
                success=response.status_code < 400,
                properties={
                    "endpoint": request.url.path,
                    "method": request.method,
                    "correlation_id": correlation_id
                }
            )
            
            # Track business metrics
            if request.url.path.startswith("/api/orders") and request.method == "POST":
                telemetry.track_event(
                    "OrderCreated",
                    properties={
                        "correlation_id": correlation_id,
                        "processing_time": f"{duration:.3f}"
                    }
                )
            
            # Update span status
            span.set_attribute("http.status_code", response.status_code)
            if response.status_code >= 400:
                span.set_status(trace.Status(trace.StatusCode.ERROR))
            
            return response
            
        except Exception as e:
            # Calculate duration for failed request
            duration = (datetime.utcnow() - start_time).total_seconds()
            
            # Log error
            logger.error(
                "request_failed",
                method=request.method,
                path=request.url.path,
                error=str(e),
                duration=duration,
                correlation_id=correlation_id,
                exc_info=True
            )
            
            # Track failed request
            telemetry.track_request(
                name=f"{request.method} {request.url.path}",
                duration=duration * 1000,
                response_code="500",
                success=False,
                properties={
                    "error": str(e),
                    "correlation_id": correlation_id
                }
            )
            
            # Track exception
            telemetry.track_exception(
                exception=e,
                properties={
                    "endpoint": request.url.path,
                    "method": request.method,
                    "correlation_id": correlation_id
                }
            )
            
            # Record exception in span
            span.record_exception(e)
            span.set_status(trace.Status(trace.StatusCode.ERROR, str(e)))
            
            # Return error response
            return Response(
                content=json.dumps({
                    "error": "Internal server error",
                    "correlation_id": correlation_id
                }),
                status_code=500,
                media_type="application/json",
                headers={"X-Correlation-ID": correlation_id}
            )

@app.get("/")
async def root():
    """Root endpoint with version info."""
    return {
        "service": "API Gateway",
        "version": "1.0.0",
        "status": "operational",
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/api/{service}/{path:path}")
async def proxy_request(service: str, path: str, request: Request):
    """Proxy requests to downstream services with monitoring."""
    # Validate service
    if service not in SERVICES:
        raise HTTPException(status_code=404, detail=f"Service '{service}' not found")
    
    service_url = SERVICES[service]
    full_url = f"{service_url}/{path}"
    
    # Get correlation ID from request state
    correlation_id = getattr(request.state, "correlation_id", str(uuid.uuid4()))
    
    # Create child span for proxy operation
    with telemetry.tracer.start_as_current_span(
        f"proxy_to_{service}",
        attributes={
            "proxy.service": service,
            "proxy.path": path,
            "proxy.url": full_url,
            "correlation_id": correlation_id
        }
    ) as span:
        # Prepare headers with trace propagation
        headers = dict(request.headers)
        headers["X-Correlation-ID"] = correlation_id
        
        # Inject trace context
        from opentelemetry import propagate
        propagate.inject(headers)
        
        # Remove host header to avoid conflicts
        headers.pop("host", None)
        
        # Track dependency start
        dependency_start = datetime.utcnow()
        
        try:
            # Make request to downstream service
            async with httpx.AsyncClient(timeout=30.0) as client:
                # Forward request with all data
                response = await client.request(
                    method=request.method,
                    url=full_url,
                    headers=headers,
                    params=dict(request.query_params),
                    content=await request.body() if request.method in ["POST", "PUT", "PATCH"] else None
                )
            
            # Calculate dependency duration
            dependency_duration = (datetime.utcnow() - dependency_start).total_seconds()
            
            # Track dependency
            telemetry.track_dependency(
                name=f"{service}/{path}",
                data=full_url,
                duration=dependency_duration * 1000,
                success=response.status_code < 400,
                dependency_type="HTTP",
                properties={
                    "service": service,
                    "status_code": str(response.status_code),
                    "correlation_id": correlation_id
                }
            )
            
            # Log successful proxy
            logger.info(
                "proxy_request_completed",
                service=service,
                path=path,
                status_code=response.status_code,
                duration=dependency_duration,
                correlation_id=correlation_id
            )
            
            # Return proxied response
            return Response(
                content=response.content,
                status_code=response.status_code,
                headers=dict(response.headers),
                media_type=response.headers.get("content-type", "application/json")
            )
            
        except httpx.TimeoutException:
            # Track timeout
            dependency_duration = (datetime.utcnow() - dependency_start).total_seconds()
            
            telemetry.track_dependency(
                name=f"{service}/{path}",
                data=full_url,
                duration=dependency_duration * 1000,
                success=False,
                dependency_type="HTTP",
                properties={
                    "service": service,
                    "error": "timeout",
                    "correlation_id": correlation_id
                }
            )
            
            logger.error(
                "proxy_request_timeout",
                service=service,
                path=path,
                correlation_id=correlation_id
            )
            
            span.set_status(trace.Status(trace.StatusCode.ERROR, "Request timeout"))
            raise HTTPException(status_code=504, detail="Gateway timeout")
            
        except Exception as e:
            # Track general failure
            dependency_duration = (datetime.utcnow() - dependency_start).total_seconds()
            
            telemetry.track_dependency(
                name=f"{service}/{path}",
                data=full_url,
                duration=dependency_duration * 1000,
                success=False,
                dependency_type="HTTP",
                properties={
                    "service": service,
                    "error": str(e),
                    "correlation_id": correlation_id
                }
            )
            
            logger.error(
                "proxy_request_failed",
                service=service,
                path=path,
                error=str(e),
                correlation_id=correlation_id,
                exc_info=True
            )
            
            span.record_exception(e)
            span.set_status(trace.Status(trace.StatusCode.ERROR, str(e)))
            raise HTTPException(status_code=502, detail="Bad gateway")

@app.post("/api/batch")
async def batch_request(requests: list[Dict[str, Any]], request: Request):
    """Execute multiple requests in parallel with monitoring."""
    correlation_id = getattr(request.state, "correlation_id", str(uuid.uuid4()))
    
    with telemetry.tracer.start_as_current_span(
        "batch_request",
        attributes={
            "batch.size": len(requests),
            "correlation_id": correlation_id
        }
    ) as span:
        # Track batch request event
        telemetry.track_event(
            "BatchRequestStarted",
            properties={
                "request_count": str(len(requests)),
                "correlation_id": correlation_id
            }
        )
        
        # Execute requests in parallel
        tasks = []
        for idx, req in enumerate(requests):
            service = req.get("service")
            path = req.get("path", "")
            method = req.get("method", "GET")
            
            # Create mock request object
            mock_request = Request(
                scope={
                    "type": "http",
                    "method": method,
                    "headers": [(b"x-correlation-id", correlation_id.encode())],
                    "query_string": b"",
                    "path": f"/api/{service}/{path}"
                }
            )
            mock_request.state.correlation_id = f"{correlation_id}-{idx}"
            
            # Add to tasks
            task = proxy_request(service, path, mock_request)
            tasks.append(task)
        
        # Wait for all requests
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Process results
        responses = []
        success_count = 0
        for idx, result in enumerate(results):
            if isinstance(result, Exception):
                responses.append({
                    "index": idx,
                    "success": False,
                    "error": str(result)
                })
            else:
                success_count += 1
                responses.append({
                    "index": idx,
                    "success": True,
                    "data": result.body.decode() if hasattr(result, 'body') else result
                })
        
        # Track batch completion
        telemetry.track_event(
            "BatchRequestCompleted",
            properties={
                "request_count": str(len(requests)),
                "success_count": str(success_count),
                "failure_count": str(len(requests) - success_count),
                "correlation_id": correlation_id
            }
        )
        
        span.set_attribute("batch.success_count", success_count)
        span.set_attribute("batch.failure_count", len(requests) - success_count)
        
        return {
            "correlation_id": correlation_id,
            "total_requests": len(requests),
            "successful": success_count,
            "failed": len(requests) - success_count,
            "results": responses
        }

if __name__ == "__main__":
    import uvicorn
    
    # Configure logging for uvicorn
    log_config = uvicorn.config.LOGGING_CONFIG
    log_config["formatters"]["default"]["fmt"] = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    log_config["formatters"]["access"]["fmt"] = '%(asctime)s - %(name)s - %(levelname)s - %(client_addr)s - "%(request_line)s" %(status_code)s'
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_config=log_config,
        access_log=True
    )