# Exercise 2: Blog Platform with AI Features (⭐⭐)

## 🎯 Exercise Overview

**Duration:** 45-60 minutes  
**Difficulty:** ⭐⭐ Application  
**Success Rate:** 80%

In this exercise, you'll build a feature-rich blog platform leveraging GitHub Copilot for rapid development. This real-world scenario will teach you authentication, rich text editing, and AI-powered content features.

### What You'll Build

A complete blog platform featuring:
- 🔐 User authentication with JWT
- 📝 Rich text editor with AI assistance
- 💬 Comment system with moderation
- 🖼️ Image upload and management
- 🔍 SEO optimization
- 📊 Analytics dashboard

### Learning Objectives

By completing this exercise, you will:
- Implement secure authentication flows
- Build complex UI components with AI
- Handle file uploads and storage
- Create SEO-friendly web applications
- Integrate AI for content generation

## 🏗️ Architecture Overview

```mermaid
graph TB
    subgraph Frontend
        Auth[Auth Components]
        Editor[Rich Text Editor]
        Blog[Blog Views]
        Admin[Admin Dashboard]
    end
    
    subgraph Backend
        JWT[JWT Auth]
        Posts[Posts API]
        Comments[Comments API]
        Upload[File Upload]
        AI[AI Integration]
    end
    
    subgraph Storage
        DB[PostgreSQL]
        S3[File Storage]
    end
    
    Auth --> JWT
    Editor --> Posts
    Editor --> AI
    Blog --> Posts
    Blog --> Comments
    Admin --> Posts
    Upload --> S3
    Posts --> DB
    Comments --> DB
    
    style Frontend fill:#e1f5fe
    style Backend fill:#f3e5f5
    style Storage fill:#e8f5e9
```

## 📋 Step 1: Enhanced Backend Setup (15 minutes)

### 1.1 Create Project Structure

```bash
# Create exercise directory
mkdir exercise2-blog-platform
cd exercise2-blog-platform

# Backend structure
mkdir -p backend/{app,tests,uploads}
mkdir -p backend/app/{models,schemas,api,core,services}
cd backend

# Setup Python environment
python -m venv venv
source venv/bin/activate  # Windows: .\venv\Scripts\activate
```

### 1.2 Install Dependencies

Create `requirements.txt`:

```txt
fastapi==0.104.1
uvicorn[standard]==0.24.0
sqlalchemy==2.0.23
alembic==1.12.1
psycopg2-binary==2.9.9
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
pydantic==2.5.0
pydantic-settings==2.1.0
aiofiles==23.2.1
python-slugify==8.0.1
markdown==3.5.1
bleach==6.1.0
pillow==10.1.0
```

Install:
```bash
pip install -r requirements.txt
```

### 1.3 Database Configuration

Create `backend/app/core/config.py`:

**Copilot Prompt Suggestion:**
```python
# Create a configuration class using Pydantic Settings that:
# - Loads environment variables
# - Has database URL (PostgreSQL)
# - JWT secret key and algorithm
# - Token expiration time (30 minutes)
# - Upload directory path
# - Allowed image extensions
# - Max upload size (5MB)
# Use proper type hints and defaults
```

**Expected Copilot Output:**
```python
from pydantic_settings import BaseSettings
from typing import List
import secrets

class Settings(BaseSettings):
    # Application
    APP_NAME: str = "AI Blog Platform"
    VERSION: str = "1.0.0"
    API_PREFIX: str = "/api/v1"
    
    # Database
    DATABASE_URL: str = "postgresql://user:password@localhost/blogdb"
    
    # Security
    SECRET_KEY: str = secrets.token_urlsafe(32)
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # File Upload
    UPLOAD_DIR: str = "./uploads"
    MAX_UPLOAD_SIZE: int = 5 * 1024 * 1024  # 5MB
    ALLOWED_EXTENSIONS: List[str] = [".jpg", ".jpeg", ".png", ".gif", ".webp"]
    
    # AI Integration
    OPENAI_API_KEY: str = ""
    AI_MODEL: str = "gpt-3.5-turbo"
    
    # CORS
    ALLOWED_ORIGINS: List[str] = ["http://localhost:5173"]
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
```

### 1.4 Database Models

Create `backend/app/models/models.py`:

**Copilot Prompt Suggestion:**
```python
# Create SQLAlchemy models for a blog platform:
# - User model: id, username, email, hashed_password, is_active, is_admin, created_at
# - Post model: id, title, slug, content, excerpt, author_id, status (draft/published), 
#   featured_image, views, created_at, updated_at, published_at
# - Comment model: id, post_id, author_id, content, is_approved, created_at
# - Tag model: id, name, slug
# - PostTag association table
# Include relationships and indexes for performance
```

