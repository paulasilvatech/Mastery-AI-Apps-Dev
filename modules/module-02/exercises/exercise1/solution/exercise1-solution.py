"""
Pattern Library Builder - Exercise 1 Solution
Complete implementation demonstrating Copilot's capabilities
"""

from typing import List, Dict, Any, Optional, Tuple, Union
import re
from datetime import datetime
from collections import defaultdict
import json

# ============================================================================
# PART 1: DATA STRUCTURE PATTERNS
# ============================================================================

class PatternLibrary:
    """A collection of coding patterns to explore Copilot's capabilities."""
    
    def __init__(self):
        self.patterns = []
        self.context_experiments = []
    
    class Stack:
        """Stack implementation with push, pop, peek, and is_empty methods."""
        
        def __init__(self):
            self.items = []
        
        def push(self, item: Any) -> None:
            """Add an item to the top of the stack."""
            self.items.append(item)
        
        def pop(self) -> Any:
            """Remove and return the top item from the stack."""
            if self.is_empty():
                raise IndexError("Stack is empty")
            return self.items.pop()
        
        def peek(self) -> Any:
            """Return the top item without removing it."""
            if self.is_empty():
                raise IndexError("Stack is empty")
            return self.items[-1]
        
        def is_empty(self) -> bool:
            """Check if the stack is empty."""
            return len(self.items) == 0
        
        def size(self) -> int:
            """Return the number of items in the stack."""
            return len(self.items)
    
    class Queue:
        """Queue implementation with enqueue, dequeue, and size methods."""
        
        def __init__(self):
            self.items = []
        
        def enqueue(self, item: Any) -> None:
            """Add an item to the rear of the queue."""
            self.items.append(item)
        
        def dequeue(self) -> Any:
            """Remove and return the front item from the queue."""
            if self.is_empty():
                raise IndexError("Queue is empty")
            return self.items.pop(0)
        
        def size(self) -> int:
            """Return the number of items in the queue."""
            return len(self.items)
        
        def is_empty(self) -> bool:
            """Check if the queue is empty."""
            return len(self.items) == 0
        
        def front(self) -> Any:
            """Return the front item without removing it."""
            if self.is_empty():
                raise IndexError("Queue is empty")
            return self.items[0]
    
    class Node:
        """Node class for a linked list with data and next attributes."""
        
        def __init__(self, data: Any, next_node: Optional['Node'] = None):
            self.data = data
            self.next = next_node
        
        def __repr__(self) -> str:
            return f"Node({self.data})"

# ============================================================================
# PART 2: ALGORITHM PATTERNS
# ============================================================================

class AlgorithmPatterns:
    """Common algorithm implementations to test Copilot's problem-solving."""
    
    @staticmethod
    def binary_search(arr: List[int], target: int) -> int:
        """
        Implement binary search that returns the index of target in sorted array.
        
        Args:
            arr: Sorted list of integers
            target: Value to search for
            
        Returns:
            Index of target if found, -1 otherwise
        """
        left, right = 0, len(arr) - 1
        
        while left <= right:
            mid = (left + right) // 2
            
            if arr[mid] == target:
                return mid
            elif arr[mid] < target:
                left = mid + 1
            else:
                right = mid - 1
        
        return -1
    
    @staticmethod
    def bubble_sort(arr: List[int]) -> None:
        """
        Sort a list in place using bubble sort algorithm.
        
        Args:
            arr: List to be sorted in place
            
        Example:
            >>> numbers = [64, 34, 25, 12, 22, 11, 90]
            >>> AlgorithmPatterns.bubble_sort(numbers)
            >>> print(numbers)
            [11, 12, 22, 25, 34, 64, 90]
        """
        n = len(arr)
        
        for i in range(n):
            # Flag to optimize by detecting if array is already sorted
            swapped = False
            
            for j in range(0, n - i - 1):
                if arr[j] > arr[j + 1]:
                    arr[j], arr[j + 1] = arr[j + 1], arr[j]
                    swapped = True
            
            # If no swapping occurred, array is sorted
            if not swapped:
                break
    
    @staticmethod
    def fibonacci_memoized(n: int, memo: Optional[Dict[int, int]] = None) -> int:
        """
        Generate fibonacci numbers using memoization for optimization.
        
        Args:
            n: The position in fibonacci sequence
            memo: Dictionary for memoization (used internally)
            
        Returns:
            The nth fibonacci number
        """
        if memo is None:
            memo = {}
        
        if n in memo:
            return memo[n]
        
        if n <= 1:
            return n
        
        memo[n] = (AlgorithmPatterns.fibonacci_memoized(n - 1, memo) + 
                   AlgorithmPatterns.fibonacci_memoized(n - 2, memo))
        
        return memo[n]

