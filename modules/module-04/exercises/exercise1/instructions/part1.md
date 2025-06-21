# Exercise 1: Test Generation Mastery (⭐ Easy)

## 🎯 Exercise Overview

**Duration**: 30-45 minutes  
**Difficulty**: ⭐ (Easy)  
**Success Rate**: 95%

In this foundational exercise, you'll master the art of generating comprehensive test suites with GitHub Copilot. You'll learn to create unit tests, parameterized tests, and mock external dependencies, transforming a simple untested module into a robust, well-tested codebase.

## 🎓 Learning Objectives

By completing this exercise, you will:
- Generate complete test suites with Copilot
- Create parameterized tests for multiple scenarios  
- Mock external dependencies effectively
- Identify and test edge cases
- Understand test coverage optimization

## 📋 Prerequisites

- ✅ Module 04 prerequisites completed
- ✅ pytest installed and configured
- ✅ Basic understanding of unit testing
- ✅ VS Code with Copilot active

## 🏗️ What You'll Build

A comprehensive test suite for a **Library Management System** that includes:
- Unit tests for all public methods
- Parameterized tests for data validation
- Mocked database operations
- Edge case coverage
- Performance benchmarks

## 📁 Project Structure

```
exercise1-easy/
├── README.md                # This file
├── instructions/
│   ├── part1.md            # Setup and basic tests
│   ├── part2.md            # Advanced testing
│   └── part3.md            # Coverage optimization
├── starter/
│   ├── library_system.py    # Code to test
│   └── requirements.txt     # Dependencies
├── solution/
│   ├── library_system.py    # Same code
│   ├── test_library.py      # Complete test suite
│   ├── test_advanced.py     # Advanced tests
│   └── conftest.py         # pytest configuration
└── tests/
    └── validate_tests.py    # Validation script
```

## 🚀 Part 1: Understanding the Code to Test

### Step 1: Examine the Library System

Navigate to the starter directory and open `library_system.py`:

```python
# library_system.py
from datetime import datetime, timedelta
from typing import List, Optional, Dict
import json
import requests
from dataclasses import dataclass, asdict

@dataclass
class Book:
    """Represents a book in the library."""
    isbn: str
    title: str
    author: str
    available: bool = True
    borrowed_date: Optional[datetime] = None
    borrower_id: Optional[str] = None
    
    def to_dict(self) -> dict:
        """Convert book to dictionary."""
        data = asdict(self)
        if self.borrowed_date:
            data['borrowed_date'] = self.borrowed_date.isoformat()
        return data

class LibrarySystem:
    """Manages library book operations."""
    
    def __init__(self, db_connection=None):
        """Initialize library system with optional database connection."""
        self.books: Dict[str, Book] = {}
        self.db = db_connection
        self.api_base_url = "https://api.library.example.com"
        self.late_fee_per_day = 0.50
        self.loan_period_days = 14
        
    def add_book(self, isbn: str, title: str, author: str) -> Book:
        """Add a new book to the library."""
        if not isbn or not title or not author:
            raise ValueError("ISBN, title, and author are required")
            
        if isbn in self.books:
            raise ValueError(f"Book with ISBN {isbn} already exists")
            
        book = Book(isbn=isbn, title=title, author=author)
        self.books[isbn] = book
        
        # Save to database if connected
        if self.db:
            self.db.save_book(book.to_dict())
            
        return book
    
    def borrow_book(self, isbn: str, borrower_id: str) -> Book:
        """Borrow a book from the library."""
        if isbn not in self.books:
            raise ValueError(f"Book with ISBN {isbn} not found")
            
        book = self.books[isbn]
        if not book.available:
            raise ValueError(f"Book '{book.title}' is already borrowed")
            
        book.available = False
        book.borrower_id = borrower_id
        book.borrowed_date = datetime.now()
        
        # Update database if connected
        if self.db:
            self.db.update_book(isbn, book.to_dict())
            
        return book
    
    def return_book(self, isbn: str) -> Dict[str, any]:
        """Return a borrowed book and calculate late fees."""
        if isbn not in self.books:
            raise ValueError(f"Book with ISBN {isbn} not found")
            
        book = self.books[isbn]
        if book.available:
            raise ValueError(f"Book '{book.title}' is not borrowed")
            
        # Calculate late fee
        days_borrowed = (datetime.now() - book.borrowed_date).days
        late_days = max(0, days_borrowed - self.loan_period_days)
        late_fee = late_days * self.late_fee_per_day
        
        # Reset book status
        book.available = True
        book.borrower_id = None
        book.borrowed_date = None
        
        # Update database if connected
        if self.db:
            self.db.update_book(isbn, book.to_dict())
            
        return {
            'book': book,
            'days_borrowed': days_borrowed,
            'late_days': late_days,
            'late_fee': late_fee
        }
    
    def search_books(self, query: str) -> List[Book]:
        """Search books by title or author."""
        query = query.lower()
        results = []
        
        for book in self.books.values():
            if query in book.title.lower() or query in book.author.lower():
                results.append(book)
                
        return results
    
    def get_overdue_books(self) -> List[Dict[str, any]]:
        """Get all overdue books with borrower information."""
        overdue = []
        current_date = datetime.now()
        
        for book in self.books.values():
            if not book.available and book.borrowed_date:
                days_borrowed = (current_date - book.borrowed_date).days
                if days_borrowed > self.loan_period_days:
                    overdue.append({
                        'book': book,
                        'days_overdue': days_borrowed - self.loan_period_days,
                        'current_fee': (days_borrowed - self.loan_period_days) * self.late_fee_per_day
                    })
                    
        return overdue
    
    def fetch_book_info(self, isbn: str) -> Dict[str, any]:
        """Fetch additional book information from external API."""
        try:
            response = requests.get(f"{self.api_base_url}/books/{isbn}")
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            raise ConnectionError(f"Failed to fetch book info: {str(e)}")
```

