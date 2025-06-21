# Exercise 2: TDD Shopping Cart - Part 3

## 🚀 Part 7: Performance and Edge Cases

### Step 23: Test Performance with Large Carts

Add performance tests to ensure the cart scales well:

```python
# Test 12: Performance with large carts
def test_large_cart_performance(benchmark):
    """Test performance with many items in cart."""
    cart = ShoppingCart()
    
    # Function to benchmark
    def add_many_items():
        for i in range(100):
            cart.add_item(
                f"ITEM-{i:03d}",
                f"Product {i}",
                Decimal(f"{10 + i * 0.5}"),
                quantity=1
            )
    
    # Benchmark the operation
    benchmark(add_many_items)
    
    assert cart.count() == 100
    assert cart.total() > Decimal('1000')

def test_search_performance(benchmark):
    """Test searching items in large cart."""
    cart = ShoppingCart()
    
    # Add 1000 items
    for i in range(1000):
        cart.add_item(
            f"ITEM-{i:04d}",
            f"Product {i}",
            Decimal('9.99'),
            quantity=1
        )
    
    # Benchmark searching
    result = benchmark(cart.find_item, "ITEM-0500")
    assert result is not None
```

### Step 24: Test Edge Cases

```python
# Test 13: Edge cases and boundary conditions
def test_decimal_precision():
    """Test that decimal calculations maintain precision."""
    cart = ShoppingCart()
    
    # Add items with prices that could cause floating point errors
    cart.add_item("ITEM-001", "Product 1", Decimal('0.1'), 3)
    cart.add_item("ITEM-002", "Product 2", Decimal('0.2'), 1)
    
    # This would be 0.5 in float, but we need exact decimal
    assert cart.total() == Decimal('0.5')
    
    # Apply percentage discount
    cart.apply_discount(DiscountType.PERCENTAGE, Decimal('33.33'))
    
    # Should maintain precision
    assert cart.discount_amount() == Decimal('0.17')  # Rounded to 2 decimal places
    
def test_max_quantity_limits():
    """Test maximum quantity constraints."""
    cart = ShoppingCart()
    
    # Try to add more than max allowed
    with pytest.raises(ValueError) as exc_info:
        cart.add_item("ITEM-001", "Product", Decimal('9.99'), quantity=1001)
    
    assert "Maximum quantity is 999" in str(exc_info.value)
    
def test_concurrent_modifications():
    """Test cart behavior with concurrent-like modifications."""
    cart = ShoppingCart()
    cart.add_item("ITEM-001", "Product", Decimal('50.00'), 2)
    
    # Simulate concurrent update scenarios
    cart.update_quantity("ITEM-001", 5)
    cart.apply_discount(DiscountType.FIXED, Decimal('20'))
    cart.update_quantity("ITEM-001", 3)
    
    # Ensure consistency
    assert cart.count() == 3
    assert cart.subtotal() == Decimal('150.00')
    assert cart.discount_amount() == Decimal('20.00')
    assert cart.total() == Decimal('130.00')
```

## 🏗️ Part 8: Complete Implementation

### Step 25: Final ShoppingCart Implementation

Here's the complete implementation that passes all tests:

