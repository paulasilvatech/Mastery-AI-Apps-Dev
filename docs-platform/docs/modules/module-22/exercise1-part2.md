---
sidebar_position: 2
title: "Exercise 1: Part 2"
description: "### Step 4: Create Documentation Templates"
---

# Exercise 1: Documentation Generation Agent - Part 2

### Step 4: Create Documentation Templates

Create `templates/markdown/module.md.j2`:
```jinja2
```jinja2
# Module: {{ module.name }}

{% if module.docstring %}
{{ module.docstring }}
{% endif %}

---

## Classes

{% for class in classes %}
### class `{{ class.name }}`
{% if class.decorators %}
Decorators: {% for dec in class.decorators %}`@{{ dec }}`{% if not loop.last %}, {% endif %}{% endfor %}
{% endif %}

{% if class.docstring %}
{{ class.docstring }}
{% else %}
```
*No documentation available*
```jinja2
{% endif %}

```
**Signature:**
```python
```jinja2
{{ class.signature }}
```
```

```jinja2
{% endfor %}

## Functions

{% for function in functions %}
### `{{ function.signature }}`
{% if function.decorators %}
Decorators: {% for dec in function.decorators %}`@{{ dec }}`{% if not loop.last %}, {% endif %}{% endfor %}
{% endif %}

{% if function.docstring %}
{{ function.docstring }}
{% else %}
```
*No documentation available*
```jinja2
{% endif %}

{% if function.parameters %}
```
**Parameters:**
```jinja2
{% for param in function.parameters %}
- `{{ param.name }}` {% if param.type %}({{ param.type }}){% endif %}{% if param.default %} = `{{ param.default }}`{% endif %}
{% endfor %}
{% endif %}

{% if function.returns %}
```
**Returns:**
```jinja2
- {% if function.returns.type %}`{{ function.returns.type }}`{% endif %} {% if function.returns.description %}{{ function.returns.description }}{% endif %}
{% endif %}

{% if function.raises %}
```
**Raises:**
```jinja2
{% for exception in function.raises %}
- `{{ exception }}`
{% endfor %}
{% endif %}

{% if function.examples %}
```
**Examples:**
```python
```jinja2
{% for example in function.examples %}
{{ example }}
{% endfor %}
```
```
```jinja2
{% endif %}

{% endfor %}

---
*Generated on {{ generated_time }}*
```
```

Create `templates/markdown/api_reference.md.j2`:
```jinja2
# API Reference

## Overview

This document provides a complete API reference for all modules, classes, and functions.

### Statistics
```jinja2
- **Total Modules:** {{ modules|length }}
- **Total Classes:** {{ all_classes|length }}
- **Total Functions:** {{ all_functions|length }}

## Modules

{% for module in modules %}
- [`{{ module.name }}`]({{ module.name }}.md) - {{ module.docstring|truncate(100) if module.docstring else "No description" }}
{% endfor %}

## Classes

{% for class in all_classes %}
### `{{ class.name }}`
- **Module:** `{{ class.source_file }}`
- **Line:** {{ class.line_number }}
- **Description:** {{ class.docstring|truncate(200) if class.docstring else "No documentation" }}
{% endfor %}

## Functions

{% for function in all_functions %}
### `{{ function.name }}`
- **Module:** `{{ function.source_file }}`
- **Signature:** `{{ function.signature }}`
- **Complexity:** {{ function.complexity }}
- **Description:** {{ function.docstring|truncate(200) if function.docstring else "No documentation" }}
{% endfor %}

---
*Generated on {{ generated_time }}*
```
```

### Step 5: Create Agent Memory System

**Copilot Prompt Suggestion:**
```python
# Create a memory system for the documentation agent that:
# - Stores previous documentation states
# - Tracks changes between versions
# - Identifies what needs updating
# - Maintains documentation history
# - Provides diff capabilities
```

