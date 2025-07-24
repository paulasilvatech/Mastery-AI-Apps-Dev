---
sidebar_position: 4
title: "Exercise 2: Part 1"
description: "## 🎯 Exercise Overview"
---

# Exercício 2: Building a CLI Tool (⭐⭐ Médio) - Partee 1

## 🎯 Visão Geral do Exercício

**Duração**: 45-60 minutos  
**Difficulty**: ⭐⭐ (Médio)  
**Success Rate**: 80%

In this intermediate exercise, you'll build a complete command-line task manager using GitHub Copilot. You'll learn how to handle multi-file projects, create complex data structures, implement persistent storage, and build a professional CLI interface.

## 🎓 Objetivos de Aprendizagem

Ao completar este exercício, você irá:
- Build multi-file applications with Copilot
- Implement data persistence with JSON
- Create advanced CLI interfaces
- Handle errors gracefully
- Structure code professionally

## 📋 Pré-requisitos

- ✅ Completard Exercício 1
- ✅ Understanding of Python classes
- ✅ Basic file I/O knowledge
- ✅ Familiarity with JSON

## 🏗️ What You'll Build

A **Task Manager CLI** with:
- Task creation, listing, updating, deletion (CRUD)
- Priority levels and due dates
- Status tracking (todo, in-progress, done)
- Pesquisar and filter capabilities
- Data persistence
- Rich terminal output

## 📁 Project Structure

```
exercise2-medium/
├── README.md               # This file
├── instructions/
│   ├── part1.md           # Setup and models (this file)
│   ├── part2.md           # CLI implementation
│   └── part3.md           # Advanced features
├── starter/
│   ├── task_manager/
│   │   ├── __init__.py
│   │   ├── models.py      # Task data models
│   │   ├── storage.py     # Persistence layer
│   │   └── cli.py         # CLI interface
│   └── requirements.txt
├── solution/
│   ├── task_manager/
│   │   ├── __init__.py
│   │   ├── models.py
│   │   ├── storage.py
│   │   ├── cli.py
│   │   └── utils.py
│   ├── tests/
│   └── tasks.json
└── resources/
    └── cli-design.md
```

## 🚀 Partee 1: Setting Up the Task Model

### Step 1: Understanding the Architecture

We'll build a modular application with clear separation of concerns:

1. **Models** (`models.py`) - Data structures
2. **Storage** (`storage.py`) - Persistence layer
3. **CLI** (`cli.py`) - User interface
4. **Utils** (`utils.py`) - Ajudaer functions

### Step 2: Create the Task Model

Abrir `starter/task_manager/models.py` and let's create our data model:

**🤖 Copilot Prompt Suggestion #1:**
```python
# Create a Task dataclass with these fields:
# - id: unique identifier (UUID string)
# - title: task title (required)
# - description: detailed description (optional)
# - status: todo, in_progress, or done (use Enum)
# - priority: low, medium, high (use Enum)
# - due_date: optional datetime
# - created_at: timestamp when created
# - updated_at: timestamp when last modified
# - tags: list of string tags
# Include validation, string representation, and to_dict method
```

Comece com imports and enums:
```python
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import List, Optional, Dict, Any
import uuid
```

**Expected Output:**
```python
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import List, Optional, Dict, Any
import uuid

class Status(Enum):
    """Task status enumeration."""
    TODO = "todo"
    IN_PROGRESS = "in_progress"
    DONE = "done"
    
    def __str__(self):
        return self.value

class Priority(Enum):
    """Task priority enumeration."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    
    def __str__(self):
        return self.value
    
    @property
    def emoji(self):
        """Return emoji representation."""
        emojis = {
            Priority.LOW: "🟢",
            Priority.MEDIUM: "🟡",
            Priority.HIGH: "🔴"
        }
        return emojis[self]

@dataclass
class Task:
    """Task model with all necessary fields."""
    title: str
    description: Optional[str] = None
    status: Status = Status.TODO
    priority: Priority = Priority.MEDIUM
    due_date: Optional[datetime] = None
    tags: List[str] = field(default_factory=list)
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    created_at: datetime = field(default_factory=datetime.now)
    updated_at: datetime = field(default_factory=datetime.now)
    
    def __post_init__(self):
        """Validate and convert fields after initialization."""
        # Convert string status to enum if needed
        if isinstance(self.status, str):
            self.status = Status(self.status)
        
        # Convert string priority to enum if needed
        if isinstance(self.priority, str):
            self.priority = Priority(self.priority)
        
        # Validate title is not empty
        if not self.title.strip():
            raise ValueError("Task title cannot be empty")
    
    def to_dict(self) -&gt; Dict[str, Any]:
        """Convert task to dictionary for JSON serialization."""
        return {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'status': self.status.value,
            'priority': self.priority.value,
            'due_date': self.due_date.isoformat() if self.due_date else None,
            'tags': self.tags,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -&gt; 'Task':
        """Create task from dictionary."""
        # Parse datetime fields
        if data.get('due_date'):
            data['due_date'] = datetime.fromisoformat(data['due_date'])
        if data.get('created_at'):
            data['created_at'] = datetime.fromisoformat(data['created_at'])
        if data.get('updated_at'):
            data['updated_at'] = datetime.fromisoformat(data['updated_at'])
        
        return cls(**data)
    
    def update(self, **kwargs) -&gt; None:
        """Update task fields and timestamp."""
        for key, value in kwargs.items():
            if hasattr(self, key):
                setattr(self, key, value)
        self.updated_at = datetime.now()
    
    def is_overdue(self) -&gt; bool:
        """Check if task is overdue."""
        if self.due_date and self.status != Status.DONE:
            return datetime.now() &gt; self.due_date
        return False
    
    def __str__(self) -&gt; str:
        """String representation for display."""
        status_icon = "✓" if self.status == Status.DONE else "○"
        overdue = " ⚠️ OVERDUE" if self.is_overdue() else ""
        return f"{status_icon} [{self.priority.emoji}] {self.title}{overdue}"
```

