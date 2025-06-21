# Exercise 3: Complete Application (⭐⭐⭐ Hard) - Part 2

## 🚀 Part 2: Implementing API Endpoints and Web Interface

Now let's implement authentication, API endpoints, and create a real-time web interface.

### Step 6: Implement Authentication

Create `starter/backend/app/core/auth.py` for authentication utilities:

**🤖 Copilot Prompt Suggestion #6:**
```python
# Create authentication utilities:
# - Password hashing with bcrypt
# - JWT token creation and validation
# - OAuth2 password bearer scheme
# - Get current user dependency
# - Permission checking decorators
# Include proper error handling and token expiration
```

**Expected Output:**
```python
from datetime import datetime, timedelta
from typing import Optional, Union
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.config import settings
from app.db.database import get_db
from app.models.database import User
from app.models.schemas import TokenData
import logging

logger = logging.getLogger(__name__)

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# OAuth2 scheme
oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl=f"{settings.API_V1_PREFIX}/auth/login",
    scheme_name="JWT"
)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against a hash."""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Hash a password."""
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """
    Create a JWT access token.
    
    Args:
        data: Data to encode in the token
        expires_delta: Token expiration time
    
    Returns:
        Encoded JWT token
    """
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire, "type": "access"})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def create_refresh_token(data: dict) -> str:
    """Create a JWT refresh token."""
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=settings.REFRESH_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire, "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
) -> User:
    """
    Get the current authenticated user.
    
    Args:
        token: JWT token from request
        db: Database session
    
    Returns:
        Current user object
    
    Raises:
        HTTPException: If authentication fails
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        token_type: str = payload.get("type")
        
        if user_id is None or token_type != "access":
            raise credentials_exception
            
        token_data = TokenData(user_id=user_id)
    except JWTError as e:
        logger.error(f"JWT decode error: {e}")
        raise credentials_exception
    
    # Get user from database
    result = await db.execute(
        select(User).where(User.id == token_data.user_id)
    )
    user = result.scalars().first()
    
    if user is None:
        raise credentials_exception
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Inactive user"
        )
    
    return user

async def get_current_active_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """Get current active user."""
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Inactive user"
        )
    return current_user

async def get_current_superuser(
    current_user: User = Depends(get_current_user)
) -> User:
    """Get current superuser."""
    if not current_user.is_superuser:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    return current_user

# Authentication utilities
async def authenticate_user(db: AsyncSession, username: str, password: str) -> Optional[User]:
    """
    Authenticate a user.
    
    Args:
        db: Database session
        username: Username or email
        password: Plain password
    
    Returns:
        User if authenticated, None otherwise
    """
    # Try to find user by username or email
    result = await db.execute(
        select(User).where(
            (User.username == username) | (User.email == username)
        )
    )
    user = result.scalars().first()
    
    if not user:
        return None
    
    if not verify_password(password, user.hashed_password):
        return None
    
    return user

# Permission checking decorator
def require_permission(permission: str):
    """
    Decorator to check user permissions.
    
    Args:
        permission: Required permission
    """
    def decorator(func):
        async def wrapper(*args, current_user: User = Depends(get_current_user), **kwargs):
            # In a real application, you'd check user permissions here
            # For now, we'll just check if user is active
            if not current_user.is_active:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Not enough permissions"
                )
            return await func(*args, current_user=current_user, **kwargs)
        return wrapper
    return decorator
```

### Step 7: Create Authentication API

Create `starter/backend/app/api/v1/auth.py`:

**🤖 Copilot Prompt Suggestion #7:**
```python
# Create authentication endpoints:
# - POST /login - Login with username/password
# - POST /register - Register new user
# - POST /refresh - Refresh access token
# - GET /me - Get current user info
# - POST /logout - Logout (optional token blacklist)
# Include rate limiting and proper error responses
```

