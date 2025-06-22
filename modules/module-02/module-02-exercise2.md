# Exercise 2: Multi-File Refactoring (⭐⭐ Medium)

## 🎯 Exercise Overview

In this exercise, you'll use GitHub Copilot's multi-file editing capabilities to refactor a small e-commerce application. You'll learn how Copilot understands context across multiple files and can help with systematic refactoring tasks.

### Duration
- **Estimated Time**: 45-60 minutes
- **Difficulty**: ⭐⭐ Medium
- **Success Rate**: 80%

### Learning Objectives
- Master multi-file context awareness
- Use Copilot for systematic refactoring
- Leverage workspace-wide suggestions
- Apply consistent patterns across files

## 📋 Exercise Structure

### Part 1: Code Analysis (15 minutes)
Analyze the existing codebase and identify refactoring opportunities using Copilot's help.

### Part 2: Multi-File Refactoring (25 minutes)
Perform systematic refactoring across multiple files with Copilot's assistance.

### Part 3: Testing and Validation (20 minutes)
Ensure refactoring maintains functionality and improves code quality.

## 🚀 Getting Started

### Setup
```bash
cd exercises/exercise2-medium
python -m venv venv
source venv/bin/activate  # On Windows: .\venv\Scripts\activate
pip install -r requirements.txt
```

### File Structure
```
exercise2-medium/
├── README.md                    # This file
├── requirements.txt
├── starter/                     # Original messy code
│   ├── app.py                  # Main application
│   ├── database.py             # Database operations
│   ├── models.py               # Data models
│   ├── utils.py                # Utility functions
│   └── config.py               # Configuration
├── solution/                   # Refactored version
└── tests/
    └── test_refactoring.py     # Validation tests
```

## 📝 Instructions

### Part 1: Analyze the Codebase

1. **Open all files in VS Code**:
   ```bash
   code starter/
   ```

2. **Review the existing code** and identify issues:
   - Code duplication
   - Poor naming conventions
   - Missing type hints
   - Lack of documentation
   - Tight coupling
   - Mixed responsibilities

3. **Use Copilot Chat** to analyze:
   ```
   Copilot Chat: "Analyze this codebase and suggest refactoring improvements"
   ```

### Part 2: Multi-File Refactoring Tasks

#### Task 1: Extract Common Patterns
The codebase has repeated database connection logic. Use Copilot to:

1. **Create a database connection manager**:
   ```python
   # In database.py, add this comment and let Copilot suggest:
   # Create a DatabaseManager class that handles connection pooling
   # and provides context manager support for transactions
   ```

2. **Refactor all database calls** to use the new manager:
   - Open `app.py` and `models.py` side by side
   - Use Copilot's multi-file awareness to update both consistently

**Copilot Prompt Suggestion:**
```python
# Refactor this function to use DatabaseManager instead of direct connection
# Ensure proper error handling and connection cleanup
def get_user_orders(user_id: int):
    # Original messy code here...
```

#### Task 2: Improve Type Safety
Add comprehensive type hints across all files:

1. **Start with models.py**:
   ```python
   # Add type hints to all class attributes and methods
   # Use TypedDict for complex data structures
   from typing import TypedDict, List, Optional
   
   class User:  # Let Copilot add proper type hints
   ```

2. **Propagate types to other files**:
   - Copilot will suggest consistent types based on usage
   - Watch how it maintains type consistency across files

#### Task 3: Implement Proper Error Handling
Replace generic exception handling with specific error types:

1. **Create custom exceptions**:
   ```python
   # In utils.py, create custom exception classes for:
   # - Database errors
   # - Validation errors  
   # - Business logic errors
   ```

2. **Update error handling** throughout the application:
   - Use Copilot's suggestions to handle specific exceptions
   - Add proper logging and error messages

#### Task 4: Extract Business Logic
Separate business logic from data access:

1. **Create a service layer**:
   ```python
   # Create services.py with business logic classes
   # Move order processing, user management, and inventory logic
   ```

2. **Refactor controllers** to use services:
   ```python
   # In app.py, refactor routes to use service classes
   # Keep routes thin, delegate to services
   ```

### Part 3: Validation and Testing

1. **Run the test suite**:
   ```bash
   python -m pytest tests/test_refactoring.py -v
   ```

2. **Use Copilot to generate additional tests**:
   ```python
   # Generate unit tests for the new DatabaseManager class
   # Include tests for connection pooling and error scenarios
   ```

3. **Performance comparison**:
   ```bash
   python tests/benchmark.py
   ```

## 🎯 Refactoring Checklist

Use this checklist to ensure comprehensive refactoring:

- [ ] **Database Layer**
  - [ ] Connection manager implemented
  - [ ] Connection pooling added
  - [ ] Transaction support
  - [ ] Proper cleanup in all cases

- [ ] **Type Safety**
  - [ ] All functions have type hints
  - [ ] Complex types use TypedDict/dataclasses
  - [ ] Return types specified
  - [ ] Optional types handled correctly

- [ ] **Error Handling**
  - [ ] Custom exception classes created
  - [ ] Specific exceptions caught
  - [ ] Proper error messages
  - [ ] Logging implemented

- [ ] **Code Organization**
  - [ ] Single responsibility principle
  - [ ] Business logic separated
  - [ ] Utilities properly organized
  - [ ] Configuration centralized

- [ ] **Documentation**
  - [ ] All classes have docstrings
  - [ ] Complex functions documented
  - [ ] Type hints serve as documentation
  - [ ] README updated

## 💡 Copilot Multi-File Tips

1. **Keep Related Files Open**: Copilot considers all open files for context
2. **Use Split Panes**: View multiple files simultaneously for better refactoring
3. **Consistent Naming**: Start with good names; Copilot will follow the pattern
4. **Incremental Changes**: Make small changes and let Copilot adapt
5. **Use Chat for Strategy**: Ask Copilot Chat for refactoring strategies before implementing

## 🏆 Success Criteria

Your refactoring is complete when:
- [ ] All tests pass
- [ ] Code follows consistent patterns
- [ ] Type safety is enforced throughout
- [ ] Error handling is specific and helpful
- [ ] Performance is maintained or improved
- [ ] Code is more maintainable and readable

## 🎯 Bonus Challenges

If you finish early:
1. Add async/await support to database operations
2. Implement caching layer with Copilot's help
3. Create a migration script for database schema
4. Add API versioning support

## 📚 Additional Resources

- [Refactoring with Copilot Best Practices](../resources/refactoring-guide.md)
- [Multi-File Editing Tips](https://code.visualstudio.com/docs/editor/multi-root-workspaces)
- [Python Type Hints Guide](https://docs.python.org/3/library/typing.html)

## 🏁 Completion

After completing the refactoring:
1. Compare your solution with the provided solution
2. Document lessons learned
3. Note which Copilot features were most helpful
4. Prepare for Exercise 3: Context-Aware Development

---

**Pro Tip**: The key to successful multi-file refactoring with Copilot is maintaining context. Keep related files open, use descriptive names, and make incremental changes that Copilot can follow and extend!