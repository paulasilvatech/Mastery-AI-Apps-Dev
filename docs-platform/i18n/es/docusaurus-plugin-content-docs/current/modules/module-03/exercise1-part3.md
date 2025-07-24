---
sidebar_position: 5
title: "Exercise 1: Part 3"
description: "## 🎯 Part 3: Advanced Context Techniques (10-15 minutes)"
---

# Ejercicio 1: Context Optimization Workshop - Partee 3

## 🎯 Partee 3: Avanzado Context Techniques (10-15 minutos)

In this final part, you'll learn advanced techniques for managing context across multiple files, creating reusable patterns, and optimizing performance.

## 📚 Avanzado Context Concepts

### Multi-File Context Management

Copilot can use context from multiple files when they're related through:
1. **Imports**: Directly imported modules
2. **Inheritance**: Parent classes
3. **Type Hints**: Referenced types
4. **Similar Names**: Files with related names

## 🛠️ Hands-On Ejercicio

### Step 1: Create Supporting Files for Context

First, create `models.py` to establish shared context:

```python
# models.py
from enum import Enum
from typing import Protocol, runtime_checkable

class Priority(Enum):
    """Task priority levels."""
    TRIVIAL = 1
    LOW = 2
    MEDIUM = 3
    HIGH = 4
    URGENT = 5
    
    @classmethod
    def from_string(cls, value: str) -&gt; 'Priority':
        """Convert string to Priority enum."""
        mapping = {
            'trivial': cls.TRIVIAL,
            'low': cls.LOW,
            'medium': cls.MEDIUM,
            'high': cls.HIGH,
            'urgent': cls.URGENT
        }
        return mapping.get(value.lower(), cls.MEDIUM)

@runtime_checkable
class TaskFilter(Protocol):
    """Protocol for task filtering strategies."""
    def matches(self, task: 'Task') -&gt; bool:
        """Return True if task matches filter criteria."""
        ...
```

Now update your main file to use these:

```python
# task_manager.py
from models import Priority, TaskFilter
from typing import Type

class TaskManager:
    # Copilot now has access to Priority enum and TaskFilter protocol
    
    def add_task_with_priority(self, title: str, priority: Union[str, Priority]) -&gt; Task:
        """Add task with flexible priority input."""
        # Copilot knows about Priority.from_string() method
        if isinstance(priority, str):
            priority_enum = Priority.from_string(priority)
        else:
            priority_enum = priority
```

### Step 2: Template Pattern Context

Create reusable patterns that Copilot can learn:

```python
# Create a filter template pattern
class CompletedFilter:
    """Filter for completed tasks."""
    def __init__(self, completed: bool = True):
        self.completed = completed
    
    def matches(self, task: Task) -&gt; bool:
        return task.completed == self.completed

class PriorityFilter:
    """Filter for tasks by priority."""
    def __init__(self, min_priority: int, max_priority: int = 5):
        self.min_priority = min_priority
        self.max_priority = max_priority
    
    def matches(self, task: Task) -&gt; bool:
        return self.min_priority &lt;= task.priority &lt;= self.max_priority

# Now create a new filter - Copilot will follow the pattern
class DueDateFilter:
    """Filter for tasks by due date range."""
    # Copilot will complete this following the established pattern
```

### Step 3: Context Preloading Technique

"Preload" context by defining interfaces first:

```python
class AdvancedTaskManager(TaskManager):
    """Extended task manager with advanced features."""
    
    # Define the interface first - this guides Copilot
    def bulk_import(self, csv_file: str) -&gt; List[Task]: ...
    def export_to_json(self, filename: str) -&gt; None: ...
    def generate_analytics(self) -&gt; Dict[str, Any]: ...
    def apply_filters(self, *filters: TaskFilter) -&gt; List[Task]: ...
    def schedule_recurring(self, task: Task, pattern: str) -&gt; List[Task]: ...
    
    # Now implement each method - Copilot understands the full interface
    def bulk_import(self, csv_file: str) -&gt; List[Task]:
        """Import tasks from CSV file."""
        # Copilot knows this is part of a larger system
```

### Step 4: Cross-File Pattern Referencias

Create `utils.py` with utility functions:

```python
# utils.py
from datetime import datetime, timedelta
from typing import List, Tuple

def parse_relative_date(date_str: str) -&gt; datetime:
    """Parse relative date strings like 'tomorrow', 'next week'."""
    now = datetime.now()
    date_str = date_str.lower().strip()
    
    if date_str == 'today':
        return now.replace(hour=17, minute=0, second=0)
    elif date_str == 'tomorrow':
        return (now + timedelta(days=1)).replace(hour=9, minute=0)
    elif date_str == 'next week':
        return (now + timedelta(weeks=1)).replace(hour=9, minute=0)
    # ... more patterns
    
def calculate_workdays(start: datetime, end: datetime) -&gt; int:
    """Calculate working days between two dates."""
    # Implementation
```

Now reference in main file:

```python
# task_manager.py
from utils import parse_relative_date, calculate_workdays

class TaskManager:
    def quick_add(self, description: str) -&gt; Task:
        """
        Parse natural language task description.
        Format: "task_title by due_date with priority"
        Example: "Finish report by tomorrow with high priority"
        """
        # Copilot can now use the imported utility functions
```