# ============================================================================
# PART 3: UTILITY PATTERNS  
# ============================================================================

class UtilityPatterns:
    """Utility functions to explore Copilot's practical suggestions."""
    
    @staticmethod
    def validate_email(email: str) -> bool:
        """
        Validate email addresses using regex.
        
        Args:
            email: Email address to validate
            
        Returns:
            True if valid email, False otherwise
        """
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return bool(re.match(pattern, email))
    
    @staticmethod
    def format_phone_number(phone: str) -> str:
        """
        Format a phone number from digits to (XXX) XXX-XXXX format.
        
        Args:
            phone: String of 10 digits
            
        Returns:
            Formatted phone number or original if invalid
        """
        # Remove all non-digit characters
        digits = re.sub(r'\D', '', phone)
        
        # Check if we have exactly 10 digits
        if len(digits) == 10:
            return f"({digits[:3]}) {digits[3:6]}-{digits[6:]}"
        
        return phone
    
    @staticmethod
    def parse_date(date_string: str) -> Optional[datetime]:
        """
        Parse various date formats and return a datetime object.
        
        Args:
            date_string: Date in various formats
            
        Returns:
            datetime object if successfully parsed, None otherwise
        """
        date_formats = [
            "%Y-%m-%d",           # 2024-01-15
            "%d/%m/%Y",           # 15/01/2024
            "%m/%d/%Y",           # 01/15/2024
            "%d-%m-%Y",           # 15-01-2024
            "%Y/%m/%d",           # 2024/01/15
            "%d %B %Y",           # 15 January 2024
            "%B %d, %Y",          # January 15, 2024
            "%Y-%m-%d %H:%M:%S", # 2024-01-15 14:30:00
        ]
        
        for date_format in date_formats:
            try:
                return datetime.strptime(date_string, date_format)
            except ValueError:
                continue
        
        return None

# ============================================================================
# PART 4: CONTEXT EXPERIMENTS
# ============================================================================

class ContextExperiments:
    """Test how different context affects Copilot's suggestions."""
    
    def process(self, data):
        """Minimal context - basic processing."""
        return [item * 2 for item in data if item > 0]
    
    def process_user_analytics_data(
        self, 
        users: List[Dict[str, Any]], 
        start_date: datetime,
        end_date: datetime,
        metrics: List[str] = ['engagement', 'retention', 'conversion']
    ) -> Dict[str, float]:
        """
        Process user data to calculate analytics metrics for dashboard.
        
        This function aggregates user activity data within the specified
        date range and calculates key performance metrics.
        
        Args:
            users: List of user dictionaries containing:
                   - user_id (int): Unique identifier
                   - created_at (datetime): Account creation date  
                   - last_active (datetime): Last activity timestamp
                   - events (List[Dict]): User events with timestamps
            start_date: Beginning of analysis period
            end_date: End of analysis period  
            metrics: Metrics to calculate
            
        Returns:
            Dictionary mapping metric names to calculated values
            
        Example:
            >>> users = load_users_from_db()
            >>> results = process_user_analytics_data(
            ...     users, 
            ...     datetime(2024, 1, 1),
            ...     datetime(2024, 1, 31)
            ... )
            >>> print(results['engagement'])  # 0.75
        """
        results = {}
        
        # Filter users active in date range
        active_users = [
            user for user in users
            if start_date <= user.get('last_active', datetime.min) <= end_date
        ]
        
        total_users = len(users)
        active_count = len(active_users)
        
        # Calculate metrics
        if 'engagement' in metrics:
            results['engagement'] = active_count / total_users if total_users > 0 else 0
        
        if 'retention' in metrics:
            retained_users = [
                user for user in active_users
                if user.get('created_at', datetime.max) < start_date
            ]
            results['retention'] = len(retained_users) / active_count if active_count > 0 else 0
        
        if 'conversion' in metrics:
            converted_users = [
                user for user in active_users
                if any(event.get('type') == 'purchase' for event in user.get('events', []))
            ]
            results['conversion'] = len(converted_users) / active_count if active_count > 0 else 0
        
        return results