Create `src/memory/doc_memory.py`:
```python
import json
import hashlib
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Any, Optional, Set
import difflib

class DocMemorySystem:
    """Memory system for documentation agent"""
    
    def __init__(self, cache_dir: Path):
        self.cache_dir = cache_dir
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.state_file = self.cache_dir / "doc_state.json"
        self.history_file = self.cache_dir / "doc_history.jsonl"
        self.current_state = self._load_state()
        
    def _load_state(self) -&gt; Dict[str, Any]:
        """Load current documentation state"""
        if self.state_file.exists():
            with open(self.state_file, 'r') as f:
                return json.load(f)
        return {
            'entities': {},
            'last_update': None,
            'version': '0.0.0'
        }
    
    def _save_state(self):
        """Save current state"""
        with open(self.state_file, 'w') as f:
            json.dump(self.current_state, f, indent=2, default=str)
    
    def store_entity(self, entity: 'CodeEntity'):
        """Store or update an entity"""
        entity_id = self._generate_entity_id(entity)
        entity_data = {
            'name': entity.name,
            'type': entity.type,
            'signature': entity.signature,
            'docstring': entity.docstring,
            'source_file': entity.source_file,
            'line_number': entity.line_number,
            'hash': self._hash_entity(entity),
            'last_seen': datetime.now().isoformat()
        }
        
        # Check if entity changed
        old_entity = self.current_state['entities'].get(entity_id)
        if old_entity and old_entity['hash'] != entity_data['hash']:
            self._record_change(entity_id, old_entity, entity_data)
            
        self.current_state['entities'][entity_id] = entity_data
        self.current_state['last_update'] = datetime.now().isoformat()
        
    def get_changed_entities(self, current_entities: List['CodeEntity']) -&gt; Set[str]:
        """Get IDs of entities that changed"""
        changed = set()
        
        for entity in current_entities:
            entity_id = self._generate_entity_id(entity)
            stored = self.current_state['entities'].get(entity_id)
            
            if not stored or stored['hash'] != self._hash_entity(entity):
                changed.add(entity_id)
                
        return changed
    
    def get_documentation_diff(self, old_doc: str, new_doc: str) -&gt; str:
        """Generate diff between documentation versions"""
        old_lines = old_doc.splitlines(keepends=True)
        new_lines = new_doc.splitlines(keepends=True)
        
        diff = difflib.unified_diff(
            old_lines, new_lines,
            fromfile='old_documentation',
            tofile='new_documentation',
            n=3
        )
        
        return ''.join(diff)
    
    def _generate_entity_id(self, entity: 'CodeEntity') -&gt; str:
        """Generate unique ID for entity"""
        return f"{entity.source_file}::{entity.type}::{entity.name}"
    
    def _hash_entity(self, entity: 'CodeEntity') -&gt; str:
        """Generate hash of entity content"""
        content = f"{entity.signature}{entity.docstring}{entity.parameters}{entity.returns}"
        return hashlib.sha256(content.encode()).hexdigest()[:16]
    
    def _record_change(self, entity_id: str, old_data: Dict, new_data: Dict):
        """Record entity change in history"""
        change_record = {
            'timestamp': datetime.now().isoformat(),
            'entity_id': entity_id,
            'change_type': 'modified',
            'old': old_data,
            'new': new_data
        }
        
        with open(self.history_file, 'a') as f:
            f.write(json.dumps(change_record) + '\n')
    
    def get_entity_history(self, entity_id: str) -&gt; List[Dict]:
        """Get change history for an entity"""
        history = []
        
        if self.history_file.exists():
            with open(self.history_file, 'r') as f:
                for line in f:
                    record = json.loads(line)
                    if record['entity_id'] == entity_id:
                        history.append(record)
                        
        return history
    
    def commit(self):
        """Commit current state"""
        self._save_state()
    
    def rollback(self):
        """Rollback to previous state"""
        self.current_state = self._load_state()
```

### Step 6: Create Integration and Demo

