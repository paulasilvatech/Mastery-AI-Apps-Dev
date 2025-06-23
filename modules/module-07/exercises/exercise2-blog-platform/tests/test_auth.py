"""Authentication Tests for Blog Platform"""

import pytest
from fastapi.testclient import TestClient
from jose import jwt
from datetime import datetime, timedelta
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.app.main import app
from backend.app.auth import create_access_token, get_password_hash, verify_password
from backend.app.config import SECRET_KEY, ALGORITHM

client = TestClient(app)

class TestAuthentication:
    """Test suite for authentication functionality"""
    
    def test_password_hashing(self):
        """Test password hashing and verification"""
        password = "testpassword123"
        hashed = get_password_hash(password)
        
        assert hashed != password
        assert verify_password(password, hashed)
        assert not verify_password("wrongpassword", hashed)
    
    def test_create_access_token(self):
        """Test JWT token creation"""
        data = {"sub": "testuser"}
        token = create_access_token(data)
        
        # Decode token
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        assert payload["sub"] == "testuser"
        assert "exp" in payload
    
    def test_user_registration(self):
        """Test user registration endpoint"""
        user_data = {
            "username": "newuser",
            "email": "newuser@example.com",
            "password": "securepassword123",
            "full_name": "New User"
        }
        
        response = client.post("/auth/register", json=user_data)
        assert response.status_code == 201
        data = response.json()
        assert data["username"] == user_data["username"]
        assert data["email"] == user_data["email"]
        assert "id" in data
        assert "password" not in data
    
    def test_duplicate_registration(self):
        """Test duplicate user registration prevention"""
        user_data = {
            "username": "existinguser",
            "email": "existing@example.com",
            "password": "password123"
        }
        
        # First registration
        client.post("/auth/register", json=user_data)
        
        # Duplicate registration
        response = client.post("/auth/register", json=user_data)
        assert response.status_code == 400
        assert "already registered" in response.json()["detail"].lower()
    
    def test_user_login(self):
        """Test user login endpoint"""
        # Register user first
        user_data = {
            "username": "logintest",
            "email": "login@example.com",
            "password": "testpassword123"
        }
        client.post("/auth/register", json=user_data)
        
        # Login
        login_data = {
            "username": "logintest",
            "password": "testpassword123"
        }
        response = client.post("/auth/token", data=login_data)
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
    
    def test_invalid_login(self):
        """Test login with invalid credentials"""
        login_data = {
            "username": "nonexistent",
            "password": "wrongpassword"
        }
        response = client.post("/auth/token", data=login_data)
        assert response.status_code == 401
    
    def test_protected_endpoint(self):
        """Test accessing protected endpoint with token"""
        # Register and login
        user_data = {
            "username": "authtest",
            "email": "auth@example.com",
            "password": "testpass123"
        }
        client.post("/auth/register", json=user_data)
        
        login_response = client.post("/auth/token", data={
            "username": "authtest",
            "password": "testpass123"
        })
        token = login_response.json()["access_token"]
        
        # Access protected endpoint
        headers = {"Authorization": f"Bearer {token}"}
        response = client.get("/auth/me", headers=headers)
        assert response.status_code == 200
        assert response.json()["username"] == "authtest"
    
    def test_protected_endpoint_no_token(self):
        """Test accessing protected endpoint without token"""
        response = client.get("/auth/me")
        assert response.status_code == 401
    
    def test_token_expiration(self):
        """Test token expiration handling"""
        # Create expired token
        data = {"sub": "testuser"}
        expired_token = create_access_token(
            data, 
            expires_delta=timedelta(minutes=-1)
        )
        
        headers = {"Authorization": f"Bearer {expired_token}"}
        response = client.get("/auth/me", headers=headers)
        assert response.status_code == 401
        assert "expired" in response.json()["detail"].lower()
    
    def test_refresh_token(self):
        """Test token refresh functionality"""
        # Register and login
        user_data = {
            "username": "refreshtest",
            "email": "refresh@example.com",
            "password": "testpass123"
        }
        client.post("/auth/register", json=user_data)
        
        login_response = client.post("/auth/token", data={
            "username": "refreshtest",
            "password": "testpass123"
        })
        old_token = login_response.json()["access_token"]
        
        # Refresh token
        headers = {"Authorization": f"Bearer {old_token}"}
        response = client.post("/auth/refresh", headers=headers)
        assert response.status_code == 200
        new_token = response.json()["access_token"]
        assert new_token != old_token