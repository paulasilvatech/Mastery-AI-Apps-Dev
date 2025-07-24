---
sidebar_position: 3
title: "Exercise 2: Overview"
description: "## 📋 Overview"
---

# Exercise 2: Building a GraphQL Social Platform API (⭐⭐ Medium)

## 📋 Overview

In this exercise, you'll create a GraphQL API for a social platform with complex relationships, efficient data loading, and real-time subscriptions. You'll learn how GraphQL differs from REST and how to leverage its powerful features for building modern APIs.

**Duration:** 45-60 minutes  
**Difficulty:** ⭐⭐ Medium  
**Success Rate:** 80%

## 🎯 Learning Objectives

By completing this exercise, you will:
- Design GraphQL schemas with types and relationships
- Implement query and mutation resolvers
- Handle N+1 query problems with DataLoader
- Add real-time subscriptions
- Integrate authentication and authorization
- Write GraphQL-specific tests

## 🏗️ System Design

```mermaid
graph TD
    subgraph "GraphQL API"
        A[GraphQL Schema] --&gt; B[Query Resolvers]
        A --&gt; C[Mutation Resolvers]
        A --&gt; D[Subscription Resolvers]
        
        B --&gt; E[DataLoader]
        C --&gt; E
        
        E --&gt; F[Database]
        
        D --&gt; G[PubSub]
        C --&gt; G
    end
    
    subgraph "Data Model"
        H[User] --&gt; I[Post]
        H --&gt; J[Follow]
        I --&gt; K[Comment]
        I --&gt; L[Like]
        K --&gt; L
    end
    
    style A fill:#f9f,stroke:#333,stroke-width:2px
    style E fill:#bbf,stroke:#333,stroke-width:2px
    style G fill:#bfb,stroke:#333,stroke-width:2px
```

## 🚀 Getting Started

### Step 1: Project Setup

```bash
cd exercises/exercise2-graphql-api
mkdir -p app/graphql
mkdir -p app/models
mkdir -p app/dataloaders
mkdir -p tests
```

### Step 2: Install GraphQL Dependencies

```bash
pip install strawberry-graphql[fastapi]
pip install aiodataloader
pip install redis
pip install strawberry-graphql[subscriptions]
```

### Step 3: Define the Data Models

Create `app/models/social.py`:

**Copilot Prompt Suggestion:**
```python
# Create SQLAlchemy models for a social platform:
# - User: id, username, email, bio, avatar_url, created_at
# - Post: id, user_id, content, image_url, created_at
# - Comment: id, post_id, user_id, content, created_at
# - Like: user_id, post_id/comment_id (polymorphic), created_at
# - Follow: follower_id, following_id, created_at
# Include proper relationships and indexes
```

**Expected Output:**
```python
from sqlalchemy import Column, String, Text, DateTime, ForeignKey, UniqueConstraint, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship, backref
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime
import uuid

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(255), unique=True, nullable=False)
    bio = Column(Text, nullable=True)
    avatar_url = Column(String(500), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Relationships
    posts = relationship("Post", back_populates="author", cascade="all, delete-orphan")
    comments = relationship("Comment", back_populates="author", cascade="all, delete-orphan")
    likes = relationship("Like", back_populates="user", cascade="all, delete-orphan")
    
    # Followers/Following
    following = relationship(
        "Follow",
        foreign_keys="Follow.follower_id",
        back_populates="follower",
        cascade="all, delete-orphan"
    )
    followers = relationship(
        "Follow",
        foreign_keys="Follow.following_id",
        back_populates="followed",
        cascade="all, delete-orphan"
    )

class Post(Base):
    __tablename__ = "posts"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=False)
    image_url = Column(String(500), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    
    # Relationships
    author = relationship("User", back_populates="posts")
    comments = relationship("Comment", back_populates="post", cascade="all, delete-orphan")
    likes = relationship("Like", primaryjoin="and_(Like.target_type=='post', Like.target_id==Post.id)")

class Comment(Base):
    __tablename__ = "comments"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    post_id = Column(UUID(as_uuid=True), ForeignKey("posts.id"), nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Relationships
    post = relationship("Post", back_populates="comments")
    author = relationship("User", back_populates="comments")
    likes = relationship("Like", primaryjoin="and_(Like.target_type=='comment', Like.target_id==Comment.id)")

class Like(Base):
    __tablename__ = "likes"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    target_type = Column(String(20), nullable=False)  # 'post' or 'comment'
    target_id = Column(UUID(as_uuid=True), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="likes")
    
    __table_args__ = (
        UniqueConstraint('user_id', 'target_type', 'target_id'),
        Index('idx_target', 'target_type', 'target_id'),
    )

class Follow(Base):
    __tablename__ = "follows"
    
    follower_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True)
    following_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Relationships
    follower = relationship("User", foreign_keys=[follower_id], back_populates="following")
    followed = relationship("User", foreign_keys=[following_id], back_populates="followers")
    
    __table_args__ = (
        UniqueConstraint('follower_id', 'following_id'),
    )
```

