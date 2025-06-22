# Exercise 3: Complete Application (⭐⭐⭐ Hard) - Part 1

## 🎯 Exercise Overview

**Duration**: 60-90 minutes  
**Difficulty**: ⭐⭐⭐ (Hard)  
**Success Rate**: 60%

In this advanced exercise, you'll build a full-featured web-based task management system with a REST API, web interface, real-time updates, and deployment configuration. This production-ready application demonstrates professional development practices with AI assistance.

## 🎓 Learning Objectives

By completing this exercise, you will:
- Build a complete web application with Copilot
- Create RESTful APIs with authentication
- Implement real-time features
- Deploy a production-ready application
- Use AI for complex architectural decisions

## 📋 Prerequisites

- ✅ Completed Exercises 1 and 2
- ✅ Understanding of web concepts
- ✅ Basic knowledge of async programming
- ✅ Familiarity with REST APIs

## 🏗️ What You'll Build

A **Complete Task Management System** with:
- RESTful API with FastAPI
- Web interface with real-time updates
- User authentication and authorization
- Database persistence with SQLite/PostgreSQL
- WebSocket support for live updates
- Docker deployment configuration
- Comprehensive monitoring

## 📁 Project Structure

```
exercise3-hard/
├── README.md               # This file
├── instructions/
│   ├── part1.md           # API and database (this file)
│   ├── part2.md           # Web interface and real-time
│   └── part3.md           # Deployment and monitoring
├── starter/
│   ├── backend/
│   │   ├── app/
│   │   │   ├── __init__.py
│   │   │   ├── main.py
│   │   │   ├── models/
│   │   │   ├── api/
│   │   │   ├── core/
│   │   │   └── db/
│   │   └── requirements.txt
│   ├── frontend/
│   │   ├── index.html
│   │   ├── style.css
│   │   └── app.js
│   └── docker/
├── solution/
│   └── [complete application]
└── resources/
    ├── api-design.md
    └── deployment-guide.md
```

## 🚀 Part 1: Building the API and Database Layer

### Step 1: Setting Up FastAPI Application

Let's create a modern, async API using FastAPI. Open `starter/backend/app/main.py`:

**🤖 Copilot Prompt Suggestion #1:**
```python
# Create a FastAPI application with:
# - CORS middleware for browser access
# - Exception handlers for proper error responses
# - Startup/shutdown events for database
# - API documentation with proper tags
# - Health check endpoint
# - Version prefix for all routes (/api/v1)
# Include proper logging setup
```

Start with the basic setup:
```python
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import logging
import uvicorn
from contextlib import asynccontextmanager
```

**Expected Output:**
```python
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
import logging
import uvicorn
from contextlib import asynccontextmanager
import sys
from typing import Any

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Lifespan context manager for startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Handle application startup and shutdown."""
    # Startup
    logger.info("Starting up Task Management API...")
    
    # Initialize database
    from app.db.database import init_db
    await init_db()
    
    # Initialize other services
    logger.info("API startup complete")
    
    yield
    
    # Shutdown
    logger.info("Shutting down Task Management API...")
    
    # Close database connections
    from app.db.database import close_db
    await close_db()
    
    logger.info("API shutdown complete")

# Create FastAPI app
app = FastAPI(
    title="Task Management API",
    description="A comprehensive task management system with real-time updates",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global exception handlers
@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    """Handle HTTP exceptions."""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "message": exc.detail,
                "type": "http_error",
                "status_code": exc.status_code
            }
        }
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle validation errors."""
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": {
                "message": "Validation error",
                "type": "validation_error",
                "details": exc.errors()
            }
        }
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Handle unexpected errors."""
    logger.error(f"Unexpected error: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": {
                "message": "An unexpected error occurred",
                "type": "internal_error"
            }
        }
    )

# Health check endpoint
@app.get("/health", tags=["System"])
async def health_check():
    """Check if the API is running."""
    return {
        "status": "healthy",
        "version": "1.0.0",
        "service": "task-management-api"
    }

# Include routers
from app.api.v1 import tasks, users, auth, websocket

app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/api/v1/users", tags=["Users"])
app.include_router(tasks.router, prefix="/api/v1/tasks", tags=["Tasks"])
app.include_router(websocket.router, prefix="/ws", tags=["WebSocket"])

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
```

### Step 2: Create Database Models

