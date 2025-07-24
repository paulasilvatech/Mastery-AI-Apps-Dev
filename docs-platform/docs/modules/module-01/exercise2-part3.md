---
sidebar_position: 8
title: "Exercise 2: Part 3"
description: "## 🚀 Part 3: Advanced Features and Testing"
---

# Exercise 2: Building a CLI Tool (⭐⭐ Medium) - Part 3

## 🚀 Part 3: Advanced Features and Testing

Let's add advanced features and comprehensive testing to complete our professional CLI tool.

### Step 7: Add Export/Import Functionality

Let's add the ability to export and import tasks. Update `cli.py` with new commands:

**🤖 Copilot Prompt Suggestion #6:**
```python
# Add export and import commands:
# - export: Export tasks to JSON or CSV format
# - import: Import tasks from JSON or CSV file
# - Support filtering on export (e.g., export only TODO tasks)
# - Handle duplicate IDs on import
# - Validate data integrity
```

Add these commands to your `cli.py`:

**Expected Output:**
```python
import csv
import json
from pathlib import Path

@cli.command()
@click.argument('filename')
@click.option('-f', '--format', type=click.Choice(['json', 'csv']), 
              default='json', help='Export format')
@click.option('-s', '--status', type=click.Choice(['todo', 'in_progress', 'done']),
              help='Export only tasks with this status')
def export(filename: str, format: str, status: Optional[str]):
    """Export tasks to a file."""
    # Get tasks to export
    if status:
        tasks = storage.filter_by_status(Status(status))
    else:
        tasks = storage.get_all_tasks()
    
    if not tasks:
        click.echo(click.style("No tasks to export", fg='yellow'))
        return
    
    # Ensure correct extension
    path = Path(filename)
    if not path.suffix:
        path = path.with_suffix(f'.{format}')
    
    try:
        if format == 'json':
            # Export as JSON
            data = [task.to_dict() for task in tasks]
            with open(path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
        else:
            # Export as CSV
            with open(path, 'w', newline='', encoding='utf-8') as f:
                fieldnames = ['id', 'title', 'description', 'status', 
                             'priority', 'due_date', 'tags', 'created_at']
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                writer.writeheader()
                
                for task in tasks:
                    row = task.to_dict()
                    row['tags'] = ', '.join(row['tags'])
                    writer.writerow(row)
        
        click.echo(click.style(f"✅ Exported {len(tasks)} task(s) to {path}", 
                              fg='green'))
        
    except Exception as e:
        click.echo(click.style(f"Error exporting: {e}", fg='red'))

@cli.command()
@click.argument('filename')
@click.option('--merge', is_flag=True, 
              help='Merge with existing tasks (skip duplicates)')
def import_tasks(filename: str, merge: bool):
    """Import tasks from a file."""
    path = Path(filename)
    
    if not path.exists():
        click.echo(click.style(f"Error: File '{filename}' not found", fg='red'))
        return
    
    try:
        # Detect format
        if path.suffix == '.json':
            with open(path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                
            if not isinstance(data, list):
                click.echo(click.style("Error: JSON file must contain a list of tasks", 
                                     fg='red'))
                return
            
            imported_tasks = []
            skipped = 0
            
            for task_data in data:
                try:
                    # Create new task with new ID if not merging
                    if not merge:
                        task_data.pop('id', None)
                    
                    task = Task.from_dict(task_data)
                    
                    # Check for duplicates when merging
                    if merge and storage.get_task(task.id):
                        skipped += 1
                        continue
                    
                    storage.save_task(task)
                    imported_tasks.append(task)
                    
                except Exception as e:
                    click.echo(click.style(f"Error importing task: {e}", fg='red'))
            
        elif path.suffix == '.csv':
            with open(path, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                imported_tasks = []
                skipped = 0
                
                for row in reader:
                    try:
                        # Process CSV row
                        if 'tags' in row and row['tags']:
                            row['tags'] = [t.strip() for t in row['tags'].split(',')]
                        else:
                            row['tags'] = []
                        
                        # Remove empty values
                        row = {k: v for k, v in row.items() if v}
                        
                        # Create task
                        if not merge:
                            row.pop('id', None)
                        
                        task = Task.from_dict(row)
                        
                        if merge and storage.get_task(task.id):
                            skipped += 1
                            continue
                        
                        storage.save_task(task)
                        imported_tasks.append(task)
                        
                    except Exception as e:
                        click.echo(click.style(f"Error importing row: {e}", fg='red'))
        
        else:
            click.echo(click.style("Error: Unsupported file format. Use .json or .csv", 
                                 fg='red'))
            return
        
        # Report results
        click.echo(click.style(f"✅ Imported {len(imported_tasks)} task(s)", fg='green'))
        if skipped &gt; 0:
            click.echo(click.style(f"Skipped {skipped} duplicate(s)", fg='yellow'))
            
    except Exception as e:
        click.echo(click.style(f"Error reading file: {e}", fg='red'))
```

