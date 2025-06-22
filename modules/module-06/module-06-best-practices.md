# Best Practices for Multi-File Projects and Workspaces

## 🎯 Overview

This guide presents production-ready patterns and best practices for managing multi-file projects with GitHub Copilot. These patterns have been tested in real-world applications and optimize both developer productivity and AI assistance effectiveness.

## 📁 Project Structure Best Practices

### 1. Consistent Organization Pattern

```
project-root/
├── src/                    # Source code
│   ├── api/               # API layer (controllers/routes)
│   ├── core/              # Core functionality (config, db)
│   ├── models/            # Data models
│   ├── services/          # Business logic
│   ├── repositories/      # Data access layer
│   └── utils/             # Shared utilities
├── tests/                 # Test files mirroring src structure
├── docs/                  # Documentation
├── scripts/               # Build and utility scripts
└── .github/               # GitHub-specific files
```

**Why this works with Copilot:**
- Predictable structure helps AI understand project layout
- Clear separation of concerns improves suggestions
- Mirrored test structure aids in test generation

### 2. Naming Conventions

```python
# Good: Clear, descriptive names
user_service.py
product_repository.py
order_controller.py

# Bad: Ambiguous names
service.py
handler.py
manager.py
```

**Copilot Benefits:**
- Better context understanding
- More accurate import suggestions
- Clearer cross-file references

## 🤖 Copilot Workspace Configuration

### 1. Project-Level Instructions

Create `.github/copilot-instructions.md`:

```markdown
# Project: E-Commerce Platform

## Architecture
- Layered architecture: API → Service → Repository → Model
- All business logic in service layer
- No direct database access from API layer

## Coding Standards
- Type hints for all function parameters and returns
- Comprehensive error handling with custom exceptions
- Async/await for all I/O operations
- Docstrings for all public methods

## Testing Requirements
- Minimum 80% code coverage
- Unit tests for all services
- Integration tests for all API endpoints
- Use pytest fixtures for test data

## Security
- Input validation on all endpoints
- SQL injection prevention via parameterized queries
- API authentication required for all endpoints except health
```

### 2. Workspace Settings

`.vscode/settings.json`:

```json
{
  "github.copilot.enable": {
    "*": true
  },
  "github.copilot.advanced": {
    "inlineSuggestCount": 3,
    "listCount": 10,
    "temperature": 0.3
  },
  "editor.tabSize": 4,
  "python.analysis.typeCheckingMode": "strict",
  "files.exclude": {
    "**/__pycache__": true,
    "**/*.pyc": true,
    ".pytest_cache": true
  }
}
```

## 🔄 Multi-File Navigation Patterns

### 1. Strategic File Opening

```python
# When working on a service, open these files:
1. The service file itself
2. Related model files
3. Repository it depends on
4. Test file for the service
5. Any shared utilities used

# This provides Copilot with full context
```

### 2. Using @workspace Effectively

```
Good queries:
@workspace find all API endpoints that use ProductService
@workspace show database models with foreign keys
@workspace list all files importing from utils.auth

Poor queries:
@workspace show me everything
@workspace find code
@workspace search files
```

### 3. Context Window Management

```python
# Pattern: Open files in order of relevance
1. Primary file you're editing
2. Direct dependencies
3. Related test files
4. Configuration files
5. Documentation

# Close unrelated files to reduce noise
```

## 🛠️ Development Workflow Patterns

### 1. Test-Driven Development with Copilot

```python
# Step 1: Write test first
def test_create_product_with_invalid_price():
    """Test that negative prices are rejected."""
    # Copilot will suggest implementation

# Step 2: In Copilot Chat
@workspace implement create_product to make this test pass

# Step 3: Refine implementation
# Let Copilot suggest edge cases
```

### 2. Cross-File Refactoring

```python
# Pattern: Use Edit mode for related changes

1. Select all affected files
2. Provide clear refactoring instructions
3. Review changes file by file
4. Use @workspace to verify completeness

Example:
"Rename all instances of 'Customer' to 'Client' in models, services, and APIs"
```

### 3. Architecture Validation

```python
# Regular checks using Copilot Chat:

@workspace verify no circular imports
@workspace ensure all services have corresponding tests
@workspace check that API endpoints follow REST conventions
@workspace find any direct database access in API layer
```

## 📝 Documentation Patterns

### 1. Self-Documenting Code Structure

