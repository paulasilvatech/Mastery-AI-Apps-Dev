# Exercise 2: Blog Platform with AI Features (Part 2)

## 📋 Step 2: API Implementation (15 minutes)

### 2.1 Database Setup

Create `backend/app/core/database.py`:

**Copilot Prompt Suggestion:**
```python
# Create database configuration:
# - SQLAlchemy engine with PostgreSQL
# - Session factory
# - Base class for models
# - Dependency to get database session
# - Database initialization function
```

**Expected Copilot Output:**
```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from .config import settings
from ..models.models import Base

engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    """Dependency to get database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    """Initialize database tables"""
    Base.metadata.create_all(bind=engine)
```

### 2.2 Authentication API

Create `backend/app/api/auth.py`:

**Copilot Prompt Suggestion:**
```python
# Create authentication endpoints:
# - POST /register - Create new user account
# - POST /login - Login with username/password, return JWT token
# - GET /me - Get current user info
# - PUT /me - Update current user
# Include validation, error handling, and proper status codes
```

**Expected Copilot Output:**
```python
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta

from ..core.database import get_db
from ..core.security import (
    get_password_hash, 
    verify_password, 
    create_access_token,
    get_current_user
)
from ..models.models import User
from ..schemas.schemas import UserCreate, UserResponse, Token, UserUpdate
from ..core.config import settings

router = APIRouter(prefix="/auth", tags=["authentication"])

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """Register new user"""
    # Check if user exists
    if db.query(User).filter(
        (User.username == user_data.username) | 
        (User.email == user_data.email)
    ).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username or email already registered"
        )
    
    # Create new user
    db_user = User(
        username=user_data.username,
        email=user_data.email,
        hashed_password=get_password_hash(user_data.password)
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    return db_user

@router.post("/login", response_model=Token)
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    """Login and get access token"""
    # Authenticate user
    user = db.query(User).filter(User.username == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Create access token
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username},
        expires_delta=access_token_expires
    )
    
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=UserResponse)
def get_current_user_info(current_user: User = Depends(get_current_user)):
    """Get current user information"""
    return current_user

@router.put("/me", response_model=UserResponse)
def update_current_user(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update current user information"""
    update_data = user_update.dict(exclude_unset=True)
    
    if "password" in update_data:
        update_data["hashed_password"] = get_password_hash(update_data.pop("password"))
    
    for field, value in update_data.items():
        setattr(current_user, field, value)
    
    db.commit()
    db.refresh(current_user)
    
    return current_user
```

### 2.3 Blog Posts API

Create `backend/app/api/posts.py`:

**Copilot Prompt Suggestion:**
```python
# Create blog post endpoints:
# - GET /posts - List posts with pagination, filtering by status, tag, author
# - POST /posts - Create new post (authenticated)
# - GET /posts/{slug} - Get single post by slug
# - PUT /posts/{id} - Update post (author or admin only)
# - DELETE /posts/{id} - Delete post (author or admin only)
# - POST /posts/{id}/view - Increment view count
# Include slug generation, tag handling, and proper permissions
```

