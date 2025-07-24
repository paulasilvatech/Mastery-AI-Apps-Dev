---
sidebar_position: 10
title: "Exercise 2: Part 1"
description: "## 🎯 Exercise Overview"
---

# Exercício 2: Refactoring Assistant (⭐⭐ Médio)

## 🎯 Visão Geral do Exercício

**Duração**: 45-60 minutos  
**Difficulty**: ⭐⭐ (Médio)  
**Success Rate**: 80%

In this exercise, you'll build an intelligent refactoring assistant that identifies code smells and automatically applies refactoring patterns. You'll learn how to use GitHub Copilot to detect problematic code patterns and transform them into clean, maintainable solutions while ensuring the code still works correctly.

## 🎓 Objetivos de Aprendizagem

Ao completar este exercício, você irá:
- Detect common code smells using pattern matching
- Apply refactoring patterns automatically
- Maintain code functionality during transformations
- Generate tests to verify refactoring safety
- Create detailed refactoring reports

## 📋 Pré-requisitos

- ✅ Completard Exercício 1
- ✅ Understanding of code smells and refactoring
- ✅ Basic knowledge of AST manipulation
- ✅ Familiarity with testing concepts

## 🏗️ What You'll Build

An **Intelligent Refactoring Assistant** that:
- Analyzes code for common smells
- Suggests appropriate refactoring patterns
- Applies transformations automatically
- Verifies correctness with tests
- Generates refactoring reports

## 📁 Project Structure

```
exercise2-medium/
├── README.md               # This file
├── instructions/
│   ├── part1.md           # Code smell detection (this file)
│   ├── part2.md           # Refactoring implementation
│   └── part3.md           # Testing and validation
├── starter/
│   ├── refactoring_assistant.py
│   ├── code_smells/       # Smell detectors
│   ├── refactorings/      # Refactoring patterns
│   └── sample_code/       # Code to refactor
├── solution/
│   ├── refactoring_assistant.py
│   ├── code_smells/
│   ├── refactorings/
│   ├── tests/
│   └── examples/
└── resources/
    ├── smell_catalog.md
    └── refactoring_patterns.md
```

## 🚀 Partee 1: Detecting Code Smells

### Step 1: Understanding Common Code Smells

Before we build our assistant, let's understand the code smells we'll detect:

1. **Long Method** - Functions that are too long (>20 lines)
2. **Large Class** - Classes with too many responsibilities
3. **Long Parameter List** - Functions with too many parameters (>4)
4. **Duplicate Code** - Similar code blocks repeated
5. **Complex Conditionals** - Nested if/else statements
6. **Feature Envy** - Methods that use another class more than their own
7. **Data Clumps** - Groups of variables that always appear together

### Step 2: Create the Base Refactoring Assistant

Navigate to the starter directory and begin:

```bash
cd exercises/exercise2-medium/starter
code refactoring_assistant.py
```

Comece com this template:

```python
#!/usr/bin/env python3
"""
Intelligent Refactoring Assistant
Detects code smells and applies automated refactoring
"""

import ast
import difflib
from typing import List, Dict, Optional, Tuple, Any
from pathlib import Path
from dataclasses import dataclass
from enum import Enum, auto
import textwrap

class SmellType(Enum):
    """Types of code smells we can detect."""
    LONG_METHOD = auto()
    LARGE_CLASS = auto()
    LONG_PARAMETER_LIST = auto()
    DUPLICATE_CODE = auto()
    COMPLEX_CONDITIONAL = auto()
    FEATURE_ENVY = auto()
    DATA_CLUMP = auto()

@dataclass
class CodeSmell:
    """Represents a detected code smell."""
    smell_type: SmellType
    severity: str  # "low", "medium", "high"
    location: Tuple[int, int]  # (start_line, end_line)
    description: str
    suggestion: str
    confidence: float  # 0.0 to 1.0

# Create a class that detects and fixes code smells
# The class should:
# - Parse Python code and build AST
# - Detect various code smells
# - Suggest appropriate refactorings
# - Apply refactorings automatically
# - Verify the refactored code works
class RefactoringAssistant:
```

