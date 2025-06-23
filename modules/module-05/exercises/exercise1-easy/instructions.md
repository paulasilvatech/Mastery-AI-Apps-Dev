# 🚀 Exercise 1: Utility Functions Library - Quick Instructions

## Overview
In this exercise, you'll create a comprehensive utility functions library while learning to use GitHub Copilot for code generation and documentation.

## Step 1: Open the starter file
```bash
cd modules/module-05/exercises/exercise1-easy/starter
code utils.py
```

## Step 2: Follow the TODOs
The file contains 8 TODO comments for different utility functions:
1. Email validation
2. Phone number formatting
3. URL parsing
4. Password generation
5. File checksum calculation
6. Temperature conversion
7. Credit card validation
8. Date parsing

## Step 3: Use Copilot to implement each function
For each TODO:
1. Read the requirements in the comment
2. Start typing the function definition
3. Let Copilot suggest the implementation
4. Review and refine the suggestion
5. Add proper type hints and docstrings

## Step 4: Test your implementation
```bash
# Run the file to see basic output
python utils.py

# Run the comprehensive test suite
cd ../tests
python -m pytest test_utils.py -v
```

## 💡 Copilot Tips
- **Be specific in comments**: The more detailed your comment, the better Copilot's suggestion
- **Use type hints**: `def function_name(param: str) -> bool:`
- **Start with docstrings**: Write the docstring first to guide Copilot
- **Iterate**: If the first suggestion isn't perfect, try rephrasing

## Example Pattern
```python
# TODO: Create a function to validate email addresses
# The function should:
# - Accept a string parameter
# - Return True if valid email, False otherwise
# - Handle common email formats

def validate_email(email: str) -> bool:
    """
    Validate email addresses using regex pattern.
    
    Args:
        email: Email address to validate
        
    Returns:
        True if valid email format, False otherwise
    """
    # Let Copilot complete this...
```

## 📋 Checklist
- [ ] All 8 functions implemented
- [ ] Type hints on all functions
- [ ] Docstrings for all functions
- [ ] Error handling where appropriate
- [ ] All tests passing

## 🎉 Success!
When all tests pass, you've successfully completed the exercise! Compare your solution with the one in the `solution/` directory.

## 📚 Further Learning
For detailed step-by-step instructions, see:
- [Part 1](../../../module-05-exercise1-part1.md) - Setup and first functions
- [Part 2](../../../module-05-exercise1-part2.md) - Advanced functions
- [Part 3](../../../module-05-exercise1-part3.md) - Testing and refinement
