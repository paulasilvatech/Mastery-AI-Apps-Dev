# Exercise 2: Prompt Pattern Library - Part 3

## 🎯 Part 3: Advanced Pattern Techniques (15-20 minutes)

In this final part, you'll learn advanced techniques including pattern composition, context-aware patterns, effectiveness testing, and metrics tracking.

## 📚 Advanced Pattern Concepts

### Key Advanced Features:
1. **Pattern Composition** - Combine multiple patterns
2. **Context Awareness** - Adapt patterns to context
3. **Pattern Testing** - Validate pattern effectiveness
4. **Metrics Tracking** - Measure pattern success
5. **Pattern Evolution** - Improve patterns over time

## 🛠️ Implementing Advanced Features

### Step 1: Context-Aware Patterns

Add context awareness to your patterns:

```python
# In prompt_library.py, add:

@dataclass
class PatternContext:
    """Context information for pattern application."""
    language: str = "python"
    framework: Optional[str] = None
    style_guide: Optional[str] = "PEP8"
    complexity_level: str = "intermediate"  # beginner, intermediate, advanced
    domain: Optional[str] = None  # e.g., "web", "data-science", "system"
    constraints: List[str] = field(default_factory=list)

class ContextAwarePattern(PromptPattern):
    """Pattern that adapts based on context."""
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.context_adaptations = {}
    
    def add_adaptation(self, context_key: str, adaptation: Dict[str, Any]):
        """Add context-specific adaptations."""
        self.context_adaptations[context_key] = adaptation
    
    def apply_with_context(self, context: PatternContext, **kwargs) -> str:
        """Apply pattern with context adaptations."""
        # Base template
        template = self.template
        params = self.parameters.copy()
        
        # Apply context adaptations
        if context.language in self.context_adaptations:
            adaptation = self.context_adaptations[context.language]
            if 'template_override' in adaptation:
                template = adaptation['template_override']
            if 'param_overrides' in adaptation:
                params.update(adaptation['param_overrides'])
        
        # Add context to parameters
        kwargs['language'] = context.language
        kwargs['framework'] = context.framework or "standard library"
        kwargs['style_guide'] = context.style_guide
        
        # Format and return
        try:
            result = template.format(**kwargs)
            self.metadata.usage_count += 1
            return result
        except KeyError as e:
            raise ValueError(f"Missing required parameter: {e}")
```

### Step 2: Pattern Composition Engine

Create advanced composition capabilities:

```python
class CompositionStrategy(Enum):
    """Strategies for composing patterns."""
    SEQUENTIAL = auto()      # One after another
    NESTED = auto()          # One inside another
    PARALLEL = auto()        # Side by side
    CONDITIONAL = auto()     # Based on conditions

class PatternComposer:
    """Advanced pattern composition engine."""
    
    def __init__(self, library: PatternLibrary):
        self.library = library
        self.composition_cache = {}
    
    def compose_sequential(
        self, 
        pattern_specs: List[Tuple[str, Dict[str, Any]]]
    ) -> str:
        """
        Compose patterns sequentially.
        
        Args:
            pattern_specs: List of (pattern_name, parameters) tuples
            
        Returns:
            Combined prompt string
        """
        composed = []
        shared_context = {}
        
        for pattern_name, params in pattern_specs:
            pattern = self.library.get_pattern(pattern_name)
            if not pattern:
                raise ValueError(f"Pattern '{pattern_name}' not found")
            
            # Merge with shared context
            merged_params = {**shared_context, **params}
            
            # Apply pattern
            prompt_part = pattern.apply(**merged_params)
            composed.append(prompt_part)
            
            # Update shared context
            shared_context.update(params)
        
        return "\n\n".join(composed)
    
    def compose_nested(
        self,
        outer_pattern: str,
        inner_patterns: List[Tuple[str, Dict[str, Any]]],
        placeholder: str = "{nested_content}"
    ) -> str:
        """
        Compose patterns with nesting.
        
        The outer pattern should contain a {nested_content} placeholder
        where inner patterns will be inserted.
        """
        # Generate inner content first
        inner_content = self.compose_sequential(inner_patterns)
        
        # Get outer pattern
        outer = self.library.get_pattern(outer_pattern)
        if not outer:
            raise ValueError(f"Pattern '{outer_pattern}' not found")
        
        # Apply outer pattern with nested content
        return outer.apply(nested_content=inner_content)
```