```python
# services/order_service.py
class OrderService:
    """Handles all order-related business logic.
    
    This service coordinates between the order repository,
    inventory service, and payment service to process orders.
    """
    
    def __init__(
        self,
        order_repo: OrderRepository,
        inventory_service: InventoryService,
        payment_service: PaymentService
    ):
        # Copilot understands dependencies from type hints
```

### 2. Contextual Comments

```python
# Good: Explains why, not what
# Use optimistic locking to handle concurrent order updates
# This prevents overselling when multiple users buy the same item

# Bad: Redundant
# Create a new order
order = Order()
```

## 🔐 Security Best Practices

### 1. Input Validation Pattern

```python
# Create centralized validation
# validators/product_validator.py
class ProductValidator:
    @staticmethod
    def validate_create(data: dict) -> ProductCreate:
        # Copilot will suggest comprehensive validation
        # based on the ProductCreate schema
```

### 2. Error Handling Strategy

```python
# exceptions/business_exceptions.py
class BusinessException(Exception):
    """Base exception for business logic errors."""
    pass

class InsufficientInventoryError(BusinessException):
    """Raised when product stock is insufficient."""
    pass

# Copilot will use these consistently across files
```

## 🚀 Performance Optimization

### 1. Lazy Loading Pattern

```python
# repositories/base_repository.py
class BaseRepository:
    def get_with_relations(self, id: int, load_relations: List[str]):
        # Copilot understands the pattern and suggests
        # optimal query construction
```

### 2. Caching Strategy

```python
# decorators/cache.py
def cache_result(ttl: int = 300):
    """Cache function results for specified TTL."""
    # Use with services for expensive operations
```

## 🧪 Testing Patterns

### 1. Fixture Organization

```python
# tests/fixtures/product_fixtures.py
@pytest.fixture
def sample_product():
    """Standard product for testing."""
    # Copilot will reference this across test files

# tests/fixtures/user_fixtures.py
@pytest.fixture
def authenticated_user():
    """User with valid authentication token."""
    # Reusable across all auth-required tests
```

### 2. Test Naming Convention

```python
def test_[what]_[condition]_[expected_result]():
    """
    Examples:
    test_create_order_with_insufficient_stock_raises_error()
    test_update_product_with_valid_data_returns_updated_product()
    test_delete_user_as_admin_succeeds()
    """
```

## 💡 Copilot Mode Selection Guide

### When to Use Chat Mode
- Asking questions about codebase
- Understanding existing functionality
- Finding specific implementations
- Getting architecture overview

### When to Use Edit Mode
- Making consistent changes across files
- Refactoring with clear requirements
- Adding similar functionality to multiple files
- Updating imports or dependencies

### When to Use Agent Mode
- Creating new features from scratch
- Complex multi-file operations
- Generating comprehensive test suites
- Major architectural changes

## 📋 Code Review Checklist

Before committing multi-file changes:

- [ ] All imports are correct and used
- [ ] No circular dependencies introduced
- [ ] Tests updated for all changes
- [ ] Documentation reflects changes
- [ ] Type hints are complete
- [ ] Error handling is consistent
- [ ] Security validations in place
- [ ] Performance implications considered

## 🎯 Anti-Patterns to Avoid

1. **God Classes**: Avoid services that do everything
2. **Circular Dependencies**: Use dependency injection
3. **Mixed Concerns**: Keep layers separate
4. **Inconsistent Naming**: Follow conventions
5. **Missing Tests**: Always write tests
6. **Direct DB Access**: Use repository pattern
7. **Hardcoded Values**: Use configuration
8. **Poor Error Messages**: Be specific

## 🔍 Continuous Improvement

1. **Regular Architecture Reviews**
   ```
   @workspace generate an architecture diagram of the current system
   ```

2. **Code Quality Metrics**
   ```
   @workspace analyze code complexity and suggest improvements
   ```

3. **Performance Profiling**
   ```
   @workspace identify potential performance bottlenecks
   ```

## 📚 Resources

- [Python Project Structure](https://docs.python-guide.org/writing/structure/)
- [Clean Architecture Principles](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [GitHub Copilot Best Practices](https://docs.github.com/en/copilot/using-github-copilot/best-practices-for-using-github-copilot)

---

Remember: The goal is to create a codebase where both humans and AI can navigate efficiently. Good organization amplifies Copilot's effectiveness!