### Step 8: Add Configuration Support

Create a configuration system for default settings:

**🤖 Copilot Prompt Suggestion #7:**
```python
# Create a config module that:
# - Stores user preferences (default priority, date format, colors)
# - Loads from ~/.taskmanager/config.json
# - Provides defaults if no config exists
# - Allows updating via CLI command
```

Create `task_manager/config.py`:

**Expected Output:**
```python
import json
import os
from pathlib import Path
from typing import Dict, Any, Optional
from dataclasses import dataclass, asdict

@dataclass
class Config:
    """Application configuration."""
    default_priority: str = 'medium'
    date_format: str = '%Y-%m-%d'
    time_format: str = '%H:%M'
    show_ids: bool = True
    truncate_title: int = 50
    color_enabled: bool = True
    confirm_delete: bool = True
    relative_dates: bool = True
    
    @classmethod
    def load(cls) -&gt; 'Config':
        """Load configuration from file."""
        config_path = cls.get_config_path()
        
        if config_path.exists():
            try:
                with open(config_path, 'r') as f:
                    data = json.load(f)
                    return cls(**data)
            except Exception:
                # Return defaults on error
                pass
        
        return cls()
    
    def save(self) -&gt; None:
        """Save configuration to file."""
        config_path = self.get_config_path()
        config_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(config_path, 'w') as f:
            json.dump(asdict(self), f, indent=2)
    
    @staticmethod
    def get_config_path() -&gt; Path:
        """Get configuration file path."""
        if os.name == 'nt':  # Windows
            config_dir = Path(os.environ.get('APPDATA', '~')) / 'taskmanager'
        else:  # Unix-like
            config_dir = Path.home() / '.config' / 'taskmanager'
        
        return config_dir / 'config.json'
    
    def update(self, **kwargs) -&gt; None:
        """Update configuration values."""
        for key, value in kwargs.items():
            if hasattr(self, key):
                setattr(self, key, value)
        self.save()

# Add config command to CLI
@cli.group()
def config():
    """Manage application configuration."""
    pass

@config.command('show')
def show_config():
    """Show current configuration."""
    cfg = Config.load()
    click.echo(click.style("Current Configuration:", bold=True, fg='cyan'))
    for key, value in asdict(cfg).items():
        click.echo(f"  {key}: {value}")

@config.command('set')
@click.argument('key')
@click.argument('value')
def set_config(key: str, value: str):
    """Set a configuration value."""
    cfg = Config.load()
    
    # Convert value types
    if hasattr(cfg, key):
        current_value = getattr(cfg, key)
        if isinstance(current_value, bool):
            value = value.lower() in ('true', 'yes', '1')
        elif isinstance(current_value, int):
            value = int(value)
    else:
        click.echo(click.style(f"Error: Unknown configuration key '{key}'", fg='red'))
        return
    
    cfg.update(**{key: value})
    click.echo(click.style(f"✅ Set {key} = {value}", fg='green'))

@config.command('reset')
def reset_config():
    """Reset configuration to defaults."""
    if confirm_action("Reset all configuration to defaults?"):
        cfg = Config()
        cfg.save()
        click.echo(click.style("✅ Configuration reset to defaults", fg='green'))
```

### Step 9: Create Comprehensive Tests

Create `tests/test_task_manager.py`:

**🤖 Copilot Prompt Suggestion #8:**
```python
# Create comprehensive tests for:
# - Task model validation and methods
# - Storage operations (CRUD, search, filter)
# - CLI commands using Click's testing utilities
# - Edge cases and error conditions
# Use pytest fixtures for setup/teardown
```

