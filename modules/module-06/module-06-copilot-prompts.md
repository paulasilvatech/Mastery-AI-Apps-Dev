# GitHub Copilot Prompt Examples for Module 06

## 🎯 Overview

This document provides specific Copilot prompt examples for each exercise in Module 06, demonstrating effective techniques for multi-file projects and workspace management.

## 📝 Exercise 1: Task Management System

### Creating the Task Model

**Copilot Prompt Suggestion:**
```python
# Create a Pydantic Task model with:
# - id field using UUID with factory default
# - title as required string with min length 1
# - description as optional string
# - status as enum (TODO, IN_PROGRESS, DONE) 
# - created_at and updated_at as datetime with defaults
# - priority as int between 1-5, default 3
# Include model config for JSON serialization
```

**Expected Output:**
```python
from pydantic import BaseModel, Field, validator
from uuid import UUID, uuid4
from datetime import datetime
from enum import Enum
from typing import Optional

class TaskStatus(str, Enum):
    TODO = "TODO"
    IN_PROGRESS = "IN_PROGRESS"
    DONE = "DONE"

class Task(BaseModel):
    id: UUID = Field(default_factory=uuid4)
    title: str = Field(..., min_length=1)
    description: Optional[str] = None
    status: TaskStatus = TaskStatus.TODO
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)
    priority: int = Field(default=3, ge=1, le=5)
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat(),
            UUID: lambda v: str(v)
        }
```
*(Note: Output may vary based on context and model updates)*

### Storage Layer Implementation

**Copilot Prompt Suggestion:**
```python
# Create JSONStorage class for task persistence with:
# - __init__ that accepts file_path and creates directory if needed
# - save_task method that appends task to JSON file
# - get_task method that finds task by ID
# - get_all_tasks that returns list of Task objects
# - update_task that modifies existing task
# - delete_task that removes task by ID
# Handle file not found and JSON decode errors gracefully
# Use Path from pathlib and type hints throughout
```

**Expected Output:**
A complete storage class with error handling, type hints, and all CRUD operations.

### Service Layer with Workspace Context

**Copilot Prompt Suggestion (in Chat mode):**
```
@workspace Create a TaskService class that:
- Uses dependency injection for JSONStorage
- Validates business rules (e.g., can't move from DONE to TODO)
- Implements search_tasks method using title/description
- Adds get_tasks_by_priority method
- Includes proper error handling with custom exceptions
Reference the Task model and JSONStorage from other files
```

**Expected Output:**
Service class that properly imports from other modules and implements business logic.

### CLI Creation with Multi-File Context

**Copilot Prompt Suggestion (Edit mode - multiple files selected):**
```
Create a Click CLI in cli.py that:
- Imports TaskService and initializes with JSONStorage
- Has commands: add, list, update, delete, search
- add command accepts --title (required), --description, --priority
- list command has --sort-by option (priority/date/status)
- update command takes task_id and --status or --priority
- All commands show formatted output with colors
- Error handling shows user-friendly messages
```

**Expected Output:**
Complete CLI with all commands, proper imports, and error handling.

## 📝 Exercise 2: E-Commerce Microservice

### Database Configuration

**Copilot Prompt Suggestion:**
```python
# Create async SQLAlchemy database configuration with:
# - Async engine using postgresql+asyncpg
# - Session factory with expire_on_commit=False
# - Base declarative class
# - get_db dependency for FastAPI that yields session
# - Proper cleanup in finally block
# Load DATABASE_URL from environment settings
```

**Expected Output:**
Complete async database setup with proper session management.

### Multi-Model Creation with Relationships

**Copilot Prompt Suggestion (Agent mode):**
```
@workspace Create SQLAlchemy models for:
1. Category model with id, name, description, created_at
2. Product model with id, name, description, price, category_id (FK), created_at, updated_at
3. Inventory model with id, product_id (FK), quantity, reserved_quantity, last_updated
Set up proper relationships:
- Category has many products
- Product belongs to category, has one inventory
- Use UUID for all IDs
- Add indexes on foreign keys
- Include __repr__ methods
```

**Expected Output:**
Three interconnected models with proper relationships and constraints.

### Repository Pattern Implementation

**Copilot Prompt Suggestion:**
```python
# Create generic BaseRepository class with:
# - Type parameters using Generic[ModelType, CreateSchemaType]
# - Async CRUD methods: create, get, get_all, update, delete
# - Pagination support with skip/limit
# - Filter support using **kwargs
# - Bulk operations: create_many, update_many
# - Use SQLAlchemy 2.0 style queries
# Include proper type hints and docstrings
```

**Expected Output:**
Reusable base repository with generic typing and comprehensive methods.

### API Endpoint Generation

**Copilot Prompt Suggestion (Edit mode - select all endpoint files):**
```
Create FastAPI routers for products, categories, and inventory:
- Standard CRUD endpoints for each
- Products: GET /products with pagination and category filter
- Categories: GET /categories/{id}/products for products in category
- Inventory: PUT /inventory/{product_id}/reserve for stock reservation
- Use dependency injection for services
- Return proper HTTP status codes
- Include request/response schemas
- Add OpenAPI documentation
```

