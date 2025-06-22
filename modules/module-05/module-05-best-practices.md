# Best Practices for Documentation and Code Quality

## 📚 Documentation Best Practices

### 1. Documentation-First Development
**Practice**: Write documentation before implementing code.

```python
# GOOD: Document first, implement second
def calculate_discount(price: float, customer_type: str) -> float:
    """
    Calculate discount based on customer type.
    
    Business Rules:
    - VIP customers: 20% discount
    - Regular customers: 10% discount
    - New customers: 5% discount
    
    Args:
        price: Original price before discount
        customer_type: One of 'vip', 'regular', 'new'
        
    Returns:
        Final price after discount
        
    Raises:
        ValueError: If customer_type is invalid
        
    Examples:
        >>> calculate_discount(100.0, 'vip')
        80.0
        >>> calculate_discount(100.0, 'new')
        95.0
    """
    # Implementation follows documentation
    discounts = {'vip': 0.20, 'regular': 0.10, 'new': 0.05}
    if customer_type not in discounts:
        raise ValueError(f"Invalid customer type: {customer_type}")
    return price * (1 - discounts[customer_type])
```

### 2. Living Documentation
**Practice**: Keep documentation synchronized with code.

```python
# Use tools to verify documentation accuracy
class DocumentationValidator:
    """Ensures documentation stays current."""
    
    def validate_examples(self, module):
        """Run all docstring examples and verify outputs."""
        import doctest
        return doctest.testmod(module)
    
    def check_parameters(self, func):
        """Verify all parameters are documented."""
        import inspect
        sig = inspect.signature(func)
        doc = func.__doc__ or ""
        
        for param in sig.parameters:
            if param != 'self' and param not in doc:
                raise ValueError(f"Parameter {param} not documented")
```

### 3. Audience-Specific Documentation
**Practice**: Write for your audience.

```python
# Developer documentation
def merge_sort(arr: List[int]) -> List[int]:
    """
    Implement merge sort algorithm.
    
    Time Complexity: O(n log n)
    Space Complexity: O(n)
    
    Implementation uses divide-and-conquer approach.
    """

# End-user documentation
def sort_items(items: List[str]) -> List[str]:
    """
    Sort items alphabetically.
    
    This function arranges your items in alphabetical order,
    making them easier to find and organize.
    
    Example:
        If you have ['banana', 'apple', 'cherry'],
        you'll get ['apple', 'banana', 'cherry'].
    """
```

## 🔨 Refactoring Best Practices

### 1. Small, Incremental Changes
**Practice**: Refactor in small steps with tests.

```python
# Step 1: Extract validation
def process_order(order_data):
    # Original: everything in one function
    if not order_data:
        raise ValueError("Empty order")
    if order_data['quantity'] <= 0:
        raise ValueError("Invalid quantity")
    # ... more code

# Refactored: Extract validation
def validate_order(order_data):
    """Validate order data."""
    if not order_data:
        raise ValueError("Empty order")
    if order_data['quantity'] <= 0:
        raise ValueError("Invalid quantity")

def process_order(order_data):
    validate_order(order_data)  # Use extracted function
    # ... rest of processing
```

### 2. Test Before Refactoring
**Practice**: Ensure tests pass before and after.

```python
# Write tests first
def test_calculate_total():
    """Test calculation before refactoring."""
    items = [{'price': 10, 'quantity': 2}, {'price': 5, 'quantity': 3}]
    assert calculate_total(items) == 35

# Now safe to refactor
def calculate_total(items):
    # Original: imperative style
    # total = 0
    # for item in items:
    #     total += item['price'] * item['quantity']
    # return total
    
    # Refactored: functional style
    return sum(item['price'] * item['quantity'] for item in items)
```

### 3. Refactor by Pattern
**Practice**: Apply known refactoring patterns.

```python
# Pattern: Replace Conditional with Polymorphism
# Before:
def calculate_shipping(order_type, weight):
    if order_type == 'standard':
        return weight * 1.0
    elif order_type == 'express':
        return weight * 2.5
    elif order_type == 'overnight':
        return weight * 5.0

# After:
from abc import ABC, abstractmethod

class ShippingStrategy(ABC):
    @abstractmethod
    def calculate(self, weight: float) -> float:
        pass

class StandardShipping(ShippingStrategy):
    def calculate(self, weight: float) -> float:
        return weight * 1.0

class ExpressShipping(ShippingStrategy):
    def calculate(self, weight: float) -> float:
        return weight * 2.5

# Usage
shipping = ExpressShipping()
cost = shipping.calculate(10.0)
```

## 📊 Code Quality Best Practices

### 1. Continuous Measurement
**Practice**: Track metrics over time.

```python
# quality_tracker.py
class QualityTracker:
    """Track quality metrics continuously."""
    
    def __init__(self):
        self.metrics_history = []
    
    def record_metrics(self, filepath: Path):
        """Record current metrics."""
        metrics = {
            'timestamp': datetime.now(),
            'complexity': self.measure_complexity(filepath),
            'coverage': self.measure_coverage(filepath),
            'smells': self.count_smells(filepath)
        }
        self.metrics_history.append(metrics)
        
        # Alert on degradation
        if self.is_degrading():
            self.send_alert("Quality degrading!")
```

### 2. Automate Quality Checks
**Practice**: Integrate quality checks in CI/CD.

