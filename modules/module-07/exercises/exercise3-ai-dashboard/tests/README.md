# AI Analytics Dashboard - Test Suite

## Overview

Comprehensive testing for the AI-powered analytics dashboard covering unit tests, integration tests, and end-to-end scenarios.

## Test Structure

```
tests/
├── backend/
│   ├── test_analytics.py      # Analytics engine tests
│   ├── test_ai_insights.py    # AI integration tests
│   ├── test_websocket.py      # WebSocket tests
│   ├── test_api.py            # API endpoint tests
│   └── test_performance.py    # Performance benchmarks
├── frontend/
│   ├── Dashboard.test.tsx     # Dashboard component tests
│   ├── Charts.test.tsx        # Chart component tests
│   ├── hooks.test.tsx         # Custom hooks tests
│   └── integration.test.tsx   # Integration tests
└── e2e/
    ├── dashboard.spec.ts       # E2E dashboard tests
    └── realtime.spec.ts        # E2E real-time tests
```

## Running Tests

### Backend Tests

```bash
# All backend tests
cd backend
pytest

# Specific test file
pytest tests/test_analytics.py

# With coverage
pytest --cov=app --cov-report=html

# Performance tests only
pytest tests/test_performance.py -v
```

### Frontend Tests

```bash
# All frontend tests
cd frontend
npm test

# Watch mode
npm test -- --watch

# Coverage
npm test -- --coverage

# Specific test file
npm test Dashboard.test.tsx
```

### End-to-End Tests

```bash
# Install Playwright
npm install -D @playwright/test

# Run E2E tests
npx playwright test

# Run in headed mode
npx playwright test --headed

# Run specific test
npx playwright test dashboard.spec.ts
```

## Test Categories

### Unit Tests

#### Analytics Engine
- Data aggregation accuracy
- Statistical calculations
- Time series processing
- Anomaly detection algorithms

#### AI Integration
- Prompt generation
- Response parsing
- Error handling
- Fallback mechanisms

#### WebSocket
- Connection establishment
- Message broadcasting
- Reconnection logic
- Performance under load

### Integration Tests

#### API Integration
- Authentication flow
- Data retrieval
- Real-time updates
- Error scenarios

#### Dashboard Integration
- Widget interactions
- Data flow
- State management
- Layout persistence

### End-to-End Tests

#### User Journeys
- Dashboard customization
- Real-time monitoring
- Report generation
- Alert configuration

## Test Data

### Fixtures

```python
@pytest.fixture
def sample_metrics():
    """Generate sample time-series data"""
    return [
        {"timestamp": "2024-01-01T00:00:00Z", "value": 100},
        {"timestamp": "2024-01-01T01:00:00Z", "value": 110},
        # ...
    ]

@pytest.fixture
def mock_ai_response():
    """Mock AI insight response"""
    return {
        "insight": "Increasing trend detected",
        "confidence": 0.85,
        "recommendations": ["Monitor for sustained growth"]
    }
```

### Mocking External Services

```python
@pytest.fixture
def mock_openai(monkeypatch):
    """Mock OpenAI API calls"""
    def mock_completion(*args, **kwargs):
        return {"choices": [{"message": {"content": "Mocked response"}}]}
    
    monkeypatch.setattr("openai.ChatCompletion.create", mock_completion)
```

## Performance Benchmarks

### Backend Performance

```python
@pytest.mark.benchmark
def test_analytics_performance(benchmark):
    """Benchmark analytics calculations"""
    data = generate_large_dataset(10000)
    result = benchmark(calculate_statistics, data)
    assert result["mean"] > 0
```

### Frontend Performance

```typescript
test('Dashboard renders under 100ms', async () => {
  const start = performance.now();
  render(<Dashboard />);
  const end = performance.now();
  
  expect(end - start).toBeLessThan(100);
});
```

## Test Best Practices

### 1. Isolation
```python
def test_isolated_calculation():
    # Each test should be independent
    # Use fixtures for setup
    # Clean up after test
```

### 2. Clear Assertions
```python
def test_anomaly_detection():
    data = [100, 102, 98, 200, 101]  # 200 is anomaly
    anomalies = detect_anomalies(data)
    
    assert len(anomalies) == 1
    assert anomalies[0].index == 3
    assert anomalies[0].confidence > 0.9
```

### 3. Edge Cases
```typescript
test('Chart handles empty data', () => {
  const { container } = render(<LineChart data={[]} />);
  expect(container.querySelector('.empty-state')).toBeInTheDocument();
});
```

### 4. Async Testing
```typescript
test('WebSocket updates data', async () => {
  const { getByTestId } = render(<Dashboard />);
  
  // Simulate WebSocket message
  act(() => {
    mockSocket.emit('data-update', newData);
  });
  
  await waitFor(() => {
    expect(getByTestId('metric-value')).toHaveTextContent('150');
  });
});
```

## Continuous Integration

### GitHub Actions Workflow

```yaml
name: Test Suite

on: [push, pull_request]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          cd backend
          pip install -r requirements.txt
          pip install pytest pytest-cov
      - name: Run tests
        run: |
          cd backend
          pytest --cov=app --cov-report=xml
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  frontend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      - name: Install dependencies
        run: |
          cd frontend
          npm ci
      - name: Run tests
        run: |
          cd frontend
          npm test -- --coverage

  e2e-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Playwright
        run: npx playwright install --with-deps
      - name: Run E2E tests
        run: npx playwright test
```

## Debugging Tests

### Backend Debugging
```bash
# Run with debugging
pytest -s -vv --pdb

# Run specific test with print statements
pytest -k "test_name" -s
```

### Frontend Debugging
```typescript
// Add debug output
test('Complex interaction', () => {
  const { debug } = render(<Component />);
  debug(); // Prints DOM structure
});
```

## Test Reports

### Coverage Reports
- Backend: `htmlcov/index.html`
- Frontend: `coverage/lcov-report/index.html`

### Performance Reports
- Backend: `pytest-benchmark` results
- Frontend: Lighthouse CI reports

Maintain test coverage above 80% for production readiness!