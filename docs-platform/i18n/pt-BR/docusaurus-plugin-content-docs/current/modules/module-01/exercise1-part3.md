---
sidebar_position: 2
title: "Exercise 1: Part 3"
description: "## 🚀 Part 3: Testing and Building a Complete Application"
---

# Exercício 1: First AI Code (⭐ Fácil) - Partee 3

## 🚀 Partee 3: Testing and Building a Completar Application

In this final part, we'll test our functions and create a command-line interface (CLI) to showcase all our utilities.

### Step 13: Writing Tests with Copilot

Abrir `starter/test_utils.py` and let's write comprehensive tests:

**🤖 Copilot Prompt Suggestion #9:**
```python
# Test the validate_email function with:
# - Valid emails: user@example.com, test.user@domain.co.uk
# - Invalid emails: no-at-sign, @no-local, no-domain@, double@@example.com
# - Edge cases: empty string, None (if handled)
# Use pytest and parametrize for multiple test cases
```

Comece com imports and the test:
```python
import pytest
from utils import validate_email, validate_phone, smart_title_case, calculate_age

def test_validate_email():
```

**Expected Output:**
```python
import pytest
from utils import validate_email, validate_phone, smart_title_case, calculate_age

@pytest.mark.parametrize("email,expected", [
    # Valid emails
    ("user@example.com", True),
    ("test.user@domain.co.uk", True),
    ("name+tag@example.org", True),
    ("user123@test-domain.com", True),
    
    # Invalid emails
    ("no-at-sign", False),
    ("@no-local", False),
    ("no-domain@", False),
    ("double@@example.com", False),
    ("user@", False),
    ("@domain.com", False),
    ("user@domain", False),  # No TLD
    
    # Edge cases
    ("", False),
    ("   ", False),
])
def test_validate_email(email, expected):
    """Test email validation function."""
    assert validate_email(email) == expected
```

### Step 14: Test the Phone Validation

**🤖 Copilot Prompt Suggestion #10:**
```python
# Test validate_phone with various formats:
# - Valid: (123) 456-7890, 123-456-7890, 123.456.7890, 1234567890
# - With country code: 1-123-456-7890
# - Invalid: too short, too long, with letters
# Check that valid numbers return 10-digit string
```

Add this test:
```python
def test_validate_phone():
```

**Expected Output:**
```python
@pytest.mark.parametrize("phone,expected", [
    # Valid formats
    ("(123) 456-7890", "1234567890"),
    ("123-456-7890", "1234567890"),
    ("123.456.7890", "1234567890"),
    ("1234567890", "1234567890"),
    ("1-123-456-7890", "1234567890"),
    ("+1-123-456-7890", "1234567890"),
    
    # Invalid formats
    ("123456789", None),  # Too short
    ("12345678901", None),  # Too long
    ("123-45A-7890", None),  # Contains letter
    ("", None),
    ("phone-number", None),
])
def test_validate_phone(phone, expected):
    """Test phone validation function."""
    assert validate_phone(phone) == expected
```

### Step 15: Test String Manipulation

**🤖 Copilot Prompt Suggestion #11:**
```python
# Test smart_title_case function:
# - Basic: "hello world" -&gt; "Hello World"
# - With articles: "the quick brown fox" -&gt; "The Quick Brown Fox"
# - Middle articles: "a tale of two cities" -&gt; "A Tale of Two Cities"
# - All caps input: "THE GREAT GATSBY" -&gt; "The Great Gatsby"
# - Empty and edge cases
```

Add the test:
```python
def test_smart_title_case():
```

**Expected Output:**
```python
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
    
    # Edge cases
    ("", ""),
    ("a", "A"),
    ("THE GREAT GATSBY", "The Great Gatsby"),
    ("war AND peace", "War and Peace"),
])
def test_smart_title_case(text, expected):
    """Test smart title case function."""
    assert smart_title_case(text) == expected
```

### Step 16: Integration Test for TextAnalyzer

**🤖 Copilot Prompt Suggestion #12:**
```python
# Test TextAnalyzer class:
# - Create sample text with known statistics
# - Test word count, sentence count, character count
# - Test average calculations
# - Test common words extraction (excluding stop words)
# Use a fixture for reusable test text
```

Add the test:
```python
from utils import TextAnalyzer

@pytest.fixture
def sample_text():
    return "The quick brown fox jumps over the lazy dog. This is a test sentence. Python is great."

def test_text_analyzer(sample_text):
```