```yaml
# .github/workflows/quality.yml
name: Code Quality
on: [push, pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Quality Checks
        run: |
          # Documentation coverage
          python -m quality_system check-docs --min-coverage 80
          
          # Code complexity
          python -m quality_system check-complexity --max 10
          
          # Test coverage
          pytest --cov=. --cov-fail-under=70
          
      - name: Generate Report
        if: always()
        run: |
          python -m quality_system report --format html
          
      - name: Upload Report
        uses: actions/upload-artifact@v3
        with:
          name: quality-report
          path: quality-report.html
```

### 3. Team Standards
**Practice**: Establish and enforce team standards.

```python
# team_standards.py
TEAM_STANDARDS = {
    "max_function_length": 50,
    "max_complexity": 10,
    "min_doc_coverage": 90,
    "required_sections": ["Args", "Returns", "Examples"],
    "naming_conventions": {
        "functions": "snake_case",
        "classes": "PascalCase",
        "constants": "UPPER_SNAKE_CASE"
    }
}

def enforce_standards(code: str) -> List[Violation]:
    """Enforce team coding standards."""
    violations = []
    
    # Check all standards
    for standard, value in TEAM_STANDARDS.items():
        if not meets_standard(code, standard, value):
            violations.append(
                Violation(standard, value, get_actual(code, standard))
            )
    
    return violations
```

## 🤖 AI-Assisted Best Practices

### 1. Prompt Engineering for Quality
**Practice**: Use specific prompts for quality improvements.

```python
# Effective prompts for documentation
"""
Generate comprehensive documentation for this function:
- Include all parameters with types and descriptions
- Add return value documentation
- Include at least 2 usage examples
- Document possible exceptions
- Add performance notes if relevant
"""

# Effective prompts for refactoring
"""
Refactor this code to:
- Reduce cyclomatic complexity below 5
- Extract duplicate logic into reusable functions
- Apply appropriate design patterns
- Maintain backward compatibility
- Include tests for refactored code
"""
```

### 2. Review AI Suggestions
**Practice**: Always review and validate AI-generated code.

```python
# Process for AI-assisted development
def ai_assisted_refactoring(code: str) -> str:
    """Safe AI-assisted refactoring process."""
    # 1. Generate suggestions
    suggestions = get_ai_suggestions(code)
    
    # 2. Validate suggestions
    for suggestion in suggestions:
        # Check syntax
        if not is_valid_python(suggestion):
            continue
            
        # Run tests
        if not passes_tests(suggestion):
            continue
            
        # Check complexity
        if complexity(suggestion) > complexity(code):
            continue
            
        # Apply if all checks pass
        code = apply_suggestion(suggestion)
    
    return code
```

## 🚀 Production Best Practices

### 1. Gradual Rollout
**Practice**: Deploy quality improvements gradually.

```python
# Feature flags for quality features
class QualityFeatures:
    """Control quality feature rollout."""
    
    def __init__(self):
        self.features = {
            "auto_documentation": 0.1,  # 10% of projects
            "auto_refactoring": 0.0,    # Not enabled yet
            "ml_predictions": 0.5       # 50% of projects
        }
    
    def is_enabled(self, feature: str, project_id: str) -> bool:
        """Check if feature enabled for project."""
        if feature not in self.features:
            return False
            
        # Use consistent hashing for gradual rollout
        hash_value = hash(f"{feature}:{project_id}") % 100
        return hash_value < self.features[feature] * 100
```

### 2. Monitor Impact
**Practice**: Track the impact of quality improvements.

```python
# Impact tracking
class QualityImpactTracker:
    """Track impact of quality improvements."""
    
    def track_before_after(self, change: QualityChange):
        """Track metrics before and after change."""
        before_metrics = {
            "bugs_per_release": self.count_bugs(),
            "time_to_fix": self.avg_fix_time(),
            "code_review_time": self.avg_review_time()
        }
        
        # Apply change
        change.apply()
        
        # Measure after
        after_metrics = {
            "bugs_per_release": self.count_bugs(),
            "time_to_fix": self.avg_fix_time(),
            "code_review_time": self.avg_review_time()
        }
        
        # Calculate improvement
        improvement = self.calculate_improvement(
            before_metrics, 
            after_metrics
        )
        
        return improvement
```

## 📋 Quality Checklist

Before committing code, ensure:

### Documentation
- [ ] All public functions have docstrings
- [ ] Complex logic has inline comments
- [ ] README is up to date
- [ ] API changes are documented
- [ ] Examples are tested and working

### Code Quality
- [ ] No functions exceed 50 lines
- [ ] Cyclomatic complexity < 10
- [ ] No duplicate code blocks
- [ ] Meaningful variable names
- [ ] Proper error handling

### Testing
- [ ] Unit tests for new code
- [ ] Integration tests updated
- [ ] Edge cases covered
- [ ] Performance tests if needed
- [ ] Documentation examples tested

### Refactoring
- [ ] Tests pass before and after
- [ ] No functionality changed
- [ ] Code is simpler/clearer
- [ ] Performance not degraded
- [ ] Team standards met

## 🎯 Remember

1. **Quality is a journey, not a destination**
2. **Automate what you can, review what you must**
3. **Documentation is for future you**
4. **Refactor continuously, not eventually**
5. **Measure everything, improve systematically**

---

*"Code quality is not about perfection, it's about continuous improvement."*