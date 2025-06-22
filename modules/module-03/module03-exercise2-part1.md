# Exercise 2: Prompt Pattern Library - Part 1

## 🎯 Part 1: Pattern Categories and Foundation (15-20 minutes)

In this part, you'll learn about different prompt pattern categories and build the foundation for your pattern library system.

## 📚 Understanding Prompt Pattern Categories

### Core Pattern Types

1. **Structural Patterns**
   - Define code organization
   - Class templates, module structure
   - Architecture patterns

2. **Behavioral Patterns**
   - Specify functionality
   - Algorithm implementation
   - Business logic

3. **Creational Patterns**
   - Generate new components
   - Factory methods, builders
   - Initialization logic

4. **Validation Patterns**
   - Ensure correctness
   - Input validation
   - Business rule enforcement

5. **Optimization Patterns**
   - Improve performance
   - Caching strategies
   - Algorithm efficiency

## 🛠️ Building the Pattern Registry

### Step 1: Create Pattern Base Classes

Start by creating the foundation in `starter/prompt_library.py`:

```python
#!/usr/bin/env python3
"""
Prompt Pattern Library System
Build reusable patterns for effective GitHub Copilot prompting
"""

from typing import Dict, List, Optional, Any, Type
from dataclasses import dataclass, field
from enum import Enum, auto
from datetime import datetime
import json
import yaml

class PatternCategory(Enum):
    """Categories for organizing prompt patterns."""
    STRUCTURAL = auto()
    BEHAVIORAL = auto()
    CREATIONAL = auto()
    VALIDATION = auto()
    OPTIMIZATION = auto()
    TESTING = auto()
    DOCUMENTATION = auto()

@dataclass
class PatternMetadata:
    """Metadata for tracking pattern usage and effectiveness."""
    created_at: datetime = field(default_factory=datetime.now)
    updated_at: datetime = field(default_factory=datetime.now)
    usage_count: int = 0
    success_rate: float = 0.0
    author: str = "unknown"
    tags: List[str] = field(default_factory=list)
    version: str = "1.0.0"
```

### Step 2: Define the Base Pattern Class

```python
@dataclass
class PromptPattern:
    """Base class for all prompt patterns."""
    name: str
    category: PatternCategory
    description: str
    template: str
    parameters: Dict[str, Any] = field(default_factory=dict)
    examples: List[Dict[str, str]] = field(default_factory=list)
    metadata: PatternMetadata = field(default_factory=PatternMetadata)
    
    def validate(self) -> List[str]:
        """Validate the pattern configuration."""
        errors = []
        
        if not self.name:
            errors.append("Pattern name is required")
        
        if not self.template:
            errors.append("Pattern template is required")
            
        if "{" in self.template or "}" in self.template:
            # Check if all placeholders have parameters
            import re
            placeholders = re.findall(r'\{(\w+)\}', self.template)
            for placeholder in placeholders:
                if placeholder not in self.parameters:
                    errors.append(f"Missing parameter definition for '{placeholder}'")
        
        return errors
    
    def apply(self, **kwargs) -> str:
        """Apply the pattern with given parameters."""
        # TODO: Implement pattern application logic
        # Should:
        # 1. Validate all required parameters are provided
        # 2. Apply defaults for optional parameters
        # 3. Format the template with parameters
        # 4. Update usage statistics
        pass
```

**🤖 Copilot Prompt Suggestion #1:**
```python
# After the apply method signature, add this comment:
# Implement pattern application that:
# - Validates all required parameters are provided
# - Uses default values for missing optional parameters
# - Safely formats template without KeyError
# - Increments usage_count
# - Returns formatted prompt string
# Example: pattern.apply(entity="User", storage="database")

def apply(self, **kwargs) -> str:
    # Let Copilot complete the implementation
```

### Step 3: Create the Pattern Library

```python
class PatternLibrary:
    """Central library for managing prompt patterns."""
    
    def __init__(self):
        self.patterns: Dict[str, PromptPattern] = {}
        self.categories: Dict[PatternCategory, List[str]] = {
            category: [] for category in PatternCategory
        }
    
    def add_pattern(self, pattern: PromptPattern) -> None:
        """Add a pattern to the library."""
        # Validate pattern first
        errors = pattern.validate()
        if errors:
            raise ValueError(f"Invalid pattern: {', '.join(errors)}")
        
        # Add to patterns dict
        self.patterns[pattern.name] = pattern
        
        # Add to category index
        self.categories[pattern.category].append(pattern.name)
        
        # Log addition
        print(f"✅ Added pattern '{pattern.name}' to {pattern.category.name} category")
```

### Step 4: Implement Pattern Search and Filtering

```python
    def search_patterns(
        self, 
        query: str = "", 
        category: Optional[PatternCategory] = None,
        tags: Optional[List[str]] = None
    ) -> List[PromptPattern]:
        """
        Search patterns by query, category, or tags.
        
        Args:
            query: Search in name and description
            category: Filter by category
            tags: Filter by tags (ANY match)
        
        Returns:
            List of matching patterns
        """
        results = []
        
        for pattern in self.patterns.values():
            # Category filter
            if category and pattern.category != category:
                continue
            
            # Query filter
            if query:
                query_lower = query.lower()
                if (query_lower not in pattern.name.lower() and 
                    query_lower not in pattern.description.lower()):
                    continue
            
            # Tag filter
            if tags:
                if not any(tag in pattern.metadata.tags for tag in tags):
                    continue
            
            results.append(pattern)
        
        return results
```

