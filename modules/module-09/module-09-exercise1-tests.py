"""
Test suite for E-Commerce Database Schema
Module 09, Exercise 1

Run with: pytest test_schema.py -v
"""

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import IntegrityError
from decimal import Decimal
from datetime import datetime, timedelta

# Import all models from the solution
from models import (
    Base, User, Address, Category, Product, ProductVariant, 
    ProductImage, CartItem, Order, OrderItem, Inventory, 
    StockMovement, Review, OrderStatus, AddressType, MovementType
)

# Test database URL (use a separate test database)
TEST_DATABASE_URL = "postgresql://workshop_user:workshop_pass@localhost/ecommerce_test"

@pytest.fixture(scope="module")
def engine():
    """Create test database engine"""
    engine = create_engine(TEST_DATABASE_URL)
    Base.metadata.create_all(engine)
    yield engine
    Base.metadata.drop_all(engine)

@pytest.fixture(scope="function")
def session(engine):
    """Create a new session for each test"""
    Session = sessionmaker(bind=engine)
    session = Session()
    yield session
    session.rollback()
    session.close()

# ========================================
# USER TESTS
# ========================================

def test_create_user(session):
    """Test creating a basic user"""
    user = User(
        email="test@example.com",
        password_hash="hashed_password",
        first_name="Test",
        last_name="User"
    )
    session.add(user)
    session.commit()
    
    assert user.id is not None
    assert user.is_active == True
    assert user.is_verified == False
    assert user.created_at is not None

def test_user_email_unique(session):
    """Test that email must be unique"""
    user1 = User(
        email="unique@example.com",
        password_hash="hash1",
        first_name="User",
        last_name="One"
    )
    user2 = User(
        email="unique@example.com",
        password_hash="hash2",
        first_name="User",
        last_name="Two"
    )
    
    session.add(user1)
    session.commit()
    
    session.add(user2)
    with pytest.raises(IntegrityError):
        session.commit()

def test_user_cascade_delete(session):
    """Test that deleting user cascades properly"""
    # Create user with related data
    user = User(
        email="cascade@example.com",
        password_hash="hash",
        first_name="Cascade",
        last_name="Test"
    )
    session.add(user)
    session.commit()
    
    # Add address
    address = Address(
        user_id=user.id,
        type=AddressType.SHIPPING,
        full_name="Test User",
        street_address1="123 Test St",
        city="Test City",
        state_province="TS",
        postal_code="12345",
        country="US"
    )
    session.add(address)
    session.commit()
    
    # Delete user
    session.delete(user)
    session.commit()
    
    # Check address was deleted
    assert session.query(Address).filter_by(id=address.id).first() is None

# ========================================
# PRODUCT TESTS
# ========================================

def test_create_product_hierarchy(session):
    """Test creating categories and products"""
    # Create category hierarchy
    electronics = Category(
        name="Electronics",
        slug="electronics",
        is_active=True
    )
    laptops = Category(
        name="Laptops",
        slug="laptops",
        parent=electronics,
        is_active=True
    )
    session.add_all([electronics, laptops])
    session.commit()
    
    # Create product
    product = Product(
        category_id=laptops.id,
        name="Test Laptop",
        slug="test-laptop",
        sku="TEST-001",
        base_price=Decimal("999.99"),
        cost=Decimal("600.00"),
        weight=Decimal("2.5")
    )
    session.add(product)
    session.commit()
    
    assert product.id is not None
    assert product.category.name == "Laptops"
    assert product.category.parent.name == "Electronics"

def test_product_price_constraint(session):
    """Test that product prices must be non-negative"""
    category = Category(name="Test", slug="test")
    session.add(category)
    session.commit()
    
    product = Product(
        category_id=category.id,
        name="Invalid Product",
        slug="invalid-product",
        sku="INVALID-001",
        base_price=Decimal("-10.00")  # Negative price
    )
    
    session.add(product)
    with pytest.raises(IntegrityError):
        session.commit()

def test_product_variant_uniqueness(session):
    """Test that product variants must be unique by attributes"""
    # Create product
    category = Category(name="Clothing", slug="clothing")
    session.add(category)
    session.commit()
    
    product = Product(
        category_id=category.id,
        name="T-Shirt",
        slug="t-shirt",
        sku="TSHIRT-001",
        base_price=Decimal("19.99")
    )
    session.add(product)
    session.commit()
    
    # Create first variant
    variant1 = ProductVariant(
        product_id=product.id,
        sku="TSHIRT-001-RED-M",
        size="M",
        color="Red"
    )
    session.add(variant1)
    session.commit()
    
    # Try to create duplicate variant
    variant2 = ProductVariant(
        product_id=product.id,
        sku="TSHIRT-001-RED-M-2",  # Different SKU
        size="M",  # Same size
        color="Red"  # Same color
    )
    session.add(variant2)
    with pytest.raises(IntegrityError):
        session.commit()

