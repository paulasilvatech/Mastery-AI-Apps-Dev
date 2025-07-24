---
sidebar_position: 5
title: "Exercise 1: Part 2"
description: "## 🚀 Part 2: API Implementation and Testing"
---

# Exercício 1: Building a RESTful Task Management API (Partee 2)

## 🚀 Partee 2: API Implementation and Testing

### Step 6: Implement API Endpoints

Create `app/api/v1/tasks.py` with the complete REST API:

**Copilot Prompt Suggestion:**
```python
# Create a FastAPI router for tasks with these endpoints:
# - GET /tasks - List tasks with pagination, filtering by status/priority
# - POST /tasks - Create a new task
# - GET /tasks/{task_id} - Get a single task
# - PUT /tasks/{task_id} - Update a task
# - DELETE /tasks/{task_id} - Delete a task
# - GET /tasks/stats - Get task statistics
# Include proper error handling, status codes, and async database operations
```

**Expected Output:**
```python
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from typing import Optional, List
from uuid import UUID
import logging

from app.database import get_db
from app.models.task import Task, TaskStatus, TaskPriority
from app.schemas.task import (
    TaskCreate, TaskUpdate, TaskResponse, 
    TaskListResponse, TaskStatus as SchemaTaskStatus,
    TaskPriority as SchemaTaskPriority
)

router = APIRouter()
logger = logging.getLogger(__name__)

@router.get("/tasks", response_model=TaskListResponse)
async def list_tasks(
    page: int = Query(1, ge=1, description="Page number"),
    size: int = Query(10, ge=1, le=100, description="Page size"),
    status: Optional[SchemaTaskStatus] = Query(None, description="Filter by status"),
    priority: Optional[SchemaTaskPriority] = Query(None, description="Filter by priority"),
    db: AsyncSession = Depends(get_db)
):
    """
    List all tasks with pagination and optional filtering.
    """
    # Build query
    query = select(Task)
    count_query = select(func.count(Task.id))
    
    # Apply filters
    filters = []
    if status:
        filters.append(Task.status == status)
    if priority:
        filters.append(Task.priority == priority)
    
    if filters:
        query = query.where(and_(*filters))
        count_query = count_query.where(and_(*filters))
    
    # Get total count
    total_result = await db.execute(count_query)
    total = total_result.scalar()
    
    # Apply pagination
    query = query.offset((page - 1) * size).limit(size)
    query = query.order_by(Task.created_at.desc())
    
    # Execute query
    result = await db.execute(query)
    tasks = result.scalars().all()
    
    # Calculate pages
    pages = (total + size - 1) // size
    
    return TaskListResponse(
        items=[TaskResponse.from_orm(task) for task in tasks],
        total=total,
        page=page,
        size=size,
        pages=pages
    )

@router.post("/tasks", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
async def create_task(
    task_data: TaskCreate,
    db: AsyncSession = Depends(get_db)
):
    """
    Create a new task.
    """
    task = Task(**task_data.dict())
    db.add(task)
    
    try:
        await db.commit()
        await db.refresh(task)
        logger.info(f"Created task: {task.id}")
        return TaskResponse.from_orm(task)
    except Exception as e:
        await db.rollback()
        logger.error(f"Error creating task: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error creating task"
        )

@router.get("/tasks/stats")
async def get_task_stats(db: AsyncSession = Depends(get_db)):
    """
    Get task statistics.
    """
    # Count by status
    status_counts = await db.execute(
        select(Task.status, func.count(Task.id))
        .group_by(Task.status)
    )
    status_stats = {status: count for status, count in status_counts}
    
    # Count by priority
    priority_counts = await db.execute(
        select(Task.priority, func.count(Task.id))
        .group_by(Task.priority)
    )
    priority_stats = {priority: count for priority, count in priority_counts}
    
    # Overdue tasks
    from datetime import datetime
    overdue_count = await db.execute(
        select(func.count(Task.id))
        .where(and_(
            Task.due_date &lt; datetime.now(),
            Task.status != TaskStatus.COMPLETED
        ))
    )
    
    return {
        "total_tasks": sum(status_stats.values()),
        "by_status": status_stats,
        "by_priority": priority_stats,
        "overdue": overdue_count.scalar()
    }

@router.get("/tasks/{task_id}", response_model=TaskResponse)
async def get_task(
    task_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """
    Get a single task by ID.
    """
    result = await db.execute(select(Task).where(Task.id == task_id))
    task = result.scalar_one_or_none()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task {task_id} not found"
        )
    
    return TaskResponse.from_orm(task)

@router.put("/tasks/{task_id}", response_model=TaskResponse)
async def update_task(
    task_id: UUID,
    task_update: TaskUpdate,
    db: AsyncSession = Depends(get_db)
):
    """
    Update a task.
    """
    result = await db.execute(select(Task).where(Task.id == task_id))
    task = result.scalar_one_or_none()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task {task_id} not found"
        )
    
    # Update only provided fields
    update_data = task_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(task, field, value)
    
    try:
        await db.commit()
        await db.refresh(task)
        logger.info(f"Updated task: {task_id}")
        return TaskResponse.from_orm(task)
    except Exception as e:
        await db.rollback()
        logger.error(f"Error updating task: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error updating task"
        )

@router.delete("/tasks/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_task(
    task_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """
    Delete a task.
    """
    result = await db.execute(select(Task).where(Task.id == task_id))
    task = result.scalar_one_or_none()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task {task_id} not found"
        )
    
    await db.delete(task)
    
    try:
        await db.commit()
        logger.info(f"Deleted task: {task_id}")
    except Exception as e:
        await db.rollback()
        logger.error(f"Error deleting task: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error deleting task"
        )
```

