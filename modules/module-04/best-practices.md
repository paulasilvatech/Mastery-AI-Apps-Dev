# Best Practices for AI-Assisted Testing and Debugging

## 🎯 Testing Best Practices with Copilot

### 1. Write Descriptive Test Names

**❌ Poor Test Names:**
```python
def test_1():
    pass

def test_function():
    pass

def test_error():
    pass
```

**✅ Good Test Names:**
```python
def test_create_user_with_valid_email_succeeds():
    pass

def test_create_user_with_duplicate_email_returns_409():
    pass

def test_withdraw_amount_exceeding_balance_raises_insufficient_funds_error():
    pass
```

**🤖 Copilot Tip:** Descriptive test names help Copilot generate better test implementations.

### 2. Follow the AAA Pattern

Always structure tests with **Arrange-Act-Assert**:

```python
def test_shopping_cart_applies_percentage_discount():
    # Arrange - Set up test data
    cart = ShoppingCart()
    cart.add_item("LAPTOP", "Gaming Laptop", Decimal("1000.00"))
    
    # Act - Execute the behavior
    cart.apply_discount(DiscountType.PERCENTAGE, Decimal("10"))
    
    # Assert - Verify the outcome
    assert cart.subtotal() == Decimal("1000.00")
    assert cart.discount_amount() == Decimal("100.00")
    assert cart.total() == Decimal("900.00")
```

### 3. Use Fixtures Effectively

**Create Reusable Test Data:**
```python
@pytest.fixture
def sample_user():
    """Provide a standard test user."""
    return User(
        username="testuser",
        email="test@example.com",
        role="standard"
    )

@pytest.fixture
def admin_user():
    """Provide an admin test user."""
    return User(
        username="admin",
        email="admin@example.com",
        role="admin"
    )

@pytest.fixture
def authenticated_client(client, sample_user):
    """Provide a client with authentication."""
    token = create_access_token(identity=sample_user.id)
    client.headers = {"Authorization": f"Bearer {token}"}
    return client
```

### 4. Test Edge Cases and Boundaries

```python
class TestPasswordValidation:
    """Test password validation edge cases."""
    
    @pytest.mark.parametrize("password,expected", [
        ("", False),                    # Empty
        ("a" * 7, False),              # Too short
        ("a" * 8, False),              # No variety
        ("abcd1234", False),           # No special chars
        ("Abcd123!", True),            # Valid
        ("A" * 128, False),            # Too long
        ("🔒Secure123!", True),        # Unicode
        (" Abcd123! ", False),         # Leading/trailing spaces
    ])
    def test_password_validation_edge_cases(self, password, expected):
        assert is_valid_password(password) == expected
```

## 🐛 Debugging Best Practices

### 1. Use Copilot for Error Analysis

When encountering an error, provide context:

```python
# Getting error: "TypeError: unsupported operand type(s) for +: 'Decimal' and 'float'"
# This happens when calculating tax on line 45
# Fix the type conversion to ensure all monetary values are Decimal
def calculate_total_with_tax(self, rate: float) -> Decimal:
```

### 2. Create Minimal Reproducible Examples

```python
# Minimal test case to reproduce the bug
def test_reproduce_decimal_error():
    """Reproduce the Decimal + float TypeError."""
    price = Decimal("10.00")
    tax_rate = 0.08  # This is a float
    
    # This will raise TypeError
    with pytest.raises(TypeError):
        total = price + price * tax_rate
    
    # Fixed version
    total = price + price * Decimal(str(tax_rate))
    assert total == Decimal("10.80")
```

### 3. Add Debug Logging

```python
import logging

def complex_calculation(data):
    """Add debug logging to trace issues."""
    logger = logging.getLogger(__name__)
    
    logger.debug(f"Input data: {data}")
    logger.debug(f"Data type: {type(data)}")
    
    try:
        # Step 1: Validate
        logger.debug("Validating input...")
        if not validate_data(data):
            logger.error(f"Validation failed for: {data}")
            raise ValueError("Invalid data")
        
        # Step 2: Process
        logger.debug("Processing data...")
        result = process_data(data)
        logger.debug(f"Processing result: {result}")
        
        # Step 3: Transform
        logger.debug("Transforming result...")
        final = transform_result(result)
        logger.debug(f"Final result: {final}")
        
        return final
        
    except Exception as e:
        logger.exception(f"Error in complex_calculation: {e}")
        raise
```

## 🔄 TDD Best Practices

### 1. Start with the Simplest Test

