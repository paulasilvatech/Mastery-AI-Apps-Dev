# Prompt Templates for AI-Assisted Testing & Debugging

## 🧪 Test Generation Prompts

### Basic Test Generation

```python
# Generate comprehensive unit tests for this function
# Include:
# - Normal cases with typical inputs
# - Edge cases (empty, None, boundaries)
# - Error cases that should raise exceptions
# - Performance test if applicable
def calculate_discount(price, discount_percent, customer_type="regular"):
    """Calculate discount based on customer type and percentage."""
    # Implementation here
```

### Parameterized Test Generation

```python
# Generate parameterized tests using pytest.mark.parametrize
# Test all combinations of:
# - Valid and invalid inputs
# - Boundary values
# - Special cases
# Include descriptive test IDs for each case
def validate_password(password):
    """Validate password meets security requirements."""
    # Min 8 chars, 1 upper, 1 lower, 1 digit, 1 special
```

### Mock-Based Test Generation

```python
# Generate tests that mock external dependencies
# Mock:
# - Database calls (use Mock or MagicMock)
# - API requests (patch requests library)
# - File system operations
# - Time/datetime operations
# Verify all mock interactions
class EmailService:
    def send_welcome_email(self, user_id):
        # Gets user from DB, sends via SMTP
```

### Integration Test Generation

```python
# Generate integration tests for this Flask/FastAPI endpoint
# Test:
# - All HTTP methods (GET, POST, PUT, DELETE)
# - Success responses with correct status codes
# - Error responses (400, 404, 500)
# - Authentication/authorization
# - Request validation
@app.route('/api/users/<int:user_id>', methods=['GET', 'PUT', 'DELETE'])
def user_endpoint(user_id):
    # Endpoint implementation
```

## 🐛 Debugging Prompts

### Error Analysis

```python
# I'm getting this error:
# TypeError: unsupported operand type(s) for +: 'NoneType' and 'int'
# Stack trace: [paste full traceback]
# 
# This happens when calling this function:
def calculate_total(items):
    total = 0
    for item in items:
        total += item.price  # Error occurs here
    return total
#
# Fix the function to handle None values gracefully
```

### Performance Debugging

```python
# This function is slow when processing large datasets (>10000 items)
# Profile and optimize for better performance
# Consider:
# - Algorithm complexity
# - Unnecessary loops
# - Memory usage
# - Caching opportunities
def find_duplicates(data_list):
    duplicates = []
    for i, item in enumerate(data_list):
        for j, other in enumerate(data_list[i+1:], i+1):
            if item == other and item not in duplicates:
                duplicates.append(item)
    return duplicates
```

### Memory Leak Detection

```python
# This class seems to have a memory leak
# Analyze and fix any circular references or resource leaks
# Add proper cleanup methods
class DataProcessor:
    def __init__(self):
        self.cache = {}
        self.handlers = []
        
    def process(self, data):
        # Processing logic that might leak
```

### Race Condition Debugging

```python
# This code has race condition issues when used concurrently
# Add proper synchronization using threading.Lock or asyncio.Lock
# Ensure thread/async safety
class Counter:
    def __init__(self):
        self.count = 0
    
    def increment(self):
        temp = self.count
        # Simulate some processing
        self.count = temp + 1
```

## 🔄 TDD Prompts

### Test-First Development

```python
# Using TDD, help me implement a BankAccount class
# Start with these test cases:
# 1. Create account with initial balance
# 2. Deposit increases balance
# 3. Withdraw decreases balance
# 4. Cannot withdraw more than balance
# 5. Cannot deposit/withdraw negative amounts
# 6. Track transaction history
# 
# First, generate the tests, then implement the minimal code to pass
```

### Red-Green-Refactor Cycle

```python
# I have this failing test:
def test_shopping_cart_apply_discount():
    cart = ShoppingCart()
    cart.add_item("laptop", 1000, 1)
    cart.apply_percentage_discount(10)
    assert cart.total() == 900
    
# The test fails with: AttributeError: 'ShoppingCart' object has no attribute 'apply_percentage_discount'
# 
# Implement the minimal code to make this test pass
```

### Refactoring with Tests

```python
# These tests are passing but the code is messy
# Refactor the implementation while keeping tests green
# Improve:
# - Code organization
# - Variable names
# - Remove duplication
# - Add type hints
def test_data_processor():
    dp = DataProcessor()
    assert dp.process([1,2,3]) == [2,4,6]
    assert dp.process([]) == []
    assert dp.process([-1,0,1]) == [-2,0,2]

# Current messy implementation:
def process(d):
    r = []
    for x in d:
        r.append(x*2)
    return r
```

## 📊 Coverage Improvement Prompts

### Identify Missing Tests

```python
# This function has 60% test coverage
# Analyze and generate tests for the uncovered branches
# Coverage report shows lines 8-10, 15, and 22-25 are not covered
def process_order(order):
    if order.status == 'pending':
        if order.payment_verified:
            order.status = 'processing'
        else:
            # Lines 8-10 not covered
            order.status = 'payment_failed'
            send_payment_failure_notification(order)
            return None
    
    if order.items:
        for item in order.items:
            if not check_inventory(item):  # Line 15 not covered
                order.status = 'out_of_stock'
                break
    else:
        # Lines 22-25 not covered
        order.status = 'empty'
        log_empty_order(order)
        return None
        
    return order
```

