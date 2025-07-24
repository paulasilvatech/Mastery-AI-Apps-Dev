---
sidebar_position: 3
title: "Exercise 2: Part 3"
description: "## 🚀 Part 3: Testing, Validation, and CLI"
---

# Exercício 2: Refactoring Assistant - Partee 3

## 🚀 Partee 3: Testing, Validation, and CLI

### Step 18: Create Comprehensive Tests

Let's build tests to ensure our refactorings are safe. Create `tests/test_refactorings.py`:

```python
import pytest
import ast
from pathlib import Path
import tempfile
import subprocess
from refactoring_assistant import RefactoringAssistant, SmellType
from refactorings import ExtractMethodRefactoring, ParameterObjectRefactoring

class TestRefactoringAssistant:
    """Comprehensive test suite for refactoring assistant."""
    
    @pytest.fixture
    def assistant(self):
        """Create assistant instance for testing."""
        return RefactoringAssistant()
    
    @pytest.fixture
    def sample_codes(self):
        """Collection of code samples with various smells."""
        return {
            "long_method": '''
def process_data(data):
    """This method is too long."""
    result = []
    
    # Step 1: Validate data
    if not data:
        return []
    if not isinstance(data, list):
        raise ValueError("Data must be a list")
    
    # Step 2: Clean data
    for item in data:
        if item is not None:
            cleaned = str(item).strip()
            if cleaned:
                result.append(cleaned)
    
    # Step 3: Sort data
    result.sort()
    
    # Step 4: Remove duplicates
    unique_result = []
    seen = set()
    for item in result:
        if item not in seen:
            seen.add(item)
            unique_result.append(item)
    
    # Step 5: Format output
    formatted = []
    for i, item in enumerate(unique_result):
        formatted.append(f"{i+1}. {item}")
    
    return formatted
''',
            "long_params": '''
def create_user(first_name, last_name, email, phone, 
                address_line1, address_line2, city, state, 
                zip_code, country, date_of_birth):
    """Too many parameters!"""
    return {
        "name": f"{{first_name}} {{last_name}}",
        "contact": {{"email": email, "phone": phone}},
        "address": {
            "line1": address_line1,
            "line2": address_line2,
            "city": city,
            "state": state,
            "zip": zip_code,
            "country": country
        },
        "dob": date_of_birth
    }
'''
        }
    
    # Test smell detection accuracy
    # Test: Long methods are detected correctly
    # Test: Parameter lists identified accurately
    # Test: Severity levels are appropriate
    def test_smell_detection(self, assistant, sample_codes):
```

**🤖 Copilot Prompt Suggestion #11:**
```python
# Create comprehensive tests for smell detection:
# 1. Test long method detection:
#    - Methods >20 lines detected
#    - Severity increases with length
#    - Docstrings excluded from count
# 2. Test parameter detection:
#    - Functions with >4 params detected
#    - Suggestions include grouping
# 3. Test duplicate detection:
#    - Exact duplicates found
#    - Similar code blocks identified
# 4. Test complex conditionals:
#    - Nested ifs detected
#    - Guard clause opportunities found
# 5. Test edge cases:
#    - Empty files
#    - Syntax errors handled
#    - Single-line functions ignored
# Use pytest parametrize for multiple cases
```

### Step 19: Test Refactoring Safety

Add tests to ensure refactorings preserve behavior:

```python
def test_refactoring_preserves_behavior(self, assistant, sample_codes):
    """Ensure refactorings don't change code behavior."""
    
    # Test that refactored code produces same output
    # Use exec() to run before/after code
    # Compare results for various inputs
    # Verify no exceptions introduced
    
    for code_type, original_code in sample_codes.items():
        # Analyze and get smells
        analysis = assistant.analyze_code(original_code)
        
        for smell in analysis['smells']:
            # Apply refactoring
            result = assistant.apply_refactoring(original_code, smell)
            
            if result.success:
                # Test behavior preservation
                self._assert_same_behavior(
                    original_code, 
                    result.refactored_code
                )

def _assert_same_behavior(self, original: str, refactored: str):
    """Assert two code snippets have same behavior."""
    # Create test scenarios based on code
    # Execute both versions
    # Compare outputs
    # Check for exceptions
```

**🤖 Copilot Prompt Suggestion #12:**
```python
# Implement behavior preservation testing:
# 1. Create isolated execution environments:
#    - Use exec() with separate namespaces
#    - Capture stdout/stderr
# 2. Generate test inputs:
#    - Analyze function signatures
#    - Create valid test data
#    - Include edge cases
# 3. Execute both versions:
#    original_ns = {}
#    exec(original_code, original_ns)
#    refactored_ns = {}
#    exec(refactored_code, refactored_ns)
# 4. Compare results:
#    - Same return values
#    - Same exceptions raised
#    - Same side effects
# 5. Report detailed differences
# Handle async functions specially
```

### Step 20: Create Property-Based Tests

Use hypothesis for thorough testing:

```python
from hypothesis import given, strategies as st

class TestPropertyBased:
    """Property-based tests for refactoring robustness."""
    
    @given(
        num_params=st.integers(min_value=1, max_value=20),
        param_names=st.lists(
            st.text(alphabet=st.characters(whitelist_categories=('Ll',)), 
                   min_size=1, max_size=10),
            min_size=1, max_size=20, unique=True
        )
    )
    def test_parameter_object_refactoring(self, num_params, param_names):
        """Test parameter object refactoring with random inputs."""
        # Generate function with given parameters
        # Apply refactoring
        # Verify result is valid Python
        # Check parameter object created correctly
```

### Step 21: Build the CLI Tool

Create a comprehensive CLI interface:

```python
# cli.py
import click
from pathlib import Path
from rich.console import Console
from rich.table import Table
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.syntax import Syntax
from refactoring_assistant import RefactoringAssistant

console = Console()

@click.group()
@click.version_option(version="1.0.0")
def cli():
    """AI-Powered Refactoring Assistant for cleaner code."""
    pass

@cli.command()
@click.argument('path', type=click.Path(exists=True))
@click.option('--smell', '-s', 
              multiple=True,
              type=click.Choice(['long-method', 'long-params', 'duplicate', 'complex']),
              help='Specific smells to detect')
@click.option('--min-severity', 
              type=click.Choice(['low', 'medium', 'high']),
              default='low',
              help='Minimum severity to report')
@click.option('--output', '-o',
              type=click.Choice(['table', 'json', 'markdown']),
              default='table',
              help='Output format')
def analyze(path, smell, min_severity, output):
    """Analyze code for smells and quality issues."""
    assistant = RefactoringAssistant()
    
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        console=console
    ) as progress:
        task = progress.add_task("Analyzing code...", total=None)
        
        # Read file
        code = Path(path).read_text()
        
        # Analyze
        report = assistant.analyze_code(code)
        
        progress.update(task, completed=True)
    
    # Display results based on output format
    if output == 'table':
        _display_table_output(report, min_severity)
    elif output == 'json':
        _display_json_output(report)
    else:
        _display_markdown_output(report)
```

**🤖 Copilot Prompt Suggestion #13:**
```python
# Implement comprehensive CLI with these features:
# 1. Analyze command:
#    - Show detected smells in table
#    - Color-code by severity
#    - Include line numbers
# 2. Refactor command:
#    - Interactive mode by default
#    - --auto flag for automatic
#    - --dry-run for preview only
# 3. Watch command:
#    - Monitor files for changes
#    - Auto-analyze on save
#    - Show real-time metrics
# 4. Report command:
#    - Generate HTML report
#    - Include before/after comparison
#    - Add code quality trends
# Use rich for beautiful output
# Support both files and directories
```

### Step 22: Add the Refactor Command

Implement the main refactoring command:

```python
@cli.command()
@click.argument('path', type=click.Path(exists=True))
@click.option('--auto', is_flag=True, help='Apply refactorings automatically')
@click.option('--interactive', '-i', is_flag=True, default=True, 
              help='Interactive mode (default)')
@click.option('--backup', '-b', is_flag=True, default=True,
              help='Create backup before refactoring')
@click.option('--smell', '-s', multiple=True,
              type=click.Choice(['long-method', 'long-params', 'duplicate', 'complex']),
              help='Only fix specific smells')
def refactor(path, auto, interactive, backup, smell):
    """Refactor code to fix detected smells."""
    assistant = RefactoringAssistant()
    filepath = Path(path)
    
    # Create backup if requested
    if backup:
        backup_path = filepath.with_suffix(filepath.suffix + '.backup')
        backup_path.write_text(filepath.read_text())
        console.print(f"[dim]Backup created: {backup_path}[/dim]")
    
    # Read code
    original_code = filepath.read_text()
    
    # Analyze
    console.print("\n[bold]Analyzing code...[/bold]")
    report = assistant.analyze_code(original_code)
    
    if not report['smells']:
        console.print("[green]✨ No code smells detected! Your code is clean.[/green]")
        return
    
    # Filter smells if specified
    smells_to_fix = report['smells']
    if smell:
        smell_types = [_smell_name_to_type(s) for s in smell]
        smells_to_fix = [s for s in smells_to_fix if s.smell_type in smell_types]
    
    # Apply refactorings
    current_code = original_code
    applied_count = 0
    
    for code_smell in smells_to_fix:
        if interactive and not auto:
            # Show smell details
            _display_smell_detail(code_smell, current_code)
            
            # Ask for confirmation
            if not click.confirm("\nApply this refactoring?"):
                continue
        
        # Apply refactoring
        result = assistant.apply_refactoring(current_code, code_smell)
        
        if result.success:
            current_code = result.refactored_code
            applied_count += 1
            console.print(f"[green]✓ Applied: {result.refactoring_name}[/green]")
        else:
            console.print(f"[red]✗ Failed: {result.error}[/red]")
    
    # Save refactored code
    if applied_count &gt; 0:
        filepath.write_text(current_code)
        console.print(f"\n[bold green]✨ Refactoring complete![/bold green]")
        console.print(f"Applied {applied_count} refactorings to {filepath}")
```