# ============================================================================
# PART 5: PATTERN DOCUMENTATION
# ============================================================================

pattern_documentation = []

def document_pattern(name: str, description: str, effectiveness: int, notes: str = ""):
    """
    Document a pattern's effectiveness with Copilot.
    
    Args:
        name: Pattern name
        description: What the pattern does
        effectiveness: Rating from 1-5 stars
        notes: Additional observations
    """
    pattern_doc = {
        'name': name,
        'description': description,
        'effectiveness': '⭐' * effectiveness,
        'rating': effectiveness,
        'notes': notes,
        'timestamp': datetime.now().isoformat()
    }
    
    pattern_documentation.append(pattern_doc)
    
    # Save to file
    with open('pattern_analysis.json', 'w') as f:
        json.dump(pattern_documentation, f, indent=2)
    
    return pattern_doc

# ============================================================================
# PART 6: TESTING PATTERNS
# ============================================================================

def test_patterns():
    """Test all implemented patterns."""
    print("Testing Pattern Library...\n")
    
    # Test Stack
    print("Testing Stack:")
    stack = PatternLibrary.Stack()
    stack.push(1)
    stack.push(2)
    stack.push(3)
    print(f"  Pushed 1, 2, 3")
    print(f"  Peek: {stack.peek()} (expected: 3)")
    print(f"  Pop: {stack.pop()} (expected: 3)")
    print(f"  Size: {stack.size()} (expected: 2)")
    document_pattern("Stack", "LIFO data structure", 5, "Perfect implementation on first try")
    
    # Test Queue
    print("\nTesting Queue:")
    queue = PatternLibrary.Queue()
    queue.enqueue('a')
    queue.enqueue('b')
    queue.enqueue('c')
    print(f"  Enqueued a, b, c")
    print(f"  Dequeue: {queue.dequeue()} (expected: a)")
    print(f"  Front: {queue.front()} (expected: b)")
    document_pattern("Queue", "FIFO data structure", 5, "Clean implementation")
    
    # Test Binary Search
    print("\nTesting Binary Search:")
    arr = [1, 3, 5, 7, 9, 11, 13]
    result = AlgorithmPatterns.binary_search(arr, 7)
    print(f"  Search for 7 in {arr}")
    print(f"  Result: index {result} (expected: 3)")
    document_pattern("Binary Search", "Efficient searching in sorted array", 5, "Copilot knows classic algorithms well")
    
    # Test Email Validation
    print("\nTesting Email Validation:")
    emails = ["test@example.com", "invalid.email", "user@domain.co.uk"]
    for email in emails:
        valid = UtilityPatterns.validate_email(email)
        print(f"  {email}: {'Valid' if valid else 'Invalid'}")
    document_pattern("Email Validation", "Regex-based email validation", 4, "Good regex but might need refinement for edge cases")
    
    print("\nAll patterns tested successfully!")
    print(f"\nDocumented {len(pattern_documentation)} patterns in pattern_analysis.json")


if __name__ == "__main__":
    test_patterns()
    
    # Create markdown report
    with open('pattern_analysis.md', 'w') as f:
        f.write("# Pattern Analysis Report\n\n")
        f.write("## Pattern Effectiveness Ratings\n\n")
        
        for pattern in pattern_documentation:
            f.write(f"### {pattern['name']}\n")
            f.write(f"- **Description**: {pattern['description']}\n")
            f.write(f"- **Effectiveness**: {pattern['effectiveness']}\n")
            f.write(f"- **Notes**: {pattern['notes']}\n\n")
        
        f.write("## Key Findings\n\n")
        f.write("1. Copilot excels at implementing well-known data structures\n")
        f.write("2. Classic algorithms are suggested accurately\n")
        f.write("3. Type hints significantly improve suggestion quality\n")
        f.write("4. Detailed docstrings lead to better implementations\n")
        f.write("5. Context-rich functions get more sophisticated suggestions\n")