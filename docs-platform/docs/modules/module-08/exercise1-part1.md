---
sidebar_position: 4
title: "Exercise 1: Part 1"
description: "## 📋 Overview"
---

# Exercise 1: Building a RESTful Task Management API (⭐ Easy)

## 📋 Overview

In this exercise, you'll build a complete RESTful API for a task management system using FastAPI and GitHub Copilot. You'll implement CRUD operations, proper HTTP semantics, input validation, and automatic API documentation.

**Duration:** 30-45 minutes  
**Difficulty:** ⭐ Easy  
**Success Rate:** 95%

## 🎯 Learning Objectives

By completing this exercise, you will:
- Design RESTful endpoints following best practices
- Implement CRUD operations with FastAPI
- Use Copilot to generate API boilerplate efficiently
- Add input validation and error handling
- Generate automatic API documentation
- Write comprehensive API tests

## 📐 API Design

Your Task Management API will support these resources:

```
/api/v1/tasks
├── GET     /tasks          # List all tasks (with pagination)
├── POST    /tasks          # Create a new task
├── GET     /tasks/{id}     # Get a specific task
├── PUT     /tasks/{id}     # Update a task
├── DELETE  /tasks/{id}     # Delete a task
└── GET     /tasks/stats    # Get task statistics
```

### Task Model
```json
{
  "id": "uuid",
  "title": "string",
  "description": "string",
  "status": "pending | in_progress | completed",
  "priority": "low | medium | high",
  "due_date": "datetime",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

## 🚀 Part 1: Setup and Basic Structure

### Step 1: Project Setup

1. Create the project structure:
```bash
cd exercises/exercise1-rest-api
mkdir -p app/api/v1
mkdir -p app/models
mkdir -p app/schemas
mkdir -p tests
```

2. Initialize the project files:
```bash
touch app/__init__.py
touch app/main.py
touch app/models/__init__.py
touch app/models/task.py
touch app/schemas/__init__.py
touch app/schemas/task.py
touch app/api/__init__.py
touch app/api/v1/__init__.py
touch app/api/v1/tasks.py
```

### Step 2: Create the Task Model

Open `app/models/task.py` and use this Copilot prompt:

**Copilot Prompt Suggestion:**
```python
# Create a SQLAlchemy model for tasks with:
# - UUID primary key
# - title (required, max 200 chars)
# - description (optional, text)
# - status enum (pending, in_progress, completed)
# - priority enum (low, medium, high)
# - due_date (optional datetime)
# - created_at and updated_at timestamps
# Include proper indexes and constraints
```

**Expected Output:**
```python
from sqlalchemy import Column, String, Text, DateTime, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql import func
import uuid
import enum
from datetime import datetime

Base = declarative_base()

class TaskStatus(str, enum.Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"

class TaskPriority(str, enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"

class Task(Base):
    __tablename__ = "tasks"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String(200), nullable=False, index=True)
    description = Column(Text, nullable=True)
    status = Column(SQLEnum(TaskStatus), default=TaskStatus.PENDING, nullable=False)
    priority = Column(SQLEnum(TaskPriority), default=TaskPriority.MEDIUM, nullable=False)
    due_date = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), server_default=func.now())
    
    # Add indexes for common queries
    __table_args__ = (
        Index('idx_status_priority', 'status', 'priority'),
        Index('idx_due_date', 'due_date'),
    )
```

### Step 3: Create Pydantic Schemas

Open `app/schemas/task.py` and use this prompt:

**Copilot Prompt Suggestion:**
```python
# Create Pydantic schemas for the task API:
# - TaskBase: shared properties
# - TaskCreate: for creating tasks (no id, timestamps)
# - TaskUpdate: for updates (all fields optional)
# - TaskResponse: for API responses (includes all fields)
# - TaskListResponse: paginated list with metadata
# Include validation for title length, valid enums, and future due dates
```

**Expected Output:**
```python
from pydantic import BaseModel, Field, validator
from typing import Optional, List
from datetime import datetime
from uuid import UUID
from enum import Enum

