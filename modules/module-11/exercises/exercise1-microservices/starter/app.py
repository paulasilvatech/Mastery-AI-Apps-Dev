# Exercise 1: Foundation - Service Decomposition
# Starter Code for User Service

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from uuid import UUID, uuid4
from datetime import datetime

# TODO: Import additional modules as needed

app = FastAPI(
    title="User Service",
    description="Microservice for user management",
    version="1.0.0"
)

# TODO: Define Pydantic models for User, UserCreate, UserUpdate
# Hint: Use the Copilot prompt from the exercise instructions

class UserBase(BaseModel):
    """Base user model with common fields"""
    # TODO: Add fields
    pass

class UserCreate(UserBase):
    """Model for creating a new user"""
    # TODO: Add password field
    pass

class User(UserBase):
    """Complete user model with generated fields"""
    # TODO: Add id and created_at fields
    pass

# TODO: Create an in-memory database
# Hint: Use a dictionary to store users by ID

users_db = {}

# TODO: Implement API endpoints

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "user-service",
        "timestamp": datetime.utcnow().isoformat()
    }

@app.post("/api/users", response_model=User, status_code=201)
async def create_user(user: UserCreate):
    """Create a new user"""
    # TODO: Implement user creation logic
    # 1. Check if username/email already exists
    # 2. Create new user with generated ID
    # 3. Store in database
    # 4. Return created user
    pass

@app.get("/api/users", response_model=List[User])
async def list_users(skip: int = 0, limit: int = 100):
    """List all users with pagination"""
    # TODO: Implement pagination logic
    pass

@app.get("/api/users/{user_id}", response_model=User)
async def get_user(user_id: UUID):
    """Get a specific user by ID"""
    # TODO: Implement user retrieval
    # Handle 404 if user not found
    pass

@app.put("/api/users/{user_id}", response_model=User)
async def update_user(user_id: UUID, user_update: UserUpdate):
    """Update an existing user"""
    # TODO: Implement update logic
    # Handle 404 if user not found
    pass

@app.delete("/api/users/{user_id}", status_code=204)
async def delete_user(user_id: UUID):
    """Delete a user"""
    # TODO: Implement deletion
    # Handle 404 if user not found
    pass

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)