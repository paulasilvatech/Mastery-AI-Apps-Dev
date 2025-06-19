# Exercise 2: Smart Calculator ⭐⭐

## Build a Natural Language Calculator with AI

Now that you've mastered basic AI assistance, let's create something more sophisticated: a calculator that understands natural language! This exercise will teach you how to use Copilot for parsing complex inputs and implementing advanced logic.

### Duration: 45-60 minutes
### Difficulty: Medium (⭐⭐)
### Success Rate: 80%

## 🎯 Learning Objectives

By completing this exercise, you will:
- ✅ Use AI to parse natural language input
- ✅ Implement complex logic with Copilot's help
- ✅ Handle multiple calculation types
- ✅ Create robust error handling
- ✅ Build a plugin-style architecture

## 📋 Requirements

Your Smart Calculator should:
1. Understand natural language math expressions
   - "What is 25 plus 17?"
   - "Calculate the square root of 144"
   - "Convert 100 fahrenheit to celsius"
2. Support basic and advanced operations
3. Remember previous results (use 'it' or 'last result')
4. Provide step-by-step explanations
5. Handle unit conversions

## 🚀 Getting Started

### Step 1: Project Setup

```bash
# Create project directory
mkdir smart-calculator
cd smart-calculator

# Create the main file
touch smart_calc.py

# Create a test file
touch test_calculator.py

# Open in VS Code
code .
```

### Step 2: Core Architecture

Start with this architectural comment in `smart_calc.py`:

```python
"""
Smart Calculator - Natural Language Math Processor
Module 01, Exercise 2

Architecture:
1. Input Parser - Converts natural language to math operations
2. Operation Handler - Executes different types of calculations
3. Memory Manager - Stores and retrieves previous results
4. Explanation Engine - Provides step-by-step solutions
5. Unit Converter - Handles various unit conversions
"""

# TODO: Import required modules including re for regex, math for calculations, and typing for type hints
```

## 📝 Implementation Guide

### Phase 1: Natural Language Parser

Use these prompts to build the parser:

```python
# Create a function to extract numbers from natural language text
# Examples: "twenty-five" -> 25, "a hundred" -> 100, "5.5" -> 5.5

# Create a function to identify math operations from words
# Examples: "plus" -> "+", "times" -> "*", "square root" -> "sqrt"

# Create a mapping of word numbers to digits
# Include: zero through twenty, thirty, forty, fifty, etc., hundred, thousand, million
```

**🎯 Copilot Tip**: Give examples in your comments! Copilot learns from patterns.

### Phase 2: Operation Handlers

Build different operation handlers:

```python
# Create a class called SmartCalculator with methods for different operations

# Basic operations: add, subtract, multiply, divide
# Advanced operations: power, square root, factorial, percentage
# Trigonometry: sin, cos, tan (in degrees)
# Statistics: average, median, mode of a list of numbers
```

### Phase 3: Memory System

Implement a result history:

```python
# Create a class to manage calculation history
# Features:
# - Store last 10 results
# - Access previous result with "it" or "last"
# - Clear history command
# - Show history command
```

### Phase 4: Explanation Engine

Add step-by-step explanations:

```python
# Create a function that explains how a calculation was performed
# Example: "15 * 4" -> "To multiply 15 by 4: 15 × 4 = 60"
# Include explanations for complex operations like percentage and square root
```

## 🧪 Test Cases

Create comprehensive tests in `test_calculator.py`:

```python
# Test natural language parsing
test_cases = [
    ("What is 5 plus 3?", 8),
    ("Calculate twenty times four", 80),
    ("What's the square root of 64?", 8),
    ("15 percent of 200", 30),
    ("Convert 32 fahrenheit to celsius", 0),
    ("What is it plus 10?", depends_on_previous),
]

# Test edge cases
edge_cases = [
    ("Divide 10 by 0", "Error: Division by zero"),
    ("Square root of negative 4", "Error: Complex number"),
    ("What is infinity plus 1?", "Error: Invalid operation"),
]
```

## 💡 Advanced Features

### Feature 1: Unit Conversions

