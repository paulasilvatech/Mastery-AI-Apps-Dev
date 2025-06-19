# Best Practices for AI-Powered Development 🎯

## Production-Ready Patterns with GitHub Copilot

After completing the exercises, you've discovered that AI-powered development is more than just accepting suggestions. This guide consolidates the best practices for using GitHub Copilot effectively in production environments.

## 🏗️ Architectural Best Practices

### 1. Design-First Approach

**Always start with clear architecture before coding:**

```python
"""
Module: User Authentication System
Architecture:
- Token-based authentication (JWT)
- Role-based access control (RBAC)
- Secure password hashing (bcrypt)
- Session management with Redis
- Rate limiting for API endpoints
"""
# After this clear description, Copilot will generate better code
```

### 2. Modular Design

**Structure your code for AI assistance:**

```python
# GOOD: Clear, focused modules
# auth/
#   ├── models.py      # User models
#   ├── validators.py  # Input validation
#   ├── handlers.py    # Business logic
#   └── utils.py       # Helper functions

# LESS EFFECTIVE: Everything in one file
# app.py  # 1000+ lines of mixed concerns
```

### 3. Interface-Driven Development

**Define interfaces first:**

```python
from abc import ABC, abstractmethod
from typing import Protocol

# Define the interface clearly
class UserRepository(Protocol):
    """Interface for user data operations"""
    
    def create_user(self, user_data: dict) -> User:
        """Create a new user in the database"""
        ...
    
    def get_user_by_email(self, email: str) -> Optional[User]:
        """Retrieve user by email address"""
        ...
    
    def update_user(self, user_id: str, updates: dict) -> User:
        """Update user information"""
        ...

# Copilot will now generate implementations that match this interface
```

## 💬 Prompt Engineering Excellence

### 1. The Context-Example-Constraint Pattern

```python
# Context: What you're building
# This function processes payment transactions for an e-commerce platform

# Example: Show the expected behavior
# Input: {"amount": 99.99, "currency": "USD", "card_token": "tok_123"}
# Output: {"status": "success", "transaction_id": "txn_456", "timestamp": "2024-01-15T10:30:00Z"}

# Constraints: Specify requirements
# - Must validate amount is positive
# - Support USD, EUR, GBP currencies only
# - Use Stripe API for processing
# - Include comprehensive error handling
# - Log all transactions for audit

def process_payment(payment_data: dict) -> dict:
    # Copilot will now generate code meeting all these requirements
```

### 2. Progressive Refinement

```python
# Step 1: Get the basic structure
# Create a function to validate email addresses

# Step 2: Add specific requirements
# The validator should check:
# - Valid format using regex
# - Domain exists (DNS check)
# - Not in disposable email list

# Step 3: Add edge cases
# Handle:
# - International domains
# - Subdomains
# - Special characters in local part
```

### 3. Type-Driven Development

```python
from typing import TypedDict, Literal, Union
from datetime import datetime

# Define precise types for better suggestions
class PaymentRequest(TypedDict):
    amount: float
    currency: Literal["USD", "EUR", "GBP"]
    card_token: str
    metadata: dict[str, str]

class PaymentResponse(TypedDict):
    status: Literal["success", "failed", "pending"]
    transaction_id: str
    timestamp: datetime
    error: Union[str, None]

# Now Copilot understands exactly what to generate
def process_payment(request: PaymentRequest) -> PaymentResponse:
    pass
```

## 🔒 Security Best Practices

### 1. Never Trust AI with Secrets

```python
# NEVER DO THIS
api_key = "sk-1234567890abcdef"  # Copilot might suggest real-looking keys

# ALWAYS DO THIS
import os
from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv("API_KEY")
if not api_key:
    raise ValueError("API_KEY environment variable not set")
```

### 2. Validate AI-Generated Security Code

```python
# When Copilot generates security-related code, always verify:

# 1. Password hashing uses appropriate algorithms
import bcrypt
password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt(rounds=12))

# 2. Input validation is comprehensive
def validate_user_input(data: str) -> str:
    # Check for SQL injection patterns
    # Validate length limits
    # Sanitize HTML/script tags
    # Verify character encoding
    pass

# 3. Authentication checks are properly implemented
def require_auth(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        # Verify token exists
        # Validate token signature
        # Check token expiration
        # Verify user permissions
        return func(*args, **kwargs)
    return wrapper
```

### 3. Security Checklist for AI Code

- [ ] No hardcoded credentials
- [ ] Proper input validation
- [ ] Secure random number generation
- [ ] Appropriate encryption methods
- [ ] Safe SQL query construction
- [ ] Protected against common vulnerabilities (XSS, CSRF, etc.)

## 🎨 Code Quality Patterns

### 1. Self-Documenting Code

