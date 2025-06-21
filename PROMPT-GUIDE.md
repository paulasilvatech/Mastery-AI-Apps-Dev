# 🤖 AI Prompting Best Practices Guide

## Core Principles

### 1. Be Specific and Clear
❌ **Poor**: "Create a function"
✅ **Good**: "Create a Python function that validates email addresses using regex"
✅ **Better**: "Create a Python function that validates email addresses using regex, returns boolean, handles None input, and includes docstring with examples"

### 2. Provide Context
```python
# Context: Building a REST API for user management
# Need: Function to hash passwords securely
# Requirements: Use bcrypt, handle salting, return string
# Create a password hashing function
```

### 3. Specify Constraints
```python
# Create a rate limiter class that:
# - Limits to 100 requests per minute
# - Uses Redis for distributed state
# - Thread-safe implementation
# - Returns remaining requests in response
# - Handles Redis connection failures gracefully
```

## Effective Patterns

### Pattern 1: Stepwise Refinement
```python
# Step 1: Create basic structure
# Create a class for managing database connections

# Step 2: Add specific features
# Add connection pooling with max 10 connections

# Step 3: Add error handling
# Add retry logic with exponential backoff
```

### Pattern 2: Example-Driven
```python
# Create a function like this example:
# Input: ["apple", "banana", "apple", "orange", "banana", "apple"]
# Output: {"apple": 3, "banana": 2, "orange": 1}
# But handle any hashable type, not just strings
```

### Pattern 3: Test-First
```python
# Create a function that passes these tests:
# assert calculate_discount(100, 0.1) == 90
# assert calculate_discount(100, 0) == 100
# assert calculate_discount(100, 1) == 0
# Handles invalid inputs by raising ValueError
```

## GitHub Copilot Specific Tips

### 1. Use Comments Strategically
```python
# TODO: Implement caching here
def get_user_data(user_id):
    # Check cache first
    # If not in cache, query database
    # Cache the result with 5-minute TTL
    # Return user data
```

### 2. Leverage Type Hints
```python
from typing import List, Dict, Optional
from datetime import datetime

def process_transactions(
    transactions: List[Dict[str, any]], 
    start_date: Optional[datetime] = None
) -> Dict[str, float]:
    # Copilot will understand the expected types
```

### 3. Natural Language in Docstrings
```python
def optimize_route(locations):
    """
    Find the shortest route visiting all locations exactly once.
    
    This is the traveling salesman problem. Use a greedy approach
    for simplicity: always visit the nearest unvisited location.
    
    Args:
        locations: List of (x, y) coordinate tuples
        
    Returns:
        Ordered list of locations representing the route
    """
```

## Agent Development Prompts

### Creating Agents
```typescript
// Create an MCP server that:
// - Exposes a weather tool
// - Accepts city name as parameter
// - Returns temperature, conditions, and forecast
// - Handles errors gracefully
// - Implements rate limiting
// - Uses OpenWeatherMap API
```

### Multi-Agent Orchestration
```python
# Create an orchestrator that coordinates:
# - Research Agent: Gathers information from web
# - Analysis Agent: Processes and summarizes data
# - Writer Agent: Creates final report
# Agents communicate via message queue
# Handle agent failures with circuit breaker pattern
```

## Advanced Techniques

### 1. Chain-of-Thought Prompting
```python
# Implement a complex calculation step by step:
# 1. First, validate all inputs are positive numbers
# 2. Then, calculate the base price using formula: base = quantity * unit_price
# 3. Apply tiered discount based on quantity thresholds
# 4. Add tax based on customer location
# 5. Round to 2 decimal places
# 6. Return detailed breakdown object
```

### 2. Iterative Refinement
```python
# Create basic version first
class DataProcessor:
    pass

# Now add initialization with configuration
# Now add data validation method
# Now add processing logic with error handling
# Now add logging throughout
# Now add performance metrics
```

### 3. Edge Case Handling
```python
# Create a URL parser that handles:
# - Standard HTTP/HTTPS URLs
# - URLs with ports (example.com:8080)
# - URLs with authentication (user:pass@example.com)
# - URLs with query parameters and fragments
# - International domains (münchen.de)
# - IP addresses (192.168.1.1)
# - Missing protocol (assume https)
# - Trailing slashes
# Return None for invalid URLs
```