### Step 5: Context Isolation for Complex Logic

Use namespace isolation for complex features:

```python
# Create a namespace for analytics
class Analytics:
    """Analytics namespace for task statistics."""
    
    @staticmethod
    def calculate_completion_rate(tasks: List[Task]) -&gt; float:
        """Calculate percentage of completed tasks."""
        if not tasks:
            return 0.0
        completed = sum(1 for t in tasks if t.completed)
        return (completed / len(tasks)) * 100
    
    @staticmethod
    def average_completion_time(tasks: List[Task]) -&gt; timedelta:
        """Calculate average time to complete tasks."""
        # Copilot understands this is analytics-focused
    
    @staticmethod
    def workload_distribution(tasks: List[Task]) -&gt; Dict[int, int]:
        """Get distribution of tasks by priority."""
        # Copilot generates analytics-specific code

# Use in main class
class TaskManager:
    def get_analytics(self) -&gt; Dict[str, Any]:
        """Generate comprehensive analytics report."""
        return {
            'completion_rate': Analytics.calculate_completion_rate(self.tasks),
            'avg_completion_time': Analytics.average_completion_time(self.tasks),
            'workload': Analytics.workload_distribution(self.tasks)
        }
```

### Step 6: Performance-Aware Context

Add performance hints in context:

```python
class TaskManager:
    def __init__(self, enable_caching: bool = True):
        self.tasks: List[Task] = []
        self.enable_caching = enable_caching
        self._cache: Dict[str, Any] = {}
    
    # Performance-critical method with caching
    def search_tasks_optimized(self, query: str) -&gt; List[Task]:
        """
        Search with caching for repeated queries.
        Cache key: query string
        Cache invalidation: on any task modification
        """
        # Check cache first
        cache_key = f"search:{query.lower()}"
        if self.enable_caching and cache_key in self._cache:
            return self._cache[cache_key]
        
        # Perform search
        results = [t for t in self.tasks if query.lower() in t.title.lower()]
        
        # Cache results
        if self.enable_caching:
            self._cache[cache_key] = results
        
        return results
    
    def _invalidate_cache(self):
        """Clear cache when tasks are modified."""
        self._cache.clear()
```

## 🎯 Avanzado Techniques Resumen

### Technique 1: Import Strategy
```python
# Group imports to establish context
# Standard library - shows what built-ins we'll use
import json
import csv
from pathlib import Path

# Type hints - signals type-safety focus
from typing import Protocol, Type, TypeVar

# Domain models - establishes business context
from models import Task, Priority, TaskFilter

# Utilities - shows available helpers
from utils import parse_date, validate_email
```

### Technique 2: Progressive Enhancement
```python
# Start simple
class Basic:
    def method(self): pass

# Add complexity gradually
class Enhanced(Basic):
    def method(self):  # Copilot sees the inheritance
        super().method()
        # Additional logic
```

### Technique 3: Context Boundaries
```python
# ========== SECTION: Data Access ==========
# Database-related methods here

# ========== SECTION: Business Logic ==========
# Core business rules here

# ========== SECTION: API Endpoints ==========
# REST API methods here
```

## 🧪 Final Validation

Run the complete context optimization test:

```python
python tests/test_context.py --comprehensive
```

Expected output:
```
✅ File Organization: OPTIMAL
✅ Import Structure: WELL-ORGANIZED
✅ Comment Placement: STRATEGIC
✅ Pattern Consistency: HIGH
✅ Multi-file Context: PROPERLY LINKED
✅ Performance Hints: PRESENT
✅ Overall Score: 95/100
```

## 💡 Expert Tips

### Context Optimization Mejores Prácticas

1. **File Organization**
   - Keep related code in same/nearby files
   - Use consistent naming conventions
   - Clear module boundaries

2. **Import Optimization**
   - Import what you use
   - Group imports logically
   - Use type hints extensively

3. **Pattern Establishment**
   - Show 2-3 examples before expecting pattern following
   - Keep patterns consistent
   - Document pattern rules

4. **Performance Awareness**
   - Add performance comments for critical sections
   - Mention algorithmic complexity
   - Indicate caching strategies

## 🏆 Ejercicio Completar!

Congratulations! You've mastered context optimization for GitHub Copilot:

- ✅ Understanding context windows
- ✅ Strategic code organization  
- ✅ Effective comment placement
- ✅ Multi-file context management
- ✅ Performance optimization
- ✅ Avanzado pattern techniques

## 🎯 Bonus Challenges

1. **Challenge 1**: Create a plugin system using context patterns
2. **Challenge 2**: Build a context-aware code generator
3. **Challenge 3**: Implement a multi-strategy task scheduler

## 📚 Additional Recursos

- [GitHub Copilot Context Deep Dive](https://github.blog/2023-10-30-context-understanding/)
- [Effective Python Patterns](https://effectivepython.com/)
- [Code Organization Mejores Prácticas](https://docs.python-guide.org/writing/structure/)

---

🎉 **Outstanding work! You're ready for Exercise 2: Prompt Pattern Library!**