```python
# Implement unit conversion support
# Categories: temperature, length, weight, volume, time
# Examples:
# - "Convert 100 meters to feet"
# - "How many pounds is 50 kilograms?"
# - "Change 2 hours to minutes"
```

### Feature 2: Financial Calculations

```python
# Add financial calculation capabilities
# - Compound interest: "Calculate compound interest on $1000 at 5% for 3 years"
# - Tips: "What's 18% tip on $45.50?"
# - Discounts: "What's the price after 25% off $80?"
```

### Feature 3: Smart Expressions

```python
# Handle complex natural language expressions
# - "What's the average of 10, 20, 30, and 40?"
# - "Find the hypotenuse of a triangle with sides 3 and 4"
# - "Calculate my BMI if I'm 180cm tall and weigh 75kg"
```

## 📋 Copilot Best Practices

### 1. Structured Comments
```python
# GOOD: Detailed, specific comment
# Function to parse mathematical operations from natural language
# Input: "What is twenty-five plus thirty-two?"
# Output: {"operation": "add", "operands": [25, 32]}
# Should handle: plus, minus, times, divided by, squared, square root of

# LESS EFFECTIVE: Vague comment
# Parse math from text
```

### 2. Example-Driven Development
```python
# Create a function to convert word numbers to integers
# Examples:
#   "twenty-three" -> 23
#   "one hundred and fifty" -> 150
#   "five thousand and one" -> 5001
# Handle: compound numbers, 'and' conjunctions, hyphenated numbers
```

### 3. Type Hints for Better Suggestions
```python
from typing import Union, List, Dict, Optional, Tuple

def parse_expression(text: str) -> Dict[str, Union[str, List[float]]]:
    """Copilot will understand the expected return structure better"""
    pass
```

## 🎨 Sample Implementation Structure

```python
class SmartCalculator:
    def __init__(self):
        self.history = []
        self.last_result = None
        
    def calculate(self, expression: str) -> Union[float, str]:
        """Main entry point for natural language calculations"""
        # Parse the expression
        # Execute the operation
        # Store in history
        # Return result with explanation
        pass
    
    def parse_expression(self, text: str) -> dict:
        """Convert natural language to structured operation"""
        pass
    
    def execute_operation(self, operation: dict) -> float:
        """Execute the parsed mathematical operation"""
        pass
    
    def explain_calculation(self, operation: dict, result: float) -> str:
        """Generate step-by-step explanation"""
        pass

# Interactive CLI
def main():
    calc = SmartCalculator()
    print("🧮 Smart Calculator - I understand natural language!")
    print("Try: 'What is 25 plus 17?' or 'Calculate the square root of 144'")
    print("Type 'help' for more examples or 'quit' to exit")
    
    while True:
        # Get user input
        # Process with calculator
        # Display result and explanation
        # Handle special commands (help, history, clear, quit)
        pass
```

## ✅ Completion Checklist

- [ ] Natural language parsing works for basic math
- [ ] Supports advanced operations (sqrt, power, trig)
- [ ] Memory system tracks previous results
- [ ] Provides clear explanations
- [ ] Handles unit conversions
- [ ] Robust error handling
- [ ] Clean, well-documented code
- [ ] All test cases pass

## 🎯 Success Metrics

Your calculator is complete when:
1. It can handle 90% of natural language math queries
2. Previous results can be referenced with "it"
3. Explanations are clear and educational
4. Errors are handled gracefully
5. Code is modular and extensible

## 🚀 Challenge Extensions

1. **Voice Input**: Add speech recognition
2. **Graphing**: Plot functions described in natural language
3. **Equation Solver**: Solve for x in "2x + 5 = 15"
4. **Multi-step**: Handle "Calculate 5 plus 3, then multiply by 2"
5. **Export**: Save calculation history to file

## 🎉 Congratulations!

You've built a sophisticated calculator that understands human language! This exercise demonstrated:
- Complex parsing with AI assistance
- Modular architecture design
- Advanced error handling
- User-friendly interfaces

**Ready for Exercise 3?** You'll create a Personal Assistant CLI tool that combines everything you've learned!