## Do's and Don'ts

### Do's ✅
- Include expected input/output examples
- Specify error handling requirements
- Mention performance considerations
- Add security requirements upfront
- Use consistent naming conventions

### Don'ts ❌
- Don't be vague ("make it better")
- Don't assume context without providing it
- Don't request impossible combinations
- Don't ignore language idioms
- Don't skip validation requirements

## Module-Specific Prompting

### For Web Development (Modules 7-8)
- Specify framework (FastAPI, Flask, etc.)
- Include route patterns
- Mention authentication needs
- Define response formats

### For Cloud/DevOps (Modules 12-14)
- Specify cloud provider (Azure)
- Include resource constraints
- Mention security requirements
- Define scaling parameters

### For Agents (Modules 21-25)
- Define agent capabilities clearly
- Specify communication protocols
- Include state management needs
- Define error recovery strategies

## Debugging with AI

### Effective Error Prompts
```python
# Getting error: "KeyError: 'user_id'"
# Stack trace shows error in line 45 of auth.py
# The function is trying to extract user_id from JWT token
# Help me fix this error and handle missing claims gracefully
```

### Performance Optimization
```python
# This function takes 5 seconds for 1000 items
# Profile shows bottleneck in database queries
# Optimize using batch operations and caching
# Maintain same interface and behavior
```

## Real-World Examples

### API Endpoint Creation
```python
# Create a FastAPI endpoint for user registration that:
# - Accepts email, password, full_name
# - Validates email format
# - Checks if email already exists
# - Hashes password with bcrypt
# - Stores in PostgreSQL database
# - Returns user object without password
# - Handles database errors gracefully
# - Includes OpenAPI documentation
```

### Data Processing Pipeline
```python
# Build a data pipeline that:
# 1. Reads CSV files from Azure Blob Storage
# 2. Validates data schema against predefined rules
# 3. Transforms dates to ISO format
# 4. Aggregates by customer_id
# 5. Enriches with external API data
# 6. Writes results to Cosmos DB
# Use async/await for performance
# Log progress at each stage
```

### Security Implementation
```python
# Implement JWT authentication middleware that:
# - Extracts token from Authorization header
# - Validates token signature with RS256
# - Checks token expiration
# - Extracts user claims
# - Caches validation results for 5 minutes
# - Handles missing/invalid tokens
# - Integrates with FastAPI dependency injection
```

## Tips for Each Experience Level

### Beginners
- Start with simple, single-purpose functions
- Use examples liberally
- Break complex tasks into steps
- Ask for explanations in comments

### Intermediate
- Focus on integration patterns
- Request error handling explicitly
- Ask for performance considerations
- Specify testing requirements

### Advanced
- Request architectural patterns
- Ask for scalability considerations
- Specify concurrency requirements
- Include monitoring/observability

## Prompt Templates

### Function Creation
```
Create a [language] function named [name] that:
- Accepts: [input parameters with types]
- Returns: [return type and format]
- Behavior: [what it should do]
- Constraints: [performance, security, etc.]
- Error handling: [how to handle failures]
- Include: [tests/docs/examples]
```

### Class Design
```
Design a [language] class for [purpose] with:
- Properties: [list of attributes]
- Methods: [list of operations]
- Initialization: [constructor requirements]
- Validation: [input validation rules]
- Thread safety: [if applicable]
- Example usage: [how it will be used]
```

### System Architecture
```
Architect a system for [purpose] that:
- Handles: [load/scale requirements]
- Integrates with: [external systems]
- Security: [authentication/authorization]
- Data flow: [how data moves through system]
- Failure modes: [how to handle failures]
- Deployment: [where/how it runs]
```

## Remember

1. **Iterate**: First prompt rarely perfect
2. **Experiment**: Try different approaches
3. **Learn**: Save effective prompts
4. **Adapt**: Adjust to Copilot's updates
5. **Combine**: Use multiple techniques together

The best prompt is one that clearly communicates your intent while providing enough context for accurate assistance.

---

💡 **Pro Tip**: Create a personal prompt library for common tasks in your domain. This will speed up your development significantly!
