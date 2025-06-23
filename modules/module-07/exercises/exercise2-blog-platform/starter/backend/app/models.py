"""Database Models for Blog Platform

TODO: Complete the implementation of these models using SQLAlchemy
"""

from sqlalchemy import Column, Integer, String, Text, DateTime, Boolean, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime

Base = declarative_base()

class User(Base):
    """User model for authentication and authorship
    
    TODO: Add the following fields:
    - id (primary key)
    - username (unique, indexed)
    - email (unique, indexed)
    - hashed_password
    - full_name (optional)
    - bio (optional)
    - avatar_url (optional)
    - is_active (default True)
    - is_superuser (default False)
    - created_at
    - updated_at
    
    Relationships:
    - posts (one-to-many with BlogPost)
    - comments (one-to-many with Comment)
    """
    __tablename__ = "users"
    
    # TODO: Implement model fields
    pass


class BlogPost(Base):
    """Blog post model
    
    TODO: Add the following fields:
    - id (primary key)
    - title (required, indexed)
    - slug (unique, indexed) - URL-friendly version of title
    - content (markdown text)
    - summary (optional excerpt)
    - featured_image (optional URL)
    - author_id (foreign key to User)
    - status (draft, published, archived)
    - published_at (nullable)
    - view_count (default 0)
    - created_at
    - updated_at
    
    Relationships:
    - author (many-to-one with User)
    - comments (one-to-many with Comment)
    - tags (many-to-many with Tag)
    """
    __tablename__ = "blog_posts"
    
    # TODO: Implement model fields
    pass


class Comment(Base):
    """Comment model with nested/threaded support
    
    TODO: Add the following fields:
    - id (primary key)
    - content (required)
    - author_id (foreign key to User)
    - post_id (foreign key to BlogPost)
    - parent_id (self-referential foreign key for nested comments)
    - is_edited (default False)
    - is_deleted (default False) - soft delete
    - created_at
    - updated_at
    
    Relationships:
    - author (many-to-one with User)
    - post (many-to-one with BlogPost)
    - parent (self-referential for threading)
    - replies (one-to-many self-referential)
    """
    __tablename__ = "comments"
    
    # TODO: Implement model fields
    pass


class Tag(Base):
    """Tag model for categorizing posts
    
    TODO: Add the following fields:
    - id (primary key)
    - name (unique, indexed)
    - slug (unique, indexed)
    - description (optional)
    - created_at
    
    Relationships:
    - posts (many-to-many with BlogPost)
    """
    __tablename__ = "tags"
    
    # TODO: Implement model fields
    pass


# TODO: Create association table for post_tags many-to-many relationship


# Database initialization
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

# TODO: Configure database URL from environment
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@localhost/blogdb")

# TODO: Create engine and session
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()