Create `starter/backend/app/models/database.py` for SQLAlchemy models:

**🤖 Copilot Prompt Suggestion #2:**
```python
# Create SQLAlchemy models for:
# - User: id, email, username, hashed_password, is_active, created_at
# - Task: id, title, description, status, priority, due_date, user_id, created_at, updated_at
# - Tag: id, name, color
# - TaskTag: many-to-many relationship
# Use proper relationships, indexes, and constraints
# Include model mixins for common fields
```

**Expected Output:**
```python
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Table, Enum as SQLEnum, Text, Index
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime
import enum
import uuid

Base = declarative_base()

# Enums
class TaskStatus(str, enum.Enum):
    TODO = "todo"
    IN_PROGRESS = "in_progress"
    DONE = "done"
    ARCHIVED = "archived"

class TaskPriority(str, enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    URGENT = "urgent"

# Association table for many-to-many relationship
task_tags = Table(
    'task_tags',
    Base.metadata,
    Column('task_id', String, ForeignKey('tasks.id', ondelete='CASCADE')),
    Column('tag_id', Integer, ForeignKey('tags.id', ondelete='CASCADE')),
    Index('idx_task_tags', 'task_id', 'tag_id', unique=True)
)

# Mixins
class TimestampMixin:
    """Add created_at and updated_at timestamps."""
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

class User(Base, TimestampMixin):
    """User model."""
    __tablename__ = 'users'
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String(255), unique=True, nullable=False, index=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    hashed_password = Column(String, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    is_superuser = Column(Boolean, default=False, nullable=False)
    
    # Relationships
    tasks = relationship("Task", back_populates="user", cascade="all, delete-orphan")
    
    # Indexes
    __table_args__ = (
        Index('idx_user_email_active', 'email', 'is_active'),
    )
    
    def __repr__(self):
        return f"<User(id={self.id}, username={self.username})>"

class Task(Base, TimestampMixin):
    """Task model."""
    __tablename__ = 'tasks'
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    status = Column(SQLEnum(TaskStatus), default=TaskStatus.TODO, nullable=False, index=True)
    priority = Column(SQLEnum(TaskPriority), default=TaskPriority.MEDIUM, nullable=False, index=True)
    due_date = Column(DateTime(timezone=True), nullable=True, index=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    
    # Foreign keys
    user_id = Column(String, ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True)
    
    # Relationships
    user = relationship("User", back_populates="tasks")
    tags = relationship("Tag", secondary=task_tags, back_populates="tasks")
    
    # Indexes for common queries
    __table_args__ = (
        Index('idx_task_user_status', 'user_id', 'status'),
        Index('idx_task_user_priority', 'user_id', 'priority'),
        Index('idx_task_due_date', 'due_date'),
    )
    
    @property
    def is_overdue(self):
        """Check if task is overdue."""
        if self.due_date and self.status not in [TaskStatus.DONE, TaskStatus.ARCHIVED]:
            return datetime.now() > self.due_date
        return False
    
    def __repr__(self):
        return f"<Task(id={self.id}, title={self.title}, status={self.status})>"

class Tag(Base):
    """Tag model."""
    __tablename__ = 'tags'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(50), unique=True, nullable=False, index=True)
    color = Column(String(7), default='#808080')  # Hex color
    
    # Relationships
    tasks = relationship("Task", secondary=task_tags, back_populates="tags")
    
    def __repr__(self):
        return f"<Tag(id={self.id}, name={self.name})>"
```

### Step 3: Create Pydantic Schemas

Create `starter/backend/app/models/schemas.py` for request/response models:

**🤖 Copilot Prompt Suggestion #3:**
```python
# Create Pydantic schemas for:
# - User schemas: UserCreate, UserUpdate, UserResponse, UserInDB
# - Task schemas: TaskCreate, TaskUpdate, TaskResponse, TaskFilter
# - Auth schemas: Token, TokenData, Login
# - Tag schemas: TagCreate, TagResponse
# Include validation, examples, and proper inheritance
# Use datetime handling and custom validators
```