```python
# TDD Progression for a Calculator
# Step 1: Simplest possible test
def test_calculator_exists():
    calc = Calculator()
    assert calc is not None

# Step 2: Test basic operation
def test_add_two_numbers():
    calc = Calculator()
    assert calc.add(2, 3) == 5

# Step 3: Test edge cases
def test_add_negative_numbers():
    calc = Calculator()
    assert calc.add(-2, -3) == -5

# Step 4: Test error conditions
def test_add_non_numeric_raises_error():
    calc = Calculator()
    with pytest.raises(TypeError):
        calc.add("2", 3)
```

### 2. Write Just Enough Code to Pass

```python
# Test first
def test_fibonacci_sequence():
    assert fibonacci(0) == 0
    assert fibonacci(1) == 1
    assert fibonacci(5) == 5
    assert fibonacci(10) == 55

# Minimal implementation (ask Copilot)
def fibonacci(n):
    """Calculate nth Fibonacci number."""
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)

# Later optimize after tests pass
def fibonacci_optimized(n):
    """Optimized with memoization."""
    cache = {0: 0, 1: 1}
    
    def fib(n):
        if n not in cache:
            cache[n] = fib(n-1) + fib(n-2)
        return cache[n]
    
    return fib(n)
```

### 3. Refactor with Confidence

```python
# Original implementation (passes tests)
def calculate_discount(price, discount_percent):
    if discount_percent < 0 or discount_percent > 100:
        raise ValueError("Discount must be between 0 and 100")
    discount_amount = price * (discount_percent / 100)
    return price - discount_amount

# Refactored with better structure (tests ensure it still works)
class PriceCalculator:
    """Refactored version with better organization."""
    
    def __init__(self, tax_rate=0.08):
        self.tax_rate = Decimal(str(tax_rate))
    
    def apply_discount(self, price: Decimal, discount_percent: Decimal) -> Decimal:
        """Apply percentage discount with validation."""
        self._validate_discount(discount_percent)
        discount_amount = price * (discount_percent / Decimal("100"))
        return (price - discount_amount).quantize(Decimal("0.01"))
    
    def _validate_discount(self, discount_percent: Decimal):
        """Validate discount percentage."""
        if not 0 <= discount_percent <= 100:
            raise ValueError("Discount must be between 0 and 100")
```

## 🏗️ Test Organization Best Practices

### 1. Structure Test Files to Mirror Source

```
project/
├── src/
│   ├── models/
│   │   ├── user.py
│   │   └── product.py
│   ├── services/
│   │   ├── auth.py
│   │   └── payment.py
│   └── utils/
│       └── validators.py
└── tests/
    ├── models/
    │   ├── test_user.py
    │   └── test_product.py
    ├── services/
    │   ├── test_auth.py
    │   └── test_payment.py
    └── utils/
        └── test_validators.py
```

### 2. Group Related Tests

```python
class TestUserCreation:
    """Tests related to user creation."""
    
    def test_create_user_with_valid_data(self):
        pass
    
    def test_create_user_with_invalid_email(self):
        pass
    
    def test_create_user_with_duplicate_username(self):
        pass

class TestUserAuthentication:
    """Tests related to user authentication."""
    
    def test_login_with_valid_credentials(self):
        pass
    
    def test_login_with_invalid_password(self):
        pass
    
    def test_login_with_nonexistent_user(self):
        pass
```

### 3. Use Markers for Test Categories

```python
@pytest.mark.unit
def test_calculate_tax():
    """Fast unit test."""
    pass

@pytest.mark.integration
def test_database_connection():
    """Slower integration test."""
    pass

@pytest.mark.slow
@pytest.mark.external
def test_third_party_api():
    """Very slow external test."""
    pass

# Run only unit tests
# pytest -m unit

# Run all except slow tests
# pytest -m "not slow"
```

## 🛡️ Mock Best Practices

### 1. Mock at the Right Level

```python
# ❌ Don't mock too deep
@patch('requests.packages.urllib3.connectionpool.HTTPConnectionPool._make_request')
def test_api_call(mock_request):
    # Too low level!
    pass

# ✅ Mock at service boundaries
@patch('myapp.services.external_api.requests.get')
def test_api_call(mock_get):
    mock_get.return_value.json.return_value = {"status": "success"}
    result = fetch_user_data("123")
    assert result["status"] == "success"
```

### 2. Use Mock Specifications

