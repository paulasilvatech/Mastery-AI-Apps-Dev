# Exercise 1: Context Optimization Workshop - Part 2

## 🎯 Part 2: Strategic Comments (10-15 minutes)

In this part, you'll master the art of using comments strategically to guide GitHub Copilot toward generating exactly the code you need.

## 📚 The Power of Comments

Comments aren't just for documentation—they're powerful context signals for Copilot. Well-placed comments can:

1. **Define Intent**: Tell Copilot what you want to achieve
2. **Specify Constraints**: Set boundaries and requirements
3. **Provide Examples**: Show input/output patterns
4. **Guide Style**: Influence code structure and naming

## 🛠️ Hands-On Exercise

### Step 1: Intent-Driven Comments

Add this to your `TaskManager` class:

```python
class TaskManager:
    # ... existing code ...
    
    # TODO: Implement batch operations for efficiency
    # Should accept a list of task IDs and an operation
    # Operations: 'complete', 'delete', 'priority_change'
    # Return a dict with results: {id: success_bool}
    def batch_update(self, task_ids: List[int], operation: str, **kwargs) -> Dict[int, bool]:
        # Let Copilot implement based on the detailed comment
```

**🤖 Copilot Prompt Suggestion #1:**
After typing the function signature, Copilot should generate code that:
- Iterates through task_ids
- Performs the specified operation
- Handles errors gracefully
- Returns the result dictionary

**Expected Output Example:**
```python
def batch_update(self, task_ids: List[int], operation: str, **kwargs) -> Dict[int, bool]:
    results = {}
    for task_id in task_ids:
        try:
            if operation == 'complete':
                task = self.get_task(task_id)
                if task:
                    task.completed = True
                    results[task_id] = True
                else:
                    results[task_id] = False
            elif operation == 'delete':
                # ... similar pattern
        except Exception:
            results[task_id] = False
    return results
```

### Step 2: Example-Driven Comments

Use examples in comments to guide complex implementations:

```python
# Create a method to parse natural language due dates
# Examples:
#   "tomorrow" -> next day at 9 AM
#   "next Friday" -> next Friday at 5 PM
#   "in 3 days" -> 3 days from now at current time
#   "end of month" -> last day of current month at 11:59 PM
def parse_due_date(self, date_string: str) -> datetime:
    """Parse natural language date strings into datetime objects."""
    # Copilot will use the examples to understand the pattern
```

**🤖 Expected Behavior**: Copilot should generate parsing logic that handles each example case, possibly using `datetime` and `timedelta` operations.

### Step 3: Constraint Comments

Specify constraints to get more precise code:

```python
# Generate a task report with the following requirements:
# - Group tasks by priority (5 to 1, descending)
# - Within each priority, sort by due date (earliest first)
# - Show only incomplete tasks
# - Format: Dict[int, List[Task]] where key is priority
# - Exclude tasks with no due date
def generate_priority_report(self) -> Dict[int, List[Task]]:
    # Copilot will follow these specific constraints
```

### Step 4: Style Guide Comments

Use comments to establish coding patterns:

```python
# Validation methods follow this pattern:
# - Name: validate_<field>
# - Return: Tuple[bool, Optional[str]] (is_valid, error_message)
# - Don't raise exceptions, return False with message

def validate_title(self, title: str) -> Tuple[bool, Optional[str]]:
    """Validate task title according to rules."""
    if not title or not title.strip():
        return False, "Title cannot be empty"
    if len(title) > 100:
        return False, "Title cannot exceed 100 characters"
    return True, None

# Now create similar validators:
def validate_priority(self, priority: int) -> Tuple[bool, Optional[str]]:
    # Copilot will follow the established pattern
```

### Step 5: Multi-Line Context Comments

For complex operations, use detailed multi-line comments:

```python
def smart_schedule(self, tasks_to_schedule: List[Task]) -> Dict[Task, datetime]:
    """
    Intelligently schedule tasks based on:
    
    Algorithm:
    1. Sort tasks by priority (highest first)
    2. Estimate time needed: 
       - Priority 5: 4 hours
       - Priority 4: 2 hours
       - Priority 3: 1 hour
       - Priority 1-2: 30 minutes
    3. Schedule starting from tomorrow 9 AM
    4. Don't schedule past 5 PM on any day
    5. Skip weekends
    6. Leave 30-minute buffers between tasks
    
    Returns mapping of task to suggested datetime
    """
    # With this detailed algorithm, Copilot can generate the implementation
```