**Expected Output:**
```python
from pydantic import BaseModel, EmailStr, Field, validator, ConfigDict
from typing import Optional, List, Any
from datetime import datetime
from enum import Enum
from app.models.database import TaskStatus, TaskPriority

# Base schemas
class BaseSchema(BaseModel):
    """Base schema with common configuration."""
    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
        use_enum_values=True,
        json_schema_extra={
            "example": {}
        }
    )

# User schemas
class UserBase(BaseSchema):
    """Base user schema."""
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50, pattern="^[a-zA-Z0-9_-]+$")
    is_active: bool = True

class UserCreate(UserBase):
    """Schema for creating a user."""
    password: str = Field(..., min_length=8, max_length=100)
    
    @validator('password')
    def validate_password(cls, v):
        """Validate password strength."""
        if not any(char.isdigit() for char in v):
            raise ValueError('Password must contain at least one digit')
        if not any(char.isupper() for char in v):
            raise ValueError('Password must contain at least one uppercase letter')
        if not any(char.islower() for char in v):
            raise ValueError('Password must contain at least one lowercase letter')
        return v
    
    model_config = ConfigDict(json_schema_extra={
        "example": {
            "email": "user@example.com",
            "username": "johndoe",
            "password": "SecurePass123"
        }
    })

class UserUpdate(BaseSchema):
    """Schema for updating a user."""
    email: Optional[EmailStr] = None
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    password: Optional[str] = Field(None, min_length=8, max_length=100)
    is_active: Optional[bool] = None

class UserResponse(UserBase):
    """Schema for user response."""
    id: str
    created_at: datetime
    updated_at: datetime
    is_superuser: bool = False
    
    model_config = ConfigDict(json_schema_extra={
        "example": {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "email": "user@example.com",
            "username": "johndoe",
            "is_active": True,
            "is_superuser": False,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        }
    })

class UserInDB(UserResponse):
    """User schema with hashed password."""
    hashed_password: str

# Tag schemas
class TagBase(BaseSchema):
    """Base tag schema."""
    name: str = Field(..., min_length=1, max_length=50)
    color: str = Field(default="#808080", pattern="^#[0-9A-Fa-f]{6}$")

class TagCreate(TagBase):
    """Schema for creating a tag."""
    model_config = ConfigDict(json_schema_extra={
        "example": {
            "name": "urgent",
            "color": "#FF0000"
        }
    })

class TagResponse(TagBase):
    """Schema for tag response."""
    id: int
    
    model_config = ConfigDict(json_schema_extra={
        "example": {
            "id": 1,
            "name": "urgent",
            "color": "#FF0000"
        }
    })

# Task schemas
class TaskBase(BaseSchema):
    """Base task schema."""
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    status: TaskStatus = TaskStatus.TODO
    priority: TaskPriority = TaskPriority.MEDIUM
    due_date: Optional[datetime] = None
    
    @validator('title')
    def validate_title(cls, v):
        """Validate title is not just whitespace."""
        if not v.strip():
            raise ValueError('Title cannot be empty')
        return v.strip()

class TaskCreate(TaskBase):
    """Schema for creating a task."""
    tag_ids: Optional[List[int]] = []
    
    model_config = ConfigDict(json_schema_extra={
        "example": {
            "title": "Complete project documentation",
            "description": "Write comprehensive docs for the API",
            "status": "todo",
            "priority": "high",
            "due_date": "2024-12-31T23:59:59Z",
            "tag_ids": [1, 2]
        }
    })

class TaskUpdate(BaseSchema):
    """Schema for updating a task."""
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    status: Optional[TaskStatus] = None
    priority: Optional[TaskPriority] = None
    due_date: Optional[datetime] = None
    tag_ids: Optional[List[int]] = None

class TaskResponse(TaskBase):
    """Schema for task response."""
    id: str
    user_id: str
    tags: List[TagResponse] = []
    created_at: datetime
    updated_at: datetime
    completed_at: Optional[datetime] = None
    is_overdue: bool = False
    
    @validator('is_overdue', pre=False, always=True)
    def calculate_overdue(cls, v, values):
        """Calculate if task is overdue."""
        due_date = values.get('due_date')
        status = values.get('status')
        if due_date and status not in [TaskStatus.DONE, TaskStatus.ARCHIVED]:
            return datetime.now() > due_date
        return False
    
    model_config = ConfigDict(json_schema_extra={
        "example": {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "title": "Complete project documentation",
            "description": "Write comprehensive docs for the API",
            "status": "todo",
            "priority": "high",
            "due_date": "2024-12-31T23:59:59Z",
            "user_id": "user123",
            "tags": [{"id": 1, "name": "urgent", "color": "#FF0000"}],
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z",
            "completed_at": None,
            "is_overdue": False
        }
    })

class TaskFilter(BaseSchema):
    """Schema for filtering tasks."""
    status: Optional[TaskStatus] = None
    priority: Optional[TaskPriority] = None
    tag_ids: Optional[List[int]] = None
    is_overdue: Optional[bool] = None
    search: Optional[str] = None
    
# Auth schemas
class Token(BaseSchema):
    """Token response schema."""
    access_token: str
    token_type: str = "bearer"
    expires_in: int = 3600
    
    model_config = ConfigDict(json_schema_extra={
        "example": {
            "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
            "token_type": "bearer",
            "expires_in": 3600
        }
    })

class TokenData(BaseSchema):
    """Token data stored in JWT."""
    user_id: Optional[str] = None
    username: Optional[str] = None
    scopes: List[str] = []

class Login(BaseSchema):
    """Login request schema."""
    username: str
    password: str
    
    model_config = ConfigDict(json_schema_extra={
        "example": {
            "username": "johndoe",
            "password": "SecurePass123"
        }
    })

# Pagination
class PaginationParams(BaseSchema):
    """Pagination parameters."""
    page: int = Field(default=1, ge=1)
    per_page: int = Field(default=20, ge=1, le=100)
    
class PaginatedResponse(BaseSchema):
    """Paginated response wrapper."""
    items: List[Any]
    total: int
    page: int
    per_page: int
    pages: int
    
    @validator('pages', pre=False, always=True)
    def calculate_pages(cls, v, values):
        """Calculate total pages."""
        total = values.get('total', 0)
        per_page = values.get('per_page', 20)
        return (total + per_page - 1) // per_page if per_page > 0 else 0
```

