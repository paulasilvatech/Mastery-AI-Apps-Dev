# Debugging Quick Reference Guide

## 🔍 Debugging Strategies with AI

### 1. Error Message Analysis

When you encounter an error, use Copilot effectively:

```python
# Error: TypeError: unsupported operand type(s) for +: 'int' and 'str'
# This error occurs when trying to add a number and string
# Fix by converting types to match
result = 5 + "10"  # Error
result = 5 + int("10")  # Fixed
```

**🤖 Copilot Prompt Pattern:**
```python
# Getting error: [paste full error message]
# This happens when: [describe what you were doing]
# Fix this function to handle the error properly:
def problematic_function():
    # Copilot will suggest fixes
```

### 2. Python Debugger (pdb)

#### Basic pdb Commands

```python
import pdb

def calculate_discount(price, discount_percent):
    pdb.set_trace()  # Debugger stops here
    discount = price * (discount_percent / 100)
    final_price = price - discount
    return final_price

# pdb commands:
# n - next line
# s - step into function
# c - continue execution
# l - list code
# p variable - print variable
# pp variable - pretty print
# h - help
```

#### Advanced pdb Usage

```python
# Conditional breakpoint
def process_items(items):
    for i, item in enumerate(items):
        if item.price > 1000:  # Only debug expensive items
            pdb.set_trace()
        process_item(item)

# Post-mortem debugging
try:
    risky_operation()
except Exception:
    import pdb
    pdb.post_mortem()  # Debug at the point of failure
```

### 3. VS Code Debugging

#### Launch Configuration (.vscode/launch.json)

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Current File",
            "type": "python",
            "request": "launch",
            "program": "${file}",
            "console": "integratedTerminal",
            "justMyCode": false  // Debug into libraries
        },
        {
            "name": "Python: Debug Tests",
            "type": "python",
            "request": "launch",
            "module": "pytest",
            "args": ["-v", "-s", "${file}"],
            "console": "integratedTerminal"
        }
    ]
}
```

#### Debugging pytest Tests

```python
# Add breakpoint() in your test
def test_complex_calculation():
    result = calculate_complex_value(100)
    breakpoint()  # Python 3.7+ built-in debugger
    assert result == expected_value
```

### 4. Print Debugging (Enhanced)

```python
# Better print debugging
from rich import print  # Colored output
from pprint import pprint  # Pretty printing

def debug_function(data):
    print(f"[DEBUG] Input type: {type(data)}")
    print(f"[DEBUG] Input value: {data}")
    
    # Show variable state at different points
    print(f"[STEP 1] Processing: {data[:10]}...")
    processed = process_data(data)
    print(f"[STEP 2] After processing: {processed}")
    
    # Pretty print complex structures
    print("[DEBUG] Complex structure:")
    pprint(complex_data, indent=2, width=80)
```

### 5. Logging for Debugging

```python
import logging

# Configure detailed logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(funcName)s:%(lineno)d - %(message)s'
)

logger = logging.getLogger(__name__)

def problematic_function(data):
    logger.debug(f"Starting with data: {data}")
    
    try:
        # Log each step
        logger.debug("Step 1: Validation")
        validate_data(data)
        
        logger.debug("Step 2: Processing")
        result = process_data(data)
        logger.debug(f"Processing result: {result}")
        
        logger.debug("Step 3: Transformation")
        final = transform_result(result)
        logger.info(f"Success: {final}")
        
        return final
        
    except Exception as e:
        logger.exception(f"Error processing {data}")
        raise
```

### 6. Common Python Errors and Fixes

#### TypeError

```python
# Problem: Type mismatch
numbers = [1, 2, "3", 4]
total = sum(numbers)  # TypeError

# Fix 1: Filter non-numbers
total = sum(x for x in numbers if isinstance(x, (int, float)))

# Fix 2: Convert types
total = sum(int(x) if isinstance(x, str) else x for x in numbers)
```

#### AttributeError

```python
# Problem: Accessing non-existent attribute
user = {"name": "John", "age": 30}
print(user.name)  # AttributeError

# Fix 1: Use dictionary access
print(user["name"])

# Fix 2: Convert to object
from types import SimpleNamespace
user_obj = SimpleNamespace(**user)
print(user_obj.name)
```

#### KeyError

```python
# Problem: Missing dictionary key
data = {"name": "John"}
age = data["age"]  # KeyError

# Fix 1: Use get() with default
age = data.get("age", 0)

# Fix 2: Check existence
if "age" in data:
    age = data["age"]
else:
    age = 0
```

### 7. Debugging Async Code

```python
import asyncio
import logging

# Configure async-aware logging
logging.basicConfig(level=logging.DEBUG)

async def debug_async_function():
    logging.debug("Starting async operation")
    
    try:
        result = await async_operation()
        logging.debug(f"Async result: {result}")
        return result
    except Exception as e:
        logging.exception("Async operation failed")
        raise

# Debug with asyncio
async def main():
    # Enable asyncio debug mode
    loop = asyncio.get_event_loop()
    loop.set_debug(True)
    
    await debug_async_function()

# Run with debugging
if __name__ == "__main__":
    asyncio.run(main(), debug=True)
