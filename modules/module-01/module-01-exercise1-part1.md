# Exercise 1: First AI Code (⭐ Easy) - Part 1

## 🎯 Exercise Overview

**Duration**: 30-45 minutes  
**Difficulty**: ⭐ (Easy)  
**Success Rate**: 95%

Welcome to your first hands-on experience with GitHub Copilot! In this foundational exercise, you'll learn how to write AI-assisted code by creating a collection of utility functions. You'll discover how to guide Copilot with comments, accept suggestions, and iterate on generated code.

## 🎓 Learning Objectives

By completing this exercise, you will:
- Write your first AI-generated functions
- Master basic prompt patterns
- Learn to accept, reject, and modify suggestions
- Understand how context affects AI suggestions
- Build confidence with Copilot workflow

## 📋 Prerequisites

- ✅ VS Code with GitHub Copilot installed
- ✅ Python 3.11+ environment active
- ✅ Copilot icon visible in status bar
- ✅ Basic Python knowledge

## 🏗️ What You'll Build

A **Utility Functions Library** containing:
- String manipulation functions
- Data validation utilities
- Mathematical calculations
- Date/time helpers
- File handling utilities

## 📁 Project Structure

```
exercise1-easy/
├── README.md               # This file
├── instructions/
│   ├── part1.md           # Setup and basics (this file)
│   ├── part2.md           # Writing functions
│   └── part3.md           # Testing and validation
├── starter/
│   ├── utils.py           # Main file to work in
│   └── test_utils.py      # Test file
├── solution/
│   ├── utils.py           # Complete solution
│   ├── test_utils.py      # All tests
│   └── examples.py        # Usage examples
└── resources/
    └── prompt-guide.md    # Prompt templates
```

## 🚀 Part 1: Setting Up and Understanding Copilot

### Step 1: Understanding How Copilot Works

Before writing code, let's understand Copilot's behavior:

1. **Context Window**: Copilot reads your current file and related files
2. **Trigger Points**: Suggestions appear when you:
   - Write a comment describing what you want
   - Start typing a function name
   - Press Enter after a function signature
   - Type common patterns (for, if, class, etc.)

3. **Suggestion Types**:
   - **Single line**: Quick completions
   - **Multi-line**: Full functions or blocks
   - **Ghost text**: Gray preview text

### Step 2: Set Up Your Workspace

1. Open VS Code in the exercise directory:
   ```bash
   cd exercises/exercise1-easy
   code .
   ```

2. Open `starter/utils.py`:
   ```python
   """
   Utility Functions Library
   A collection of helpful functions for common programming tasks.
   """
   
   # Your code will go here
   ```

3. Check Copilot is active:
   - Look for the Copilot icon in the status bar
   - It should say "GitHub Copilot" when you hover
   - If it shows an error, sign in again

### Step 3: Your First AI-Generated Function

Let's create a simple function to validate email addresses:

1. In `utils.py`, type this comment:
   ```python
   # Create a function that validates email addresses
   # It should check for @ symbol and domain
   # Return True if valid, False otherwise
   ```

2. Press Enter and start typing:
   ```python
   def validate_email(
   ```

3. **Watch the Magic!** 🎩
   - Copilot should suggest the rest of the function signature
   - You'll see gray "ghost text" with the suggestion
   - Press `Tab` to accept the suggestion

**🤖 Copilot Prompt Suggestion #1:**
```python
# Create a function that validates email addresses
# It should check for @ symbol and domain
# Return True if valid, False otherwise
def validate_email(email: str) -> bool:
```

**Expected Output:**
```python
def validate_email(email: str) -> bool:
    """
    Validate an email address.
    
    Args:
        email: The email address to validate.
        
    Returns:
        True if valid, False otherwise.
    """
    if not email or '@' not in email:
        return False
    
    parts = email.split('@')
    if len(parts) != 2:
        return False
    
    local, domain = parts
    if not local or not domain:
        return False
    
    if '.' not in domain:
        return False
    
    return True
```

### Step 4: Working with Suggestions

Now let's practice different ways to interact with Copilot:

**Accepting Suggestions:**
- `Tab` - Accept the current suggestion
- `Ctrl+Enter` - Open Copilot panel with 10 suggestions

**Rejecting Suggestions:**
- `Esc` - Dismiss the current suggestion
- Keep typing - Override with your own code

**Navigating Suggestions:**
- `Alt+]` - Next suggestion
- `Alt+[` - Previous suggestion

### Step 5: Understanding Context Impact

Copilot's suggestions improve with better context. Let's see this in action:

1. **Minimal Context:**
   ```python
   # Function to check palindrome
   def is_palindrome(
   ```
   
   Copilot might suggest a basic implementation.

2. **Rich Context:**
   ```python
   # Check if a string is a palindrome
   # - Ignore case differences
   # - Ignore spaces and punctuation
   # - Handle empty strings (return True)
   # Examples: "A man a plan a canal Panama" -> True
   #          "race a car" -> False
   def is_palindrome(
   ```
   
   Now Copilot will suggest a more sophisticated implementation!

**🤖 Copilot Prompt Suggestion #2:**
```python
# Check if a string is a palindrome
# - Ignore case differences
# - Ignore spaces and punctuation  
# - Handle empty strings (return True)
# Examples: "A man a plan a canal Panama" -> True
#          "race a car" -> False
def is_palindrome(s: str) -> bool:
```

**Expected Output:**
```python
def is_palindrome(s: str) -> bool:
    """
    Check if a string is a palindrome.
    
    Args:
        s: The string to check.
        
    Returns:
        True if palindrome, False otherwise.
    """
    # Remove non-alphanumeric characters and convert to lowercase
    cleaned = ''.join(c.lower() for c in s if c.isalnum())
    
    # Empty string is considered a palindrome
    if not cleaned:
        return True
    
    # Check if string equals its reverse
    return cleaned == cleaned[::-1]
```

### Step 6: Common Copilot Patterns

Here are patterns that trigger good suggestions:

1. **Descriptive Comments:**
   ```python
   # Calculate the factorial of a number using recursion
   # Handle negative numbers by returning None
   ```

2. **Type Hints:**
   ```python
   def calculate_discount(price: float, discount_percent: float) -> float:
   ```

3. **Docstring Templates:**
   ```python
   def function_name():
       """
       Brief description.
       
       Args:
       Returns:
       Raises:
       """
   ```

4. **Test Functions:**
   ```python
   def test_validate_email():
       # Test valid emails
       # Test invalid emails
       # Test edge cases
   ```

## 🎯 Part 1 Summary

You've learned:
1. How Copilot reads context and generates suggestions
2. Keyboard shortcuts for accepting/rejecting suggestions
3. The importance of descriptive comments
4. How context quality affects suggestion quality

**Next Steps:**
- Continue to [Part 2](part2.md) to write more complex functions
- Practice accepting and modifying suggestions
- Experiment with different prompt styles

---

💡 **Pro Tip**: The more specific your comments, the better Copilot's suggestions. Think of it as pair programming with a very fast typist who needs clear instructions!