**Expected Output:**
```python
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import timedelta
from app.db.database import get_db
from app.models.database import User
from app.models.schemas import (
    UserCreate, UserResponse, Token, Login
)
from app.core.auth import (
    authenticate_user, create_access_token, create_refresh_token,
    get_password_hash, get_current_user, verify_password
)
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(
    user_data: UserCreate,
    db: AsyncSession = Depends(get_db)
):
    """
    Register a new user.
    
    Args:
        user_data: User registration data
        db: Database session
    
    Returns:
        Created user
    
    Raises:
        HTTPException: If username/email already exists
    """
    # Check if user already exists
    result = await db.execute(
        select(User).where(
            (User.username == user_data.username) | 
            (User.email == user_data.email)
        )
    )
    if result.scalars().first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username or email already registered"
        )
    
    # Create new user
    user = User(
        username=user_data.username,
        email=user_data.email,
        hashed_password=get_password_hash(user_data.password),
        is_active=True,
        is_superuser=False
    )
    
    db.add(user)
    await db.commit()
    await db.refresh(user)
    
    logger.info(f"New user registered: {user.username}")
    
    return user

@router.post("/login", response_model=Token)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db)
):
    """
    Login with username/password.
    
    Args:
        form_data: OAuth2 form with username and password
        db: Database session
    
    Returns:
        Access and refresh tokens
    
    Raises:
        HTTPException: If authentication fails
    """
    user = await authenticate_user(db, form_data.username, form_data.password)
    
    if not user:
        logger.warning(f"Failed login attempt for: {form_data.username}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Create tokens
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.id, "username": user.username},
        expires_delta=access_token_expires
    )
    refresh_token = create_refresh_token(
        data={"sub": user.id}
    )
    
    logger.info(f"User logged in: {user.username}")
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    }

@router.post("/refresh", response_model=Token)
async def refresh_token(
    refresh_token: str,
    db: AsyncSession = Depends(get_db)
):
    """
    Refresh access token using refresh token.
    
    Args:
        refresh_token: JWT refresh token
        db: Database session
    
    Returns:
        New access token
    
    Raises:
        HTTPException: If refresh token is invalid
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid refresh token",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        # Decode refresh token
        from jose import jwt
        payload = jwt.decode(
            refresh_token, 
            settings.SECRET_KEY, 
            algorithms=[settings.ALGORITHM]
        )
        
        user_id: str = payload.get("sub")
        token_type: str = payload.get("type")
        
        if user_id is None or token_type != "refresh":
            raise credentials_exception
            
    except Exception:
        raise credentials_exception
    
    # Get user
    result = await db.execute(
        select(User).where(User.id == user_id)
    )
    user = result.scalars().first()
    
    if not user or not user.is_active:
        raise credentials_exception
    
    # Create new access token
    access_token = create_access_token(
        data={"sub": user.id, "username": user.username}
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    }

@router.get("/me", response_model=UserResponse)
async def get_current_user_info(
    current_user: User = Depends(get_current_user)
):
    """
    Get current user information.
    
    Args:
        current_user: Current authenticated user
    
    Returns:
        User information
    """
    return current_user

@router.post("/logout")
async def logout(
    current_user: User = Depends(get_current_user)
):
    """
    Logout current user.
    
    Note: In a production application, you might want to:
    - Invalidate the token (token blacklist)
    - Clear refresh tokens
    - Log the logout event
    
    Args:
        current_user: Current authenticated user
    
    Returns:
        Success message
    """
    logger.info(f"User logged out: {current_user.username}")
    
    # In a real application, you would:
    # 1. Add token to blacklist
    # 2. Clear any server-side sessions
    # 3. Invalidate refresh tokens
    
    return {"message": "Successfully logged out"}

@router.put("/me", response_model=UserResponse)
async def update_current_user(
    user_update: dict,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Update current user information.
    
    Args:
        user_update: Fields to update
        current_user: Current authenticated user
        db: Database session
    
    Returns:
        Updated user
    """
    # Update allowed fields
    allowed_fields = {"email", "username"}
    
    for field, value in user_update.items():
        if field in allowed_fields and value is not None:
            setattr(current_user, field, value)
    
    # Handle password update separately
    if "password" in user_update and user_update["password"]:
        current_user.hashed_password = get_password_hash(user_update["password"])
    
    await db.commit()
    await db.refresh(current_user)
    
    return current_user
```

### Step 8: Create Task API Endpoints

Create `starter/backend/app/api/v1/tasks.py`:

**🤖 Copilot Prompt Suggestion #8:**
```python
# Create task CRUD endpoints:
# - GET /tasks - List tasks with pagination and filters
# - POST /tasks - Create new task
# - GET /tasks/{id} - Get task by ID
# - PUT /tasks/{id} - Update task
# - DELETE /tasks/{id} - Delete task
# - POST /tasks/{id}/complete - Mark task as complete
# - GET /tasks/stats - Get task statistics
# Include proper permissions, filtering, and sorting
```

