# Exercise 1: First AI Code (⭐ Easy) - Part 2

## 🚀 Part 2: Writing More Complex Functions

Now that you understand the basics, let's create more sophisticated functions and explore advanced Copilot features.

### Step 7: String Manipulation Functions

Let's build a set of string utilities. Add these to your `utils.py` file:

**🤖 Copilot Prompt Suggestion #3:**
```python
# Create a function that converts text to title case
# but keeps certain words lowercase (a, an, the, in, on, at, to, for)
# unless they are the first or last word
# Example: "the quick brown fox" -> "The Quick Brown Fox"
#          "a tale of two cities" -> "A Tale of Two Cities"
```

After typing the comment, start the function:
```python
def smart_title_case(text: str) -> str:
```

**Expected Output:**
```python
def smart_title_case(text: str) -> str:
    """
    Convert text to title case with smart word handling.
    
    Args:
        text: The text to convert.
        
    Returns:
        Text in smart title case.
    """
    if not text:
        return text
    
    # Words to keep lowercase unless first/last
    lowercase_words = {'a', 'an', 'the', 'in', 'on', 'at', 'to', 'for', 
                      'of', 'with', 'by', 'and', 'or', 'but'}
    
    words = text.split()
    result = []
    
    for i, word in enumerate(words):
        # First or last word is always capitalized
        if i == 0 or i == len(words) - 1:
            result.append(word.capitalize())
        # Check if word should be lowercase
        elif word.lower() in lowercase_words:
            result.append(word.lower())
        else:
            result.append(word.capitalize())
    
    return ' '.join(result)
```

### Step 8: Data Validation Functions

Now let's create more validation utilities:

**🤖 Copilot Prompt Suggestion #4:**
```python
# Create a function that validates a phone number
# Accept formats: (123) 456-7890, 123-456-7890, 123.456.7890, 1234567890
# Return the cleaned number as 10 digits or None if invalid
# Must be exactly 10 digits when cleaned
```

Start typing:
```python
def validate_phone(phone: str) -> Optional[str]:
```

Note: You'll need to import Optional:
```python
from typing import Optional
```

**Expected Output:**
```python
def validate_phone(phone: str) -> Optional[str]:
    """
    Validate and clean a phone number.
    
    Args:
        phone: The phone number to validate.
        
    Returns:
        Cleaned 10-digit phone number or None if invalid.
    """
    if not phone:
        return None
    
    # Remove all non-digit characters
    cleaned = ''.join(c for c in phone if c.isdigit())
    
    # Check if exactly 10 digits
    if len(cleaned) == 10:
        return cleaned
    
    # Check if 11 digits starting with 1 (country code)
    if len(cleaned) == 11 and cleaned[0] == '1':
        return cleaned[1:]
    
    return None
```

### Step 9: Mathematical Calculations

Let's create some math utilities with Copilot:

**🤖 Copilot Prompt Suggestion #5:**
```python
# Create a function that calculates compound interest
# Parameters: principal, rate (as percentage), time (years), compounds per year
# Formula: A = P(1 + r/n)^(nt)
# Return both the final amount and the interest earned
# Round to 2 decimal places
```

Start the function:
```python
def calculate_compound_interest(principal: float, rate: float, time: float, n: int = 12) -> tuple[float, float]:
```

**Expected Output:**
```python
def calculate_compound_interest(principal: float, rate: float, time: float, n: int = 12) -> tuple[float, float]:
    """
    Calculate compound interest.
    
    Args:
        principal: Initial amount.
        rate: Annual interest rate as percentage (e.g., 5 for 5%).
        time: Time period in years.
        n: Number of times interest compounds per year (default: 12).
        
    Returns:
        Tuple of (final_amount, interest_earned).
    """
    # Convert percentage to decimal
    r = rate / 100
    
    # Calculate final amount using compound interest formula
    final_amount = principal * (1 + r/n) ** (n * time)
    
    # Calculate interest earned
    interest_earned = final_amount - principal
    
    # Round to 2 decimal places
    return round(final_amount, 2), round(interest_earned, 2)
```

### Step 10: Date and Time Utilities

Let's add some datetime helpers:

**🤖 Copilot Prompt Suggestion #6:**
```python
# Create a function that calculates age from birthdate
# Input: birthdate as string in format YYYY-MM-DD
# Return: age in years as integer
# Handle future dates by returning 0
# Handle invalid dates by returning None
```

You'll need to import datetime:
```python
from datetime import datetime
```

Start typing:
```python
def calculate_age(birthdate_str: str) -> Optional[int]:
```

