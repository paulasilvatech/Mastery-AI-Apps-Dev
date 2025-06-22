# Best Practices for AI-Powered Development

## 🎯 Overview

This guide contains production-ready patterns and best practices for using GitHub Copilot effectively in real-world development scenarios.

## 🏗️ Fundamental Principles

### 1. Context is Everything

**Principle**: The quality of AI suggestions directly correlates with the quality of context provided.

**Best Practices:**
```python
# ❌ Poor context
# Function to process data
def process():
    pass

# ✅ Rich context
# Process customer order data from CSV file
# - Validate order IDs are unique
# - Calculate total with tax (8.5%)
# - Handle missing fields gracefully
# - Return OrderSummary object with statistics
def process_customer_orders(csv_file_path: str) -> OrderSummary:
    pass
```

### 2. Iterative Refinement

**Principle**: Treat Copilot suggestions as a starting point, not the final solution.

**Workflow:**
1. Write initial prompt
2. Accept suggestion
3. Review and understand
4. Refine and improve
5. Add error handling
6. Optimize if needed

### 3. Type-Driven Development

**Principle**: Use type hints to guide Copilot toward correct implementations.

```python
# ✅ Clear types guide better suggestions
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime

@dataclass
class Transaction:
    id: str
    amount: float
    timestamp: datetime
    category: Optional[str] = None

def analyze_transactions(
    transactions: List[Transaction],
    start_date: datetime,
    end_date: datetime
) -> Dict[str, Tuple[int, float]]:
    """Analyze transactions by category within date range."""
    pass
```

## 📝 Prompt Engineering Patterns

### 1. The Specification Pattern

Structure your prompts like specifications:

```python
# Specification: Email Validator
# Requirements:
#   1. Check basic format (user@domain.ext)
#   2. Validate domain has at least one dot
#   3. No consecutive dots allowed
#   4. Local part allows letters, numbers, dots, hyphens, underscores
#   5. Case-insensitive comparison
# Returns: (is_valid: bool, error_message: str | None)
def validate_email_advanced(email: str) -> Tuple[bool, Optional[str]]:
```

### 2. The Example-Driven Pattern

Provide input/output examples:

```python
# Parse configuration string into dictionary
# Format: "key1=value1;key2=value2;key3=value3"
# Example input: "host=localhost;port=8080;debug=true"
# Example output: {"host": "localhost", "port": 8080, "debug": True}
# Note: Automatically convert numeric strings and boolean strings
def parse_config(config_string: str) -> Dict[str, Union[str, int, bool]]:
```

### 3. The Step-by-Step Pattern

Break complex tasks into steps:

```python
# Calculate the median of a list without using statistics module
# Steps:
#   1. Handle empty list case
#   2. Sort the list
#   3. Find middle index(es)
#   4. Return middle value for odd length
#   5. Return average of two middle values for even length
def calculate_median(numbers: List[float]) -> Optional[float]:
```

## 🛡️ Security Best Practices

### 1. Never Trust Generated Secrets

```python
# ❌ Never accept generated secrets/keys
# Generate API key for user
def generate_api_key():
    return "sk_live_abcd1234..."  # DON'T USE THIS!

# ✅ Use proper cryptographic libraries
import secrets
def generate_api_key():
    """Generate cryptographically secure API key."""
    return f"sk_live_{secrets.token_urlsafe(32)}"
```

### 2. Validate Generated Security Code

Always review security-critical suggestions:
- Authentication logic
- Authorization checks
- Cryptographic operations
- SQL queries (check for injection)
- File operations (check path traversal)

### 3. Input Validation Pattern

```python
# Secure file reading with validation
# - Prevent path traversal attacks
# - Validate file extensions
# - Limit file size
# - Sandbox to specific directory
import os
from pathlib import Path

def read_user_file(filename: str, allowed_dir: str = "./uploads") -> Optional[str]:
    """Safely read user-uploaded file with security checks."""
    # Copilot will include security validations
```

## 🚀 Performance Patterns

### 1. Optimization Hints

```python
# Find all prime numbers up to n
# Use Sieve of Eratosthenes algorithm for O(n log log n) performance
# Optimize: use bytearray for memory efficiency
# Return: list of primes
def find_primes_optimized(n: int) -> List[int]:
```

### 2. Caching Pattern

```python
# Fibonacci with memoization
# Use functools.lru_cache for automatic caching
# Handle negative inputs appropriately
from functools import lru_cache

@lru_cache(maxsize=None)
def fibonacci(n: int) -> int:
```

## 🧪 Testing Best Practices

### 1. Test Generation Pattern

```python
# After writing a function, immediately write tests:

def calculate_discount(price: float, discount_percent: float) -> float:
    """Calculate discounted price."""
    # Implementation here

# Generate comprehensive tests including:
# - Normal cases (10%, 25%, 50% discounts)
# - Edge cases (0%, 100% discount)
# - Invalid inputs (negative values, > 100%)
# - Type errors (None, strings)
# Use pytest.parametrize for multiple cases
def test_calculate_discount():
```

### 2. Test-Driven Prompting

