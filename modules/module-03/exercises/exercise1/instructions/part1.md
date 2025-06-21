# Exercise 1: Context Optimization Workshop - Part 1

## 🎯 Part 1: Context Basics (10-15 minutes)

In this part, you'll learn the fundamentals of how GitHub Copilot uses context to generate suggestions and how to structure your code for optimal results.

## 📚 Understanding Context Windows

### What is a Context Window?

The context window is the "viewport" of code that Copilot analyzes to generate suggestions. Think of it as Copilot's field of vision.

```
┌─────────────────────────────────┐
│  Previous code (context)        │ ← ~20 lines
├─────────────────────────────────┤
│  Your cursor position ▼         │ ← Current line
├─────────────────────────────────┤
│  Following code (context)       │ ← ~20 lines
└─────────────────────────────────┘
```

### Context Hierarchy

1. **Immediate Context** (Highest Priority)
   - Code immediately around cursor
   - Current function/class
   - Recent variables

2. **File Context** (Medium Priority)
   - Imports at top of file
   - Class definitions
   - Global variables

3. **Workspace Context** (Lower Priority)
   - Imported modules
   - Similar filenames
   - Project patterns

## 🛠️ Hands-On Exercise

### Step 1: Create the Basic Structure

Open `starter/task_manager.py` and start with this structure:

```python
#!/usr/bin/env python3
"""
Task Manager Application
Demonstrates context optimization for GitHub Copilot
"""

from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any
from dataclasses import dataclass, field
import json

# Place your cursor here and see what Copilot suggests
```

**🤖 Copilot Observation**: Notice how Copilot might suggest common imports or class definitions based on the file name and docstring.

### Step 2: Define Data Models with Context

Add this data model to establish context:

```python
@dataclass
class Task:
    """Represents a task in the task manager."""
    id: int
    title: str
    description: str = ""
    priority: int = 3  # 1-5, where 5 is highest
    completed: bool = False
    created_at: datetime = field(default_factory=datetime.now)
    due_date: Optional[datetime] = None
    tags: List[str] = field(default_factory=list)
```

**🤖 Copilot Prompt Suggestion #1:**
```python
# After the Task class, type this comment and press Enter:
# Create a TaskManager class that can:
# - Add new tasks
# - List all tasks
# - Mark tasks as complete
# - Delete tasks
# Use a list to store tasks internally

class TaskManager:
    # Let Copilot complete this
```

**Expected Output:**
Copilot should generate a class with an `__init__` method and basic CRUD operations. The quality depends on the context provided.

### Step 3: Optimize Import Context

Reorganize imports for better context:

```python
# Standard library imports
from datetime import datetime, timedelta
import json
from pathlib import Path

# Type hints - signals we care about types
from typing import List, Optional, Dict, Any, Union, Tuple

# Data structures - signals we'll use dataclasses
from dataclasses import dataclass, field

# This organization tells Copilot:
# 1. We're working with dates/times
# 2. We care about type safety
# 3. We're using modern Python features
```

### Step 4: Function Placement for Context

Add functions in logical groups:

```python
class TaskManager:
    def __init__(self):
        self.tasks: List[Task] = []
        self.next_id: int = 1
    
    # Group 1: CRUD Operations
    def add_task(self, title: str, **kwargs) -> Task:
        """Add a new task to the manager."""
        task = Task(
            id=self.next_id,
            title=title,
            **kwargs
        )
        self.tasks.append(task)
        self.next_id += 1
        return task
    
    # Now Copilot knows the pattern, let it complete:
    def get_task(self, task_id: int) -> Optional[Task]:
        # Copilot will complete this following the pattern
```

**🤖 Copilot Prompt Suggestion #2:**
```python
# After add_task, type this and let Copilot complete:
def update_task(self, task_id: int, **updates) -> Optional[Task]:
    """Update task with given id. Returns updated task or None."""
    # Copilot should generate the implementation
```

### Step 5: Context Isolation Technique

Sometimes you need to isolate context to avoid interference:

```python
# ============= SEARCH FUNCTIONALITY =============
# This comment block creates visual separation

def search_tasks(self, query: str) -> List[Task]:
    """
    Search tasks by title or description.
    Case-insensitive partial matching.
    """
    # Copilot now focuses on search logic
    
# ============= REPORTING FUNCTIONS =============
# Another context boundary

def get_tasks_by_priority(self, priority: int) -> List[Task]:
    """Get all tasks with specific priority."""
    # Copilot understands this is filtering logic
```

### Step 6: Test Context Understanding

Create a test file to see how context affects suggestions:

```python
# In test_context_understanding.py
from task_manager import Task, TaskManager

# Create test data with clear patterns
manager = TaskManager()

# Pattern 1: Simple task creation
task1 = manager.add_task("Buy groceries", priority=2)
task2 = manager.add_task("Write report", priority=5, 
                        description="Quarterly sales report")

# Now type this and see what Copilot suggests:
task3 = manager.add_task(
```

**🤖 Expected Behavior**: Copilot should suggest task creation following the established pattern with appropriate parameters.

## 📊 Context Optimization Checklist

After completing Part 1, verify you understand:

- [ ] How the context window size affects suggestions
- [ ] Import organization impact on Copilot
- [ ] Function grouping for better context
- [ ] Using comments as context boundaries
- [ ] The hierarchy of context priority

## 🎯 Part 1 Summary

You've learned:
1. How Copilot's context window works
2. Structuring imports for better suggestions
3. Grouping related functions
4. Using comments for context isolation
5. Establishing patterns for Copilot to follow

## ⚡ Quick Exercise

Before moving to Part 2, try this:

```python
# Add this comment in your TaskManager class:
# Create a method that returns all overdue tasks
# Consider a task overdue if due_date is past and not completed

def get_overdue_tasks(self) -> List[Task]:
    # Let Copilot complete this
```

**Success Indicator**: Copilot should generate a method that:
- Checks both conditions (due_date and completed)
- Handles None due_dates
- Returns a filtered list

---

✅ **Ready for Part 2? Continue to learn about strategic comment placement!**