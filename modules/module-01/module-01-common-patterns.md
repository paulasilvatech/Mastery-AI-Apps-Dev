# Common AI-Powered Development Patterns

## 🎯 Overview

This guide contains common patterns and idioms that work exceptionally well with GitHub Copilot. These patterns help you write code that Copilot understands and can extend effectively.

## 🏗️ Structural Patterns

### 1. Comment-Driven Development (CDD)

**Pattern**: Write detailed comments before code, let Copilot implement.

```python
class UserService:
    def __init__(self, db_connection):
        self.db = db_connection
    
    # Get a user by ID from the database
    # - Check if ID is valid (positive integer)
    # - Query database for user with given ID
    # - Return User object if found, None otherwise
    # - Log any database errors but don't raise
    # - Cache result for 5 minutes
    def get_user_by_id(self, user_id: int) -> Optional[User]:
        # Copilot will implement based on comments
```

### 2. Type-First Development

**Pattern**: Define types and interfaces first, implementation follows.

```python
from typing import Protocol, List, Dict, Optional
from dataclasses import dataclass
from datetime import datetime

# Define data structures first
@dataclass
class Transaction:
    id: str
    amount: float
    date: datetime
    category: str
    description: Optional[str] = None

# Define interface
class TransactionRepository(Protocol):
    def save(self, transaction: Transaction) -> None: ...
    def get_by_id(self, transaction_id: str) -> Optional[Transaction]: ...
    def get_by_date_range(self, start: datetime, end: datetime) -> List[Transaction]: ...
    def get_by_category(self, category: str) -> List[Transaction]: ...

# Now implement - Copilot knows exactly what's needed
class SQLiteTransactionRepository:
    # Copilot will implement all protocol methods
```

### 3. Example-Driven Patterns

**Pattern**: Provide input/output examples in comments.

```python
# Parse configuration string into dictionary
# Examples:
#   "host=localhost;port=8080;debug=true" -> {"host": "localhost", "port": 8080, "debug": True}
#   "name=app;version=1.0.0" -> {"name": "app", "version": "1.0.0"}
#   "key=value=with=equals" -> {"key": "value=with=equals"}
# Auto-convert numeric strings and boolean strings
def parse_config(config_string: str) -> Dict[str, Union[str, int, bool]]:
    # Copilot understands the pattern from examples
```

## 🔄 Behavioral Patterns

### 4. Guard Clause Pattern

**Pattern**: Start functions with validation, Copilot follows the pattern.

```python
def process_payment(amount: float, account: Account, recipient: str) -> PaymentResult:
    # Guard clauses first
    if amount <= 0:
        raise ValueError("Amount must be positive")
    
    if not account.is_active:
        raise AccountError("Account is not active")
    
    if not validate_recipient(recipient):
        raise ValueError("Invalid recipient")
    
    # Main logic - Copilot knows all inputs are valid
    # ... implementation
```

### 5. Builder Pattern with Fluent Interface

**Pattern**: Chain method calls for configuration.

```python
class QueryBuilder:
    def __init__(self):
        self._table = None
        self._conditions = []
        self._order_by = None
        self._limit = None
    
    def from_table(self, table: str) -> 'QueryBuilder':
        self._table = table
        return self
    
    def where(self, condition: str) -> 'QueryBuilder':
        self._conditions.append(condition)
        return self
    
    # Copilot will continue the pattern
    def order_by(self, column: str, desc: bool = False) -> 'QueryBuilder':
        # Copilot implements following the pattern
```

### 6. Strategy Pattern with Registration

**Pattern**: Register strategies dynamically.

```python
class PaymentProcessor:
    _strategies: Dict[str, PaymentStrategy] = {}
    
    @classmethod
    def register(cls, name: str, strategy: PaymentStrategy):
        cls._strategies[name] = strategy
    
    def process(self, method: str, amount: float) -> bool:
        if method not in self._strategies:
            raise ValueError(f"Unknown payment method: {method}")
        
        return self._strategies[method].process(amount)

# Register strategies
PaymentProcessor.register("credit_card", CreditCardStrategy())
PaymentProcessor.register("paypal", PayPalStrategy())
# Copilot will suggest more registrations
```

