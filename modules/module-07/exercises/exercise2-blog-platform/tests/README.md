# Blog Platform Tests

## Overview

Comprehensive test suite for the AI-enhanced blog platform covering authentication, blog posts, comments, and AI features.

## Test Structure

```
tests/
├── test_auth.py          # Authentication and authorization tests
├── test_blog_posts.py    # Blog post CRUD and search tests
├── test_comments.py       # Comment system tests
├── test_ai_features.py   # AI integration tests
└── conftest.py          # Shared fixtures and configuration
```

## Running Tests

### All Tests
```bash
pytest -v
```

### Specific Test File
```bash
pytest tests/test_auth.py -v
```

### With Coverage
```bash
pytest --cov=app --cov-report=html --cov-report=term
```

### Watch Mode
```bash
pytest-watch
```

## Test Categories

### Authentication Tests
- User registration
- Login/logout
- JWT token validation
- Protected endpoints
- Password reset
- Email verification

### Blog Post Tests
- CRUD operations
- Slug generation
- Status transitions
- Search functionality
- Filtering and sorting
- Pagination
- Tag management

### Comment Tests
- Creating comments
- Nested/threaded comments
- Comment moderation
- Soft deletion
- Edit history

### AI Feature Tests
- Content suggestions
- Auto-tagging
- SEO optimization
- Content moderation
- Summary generation

## Test Data

Tests use a separate test database that's created and destroyed for each test session.

### Fixtures

```python
@pytest.fixture
def test_user():
    """Create a test user"""
    return {
        "username": "testuser",
        "email": "test@example.com",
        "password": "testpass123"
    }

@pytest.fixture
def auth_headers(test_user):
    """Get auth headers with valid token"""
    # Register and login user
    # Return headers with Bearer token
```

## Writing Tests

### Test Structure
```python
class TestFeature:
    """Group related tests"""
    
    def test_happy_path(self):
        """Test normal operation"""
        # Arrange
        # Act
        # Assert
    
    def test_error_case(self):
        """Test error handling"""
        # Test validation
        # Test permissions
        # Test edge cases
```

### Best Practices

1. **Isolation**: Each test should be independent
2. **Clarity**: Clear test names and assertions
3. **Coverage**: Test both success and failure paths
4. **Performance**: Mock external services
5. **Data**: Use factories for test data

## Continuous Integration

Tests run automatically on:
- Pull requests
- Main branch commits
- Scheduled daily runs

### GitHub Actions
```yaml
- name: Run Tests
  run: |
    pytest --cov=app --cov-report=xml
    
- name: Upload Coverage
  uses: codecov/codecov-action@v3
```

## Debugging Tests

### Verbose Output
```bash
pytest -vv -s
```

### Debug Single Test
```bash
pytest -k "test_user_registration" --pdb
```

### Check Database State
```python
# In test
import pdb; pdb.set_trace()
# Inspect database
```

## Performance Testing

### Load Tests
```python
def test_concurrent_requests():
    """Test API under load"""
    import asyncio
    import aiohttp
    
    async def make_request():
        # Concurrent request logic
    
    # Run 100 concurrent requests
    asyncio.run(test_load())
```

### Benchmark Tests
```python
@pytest.mark.benchmark
def test_search_performance(benchmark):
    """Benchmark search functionality"""
    result = benchmark(search_posts, "python")
    assert result["total"] > 0
```