### Step 4: Create GraphQL Schema

Create `app/graphql/schema.py`:

**Copilot Prompt Suggestion:**
```python
# Create Strawberry GraphQL schema with:
# Types: User, Post, Comment, Like, Follow
# Queries: user, users, post, posts, feed
# Mutations: createUser, createPost, createComment, likePost, followUser
# Subscriptions: postCreated, commentAdded
# Include proper type annotations and descriptions
```

**Expected Output:**
```python
import strawberry
from typing import List, Optional
from datetime import datetime
from uuid import UUID
import asyncio
from strawberry.types import Info
from strawberry.fastapi import GraphQLRouter
from strawberry.subscriptions import GRAPHQL_TRANSPORT_WS_PROTOCOL

# GraphQL Types
@strawberry.type
class User:
    id: UUID
    username: str
    email: str
    bio: Optional[str]
    avatar_url: Optional[str]
    created_at: datetime
    
    @strawberry.field
    async def posts(self, info: Info, limit: int = 10) -&gt; List["Post"]:
        return await info.context["dataloaders"]["posts_by_user"].load((self.id, limit))
    
    @strawberry.field
    async def followers_count(self, info: Info) -&gt; int:
        return await info.context["dataloaders"]["followers_count"].load(self.id)
    
    @strawberry.field
    async def following_count(self, info: Info) -&gt; int:
        return await info.context["dataloaders"]["following_count"].load(self.id)

@strawberry.type
class Post:
    id: UUID
    user_id: UUID
    content: str
    image_url: Optional[str]
    created_at: datetime
    
    @strawberry.field
    async def author(self, info: Info) -&gt; User:
        return await info.context["dataloaders"]["user"].load(self.user_id)
    
    @strawberry.field
    async def comments(self, info: Info, limit: int = 10) -&gt; List["Comment"]:
        return await info.context["dataloaders"]["comments_by_post"].load((self.id, limit))
    
    @strawberry.field
    async def likes_count(self, info: Info) -&gt; int:
        return await info.context["dataloaders"]["likes_count"].load(("post", self.id))
    
    @strawberry.field
    async def is_liked_by_me(self, info: Info) -&gt; bool:
        user_id = info.context.get("user_id")
        if not user_id:
            return False
        return await info.context["dataloaders"]["is_liked"].load((user_id, "post", self.id))

@strawberry.type
class Comment:
    id: UUID
    post_id: UUID
    user_id: UUID
    content: str
    created_at: datetime
    
    @strawberry.field
    async def author(self, info: Info) -&gt; User:
        return await info.context["dataloaders"]["user"].load(self.user_id)
    
    @strawberry.field
    async def likes_count(self, info: Info) -&gt; int:
        return await info.context["dataloaders"]["likes_count"].load(("comment", self.id))

@strawberry.type
class Like:
    user_id: UUID
    target_type: str
    target_id: UUID
    created_at: datetime

@strawberry.type
class Follow:
    follower_id: UUID
    following_id: UUID
    created_at: datetime

# Input Types
@strawberry.input
class CreateUserInput:
    username: str
    email: str
    bio: Optional[str] = None
    avatar_url: Optional[str] = None

@strawberry.input
class CreatePostInput:
    content: str
    image_url: Optional[str] = None

@strawberry.input
class CreateCommentInput:
    post_id: UUID
    content: str

# Mutations
@strawberry.type
class Mutation:
    @strawberry.mutation
    async def create_user(self, info: Info, input: CreateUserInput) -&gt; User:
        # Implementation will use database
        pass
    
    @strawberry.mutation
    async def create_post(self, info: Info, input: CreatePostInput) -&gt; Post:
        # Requires authentication
        user_id = info.context.get("user_id")
        if not user_id:
            raise Exception("Authentication required")
        
        # Create post in database
        # Publish to subscription
        post = await create_post_in_db(user_id, input)
        await info.context["pubsub"].publish("post_created", post)
        return post
    
    @strawberry.mutation
    async def create_comment(self, info: Info, input: CreateCommentInput) -&gt; Comment:
        # Implementation
        pass
    
    @strawberry.mutation
    async def like_post(self, info: Info, post_id: UUID) -&gt; Post:
        # Implementation
        pass
    
    @strawberry.mutation
    async def follow_user(self, info: Info, user_id: UUID) -&gt; User:
        # Implementation
        pass

# Queries
@strawberry.type
class Query:
    @strawberry.field
    async def user(self, info: Info, id: Optional[UUID] = None, username: Optional[str] = None) -&gt; Optional[User]:
        if id:
            return await info.context["dataloaders"]["user"].load(id)
        elif username:
            return await get_user_by_username(info.context["db"], username)
        return None
    
    @strawberry.field
    async def users(self, info: Info, limit: int = 20, offset: int = 0) -&gt; List[User]:
        return await get_users(info.context["db"], limit, offset)
    
    @strawberry.field
    async def post(self, info: Info, id: UUID) -&gt; Optional[Post]:
        return await get_post_by_id(info.context["db"], id)
    
    @strawberry.field
    async def posts(self, info: Info, limit: int = 20, offset: int = 0) -&gt; List[Post]:
        return await get_posts(info.context["db"], limit, offset)
    
    @strawberry.field
    async def feed(self, info: Info, limit: int = 20, offset: int = 0) -&gt; List[Post]:
        user_id = info.context.get("user_id")
        if not user_id:
            raise Exception("Authentication required")
        return await get_user_feed(info.context["db"], user_id, limit, offset)

# Subscriptions
@strawberry.type
class Subscription:
    @strawberry.subscription
    async def post_created(self, info: Info) -&gt; AsyncGenerator[Post, None]:
        async for post in info.context["pubsub"].subscribe("post_created"):
            yield post
    
    @strawberry.subscription
    async def comment_added(self, info: Info, post_id: UUID) -&gt; AsyncGenerator[Comment, None]:
        async for comment in info.context["pubsub"].subscribe(f"comment_added:{post_id}"):
            yield comment

# Create schema
schema = strawberry.Schema(
    query=Query,
    mutation=Mutation,
    subscription=Subscription
)
```