```python
# Tell Copilot to generate documentation
# Create a well-documented function for calculating compound interest
# Include:
# - Comprehensive docstring
# - Parameter descriptions
# - Return value explanation
# - Usage examples
# - Edge cases

def calculate_compound_interest(
    principal: float,
    annual_rate: float,
    compounds_per_year: int,
    years: float
) -> float:
    """
    Calculate compound interest for an investment.
    
    Args:
        principal: Initial investment amount in dollars
        annual_rate: Annual interest rate as a decimal (e.g., 0.05 for 5%)
        compounds_per_year: Number of times interest compounds per year
        years: Investment period in years
    
    Returns:
        float: Final amount after compound interest
    
    Example:
        >>> calculate_compound_interest(1000, 0.05, 12, 3)
        1161.47
    
    Raises:
        ValueError: If any input is negative or compounds_per_year is 0
    """
    # Copilot will maintain this documentation standard
```

### 2. Error Handling Patterns

```python
# Comprehensive error handling pattern
from typing import Union, Optional
import logging

class PaymentError(Exception):
    """Base exception for payment processing"""
    pass

class InvalidAmountError(PaymentError):
    """Raised when payment amount is invalid"""
    pass

class PaymentGatewayError(PaymentError):
    """Raised when payment gateway fails"""
    pass

def safe_payment_process(amount: float) -> Union[dict, None]:
    """
    Process payment with comprehensive error handling.
    
    Tell Copilot to:
    - Validate inputs before processing
    - Handle specific exceptions explicitly
    - Log errors appropriately
    - Provide user-friendly error messages
    - Include retry logic for transient failures
    """
    try:
        # Validation
        if amount <= 0:
            raise InvalidAmountError(f"Invalid amount: {amount}")
        
        # Processing with retry logic
        max_retries = 3
        for attempt in range(max_retries):
            try:
                result = process_payment_api(amount)
                return result
            except PaymentGatewayError as e:
                if attempt == max_retries - 1:
                    logging.error(f"Payment failed after {max_retries} attempts: {e}")
                    raise
                logging.warning(f"Payment attempt {attempt + 1} failed, retrying...")
                
    except InvalidAmountError as e:
        logging.error(f"Invalid payment amount: {e}")
        return {"error": "Invalid payment amount", "user_message": "Please enter a valid amount"}
    except PaymentGatewayError as e:
        logging.error(f"Payment gateway error: {e}")
        return {"error": "Payment processing failed", "user_message": "Please try again later"}
    except Exception as e:
        logging.exception("Unexpected error in payment processing")
        return {"error": "Unknown error", "user_message": "An unexpected error occurred"}
```

### 3. Testing Patterns

```python
# Guide Copilot to generate comprehensive tests
# Test function: calculate_discount(price, discount_percentage)
# Generate tests for:
# - Normal cases (10%, 25%, 50% discounts)
# - Edge cases (0%, 100% discounts)
# - Invalid inputs (negative values, > 100%)
# - Type errors (string inputs)
# - Floating point precision

import pytest
from decimal import Decimal

class TestCalculateDiscount:
    """Comprehensive test suite for discount calculation"""
    
    @pytest.mark.parametrize("price,discount,expected", [
        (100, 10, 90),
        (100, 25, 75),
        (100, 50, 50),
        (99.99, 10, 89.99),
    ])
    def test_normal_discounts(self, price, discount, expected):
        """Test standard discount calculations"""
        assert calculate_discount(price, discount) == expected
    
    def test_edge_cases(self):
        """Test boundary conditions"""
        assert calculate_discount(100, 0) == 100
        assert calculate_discount(100, 100) == 0
    
    def test_invalid_inputs(self):
        """Test error handling for invalid inputs"""
        with pytest.raises(ValueError):
            calculate_discount(-100, 10)
        with pytest.raises(ValueError):
            calculate_discount(100, -10)
        with pytest.raises(ValueError):
            calculate_discount(100, 150)
```

## 🚀 Performance Optimization

### 1. Efficient Algorithm Selection

```python
# Tell Copilot about performance requirements
# Create a function to find common elements in two lists
# Requirements:
# - Must handle lists with 100,000+ elements efficiently
# - Optimize for speed over memory usage
# - Return results in sorted order

def find_common_elements_optimized(list1: list, list2: list) -> list:
    """
    Find common elements using set intersection for O(n) performance.
    
    Converting to sets provides O(1) average lookup time,
    making this much faster than nested loops O(n²).
    """
    # Copilot will suggest set-based solution
    return sorted(set(list1) & set(list2))
```

### 2. Caching Patterns