**Expected Output:**
```python
@pytest.fixture
def sample_text():
    """Sample text for testing."""
    return "The quick brown fox jumps over the lazy dog. This is a test sentence. Python is great."

def test_text_analyzer(sample_text):
    """Test TextAnalyzer functionality."""
    analyzer = TextAnalyzer(sample_text)
    stats = analyzer.get_statistics()
    
    # Test basic counts
    assert stats['word_count'] == 17
    assert stats['sentence_count'] == 3
    assert stats['character_count'] == len(sample_text)
    
    # Test averages (approximate due to rounding)
    assert 3.5 &lt; stats['avg_word_length'] &lt; 4.5
    assert 5 &lt; stats['avg_words_per_sentence'] &lt; 6
    
    # Test common words
    common_words = analyzer.get_common_words(5)
    
    # Should exclude stop words like "the", "is", "a"
    word_list = [word for word, count in common_words]
    assert "the" not in word_list
    assert "is" not in word_list
    
    # Should include content words
    assert any(word in word_list for word in ["quick", "brown", "fox", "python", "test"])
```

### Step 17: Create a CLI Application

Now let's create a complete CLI application that uses all our utilities. Create a new file `cli_app.py`:

**🤖 Copilot Prompt Suggestion #13:**
```python
# Create a CLI application using click that provides these commands:
# - validate email <email> - Check if email is valid
# - validate phone <phone> - Check if phone is valid  
# - titlecase <text> - Convert text to smart title case
# - analyze <text> - Analyze text and show statistics
# - compound-interest - Interactive calculator for compound interest
# Include help text, examples, and colored output using click styles
```

Start the file:
```python
import click
from utils import (
    validate_email, validate_phone, smart_title_case,
    calculate_compound_interest, TextAnalyzer
)

@click.group()
def cli():
    """Utility Functions CLI - Your AI-powered toolkit!"""
    pass
```

**Expected Output:**
```python
import click
from utils import (
    validate_email, validate_phone, smart_title_case,
    calculate_compound_interest, TextAnalyzer
)

@click.group()
def cli():
    """Utility Functions CLI - Your AI-powered toolkit!"""
    pass

@cli.command()
@click.argument('email')
def validate_email_cmd(email):
    """Check if an email address is valid."""
    if validate_email(email):
        click.echo(click.style(f"✅ '{email}' is valid!", fg='green'))
    else:
        click.echo(click.style(f"❌ '{email}' is not valid!", fg='red'))

@cli.command()
@click.argument('phone')
def validate_phone_cmd(phone):
    """Check if a phone number is valid."""
    result = validate_phone(phone)
    if result:
        click.echo(click.style(f"✅ Valid phone: {result}", fg='green'))
        # Format for display
        formatted = f"({result[:3]}) {result[3:6]}-{result[6:]}"
        click.echo(f"📞 Formatted: {formatted}")
    else:
        click.echo(click.style(f"❌ '{phone}' is not a valid phone number!", fg='red'))

@cli.command()
@click.argument('text', nargs=-1, required=True)
def titlecase(text):
    """Convert text to smart title case."""
    input_text = ' '.join(text)
    result = smart_title_case(input_text)
    click.echo(f"Original: {input_text}")
    click.echo(f"Title Case: {click.style(result, fg='cyan', bold=True)}")

@cli.command()
@click.argument('text', nargs=-1, required=True)
def analyze(text):
    """Analyze text and show statistics."""
    input_text = ' '.join(text)
    analyzer = TextAnalyzer(input_text)
    stats = analyzer.get_statistics()
    
    click.echo(click.style("📊 Text Analysis Results:", fg='yellow', bold=True))
    click.echo(f"  Words: {stats['word_count']}")
    click.echo(f"  Sentences: {stats['sentence_count']}")
    click.echo(f"  Characters: {stats['character_count']}")
    click.echo(f"  Avg word length: {stats['avg_word_length']:.1f}")
    click.echo(f"  Avg words/sentence: {stats['avg_words_per_sentence']:.1f}")
    
    # Show common words
    click.echo(click.style("\n🔤 Most Common Words:", fg='yellow'))
    for word, count in analyzer.get_common_words(5):
        click.echo(f"  {word}: {count}")

@cli.command()
def compound_interest():
    """Interactive compound interest calculator."""
    click.echo(click.style("💰 Compound Interest Calculator", fg='green', bold=True))
    
    # Get inputs interactively
    principal = click.prompt("Enter principal amount ($)", type=float)
    rate = click.prompt("Enter annual interest rate (%)", type=float)
    time = click.prompt("Enter time period (years)", type=float)
    n = click.prompt("Compounds per year", type=int, default=12)
    
    # Calculate
    final_amount, interest_earned = calculate_compound_interest(principal, rate, time, n)
    
    # Display results
    click.echo(click.style("\n📈 Results:", fg='cyan', bold=True))
    click.echo(f"  Principal: ${principal:,.2f}")
    click.echo(f"  Rate: {rate}%")
    click.echo(f"  Time: {time} years")
    click.echo(f"  Final Amount: ${click.style(f'{final_amount:,.2f}', fg='green', bold=True)}")
    click.echo(f"  Interest Earned: ${click.style(f'{interest_earned:,.2f}', fg='yellow', bold=True)}")

if __name__ == '__main__':
    cli()
```

### Step 18: Create a Validation Script

Create `validate_exercise.py` to check if the exercise is complete:

