# Exercise 3: Debug & Optimize API (⭐⭐⭐ Hard)

## 🎯 Exercise Overview

**Duration**: 60-90 minutes  
**Difficulty**: ⭐⭐⭐ (Hard)  
**Success Rate**: 60%

In this challenging exercise, you'll receive a buggy REST API with poor test coverage and performance issues. You'll use GitHub Copilot to debug problems, write comprehensive tests, optimize performance, and implement best practices for production-ready code.

## 🎓 Learning Objectives

By completing this exercise, you will:
- Debug complex API issues with AI assistance
- Improve test coverage from ~40% to 95%+
- Optimize database queries and caching
- Implement comprehensive error handling
- Add performance monitoring and logging

## 📋 Prerequisites

- ✅ Completed Exercises 1 & 2
- ✅ Understanding of REST APIs
- ✅ Basic knowledge of Flask/FastAPI
- ✅ Familiarity with async programming

## 🏗️ What You'll Fix and Build

A **Task Management API** that currently has:
- 🐛 Multiple bugs causing test failures
- 📉 Poor test coverage (~40%)
- 🐌 Performance issues with N+1 queries
- ❌ Missing error handling
- 🔓 Security vulnerabilities
- 📊 No monitoring or logging

## 📁 Project Structure

```
exercise3-hard/
├── README.md                    # This file
├── instructions/
│   ├── part1.md                # Debugging and testing
│   ├── part2.md                # Performance optimization
│   └── part3.md                # Production hardening
├── starter/
│   ├── app.py                  # Buggy Flask API
│   ├── models.py               # Database models
│   ├── routes/
│   │   ├── __init__.py
│   │   ├── tasks.py            # Task endpoints (buggy)
│   │   ├── users.py            # User endpoints (buggy)
│   │   └── projects.py         # Project endpoints (buggy)
│   ├── tests/
│   │   ├── test_tasks.py       # Incomplete tests
│   │   ├── test_users.py       # Missing tests
│   │   └── test_projects.py    # Failing tests
│   └── requirements.txt
├── solution/
│   └── [complete fixed implementation]
└── debugging/
    ├── bug_report.md           # List of known issues
    └── performance_profile.txt # Performance baseline
```

## 🐛 Part 1: Initial Assessment

### Step 1: Run the Broken Tests

First, let's see what we're dealing with:

```bash
cd starter
pip install -r requirements.txt
pytest -v
```

You'll see output like:
```
========================= test session starts ==========================
test_tasks.py::test_create_task FAILED
test_tasks.py::test_get_task PASSED
test_tasks.py::test_update_task FAILED
test_tasks.py::test_delete_task ERROR
test_projects.py::test_create_project FAILED
test_projects.py::test_list_projects ERROR
... 
=================== 8 failed, 4 passed, 3 errors ===================
```

### Step 2: Check Current Coverage

```bash
pytest --cov=. --cov-report=term-missing
```

Output shows:
```
Name            Stmts   Miss  Cover   Missing
----------------------------------------------
app.py             45     27    40%   12-15, 23-35, 41-45
models.py          78     45    42%   23-45, 67-89
routes/tasks.py    95     58    39%   [many lines]
routes/users.py    67     67     0%   1-67
----------------------------------------------
TOTAL            285    197    31%
```

### Step 3: Examine the Buggy Code

Open `routes/tasks.py` and you'll find code like this:

```python
# routes/tasks.py - BUGGY VERSION
from flask import Blueprint, request, jsonify
from models import Task, User, db
from datetime import datetime

tasks_bp = Blueprint('tasks', __name__)

@tasks_bp.route('/tasks', methods=['GET'])
def get_tasks():
    """Get all tasks with filters."""
    # BUG: N+1 query problem
    tasks = Task.query.all()
    result = []
    for task in tasks:
        task_data = {
            'id': task.id,
            'title': task.title,
            'description': task.description,
            'status': task.status,
            'created_at': task.created_at,
            # BUG: This causes N+1 queries
            'assignee': task.assignee.username if task.assignee else None,
            'project': task.project.name  # BUG: No null check
        }
        result.append(task_data)
    return jsonify(result)

@tasks_bp.route('/tasks', methods=['POST'])
def create_task():
    """Create a new task."""
    data = request.json  # BUG: No validation
    
    task = Task(
        title=data['title'],  # BUG: KeyError if missing
        description=data['description'],
        assignee_id=data['assignee_id'],  # BUG: No validation
        project_id=data['project_id']
    )
    
    db.session.add(task)
    db.session.commit()  # BUG: No error handling
    
    return jsonify({'id': task.id}), 201

@tasks_bp.route('/tasks/<int:task_id>', methods=['PUT'])
def update_task(task_id):
    """Update a task."""
    task = Task.query.get(task_id)  # BUG: No 404 handling
    data = request.json
    
    # BUG: Allows setting invalid status
    task.title = data.get('title', task.title)
    task.status = data.get('status', task.status)
    
    # BUG: SQL injection vulnerability
    if 'assignee_username' in data:
        user = User.query.filter(
            f"username = '{data['assignee_username']}'"  # DANGER!
        ).first()
        task.assignee = user
    
    db.session.commit()
    return jsonify({'message': 'Updated'})
```

## 🔍 Part 2: Debugging with Copilot

### Step 4: Fix the Create Task Endpoint

Let's fix the create_task function using Copilot:

```python
# Fix the create_task endpoint:
# 1. Add request validation
# 2. Check if assignee and project exist
# 3. Add proper error handling
# 4. Return complete task data
@tasks_bp.route('/tasks', methods=['POST'])
def create_task():
```

**🤖 Copilot Prompt Suggestion #1:**
"Fix create_task endpoint with request validation using Flask-Marshmallow schema, verify foreign keys exist, handle database errors, and return serialized task"