```python
from functools import lru_cache
import time

# Tell Copilot to implement caching
# Create a expensive computation function with caching
# - Cache up to 128 results
# - Include cache statistics
# - Add cache clearing capability

class DataProcessor:
    def __init__(self):
        self.cache_hits = 0
        self.cache_misses = 0
    
    @lru_cache(maxsize=128)
    def expensive_computation(self, data_id: str) -> dict:
        """
        Perform expensive data processing with caching.
        
        Caches up to 128 results to avoid repeated computation.
        """
        self.cache_misses += 1  # Only called on cache miss
        
        # Simulate expensive operation
        time.sleep(1)
        
        # Complex processing here
        result = {"id": data_id, "processed": True, "timestamp": time.time()}
        return result
    
    def get_cache_stats(self) -> dict:
        """Return cache performance statistics"""
        info = self.expensive_computation.cache_info()
        return {
            "hits": info.hits,
            "misses": info.misses,
            "size": info.currsize,
            "max_size": info.maxsize
        }
```

## 🔄 Refactoring with AI

### 1. Code Smell Detection

```python
# Ask Copilot to identify and fix code smells

# BEFORE: Code with multiple issues
def process_user_data(users):
    results = []
    for u in users:
        if u['age'] > 18:
            if u['status'] == 'active':
                if u['email'] != None:
                    # Complex nested logic
                    u['processed'] = True
                    results.append(u)
    return results

# AFTER: Refactored with Copilot's help
def is_valid_user(user: dict) -> bool:
    """Check if user meets processing criteria"""
    return (
        user.get('age', 0) > 18 and
        user.get('status') == 'active' and
        user.get('email') is not None
    )

def process_user_data(users: list[dict]) -> list[dict]:
    """Process users meeting validation criteria"""
    valid_users = [user for user in users if is_valid_user(user)]
    
    for user in valid_users:
        user['processed'] = True
    
    return valid_users
```

### 2. Pattern Implementation

```python
# Ask Copilot to implement design patterns

# Implement the Builder pattern for complex object creation
class EmailBuilder:
    """
    Builder pattern for constructing email messages.
    
    Usage:
        email = (EmailBuilder()
                .set_recipient("user@example.com")
                .set_subject("Welcome!")
                .set_body("Thanks for joining...")
                .add_attachment("file.pdf")
                .build())
    """
    def __init__(self):
        self.reset()
    
    def reset(self):
        self._email = {
            'recipient': None,
            'subject': None,
            'body': None,
            'attachments': [],
            'cc': [],
            'bcc': []
        }
        return self
    
    def set_recipient(self, recipient: str):
        self._email['recipient'] = recipient
        return self
    
    def set_subject(self, subject: str):
        self._email['subject'] = subject
        return self
    
    def set_body(self, body: str):
        self._email['body'] = body
        return self
    
    def add_attachment(self, filename: str):
        self._email['attachments'].append(filename)
        return self
    
    def build(self) -> dict:
        # Validate required fields
        if not self._email['recipient']:
            raise ValueError("Recipient is required")
        if not self._email['subject']:
            raise ValueError("Subject is required")
        
        return self._email.copy()
```

## 📊 Metrics and Monitoring

### 1. Performance Instrumentation

```python
import time
import functools
import logging

# Create a decorator for performance monitoring
def monitor_performance(func):
    """
    Decorator to monitor function performance.
    
    Logs execution time and handles errors gracefully.
    """
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        start_time = time.time()
        
        try:
            result = func(*args, **kwargs)
            execution_time = time.time() - start_time
            
            logging.info(
                f"{func.__name__} completed in {execution_time:.3f}s",
                extra={
                    "function": func.__name__,
                    "execution_time": execution_time,
                    "status": "success"
                }
            )
            
            return result
            
        except Exception as e:
            execution_time = time.time() - start_time
            
            logging.error(
                f"{func.__name__} failed after {execution_time:.3f}s: {str(e)}",
                extra={
                    "function": func.__name__,
                    "execution_time": execution_time,
                    "status": "error",
                    "error": str(e)
                }
            )
            raise
    
    return wrapper
```

## 🎯 Key Takeaways

### Do's ✅
1. **Write clear architectural comments** before implementation
2. **Use type hints** extensively for better suggestions
3. **Provide examples** in comments for complex logic
4. **Review all generated code** for security and correctness
5. **Break complex problems** into smaller, focused functions
6. **Test AI-generated code** thoroughly
7. **Document your intent** clearly for future maintainers

### Don'ts ❌
1. **Don't accept suggestions blindly** - always review
2. **Don't let AI generate security-critical code** without review
3. **Don't use vague comments** - be specific
4. **Don't ignore code smells** in AI suggestions
5. **Don't skip testing** because "AI wrote it"
6. **Don't put secrets** in code or comments
7. **Don't assume AI understands** your business logic

## 🚀 Moving Forward

You now have a solid foundation in AI-powered development. These best practices will serve you throughout the workshop and in your professional development. Remember:

> **GitHub Copilot is a powerful tool, but you are the architect, the reviewer, and the guardian of code quality.**

Ready for Module 2? You'll dive deeper into advanced Copilot features and learn to leverage its full potential!