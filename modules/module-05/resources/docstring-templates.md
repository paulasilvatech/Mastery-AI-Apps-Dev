# Docstring Templates and Examples

## 📝 Google Style Docstrings

### Function Template
```python
def function_name(param1: type1, param2: type2 = default) -> return_type:
    """Brief one-line description of function.
    
    Longer description explaining the function's purpose,
    behavior, and any important details.
    
    Args:
        param1: Description of first parameter.
        param2: Description of second parameter. Defaults to default.
        
    Returns:
        Description of return value.
        
    Raises:
        ExceptionType: Description of when this exception is raised.
        
    Examples:
        >>> function_name(value1, value2)
        expected_output
        
    Note:
        Any additional notes about the function.
    """
```

### Class Template
```python
class ClassName:
    """Brief one-line description of class.
    
    Longer description of the class purpose and usage.
    
    Attributes:
        attribute1: Description of first attribute.
        attribute2: Description of second attribute.
        
    Examples:
        >>> obj = ClassName()
        >>> obj.method()
        expected_output
    """
    
    def __init__(self, param1: type1):
        """Initialize ClassName.
        
        Args:
            param1: Description of initialization parameter.
        """
```

### Real-World Example
```python
def calculate_moving_average(data: List[float], window_size: int = 3) -> List[float]:
    """Calculate moving average of time series data.
    
    Computes the simple moving average over a specified window size.
    The first (window_size - 1) values will be None as there's
    insufficient data to calculate the average.
    
    Args:
        data: List of numerical values to process.
        window_size: Number of periods for averaging. Defaults to 3.
        
    Returns:
        List of moving averages with same length as input.
        
    Raises:
        ValueError: If window_size is larger than data length or <= 0.
        TypeError: If data contains non-numeric values.
        
    Examples:
        >>> calculate_moving_average([1, 2, 3, 4, 5], 3)
        [None, None, 2.0, 3.0, 4.0]
        
        >>> calculate_moving_average([10, 20, 30], 2)
        [None, 15.0, 25.0]
        
    Note:
        For financial data, consider using exponential moving average
        for more weight on recent values.
    """
```

## 📐 NumPy Style Docstrings

### Function Template
```python
def function_name(param1, param2=None):
    """
    Brief description of function.
    
    Extended description providing more details about the function,
    its purpose, algorithm used, etc.
    
    Parameters
    ----------
    param1 : type
        Description of first parameter.
    param2 : type, optional
        Description of second parameter, by default None.
        
    Returns
    -------
    return_type
        Description of return value.
        
    Raises
    ------
    ExceptionType
        Description of when this exception is raised.
        
    See Also
    --------
    related_function : Brief description of related function.
    
    Notes
    -----
    Additional notes about the implementation or usage.
    
    References
    ----------
    .. [1] Author, "Title", Journal, 2023.
    
    Examples
    --------
    >>> function_name(value1, value2)
    expected_output
    """
```

### Real-World Example
```python
def pearson_correlation(x, y, ddof=0):
    """
    Calculate Pearson correlation coefficient between two arrays.
    
    Computes the Pearson correlation coefficient measuring the linear
    relationship between two datasets. The coefficient ranges from
    -1 to 1, where 1 indicates perfect positive correlation.
    
    Parameters
    ----------
    x : array_like
        First array of values.
    y : array_like
        Second array of values, must be same length as x.
    ddof : int, optional
        Delta degrees of freedom for standard deviation, by default 0.
        
    Returns
    -------
    float
        Pearson correlation coefficient between x and y.
        
    Raises
    ------
    ValueError
        If x and y have different lengths.
    TypeError
        If inputs cannot be converted to numeric arrays.
        
    See Also
    --------
    spearman_correlation : Non-parametric rank correlation.
    covariance : Measure of joint variability.
    
    Notes
    -----
    The Pearson correlation is defined as:
    
    .. math:: r = \\frac{\\sum{(x_i - \\bar{x})(y_i - \\bar{y})}}{\\sqrt{\\sum{(x_i - \\bar{x})^2}\\sum{(y_i - \\bar{y})^2}}}
    
    This implementation uses Welford's algorithm for numerical stability.
    
    References
    ----------
    .. [1] Pearson, K. (1895). "Notes on regression and inheritance"
    
    Examples
    --------
    >>> x = [1, 2, 3, 4, 5]
    >>> y = [2, 4, 6, 8, 10]
    >>> pearson_correlation(x, y)
    1.0
    
    >>> x = [1, 2, 3]
    >>> y = [3, 2, 1]
    >>> pearson_correlation(x, y)
    -1.0
    """
```

## 🔷 Sphinx Style Docstrings

### Function Template
```python
def function_name(param1, param2=None):
    """Brief description of function.
    
    Longer description with more details.
    
    :param param1: Description of first parameter
    :type param1: type
    :param param2: Description of second parameter, defaults to None
    :type param2: type, optional
    
    :returns: Description of return value
    :rtype: return_type
    
    :raises ExceptionType: Description of when raised
    
    :Example:
    
    >>> function_name(value1, value2)
    expected_output
    
    .. note::
       Additional notes about the function.
       
    .. warning::
       Important warnings for users.
       
    .. seealso::
       :func:`related_function`
    """
```

