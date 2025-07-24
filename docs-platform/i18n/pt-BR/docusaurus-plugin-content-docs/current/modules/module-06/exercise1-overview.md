---
sidebar_position: 2
title: "Exercise 1: Overview"
description: "## 🎯 Objective"
---

# Exercício 1: Task Management System (⭐ Fácil)

## 🎯 Objective

Build a multi-file task management system that demonstrates fundamental workspace concepts in GitHub Copilot. You'll create a modular application with separate files for models, services, and the main application logic.

**Duração**: 30-45 minutos  
**Difficulty**: ⭐ (Fácil)  
**Success Rate**: 95%

## 📋 Learning Goals

Ao completar este exercício, você irá:
1. Use `@workspace` to navigate multi-file projects
2. Leverage Copilot's multi-file context awareness
3. Create modular Python applications
4. Implement cross-file refactoring
5. Practice workspace-level testing

## 🏗️ What You'll Build

A command-line task management system with:
- Task model with CRUD operations
- Service layer for business logic
- Persistence using JSON files
- CLI interface for user interaction
- Unit tests across multiple modules

## 📁 Project Structure

```
task-manager/
├── src/
│   ├── __init__.py
│   ├── models/
│   │   ├── __init__.py
│   │   └── task.py          # Task data model
│   ├── services/
│   │   ├── __init__.py
│   │   └── task_service.py  # Business logic
│   ├── storage/
│   │   ├── __init__.py
│   │   └── json_storage.py  # File persistence
│   └── cli.py               # Command-line interface
├── tests/
│   ├── __init__.py
│   ├── test_models.py
│   ├── test_services.py
│   └── test_storage.py
├── main.py                  # Application entry point
└── requirements.txt
```

## 🚀 Step-by-Step Instructions

### Step 1: Configurar the Workspace

1. Create the project structure:
```bash
mkdir -p task-manager/src/{models,services,storage}
mkdir -p task-manager/tests
cd task-manager
```

2. Initialize the Python ambiente:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Create `requirements.txt`:
```txt
pydantic==2.5.0
click==8.1.7
pytest==7.4.3
pytest-cov==4.1.0
```

4. Install dependencies:
```bash
pip install -r requirements.txt
```

5. Abrir in VS Code:
```bash
code .
```

### Step 2: Create the Task Model

1. Abrir `src/models/task.py`

2. Add this comment to guide Copilot:
```python
# Create a Pydantic model for a Task with:
# - id: UUID
# - title: str (required)
# - description: str (optional)
# - status: enum (TODO, IN_PROGRESS, DONE)
# - created_at: datetime
# - updated_at: datetime
# - priority: int (1-5, default 3)
```

3. **Copilot Prompt Suggestion:**
```python
# After the comment above, press Enter and wait for Copilot
# It should suggest the imports and model structure
# Accept suggestions with Tab
```

**Expected structure:**
- Proper imports (uuid, datetime, pydantic, enum)
- TaskStatus enum
- Task model with validation
- Ajudaer methods for status updates

### Step 3: Implement Storage Layer

1. Abrir `src/storage/json_storage.py`

2. Use this guided prompt:
```python
# Create a JSONStorage class that:
# - Saves and loads tasks from a JSON file
# - Handles file creation if it doesn't exist
# - Provides methods: save_task, get_task, get_all_tasks, update_task, delete_task
# - Uses the Task model from models.task
```

3. **Workspace Context Tip:**
   - Abrir both `task.py` and `json_storage.py` in tabs
   - Copilot will recognize the Task model and suggest proper imports

### Step 4: Build the Service Layer

1. Abrir `src/services/task_service.py`

2. Comece com Copilot Chat:
   - Abrir Copilot Chat (Ctrl+I / Cmd+I)
   - Type: `@workspace create a TaskService class that uses JSONStorage and provides business logic for task management`

3. The service should include:
   - Task creation with validation
   - Status transitions (TODO → IN_PROGRESS → DONE)
   - Priority-based sorting
   - Pesquisar functionality

### Step 5: Create the CLI Interface

1. Abrir `src/cli.py`

2. **Multi-file Editar Mode:**
   - Click on Copilot icon → "Editar"
   - Select `cli.py`, `task_service.py`, and `task.py`
   - Prompt: "Create a Click CLI that provides commands for all task operations using the TaskService"

3. Implement commands:
   - `add` - Create a new task
   - `list` - Show all tasks
   - `update` - Modify task status
   - `delete` - Remove a task
   - `search` - Find tasks by title

### Step 6: Write Tests

1. Abrir `tests/test_models.py`

2. Use Copilot to generate tests:
```python
# Test Task model validation, including:
# - Valid task creation
# - Invalid priority values
# - Status transitions
# - Datetime handling
```

3. **Workspace Navigation:**
   - In Copilot Chat: `@workspace show me all methods in TaskService that need testing`
   - Use the results to create comprehensive tests

### Step 7: Create the Main Entry Point

1. Abrir `main.py`

2. Simple prompt:
```python
# Create entry point that imports and runs the CLI
```

### Step 8: Test Your Application

1. Run the tests:
```bash
pytest -v --cov=src
```

2. Test the CLI:
```bash
python main.py add "Complete Module 6" --priority 5
python main.py list
python main.py update 1 --status IN_PROGRESS
```

## 🎯 Validation Criteria

Your implementation should:
- [ ] Have at least 4 separate Python files
- [ ] Use proper imports across files
- [ ] Include error handling
- [ ] Pass all unit tests
- [ ] Provide a working CLI
- [ ] Demonstrate workspace navigation

## 💡 Copilot Tips

1. **Use @workspace for exploration:**
   ```
   @workspace find all classes that inherit from BaseModel
   @workspace what storage methods are available?
   ```

2. **Keep related files open:**
   - Having multiple files open helps Copilot understand relationships

3. **Use Editar mode for refactoring:**
   - Select multiple files when making cross-file changes

4. **Leverage Agent mode for complex tasks:**
   - Let Copilot create the entire test suite

## 🐛 Common Issues

### Import Errors
- Ensure all `__init__.py` files exist
- Use relative imports: `from ..models.task import Task`

### Copilot Not Suggesting Cross-file Imports
- Abrir the files you're importing from
- Add explicit comments about what you need

### JSON Storage Issues
- Create the data directory if it doesn't exist
- Handle file permissions properly

## 🚀 Extension Challenges

Once you complete the basic requirements:

1. **Add Tags to Tarefas**
   - Modify the model to support multiple tags
   - Atualizar all layers to handle tags

2. **Implement Task Dependencies**
   - Allow tasks to depend on other tasks
   - Prevent closing tasks with open dependencies

3. **Add Export Functionality**
   - Export tasks to CSV
   - Import tasks from CSV

## 📝 Reflection Questions

After completing this exercise:
1. How did having multiple files open affect Copilot's suggestions?
2. Which Copilot mode (Chat/Editar/Agent) was most helpful?
3. What workspace organization strategies improved AI assistance?

## ✅ Verificarlist

Before moving to the next exercise:
- [ ] All tests pass
- [ ] CLI works for all operations
- [ ] Used @workspace at least 3 times
- [ ] Tried all three Copilot modes
- [ ] Code is properly organized across files

---

**Ready for more?** Move on to Exercise 2 where you'll build a microservice with API endpoints!