### Step 5: Implement DataLoaders

Create `app/dataloaders/social.py`:

**Copilot Prompt Suggestion:**
```python
# Create DataLoader implementations to prevent N+1 queries:
# - UserLoader: batch load users by ID
# - PostsByUserLoader: batch load posts for multiple users
# - CommentsLoader: batch load comments for posts
# - LikesCountLoader: batch load like counts
# - FollowersCountLoader: batch load follower counts
# Use aiodataloader for async batch loading
```

**Expected Output:**
```python
from aiodataloader import DataLoader
from typing import List, Dict, Tuple
from uuid import UUID
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.social import User, Post, Comment, Like, Follow

class UserLoader(DataLoader):
    def __init__(self, db_session: AsyncSession):
        super().__init__()
        self.db = db_session
    
    async def batch_load_fn(self, user_ids: List[UUID]) -&gt; List[User]:
        query = select(User).where(User.id.in_(user_ids))
        result = await self.db.execute(query)
        users = result.scalars().all()
        
        # Create mapping
        user_map = {user.id: user for user in users}
        
        # Return in same order as requested
        return [user_map.get(user_id) for user_id in user_ids]

class PostsByUserLoader(DataLoader):
    def __init__(self, db_session: AsyncSession):
        super().__init__()
        self.db = db_session
    
    async def batch_load_fn(self, keys: List[Tuple[UUID, int]]) -&gt; List[List[Post]]:
        # Extract unique user IDs
        user_ids = list(set(user_id for user_id, _ in keys))
        
        # Query all posts for these users
        query = select(Post).where(Post.user_id.in_(user_ids)).order_by(Post.created_at.desc())
        result = await self.db.execute(query)
        posts = result.scalars().all()
        
        # Group by user
        posts_by_user = {}
        for post in posts:
            if post.user_id not in posts_by_user:
                posts_by_user[post.user_id] = []
            posts_by_user[post.user_id].append(post)
        
        # Return in requested order with limit applied
        return [
            posts_by_user.get(user_id, [])[:limit]
            for user_id, limit in keys
        ]

class LikesCountLoader(DataLoader):
    def __init__(self, db_session: AsyncSession):
        super().__init__()
        self.db = db_session
    
    async def batch_load_fn(self, keys: List[Tuple[str, UUID]]) -&gt; List[int]:
        # Count likes for all requested targets
        counts = {}
        
        for target_type in ['post', 'comment']:
            target_ids = [target_id for t_type, target_id in keys if t_type == target_type]
            
            if target_ids:
                query = select(
                    Like.target_id,
                    func.count(Like.id).label('count')
                ).where(
                    Like.target_type == target_type,
                    Like.target_id.in_(target_ids)
                ).group_by(Like.target_id)
                
                result = await self.db.execute(query)
                for target_id, count in result:
                    counts[(target_type, target_id)] = count
        
        # Return counts in order
        return [counts.get(key, 0) for key in keys]

class FollowersCountLoader(DataLoader):
    def __init__(self, db_session: AsyncSession):
        super().__init__()
        self.db = db_session
    
    async def batch_load_fn(self, user_ids: List[UUID]) -&gt; List[int]:
        query = select(
            Follow.following_id,
            func.count(Follow.follower_id).label('count')
        ).where(
            Follow.following_id.in_(user_ids)
        ).group_by(Follow.following_id)
        
        result = await self.db.execute(query)
        counts = {user_id: count for user_id, count in result}
        
        return [counts.get(user_id, 0) for user_id in user_ids]

def create_dataloaders(db_session: AsyncSession) -&gt; Dict[str, DataLoader]:
    return {
        "user": UserLoader(db_session),
        "posts_by_user": PostsByUserLoader(db_session),
        "likes_count": LikesCountLoader(db_session),
        "followers_count": FollowersCountLoader(db_session),
        # Add more dataloaders as needed
    }
```

