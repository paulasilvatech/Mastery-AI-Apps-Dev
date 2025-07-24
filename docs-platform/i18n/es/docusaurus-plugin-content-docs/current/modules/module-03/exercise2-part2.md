---
sidebar_position: 3
title: "Exercise 2: Part 2"
description: "## 🎯 Part 2: Building Reusable Templates (15-20 minutes)"
---

# Ejercicio 2: Prompt Pattern Library - Partee 2

## 🎯 Partee 2: Building Reusable Templates (15-20 minutos)

Now that you have the foundation, let's create specific, reusable prompt templates for common programming tasks.

## 📚 Template Design Principles

### Effective Templates Should Be:
1. **Parameterized** - Use placeholders for customization
2. **Comprehensive** - Include all necessary context
3. **Example-Driven** - Show expected behavior
4. **Constraint-Clear** - Specify requirements explicitly
5. **Reusable** - Work across different contexts

## 🛠️ Creating Pattern Módulos

### Step 1: CRUD Pattern Módulo

Create `patterns/crud.py`:

```python
"""CRUD (Create, Read, Update, Delete) operation patterns."""

from typing import List
from prompt_library import PromptPattern, PatternCategory, PatternBuilder

class CRUDPatterns:
    """Collection of CRUD operation patterns."""
    
    @staticmethod
    def create_pattern() -&gt; PromptPattern:
        """Pattern for generating create/add methods."""
        return (PatternBuilder()
            .name("crud_create")
            .category(PatternCategory.BEHAVIORAL)
            .description("Generate a create/add method with validation")
            .template("""
# Create a method to add new {entity}
# Requirements:
# - Validate all required fields: {required_fields}
# - Generate unique ID (auto-increment or UUID)
# - Check for duplicates on: {unique_fields}
# - Store in {storage_type}
# - Return created {entity} object
# - Log the creation for audit trail
# Error handling:
# - Raise ValueError for validation failures
# - Raise DuplicateError if {unique_fields} already exist

def create_{entity_lower}(
    self,
    {field_params}
) -&gt; {entity}:
    \"\"\"
    Create a new {entity}.
    
    Args:
        {field_docs}
    
    Returns:
        Created {entity} instance
        
    Raises:
        ValueError: If validation fails
        DuplicateError: If {unique_fields} already exist
    \"\"\"
    # Copilot will generate implementation
""")
            .parameter("entity", "string", required=True)
            .parameter("entity_lower", "string", required=True)
            .parameter("required_fields", "string", required=True)
            .parameter("unique_fields", "string", required=True)
            .parameter("storage_type", "string", default="database")
            .parameter("field_params", "string", required=True)
            .parameter("field_docs", "string", required=True)
            .example(
                input="""entity="User", required_fields="email, password", 
                       unique_fields="email", field_params="email: str, password: str, name: str = None\"""",
                output="Complete create_user method with validation and storage"
            )
            .build()
        )
```

**🤖 Copilot Prompt Suggestion #1:**
```python
# Create similar patterns for Read, Update, Delete operations
# Each should follow the same structure but with appropriate:
# - Method names (get/list, update, delete)
# - Parameters (id, filters, update_data)
# - Return types (single object, list, bool)
# - Error handling (NotFound, ValidationError)

@staticmethod
def read_pattern() -&gt; PromptPattern:
    # Let Copilot generate based on create_pattern example
```

### Step 2: Validation Pattern Módulo

Create `patterns/validation.py`:

```python
"""Validation patterns for input checking and business rules."""

from prompt_library import PromptPattern, PatternCategory, PatternBuilder

class ValidationPatterns:
    """Collection of validation patterns."""
    
    @staticmethod
    def field_validator_pattern() -&gt; PromptPattern:
        """Pattern for field validation functions."""
        return (PatternBuilder()
            .name("field_validator")
            .category(PatternCategory.VALIDATION)
            .description("Generate field validation with specific rules")
            .template("""
# Validate {field_name} field
# Type: {field_type}
# Rules:
{validation_rules}
# Return format: Tuple[bool, Optional[str]] (is_valid, error_message)
# 
# Valid examples:
{valid_examples}
#
# Invalid examples:
{invalid_examples}

def validate_{field_name}(value: {field_type}) -&gt; Tuple[bool, Optional[str]]:
    \"\"\"
    Validate {field_name} according to business rules.
    
    Args:
        value: The {field_name} to validate
        
    Returns:
        Tuple of (is_valid, error_message)
        error_message is None if valid
    \"\"\"
    # Copilot will implement validation logic
""")
            .parameter("field_name", "string", required=True)
            .parameter("field_type", "string", required=True)
            .parameter("validation_rules", "string", required=True)
            .parameter("valid_examples", "string", required=True)
            .parameter("invalid_examples", "string", required=True)
            .example(
                input="""field_name="email", field_type="str",
                       validation_rules="- Must contain @ symbol\\n- Valid domain\\n- No spaces",
                       valid_examples="user@example.com, test.user@company.co.uk",
                       invalid_examples="invalid.email, @example.com, user @example.com\"""",
                output="Email validation function with regex and clear error messages"
            )
            .build()
        )
```

