"""
E-Commerce Database Schema - Starter Code
Module 09, Exercise 1

This file contains the starter code for creating an e-commerce database schema.
Use GitHub Copilot to help you complete the implementation.

Instructions:
1. Complete all TODO sections
2. Add proper relationships between tables
3. Include appropriate constraints and indexes
4. Follow the naming conventions provided
"""

from sqlalchemy import create_engine, Column, Integer, String, DateTime, Numeric, Boolean, ForeignKey, Text, Index
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship, sessionmaker
from datetime import datetime
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Create base class for declarative models
Base = declarative_base()

# ========================================
# USER MANAGEMENT TABLES
# ========================================

class User(Base):
    """
    User table for authentication and profile management
    
    TODO: Add the following columns using Copilot:
    - id (primary key)
    - email (unique, indexed, not null)
    - password_hash (not null)
    - first_name, last_name
    - is_active, is_verified (boolean flags)
    - created_at, updated_at (timestamps)
    
    TODO: Add relationships to:
    - addresses (one-to-many)
    - orders (one-to-many)
    - reviews (one-to-many)
    - cart_items (one-to-many)
    """
    __tablename__ = 'users'
    
    # TODO: Complete the User model implementation
    # Copilot Prompt: Add all columns for the User table with proper types and constraints
    

class Address(Base):
    """
    Address table for shipping and billing
    
    TODO: Complete implementation with:
    - Proper foreign key to users
    - Address fields (street, city, state, zip, country)
    - Type field (shipping/billing)
    - is_default flag
    """
    __tablename__ = 'addresses'
    
    # TODO: Implement Address model
    

# ========================================
# PRODUCT CATALOG TABLES
# ========================================

class Category(Base):
    """
    Product categories with hierarchical structure
    
    TODO: Implement with:
    - Self-referential relationship for parent/child
    - name, slug (URL-friendly name)
    - description
    - is_active flag
    - display_order for sorting
    """
    __tablename__ = 'categories'
    
    # TODO: Implement Category model with hierarchical structure
    

class Product(Base):
    """
    Main product table
    
    TODO: Add columns:
    - Basic info (name, slug, description, SKU)
    - category_id (foreign key)
    - base_price (use Numeric for money)
    - is_active, is_featured flags
    - timestamps
    
    TODO: Add relationships to:
    - category
    - variants
    - images
    - reviews
    """
    __tablename__ = 'products'
    
    # TODO: Implement Product model
    

class ProductVariant(Base):
    """
    Product variants (size, color combinations)
    
    TODO: Implement with:
    - product_id foreign key
    - SKU (unique)
    - size, color attributes
    - price_adjustment (can be negative)
    - stock quantity
    - weight (for shipping calculations)
    """
    __tablename__ = 'product_variants'
    
    # TODO: Implement ProductVariant model
    

class ProductImage(Base):
    """
    Product images with ordering
    
    TODO: Add:
    - product_id foreign key
    - image_url
    - alt_text
    - display_order
    - is_primary flag
    """
    __tablename__ = 'product_images'
    
    # TODO: Implement ProductImage model
    

# ========================================
# SHOPPING CART & ORDERS
# ========================================

class CartItem(Base):
    """
    Shopping cart items (persisted)
    
    TODO: Implement with:
    - user_id, product_variant_id foreign keys
    - quantity
    - added_at timestamp
    - Unique constraint on (user_id, product_variant_id)
    """
    __tablename__ = 'cart_items'
    
    # TODO: Implement CartItem model
    

class Order(Base):
    """
    Order table with status tracking
    
    TODO: Add:
    - user_id foreign key
    - order_number (unique)
    - status (pending, processing, shipped, delivered, cancelled)
    - totals (subtotal, tax, shipping, total)
    - shipping_address_id, billing_address_id
    - timestamps for each status change
    """
    __tablename__ = 'orders'
    
    # TODO: Implement Order model
    

class OrderItem(Base):
    """
    Individual items within an order
    
    TODO: Include:
    - order_id, product_variant_id foreign keys
    - quantity
    - price_at_time (snapshot of price when ordered)
    - discount_amount
    """
    __tablename__ = 'order_items'
    
    # TODO: Implement OrderItem model
    

# ========================================
# INVENTORY & REVIEWS
# ========================================

class Inventory(Base):
    """
    Real-time inventory tracking
    
    TODO: Add:
    - product_variant_id (unique foreign key)
    - quantity_available
    - quantity_reserved
    - reorder_point
    - reorder_quantity
    """
    __tablename__ = 'inventory'
    
    # TODO: Implement Inventory model
    

class StockMovement(Base):
    """
    Log of all inventory changes
    
    TODO: Track:
    - product_variant_id
    - movement_type (sale, return, adjustment, restock)
    - quantity (positive or negative)
    - reference_type, reference_id (polymorphic to order, etc.)
    - notes
    - created_at, created_by
    """
    __tablename__ = 'stock_movements'
    
    # TODO: Implement StockMovement model
    

class Review(Base):
    """
    Product reviews and ratings
    
    TODO: Implement:
    - user_id, product_id, order_id foreign keys
    - rating (1-5)
    - title, comment
    - is_verified_purchase
    - helpful_count, not_helpful_count
    - created_at, updated_at
    """
    __tablename__ = 'reviews'
    
    # TODO: Implement Review model
    

# ========================================
# DATABASE INITIALIZATION
# ========================================

def create_database():
    """Create all tables in the database"""
    # Get database URL from environment or use default
    database_url = os.getenv('DATABASE_URL', 'postgresql://workshop_user:workshop_pass@localhost/ecommerce_db')
    
    # Create engine
    engine = create_engine(database_url, echo=True)
    
    # Create all tables
    Base.metadata.create_all(engine)
    
    return engine

def get_session():
    """Get a database session"""
    engine = create_database()
    Session = sessionmaker(bind=engine)
    return Session()

# ========================================
# INDEXES AND CONSTRAINTS
# ========================================

# TODO: Add composite indexes for common queries
# Example:
# Index('idx_user_email', User.email)
# Index('idx_product_category', Product.category_id)
# Index('idx_order_user_status', Order.user_id, Order.status)


if __name__ == "__main__":
    # Create the database schema
    print("Creating database schema...")
    engine = create_database()
    print("Database schema created successfully!")
    
    # TODO: Add some sample data for testing
    # Copilot Prompt: Create a function to insert sample data for testing