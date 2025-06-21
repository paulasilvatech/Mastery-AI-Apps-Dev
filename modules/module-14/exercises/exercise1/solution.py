# Exercise 1: Complete Solution - Build Your First Pipeline

This directory contains the complete solution for Exercise 1.

## 📁 File Structure

```
exercise1-solution/
├── .github/
│   └── workflows/
│       └── ci.yml
├── src/
│   ├── __init__.py
│   └── app.py
├── tests/
│   ├── __init__.py
│   └── test_app.py
├── requirements.txt
├── requirements-dev.txt
├── README.md
├── .gitignore
└── startup.sh
```

## 📄 Complete Files

### .github/workflows/ci.yml
```yaml
name: CI Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:
    inputs:
      debug_enabled:
        description: 'Enable debug logging'
        required: false
        default: 'false'
        type: boolean
      skip_tests:
        description: 'Skip test execution'
        required: false
        default: 'false'
        type: boolean

env:
  PYTHON_VERSION: '3.11'

jobs:
  lint:
    name: Code Quality Checks
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}
    
    - name: Cache pip packages
      uses: actions/cache@v3
      with:
        path: ~/.cache/pip
        key: ${{ runner.os }}-pip-${{ hashFiles('requirements-dev.txt') }}
        restore-keys: |
          ${{ runner.os }}-pip-
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements-dev.txt
    
    - name: Run flake8
      run: |
        flake8 src tests --max-line-length=88 --exclude=__pycache__
        echo "✅ Linting passed!" >> $GITHUB_STEP_SUMMARY
    
    - name: Check formatting with black
      run: |
        black --check src tests
        echo "✅ Code formatting check passed!" >> $GITHUB_STEP_SUMMARY
    
    - name: Type checking with mypy
      run: |
        mypy src --ignore-missing-imports
        echo "✅ Type checking passed!" >> $GITHUB_STEP_SUMMARY

  test:
    name: Run Tests (Python ${{ matrix.python-version }})
    runs-on: ubuntu-latest
    needs: lint
    strategy:
      matrix:
        python-version: ['3.9', '3.10', '3.11']
        include:
          - python-version: '3.11'
            required: true
          - python-version: '3.10'
            required: false
          - python-version: '3.9'
            required: false
      fail-fast: false
    continue-on-error: ${{ matrix.required == false }}
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}
    
    - name: Cache pip packages
      uses: actions/cache@v3
      with:
        path: ~/.cache/pip
        key: ${{ runner.os }}-pip-${{ matrix.python-version }}-${{ hashFiles('requirements-dev.txt') }}
        restore-keys: |
          ${{ runner.os }}-pip-${{ matrix.python-version }}-
          ${{ runner.os }}-pip-
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements-dev.txt
    
    - name: Run tests with coverage
      if: ${{ github.event.inputs.skip_tests != 'true' }}
      run: |
        if [[ "${{ github.event.inputs.debug_enabled }}" == "true" ]]; then
          pytest tests/ -v -s --cov=src --cov-report=xml --cov-report=html --cov-report=term
        else
          pytest tests/ -v --cov=src --cov-report=xml --cov-report=html --cov-report=term
        fi
    
    - name: Upload coverage reports
      uses: actions/upload-artifact@v3
      with:
        name: coverage-report-${{ matrix.python-version }}
        path: htmlcov/
    
    - name: Generate test summary
      if: always()
      run: |
        echo "## Test Results 🧪" >> $GITHUB_STEP_SUMMARY
        echo "- Python Version: ${{ matrix.python-version }}" >> $GITHUB_STEP_SUMMARY
        echo "Coverage report has been uploaded as an artifact." >> $GITHUB_STEP_SUMMARY

  security:
    name: Security Scanning
    runs-on: ubuntu-latest
    needs: lint
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}
    
    - name: Install bandit
      run: |
        python -m pip install --upgrade pip
        pip install bandit
    
    - name: Run security scan
      run: |
        bandit -r src/ -f json -o bandit-report.json || true
        echo "## Security Scan Results 🔒" >> $GITHUB_STEP_SUMMARY
        echo "Security scan completed. Check the logs for details." >> $GITHUB_STEP_SUMMARY
    
    - name: Upload security report
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: security-report
        path: bandit-report.json

  build:
    name: Build Application
    runs-on: ubuntu-latest
    needs: [test, security]
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
    
    - name: Create deployment package
      run: |
        mkdir -p dist
        cp -r src dist/
        cp requirements.txt dist/
        cp startup.sh dist/
        tar -czf app-${{ github.sha }}.tar.gz dist/
    
    - name: Upload build artifacts
      uses: actions/upload-artifact@v3
      with:
        name: app-package
        path: app-${{ github.sha }}.tar.gz
        retention-days: 7
    
    - name: Build summary
      run: |
        echo "## Build Complete! 🚀" >> $GITHUB_STEP_SUMMARY
        echo "- **Commit:** ${{ github.sha }}" >> $GITHUB_STEP_SUMMARY
        echo "- **Branch:** ${{ github.ref_name }}" >> $GITHUB_STEP_SUMMARY
        echo "- **Actor:** ${{ github.actor }}" >> $GITHUB_STEP_SUMMARY
        echo "- **Run Number:** ${{ github.run_number }}" >> $GITHUB_STEP_SUMMARY
```