### Step 6: Integration with FastAPI

Create `app/graphql/app.py`:

**Copilot Prompt Suggestion:**
```python
# Create FastAPI app with GraphQL integration:
# - Add GraphQL router with playground
# - Setup WebSocket support for subscriptions
# - Add authentication middleware
# - Inject database and dataloaders into context
# - Setup Redis pubsub for subscriptions
```

**Expected Output:**
```python
from fastapi import FastAPI, Depends, Request, WebSocket
from strawberry.fastapi import GraphQLRouter
from strawberry.subscriptions import GRAPHQL_TRANSPORT_WS_PROTOCOL
import redis.asyncio as redis
from app.graphql.schema import schema
from app.database import get_db
from app.dataloaders.social import create_dataloaders
from typing import Dict, Any
import asyncio

# Create Redis client for pubsub
redis_client = redis.from_url("redis://localhost:6379")

class PubSub:
    def __init__(self):
        self.subscribers: Dict[str, List[asyncio.Queue]] = {}
    
    async def publish(self, channel: str, message: Any):
        if channel in self.subscribers:
            for queue in self.subscribers[channel]:
                await queue.put(message)
    
    async def subscribe(self, channel: str):
        queue = asyncio.Queue()
        if channel not in self.subscribers:
            self.subscribers[channel] = []
        self.subscribers[channel].append(queue)
        
        try:
            while True:
                message = await queue.get()
                yield message
        finally:
            self.subscribers[channel].remove(queue)

pubsub = PubSub()

async def get_context(request: Request = None, websocket: WebSocket = None):
    # Get database session
    db = await get_db()
    
    # Get user from auth header (simplified)
    user_id = None
    if request:
        auth_header = request.headers.get("Authorization")
        if auth_header:
            # Extract user_id from token
            user_id = extract_user_from_token(auth_header)
    
    return {
        "db": db,
        "dataloaders": create_dataloaders(db),
        "user_id": user_id,
        "pubsub": pubsub,
        "request": request,
        "websocket": websocket
    }

# Create GraphQL router
graphql_app = GraphQLRouter(
    schema,
    context_getter=get_context,
    subscription_protocols=[GRAPHQL_TRANSPORT_WS_PROTOCOL]
)

# Create FastAPI app
app = FastAPI(title="Social Platform GraphQL API")
app.include_router(graphql_app, prefix="/graphql")

@app.get("/")
async def root():
    return {{"message": "Social Platform GraphQL API"}}
```