### Step 2: Understanding Testing Requirements

This library system has several testing challenges:
1. **State Management**: Books can be available or borrowed
2. **External Dependencies**: Database and API connections
3. **Date/Time Operations**: Late fee calculations
4. **Error Cases**: Various validation errors
5. **Search Functionality**: Partial string matching

### Step 3: Set Up Test File

Create `test_library.py` in the starter directory:

```python
# test_library.py
import pytest
from datetime import datetime, timedelta
from unittest.mock import Mock, patch, MagicMock
from library_system import Book, LibrarySystem

# Your test code starts here
# We'll use Copilot to generate comprehensive tests
```

## 🧪 Part 2: Generating Basic Unit Tests

### Step 4: Test Book Class

Let's start by testing the Book dataclass. Add this comment and let Copilot help:

```python
# Test the Book dataclass
# Test cases:
# 1. Create a book with all fields
# 2. Create a book with default values
# 3. Test to_dict() method
# 4. Test to_dict() with borrowed_date
class TestBook:
```

**🤖 Copilot Prompt Suggestion #1:**
"Create a comprehensive test class for the Book dataclass that tests initialization, default values, and the to_dict method with proper datetime handling"

**Expected Copilot Generation:**
```python
class TestBook:
    def test_book_creation_with_all_fields(self):
        """Test creating a book with all fields specified."""
        borrowed_date = datetime.now()
        book = Book(
            isbn="978-0-123456-78-9",
            title="Test Book",
            author="Test Author",
            available=False,
            borrowed_date=borrowed_date,
            borrower_id="user123"
        )
        
        assert book.isbn == "978-0-123456-78-9"
        assert book.title == "Test Book"
        assert book.author == "Test Author"
        assert book.available is False
        assert book.borrowed_date == borrowed_date
        assert book.borrower_id == "user123"
    
    def test_book_creation_with_defaults(self):
        """Test creating a book with only required fields."""
        book = Book(
            isbn="978-0-123456-78-9",
            title="Test Book",
            author="Test Author"
        )
        
        assert book.available is True
        assert book.borrowed_date is None
        assert book.borrower_id is None
    
    def test_to_dict_without_borrowed_date(self):
        """Test converting book to dictionary without borrowed date."""
        book = Book(
            isbn="978-0-123456-78-9",
            title="Test Book",
            author="Test Author"
        )
        
        result = book.to_dict()
        
        assert result == {
            'isbn': "978-0-123456-78-9",
            'title': "Test Book",
            'author': "Test Author",
            'available': True,
            'borrowed_date': None,
            'borrower_id': None
        }
    
    def test_to_dict_with_borrowed_date(self):
        """Test converting book to dictionary with borrowed date."""
        borrowed_date = datetime(2024, 1, 15, 10, 30, 0)
        book = Book(
            isbn="978-0-123456-78-9",
            title="Test Book",
            author="Test Author",
            available=False,
            borrowed_date=borrowed_date,
            borrower_id="user123"
        )
        
        result = book.to_dict()
        
        assert result['borrowed_date'] == "2024-01-15T10:30:00"
        assert result['borrower_id'] == "user123"
        assert result['available'] is False
```

### Step 5: Test LibrarySystem Initialization

Now let's test the LibrarySystem class initialization:

```python
# Test LibrarySystem initialization
# Test with and without database connection
# Verify all attributes are properly set
class TestLibrarySystemInit:
```

**🤖 Copilot Prompt Suggestion #2:**
"Generate tests for LibrarySystem initialization including with/without database, checking all default values and attributes"

### Step 6: Test add_book Method

Create comprehensive tests for the add_book method:

```python
# Test add_book method
# Test successful book addition
# Test validation errors (empty fields)
# Test duplicate ISBN error
# Test database save is called
class TestAddBook:
```

**🤖 Copilot Prompt Suggestion #3:**
"Create comprehensive tests for add_book method including success cases, validation errors, duplicate handling, and mocked database interactions"

### 📊 Understanding Test Structure

Each test should follow the **Arrange-Act-Assert** pattern:
1. **Arrange**: Set up test data and mocks
2. **Act**: Execute the code being tested
3. **Assert**: Verify the results

Example:
```python
def test_add_book_success(self):
    # Arrange
    library = LibrarySystem()
    
    # Act
    book = library.add_book("978-0-123456-78-9", "Test Title", "Test Author")
    
    # Assert
    assert book.isbn == "978-0-123456-78-9"
    assert book in library.books.values()
```

### 🎯 Testing Best Practices

1. **Test One Thing**: Each test should verify one behavior
2. **Clear Names**: Test names should describe what they test
3. **Independent Tests**: Tests shouldn't depend on each other
4. **Use Fixtures**: Share common setup code
5. **Mock External Dependencies**: Don't make real API calls

---

**Continue to Part 2** for advanced testing techniques including parameterized tests, mocking, and coverage optimization.