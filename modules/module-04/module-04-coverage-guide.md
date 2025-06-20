# Coverage Best Practices Guide

## 📊 Understanding Code Coverage

### What is Code Coverage?

Code coverage measures how much of your code is executed during tests:
- **Line Coverage**: Which lines were executed
- **Branch Coverage**: Which decision paths were taken
- **Function Coverage**: Which functions were called
- **Statement Coverage**: Which statements were executed

### Coverage is a Tool, Not a Goal

**Remember**: 100% coverage ≠ bug-free code

```python
# This has 100% coverage but is still wrong
def add(a, b):
    return a - b  # Bug: should be addition

def test_add():
    assert add(2, 2) == 0  # Test passes, 100% coverage, but wrong!
```

## 🚀 Getting Started with Coverage

### Installation and Basic Usage

```bash
# Install coverage tools
pip install pytest-cov coverage

# Run tests with coverage
pytest --cov=myproject tests/

# Generate HTML report
pytest --cov=myproject --cov-report=html tests/

# View report
open htmlcov/index.html  # macOS
xdg-open htmlcov/index.html  # Linux
start htmlcov/index.html  # Windows
```

### Configuration File (.coveragerc)

```ini
# .coveragerc or pyproject.toml
[run]
source = src
omit = 
    */tests/*
    */venv/*
    */__pycache__/*
    */migrations/*
    setup.py
    */config.py

[report]
precision = 2
skip_empty = True
show_missing = True
exclude_lines =
    # Don't complain about missing debug-only code
    def __repr__
    if self\.debug
    
    # Don't complain if tests don't hit defensive assertion code
    raise AssertionError
    raise NotImplementedError
    
    # Don't complain if non-runnable code isn't run
    if 0:
    if __name__ == .__main__.:
    
    # Type checking
    if TYPE_CHECKING:
    @overload
    
    # Abstract methods
    @abstractmethod

[html]
directory = htmlcov
title = My Project Coverage Report

[xml]
output = coverage.xml
```

## 📈 Achieving Meaningful Coverage

### 1. Focus on Critical Paths First

```python
# Priority 1: Business logic
class BankAccount:
    def withdraw(self, amount):
        """Critical: Must be thoroughly tested."""
        if amount <= 0:
            raise ValueError("Amount must be positive")
        if amount > self.balance:
            raise InsufficientFundsError()
        self.balance -= amount
        return self.balance

# Priority 2: Data validation
def validate_email(email):
    """Important: Prevents bad data."""
    if not re.match(r'^[^@]+@[^@]+\.[^@]+$', email):
        raise ValueError("Invalid email")
    return True

# Priority 3: Simple getters (lower priority)
def get_name(self):
    """Less critical for coverage."""
    return self.name
```

### 2. Test All Branches

```python
# Code with multiple branches
def categorize_age(age):
    if age < 0:
        return "Invalid"
    elif age < 13:
        return "Child"
    elif age < 20:
        return "Teenager"
    elif age < 65:
        return "Adult"
    else:
        return "Senior"

# Tests covering all branches
@pytest.mark.parametrize("age,expected", [
    (-1, "Invalid"),      # Branch 1
    (0, "Child"),         # Branch 2, edge case
    (12, "Child"),        # Branch 2
    (13, "Teenager"),     # Branch 3, edge case
    (19, "Teenager"),     # Branch 3
    (20, "Adult"),        # Branch 4, edge case
    (64, "Adult"),        # Branch 4
    (65, "Senior"),       # Branch 5, edge case
    (100, "Senior"),      # Branch 5
])
def test_categorize_age_all_branches(age, expected):
    assert categorize_age(age) == expected
```

### 3. Cover Error Paths

```python
# Function with error handling
def divide_numbers(a, b):
    try:
        result = a / b
        logging.info(f"Division successful: {a}/{b} = {result}")
        return result
    except ZeroDivisionError:
        logging.error(f"Division by zero attempted: {a}/{b}")
        return None
    except TypeError as e:
        logging.error(f"Type error in division: {e}")
        raise

# Test all paths including errors
def test_divide_success():
    assert divide_numbers(10, 2) == 5

def test_divide_by_zero():
    assert divide_numbers(10, 0) is None

def test_divide_type_error():
    with pytest.raises(TypeError):
        divide_numbers("10", 2)
```