Create `src/doc_agent_demo.py`:
```python
"""Demo script for documentation generation agent"""

from pathlib import Path
from src.agents.documentation_agent import (
    DocumentationAgent, DocumentationConfig, DocFormat
)

# Sample code to document
sample_code = '''
"""Sample module for documentation generation demo"""

from typing import List, Optional, Dict
from dataclasses import dataclass

@dataclass
class Task:
    """Represents a task in the system
    
    Attributes:
        id: Unique task identifier
        title: Task title
        completed: Whether task is completed
        tags: Optional list of tags
    """
    id: int
    title: str
    completed: bool = False
    tags: Optional[List[str]] = None

class TaskManager:
    """Manages a collection of tasks
    
    This class provides methods to add, remove, and query tasks.
    It maintains tasks in memory and provides various filtering options.
    
    Example:
        &gt;&gt;&gt; manager = TaskManager()
        &gt;&gt;&gt; task = manager.add_task("Complete documentation")
        &gt;&gt;&gt; manager.get_task(task.id)
        Task(id=1, title='Complete documentation', completed=False)
    """
    
    def __init__(self):
        """Initialize empty task manager"""
        self.tasks: Dict[int, Task] = {}
        self._next_id = 1
    
    def add_task(self, title: str, tags: Optional[List[str]] = None) -&gt; Task:
        """Add a new task
        
        Args:
            title: Task title
            tags: Optional list of tags
            
        Returns:
            The created task
            
        Raises:
            ValueError: If title is empty
        """
        if not title:
            raise ValueError("Task title cannot be empty")
            
        task = Task(id=self._next_id, title=title, tags=tags)
        self.tasks[task.id] = task
        self._next_id += 1
        return task
    
    def get_task(self, task_id: int) -&gt; Optional[Task]:
        """Get task by ID
        
        Args:
            task_id: Task identifier
            
        Returns:
            Task if found, None otherwise
        """
        return self.tasks.get(task_id)
    
    def complete_task(self, task_id: int) -&gt; bool:
        """Mark task as completed
        
        Args:
            task_id: Task identifier
            
        Returns:
            True if task was marked complete, False if not found
        """
        task = self.get_task(task_id)
        if task:
            task.completed = True
            return True
        return False
    
    def get_tasks_by_tag(self, tag: str) -&gt; List[Task]:
        """Get all tasks with specific tag
        
        Args:
            tag: Tag to filter by
            
        Returns:
            List of tasks with the specified tag
        """
        return [
            task for task in self.tasks.values()
            if task.tags and tag in task.tags
        ]

def process_tasks(manager: TaskManager, tag: str = "important") -&gt; int:
    """Process all tasks with given tag
    
    This function demonstrates task processing logic.
    
    Args:
        manager: Task manager instance
        tag: Tag to filter tasks
        
    Returns:
        Number of tasks processed
    """
    tasks = manager.get_tasks_by_tag(tag)
    count = 0
    
    for task in tasks:
        if not task.completed:
            # Process task
            print(f"Processing: {task.title}")
            manager.complete_task(task.id)
            count += 1
            
    return count
'''

def main():
    """Run documentation generation demo"""
    
    # Set up paths
    project_dir = Path("demo_project")
    project_dir.mkdir(exist_ok=True)
    
    # Create sample file
    sample_file = project_dir / "task_manager.py"
    sample_file.write_text(sample_code)
    
    # Create template directory with sample templates
    template_dir = Path("templates")
    template_dir.mkdir(exist_ok=True)
    
    # Configure agent
    config = DocumentationConfig(
        project_name="Task Manager Demo",
        version="1.0.0",
        author="Documentation Agent",
        formats=[DocFormat.MARKDOWN, DocFormat.HTML],
        output_dir=Path("docs"),
        template_dir=template_dir,
        include_private=False,
        include_source=True
    )
    
    # Create agent
    agent = DocumentationAgent(config)
    
    # Analyze project
    print("🔍 Analyzing project...")
    stats = agent.analyze_project(project_dir)
    
    print(f"\n📊 Analysis Results:")
    print(f"  - Files analyzed: {stats['total_files']}")
    print(f"  - Documented entities: {stats['documented_entities']}")
    print(f"  - Undocumented entities: {stats['undocumented_entities']}")
    print(f"  - Coverage: {stats['coverage']:.1%}")
    
    # Generate documentation
    print("\n📝 Generating documentation...")
    generated = agent.generate_documentation()
    
    print("\n✅ Documentation generated:")
    for format_type, path in generated.items():
        print(f"  - {format_type.value}: {path}")
    
    # Test incremental update
    print("\n🔄 Testing incremental update...")
    
    # Modify the sample file
    updated_code = sample_code.replace(
        "def add_task(self, title: str",
        "def add_task(self, title: str, priority: int = 0"
    )
    sample_file.write_text(updated_code)
    
    # Update documentation
    updated = agent.update_documentation([sample_file])
    print("✅ Documentation updated")
    
    # Show memory statistics
    if hasattr(agent, 'memory'):
        stats = agent.memory.current_state
        print(f"\n💾 Memory Statistics:")
        print(f"  - Tracked entities: {len(stats['entities'])}")
        print(f"  - Last update: {stats['last_update']}")

if __name__ == "__main__":
    main()
```