**🤖 Copilot Prompt Suggestion #14:**
```python
# Create a validation script that checks:
# 1. All required functions exist in utils.py
# 2. All tests pass
# 3. CLI application runs without errors
# 4. Code follows PEP 8 style
# Show results with checkmarks/crosses and colors
# Return exit code 0 if all pass, 1 if any fail
```

**Expected Output:**
```python
#!/usr/bin/env python3
"""Exercise 1 Validation Script"""

import subprocess
import sys
from pathlib import Path
import ast

def check_functions_exist():
    """Check if all required functions exist."""
    required_functions = [
        'validate_email',
        'validate_phone',
        'smart_title_case',
        'calculate_compound_interest',
        'calculate_age',
        'read_json_safely'
    ]
    
    utils_file = Path('starter/utils.py')
    if not utils_file.exists():
        print("❌ utils.py not found")
        return False
    
    try:
        tree = ast.parse(utils_file.read_text())
        defined_functions = [
            node.name for node in ast.walk(tree) 
            if isinstance(node, ast.FunctionDef)
        ]
        
        all_exist = True
        for func in required_functions:
            if func in defined_functions:
                print(f"✅ Function '{func}' exists")
            else:
                print(f"❌ Function '{func}' missing")
                all_exist = False
        
        # Check for TextAnalyzer class
        classes = [
            node.name for node in ast.walk(tree) 
            if isinstance(node, ast.ClassDef)
        ]
        if 'TextAnalyzer' in classes:
            print("✅ TextAnalyzer class exists")
        else:
            print("❌ TextAnalyzer class missing")
            all_exist = False
            
        return all_exist
        
    except Exception as e:
        print(f"❌ Error parsing utils.py: {e}")
        return False

def run_tests():
    """Run pytest on the test file."""
    print("\n🧪 Running tests...")
    result = subprocess.run(
        ['pytest', 'starter/test_utils.py', '-v'],
        capture_output=True,
        text=True
    )
    
    if result.returncode == 0:
        print("✅ All tests passed!")
        return True
    else:
        print("❌ Some tests failed:")
        print(result.stdout)
        return False

def check_cli_app():
    """Check if CLI app exists and has basic structure."""
    cli_file = Path('cli_app.py')
    if not cli_file.exists():
        print("❌ cli_app.py not found")
        return False
    
    try:
        # Test basic CLI functionality
        result = subprocess.run(
            ['python', 'cli_app.py', '--help'],
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            print("✅ CLI app runs successfully")
            return True
        else:
            print("❌ CLI app has errors")
            return False
            
    except Exception as e:
        print(f"❌ Error running CLI app: {e}")
        return False

def main():
    """Run all validations."""
    print("🔍 Exercise 1 Validation")
    print("=" * 40)
    
    checks = [
        ("Checking functions", check_functions_exist()),
        ("Running tests", run_tests()),
        ("Checking CLI app", check_cli_app())
    ]
    
    print("\n📊 Summary")
    print("=" * 40)
    
    all_passed = all(result for _, result in checks)
    
    if all_passed:
        print("✅ All checks passed! Exercise complete! 🎉")
        sys.exit(0)
    else:
        print("❌ Some checks failed. Please review and fix.")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

### Step 19: Running Everything

Now let's test our complete application:

1. **Run the tests:**
   ```bash
   pytest starter/test_utils.py -v
   ```

2. **Try the CLI commands:**
   ```bash
   # Validate email
   python cli_app.py validate-email-cmd user@example.com
   
   # Validate phone
   python cli_app.py validate-phone-cmd "(555) 123-4567"
   
   # Title case
   python cli_app.py titlecase the quick brown fox
   
   # Analyze text
   python cli_app.py analyze "Python is amazing. AI makes coding faster."
   
   # Compound interest
   python cli_app.py compound-interest
   ```

3. **Run validation:**
   ```bash
   python validate_exercise.py
   ```

## 🎯 Exercício Completar!

Congratulations! You've successfully:
1. ✅ Written your first AI-assisted functions
2. ✅ Created comprehensive tests with Copilot
3. ✅ Built a complete CLI application
4. ✅ Learned fundamental Copilot patterns

### Key Takeaways

1. **Context is King** - Better comments = better suggestions
2. **Iterative Development** - Accept, modify, improve
3. **Type Hints Ajuda** - They guide Copilot effectively
4. **Tests are Fácil** - Copilot excels at generating tests
5. **Full Applications** - Copilot can help with entire programs

### Extension Challenges

Try these additional challenges:
1. Add a function to validate credit card numbers (Luhn algorithm)
2. Create a password strength checker
3. Add file compression utilities
4. Implement a simple encryption function
5. Add more text analysis features (readability scores)

### What's Próximo?

- Revisar the [best practices](best-practices.md) document
- Try the independent [project](./index)
- Move on to [Exercício 2](./exercise2-part1)

---

🎉 **Congratulations!** You've completed your first AI-powered coding exercise. You're now ready to explore more advanced Copilot features!