**Expected Output:**
```python
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_
from sqlalchemy.orm import selectinload
from typing import List, Optional
from datetime import datetime
from app.db.database import get_db
from app.models.database import Task, User, Tag, TaskStatus, TaskPriority
from app.models.schemas import (
    TaskCreate, TaskUpdate, TaskResponse, TaskFilter,
    PaginationParams, PaginatedResponse
)
from app.core.auth import get_current_user
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

@router.get("/", response_model=PaginatedResponse)
async def list_tasks(
    # Pagination
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=settings.MAX_PAGE_SIZE),
    # Filters
    status: Optional[TaskStatus] = None,
    priority: Optional[TaskPriority] = None,
    is_overdue: Optional[bool] = None,
    tag_ids: Optional[List[int]] = Query(None),
    search: Optional[str] = None,
    # Sorting
    sort_by: str = Query("created_at", regex="^(created_at|due_date|priority|title)$"),
    sort_order: str = Query("desc", regex="^(asc|desc)$"),
    # Auth
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    List tasks with pagination and filters.
    
    Args:
        page: Page number
        per_page: Items per page
        status: Filter by status
        priority: Filter by priority
        is_overdue: Filter overdue tasks
        tag_ids: Filter by tag IDs
        search: Search in title and description
        sort_by: Sort field
        sort_order: Sort order (asc/desc)
        current_user: Current authenticated user
        db: Database session
    
    Returns:
        Paginated list of tasks
    """
    # Build query
    query = select(Task).where(Task.user_id == current_user.id)
    
    # Apply filters
    filters = []
    
    if status:
        filters.append(Task.status == status)
    
    if priority:
        filters.append(Task.priority == priority)
    
    if is_overdue is not None:
        if is_overdue:
            filters.append(
                and_(
                    Task.due_date < datetime.now(),
                    Task.status.not_in([TaskStatus.DONE, TaskStatus.ARCHIVED])
                )
            )
        else:
            filters.append(
                or_(
                    Task.due_date >= datetime.now(),
                    Task.due_date.is_(None),
                    Task.status.in_([TaskStatus.DONE, TaskStatus.ARCHIVED])
                )
            )
    
    if tag_ids:
        # Filter by tags (tasks that have ANY of the specified tags)
        query = query.join(Task.tags).where(Tag.id.in_(tag_ids))
    
    if search:
        search_filter = or_(
            Task.title.ilike(f"%{search}%"),
            Task.description.ilike(f"%{search}%")
        )
        filters.append(search_filter)
    
    if filters:
        query = query.where(and_(*filters))
    
    # Add sorting
    sort_column = getattr(Task, sort_by)
    if sort_order == "desc":
        query = query.order_by(sort_column.desc())
    else:
        query = query.order_by(sort_column.asc())
    
    # Include tags in the query
    query = query.options(selectinload(Task.tags))
    
    # Count total items
    count_query = select(func.count()).select_from(Task).where(Task.user_id == current_user.id)
    if filters:
        count_query = count_query.where(and_(*filters))
    
    total_result = await db.execute(count_query)
    total = total_result.scalar()
    
    # Apply pagination
    query = query.offset((page - 1) * per_page).limit(per_page)
    
    # Execute query
    result = await db.execute(query)
    tasks = result.scalars().all()
    
    # Convert to response model
    task_responses = [TaskResponse.model_validate(task) for task in tasks]
    
    return PaginatedResponse(
        items=task_responses,
        total=total,
        page=page,
        per_page=per_page,
        pages=(total + per_page - 1) // per_page
    )

@router.post("/", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
async def create_task(
    task_data: TaskCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a new task.
    
    Args:
        task_data: Task creation data
        current_user: Current authenticated user
        db: Database session
    
    Returns:
        Created task
    """
    # Create task
    task = Task(
        **task_data.model_dump(exclude={"tag_ids"}),
        user_id=current_user.id
    )
    
    # Add tags if specified
    if task_data.tag_ids:
        result = await db.execute(
            select(Tag).where(Tag.id.in_(task_data.tag_ids))
        )
        tags = result.scalars().all()
        task.tags = tags
    
    db.add(task)
    await db.commit()
    await db.refresh(task)
    
    # Load relationships
    await db.refresh(task, ["tags"])
    
    logger.info(f"Task created: {task.id} by user: {current_user.username}")
    
    return TaskResponse.model_validate(task)

@router.get("/{task_id}", response_model=TaskResponse)
async def get_task(
    task_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get task by ID.
    
    Args:
        task_id: Task ID
        current_user: Current authenticated user
        db: Database session
    
    Returns:
        Task details
    
    Raises:
        HTTPException: If task not found or unauthorized
    """
    result = await db.execute(
        select(Task)
        .where(Task.id == task_id)
        .options(selectinload(Task.tags))
    )
    task = result.scalars().first()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    
    if task.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to access this task"
        )
    
    return TaskResponse.model_validate(task)

@router.put("/{task_id}", response_model=TaskResponse)
async def update_task(
    task_id: str,
    task_update: TaskUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Update a task.
    
    Args:
        task_id: Task ID
        task_update: Fields to update
        current_user: Current authenticated user
        db: Database session
    
    Returns:
        Updated task
    
    Raises:
        HTTPException: If task not found or unauthorized
    """
    # Get task
    result = await db.execute(
        select(Task).where(Task.id == task_id)
    )
    task = result.scalars().first()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    
    if task.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this task"
        )
    
    # Update fields
    update_data = task_update.model_dump(exclude_unset=True)
    
    # Handle tags separately
    if "tag_ids" in update_data:
        tag_ids = update_data.pop("tag_ids")
        if tag_ids is not None:
            result = await db.execute(
                select(Tag).where(Tag.id.in_(tag_ids))
            )
            tags = result.scalars().all()
            task.tags = tags
    
    # Update other fields
    for field, value in update_data.items():
        setattr(task, field, value)
    
    # Update timestamp
    task.updated_at = datetime.now()
    
    # Set completed_at if marking as done
    if task_update.status == TaskStatus.DONE and task.completed_at is None:
        task.completed_at = datetime.now()
    elif task_update.status != TaskStatus.DONE:
        task.completed_at = None
    
    await db.commit()
    await db.refresh(task, ["tags"])
    
    logger.info(f"Task updated: {task.id} by user: {current_user.username}")
    
    return TaskResponse.model_validate(task)

@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_task(
    task_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Delete a task.
    
    Args:
        task_id: Task ID
        current_user: Current authenticated user
        db: Database session
    
    Raises:
        HTTPException: If task not found or unauthorized
    """
    # Get task
    result = await db.execute(
        select(Task).where(Task.id == task_id)
    )
    task = result.scalars().first()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    
    if task.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to delete this task"
        )
    
    await db.delete(task)
    await db.commit()
    
    logger.info(f"Task deleted: {task.id} by user: {current_user.username}")

@router.post("/{task_id}/complete", response_model=TaskResponse)
async def complete_task(
    task_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Mark a task as complete.
    
    Args:
        task_id: Task ID
        current_user: Current authenticated user
        db: Database session
    
    Returns:
        Updated task
    """
    # Get and update task
    result = await db.execute(
        select(Task)
        .where(Task.id == task_id)
        .options(selectinload(Task.tags))
    )
    task = result.scalars().first()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    
    if task.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this task"
        )
    
    if task.status == TaskStatus.DONE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Task is already completed"
        )
    
    task.status = TaskStatus.DONE
    task.completed_at = datetime.now()
    task.updated_at = datetime.now()
    
    await db.commit()
    await db.refresh(task)
    
    return TaskResponse.model_validate(task)

@router.get("/stats/summary")
async def get_task_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get task statistics for the current user.
    
    Args:
        current_user: Current authenticated user
        db: Database session
    
    Returns:
        Task statistics
    """
    # Build statistics query
    stats_query = select(
        func.count(Task.id).label("total"),
        func.sum(func.cast(Task.status == TaskStatus.TODO, type_=int)).label("todo"),
        func.sum(func.cast(Task.status == TaskStatus.IN_PROGRESS, type_=int)).label("in_progress"),
        func.sum(func.cast(Task.status == TaskStatus.DONE, type_=int)).label("done"),
        func.sum(func.cast(Task.priority == TaskPriority.HIGH, type_=int)).label("high_priority"),
        func.sum(
            func.cast(
                and_(
                    Task.due_date < datetime.now(),
                    Task.status != TaskStatus.DONE
                ),
                type_=int
            )
        ).label("overdue")
    ).where(Task.user_id == current_user.id)
    
    result = await db.execute(stats_query)
    stats = result.first()
    
    # Get completion rate for last 7 days
    from datetime import timedelta
    week_ago = datetime.now() - timedelta(days=7)
    
    completed_query = select(func.count(Task.id)).where(
        and_(
            Task.user_id == current_user.id,
            Task.status == TaskStatus.DONE,
            Task.completed_at >= week_ago
        )
    )
    
    completed_result = await db.execute(completed_query)
    completed_this_week = completed_result.scalar()
    
    return {
        "total_tasks": stats.total or 0,
        "by_status": {
            "todo": stats.todo or 0,
            "in_progress": stats.in_progress or 0,
            "done": stats.done or 0
        },
        "high_priority": stats.high_priority or 0,
        "overdue": stats.overdue or 0,
        "completed_this_week": completed_this_week or 0,
        "completion_rate": round((stats.done or 0) / (stats.total or 1) * 100, 2)
    }
```