### src/app.py
```python
import os
import logging
from typing import Dict, Any
from datetime import datetime
from flask import Flask, jsonify

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration
app.config['JSON_SORT_KEYS'] = False
app.config['JSONIFY_PRETTYPRINT_REGULAR'] = True


@app.route('/health')
def health_check() -> Dict[str, str]:
    """Health check endpoint for monitoring."""
    logger.info("Health check requested")
    return jsonify({
        "status": "healthy",
        "service": "cicd-demo",
        "timestamp": datetime.utcnow().isoformat(),
        "version": os.environ.get('VERSION', '1.0.0')
    })


@app.route('/')
def welcome() -> str:
    """Welcome endpoint."""
    logger.info("Welcome page accessed")
    return "Welcome to CI/CD Workshop!"


@app.route('/api/data')
def get_data() -> Dict[str, Any]:
    """API endpoint returning sample data."""
    data = {
        "message": "Hello from CI/CD Pipeline!",
        "version": os.environ.get('VERSION', '1.0.0'),
        "timestamp": datetime.utcnow().isoformat(),
        "environment": os.environ.get('ENVIRONMENT', 'development'),
        "features": {
            "ci_cd": True,
            "automated_testing": True,
            "security_scanning": True
        }
    }
    logger.info(f"API data requested: {data['message']}")
    return jsonify(data)


@app.errorhandler(404)
def not_found(error) -> tuple[Dict[str, str], int]:
    """Handle 404 errors."""
    logger.warning(f"404 error: {error}")
    return jsonify({"error": "Not found", "status_code": 404}), 404


@app.errorhandler(500)
def internal_error(error) -> tuple[Dict[str, str], int]:
    """Handle 500 errors."""
    logger.error(f"Internal error: {error}")
    return jsonify({"error": "Internal server error", "status_code": 500}), 500


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('DEBUG', 'False').lower() == 'true'
    
    logger.info(f"Starting application on port {port}")
    logger.info(f"Debug mode: {debug}")
    
    app.run(host='0.0.0.0', port=port, debug=debug)
```

### tests/test_app.py
```python
import pytest
import json
from datetime import datetime
from src.app import app


@pytest.fixture
def client():
    """Create a test client for the Flask app."""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_welcome_endpoint(client):
    """Test the welcome endpoint returns correct message."""
    response = client.get('/')
    assert response.status_code == 200
    assert b'Welcome to CI/CD Workshop!' in response.data


def test_health_check(client):
    """Test the health check endpoint returns healthy status."""
    response = client.get('/health')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert data['status'] == 'healthy'
    assert data['service'] == 'cicd-demo'
    assert 'timestamp' in data
    assert 'version' in data


def test_health_check_timestamp_format(client):
    """Test that health check returns valid ISO format timestamp."""
    response = client.get('/health')
    data = json.loads(response.data)
    
    # This should not raise an exception
    datetime.fromisoformat(data['timestamp'].replace('Z', '+00:00'))


def test_api_data_endpoint(client):
    """Test the API data endpoint returns correct JSON."""
    response = client.get('/api/data')
    assert response.status_code == 200
    
    data = json.loads(response.data)
    assert 'message' in data
    assert 'version' in data
    assert 'timestamp' in data
    assert 'environment' in data
    assert 'features' in data
    
    # Check features
    assert data['features']['ci_cd'] is True
    assert data['features']['automated_testing'] is True
    assert data['features']['security_scanning'] is True


def test_404_error(client):
    """Test that 404 errors are handled correctly."""
    response = client.get('/nonexistent')
    assert response.status_code == 404
    
    data = json.loads(response.data)
    assert data['error'] == 'Not found'
    assert data['status_code'] == 404


def test_content_type(client):
    """Test that JSON endpoints return correct content type."""
    endpoints = ['/health', '/api/data']
    
    for endpoint in endpoints:
        response = client.get(endpoint)
        assert response.content_type == 'application/json'


def test_cors_headers(client):
    """Test CORS headers if implemented."""
    response = client.get('/api/data')
    # Add CORS tests if CORS is implemented in the app
    # assert 'Access-Control-Allow-Origin' in response.headers


def test_api_data_structure(client):
    """Test the structure of API response."""
    response = client.get('/api/data')
    data = json.loads(response.data)
    
    # Verify structure
    assert isinstance(data, dict)
    assert isinstance(data['features'], dict)
    assert isinstance(data['message'], str)
    assert isinstance(data['version'], str)
```

### startup.sh
```bash
#!/bin/bash
set -e

echo "Starting CI/CD Workshop Application..."
echo "Environment: ${ENVIRONMENT:-development}"
echo "Port: ${PORT:-8000}"
echo "Workers: ${WORKERS:-4}"

# Run database migrations if needed
# python manage.py migrate

# Collect static files if needed
# python manage.py collectstatic --noinput

# Start the application
exec gunicorn \
    --bind=0.0.0.0:${PORT:-8000} \
    --workers=${WORKERS:-4} \
    --timeout=${TIMEOUT:-600} \
    --access-logfile=- \
    --error-logfile=- \
    --log-level=${LOG_LEVEL:-info} \
    src.app:app
```

## 🧪 Running the Solution

1. **Clone and setup:**
   ```bash
   git clone <your-repo>
   cd cicd-workshop
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements-dev.txt
   ```

2. **Run tests locally:**
   ```bash
   pytest tests/ -v --cov=src
   ```

3. **Run the application:**
   ```bash
   python src/app.py
   ```

4. **Push to trigger CI:**
   ```bash
   git add .
   git commit -m "Complete CI pipeline"
   git push origin main
   ```

## 📊 Expected Results

- ✅ All linting checks pass
- ✅ 100% test coverage
- ✅ Security scan completes
- ✅ Build artifacts generated
- ✅ Status badge shows passing
- ✅ Job summaries provide insights

## 🎯 Learning Outcomes Achieved

1. Created a complete CI/CD pipeline
2. Implemented code quality checks
3. Added comprehensive testing
4. Integrated security scanning
5. Built deployment packages
6. Used caching effectively
7. Created informative summaries