### Step 7: Write Tests

Create `tests/test_graphql.py`:

**Copilot Prompt Suggestion:**
```python
# Create tests for GraphQL API:
# - Test queries (user, posts, feed)
# - Test mutations (createPost, likePost, followUser)
# - Test subscriptions using WebSocket
# - Test DataLoader efficiency
# - Test error handling and validation
```

**Expected Output:**
```python
import pytest
from httpx import AsyncClient
from app.graphql.app import app
import json

@pytest.fixture
async def client():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

@pytest.mark.asyncio
async def test_create_user_mutation(client):
    mutation = """
    mutation CreateUser($input: CreateUserInput!) {
        createUser(input: $input) {
            id
            username
            email
        }
    }
    """
    
    variables = {
        "input": {
            "username": "testuser",
            "email": "test@example.com",
            "bio": "Test bio"
        }
    }
    
    response = await client.post(
        "/graphql",
        json={{"query": mutation, "variables": variables}}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["data"]["createUser"]["username"] == "testuser"

@pytest.mark.asyncio
async def test_query_posts_with_author(client):
    query = """
    query GetPosts($limit: Int!) {
        posts(limit: $limit) {
            id
            content
            author {
                username
            }
            likesCount
            comments(limit: 5) {
                content
                author {
                    username
                }
            }
        }
    }
    """
    
    response = await client.post(
        "/graphql",
        json={{"query": query, "variables": {{"limit": 10}}}}
    )
    
    assert response.status_code == 200
    # Verify no N+1 queries occurred

@pytest.mark.asyncio
async def test_subscription():
    # Test WebSocket subscription
    # This requires WebSocket test client
    pass
```

## 🎉 Exercise Complete!

You've successfully built a GraphQL API with:
- ✅ Complex schema with relationships
- ✅ Efficient data loading with DataLoader
- ✅ Real-time subscriptions
- ✅ Authentication integration
- ✅ Comprehensive testing

## 📊 Success Criteria

- All queries resolve without N+1 problems
- Subscriptions deliver real-time updates
- Authentication properly enforced
- Schema is well-documented
- Tests cover all operations

## 🚀 Extension Challenges

1. Add field-level authorization
2. Implement cursor-based pagination
3. Add query complexity analysis
4. Create custom scalars for validation
5. Implement federation for microservices

---

Ready for the ultimate challenge? Continue to [Exercise 3: Enterprise API Gateway](../exercise3-api-gateway/instructions.md)!