**🤖 Copilot Prompt Suggestion #2:**
```python
# Create a method to get patterns by effectiveness
# Should:
# - Return patterns sorted by success_rate
# - Allow filtering by minimum success rate
# - Optionally limit number of results
# - Include only patterns with minimum usage count

def get_top_patterns(
    self, 
    min_success_rate: float = 0.7,
    min_usage: int = 5,
    limit: Optional[int] = None
) -> List[PromptPattern]:
    # Copilot will implement the filtering and sorting logic
```

### Step 5: Add Import/Export Functionality

```python
    def export_to_file(self, filepath: str, format: str = "json") -> None:
        """Export library to file (JSON or YAML)."""
        data = {
            "version": "1.0",
            "patterns": []
        }
        
        for pattern in self.patterns.values():
            pattern_data = {
                "name": pattern.name,
                "category": pattern.category.name,
                "description": pattern.description,
                "template": pattern.template,
                "parameters": pattern.parameters,
                "examples": pattern.examples,
                "metadata": {
                    "author": pattern.metadata.author,
                    "tags": pattern.metadata.tags,
                    "version": pattern.metadata.version
                }
            }
            data["patterns"].append(pattern_data)
        
        if format == "json":
            with open(filepath, 'w') as f:
                json.dump(data, f, indent=2, default=str)
        elif format == "yaml":
            with open(filepath, 'w') as f:
                yaml.dump(data, f, default_flow_style=False)
```

### Step 6: Create Pattern Builder Helper

```python
class PatternBuilder:
    """Fluent interface for building patterns."""
    
    def __init__(self):
        self._pattern_data = {}
    
    def name(self, name: str) -> 'PatternBuilder':
        self._pattern_data['name'] = name
        return self
    
    def category(self, category: PatternCategory) -> 'PatternBuilder':
        self._pattern_data['category'] = category
        return self
    
    def description(self, desc: str) -> 'PatternBuilder':
        self._pattern_data['description'] = desc
        return self
    
    def template(self, template: str) -> 'PatternBuilder':
        self._pattern_data['template'] = template
        return self
    
    def parameter(self, name: str, type: str, required: bool = True, 
                  default: Any = None) -> 'PatternBuilder':
        if 'parameters' not in self._pattern_data:
            self._pattern_data['parameters'] = {}
        
        self._pattern_data['parameters'][name] = {
            'type': type,
            'required': required,
            'default': default
        }
        return self
    
    def example(self, input: str, output: str) -> 'PatternBuilder':
        if 'examples' not in self._pattern_data:
            self._pattern_data['examples'] = []
        
        self._pattern_data['examples'].append({
            'input': input,
            'output': output
        })
        return self
    
    def build(self) -> PromptPattern:
        """Build and return the pattern."""
        return PromptPattern(**self._pattern_data)
```

## 📊 Testing Your Foundation

Create a test script to verify your implementation:

```python
# test_foundation.py
from prompt_library import PatternLibrary, PatternBuilder, PatternCategory

# Create library
library = PatternLibrary()

# Build a test pattern using the builder
pattern = (PatternBuilder()
    .name("crud_create")
    .category(PatternCategory.BEHAVIORAL)
    .description("Generate create method for CRUD operations")
    .template("""
# Create a method to add new {entity}
# Requirements:
# - Validate input data
# - Generate unique ID
# - Store in {storage_type}
# - Return created object
# - Handle errors gracefully

def create_{entity_lower}(self, data: Dict) -> {entity}:
    # Copilot will generate implementation
""")
    .parameter("entity", "string", required=True)
    .parameter("entity_lower", "string", required=True)
    .parameter("storage_type", "string", default="memory")
    .example(
        input="entity='User', storage_type='database'",
        output="def create_user(self, data: Dict) -> User: ..."
    )
    .build()
)

# Add to library
library.add_pattern(pattern)

# Test search
results = library.search_patterns(category=PatternCategory.BEHAVIORAL)
print(f"Found {len(results)} behavioral patterns")

# Test apply
prompt = pattern.apply(entity="Task", entity_lower="task")
print("Generated prompt:")
print(prompt)
```

## 🎯 Part 1 Summary

You've built:
1. Pattern category system
2. Base pattern classes with metadata
3. Pattern library with search capabilities
4. Import/export functionality
5. Fluent pattern builder
6. Validation system

## 💡 Key Concepts

- **Categories** help organize patterns logically
- **Metadata** tracks usage and effectiveness
- **Validation** ensures pattern quality
- **Builder pattern** simplifies pattern creation
- **Search functionality** enables pattern discovery

## ⚡ Quick Challenge

Before moving to Part 2, create one pattern for each category:

```python
# Challenge: Create these patterns
# 1. STRUCTURAL: Class template pattern
# 2. BEHAVIORAL: Event handler pattern  
# 3. CREATIONAL: Factory method pattern
# 4. VALIDATION: Input validator pattern
# 5. OPTIMIZATION: Caching pattern
```

---

✅ **Great work! You've built the foundation. Continue to Part 2 to create specific pattern templates!**