class TaskStatus(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress" 
    COMPLETED = "completed"

class TaskPriority(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"

class TaskBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = None
    status: TaskStatus = TaskStatus.PENDING
    priority: TaskPriority = TaskPriority.MEDIUM
    due_date: Optional[datetime] = None
    
    @validator('due_date')
    def due_date_must_be_future(cls, v):
        if v and v &lt; datetime.now():
            raise ValueError('Due date must be in the future')
        return v

class TaskCreate(TaskBase):
    pass

class TaskUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = None
    status: Optional[TaskStatus] = None
    priority: Optional[TaskPriority] = None
    due_date: Optional[datetime] = None
    
    @validator('due_date')
    def due_date_must_be_future(cls, v):
        if v and v &lt; datetime.now():
            raise ValueError('Due date must be in the future')
        return v

class TaskResponse(TaskBase):
    id: UUID
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class TaskListResponse(BaseModel):
    items: List[TaskResponse]
    total: int
    page: int
    size: int
    pages: int
```

### Step 4: Database Configuration

Create `app/database.py`:

**Copilot Prompt Suggestion:**
```python
# Create database configuration for FastAPI:
# - Support both SQLite (development) and PostgreSQL (production)
# - Create async session factory
# - Include database initialization function
# - Add connection pooling for production
# Use environment variables for configuration
```

**Expected Output:**
```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import NullPool
import os
from app.models.task import Base

# Database URL from environment
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./test.db")

# Convert postgres:// to postgresql:// for compatibility
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# Create async engine
engine = create_async_engine(
    DATABASE_URL,
    echo=True if os.getenv("API_ENV") == "development" else False,
    poolclass=NullPool if "sqlite" in DATABASE_URL else None,
)

# Create async session factory
async_session = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False
)

# Database initialization
async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

# Dependency to get database session
async def get_db():
    async with async_session() as session:
        try:
            yield session
        finally:
            await session.close()
```

### Step 5: Main Application Setup

Create `app/main.py`:

**Copilot Prompt Suggestion:**
```python
# Create the main FastAPI application:
# - Configure CORS for development
# - Add startup event to initialize database
# - Include API router with /api/v1 prefix
# - Add health check endpoint
# - Configure OpenAPI documentation
# - Add global exception handlers
# Include proper logging setup
```

**Expected Output:**
```python
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import logging
import os
from app.database import init_db
from app.api.v1 import tasks

# Configure logging
logging.basicConfig(
    level=logging.INFO if os.getenv("API_ENV") != "production" else logging.WARNING,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting up...")
    await init_db()
    yield
    # Shutdown
    logger.info("Shutting down...")

# Create FastAPI app
app = FastAPI(
    title="Task Management API",
    description="A RESTful API for managing tasks built with FastAPI",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if os.getenv("API_ENV") == "development" else os.getenv("ALLOWED_ORIGINS", "").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Global exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={{"detail": "Internal server error"}}
    )

# Health check endpoint
@app.get("/health")
async def health_check():
    return {{"status": "healthy", "service": "task-api"}}

# Include routers
app.include_router(tasks.router, prefix="/api/v1", tags=["tasks"])
```

## 📝 Progress Check

At this point, you should have:
- ✅ Project structure created
- ✅ Task model defined with SQLAlchemy
- ✅ Pydantic schemas for validation
- ✅ Database configuration
- ✅ Main FastAPI application setup

## 🎯 Next Steps

Continue to [Part 2](./exercise1-part2) where you'll:
- Implement the REST API endpoints
- Add pagination and filtering
- Create comprehensive tests
- Add performance optimizations

---

**Tips for Success:**
- Let Copilot help with boilerplate code
- Focus on understanding the patterns
- Test each component as you build
- Refer to FastAPI docs when needed