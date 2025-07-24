---
sidebar_position: 8
title: "Exercise 2: Part 2"
description: "## 🚀 Part 3: Tax and Shipping Calculations"
---

# Exercício 2: TDD Shopping Cart - Partee 2

## 🚀 Partee 3: Tax and Shipping Calculations

### Step 14: Test Tax Calculations (Red)

Write tests for regional tax calculations:

```python
# Test 7: Tax calculations by region
def test_tax_calculation_by_state():
    """Test calculating tax based on shipping state."""
    cart = ShoppingCart()
    cart.add_item("LAPTOP-001", "Gaming Laptop", Decimal('1000.00'), 1)
    
    # California tax (7.25%)
    cart.set_shipping_address(state="CA")
    
    assert cart.subtotal() == Decimal('1000.00')
    assert cart.tax_rate() == Decimal('0.0725')
    assert cart.tax_amount() == Decimal('72.50')
    assert cart.total() == Decimal('1072.50')
    
def test_tax_calculation_with_discount():
    """Test that tax is calculated after discount."""
    cart = ShoppingCart()
    cart.add_item("LAPTOP-001", "Gaming Laptop", Decimal('1000.00'), 1)
    
    # Apply discount first
    cart.apply_discount(DiscountType.FIXED, Decimal('100'))
    
    # Set state for tax
    cart.set_shipping_address(state="NY")  # 8% tax
    
    assert cart.subtotal() == Decimal('1000.00')
    assert cart.discount_amount() == Decimal('100.00')
    assert cart.taxable_amount() == Decimal('900.00')  # After discount
    assert cart.tax_amount() == Decimal('72.00')  # 8% of 900
    assert cart.total() == Decimal('972.00')
    
def test_tax_free_states():
    """Test states with no sales tax."""
    cart = ShoppingCart()
    cart.add_item("LAPTOP-001", "Gaming Laptop", Decimal('1000.00'), 1)
    
    # Oregon has no sales tax
    cart.set_shipping_address(state="OR")
    
    assert cart.tax_rate() == Decimal('0.00')
    assert cart.tax_amount() == Decimal('0.00')
    assert cart.total() == Decimal('1000.00')
```

### Step 15: Test Shipping Calculations (Red)

```python
# Test 8: Shipping cost calculations
def test_shipping_standard():
    """Test standard shipping cost calculation."""
    cart = ShoppingCart()
    cart.add_item("BOOK-001", "Python Guide", Decimal('29.99'), 1, weight=1.5)
    cart.add_item("LAPTOP-001", "Gaming Laptop", Decimal('999.99'), 1, weight=5.0)
    
    cart.set_shipping_method("STANDARD")
    
    assert cart.total_weight() == Decimal('6.5')
    assert cart.shipping_cost() == Decimal('9.99')  # Standard rate
    
def test_shipping_express():
    """Test express shipping cost."""
    cart = ShoppingCart()
    cart.add_item("BOOK-001", "Python Guide", Decimal('29.99'), 2, weight=1.5)
    
    cart.set_shipping_method("EXPRESS")
    
    assert cart.total_weight() == Decimal('3.0')  # 2 books * 1.5
    assert cart.shipping_cost() == Decimal('19.99')  # Express rate
    
def test_free_shipping_threshold():
    """Test free shipping for orders over threshold."""
    cart = ShoppingCart()
    cart.add_item("LAPTOP-001", "Gaming Laptop", Decimal('999.99'), 1)
    cart.add_item("MOUSE-001", "Gaming Mouse", Decimal('50.01'), 1)
    
    cart.set_shipping_method("STANDARD")
    
    # Total is $1050, threshold is $100
    assert cart.subtotal() &gt;= Decimal('100.00')
    assert cart.shipping_cost() == Decimal('0.00')
```

### Step 16: Implement Tax System (Green)

Now implement the tax calculation features:

```python
# Add to shopping_cart.py

# Tax rates by state (simplified)
TAX_RATES = {
    'CA': Decimal('0.0725'),
    'NY': Decimal('0.08'),
    'TX': Decimal('0.0625'),
    'FL': Decimal('0.06'),
    'OR': Decimal('0.00'),  # No sales tax
    'MT': Decimal('0.00'),  # No sales tax
    'NH': Decimal('0.00'),  # No sales tax
    # Add more states as needed
}

# Update ShoppingCart class to handle tax
# Add methods: set_shipping_address, tax_rate, tax_amount, taxable_amount
```

**🤖 Copilot Prompt Suggestion #5:**
"Add tax calculation to ShoppingCart: set_shipping_address(state), tax_rate() returns rate from TAX_RATES, tax_amount() calculates tax on discounted subtotal, update total() to include tax"

### Step 17: Implement Shipping System (Green)

