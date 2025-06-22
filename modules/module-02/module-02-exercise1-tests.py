"""
Test suite for Pattern Library Exercise
Validates all pattern implementations
"""

import pytest
import sys
from pathlib import Path
from datetime import datetime

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from starter.pattern_library import (
    PatternLibrary, 
    AlgorithmPatterns, 
    UtilityPatterns,
    ContextExperiments,
    document_pattern
)

class TestDataStructures:
    """Test data structure implementations."""
    
    def test_stack_operations(self):
        """Test Stack class functionality."""
        stack = PatternLibrary.Stack()
        
        # Test is_empty on new stack
        assert stack.is_empty() == True
        
        # Test push and size
        stack.push(10)
        stack.push(20)
        stack.push(30)
        assert stack.size() == 3
        assert stack.is_empty() == False
        
        # Test peek
        assert stack.peek() == 30
        assert stack.size() == 3  # Peek shouldn't remove item
        
        # Test pop
        assert stack.pop() == 30
        assert stack.pop() == 20
        assert stack.size() == 1
        
        # Test error on empty stack
        stack.pop()  # Remove last item
        with pytest.raises(IndexError):
            stack.pop()
    
    def test_queue_operations(self):
        """Test Queue class functionality."""
        queue = PatternLibrary.Queue()
        
        # Test is_empty on new queue
        assert queue.is_empty() == True
        
        # Test enqueue and size
        queue.enqueue('first')
        queue.enqueue('second')
        queue.enqueue('third')
        assert queue.size() == 3
        
        # Test dequeue (FIFO order)
        assert queue.dequeue() == 'first'
        assert queue.dequeue() == 'second'
        assert queue.size() == 1
        
        # Test error on empty queue
        queue.dequeue()  # Remove last item
        with pytest.raises(IndexError):
            queue.dequeue()
    
    def test_linked_list_node(self):
        """Test Node class for linked list."""
        # Create nodes
        node1 = PatternLibrary.Node(10)
        node2 = PatternLibrary.Node(20)
        node3 = PatternLibrary.Node(30)
        
        # Link nodes
        node1.next = node2
        node2.next = node3
        
        # Test traversal
        current = node1
        values = []
        while current:
            values.append(current.data)
            current = current.next
        
        assert values == [10, 20, 30]

class TestAlgorithms:
    """Test algorithm implementations."""
    
    def test_binary_search(self):
        """Test binary search implementation."""
        # Test with found elements
        arr = [1, 3, 5, 7, 9, 11, 13, 15]
        assert AlgorithmPatterns.binary_search(arr, 7) == 3
        assert AlgorithmPatterns.binary_search(arr, 1) == 0
        assert AlgorithmPatterns.binary_search(arr, 15) == 7
        
        # Test with not found elements
        assert AlgorithmPatterns.binary_search(arr, 4) == -1
        assert AlgorithmPatterns.binary_search(arr, 20) == -1
        
        # Test edge cases
        assert AlgorithmPatterns.binary_search([], 5) == -1
        assert AlgorithmPatterns.binary_search([5], 5) == 0
        assert AlgorithmPatterns.binary_search([5], 3) == -1
    
    def test_bubble_sort(self):
        """Test bubble sort implementation."""
        # Test normal case
        arr1 = [64, 34, 25, 12, 22, 11, 90]
        AlgorithmPatterns.bubble_sort(arr1)
        assert arr1 == [11, 12, 22, 25, 34, 64, 90]
        
        # Test already sorted
        arr2 = [1, 2, 3, 4, 5]
        AlgorithmPatterns.bubble_sort(arr2)
        assert arr2 == [1, 2, 3, 4, 5]
        
        # Test reverse sorted
        arr3 = [5, 4, 3, 2, 1]
        AlgorithmPatterns.bubble_sort(arr3)
        assert arr3 == [1, 2, 3, 4, 5]
        
        # Test edge cases
        arr4 = []
        AlgorithmPatterns.bubble_sort(arr4)
        assert arr4 == []
        
        arr5 = [1]
        AlgorithmPatterns.bubble_sort(arr5)
        assert arr5 == [1]
    
    def test_fibonacci_memoized(self):
        """Test memoized fibonacci implementation."""
        # Test known fibonacci numbers
        assert AlgorithmPatterns.fibonacci_memoized(0) == 0
        assert AlgorithmPatterns.fibonacci_memoized(1) == 1
        assert AlgorithmPatterns.fibonacci_memoized(2) == 1
        assert AlgorithmPatterns.fibonacci_memoized(3) == 2
        assert AlgorithmPatterns.fibonacci_memoized(4) == 3
        assert AlgorithmPatterns.fibonacci_memoized(5) == 5
        assert AlgorithmPatterns.fibonacci_memoized(10) == 55
        
        # Test larger number (memoization should make this fast)
        assert AlgorithmPatterns.fibonacci_memoized(30) == 832040

