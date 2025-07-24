---
sidebar_position: 4
title: "Exercise 1: Part 3"
description: "## 📊 Part 8: Coverage Optimization"
---

# Ejercicio 1: Test Generation Mastery - Partee 3

## 📊 Partee 8: Coverage Optimization

### Step 16: Analyze Coverage Gaps

After running your initial tests, you might see coverage gaps. Here's how to identify and fill them:

```bash
# Generate detailed coverage report
pytest --cov=library_system --cov-report=term-missing

# Look for lines marked with "!"
# These are uncovered lines
```

Common coverage gaps include:
- Exception handlers
- Else branches
- Default parameter values
- Early returns

### Step 17: Test get_overdue_books Method

This method requires complex setup with multiple borrowed books:

```python
# Test get_overdue_books with various scenarios
# No overdue books
# One overdue book  
# Multiple overdue books with different overdue periods
# Books borrowed today (not overdue)
@patch('library_system.datetime')
def test_get_overdue_books_multiple(mock_datetime, empty_library):
```

**🤖 Copilot Prompt Suggestion #11:**
"Create comprehensive tests for get_overdue_books including no overdue books, single overdue, multiple overdue with different periods, and edge cases"

**Expected Implementation:**
```python
@patch('library_system.datetime')
def test_get_overdue_books_multiple(mock_datetime, empty_library):
    """Test getting multiple overdue books with different overdue periods."""
    # Set up current date
    current_date = datetime(2024, 2, 1, 10, 0, 0)
    
    # Add books
    library = empty_library
    books_data = [
        ("978-1-111111-11-1", "Book 1", "Author 1"),
        ("978-2-222222-22-2", "Book 2", "Author 2"),
        ("978-3-333333-33-3", "Book 3", "Author 3"),
        ("978-4-444444-44-4", "Book 4", "Author 4"),
    ]
    
    for isbn, title, author in books_data:
        library.add_book(isbn, title, author)
    
    # Borrow books at different times
    borrow_dates = [
        datetime(2024, 1, 1, 10, 0, 0),   # 31 days ago (17 days overdue)
        datetime(2024, 1, 10, 10, 0, 0),  # 22 days ago (8 days overdue)
        datetime(2024, 1, 18, 10, 0, 0),  # 14 days ago (0 days overdue)
        datetime(2024, 1, 20, 10, 0, 0),  # 12 days ago (not overdue)
    ]
    
    # Mock datetime for borrowing
    for i, (isbn, _, _) in enumerate(books_data):
        mock_datetime.now.return_value = borrow_dates[i]
        library.borrow_book(isbn, f"user{i+1}")
    
    # Mock current date for checking overdue
    mock_datetime.now.return_value = current_date
    
    # Act
    overdue_books = library.get_overdue_books()
    
    # Assert
    assert len(overdue_books) == 2  # Only first two books are overdue
    
    # Check first overdue book
    assert overdue_books[0]['book'].isbn == "978-1-111111-11-1"
    assert overdue_books[0]['days_overdue'] == 17
    assert overdue_books[0]['current_fee'] == 8.50  # 17 * 0.50
    
    # Check second overdue book
    assert overdue_books[1]['book'].isbn == "978-2-222222-22-2"
    assert overdue_books[1]['days_overdue'] == 8
    assert overdue_books[1]['current_fee'] == 4.00  # 8 * 0.50
```

### Step 18: Test Exception Paths

Ensure all error conditions are tested:

```python
# Test all ValueError conditions in borrow_book
class TestBorrowBookErrors:
    def test_borrow_nonexistent_book(self, empty_library):
        """Test borrowing a book that doesn't exist."""
        with pytest.raises(ValueError) as exc_info:
            empty_library.borrow_book("999-9-999999-99-9", "user123")
        assert "not found" in str(exc_info.value)
    
    def test_borrow_already_borrowed_book(self, borrowed_book_library):
        """Test borrowing a book that's already borrowed."""
        with pytest.raises(ValueError) as exc_info:
            borrowed_book_library.borrow_book("978-0-123456-78-9", "user456")
        assert "already borrowed" in str(exc_info.value)

# Test all ValueError conditions in return_book
class TestReturnBookErrors:
    def test_return_nonexistent_book(self, empty_library):
        """Test returning a book that doesn't exist."""
        with pytest.raises(ValueError) as exc_info:
            empty_library.return_book("999-9-999999-99-9")
        assert "not found" in str(exc_info.value)
    
    def test_return_available_book(self, populated_library):
        """Test returning a book that's not borrowed."""
        with pytest.raises(ValueError) as exc_info:
            populated_library.return_book("978-0-123456-78-9")
        assert "is not borrowed" in str(exc_info.value)
```

## 🔧 Partee 9: Performance Testing

### Step 19: Add Performance Benchmarks

Use pytest-benchmark to ensure your code performs well:

```python
# Test performance of search with large dataset
def test_search_performance(benchmark):
    """Benchmark search performance with 1000 books."""
    # Create library with many books
    library = LibrarySystem()
    
    # Add 1000 books
    for i in range(1000):
        library.add_book(
            f"978-0-{i:06d}-00-0",
            f"Book Title {i}",
            f"Author {i % 100}"
        )
    
    # Benchmark the search
    result = benchmark(library.search_books, "Title 500")
    
    assert len(result) == 1
    assert result[0].title == "Book Title 500"
```

## 📝 Partee 10: Completar Test Suite

### Step 20: Final Test Organization

Here's the complete structure for your test file:

