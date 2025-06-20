"""
E-Commerce Database Schema - Complete Solution
Module 09, Exercise 1

This is the complete implementation of an e-commerce database schema
with all best practices applied.
"""

from sqlalchemy import (
    create_engine, Column, Integer, String, DateTime, Numeric, Boolean, 
    ForeignKey, Text, Index, UniqueConstraint, CheckConstraint, Enum
)
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship, sessionmaker
from sqlalchemy.sql import func
from datetime import datetime
import enum
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Create base class for declarative models
Base = declarative_base()

# ========================================
# ENUMS
# ========================================

class OrderStatus(enum.Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    PAID = "paid"
    SHIPPED = "shipped"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"
    REFUNDED = "refunded"

class AddressType(enum.Enum):
    SHIPPING = "shipping"
    BILLING = "billing"

class MovementType(enum.Enum):
    SALE = "sale"
    RETURN = "return"
    ADJUSTMENT = "adjustment"
    RESTOCK = "restock"

# ========================================
# USER MANAGEMENT TABLES
# ========================================

class User(Base):
    """User table for authentication and profile management"""
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    phone = Column(String(20))
    is_active = Column(Boolean, default=True, nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Relationships
    addresses = relationship("Address", back_populates="user", cascade="all, delete-orphan")
    orders = relationship("Order", back_populates="user")
    reviews = relationship("Review", back_populates="user")
    cart_items = relationship("CartItem", back_populates="user", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<User(id={self.id}, email='{self.email}')>"

class Address(Base):
    """Address table for shipping and billing"""
    __tablename__ = 'addresses'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    type = Column(Enum(AddressType), nullable=False)
    is_default = Column(Boolean, default=False, nullable=False)
    full_name = Column(String(200), nullable=False)
    street_address1 = Column(String(255), nullable=False)
    street_address2 = Column(String(255))
    city = Column(String(100), nullable=False)
    state_province = Column(String(100), nullable=False)
    postal_code = Column(String(20), nullable=False)
    country = Column(String(2), nullable=False)  # ISO country code
    phone = Column(String(20))
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="addresses")
    shipping_orders = relationship("Order", foreign_keys="Order.shipping_address_id", back_populates="shipping_address")
    billing_orders = relationship("Order", foreign_keys="Order.billing_address_id", back_populates="billing_address")
    
    # Indexes
    __table_args__ = (
        Index('idx_addresses_user_type', 'user_id', 'type'),
        Index('idx_addresses_user_default', 'user_id', 'is_default'),
    )

# ========================================
# PRODUCT CATALOG TABLES
# ========================================

class Category(Base):
    """Product categories with hierarchical structure"""
    __tablename__ = 'categories'
    
    id = Column(Integer, primary_key=True)
    parent_id = Column(Integer, ForeignKey('categories.id', ondelete='CASCADE'))
    name = Column(String(100), nullable=False)
    slug = Column(String(100), unique=True, nullable=False, index=True)
    description = Column(Text)
    image_url = Column(String(500))
    is_active = Column(Boolean, default=True, nullable=False)
    display_order = Column(Integer, default=0, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Self-referential relationship
    parent = relationship("Category", remote_side=[id], backref="subcategories")
    products = relationship("Product", back_populates="category")
    
    # Indexes
    __table_args__ = (
        Index('idx_categories_parent_active', 'parent_id', 'is_active'),
        Index('idx_categories_display_order', 'display_order'),
    )

class Product(Base):
    """Main product table"""
    __tablename__ = 'products'
    
    id = Column(Integer, primary_key=True)
    category_id = Column(Integer, ForeignKey('categories.id'), nullable=False)
    name = Column(String(255), nullable=False)
    slug = Column(String(255), unique=True, nullable=False, index=True)
    description = Column(Text)
    sku = Column(String(50), unique=True, nullable=False, index=True)
    base_price = Column(Numeric(10, 2), nullable=False)
    cost = Column(Numeric(10, 2))  # For profit calculations
    weight = Column(Numeric(8, 3))  # In kg
    is_active = Column(Boolean, default=True, nullable=False)
    is_featured = Column(Boolean, default=False, nullable=False)
    meta_title = Column(String(255))
    meta_description = Column(String(500))
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Relationships
    category = relationship("Category", back_populates="products")
    variants = relationship("ProductVariant", back_populates="product", cascade="all, delete-orphan")
    images = relationship("ProductImage", back_populates="product", cascade="all, delete-orphan")
    reviews = relationship("Review", back_populates="product")
    
    # Constraints
    __table_args__ = (
        CheckConstraint('base_price >= 0', name='check_product_price_positive'),
        CheckConstraint('cost >= 0', name='check_product_cost_positive'),
        Index('idx_products_category_active', 'category_id', 'is_active'),
        Index('idx_products_featured', 'is_featured', 'is_active'),
        Index('idx_products_name_trgm', 'name'),  # For full-text search
    )

class ProductVariant(Base):
    """Product variants (size, color combinations)"""
    __tablename__ = 'product_variants'
    
    id = Column(Integer, primary_key=True)
    product_id = Column(Integer, ForeignKey('products.id', ondelete='CASCADE'), nullable=False)
    sku = Column(String(50), unique=True, nullable=False, index=True)
    size = Column(String(50))
    color = Column(String(50))
    material = Column(String(100))
    price_adjustment = Column(Numeric(10, 2), default=0, nullable=False)
    weight_adjustment = Column(Numeric(8, 3), default=0)  # In kg
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Relationships
    product = relationship("Product", back_populates="variants")
    inventory = relationship("Inventory", uselist=False, back_populates="variant", cascade="all, delete-orphan")
    cart_items = relationship("CartItem", back_populates="variant")
    order_items = relationship("OrderItem", back_populates="variant")
    stock_movements = relationship("StockMovement", back_populates="variant")
    
    # Constraints
    __table_args__ = (
        UniqueConstraint('product_id', 'size', 'color', 'material', name='uq_product_variant_attributes'),
        Index('idx_product_variants_product_active', 'product_id', 'is_active'),
    )

class ProductImage(Base):
    """Product images with ordering"""
    __tablename__ = 'product_images'
    
    id = Column(Integer, primary_key=True)
    product_id = Column(Integer, ForeignKey('products.id', ondelete='CASCADE'), nullable=False)
    image_url = Column(String(500), nullable=False)
    thumbnail_url = Column(String(500))
    alt_text = Column(String(255))
    display_order = Column(Integer, default=0, nullable=False)
    is_primary = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Relationships
    product = relationship("Product", back_populates="images")
    
    # Constraints
    __table_args__ = (
        Index('idx_product_images_product_order', 'product_id', 'display_order'),
        Index('idx_product_images_primary', 'product_id', 'is_primary'),
    )

# ========================================
# SHOPPING CART & ORDERS
# ========================================

class CartItem(Base):
    """Shopping cart items (persisted)"""
    __tablename__ = 'cart_items'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    product_variant_id = Column(Integer, ForeignKey('product_variants.id'), nullable=False)
    quantity = Column(Integer, nullable=False)
    added_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="cart_items")
    variant = relationship("ProductVariant", back_populates="cart_items")
    
    # Constraints
    __table_args__ = (
        UniqueConstraint('user_id', 'product_variant_id', name='uq_cart_user_variant'),
        CheckConstraint('quantity > 0', name='check_cart_quantity_positive'),
        Index('idx_cart_items_user', 'user_id'),
    )

class Order(Base):
    """Order table with status tracking"""
    __tablename__ = 'orders'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    order_number = Column(String(50), unique=True, nullable=False, index=True)
    status = Column(Enum(OrderStatus), default=OrderStatus.PENDING, nullable=False)
    
    # Financial fields
    subtotal = Column(Numeric(10, 2), nullable=False)
    tax_amount = Column(Numeric(10, 2), default=0, nullable=False)
    shipping_amount = Column(Numeric(10, 2), default=0, nullable=False)
    discount_amount = Column(Numeric(10, 2), default=0, nullable=False)
    total_amount = Column(Numeric(10, 2), nullable=False)
    
    # Address references
    shipping_address_id = Column(Integer, ForeignKey('addresses.id'))
    billing_address_id = Column(Integer, ForeignKey('addresses.id'))
    
    # Payment information (store only safe data)
    payment_method = Column(String(50))
    payment_reference = Column(String(255))  # External payment ID
    
    # Timestamps for status changes
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    paid_at = Column(DateTime(timezone=True))
    shipped_at = Column(DateTime(timezone=True))
    delivered_at = Column(DateTime(timezone=True))
    cancelled_at = Column(DateTime(timezone=True))
    
    # Additional fields
    notes = Column(Text)
    tracking_number = Column(String(255))
    
    # Relationships
    user = relationship("User", back_populates="orders")
    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")
    shipping_address = relationship("Address", foreign_keys=[shipping_address_id], back_populates="shipping_orders")
    billing_address = relationship("Address", foreign_keys=[billing_address_id], back_populates="billing_orders")
    reviews = relationship("Review", back_populates="order")
    
    # Constraints and indexes
    __table_args__ = (
        CheckConstraint('total_amount >= 0', name='check_order_total_positive'),
        Index('idx_orders_user_status', 'user_id', 'status'),
        Index('idx_orders_status_created', 'status', 'created_at'),
        Index('idx_orders_created_at', 'created_at'),
    )

class OrderItem(Base):
    """Individual items within an order"""
    __tablename__ = 'order_items'
    
    id = Column(Integer, primary_key=True)
    order_id = Column(Integer, ForeignKey('orders.id', ondelete='CASCADE'), nullable=False)
    product_variant_id = Column(Integer, ForeignKey('product_variants.id'), nullable=False)
    quantity = Column(Integer, nullable=False)
    price_at_time = Column(Numeric(10, 2), nullable=False)  # Snapshot of price
    discount_amount = Column(Numeric(10, 2), default=0, nullable=False)
    tax_amount = Column(Numeric(10, 2), default=0, nullable=False)
    total_amount = Column(Numeric(10, 2), nullable=False)
    
    # Relationships
    order = relationship("Order", back_populates="items")
    variant = relationship("ProductVariant", back_populates="order_items")
    
    # Constraints
    __table_args__ = (
        CheckConstraint('quantity > 0', name='check_order_item_quantity_positive'),
        CheckConstraint('price_at_time >= 0', name='check_order_item_price_positive'),
        Index('idx_order_items_order', 'order_id'),
        Index('idx_order_items_variant', 'product_variant_id'),
    )

# ========================================
# INVENTORY & REVIEWS
# ========================================

class Inventory(Base):
    """Real-time inventory tracking"""
    __tablename__ = 'inventory'
    
    id = Column(Integer, primary_key=True)
    product_variant_id = Column(Integer, ForeignKey('product_variants.id', ondelete='CASCADE'), unique=True, nullable=False)
    quantity_available = Column(Integer, default=0, nullable=False)
    quantity_reserved = Column(Integer, default=0, nullable=False)  # For pending orders
    reorder_point = Column(Integer, default=10, nullable=False)
    reorder_quantity = Column(Integer, default=50, nullable=False)
    last_restocked_at = Column(DateTime(timezone=True))
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Relationships
    variant = relationship("ProductVariant", back_populates="inventory")
    
    # Computed property
    @property
    def quantity_on_hand(self):
        return self.quantity_available + self.quantity_reserved
    
    # Constraints
    __table_args__ = (
        CheckConstraint('quantity_available >= 0', name='check_inventory_available_positive'),
        CheckConstraint('quantity_reserved >= 0', name='check_inventory_reserved_positive'),
        Index('idx_inventory_low_stock', 'quantity_available', 'reorder_point'),
    )

class StockMovement(Base):
    """Log of all inventory changes"""
    __tablename__ = 'stock_movements'
    
    id = Column(Integer, primary_key=True)
    product_variant_id = Column(Integer, ForeignKey('product_variants.id'), nullable=False)
    movement_type = Column(Enum(MovementType), nullable=False)
    quantity = Column(Integer, nullable=False)  # Positive for additions, negative for removals
    reference_type = Column(String(50))  # 'order', 'return', 'adjustment', etc.
    reference_id = Column(Integer)  # ID of related entity
    notes = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    created_by = Column(Integer, ForeignKey('users.id'))
    
    # Relationships
    variant = relationship("ProductVariant", back_populates="stock_movements")
    
    # Indexes
    __table_args__ = (
        Index('idx_stock_movements_variant_date', 'product_variant_id', 'created_at'),
        Index('idx_stock_movements_reference', 'reference_type', 'reference_id'),
    )

class Review(Base):
    """Product reviews and ratings"""
    __tablename__ = 'reviews'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    product_id = Column(Integer, ForeignKey('products.id'), nullable=False)
    order_id = Column(Integer, ForeignKey('orders.id'))  # For verified purchase
    rating = Column(Integer, nullable=False)
    title = Column(String(255))
    comment = Column(Text)
    is_verified_purchase = Column(Boolean, default=False, nullable=False)
    helpful_count = Column(Integer, default=0, nullable=False)
    not_helpful_count = Column(Integer, default=0, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="reviews")
    product = relationship("Product", back_populates="reviews")
    order = relationship("Order", back_populates="reviews")
    
    # Constraints and indexes
    __table_args__ = (
        CheckConstraint('rating >= 1 AND rating <= 5', name='check_review_rating_range'),
        UniqueConstraint('user_id', 'product_id', 'order_id', name='uq_review_user_product_order'),
        Index('idx_reviews_product_rating', 'product_id', 'rating'),
        Index('idx_reviews_product_verified', 'product_id', 'is_verified_purchase'),
        Index('idx_reviews_created_at', 'created_at'),
    )

# ========================================
# DATABASE INITIALIZATION
# ========================================

def create_database():
    """Create all tables in the database"""
    database_url = os.getenv('DATABASE_URL', 'postgresql://workshop_user:workshop_pass@localhost/ecommerce_db')
    engine = create_engine(database_url, echo=True)
    Base.metadata.create_all(engine)
    return engine

def get_session():
    """Get a database session"""
    engine = create_database()
    Session = sessionmaker(bind=engine)
    return Session()

def create_sample_data():
    """Create sample data for testing"""
    session = get_session()
    
    try:
        # Create categories
        electronics = Category(name="Electronics", slug="electronics", is_active=True)
        computers = Category(name="Computers", slug="computers", parent=electronics, is_active=True)
        
        session.add_all([electronics, computers])
        session.commit()
        
        # Create a user
        user = User(
            email="john.doe@example.com",
            password_hash="hashed_password_here",
            first_name="John",
            last_name="Doe",
            is_active=True,
            is_verified=True
        )
        session.add(user)
        session.commit()
        
        # Create address
        address = Address(
            user_id=user.id,
            type=AddressType.SHIPPING,
            is_default=True,
            full_name="John Doe",
            street_address1="123 Main St",
            city="New York",
            state_province="NY",
            postal_code="10001",
            country="US"
        )
        session.add(address)
        session.commit()
        
        # Create a product with variant
        laptop = Product(
            category_id=computers.id,
            name="Professional Laptop",
            slug="professional-laptop",
            description="High-performance laptop for professionals",
            sku="LAPTOP-001",
            base_price=1299.99,
            cost=800.00,
            weight=2.5,
            is_active=True,
            is_featured=True
        )
        session.add(laptop)
        session.commit()
        
        # Create product variant
        variant = ProductVariant(
            product_id=laptop.id,
            sku="LAPTOP-001-BLK-16GB",
            size="16GB RAM",
            color="Black",
            price_adjustment=200.00,
            is_active=True
        )
        session.add(variant)
        session.commit()
        
        # Create inventory
        inventory = Inventory(
            product_variant_id=variant.id,
            quantity_available=50,
            quantity_reserved=5,
            reorder_point=10,
            reorder_quantity=30
        )
        session.add(inventory)
        session.commit()
        
        print("Sample data created successfully!")
        
    except Exception as e:
        session.rollback()
        print(f"Error creating sample data: {e}")
    finally:
        session.close()

# ========================================
# ADDITIONAL INDEXES FOR PERFORMANCE
# ========================================

# Composite indexes for common queries
Index('idx_orders_user_created', Order.user_id, Order.created_at.desc())
Index('idx_products_category_price', Product.category_id, Product.base_price)
Index('idx_inventory_variant_available', Inventory.product_variant_id, Inventory.quantity_available)

# Partial indexes for filtered queries
Index('idx_users_active_verified', User.email, postgresql_where=(User.is_active == True) & (User.is_verified == True))
Index('idx_products_active_featured', Product.id, postgresql_where=(Product.is_active == True) & (Product.is_featured == True))
Index('idx_orders_pending_payment', Order.id, Order.created_at, postgresql_where=Order.status == OrderStatus.PENDING)

if __name__ == "__main__":
    print("Creating database schema...")
    engine = create_database()
    print("Database schema created successfully!")
    
    print("\nCreating sample data...")
    create_sample_data()
    print("\nDone!")