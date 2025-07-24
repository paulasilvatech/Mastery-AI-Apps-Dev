---
sidebar_position: 7
title: "Exercise 3: Part 2"
description: "## 📊 Part 5: Adding Monitoring and Logging"
---

# Exercício 3: Debug & Optimize API - Partee 2

## 📊 Partee 5: Adding Monitoring and Logging

### Step 13: Implement Structured Logging

Replace print statements with proper logging:

```python
# app.py - Add structured logging
import logging
import json
from pythonjsonlogger import jsonlogger

# Configure structured JSON logging
# Log all requests with timing
# Log errors with stack traces
# Add correlation IDs for request tracking
def setup_logging(app):
```

**🤖 Copilot Prompt Suggestion #7:**
"Create structured logging setup with JSON formatter, request/response middleware logging with timing, error logging with traceback, correlation ID generation using uuid"

**Expected Implementation:**
```python
import logging
import time
import uuid
from flask import g, request
from pythonjsonlogger import jsonlogger

def setup_logging(app):
    """Configure structured logging for the application."""
    # Create JSON formatter
    formatter = jsonlogger.JsonFormatter(
        '%(timestamp)s %(level)s %(name)s %(message)s'
    )
    
    # Configure handlers
    handler = logging.StreamHandler()
    handler.setFormatter(formatter)
    
    # Set up logger
    app.logger.handlers = []
    app.logger.addHandler(handler)
    app.logger.setLevel(logging.INFO)
    
    # Add request logging middleware
    @app.before_request
    def before_request():
        g.start_time = time.time()
        g.correlation_id = str(uuid.uuid4())
        
        app.logger.info('request_started', extra={
            'correlation_id': g.correlation_id,
            'method': request.method,
            'path': request.path,
            'remote_addr': request.remote_addr
        })
    
    @app.after_request
    def after_request(response):
        duration = time.time() - g.start_time
        
        app.logger.info('request_completed', extra={
            'correlation_id': g.correlation_id,
            'method': request.method,
            'path': request.path,
            'status_code': response.status_code,
            'duration_ms': round(duration * 1000, 2)
        })
        
        # Add correlation ID to response headers
        response.headers['X-Correlation-ID'] = g.correlation_id
        return response
    
    @app.errorhandler(Exception)
    def handle_exception(error):
        app.logger.error('unhandled_exception', extra={
            'correlation_id': getattr(g, 'correlation_id', 'unknown'),
            'error_type': type(error).__name__,
            'error_message': str(error),
            'traceback': traceback.format_exc()
        })
        
        return jsonify({
            'error': 'Internal server error',
            'correlation_id': getattr(g, 'correlation_id', 'unknown')
        }), 500
```

### Step 14: Add Performance Monitoring

Implement APM (Application Performance Monitoring):

```python
# monitoring.py - Add performance monitoring
from functools import wraps
import time
from prometheus_flask_exporter import PrometheusMetrics

# Add Prometheus metrics:
# - Request count by endpoint
# - Request duration histograms
# - Database query time
# - Cache hit/miss rates
def setup_monitoring(app):
```

**🤖 Copilot Prompt Suggestion #8:**
"Create Prometheus monitoring with request_count counter, request_duration histogram, db_query_duration histogram, cache_hit_rate gauge, custom decorator for timing functions"

### Step 15: Create Health Verificar Endpoints

```python
# routes/health.py
from flask import Blueprint, jsonify
import psutil
from sqlalchemy import text

health_bp = Blueprint('health', __name__)

# Create health check endpoints:
# /health - Basic health check
# /health/live - Kubernetes liveness probe
# /health/ready - Kubernetes readiness probe
# Include: database connection, memory usage, disk space
```

**🤖 Copilot Prompt Suggestion #9:**
"Create health endpoints with database ping, memory/CPU usage via psutil, disk space check, external service checks, return 200/503 based on health"

## 🔒 Partee 6: Security Difícilening

### Step 16: Add Authentication and Authorization

Implement JWT authentication:

```python
# auth.py - JWT authentication
from functools import wraps
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity

# Implement:
# - User login endpoint
# - Token generation
# - Protected route decorator
# - Role-based access control
def setup_auth(app):
```

**🤖 Copilot Prompt Suggestion #10:**
"Create JWT auth with login endpoint validating username/password, token generation with user roles, @require_role decorator for RBAC, token refresh endpoint"