**🤖 Copilot Prompt Suggestion #1:**
```python
# After the class definition, add:
# The RefactoringAssistant should have these core methods:
# - __init__(self): Initialize smell detectors and refactorings
# - analyze_code(self, code: str) -&gt; List[CodeSmell]: Detect all smells
# - suggest_refactoring(self, smell: CodeSmell) -&gt; str: Suggest fix
# - apply_refactoring(self, code: str, smell: CodeSmell) -&gt; str: Apply fix
# - verify_refactoring(self, original: str, refactored: str) -&gt; bool: Check safety
# Include configuration for thresholds and severity levels
```

**Expected Output:**
Copilot should generate a complete class structure with initialization and method stubs for smell detection and refactoring.

### Step 3: Implement Long Method Detection

Create the first smell detector:

```python
def _detect_long_methods(self, tree: ast.Module) -&gt; List[CodeSmell]:
    """
    Detect methods that are too long.
    
    Args:
        tree: AST of the code to analyze.
        
    Returns:
        List of detected long method smells.
    """
    smells = []
    
    # Walk the AST to find all function definitions
    # Calculate method length (excluding docstrings)
    # Check against threshold (default: 20 lines)
    # Consider complexity, not just line count
    # Return smell with severity based on length
```

**🤖 Copilot Prompt Suggestion #2:**
```python
# Implement long method detection:
# 1. Use ast.walk() to find FunctionDef nodes
# 2. Calculate actual code lines (exclude comments/docstrings)
# 3. Determine severity:
#    - 20-30 lines: low
#    - 30-50 lines: medium  
#    - 50+ lines: high
# 4. Generate helpful suggestion like:
#    "Consider breaking this 35-line method into smaller functions"
# 5. Calculate confidence based on complexity metrics
# Include method name and location in smell report
```

### Step 4: Detect Long Parameter Lists

Add parameter list detection:

```python
def _detect_long_parameter_lists(self, tree: ast.Module) -&gt; List[CodeSmell]:
    """
    Detect functions with too many parameters.
    
    Args:
        tree: AST of the code to analyze.
        
    Returns:
        List of detected parameter list smells.
    """
    # Detect functions with >4 parameters
    # Consider using parameter objects
    # Check for related parameters that could be grouped
    # Suggest refactoring approaches
```

**🤖 Copilot Prompt Suggestion #3:**
```python
# Detect long parameter lists:
# 1. Find all FunctionDef nodes
# 2. Count parameters (args, kwonlyargs)
# 3. Detect patterns in parameter names that suggest grouping
#    - Related prefixes (user_name, user_email, user_id)
#    - Common suffixes (start_date, end_date)
# 4. Severity based on count:
#    - 5-6 params: low
#    - 7-8 params: medium
#    - 9+ params: high
# 5. Suggest parameter object or builder pattern
# Provide specific grouping suggestions
```

### Step 5: Implement Duplicate Code Detection

Create a sophisticated duplicate code detector:

```python
def _detect_duplicate_code(self, tree: ast.Module) -&gt; List[CodeSmell]:
    """
    Detect duplicate or similar code blocks.
    
    Args:
        tree: AST of the code to analyze.
        
    Returns:
        List of detected duplicate code smells.
    """
    # Use AST comparison to find similar structures
    # Detect exact duplicates and near-duplicates
    # Consider variable name differences
    # Find common patterns across functions
    # Suggest extraction to shared method
```

**🤖 Copilot Prompt Suggestion #4:**
```python
# Implement duplicate detection using these steps:
# 1. Extract all code blocks (function bodies, loops, conditions)
# 2. Normalize AST for comparison:
#    - Replace variable names with placeholders
#    - Ignore comments and docstrings
# 3. Compare blocks using:
#    - Exact AST matching
#    - Similarity scoring (>80% similar)
# 4. Group similar blocks together
# 5. Calculate severity by:
#    - Number of duplicates
#    - Size of duplicated code
# 6. Suggest extraction methods:
#    - Extract method for duplicate logic
#    - Create base class for duplicate classes
#    - Use decorators for cross-cutting concerns
```

### Step 6: Detect Complex Conditionals

Add detection for nested and complex conditions:

```python
def _detect_complex_conditionals(self, tree: ast.Module) -&gt; List[CodeSmell]:
    """
    Detect overly complex conditional statements.
    
    Args:
        tree: AST of the code to analyze.
        
    Returns:
        List of detected complex conditional smells.
    """
    # Find deeply nested if/else statements
    # Detect complex boolean expressions
    # Identify switch-like if/elif chains
    # Check for guard clause opportunities
    # Suggest simplification strategies
```

