# Exercise 1: Documentation Generator (⭐ Easy)

## 🎯 Exercise Overview

**Duration**: 30-45 minutes  
**Difficulty**: ⭐ (Easy)  
**Success Rate**: 95%

In this foundational exercise, you'll build an AI-powered documentation generator that automatically creates comprehensive documentation for Python code. You'll learn how to use GitHub Copilot to generate docstrings, create README files, and build API documentation that stays synchronized with your code.

## 🎓 Learning Objectives

By completing this exercise, you will:
- Generate comprehensive docstrings using AI
- Create multiple documentation formats (Google, NumPy, Sphinx)
- Build automated README generators
- Extract and format API documentation
- Implement documentation validation

## 📋 Prerequisites

- ✅ Module 05 prerequisites completed
- ✅ VS Code with Python Docstring Generator extension
- ✅ Understanding of Python functions and classes
- ✅ Basic markdown knowledge

## 🏗️ What You'll Build

A **Smart Documentation Generator** that:
- Analyzes Python code structure
- Generates appropriate docstrings
- Creates README files automatically
- Exports API documentation
- Validates documentation completeness

## 📁 Project Structure

```
exercise1-easy/
├── README.md               # This file
├── instructions/
│   ├── part1.md           # Setup and basics (this file)
│   ├── part2.md           # Advanced features
│   └── part3.md           # Testing and validation
├── starter/
│   ├── doc_generator.py   # Main generator code
│   ├── templates/         # Documentation templates
│   └── sample_code.py     # Code to document
├── solution/
│   ├── doc_generator.py   # Complete solution
│   ├── templates/
│   ├── tests/
│   └── examples/
└── resources/
    ├── docstring_formats.md
    └── markdown_guide.md
```

## 🚀 Part 1: Setting Up the Documentation Generator

### Step 1: Understanding Documentation Formats

Before we start coding, let's understand the three main Python docstring formats:

**Google Style:**
```python
def function(arg1: str, arg2: int) -> bool:
    """Brief description.
    
    Args:
        arg1: Description of arg1.
        arg2: Description of arg2.
        
    Returns:
        Description of return value.
        
    Raises:
        ValueError: If arg2 is negative.
    """
```

**NumPy Style:**
```python
def function(arg1: str, arg2: int) -> bool:
    """
    Brief description.
    
    Parameters
    ----------
    arg1 : str
        Description of arg1.
    arg2 : int
        Description of arg2.
        
    Returns
    -------
    bool
        Description of return value.
    """
```

**Sphinx Style:**
```python
def function(arg1: str, arg2: int) -> bool:
    """Brief description.
    
    :param arg1: Description of arg1.
    :type arg1: str
    :param arg2: Description of arg2.
    :type arg2: int
    :returns: Description of return value.
    :rtype: bool
    :raises ValueError: If arg2 is negative.
    """
```

### Step 2: Create the Base Documentation Generator

Navigate to the starter directory and open `doc_generator.py`:

```bash
cd exercises/exercise1-easy/starter
code doc_generator.py
```

Start with this template:
```python
#!/usr/bin/env python3
"""
Smart Documentation Generator
Automatically generates comprehensive documentation for Python code
"""

import ast
import inspect
from typing import List, Dict, Optional, Any, Union
from pathlib import Path
from enum import Enum
import json

class DocStyle(Enum):
    """Documentation style formats."""
    GOOGLE = "google"
    NUMPY = "numpy"
    SPHINX = "sphinx"

# Create a class that generates documentation for Python code
# The class should:
# - Parse Python files using AST (Abstract Syntax Tree)
# - Extract function and class information
# - Generate docstrings in multiple formats
# - Create README files with API documentation
# - Support type hints and annotations
class DocumentationGenerator:
```

**🤖 Copilot Prompt Suggestion #1:**
```python
# After typing the class definition, add this detailed comment:
# The DocumentationGenerator should have these methods:
# - __init__(self, style: DocStyle = DocStyle.GOOGLE)
# - parse_file(self, filepath: Path) -> ast.Module
# - extract_functions(self, tree: ast.Module) -> List[Dict]
# - extract_classes(self, tree: ast.Module) -> List[Dict]
# - generate_docstring(self, func_info: Dict) -> str
# - generate_readme(self, module_info: Dict) -> str
# Include error handling and validation
```