**Expected Output:**
```python
import pytest
import tempfile
import json
from datetime import datetime, timedelta
from pathlib import Path
from click.testing import CliRunner

from task_manager.models import Task, Status, Priority
from task_manager.storage import TaskStorage
from task_manager.cli import cli
from task_manager.utils import parse_date_input, format_relative_date

@pytest.fixture
def temp_storage():
    """Create temporary storage for testing."""
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        temp_path = f.name
    
    storage = TaskStorage(temp_path)
    yield storage
    
    # Cleanup
    Path(temp_path).unlink(missing_ok=True)

@pytest.fixture
def sample_task():
    """Create a sample task."""
    return Task(
        title="Test Task",
        description="Test Description",
        priority=Priority.HIGH,
        tags=["test", "sample"]
    )

@pytest.fixture
def cli_runner():
    """Create CLI test runner."""
    return CliRunner()

class TestTaskModel:
    """Test Task model."""
    
    def test_task_creation(self):
        """Test basic task creation."""
        task = Task(title="Test Task")
        assert task.title == "Test Task"
        assert task.status == Status.TODO
        assert task.priority == Priority.MEDIUM
        assert task.id is not None
        assert isinstance(task.created_at, datetime)
    
    def test_task_validation(self):
        """Test task validation."""
        with pytest.raises(ValueError):
            Task(title="")
        
        with pytest.raises(ValueError):
            Task(title="   ")
    
    def test_task_serialization(self, sample_task):
        """Test task to/from dict conversion."""
        task_dict = sample_task.to_dict()
        assert task_dict['title'] == "Test Task"
        assert task_dict['priority'] == 'high'
        assert task_dict['tags'] == ["test", "sample"]
        
        # Test deserialization
        new_task = Task.from_dict(task_dict)
        assert new_task.title == sample_task.title
        assert new_task.priority == sample_task.priority
    
    def test_task_update(self, sample_task):
        """Test task update."""
        original_updated = sample_task.updated_at
        sample_task.update(title="Updated Title", status=Status.DONE)
        
        assert sample_task.title == "Updated Title"
        assert sample_task.status == Status.DONE
        assert sample_task.updated_at &gt; original_updated
    
    def test_overdue_detection(self):
        """Test overdue task detection."""
        past_date = datetime.now() - timedelta(days=1)
        task = Task(title="Overdue Task", due_date=past_date)
        assert task.is_overdue()
        
        future_date = datetime.now() + timedelta(days=1)
        task2 = Task(title="Future Task", due_date=future_date)
        assert not task2.is_overdue()
        
        # Completed tasks are never overdue
        task.status = Status.DONE
        assert not task.is_overdue()

class TestStorage:
    """Test storage operations."""
    
    def test_save_and_retrieve(self, temp_storage, sample_task):
        """Test saving and retrieving tasks."""
        saved = temp_storage.save_task(sample_task)
        assert saved.id == sample_task.id
        
        retrieved = temp_storage.get_task(sample_task.id)
        assert retrieved.title == sample_task.title
    
    def test_update_task(self, temp_storage, sample_task):
        """Test updating tasks."""
        temp_storage.save_task(sample_task)
        
        updated = temp_storage.update_task(
            sample_task.id,
            title="Updated Title",
            status=Status.IN_PROGRESS
        )
        
        assert updated.title == "Updated Title"
        assert updated.status == Status.IN_PROGRESS
    
    def test_delete_task(self, temp_storage, sample_task):
        """Test deleting tasks."""
        temp_storage.save_task(sample_task)
        assert temp_storage.delete_task(sample_task.id)
        assert temp_storage.get_task(sample_task.id) is None
        assert not temp_storage.delete_task("nonexistent")
    
    def test_search_tasks(self, temp_storage):
        """Test task searching."""
        tasks = [
            Task(title="Python project", description="Build a Python app"),
            Task(title="JavaScript tutorial", tags=["programming"]),
            Task(title="Meeting notes", description="Discuss project timeline")
        ]
        
        for task in tasks:
            temp_storage.save_task(task)
        
        # Search by title
        results = temp_storage.search_tasks("project")
        assert len(results) == 2
        
        # Search by description
        results = temp_storage.search_tasks("timeline")
        assert len(results) == 1
        
        # Search by tag
        results = temp_storage.search_tasks("programming")
        assert len(results) == 1
    
    def test_filter_operations(self, temp_storage):
        """Test filtering tasks."""
        tasks = [
            Task(title="Task 1", status=Status.TODO, priority=Priority.HIGH),
            Task(title="Task 2", status=Status.IN_PROGRESS, priority=Priority.HIGH),
            Task(title="Task 3", status=Status.DONE, priority=Priority.LOW),
        ]
        
        for task in tasks:
            temp_storage.save_task(task)
        
        # Filter by status
        todo_tasks = temp_storage.filter_by_status(Status.TODO)
        assert len(todo_tasks) == 1
        
        # Filter by priority
        high_priority = temp_storage.filter_by_priority(Priority.HIGH)
        assert len(high_priority) == 2

class TestCLI:
    """Test CLI commands."""
    
    def test_add_command(self, cli_runner, temp_storage, monkeypatch):
        """Test add command."""
        # Monkeypatch storage to use temp file
        monkeypatch.setattr('task_manager.cli.storage', temp_storage)
        
        result = cli_runner.invoke(cli, ['add', 'Test Task', '-p', 'high'])
        assert result.exit_code == 0
        assert 'Task created successfully' in result.output
        
        # Verify task was created
        tasks = temp_storage.get_all_tasks()
        assert len(tasks) == 1
        assert tasks[0].title == 'Test Task'
        assert tasks[0].priority == Priority.HIGH
    
    def test_list_command(self, cli_runner, temp_storage, monkeypatch):
        """Test list command."""
        monkeypatch.setattr('task_manager.cli.storage', temp_storage)
        
        # Add some tasks
        temp_storage.save_task(Task(title="Task 1", status=Status.TODO))
        temp_storage.save_task(Task(title="Task 2", status=Status.DONE))
        
        result = cli_runner.invoke(cli, ['list'])
        assert result.exit_code == 0
        assert 'Task 1' in result.output
        assert 'Task 2' in result.output
        
        # Test filtering
        result = cli_runner.invoke(cli, ['list', '--status', 'todo'])
        assert 'Task 1' in result.output
        assert 'Task 2' not in result.output
    
    def test_done_command(self, cli_runner, temp_storage, monkeypatch):
        """Test done command."""
        monkeypatch.setattr('task_manager.cli.storage', temp_storage)
        
        task = Task(title="Test Task")
        temp_storage.save_task(task)
        
        result = cli_runner.invoke(cli, ['done', task.id[:8]])
        assert result.exit_code == 0
        assert 'marked as done' in result.output
        
        # Verify status changed
        updated = temp_storage.get_task(task.id)
        assert updated.status == Status.DONE
    
    def test_search_command(self, cli_runner, temp_storage, monkeypatch):
        """Test search command."""
        monkeypatch.setattr('task_manager.cli.storage', temp_storage)
        
        temp_storage.save_task(Task(title="Python project"))
        temp_storage.save_task(Task(title="JavaScript tutorial"))
        
        result = cli_runner.invoke(cli, ['search', 'Python'])
        assert result.exit_code == 0
        assert 'Python project' in result.output
        assert 'JavaScript' not in result.output

class TestUtils:
    """Test utility functions."""
    
    def test_parse_date_input(self):
        """Test date parsing."""
        # Test relative dates
        today = parse_date_input('today')
        assert today.date() == datetime.now().date()
        
        tomorrow = parse_date_input('tomorrow')
        assert tomorrow.date() == (datetime.now() + timedelta(days=1)).date()
        
        # Test "in X days" format
        in_5_days = parse_date_input('in 5 days')
        expected = (datetime.now() + timedelta(days=5)).date()
        assert in_5_days.date() == expected
        
        # Test standard formats
        date = parse_date_input('2024-12-25')
        assert date.year == 2024
        assert date.month == 12
        assert date.day == 25
        
        # Test invalid input
        assert parse_date_input('invalid') is None
    
    def test_format_relative_date(self):
        """Test relative date formatting."""
        now = datetime.now()
        
        assert format_relative_date(now) == "just now"
        
        yesterday = now - timedelta(days=1)
        assert format_relative_date(yesterday) == "yesterday"
        
        last_week = now - timedelta(days=5)
        assert format_relative_date(last_week) == "5 days ago"

if __name__ == '__main__':
    pytest.main([__file__, '-v'])
```

