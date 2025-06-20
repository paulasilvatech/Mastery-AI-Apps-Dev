# Utility functions - poorly organized
# Mixed responsibilities, no proper error handling

import re
import json
from datetime import datetime

def validate_email(email):
    # Too simple
    return "@" in email and "." in email

def validate_phone(phone):
    # Not implemented
    return True

def format_currency(amount):
    # No locale support
    return f"${amount:.2f}"

def parse_date(date_string):
    # No error handling
    return datetime.strptime(date_string, "%Y-%m-%d")

def calculate_tax(amount, rate=0.08):
    # Hardcoded tax rate
    return amount * rate

def generate_order_number():
    # Not unique enough
    return f"ORD-{datetime.now().strftime('%Y%m%d%H%M%S')}"

def send_email(to, subject, body):
    # Fake implementation
    print(f"Email to {to}: {subject}")
    return True

def log_error(error):
    # Just prints to console
    print(f"ERROR: {error}")

def clean_phone_number(phone):
    # Remove all non-digits
    return re.sub(r'\D', '', phone)

def paginate_results(results, page=1, per_page=10):
    # Simple pagination
    start = (page - 1) * per_page
    end = start + per_page
    return results[start:end]

def calculate_shipping(weight, distance):
    # Overly simple calculation
    base_rate = 5.0
    weight_rate = weight * 0.5
    distance_rate = distance * 0.1
    return base_rate + weight_rate + distance_rate

def validate_credit_card(number):
    # Fake validation
    return len(number) == 16 and number.isdigit()

def hash_password(password):
    # NEVER DO THIS - just for example
    return password[::-1]  # Reversing is not encryption!

def check_password(password, hashed):
    # Equally bad
    return password[::-1] == hashed

# Random utility functions that should be elsewhere
def convert_to_csv(data):
    # Basic CSV conversion
    if not data:
        return ""
    
    headers = data[0].keys()
    lines = [",".join(headers)]
    
    for row in data:
        lines.append(",".join(str(row[h]) for h in headers))
    
    return "\n".join(lines)

def load_config():
    # Hardcoded config
    return {
        'database': 'ecommerce.db',
        'debug': True,
        'port': 5000,
        'secret_key': 'not-very-secret'
    }