class TestUtilities:
    """Test utility function implementations."""
    
    def test_email_validation(self):
        """Test email validation function."""
        # Valid emails
        assert UtilityPatterns.validate_email("user@example.com") == True
        assert UtilityPatterns.validate_email("test.user@domain.co.uk") == True
        assert UtilityPatterns.validate_email("name+tag@company.org") == True
        
        # Invalid emails
        assert UtilityPatterns.validate_email("invalid.email") == False
        assert UtilityPatterns.validate_email("@example.com") == False
        assert UtilityPatterns.validate_email("user@") == False
        assert UtilityPatterns.validate_email("user @example.com") == False
    
    def test_phone_formatting(self):
        """Test phone number formatting."""
        # Test valid 10-digit numbers
        assert UtilityPatterns.format_phone_number("1234567890") == "(123) 456-7890"
        assert UtilityPatterns.format_phone_number("123-456-7890") == "(123) 456-7890"
        assert UtilityPatterns.format_phone_number("123.456.7890") == "(123) 456-7890"
        assert UtilityPatterns.format_phone_number("(123)456-7890") == "(123) 456-7890"
        
        # Test invalid numbers (should return original)
        assert UtilityPatterns.format_phone_number("12345") == "12345"
        assert UtilityPatterns.format_phone_number("12345678901") == "12345678901"
        assert UtilityPatterns.format_phone_number("abcdefghij") == "abcdefghij"
    
    def test_date_parsing(self):
        """Test date parsing function."""
        # Test various formats
        date1 = UtilityPatterns.parse_date("2024-01-15")
        assert date1.year == 2024 and date1.month == 1 and date1.day == 15
        
        date2 = UtilityPatterns.parse_date("15/01/2024")
        assert date2.year == 2024 and date2.month == 1 and date2.day == 15
        
        date3 = UtilityPatterns.parse_date("January 15, 2024")
        assert date3.year == 2024 and date3.month == 1 and date3.day == 15
        
        # Test invalid format
        assert UtilityPatterns.parse_date("invalid date") == None

class TestContextExperiments:
    """Test context experiment implementations."""
    
    def test_minimal_context_function(self):
        """Test the minimal context process function."""
        context = ContextExperiments()
        
        # Test basic processing
        result = context.process([1, -2, 3, -4, 5])
        assert result == [2, 6, 10]  # Only positive numbers, doubled
    
    def test_rich_context_function(self):
        """Test the rich context analytics function."""
        context = ContextExperiments()
        
        # Create test data
        users = [
            {
                'user_id': 1,
                'created_at': datetime(2023, 12, 1),
                'last_active': datetime(2024, 1, 15),
                'events': [{'type': 'login'}, {'type': 'purchase'}]
            },
            {
                'user_id': 2,
                'created_at': datetime(2024, 1, 5),
                'last_active': datetime(2024, 1, 20),
                'events': [{'type': 'login'}]
            },
            {
                'user_id': 3,
                'created_at': datetime(2023, 11, 1),
                'last_active': datetime(2023, 12, 31),
                'events': []
            }
        ]
        
        # Test analytics calculation
        results = context.process_user_analytics_data(
            users,
            datetime(2024, 1, 1),
            datetime(2024, 1, 31)
        )
        
        assert 'engagement' in results
        assert 'retention' in results
        assert 'conversion' in results
        assert 0 <= results['engagement'] <= 1
        assert 0 <= results['retention'] <= 1
        assert 0 <= results['conversion'] <= 1

class TestDocumentation:
    """Test pattern documentation functionality."""
    
    def test_document_pattern(self):
        """Test pattern documentation function."""
        # Clear any existing documentation
        global pattern_documentation
        pattern_documentation = []
        
        # Document a pattern
        doc = document_pattern(
            "Test Pattern",
            "A test pattern for validation",
            4,
            "Works well with clear context"
        )
        
        assert doc['name'] == "Test Pattern"
        assert doc['rating'] == 4
        assert doc['effectiveness'] == "⭐⭐⭐⭐"
        assert 'timestamp' in doc
        
        # Check if saved to list
        assert len(pattern_documentation) == 1
        
        # Check if file was created
        assert Path('pattern_analysis.json').exists()

# Run tests if executed directly
if __name__ == "__main__":
    pytest.main([__file__, "-v"])