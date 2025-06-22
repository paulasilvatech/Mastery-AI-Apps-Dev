# GitHub Copilot Prompt Templates & Patterns

## 🎯 Module 02 Specific Prompts

This guide provides battle-tested prompt templates that maximize GitHub Copilot's effectiveness for core features.

## 📋 Categories

### 1. Code Generation Prompts

#### Function Implementation
```python
# Create a function that [specific task] with the following requirements:
# - Input: [describe input with types]
# - Output: [describe output with type]
# - Constraints: [performance, validation, etc.]
# - Example: input -> output
def function_name(params):
    # Copilot will generate based on detailed context
```

**Real Example:**
```python
# Create a function that merges overlapping date ranges with the following requirements:
# - Input: List of tuples [(start_date, end_date), ...] 
# - Output: List of merged non-overlapping ranges
# - Constraints: Dates are datetime objects, ranges are sorted by start date
# - Example: [(1, 3), (2, 5), (7, 8)] -> [(1, 5), (7, 8)]
def merge_date_ranges(ranges: List[Tuple[datetime, datetime]]) -> List[Tuple[datetime, datetime]]:
    # Copilot generates efficient implementation
```

#### Class Design
```python
# Design a class for [purpose] that:
# - Manages [what it manages]
# - Provides [key operations]
# - Follows [pattern name] pattern
# - Thread-safe: [yes/no]
# - Example usage:
#   obj = ClassName()
#   obj.operation()
class ClassName:
    # Copilot creates comprehensive class
```

### 2. Refactoring Prompts

#### Extract Method
```python
# TODO: Extract this logic into a separate method called 'calculate_discount'
# The method should handle all discount rules and return the final price
# Original code below:
if customer.is_premium and total > 100:
    discount = 0.2
elif total > 50:
    discount = 0.1
else:
    discount = 0
final_price = total * (1 - discount)
# Copilot will extract and improve
```

#### Improve Error Handling
```python
# Improve error handling for this database operation:
# - Add specific exception types
# - Include retry logic for transient errors
# - Log errors appropriately
# - Return meaningful error messages
def get_user(user_id):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
    return cursor.fetchone()
# Copilot will add comprehensive error handling
```

### 3. Multi-File Context Prompts

#### Consistent Patterns
```python
# Following the pattern established in models/base.py,
# create a repository class for User that includes:
# - CRUD operations
# - Query builders
# - Transaction support
# - Same error handling pattern
class UserRepository:
    # Copilot follows patterns from other files
```

#### Cross-File Refactoring
```python
# Update this function to use the new DatabaseManager from database.py
# instead of direct connections
# Maintain the same interface but use connection pooling
def get_products():
    # Old implementation
    conn = sqlite3.connect('db.sqlite')
    # Copilot will refactor using context from database.py
```

### 4. Pattern Recognition Prompts

#### Similar Implementations
```python
# Create similar validation functions for:
# - validate_phone_number (format: +1-234-567-8900)
# - validate_postal_code (US and Canada)
# - validate_ssn (format: XXX-XX-XXXX)
# Follow the same pattern as this email validator:
def validate_email(email: str) -> Tuple[bool, Optional[str]]:
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    if re.match(pattern, email):
        return True, None
    return False, "Invalid email format"

# Copilot will create consistent validators
```

#### API Endpoints
```python
# Create CRUD endpoints for Product model similar to these User endpoints:
# Follow the same structure, error handling, and response format
@app.get("/users/{user_id}")
async def get_user(user_id: int) -> UserResponse:
    user = user_service.get_user(user_id)
    if not user:
        raise HTTPException(404, "User not found")
    return UserResponse.from_model(user)

# Now create for Product:
# Copilot generates consistent endpoints
```

### 5. Performance Optimization Prompts

#### Optimization Request
```python
# Optimize this function for performance:
# - Current: O(n²) time complexity
# - Target: O(n log n) or better
# - Handle large datasets (1M+ records)
# - Minimize memory usage
def find_duplicates(items):
    duplicates = []
    for i in range(len(items)):
        for j in range(i + 1, len(items)):
            if items[i] == items[j]:
                duplicates.append(items[i])
    return duplicates
# Copilot suggests optimized algorithm
```

#### Caching Implementation
```python
# Add caching to this expensive operation:
# - Use LRU cache with size limit of 1000
# - Cache timeout: 5 minutes
# - Cache key should include all parameters
# - Thread-safe implementation
def calculate_analytics(user_id: int, start_date: date, end_date: date) -> Dict:
    # Expensive database queries and calculations
    # Copilot adds sophisticated caching
```