**Expected Fix:**
```python
from flask import abort
from marshmallow import Schema, fields, ValidationError
from sqlalchemy.exc import SQLAlchemyError

class TaskCreateSchema(Schema):
    title = fields.Str(required=True, validate=lambda x: 1 <= len(x) <= 200)
    description = fields.Str(required=True)
    assignee_id = fields.Int(required=False)
    project_id = fields.Int(required=True)
    due_date = fields.DateTime(required=False)

task_create_schema = TaskCreateSchema()

@tasks_bp.route('/tasks', methods=['POST'])
def create_task():
    """Create a new task with validation."""
    # Validate request data
    try:
        data = task_create_schema.load(request.json)
    except ValidationError as err:
        return jsonify({'errors': err.messages}), 400
    
    # Verify project exists
    project = Project.query.get(data['project_id'])
    if not project:
        return jsonify({'error': 'Project not found'}), 404
    
    # Verify assignee exists if provided
    if data.get('assignee_id'):
        assignee = User.query.get(data['assignee_id'])
        if not assignee:
            return jsonify({'error': 'Assignee not found'}), 404
    
    # Create task
    try:
        task = Task(
            title=data['title'],
            description=data['description'],
            project_id=data['project_id'],
            assignee_id=data.get('assignee_id'),
            due_date=data.get('due_date'),
            status='pending'
        )
        
        db.session.add(task)
        db.session.commit()
        
        return jsonify({
            'id': task.id,
            'title': task.title,
            'status': task.status,
            'created_at': task.created_at.isoformat()
        }), 201
        
    except SQLAlchemyError as e:
        db.session.rollback()
        return jsonify({'error': 'Database error occurred'}), 500
```

### Step 5: Fix the N+1 Query Problem

Fix the get_tasks endpoint:

```python
# Fix get_tasks to eliminate N+1 queries
# Use eager loading with joinedload
# Add query filters for status, assignee, project
# Add pagination support
@tasks_bp.route('/tasks', methods=['GET'])
def get_tasks():
```

**🤖 Copilot Prompt Suggestion #2:**
"Fix get_tasks with eager loading using joinedload for assignee and project, add filters for status/assignee_id/project_id from query params, implement pagination with page/per_page"

### Step 6: Fix the SQL Injection Vulnerability

```python
# Fix update_task to:
# 1. Remove SQL injection vulnerability
# 2. Add 404 handling
# 3. Validate status values
# 4. Use proper ORM queries
@tasks_bp.route('/tasks/<int:task_id>', methods=['PUT'])
def update_task(task_id):
```

**🤖 Copilot Prompt Suggestion #3:**
"Fix update_task removing SQL injection by using ORM filter_by, add 404 if task not found, validate status in ['pending','in_progress','completed'], use schema validation"

## 🧪 Part 3: Writing Comprehensive Tests

### Step 7: Create Test Fixtures

Create `conftest.py` with proper test fixtures:

```python
# conftest.py
import pytest
from app import create_app, db
from models import User, Project, Task
from datetime import datetime

# Create test fixtures for:
# 1. Test app with test database
# 2. Database session with rollback
# 3. Sample users, projects, and tasks
# 4. Authentication headers
```

**🤖 Copilot Prompt Suggestion #4:**
"Create pytest fixtures: app with test config, db session with transaction rollback, create_user/create_project/create_task factories, auth_headers fixture for API testing"

### Step 8: Write Comprehensive Task Tests

Update `test_tasks.py`:

```python
# Write comprehensive tests for tasks API:
# - Test all CRUD operations
# - Test validation errors
# - Test filtering and pagination
# - Test authorization
# - Test edge cases
class TestTasksAPI:
```

**🤖 Copilot Prompt Suggestion #5:**
"Create TestTasksAPI class with tests for: create with valid/invalid data, get with filters, update with authorization check, delete cascade behavior, pagination limits"

### Step 9: Add Integration Tests

```python
# Test complex workflows:
# 1. Create project -> Create tasks -> Assign users
# 2. Test task status transitions
# 3. Test concurrent updates
# 4. Test bulk operations
def test_complete_task_workflow(client, db_session):
```

## 🚀 Part 4: Performance Optimization

### Step 10: Add Database Indexes

Examine slow queries and add indexes:

```python
# models.py - Add indexes for common queries
class Task(db.Model):
    __tablename__ = 'tasks'
    
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    status = db.Column(db.String(20), nullable=False, default='pending')
    assignee_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    project_id = db.Column(db.Integer, db.ForeignKey('projects.id'))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Add indexes for common queries
    __table_args__ = (
        db.Index('idx_task_status', 'status'),
        db.Index('idx_task_assignee', 'assignee_id'),
        db.Index('idx_task_project', 'project_id'),
        db.Index('idx_task_created', 'created_at'),
    )
```

### Step 11: Implement Caching

Add caching for frequently accessed data:

```python
# Add caching using Flask-Caching
from flask_caching import Cache

cache = Cache(config={'CACHE_TYPE': 'simple'})

# Cache get_tasks results
@tasks_bp.route('/tasks', methods=['GET'])
@cache.cached(timeout=60, query_string=True)
def get_tasks():
```

**🤖 Copilot Prompt Suggestion #6:**
"Add Redis caching to get_tasks with cache key based on filters, invalidate cache on create/update/delete, add cache warming for popular queries"

### Step 12: Add Query Optimization

```python
# Optimize database queries:
# 1. Use select_related for foreign keys
# 2. Add query result limiting
# 3. Use database views for complex aggregations
# 4. Implement query result streaming for large datasets
```

---

**Continue to Part 2** for implementing monitoring, error tracking, and production hardening.