# Exercise 1: Test Generation Mastery - Part 2

## 🚀 Part 3: Parameterized Testing

### Step 7: Create Parameterized Tests

Parameterized tests allow you to run the same test with different inputs. This is perfect for validation testing:

```python
# Test validation with multiple invalid inputs using pytest.mark.parametrize
# Test empty strings, None values, whitespace-only strings
# Each test case should have input values and expected error message
@pytest.mark.parametrize("isbn,title,author,expected_error", [
    # Add test cases here
])
def test_add_book_validation(library_system, isbn, title, author, expected_error):
```

**🤖 Copilot Prompt Suggestion #4:**
"Create parameterized tests for add_book validation that test empty strings, None values, whitespace, and verify correct error messages"

**Expected Copilot Generation:**
```python
import pytest

@pytest.mark.parametrize("isbn,title,author,expected_error", [
    ("", "Valid Title", "Valid Author", "ISBN, title, and author are required"),
    ("978-0-123456-78-9", "", "Valid Author", "ISBN, title, and author are required"),
    ("978-0-123456-78-9", "Valid Title", "", "ISBN, title, and author are required"),
    (None, "Valid Title", "Valid Author", "ISBN, title, and author are required"),
    ("978-0-123456-78-9", None, "Valid Author", "ISBN, title, and author are required"),
    ("978-0-123456-78-9", "Valid Title", None, "ISBN, title, and author are required"),
    ("   ", "Valid Title", "Valid Author", "ISBN, title, and author are required"),
    ("978-0-123456-78-9", "   ", "Valid Author", "ISBN, title, and author are required"),
    ("978-0-123456-78-9", "Valid Title", "   ", "ISBN, title, and author are required"),
])
def test_add_book_validation(isbn, title, author, expected_error):
    """Test add_book validation with various invalid inputs."""
    library = LibrarySystem()
    
    with pytest.raises(ValueError) as exc_info:
        library.add_book(isbn, title, author)
    
    assert str(exc_info.value) == expected_error
```

### Step 8: Create Fixtures

Fixtures provide reusable test setup. Create a `conftest.py` file:

```python
# conftest.py
import pytest
from datetime import datetime, timedelta
from unittest.mock import Mock
from library_system import LibrarySystem, Book

# Create fixtures for:
# 1. Empty library system
# 2. Library with sample books
# 3. Mock database connection
# 4. Sample book data
```

**🤖 Copilot Prompt Suggestion #5:**
"Create pytest fixtures for library system testing including empty library, populated library with 3 books, mock database, and sample book data"

**Expected Fixture Implementation:**
```python
@pytest.fixture
def empty_library():
    """Provide an empty library system."""
    return LibrarySystem()

@pytest.fixture
def mock_db():
    """Provide a mock database connection."""
    db = Mock()
    db.save_book = Mock()
    db.update_book = Mock()
    db.delete_book = Mock()
    return db

@pytest.fixture
def library_with_db(mock_db):
    """Provide a library system with mock database."""
    return LibrarySystem(db_connection=mock_db)

@pytest.fixture
def sample_books():
    """Provide sample book data."""
    return [
        {"isbn": "978-0-123456-78-9", "title": "Python Testing", "author": "Test Author"},
        {"isbn": "978-0-987654-32-1", "title": "Advanced Python", "author": "Expert Coder"},
        {"isbn": "978-0-111111-11-1", "title": "Testing Mastery", "author": "Test Author"},
    ]

@pytest.fixture
def populated_library(sample_books):
    """Provide a library with sample books."""
    library = LibrarySystem()
    for book_data in sample_books:
        library.add_book(**book_data)
    return library

@pytest.fixture
def borrowed_book_library(populated_library):
    """Provide a library with one borrowed book."""
    # Borrow the first book
    library = populated_library
    library.borrow_book("978-0-123456-78-9", "user123")
    return library
```

## 🎭 Part 4: Mocking External Dependencies

### Step 9: Mock Database Operations

Test database interactions without a real database:

```python
# Test that add_book calls database save_book with correct data
def test_add_book_saves_to_database(library_with_db, mock_db):
```

**🤖 Copilot Prompt Suggestion #6:**
"Test add_book method with mocked database, verify save_book is called once with correct book data"

```python
def test_add_book_saves_to_database(library_with_db, mock_db):
    """Test that adding a book saves it to the database."""
    # Act
    book = library_with_db.add_book("978-0-123456-78-9", "Test Book", "Test Author")
    
    # Assert
    mock_db.save_book.assert_called_once()
    call_args = mock_db.save_book.call_args[0][0]
    
    assert call_args['isbn'] == "978-0-123456-78-9"
    assert call_args['title'] == "Test Book"
    assert call_args['author'] == "Test Author"
    assert call_args['available'] is True
```

### Step 10: Mock External API Calls

Test the fetch_book_info method without making real HTTP requests:

```python
# Test fetch_book_info with mocked requests
# Mock successful API response
# Mock API error responses
# Use patch decorator to mock requests.get
@patch('library_system.requests.get')
def test_fetch_book_info_success(mock_get, empty_library):
```

**🤖 Copilot Prompt Suggestion #7:**
"Create tests for fetch_book_info that mock successful API responses and various error conditions using unittest.mock.patch"

