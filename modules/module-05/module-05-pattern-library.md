# Module 05 Pattern Library & Quick Reference

## 🎯 Documentation Patterns

### Pattern: Self-Documenting Code
```python
# Instead of this:
def calc(x, y, z):
    """Calculate result."""
    return (x * y) / z if z != 0 else 0

# Use this:
def calculate_weighted_average(
    value: float, 
    weight: float, 
    total_weight: float
) -> float:
    """Calculate weighted average with safe division.
    
    Args:
        value: The value to be weighted.
        weight: Weight for this value.
        total_weight: Sum of all weights.
        
    Returns:
        Weighted contribution, or 0 if total_weight is 0.
    """
    if total_weight == 0:
        return 0.0
    return (value * weight) / total_weight
```

### Pattern: Documentation-Driven Development
```python
def new_feature():
    """Implement user authentication with OAuth2.
    
    This function will:
    1. Accept OAuth2 credentials
    2. Validate with provider
    3. Create or update user session
    4. Return authentication token
    
    Args:
        provider: OAuth provider name ('google', 'github')
        credentials: OAuth2 credentials object
        
    Returns:
        AuthToken with access and refresh tokens
        
    Raises:
        AuthenticationError: If credentials are invalid
        ProviderError: If provider is unavailable
    """
    # TODO: Implement based on documentation
    raise NotImplementedError("Write the docs first!")
```

## 🔨 Refactoring Patterns

### Pattern: Extract Method
```python
# Before: Long method
def process_order(order_data):
    # Validate
    if not order_data:
        raise ValueError("Empty order")
    if 'items' not in order_data:
        raise ValueError("No items")
    
    # Calculate totals
    subtotal = 0
    for item in order_data['items']:
        subtotal += item['price'] * item['quantity']
    
    # Apply discount
    discount = 0
    if order_data.get('coupon'):
        if order_data['coupon'] == 'SAVE10':
            discount = subtotal * 0.1
        elif order_data['coupon'] == 'SAVE20':
            discount = subtotal * 0.2
    
    # Calculate final
    total = subtotal - discount
    tax = total * 0.08
    final = total + tax
    
    return final

# After: Extracted methods
def process_order(order_data):
    """Process order and return final total."""
    validate_order(order_data)
    subtotal = calculate_subtotal(order_data['items'])
    discount = apply_discount(subtotal, order_data.get('coupon'))
    return calculate_final_total(subtotal, discount)

def validate_order(order_data):
    """Validate order data structure."""
    if not order_data:
        raise ValueError("Empty order")
    if 'items' not in order_data:
        raise ValueError("No items")

def calculate_subtotal(items):
    """Calculate order subtotal from items."""
    return sum(item['price'] * item['quantity'] for item in items)

def apply_discount(subtotal, coupon_code):
    """Apply coupon discount to subtotal."""
    discounts = {'SAVE10': 0.1, 'SAVE20': 0.2}
    return subtotal * discounts.get(coupon_code, 0)

def calculate_final_total(subtotal, discount, tax_rate=0.08):
    """Calculate final total with tax."""
    total = subtotal - discount
    tax = total * tax_rate
    return total + tax
```

### Pattern: Replace Conditional with Polymorphism
```python
# Before: Complex conditionals
def calculate_shipping(order_type, weight, distance):
    if order_type == 'standard':
        base = weight * 0.5
        if distance > 100:
            return base * 1.5
        return base
    elif order_type == 'express':
        base = weight * 1.0
        if distance > 100:
            return base * 2.0
        return base * 1.5
    elif order_type == 'overnight':
        return weight * 3.0 + distance * 0.1

# After: Polymorphic solution
from abc import ABC, abstractmethod

class ShippingStrategy(ABC):
    @abstractmethod
    def calculate(self, weight: float, distance: float) -> float:
        """Calculate shipping cost."""
        pass

class StandardShipping(ShippingStrategy):
    def calculate(self, weight: float, distance: float) -> float:
        base = weight * 0.5
        return base * 1.5 if distance > 100 else base

class ExpressShipping(ShippingStrategy):
    def calculate(self, weight: float, distance: float) -> float:
        base = weight * 1.0
        return base * 2.0 if distance > 100 else base * 1.5

class OvernightShipping(ShippingStrategy):
    def calculate(self, weight: float, distance: float) -> float:
        return weight * 3.0 + distance * 0.1

# Usage
shipping_strategies = {
    'standard': StandardShipping(),
    'express': ExpressShipping(),
    'overnight': OvernightShipping()
}

def calculate_shipping(order_type: str, weight: float, distance: float) -> float:
    strategy = shipping_strategies.get(order_type)
    if not strategy:
        raise ValueError(f"Unknown shipping type: {order_type}")
    return strategy.calculate(weight, distance)
```

## 📊 Quality Measurement Patterns

### Pattern: Quality Gate
```python
class QualityGate:
    """Enforce quality standards before deployment."""
    
    def __init__(self):
        self.checks = [
            ('documentation', self.check_documentation, 80),
            ('test_coverage', self.check_test_coverage, 70),
            ('complexity', self.check_complexity, 10),
            ('duplication', self.check_duplication, 5)
        ]
    
    def validate(self, project_path: Path) -> Tuple[bool, List[str]]:
        """Run all quality checks."""
        failures = []
        
        for check_name, check_func, threshold in self.checks:
            result = check_func(project_path)
            if not self.passes_threshold(result, threshold, check_name):
                failures.append(
                    f"{check_name}: {result} (required: {threshold})"
                )
        
        return len(failures) == 0, failures
```