```python
# Shipping rates
SHIPPING_RATES = {
    'STANDARD': Decimal('9.99'),
    'EXPRESS': Decimal('19.99'),
    'OVERNIGHT': Decimal('39.99')
}

FREE_SHIPPING_THRESHOLD = Decimal('100.00')

# Add weight parameter to CartItem
# Add shipping methods to ShoppingCart
```

**🤖 Copilot Prompt Suggestion #6:**
"Atualizar CartItem to include weight parameter, add total_weight() to ShoppingCart, implement set_shipping_method() and shipping_cost() with free shipping over $100"

## 💾 Partee 4: Cart Persistence

### Step 18: Test Cart Serialization (Red)

```python
# Test 9: Cart persistence
def test_cart_to_dict():
    """Test converting cart to dictionary for storage."""
    cart = ShoppingCart()
    cart.add_item("LAPTOP-001", "Gaming Laptop", Decimal('999.99'), 1)
    cart.apply_discount(DiscountType.PERCENTAGE, Decimal('10'))
    cart.set_shipping_address(state="CA")
    cart.set_shipping_method("EXPRESS")
    
    cart_dict = cart.to_dict()
    
    assert cart_dict['items'][0]['product_id'] == "LAPTOP-001"
    assert cart_dict['items'][0]['quantity'] == 1
    assert cart_dict['discount']['type'] == "PERCENTAGE"
    assert cart_dict['discount']['value'] == "10"
    assert cart_dict['shipping']['state'] == "CA"
    assert cart_dict['shipping']['method'] == "EXPRESS"
    assert 'created_at' in cart_dict
    assert 'updated_at' in cart_dict
    
def test_cart_from_dict():
    """Test loading cart from dictionary."""
    cart_data = {
        'items': [
            {
                'product_id': 'LAPTOP-001',
                'name': 'Gaming Laptop',
                'price': '999.99',
                'quantity': 2,
                'weight': '5.0'
            }
        ],
        'discount': {
            'type': 'FIXED',
            'value': '50.00'
        },
        'shipping': {
            'state': 'NY',
            'method': 'STANDARD'
        },
        'created_at': '2024-01-15T10:30:00',
        'updated_at': '2024-01-15T11:00:00'
    }
    
    cart = ShoppingCart.from_dict(cart_data)
    
    assert cart.count() == 2
    assert cart.subtotal() == Decimal('1999.98')
    assert cart.discount_amount() == Decimal('50.00')
    assert cart.tax_rate() == Decimal('0.08')
```

### Step 19: Test Cart Validation (Red)

```python
# Test 10: Cart validation
def test_validate_inventory():
    """Test inventory validation before checkout."""
    cart = ShoppingCart()
    cart.add_item("LAPTOP-001", "Gaming Laptop", Decimal('999.99'), 2)
    cart.add_item("MOUSE-001", "Gaming Mouse", Decimal('49.99'), 5)
    
    # Mock inventory check
    inventory = {
        "LAPTOP-001": 1,  # Only 1 available
        "MOUSE-001": 10   # Plenty available
    }
    
    validation_result = cart.validate_inventory(inventory)
    
    assert validation_result.is_valid is False
    assert len(validation_result.errors) == 1
    assert validation_result.errors[0]['product_id'] == "LAPTOP-001"
    assert validation_result.errors[0]['requested'] == 2
    assert validation_result.errors[0]['available'] == 1
    
def test_validate_minimum_order():
    """Test minimum order amount validation."""
    cart = ShoppingCart()
    cart.add_item("PENCIL-001", "Pencil", Decimal('0.99'), 1)
    
    validation_result = cart.validate_checkout(min_order=Decimal('10.00'))
    
    assert validation_result.is_valid is False
    assert "Minimum order amount" in validation_result.errors[0]['message']
```

## 🔄 Partee 5: Refactoring (Green to Better Green)

### Step 20: Extract Discount Strategies

After all tests pass, refactor the discount system:

```python
# Create discounts.py with strategy pattern
from abc import ABC, abstractmethod
from decimal import Decimal
from typing import List

class DiscountStrategy(ABC):
    """Abstract base class for discount strategies."""
    
    @abstractmethod
    def calculate_discount(self, items: List[CartItem]) -&gt; Decimal:
        """Calculate discount amount for given items."""
        pass

class PercentageDiscount(DiscountStrategy):
    """Percentage-based discount strategy."""
    
    def __init__(self, percentage: Decimal):
        self.percentage = percentage
    
    def calculate_discount(self, items: List[CartItem]) -&gt; Decimal:
        subtotal = sum(item.subtotal() for item in items)
        return subtotal * (self.percentage / Decimal('100'))

# Implement FixedDiscount and BOGODiscount classes
```

**🤖 Copilot Prompt Suggestion #7:**
"Implement FixedDiscount that returns min(fixed_amount, subtotal) and BOGODiscount that calculates free items for pairs"

