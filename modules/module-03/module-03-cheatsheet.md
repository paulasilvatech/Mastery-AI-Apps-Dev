# Module 03: Effective Prompting - Quick Reference

## 🚀 Essential Shortcuts

| Action | Shortcut | Description |
|--------|----------|-------------|
| Accept suggestion | `Tab` | Accept entire suggestion |
| Accept word | `Ctrl+→` | Accept next word only |
| See alternatives | `Alt+]` | Cycle through suggestions |
| Dismiss | `Esc` | Close suggestion |
| Trigger manually | `Alt+\` | Force suggestion |

## 📝 Prompt Formula

```
[CONTEXT] + [INTENT] + [CONSTRAINTS] + [EXAMPLES] = Great Code
```

### Example
```python
# [CONTEXT] Working with user authentication
# [INTENT] Create a password validation function
# [CONSTRAINTS] Min 8 chars, uppercase, lowercase, number, special char
# [EXAMPLES] "Pass123!" -> True, "weak" -> False
def validate_password(password: str) -> bool:
    # Copilot generates comprehensive validation
```

## 🎯 Effective Prompt Patterns

### 1. The Specification Pattern
```python
# SPEC: Function to [action]
# Input: [type and description]
# Output: [type and description]
# Rules: [business logic]
# Edge cases: [special handling]
```

### 2. The Example Pattern
```python
# Examples:
#   Input -> Output
#   "1h" -> 3600
#   "30m" -> 1800
#   "1h 30m" -> 5400
```

### 3. The Algorithm Pattern
```python
# Algorithm:
# 1. [First step]
# 2. [Second step]
# 3. [Continue...]
# Complexity: O(n)
```

### 4. The TODO Pattern
```python
# TODO: Implement function that:
# - [Requirement 1]
# - [Requirement 2]
# - [Requirement 3]
```

## 🏗️ Context Optimization

### Good Context Structure
```python
# 1. Imports (establishes dependencies)
from typing import List, Optional
import datetime

# 2. Type definitions (shows data structures)
@dataclass
class User:
    id: int
    email: str

# 3. Related functions (shows patterns)
def get_user(id: int) -> Optional[User]:
    pass

# 4. Your prompt here (informed by context above)
def validate_user(user: User) -> bool:
    # Copilot has full context
```

## 💡 Quick Tips

### DO ✅
- **Be Specific**: "validate email with regex" > "check email"
- **Use Types**: Always include type hints
- **Show Patterns**: 2-3 examples before expecting pattern following
- **Group Related**: Keep similar functions together
- **Comment Intent**: Explain the why, not just what

### DON'T ❌
- **Be Vague**: "do something with data"
- **Skip Types**: Avoid `def func(x, y):`
- **Mix Contexts**: Don't jumble unrelated code
- **Over-comment**: Don't comment obvious code
- **Trust Blindly**: Always review generated code

## 🔧 Common Fixes

| Problem | Quick Fix |
|---------|-----------|
| Wrong suggestions | Add more specific context |
| No suggestions | Check file size, reduce complexity |
| Generic code | Add examples and constraints |
| Wrong patterns | Establish pattern with 2-3 examples |
| Slow response | Reduce file size, clean imports |

## 📊 Prompt Templates

### CRUD Operations
```python
# Create [entity] with validation
# Validate: [fields to check]
# Return: [entity] object or raise [Exception]
# Side effects: [any additional actions]
```

### Data Processing
```python
# Process [data type] with these steps:
# 1. Filter: [criteria]
# 2. Transform: [operations]
# 3. Aggregate: [grouping]
# Return: [output format]
```

### API Endpoint
```python
# HTTP [METHOD] /api/[endpoint]
# Auth: [required/optional]
# Body: {example json}
# Returns: {example response}
# Errors: [status codes and meanings]
```

## 🎨 Comment Strategies

### Strategic Placement
```python
class DataProcessor:
    def __init__(self):
        # Copilot sees class context
        pass
    
    # SECTION: Validation Methods
    # ===========================
    
    # Validate with specific rules
    def validate_data(self, data):
        # Context is clear
```

### Context Boundaries
```python
# ========== AUTHENTICATION ==========
# Authentication-related code here

# ========== DATA PROCESSING ==========
# Data processing code here
```

## 📈 Effectiveness Metrics

Track your prompt success:
- **First-try success**: Aim for 70%+
- **Modification time**: Under 2 minutes
- **Code accuracy**: 90%+ correct logic
- **Pattern reuse**: High is good

## 🔍 Debug Commands

```python
# Debug: Show what context Copilot sees
# Current file: task_manager.py
# Imports: typing, datetime, dataclasses
# Classes: Task, TaskManager
# Recent methods: add_task, get_task

# Now implement: [your function]
```

## 🚀 Advanced Techniques

### 1. Progressive Enhancement
```python
# Start simple
def process(data): pass

# Add details
def process(data: List[Dict]) -> Dict: pass

# Full spec
def process(data: List[Dict], 
           options: Options = None) -> ProcessResult:
    """Complete implementation."""
```

### 2. Pattern Priming
```python
# Prime with pattern
async def fetch_user(id: int) -> User:
    return await db.get(User, id)

async def fetch_task(id: int) -> Task:
    return await db.get(Task, id)

# Now similar pattern works
async def fetch_project(id: int) -> Project:
    # Follows established pattern
```

## 📋 Pre-Flight Checklist

Before writing a prompt:
- [ ] Context is organized
- [ ] Types are defined
- [ ] Examples ready (if needed)
- [ ] Requirements clear
- [ ] Pattern established (if applicable)

## 🆘 Emergency Kit

```bash
# Copilot not working?
gh copilot status
gh auth refresh

# VS Code issues?
# Reload: Ctrl+Shift+P -> "Reload Window"
# Reset: Disable/Enable extension

# Still stuck?
# Check: https://githubstatus.com
```

---

📌 **Keep this handy while coding. Effective prompting is a skill—practice makes perfect!**