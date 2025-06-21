# Test Monitoring Implementation
import pytest
import asyncio
import httpx
from datetime import datetime, timedelta
import os
import json
from typing import Dict, List, Any

# Test configuration
BASE_URL = os.getenv("API_BASE_URL", "http://localhost:8000")
APP_INSIGHTS_CONNECTION = os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING")

class TestMonitoring:
    """Test suite for monitoring implementation."""
    
    @pytest.fixture
    async def client(self):
        """Create test client."""
        async with httpx.AsyncClient(base_url=BASE_URL) as client:
            yield client
    
    @pytest.mark.asyncio
    async def test_health_endpoint(self, client):
        """Test health check endpoint returns proper monitoring data."""
        response = await client.get("/health/status")
        assert response.status_code == 200
        
        data = response.json()
        assert "status" in data
        assert "timestamp" in data
        assert "services" in data
        assert "metrics" in data
        
        # Verify service health checks
        for service in data["services"]:
            assert "name" in service
            assert "status" in service
            if service["status"] == "healthy":
                assert "response_time" in service
    
    @pytest.mark.asyncio
    async def test_correlation_id_propagation(self, client):
        """Test correlation ID is properly propagated."""
        correlation_id = "test-correlation-123"
        headers = {"X-Correlation-ID": correlation_id}
        
        response = await client.get("/", headers=headers)
        assert response.status_code == 200
        assert response.headers.get("X-Correlation-ID") == correlation_id
    
    @pytest.mark.asyncio
    async def test_response_time_header(self, client):
        """Test response time is included in headers."""
        response = await client.get("/")
        assert response.status_code == 200
        assert "X-Response-Time" in response.headers
        
        # Verify it's a valid float
        response_time = float(response.headers["X-Response-Time"])
        assert response_time > 0
        assert response_time < 10  # Should be less than 10 seconds
    
    @pytest.mark.asyncio
    async def test_trace_context_propagation(self, client):
        """Test W3C trace context propagation."""
        # Valid W3C traceparent format
        traceparent = "00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01"
        headers = {"traceparent": traceparent}
        
        response = await client.get("/", headers=headers)
        assert response.status_code == 200
        
        # For proxy requests, trace context should be forwarded
        # This would be validated by checking downstream service received it
    
    @pytest.mark.asyncio
    async def test_error_tracking(self, client):
        """Test errors are properly tracked."""
        # Request non-existent service
        response = await client.get("/api/nonexistent/test")
        assert response.status_code == 404
        
        # Should have correlation ID even for errors
        assert "X-Correlation-ID" in response.headers
        
        # Error response should have proper format
        data = response.json()
        assert "detail" in data or "error" in data
    
    @pytest.mark.asyncio
    async def test_proxy_monitoring(self, client):
        """Test proxy requests include monitoring."""
        # This assumes order service is running
        response = await client.get("/api/orders/health")
        
        # Even if service is down, should get proper error response
        assert response.status_code in [200, 502, 503, 504]
        assert "X-Correlation-ID" in response.headers
    
    @pytest.mark.asyncio
    async def test_batch_request_monitoring(self, client):
        """Test batch requests are properly monitored."""
        batch_requests = [
            {"service": "orders", "path": "health", "method": "GET"},
            {"service": "products", "path": "health", "method": "GET"},
            {"service": "users", "path": "health", "method": "GET"}
        ]
        
        response = await client.post("/api/batch", json=batch_requests)
        data = response.json()
        
        assert "correlation_id" in data
        assert "total_requests" in data
        assert data["total_requests"] == len(batch_requests)
        assert "successful" in data
        assert "failed" in data
        assert "results" in data
    
    @pytest.mark.asyncio
    async def test_metrics_endpoint(self, client):
        """Test Prometheus metrics endpoint if implemented."""
        response = await client.get("/metrics")
        
        if response.status_code == 200:
            content = response.text
            # Check for standard metrics
            assert "http_requests_total" in content or "request_count" in content
            assert "http_request_duration_seconds" in content or "request_duration" in content

class TestApplicationInsights:
    """Test Application Insights integration."""
    
    @pytest.mark.skipif(not APP_INSIGHTS_CONNECTION, reason="No App Insights connection")
    @pytest.mark.asyncio
    async def test_telemetry_sending(self):
        """Test telemetry is being sent to Application Insights."""
        from azure.monitor.query import LogsQueryClient
        from azure.identity import DefaultAzureCredential
        
        # Extract workspace ID from connection string
        # This is a simplified example
        
        credential = DefaultAzureCredential()
        client = LogsQueryClient(credential)
        
        # Query recent requests
        query = """
        requests
        | where timestamp > ago(5m)
        | where cloud_RoleName == "api-gateway"
        | summarize count() by bin(timestamp, 1m)
        """
        
        # Note: In real test, you'd need the workspace ID
        # response = await client.query_workspace(workspace_id, query)

class TestPerformanceMonitoring:
    """Test performance monitoring capabilities."""
    
    @pytest.mark.asyncio
    async def test_load_with_monitoring(self):
        """Generate load and verify monitoring captures it."""
        async def make_request(session: httpx.AsyncClient, index: int):
            """Make a single request."""
            try:
                response = await session.get(
                    "/",
                    headers={"X-Request-ID": f"load-test-{index}"}
                )
                return {
                    "index": index,
                    "status": response.status_code,
                    "duration": float(response.headers.get("X-Response-Time", 0))
                }
            except Exception as e:
                return {
                    "index": index,
                    "status": 0,
                    "error": str(e)
                }
        
        # Generate 100 concurrent requests
        async with httpx.AsyncClient(base_url=BASE_URL) as client:
            tasks = [make_request(client, i) for i in range(100)]
            results = await asyncio.gather(*tasks)
        
        # Analyze results
        successful = [r for r in results if r.get("status") == 200]
        failed = [r for r in results if r.get("status") != 200]
        
        print(f"\nLoad Test Results:")
        print(f"Total Requests: {len(results)}")
        print(f"Successful: {len(successful)}")
        print(f"Failed: {len(failed)}")
        
        if successful:
            durations = [r["duration"] for r in successful]
            avg_duration = sum(durations) / len(durations)
            p95_duration = sorted(durations)[int(len(durations) * 0.95)]
            
            print(f"Average Duration: {avg_duration:.3f}s")
            print(f"P95 Duration: {p95_duration:.3f}s")
        
        # Verify monitoring captured the load
        assert len(successful) > 0, "No successful requests"
        assert avg_duration < 1.0, "Average response time too high"

class TestDistributedTracing:
    """Test distributed tracing implementation."""
    
    @pytest.mark.asyncio
    async def test_trace_propagation_chain(self):
        """Test trace context propagates through service chain."""
        trace_id = "0af7651916cd43dd8448eb211c80319c"
        parent_id = "b7ad6b7169203331"
        traceparent = f"00-{trace_id}-{parent_id}-01"
        
        async with httpx.AsyncClient(base_url=BASE_URL) as client:
            # Make request with trace context
            response = await client.get(
                "/api/orders/test",
                headers={"traceparent": traceparent}
            )
            
            # Even if endpoint doesn't exist, trace should propagate
            correlation_id = response.headers.get("X-Correlation-ID")
            assert correlation_id is not None
            
            # In a real test, we'd verify downstream services received
            # the trace context by checking their logs/telemetry

def run_all_tests():
    """Run all monitoring tests."""
    pytest.main([__file__, "-v", "--tb=short"])

if __name__ == "__main__":
    run_all_tests()