### Step 10: Create Requirements File

Create `requirements.txt`:

```
click>=8.1.0
pytest>=7.4.0
python-dateutil>=2.8.0
```

### Step 11: Run and Validate

Create a validation script `validate_exercise2.py`:

**🤖 Copilot Prompt Suggestion #9:**
```python
# Create validation script that checks:
# - All required files exist
# - Code runs without errors
# - All CLI commands work
# - Tests pass
# - Basic functionality works end-to-end
```

**Expected Output:**
```python
#!/usr/bin/env python3
"""Exercise 2 Validation Script"""

import subprocess
import sys
import os
from pathlib import Path

def check_files():
    """Check all required files exist."""
    required_files = [
        'task_manager/__init__.py',
        'task_manager/models.py',
        'task_manager/storage.py',
        'task_manager/cli.py',
        'task_manager/utils.py',
        'task_manager/config.py',
        'task.py',
        'requirements.txt',
        'tests/test_task_manager.py'
    ]
    
    all_exist = True
    for file in required_files:
        if Path(file).exists():
            print(f"✅ {file} exists")
        else:
            print(f"❌ {file} missing")
            all_exist = False
    
    return all_exist

def run_tests():
    """Run pytest."""
    print("\n🧪 Running tests...")
    result = subprocess.run(
        [sys.executable, '-m', 'pytest', 'tests/', '-v'],
        capture_output=True,
        text=True
    )
    
    if result.returncode == 0:
        print("✅ All tests passed!")
        return True
    else:
        print("❌ Some tests failed:")
        print(result.stdout)
        return False

def test_cli_commands():
    """Test basic CLI functionality."""
    print("\n🔧 Testing CLI commands...")
    
    commands = [
        (['python', 'task.py', '--help'], "Help command"),
        (['python', 'task.py', 'add', 'Test task'], "Add command"),
        (['python', 'task.py', 'list'], "List command"),
        (['python', 'task.py', 'stats'], "Stats command"),
    ]
    
    all_passed = True
    for cmd, description in commands:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ {description} works")
        else:
            print(f"❌ {description} failed")
            all_passed = False
    
    return all_passed

def main():
    """Run all validations."""
    print("🔍 Exercise 2 Validation")
    print("=" * 40)
    
    checks = [
        ("Checking files", check_files()),
        ("Running tests", run_tests()),
        ("Testing CLI", test_cli_commands())
    ]
    
    print("\n📊 Summary")
    print("=" * 40)
    
    all_passed = all(result for _, result in checks)
    
    if all_passed:
        print("✅ All checks passed! Exercise complete! 🎉")
        sys.exit(0)
    else:
        print("❌ Some checks failed. Please review and fix.")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

## 🎯 Exercise 2 Complete!

Congratulations! You've built a professional CLI task manager with:

1. ✅ Robust data models with validation
2. ✅ Persistent storage with atomic writes
3. ✅ Comprehensive CLI interface
4. ✅ Import/export functionality
5. ✅ Configuration management
6. ✅ Complete test coverage
7. ✅ Professional error handling

### Key Takeaways

1. **Modular Design** - Separation of concerns makes code maintainable
2. **Rich CLI** - Click makes building CLIs intuitive
3. **Data Persistence** - JSON storage with atomic writes
4. **Testing** - Comprehensive tests ensure reliability
5. **User Experience** - Colors, confirmations, and helpful messages

### Extension Challenges

1. Add recurring tasks functionality
2. Implement task dependencies
3. Add reminder notifications
4. Create a web API interface
5. Add task categories/projects
6. Implement undo/redo functionality
7. Add time tracking features

### What's Next?

- Try the extension challenges
- Move on to [Exercise 3](./exercise3-part1) - Complete Application
- Review the [best practices](best-practices.md) guide

---

🎉 **Excellent work!** You've mastered building CLI applications with AI assistance. The skills you've learned here apply to any CLI tool you'll build in the future!