**🤖 Copilot Prompt Suggestion #1:**
```python
# Add a method for conditional composition
# Should:
# - Accept conditions as lambda functions
# - Evaluate conditions with given context
# - Apply different patterns based on condition results
# - Support if-elif-else logic
# - Cache composition results for performance

def compose_conditional(
    self,
    conditions: List[Tuple[Callable, str, Dict[str, Any]]],
    default_pattern: Optional[Tuple[str, Dict[str, Any]]] = None,
    context: Dict[str, Any] = None
) -> str:
    """Compose patterns based on conditions."""
    # Copilot will implement conditional logic
```

### Step 3: Pattern Testing Framework

Create a framework to test pattern effectiveness:

```python
@dataclass
class PatternTest:
    """Test case for a pattern."""
    name: str
    pattern_name: str
    parameters: Dict[str, Any]
    expected_keywords: List[str]
    forbidden_keywords: List[str] = field(default_factory=list)
    expected_structure: Optional[str] = None  # Regex pattern
    
class PatternTester:
    """Test pattern effectiveness."""
    
    def __init__(self, library: PatternLibrary):
        self.library = library
        self.test_results = {}
    
    def test_pattern(self, test: PatternTest) -> Tuple[bool, List[str]]:
        """
        Test a pattern against expectations.
        
        Returns:
            Tuple of (success, error_messages)
        """
        errors = []
        pattern = self.library.get_pattern(test.pattern_name)
        
        if not pattern:
            return False, [f"Pattern '{test.pattern_name}' not found"]
        
        try:
            # Apply pattern
            result = pattern.apply(**test.parameters)
            
            # Check expected keywords
            for keyword in test.expected_keywords:
                if keyword not in result:
                    errors.append(f"Missing expected keyword: '{keyword}'")
            
            # Check forbidden keywords
            for keyword in test.forbidden_keywords:
                if keyword in result:
                    errors.append(f"Contains forbidden keyword: '{keyword}'")
            
            # Check structure if provided
            if test.expected_structure:
                import re
                if not re.search(test.expected_structure, result, re.MULTILINE):
                    errors.append("Output doesn't match expected structure")
            
            success = len(errors) == 0
            return success, errors
            
        except Exception as e:
            return False, [f"Pattern application failed: {str(e)}"]
    
    def run_test_suite(self, tests: List[PatternTest]) -> Dict[str, Any]:
        """Run a suite of tests and return results."""
        results = {
            'total': len(tests),
            'passed': 0,
            'failed': 0,
            'details': []
        }
        
        for test in tests:
            success, errors = self.test_pattern(test)
            if success:
                results['passed'] += 1
            else:
                results['failed'] += 1
            
            results['details'].append({
                'test_name': test.name,
                'pattern': test.pattern_name,
                'success': success,
                'errors': errors
            })
        
        return results
```

### Step 4: Metrics and Analytics

Implement pattern effectiveness tracking:

```python
class PatternMetrics:
    """Track and analyze pattern usage metrics."""
    
    def __init__(self):
        self.usage_history = []
        self.feedback_scores = {}
        self.modification_times = {}
    
    def track_usage(
        self, 
        pattern_name: str, 
        parameters: Dict[str, Any],
        generation_time: float,
        user_id: Optional[str] = None
    ):
        """Track pattern usage."""
        self.usage_history.append({
            'pattern': pattern_name,
            'timestamp': datetime.now(),
            'parameters': parameters,
            'generation_time': generation_time,
            'user': user_id
        })
    
    def record_feedback(
        self,
        pattern_name: str,
        score: float,  # 0-5 rating
        modification_time: Optional[float] = None,
        comments: Optional[str] = None
    ):
        """Record user feedback on pattern effectiveness."""
        if pattern_name not in self.feedback_scores:
            self.feedback_scores[pattern_name] = []
        
        self.feedback_scores[pattern_name].append({
            'score': score,
            'timestamp': datetime.now(),
            'modification_time': modification_time,
            'comments': comments
        })
    
    def calculate_effectiveness(self, pattern_name: str) -> Dict[str, float]:
        """Calculate pattern effectiveness metrics."""
        if pattern_name not in self.feedback_scores:
            return {'average_score': 0.0, 'usage_count': 0}
        
        scores = [f['score'] for f in self.feedback_scores[pattern_name]]
        mod_times = [f['modification_time'] for f in self.feedback_scores[pattern_name] 
                     if f['modification_time'] is not None]
        
        usage_count = sum(1 for u in self.usage_history if u['pattern'] == pattern_name)
        
        return {
            'average_score': sum(scores) / len(scores) if scores else 0.0,
            'usage_count': usage_count,
            'average_modification_time': sum(mod_times) / len(mod_times) if mod_times else 0.0,
            'satisfaction_rate': sum(1 for s in scores if s >= 4) / len(scores) if scores else 0.0
        }
```

