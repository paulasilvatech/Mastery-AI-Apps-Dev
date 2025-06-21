"""
Tests for Utility Functions Library
Comprehensive test suite for all utility functions.
"""

import pytest
from datetime import datetime, timedelta
import json
import tempfile
from pathlib import Path

from utils import (
    validate_email, is_palindrome, smart_title_case, validate_phone,
    calculate_compound_interest, calculate_age, read_json_safely,
    TextAnalyzer, format_currency, generate_password, parse_csv_line
)


class TestEmailValidation:
    """Test email validation function."""
    
    @pytest.mark.parametrize("email,expected", [
        # Valid emails
        ("user@example.com", True),
        ("test.user@domain.co.uk", True),
        ("name+tag@example.org", True),
        ("user123@test-domain.com", True),
        ("first.last@subdomain.example.com", True),
        
        # Invalid emails
        ("no-at-sign", False),
        ("@no-local", False),
        ("no-domain@", False),
        ("double@@example.com", False),
        ("user@", False),
        ("@domain.com", False),
        ("user@domain", False),  # No TLD
        ("user @domain.com", False),  # Space in email
        ("user@domain .com", False),  # Space in domain
        
        # Edge cases
        ("", False),
        ("   ", False),
        (None, False),  # If function handles None
    ])
    def test_validate_email(self, email, expected):
        """Test email validation with various inputs."""
        # Handle None case if function doesn't
        if email is None:
            with pytest.raises(AttributeError):
                validate_email(email)
        else:
            assert validate_email(email) == expected


class TestStringFunctions:
    """Test string manipulation functions."""
    
    @pytest.mark.parametrize("text,expected", [
        # Basic palindromes
        ("racecar", True),
        ("A man a plan a canal Panama", True),
        ("race a car", False),
        
        # With punctuation and spaces
        ("Was it a car or a cat I saw?", True),
        ("Madam, I'm Adam", True),
        ("No 'x' in Nixon", False),
        
        # Edge cases
        ("", True),  # Empty string
        ("a", True),  # Single character
        ("ab", False),
        ("aa", True),
        
        # Numbers
        ("12321", True),
        ("12345", False),
    ])
    def test_is_palindrome(self, text, expected):
        """Test palindrome detection."""
        assert is_palindrome(text) == expected
    
    @pytest.mark.parametrize("text,expected", [
        # Basic cases
        ("hello world", "Hello World"),
        ("python programming", "Python Programming"),
        
        # With articles
        ("the quick brown fox", "The Quick Brown Fox"),
        ("a tale of two cities", "A Tale of Two Cities"),
        ("the lord of the rings", "The Lord of the Rings"),
        
        # Articles in middle
        ("jack and the beanstalk", "Jack and the Beanstalk"),
        ("beauty and the beast", "Beauty and the Beast"),
        ("war and peace", "War and Peace"),
        
        # Edge cases
        ("", ""),
        ("a", "A"),
        ("THE GREAT GATSBY", "The Great Gatsby"),
        ("war AND peace", "War and Peace"),
        ("   spaced   out   ", "Spaced Out"),
    ])
    def test_smart_title_case(self, text, expected):
        """Test smart title case conversion."""
        assert smart_title_case(text) == expected


class TestPhoneValidation:
    """Test phone number validation."""
    
    @pytest.mark.parametrize("phone,expected", [
        # Valid formats
        ("(123) 456-7890", "1234567890"),
        ("123-456-7890", "1234567890"),
        ("123.456.7890", "1234567890"),
        ("1234567890", "1234567890"),
        ("1-123-456-7890", "1234567890"),
        ("+1-123-456-7890", "1234567890"),
        ("1 (123) 456-7890", "1234567890"),
        
        # Invalid formats
        ("123456789", None),  # Too short
        ("12345678901", None),  # Too long (not starting with 1)
        ("21234567890", None),  # 11 digits not starting with 1
        ("123-45A-7890", None),  # Contains letter
        ("", None),
        ("phone-number", None),
        ("123-456-789", None),  # Too short
    ])
    def test_validate_phone(self, phone, expected):
        """Test phone number validation and cleaning."""
        assert validate_phone(phone) == expected


class TestMathFunctions:
    """Test mathematical calculation functions."""
    
    def test_compound_interest_basic(self):
        """Test basic compound interest calculation."""
        # $1000 at 5% for 1 year, monthly compounding
        final, interest = calculate_compound_interest(1000, 5, 1, 12)
        assert final == 1051.16
        assert interest == 51.16
    
    def test_compound_interest_no_compounding(self):
        """Test with annual compounding."""
        # $1000 at 10% for 2 years, annual compounding
        final, interest = calculate_compound_interest(1000, 10, 2, 1)
        assert final == 1210.00
        assert interest == 210.00
    
    def test_compound_interest_high_frequency(self):
        """Test with daily compounding."""
        # $5000 at 3% for 5 years, daily compounding
        final, interest = calculate_compound_interest(5000, 3, 5, 365)
        # Should be approximately $5809.17
        assert 5809 < final < 5810
        assert 809 < interest < 810


