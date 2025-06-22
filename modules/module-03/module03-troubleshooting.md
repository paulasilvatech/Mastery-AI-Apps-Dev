# Module 03: Troubleshooting Guide

## 🔧 Common Issues and Solutions

### 🚫 Issue: Copilot Not Generating Expected Code

#### Symptoms
- Suggestions are irrelevant or incorrect
- Copilot generates generic code instead of specific solutions
- Code doesn't match requirements

#### Solutions

1. **Check Context Window**
   ```python
   # Bad: Prompt too far from context
   class UserManager:
       # ... 100 lines of code ...
   
   # Create a method to validate email
   def validate_email():  # Poor context
   ```
   
   ```python
   # Good: Prompt near relevant context
   class UserManager:
       def create_user(self, email: str):
           # Validate email first
           if not self.validate_email(email):
               raise ValueError("Invalid email")
   
       # Create a method to validate email format
       # Should check for @ symbol and domain
       def validate_email(self, email: str) -> bool:
           # Better context
   ```

2. **Improve Prompt Specificity**
   ```python
   # Bad: Too vague
   # Process the data
   def process():
       pass
   
   # Good: Specific requirements
   # Process user registration data:
   # - Validate email format (regex)
   # - Check password strength (8+ chars, mixed case, number)
   # - Ensure age >= 18
   # - Return validation errors as list
   def process_registration(self, email: str, password: str, age: int) -> List[str]:
       pass
   ```

3. **Add Examples**
   ```python
   # Include examples in comments
   # Parse duration strings to seconds
   # Examples:
   #   "1h 30m" -> 5400
   #   "45m" -> 2700
   #   "2h" -> 7200
   def parse_duration(duration_str: str) -> int:
       # Copilot understands the pattern
   ```

### 🔴 Issue: Inconsistent Code Generation

#### Symptoms
- Different suggestions for similar prompts
- Inconsistent naming conventions
- Varying code styles

#### Solutions

1. **Establish Patterns First**
   ```python
   # Define pattern with 2-3 examples
   def get_user_by_id(self, user_id: int) -> Optional[User]:
       """Get user by ID."""
       return next((u for u in self.users if u.id == user_id), None)
   
   def get_user_by_email(self, email: str) -> Optional[User]:
       """Get user by email."""
       return next((u for u in self.users if u.email == email), None)
   
   # Now Copilot follows the pattern
   def get_user_by_username(self, username: str) -> Optional[User]:
       # Copilot generates consistently
   ```

2. **Use Type Hints Consistently**
   ```python
   # Always use complete type hints
   from typing import List, Optional, Dict, Union, Tuple
   
   def process_items(
       items: List[Dict[str, Any]], 
       filter_func: Optional[Callable] = None
   ) -> Tuple[List[Dict], List[str]]:
       """Process with consistent typing."""
   ```

### ⚠️ Issue: Context Pollution

#### Symptoms
- Copilot suggests code from unrelated parts
- Mixed patterns in suggestions
- Conflicting implementations

#### Solutions

1. **Isolate Context**
   ```python
   # ============= USER MANAGEMENT =============
   # Clear section boundary
   
   class UserManager:
       # User-related code only
       pass
   
   # ============= TASK MANAGEMENT =============
   # Different section
   
   class TaskManager:
       # Task-related code only
       pass
   ```

2. **Use Separate Files**
   ```
   project/
   ├── models/
   │   ├── user.py     # User model only
   │   └── task.py     # Task model only
   ├── services/
   │   ├── auth.py     # Auth service only
   │   └── task.py     # Task service only
   ```

### 🐌 Issue: Slow or No Suggestions

#### Symptoms
- Long delay before suggestions appear
- Copilot seems unresponsive
- Partial suggestions only

#### Solutions

1. **Reduce File Size**
   ```bash
   # Check file size
   wc -l large_file.py
   
   # If > 500 lines, consider splitting
   ```

2. **Optimize Imports**
   ```python
   # Bad: Circular or heavy imports
   from .entire_module import *
   
   # Good: Specific imports
   from .models import User, Task
   ```

3. **Check Network Connection**
   ```bash
   # Test Copilot connection
   gh copilot status
   
   # If issues, re-authenticate
   gh auth refresh
   ```

### 🔄 Issue: Copilot Overwrites Custom Code

#### Symptoms
- Suggestions replace existing code
- Hard to preserve custom logic
- Conflicts with manual edits

#### Solutions

1. **Use Partial Acceptance**
   - Accept suggestions word-by-word with `Ctrl+→`
   - Review before accepting with `Tab`
   - Use `Esc` to dismiss unwanted suggestions

2. **Comment Preservation Markers**
   ```python
   def complex_function():
       # Standard logic here
       
       # CUSTOM: Do not modify this section
       custom_logic = perform_special_calculation()
       # END CUSTOM
       
       # Continue with standard logic
   ```

### 📝 Issue: Poor Documentation Generation

#### Symptoms
- Generic or unhelpful docstrings
- Missing parameter descriptions
- Incorrect return type documentation