### Step 7: Create Smell Analysis Report

Build a comprehensive analysis method:

```python
def analyze_code(self, code: str) -&gt; Dict[str, Any]:
    """
    Perform complete code smell analysis.
    
    Args:
        code: Python code to analyze.
        
    Returns:
        Analysis report with all detected smells and metrics.
    """
    try:
        tree = ast.parse(code)
    except SyntaxError as e:
        return {{"error": f"Syntax error: {{e}}", "smells": []}}
    
    # Run all smell detectors
    smells = []
    smells.extend(self._detect_long_methods(tree))
    smells.extend(self._detect_long_parameter_lists(tree))
    smells.extend(self._detect_duplicate_code(tree))
    smells.extend(self._detect_complex_conditionals(tree))
    
    # Calculate code metrics
    metrics = self._calculate_code_metrics(tree)
    
    # Generate summary and recommendations
    summary = self._generate_analysis_summary(smells, metrics)
    
    return {
        "smells": smells,
        "metrics": metrics,
        "summary": summary,
        "total_issues": len(smells),
        "severity_breakdown": self._count_by_severity(smells)
    }
```

**🤖 Copilot Prompt Suggestion #5:**
```python
# Create comprehensive analysis report:
# 1. Aggregate all detected smells
# 2. Sort by severity and type
# 3. Calculate metrics:
#    - Lines of code
#    - Cyclomatic complexity
#    - Number of classes/functions
#    - Average method length
# 4. Generate actionable summary:
#    - Top 3 priority issues
#    - Quick wins vs major refactorings
#    - Estimated effort for fixes
# 5. Create visualization-ready data
# Return structured report for easy consumption
```

### Step 8: Implement Code Metrics

Add code quality metrics calculation:

```python
def _calculate_code_metrics(self, tree: ast.Module) -&gt; Dict[str, Any]:
    """
    Calculate various code quality metrics.
    
    Args:
        tree: AST to analyze.
        
    Returns:
        Dictionary of code metrics.
    """
    # Calculate comprehensive metrics:
    # - Total lines of code
    # - Number of classes and functions
    # - Average function length
    # - Maximum nesting depth
    # - Cyclomatic complexity
    # - Comment to code ratio
```

## ✅ Progress Verificarpoint

At this point, you should have:
- ✅ Created the RefactoringAssistant base class
- ✅ Implemented long method detection
- ✅ Added parameter list smell detection
- ✅ Built duplicate code detection
- ✅ Created complex conditional detection
- ✅ Implemented comprehensive analysis

### Quick Test

Test your smell detection:

```python
# test_smells.py
sample_code = '''
def process_user_data(user_name, user_email, user_age, user_address, 
                     user_phone, user_country, user_state, user_zip):
    """Process user information - this is way too many parameters!"""
    
    # This is a long method that should be split
    if user_age &lt; 0:
        print("Invalid age")
        return None
    
    if user_age &lt; 18:
        if user_country == "US":
            if user_state == "CA":
                print("Minor in California")
            else:
                print("Minor in US")
        else:
            print("Minor international")
    else:
        if user_country == "US":
            if user_state == "CA":
                print("Adult in California")
            else:
                print("Adult in US")
        else:
            print("Adult international")
    
    # Duplicate code block 1
    user_data = {
        "name": user_name.strip().title(),
        "email": user_email.strip().lower(),
        "age": user_age
    }
    
    # More processing...
    # ... (imagine 20 more lines)
    
    # Duplicate code block 2 (similar to block 1)
    processed_data = {
        "name": user_name.strip().title(),
        "email": user_email.strip().lower(),
        "age": user_age
    }
    
    return processed_data
'''

assistant = RefactoringAssistant()
report = assistant.analyze_code(sample_code)
print(f"Found {report['total_issues']} code smells")
```

## 🎯 Partee 1 Resumo

You've successfully:
1. Built the foundation for a refactoring assistant
2. Implemented multiple code smell detectors
3. Created comprehensive code analysis
4. Generated actionable reports
5. Learned to identify problematic patterns

**Próximo**: Continuar to Partee 2 where we'll implement the actual refactoring transformations!

---

💡 **Pro Tip**: When detecting code smells, consider the context. A long method in a test file might be acceptable, while the same length in production code is problematic!