### 4. Use Coverage to Find Dead Code

```python
# coverage run --branch -m pytest
# coverage report -m

# Output might show:
# module.py     85%   23-25, 45->47

# Lines 23-25 are never executed (dead code)
def process_data(data):
    if isinstance(data, list):
        return process_list(data)
    elif isinstance(data, dict):
        return process_dict(data)
    else:
        # Lines 23-25: Never reached, maybe remove?
        print("Unknown type")
        log_error("Unknown data type")
        return None
```

## 🎯 Coverage Strategies

### 1. Incremental Coverage Improvement

```python
# Start with the most important modules
# coverage.py

import subprocess

def check_coverage(module, threshold):
    """Check if module meets coverage threshold."""
    result = subprocess.run(
        f"pytest --cov={module} --cov-report=term",
        shell=True,
        capture_output=True,
        text=True
    )
    
    # Parse coverage percentage
    for line in result.stdout.split('\n'):
        if module in line and '%' in line:
            coverage = int(line.split()[-1].rstrip('%'))
            if coverage < threshold:
                print(f"❌ {module}: {coverage}% (need {threshold}%)")
                return False
            else:
                print(f"✅ {module}: {coverage}%")
                return True
    return False

# Set incremental goals
modules = {
    'core': 95,      # Critical modules need high coverage
    'utils': 85,     # Utility modules
    'models': 90,    # Data models
    'api': 85,       # API endpoints
}

for module, threshold in modules.items():
    check_coverage(module, threshold)
```

### 2. Coverage by Feature

```python
# Mark tests by feature
@pytest.mark.feature_auth
def test_login():
    pass

@pytest.mark.feature_payment
def test_process_payment():
    pass

# Run coverage by feature
# pytest -m feature_auth --cov=auth --cov-report=term
# pytest -m feature_payment --cov=payment --cov-report=term
```

### 3. Mutation Testing (Beyond Coverage)

```python
# pip install mutmut

# Original code
def is_adult(age):
    return age >= 18

# Mutation testing changes the code:
# return age > 18  (>= to >)
# return age >= 17 (18 to 17)

# Good tests should catch these mutations
def test_is_adult():
    assert is_adult(18) is True  # Catches >= to > mutation
    assert is_adult(17) is False  # Catches 18 to 17 mutation
    assert is_adult(19) is True
```

## 📊 Coverage Reports

### 1. Terminal Report

```bash
pytest --cov=src --cov-report=term-missing

# Output:
# Name                Stmts   Miss  Cover   Missing
# -------------------------------------------------
# src/__init__.py         2      0   100%
# src/calculator.py      45      5    89%   23-27
# src/database.py        78      0   100%
# src/utils.py           34      2    94%   45, 67
# -------------------------------------------------
# TOTAL                 159      7    96%
```

### 2. HTML Report Analysis

```python
# Generate detailed HTML report
pytest --cov=src --cov-report=html --cov-report=term

# Key features in HTML report:
# - Click on files to see line-by-line coverage
# - Red lines = not covered
# - Yellow lines = partially covered (branch)
# - Green lines = fully covered
```

### 3. XML Report for CI/CD

```bash
# Generate XML for CI tools
pytest --cov=src --cov-report=xml

# Use in GitHub Actions
# - name: Upload coverage reports to Codecov
#   uses: codecov/codecov-action@v3
#   with:
#     file: ./coverage.xml
```

### 4. Coverage Badges

```python
# Generate coverage badge
# pip install coverage-badge

coverage-badge -o coverage.svg

# Add to README.md
# ![Coverage](coverage.svg)
```

## 🚧 Common Coverage Pitfalls

### 1. Testing Only Happy Paths

```python
# ❌ Incomplete testing
def test_user_creation():
    user = User("john", "john@example.com")
    assert user.name == "john"

# ✅ Complete testing
def test_user_creation_success():
    user = User("john", "john@example.com")
    assert user.name == "john"

def test_user_creation_invalid_email():
    with pytest.raises(ValueError):
        User("john", "invalid-email")

def test_user_creation_empty_name():
    with pytest.raises(ValueError):
        User("", "john@example.com")
```