### Step 6: Progressive Comment Refinement

Start with a basic comment and refine based on Copilot's output:

```python
# First attempt - too vague
# Create a search function
def search_tasks_v1(self, query: str):
    pass

# Second attempt - better
# Search tasks by title, description, and tags
# Case-insensitive, partial match
def search_tasks_v2(self, query: str) -> List[Task]:
    pass

# Third attempt - precise
# Search tasks using the following rules:
# - Check title, description, and all tags
# - Case-insensitive comparison
# - Partial match (use 'in' operator)
# - Return tasks sorted by relevance:
#   1. Title matches (weight: 3)
#   2. Description matches (weight: 2)
#   3. Tag matches (weight: 1)
# - No duplicates in results
def search_tasks_v3(self, query: str) -> List[Tuple[Task, int]]:
    # Returns list of (task, relevance_score) tuples
```

## 📊 Comment Strategy Patterns

### Pattern 1: The Recipe Comment
```python
# Recipe: Create a summary of tasks
# Ingredients: all tasks, date range
# Steps:
# 1. Filter tasks by date range
# 2. Group by completion status
# 3. Calculate statistics
# 4. Format as readable string
# Output: Multi-line summary string
```

### Pattern 2: The Contract Comment
```python
# Contract for this function:
# Preconditions:
#   - task_id must exist
#   - new_date must be in the future
# Postconditions:
#   - Task due_date is updated
#   - Modification timestamp is set
#   - Returns True on success
# Invariants:
#   - Other task fields unchanged
```

### Pattern 3: The Example Table Comment
```python
# Parse priority from string:
# Input     | Output
# --------- | ------
# "urgent"  | 5
# "high"    | 4
# "medium"  | 3
# "low"     | 2
# "trivial" | 1
# (other)   | 3 (default)
```

## 🧪 Testing Comment Effectiveness

Create a test to verify your comment strategy:

```python
# test_comment_guidance.py
def test_comment_guided_generation():
    """Test if comments effectively guide Copilot."""
    
    # Test 1: Specific algorithm comment
    # Implement fibonacci with memoization
    # Store results in a dict to avoid recalculation
    # Handle negative numbers by returning 0
    def fibonacci_memo(n: int) -> int:
        # Check if Copilot generates memoized solution
        pass
```

## 🎯 Part 2 Summary

You've learned:
1. Using comments to define clear intent
2. Providing examples in comments
3. Specifying constraints and requirements
4. Establishing coding patterns
5. Progressive comment refinement

## 💡 Pro Tips

### Effective Comment Strategies
- **Be Specific**: Vague comments yield vague code
- **Use Examples**: Show don't just tell
- **Define Edge Cases**: Mention special handling
- **Specify Types**: Even in comments, mention types
- **Order Matters**: Put most important info first

### Comment Anti-Patterns to Avoid
- ❌ "Do something with the data"
- ❌ "Handle errors" (too vague)
- ❌ Contradictory requirements
- ❌ Overly complex nested logic
- ❌ Assuming context not provided

## ⚡ Quick Challenge

Try this exercise:

```python
# Challenge: Create a task delegation system
# Requirements:
# - Assign tasks to team members (string names)
# - Balance workload (max 5 tasks per person)
# - Consider task priority (high priority to experienced members)
# - Track assignment history
# - Return delegation plan as Dict[str, List[Task]]
# 
# Team structure:
# - Senior: ["Alice", "Bob"] (can handle priority 4-5)
# - Mid: ["Carol", "Dave"] (can handle priority 2-4)  
# - Junior: ["Eve", "Frank"] (can handle priority 1-3)

def delegate_tasks(self, unassigned_tasks: List[Task]) -> Dict[str, List[Task]]:
    # Let Copilot implement this complex logic
```

---

✅ **Excellent work! Ready for Part 3 to learn advanced context techniques!**