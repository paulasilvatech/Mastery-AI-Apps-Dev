---
sidebar_position: 5
title: "Exercise 2: Part 2"
description: "## 🚀 Part 2: Implementing Refactoring Transformations"
---

# Ejercicio 2: Refactoring Assistant - Partee 2

## 🚀 Partee 2: Implementing Refactoring Transformations

### Step 9: Create Refactoring Base Classes

Let's build the infrastructure for applying refactorings. Create `refactorings/base.py`:

```python
from abc import ABC, abstractmethod
from typing import Optional, Tuple
import ast

class Refactoring(ABC):
    """Base class for all refactoring operations."""
    
    def __init__(self, name: str, description: str):
        self.name = name
        self.description = description
    
    @abstractmethod
    def can_apply(self, node: ast.AST, smell: CodeSmell) -&gt; bool:
        """Check if this refactoring can be applied."""
        pass
    
    @abstractmethod
    def apply(self, code: str, smell: CodeSmell) -&gt; Tuple[str, str]:
        """
        Apply the refactoring.
        
        Returns:
            Tuple of (refactored_code, explanation)
        """
        pass
    
    @abstractmethod
    def preview(self, code: str, smell: CodeSmell) -&gt; str:
        """Generate a preview of the refactoring."""
        pass
```

### Step 10: Implement Extract Method Refactoring

Create the most common refactoring - Extract Method:

```python
class ExtractMethodRefactoring(Refactoring):
    """Extract a portion of a long method into a separate method."""
    
    def __init__(self):
        super().__init__(
            "Extract Method",
            "Extract code into a new method to reduce method length"
        )
    
    def apply(self, code: str, smell: CodeSmell) -&gt; Tuple[str, str]:
        """
        Extract part of a long method into a new method.
        
        Args:
            code: Original code
            smell: Long method smell to fix
            
        Returns:
            Refactored code and explanation
        """
        # Parse the code and find the long method
        # Identify logical blocks that can be extracted
        # Create new method with appropriate parameters
        # Replace original code with method call
        # Ensure variable scope is maintained
```

**🤖 Copilot Prompt Suggestion #6:**
```python
# Implement Extract Method refactoring:
# 1. Parse code and locate the long method using smell.location
# 2. Analyze method body to find extractable blocks:
#    - Loops with independent logic
#    - Conditional blocks with cohesive purpose
#    - Sequential statements with single responsibility
# 3. Determine required parameters:
#    - Variables used but not defined in block
#    - Variables modified and used later
# 4. Generate new method:
#    - Create descriptive name from block purpose
#    - Add parameters and return values
#    - Include appropriate docstring
# 5. Replace original code with method call
# 6. Place new method after current method
# Return refactored code with explanation
```

### Step 11: Implement Parameter Object Refactoring

Handle long parameter lists:

```python
class ParameterObjectRefactoring(Refactoring):
    """Replace long parameter list with parameter object."""
    
    def apply(self, code: str, smell: CodeSmell) -&gt; Tuple[str, str]:
        """
        Create a parameter object for long parameter lists.
        
        Args:
            code: Original code
            smell: Long parameter list smell
            
        Returns:
            Refactored code and explanation
        """
        # Analyze parameters for logical groupings
        # Create dataclass or named tuple
        # Update function signature
        # Update all function calls
        # Add backward compatibility if needed
```

**🤖 Copilot Prompt Suggestion #7:**
```python
# Implement Parameter Object refactoring:
# 1. Extract function with long parameter list
# 2. Identify parameter groups:
#    - Common prefixes (user_*, address_*)
#    - Related concepts (start/end dates)
#    - Domain objects (customer info)
# 3. Create parameter classes:
#    - Use @dataclass for simplicity
#    - Include validation if appropriate
#    - Add helpful methods
# 4. Update function signature:
#    - Replace grouped params with object
#    - Keep ungrouped params separate
# 5. Update function body:
#    - Access params through object
#    - Maintain same logic
# 6. Find and update all callers
# Use semantic naming for parameter objects
```

### Step 12: Implement Remove Duplication Refactoring

Create a refactoring to eliminate duplicate code:

```python
class RemoveDuplicationRefactoring(Refactoring):
    """Remove duplicate code by extracting to shared method."""
    
    def apply(self, code: str, smell: CodeSmell) -&gt; Tuple[str, str]:
        """
        Remove duplicate code blocks.
        
        Args:
            code: Original code with duplication
            smell: Duplicate code smell
            
        Returns:
            Refactored code without duplication
        """
        # Identify all instances of duplicate code
        # Find common location for extracted method
        # Handle variable name differences
        # Create parameterized shared method
        # Replace all duplicates with method calls
```