**Expected Output:**
```python
def calculate_age(birthdate_str: str) -> Optional[int]:
    """
    Calculate age from birthdate string.
    
    Args:
        birthdate_str: Birthdate in YYYY-MM-DD format.
        
    Returns:
        Age in years or None if invalid date.
    """
    try:
        # Parse the birthdate
        birthdate = datetime.strptime(birthdate_str, '%Y-%m-%d')
        
        # Get current date
        today = datetime.now()
        
        # Handle future dates
        if birthdate > today:
            return 0
        
        # Calculate age
        age = today.year - birthdate.year
        
        # Adjust if birthday hasn't occurred this year
        if (today.month, today.day) < (birthdate.month, birthdate.day):
            age -= 1
        
        return age
        
    except ValueError:
        return None
```

### Step 11: File Handling Utilities

Now let's create some file utilities:

**🤖 Copilot Prompt Suggestion #7:**
```python
# Create a function that reads a JSON file safely
# Parameters: filepath
# Return: parsed JSON data or None if error
# Handle: file not found, invalid JSON, permission errors
# Log errors but don't raise exceptions
```

Import necessary modules:
```python
import json
import logging
from pathlib import Path
```

Start the function:
```python
def read_json_safely(filepath: str) -> Optional[dict]:
```

**Expected Output:**
```python
def read_json_safely(filepath: str) -> Optional[dict]:
    """
    Safely read and parse a JSON file.
    
    Args:
        filepath: Path to the JSON file.
        
    Returns:
        Parsed JSON data or None if error.
    """
    try:
        path = Path(filepath)
        
        # Check if file exists
        if not path.exists():
            logging.warning(f"File not found: {filepath}")
            return None
        
        # Read and parse JSON
        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        return data
        
    except json.JSONDecodeError as e:
        logging.error(f"Invalid JSON in {filepath}: {e}")
        return None
    except PermissionError:
        logging.error(f"Permission denied: {filepath}")
        return None
    except Exception as e:
        logging.error(f"Error reading {filepath}: {e}")
        return None
```

### Step 12: Creating a Utility Class

Let's combine some functions into a class:

**🤖 Copilot Prompt Suggestion #8:**
```python
# Create a TextAnalyzer class that:
# - Counts words, sentences, and characters
# - Calculates average word length
# - Finds most common words (excluding stop words)
# - Calculates readability score (simple: avg words per sentence)
# Include methods: analyze(), get_statistics(), get_common_words(n=10)
```

Start the class:
```python
class TextAnalyzer:
```

**Expected Output:**
```python
class TextAnalyzer:
    """Analyze text and provide statistics."""
    
    def __init__(self, text: str):
        """
        Initialize analyzer with text.
        
        Args:
            text: The text to analyze.
        """
        self.text = text
        self.stop_words = {
            'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 
            'at', 'to', 'for', 'of', 'with', 'by', 'is', 'was',
            'are', 'were', 'been', 'be', 'have', 'has', 'had',
            'do', 'does', 'did', 'will', 'would', 'could', 'should'
        }
        self._statistics = None
        
    def analyze(self) -> dict:
        """
        Analyze the text and cache results.
        
        Returns:
            Dictionary with analysis results.
        """
        if self._statistics is None:
            words = self.text.lower().split()
            sentences = self.text.split('.')
            
            # Filter out empty sentences
            sentences = [s.strip() for s in sentences if s.strip()]
            
            # Calculate statistics
            self._statistics = {
                'word_count': len(words),
                'sentence_count': len(sentences),
                'character_count': len(self.text),
                'avg_word_length': sum(len(w) for w in words) / len(words) if words else 0,
                'avg_words_per_sentence': len(words) / len(sentences) if sentences else 0
            }
            
        return self._statistics
    
    def get_statistics(self) -> dict:
        """Get text statistics."""
        return self.analyze()
    
    def get_common_words(self, n: int = 10) -> list[tuple[str, int]]:
        """
        Get most common words excluding stop words.
        
        Args:
            n: Number of words to return.
            
        Returns:
            List of (word, count) tuples.
        """
        from collections import Counter
        
        words = self.text.lower().split()
        # Filter out stop words and non-alphabetic words
        filtered_words = [
            w for w in words 
            if w.isalpha() and w not in self.stop_words
        ]
        
        word_counts = Counter(filtered_words)
        return word_counts.most_common(n)
```

## 🎯 Part 2 Summary

You've successfully:
1. Created complex string manipulation functions
2. Built robust validation utilities
3. Implemented mathematical calculations
4. Added date/time handling
5. Created file utilities with error handling
6. Built a complete analyzer class

**Key Learnings:**
- Detailed comments produce better suggestions
- Type hints guide Copilot effectively
- Error handling improves with specific requirements
- Classes benefit from clear method descriptions

**Next**: Continue to [Part 3](part3.md) where we'll test our functions and create a complete CLI application!

---

💡 **Pro Tip**: When Copilot's suggestion is close but not perfect, accept it and then modify. This is often faster than trying to get the perfect suggestion!