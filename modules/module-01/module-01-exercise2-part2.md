# Exercise 2: Building a CLI Tool (⭐⭐ Medium) - Part 2

## 🚀 Part 2: Building the CLI Interface

Now let's create the command-line interface that users will interact with.

### Step 5: Create the Main CLI Structure

Open `starter/task_manager/cli.py` and let's build the CLI:

**🤖 Copilot Prompt Suggestion #4:**
```python
# Create a Click CLI application with these commands:
# - add: Add a new task with title, description, priority, due date, tags
# - list: List tasks with filters (status, priority, overdue)
# - show: Show detailed task information
# - update: Update task fields
# - delete: Delete a task
# - done: Mark task as done
# - search: Search tasks by keyword
# - stats: Show task statistics
# - clear: Clear completed tasks
# Include help text, examples, and error handling
```

Start with imports and basic structure:
```python
import click
from datetime import datetime
from typing import Optional, List
from task_manager.models import Task, Status, Priority
from task_manager.storage import TaskStorage
from task_manager.utils import (
    parse_date_input, format_task_table, validate_title,
    confirm_action, format_statistics, colorize_status,
    colorize_priority, format_relative_date
)
```

**Expected Output:**
```python
import click
from datetime import datetime
from typing import Optional, List
from task_manager.models import Task, Status, Priority
from task_manager.storage import TaskStorage
from task_manager.utils import (
    parse_date_input, format_task_table, validate_title,
    confirm_action, format_statistics, colorize_status,
    colorize_priority, format_relative_date
)

# Initialize storage
storage = TaskStorage()

@click.group()
@click.version_option(version='1.0.0')
def cli():
    """
    Task Manager CLI - Manage your tasks efficiently!
    
    Examples:
        task add "Complete project documentation"
        task list --status todo
        task done abc123
        task search "project"
    """
    pass

@cli.command()
@click.argument('title')
@click.option('-d', '--description', help='Task description')
@click.option('-p', '--priority', type=click.Choice(['low', 'medium', 'high']), 
              default='medium', help='Task priority')
@click.option('--due', help='Due date (e.g., "tomorrow", "next week", "2024-12-25")')
@click.option('-t', '--tag', multiple=True, help='Task tags (can be used multiple times)')
def add(title: str, description: Optional[str], priority: str, 
        due: Optional[str], tag: List[str]):
    """Add a new task."""
    # Validate title
    is_valid, error = validate_title(title)
    if not is_valid:
        click.echo(click.style(f"Error: {error}", fg='red'))
        return
    
    # Parse due date
    due_date = None
    if due:
        due_date = parse_date_input(due)
        if not due_date:
            click.echo(click.style(f"Error: Invalid date format '{due}'", fg='red'))
            click.echo("Try: 'tomorrow', 'next week', '2024-12-25'")
            return
    
    # Create task
    task = Task(
        title=title,
        description=description,
        priority=Priority(priority),
        due_date=due_date,
        tags=list(tag)
    )
    
    # Save task
    saved_task = storage.save_task(task)
    
    click.echo(click.style("✅ Task created successfully!", fg='green'))
    click.echo(f"ID: {saved_task.id[:8]}")
    click.echo(f"Title: {saved_task.title}")
    if saved_task.due_date:
        click.echo(f"Due: {saved_task.due_date.strftime('%Y-%m-%d')}")

@cli.command()
@click.option('-s', '--status', type=click.Choice(['todo', 'in_progress', 'done']),
              help='Filter by status')
@click.option('-p', '--priority', type=click.Choice(['low', 'medium', 'high']),
              help='Filter by priority')
@click.option('--overdue', is_flag=True, help='Show only overdue tasks')
@click.option('--detailed', is_flag=True, help='Show task descriptions')
def list(status: Optional[str], priority: Optional[str], 
         overdue: bool, detailed: bool):
    """List all tasks with optional filters."""
    # Get tasks based on filters
    if overdue:
        tasks = storage.get_overdue_tasks()
        title = "Overdue Tasks"
    elif status:
        tasks = storage.filter_by_status(Status(status))
        title = f"Tasks - Status: {status}"
    elif priority:
        tasks = storage.filter_by_priority(Priority(priority))
        title = f"Tasks - Priority: {priority}"
    else:
        tasks = storage.get_all_tasks()
        title = "All Tasks"
    
    # Sort tasks
    tasks.sort(key=lambda t: (
        t.status != Status.TODO,  # TODO first
        t.priority != Priority.HIGH,  # HIGH priority first
        t.due_date or datetime.max  # Tasks with due dates first
    ))
    
    click.echo(click.style(f"\n{title}", bold=True, fg='cyan'))
    click.echo(format_task_table(tasks, show_description=detailed))
    click.echo(f"\nTotal: {len(tasks)} task(s)")

@cli.command()
@click.argument('task_id')
def show(task_id: str):
    """Show detailed information about a task."""
    # Find task by partial ID
    matching_tasks = [
        task for task in storage.get_all_tasks()
        if task.id.startswith(task_id)
    ]
    
    if not matching_tasks:
        click.echo(click.style(f"Error: No task found with ID '{task_id}'", fg='red'))
        return
    
    if len(matching_tasks) > 1:
        click.echo(click.style(f"Error: Multiple tasks match '{task_id}'", fg='red'))
        click.echo("Matching IDs:")
        for task in matching_tasks:
            click.echo(f"  - {task.id[:8]}: {task.title}")
        return
    
    task = matching_tasks[0]
    
    # Display detailed information
    click.echo(click.style("\n📋 Task Details", bold=True, fg='cyan'))
    click.echo(f"ID: {task.id}")
    click.echo(f"Title: {task.title}")
    
    if task.description:
        click.echo(f"\nDescription:")
        click.echo(click.style(task.description, fg='bright_white'))
    
    click.echo(f"\nStatus: {colorize_status(task.status)}")
    click.echo(f"Priority: {colorize_priority(task.priority)}")
    
    if task.due_date:
        due_str = task.due_date.strftime('%Y-%m-%d %H:%M')
        if task.is_overdue():
            due_str = click.style(f"{due_str} (OVERDUE!)", fg='red', bold=True)
        click.echo(f"Due Date: {due_str}")
    
    if task.tags:
        tags_str = ", ".join(f"#{tag}" for tag in task.tags)
        click.echo(f"Tags: {tags_str}")
    
    click.echo(f"\nCreated: {format_relative_date(task.created_at)}")
    click.echo(f"Updated: {format_relative_date(task.updated_at)}")

@cli.command()
@click.argument('task_id')
@click.option('-t', '--title', help='New title')
@click.option('-d', '--description', help='New description')
@click.option('-s', '--status', type=click.Choice(['todo', 'in_progress', 'done']),
              help='New status')
@click.option('-p', '--priority', type=click.Choice(['low', 'medium', 'high']),
              help='New priority')
@click.option('--due', help='New due date')
@click.option('--add-tag', multiple=True, help='Add tags')
@click.option('--remove-tag', multiple=True, help='Remove tags')
def update(task_id: str, title: Optional[str], description: Optional[str],
           status: Optional[str], priority: Optional[str], due: Optional[str],
           add_tag: List[str], remove_tag: List[str]):
    """Update task fields."""
    # Find task
    task = None
    for t in storage.get_all_tasks():
        if t.id.startswith(task_id):
            task = t
            break
    
    if not task:
        click.echo(click.style(f"Error: No task found with ID '{task_id}'", fg='red'))
        return
    
    # Build update dictionary
    updates = {}
    
    if title:
        is_valid, error = validate_title(title)
        if not is_valid:
            click.echo(click.style(f"Error: {error}", fg='red'))
            return
        updates['title'] = title
    
    if description is not None:
        updates['description'] = description
    
    if status:
        updates['status'] = Status(status)
    
    if priority:
        updates['priority'] = Priority(priority)
    
    if due:
        due_date = parse_date_input(due)
        if not due_date:
            click.echo(click.style(f"Error: Invalid date format '{due}'", fg='red'))
            return
        updates['due_date'] = due_date
    
    # Handle tags
    if add_tag or remove_tag:
        current_tags = set(task.tags)
        current_tags.update(add_tag)
        current_tags.difference_update(remove_tag)
        updates['tags'] = list(current_tags)
    
    if not updates:
        click.echo(click.style("No updates specified", fg='yellow'))
        return
    
    # Update task
    storage.update_task(task.id, **updates)
    
    click.echo(click.style("✅ Task updated successfully!", fg='green'))
    
    # Show what was updated
    for field, value in updates.items():
        if field == 'tags':
            click.echo(f"{field}: {', '.join(value)}")
        else:
            click.echo(f"{field}: {value}")

@cli.command()
@click.argument('task_id')
@click.option('-y', '--yes', is_flag=True, help='Skip confirmation')
def delete(task_id: str, yes: bool):
    """Delete a task."""
    # Find task
    task = None
    for t in storage.get_all_tasks():
        if t.id.startswith(task_id):
            task = t
            break
    
    if not task:
        click.echo(click.style(f"Error: No task found with ID '{task_id}'", fg='red'))
        return
    
    # Confirm deletion
    if not yes:
        click.echo(f"Task: {task.title}")
        if not confirm_action("Are you sure you want to delete this task?"):
            click.echo("Deletion cancelled")
            return
    
    # Delete task
    if storage.delete_task(task.id):
        click.echo(click.style("✅ Task deleted successfully!", fg='green'))
    else:
        click.echo(click.style("Error deleting task", fg='red'))

@cli.command()
@click.argument('task_id')
def done(task_id: str):
    """Mark a task as done."""
    # Find task
    task = None
    for t in storage.get_all_tasks():
        if t.id.startswith(task_id):
            task = t
            break
    
    if not task:
        click.echo(click.style(f"Error: No task found with ID '{task_id}'", fg='red'))
        return
    
    if task.status == Status.DONE:
        click.echo(click.style("Task is already done!", fg='yellow'))
        return
    
    # Mark as done
    storage.update_task(task.id, status=Status.DONE)
    click.echo(click.style(f"✅ Task '{task.title}' marked as done!", fg='green'))

@cli.command()
@click.argument('query')
def search(query: str):
    """Search tasks by title, description, or tags."""
    tasks = storage.search_tasks(query)
    
    if not tasks:
        click.echo(click.style(f"No tasks found matching '{query}'", fg='yellow'))
        return
    
    click.echo(click.style(f"\nSearch Results for '{query}'", bold=True, fg='cyan'))
    click.echo(format_task_table(tasks))
    click.echo(f"\nFound: {len(tasks)} task(s)")

@cli.command()
def stats():
    """Show task statistics."""
    stats = storage.get_statistics()
    click.echo(format_statistics(stats))

@cli.command()
@click.option('-y', '--yes', is_flag=True, help='Skip confirmation')
def clear(yes: bool):
    """Clear all completed tasks."""
    completed_count = len(storage.filter_by_status(Status.DONE))
    
    if completed_count == 0:
        click.echo(click.style("No completed tasks to clear", fg='yellow'))
        return
    
    if not yes:
        if not confirm_action(f"Delete {completed_count} completed task(s)?"):
            click.echo("Operation cancelled")
            return
    
    deleted = storage.clear_completed()
    click.echo(click.style(f"✅ Cleared {deleted} completed task(s)", fg='green'))

if __name__ == '__main__':
    cli()
```

