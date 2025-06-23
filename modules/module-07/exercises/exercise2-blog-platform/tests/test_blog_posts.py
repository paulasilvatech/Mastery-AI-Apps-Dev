"""Blog Post Tests for Blog Platform"""

import pytest
from fastapi.testclient import TestClient
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.app.main import app

client = TestClient(app)

class TestBlogPosts:
    """Test suite for blog post functionality"""
    
    @pytest.fixture
    def auth_headers(self):
        """Get authentication headers for testing"""
        # Register and login a test user
        user_data = {
            "username": "testauthor",
            "email": "author@example.com",
            "password": "testpass123"
        }
        client.post("/auth/register", json=user_data)
        
        login_response = client.post("/auth/token", data={
            "username": "testauthor",
            "password": "testpass123"
        })
        token = login_response.json()["access_token"]
        return {"Authorization": f"Bearer {token}"}
    
    def test_create_blog_post(self, auth_headers):
        """Test creating a new blog post"""
        post_data = {
            "title": "My First Blog Post",
            "content": "# Hello World\n\nThis is my first blog post!",
            "summary": "A brief introduction",
            "tags": ["introduction", "hello"]
        }
        
        response = client.post("/posts", json=post_data, headers=auth_headers)
        assert response.status_code == 201
        data = response.json()
        assert data["title"] == post_data["title"]
        assert data["slug"] == "my-first-blog-post"
        assert data["status"] == "draft"
        assert "id" in data
        assert "author" in data
    
    def test_get_blog_posts(self):
        """Test retrieving blog posts"""
        response = client.get("/posts")
        assert response.status_code == 200
        data = response.json()
        assert "posts" in data
        assert "total" in data
        assert "page" in data
        assert "pages" in data
    
    def test_get_single_post(self, auth_headers):
        """Test retrieving a single blog post"""
        # Create a post first
        post_data = {
            "title": "Test Post",
            "content": "Test content"
        }
        create_response = client.post("/posts", json=post_data, headers=auth_headers)
        post_id = create_response.json()["id"]
        
        # Get the post
        response = client.get(f"/posts/{post_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == post_id
        assert data["title"] == "Test Post"
    
    def test_update_blog_post(self, auth_headers):
        """Test updating a blog post"""
        # Create a post
        create_response = client.post("/posts", json={
            "title": "Original Title",
            "content": "Original content"
        }, headers=auth_headers)
        post_id = create_response.json()["id"]
        
        # Update the post
        update_data = {
            "title": "Updated Title",
            "content": "Updated content",
            "status": "published"
        }
        response = client.put(f"/posts/{post_id}", json=update_data, headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Updated Title"
        assert data["status"] == "published"
        assert data["published_at"] is not None
    
    def test_delete_blog_post(self, auth_headers):
        """Test deleting a blog post"""
        # Create a post
        create_response = client.post("/posts", json={
            "title": "Delete Me",
            "content": "To be deleted"
        }, headers=auth_headers)
        post_id = create_response.json()["id"]
        
        # Delete the post
        response = client.delete(f"/posts/{post_id}", headers=auth_headers)
        assert response.status_code == 204
        
        # Verify deletion
        get_response = client.get(f"/posts/{post_id}")
        assert get_response.status_code == 404
    
    def test_unauthorized_post_creation(self):
        """Test creating post without authentication"""
        post_data = {
            "title": "Unauthorized Post",
            "content": "Should fail"
        }
        response = client.post("/posts", json=post_data)
        assert response.status_code == 401
    
    def test_search_posts(self, auth_headers):
        """Test searching blog posts"""
        # Create posts with different content
        posts = [
            {"title": "Python Tutorial", "content": "Learn Python programming"},
            {"title": "JavaScript Guide", "content": "Master JavaScript"},
            {"title": "Python Advanced", "content": "Advanced Python concepts"}
        ]
        
        for post in posts:
            client.post("/posts", json=post, headers=auth_headers)
        
        # Search for Python posts
        response = client.get("/posts/search?q=Python")
        assert response.status_code == 200
        data = response.json()
        assert data["total"] >= 2
        for post in data["posts"]:
            assert "python" in post["title"].lower() or "python" in post["content"].lower()
    
    def test_filter_by_status(self, auth_headers):
        """Test filtering posts by status"""
        # Create draft post
        client.post("/posts", json={
            "title": "Draft Post",
            "content": "Draft content"
        }, headers=auth_headers)
        
        # Create and publish post
        create_response = client.post("/posts", json={
            "title": "Published Post",
            "content": "Published content"
        }, headers=auth_headers)
        post_id = create_response.json()["id"]
        client.put(f"/posts/{post_id}", json={"status": "published"}, headers=auth_headers)
        
        # Get only published posts
        response = client.get("/posts?status=published")
        assert response.status_code == 200
        data = response.json()
        for post in data["posts"]:
            assert post["status"] == "published"
    
    def test_pagination(self, auth_headers):
        """Test post pagination"""
        # Create multiple posts
        for i in range(15):
            client.post("/posts", json={
                "title": f"Post {i}",
                "content": f"Content {i}"
            }, headers=auth_headers)
        
        # Test first page
        response = client.get("/posts?page=1&limit=10")
        assert response.status_code == 200
        data = response.json()
        assert len(data["posts"]) == 10
        assert data["page"] == 1
        assert data["pages"] >= 2
        
        # Test second page
        response = client.get("/posts?page=2&limit=10")
        assert response.status_code == 200
        data = response.json()
        assert len(data["posts"]) >= 5