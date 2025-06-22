# app/models/social.py
from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
import uuid
from datetime import datetime

Base = declarative_base()

# TODO: Create the following models:
# - User: id, username, email, bio, avatar_url, created_at
# - Post: id, user_id, content, image_url, created_at
# - Comment: id, post_id, user_id, content, created_at
# - Like: user_id, target_type, target_id, created_at
# - Follow: follower_id, following_id, created_at

# app/graphql/schema.py
import strawberry
from typing import List, Optional
from datetime import datetime
from uuid import UUID

# TODO: Create GraphQL types:
# @strawberry.type
# class User:
#     id: UUID
#     username: str
#     email: str
#     bio: Optional[str]
#     avatar_url: Optional[str]
#     created_at: datetime

# TODO: Create Post, Comment, Like, Follow types

# TODO: Create input types for mutations

# TODO: Create Query class with:
# - user(id or username)
# - users(limit, offset)
# - post(id)
# - posts(limit, offset)
# - feed(limit, offset)

# TODO: Create Mutation class with:
# - createUser
# - createPost
# - createComment
# - likePost
# - followUser

# TODO: Create Subscription class with:
# - postCreated
# - commentAdded

# app/dataloaders/social.py
from aiodataloader import DataLoader
from typing import List
from uuid import UUID

# TODO: Create DataLoader classes:
# - UserLoader: batch load users by ID
# - PostsByUserLoader: batch load posts for users
# - CommentsLoader: batch load comments for posts
# - LikesCountLoader: batch load like counts
# - FollowersCountLoader: batch load follower counts

# app/graphql/app.py
from fastapi import FastAPI
from strawberry.fastapi import GraphQLRouter

# TODO: Create FastAPI app with GraphQL integration
# - Setup context with database and dataloaders
# - Configure WebSocket support for subscriptions
# - Add authentication to context

# requirements.txt
fastapi==0.109.0
strawberry-graphql[fastapi]==0.217.1
sqlalchemy==2.0.25
aiodataloader==0.4.0
redis==5.0.1
uvicorn[standard]==0.27.0
pytest==7.4.4
pytest-asyncio==0.23.3
httpx==0.26.0