### Step 13: Implement Guard Clause Refactoring

Simplify complex conditionals:

```python
class GuardClauseRefactoring(Refactoring):
    """Replace nested conditionals with guard clauses."""
    
    def apply(self, code: str, smell: CodeSmell) -&gt; Tuple[str, str]:
        """
        Convert nested conditionals to guard clauses.
        
        Args:
            code: Code with complex conditionals
            smell: Complex conditional smell
            
        Returns:
            Refactored code with guard clauses
        """
        # Identify nested if statements
        # Convert to early returns
        # Flatten the conditional logic
        # Improve readability
```

**🤖 Copilot Prompt Suggestion #8:**
```python
# Implement Guard Clause refactoring:
# 1. Find deeply nested conditionals
# 2. Identify conditions that can exit early
# 3. Convert pattern:
#    if condition:
#        # lots of code
#    else:
#        return error
#    To:
#    if not condition:
#        return error
#    # lots of code (un-indented)
# 4. Apply recursively for multiple levels
# 5. Preserve logic and side effects
# 6. Improve variable names if needed
# Result should be flatter, more readable code
```

### Step 14: Create Refactoring Orchestrator

Build a system to apply refactorings intelligently:

```python
class RefactoringOrchestrator:
    """Orchestrates the application of refactorings."""
    
    def __init__(self):
        self.refactorings = {
            SmellType.LONG_METHOD: ExtractMethodRefactoring(),
            SmellType.LONG_PARAMETER_LIST: ParameterObjectRefactoring(),
            SmellType.DUPLICATE_CODE: RemoveDuplicationRefactoring(),
            SmellType.COMPLEX_CONDITIONAL: GuardClauseRefactoring(),
        }
    
    def suggest_refactoring(self, smell: CodeSmell) -&gt; Refactoring:
        """Suggest the best refactoring for a code smell."""
        return self.refactorings.get(smell.smell_type)
    
    def apply_refactoring(self, code: str, smell: CodeSmell) -&gt; RefactoringResult:
        """
        Apply appropriate refactoring for the smell.
        
        Args:
            code: Original code
            smell: Detected code smell
            
        Returns:
            RefactoringResult with new code and details
        """
        # Select appropriate refactoring
        # Check if it can be applied
        # Apply the refactoring
        # Validate the result
        # Return detailed result
```

### Step 15: Implement Safe Refactoring

Add safety checks to ensure refactorings don't break code:

```python
def safe_refactor(self, code: str, smell: CodeSmell) -&gt; RefactoringResult:
    """
    Safely apply refactoring with validation.
    
    Args:
        code: Original code
        smell: Code smell to fix
        
    Returns:
        RefactoringResult with success status
    """
    # Create backup of original code
    # Apply refactoring in try/except
    # Parse refactored code to check syntax
    # Run basic semantic checks
    # Compare behavior if possible
    # Rollback on failure
```

**🤖 Copilot Prompt Suggestion #9:**
```python
# Implement safe refactoring with these steps:
# 1. Create snapshot of original code
# 2. Try to apply refactoring:
#    try:
#        refactored_code = refactoring.apply(code, smell)
#    except Exception as e:
#        return RefactoringResult(success=False, error=str(e))
# 3. Validate syntax:
#    - Parse with ast.parse()
#    - Check for syntax errors
# 4. Semantic validation:
#    - Ensure all variables still defined
#    - Check function signatures match calls
#    - Verify imports still valid
# 5. Generate diff for review:
#    - Use difflib for readable diff
#    - Highlight changes clearly
# 6. Return comprehensive result
# Include rollback mechanism
```

### Step 16: Create Interactive Refactoring

Build an interactive refactoring experience:

```python
class InteractiveRefactoring:
    """Provides interactive refactoring with preview."""
    
    def __init__(self, assistant: RefactoringAssistant):
        self.assistant = assistant
        self.console = Console()
    
    def refactor_file(self, filepath: Path) -&gt; None:
        """
        Interactively refactor a Python file.
        
        Args:
            filepath: Path to file to refactor
        """
        # Read file content
        code = filepath.read_text()
        
        # Analyze for smells
        report = self.assistant.analyze_code(code)
        
        # Show analysis results
        self._display_analysis(report)
        
        # For each smell, offer refactoring
        for smell in report['smells']:
            if self._prompt_for_refactoring(smell):
                # Show preview
                preview = self._generate_preview(code, smell)
                self._display_preview(preview)
                
                # Apply if confirmed
                if self._confirm_refactoring():
                    result = self.assistant.apply_refactoring(code, smell)
                    if result.success:
                        code = result.refactored_code
                        self.console.print("[green]✓ Refactoring applied![/green]")
        
        # Save refactored file
        self._save_refactored_file(filepath, code)
```