### Step 4: Create Database Connection

Create `starter/backend/app/db/database.py`:

**🤖 Copilot Prompt Suggestion #4:**
```python
# Create async database configuration with:
# - SQLAlchemy async engine and session
# - Connection pooling configuration
# - Database URL from environment variables
# - Async context manager for sessions
# - Database initialization and migration functions
# Support both SQLite (development) and PostgreSQL (production)
```

**Expected Output:**
```python
import os
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import NullPool
from app.models.database import Base
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

# Database URL
if settings.ENVIRONMENT == "test":
    # Use in-memory SQLite for tests
    SQLALCHEMY_DATABASE_URL = "sqlite+aiosqlite:///:memory:"
elif settings.DATABASE_URL.startswith("sqlite"):
    # SQLite for development
    SQLALCHEMY_DATABASE_URL = settings.DATABASE_URL.replace("sqlite://", "sqlite+aiosqlite://")
else:
    # PostgreSQL for production
    SQLALCHEMY_DATABASE_URL = settings.DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://")

# Create async engine
engine = create_async_engine(
    SQLALCHEMY_DATABASE_URL,
    echo=settings.DEBUG,
    poolclass=NullPool if "sqlite" in SQLALCHEMY_DATABASE_URL else None,
    pool_size=5 if "postgresql" in SQLALCHEMY_DATABASE_URL else None,
    max_overflow=10 if "postgresql" in SQLALCHEMY_DATABASE_URL else None,
    pool_pre_ping=True,
    connect_args={"check_same_thread": False} if "sqlite" in SQLALCHEMY_DATABASE_URL else {},
)

# Create async session factory
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)

# Dependency to get database session
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    Get database session.
    
    Yields:
        Database session
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()

# Database lifecycle functions
async def init_db():
    """Initialize database tables."""
    try:
        async with engine.begin() as conn:
            # Create all tables
            await conn.run_sync(Base.metadata.create_all)
            logger.info("Database tables created successfully")
            
        # Create default data if needed
        await create_default_data()
        
    except Exception as e:
        logger.error(f"Error initializing database: {e}")
        raise

async def close_db():
    """Close database connections."""
    await engine.dispose()
    logger.info("Database connections closed")

async def create_default_data():
    """Create default data for the application."""
    async with AsyncSessionLocal() as session:
        # Check if we need to create default data
        from sqlalchemy import select
        from app.models.database import User, Tag
        
        # Check if admin user exists
        result = await session.execute(
            select(User).where(User.username == "admin")
        )
        admin = result.scalars().first()
        
        if not admin:
            # Create default admin user
            from app.core.auth import get_password_hash
            
            admin = User(
                username="admin",
                email="admin@example.com",
                hashed_password=get_password_hash("admin123"),
                is_superuser=True,
                is_active=True
            )
            session.add(admin)
            logger.info("Created default admin user")
        
        # Create default tags
        default_tags = [
            {"name": "work", "color": "#0066CC"},
            {"name": "personal", "color": "#00AA00"},
            {"name": "urgent", "color": "#FF0000"},
            {"name": "idea", "color": "#FFAA00"},
        ]
        
        for tag_data in default_tags:
            result = await session.execute(
                select(Tag).where(Tag.name == tag_data["name"])
            )
            if not result.scalars().first():
                tag = Tag(**tag_data)
                session.add(tag)
        
        await session.commit()
        logger.info("Default data created successfully")

# Database utilities
async def check_database_connection():
    """Check if database is accessible."""
    try:
        async with engine.connect() as conn:
            await conn.execute("SELECT 1")
        return True
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        return False
```