class TestDateFunctions:
    """Test date-related functions."""
    
    def test_calculate_age_valid_dates(self):
        """Test age calculation with valid dates."""
        # Calculate age for someone born 25 years ago
        today = datetime.now()
        birthdate = today.replace(year=today.year - 25)
        birthdate_str = birthdate.strftime('%Y-%m-%d')
        
        assert calculate_age(birthdate_str) == 25
    
    def test_calculate_age_birthday_not_reached(self):
        """Test age when birthday hasn't occurred this year."""
        today = datetime.now()
        # Birthday is tomorrow
        birthdate = today.replace(year=today.year - 25) + timedelta(days=1)
        birthdate_str = birthdate.strftime('%Y-%m-%d')
        
        assert calculate_age(birthdate_str) == 24
    
    def test_calculate_age_future_date(self):
        """Test with future date."""
        future_date = (datetime.now() + timedelta(days=365)).strftime('%Y-%m-%d')
        assert calculate_age(future_date) == 0
    
    def test_calculate_age_invalid_date(self):
        """Test with invalid date format."""
        assert calculate_age("not-a-date") is None
        assert calculate_age("2023-13-45") is None  # Invalid month/day


class TestFileOperations:
    """Test file operation functions."""
    
    def test_read_json_safely_valid_file(self):
        """Test reading a valid JSON file."""
        # Create temporary JSON file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump({"test": "data", "number": 42}, f)
            temp_path = f.name
        
        try:
            result = read_json_safely(temp_path)
            assert result == {"test": "data", "number": 42}
        finally:
            Path(temp_path).unlink()
    
    def test_read_json_safely_invalid_json(self):
        """Test reading invalid JSON."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            f.write("not valid json{")
            temp_path = f.name
        
        try:
            result = read_json_safely(temp_path)
            assert result is None
        finally:
            Path(temp_path).unlink()
    
    def test_read_json_safely_nonexistent_file(self):
        """Test reading non-existent file."""
        result = read_json_safely("/path/that/does/not/exist.json")
        assert result is None


class TestTextAnalyzer:
    """Test TextAnalyzer class."""
    
    @pytest.fixture
    def sample_text(self):
        """Sample text for testing."""
        return "The quick brown fox jumps over the lazy dog. This is a test sentence. Python is great."
    
    def test_text_analyzer_statistics(self, sample_text):
        """Test basic text statistics."""
        analyzer = TextAnalyzer(sample_text)
        stats = analyzer.get_statistics()
        
        assert stats['word_count'] == 17
        assert stats['sentence_count'] == 3
        assert stats['character_count'] == len(sample_text)
        assert 3.5 < stats['avg_word_length'] < 4.5
        assert 5 < stats['avg_words_per_sentence'] < 6
    
    def test_text_analyzer_common_words(self, sample_text):
        """Test common words extraction."""
        analyzer = TextAnalyzer(sample_text)
        common_words = analyzer.get_common_words(5)
        
        # Should exclude stop words
        word_list = [word for word, count in common_words]
        assert "the" not in word_list
        assert "is" not in word_list
        
        # Should include content words
        assert any(word in word_list for word in ["quick", "brown", "fox", "python", "test"])
    
    def test_text_analyzer_empty_text(self):
        """Test with empty text."""
        analyzer = TextAnalyzer("")
        stats = analyzer.get_statistics()
        
        assert stats['word_count'] == 0
        assert stats['sentence_count'] == 0
        assert stats['character_count'] == 0


class TestUtilityFunctions:
    """Test additional utility functions."""
    
    @pytest.mark.parametrize("amount,currency,expected", [
        (1234.56, 'USD', '$1,234.56'),
        (1234.5, 'USD', '$1,234.50'),
        (1234567.89, 'EUR', '€1,234,567.89'),
        (1234.56, 'GBP', '£1,234.56'),
        (1234.56, 'JPY', '¥1,234.56'),
        (1234.56, 'CAD', 'CAD 1,234.56'),  # Unknown currency
    ])
    def test_format_currency(self, amount, currency, expected):
        """Test currency formatting."""
        assert format_currency(amount, currency) == expected
    
    def test_generate_password_length(self):
        """Test password generation with specific length."""
        password = generate_password(16)
        assert len(password) == 16
    
    def test_generate_password_complexity(self):
        """Test password contains required character types."""
        password = generate_password(12, include_symbols=True)
        
        # Check for at least one of each type
        assert any(c.islower() for c in password)
        assert any(c.isupper() for c in password)
        assert any(c.isdigit() for c in password)
        assert any(not c.isalnum() for c in password)  # Special character
    
    def test_generate_password_no_symbols(self):
        """Test password generation without symbols."""
        password = generate_password(12, include_symbols=False)
        
        # Should only contain alphanumeric
        assert all(c.isalnum() for c in password)
    
    @pytest.mark.parametrize("line,expected", [
        ('a,b,c', ['a', 'b', 'c']),
        ('a,"b,c",d', ['a', 'b,c', 'd']),
        ('"hello","world"', ['hello', 'world']),
        ('1,2,3,', ['1', '2', '3', '']),
        ('', []),
        ('single', ['single']),
    ])
    def test_parse_csv_line(self, line, expected):
        """Test CSV line parsing."""
        assert parse_csv_line(line) == expected


# Performance tests (optional)
class TestPerformance:
    """Performance tests for utility functions."""
    
    def test_text_analyzer_performance(self):
        """Test TextAnalyzer with large text."""
        # Generate large text
        large_text = " ".join(["word"] * 10000)
        
        import time
        start = time.time()
        analyzer = TextAnalyzer(large_text)
        stats = analyzer.get_statistics()
        duration = time.time() - start
        
        # Should complete within reasonable time
        assert duration < 1.0  # Less than 1 second
        assert stats['word_count'] == 10000


if __name__ == '__main__':
    pytest.main([__file__, '-v'])