### Step 17: Add Batch Refactoring

Enable refactoring multiple files:

```python
def refactor_project(self, 
                    project_path: Path,
                    auto_apply: bool = False,
                    smell_filter: Optional[List[SmellType]] = None) -&gt; Dict:
    """
    Refactor an entire project.
    
    Args:
        project_path: Root directory of project
        auto_apply: Apply refactorings without confirmation
        smell_filter: Only fix specific smell types
        
    Returns:
        Summary of refactorings applied
    """
    results = {
        "files_analyzed": 0,
        "smells_found": 0,
        "refactorings_applied": 0,
        "files_modified": 0
    }
    
    # Find all Python files
    # Analyze each file
    # Apply refactorings based on settings
    # Generate comprehensive report
    # Create backup before modifications
```

**🤖 Copilot Prompt Suggestion #10:**
```python
# Implement batch refactoring:
# 1. Discover Python files recursively
#    - Skip __pycache__, venv, etc.
# 2. Process each file:
#    - Analyze for smells
#    - Filter by smell_filter if provided
#    - Sort by severity
# 3. Apply refactorings:
#    - If auto_apply, apply high-severity first
#    - Otherwise, generate report for review
# 4. Track changes:
#    - Original vs refactored line counts
#    - Number of each smell type fixed
#    - Time taken per file
# 5. Generate summary report:
#    - Markdown format
#    - Include before/after metrics
#    - List all changes made
# 6. Create git-friendly backup
# Support dry-run mode
```

## ✅ Progress Verificarpoint

At this point, you should have:
- ✅ Created refactoring base classes
- ✅ Implemented Extract Method refactoring
- ✅ Built Parameter Object refactoring
- ✅ Added Remove Duplication refactoring
- ✅ Created Guard Clause refactoring
- ✅ Built refactoring orchestrator
- ✅ Added safety mechanisms
- ✅ Implemented interactive mode

### Testing Refactorings

Test your refactorings with this example:

```python
# test_refactoring.py
code_with_smells = '''
def calculate_price(item_name, item_quantity, item_price, 
                   customer_name, customer_email, customer_level,
                   discount_percent, tax_rate, shipping_cost):
    """Calculate total price - needs refactoring!"""
    
    # Complex nested conditionals
    if customer_level == "gold":
        if item_quantity &gt; 10:
            if discount_percent &gt; 0:
                base_discount = 0.2
            else:
                base_discount = 0.15
        else:
            if discount_percent &gt; 0:
                base_discount = 0.1
            else:
                base_discount = 0.05
    else:
        if item_quantity &gt; 10:
            base_discount = 0.05
        else:
            base_discount = 0
    
    # Calculate base price
    subtotal = item_quantity * item_price
    discount_amount = subtotal * (base_discount + discount_percent)
    
    # Apply discount
    discounted_price = subtotal - discount_amount
    
    # Add tax
    tax_amount = discounted_price * tax_rate
    total_with_tax = discounted_price + tax_amount
    
    # Add shipping
    final_total = total_with_tax + shipping_cost
    
    return final_total
'''

assistant = RefactoringAssistant()
analysis = assistant.analyze_code(code_with_smells)

for smell in analysis['smells']:
    print(f"\nFound: {smell.smell_type.name}")
    print(f"Suggestion: {smell.suggestion}")
    
    # Apply refactoring
    result = assistant.apply_refactoring(code_with_smells, smell)
    if result.success:
        print("Refactoring preview:")
        print(result.preview)
```

## 🎯 Partee 2 Resumen

You've successfully:
1. Built multiple refactoring implementations
2. Created safety mechanisms for refactoring
3. Implemented interactive refactoring mode
4. Added batch processing capabilities
5. Learned to transform code while preserving behavior

**Siguiente**: Continuar to Partee 3 where we'll add testing, validation, and create a complete CLI tool!

---

💡 **Pro Tip**: Always create a backup before applying refactorings. Even with safety checks, it's better to be able to rollback changes quickly!