**Expected Copilot Output:**
```python
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session, joinedload
from typing import Optional, List
from datetime import datetime
from slugify import slugify

from ..core.database import get_db
from ..core.security import get_current_user, get_current_admin_user
from ..models.models import Post, Tag, User, PostStatus
from ..schemas.schemas import (
    PostCreate, PostUpdate, PostResponse, 
    PostListResponse, TagCreate
)

router = APIRouter(prefix="/posts", tags=["posts"])

def get_or_create_tag(db: Session, tag_name: str) -> Tag:
    """Get existing tag or create new one"""
    tag = db.query(Tag).filter(Tag.name == tag_name).first()
    if not tag:
        tag = Tag(name=tag_name, slug=slugify(tag_name))
        db.add(tag)
        db.flush()
    return tag

@router.get("", response_model=PostListResponse)
def get_posts(
    page: int = Query(1, ge=1),
    per_page: int = Query(10, ge=1, le=100),
    status: Optional[PostStatus] = None,
    tag: Optional[str] = None,
    author_id: Optional[int] = None,
    db: Session = Depends(get_db)
):
    """Get paginated list of posts"""
    query = db.query(Post).options(
        joinedload(Post.author),
        joinedload(Post.tags)
    )
    
    # Apply filters
    if status:
        query = query.filter(Post.status == status)
    else:
        # Default to published posts for non-authenticated users
        query = query.filter(Post.status == PostStatus.PUBLISHED)
    
    if tag:
        query = query.join(Post.tags).filter(Tag.slug == tag)
    
    if author_id:
        query = query.filter(Post.author_id == author_id)
    
    # Pagination
    total = query.count()
    posts = query.offset((page - 1) * per_page).limit(per_page).all()
    
    # Add comment count
    for post in posts:
        post.comments_count = len(post.comments)
    
    return {
        "posts": posts,
        "total": total,
        "page": page,
        "per_page": per_page,
        "pages": (total + per_page - 1) // per_page
    }

@router.post("", response_model=PostResponse, status_code=status.HTTP_201_CREATED)
def create_post(
    post_data: PostCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create new blog post"""
    # Generate unique slug
    base_slug = slugify(post_data.title)
    slug = base_slug
    counter = 1
    
    while db.query(Post).filter(Post.slug == slug).first():
        slug = f"{base_slug}-{counter}"
        counter += 1
    
    # Create post
    post_dict = post_data.dict(exclude={"tags"})
    db_post = Post(
        **post_dict,
        slug=slug,
        author_id=current_user.id
    )
    
    # Handle tags
    if post_data.tags:
        for tag_name in post_data.tags:
            tag = get_or_create_tag(db, tag_name)
            db_post.tags.append(tag)
    
    # Set published_at if publishing
    if post_data.status == PostStatus.PUBLISHED:
        db_post.published_at = datetime.utcnow()
    
    db.add(db_post)
    db.commit()
    db.refresh(db_post)
    
    return db_post

@router.get("/{slug}", response_model=PostResponse)
def get_post(slug: str, db: Session = Depends(get_db)):
    """Get single post by slug"""
    post = db.query(Post).options(
        joinedload(Post.author),
        joinedload(Post.tags),
        joinedload(Post.comments)
    ).filter(Post.slug == slug).first()
    
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    post.comments_count = len([c for c in post.comments if c.is_approved])
    return post

@router.put("/{post_id}", response_model=PostResponse)
def update_post(
    post_id: int,
    post_update: PostUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update blog post"""
    post = db.query(Post).filter(Post.id == post_id).first()
    
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    # Check permissions
    if post.author_id != current_user.id and not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    # Update fields
    update_data = post_update.dict(exclude_unset=True, exclude={"tags"})
    
    # Update slug if title changed
    if "title" in update_data:
        new_slug = slugify(update_data["title"])
        if new_slug != post.slug:
            # Check if new slug exists
            existing = db.query(Post).filter(
                Post.slug == new_slug,
                Post.id != post_id
            ).first()
            
            if existing:
                counter = 1
                while db.query(Post).filter(
                    Post.slug == f"{new_slug}-{counter}",
                    Post.id != post_id
                ).first():
                    counter += 1
                new_slug = f"{new_slug}-{counter}"
            
            post.slug = new_slug
    
    # Update other fields
    for field, value in update_data.items():
        setattr(post, field, value)
    
    # Update published_at
    if post_update.status == PostStatus.PUBLISHED and not post.published_at:
        post.published_at = datetime.utcnow()
    
    # Update tags if provided
    if post_update.tags is not None:
        post.tags.clear()
        for tag_name in post_update.tags:
            tag = get_or_create_tag(db, tag_name)
            post.tags.append(tag)
    
    db.commit()
    db.refresh(post)
    
    return post

@router.delete("/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_post(
    post_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete blog post"""
    post = db.query(Post).filter(Post.id == post_id).first()
    
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    # Check permissions
    if post.author_id != current_user.id and not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    db.delete(post)
    db.commit()

@router.post("/{post_id}/view", status_code=status.HTTP_200_OK)
def increment_view_count(post_id: int, db: Session = Depends(get_db)):
    """Increment post view count"""
    post = db.query(Post).filter(Post.id == post_id).first()
    
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    post.views += 1
    db.commit()
    
    return {"views": post.views}
```

### 2.4 Comments API

Create `backend/app/api/comments.py`:

**Copilot Prompt Suggestion:**
```python
# Create comment endpoints:
# - GET /posts/{post_id}/comments - Get comments for a post
# - POST /comments - Create new comment (authenticated)
# - PUT /comments/{id}/approve - Approve/reject comment (admin only)
# - DELETE /comments/{id} - Delete comment (author or admin)
# Include nested comment support and moderation
```

**Expected Copilot Output:**
```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from ..core.database import get_db
from ..core.security import get_current_user, get_current_admin_user
from ..models.models import Comment, Post, User
from ..schemas.schemas import CommentCreate, CommentResponse

router = APIRouter(tags=["comments"])

@router.get("/posts/{post_id}/comments", response_model=List[CommentResponse])
def get_post_comments(
    post_id: int,
    include_unapproved: bool = False,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get comments for a specific post"""
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    query = db.query(Comment).filter(Comment.post_id == post_id)
    
    # Only show approved comments unless user is admin or post author
    if not include_unapproved or (
        not current_user.is_admin and post.author_id != current_user.id
    ):
        query = query.filter(Comment.is_approved == True)
    
    comments = query.order_by(Comment.created_at.desc()).all()
    return comments

@router.post("/comments", response_model=CommentResponse, status_code=status.HTTP_201_CREATED)
def create_comment(
    comment_data: CommentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create new comment"""
    # Verify post exists
    post = db.query(Post).filter(Post.id == comment_data.post_id).first()
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    # Create comment
    db_comment = Comment(
        post_id=comment_data.post_id,
        author_id=current_user.id,
        content=comment_data.content,
        is_approved=True  # Auto-approve for now, can add moderation logic
    )
    
    db.add(db_comment)
    db.commit()
    db.refresh(db_comment)
    
    return db_comment

@router.put("/comments/{comment_id}/approve")
def toggle_comment_approval(
    comment_id: int,
    approved: bool,
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Approve or reject a comment (admin only)"""
    comment = db.query(Comment).filter(Comment.id == comment_id).first()
    
    if not comment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Comment not found"
        )
    
    comment.is_approved = approved
    db.commit()
    
    return {"message": f"Comment {'approved' if approved else 'rejected'}"}

@router.delete("/comments/{comment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_comment(
    comment_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a comment"""
    comment = db.query(Comment).filter(Comment.id == comment_id).first()
    
    if not comment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Comment not found"
        )
    
    # Check permissions
    if comment.author_id != current_user.id and not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    db.delete(comment)
    db.commit()
```