## 🧪 Testing Patterns

### 7. Parametrized Test Pattern

**Pattern**: Define test cases as data, Copilot generates test logic.

```python
import pytest

# Test data pattern that Copilot recognizes
test_cases = [
    # (input, expected_output, description)
    ("hello world", "Hello World", "basic title case"),
    ("the quick brown fox", "The Quick Brown Fox", "articles maintained"),
    ("", "", "empty string"),
    ("ALREADY UPPER", "Already Upper", "handles all caps"),
]

@pytest.mark.parametrize("input_text,expected,description", test_cases)
def test_title_case(input_text, expected, description):
    # Copilot will implement the test
```

### 8. Fixture Pattern

**Pattern**: Create reusable test fixtures.

```python
@pytest.fixture
def sample_user():
    """Create a sample user for testing."""
    return User(
        id="123",
        name="Test User",
        email="test@example.com",
        created_at=datetime.now()
    )

@pytest.fixture
def authenticated_client(sample_user):
    """Create an authenticated test client."""
    client = TestClient(app)
    # Copilot will implement authentication setup
    return client

# Copilot knows how to use these fixtures in tests
def test_get_user_profile(authenticated_client, sample_user):
    # Test implementation
```

## 🎨 Code Organization Patterns

### 9. Module Organization Pattern

**Pattern**: Consistent module structure.

```python
"""
Module: user_service.py
Purpose: Handle user-related business logic
"""

# Standard library imports
import logging
from datetime import datetime
from typing import List, Optional

# Third-party imports
import bcrypt
from sqlalchemy.orm import Session

# Local imports
from .models import User
from .exceptions import UserNotFoundError
from .validators import validate_email

# Module-level logger
logger = logging.getLogger(__name__)

# Constants
MAX_LOGIN_ATTEMPTS = 3
PASSWORD_MIN_LENGTH = 8

# Main implementation follows...
```

### 10. Error Handling Pattern

**Pattern**: Consistent error handling structure.

```python
class ServiceError(Exception):
    """Base exception for service layer."""
    pass

class ValidationError(ServiceError):
    """Raised when validation fails."""
    pass

class NotFoundError(ServiceError):
    """Raised when resource not found."""
    pass

class PermissionError(ServiceError):
    """Raised when user lacks permission."""
    pass

# Usage pattern Copilot learns
def get_resource(resource_id: str, user: User) -> Resource:
    try:
        resource = db.get(resource_id)
        if not resource:
            raise NotFoundError(f"Resource {resource_id} not found")
        
        if not user.can_access(resource):
            raise PermissionError("Access denied")
        
        return resource
        
    except DatabaseError as e:
        logger.error(f"Database error: {e}")
        raise ServiceError("Unable to retrieve resource") from e
```

## 🚀 Performance Patterns

### 11. Caching Pattern

**Pattern**: Consistent caching approach.

```python
from functools import lru_cache
from typing import Dict, Any
import time

class CacheManager:
    def __init__(self, ttl: int = 300):  # 5 minutes default
        self._cache: Dict[str, tuple[Any, float]] = {}
        self._ttl = ttl
    
    def get_or_compute(self, key: str, compute_func, *args, **kwargs):
        # Check cache first
        if key in self._cache:
            value, timestamp = self._cache[key]
            if time.time() - timestamp < self._ttl:
                return value
        
        # Compute and cache
        value = compute_func(*args, **kwargs)
        self._cache[key] = (value, time.time())
        return value
    
    # Copilot will suggest cache invalidation methods
```

### 12. Batch Processing Pattern

**Pattern**: Process items in configurable batches.

```python
from typing import List, Callable, TypeVar, Generator

T = TypeVar('T')
R = TypeVar('R')

def process_in_batches(
    items: List[T],
    batch_size: int,
    process_func: Callable[[List[T]], List[R]],
    progress_callback: Optional[Callable[[int, int], None]] = None
) -> Generator[R, None, None]:
    """Process items in batches with optional progress reporting."""
    total = len(items)
    
    for i in range(0, total, batch_size):
        batch = items[i:i + batch_size]
        results = process_func(batch)
        
        if progress_callback:
            progress_callback(i + len(batch), total)
        
        yield from results

# Usage pattern
def bulk_save_users(users: List[User]):
    def save_batch(batch: List[User]) -> List[User]:
        # Copilot implements batch saving
        pass
    
    return list(process_in_batches(users, 100, save_batch))
```