### Step 7: Create Tests

Create `tests/test_documentation_agent.py`:
```python
import pytest
from pathlib import Path
from src.agents.documentation_agent import (
    DocumentationAgent, DocumentationConfig, DocFormat, CodeEntity
)
from src.analyzers.python_analyzer import PythonAnalyzer

class TestDocumentationAgent:
    @pytest.fixture
    def config(self, tmp_path):
        return DocumentationConfig(
            project_name="Test Project",
            version="1.0.0",
            author="Test Author",
            formats=[DocFormat.MARKDOWN],
            output_dir=tmp_path / "docs",
            template_dir=Path("templates"),
            include_private=False
        )
    
    @pytest.fixture
    def agent(self, config):
        return DocumentationAgent(config)
    
    def test_agent_initialization(self, agent):
        """Test agent initializes correctly"""
        assert agent.config.project_name == "Test Project"
        assert len(agent.entities) == 0
        assert agent.template_engine is not None
        assert DocFormat.MARKDOWN in agent.generators
    
    def test_analyze_simple_module(self, agent, tmp_path):
        """Test analyzing a simple Python module"""
        # Create test file
        test_file = tmp_path / "test_module.py"
        test_file.write_text('''
"""Test module docstring"""

def test_function(param: str) -&gt; str:
    """Test function docstring
    
    Args:
        param: Test parameter
        
    Returns:
        Modified parameter
    """
    return param.upper()
''')
        
        # Analyze
        stats = agent.analyze_project(tmp_path)
        
        assert stats['total_files'] == 1
        assert stats['documented_entities'] == 2  # module + function
        assert stats['coverage'] == 1.0
        assert len(agent.entities) == 2
    
    def test_documentation_generation(self, agent, tmp_path):
        """Test documentation generation"""
        # Create test entity
        entity = CodeEntity(
            name="test_function",
            type="function",
            docstring="Test function",
            signature="def test_function(x: int) -&gt; int",
```jinja2
            parameters=[{"name": "x", "type": "int", "default": None}],
            returns={"type": "int", "description": "Result"},
