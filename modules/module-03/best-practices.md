# Best Practices for Effective Prompting with GitHub Copilot

## 🎯 Overview

This guide contains production-ready best practices for prompting GitHub Copilot effectively. These patterns have been tested in real-world scenarios and proven to improve code generation quality, consistency, and developer productivity.

## 📋 Quick Reference

### The Golden Rules of Prompting

1. **Be Specific** - Vague prompts yield vague code
2. **Show Examples** - Demonstrate the pattern you want
3. **Provide Context** - Help Copilot understand the bigger picture
4. **Iterate** - Refine prompts based on results
5. **Verify** - Always review and test generated code

## 🏗️ Context Optimization Patterns

### 1. The Sandwich Pattern

Place your prompt between relevant context:

```python
# Existing context (bread top)
class UserManager:
    def __init__(self):
        self.users = []
        self.auth_service = AuthService()

# Your prompt (filling)
# Create a method that authenticates a user with email and password
# Should:
# - Check if user exists
# - Verify password using auth_service
# - Return user object or None
# - Log failed attempts
def authenticate_user(self, email: str, password: str) -> Optional[User]:
    # Copilot generates here

# Related context (bread bottom)
def create_user(self, email: str, password: str) -> User:
    # Existing implementation
```

### 2. The Progressive Disclosure Pattern

Start simple, add complexity gradually:

```python
# Step 1: Basic structure
def process_data(data):
    pass

# Step 2: Add type hints and basic logic
def process_data(data: List[Dict]) -> DataFrame:
    # Convert list of dicts to DataFrame
    pass

# Step 3: Add full requirements
def process_data(data: List[Dict], 
                filters: Optional[Dict] = None,
                sort_by: str = 'date') -> DataFrame:
    """
    Process raw data with filtering and sorting.
    
    Requirements:
    - Handle missing values
    - Apply filters if provided
    - Sort by specified column
    - Add calculated fields (total, average)
    - Cache results for repeated calls
    """
    # Now Copilot has full context
```

### 3. The Example-Driven Pattern

Show input/output examples:

```python
def parse_time_expression(expr: str) -> int:
    """
    Parse human-readable time expressions to minutes.
    
    Examples:
    - "1h 30m" -> 90
    - "2 hours" -> 120
    - "45 min" -> 45
    - "1.5h" -> 90
    - "90" -> 90 (assumes minutes)
    
    Handles: h, hour, hours, m, min, mins, minutes
    """
    # Copilot understands the pattern from examples
```

## 🎨 Prompt Engineering Patterns

### 1. The Specification Pattern

```python
# SPECIFICATION: User Registration Validator
# Purpose: Validate user registration data
# 
# Inputs:
#   - username: str (3-20 chars, alphanumeric + underscore)
#   - email: str (valid email format)
#   - password: str (min 8 chars, 1 upper, 1 lower, 1 digit)
#   - age: int (must be 13+)
#
# Outputs:
#   - Tuple[bool, List[str]] - (is_valid, error_messages)
#
# Behavior:
#   - Check all fields even if one fails
#   - Return specific error messages
#   - Case-insensitive email validation
#   - No external service calls

def validate_registration(username: str, email: str, password: str, age: int) -> Tuple[bool, List[str]]:
    # Copilot generates comprehensive validation
```

### 2. The Algorithm Pattern

```python
# ALGORITHM: Find optimal meeting time
# Input: List of availability slots for multiple people
# Output: Best common time slot
#
# Steps:
# 1. Convert all times to common timezone
# 2. Find overlapping slots across all participants
# 3. Rank slots by:
#    - Number of participants available
#    - Preferred time (9 AM - 5 PM weighted higher)
#    - Duration (prefer longer slots)
# 4. Return top slot or None if no overlap
#
# Edge cases:
# - Handle timezone differences
# - Minimum slot duration: 30 minutes
# - Maximum participants: 20

def find_optimal_meeting_time(availabilities: List[PersonAvailability]) -> Optional[TimeSlot]:
    # Copilot implements the algorithm
```

### 3. The Constraint Pattern

```python
# Create a rate limiter with these constraints:
# - HARD LIMITS:
#   * Max 100 requests per minute per user
#   * Max 1000 requests per hour per user
#   * Global max 10000 requests per minute
# - SOFT LIMITS:
#   * Warn at 80% of limit
#   * Send alert at 90% of limit
# - FEATURES:
#   * Sliding window algorithm
#   * Redis backend for distributed systems
#   * Graceful degradation if Redis unavailable
#   * Whitelist for internal services
# - PERFORMANCE:
#   * Decision time < 1ms
#   * Minimal memory footprint

class RateLimiter:
    # Copilot considers all constraints
```

## 📊 Production Patterns

### 1. The Error Handling Pattern

```python
# Implement robust error handling:
# - Catch specific exceptions
# - Log errors with context
# - Graceful degradation
# - User-friendly error messages
# - Retry logic for transient failures
# - Circuit breaker for repeated failures
# - Metrics/monitoring integration

async def fetch_user_data(user_id: str) -> UserData:
    """Fetch user data with production-grade error handling."""
    # Copilot generates comprehensive error handling
```

### 2. The Performance Pattern

```python
# Optimize for performance:
# - Use caching (LRU, TTL-based)
# - Implement lazy loading
# - Batch operations when possible
# - Use async/await for I/O
# - Profile-guided optimization points
# - Memory-efficient data structures
# Target: Handle 10k requests/second

class HighPerformanceProcessor:
    # Copilot generates performance-optimized code
```

### 3. The Security Pattern

```python
# Security requirements:
# - Input validation against OWASP Top 10
# - SQL injection prevention
# - XSS protection
# - Authentication required
# - Authorization checks
# - Audit logging
# - Rate limiting
# - Encryption for sensitive data

@require_auth
@rate_limit(100, "1m")
def update_user_profile(user_id: str, profile_data: dict) -> dict:
    # Copilot implements with security in mind
```

