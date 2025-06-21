"""
Utility Functions Library - Complete Solution
A collection of helpful functions for common programming tasks.
"""

import re
import json
import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Optional, Dict, Any, Union
from collections import Counter

# Configure logging
logging.basicConfig(level=logging.INFO)


def validate_email(email: str) -> bool:
    """
    Validate an email address.
    
    Args:
        email: The email address to validate.
        
    Returns:
        True if valid, False otherwise.
    """
    if not email or '@' not in email:
        return False
    
    parts = email.split('@')
    if len(parts) != 2:
        return False
    
    local, domain = parts
    if not local or not domain:
        return False
    
    if '.' not in domain:
        return False
    
    # Basic regex validation
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None


def is_palindrome(s: str) -> bool:
    """
    Check if a string is a palindrome.
    
    Args:
        s: The string to check.
        
    Returns:
        True if palindrome, False otherwise.
    """
    # Remove non-alphanumeric characters and convert to lowercase
    cleaned = ''.join(c.lower() for c in s if c.isalnum())
    
    # Empty string is considered a palindrome
    if not cleaned:
        return True
    
    # Check if string equals its reverse
    return cleaned == cleaned[::-1]


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


def calculate_compound_interest(
    principal: float, 
    rate: float, 
    time: float, 
    n: int = 12
) -> tuple[float, float]:
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
            sentences = [s.strip() for s in self.text.split('.') if s.strip()]
            
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
        words = self.text.lower().split()
        # Filter out stop words and non-alphabetic words
        filtered_words = [
            w for w in words 
            if w.isalpha() and w not in self.stop_words
        ]
        
        word_counts = Counter(filtered_words)
        return word_counts.most_common(n)


# Additional utility functions

def format_currency(amount: float, currency: str = 'USD') -> str:
    """
    Format a number as currency.
    
    Args:
        amount: The amount to format.
        currency: Currency code (default: USD).
        
    Returns:
        Formatted currency string.
    """
    symbols = {
        'USD': '$',
        'EUR': '€',
        'GBP': '£',
        'JPY': '¥'
    }
    
    symbol = symbols.get(currency, currency + ' ')
    return f"{symbol}{amount:,.2f}"


def generate_password(length: int = 12, include_symbols: bool = True) -> str:
    """
    Generate a secure random password.
    
    Args:
        length: Password length (default: 12).
        include_symbols: Include special characters (default: True).
        
    Returns:
        Generated password.
    """
    import string
    import secrets
    
    # Character sets
    lowercase = string.ascii_lowercase
    uppercase = string.ascii_uppercase
    digits = string.digits
    symbols = string.punctuation if include_symbols else ''
    
    # Combine all characters
    all_chars = lowercase + uppercase + digits + symbols
    
    # Ensure at least one character from each set
    password = [
        secrets.choice(lowercase),
        secrets.choice(uppercase),
        secrets.choice(digits)
    ]
    
    if include_symbols:
        password.append(secrets.choice(symbols))
    
    # Fill the rest
    for _ in range(length - len(password)):
        password.append(secrets.choice(all_chars))
    
    # Shuffle and return
    secrets.SystemRandom().shuffle(password)
    return ''.join(password)


def parse_csv_line(line: str, delimiter: str = ',') -> List[str]:
    """
    Parse a CSV line handling quoted values.
    
    Args:
        line: CSV line to parse.
        delimiter: Field delimiter (default: comma).
        
    Returns:
        List of field values.
    """
    fields = []
    current_field = ''
    in_quotes = False
    
    for char in line:
        if char == '"':
            in_quotes = not in_quotes
        elif char == delimiter and not in_quotes:
            fields.append(current_field.strip())
            current_field = ''
        else:
            current_field += char
    
    # Add the last field
    if current_field:
        fields.append(current_field.strip())
    
    return fields