```
            raises=[],
            examples=["&gt;&gt;&gt; test_function(5)\\n10"],
            source_file="test.py",
            line_number=1
        )
        
        agent.entities = [entity]
        
        # Generate docs
        generated = agent.generate_documentation()
        
        assert DocFormat.MARKDOWN in generated
        assert generated[DocFormat.MARKDOWN].exists()
    
    def test_memory_system(self, agent, tmp_path):
        """Test documentation memory system"""
        # Create test file
        test_file = tmp_path / "test.py"
        test_file.write_text('def func(): pass')
        
        # First analysis
        agent.analyze_project(tmp_path)
        initial_entities = len(agent.entities)
        
        # Modify file
        test_file.write_text('def func():\n    """New docstring"""\n    pass')
        
        # Update documentation
        agent.update_documentation([test_file])
        
        # Should detect the change
        assert len(agent.entities) == initial_entities
    
    def test_skip_private_entities(self, agent, tmp_path):
        """Test that private entities are skipped"""
        test_file = tmp_path / "test.py"
        test_file.write_text('''
def public_function():
    pass

def _private_function():
    pass

class PublicClass:
    pass

class _PrivateClass:
    pass
''')
        
        agent.analyze_project(tmp_path)
        
        # Should only find public entities
        entity_names = [e.name for e in agent.entities]
        assert "public_function" in entity_names
        assert "PublicClass" in entity_names
        assert "_private_function" not in entity_names
        assert "_PrivateClass" not in entity_names

class TestPythonAnalyzer:
    def test_extract_function_parameters(self):
        """Test parameter extraction"""
        analyzer = PythonAnalyzer(None)
        
        # Test code with various parameter types
        code = '''
def complex_function(
    pos_arg,
    typed_arg: int,
    default_arg: str = "default",
    *args,
    keyword_only: bool,
    **kwargs
) -&gt; dict:
    pass
'''
        
        import ast
        tree = ast.parse(code)
        func_node = tree.body[0]
        
        params = analyzer._extract_parameters(func_node)
        
        assert len(params) == 6
        assert params[0]['name'] == 'pos_arg'
        assert params[1]['type'] == 'int'
        assert params[2]['default'] == '"default"'
        assert params[3]['name'] == '*args'
        assert params[4]['name'] == 'keyword_only'
        assert params[5]['name'] == '**kwargs'
```

## 🏃 Running the Documentation Agent

1. **Set up the environment**:
```bash
# Create templates directory
mkdir -p templates/markdown
# Copy template files from exercise

# Run the demo
python src/doc_agent_demo.py
```

2. **Use with your project**:
```python
from pathlib import Path
from src.agents.documentation_agent import DocumentationAgent, DocumentationConfig, DocFormat

# Configure for your project
config = DocumentationConfig(
    project_name="My Project",
    version="2.0.0",
    author="Your Name",
    formats=[DocFormat.MARKDOWN, DocFormat.HTML],
    output_dir=Path("docs"),
    template_dir=Path("templates")
)

# Create agent and generate docs
agent = DocumentationAgent(config)
stats = agent.analyze_project(Path("src"))
generated = agent.generate_documentation()

print(f"Documentation coverage: {stats['coverage']:.1%}")
```

## 🎯 Validation

Run the validation script:
```bash
python scripts/validate_exercise1.py
```

Expected output:
```
✅ Documentation agent implemented
✅ Code analyzer working correctly
✅ Multiple format generators functional
✅ Memory system tracks changes
✅ Templates render correctly
✅ Incremental updates work

Score: 100/100
```

## 🚀 Extension Challenges

1. **Add Language Support**: Extend to JavaScript/TypeScript
2. **Interactive Mode**: Create CLI for interactive documentation
3. **Git Integration**: Auto-generate docs on commit
4. **Quality Metrics**: Add documentation quality scoring
5. **AI Enhancement**: Use LLM to improve docstrings

## 📚 Additional Resources

- [Sphinx Documentation](https://www.sphinx-doc.org/)
- [MkDocs](https://www.mkdocs.org/)
- [Python AST Documentation](https://docs.python.org/3/library/ast.html)
- [Jinja2 Templates](https://jinja.palletsprojects.com/)

## ⏭️ Next Exercise

Ready for more? Move on to [Exercise 2: Database Migration Agent](../exercise2-medium/README.md) where you'll build an agent that manages database schema changes!