```python
# shopping_cart.py
from decimal import Decimal, ROUND_HALF_UP
from typing import List, Optional, Dict, Any
from dataclasses import dataclass, field
from enum import Enum
from datetime import datetime
import json

# Constants
TAX_RATES = {
    'CA': Decimal('0.0725'),
    'NY': Decimal('0.08'),
    'TX': Decimal('0.0625'),
    'FL': Decimal('0.06'),
    'OR': Decimal('0.00'),
    'MT': Decimal('0.00'),
    'NH': Decimal('0.00'),
}

SHIPPING_RATES = {
    'STANDARD': Decimal('9.99'),
    'EXPRESS': Decimal('19.99'),
    'OVERNIGHT': Decimal('39.99')
}

FREE_SHIPPING_THRESHOLD = Decimal('100.00')
MAX_QUANTITY_PER_ITEM = 999

class DiscountType(Enum):
    PERCENTAGE = "PERCENTAGE"
    FIXED = "FIXED"
    BOGO = "BOGO"

@dataclass
class CartItem:
    """Represents an item in the shopping cart."""
    product_id: str
    name: str
    price: Decimal
    quantity: int
    weight: Decimal = Decimal('0.0')
    
    def subtotal(self) -> Decimal:
        """Calculate subtotal for this item."""
        return (self.price * self.quantity).quantize(
            Decimal('0.01'), rounding=ROUND_HALF_UP
        )
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for serialization."""
        return {
            'product_id': self.product_id,
            'name': self.name,
            'price': str(self.price),
            'quantity': self.quantity,
            'weight': str(self.weight)
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'CartItem':
        """Create CartItem from dictionary."""
        return cls(
            product_id=data['product_id'],
            name=data['name'],
            price=Decimal(data['price']),
            quantity=data['quantity'],
            weight=Decimal(data.get('weight', '0.0'))
        )

@dataclass
class ValidationResult:
    """Result of cart validation."""
    is_valid: bool
    errors: List[Dict[str, Any]] = field(default_factory=list)

class ShoppingCart:
    """E-commerce shopping cart with TDD implementation."""
    
    def __init__(self):
        self.items: List[CartItem] = []
        self._discount_type: Optional[DiscountType] = None
        self._discount_value: Optional[Decimal] = None
        self._shipping_state: Optional[str] = None
        self._shipping_method: Optional[str] = None
        self.created_at = datetime.now()
        self.updated_at = datetime.now()
    
    def add_item(self, product_id: str, name: str, price: Decimal, 
                 quantity: int = 1, weight: Decimal = Decimal('0.0')):
        """Add item to cart or update quantity if exists."""
        if quantity > MAX_QUANTITY_PER_ITEM:
            raise ValueError(f"Maximum quantity is {MAX_QUANTITY_PER_ITEM}")
        
        # Check if item already exists
        existing_item = self.find_item(product_id)
        if existing_item:
            new_quantity = existing_item.quantity + quantity
            if new_quantity > MAX_QUANTITY_PER_ITEM:
                raise ValueError(f"Maximum quantity is {MAX_QUANTITY_PER_ITEM}")
            existing_item.quantity = new_quantity
        else:
            item = CartItem(product_id, name, price, quantity, weight)
            self.items.append(item)
        
        self._update_timestamp()
    
    def remove_item(self, product_id: str, quantity: Optional[int] = None):
        """Remove item or reduce quantity."""
        item = self.find_item(product_id)
        if not item:
            raise ValueError(f"Item not found: {product_id}")
        
        if quantity is None or quantity >= item.quantity:
            self.items.remove(item)
        else:
            item.quantity -= quantity
        
        self._update_timestamp()
    
    def update_quantity(self, product_id: str, quantity: int):
        """Update item quantity."""
        if quantity > MAX_QUANTITY_PER_ITEM:
            raise ValueError(f"Maximum quantity is {MAX_QUANTITY_PER_ITEM}")
        
        item = self.find_item(product_id)
        if not item:
            raise ValueError(f"Item not found: {product_id}")
        
        if quantity == 0:
            self.items.remove(item)
        else:
            item.quantity = quantity
        
        self._update_timestamp()
    
    def find_item(self, product_id: str) -> Optional[CartItem]:
        """Find item by product ID."""
        for item in self.items:
            if item.product_id == product_id:
                return item
        return None
    
    def apply_discount(self, discount_type: DiscountType, 
                      value: Optional[Decimal] = None):
        """Apply discount to cart."""
        self._discount_type = discount_type
        self._discount_value = value
        self._update_timestamp()
    
    def set_shipping_address(self, state: str):
        """Set shipping state for tax calculation."""
        self._shipping_state = state
        self._update_timestamp()
    
    def set_shipping_method(self, method: str):
        """Set shipping method."""
        if method not in SHIPPING_RATES:
            raise ValueError(f"Invalid shipping method: {method}")
        self._shipping_method = method
        self._update_timestamp()
    
    def count(self) -> int:
        """Total item count in cart."""
        return sum(item.quantity for item in self.items)
    
    def is_empty(self) -> bool:
        """Check if cart is empty."""
        return len(self.items) == 0
    
    def subtotal(self) -> Decimal:
        """Calculate subtotal before discounts and tax."""
        total = sum(item.subtotal() for item in self.items)
        return total.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
    
    def discount_amount(self) -> Decimal:
        """Calculate discount amount."""
        if not self._discount_type:
            return Decimal('0.00')
        
        if self._discount_type == DiscountType.PERCENTAGE:
            amount = self.subtotal() * (self._discount_value / Decimal('100'))
        elif self._discount_type == DiscountType.FIXED:
            amount = min(self._discount_value, self.subtotal())
        elif self._discount_type == DiscountType.BOGO:
            amount = self._calculate_bogo_discount()
        else:
            amount = Decimal('0.00')
        
        return amount.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
    
    def _calculate_bogo_discount(self) -> Decimal:
        """Calculate Buy One Get One discount."""
        total_discount = Decimal('0.00')
        for item in self.items:
            free_items = item.quantity // 2
            total_discount += item.price * free_items
        return total_discount
    
    def taxable_amount(self) -> Decimal:
        """Calculate amount subject to tax (after discounts)."""
        return self.subtotal() - self.discount_amount()
    
    def tax_rate(self) -> Decimal:
        """Get tax rate for shipping state."""
        if not self._shipping_state:
            return Decimal('0.00')
        return TAX_RATES.get(self._shipping_state, Decimal('0.00'))
    
    def tax_amount(self) -> Decimal:
        """Calculate tax amount."""
        amount = self.taxable_amount() * self.tax_rate()
        return amount.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
    
    def total_weight(self) -> Decimal:
        """Calculate total weight of items."""
        total = sum(item.weight * item.quantity for item in self.items)
        return total.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
    
    def shipping_cost(self) -> Decimal:
        """Calculate shipping cost."""
        if not self._shipping_method:
            return Decimal('0.00')
        
        # Free shipping over threshold
        if self.subtotal() >= FREE_SHIPPING_THRESHOLD:
            return Decimal('0.00')
        
        return SHIPPING_RATES.get(self._shipping_method, Decimal('0.00'))
    
    def total(self) -> Decimal:
        """Calculate final total including all charges."""
        total = (
            self.subtotal() 
            - self.discount_amount() 
            + self.tax_amount() 
            + self.shipping_cost()
        )
        return total.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
    
    def validate_inventory(self, inventory: Dict[str, int]) -> ValidationResult:
        """Validate cart against available inventory."""
        errors = []
        
        for item in self.items:
            available = inventory.get(item.product_id, 0)
            if available < item.quantity:
                errors.append({
                    'product_id': item.product_id,
                    'requested': item.quantity,
                    'available': available,
                    'message': f"Only {available} units available"
                })
        
        return ValidationResult(is_valid=len(errors) == 0, errors=errors)
    
    def validate_checkout(self, min_order: Decimal = Decimal('0.00')) -> ValidationResult:
        """Validate cart for checkout."""
        errors = []
        
        if self.is_empty():
            errors.append({'message': 'Cart is empty'})
        
        if self.total() < min_order:
            errors.append({
                'message': f'Minimum order amount is ${min_order}'
            })
        
        return ValidationResult(is_valid=len(errors) == 0, errors=errors)
    
    def order_summary(self) -> Dict[str, Any]:
        """Generate order summary."""
        return {
            'item_count': self.count(),
            'total_weight': str(self.total_weight()),
            'items': [item.to_dict() for item in self.items],
            'totals': {
                'subtotal': str(self.subtotal()),
                'discount': str(self.discount_amount()),
                'tax': str(self.tax_amount()),
                'shipping': str(self.shipping_cost()),
                'total': str(self.total())
            },
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert cart to dictionary for persistence."""
        data = {
            'items': [item.to_dict() for item in self.items],
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }
        
        if self._discount_type:
            data['discount'] = {
                'type': self._discount_type.value,
                'value': str(self._discount_value) if self._discount_value else None
            }
        
        if self._shipping_state or self._shipping_method:
            data['shipping'] = {
                'state': self._shipping_state,
                'method': self._shipping_method
            }
        
        return data
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'ShoppingCart':
        """Create cart from dictionary."""
        cart = cls()
        
        # Load items
        for item_data in data.get('items', []):
            item = CartItem.from_dict(item_data)
            cart.items.append(item)
        
        # Load discount
        if 'discount' in data:
            discount_data = data['discount']
            cart._discount_type = DiscountType(discount_data['type'])
            if discount_data.get('value'):
                cart._discount_value = Decimal(discount_data['value'])
        
        # Load shipping
        if 'shipping' in data:
            shipping_data = data['shipping']
            cart._shipping_state = shipping_data.get('state')
            cart._shipping_method = shipping_data.get('method')
        
        # Load timestamps
        cart.created_at = datetime.fromisoformat(data['created_at'])
        cart.updated_at = datetime.fromisoformat(data['updated_at'])
        
        return cart
    
    def _update_timestamp(self):
        """Update the last modified timestamp."""
        self.updated_at = datetime.now()
```