### Step 7: Create Comprehensive Tests

Create `tests/test_tasks.py`:

**Copilot Prompt Suggestion:**
```python
# Create comprehensive tests for the task API:
# - Test all CRUD operations
# - Test pagination and filtering
# - Test validation errors
# - Test edge cases (non-existent IDs, invalid data)
# - Use pytest fixtures for test database
# - Include async test support
```

**Expected Output:**
```python
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from app.main import app
from app.models.task import Base
from app.database import get_db
import uuid
from datetime import datetime, timedelta

# Test database setup
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

@pytest.fixture
async def test_db():
    engine = create_async_engine(TEST_DATABASE_URL, echo=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async def override_get_db():
        async with async_session() as session:
            yield session
    
    app.dependency_overrides[get_db] = override_get_db
    yield
    app.dependency_overrides.clear()

@pytest.fixture
async def client(test_db):
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

@pytest.mark.asyncio
async def test_create_task(client):
    """Test creating a new task."""
    task_data = {
        "title": "Test Task",
        "description": "Test Description",
        "priority": "high",
        "due_date": (datetime.now() + timedelta(days=1)).isoformat()
    }
    
    response = await client.post("/api/v1/tasks", json=task_data)
    assert response.status_code == 201
    
    data = response.json()
    assert data["title"] == task_data["title"]
    assert data["description"] == task_data["description"]
    assert data["priority"] == task_data["priority"]
    assert data["status"] == "pending"
    assert "id" in data
    assert "created_at" in data

@pytest.mark.asyncio
async def test_list_tasks(client):
    """Test listing tasks with pagination."""
    # Create multiple tasks
    for i in range(15):
        await client.post("/api/v1/tasks", json={
            "title": f"Task {{i}}",
            "priority": ["low", "medium", "high"][i % 3]
        })
    
    # Test pagination
    response = await client.get("/api/v1/tasks?page=1&size=10")
    assert response.status_code == 200
    
    data = response.json()
    assert len(data["items"]) == 10
    assert data["total"] == 15
    assert data["pages"] == 2
    assert data["page"] == 1

@pytest.mark.asyncio
async def test_filter_tasks(client):
    """Test filtering tasks by status and priority."""
    # Create tasks with different statuses and priorities
    tasks = [
        {{"title": "Task 1", "status": "pending", "priority": "high"}},
        {{"title": "Task 2", "status": "in_progress", "priority": "medium"}},
        {{"title": "Task 3", "status": "completed", "priority": "low"}},
        {{"title": "Task 4", "status": "pending", "priority": "high"}},
    ]
    
    for task in tasks:
        await client.post("/api/v1/tasks", json=task)
    
    # Filter by status
    response = await client.get("/api/v1/tasks?status=pending")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 2
    assert all(item["status"] == "pending" for item in data["items"])
    
    # Filter by priority
    response = await client.get("/api/v1/tasks?priority=high")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 2
    assert all(item["priority"] == "high" for item in data["items"])

@pytest.mark.asyncio
async def test_get_task(client):
    """Test getting a single task."""
    # Create a task
    create_response = await client.post("/api/v1/tasks", json={{"title": "Test Task"}})
    task_id = create_response.json()["id"]
    
    # Get the task
    response = await client.get(f"/api/v1/tasks/{task_id}")
    assert response.status_code == 200
    assert response.json()["id"] == task_id

@pytest.mark.asyncio
async def test_get_nonexistent_task(client):
    """Test getting a non-existent task."""
    fake_id = str(uuid.uuid4())
    response = await client.get(f"/api/v1/tasks/{fake_id}")
    assert response.status_code == 404

@pytest.mark.asyncio
async def test_update_task(client):
    """Test updating a task."""
    # Create a task
    create_response = await client.post("/api/v1/tasks", json={{"title": "Original Title"}})
    task_id = create_response.json()["id"]
    
    # Update the task
    update_data = {
        "title": "Updated Title",
        "status": "in_progress",
        "priority": "high"
    }
    response = await client.put(f"/api/v1/tasks/{task_id}", json=update_data)
    assert response.status_code == 200
    
    data = response.json()
    assert data["title"] == "Updated Title"
    assert data["status"] == "in_progress"
    assert data["priority"] == "high"

@pytest.mark.asyncio
async def test_delete_task(client):
    """Test deleting a task."""
    # Create a task
    create_response = await client.post("/api/v1/tasks", json={{"title": "To Delete"}})
    task_id = create_response.json()["id"]
    
    # Delete the task
    response = await client.delete(f"/api/v1/tasks/{task_id}")
    assert response.status_code == 204
    
    # Verify it's deleted
    response = await client.get(f"/api/v1/tasks/{task_id}")
    assert response.status_code == 404

@pytest.mark.asyncio
async def test_task_stats(client):
    """Test task statistics endpoint."""
    # Create tasks with various statuses
    tasks = [
        {{"title": "Task 1", "status": "pending"}},
        {{"title": "Task 2", "status": "pending"}},
        {{"title": "Task 3", "status": "in_progress"}},
        {{"title": "Task 4", "status": "completed"}},
        {"title": "Overdue", "status": "pending", 
         "due_date": (datetime.now() - timedelta(days=1)).isoformat()},
    ]
    
    for task in tasks:
        await client.post("/api/v1/tasks", json=task)
    
    response = await client.get("/api/v1/tasks/stats")
    assert response.status_code == 200
    
    stats = response.json()
    assert stats["total_tasks"] == 5
    assert stats["by_status"]["pending"] == 3
    assert stats["by_status"]["in_progress"] == 1
    assert stats["by_status"]["completed"] == 1
    assert stats["overdue"] == 1

@pytest.mark.asyncio
async def test_validation_errors(client):
    """Test validation errors."""
    # Empty title
    response = await client.post("/api/v1/tasks", json={{"title": ""}})
    assert response.status_code == 422
    
    # Invalid status
    response = await client.post("/api/v1/tasks", json={
        "title": "Test",
        "status": "invalid_status"
    })
    assert response.status_code == 422
    
    # Past due date
    response = await client.post("/api/v1/tasks", json={
        "title": "Test",
        "due_date": (datetime.now() - timedelta(days=1)).isoformat()
    })
    assert response.status_code == 422
```