### Edge Case Generation

```python
# Generate edge case tests for this function
# Consider:
# - Boundary values
# - Type variations
# - Null/None/empty inputs
# - Extreme values
# - Unicode/special characters
# - Concurrent access
def merge_sorted_lists(list1, list2):
    """Merge two sorted lists into one sorted list."""
    # Implementation
```

### Branch Coverage

```python
# Improve branch coverage for this function
# Currently: 70% line coverage, 40% branch coverage
# Generate tests that cover all conditional branches
def calculate_shipping_cost(weight, distance, express=False, insurance=False):
    base_cost = 5.0
    
    if weight > 50:
        base_cost += 10
    elif weight > 20:
        base_cost += 5
    
    if distance > 1000:
        base_cost *= 2
    elif distance > 500:
        base_cost *= 1.5
        
    if express:
        base_cost *= 1.5
        
    if insurance:
        base_cost += max(10, base_cost * 0.1)
        
    return round(base_cost, 2)
```

## 🔍 Complex Debugging Scenarios

### Multi-threading Issues

```python
# This multi-threaded code produces inconsistent results
# Debug and fix thread safety issues
# Add proper synchronization
import threading

class SharedCounter:
    def __init__(self):
        self.count = 0
        
    def increment_many(self, n):
        for _ in range(n):
            self.count += 1

# Test shows count is sometimes less than expected
def test_concurrent_increments():
    counter = SharedCounter()
    threads = []
    
    for _ in range(10):
        t = threading.Thread(target=counter.increment_many, args=(1000,))
        threads.append(t)
        t.start()
    
    for t in threads:
        t.join()
        
    assert counter.count == 10000  # Often fails!
```

### Async/Await Debugging

```python
# This async code hangs or times out
# Debug the issue and fix the async flow
# Ensure proper error handling
async def fetch_user_data(user_ids):
    results = {}
    
    async def fetch_one(user_id):
        response = await http_client.get(f"/users/{user_id}")
        return response.json()
    
    # This seems to hang with many users
    for user_id in user_ids:
        results[user_id] = await fetch_one(user_id)
        
    return results
```

### Database Transaction Issues

```python
# This code sometimes fails with database integrity errors
# Debug transaction handling and add proper rollback
# Ensure ACID properties
def transfer_funds(from_account_id, to_account_id, amount):
    from_account = Account.query.get(from_account_id)
    to_account = Account.query.get(to_account_id)
    
    from_account.balance -= amount
    to_account.balance += amount
    
    db.session.commit()  # Sometimes fails here
    
    # Send notifications
    notify_transfer(from_account, to_account, amount)
```

## 🎯 Test Quality Prompts

### Improve Test Readability

```python
# Refactor these tests to be more readable and maintainable
# Use:
# - Descriptive test names
# - Clear arrange-act-assert structure  
# - Helper functions for setup
# - Better assertions with messages
def test_1():
    u = User("j", "j@e.c", "p")
    assert u.email == "j@e.c"
    
def test_2():
    u = User("j", "bad", "p")
    try:
        u.validate()
        assert False
    except:
        assert True
```

### Test Documentation

```python
# Add comprehensive docstrings to these tests
# Include:
# - What is being tested
# - Why it's important
# - Expected behavior
# - Any special setup/teardown
class TestPaymentProcessor:
    def test_successful_payment(self):
        # test code
        
    def test_declined_card(self):
        # test code
```

### Test Data Builders

```python
# Create test data builder pattern for these tests
# Reduce duplication and improve maintainability
# Use builder pattern or factory functions
def test_order_processing():
    order = Order(
        id=1,
        customer_id=123,
        items=[
            OrderItem(product_id=1, quantity=2, price=10.99),
            OrderItem(product_id=2, quantity=1, price=25.50)
        ],
        shipping_address="123 Main St",
        billing_address="123 Main St",
        payment_method="credit_card"
    )
    # More tests with similar setup...
```

## 💡 Meta-Prompts for Testing

### Generate Test Strategy

```
For this application/module:
[Describe your application]

Generate a comprehensive test strategy including:
1. Types of tests needed (unit, integration, e2e)
2. Key areas to focus testing on
3. Test data requirements
4. Mocking strategy
5. Coverage goals
6. Performance testing needs
7. Security testing considerations
```

### Review Test Suite

```
Review this test suite and suggest improvements:
[Paste your test file]

Consider:
1. Coverage gaps
2. Test quality and assertions
3. Performance of tests
4. Maintainability
5. Missing edge cases
6. Better organization
```

### Debug Test Failures

```
This test is flaky (sometimes passes, sometimes fails):
[Paste the test]

Common failure: [Paste error message]

Help me:
1. Identify why it's flaky
2. Make it deterministic
3. Improve reliability
4. Add better error messages
```

---

## 🚀 Pro Tips

1. **Be Specific**: The more context you provide, the better Copilot's suggestions
2. **Iterate**: Start with basic tests, then ask for edge cases
3. **Combine Prompts**: Use multiple prompts to build comprehensive test suites
4. **Review Generated Code**: Always review and understand AI-generated tests
5. **Learn Patterns**: Use these templates as starting points, adapt to your needs

Remember: AI is your testing assistant, not a replacement for testing knowledge!