### Step 3: Create the Storage Layer

Now let's implement the persistence layer. Abrir `starter/task_manager/storage.py`:

**🤖 Copilot Prompt Suggestion #2:**
```python
# Create a TaskStorage class that:
# - Saves and loads tasks from JSON file
# - Provides CRUD operations (create, read, update, delete)
# - Handles file errors gracefully
# - Maintains data integrity with atomic writes
# - Supports searching and filtering
# - Implements singleton pattern for consistent state
# Include methods: save_task, get_task, get_all_tasks, update_task, 
# delete_task, search_tasks, filter_by_status, filter_by_priority
```

Start the implementation:
```python
import json
import os
from pathlib import Path
from typing import List, Optional, Dict, Any, Callable
from threading import Lock
from task_manager.models import Task, Status, Priority
```

**Expected Output:**
```python
import json
import os
from pathlib import Path
from typing import List, Optional, Dict, Any, Callable
from threading import Lock
import tempfile
import shutil

from task_manager.models import Task, Status, Priority

class TaskStorage:
    """Handles task persistence with JSON storage."""
    
    _instance = None
    _lock = Lock()
    
    def __new__(cls, storage_path: str = "tasks.json"):
        """Implement singleton pattern."""
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super().__new__(cls)
        return cls._instance
    
    def __init__(self, storage_path: str = "tasks.json"):
        """Initialize storage with file path."""
        if not hasattr(self, 'initialized'):
            self.storage_path = Path(storage_path)
            self.tasks: Dict[str, Task] = {}
            self._load_tasks()
            self.initialized = True
    
    def _load_tasks(self) -&gt; None:
        """Load tasks from JSON file."""
        if self.storage_path.exists():
            try:
                with open(self.storage_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    self.tasks = {
                        task_id: Task.from_dict(task_data)
                        for task_id, task_data in data.items()
                    }
            except (json.JSONDecodeError, ValueError) as e:
                # Backup corrupted file
                backup_path = self.storage_path.with_suffix('.backup')
                shutil.copy2(self.storage_path, backup_path)
                print(f"Error loading tasks, created backup: {backup_path}")
                self.tasks = {}
        else:
            self.tasks = {}
    
    def _save_tasks(self) -&gt; None:
        """Save tasks to JSON file with atomic write."""
        # Convert tasks to dictionary format
        data = {
            task_id: task.to_dict()
            for task_id, task in self.tasks.items()
        }
        
        # Write to temporary file first (atomic operation)
        temp_fd, temp_path = tempfile.mkstemp()
        try:
            with os.fdopen(temp_fd, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
            
            # Move temp file to actual location (atomic on same filesystem)
            shutil.move(temp_path, self.storage_path)
        except Exception:
            # Clean up temp file on error
            if os.path.exists(temp_path):
                os.unlink(temp_path)
            raise
    
    def save_task(self, task: Task) -&gt; Task:
        """Save a new or existing task."""
        self.tasks[task.id] = task
        self._save_tasks()
        return task
    
    def get_task(self, task_id: str) -&gt; Optional[Task]:
        """Get task by ID."""
        return self.tasks.get(task_id)
    
    def get_all_tasks(self) -&gt; List[Task]:
        """Get all tasks."""
        return list(self.tasks.values())
    
    def update_task(self, task_id: str, **kwargs) -&gt; Optional[Task]:
        """Update task fields."""
        task = self.get_task(task_id)
        if task:
            task.update(**kwargs)
            self._save_tasks()
            return task
        return None
    
    def delete_task(self, task_id: str) -&gt; bool:
        """Delete task by ID."""
        if task_id in self.tasks:
            del self.tasks[task_id]
            self._save_tasks()
            return True
        return False
    
    def search_tasks(self, query: str) -&gt; List[Task]:
        """Search tasks by title or description."""
        query_lower = query.lower()
        results = []
        
        for task in self.tasks.values():
            if (query_lower in task.title.lower() or 
                (task.description and query_lower in task.description.lower()) or
                any(query_lower in tag.lower() for tag in task.tags)):
                results.append(task)
        
        return results
    
    def filter_by_status(self, status: Status) -&gt; List[Task]:
        """Filter tasks by status."""
        return [task for task in self.tasks.values() if task.status == status]
    
    def filter_by_priority(self, priority: Priority) -&gt; List[Task]:
        """Filter tasks by priority."""
        return [task for task in self.tasks.values() if task.priority == priority]
    
    def filter_tasks(self, filter_func: Callable[[Task], bool]) -&gt; List[Task]:
        """Filter tasks using custom function."""
        return [task for task in self.tasks.values() if filter_func(task)]
    
    def get_overdue_tasks(self) -&gt; List[Task]:
        """Get all overdue tasks."""
        return self.filter_tasks(lambda t: t.is_overdue())
    
    def clear_completed(self) -&gt; int:
        """Remove all completed tasks and return count."""
        completed = self.filter_by_status(Status.DONE)
        count = len(completed)
        
        for task in completed:
            self.delete_task(task.id)
        
        return count
    
    def get_statistics(self) -&gt; Dict[str, Any]:
        """Get task statistics."""
        all_tasks = self.get_all_tasks()
        
        return {
            'total': len(all_tasks),
            'by_status': {
                status.value: len(self.filter_by_status(status))
                for status in Status
            },
            'by_priority': {
                priority.value: len(self.filter_by_priority(priority))
                for priority in Priority
            },
            'overdue': len(self.get_overdue_tasks())
        }
```