#### Solutions

1. **Provide Docstring Template**
   ```python
   def calculate_discount(
       price: float, 
       discount_percent: float, 
       member: bool = False
   ) -> float:
       """
       Calculate discounted price with member benefits.
       
       Args:
           price: Original price in dollars
           discount_percent: Discount percentage (0-100)
           member: Whether customer is a member (additional 5% off)
           
       Returns:
           Final price after all discounts
           
       Example:
           >>> calculate_discount(100, 20, True)
           76.0
       """
       # Copilot follows the format
   ```

### 🎯 Issue: Wrong Language Patterns

#### Symptoms
- JavaScript patterns in Python code
- Wrong framework conventions
- Language-specific features missing

#### Solutions

1. **Set Language Context**
   ```python
   #!/usr/bin/env python3
   # -*- coding: utf-8 -*-
   """
   Python module using Python 3.11+ features
   Using type hints and dataclasses
   """
   
   from dataclasses import dataclass
   from typing import Optional
   ```

2. **Use Language-Specific Patterns**
   ```python
   # Python-specific patterns
   # Use list comprehension
   filtered = [x for x in items if x.active]
   
   # Use context managers
   with open('file.txt') as f:
       content = f.read()
   
   # Use f-strings
   message = f"Hello {name}, you have {count} items"
   ```

## 🛠️ Debugging Techniques

### 1. Context Inspection

```python
# Add debug comments to see what Copilot considers
# DEBUG: Current context includes:
# - UserManager class with create_user method
# - User dataclass with id, email, name
# - Import of typing and dataclasses

# Now create validation method
def validate_user_data():
    # Check if suggestions use available context
```

### 2. Progressive Building

```python
# Start simple
def process():
    pass

# Add complexity gradually
def process(data):
    pass

# Add more details
def process(data: List[Dict]) -> Dict:
    pass

# Final version
def process(data: List[Dict], options: ProcessOptions) -> ProcessResult:
    """Full implementation with all context."""
```

### 3. Pattern Testing

```python
# Test if Copilot learned your pattern
# Pattern test: Create getter method
def get_by_id(self, id: int) -> Optional[Model]:
    return self._find_one(id=id)

# Try similar prompt
def get_by_name(self, name: str) -> Optional[Model]:
    # Should follow same pattern
```

## 📊 Performance Optimization

### Improve Suggestion Speed

1. **Optimize File Structure**
   - Keep files under 500 lines
   - Use clear module boundaries
   - Minimize circular imports

2. **Reduce Context Noise**
   - Remove commented-out code
   - Clean up unused imports
   - Organize related code together

3. **VS Code Settings**
   ```json
   {
     "github.copilot.advanced": {
       "length": 500,        // Suggestion length
       "temperature": 0.1,   // Consistency vs creativity
       "top_p": 1,          // Sampling parameter
       "stops": ["\\n\\n"]  // Stop sequences
     }
   }
   ```

## 🚨 Emergency Fixes

### Copilot Completely Stopped Working

1. **Full Reset**
   ```bash
   # Sign out
   gh auth logout
   
   # Clear extension data
   # VS Code: Ctrl+Shift+P -> "Clear Editor History"
   
   # Reinstall extension
   code --uninstall-extension GitHub.copilot
   code --install-extension GitHub.copilot
   
   # Re-authenticate
   gh auth login
   ```

2. **Check Service Status**
   - Visit: https://www.githubstatus.com/
   - Check Copilot service status
   - Try again later if degraded

### Generate Debug Log

```bash
# Enable verbose logging
code --log-level=debug

# Check logs
# Windows: %APPDATA%\Code\logs
# macOS: ~/Library/Application Support/Code/logs
# Linux: ~/.config/Code/logs
```

## 📋 Prevention Checklist

### Before Writing Prompts
- [ ] File is well-organized
- [ ] Imports are clean and specific
- [ ] Related code is nearby
- [ ] Clear section boundaries exist
- [ ] Type hints are consistent

### During Prompt Writing
- [ ] Be specific about requirements
- [ ] Include examples when helpful
- [ ] Add constraints and edge cases
- [ ] Use consistent terminology
- [ ] Check context window position

### After Generation
- [ ] Review generated code carefully
- [ ] Test edge cases
- [ ] Verify type safety
- [ ] Check for security issues
- [ ] Ensure consistent style

## 🆘 Getting Additional Help

1. **Module Support**
   - GitHub Discussions: Module 03 section
   - Slack: #module-03-prompting
   - Office Hours: Tuesdays 2-3 PM PT

2. **Official Resources**
   - [GitHub Copilot Troubleshooting](https://docs.github.com/copilot/troubleshooting)
   - [VS Code Copilot Issues](https://github.com/github/copilot/issues)

3. **Community**
   - Stack Overflow: [github-copilot] tag
   - Reddit: r/githubcopilot

---

💡 **Remember**: Most issues can be resolved by improving context quality and prompt clarity. When in doubt, simplify and rebuild!