### 2. Ignoring Integration Boundaries

```python
# This might have 100% unit test coverage
class EmailService:
    def send_email(self, to, subject, body):
        # Complex SMTP logic
        pass

# But still fail in integration
def test_integration():
    """Test actual email sending with real SMTP."""
    service = EmailService()
    # Test with real configuration
    result = service.send_email(
        "test@example.com",
        "Test Subject",
        "Test Body"
    )
    assert result.status_code == 250
```

### 3. Coverage Without Assertions

```python
# ❌ Coverage without verification
def test_process_data():
    data = [1, 2, 3]
    result = process_data(data)  # 100% coverage
    # But no assertions!

# ✅ Meaningful test
def test_process_data():
    data = [1, 2, 3]
    result = process_data(data)
    assert result == [2, 4, 6]
    assert len(result) == len(data)
    assert all(r == d * 2 for r, d in zip(result, data))
```

## 🎨 Advanced Coverage Techniques

### 1. Context-Based Coverage

```python
# Track coverage by test context
# pytest --cov=src --cov-context=test

# Shows which tests cover which lines
# Useful for identifying redundant tests
```

### 2. Differential Coverage

```python
# Check coverage of changed files only
import subprocess

def get_changed_files():
    """Get list of changed Python files."""
    result = subprocess.run(
        "git diff --name-only HEAD~1 HEAD | grep '\.py$'",
        shell=True,
        capture_output=True,
        text=True
    )
    return result.stdout.strip().split('\n')

# Run coverage only on changed files
changed = get_changed_files()
if changed:
    files = " ".join(changed)
    subprocess.run(f"pytest --cov={files}", shell=True)
```

### 3. Coverage Trends

```python
# Track coverage over time
import json
from datetime import datetime

def record_coverage():
    """Record coverage metrics over time."""
    # Get current coverage
    result = subprocess.run(
        "coverage json",
        shell=True,
        capture_output=True
    )
    
    coverage_data = json.loads(result.stdout)
    percent = coverage_data['totals']['percent_covered']
    
    # Append to history
    with open('coverage_history.json', 'r+') as f:
        history = json.load(f)
        history.append({
            'date': datetime.now().isoformat(),
            'coverage': percent,
            'commit': get_current_commit()
        })
        f.seek(0)
        json.dump(history, f, indent=2)
```

## 📋 Coverage Checklist

### For Each Module

- [ ] Line coverage > 80%
- [ ] Branch coverage > 75%
- [ ] All public methods tested
- [ ] All error paths tested
- [ ] Edge cases covered
- [ ] Integration points tested

### For the Project

- [ ] Overall coverage > 85%
- [ ] Critical modules > 95%
- [ ] No untested public APIs
- [ ] Coverage trend improving
- [ ] CI/CD coverage gates set
- [ ] Coverage reports accessible

## 🤖 Using Copilot for Coverage

### Generate Missing Tests

```python
# This function has 60% coverage
# Generate tests for the uncovered branches:
# - Empty list case
# - List with None values  
# - List with negative numbers
def calculate_average(numbers):
    if not numbers:
        return 0
    
    valid_numbers = [n for n in numbers if n is not None and n >= 0]
    if not valid_numbers:
        return 0
        
    return sum(valid_numbers) / len(valid_numbers)
```

### Identify Coverage Gaps

```python
# Analyze this code and tell me what test cases are missing
# for 100% branch coverage
def process_order(order):
    if order.status == 'pending':
        if order.payment_verified:
            if inventory.has_stock(order.items):
                order.status = 'confirmed'
                inventory.reserve(order.items)
            else:
                order.status = 'backorder'
        else:
            order.status = 'payment_failed'
    elif order.status == 'confirmed':
        if order.shipped:
            order.status = 'completed'
    
    return order
```

---

## 🎯 Remember

> "Coverage is a useful metric for finding untested code, but it's a terrible metric for measuring test quality. Aim for thoughtful tests that verify behavior, not just lines executed."

Focus on:
- **Behavior coverage** over line coverage
- **Critical paths** over trivial code  
- **Edge cases** over happy paths
- **Integration** over isolation
- **Maintainability** over metrics