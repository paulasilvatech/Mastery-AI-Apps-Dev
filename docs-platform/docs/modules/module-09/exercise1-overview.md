---
sidebar_position: 4
title: "Exercise 1: Overview"
description: "## 🎯 Objective"
---

# Exercise 1: E-Commerce Database Schema Design (⭐ Easy)

## 🎯 Objective

Design and implement a complete e-commerce database schema using PostgreSQL with GitHub Copilot assistance. You'll create tables for products, users, orders, and inventory tracking while learning best practices for database design.

**Duration**: 30-45 minutes  
**Difficulty**: ⭐ Easy  
**Success Rate**: 95%

## 📚 Concepts Covered

- Entity-Relationship modeling
- Database normalization (3NF)
- Primary and foreign keys
- Constraints and validations
- Indexes for performance
- Using GitHub Copilot for schema generation

## 🏗️ What You'll Build

A complete database schema for an e-commerce platform including:
- User management system
- Product catalog with categories
- Shopping cart functionality
- Order processing system
- Inventory tracking
- Review and rating system

## 📋 Requirements

### Business Requirements
1. **Users** can register, login, and manage profiles
2. **Products** belong to categories and have variants (size, color)
3. **Cart** items persist between sessions
4. **Orders** track status from placement to delivery
5. **Inventory** updates automatically with orders
6. **Reviews** are linked to verified purchases

### Technical Requirements
- PostgreSQL 15+
- Proper data types and constraints
- Referential integrity
- Optimized indexes
- Audit fields (created_at, updated_at)

## 🔨 Step-by-Step Instructions

### Step 1: Project Setup (5 minutes)

1. Create project structure:
```bash
mkdir ecommerce-db
cd ecommerce-db
mkdir -p {schemas,migrations,tests,scripts}
```

2. Initialize Python environment:
```bash
python -m venv venv
source venv/bin/activate  # Windows: .\venv\Scripts\activate
pip install sqlalchemy psycopg2-binary alembic pytest
```

3. Create configuration file:
```python
# config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str = "postgresql://workshop_user:workshop_pass@localhost/ecommerce_db"
    echo_sql: bool = True
    
settings = Settings()
```

### Step 2: Design Core Entities (10 minutes)

**Copilot Prompt Suggestion:**
```python
# Create SQLAlchemy models for an e-commerce system with:
# - Users table with email, password hash, profile info
# - Products table with name, description, price, SKU
# - Categories table with hierarchical structure
# - Include proper relationships and constraints
# Use best practices for naming and types
```

**Expected Output Structure:**
```python
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Numeric, Boolean, ForeignKey, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    addresses = relationship("Address", back_populates="user")
    orders = relationship("Order", back_populates="user")
    reviews = relationship("Review", back_populates="user")
    cart_items = relationship("CartItem", back_populates="user")
```

### Step 3: Implement Product Catalog (10 minutes)

**Copilot Prompt Suggestion:**
```python
# Extend the schema with:
# - Products with variants (ProductVariant for size/color)
# - Categories with parent-child relationships
# - Product images with ordering
# - Price history tracking
# Include proper indexes for search performance
```

Key implementation points:
1. Products have multiple variants (size, color combinations)
2. Categories support nesting (Electronics &gt; Computers &gt; Laptops)
3. Price changes are tracked for analytics
4. Images have display order

### Step 4: Add Shopping Cart & Orders (10 minutes)

**Copilot Prompt Suggestion:**
```python
# Create shopping cart and order system:
# - Cart items linked to user and product variants
# - Orders with status workflow (pending, paid, shipped, delivered)
# - Order items with price snapshot
# - Shipping and billing addresses
# - Payment information (storing only safe data)
# Include constraints to ensure data integrity
```

Important considerations:
- Cart items should persist across sessions
- Order items capture price at time of purchase
- Status transitions should be trackable
- Never store sensitive payment data directly

### Step 5: Implement Inventory & Reviews (5 minutes)

**Copilot Prompt Suggestion:**
```python
# Complete the schema with:
# - Inventory tracking per product variant
# - Stock movements log (additions, sales, adjustments)
# - Review system with ratings and verified purchase flag
# - Helpful votes on reviews
# Add database triggers or checks for inventory
```