## 🔐 Security Patterns

### 13. Input Validation Pattern

**Pattern**: Centralized validation with clear rules.

```python
from typing import Any, Dict, List, Callable

class Validator:
    def __init__(self):
        self.rules: List[Callable[[Any], bool]] = []
        self.errors: List[str] = []
    
    def add_rule(self, rule: Callable[[Any], bool], error_message: str):
        def wrapped_rule(value):
            if not rule(value):
                self.errors.append(error_message)
                return False
            return True
        self.rules.append(wrapped_rule)
        return self
    
    def validate(self, value: Any) -> bool:
        self.errors = []
        return all(rule(value) for rule in self.rules)

# Usage pattern Copilot learns
def validate_password(password: str) -> tuple[bool, List[str]]:
    validator = Validator()
    validator.add_rule(lambda p: len(p) >= 8, "Password must be at least 8 characters")
    validator.add_rule(lambda p: any(c.isupper() for c in p), "Must contain uppercase letter")
    # Copilot will suggest more rules
```

### 14. Sanitization Pattern

**Pattern**: Clean user input consistently.

```python
import re
from typing import Optional

class InputSanitizer:
    @staticmethod
    def sanitize_string(value: str, max_length: Optional[int] = None) -> str:
        # Remove control characters
        value = re.sub(r'[\x00-\x1f\x7f-\x9f]', '', value)
        
        # Normalize whitespace
        value = ' '.join(value.split())
        
        # Enforce length limit
        if max_length:
            value = value[:max_length]
        
        return value.strip()
    
    @staticmethod
    def sanitize_filename(filename: str) -> str:
        # Copilot implements filename sanitization
        pass
    
    @staticmethod
    def sanitize_html(html: str) -> str:
        # Copilot implements HTML sanitization
        pass
```

## 🎯 Integration Patterns

### 15. Adapter Pattern

**Pattern**: Consistent interface for different implementations.

```python
from abc import ABC, abstractmethod

class StorageAdapter(ABC):
    @abstractmethod
    def save(self, key: str, data: bytes) -> None:
        pass
    
    @abstractmethod
    def load(self, key: str) -> Optional[bytes]:
        pass
    
    @abstractmethod
    def delete(self, key: str) -> bool:
        pass
    
    @abstractmethod
    def exists(self, key: str) -> bool:
        pass

class S3StorageAdapter(StorageAdapter):
    def __init__(self, bucket: str, client):
        self.bucket = bucket
        self.client = client
    
    # Copilot implements all abstract methods

class LocalStorageAdapter(StorageAdapter):
    def __init__(self, base_path: str):
        self.base_path = Path(base_path)
    
    # Copilot implements all abstract methods
```

## 💡 Best Practices for Pattern Usage

1. **Consistency is Key**
   - Use the same pattern throughout your codebase
   - Copilot learns and reinforces your patterns

2. **Start Simple**
   - Begin with basic implementation
   - Let Copilot suggest enhancements

3. **Document Intent**
   - Clear comments about why you chose a pattern
   - Copilot will maintain the intent

4. **Combine Patterns**
   - Mix and match patterns as needed
   - Copilot understands composite patterns

5. **Evolve Gradually**
   - Start with simple patterns
   - Refactor to more complex ones as needed

## 📚 Quick Reference

### When to Use Each Pattern:

| Pattern | Use When |
|---------|----------|
| Comment-Driven | Starting new features |
| Type-First | Building APIs or libraries |
| Example-Driven | Complex transformations |
| Guard Clause | Input validation needed |
| Builder | Complex object construction |
| Strategy | Multiple algorithms for same task |
| Parametrized Tests | Many similar test cases |
| Caching | Expensive computations |
| Batch Processing | Large data sets |
| Adapter | Multiple implementations |

---

🎯 **Remember**: These patterns are starting points. As you work with Copilot, you'll discover patterns that work best for your specific needs. The key is consistency - Copilot learns from your codebase and reinforces the patterns you establish.