**🤖 Copilot Prompt Suggestion #2:**
```python
# Create a pattern recommendation system
# Should:
# - Analyze user's past pattern usage
# - Consider effectiveness metrics
# - Recommend patterns based on current context
# - Learn from user preferences
# - Suggest pattern combinations

class PatternRecommender:
    """Recommend patterns based on context and history."""
    
    def __init__(self, library: PatternLibrary, metrics: PatternMetrics):
        self.library = library
        self.metrics = metrics
    
    def recommend_patterns(
        self,
        context: PatternContext,
        task_description: str,
        limit: int = 5
    ) -> List[Tuple[PromptPattern, float]]:
        """Recommend patterns with confidence scores."""
        # Copilot will implement recommendation logic
```

### Step 5: Pattern Evolution System

Create a system for improving patterns based on feedback:

```python
class PatternEvolution:
    """Evolve patterns based on usage and feedback."""
    
    def __init__(self, library: PatternLibrary, metrics: PatternMetrics):
        self.library = library
        self.metrics = metrics
        self.evolution_history = []
    
    def suggest_improvements(
        self, 
        pattern_name: str
    ) -> List[Dict[str, Any]]:
        """Suggest improvements for a pattern based on metrics."""
        pattern = self.library.get_pattern(pattern_name)
        if not pattern:
            return []
        
        effectiveness = self.metrics.calculate_effectiveness(pattern_name)
        suggestions = []
        
        # Low satisfaction rate
        if effectiveness['satisfaction_rate'] < 0.7:
            suggestions.append({
                'type': 'template_revision',
                'reason': 'Low user satisfaction',
                'suggestion': 'Review template clarity and completeness'
            })
        
        # High modification time
        if effectiveness['average_modification_time'] > 300:  # 5 minutes
            suggestions.append({
                'type': 'add_examples',
                'reason': 'Users spend too much time modifying output',
                'suggestion': 'Add more specific examples or constraints'
            })
        
        # Low usage
        if effectiveness['usage_count'] < 10:
            suggestions.append({
                'type': 'improve_discovery',
                'reason': 'Pattern is underutilized',
                'suggestion': 'Improve description or add more tags'
            })
        
        return suggestions
    
    def create_variant(
        self,
        pattern_name: str,
        modifications: Dict[str, Any]
    ) -> PromptPattern:
        """Create a variant of an existing pattern."""
        original = self.library.get_pattern(pattern_name)
        if not original:
            raise ValueError(f"Pattern '{pattern_name}' not found")
        
        # Create variant
        variant = PatternBuilder()
        variant.name(f"{original.name}_v2")
        variant.category(original.category)
        variant.description(f"{original.description} (Improved)")
        
        # Apply modifications
        template = modifications.get('template', original.template)
        variant.template(template)
        
        # Copy and update parameters
        for param_name, param_info in original.parameters.items():
            variant.parameter(
                param_name,
                param_info.get('type', 'string'),
                param_info.get('required', True),
                param_info.get('default')
            )
        
        # Add modification to parameters
        for param_name, param_info in modifications.get('parameters', {}).items():
            variant.parameter(param_name, **param_info)
        
        return variant.build()
```

### Step 6: Integration Example

Create a complete example showing all advanced features:

```python
# advanced_example.py
from prompt_library import (
    PatternLibrary, PatternContext, PatternComposer,
    PatternTester, PatternMetrics, PatternTest
)
import time

# Initialize system
library = PatternLibrary()
context = PatternContext(
    language="python",
    framework="fastapi",
    complexity_level="advanced",
    domain="web"
)
composer = PatternComposer(library)
tester = PatternTester(library)
metrics = PatternMetrics()

# Load patterns
PatternCollections.load_default_patterns(library)

# Example: Compose a complete API endpoint
api_composition = composer.compose_sequential([
    ("validation_schema", {
        "entity": "User",
        "fields": "email, password, age"
    }),
    ("crud_create", {
        "entity": "User",
        "entity_lower": "user",
        "required_fields": "email, password",
        "unique_fields": "email",
        "storage_type": "PostgreSQL"
    }),
    ("unit_test", {
        "function_name": "create_user",
        "function_signature": "create_user(email: str, password: str) -> User",
        "edge_cases": "empty email, weak password",
        "error_cases": "duplicate email, invalid format"
    })
])

print("Composed API Endpoint:")
print(api_composition)

# Test the pattern
test = PatternTest(
    name="test_user_creation",
    pattern_name="crud_create",
    parameters={
        "entity": "User",
        "entity_lower": "user",
        "required_fields": "email",
        "unique_fields": "email"
    },
    expected_keywords=["def create_user", "validate", "return User"],
    forbidden_keywords=["TODO", "FIXME"],
    expected_structure=r"def create_user.*?->.*?User:"
)

success, errors = tester.test_pattern(test)
print(f"\nPattern Test: {'PASSED' if success else 'FAILED'}")
if errors:
    for error in errors:
        print(f"  - {error}")

# Track metrics
start_time = time.time()
result = library.get_pattern("crud_create").apply(
    entity="Product",
    entity_lower="product",
    required_fields="name, price",
    unique_fields="sku"
)
generation_time = time.time() - start_time

metrics.track_usage("crud_create", 
                   {"entity": "Product"}, 
                   generation_time)
metrics.record_feedback("crud_create", 4.5, 120)  # 4.5 stars, 2 min modification

# Get effectiveness
effectiveness = metrics.calculate_effectiveness("crud_create")
print(f"\nPattern Effectiveness:")
print(f"  Average Score: {effectiveness['average_score']:.2f}/5")
print(f"  Usage Count: {effectiveness['usage_count']}")
print(f"  Satisfaction Rate: {effectiveness['satisfaction_rate']:.1%}")
```

## 🎯 Part 3 Summary

You've implemented:
1. Context-aware patterns that adapt to different scenarios
2. Advanced composition strategies (sequential, nested, conditional)
3. Pattern testing framework for quality assurance
4. Metrics tracking and effectiveness measurement
5. Pattern evolution based on feedback
6. Complete integration example

## 💡 Advanced Best Practices

1. **Test Patterns Regularly** - Ensure they generate expected output
2. **Track Metrics** - Monitor usage and satisfaction
3. **Evolve Patterns** - Improve based on feedback
4. **Compose Wisely** - Use composition for complex scenarios
5. **Context Matters** - Adapt patterns to specific contexts

## 🏆 Final Challenge

Create a complete pattern workflow:

```python
# Challenge: Build an automated pattern improvement system
# Requirements:
# 1. Monitor pattern usage continuously
# 2. Identify underperforming patterns
# 3. Generate improvement suggestions
# 4. Create A/B test variants
# 5. Automatically promote better variants
# 6. Generate reports on pattern effectiveness

class PatternOptimizationPipeline:
    """Automated pattern optimization system."""
    # Your implementation
```

## 📊 Module Summary

You've built a comprehensive prompt pattern library with:
- **15+ reusable patterns** across multiple categories
- **Pattern composition** for complex scenarios
- **Context awareness** for adaptability
- **Testing framework** for quality assurance
- **Metrics tracking** for continuous improvement
- **Evolution system** for pattern optimization

---

🎉 **Congratulations! You've mastered prompt pattern libraries. Ready for Exercise 3: Custom Instruction System!**