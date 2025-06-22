# GitHub Copilot Prompt Templates

## 🎯 Overview

This guide contains proven prompt templates that consistently generate high-quality code with GitHub Copilot. Use these as starting points and adapt them to your specific needs.

## 📝 Function Generation Templates

### Basic Function Template
```python
# Create a function that [action] [target] with:
# - [Requirement 1]
# - [Requirement 2]
# - [Error handling for: specific cases]
# Return: [expected output type and format]
# Example: [input] -> [output]
```

**Example Usage:**
```python
# Create a function that validates credit card numbers with:
# - Support for Visa, MasterCard, Amex
# - Luhn algorithm validation
# - Error handling for: invalid format, wrong length
# Return: tuple (is_valid: bool, card_type: str)
# Example: "4111111111111111" -> (True, "Visa")
```

### Class Generation Template
```python
# Create a [ClassName] class that:
# - [Primary responsibility]
# - Properties: [list key properties with types]
# - Methods: [list key methods with purpose]
# - Implements: [interfaces/protocols if any]
# - Inheritance: [parent class if any]
# Include: validation, error handling, documentation
```

**Example Usage:**
```python
# Create a BankAccount class that:
# - Manages account balance and transactions
# - Properties: account_number (str), balance (float), owner (str), transactions (list)
# - Methods: deposit(amount), withdraw(amount), get_statement(), transfer_to(account, amount)
# - Implements: JSON serialization
# - Inheritance: none
# Include: validation, error handling, documentation
```

## 🏗️ Architecture Templates

### API Endpoint Template
```python
# Create a [METHOD] endpoint at [PATH] that:
# - Accepts: [input format and parameters]
# - Validates: [validation requirements]
# - Processes: [business logic description]
# - Returns: [response format]
# - Status codes: [list expected status codes and conditions]
# - Error handling: [specific error scenarios]
# Include: authentication check, logging, rate limiting
```

### Database Model Template
```python
# Create a [ModelName] database model with:
# - Fields: [field_name: type, constraints] for each field
# - Relationships: [describe any foreign keys or associations]
# - Indexes: [list fields that need indexing]
# - Validations: [business rules]
# - Methods: [instance and class methods needed]
# Use: [SQLAlchemy/Django ORM/etc.]
```

## 🧪 Testing Templates

### Unit Test Template
```python
# Create comprehensive unit tests for [function/class] that:
# - Test normal cases: [list scenarios]
# - Test edge cases: [list edge cases]
# - Test error conditions: [list error scenarios]
# - Use: pytest with parametrize for multiple test cases
# - Include: setup/teardown if needed
# - Mock: [external dependencies to mock]
```

### Integration Test Template
```python
# Create integration tests for [feature/flow] that:
# - Setup: [required test data and state]
# - Test flow: [step-by-step user journey]
# - Assertions: [expected outcomes at each step]
# - Cleanup: [restore original state]
# - Coverage: [specific scenarios to cover]
```

## 🔧 Refactoring Templates

### Code Improvement Template
```python
# Refactor this code to:
# - Improve: [performance/readability/maintainability]
# - Apply pattern: [design pattern if applicable]
# - Maintain: [what should stay the same]
# - Add: [new requirements if any]
# Keep the same interface but improve implementation
```

### Extract Method Template
```python
# Extract the [description] logic into a separate method:
# - Method name: [suggested name]
# - Parameters: [what it needs]
# - Return: [what it should return]
# - Purpose: [why this extraction makes sense]
# Maintain current functionality while improving structure
```

## 📚 Documentation Templates

### Function Documentation Template
```python
# Add comprehensive docstring including:
# - Brief one-line description
# - Detailed explanation of purpose and behavior
# - Args: parameter names, types, and descriptions
# - Returns: type and description of return value
# - Raises: exceptions that might be raised
# - Examples: 2-3 usage examples with expected output
# Use: [Google/NumPy/Sphinx] style
```

### README Generation Template
```markdown
# Generate a comprehensive README.md that includes:
# - Project title and description
# - Key features (bullet points)
# - Installation instructions (step by step)
# - Usage examples (code blocks)
# - API reference (if applicable)
# - Configuration options
# - Contributing guidelines
# - License information
# Target audience: [developers/users/both]
```

## 🚀 Advanced Templates

### Async Function Template
```python
# Create an async function that [action] with:
# - Concurrent operations: [what runs in parallel]
# - Error handling: [how to handle failures]
# - Timeout: [timeout behavior]
# - Cancellation: [cleanup on cancellation]
# - Return: [expected result format]
# Use: asyncio with proper exception handling
```

### Design Pattern Template
```python
# Implement the [Pattern Name] pattern for [use case]:
# - Components: [list main components]
# - Responsibilities: [what each component does]
# - Interactions: [how components work together]
# - Benefits: [why this pattern fits]
# Include: proper abstraction, extensibility points
```

### Performance Optimization Template
```python
# Optimize this function for [metric: speed/memory/both]:
# - Current complexity: [time/space]
# - Target complexity: [desired time/space]
# - Constraints: [what must remain unchanged]
# - Trade-offs acceptable: [what can be sacrificed]
# Use: [specific techniques/algorithms if known]
```