### 6. Testing Prompts

#### Comprehensive Tests
```python
# Generate comprehensive tests for this function including:
# - Normal cases
# - Edge cases (empty, null, maximum values)
# - Error cases
# - Performance tests
# - Property-based tests
def process_payment(amount: Decimal, card_number: str, cvv: str) -> PaymentResult:
    # Implementation here
    pass

# Test class:
class TestProcessPayment:
    # Copilot generates thorough test suite
```

#### Mock Testing
```python
# Create tests using mocks for external dependencies:
# - Mock database calls
# - Mock API requests  
# - Mock file system operations
# - Verify mock interactions
def sync_data_with_external_service():
    data = fetch_from_database()
    response = send_to_api(data)
    save_to_file(response)
    return response

# Copilot creates sophisticated mock tests
```

### 7. Documentation Prompts

#### API Documentation
```python
# Generate comprehensive docstring following Google style:
# Include all parameters, return values, exceptions, and examples
def complex_calculation(data, options=None, *, validate=True, cache=False):
    # Implementation
    pass
# Copilot adds detailed documentation
```

#### Architecture Documentation
```python
# Document this class with:
# - Purpose and responsibilities
# - Design patterns used
# - Integration points
# - Usage examples
# - Performance considerations
class EventProcessor:
    # Copilot creates architectural documentation
```

## 🎯 Context Optimization Patterns

### Pattern 1: Progressive Context Building
```python
# Step 1: Define the interface
class PaymentProcessor(Protocol):
    def process(self, amount: Decimal) -> Result: ...
    def refund(self, transaction_id: str) -> Result: ...

# Step 2: Add concrete implementation
# Copilot now understands the expected interface
class StripePaymentProcessor:
    """Implements PaymentProcessor using Stripe API."""
    # Copilot follows the protocol
```

### Pattern 2: Example-Driven Development
```python
"""
Transform user data according to these rules:
- Names: "john doe" -> {"first": "John", "last": "Doe"}
- Emails: "JOHN@EXAMPLE.COM" -> "john@example.com"
- Phones: "1234567890" -> "+1 (123) 456-7890"
- Dates: "2024-01-15" -> datetime(2024, 1, 15)
"""
def transform_user_data(raw_data: Dict) -> User:
    # Copilot follows the examples
```

### Pattern 3: Constraint Specification
```python
# Build a rate limiter with these constraints:
# - Max 100 requests per minute per user
# - Sliding window algorithm
# - Redis backend for distributed systems
# - Graceful degradation if Redis unavailable
# - Return remaining quota in response
class RateLimiter:
    # Copilot implements with all constraints
```

## 💡 Advanced Techniques

### Custom Instructions Integration
```python
# Following project custom instructions:
# - Always use type hints (see .copilot/instructions.md)
# - Follow repository pattern
# - Include comprehensive error handling
# - Add performance metrics
class OrderService:
    # Copilot applies custom instructions
```

### Multi-Mode Usage
```python
# 1. Use Chat for design decisions
"Help me design a caching strategy for this service"

# 2. Use inline for implementation
def get_with_cache(key: str) -> Optional[Any]:
    # Copilot implements based on chat discussion

# 3. Use Edit for refactoring
# Select the code and ask to "add retry logic with exponential backoff"
```

## 📊 Effectiveness Metrics

Track these metrics to improve your prompting:
1. **First-attempt success rate**: How often is the first suggestion correct?
2. **Modification rate**: How much do you modify accepted suggestions?
3. **Context switches**: How often do you need to add context?
4. **Completion speed**: Time from prompt to acceptable code

## 🏆 Best Practices Summary

1. **Be Specific**: Vague prompts yield vague results
2. **Provide Examples**: Show input/output transformations
3. **State Constraints**: Performance, security, compatibility
4. **Use Type Information**: Always include type hints
5. **Reference Patterns**: Mention design patterns explicitly
6. **Progressive Refinement**: Build complex features incrementally

## 🚀 Quick Reference Card

```python
# Function: "Create a function that [task] with [constraints]"
# Class: "Design a class for [purpose] following [pattern]"
# Refactor: "Refactor this to [improvement] while maintaining [invariant]"
# Test: "Generate tests including [edge cases] and [error cases]"
# Optimize: "Optimize for [metric] with target [goal]"
# Document: "Document with [style] including [examples]"
```

---

**Pro Tip**: The best prompts read like clear requirements documents. If a human developer would need clarification, so will Copilot!