### Step 3: Algorithm Pattern Módulo

Create `patterns/algorithms.py`:

```python
"""Algorithm implementation patterns."""

class AlgorithmPatterns:
    """Collection of algorithm patterns."""
    
    @staticmethod
    def search_algorithm_pattern() -&gt; PromptPattern:
        """Pattern for search algorithm implementation."""
        return (PatternBuilder()
            .name("search_algorithm")
            .category(PatternCategory.BEHAVIORAL)
            .description("Generate search algorithms with specific requirements")
            .template("""
# Implement {algorithm_name} search algorithm
# Input: {input_description}
# Output: {output_description}
# 
# Algorithm steps:
{algorithm_steps}
#
# Time complexity: {time_complexity}
# Space complexity: {space_complexity}
#
# Example:
# Input: {example_input}
# Output: {example_output}
#
# Edge cases to handle:
{edge_cases}

def {function_name}({parameters}) -&gt; {return_type}:
    \"\"\"
    {algorithm_description}
    
    Args:
        {param_docs}
    
    Returns:
        {return_docs}
    
    Complexity:
        Time: {time_complexity}
        Space: {space_complexity}
    \"\"\"
    # Copilot will implement the algorithm
""")
            .parameter("algorithm_name", "string", required=True)
            .parameter("function_name", "string", required=True)
            .parameter("input_description", "string", required=True)
            .parameter("output_description", "string", required=True)
            .parameter("algorithm_steps", "string", required=True)
            .parameter("time_complexity", "string", default="O(n)")
            .parameter("space_complexity", "string", default="O(1)")
            .parameter("parameters", "string", required=True)
            .parameter("return_type", "string", required=True)
            .parameter("example_input", "string", required=True)
            .parameter("example_output", "string", required=True)
            .parameter("edge_cases", "string", required=True)
            .parameter("algorithm_description", "string", required=True)
            .parameter("param_docs", "string", required=True)
            .parameter("return_docs", "string", required=True)
            .build()
        )
```

**🤖 Copilot Prompt Suggestion #2:**
```python
# Create a data structure operation pattern
# Should handle operations like:
# - Insert with specific position/order
# - Remove with criteria
# - Find with custom comparison
# - Transform elements
# Include complexity analysis and examples

@staticmethod
def data_structure_operation_pattern() -&gt; PromptPattern:
    """Pattern for data structure operations."""
    # Copilot will create similar to search_algorithm_pattern
```

### Step 4: Testing Pattern Módulo

Create `patterns/testing.py`:

```python
"""Testing patterns for unit tests and test cases."""

class TestingPatterns:
    """Collection of testing patterns."""
    
    @staticmethod
    def unit_test_pattern() -&gt; PromptPattern:
        """Pattern for generating unit tests."""
        return (PatternBuilder()
            .name("unit_test")
            .category(PatternCategory.TESTING)
            .description("Generate comprehensive unit tests")
            .template("""
# Generate unit tests for {function_name}
# Function signature: {function_signature}
# Function purpose: {function_purpose}
#
# Test categories to cover:
# 1. Happy path - normal expected usage
# 2. Edge cases - {edge_cases}
# 3. Error cases - {error_cases}
# 4. Boundary values - {boundary_values}
#
# Use {test_framework} framework
# Include setup/teardown if needed
# Mock external dependencies: {dependencies_to_mock}

import {test_framework}
{additional_imports}

class Test{class_name}({test_base_class}):
    \"\"\"Test cases for {function_name}.\"\"\"
    
    def setUp(self):
        \"\"\"Set up test fixtures.\"\"\"
        # Initialize test data
        
    # Test happy path
    def test_{function_name}_success(self):
        \"\"\"Test {function_name} with valid input.\"\"\"
        # Copilot will generate test cases
        
    # Test edge cases
    def test_{function_name}_edge_cases(self):
        \"\"\"Test {function_name} with edge cases.\"\"\"
        # Copilot will generate edge case tests
        
    # Test error handling
    def test_{function_name}_errors(self):
        \"\"\"Test {function_name} error handling.\"\"\"
        # Copilot will generate error tests
""")
            .parameter("function_name", "string", required=True)
            .parameter("function_signature", "string", required=True)
            .parameter("function_purpose", "string", required=True)
            .parameter("edge_cases", "string", required=True)
            .parameter("error_cases", "string", required=True)
            .parameter("boundary_values", "string", required=True)
            .parameter("test_framework", "string", default="pytest")
            .parameter("dependencies_to_mock", "string", default="None")
            .parameter("class_name", "string", required=True)
            .parameter("test_base_class", "string", default="TestCase")
            .parameter("additional_imports", "string", default="")
            .build()
        )
```