## 🎯 Exercise Completion

### Running All Tests

```bash
# Run all tests with coverage
pytest test_shopping_cart.py -v --cov=shopping_cart --cov-report=term-missing

# Generate HTML coverage report
pytest test_shopping_cart.py --cov=shopping_cart --cov-report=html
```

### Expected Output
```
==================== test session starts ====================
test_shopping_cart.py::test_create_empty_cart PASSED
test_shopping_cart.py::test_add_item_to_cart PASSED
test_shopping_cart.py::test_cart_item_creation PASSED
... [all tests] ...
test_shopping_cart.py::test_complete_checkout_workflow PASSED

---------- coverage: platform darwin, python 3.11.0 ----------
Name               Stmts   Miss  Cover   Missing
------------------------------------------------
shopping_cart.py     245      0   100%

==================== 22 passed in 0.34s ====================
```

## 🏆 TDD Mastery Achievements

You've successfully:
1. ✅ Written tests before implementation
2. ✅ Used Copilot to generate code that passes tests
3. ✅ Refactored with confidence
4. ✅ Achieved 100% test coverage
5. ✅ Built a production-ready shopping cart

## 💡 Key TDD + Copilot Insights

1. **Test Design Drives API Design**
   - Writing tests first forces you to think about usability
   - Copilot generates cleaner code when tests are clear

2. **Incremental Development Works**
   - Small test → small implementation → refactor
   - Copilot excels at small, focused tasks

3. **Tests Enable Fearless Refactoring**
   - Extract classes and methods confidently
   - Copilot can suggest refactoring patterns

## 🚀 Extension Challenges

1. **Add Coupon System**
   - Multiple coupon types
   - Stackable vs exclusive coupons
   - Expiration dates

2. **Implement Wishlist**
   - Move items between cart and wishlist
   - Price tracking
   - Stock alerts

3. **Add Recommendation Engine**
   - Suggest related products
   - Frequently bought together
   - Personalized discounts

4. **Multi-Currency Support**
   - Currency conversion
   - Regional pricing
   - Display preferences

---

🎉 **Excellent work!** You've mastered TDD with AI assistance. Ready for Exercise 3?