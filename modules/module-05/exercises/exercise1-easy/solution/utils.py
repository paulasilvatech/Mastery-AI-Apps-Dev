"""
Utility Functions Library
A collection of helpful functions for common programming tasks.
"""

import re
import random
import string
import hashlib
from pathlib import Path
from datetime import datetime
from typing import Optional, Dict, Union
from urllib.parse import urlparse, parse_qs

def validate_email(email: str) -> bool:
    """
    Validate email addresses using regex pattern.
    
    Args:
        email: Email address to validate
        
    Returns:
        True if valid email format, False otherwise
    """
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, str(email).strip()))

def format_phone_number(phone: str) -> Optional[str]:
    """
    Format phone numbers to (XXX) XXX-XXXX format.
    
    Args:
        phone: Phone number in various formats
        
    Returns:
        Formatted phone number or None if invalid
    """
    # Remove all non-digits
    digits = re.sub(r'\D', '', phone)
    
    # Check if we have exactly 10 digits
    if len(digits) == 10:
        return f"({digits[:3]}) {digits[3:6]}-{digits[6:]}"
    elif len(digits) == 11 and digits[0] == '1':
        # Handle US numbers with country code
        return f"({digits[1:4]}) {digits[4:7]}-{digits[7:]}"
    else:
        return None

def parse_url(url: str) -> Dict[str, Union[str, Dict]]:
    """
    Parse URL and extract components.
    
    Args:
        url: URL string to parse
        
    Returns:
        Dictionary with protocol, domain, path, and query parameters
    """
    try:
        parsed = urlparse(url)
        return {
            'protocol': parsed.scheme,
            'domain': parsed.netloc,
            'path': parsed.path,
            'query_params': parse_qs(parsed.query),
            'fragment': parsed.fragment
        }
    except Exception as e:
        return {
            'error': str(e),
            'protocol': '',
            'domain': '',
            'path': '',
            'query_params': {}
        }

def generate_password(
    length: int = 12,
    use_uppercase: bool = True,
    use_lowercase: bool = True,
    use_numbers: bool = True,
    use_symbols: bool = True
) -> str:
    """
    Generate a secure random password.
    
    Args:
        length: Password length (minimum 4)
        use_uppercase: Include uppercase letters
        use_lowercase: Include lowercase letters
        use_numbers: Include numbers
        use_symbols: Include symbols
        
    Returns:
        Generated password string
        
    Raises:
        ValueError: If length < 4 or no character types selected
    """
    if length < 4:
        raise ValueError("Password length must be at least 4")
    
    chars = ""
    required_chars = []
    
    if use_uppercase:
        chars += string.ascii_uppercase
        required_chars.append(random.choice(string.ascii_uppercase))
    if use_lowercase:
        chars += string.ascii_lowercase
        required_chars.append(random.choice(string.ascii_lowercase))
    if use_numbers:
        chars += string.digits
        required_chars.append(random.choice(string.digits))
    if use_symbols:
        chars += string.punctuation
        required_chars.append(random.choice(string.punctuation))
    
    if not chars:
        raise ValueError("At least one character type must be selected")
    
    # Fill remaining length with random characters
    remaining_length = length - len(required_chars)
    password_chars = required_chars + [random.choice(chars) for _ in range(remaining_length)]
    
    # Shuffle to avoid predictable patterns
    random.shuffle(password_chars)
    
    return ''.join(password_chars)

def calculate_file_checksums(filepath: Union[str, Path]) -> Dict[str, str]:
    """
    Calculate MD5 and SHA256 checksums for a file.
    
    Args:
        filepath: Path to the file
        
    Returns:
        Dictionary with 'md5' and 'sha256' hashes
        
    Raises:
        FileNotFoundError: If file doesn't exist
        IOError: If file can't be read
    """
    filepath = Path(filepath)
    
    if not filepath.exists():
        raise FileNotFoundError(f"File not found: {filepath}")
    
    md5_hash = hashlib.md5()
    sha256_hash = hashlib.sha256()
    
    try:
        with open(filepath, 'rb') as f:
            for chunk in iter(lambda: f.read(4096), b''):
                md5_hash.update(chunk)
                sha256_hash.update(chunk)
        
        return {
            'md5': md5_hash.hexdigest(),
            'sha256': sha256_hash.hexdigest()
        }
    except Exception as e:
        raise IOError(f"Error reading file: {e}")