### Step 21: Refactor Tax Calculation

Extract tax calculation to a separate class:

```python
# Create tax_calculator.py
class TaxCalculator:
    """Handles regional tax calculations."""
    
    def __init__(self):
        self.rates = TAX_RATES
    
    def calculate_tax(self, taxable_amount: Decimal, state: str) -&gt; Decimal:
        """Calculate tax for given amount and state."""
        rate = self.rates.get(state, Decimal('0.00'))
        return taxable_amount * rate
    
    def is_tax_free(self, state: str) -&gt; bool:
        """Check if state has no sales tax."""
        return self.rates.get(state, Decimal('0.00')) == Decimal('0.00')
```

## ✅ Partee 6: Integration Tests

### Step 22: Write Full Workflow Tests

```python
# Test 11: Complete checkout workflow
def test_complete_checkout_workflow():
    """Test full shopping cart workflow from empty to checkout."""
    # Create cart
    cart = ShoppingCart()
    
    # Add items
    cart.add_item("LAPTOP-001", "Gaming Laptop", Decimal('999.99'), 1, weight=5.0)
    cart.add_item("MOUSE-001", "Gaming Mouse", Decimal('49.99'), 2, weight=0.5)
    cart.add_item("KEYBOARD-001", "Mechanical Keyboard", Decimal('149.99'), 1, weight=1.0)
    
    # Apply discount code
    cart.apply_discount(DiscountType.PERCENTAGE, Decimal('15'))
    
    # Set shipping
    cart.set_shipping_address(state="CA")
    cart.set_shipping_method("STANDARD")
    
    # Validate inventory
    inventory = {
        "LAPTOP-001": 5,
        "MOUSE-001": 10,
        "KEYBOARD-001": 3
    }
    validation = cart.validate_inventory(inventory)
    assert validation.is_valid is True
    
    # Check final totals
    assert cart.subtotal() == Decimal('1249.96')
    assert cart.discount_amount() == Decimal('187.49')  # 15% off
    assert cart.taxable_amount() == Decimal('1062.47')
    assert cart.tax_amount() == Decimal('77.03')  # 7.25% CA tax
    assert cart.shipping_cost() == Decimal('0.00')  # Free shipping over $100
    assert cart.total() == Decimal('1139.50')
    
    # Generate order summary
    summary = cart.order_summary()
    assert summary['item_count'] == 4
    assert summary['total_weight'] == '7.0'
    assert 'items' in summary
    assert 'totals' in summary
```

## 🏁 TDD Melhores Práticas Applied

### What We Learned

1. **Write Test First**
   - Describe behavior before implementation
   - Think about API design upfront
   - Consider edge cases early

2. **Minimal Implementation**
   - Write just enough code to pass
   - Don't over-engineer initially
   - Add features incrementally

3. **Refactor Confidently**
   - Tests provide safety net
   - Extract patterns when they emerge
   - Keep code clean and maintainable

### Copilot TDD Tips

1. **Describe Intent Clearly**
   ```python
   # Bad: Implement discount
   # Good: Calculate 15% discount on subtotal after removing tax-exempt items
   ```

2. **Reference Test Requirements**
   ```python
   # Implement method to make test_calculate_tax_after_discount pass
   # Should apply discount first, then calculate tax on discounted amount
   ```

3. **Ask for Incremental Changes**
   ```python
   # First: Make the test pass with simple implementation
   # Then: Optimize for performance
   # Finally: Add error handling
   ```

## 🎯 Validation Script

Create `validate_tdd.py` to check your TDD progress:

```python
#!/usr/bin/env python3
"""Validate TDD implementation."""

import subprocess
import sys
from pathlib import Path

def run_tests_individually():
    """Run each test method individually to verify TDD approach."""
    test_methods = [
        "test_create_empty_cart",
        "test_add_item_to_cart",
        "test_cart_item_creation",
        "test_remove_item_from_cart",
        "test_percentage_discount",
        "test_tax_calculation_by_state",
        "test_shipping_standard",
        "test_cart_to_dict",
        "test_validate_inventory",
        "test_complete_checkout_workflow"
    ]
    
    passed = 0
    failed = 0
    
    for test in test_methods:
        result = subprocess.run(
            f"pytest test_shopping_cart.py::{test} -v",
            shell=True,
            capture_output=True
        )
        
        if result.returncode == 0:
            print(f"✅ {test}")
            passed += 1
        else:
            print(f"❌ {test}")
            failed += 1
    
    print(f"\n📊 Results: {passed} passed, {failed} failed")
    return failed == 0

if __name__ == "__main__":
    success = run_tests_individually()
    sys.exit(0 if success else 1)
```

---

**Continue to Part 3** for final integration and performance optimization.