### Step 23: Create Validation Commands

Add commands for validation and reporting:

```python
@cli.command()
@click.argument('path', type=click.Path(exists=True))
@click.option('--threshold', '-t', type=int, default=80,
              help='Quality threshold percentage')
def validate(path, threshold):
    """Validate code quality against standards."""
    # Check code quality metrics
    # Compare against threshold
    # Return appropriate exit code
    # Display quality report
```

### Step 24: Add Configuration Support

Create configuration file support:

```python
# config.py
from pydantic import BaseModel, Field
from typing import Dict, List, Optional

class RefactoringConfig(BaseModel):
    """Configuration for refactoring assistant."""
    
    # Smell detection thresholds
    long_method_threshold: int = Field(default=20, ge=10, le=100)
    long_parameter_threshold: int = Field(default=4, ge=3, le=10)
    complexity_threshold: int = Field(default=10, ge=5, le=20)
    
    # Behavior settings
    auto_backup: bool = Field(default=True)
    preserve_comments: bool = Field(default=True)
    format_after_refactor: bool = Field(default=True)
    
    # Exclusions
    exclude_patterns: List[str] = Field(default_factory=lambda: [
        "**/tests/**",
        "**/test_*.py",
        "**/*_test.py"
    ])
    
    # Style preferences
    docstring_style: str = Field(default="google", pattern="^(google|numpy|sphinx)$")
    
    @classmethod
    def from_file(cls, path: Path) -&gt; 'RefactoringConfig':
        """Load configuration from file."""
        import toml
        data = toml.load(path)
        return cls(**data)
```

### Step 25: Create the Completar Package

Finalize the complete refactoring assistant:

```python
# __main__.py
"""Entry point for refactoring assistant."""

from cli import cli

if __name__ == "__main__":
    cli()
```

Create `setup.py` for distribution:

```python
from setuptools import setup, find_packages

setup(
    name="ai-refactoring-assistant",
    version="1.0.0",
    packages=find_packages(),
    install_requires=[
        "click>=8.1.0",
        "rich>=13.0.0",
        "pydantic>=2.0.0",
        "black>=24.0.0",
        "pytest>=8.0.0",
        "hypothesis>=6.0.0"
    ],
    entry_points={
        "console_scripts": [
            "refactor=cli:cli",
        ],
    },
)
```

## ✅ Exercício Completion Verificarlist

Verify you've completed all components:

- [ ] Implemented multiple smell detectors
- [ ] Created refactoring transformations
- [ ] Built safety validation
- [ ] Added comprehensive tests
- [ ] Created interactive CLI
- [ ] Implemented batch processing
- [ ] Added configuration support
- [ ] Created backup mechanism
- [ ] Built reporting features
- [ ] Package ready for distribution

### Final Integration Test

Test the complete system:

```bash
# Install the package
pip install -e .

# Analyze a file
refactor analyze my_code.py

# Interactive refactoring
refactor refactor my_code.py --interactive

# Batch refactoring with specific smells
refactor refactor src/ --smell long-method --smell duplicate --auto

# Validate code quality
refactor validate src/ --threshold 85

# Generate report
refactor report src/ --output report.html
```

## 🎯 Exercício Resumo

Congratulations! You've built a sophisticated refactoring assistant that:

1. **Detects Code Smells** - Multiple types with severity levels
2. **Applies Refactorings** - Safe, automated transformations
3. **Preserves Behavior** - Validated through testing
4. **Provides Great UX** - Interactive CLI with rich output
5. **Supports Teams** - Configuration and standards enforcement

### Key Learnings

- Using AST for code analysis and transformation
- Building safe, automated refactoring tools
- Creating interactive developer tools
- Testing code transformations
- Building produção-ready CLI applications

## 🚀 Extensions and Challenges

### Challenge 1: Add More Refactorings
- Replace Temp with Query
- Introduce Parameter Object
- Replace Conditional with Polymorphism

### Challenge 2: IDE Integration
- Create VS Code extension
- Add real-time smell detection
- Provide quick-fix suggestions

### Challenge 3: Machine Learning
- Train model to detect custom smells
- Learn team-specific patterns
- Suggest project-specific refactorings

### Challenge 4: Metrics Painel
- Trilha code quality over time
- Show refactoring impact
- Generate team reports

## 📝 Independent Project Ideas

1. **Code Revisar Assistant** - Automatically review PRs for smells
2. **Legacy Code Modernizer** - Atualizar old Python code patterns
3. **Performance Optimizer** - Refactor for better performance
4. **Test Generator** - Create tests during refactoring

---

🎉 **Outstanding work! You've built a powerful tool that improves code quality. Continue to Exercise 3 to create a complete quality automation system!**