```python
# Create mocks that match the interface
from unittest.mock import create_autospec

class PaymentGateway:
    def charge(self, amount, card_number):
        pass
    
    def refund(self, transaction_id):
        pass

# Create a mock that has the same interface
mock_gateway = create_autospec(PaymentGateway)

# This will raise AttributeError (good!)
# mock_gateway.invalid_method()
```

### 3. Verify Mock Interactions

```python
def test_order_processing():
    # Arrange
    mock_payment = Mock()
    mock_inventory = Mock()
    mock_email = Mock()
    
    order_service = OrderService(
        payment=mock_payment,
        inventory=mock_inventory,
        email=mock_email
    )
    
    # Act
    order_service.process_order(order_id="123", amount=99.99)
    
    # Assert - Verify all interactions
    mock_payment.charge.assert_called_once_with(99.99, ANY)
    mock_inventory.reserve_items.assert_called_once()
    mock_email.send_confirmation.assert_called_once()
    
    # Verify order of calls
    expected_calls = [
        call.reserve_items("123"),
        call.check_availability()
    ]
    assert mock_inventory.method_calls == expected_calls
```

## 📊 Coverage Best Practices

### 1. Aim for Meaningful Coverage

```python
# ❌ Coverage for coverage's sake
def test_getters_and_setters():
    user = User()
    user.name = "John"
    assert user.name == "John"  # Not meaningful

# ✅ Test behavior, not implementation
def test_user_full_name_formatting():
    user = User(first_name="John", last_name="Doe")
    assert user.full_name == "John Doe"
    
    user.middle_name = "Q"
    assert user.full_name == "John Q Doe"
```

### 2. Focus on Critical Paths

```python
# Identify and thoroughly test critical paths
class TestPaymentProcessing:
    """Critical path: Payment must never fail silently."""
    
    def test_successful_payment(self):
        # Happy path
        pass
    
    def test_insufficient_funds(self):
        # Expected failure
        pass
    
    def test_network_timeout(self):
        # Infrastructure failure
        pass
    
    def test_invalid_card(self):
        # Validation failure
        pass
    
    def test_payment_gateway_error(self):
        # External service failure
        pass
    
    def test_concurrent_payments(self):
        # Race condition handling
        pass
```

### 3. Exclude Generated Code

```python
# .coveragerc
[run]
omit = 
    */migrations/*
    */venv/*
    */tests/*
    */__pycache__/*
    */staticfiles/*
    setup.py

[report]
exclude_lines =
    # Don't complain about missing debug code:
    def __repr__
    if self\.debug
    
    # Don't complain if tests don't hit defensive assertion code:
    raise AssertionError
    raise NotImplementedError
    
    # Don't complain if non-runnable code isn't run:
    if 0:
    if __name__ == .__main__.:
    
    # Don't complain about type checking code:
    if TYPE_CHECKING:
```

## 🎨 Copilot Prompt Patterns for Testing

### 1. Test Generation Pattern

```python
# Generate comprehensive tests for this function
# Include:
# - Happy path test
# - Edge cases (empty input, None, max values)
# - Error cases (invalid types, out of range)
# - Performance test for large inputs
def process_data(items: List[dict]) -> dict:
    """Process items and return summary statistics."""
    # Implementation here
```

### 2. Debugging Pattern

```python
# Debug this failing test
# Error: AssertionError: 99.99 != 100.00
# The test expects exact decimal arithmetic
# Fix the implementation to handle Decimal properly
def test_calculate_total():
    cart = ShoppingCart()
    cart.add_item("item1", Decimal("33.33"))
    cart.add_item("item2", Decimal("33.33"))
    cart.add_item("item3", Decimal("33.33"))
    assert cart.total() == Decimal("99.99")
```

### 3. Refactoring Pattern

```python
# Refactor this test to:
# - Use fixtures for test data
# - Parametrize for multiple scenarios
# - Add better assertions with helpful messages
# - Follow AAA pattern clearly
def test_stuff():
    u = User("john", "john@example.com", "password123")
    u.save()
    u2 = User.get(u.id)
    assert u2.email == "john@example.com"
```

---

## 🚀 Summary

Remember these key principles:

1. **Test Behavior, Not Implementation** - Focus on what the code does, not how
2. **Keep Tests Simple and Focused** - One test, one concept
3. **Use Descriptive Names** - Tests are documentation
4. **Maintain Test Independence** - Tests shouldn't depend on each other
5. **Mock External Dependencies** - Keep tests fast and deterministic
6. **Refactor Tests Too** - Clean tests are as important as clean code

With Copilot as your testing assistant, you can achieve high-quality, comprehensive test coverage faster than ever before!