### Step 5: Create Core Configuration

Create `starter/backend/app/core/config.py`:

**🤖 Copilot Prompt Suggestion #5:**
```python
# Create application configuration using Pydantic Settings:
# - Load from environment variables
# - Support .env files
# - Include: database URL, JWT secret, CORS origins, API keys
# - Validation for all settings
# - Different configs for dev/prod/test
```

**Expected Output:**
```python
from pydantic_settings import BaseSettings
from typing import List, Optional
from functools import lru_cache
import secrets
import os

class Settings(BaseSettings):
    """Application settings."""
    
    # Application
    APP_NAME: str = "Task Management API"
    APP_VERSION: str = "1.0.0"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    
    # API
    API_V1_PREFIX: str = "/api/v1"
    
    # Database
    DATABASE_URL: str = "sqlite:///./tasks.db"
    
    # Security
    SECRET_KEY: str = secrets.token_urlsafe(32)
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours
    REFRESH_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # CORS
    CORS_ORIGINS: List[str] = ["http://localhost:3000", "http://localhost:8080"]
    
    # Pagination
    DEFAULT_PAGE_SIZE: int = 20
    MAX_PAGE_SIZE: int = 100
    
    # WebSocket
    WS_MESSAGE_QUEUE_SIZE: int = 1000
    
    # Rate limiting
    RATE_LIMIT_REQUESTS: int = 100
    RATE_LIMIT_PERIOD: int = 60  # seconds
    
    # Email (optional)
    SMTP_HOST: Optional[str] = None
    SMTP_PORT: Optional[int] = None
    SMTP_USER: Optional[str] = None
    SMTP_PASSWORD: Optional[str] = None
    SMTP_FROM: Optional[str] = "noreply@taskmanager.com"
    
    # External services
    OPENAI_API_KEY: Optional[str] = None
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True
        
    @property
    def is_production(self) -> bool:
        """Check if running in production."""
        return self.ENVIRONMENT == "production"
    
    @property
    def is_development(self) -> bool:
        """Check if running in development."""
        return self.ENVIRONMENT == "development"
    
    @property
    def is_test(self) -> bool:
        """Check if running in test."""
        return self.ENVIRONMENT == "test"

@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()

# Create settings instance
settings = get_settings()

# Validate critical settings
if settings.is_production:
    if settings.SECRET_KEY == secrets.token_urlsafe(32):
        raise ValueError("SECRET_KEY must be set in production")
    if settings.DEBUG:
        raise ValueError("DEBUG must be False in production")
    if "*" in settings.CORS_ORIGINS:
        raise ValueError("CORS_ORIGINS cannot contain '*' in production")
```

## 🎯 Part 1 Summary

You've successfully:
1. Set up a modern FastAPI application structure
2. Created comprehensive database models with SQLAlchemy
3. Defined Pydantic schemas for validation
4. Configured async database connections
5. Set up application configuration management

**Key Components Built:**
- FastAPI application with proper middleware
- User and Task models with relationships
- Request/response schemas with validation
- Async database configuration
- Settings management with environment variables

**Next**: Continue to [Part 2](module-01-exercise3-part2.md) where we'll implement authentication, API endpoints, and the web interface!

---

💡 **Pro Tip**: When building complex applications with Copilot, start with clear architectural decisions. Copilot will follow your patterns consistently across the codebase!