# ========================================
# ORDER TESTS
# ========================================

def test_create_order_workflow(session):
    """Test complete order creation workflow"""
    # Setup: Create user, product, and variant
    user = User(
        email="order@example.com",
        password_hash="hash",
        first_name="Order",
        last_name="Test"
    )
    session.add(user)
    
    category = Category(name="Test", slug="test")
    session.add(category)
    session.commit()
    
    product = Product(
        category_id=category.id,
        name="Test Product",
        slug="test-product",
        sku="TEST-001",
        base_price=Decimal("50.00")
    )
    session.add(product)
    session.commit()
    
    variant = ProductVariant(
        product_id=product.id,
        sku="TEST-001-DEFAULT"
    )
    session.add(variant)
    session.commit()
    
    # Create order
    order = Order(
        user_id=user.id,
        order_number="ORD-001",
        status=OrderStatus.PENDING,
        subtotal=Decimal("100.00"),
        tax_amount=Decimal("10.00"),
        shipping_amount=Decimal("5.00"),
        total_amount=Decimal("115.00")
    )
    session.add(order)
    session.commit()
    
    # Add order items
    order_item = OrderItem(
        order_id=order.id,
        product_variant_id=variant.id,
        quantity=2,
        price_at_time=Decimal("50.00"),
        total_amount=Decimal("100.00")
    )
    session.add(order_item)
    session.commit()
    
    assert order.id is not None
    assert len(order.items) == 1
    assert order.items[0].quantity == 2

def test_order_status_workflow(session):
    """Test order status transitions"""
    user = User(
        email="status@example.com",
        password_hash="hash",
        first_name="Status",
        last_name="Test"
    )
    session.add(user)
    session.commit()
    
    order = Order(
        user_id=user.id,
        order_number="ORD-002",
        status=OrderStatus.PENDING,
        subtotal=Decimal("100.00"),
        total_amount=Decimal("100.00")
    )
    session.add(order)
    session.commit()
    
    # Update status to paid
    order.status = OrderStatus.PAID
    order.paid_at = datetime.utcnow()
    session.commit()
    
    # Update status to shipped
    order.status = OrderStatus.SHIPPED
    order.shipped_at = datetime.utcnow()
    session.commit()
    
    assert order.status == OrderStatus.SHIPPED
    assert order.paid_at is not None
    assert order.shipped_at is not None

# ========================================
# INVENTORY TESTS
# ========================================

def test_inventory_management(session):
    """Test inventory tracking"""
    # Setup product variant
    category = Category(name="Test", slug="test")
    session.add(category)
    session.commit()
    
    product = Product(
        category_id=category.id,
        name="Inventory Test",
        slug="inventory-test",
        sku="INV-001",
        base_price=Decimal("25.00")
    )
    session.add(product)
    session.commit()
    
    variant = ProductVariant(
        product_id=product.id,
        sku="INV-001-DEFAULT"
    )
    session.add(variant)
    session.commit()
    
    # Create inventory
    inventory = Inventory(
        product_variant_id=variant.id,
        quantity_available=100,
        quantity_reserved=10,
        reorder_point=20,
        reorder_quantity=50
    )
    session.add(inventory)
    session.commit()
    
    assert inventory.quantity_on_hand == 110  # available + reserved
    
    # Test stock movement
    movement = StockMovement(
        product_variant_id=variant.id,
        movement_type=MovementType.SALE,
        quantity=-5,  # Negative for sale
        reference_type="order",
        reference_id=1
    )
    session.add(movement)
    session.commit()
    
    assert movement.id is not None

def test_inventory_constraints(session):
    """Test inventory quantity constraints"""
    # Setup
    category = Category(name="Test", slug="test")
    session.add(category)
    session.commit()
    
    product = Product(
        category_id=category.id,
        name="Constraint Test",
        slug="constraint-test",
        sku="CONST-001",
        base_price=Decimal("10.00")
    )
    session.add(product)
    session.commit()
    
    variant = ProductVariant(
        product_id=product.id,
        sku="CONST-001-DEFAULT"
    )
    session.add(variant)
    session.commit()
    
    # Try to create inventory with negative quantity
    inventory = Inventory(
        product_variant_id=variant.id,
        quantity_available=-10  # Negative quantity
    )
    session.add(inventory)
    with pytest.raises(IntegrityError):
        session.commit()

# ========================================
# CART TESTS
# ========================================