```

### 8. Memory Debugging

```python
import tracemalloc
import gc

# Start tracing memory
tracemalloc.start()

# Your code here
large_list = [i for i in range(1000000)]

# Get memory usage
current, peak = tracemalloc.get_traced_memory()
print(f"Current memory: {current / 1024 / 1024:.2f} MB")
print(f"Peak memory: {peak / 1024 / 1024:.2f} MB")

# Get top memory users
snapshot = tracemalloc.take_snapshot()
top_stats = snapshot.statistics('lineno')

print("[ Top 10 memory users ]")
for stat in top_stats[:10]:
    print(stat)

# Clean up
tracemalloc.stop()
```

### 9. Performance Debugging

```python
import cProfile
import pstats
from line_profiler import LineProfiler

# Profile entire function
def profile_function():
    cProfile.run('expensive_function()', 'profile_stats')
    
    # Analyze results
    stats = pstats.Stats('profile_stats')
    stats.sort_stats('cumulative')
    stats.print_stats(10)  # Top 10 functions

# Line-by-line profiling
@profile  # Use kernprof -l -v script.py
def slow_function():
    result = []
    for i in range(1000):
        result.append(i ** 2)  # This line is slow
    return result

# Time specific sections
import time

def debug_performance():
    start = time.perf_counter()
    
    # Section 1
    section1_start = time.perf_counter()
    do_something()
    print(f"Section 1: {time.perf_counter() - section1_start:.4f}s")
    
    # Section 2
    section2_start = time.perf_counter()
    do_something_else()
    print(f"Section 2: {time.perf_counter() - section2_start:.4f}s")
    
    print(f"Total: {time.perf_counter() - start:.4f}s")
```

### 10. Database Query Debugging

```python
# SQLAlchemy query debugging
import logging

# Enable SQL logging
logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)

# Or with echo
engine = create_engine('postgresql://...', echo=True)

# Flask-SQLAlchemy debugging
app.config['SQLALCHEMY_ECHO'] = True

# Log slow queries
from flask_sqlalchemy import get_debug_queries

@app.after_request
def after_request(response):
    for query in get_debug_queries():
        if query.duration >= 0.5:
            app.logger.warning(
                f"Slow query: {query.statement}\n"
                f"Duration: {query.duration}s\n"
                f"Context: {query.context}"
            )
    return response
```

### 11. Network Debugging

```python
import requests
import logging
from http.client import HTTPConnection

# Debug HTTP requests
HTTPConnection.debuglevel = 1

# Configure logging
logging.basicConfig()
logging.getLogger().setLevel(logging.DEBUG)
requests_log = logging.getLogger("requests.packages.urllib3")
requests_log.setLevel(logging.DEBUG)
requests_log.propagate = True

# Debug requests
response = requests.get('https://api.example.com/data')
```

### 12. Debugging with IPython

```python
# Install: pip install ipython

# Drop into IPython debugger on error
from IPython.core.debugger import set_trace

def debug_with_ipython():
    data = complex_calculation()
    set_trace()  # Better than pdb.set_trace()
    # Now you have IPython features:
    # - Tab completion
    # - Syntax highlighting
    # - Magic commands (%timeit, %debug, etc.)
    return process_data(data)

# Embed IPython for exploration
from IPython import embed

def explore_data():
    result = get_complex_data()
    embed()  # Drops into IPython with access to local variables
    return result
```

## 🤖 Copilot Debugging Patterns

### Pattern 1: Error Fix Request
```python
# This function raises: ValueError: invalid literal for int() with base 10: 'abc'
# Fix it to handle non-numeric strings gracefully
def parse_number(value):
    return int(value)  # Current implementation
```

### Pattern 2: Add Debug Logging
```python
# Add comprehensive debug logging to this function
# Log: input parameters, intermediate steps, errors, execution time
def complex_algorithm(data):
    # Copilot will add logging
```

### Pattern 3: Test Case Generation
```python
# Generate test cases that would help debug this function
# Include edge cases that might cause errors
def validate_email(email):
    # Implementation
```

## 🚨 Quick Debug Checklist

When debugging, ask yourself:

1. **What changed?** - Recent code changes often cause bugs
2. **Can I reproduce it?** - Consistent reproduction is key
3. **What's the minimal case?** - Simplify to isolate the issue
4. **What are my assumptions?** - Challenge what you think you know
5. **Is it data-related?** - Check input data validity
6. **Is it environment-related?** - Development vs. production
7. **Is it a race condition?** - Threading/async issues
8. **Is it a type issue?** - Python's dynamic typing pitfall
9. **Is it a library bug?** - Check library versions/issues
10. **Did I read the docs?** - RTFM saves time

## 📝 Debug Output Formatting

```python
# Create readable debug output
def debug_print(label, value, width=80):
    """Pretty print debug information."""
    print("=" * width)
    print(f"{label}:")
    print("-" * width)
    
    if isinstance(value, (list, dict, tuple)):
        from pprint import pprint
        pprint(value, width=width)
    else:
        print(value)
    
    print("=" * width)
    print()

# Usage
debug_print("User Data", user_dict)
debug_print("API Response", response.json())
```

---

Remember: The best debugger is a good test suite! 🧪