### Step 5: Create Pattern Collections

Atrás in `prompt_library.py`, add a pattern collection loader:

```python
class PatternCollections:
    """Load and manage pattern collections."""
    
    @staticmethod
    def load_default_patterns(library: PatternLibrary) -&gt; None:
        """Load all default patterns into the library."""
        from patterns.crud import CRUDPatterns
        from patterns.validation import ValidationPatterns
        from patterns.algorithms import AlgorithmPatterns
        from patterns.testing import TestingPatterns
        
        # Load CRUD patterns
        library.add_pattern(CRUDPatterns.create_pattern())
        library.add_pattern(CRUDPatterns.read_pattern())
        library.add_pattern(CRUDPatterns.update_pattern())
        library.add_pattern(CRUDPatterns.delete_pattern())
        
        # Load validation patterns
        library.add_pattern(ValidationPatterns.field_validator_pattern())
        library.add_pattern(ValidationPatterns.business_rule_pattern())
        library.add_pattern(ValidationPatterns.schema_validator_pattern())
        
        # Load algorithm patterns
        library.add_pattern(AlgorithmPatterns.search_algorithm_pattern())
        library.add_pattern(AlgorithmPatterns.sort_algorithm_pattern())
        library.add_pattern(AlgorithmPatterns.data_structure_operation_pattern())
        
        # Load testing patterns
        library.add_pattern(TestingPatterns.unit_test_pattern())
        library.add_pattern(TestingPatterns.integration_test_pattern())
        library.add_pattern(TestingPatterns.mock_pattern())
        
        print(f"✅ Loaded {len(library.patterns)} default patterns")
```

### Step 6: Pattern Composition

Add pattern composition functionality:

```python
class PatternComposer:
    """Compose multiple patterns together."""
    
    def __init__(self, library: PatternLibrary):
        self.library = library
    
    def compose(self, pattern_names: List[str], context: Dict[str, Any]) -&gt; str:
        """
        Compose multiple patterns into a single prompt.
        
        Args:
            pattern_names: List of pattern names to compose
            context: Shared context for all patterns
            
        Returns:
            Combined prompt string
        """
        composed_prompt = []
        
        for name in pattern_names:
            pattern = self.library.get_pattern(name)
            if pattern:
                # Apply pattern with context
                prompt_part = pattern.apply(**context)
                composed_prompt.append(prompt_part)
                composed_prompt.append("\n\n")  # Separator
        
        return "\n".join(composed_prompt)
```

## 📊 Testing Your Templates

Create a comprehensive test:

```python
# test_templates.py
from prompt_library import PatternLibrary, PatternCollections
from patterns.crud import CRUDPatterns

# Create and populate library
library = PatternLibrary()
PatternCollections.load_default_patterns(library)

# Test CRUD pattern
crud_pattern = library.get_pattern("crud_create")
user_prompt = crud_pattern.apply(
    entity="User",
    entity_lower="user",
    required_fields="email, password, username",
    unique_fields="email, username",
    storage_type="PostgreSQL database",
    field_params="email: str, password: str, username: str, full_name: str = None",
    field_docs="email: User's email address\n        password: Encrypted password\n        username: Unique username\n        full_name: Optional full name"
)

print("Generated CRUD Prompt:")
print(user_prompt)
print("\n" + "="*50 + "\n")

# Test validation pattern
validation_pattern = library.get_pattern("field_validator")
password_prompt = validation_pattern.apply(
    field_name="password",
    field_type="str",
    validation_rules="- Minimum 8 characters\n- At least one uppercase letter\n- At least one lowercase letter\n- At least one digit\n- At least one special character",
    valid_examples="'SecureP@ss123', 'MyStr0ng!Pass'",
    invalid_examples="'weak', 'NoDigits!', '12345678', 'no_uppercase1!'"
)

print("Generated Validation Prompt:")
print(password_prompt)
```

## 🎯 Partee 2 Resumen

You've created:
1. Specialized pattern modules (CRUD, Validation, Algorithms, Testing)
2. Comprehensive templates with parameters
3. Pattern collections for easy loading
4. Pattern composition functionality
5. Real-world applicable patterns

## 💡 Mejores Prácticas for Templates

1. **Include All Context** - Don't assume Copilot knows requirements
2. **Provide Examples** - Show input/output relationships
3. **Specify Constraints** - Be explicit about rules and limitations
4. **Document Parameters** - Clear descriptions for each placeholder
5. **Test Templates** - Verify they generate quality code

## ⚡ Challenge: Create Custom Pattern

Create your own pattern for a common task:

```python
# Challenge: Create an API endpoint pattern
# Should include:
# - HTTP method and route
# - Authentication requirements
# - Request/response schemas
# - Error handling
# - Rate limiting
# - Logging

def api_endpoint_pattern() -&gt; PromptPattern:
    # Your implementation
```

---

✅ **Excellent! You've built a comprehensive pattern library. Continue to Part 3 for advanced techniques!**