def test_shopping_cart(session):
    """Test shopping cart functionality"""
    # Setup user and product
    user = User(
        email="cart@example.com",
        password_hash="hash",
        first_name="Cart",
        last_name="Test"
    )
    session.add(user)
    
    category = Category(name="Test", slug="test")
    session.add(category)
    session.commit()
    
    product = Product(
        category_id=category.id,
        name="Cart Product",
        slug="cart-product",
        sku="CART-001",
        base_price=Decimal("30.00")
    )
    session.add(product)
    session.commit()
    
    variant = ProductVariant(
        product_id=product.id,
        sku="CART-001-DEFAULT"
    )
    session.add(variant)
    session.commit()
    
    # Add to cart
    cart_item = CartItem(
        user_id=user.id,
        product_variant_id=variant.id,
        quantity=3
    )
    session.add(cart_item)
    session.commit()
    
    assert cart_item.id is not None
    assert len(user.cart_items) == 1

def test_cart_unique_constraint(session):
    """Test that user can't have duplicate items in cart"""
    # Setup
    user = User(
        email="unique_cart@example.com",
        password_hash="hash",
        first_name="Unique",
        last_name="Cart"
    )
    session.add(user)
    
    category = Category(name="Test", slug="test")
    session.add(category)
    session.commit()
    
    product = Product(
        category_id=category.id,
        name="Unique Product",
        slug="unique-product",
        sku="UNIQUE-001",
        base_price=Decimal("20.00")
    )
    session.add(product)
    session.commit()
    
    variant = ProductVariant(
        product_id=product.id,
        sku="UNIQUE-001-DEFAULT"
    )
    session.add(variant)
    session.commit()
    
    # Add first item
    cart_item1 = CartItem(
        user_id=user.id,
        product_variant_id=variant.id,
        quantity=1
    )
    session.add(cart_item1)
    session.commit()
    
    # Try to add duplicate
    cart_item2 = CartItem(
        user_id=user.id,
        product_variant_id=variant.id,
        quantity=2
    )
    session.add(cart_item2)
    with pytest.raises(IntegrityError):
        session.commit()

# ========================================
# REVIEW TESTS
# ========================================

def test_product_reviews(session):
    """Test review system with verified purchases"""
    # Setup
    user = User(
        email="reviewer@example.com",
        password_hash="hash",
        first_name="Review",
        last_name="User"
    )
    session.add(user)
    
    category = Category(name="Test", slug="test")
    session.add(category)
    session.commit()
    
    product = Product(
        category_id=category.id,
        name="Review Product",
        slug="review-product",
        sku="REV-001",
        base_price=Decimal("40.00")
    )
    session.add(product)
    session.commit()
    
    # Create an order (for verified purchase)
    order = Order(
        user_id=user.id,
        order_number="ORD-REV-001",
        status=OrderStatus.DELIVERED,
        subtotal=Decimal("40.00"),
        total_amount=Decimal("40.00")
    )
    session.add(order)
    session.commit()
    
    # Add review
    review = Review(
        user_id=user.id,
        product_id=product.id,
        order_id=order.id,
        rating=5,
        title="Great product!",
        comment="Really satisfied with this purchase.",
        is_verified_purchase=True
    )
    session.add(review)
    session.commit()
    
    assert review.id is not None
    assert review.is_verified_purchase == True

def test_review_rating_constraint(session):
    """Test that ratings must be between 1 and 5"""
    # Setup
    user = User(
        email="bad_reviewer@example.com",
        password_hash="hash",
        first_name="Bad",
        last_name="Reviewer"
    )
    session.add(user)
    
    category = Category(name="Test", slug="test")
    session.add(category)
    session.commit()
    
    product = Product(
        category_id=category.id,
        name="Bad Review Product",
        slug="bad-review-product",
        sku="BAD-001",
        base_price=Decimal("10.00")
    )
    session.add(product)
    session.commit()
    
    # Try to create review with invalid rating
    review = Review(
        user_id=user.id,
        product_id=product.id,
        rating=6,  # Invalid rating
        comment="Too high rating"
    )
    session.add(review)
    with pytest.raises(IntegrityError):
        session.commit()

# ========================================
# PERFORMANCE TESTS
# ========================================

def test_query_performance(session):
    """Test that common queries use indexes efficiently"""
    # This would normally use EXPLAIN ANALYZE in production
    # Here we just ensure queries execute without N+1 problems
    
    # Create test data
    user = User(
        email="perf@example.com",
        password_hash="hash",
        first_name="Perf",
        last_name="Test"
    )
    session.add(user)
    session.commit()
    
    # Query user with orders (should use join)
    from sqlalchemy.orm import joinedload
    user_with_orders = session.query(User)\
        .options(joinedload(User.orders))\
        .filter_by(email="perf@example.com")\
        .first()
    
    # This should not trigger additional queries
    orders = user_with_orders.orders
    assert isinstance(orders, list)

if __name__ == "__main__":
    pytest.main([__file__, "-v"])