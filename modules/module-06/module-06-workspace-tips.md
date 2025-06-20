# Workspace Tips and Strategies for Multi-File Projects

## 🎯 Overview

This guide provides advanced tips and strategies for maximizing GitHub Copilot's effectiveness in multi-file projects.

## 🗂️ File Organization Strategies

### 1. The "Context Triangle" Pattern

When working on a feature, open files in this priority order:

```
        Current File (Focus)
              /    \
             /      \
     Dependencies   Tests
         /            \
        /              \
    Models          Configs
```

**Example for Service Development:**
1. `product_service.py` (current focus)
2. `product_repository.py` (direct dependency)
3. `test_product_service.py` (tests)
4. `product.py` (model)
5. `config.py` (configuration)

### 2. The "Layer Navigation" Pattern

Keep one file from each layer open:

```
API Layer:        products.py
Service Layer:    product_service.py
Repository:       product_repository.py
Model:           product.py
Schema:          product_schema.py
```

This helps Copilot understand the full stack.

## 🔍 Effective @workspace Queries

### Discovery Queries

```bash
# Find all entry points
@workspace find all files with if __name__ == "__main__"

# Locate configuration
@workspace where are environment variables loaded?

# Find all tests
@workspace list all files starting with test_ or ending with _test.py

# Discover patterns
@workspace show me all classes that inherit from BaseModel
```

### Analysis Queries

```bash
# Dependency analysis
@workspace which files import from models.product?

# Find TODOs
@workspace find all TODO comments

# Architecture check
@workspace show the inheritance hierarchy for service classes

# Security audit
@workspace find any hardcoded passwords or API keys
```

### Refactoring Queries

```bash
# Before renaming
@workspace find all references to UserManager class

# Import cleanup
@workspace find unused imports

# Pattern consistency
@workspace show all exception handling patterns

# API consistency
@workspace list all API endpoints and their HTTP methods
```

## 🎨 Context Optimization Techniques

### 1. Strategic Comments

Place these comments in key files to guide Copilot:

```python
# src/services/__init__.py
"""
Service Layer - Business Logic

All services should:
- Inherit from BaseService
- Use dependency injection
- Handle their own transactions
- Raise domain-specific exceptions
- Log all operations
"""
```

### 2. Type Hints as Documentation

```python
from typing import Protocol

class RepositoryProtocol(Protocol):
    """Protocol that all repositories must implement."""
    async def get(self, id: int) -> Model: ...
    async def create(self, data: dict) -> Model: ...
    async def update(self, id: int, data: dict) -> Model: ...
    async def delete(self, id: int) -> bool: ...
```

### 3. Example-Driven Development

```python
# In your test file, write the ideal API first
def test_ideal_usage():
    """This test shows how we want the API to work."""
    service = ProductService(mock_repo)
    product = service.create_product(
        name="Laptop",
        price=999.99,
        category="Electronics"
    )
    assert product.id is not None
```

## 🚀 Multi-File Editing Workflows

### Workflow 1: Top-Down Feature Development

1. **Start with the API endpoint**
   ```python
   @router.post("/products")
   async def create_product(product: ProductCreate):
       # Copilot will suggest service call
   ```

2. **Move to service layer**
   - Copilot knows what's needed from API

3. **Implement repository**
   - Context flows down naturally

### Workflow 2: Bottom-Up Refactoring

1. **Start with models**
   - Change data structure

2. **Update repositories**
   - Copilot suggests changes based on model

3. **Propagate to services and APIs**
   - Changes flow up naturally

### Workflow 3: Test-Driven Multi-File

1. **Write integration test first**
2. **Use Edit mode on all affected files**
3. **Let Copilot implement to pass tests**

## 🔧 Advanced Copilot Modes

### Chat Mode Strategies

**Information Gathering:**
```
@workspace summarize the authentication flow
@workspace what validation rules exist for products?
@workspace how is error handling implemented?
```

**Code Generation:**
```
@workspace create a new endpoint for bulk product upload 
following existing patterns
```

### Edit Mode Strategies

**Consistent Updates:**
1. Select all related files
2. Provide clear transformation rules
3. Review changes file by file

**Example:**
```
Selected files: All service files
Prompt: Add async context manager support to all service classes
for proper resource cleanup
```

### Agent Mode Strategies

**Complex Feature Development:**
```
Create a complete notification system with:
- Email and SMS providers
- Template management
- Async job processing
- Delivery tracking
- Following existing service patterns
```

## 📊 Context Window Management

### Signs of Context Overload

- Generic suggestions
- Ignoring project patterns
- Slow response times
- Incomplete operations

### Solutions

1. **Close unnecessary files**
2. **Use focused workspaces**
3. **Clear VS Code cache**
4. **Restart Copilot**

## 🎯 Pattern Recognition

### Help Copilot Learn Your Patterns

1. **Consistent naming:**
   ```python
   # Always use this pattern
   get_product()      # Single item
   list_products()    # Multiple items
   create_product()   # Create new
   update_product()   # Modify existing
   delete_product()   # Remove
   ```

2. **Consistent structure:**
   ```python
   class ServiceName:
       def __init__(self, dependencies):
           # Always inject dependencies
       
       async def operation(self):
           # Always async
           # Always log
           # Always handle errors
   ```

3. **Consistent imports:**
   ```python
   # Group imports consistently
   # 1. Standard library
   # 2. Third-party
   # 3. Local application
   ```

## 🔄 Incremental Development

### Building Features Incrementally

1. **Phase 1: Basic structure**
   - Create all files with stubs
   - Define interfaces

2. **Phase 2: Core functionality**
   - Implement happy path
   - Basic error handling

3. **Phase 3: Edge cases**
   - Add validation
   - Comprehensive errors

4. **Phase 4: Optimization**
   - Add caching
   - Performance improvements

## 💡 Pro Tips

### 1. Use Breadcrumbs

```python
# In complex files, add navigation comments
# === SECTION: User Authentication ===

# === SECTION: Data Validation ===

# === SECTION: Business Logic ===
```

### 2. Create Learning Examples

```python
# example_usage.py
"""
This file shows how to use our API.
Copilot will learn from these examples.
"""
```

### 3. Maintain a Patterns File

```python
# patterns.py
"""
Common patterns used in this project:
- Repository: See product_repository.py
- Service: See product_service.py
- API: See products.py
"""
```

## 🎮 Interactive Development

### Live Coding Sessions

1. **Open terminal in VS Code**
2. **Run tests in watch mode**
3. **Let Copilot see test output**
4. **It will suggest fixes**

### REPL-Driven Development

```python
# Use Python REPL to experiment
# Copilot can see REPL history
>>> from src.models.product import Product
>>> p = Product(name="Test")
# Copilot learns from your experiments
```

## 📈 Productivity Metrics

Track your multi-file efficiency:

1. **Time to implement feature**
2. **Number of manual corrections**
3. **Cross-file consistency**
4. **Test coverage achieved**

## 🎯 Challenge Exercises

### Challenge 1: Cross-File Refactoring
- Rename a core model
- Update all references
- Maintain functionality

### Challenge 2: Pattern Propagation
- Create new pattern in one file
- Apply to all similar files
- Ensure consistency

### Challenge 3: Architecture Evolution
- Add new layer to architecture
- Update all components
- Maintain backwards compatibility

---

**Remember:** The key to multi-file mastery is understanding how Copilot uses context. Organize thoughtfully, query strategically, and iterate continuously!