**Expected Output:**
Copilot should generate a complete class structure with all methods initialized. The class will handle file parsing, information extraction, and documentation generation.

### Step 3: Implement File Parsing

Add the file parsing functionality:

```python
def parse_file(self, filepath: Path) -> ast.Module:
    """
    Parse a Python file and return its AST.
    
    Args:
        filepath: Path to the Python file to parse.
        
    Returns:
        Parsed AST module.
        
    Raises:
        FileNotFoundError: If the file doesn't exist.
        SyntaxError: If the file contains invalid Python syntax.
    """
    # Implementation here
```

**🤖 Copilot Prompt Suggestion #2:**
```python
# Inside parse_file method, add:
# Read the file content safely
# Parse using ast.parse()
# Handle encoding issues (utf-8)
# Add helpful error messages
# Return the parsed tree
```

### Step 4: Extract Function Information

Create a method to extract function details:

```python
def extract_functions(self, tree: ast.Module) -> List[Dict[str, Any]]:
    """
    Extract all function definitions from an AST.
    
    Args:
        tree: Parsed AST module.
        
    Returns:
        List of function information dictionaries containing:
        - name: Function name
        - args: List of arguments with types
        - returns: Return type annotation
        - decorators: List of decorators
        - docstring: Existing docstring if any
        - lineno: Line number in source
    """
    # Implementation here
```

**🤖 Copilot Prompt Suggestion #3:**
```python
# Extract function information by:
# - Walking the AST with ast.walk()
# - Identifying FunctionDef nodes
# - Extracting argument names and type annotations
# - Getting return type from node.returns
# - Extracting existing docstring with ast.get_docstring()
# - Collecting decorator names
# Return structured information for each function
```

### Step 5: Create Docstring Templates

Let's create template generators for each documentation style:

```python
def _google_style_docstring(self, func_info: Dict[str, Any]) -> str:
    """Generate Google-style docstring from function information."""
    # Create a properly formatted Google-style docstring
    # Include:
    # - Brief description (auto-generated from function name)
    # - Args section with type annotations
    # - Returns section if applicable
    # - Raises section for common exceptions
    # - Examples section with usage
```

**🤖 Copilot Prompt Suggestion #4:**
```python
# Generate Google-style docstring:
# Start with brief description based on function name
# Create Args section:
#   - List each argument with its type
#   - Add placeholder descriptions
# Add Returns section if return type exists
# Include Raises section for common exceptions
# Add Examples section with function call
# Use proper indentation and formatting
```

### Step 6: Implement Class Documentation

Add support for documenting classes:

```python
def extract_classes(self, tree: ast.Module) -> List[Dict[str, Any]]:
    """
    Extract all class definitions from an AST.
    
    Args:
        tree: Parsed AST module.
        
    Returns:
        List of class information dictionaries.
    """
    # Extract class information including:
    # - Class name and bases
    # - Class docstring
    # - Methods with their signatures
    # - Class attributes
    # - Properties and decorators
```

## ✅ Progress Checkpoint

At this point, you should have:
- ✅ Created the DocumentationGenerator class structure
- ✅ Implemented file parsing with AST
- ✅ Created function extraction logic
- ✅ Started docstring generation templates
- ✅ Added class extraction support

### Quick Test

Test your progress with this code:

```python
# test_basic.py
def calculate_sum(a: int, b: int) -> int:
    return a + b

class Calculator:
    def multiply(self, x: float, y: float) -> float:
        return x * y

# Test the generator
if __name__ == "__main__":
    gen = DocumentationGenerator()
    tree = gen.parse_file(Path("test_basic.py"))
    functions = gen.extract_functions(tree)
    print(f"Found {len(functions)} functions")
```

## 🎯 Part 1 Summary

You've successfully:
1. Set up the documentation generator structure
2. Implemented Python file parsing using AST
3. Created function and class extraction logic
4. Started building docstring templates
5. Learned to guide Copilot for documentation tasks

**Next**: Continue to Part 2 where we'll add advanced features including README generation, API documentation export, and multiple format support!

---

💡 **Pro Tip**: When using Copilot for documentation, provide examples of the desired format in comments. Copilot learns from patterns and will generate consistent documentation!