### 2.5 File Upload Service

Create `backend/app/services/upload.py`:

**Copilot Prompt Suggestion:**
```python
# Create file upload service:
# - Handle image uploads with validation
# - Resize images to multiple sizes (thumbnail, medium, large)
# - Generate unique filenames
# - Save to local storage (can be extended to S3)
# - Return file URLs
# Include error handling and file type validation
```

**Expected Copilot Output:**
```python
import os
import uuid
from pathlib import Path
from typing import Optional, Tuple
from PIL import Image
from fastapi import UploadFile, HTTPException
from ..core.config import settings

class UploadService:
    def __init__(self):
        self.upload_dir = Path(settings.UPLOAD_DIR)
        self.upload_dir.mkdir(exist_ok=True)
        
        # Create subdirectories
        for subdir in ['original', 'thumbnail', 'medium', 'large']:
            (self.upload_dir / subdir).mkdir(exist_ok=True)
    
    def validate_file(self, file: UploadFile) -> None:
        """Validate uploaded file"""
        # Check file size
        file.file.seek(0, 2)  # Move to end
        file_size = file.file.tell()
        file.file.seek(0)  # Reset to beginning
        
        if file_size > settings.MAX_UPLOAD_SIZE:
            raise HTTPException(
                status_code=400,
                detail=f"File too large. Max size: {settings.MAX_UPLOAD_SIZE // 1024 // 1024}MB"
            )
        
        # Check file extension
        ext = Path(file.filename).suffix.lower()
        if ext not in settings.ALLOWED_EXTENSIONS:
            raise HTTPException(
                status_code=400,
                detail=f"File type not allowed. Allowed types: {', '.join(settings.ALLOWED_EXTENSIONS)}"
            )
    
    def generate_filename(self, original_filename: str) -> str:
        """Generate unique filename"""
        ext = Path(original_filename).suffix
        return f"{uuid.uuid4()}{ext}"
    
    def resize_image(self, image_path: Path, size: Tuple[int, int], output_dir: str) -> str:
        """Resize image and save to output directory"""
        with Image.open(image_path) as img:
            # Convert RGBA to RGB if necessary
            if img.mode == 'RGBA':
                rgb_img = Image.new('RGB', img.size, (255, 255, 255))
                rgb_img.paste(img, mask=img.split()[3])
                img = rgb_img
            
            # Resize maintaining aspect ratio
            img.thumbnail(size, Image.Resampling.LANCZOS)
            
            # Save resized image
            output_path = self.upload_dir / output_dir / image_path.name
            img.save(output_path, 'JPEG', quality=85, optimize=True)
            
            return str(output_path.relative_to(self.upload_dir))
    
    async def upload_image(self, file: UploadFile) -> dict:
        """Upload and process image"""
        self.validate_file(file)
        
        # Generate unique filename
        filename = self.generate_filename(file.filename)
        original_path = self.upload_dir / 'original' / filename
        
        # Save original file
        content = await file.read()
        with open(original_path, 'wb') as f:
            f.write(content)
        
        # Create different sizes
        sizes = {
            'thumbnail': (150, 150),
            'medium': (800, 600),
            'large': (1920, 1080)
        }
        
        urls = {
            'original': f"/uploads/original/{filename}"
        }
        
        for size_name, dimensions in sizes.items():
            resized_path = self.resize_image(original_path, dimensions, size_name)
            urls[size_name] = f"/uploads/{resized_path}"
        
        return urls
    
    def delete_image(self, filename: str) -> None:
        """Delete image and all its sizes"""
        for subdir in ['original', 'thumbnail', 'medium', 'large']:
            file_path = self.upload_dir / subdir / filename
            if file_path.exists():
                file_path.unlink()

upload_service = UploadService()
```

## ✅ Checkpoint 2

Before proceeding to the main application, verify:
- [ ] All API endpoints are implemented
- [ ] Authentication flow works correctly
- [ ] File upload service handles images
- [ ] Database relationships are working
- [ ] Permissions are properly enforced

Continue to Part 3 for main application setup...


## ⏭️ Next Steps

Proceed to [Part 3](./part3.md)