## 🔄 Iterative Improvement Patterns

### 1. The Refinement Loop

```python
# Version 1: Basic implementation
def calculate_price(items):
    return sum(item.price for item in items)

# Version 2: Add requirements discovered during testing
def calculate_price(items: List[Item], 
                   discount_code: Optional[str] = None) -> Decimal:
    """Calculate with discounts and tax."""
    # More specific implementation

# Version 3: Production-ready
def calculate_price(
    items: List[Item],
    discount_code: Optional[str] = None,
    tax_rate: Decimal = Decimal("0.08"),
    currency: str = "USD"
) -> PriceBreakdown:
    """
    Calculate total price with full breakdown.
    
    Handles:
    - Multiple discount types
    - Tax exemptions
    - Currency conversion
    - Bulk pricing
    - Shipping costs
    
    Returns detailed breakdown for transparency.
    """
    # Copilot generates comprehensive solution
```

### 2. The Test-Driven Pattern

```python
# First, write the test to guide implementation
def test_password_strength():
    # Weak passwords
    assert not is_strong_password("12345678")
    assert not is_strong_password("password")
    assert not is_strong_password("Password1")
    
    # Strong passwords
    assert is_strong_password("Str0ng!Pass")
    assert is_strong_password("MyP@ssw0rd123")
    
    # Edge cases
    assert not is_strong_password("")
    assert not is_strong_password("a" * 100)

# Then implement to pass tests
def is_strong_password(password: str) -> bool:
    """Check if password meets security requirements."""
    # Copilot generates implementation matching tests
```

## 🎯 Domain-Specific Patterns

### 1. API Endpoint Pattern

```python
# REST API endpoint pattern
# HTTP Method: POST
# Path: /api/v1/orders
# Auth: Bearer token required
# 
# Request body:
# {
#   "items": [{"product_id": "123", "quantity": 2}],
#   "shipping_address": {...},
#   "payment_method": "credit_card"
# }
#
# Response:
# Success (201): {"order_id": "...", "status": "pending", "total": 99.99}
# Validation error (400): {"errors": [...]}
# Auth error (401): {"error": "Unauthorized"}
#
# Business rules:
# - Validate inventory availability
# - Calculate shipping based on address
# - Apply applicable taxes
# - Send confirmation email

@app.route("/api/v1/orders", methods=["POST"])
@require_authentication
async def create_order():
    # Copilot implements the endpoint
```

### 2. Data Pipeline Pattern

```python
# ETL Pipeline Specification
# Source: CSV files in S3 bucket
# Destination: PostgreSQL database
# 
# Pipeline steps:
# 1. EXTRACT:
#    - Download files from S3
#    - Handle multiple file formats
#    - Validate file integrity
#
# 2. TRANSFORM:
#    - Clean data (remove duplicates, fix formats)
#    - Enrich with external API data
#    - Apply business rules
#    - Generate audit trail
#
# 3. LOAD:
#    - Bulk insert with conflict handling
#    - Update materialized views
#    - Send notifications
#
# Requirements:
# - Idempotent operations
# - Resumable on failure
# - Process 1M records in < 5 minutes

class DataPipeline:
    # Copilot builds the pipeline
```

## 📈 Measuring Prompt Effectiveness

### Key Metrics

1. **Accuracy Rate**: Generated code correctness
2. **Modification Time**: Time to adjust generated code
3. **Completeness**: How much was generated vs. written
4. **Pattern Reuse**: How often patterns are reused

### Tracking Template

```python
# PROMPT METRICS:
# Pattern: API Endpoint
# Success Rate: 85%
# Avg Modification: 2 minutes
# Reuse Count: 45
# Last Updated: 2024-01-15
#
# Common modifications:
# - Add custom validation
# - Adjust error messages
# - Add logging
```

## 🚀 Advanced Techniques

### 1. Multi-Stage Prompting

```python
# Stage 1: Structure
class OrderService:
    """Define the interface first."""
    def create_order(self, data: dict) -> Order: ...
    def update_order(self, id: str, data: dict) -> Order: ...
    def cancel_order(self, id: str) -> bool: ...

# Stage 2: Implementation details
# Now implement create_order with:
# - Inventory check
# - Payment processing
# - Email notification
def create_order(self, data: dict) -> Order:
    # Copilot has clear structure to follow
```

### 2. Context Injection

```python
# Inject domain knowledge
"""
DOMAIN CONTEXT:
- Order statuses: pending, confirmed, shipped, delivered, cancelled
- Payment methods: credit_card, paypal, bank_transfer
- Shipping providers: fedex, ups, usps
- Business hours: 9 AM - 5 PM EST
- SLA: Order confirmation within 2 minutes
"""

class OrderProcessor:
    # Copilot uses domain context
```

## ✅ Checklist for Production Prompts

Before using a prompt in production:

- [ ] Specific requirements clearly stated
- [ ] Examples provided where helpful
- [ ] Constraints and edge cases defined
- [ ] Error handling requirements included
- [ ] Performance considerations mentioned
- [ ] Security requirements specified
- [ ] Testing approach defined
- [ ] Documentation expectations clear

## 🎓 Learning Resources

- [Official GitHub Copilot Documentation](https://docs.github.com/en/copilot)
- [Prompt Engineering Guide](https://www.promptingguide.ai/)
- [Clean Code Principles](https://clean-code-developer.com/)
- [Design Patterns](https://refactoring.guru/design-patterns)

---

💡 **Remember**: The best prompt is one that clearly communicates intent while providing sufficient context for accurate code generation. Practice and iterate to find what works best for your team and project!