### Step 6: Create Indexes and Constraints (5 minutes)

**Copilot Prompt Suggestion:**
```sql
-- Create optimal indexes for:
-- 1. User login (email lookup)
-- 2. Product search (name, description)
-- 3. Order history by user
-- 4. Active cart items
-- 5. Product reviews
-- Include composite indexes where beneficial
```

### Step 7: Generate Migration Scripts (5 minutes)

1. Initialize Alembic:
```bash
alembic init migrations
```

2. Configure Alembic:
```python
# alembic.ini
sqlalchemy.url = postgresql://workshop_user:workshop_pass@localhost/ecommerce_db

# migrations/env.py
from models import Base
target_metadata = Base.metadata
```

3. Generate initial migration:
```bash
alembic revision --autogenerate -m "Initial schema"
alembic upgrade head
```

## 🧪 Validation Tests

Create `tests/test_schema.py`:

**Copilot Prompt Suggestion:**
```python
# Create pytest tests that validate:
# - All tables are created successfully
# - Relationships work correctly
# - Constraints are enforced
# - Cascade deletes work as expected
# - Sample data can be inserted and queried
```

Run tests:
```bash
pytest tests/test_schema.py -v
```

## 📊 Expected Schema Diagram

```mermaid
erDiagram
    User ||--o{ Order : places
    User ||--o{ CartItem : has
    User ||--o{ Review : writes
    User ||--o{ Address : has
    
    Product ||--o{ ProductVariant : has
    Product }o--|| Category : belongs_to
    Product ||--o{ ProductImage : has
    Product ||--o{ Review : receives
    
    ProductVariant ||--o{ CartItem : contains
    ProductVariant ||--o{ OrderItem : contains
    ProductVariant ||--|| Inventory : tracks
    
    Order ||--o{ OrderItem : contains
    Order }o--|| Address : ships_to
    Order }o--|| Address : bills_to
    
    Review }o--|| Order : verified_by
```

## ✅ Success Criteria

Your implementation is complete when:

1. **Schema Created** ✓
   - All tables exist with proper columns
   - Data types are appropriate
   - Constraints are enforced

2. **Relationships Work** ✓
   - Foreign keys are properly set
   - Cascading deletes work correctly
   - No orphaned records possible

3. **Performance Ready** ✓
   - Indexes on frequently queried columns
   - Composite indexes where beneficial
   - No N+1 query problems

4. **Data Integrity** ✓
   - Email uniqueness enforced
   - Inventory can't go negative
   - Prices are properly stored (decimal)

5. **Tests Pass** ✓
   - All unit tests pass
   - Sample data workflow works
   - Constraints are validated

## 🚀 Extension Challenges

If you finish early, try these additional challenges:

1. **Add Wishlists**: Users can save products for later
2. **Implement Coupons**: Discount system with rules
3. **Add Product Bundles**: Group products with special pricing
4. **Create Analytics Views**: Materialized views for reporting
5. **Add Full-Text Search**: PostgreSQL FTS for products

## 💡 Tips and Hints

- Use `SERIAL` or `IDENTITY` for auto-incrementing IDs
- Always use `DECIMAL` for money, never `FLOAT`
- Consider using `UUID` for public-facing IDs
- Add indexes on foreign keys for better JOIN performance
- Use `CHECK` constraints for business rules
- Consider `ENUM` types for status fields

## 📚 Resources

- [PostgreSQL Data Types](https://www.postgresql.org/docs/current/datatype.html)
- [SQLAlchemy Relationships](https://docs.sqlalchemy.org/orm/relationships.html)
- [Database Normalization](https://learn.microsoft.com/sql/relational-databases/database-normalization)
- [Index Design Guidelines](https://www.postgresql.org/docs/current/indexes.html)

## 🎯 Next Steps

After completing this exercise:
1. Review the provided solution
2. Compare your approach with best practices
3. Try the extension challenges
4. Move on to Exercise 2: Query Performance Optimization

Remember: Good database design is the foundation of scalable applications. Take time to understand why certain decisions are made!