### Step 9: Create Web Interface

Create `starter/frontend/index.html`:

**🤖 Copilot Prompt Suggestion #9:**
```html
<!-- Create a modern, responsive web interface with:
- Login/Register forms
- Task list with real-time updates
- Task creation and editing modals
- Filtering and search
- Statistics dashboard
- WebSocket connection for live updates
Use Tailwind CSS for styling and Alpine.js for interactivity -->
```

**Expected Output:**
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Task Manager - AI Powered</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="style.css">
</head>
<body class="bg-gray-50">
    <div x-data="taskManager()" x-init="init()" class="min-h-screen">
        <!-- Navigation -->
        <nav class="bg-white shadow-sm border-b border-gray-200">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div class="flex justify-between h-16">
                    <div class="flex items-center">
                        <h1 class="text-xl font-semibold text-gray-900">
                            <i class="fas fa-tasks mr-2"></i>Task Manager
                        </h1>
                    </div>
                    <div class="flex items-center space-x-4" x-show="isAuthenticated">
                        <span class="text-sm text-gray-600">
                            Welcome, <span x-text="currentUser.username" class="font-medium"></span>
                        </span>
                        <button @click="logout()" 
                                class="text-sm text-red-600 hover:text-red-800">
                            <i class="fas fa-sign-out-alt mr-1"></i>Logout
                        </button>
                    </div>
                </div>
            </div>
        </nav>

        <!-- Login/Register Modal -->
        <div x-show="!isAuthenticated" 
             class="fixed inset-0 bg-gray-600 bg-opacity-50 flex items-center justify-center z-50">
            <div class="bg-white rounded-lg shadow-xl p-6 w-full max-w-md">
                <h2 class="text-2xl font-bold mb-6 text-center">
                    <span x-text="authMode === 'login' ? 'Login' : 'Register'"></span>
                </h2>
                
                <form @submit.prevent="authMode === 'login' ? login() : register()">
                    <div class="mb-4">
                        <label class="block text-gray-700 text-sm font-bold mb-2">
                            Username
                        </label>
                        <input x-model="authForm.username" 
                               type="text" 
                               required
                               class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                    </div>
                    
                    <div class="mb-4" x-show="authMode === 'register'">
                        <label class="block text-gray-700 text-sm font-bold mb-2">
                            Email
                        </label>
                        <input x-model="authForm.email" 
                               type="email" 
                               :required="authMode === 'register'"
                               class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                    </div>
                    
                    <div class="mb-6">
                        <label class="block text-gray-700 text-sm font-bold mb-2">
                            Password
                        </label>
                        <input x-model="authForm.password" 
                               type="password" 
                               required
                               class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                    </div>
                    
                    <div class="mb-4" x-show="authError">
                        <p class="text-red-500 text-sm" x-text="authError"></p>
                    </div>
                    
                    <button type="submit" 
                            class="w-full bg-blue-500 text-white font-bold py-2 px-4 rounded hover:bg-blue-600">
                        <span x-text="authMode === 'login' ? 'Login' : 'Register'"></span>
                    </button>
                </form>
                
                <p class="text-center mt-4 text-sm text-gray-600">
                    <span x-show="authMode === 'login'">
                        Don't have an account? 
                        <a @click="authMode = 'register'" class="text-blue-500 hover:text-blue-700 cursor-pointer">
                            Register
                        </a>
                    </span>
                    <span x-show="authMode === 'register'">
                        Already have an account? 
                        <a @click="authMode = 'login'" class="text-blue-500 hover:text-blue-700 cursor-pointer">
                            Login
                        </a>
                    </span>
                </p>
            </div>
        </div>

        <!-- Main Content -->
        <div x-show="isAuthenticated" class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
            <!-- Statistics -->
            <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
                <div class="bg-white rounded-lg shadow p-6">
                    <div class="flex items-center">
                        <div class="p-3 bg-blue-100 rounded-full">
                            <i class="fas fa-tasks text-blue-600"></i>
                        </div>
                        <div class="ml-4">
                            <p class="text-sm text-gray-600">Total Tasks</p>
                            <p class="text-2xl font-semibold" x-text="stats.total_tasks || 0"></p>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow p-6">
                    <div class="flex items-center">
                        <div class="p-3 bg-yellow-100 rounded-full">
                            <i class="fas fa-clock text-yellow-600"></i>
                        </div>
                        <div class="ml-4">
                            <p class="text-sm text-gray-600">In Progress</p>
                            <p class="text-2xl font-semibold" x-text="stats.by_status?.in_progress || 0"></p>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow p-6">
                    <div class="flex items-center">
                        <div class="p-3 bg-green-100 rounded-full">
                            <i class="fas fa-check-circle text-green-600"></i>
                        </div>
                        <div class="ml-4">
                            <p class="text-sm text-gray-600">Completed</p>
                            <p class="text-2xl font-semibold" x-text="stats.by_status?.done || 0"></p>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow p-6">
                    <div class="flex items-center">
                        <div class="p-3 bg-red-100 rounded-full">
                            <i class="fas fa-exclamation-triangle text-red-600"></i>
                        </div>
                        <div class="ml-4">
                            <p class="text-sm text-gray-600">Overdue</p>
                            <p class="text-2xl font-semibold" x-text="stats.overdue || 0"></p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Actions Bar -->
            <div class="bg-white rounded-lg shadow p-4 mb-6">
                <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
                    <button @click="showTaskModal = true; editingTask = null; resetTaskForm()" 
                            class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
                        <i class="fas fa-plus mr-2"></i>New Task
                    </button>
                    
                    <div class="flex flex-col md:flex-row gap-4 flex-1 md:ml-4">
                        <input x-model="searchQuery" 
                               @input="searchTasks()"
                               type="text" 
                               placeholder="Search tasks..."
                               class="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                        
                        <select x-model="filterStatus" 
                                @change="loadTasks()"
                                class="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                            <option value="">All Status</option>
                            <option value="todo">To Do</option>
                            <option value="in_progress">In Progress</option>
                            <option value="done">Done</option>
                        </select>
                        
                        <select x-model="filterPriority" 
                                @change="loadTasks()"
                                class="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                            <option value="">All Priority</option>
                            <option value="low">Low</option>
                            <option value="medium">Medium</option>
                            <option value="high">High</option>
                            <option value="urgent">Urgent</option>
                        </select>
                    </div>
                </div>
            </div>

            <!-- Task List -->
            <div class="bg-white rounded-lg shadow">
                <div class="px-6 py-4 border-b border-gray-200">
                    <h3 class="text-lg font-semibold">Tasks</h3>
                </div>
                
                <div class="divide-y divide-gray-200" x-show="tasks.length > 0">
                    <template x-for="task in tasks" :key="task.id">
                        <div class="p-6 hover:bg-gray-50 transition-colors">
                            <div class="flex items-start justify-between">
                                <div class="flex-1">
                                    <div class="flex items-center">
                                        <input type="checkbox" 
                                               :checked="task.status === 'done'"
                                               @change="toggleTaskComplete(task)"
                                               class="mr-3 h-5 w-5 text-blue-600 rounded focus:ring-blue-500">
                                        
                                        <h4 class="text-lg font-medium" 
                                            :class="{'line-through text-gray-500': task.status === 'done'}"
                                            x-text="task.title"></h4>
                                        
                                        <span class="ml-3 px-2 py-1 text-xs rounded-full"
                                              :class="{
                                                  'bg-red-100 text-red-800': task.priority === 'urgent',
                                                  'bg-orange-100 text-orange-800': task.priority === 'high',
                                                  'bg-yellow-100 text-yellow-800': task.priority === 'medium',
                                                  'bg-green-100 text-green-800': task.priority === 'low'
                                              }"
                                              x-text="task.priority"></span>
                                    </div>
                                    
                                    <p class="mt-1 text-sm text-gray-600" 
                                       x-text="task.description"></p>
                                    
                                    <div class="mt-2 flex items-center text-sm text-gray-500">
                                        <span x-show="task.due_date" class="mr-4">
                                            <i class="fas fa-calendar mr-1"></i>
                                            <span x-text="formatDate(task.due_date)"></span>
                                            <span x-show="isOverdue(task)" class="text-red-600 font-semibold">
                                                (Overdue)
                                            </span>
                                        </span>
                                        
                                        <span class="mr-4">
                                            <i class="fas fa-info-circle mr-1"></i>
                                            <span x-text="task.status.replace('_', ' ')"></span>
                                        </span>
                                    </div>
                                    
                                    <div class="mt-2" x-show="task.tags && task.tags.length > 0">
                                        <template x-for="tag in task.tags" :key="tag.id">
                                            <span class="inline-block px-2 py-1 mr-2 text-xs rounded-full"
                                                  :style="`background-color: ${tag.color}20; color: ${tag.color}`"
                                                  x-text="`#${tag.name}`"></span>
                                        </template>
                                    </div>
                                </div>
                                
                                <div class="flex items-center ml-4 space-x-2">
                                    <button @click="editTask(task)"
                                            class="text-blue-600 hover:text-blue-800">
                                        <i class="fas fa-edit"></i>
                                    </button>
                                    <button @click="deleteTask(task.id)"
                                            class="text-red-600 hover:text-red-800">
                                        <i class="fas fa-trash"></i>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </template>
                </div>
                
                <div x-show="tasks.length === 0" class="p-8 text-center text-gray-500">
                    <i class="fas fa-inbox text-4xl mb-4"></i>
                    <p>No tasks found. Create your first task!</p>
                </div>
            </div>
        </div>

        <!-- Task Modal -->
        <div x-show="showTaskModal" 
             x-transition
             class="fixed inset-0 bg-gray-600 bg-opacity-50 flex items-center justify-center z-50">
            <div class="bg-white rounded-lg shadow-xl p-6 w-full max-w-lg max-h-[90vh] overflow-y-auto">
                <h3 class="text-xl font-bold mb-4">
                    <span x-text="editingTask ? 'Edit Task' : 'New Task'"></span>
                </h3>
                
                <form @submit.prevent="saveTask()">
                    <div class="mb-4">
                        <label class="block text-gray-700 text-sm font-bold mb-2">Title</label>
                        <input x-model="taskForm.title" 
                               type="text" 
                               required
                               class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                    </div>
                    
                    <div class="mb-4">
                        <label class="block text-gray-700 text-sm font-bold mb-2">Description</label>
                        <textarea x-model="taskForm.description" 
                                  rows="3"
                                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"></textarea>
                    </div>
                    
                    <div class="grid grid-cols-2 gap-4 mb-4">
                        <div>
                            <label class="block text-gray-700 text-sm font-bold mb-2">Status</label>
                            <select x-model="taskForm.status" 
                                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                                <option value="todo">To Do</option>
                                <option value="in_progress">In Progress</option>
                                <option value="done">Done</option>
                            </select>
                        </div>
                        
                        <div>
                            <label class="block text-gray-700 text-sm font-bold mb-2">Priority</label>
                            <select x-model="taskForm.priority" 
                                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                                <option value="low">Low</option>
                                <option value="medium">Medium</option>
                                <option value="high">High</option>
                                <option value="urgent">Urgent</option>
                            </select>
                        </div>
                    </div>
                    
                    <div class="mb-4">
                        <label class="block text-gray-700 text-sm font-bold mb-2">Due Date</label>
                        <input x-model="taskForm.due_date" 
                               type="datetime-local"
                               class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                    </div>
                    
                    <div class="flex justify-end space-x-2">
                        <button type="button" 
                                @click="showTaskModal = false"
                                class="px-4 py-2 text-gray-700 bg-gray-200 rounded hover:bg-gray-300">
                            Cancel
                        </button>
                        <button type="submit" 
                                class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600">
                            <span x-text="editingTask ? 'Update' : 'Create'"></span>
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script src="app.js"></script>
</body>
</html>
```

### Step 10: Create JavaScript Application

Create `starter/frontend/app.js`:

**🤖 Copilot Prompt Suggestion #10:**
```javascript
// Create Alpine.js application with:
// - Authentication (login/register/logout)
// - Task CRUD operations
// - Real-time updates via WebSocket
// - Search and filtering
// - Error handling and notifications
// - Token management with refresh
// Use fetch API for HTTP requests and WebSocket for real-time
```

**Expected Output:**
```javascript
function taskManager() {
    return {
        // Authentication
        isAuthenticated: false,
        authMode: 'login',
        authForm: {
            username: '',
            email: '',
            password: ''
        },
        authError: '',
        currentUser: null,
        token: null,
        
        // Tasks
        tasks: [],
        stats: {},
        showTaskModal: false,
        editingTask: null,
        taskForm: {
            title: '',
            description: '',
            status: 'todo',
            priority: 'medium',
            due_date: '',
            tag_ids: []
        },
        
        // Filters
        searchQuery: '',
        filterStatus: '',
        filterPriority: '',
        
        // WebSocket
        ws: null,
        
        // API Base URL
        apiUrl: 'http://localhost:8000/api/v1',
        
        // Initialize
        async init() {
            // Check for saved token
            const savedToken = localStorage.getItem('token');
            if (savedToken) {
                this.token = savedToken;
                await this.getCurrentUser();
            }
            
            // Set up periodic token refresh
            setInterval(() => {
                if (this.isAuthenticated) {
                    this.refreshToken();
                }
            }, 30 * 60 * 1000); // Refresh every 30 minutes
        },
        
        // Authentication Methods
        async login() {
            try {
                const formData = new URLSearchParams();
                formData.append('username', this.authForm.username);
                formData.append('password', this.authForm.password);
                
                const response = await fetch(`${this.apiUrl}/auth/login`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded'
                    },
                    body: formData
                });
                
                if (!response.ok) {
                    const error = await response.json();
                    throw new Error(error.error?.message || 'Login failed');
                }
                
                const data = await response.json();
                this.token = data.access_token;
                localStorage.setItem('token', this.token);
                localStorage.setItem('refresh_token', data.refresh_token);
                
                await this.getCurrentUser();
                this.authError = '';
                this.resetAuthForm();
                
            } catch (error) {
                this.authError = error.message;
            }
        },
        
        async register() {
            try {
                const response = await fetch(`${this.apiUrl}/auth/register`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(this.authForm)
                });
                
                if (!response.ok) {
                    const error = await response.json();
                    throw new Error(error.error?.message || 'Registration failed');
                }
                
                // Auto-login after registration
                await this.login();
                
            } catch (error) {
                this.authError = error.message;
            }
        },
        
        async getCurrentUser() {
            try {
                const response = await fetch(`${this.apiUrl}/auth/me`, {
                    headers: {
                        'Authorization': `Bearer ${this.token}`
                    }
                });
                
                if (!response.ok) {
                    throw new Error('Failed to get user info');
                }
                
                this.currentUser = await response.json();
                this.isAuthenticated = true;
                
                // Load tasks and connect WebSocket
                await this.loadTasks();
                await this.loadStats();
                this.connectWebSocket();
                
            } catch (error) {
                this.logout();
            }
        },
        
        async refreshToken() {
            try {
                const refreshToken = localStorage.getItem('refresh_token');
                if (!refreshToken) return;
                
                const response = await fetch(`${this.apiUrl}/auth/refresh`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ refresh_token: refreshToken })
                });
                
                if (response.ok) {
                    const data = await response.json();
                    this.token = data.access_token;
                    localStorage.setItem('token', this.token);
                }
            } catch (error) {
                console.error('Token refresh failed:', error);
            }
        },
        
        logout() {
            this.isAuthenticated = false;
            this.currentUser = null;
            this.token = null;
            this.tasks = [];
            this.stats = {};
            
            localStorage.removeItem('token');
            localStorage.removeItem('refresh_token');
            
            if (this.ws) {
                this.ws.close();
            }
            
            this.resetAuthForm();
        },
        
        // Task Methods
        async loadTasks() {
            try {
                const params = new URLSearchParams();
                if (this.filterStatus) params.append('status', this.filterStatus);
                if (this.filterPriority) params.append('priority', this.filterPriority);
                if (this.searchQuery) params.append('search', this.searchQuery);
                
                const response = await fetch(`${this.apiUrl}/tasks?${params}`, {
                    headers: {
                        'Authorization': `Bearer ${this.token}`
                    }
                });
                
                if (!response.ok) {
                    throw new Error('Failed to load tasks');
                }
                
                const data = await response.json();
                this.tasks = data.items;
                
            } catch (error) {
                console.error('Error loading tasks:', error);
                this.showNotification('Failed to load tasks', 'error');
            }
        },
        
        async loadStats() {
            try {
                const response = await fetch(`${this.apiUrl}/tasks/stats/summary`, {
                    headers: {
                        'Authorization': `Bearer ${this.token}`
                    }
                });
                
                if (response.ok) {
                    this.stats = await response.json();
                }
            } catch (error) {
                console.error('Error loading stats:', error);
            }
        },
        
        async saveTask() {
            try {
                const url = this.editingTask 
                    ? `${this.apiUrl}/tasks/${this.editingTask.id}`
                    : `${this.apiUrl}/tasks`;
                
                const method = this.editingTask ? 'PUT' : 'POST';
                
                const response = await fetch(url, {
                    method: method,
                    headers: {
                        'Authorization': `Bearer ${this.token}`,
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(this.taskForm)
                });
                
                if (!response.ok) {
                    throw new Error('Failed to save task');
                }
                
                const task = await response.json();
                
                if (this.editingTask) {
                    const index = this.tasks.findIndex(t => t.id === task.id);
                    if (index !== -1) {
                        this.tasks[index] = task;
                    }
                } else {
                    this.tasks.unshift(task);
                }
                
                this.showTaskModal = false;
                this.resetTaskForm();
                await this.loadStats();
                
                this.showNotification(
                    this.editingTask ? 'Task updated!' : 'Task created!',
                    'success'
                );
                
            } catch (error) {
                console.error('Error saving task:', error);
                this.showNotification('Failed to save task', 'error');
            }
        },
        
        async deleteTask(taskId) {
            if (!confirm('Are you sure you want to delete this task?')) {
                return;
            }
            
            try {
                const response = await fetch(`${this.apiUrl}/tasks/${taskId}`, {
                    method: 'DELETE',
                    headers: {
                        'Authorization': `Bearer ${this.token}`
                    }
                });
                
                if (!response.ok) {
                    throw new Error('Failed to delete task');
                }
                
                this.tasks = this.tasks.filter(t => t.id !== taskId);
                await this.loadStats();
                
                this.showNotification('Task deleted!', 'success');
                
            } catch (error) {
                console.error('Error deleting task:', error);
                this.showNotification('Failed to delete task', 'error');
            }
        },
        
        async toggleTaskComplete(task) {
            try {
                const newStatus = task.status === 'done' ? 'todo' : 'done';
                
                const response = await fetch(`${this.apiUrl}/tasks/${task.id}`, {
                    method: 'PUT',
                    headers: {
                        'Authorization': `Bearer ${this.token}`,
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ status: newStatus })
                });
                
                if (!response.ok) {
                    throw new Error('Failed to update task');
                }
                
                const updatedTask = await response.json();
                const index = this.tasks.findIndex(t => t.id === task.id);
                if (index !== -1) {
                    this.tasks[index] = updatedTask;
                }
                
                await this.loadStats();
                
            } catch (error) {
                console.error('Error updating task:', error);
                this.showNotification('Failed to update task', 'error');
            }
        },
        
        editTask(task) {
            this.editingTask = task;
            this.taskForm = {
                title: task.title,
                description: task.description || '',
                status: task.status,
                priority: task.priority,
                due_date: task.due_date ? this.formatDateForInput(task.due_date) : '',
                tag_ids: task.tags.map(t => t.id)
            };
            this.showTaskModal = true;
        },
        
        searchTasks() {
            // Debounce search
            clearTimeout(this.searchTimeout);
            this.searchTimeout = setTimeout(() => {
                this.loadTasks();
            }, 300);
        },
        
        // WebSocket
        connectWebSocket() {
            const wsUrl = `ws://localhost:8000/ws/tasks?token=${this.token}`;
            
            this.ws = new WebSocket(wsUrl);
            
            this.ws.onopen = () => {
                console.log('WebSocket connected');
            };
            
            this.ws.onmessage = (event) => {
                const message = JSON.parse(event.data);
                this.handleWebSocketMessage(message);
            };
            
            this.ws.onerror = (error) => {
                console.error('WebSocket error:', error);
            };
            
            this.ws.onclose = () => {
                console.log('WebSocket disconnected');
                // Reconnect after 5 seconds if authenticated
                if (this.isAuthenticated) {
                    setTimeout(() => this.connectWebSocket(), 5000);
                }
            };
        },
        
        handleWebSocketMessage(message) {
            switch (message.type) {
                case 'task_created':
                    if (!this.tasks.find(t => t.id === message.data.id)) {
                        this.tasks.unshift(message.data);
                        this.loadStats();
                    }
                    break;
                    
                case 'task_updated':
                    const index = this.tasks.findIndex(t => t.id === message.data.id);
                    if (index !== -1) {
                        this.tasks[index] = message.data;
                        this.loadStats();
                    }
                    break;
                    
                case 'task_deleted':
                    this.tasks = this.tasks.filter(t => t.id !== message.data.id);
                    this.loadStats();
                    break;
            }
        },
        
        // Utility Methods
        resetAuthForm() {
            this.authForm = {
                username: '',
                email: '',
                password: ''
            };
            this.authError = '';
        },
        
        resetTaskForm() {
            this.taskForm = {
                title: '',
                description: '',
                status: 'todo',
                priority: 'medium',
                due_date: '',
                tag_ids: []
            };
            this.editingTask = null;
        },
        
        formatDate(dateString) {
            const date = new Date(dateString);
            return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], { 
                hour: '2-digit', 
                minute: '2-digit' 
            });
        },
        
        formatDateForInput(dateString) {
            const date = new Date(dateString);
            return date.toISOString().slice(0, 16);
        },
        
        isOverdue(task) {
            if (!task.due_date || task.status === 'done') {
                return false;
            }
            return new Date(task.due_date) < new Date();
        },
        
        showNotification(message, type = 'info') {
            // You can implement a toast notification system here
            console.log(`[${type}] ${message}`);
        }
    };
}
```

## 🎯 Part 2 Summary

You've successfully:
1. Implemented complete authentication system
2. Created comprehensive task API endpoints
3. Built a modern, responsive web interface
4. Added real-time WebSocket updates
5. Implemented search, filtering, and statistics

**Key Features Built:**
- JWT-based authentication with refresh tokens
- Full CRUD operations for tasks
- Real-time updates via WebSocket
- Advanced filtering and search
- Responsive UI with Tailwind CSS
- Interactive features with Alpine.js

**Next**: Continue to [Part 3](part3.md) where we'll add deployment configuration, monitoring, and production optimization!

---

💡 **Pro Tip**: When building real-time features with Copilot, describe the message flow clearly. Copilot will generate consistent WebSocket implementations!