**Expected Copilot Output:**
```python
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, ForeignKey, Table, Enum
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime
import enum

Base = declarative_base()

# Association table for many-to-many relationship
post_tags = Table(
    'post_tags',
    Base.metadata,
    Column('post_id', Integer, ForeignKey('posts.id', ondelete='CASCADE')),
    Column('tag_id', Integer, ForeignKey('tags.id', ondelete='CASCADE'))
)

class PostStatus(str, enum.Enum):
    DRAFT = "draft"
    PUBLISHED = "published"

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    is_active = Column(Boolean, default=True)
    is_admin = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    posts = relationship("Post", back_populates="author", cascade="all, delete-orphan")
    comments = relationship("Comment", back_populates="author", cascade="all, delete-orphan")

class Post(Base):
    __tablename__ = "posts"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    slug = Column(String(250), unique=True, index=True, nullable=False)
    content = Column(Text, nullable=False)
    excerpt = Column(String(500))
    author_id = Column(Integer, ForeignKey("users.id", ondelete='CASCADE'), nullable=False)
    status = Column(Enum(PostStatus), default=PostStatus.DRAFT)
    featured_image = Column(String(500))
    views = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    published_at = Column(DateTime(timezone=True))
    
    # Relationships
    author = relationship("User", back_populates="posts")
    comments = relationship("Comment", back_populates="post", cascade="all, delete-orphan")
    tags = relationship("Tag", secondary=post_tags, back_populates="posts")

class Comment(Base):
    __tablename__ = "comments"
    
    id = Column(Integer, primary_key=True, index=True)
    post_id = Column(Integer, ForeignKey("posts.id", ondelete='CASCADE'), nullable=False)
    author_id = Column(Integer, ForeignKey("users.id", ondelete='CASCADE'), nullable=False)
    content = Column(Text, nullable=False)
    is_approved = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    post = relationship("Post", back_populates="comments")
    author = relationship("User", back_populates="comments")

class Tag(Base):
    __tablename__ = "tags"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), unique=True, nullable=False)
    slug = Column(String(60), unique=True, index=True, nullable=False)
    
    # Relationships
    posts = relationship("Post", secondary=post_tags, back_populates="tags")
```

### 1.5 Authentication System

Create `backend/app/core/security.py`:

**Copilot Prompt Suggestion:**
```python
# Create security utilities:
# - Password hashing functions using bcrypt
# - JWT token creation and verification
# - Get current user dependency for FastAPI
# - Create access token with user data
# Include proper error handling and type hints
```

**Expected Copilot Output:**
```python
from datetime import datetime, timedelta
from typing import Optional, Union
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from ..models.models import User
from ..core.config import settings
from ..core.database import get_db

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_PREFIX}/auth/login")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash"""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Generate password hash"""
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def verify_token(token: str) -> dict:
    """Verify JWT token and return payload"""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> User:
    """Get current authenticated user"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = verify_token(token)
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = db.query(User).filter(User.username == username).first()
    if user is None:
        raise credentials_exception
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    
    return user

async def get_current_admin_user(current_user: User = Depends(get_current_user)) -> User:
    """Verify current user is admin"""
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    return current_user
```

### 1.6 Pydantic Schemas

Create `backend/app/schemas/schemas.py`:

**Copilot Prompt Suggestion:**
```python
# Create Pydantic schemas for the blog platform:
# User schemas: UserCreate, UserLogin, UserResponse, UserUpdate
# Post schemas: PostCreate, PostUpdate, PostResponse with pagination
# Comment schemas: CommentCreate, CommentResponse
# Tag schemas: TagCreate, TagResponse
# Auth schemas: Token, TokenData
# Include validation, optional fields, and response models
```

**Expected Copilot Output:**
```python
from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional, List
from datetime import datetime
from ..models.models import PostStatus

# User Schemas
class UserBase(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr

class UserCreate(UserBase):
    password: str = Field(..., min_length=8)
    
    @validator('password')
    def validate_password(cls, v):
        if not any(char.isdigit() for char in v):
            raise ValueError('Password must contain at least one digit')
        if not any(char.isupper() for char in v):
            raise ValueError('Password must contain at least one uppercase letter')
        return v

class UserLogin(BaseModel):
    username: str
    password: str

class UserResponse(UserBase):
    id: int
    is_active: bool
    is_admin: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    password: Optional[str] = Field(None, min_length=8)

# Auth Schemas
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class TokenData(BaseModel):
    username: Optional[str] = None

# Tag Schemas
class TagBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=50)

class TagCreate(TagBase):
    pass

class TagResponse(TagBase):
    id: int
    slug: str
    
    class Config:
        from_attributes = True

# Post Schemas
class PostBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    content: str = Field(..., min_length=10)
    excerpt: Optional[str] = Field(None, max_length=500)
    featured_image: Optional[str] = None
    status: PostStatus = PostStatus.DRAFT

class PostCreate(PostBase):
    tags: Optional[List[str]] = []

class PostUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    content: Optional[str] = Field(None, min_length=10)
    excerpt: Optional[str] = Field(None, max_length=500)
    featured_image: Optional[str] = None
    status: Optional[PostStatus] = None
    tags: Optional[List[str]] = None

class PostResponse(PostBase):
    id: int
    slug: str
    author: UserResponse
    tags: List[TagResponse]
    views: int
    created_at: datetime
    updated_at: datetime
    published_at: Optional[datetime]
    comments_count: int = 0
    
    class Config:
        from_attributes = True

class PostListResponse(BaseModel):
    posts: List[PostResponse]
    total: int
    page: int
    per_page: int
    pages: int

# Comment Schemas
class CommentBase(BaseModel):
    content: str = Field(..., min_length=1, max_length=1000)

class CommentCreate(CommentBase):
    post_id: int

class CommentResponse(CommentBase):
    id: int
    author: UserResponse
    is_approved: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

# AI Schemas
class AIContentRequest(BaseModel):
    prompt: str
    type: str = Field(..., regex="^(title|excerpt|content|tags)$")
    context: Optional[str] = None

class AIContentResponse(BaseModel):
    generated_text: str
    tokens_used: int
```

## ✅ Checkpoint 1

Before proceeding to API endpoints, ensure:
- [ ] Database models are created correctly
- [ ] Authentication system is implemented
- [ ] All schemas have proper validation
- [ ] Security utilities work as expected
- [ ] Configuration is properly set up

Continue to Part 2 for API implementation...


## ⏭️ Next Steps

Proceed to [Part 2](./part2.md)