### Step 6: Create the Main Entry Point

Create `task.py` in the project root as the main entry point:

**🤖 Copilot Prompt Suggestion #5:**
```python
# Create a main entry point script that:
# - Sets up the Python path
# - Handles keyboard interrupts gracefully
# - Shows a nice error message for missing dependencies
# - Runs the CLI application
```

**Expected Output:**
```python
#!/usr/bin/env python3
"""
Task Manager CLI - Main Entry Point
"""

import sys
import os

# Add the project directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    from task_manager.cli import cli
except ImportError as e:
    print("Error: Missing dependencies. Please install requirements:")
    print("  pip install -r requirements.txt")
    print(f"\nDetails: {e}")
    sys.exit(1)

def main():
    """Run the CLI application."""
    try:
        cli()
    except KeyboardInterrupt:
        print("\n\nOperation cancelled by user")
        sys.exit(0)
    except Exception as e:
        print(f"\nError: {e}")
        print("\nFor help, run: task --help")
        sys.exit(1)

if __name__ == '__main__':
    main()
```

## 🎯 Part 2 Summary

You've successfully:
1. Built a complete CLI interface with Click
2. Implemented all CRUD operations
3. Added search and filter functionality
4. Created a user-friendly command structure
5. Handled errors gracefully

**Key Commands Created:**
- `task add` - Create new tasks
- `task list` - View tasks with filters
- `task show` - Detailed task view
- `task update` - Modify tasks
- `task delete` - Remove tasks
- `task done` - Complete tasks
- `task search` - Find tasks
- `task stats` - View statistics
- `task clear` - Clean up completed tasks

**Next**: Continue to [Part 3](part3.md) where we'll add advanced features and testing!

---

💡 **Pro Tip**: Copilot excels at generating Click commands. Give it clear descriptions of options and it will create comprehensive CLI interfaces!