### Step 8: Run and Test Your API

1. **Start the API server:**
```bash
uvicorn app.main:app --reload
```

2. **Run the tests:**
```bash
pytest tests/test_tasks.py -v
```

3. **Explore the API documentation:**
- Abrir http://localhost:8000/api/docs for Swagger UI
- Abrir http://localhost:8000/api/redoc for ReDoc

### Step 9: Performance Optimizations

Add these optimizations to your API:

**Copilot Prompt Suggestion:**
```python
# Add performance optimizations:
# - Response caching for stats endpoint
# - Database query optimization with eager loading
# - Request rate limiting
# - Response compression
```

Create `app/middleware/cache.py`:
```python
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
import hashlib
import json
from typing import Dict, Optional
import time

class CacheMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, cache_ttl: int = 60):
        super().__init__(app)
        self.cache: Dict[str, tuple] = {}
        self.cache_ttl = cache_ttl
    
    async def dispatch(self, request: Request, call_next):
        # Only cache GET requests
        if request.method != "GET":
            return await call_next(request)
        
        # Create cache key
        cache_key = f"{request.method}:{request.url.path}:{request.url.query}"
        
        # Check cache
        if cache_key in self.cache:
            cached_response, timestamp = self.cache[cache_key]
            if time.time() - timestamp &lt; self.cache_ttl:
                return Response(
                    content=cached_response,
                    media_type="application/json",
                    headers={{"X-Cache": "HIT"}}
                )
        
        # Process request
        response = await call_next(request)
        
        # Cache successful responses
        if response.status_code == 200:
            body = b""
            async for chunk in response.body_iterator:
                body += chunk
            
            self.cache[cache_key] = (body, time.time())
            
            return Response(
                content=body,
                media_type=response.media_type,
                headers=dict(response.headers, **{{"X-Cache": "MISS"}})
            )
        
        return response
```

## 🎉 Exercício Completar!

Congratulations! You've successfully built a complete RESTful API with:

- ✅ Full CRUD operations
- ✅ Pagination and filtering
- ✅ Input validation
- ✅ Error handling
- ✅ Automatic documentation
- ✅ Comprehensive tests
- ✅ Performance optimizations

## 📊 Success Criteria

Your implementation should:
- Pass all tests (100% coverage)
- Handle 1000+ requests/second
- Validate all inputs properly
- Return appropriate HTTP status codes
- Generate complete API documentation

## 🚀 Extension Challenges

Try these additional features:
1. Add authentication with JWT tokens
2. Implement task search functionality
3. Add task tags/categories
4. Create batch operations endpoint
5. Add WebSocket support for real-time updates

## 📚 Key Takeaways

- **RESTful Design**: Recursos, HTTP verbs, and status codes
- **FastAPI Features**: Automatic validation, documentation, and async support
- **Testing**: Comprehensive test coverage ensures reliability
- **Performance**: Caching and optimization techniques
- **AI Assistance**: Copilot speeds up boilerplate code generation

---

Ready for the next challenge? Move on to [Exercise 2: GraphQL API](../exercise2-graphql-api/instructions.md)!