def convert_temperature(value: float, from_unit: str, to_unit: str) -> float:
    """
    Convert between temperature units.
    
    Args:
        value: Temperature value
        from_unit: Source unit ('C', 'F', or 'K')
        to_unit: Target unit ('C', 'F', or 'K')
        
    Returns:
        Converted temperature value
        
    Raises:
        ValueError: If invalid unit specified
    """
    units = ['C', 'F', 'K']
    from_unit = from_unit.upper()
    to_unit = to_unit.upper()
    
    if from_unit not in units or to_unit not in units:
        raise ValueError(f"Invalid unit. Use one of: {units}")
    
    # Convert to Celsius first
    if from_unit == 'F':
        celsius = (value - 32) * 5/9
    elif from_unit == 'K':
        celsius = value - 273.15
    else:
        celsius = value
    
    # Convert from Celsius to target unit
    if to_unit == 'F':
        return celsius * 9/5 + 32
    elif to_unit == 'K':
        return celsius + 273.15
    else:
        return celsius

def validate_credit_card(card_number: str) -> bool:
    """
    Validate credit card number using Luhn algorithm.
    
    Args:
        card_number: Credit card number (can contain spaces/dashes)
        
    Returns:
        True if valid, False otherwise
    """
    # Remove spaces and dashes
    card_number = re.sub(r'[\s-]', '', str(card_number))
    
    # Check if all characters are digits
    if not card_number.isdigit():
        return False
    
    # Convert to list of integers
    digits = [int(d) for d in card_number]
    
    # Apply Luhn algorithm
    checksum = 0
    for i, digit in enumerate(reversed(digits)):
        if i % 2 == 1:
            digit *= 2
            if digit > 9:
                digit -= 9
        checksum += digit
    
    return checksum % 10 == 0

def parse_and_format_date(
    date_string: str,
    input_format: str = None,
    output_format: str = '%Y-%m-%d'
) -> Optional[str]:
    """
    Parse various date formats and convert to specified format.
    
    Args:
        date_string: Date string to parse
        input_format: Expected input format (None for auto-detect)
        output_format: Desired output format
        
    Returns:
        Formatted date string or None if parsing fails
    """
    if input_format:
        try:
            dt = datetime.strptime(date_string, input_format)
            return dt.strftime(output_format)
        except ValueError:
            return None
    
    # Try common formats
    common_formats = [
        '%Y-%m-%d',
        '%d/%m/%Y',
        '%m/%d/%Y',
        '%Y/%m/%d',
        '%d-%m-%Y',
        '%m-%d-%Y',
        '%B %d, %Y',
        '%b %d, %Y',
        '%d %B %Y',
        '%d %b %Y'
    ]
    
    for fmt in common_formats:
        try:
            dt = datetime.strptime(date_string.strip(), fmt)
            return dt.strftime(output_format)
        except ValueError:
            continue
    
    return None

if __name__ == "__main__":
    # Test the functions
    print("Utility Functions Library - Testing\n")
    
    # Test email validation
    print("Email Validation:")
    print(f"test@example.com: {validate_email('test@example.com')}")
    print(f"invalid.email: {validate_email('invalid.email')}")
    
    # Test phone formatting
    print("\nPhone Formatting:")
    print(f"555-123-4567: {format_phone_number('555-123-4567')}")
    print(f"5551234567: {format_phone_number('5551234567')}")
    
    # Test URL parsing
    print("\nURL Parsing:")
    url_info = parse_url('https://example.com/path?query=value&foo=bar#section')
    print(f"URL components: {url_info}")
    
    # Test password generation
    print("\nPassword Generation:")
    print(f"Generated password: {generate_password(16, use_symbols=True)}")
    
    # Test temperature conversion
    print("\nTemperature Conversion:")
    print(f"100°C to °F: {convert_temperature(100, 'C', 'F')}")
    print(f"32°F to °C: {convert_temperature(32, 'F', 'C')}")
    
    # Test credit card validation
    print("\nCredit Card Validation:")
    print(f"4111111111111111: {validate_credit_card('4111111111111111')}")
    print(f"1234567890123456: {validate_credit_card('1234567890123456')}")
    
    # Test date parsing
    print("\nDate Parsing:")
    print(f"2023-12-25: {parse_and_format_date('2023-12-25', output_format='%B %d, %Y')}")
    print(f"12/25/2023: {parse_and_format_date('12/25/2023', output_format='%Y-%m-%d')}")