**Expected Output:**
Complete API routers with proper structure and error handling.

## 📝 Exercise 3: Real-Time Collaboration Platform

### WebSocket Connection Manager

**Copilot Prompt Suggestion:**
```python
# Create ConnectionManager class for WebSocket handling:
# - Store active connections by room_id using dict[str, list[WebSocket]]
# - connect method adds user to room with user_id metadata
# - disconnect method removes user and notifies others
# - broadcast_to_room sends message to all in room except sender
# - broadcast_to_user sends direct message
# - get_room_users returns list of active users in room
# - Implement heartbeat checking with 30s timeout
# Use asyncio and proper exception handling for disconnections
```

**Expected Output:**
Robust connection manager handling multiple rooms and users.

### Document Synchronization with OT

**Copilot Prompt Suggestion (Chat mode with context):**
```
@workspace Implement operational transformation for document sync:
- Create Operation class with type (insert/delete), position, content
- Transform function that adjusts operations based on conflicts
- DocumentSync service that:
  - Maintains document state per room
  - Applies operations in correct order
  - Handles concurrent edits using OT
  - Broadcasts transformed operations
  - Stores operation history
Reference the WebSocket events from shared types
```

**Expected Output:**
Complete OT implementation with conflict resolution.

### React Hooks for Real-time Features

**Copilot Prompt Suggestion:**
```typescript
// Create useCollaboration hook that:
// - Connects to WebSocket server with auto-reconnect
// - Handles document updates with optimistic UI
// - Tracks user presence with 5s heartbeat
// - Shows remote cursors with smooth animation
// - Provides methods: sendOperation, updateCursor
// - Returns: document, users, cursors, connectionState
// - Cleanup on unmount
// Use Socket.IO client and handle all error cases
```

**Expected Output:**
Complete React hook with real-time synchronization logic.

### Complex Multi-File Refactoring

**Copilot Prompt Suggestion (Agent mode):**
```
@workspace Refactor the entire codebase to:
1. Extract all WebSocket event types to shared/events.ts
2. Update backend to use these shared types
3. Update frontend to import from shared
4. Add proper TypeScript types everywhere
5. Ensure no any types remain
6. Update all imports to use path aliases
Maintain backward compatibility
```

**Expected Output:**
Systematic refactoring across frontend, backend, and shared code.

## 💡 Advanced Workspace Prompts

### Architecture Analysis

**Copilot Prompt Suggestion:**
```
@workspace Analyze the current architecture and:
- Create a Mermaid diagram showing component relationships
- Identify circular dependencies
- Suggest improvements for scalability
- Find unused exports
- List all external dependencies by component
```

### Performance Optimization

**Copilot Prompt Suggestion:**
```
@workspace Find performance bottlenecks:
- Identify N+1 query problems
- Find missing database indexes
- Locate synchronous operations that should be async
- Find unnecessary re-renders in React
- Suggest caching opportunities
```

### Security Audit

**Copilot Prompt Suggestion:**
```
@workspace Security review:
- Find any SQL injection vulnerabilities
- Check for exposed sensitive data
- Verify all endpoints have authentication
- Find any hardcoded secrets
- Check for XSS vulnerabilities
- Verify CORS configuration
```

## 🎯 Best Practices for Prompts

### 1. Be Specific About Context

**Good Prompt:**
```python
# Using the Task model from models/task.py and following
# the repository pattern in repositories/base.py,
# create a TaskRepository with additional filter methods
```

**Poor Prompt:**
```python
# Make a repository
```

### 2. Reference Existing Patterns

**Good Prompt:**
```
@workspace Create a NotificationService following the same 
dependency injection pattern as ProductService, using the
BaseService abstract class
```

### 3. Include Constraints

**Good Prompt:**
```python
# Create validation function that:
# - Accepts Product object
# - Checks price is positive
# - Ensures SKU is unique (check via repository)
# - Validates category exists
# - Returns ValidationResult with errors list
# - Never raises exceptions
```

### 4. Specify Expected Output Format

**Good Prompt:**
```typescript
// Create a REST API client that:
// - Returns typed responses using generics
// - Handles errors with Result<T, E> pattern
// - Includes retry logic with exponential backoff
// - Example: const result = await api.get<User>('/users/123')
```

## 🔄 Iterative Refinement

### Initial Prompt
```python
# Create a caching decorator
```

### Refined Prompt
```python
# Create a caching decorator that:
# - Accepts TTL parameter in seconds
# - Uses function arguments as cache key
# - Supports async functions
# - Uses LRU eviction when cache is full
# - Thread-safe for concurrent access
# Name it @cache_result(ttl=300)
```

### Final Prompt with Context
```python
# Create a caching decorator for the service layer that:
# - Integrates with our Redis setup from core/redis.py
# - Uses pickle for serialization
# - Includes cache invalidation method
# - Logs cache hits/misses
# - Compatible with our async service methods
# Follow the decorator pattern in utils/decorators.py
```

## 📚 Learning Resources

- Practice these prompts in order of complexity
- Experiment with variations
- Save successful prompts for reuse
- Share effective prompts with your team

---

**Remember:** The best prompts provide clear context, specific requirements, and reference existing patterns in your codebase!