### Step 17: Add Input Sanitization

Prevent XSS and injection attacks:

```python
# security.py - Input sanitization
import bleach
from marshmallow import fields, pre_load

# Create custom fields that:
# - Strip HTML from text inputs
# - Validate against SQL injection patterns
# - Limit input sizes
# - Sanitize file uploads
class SanitizedString(fields.String):
```

### Step 18: Implement Rate Limiting

```python
# Add rate limiting to prevent abuse
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

# Configure rate limits:
# - 100 requests per minute per IP
# - 10 login attempts per hour
# - 1000 API calls per day per user
limiter = Limiter(
    app,
    key_func=get_remote_address,
    default_limits=["100 per minute"]
)
```

## 🧪 Partee 7: Avançado Testing

### Step 19: Add Load Testing

Create load tests using locust:

```python
# locustfile.py
from locust import HttpUser, task, between
import random

class TaskAPIUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        """Login and get auth token."""
        response = self.client.post("/auth/login", json={
            "username": "testuser",
            "password": "testpass"
        })
        self.token = response.json()["access_token"]
        self.headers = {{"Authorization": f"Bearer {{self.token}}"}}
    
    @task(3)
    def list_tasks(self):
        """Test listing tasks with various filters."""
        filters = ["", "?status=pending", "?assignee_id=1", "?page=2"]
        self.client.get(f"/tasks{random.choice(filters)}", headers=self.headers)
    
    @task(2)
    def create_task(self):
        """Test creating tasks."""
        self.client.post("/tasks", headers=self.headers, json={
            "title": f"Load test task {{random.randint(1, 1000)}}",
            "description": "Created by load test",
            "project_id": random.randint(1, 5)
        })
    
    @task(1)
    def update_task(self):
        """Test updating tasks."""
        task_id = random.randint(1, 100)
        self.client.put(f"/tasks/{task_id}", headers=self.headers, json={
            "status": random.choice(["pending", "in_progress", "completed"])
        })
```

### Step 20: Add Contract Testing

Test API contracts with Pact:

```python
# test_contracts.py
from pact import Consumer, Provider

# Define API contracts:
# - Request/response schemas
# - Status codes
# - Header requirements
# - Error formats
def test_task_api_contract():
```

**🤖 Copilot Prompt Suggestion #11:**
"Create Pact contract tests defining consumer expectations for task CRUD operations, response schemas, error structures, and header requirements"

## 📈 Partee 8: Performance Analysis

### Step 21: Perfil Database Queries

Add query profiling:

```python
# Add SQLAlchemy query profiling
from flask_sqlalchemy import get_debug_queries
import logging

def log_slow_queries(app):
    """Log queries that take too long."""
    @app.after_request
    def after_request(response):
        for query in get_debug_queries():
            if query.duration &gt;= 0.5:  # 500ms threshold
                app.logger.warning('slow_query', extra={
                    'duration': query.duration,
                    'sql': query.statement,
                    'parameters': query.parameters,
                    'context': query.context
                })
        return response
```

### Step 22: Optimize Critical Paths

Identify and optimize the slowest endpoints:

```python
# Performance optimizations:
# 1. Add database connection pooling
# 2. Implement query result caching
# 3. Use async tasks for heavy operations
# 4. Add CDN for static assets

# Example: Optimize task search
@tasks_bp.route('/tasks/search')
def search_tasks():
    """Optimized task search with full-text search."""
    query = request.args.get('q', '')
    
    # Use PostgreSQL full-text search
    sql = text("""
        SELECT * FROM tasks 
        WHERE to_tsvector('english', title || ' ' || description) 
        @@ plainto_tsquery('english', :query)
        ORDER BY ts_rank(
            to_tsvector('english', title || ' ' || description),
            plainto_tsquery('english', :query)
        ) DESC
        LIMIT 20
    """)
    
    results = db.session.execute(sql, {{'query': query}})
    return jsonify([dict(row) for row in results])
```

## 🎯 Final Integration

### Step 23: Completar Test Suite

Create a comprehensive test that verifies all fixes:

```python
# test_integration.py
import pytest
import concurrent.futures
from datetime import datetime, timedelta

class TestCompleteAPIFlow:
    """Test the complete API with all fixes applied."""
    
    def test_concurrent_operations(self, client, auth_headers):
        """Test API handles concurrent requests correctly."""
        project_id = create_test_project(client, auth_headers)
        
        # Create tasks concurrently
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            futures = []
            for i in range(50):
                future = executor.submit(
                    create_task_async,
                    client,
                    auth_headers,
                    f"Concurrent task {i}",
                    project_id
                )
                futures.append(future)
            
            # Wait for all tasks to complete
            results = [f.result() for f in futures]
        
        # Verify all tasks were created
        response = client.get(
            f'/tasks?project_id={project_id}',
            headers=auth_headers
        )
        assert response.status_code == 200
        assert len(response.json['tasks']) == 50
    
    def test_performance_under_load(self, client, auth_headers):
        """Test API maintains performance under load."""
        import time
        
        # Measure baseline
        start = time.time()
        response = client.get('/tasks', headers=auth_headers)
        baseline = time.time() - start
        
        # Create many tasks
        for i in range(1000):
            create_task(client, auth_headers, f"Load task {i}")
        
        # Measure performance with load
        start = time.time()
        response = client.get('/tasks?page=1&per_page=50', headers=auth_headers)
        loaded = time.time() - start
        
        # Performance should not degrade more than 2x
        assert loaded &lt; baseline * 2
        assert response.status_code == 200
    
    def test_security_measures(self, client):
        """Test all security measures are working."""
        # Test rate limiting
        for i in range(150):
            response = client.get('/tasks')
            if i &gt; 100:
                assert response.status_code == 429  # Too Many Requests
        
        # Test SQL injection protection
        response = client.get("/tasks?status='; DROP TABLE tasks; --")
        assert response.status_code in [200, 400]  # Not 500
        
        # Test XSS protection
        response = client.post('/tasks', json={
            'title': '<script>alert("XSS")</script>',
            'description': 'Test',
            'project_id': 1
        })
        # Verify HTML is escaped in response
        assert '<script>' not in response.get_data(as_text=True)
```

### Step 24: Generate Performance Report

Create a script to measure improvements:

```python
# benchmark.py
import time
import statistics
import requests
from concurrent.futures import ThreadPoolExecutor

def benchmark_endpoint(url, method='GET', data=None, iterations=100):
    """Benchmark an endpoint."""
    times = []
    
    for _ in range(iterations):
        start = time.time()
        if method == 'GET':
            response = requests.get(url)
        elif method == 'POST':
            response = requests.post(url, json=data)
        duration = time.time() - start
        times.append(duration)
    
    return {
        'mean': statistics.mean(times),
        'median': statistics.median(times),
        'stdev': statistics.stdev(times),
        'min': min(times),
        'max': max(times),
        'p95': sorted(times)[int(0.95 * len(times))]
    }

# Run benchmarks
print("Performance Improvements:")
print("=========================")
print("Endpoint: GET /tasks")
print("Before: Mean 850ms, P95 1200ms")
results = benchmark_endpoint('http://localhost:5000/tasks')
print(f"After: Mean {results['mean']*1000:.0f}ms, P95 {results['p95']*1000:.0f}ms")
```

## ✅ Exercício Completion Verificarlist

### Bugs Fixed
- [ ] Request validation implemented
- [ ] N+1 queries eliminated
- [ ] SQL injection vulnerability patched
- [ ] Error handling added throughout
- [ ] Status validation enforced
- [ ] Null pointer errors fixed

### Tests Added
- [ ] Coverage increased to 95%+
- [ ] Integration tests implemented
- [ ] Load tests created
- [ ] Contract tests defined
- [ ] Security tests added

### Performance Optimized
- [ ] Database indexes added
- [ ] Caching implemented
- [ ] Query optimization completed
- [ ] Connection pooling configurado
- [ ] Monitoring added

### produção Ready
- [ ] Structured logging implemented
- [ ] Health checks added
- [ ] Authentication/authorization working
- [ ] Rate limiting configurado
- [ ] Security hardening complete

## 🎉 Congratulations!

You've successfully:
- 🐛 Debugged a complex API with multiple issues
- 🧪 Achieved 95%+ test coverage
- ⚡ Optimized performance by 5x
- 🔒 Implemented produção-grade security
- 📊 Added comprehensive monitoring

---

**Ready for the Module 4 Project?** Apply everything you've learned to build your own tested application!