# Test Patterns Cheat Sheet

## 🎯 Quick Reference for Common Testing Patterns

### Basic Test Structure

```python
# AAA Pattern - Arrange, Act, Assert
def test_example():
    # Arrange - Set up test data
    user = User(name="John", age=30)
    
    # Act - Execute the behavior
    result = user.can_vote()
    
    # Assert - Verify the outcome
    assert result is True
```

### Pytest Fixtures

```python
# Simple fixture
@pytest.fixture
def sample_user():
    return User(name="Test User", email="test@example.com")

# Fixture with teardown
@pytest.fixture
def database():
    db = Database()
    db.connect()
    yield db  # Test runs here
    db.disconnect()  # Cleanup

# Fixture using other fixtures
@pytest.fixture
def logged_in_user(sample_user, client):
    client.login(sample_user)
    return sample_user
```

### Parametrized Tests

```python
# Single parameter
@pytest.mark.parametrize("input,expected", [
    (0, 0),
    (1, 1),
    (5, 120),  # 5! = 120
    (-1, None),  # Error case
])
def test_factorial(input, expected):
    assert factorial(input) == expected

# Multiple parameters
@pytest.mark.parametrize("a,b,expected", [
    (2, 3, 5),
    (-1, 1, 0),
    (0, 0, 0),
])
def test_addition(a, b, expected):
    assert add(a, b) == expected

# Named test cases
@pytest.mark.parametrize("username,valid", [
    pytest.param("john_doe", True, id="valid_username"),
    pytest.param("john doe", False, id="space_in_username"),
    pytest.param("a", False, id="too_short"),
    pytest.param("", False, id="empty_username"),
])
def test_username_validation(username, valid):
    assert is_valid_username(username) == valid
```

### Exception Testing

```python
# Basic exception test
def test_division_by_zero():
    with pytest.raises(ZeroDivisionError):
        divide(10, 0)

# Check exception message
def test_invalid_email():
    with pytest.raises(ValueError) as exc_info:
        validate_email("not-an-email")
    assert "Invalid email format" in str(exc_info.value)

# Check custom exception attributes
def test_insufficient_funds():
    account = Account(balance=100)
    with pytest.raises(InsufficientFundsError) as exc_info:
        account.withdraw(150)
    
    error = exc_info.value
    assert error.requested == 150
    assert error.available == 100
```

### Mocking Patterns

```python
# Basic mock
from unittest.mock import Mock, patch

def test_email_sent():
    mock_email = Mock()
    service = NotificationService(email_client=mock_email)
    
    service.notify_user("user@example.com", "Hello")
    
    mock_email.send.assert_called_once_with(
        to="user@example.com",
        subject="Notification",
        body="Hello"
    )

# Patching external dependencies
@patch('requests.get')
def test_fetch_user_data(mock_get):
    mock_get.return_value.json.return_value = {"id": 1, "name": "John"}
    
    user = fetch_user_from_api(1)
    
    assert user.name == "John"
    mock_get.assert_called_with("https://api.example.com/users/1")

# Mock with side effects
def test_retry_on_failure():
    mock_api = Mock()
    mock_api.call.side_effect = [
        ConnectionError("Failed"),
        ConnectionError("Failed"),
        {"success": True}
    ]
    
    result = retry_api_call(mock_api, max_retries=3)
    
    assert result == {"success": True}
    assert mock_api.call.call_count == 3
```

### Time-Based Testing

```python
from freezegun import freeze_time
from datetime import datetime, timedelta

# Freeze time for testing
@freeze_time("2024-01-15 10:00:00")
def test_expiry_check():
    item = create_item(expires_in_days=7)
    assert item.expires_at == datetime(2024, 1, 22, 10, 0, 0)
    assert not item.is_expired()

# Test with time progression
def test_cache_expiry():
    with freeze_time("2024-01-15 10:00:00") as frozen_time:
        cache.set("key", "value", ttl=60)
        assert cache.get("key") == "value"
        
        frozen_time.shift(61)  # Move forward 61 seconds
        assert cache.get("key") is None

# Mock datetime
@patch('myapp.datetime')
def test_business_hours(mock_datetime):
    mock_datetime.now.return_value = datetime(2024, 1, 15, 14, 0)  # 2 PM
    assert is_business_hours() is True
    
    mock_datetime.now.return_value = datetime(2024, 1, 15, 22, 0)  # 10 PM
    assert is_business_hours() is False
```

### Database Testing

```python
# Transaction rollback pattern
@pytest.fixture
def db_session():
    connection = engine.connect()
    transaction = connection.begin()
    session = Session(bind=connection)
    
    yield session
    
    session.close()
    transaction.rollback()
    connection.close()

# Test with database
def test_create_user(db_session):
    user = User(name="John", email="john@example.com")
    db_session.add(user)
    db_session.commit()
    
    found = db_session.query(User).filter_by(email="john@example.com").first()
    assert found.name == "John"

# In-memory database
@pytest.fixture(scope="session")
def in_memory_db():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    return engine
```

### Async Testing