```python
# test_library_complete.py
import pytest
from datetime import datetime, timedelta
from unittest.mock import Mock, patch, MagicMock
import requests
from library_system import Book, LibrarySystem

# ===== Fixtures (in conftest.py) =====
# [Include all fixtures from Part 2]

# ===== Book Tests =====
class TestBook:
    # [Include all Book tests from Part 1]
    pass

# ===== LibrarySystem Initialization =====
class TestLibrarySystemInit:
    def test_init_without_database(self):
        library = LibrarySystem()
        assert library.db is None
        assert library.books == {}
        assert library.late_fee_per_day == 0.50
        assert library.loan_period_days == 14
    
    def test_init_with_database(self, mock_db):
        library = LibrarySystem(db_connection=mock_db)
        assert library.db == mock_db

# ===== Add Book Tests =====
class TestAddBook:
    # [Include all add_book tests]
    pass

# ===== Parameterized Validation Tests =====
# [Include parameterized tests from Part 2]

# ===== Borrow Book Tests =====
class TestBorrowBook:
    # [Include all borrow_book tests]
    pass

# ===== Return Book Tests =====
class TestReturnBook:
    # [Include all return_book tests with datetime mocking]
    pass

# ===== Search Tests =====
class TestSearchBooks:
    # [Include all search tests]
    pass

# ===== Overdue Books Tests =====
class TestOverdueBooks:
    # [Include all get_overdue_books tests]
    pass

# ===== External API Tests =====
class TestExternalAPI:
    # [Include all fetch_book_info tests]
    pass

# ===== Edge Cases =====
class TestEdgeCases:
    # [Include all edge case tests]
    pass

# ===== Performance Tests =====
class TestPerformance:
    # [Include benchmark tests]
    pass
```

## 🎯 Final Validation

### Step 21: Run Completar Test Suite

Execute all tests with full reporting:

```bash
# Run all tests with coverage
pytest -v --cov=library_system --cov-report=html --cov-report=term

# Run specific test classes
pytest -v test_library.py::TestBook

# Run with markers
pytest -v -m "not slow"

# Generate coverage badge
coverage-badge -o coverage.svg
```

### Step 22: Validate Your Learning

Create `validate_tests.py` to ensure you've covered all requirements:

```python
#!/usr/bin/env python3
"""Validate that all required tests are implemented."""

import ast
import sys
from pathlib import Path

def analyze_test_file(filepath):
    """Analyze test file for required components."""
    with open(filepath, 'r') as f:
        tree = ast.parse(f.read())
    
    test_classes = []
    test_methods = []
    has_fixtures = False
    has_parametrize = False
    has_mocks = False
    
    for node in ast.walk(tree):
        if isinstance(node, ast.ClassDef) and node.name.startswith('Test'):
            test_classes.append(node.name)
        elif isinstance(node, ast.FunctionDef) and node.name.startswith('test_'):
            test_methods.append(node.name)
        elif isinstance(node, ast.FunctionDef) and any(
            decorator.id == 'fixture' for decorator in node.decorator_list 
            if isinstance(decorator, ast.Name)
        ):
            has_fixtures = True
        elif isinstance(node, ast.Attribute) and node.attr == 'parametrize':
            has_parametrize = True
        elif isinstance(node, ast.Name) and node.id in ['Mock', 'patch']:
            has_mocks = True
    
    return {
        'classes': test_classes,
        'methods': test_methods,
        'fixtures': has_fixtures,
        'parametrize': has_parametrize,
        'mocks': has_mocks
    }

def main():
    """Check if all required tests are present."""
    test_file = Path('test_library.py')
    
    if not test_file.exists():
        print("❌ test_library.py not found!")
        return 1
    
    results = analyze_test_file(test_file)
    
    # Check requirements
    required_classes = ['TestBook', 'TestLibrarySystemInit', 'TestAddBook']
    required_patterns = ['test_add_book', 'test_borrow_book', 'test_return_book']
    
    print("🔍 Test Analysis Results:\n")
    print(f"✅ Found {len(results['classes'])} test classes")
    print(f"✅ Found {len(results['methods'])} test methods")
    print(f"{'✅' if results['fixtures'] else '❌'} Uses fixtures")
    print(f"{'✅' if results['parametrize'] else '❌'} Uses parametrized tests")
    print(f"{'✅' if results['mocks'] else '❌'} Uses mocks")
    
    # Detailed checks
    missing_classes = set(required_classes) - set(results['classes'])
    if missing_classes:
        print(f"\n❌ Missing test classes: {missing_classes}")
        return 1
    
    print("\n✅ All required components found!")
    print("\n📊 Run 'pytest --cov' to check coverage")
    return 0

if __name__ == "__main__":
    sys.exit(main())
```

## 🏁 Ejercicio Resumen

### What You've Learned

1. **Test Generation with Copilot**
   - Using comments to guide test creation
   - Generating comprehensive test cases
   - Creating edge case tests

2. **Avanzado Testing Techniques**
   - Parameterized testing for efficiency
   - Fixtures for reusable setup
   - Mocking external dependencies
   - Time-based testing

3. **Coverage Optimization**
   - Identifying coverage gaps
   - Testing all code paths
   - Achieving Greater than 90% coverage

### Key Takeaways

- **Comience con clear test descriptions** - Copilot generates better tests with good prompts
- **Use parameterized tests** - Reduce code duplication
- **Mock external dependencies** - Keep tests fast and isolated
- **Verificar coverage regularly** - Ensure comprehensive testing
- **Test edge cases** - Think beyond the happy path

## 🎯 Extension Challenges

1. **Add Integration Tests**
   - Test the full workflow of borrowing and returning
   - Test concurrent operations

2. **Add Property-Based Tests**
   - Use hypothesis library
   - Generate random test data

3. **Create Custom Assertions**
   - Build domain-specific assertions
   - Improve test readability

4. **Performance Profiling**
   - Perfil memory usage
   - Optimize slow operations

---

🎉 **Congratulations!** You've completed Exercise 1 and mastered AI-assisted test generation!