## 💡 Prompt Optimization Tips

### 1. Be Specific About Types
```python
# ❌ Vague
# Create a function that processes data

# ✅ Specific
# Create a function that processes a list of dictionaries containing 
# user data (id: int, name: str, email: str) and returns 
# a dictionary mapping user IDs to email addresses
```

### 2. Include Examples
```python
# Process log entries and extract error information
# Input example: "2024-01-15 10:30:45 ERROR Database connection failed"
# Output example: {"timestamp": "2024-01-15 10:30:45", "level": "ERROR", "message": "Database connection failed"}
```

### 3. Specify Error Handling
```python
# Create a file parser that:
# - Handles missing files gracefully (return None)
# - Validates file format (raise ValueError for invalid format)
# - Manages large files efficiently (stream processing)
# - Logs warnings for recoverable issues
```

### 4. Chain Complex Tasks
```python
# Step 1: Create a data validator class
# Step 2: Add methods for each validation rule
# Step 3: Implement custom error messages
# Step 4: Add configuration support
# Step 5: Create comprehensive tests
```

## 🎯 Context-Specific Templates

### CLI Application
```python
# Create a CLI command that [action] with:
# - Arguments: [positional args with types]
# - Options: [--flag descriptions and defaults]
# - Help text: [user-friendly descriptions]
# - Output format: [human-readable/json/csv]
# - Error messages: [clear user guidance]
# Use: click/argparse with proper styling
```

### Web API
```python
# Create a REST endpoint that [action] with:
# - Route: [HTTP method and path]
# - Request body: [expected JSON schema]
# - Query parameters: [optional filters]
# - Response: [success and error formats]
# - Authentication: [required auth method]
# - Validation: [input validation rules]
# Use: FastAPI with Pydantic models
```

### Data Processing
```python
# Create a data pipeline that:
# - Input: [data source and format]
# - Transformations: [list of operations]
# - Validation: [data quality checks]
# - Output: [destination and format]
# - Error handling: [how to handle bad data]
# - Performance: [handle large datasets efficiently]
# Use: pandas/pure Python as appropriate
```

## 📊 Pattern Library

### Singleton Pattern
```python
# Implement a thread-safe singleton for [ClassName] that:
# - Ensures single instance across application
# - Lazy initialization
# - Thread-safe in multi-threaded environment
# - Allows configuration on first creation
```

### Factory Pattern
```python
# Create a factory for [ProductType] that:
# - Creates different types based on [criteria]
# - Supports registration of new types
# - Validates input parameters
# - Returns consistent interface
```

### Observer Pattern
```python
# Implement observer pattern for [SubjectClass] that:
# - Allows multiple observers to subscribe
# - Notifies on [specific events]
# - Supports priority-based notification
# - Handles observer errors gracefully
```

## 🔍 Debugging Templates

### Bug Fix Template
```python
# Fix the bug where [description of issue]:
# - Current behavior: [what happens now]
# - Expected behavior: [what should happen]
# - Root cause: [if known]
# - Maintain: [what should not change]
# Add tests to prevent regression
```

### Performance Fix Template
```python
# Improve performance of [operation] that currently:
# - Takes: [current time/resources]
# - Should take: [target time/resources]
# - Bottleneck: [identified slow part]
# - Approach: [suggested optimization strategy]
# Maintain correctness and add benchmarks
```

## 📈 Scaling Templates

### Concurrency Template
```python
# Make [operation] concurrent to:
# - Handle multiple [items] in parallel
# - Limit concurrency to [N] at a time
# - Aggregate results maintaining order
# - Handle partial failures gracefully
# Use: asyncio/threading/multiprocessing as appropriate
```

### Caching Template
```python
# Add caching to [function/method] that:
# - Caches based on: [key parameters]
# - TTL: [time to live]
# - Size limit: [max cache entries]
# - Invalidation: [when to clear cache]
# - Thread-safe: [if needed]
# Use: functools.lru_cache/redis/custom
```

---

## 🚀 Quick Reference Card

### Most Effective Prompt Starters:
1. "Create a function that..."
2. "Refactor this code to..."
3. "Add error handling for..."
4. "Generate tests that..."
5. "Implement the pattern..."
6. "Optimize this for..."
7. "Add documentation including..."
8. "Create a class that..."

### Key Phrases for Quality:
- "Include type hints and docstring"
- "Handle edge cases"
- "Follow PEP 8 style"
- "Make it production-ready"
- "Add comprehensive error handling"
- "Include usage examples"
- "Optimize for [metric]"
- "Make it thread-safe"

### Output Modifiers:
- "Keep it simple and readable"
- "Prioritize performance"
- "Focus on maintainability"
- "Make it extensible"
- "Follow SOLID principles"
- "Use functional approach"
- "Minimize dependencies"
- "Make it testable"

---

💡 **Remember**: The best prompts are specific, include context, and provide examples. Iterate on your prompts based on the output you receive, and save the ones that work well for future use!