```python
# Basic async test
@pytest.mark.asyncio
async def test_async_function():
    result = await fetch_data_async()
    assert result == {"status": "ok"}

# Mock async functions
@pytest.mark.asyncio
async def test_async_with_mock():
    mock_client = AsyncMock()
    mock_client.get.return_value = {"data": "test"}
    
    service = AsyncService(mock_client)
    result = await service.process()
    
    assert result == {"data": "test"}
    mock_client.get.assert_awaited_once()

# Test async context manager
@pytest.mark.asyncio
async def test_async_context():
    async with AsyncDatabase() as db:
        result = await db.query("SELECT 1")
        assert result == [(1,)]
```

### Performance Testing

```python
# Basic benchmark
def test_performance(benchmark):
    result = benchmark(expensive_function, 1000)
    assert result == expected_value

# Custom benchmark
@pytest.mark.benchmark(
    group="sorting",
    min_rounds=5,
    max_time=1.0,
    min_time=0.0001,
    warmup=True
)
def test_sort_performance(benchmark):
    data = list(range(10000, 0, -1))
    benchmark(sorted, data)

# Assert performance requirements
def test_response_time(benchmark):
    result = benchmark(api_call)
    stats = benchmark.stats
    assert stats["mean"] < 0.1  # Mean time < 100ms
    assert stats["max"] < 0.2   # Max time < 200ms
```

### Test Markers

```python
# Skip test
@pytest.mark.skip(reason="Not implemented yet")
def test_future_feature():
    pass

# Conditional skip
@pytest.mark.skipif(sys.version_info < (3, 9), reason="Requires Python 3.9+")
def test_new_syntax():
    pass

# Expected failure
@pytest.mark.xfail(reason="Known bug in library")
def test_buggy_behavior():
    assert buggy_function() == "correct"

# Custom markers
@pytest.mark.slow
def test_integration():
    pass

@pytest.mark.unit
def test_calculation():
    pass

# Run: pytest -m unit
# Run: pytest -m "not slow"
```

### Data-Driven Testing

```python
# Using pytest-datadir
def test_process_file(datadir):
    input_file = datadir / "input.json"
    output = process_json_file(input_file)
    
    expected_file = datadir / "expected_output.json"
    expected = json.loads(expected_file.read_text())
    
    assert output == expected

# Table-driven tests
test_cases = [
    # (input, expected_output, description)
    ("hello", "HELLO", "lowercase to uppercase"),
    ("WORLD", "WORLD", "already uppercase"),
    ("123", "123", "numbers unchanged"),
    ("", "", "empty string"),
]

@pytest.mark.parametrize("input,expected,description", test_cases)
def test_uppercase(input, expected, description):
    assert input.upper() == expected, f"Failed: {description}"
```

### Property-Based Testing

```python
from hypothesis import given, strategies as st

# Basic property test
@given(st.integers())
def test_abs_always_positive(x):
    assert abs(x) >= 0

# Complex property test
@given(
    st.lists(st.integers(), min_size=1),
    st.integers(min_value=0)
)
def test_list_slicing(lst, index):
    if index < len(lst):
        assert lst[index] == lst[index:index+1][0]

# Custom strategies
@st.composite
def user_data(draw):
    return {
        'name': draw(st.text(min_size=1, max_size=50)),
        'age': draw(st.integers(min_value=0, max_value=150)),
        'email': draw(st.emails())
    }

@given(user_data())
def test_user_creation(data):
    user = User(**data)
    assert user.name == data['name']
    assert 0 <= user.age <= 150
```

### Snapshot Testing

```python
# Using pytest-snapshot
def test_api_response(snapshot):
    response = api.get_user(123)
    snapshot.assert_match(response.json())

def test_html_generation(snapshot):
    html = render_template("user.html", user=sample_user)
    snapshot.assert_match(html, "user_template.html")
```

### Golden Master Testing

```python
def test_legacy_calculation():
    # Record expected outputs for various inputs
    golden_master = {
        (1, 2): 3,
        (5, 5): 10,
        (-1, 1): 0,
        (0, 0): 0,
    }
    
    for inputs, expected in golden_master.items():
        result = legacy_function(*inputs)
        assert result == expected, f"Failed for inputs {inputs}"
```

## 🤖 Copilot Prompts for Test Generation

### Generate Complete Test Suite
```python
# Generate comprehensive tests for this class
# Include:
# - Constructor tests with valid/invalid inputs
# - Method tests with edge cases
# - Integration tests with dependencies
# - Error handling tests
# - Performance tests if applicable
class PaymentProcessor:
    # ... implementation ...
```

### Generate Specific Test Types
```python
# Generate parametrized tests for all edge cases
# Generate async tests for this async function  
# Generate mock tests for external dependencies
# Generate property-based tests for this algorithm
```

---

## 📚 Quick Command Reference

```bash
# Run tests
pytest                          # Run all tests
pytest -v                       # Verbose output
pytest -k "test_user"          # Run tests matching pattern
pytest -m unit                 # Run marked tests
pytest --lf                    # Run last failed
pytest --ff                    # Run failed first

# Coverage
pytest --cov=src               # Coverage for src directory
pytest --cov-report=html       # HTML coverage report
pytest --cov-report=term-missing  # Show missing lines

# Performance
pytest --durations=10          # Show 10 slowest tests
pytest --benchmark-only        # Run only benchmarks

# Debugging
pytest -s                      # Show print statements
pytest --pdb                   # Drop to debugger on failure
pytest --pdbcls=IPython.terminal.debugger:TerminalPdb  # Use IPython debugger
```