# app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# TODO: Import your routers and database initialization

app = FastAPI(
    title="Task Management API",
    description="A RESTful API for managing tasks",
    version="1.0.0"
)

# TODO: Configure CORS middleware

# TODO: Add startup event for database initialization

# TODO: Include routers

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}

# app/models/task.py
from sqlalchemy import Column, String, DateTime
from sqlalchemy.ext.declarative import declarative_base
import uuid
from datetime import datetime

Base = declarative_base()

# TODO: Create Task model with the following fields:
# - id (UUID, primary key)
# - title (String, required, max 200 chars)
# - description (Text, optional)
# - status (Enum: pending, in_progress, completed)
# - priority (Enum: low, medium, high)
# - due_date (DateTime, optional)
# - created_at (DateTime, auto-generated)
# - updated_at (DateTime, auto-updated)

# app/schemas/task.py
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from uuid import UUID

# TODO: Create Pydantic schemas:
# - TaskBase (shared fields)
# - TaskCreate (for creating tasks)
# - TaskUpdate (for updating tasks, all fields optional)
# - TaskResponse (for API responses, includes all fields)
# - TaskListResponse (for paginated responses)

# app/database.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
import os

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./test.db")

# TODO: Create async engine and session factory

# TODO: Create get_db dependency

# TODO: Create init_db function

# app/api/v1/tasks.py
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
from uuid import UUID

router = APIRouter()

# TODO: Implement the following endpoints:
# GET /tasks - List all tasks with pagination and filtering
# POST /tasks - Create a new task
# GET /tasks/{task_id} - Get a specific task
# PUT /tasks/{task_id} - Update a task
# DELETE /tasks/{task_id} - Delete a task
# GET /tasks/stats - Get task statistics

# requirements.txt
fastapi==0.109.0
uvicorn[standard]==0.27.0
sqlalchemy==2.0.25
aiosqlite==0.19.0
pydantic==2.5.3
python-multipart==0.0.6
pytest==7.4.4
pytest-asyncio==0.23.3
httpx==0.26.0