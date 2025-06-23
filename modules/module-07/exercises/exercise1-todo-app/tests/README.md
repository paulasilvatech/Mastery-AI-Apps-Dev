# Todo Application Tests

## Overview

This directory contains comprehensive tests for the AI-Powered Todo Application, covering both backend and frontend functionality.

## Test Structure

### Backend Tests (`test_backend.py`)
- API endpoint testing using FastAPI TestClient
- Database operations validation
- Error handling verification
- AI suggestion endpoint testing

### Frontend Tests (`test_frontend.js`)
- Component unit tests
- User interaction testing
- Integration tests
- State management validation

## Running Tests

### Backend Tests

```bash
# From the exercise root directory
cd backend
python -m pytest ../tests/test_backend.py -v

# With coverage
python -m pytest ../tests/test_backend.py --cov=app --cov-report=html
```

### Frontend Tests

```bash
# From the frontend directory
cd frontend
npm test

# Watch mode
npm test -- --watch

# Coverage report
npm test -- --coverage
```

## Test Coverage

### Backend Coverage
- ✅ CRUD operations (Create, Read, Update, Delete)
- ✅ Filtering and pagination
- ✅ Error handling (404, validation)
- ✅ AI suggestion endpoint
- ✅ Database transactions

### Frontend Coverage
- ✅ Component rendering
- ✅ User interactions (form submission, checkbox, buttons)
- ✅ API integration
- ✅ State updates
- ✅ Error states
- ✅ Loading states

## Writing New Tests

### Backend Test Example

```python
def test_new_feature(self):
    """Test description"""
    # Arrange
    test_data = {"field": "value"}
    
    # Act
    response = client.post("/endpoint", json=test_data)
    
    # Assert
    assert response.status_code == 200
    assert response.json()["field"] == "value"
```

### Frontend Test Example

```javascript
test('component behavior', async () => {
  // Arrange
  render(<Component prop="value" />);
  
  // Act
  fireEvent.click(screen.getByText('Button'));
  
  // Assert
  await waitFor(() => {
    expect(screen.getByText('Result')).toBeInTheDocument();
  });
});
```

## Continuous Integration

Tests are automatically run on:
- Pull requests
- Commits to main branch
- Manual workflow dispatch

## Troubleshooting

### Common Issues

1. **Import errors**: Ensure you're running tests from the correct directory
2. **Database conflicts**: Tests use a separate test database
3. **Async warnings**: Use `waitFor` for asynchronous operations
4. **Mock not working**: Clear mocks between tests with `beforeEach`

### Debug Mode

```bash
# Backend
python -m pytest -s -vv test_backend.py

# Frontend
npm test -- --verbose
```