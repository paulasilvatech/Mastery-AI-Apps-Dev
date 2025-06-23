#!/usr/bin/env python3
"""
Unit tests for the utility functions library.
"""

import pytest
import sys
from pathlib import Path

# Add parent directory to path to import utils
sys.path.insert(0, str(Path(__file__).parent.parent / "solution"))

from utils import (
    validate_email,
    format_phone_number,
    parse_url,
    generate_password,
    calculate_file_checksums,
    convert_temperature,
    validate_credit_card,
    parse_and_format_date
)

class TestEmailValidation:
    """Test email validation function."""
    
    def test_valid_emails(self):
        """Test valid email addresses."""
        valid_emails = [
            "test@example.com",
            "user.name@domain.co.uk",
            "first+last@company.org",
            "123@test.com",
            "a@b.co"
        ]
        for email in valid_emails:
            assert validate_email(email), f"{email} should be valid"
    
    def test_invalid_emails(self):
        """Test invalid email addresses."""
        invalid_emails = [
            "invalid.email",
            "@example.com",
            "user@",
            "user name@example.com",
            "user@example",
            ""
        ]
        for email in invalid_emails:
            assert not validate_email(email), f"{email} should be invalid"

class TestPhoneFormatting:
    """Test phone number formatting."""
    
    def test_valid_phones(self):
        """Test formatting of valid phone numbers."""
        test_cases = [
            ("5551234567", "(555) 123-4567"),
            ("555-123-4567", "(555) 123-4567"),
            ("(555) 123-4567", "(555) 123-4567"),
            ("1-555-123-4567", "(555) 123-4567"),
            ("15551234567", "(555) 123-4567")
        ]
        for input_phone, expected in test_cases:
            assert format_phone_number(input_phone) == expected
    
    def test_invalid_phones(self):
        """Test invalid phone numbers return None."""
        invalid_phones = ["123", "555-CALL-NOW", "123456789", ""]
        for phone in invalid_phones:
            assert format_phone_number(phone) is None

class TestURLParsing:
    """Test URL parsing function."""
    
    def test_complete_url(self):
        """Test parsing a complete URL."""
        url = "https://example.com/path/to/page?param1=value1&param2=value2#section"
        result = parse_url(url)
        
        assert result["protocol"] == "https"
        assert result["domain"] == "example.com"
        assert result["path"] == "/path/to/page"
        assert "param1" in result["query_params"]
        assert result["fragment"] == "section"
    
    def test_simple_url(self):
        """Test parsing a simple URL."""
        result = parse_url("http://example.com")
        assert result["protocol"] == "http"
        assert result["domain"] == "example.com"

class TestPasswordGeneration:
    """Test password generation."""
    
    def test_password_length(self):
        """Test generated password has correct length."""
        for length in [8, 12, 16, 20]:
            password = generate_password(length=length)
            assert len(password) == length
    
    def test_password_complexity(self):
        """Test password contains required character types."""
        password = generate_password(
            length=20,
            use_uppercase=True,
            use_lowercase=True,
            use_numbers=True,
            use_symbols=True
        )
        
        assert any(c.isupper() for c in password)
        assert any(c.islower() for c in password)
        assert any(c.isdigit() for c in password)
        assert any(not c.isalnum() for c in password)
    
    def test_password_minimum_length(self):
        """Test minimum password length requirement."""
        with pytest.raises(ValueError):
            generate_password(length=3)

class TestTemperatureConversion:
    """Test temperature conversion."""
    
    def test_celsius_to_fahrenheit(self):
        """Test Celsius to Fahrenheit conversion."""
        assert convert_temperature(0, 'C', 'F') == 32
        assert convert_temperature(100, 'C', 'F') == 212
        assert round(convert_temperature(37, 'C', 'F'), 1) == 98.6
    
    def test_fahrenheit_to_celsius(self):
        """Test Fahrenheit to Celsius conversion."""
        assert convert_temperature(32, 'F', 'C') == 0
        assert convert_temperature(212, 'F', 'C') == 100
    
    def test_kelvin_conversion(self):
        """Test Kelvin conversions."""
        assert convert_temperature(0, 'C', 'K') == 273.15
        assert convert_temperature(273.15, 'K', 'C') == 0
    
    def test_invalid_units(self):
        """Test invalid unit raises ValueError."""
        with pytest.raises(ValueError):
            convert_temperature(100, 'X', 'C')

class TestCreditCardValidation:
    """Test credit card validation."""
    
    def test_valid_cards(self):
        """Test valid credit card numbers."""
        valid_cards = [
            "4111111111111111",  # Visa test number
            "5500000000000004",  # Mastercard test number
            "340000000000009",   # Amex test number
            "4111-1111-1111-1111",  # With dashes
            "4111 1111 1111 1111"   # With spaces
        ]
        for card in valid_cards:
            assert validate_credit_card(card), f"{card} should be valid"
    
    def test_invalid_cards(self):
        """Test invalid credit card numbers."""
        invalid_cards = [
            "1234567890123456",
            "0000000000000000",
            "411111111111111",  # Too short
            "41111111111111112", # Too long
            "abcd-efgh-ijkl-mnop"
        ]
        for card in invalid_cards:
            assert not validate_credit_card(card), f"{card} should be invalid"

class TestDateParsing:
    """Test date parsing and formatting."""
    
    def test_common_formats(self):
        """Test parsing common date formats."""
        test_cases = [
            ("2023-12-25", "%Y-%m-%d", "2023-12-25"),
            ("12/25/2023", "%Y-%m-%d", "2023-12-25"),
            ("25/12/2023", "%Y-%m-%d", "2023-12-25"),
            ("December 25, 2023", "%Y-%m-%d", "2023-12-25"),
            ("25 Dec 2023", "%Y-%m-%d", "2023-12-25")
        ]
        
        for date_str, output_fmt, expected in test_cases:
            result = parse_and_format_date(date_str, output_format=output_fmt)
            assert result == expected, f"Failed to parse {date_str}"
    
    def test_custom_format(self):
        """Test parsing with custom format."""
        result = parse_and_format_date(
            "2023-12-25",
            input_format="%Y-%m-%d",
            output_format="%B %d, %Y"
        )
        assert result == "December 25, 2023"
    
    def test_invalid_date(self):
        """Test invalid date returns None."""
        assert parse_and_format_date("not a date") is None
        assert parse_and_format_date("99/99/9999") is None

if __name__ == "__main__":
    pytest.main(["-v", __file__])