### Step 4: Create Utility Functions

Create `starter/task_manager/utils.py` for helper functions:

**🤖 Copilot Prompt Suggestion #3:**
```python
# Create utility functions for:
# - Formatting dates for display (relative time like "2 days ago")
# - Parsing date input (flexible formats: "tomorrow", "next week", "2024-12-25")
# - Colorizing terminal output based on priority/status
# - Creating task tables for display
# - Validating user input
# Use click.style for colors and handle edge cases
```

**Expected Output:**
```python
from datetime import datetime, timedelta
from typing import Optional, List, Tuple
import re
from task_manager.models import Task, Status, Priority
import click

def format_relative_date(date: datetime) -&gt; str:
    """Format datetime as relative time (e.g., '2 days ago')."""
    now = datetime.now()
    delta = now - date
    
    if delta.days == 0:
        if delta.seconds &lt; 60:
            return "just now"
        elif delta.seconds &lt; 3600:
            minutes = delta.seconds // 60
            return f"{minutes} minute{'s' if minutes != 1 else ''} ago"
        else:
            hours = delta.seconds // 3600
            return f"{hours} hour{'s' if hours != 1 else ''} ago"
    elif delta.days == 1:
        return "yesterday"
    elif delta.days &lt; 7:
        return f"{delta.days} days ago"
    elif delta.days &lt; 30:
        weeks = delta.days // 7
        return f"{weeks} week{'s' if weeks != 1 else ''} ago"
    else:
        return date.strftime("%Y-%m-%d")

def parse_date_input(date_string: str) -&gt; Optional[datetime]:
    """Parse flexible date input formats."""
    date_string = date_string.lower().strip()
    now = datetime.now()
    
    # Relative dates
    relative_dates = {
        'today': now,
        'tomorrow': now + timedelta(days=1),
        'yesterday': now - timedelta(days=1),
        'next week': now + timedelta(weeks=1),
        'next month': now + timedelta(days=30),
    }
    
    if date_string in relative_dates:
        return relative_dates[date_string]
    
    # "in X days/weeks" pattern
    in_pattern = r'in (\d+) (day|days|week|weeks|month|months)'
    match = re.match(in_pattern, date_string)
    if match:
        amount = int(match.group(1))
        unit = match.group(2)
        if 'day' in unit:
            return now + timedelta(days=amount)
        elif 'week' in unit:
            return now + timedelta(weeks=amount)
        elif 'month' in unit:
            return now + timedelta(days=amount * 30)
    
    # Standard date formats
    date_formats = [
        "%Y-%m-%d",
        "%Y/%m/%d",
        "%d-%m-%Y",
        "%d/%m/%Y",
        "%m-%d-%Y",
        "%m/%d/%Y",
    ]
    
    for fmt in date_formats:
        try:
            return datetime.strptime(date_string, fmt)
        except ValueError:
            continue
    
    return None

def colorize_status(status: Status) -&gt; str:
    """Return colorized status string."""
    colors = {
        Status.TODO: 'yellow',
        Status.IN_PROGRESS: 'blue',
        Status.DONE: 'green'
    }
    return click.style(str(status), fg=colors[status])

def colorize_priority(priority: Priority) -&gt; str:
    """Return colorized priority string with emoji."""
    colors = {
        Priority.LOW: 'green',
        Priority.MEDIUM: 'yellow',
        Priority.HIGH: 'red'
    }
    return click.style(f"{priority.emoji} {priority}", fg=colors[priority])

def format_task_table(tasks: List[Task], show_description: bool = False) -&gt; str:
    """Format tasks as a table for display."""
    if not tasks:
        return click.style("No tasks found.", fg='yellow')
    
    # Calculate column widths
    id_width = 8  # Show first 8 chars of ID
    title_width = max(len(task.title) for task in tasks)
    title_width = min(title_width, 50)  # Cap at 50 chars
    
    # Header
    lines = []
    header = f"{'ID':&lt;{id_width}} | {'Title':&lt;{title_width}} | {'Status':Less than 12} | {'Priority':Less than 12} | {'Due Date':Less than 12}"
    lines.append(click.style(header, bold=True))
    lines.append("-" * len(header))
    
    # Task rows
    for task in tasks:
        task_id = task.id[:id_width]
        title = task.title[:title_width].ljust(title_width)
        status = colorize_status(task.status).ljust(12 + 10)  # Extra space for ANSI codes
        priority = colorize_priority(task.priority).ljust(12 + 10)
        
        if task.due_date:
            if task.is_overdue():
                due_date = click.style(task.due_date.strftime("%Y-%m-%d"), fg='red', bold=True)
            else:
                due_date = task.due_date.strftime("%Y-%m-%d")
        else:
            due_date = "-"
        
        line = f"{task_id} | {title} | {status} | {priority} | {due_date}"
        lines.append(line)
        
        if show_description and task.description:
            desc_lines = task.description.split('\n')
            for desc_line in desc_lines[:2]:  # Show first 2 lines
                lines.append(f"         | {click.style(desc_line[:title_width], fg='bright_black')}")
    
    return '\n'.join(lines)

def validate_title(title: str) -&gt; Tuple[bool, Optional[str]]:
    """Validate task title."""
    if not title or not title.strip():
        return False, "Title cannot be empty"
    
    if len(title) &gt; 200:
        return False, "Title must be less than 200 characters"
    
    return True, None

def confirm_action(message: str) -&gt; bool:
    """Ask for user confirmation."""
    return click.confirm(message, default=False)

def format_statistics(stats: dict) -&gt; str:
    """Format statistics for display."""
    lines = [
        click.style("📊 Task Statistics", bold=True, fg='cyan'),
        f"Total Tasks: {stats['total']}",
        "",
        "By Status:",
        f"  📋 TODO: {stats['by_status']['todo']}",
        f"  🔄 In Progress: {stats['by_status']['in_progress']}",
        f"  ✅ Done: {stats['by_status']['done']}",
        "",
        "By Priority:",
        f"  🟢 Low: {stats['by_priority']['low']}",
        f"  🟡 Medium: {stats['by_priority']['medium']}",
        f"  🔴 High: {stats['by_priority']['high']}",
    ]
    
    if stats['overdue'] &gt; 0:
        lines.append("")
        lines.append(click.style(f"⚠️  Overdue Tasks: {stats['overdue']}", fg='red', bold=True))
    
    return '\n'.join(lines)
```

## 🎯 Partee 1 Resumo

You've successfully:
1. Created a comprehensive Task model with validation
2. Built a robust storage layer with atomic writes
3. Implemented utility functions for formatting and validation
4. Set up the foundation for a professional CLI application

**Key Learnings:**
- Dataclasses simplify model creation
- Enums provide type safety for status/priority
- Atomic writes prevent data corruption
- Singleton pattern ensures consistent state

**Próximo**: Continuar to [Partee 2](./exercise2-part2) where we'll build the CLI interface!

---

💡 **Pro Tip**: When building multi-file applications with Copilot, establish clear patterns in one module, and Copilot will follow them in others!