### Pattern: Continuous Quality Monitoring
```python
class QualityMonitor:
    """Monitor code quality continuously."""
    
    def __init__(self):
        self.metrics_history = []
        self.alert_thresholds = {
            'quality_drop': 10,  # Alert if quality drops by 10%
            'complexity_increase': 2  # Alert if complexity increases by 2
        }
    
    async def monitor(self, filepath: Path):
        """Monitor file for quality changes."""
        current = await self.measure_quality(filepath)
        
        if self.metrics_history:
            previous = self.metrics_history[-1]
            self.check_degradation(previous, current)
        
        self.metrics_history.append(current)
        
    def check_degradation(self, previous, current):
        """Check for quality degradation."""
        quality_drop = previous.quality - current.quality
        if quality_drop > self.alert_thresholds['quality_drop']:
            self.send_alert(f"Quality dropped by {quality_drop}%")
```

## 🤖 AI-Assisted Patterns

### Pattern: Prompt-Driven Documentation
```python
# Copilot prompt pattern for documentation
def complex_algorithm(data: List[float], params: Dict[str, Any]):
    """
    # Generate comprehensive documentation:
    # - Explain the algorithm purpose
    # - Detail each parameter with examples
    # - Describe return value structure
    # - Include 3 usage examples
    # - Add performance considerations
    # - Note any limitations
    """
    # Copilot will generate complete docstring
```

### Pattern: Iterative Refactoring with AI
```python
# Step 1: Identify smell
# Comment: This function is too complex, refactor it

# Step 2: Request specific refactoring
# Copilot: Extract the validation logic into separate method
# Copilot: Use early returns to reduce nesting
# Copilot: Apply DRY principle to repeated code

# Step 3: Validate each change
# Run tests after each refactoring step
```

## 📋 Quick Reference Commands

### Documentation Commands
```bash
# Generate documentation
python -m doc_generator generate <file>

# Check documentation coverage
python -m doc_generator coverage <project>

# Validate docstring format
python -m doc_generator validate --style google <file>

# Generate API docs
python -m doc_generator api --format markdown <module>
```

### Refactoring Commands
```bash
# Analyze code smells
python -m refactoring analyze <file>

# Apply automatic refactoring
python -m refactoring fix --auto <file>

# Interactive refactoring
python -m refactoring fix --interactive <file>

# Generate refactoring report
python -m refactoring report --output report.html <project>
```

### Quality System Commands
```bash
# Start quality monitoring
quality-system start --watch <project>

# Run quality check
quality-system check --threshold 80 <project>

# Generate quality report
quality-system report --format pdf <project>

# View dashboard
quality-system dashboard --port 3000
```

## 🎨 Code Quality Checklist

### Before Committing
- [ ] **Documentation**
  - [ ] All public functions have docstrings
  - [ ] Docstrings include examples
  - [ ] Complex logic has inline comments
  - [ ] README is updated

- [ ] **Code Structure**
  - [ ] No function exceeds 50 lines
  - [ ] Cyclomatic complexity < 10
  - [ ] No duplicate code blocks
  - [ ] Clear variable names

- [ ] **Testing**
  - [ ] Unit tests pass
  - [ ] Test coverage > 80%
  - [ ] Edge cases covered
  - [ ] Integration tests pass

- [ ] **Quality Metrics**
  - [ ] Quality score > 80%
  - [ ] No critical smells
  - [ ] Performance acceptable
  - [ ] Security checks pass

## 🚀 Productivity Tips

### 1. Copilot Shortcuts
```
Alt+\ : Trigger suggestion
Tab   : Accept suggestion
Esc   : Dismiss suggestion
Alt+] : Next suggestion
Alt+[ : Previous suggestion
```

### 2. VS Code Extensions
- **Python Docstring Generator**: Auto-generate docstrings
- **Better Comments**: Highlight important comments
- **GitLens**: See code quality history
- **SonarLint**: Real-time quality feedback

### 3. Pre-commit Hooks
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/psf/black
    rev: 24.3.0
    hooks:
      - id: black
      
  - repo: https://github.com/pycqa/flake8
    rev: 7.0.0
    hooks:
      - id: flake8
        args: ['--max-line-length=88']
        
  - repo: local
    hooks:
      - id: check-docstrings
        name: Check Docstring Coverage
        entry: python -m doc_generator check
        language: system
        types: [python]
```

## 📚 Essential Resources

### Documentation
- [PEP 257 - Docstring Conventions](https://peps.python.org/pep-0257/)
- [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html)
- [Sphinx Documentation](https://www.sphinx-doc.org/)

### Refactoring
- [Refactoring.Guru](https://refactoring.guru/)
- [Martin Fowler's Refactoring Catalog](https://refactoring.com/catalog/)
- [Clean Code by Robert Martin](https://www.oreilly.com/library/view/clean-code/9780136083238/)

### Code Quality
- [Code Climate](https://codeclimate.com/)
- [SonarQube](https://www.sonarqube.org/)
- [Radon - Python Metrics](https://radon.readthedocs.io/)

---

## 🎯 Module 05 Summary

You've mastered:
1. **AI-Powered Documentation** - Generate comprehensive docs automatically
2. **Intelligent Refactoring** - Identify and fix code smells systematically
3. **Quality Automation** - Build systems that enforce standards continuously
4. **Best Practices** - Apply professional patterns in real projects

**Remember**: Quality is not an act, it's a habit. Use these patterns daily!

---

*Keep this reference handy as you continue your journey to code quality mastery!*