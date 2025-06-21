# Exercise 1: Starter Code - Build Your First Pipeline

This directory contains the starter code for Exercise 1. Your task is to complete the CI/CD pipeline implementation.

## 📁 Initial Structure

```
exercise1-starter/
├── .github/
│   └── workflows/
│       └── ci.yml          # TO COMPLETE
├── src/
│   ├── __init__.py
│   └── app.py             # TO COMPLETE
├── tests/
│   ├── __init__.py
│   └── test_app.py        # TO COMPLETE
├── requirements.txt        # PROVIDED
├── requirements-dev.txt    # PROVIDED
├── README.md              # TO COMPLETE
└── .gitignore            # PROVIDED
```

## 📄 Starter Files

### .github/workflows/ci.yml
```yaml
name: CI Pipeline

on:
  # TODO: Add triggers for push to main and pull requests
  push:
    branches: [ main ]

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
    
    # TODO: Add caching for pip packages
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements-dev.txt
    
    # TODO: Add linting with flake8
    # TODO: Add code formatting check with black
    # TODO: Add type checking with mypy
    # TODO: Add job summary

  test:
    name: Run Tests
    runs-on: ubuntu-latest
    # TODO: Make this job depend on lint job
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    # TODO: Complete test job
    # - Set up Python
    # - Cache dependencies  
    # - Install dependencies
    # - Run tests with coverage
    # - Upload coverage report
    # - Add test summary

  # TODO: Add security scanning job
  # TODO: Add build job
```

### src/app.py
```python
import os
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/health')
def health_check():
    """Health check endpoint."""
    # TODO: Return proper health check response with status and service name
    return jsonify({"status": "ok"})

@app.route('/')
def welcome():
    """Welcome endpoint."""
    # TODO: Return welcome message
    return "Hello World!"

# TODO: Add /api/data endpoint that returns JSON with message, version, and timestamp

# TODO: Add error handlers for 404 and 500 errors

if __name__ == '__main__':
    # TODO: Get port from environment variable with default 5000
    # TODO: Add logging
    app.run(host='0.0.0.0', port=5000)
```

### tests/test_app.py
```python
import pytest
from src.app import app

@pytest.fixture
def client():
    """Create a test client for the Flask app."""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_welcome_endpoint(client):
    """Test the welcome endpoint."""
    response = client.get('/')
    # TODO: Add assertions to check status code and response content

# TODO: Add test for health check endpoint
# TODO: Add test for API data endpoint
# TODO: Add test for 404 error handling
# TODO: Add test for content type headers
```

### requirements.txt
```
Flask==3.0.0
gunicorn==21.2.0
```

### requirements-dev.txt
```
-r requirements.txt
pytest==7.4.3
pytest-cov==4.1.0
flake8==6.1.0
black==23.11.0
mypy==1.7.1
bandit==1.7.5
```

### .gitignore
```
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
.venv
*.egg-info/
dist/
build/

# Testing
.coverage
.pytest_cache/
htmlcov/
.tox/

# IDE
.vscode/
.idea/
*.swp

# OS
.DS_Store
Thumbs.db

# CI/CD
*.log
bandit-report.json
```

### README.md
```markdown
# CI/CD Workshop Demo

<!-- TODO: Add build status badge here -->

## Description

<!-- TODO: Add project description -->

## Installation

```bash
# TODO: Add installation instructions
```

## Running Tests

```bash
# TODO: Add test commands
```

## CI/CD Pipeline

<!-- TODO: Describe what your pipeline does -->
```

## 📝 Tasks to Complete

### 1. Complete the Flask Application (src/app.py)
- [ ] Implement proper health check response
- [ ] Add welcome message
- [ ] Create /api/data endpoint
- [ ] Add error handlers
- [ ] Configure port from environment
- [ ] Add logging

### 2. Write Comprehensive Tests (tests/test_app.py)
- [ ] Complete welcome endpoint test
- [ ] Add health check test
- [ ] Add API data endpoint test
- [ ] Add 404 error test
- [ ] Add content type test

### 3. Complete CI/CD Pipeline (.github/workflows/ci.yml)
- [ ] Add workflow triggers
- [ ] Implement caching
- [ ] Add linting steps
- [ ] Complete test job
- [ ] Add security scanning
- [ ] Create build job
- [ ] Add job summaries

### 4. Update Documentation (README.md)
- [ ] Add build status badge
- [ ] Write project description
- [ ] Document installation steps
- [ ] Explain test execution
- [ ] Describe CI/CD pipeline

## 💡 Hints

1. **For the Flask app:**
   - Use `jsonify()` for JSON responses
   - Include timestamps with `datetime.utcnow().isoformat()`
   - Get environment variables with `os.environ.get('VAR', 'default')`

2. **For tests:**
   - Check both status codes and response content
   - Use `json.loads()` to parse JSON responses
   - Test error scenarios too

3. **For the workflow:**
   - Use `needs:` to create job dependencies
   - Matrix strategy can test multiple Python versions
   - `$GITHUB_STEP_SUMMARY` for job summaries
   - Use `if: always()` to upload artifacts even on failure

4. **For caching:**
   ```yaml
   key: ${{ runner.os }}-pip-${{ hashFiles('requirements-dev.txt') }}
   ```

## 🎯 Success Criteria

Your implementation is complete when:
- [ ] All tests pass locally and in CI
- [ ] Code passes linting and formatting checks
- [ ] Security scan finds no critical issues
- [ ] Build artifacts are created successfully
- [ ] README has a working status badge
- [ ] Pipeline provides useful feedback

## 🚀 Getting Started

1. Copy this starter code to your repository
2. Create a virtual environment and install dependencies
3. Start with the Flask application
4. Write tests for your implementation
5. Build the CI/CD pipeline incrementally
6. Test locally before pushing

Good luck! 🍀