**Expected Mock Tests:**
```python
from unittest.mock import patch

@patch('library_system.requests.get')
def test_fetch_book_info_success(mock_get, empty_library):
    """Test successful API call to fetch book info."""
    # Arrange
    mock_response = Mock()
    mock_response.json.return_value = {
        'isbn': '978-0-123456-78-9',
        'title': 'Extended Title',
        'publisher': 'Test Publisher',
        'year': 2024,
        'pages': 350
    }
    mock_response.raise_for_status = Mock()
    mock_get.return_value = mock_response
    
    # Act
    result = empty_library.fetch_book_info('978-0-123456-78-9')
    
    # Assert
    assert result['publisher'] == 'Test Publisher'
    assert result['year'] == 2024
    mock_get.assert_called_once_with(
        'https://api.library.example.com/books/978-0-123456-78-9'
    )

@patch('library_system.requests.get')
def test_fetch_book_info_api_error(mock_get, empty_library):
    """Test API error handling."""
    # Arrange
    mock_get.side_effect = requests.RequestException("API is down")
    
    # Act & Assert
    with pytest.raises(ConnectionError) as exc_info:
        empty_library.fetch_book_info('978-0-123456-78-9')
    
    assert "Failed to fetch book info: API is down" in str(exc_info.value)
```

## ⏰ Part 5: Testing Time-Dependent Code

### Step 11: Mock datetime for Late Fee Calculations

Testing code that depends on the current time requires mocking datetime:

```python
# Test return_book with different return dates to calculate late fees
# Mock datetime.now() to control the return date
# Test on-time return (no fee)
# Test late return (with fee)
@patch('library_system.datetime')
def test_return_book_on_time(mock_datetime, borrowed_book_library):
```

**🤖 Copilot Prompt Suggestion #8:**
"Create tests for return_book that mock datetime to test on-time returns (no fee) and late returns with calculated fees"

```python
from datetime import datetime, timedelta

@patch('library_system.datetime')
def test_return_book_on_time(mock_datetime, borrowed_book_library):
    """Test returning a book on time (no late fee)."""
    # Arrange
    borrow_date = datetime(2024, 1, 1, 10, 0, 0)
    return_date = datetime(2024, 1, 14, 10, 0, 0)  # Exactly 14 days later
    
    # Mock datetime.now() for both borrow and return
    mock_datetime.now.side_effect = [borrow_date, return_date]
    
    # Re-borrow the book with mocked date
    library = LibrarySystem()
    library.add_book("978-0-123456-78-9", "Test Book", "Test Author")
    library.borrow_book("978-0-123456-78-9", "user123")
    
    # Act
    result = library.return_book("978-0-123456-78-9")
    
    # Assert
    assert result['days_borrowed'] == 14
    assert result['late_days'] == 0
    assert result['late_fee'] == 0.0
    assert result['book'].available is True

@patch('library_system.datetime')
def test_return_book_late(mock_datetime, borrowed_book_library):
    """Test returning a book late with fees."""
    # Arrange
    borrow_date = datetime(2024, 1, 1, 10, 0, 0)
    return_date = datetime(2024, 1, 20, 10, 0, 0)  # 19 days later (5 days late)
    
    mock_datetime.now.side_effect = [borrow_date, return_date]
    
    # Re-borrow the book with mocked date
    library = LibrarySystem()
    library.add_book("978-0-123456-78-9", "Test Book", "Test Author")
    library.borrow_book("978-0-123456-78-9", "user123")
    
    # Act
    result = library.return_book("978-0-123456-78-9")
    
    # Assert
    assert result['days_borrowed'] == 19
    assert result['late_days'] == 5
    assert result['late_fee'] == 2.50  # 5 days * $0.50
```

## 🔍 Part 6: Testing Search and Query Functions

### Step 12: Test Search Functionality

Test the search_books method with various queries:

```python
# Test search_books with parameterized test cases
# Test exact matches, partial matches, case-insensitive search
# Test no results found
@pytest.mark.parametrize("query,expected_count,expected_isbns", [
    # Add test cases
])
def test_search_books(populated_library, query, expected_count, expected_isbns):
```

**🤖 Copilot Prompt Suggestion #9:**
"Create parameterized tests for search_books that test exact title match, partial author match, case-insensitive search, and no results"

## 🎯 Part 7: Edge Cases and Error Scenarios

### Step 13: Test Edge Cases

Create tests for unusual but valid scenarios:

```python
# Test edge cases:
# 1. Return a book that was borrowed at midnight
# 2. Search with special characters
# 3. Very long ISBN numbers
# 4. Unicode characters in titles/authors
class TestEdgeCases:
```

**🤖 Copilot Prompt Suggestion #10:**
"Generate edge case tests including midnight borrows, special characters in search, long ISBNs, and Unicode handling"

## 📊 Coverage Analysis

### Step 14: Check Test Coverage

Run pytest with coverage:

```bash
pytest --cov=library_system --cov-report=html --cov-report=term
```

This generates:
- Terminal report showing coverage percentages
- HTML report in `htmlcov/index.html`

### Step 15: Identify Missing Coverage

Look for uncovered lines and add tests:

```python
# After reviewing coverage report, add tests for:
# - get_overdue_books with multiple overdue books
# - Error paths in return_book
# - Edge cases in search_books
```

## ✅ Exercise Completion Checklist

- [ ] Created tests for Book dataclass
- [ ] Tested LibrarySystem initialization
- [ ] Created parameterized validation tests
- [ ] Implemented pytest fixtures
- [ ] Mocked database operations
- [ ] Mocked external API calls
- [ ] Tested time-dependent code
- [ ] Covered search functionality
- [ ] Added edge case tests
- [ ] Achieved >90% code coverage

## 🎉 Congratulations!

You've mastered test generation with Copilot! You've learned:
- How to guide Copilot to generate comprehensive tests
- Parameterized testing for efficiency
- Mocking external dependencies
- Testing time-dependent code
- Achieving high test coverage

---

**Continue to Part 3** for coverage optimization and final validation.