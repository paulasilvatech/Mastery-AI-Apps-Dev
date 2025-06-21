"""
Task Service - Business Logic Layer

This is an example solution showing best practices for multi-file projects.
Notice how it properly imports from other modules and maintains clear separation of concerns.
"""

from typing import List, Optional, Dict
from uuid import UUID
from datetime import datetime
import logging

from src.models.task import Task, TaskStatus
from src.storage.json_storage import JSONStorage
from src.exceptions import (
    TaskNotFoundError,
    InvalidStatusTransitionError,
    ValidationError
)


# Configure logging
logger = logging.getLogger(__name__)


class TaskService:
    """Service layer for task management.
    
    This service implements all business logic for tasks,
    including validation, status transitions, and search functionality.
    
    Attributes:
        storage: The storage backend for persisting tasks.
    """
    
    # Valid status transitions
    VALID_TRANSITIONS = {
        TaskStatus.TODO: [TaskStatus.IN_PROGRESS],
        TaskStatus.IN_PROGRESS: [TaskStatus.TODO, TaskStatus.DONE],
        TaskStatus.DONE: [TaskStatus.IN_PROGRESS]  # Allow reopening
    }
    
    def __init__(self, storage: JSONStorage):
        """Initialize the task service.
        
        Args:
            storage: Storage implementation for task persistence.
        """
        self.storage = storage
        logger.info("TaskService initialized with storage: %s", type(storage).__name__)
    
    def create_task(
        self,
        title: str,
        description: Optional[str] = None,
        priority: int = 3
    ) -> Task:
        """Create a new task.
        
        Args:
            title: Task title (required).
            description: Optional task description.
            priority: Task priority (1-5, default 3).
            
        Returns:
            The created task.
            
        Raises:
            ValidationError: If input validation fails.
        """
        # Validate inputs
        if not title or not title.strip():
            raise ValidationError("Task title cannot be empty")
        
        if not 1 <= priority <= 5:
            raise ValidationError(f"Priority must be between 1 and 5, got {priority}")
        
        # Create the task
        task = Task(
            title=title.strip(),
            description=description,
            priority=priority
        )
        
        # Save to storage
        self.storage.save_task(task)
        logger.info("Created task: %s", task.id)
        
        return task
    
    def get_task(self, task_id: UUID) -> Task:
        """Retrieve a task by ID.
        
        Args:
            task_id: The UUID of the task.
            
        Returns:
            The requested task.
            
        Raises:
            TaskNotFoundError: If task doesn't exist.
        """
        task = self.storage.get_task(task_id)
        if not task:
            raise TaskNotFoundError(f"Task {task_id} not found")
        return task
    
    def list_tasks(
        self,
        status: Optional[TaskStatus] = None,
        priority: Optional[int] = None,
        sort_by: str = "created_at"
    ) -> List[Task]:
        """List tasks with optional filtering and sorting.
        
        Args:
            status: Filter by task status.
            priority: Filter by priority level.
            sort_by: Sort field (created_at, priority, updated_at).
            
        Returns:
            List of tasks matching the criteria.
        """
        tasks = self.storage.get_all_tasks()
        
        # Apply filters
        if status:
            tasks = [t for t in tasks if t.status == status]
        
        if priority is not None:
            tasks = [t for t in tasks if t.priority == priority]
        
        # Sort results
        if sort_by == "priority":
            tasks.sort(key=lambda t: t.priority, reverse=True)
        elif sort_by == "updated_at":
            tasks.sort(key=lambda t: t.updated_at, reverse=True)
        else:  # Default to created_at
            tasks.sort(key=lambda t: t.created_at, reverse=True)
        
        logger.debug("Listed %d tasks with filters: status=%s, priority=%s", 
                    len(tasks), status, priority)
        
        return tasks
    
    def update_task_status(self, task_id: UUID, new_status: TaskStatus) -> Task:
        """Update task status with validation.
        
        Args:
            task_id: The task to update.
            new_status: The desired new status.
            
        Returns:
            The updated task.
            
        Raises:
            TaskNotFoundError: If task doesn't exist.
            InvalidStatusTransitionError: If transition is not allowed.
        """
        task = self.get_task(task_id)
        
        # Validate transition
        if new_status != task.status:
            valid_transitions = self.VALID_TRANSITIONS.get(task.status, [])
            if new_status not in valid_transitions:
                raise InvalidStatusTransitionError(
                    f"Cannot transition from {task.status} to {new_status}"
                )
        
        # Update the task
        task.status = new_status
        task.updated_at = datetime.now()
        
        # Save changes
        self.storage.update_task(task)
        logger.info("Updated task %s status: %s -> %s", 
                   task_id, task.status, new_status)
        
        return task
    
    def update_task_priority(self, task_id: UUID, priority: int) -> Task:
        """Update task priority.
        
        Args:
            task_id: The task to update.
            priority: New priority (1-5).
            
        Returns:
            The updated task.
            
        Raises:
            TaskNotFoundError: If task doesn't exist.
            ValidationError: If priority is invalid.
        """
        if not 1 <= priority <= 5:
            raise ValidationError(f"Priority must be between 1 and 5, got {priority}")
        
        task = self.get_task(task_id)
        task.priority = priority
        task.updated_at = datetime.now()
        
        self.storage.update_task(task)
        logger.info("Updated task %s priority: %d", task_id, priority)
        
        return task
    
    def delete_task(self, task_id: UUID) -> bool:
        """Delete a task.
        
        Args:
            task_id: The task to delete.
            
        Returns:
            True if deleted successfully.
            
        Raises:
            TaskNotFoundError: If task doesn't exist.
        """
        # Verify task exists
        self.get_task(task_id)
        
        # Delete from storage
        result = self.storage.delete_task(task_id)
        logger.info("Deleted task: %s", task_id)
        
        return result
    
    def search_tasks(self, query: str) -> List[Task]:
        """Search tasks by title or description.
        
        Args:
            query: Search query string.
            
        Returns:
            List of matching tasks.
        """
        if not query:
            return []
        
        query_lower = query.lower()
        all_tasks = self.storage.get_all_tasks()
        
        # Search in title and description
        matching_tasks = [
            task for task in all_tasks
            if (query_lower in task.title.lower() or
                (task.description and query_lower in task.description.lower()))
        ]
        
        logger.debug("Search for '%s' found %d tasks", query, len(matching_tasks))
        
        return matching_tasks
    
    def get_statistics(self) -> Dict[str, any]:
        """Get task statistics.
        
        Returns:
            Dictionary with task statistics.
        """
        tasks = self.storage.get_all_tasks()
        
        stats = {
            "total": len(tasks),
            "by_status": {
                TaskStatus.TODO: 0,
                TaskStatus.IN_PROGRESS: 0,
                TaskStatus.DONE: 0
            },
            "by_priority": {i: 0 for i in range(1, 6)},
            "completion_rate": 0.0
        }
        
        for task in tasks:
            stats["by_status"][task.status] += 1
            stats["by_priority"][task.priority] += 1
        
        if stats["total"] > 0:
            stats["completion_rate"] = (
                stats["by_status"][TaskStatus.DONE] / stats["total"] * 100
            )
        
        return stats


# Copilot Learning Notes:
# This service demonstrates several patterns that Copilot learns from:
# 1. Dependency injection in __init__
# 2. Comprehensive docstrings
# 3. Type hints throughout
# 4. Proper error handling with custom exceptions
# 5. Logging for observability
# 6. Business logic validation
# 7. Clear method naming conventions
# 8. Separation of concerns (service doesn't know about storage implementation)