### Real-World Example
```python
def parse_configuration(config_file, validate=True, encoding='utf-8'):
    """Parse configuration file and return settings dictionary.
    
    Reads a YAML or JSON configuration file and returns a dictionary
    of settings. Supports environment variable expansion and includes
    schema validation.
    
    :param config_file: Path to configuration file
    :type config_file: str or pathlib.Path
    :param validate: Whether to validate against schema, defaults to True
    :type validate: bool, optional
    :param encoding: File encoding, defaults to 'utf-8'
    :type encoding: str, optional
    
    :returns: Dictionary containing configuration settings
    :rtype: dict
    
    :raises FileNotFoundError: If config_file doesn't exist
    :raises ValueError: If file format is not supported
    :raises ValidationError: If validation is enabled and config is invalid
    
    :Example:
    
    >>> config = parse_configuration('app.yaml')
    >>> print(config['database']['host'])
    'localhost'
    
    >>> config = parse_configuration('settings.json', validate=False)
    >>> config['debug']
    True
    
    .. note::
       Environment variables in the format ${VAR_NAME} will be expanded
       automatically during parsing.
       
    .. warning::
       Disabling validation may lead to runtime errors if the configuration
       doesn't match expected schema.
       
    .. versionadded:: 2.0
       Added support for environment variable expansion
       
    .. seealso::
       :func:`validate_configuration` - Standalone validation function
       :class:`ConfigurationSchema` - Schema definition class
    """
```

## 🎯 Best Practices for Docstrings

### 1. Be Concise but Complete
```python
# Bad: Too verbose
def add(a, b):
    """
    This function takes two parameters, a and b, which should be
    numbers, and adds them together using the addition operator,
    then returns the result of the addition operation.
    """
    
# Good: Concise and clear
def add(a: float, b: float) -> float:
    """Add two numbers and return the sum.
    
    Args:
        a: First number.
        b: Second number.
        
    Returns:
        Sum of a and b.
    """
```

### 2. Include Examples
```python
def normalize_text(text: str, lowercase: bool = True) -> str:
    """Normalize text for consistent processing.
    
    Args:
        text: Input text to normalize.
        lowercase: Convert to lowercase. Defaults to True.
        
    Returns:
        Normalized text.
        
    Examples:
        >>> normalize_text("  Hello World!  ")
        'hello world!'
        
        >>> normalize_text("  Hello World!  ", lowercase=False)
        'Hello World!'
    """
```

### 3. Document Edge Cases
```python
def divide_safe(numerator: float, denominator: float) -> Optional[float]:
    """Safely divide two numbers.
    
    Args:
        numerator: The number to be divided.
        denominator: The number to divide by.
        
    Returns:
        Result of division, or None if denominator is zero.
        
    Examples:
        >>> divide_safe(10, 2)
        5.0
        
        >>> divide_safe(10, 0)
        None
        
    Note:
        This function returns None instead of raising ZeroDivisionError
        to allow for cleaner error handling in data pipelines.
    """
```

### 4. Use Type Hints
```python
from typing import List, Dict, Optional, Union

def process_records(
    records: List[Dict[str, Any]], 
    fields: Optional[List[str]] = None
) -> Union[List[Dict[str, Any]], None]:
    """Process records filtering by specified fields.
    
    Args:
        records: List of record dictionaries.
        fields: Fields to include. If None, includes all fields.
        
    Returns:
        Filtered records or None if no records match.
    """
```

## 📊 Docstring Coverage Metrics

### Measuring Documentation Quality
```python
def calculate_docstring_coverage(module_path: Path) -> float:
    """Calculate percentage of documented functions/classes.
    
    A function/class is considered documented if it has:
    - A docstring of at least 10 characters
    - Description of all parameters
    - Description of return value (for functions)
    
    Args:
        module_path: Path to Python module to analyze.
        
    Returns:
        Documentation coverage as percentage (0-100).
        
    Examples:
        >>> calculate_docstring_coverage(Path("my_module.py"))
        87.5  # 87.5% of items are properly documented
    """
```

## 🔄 Automated Docstring Generation

### Using Comments as Hints
```python
# Copilot will generate comprehensive docstring from this comment:
# Function to validate email addresses using regex
# Should check for @ symbol, domain, and common patterns
# Returns tuple of (is_valid, error_message)
# Handles international domains and modern TLDs
def validate_email(email: str) -> Tuple[bool, Optional[str]]:
    # Copilot generates complete docstring here
```

### Template for Copilot
```python
# Generate docstring with:
# - Brief description
# - Detailed explanation of algorithm
# - All parameters with types
# - Return value description
# - 2-3 usage examples
# - Common exceptions
# - Performance notes if relevant
def complex_algorithm(data: List[float], threshold: float = 0.5):
    # Implementation
```

## 📚 Additional Resources

### Tools for Docstring Validation
- `pydocstyle` - Check compliance with conventions
- `darglint` - Check docstring matches function signature
- `interrogate` - Calculate documentation coverage
- `sphinx-autodoc` - Generate API docs from docstrings

### VS Code Extensions
- Python Docstring Generator
- autoDocstring
- Better Comments
- Sphinx Preview

---

*Remember: Good documentation is an investment in your future self and your team. Make it count!*