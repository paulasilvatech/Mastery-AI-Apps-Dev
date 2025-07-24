---
sidebar_position: 3
title: "Exercise 2: Part 1"
description: "## 🎯 Exercise Overview"
---

# Exercise 2: TDD Shopping Cart (⭐⭐ Medium)

## 🎯 Exercise Overview

**Duration**: 45-60 minutes  
**Difficulty**: ⭐⭐ (Medium)  
**Success Rate**: 80%

In this exercise, you'll build a complete shopping cart system using Test-Driven Development (TDD) with GitHub Copilot. You'll write tests first, then use Copilot to generate implementation code that makes the tests pass, following the Red-Green-Refactor cycle.

## 🎓 Learning Objectives

By completing this exercise, you will:
- Master the TDD workflow with AI assistance
- Write tests before implementation
- Use Copilot to generate code that passes tests
- Handle complex business logic with TDD
- Refactor with confidence

## 📋 Prerequisites

- ✅ Completed Exercise 1
- ✅ Understanding of TDD principles
- ✅ Familiarity with pytest
- ✅ Copilot actively suggesting

## 🏗️ What You'll Build

An **E-Commerce Shopping Cart** with:
- Add/remove items with quantity
- Discount calculations (percentage, fixed, BOGO)
- Tax computation by region
- Shipping cost calculation
- Cart persistence
- Inventory validation

## 📁 Project Structure

```
exercise2-medium/
├── README.md                  # This file
├── instructions/
│   ├── part1.md              # TDD basics and setup
│   ├── part2.md              # Advanced features
│   └── part3.md              # Integration and refactoring
├── starter/
│   ├── test_shopping_cart.py  # Write tests here first
│   ├── shopping_cart.py       # Implement after tests
│   └── requirements.txt       # Dependencies
├── solution/
│   ├── test_shopping_cart.py  # Complete test suite
│   ├── shopping_cart.py       # Full implementation
│   ├── models.py             # Data models
│   └── discounts.py          # Discount strategies
└── resources/
    └── tdd_workflow.md       # TDD quick reference
```

## 🔄 Understanding TDD with Copilot

### The TDD Cycle

```mermaid
graph LR
    A[Write Failing Test] --&gt; B[Run Test - RED]
    B --&gt; C[Write Minimal Code]
    C --&gt; D[Run Test - GREEN]
    D --&gt; E[Refactor]
    E --&gt; A
    
    style B fill:#ff6b6b
    style D fill:#51cf66
    style E fill:#339af0
```

### TDD + Copilot Workflow

1. **Red Phase**: Write test describing desired behavior
2. **Green Phase**: Let Copilot generate implementation
3. **Refactor Phase**: Ask Copilot for improvements

## 🚀 Part 1: Starting with TDD

### Step 1: Set Up Test File

Create `test_shopping_cart.py` with the basic structure:

```python
# test_shopping_cart.py
import pytest
from decimal import Decimal
from datetime import datetime
from shopping_cart import ShoppingCart, CartItem, DiscountType

# We'll write all tests first, then implement
# This is the TDD way!
```

### Step 2: Write Your First Test (Red Phase)

Start with the simplest test - creating an empty cart:

```python
# Test 1: Create an empty shopping cart
def test_create_empty_cart():
    """Test that we can create an empty shopping cart."""
    cart = ShoppingCart()
    
    assert cart.items == []
    assert cart.total() == Decimal('0.00')
    assert cart.count() == 0
    assert cart.is_empty() is True
```

**Important**: This test will fail! That's expected in TDD.

### Step 3: Run the Test (Verify Red)

```bash
pytest test_shopping_cart.py::test_create_empty_cart -v
```

You'll see:
```
ImportError: cannot import name 'ShoppingCart' from 'shopping_cart'
```

Perfect! We have a failing test.

### Step 4: Generate Implementation (Green Phase)

Now create `shopping_cart.py` and use Copilot to implement:

```python
# shopping_cart.py
from decimal import Decimal
from typing import List, Optional, Dict
from dataclasses import dataclass
from enum import Enum

# Implement ShoppingCart class that makes test_create_empty_cart pass
# The cart should:
# - Have an items list
# - Have a total() method returning Decimal
# - Have a count() method returning int
# - Have an is_empty() method returning bool
```

**🤖 Copilot Prompt Suggestion #1:**
"Create a ShoppingCart class with empty items list, total() returning Decimal('0.00'), count() returning 0, and is_empty() returning True when empty"

**Expected Implementation:**
```python
class ShoppingCart:
    """Shopping cart for e-commerce system."""
    
    def __init__(self):
        self.items: List['CartItem'] = []
    
    def total(self) -&gt; Decimal:
        """Calculate total price of all items in cart."""
        return Decimal('0.00')
    
    def count(self) -&gt; int:
        """Count total number of items in cart."""
        return 0
    
    def is_empty(self) -&gt; bool:
        """Check if cart is empty."""
        return len(self.items) == 0
```

### Step 5: Run Test Again (Verify Green)

```bash
pytest test_shopping_cart.py::test_create_empty_cart -v
```

✅ Test passes! You've completed your first TDD cycle.

### Step 6: Write Test for Adding Items (Red)

Now test adding items to the cart:

```python
# Test 2: Add items to cart
def test_add_item_to_cart():
    """Test adding items to the shopping cart."""
    cart = ShoppingCart()
    
    # Add first item
    cart.add_item(
        product_id="LAPTOP-001",
        name="Gaming Laptop",
        price=Decimal('999.99'),
        quantity=1
    )
    
    assert cart.count() == 1
    assert cart.total() == Decimal('999.99')
    assert cart.is_empty() is False
    
    # Add second item
    cart.add_item(
        product_id="MOUSE-001",
        name="Gaming Mouse",
        price=Decimal('49.99'),
        quantity=2
    )
    
    assert cart.count() == 3  # 1 laptop + 2 mice
    assert cart.total() == Decimal('1099.97')  # 999.99 + (49.99 * 2)
```

### Step 7: Write Test for CartItem Model (Red)

Before implementing add_item, we need CartItem:

```python
# Test 3: CartItem model
def test_cart_item_creation():
    """Test creating a cart item."""
    item = CartItem(
        product_id="LAPTOP-001",
        name="Gaming Laptop",
        price=Decimal('999.99'),
        quantity=1
    )
    
    assert item.product_id == "LAPTOP-001"
    assert item.name == "Gaming Laptop"
    assert item.price == Decimal('999.99')
    assert item.quantity == 1
    assert item.subtotal() == Decimal('999.99')
    
def test_cart_item_subtotal():
    """Test cart item subtotal calculation."""
    item = CartItem(
        product_id="MOUSE-001",
        name="Gaming Mouse",
        price=Decimal('49.99'),
        quantity=3
    )
    
    assert item.subtotal() == Decimal('149.97')
```

### Step 8: Implement CartItem (Green)

Add to `shopping_cart.py`:

```python
# Create CartItem dataclass
# Should have: product_id, name, price (Decimal), quantity (int)
# Should have subtotal() method that returns price * quantity
@dataclass
class CartItem:
```

**🤖 Copilot Prompt Suggestion #2:**
"Create CartItem dataclass with product_id, name, price as Decimal, quantity as int, and subtotal() method returning price * quantity"

### Step 9: Implement add_item Method (Green)

Now implement the add_item method:

```python
# In ShoppingCart class, implement add_item method
# Should create CartItem and add to items list
# Should update total() to sum all item subtotals
# Should update count() to sum all quantities
def add_item(self, product_id: str, name: str, price: Decimal, quantity: int = 1):
```

**🤖 Copilot Prompt Suggestion #3:**
"Implement add_item that creates CartItem, adds to items list, and update total() and count() methods to calculate from items"

## 📦 Part 2: Testing Complex Features

### Step 10: Test Removing Items (Red)

Write tests for removing items:

```python
# Test 4: Remove items from cart
def test_remove_item_from_cart():
    """Test removing items from cart."""
    cart = ShoppingCart()
    
    # Add items
    cart.add_item("LAPTOP-001", "Gaming Laptop", Decimal('999.99'), 1)
    cart.add_item("MOUSE-001", "Gaming Mouse", Decimal('49.99'), 2)
    
    # Remove one mouse
    cart.remove_item("MOUSE-001", quantity=1)
    
    assert cart.count() == 2  # 1 laptop + 1 mouse
    assert cart.total() == Decimal('1049.98')
    
    # Remove all mice
    cart.remove_item("MOUSE-001")
    
    assert cart.count() == 1
    assert cart.total() == Decimal('999.99')
    
def test_remove_nonexistent_item():
    """Test removing item that doesn't exist."""
    cart = ShoppingCart()
    cart.add_item("LAPTOP-001", "Gaming Laptop", Decimal('999.99'), 1)
    
    with pytest.raises(ValueError) as exc_info:
        cart.remove_item("PHONE-001")
    
    assert "Item not found" in str(exc_info.value)
```

### Step 11: Test Quantity Updates (Red)

```python
# Test 5: Update item quantities
def test_update_item_quantity():
    """Test updating item quantities in cart."""
    cart = ShoppingCart()
    cart.add_item("LAPTOP-001", "Gaming Laptop", Decimal('999.99'), 1)
    
    # Increase quantity
    cart.update_quantity("LAPTOP-001", 3)
    
    assert cart.count() == 3
    assert cart.total() == Decimal('2999.97')
    
    # Decrease quantity
    cart.update_quantity("LAPTOP-001", 1)
    
    assert cart.count() == 1
    assert cart.total() == Decimal('999.99')
    
def test_update_quantity_to_zero_removes_item():
    """Test that updating quantity to 0 removes the item."""
    cart = ShoppingCart()
    cart.add_item("LAPTOP-001", "Gaming Laptop", Decimal('999.99'), 2)
    
    cart.update_quantity("LAPTOP-001", 0)
    
    assert cart.is_empty() is True
    assert cart.count() == 0
```

### Step 12: Test Discount System (Red)

Write comprehensive discount tests:

```python
# Test 6: Discount system
def test_percentage_discount():
    """Test applying percentage discount to cart."""
    cart = ShoppingCart()
    cart.add_item("LAPTOP-001", "Gaming Laptop", Decimal('1000.00'), 1)
    cart.add_item("MOUSE-001", "Gaming Mouse", Decimal('50.00'), 2)
    
    # Apply 10% discount
    cart.apply_discount(DiscountType.PERCENTAGE, Decimal('10'))
    
    assert cart.subtotal() == Decimal('1100.00')
    assert cart.discount_amount() == Decimal('110.00')
    assert cart.total() == Decimal('990.00')
    
def test_fixed_discount():
    """Test applying fixed amount discount."""
    cart = ShoppingCart()
    cart.add_item("LAPTOP-001", "Gaming Laptop", Decimal('1000.00'), 1)
    
    # Apply $50 discount
    cart.apply_discount(DiscountType.FIXED, Decimal('50'))
    
    assert cart.subtotal() == Decimal('1000.00')
    assert cart.discount_amount() == Decimal('50.00')
    assert cart.total() == Decimal('950.00')
    
def test_bogo_discount():
    """Test Buy One Get One discount."""
    cart = ShoppingCart()
    cart.add_item("SHIRT-001", "T-Shirt", Decimal('20.00'), 4)
    
    # Apply BOGO discount
    cart.apply_discount(DiscountType.BOGO)
    
    assert cart.subtotal() == Decimal('80.00')
    assert cart.discount_amount() == Decimal('40.00')  # 2 free shirts
    assert cart.total() == Decimal('40.00')
```

### Step 13: Create DiscountType Enum

Add to `shopping_cart.py`:

```python
# Create DiscountType enum with PERCENTAGE, FIXED, and BOGO options
class DiscountType(Enum):
```

**🤖 Copilot Prompt Suggestion #4:**
"Create DiscountType enum with PERCENTAGE, FIXED, and BOGO values"

---

**Continue to Part 2** for implementing the discount system, tax calculations, and shipping features using TDD.