Write test expectations first:

```python
# Tests I want to pass:
# parse_date("2023-01-15") -> datetime(2023, 1, 15)
# parse_date("01/15/2023") -> datetime(2023, 1, 15)
# parse_date("Jan 15, 2023") -> datetime(2023, 1, 15)
# parse_date("invalid") -> None
# Now create the function:
def parse_date(date_string: str) -> Optional[datetime]:
```

## 📚 Documentation Patterns

### 1. Docstring Generation

```python
# After function implementation, generate docstring:
def complex_function(data: List[Dict], config: Config) -> Result:
    # Implementation...
    
    # Add comprehensive docstring including:
    # - Brief one-line description
    # - Detailed explanation
    # - Args with types and descriptions
    # - Returns with type and description
    # - Raises with exceptions
    # - Examples with >>> notation
    """Generate docstring here"""
```

### 2. README Generation

Use Copilot to generate documentation:

```markdown
# Generate README.md for this module including:
# - Brief description
# - Installation instructions
# - Usage examples
# - API reference
# - Contributing guidelines
# - License information
```

## 🎨 Code Style Patterns

### 1. Consistent Naming

```python
# Follow Python naming conventions:
# - snake_case for functions and variables
# - PascalCase for classes
# - UPPER_SNAKE_CASE for constants
# - _private for internal use
# - __double_underscore for name mangling (rarely)

class DataProcessor:
    MAX_BATCH_SIZE = 1000
    
    def process_batch(self, items: List[Item]) -> ProcessResult:
        pass
    
    def _validate_item(self, item: Item) -> bool:
        pass
```

### 2. Error Handling Pattern

```python
# Robust error handling with specific exceptions
# - Use custom exceptions for domain errors
# - Provide helpful error messages
# - Log errors appropriately
# - Clean up resources in finally blocks

class ValidationError(Exception):
    """Domain-specific validation error."""
    pass

def process_payment(amount: float, card_number: str) -> PaymentResult:
    """Process payment with comprehensive error handling."""
    # Copilot will generate try/except/finally blocks
```

## 🔄 Refactoring Patterns

### 1. Extract Method

```python
# Before: Long function
def process_order(order_data):
    # 50+ lines of code doing multiple things
    
# Prompt for refactoring:
# Refactor process_order by extracting:
# - validate_order_data() for validation logic
# - calculate_totals() for price calculations
# - send_notifications() for email/SMS sending
# - update_inventory() for stock management
# Keep main function as coordinator
```

### 2. Simplify Conditionals

```python
# Refactor complex conditionals using:
# - Early returns (guard clauses)
# - Extract boolean methods
# - Use dictionary dispatch for multiple conditions
# Original: nested if/elif/else
# Target: clean, readable flow
```

## 🚫 Anti-Patterns to Avoid

### 1. Blind Acceptance

```python
# ❌ Don't accept without understanding
suggestion = copilot.generate()
code.append(suggestion)  # NO!

# ✅ Review, understand, then integrate
suggestion = copilot.generate()
if understand(suggestion) and is_correct(suggestion):
    code.append(improve(suggestion))
```

### 2. Over-Reliance

- Don't use Copilot for critical algorithms you don't understand
- Don't let it generate security-critical code without review
- Don't use it as a replacement for learning fundamentals

### 3. Context Pollution

```python
# ❌ Mixing concerns in one file confuses Copilot
# authentication.py
def hash_password(): pass
def calculate_tax(): pass  # Unrelated!
def send_email(): pass     # Unrelated!

# ✅ Keep files focused on single responsibility
# authentication.py
def hash_password(): pass
def verify_password(): pass
def generate_token(): pass
```

## 📊 Metrics and Measurement

### Track Your Copilot Usage

1. **Acceptance Rate**: What percentage of suggestions do you use?
2. **Modification Rate**: How often do you modify suggestions?
3. **Time Saved**: Measure development speed improvements
4. **Code Quality**: Track bugs, test coverage, complexity

### Continuous Improvement

1. **Weekly Review**: What patterns worked well?
2. **Prompt Library**: Save effective prompts
3. **Team Sharing**: Share discoveries with teammates
4. **Feedback Loop**: Report issues to GitHub

## 🎯 Production Checklist

Before deploying Copilot-assisted code:

- [ ] **Understood**: Do you understand every line?
- [ ] **Tested**: Is there comprehensive test coverage?
- [ ] **Reviewed**: Has someone else reviewed it?
- [ ] **Secure**: Have security implications been considered?
- [ ] **Performant**: Will it scale appropriately?
- [ ] **Documented**: Is it well-documented?
- [ ] **Maintainable**: Can others understand and modify it?

## 🌟 Golden Rules

1. **Copilot is your pair programmer, not your replacement**
2. **Quality > Quantity - Better to write less code you understand**
3. **Context is key - Invest time in good prompts**
4. **Always validate - Especially for security and performance**
5. **Keep learning - Copilot enhances skills, doesn't replace them**

---

Remember: AI-powered development is about augmentation, not automation. Use these patterns to become a more effective developer, not a dependent one.
