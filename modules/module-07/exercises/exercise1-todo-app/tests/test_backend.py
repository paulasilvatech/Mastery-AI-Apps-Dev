"""Tests for Todo Application Backend"""

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import sys
import os

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.app.main import app
from backend.app.models import Base, get_db

# Create test database
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)

# Override the dependency
def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db
client = TestClient(app)

class TestTodoAPI:
    """Test suite for Todo API endpoints"""
    
    def test_root_endpoint(self):
        """Test root endpoint returns correct message"""
        response = client.get("/")
        assert response.status_code == 200
        assert response.json() == {"message": "Todo API is running!"}
    
    def test_create_todo(self):
        """Test creating a new todo"""
        todo_data = {
            "title": "Test Todo",
            "description": "This is a test todo item"
        }
        response = client.post("/todos", json=todo_data)
        assert response.status_code == 201
        data = response.json()
        assert data["title"] == todo_data["title"]
        assert data["description"] == todo_data["description"]
        assert data["completed"] is False
        assert "id" in data
        assert "created_at" in data
        assert "updated_at" in data
    
    def test_get_todos(self):
        """Test getting all todos"""
        # Create a few todos first
        for i in range(3):
            client.post("/todos", json={"title": f"Todo {i}"})
        
        response = client.get("/todos")
        assert response.status_code == 200
        data = response.json()
        assert "todos" in data
        assert "total" in data
        assert data["total"] >= 3
    
    def test_get_single_todo(self):
        """Test getting a single todo by ID"""
        # Create a todo
        create_response = client.post("/todos", json={"title": "Single Todo"})
        todo_id = create_response.json()["id"]
        
        # Get the todo
        response = client.get(f"/todos/{todo_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == todo_id
        assert data["title"] == "Single Todo"
    
    def test_update_todo(self):
        """Test updating a todo"""
        # Create a todo
        create_response = client.post("/todos", json={"title": "Update Me"})
        todo_id = create_response.json()["id"]
        
        # Update the todo
        update_data = {
            "title": "Updated Todo",
            "completed": True
        }
        response = client.put(f"/todos/{todo_id}", json=update_data)
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Updated Todo"
        assert data["completed"] is True
    
    def test_delete_todo(self):
        """Test deleting a todo"""
        # Create a todo
        create_response = client.post("/todos", json={"title": "Delete Me"})
        todo_id = create_response.json()["id"]
        
        # Delete the todo
        response = client.delete(f"/todos/{todo_id}")
        assert response.status_code == 204
        
        # Verify it's deleted
        get_response = client.get(f"/todos/{todo_id}")
        assert get_response.status_code == 404
    
    def test_filter_completed_todos(self):
        """Test filtering todos by completed status"""
        # Create mixed todos
        client.post("/todos", json={"title": "Incomplete 1"})
        client.post("/todos", json={"title": "Incomplete 2"})
        
        # Create and complete a todo
        create_response = client.post("/todos", json={"title": "Complete Me"})
        todo_id = create_response.json()["id"]
        client.put(f"/todos/{todo_id}", json={"completed": True})
        
        # Get only completed todos
        response = client.get("/todos?completed=true")
        assert response.status_code == 200
        data = response.json()
        for todo in data["todos"]:
            assert todo["completed"] is True
    
    def test_todo_not_found(self):
        """Test 404 error for non-existent todo"""
        response = client.get("/todos/99999")
        assert response.status_code == 404
        assert response.json()["detail"] == "Todo not found"
    
    def test_suggest_next_todo(self):
        """Test AI suggestion endpoint"""
        response = client.get("/todos/suggest/next")
        assert response.status_code == 200
        data = response.json()
        assert "suggestion" in data
        assert isinstance(data["suggestion"], str)
        assert len(data["suggestion"]) > 0

if __name__ == "__main__":
    pytest.main([__file__, "-v"])