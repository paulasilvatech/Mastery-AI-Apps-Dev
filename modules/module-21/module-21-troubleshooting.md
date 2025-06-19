# 🔧 Module 21: AI Agents Troubleshooting Guide

## Common Issues and Solutions

### 🚫 Agent Not Responding

#### Symptoms
- Agent methods return None
- No output from agent execution
- Timeouts without error messages

#### Solutions

1. **Check Agent Initialization**
```python
# ❌ Wrong
agent = CodeReviewAgent  # Missing parentheses

# ✅ Correct
agent = CodeReviewAgent()
```

2. **Verify Context Passing**
```python
# Ensure context has required fields
context = CodeContext(
    file_path="example.py",
    language="python",
    current_line=10,
    surrounding_code="def example(): pass",
    project_context={}  # Don't forget this!
)
```

3. **Enable Debug Logging**
```python
import logging
logging.basicConfig(level=logging.DEBUG)

# Now you'll see what the agent is doing
agent = CodeReviewAgent()
```

### 🔴 Import Errors

#### Error: "No module named 'agents'"
```bash
# Solution 1: Add src to Python path
export PYTHONPATH="${PYTHONPATH}:${PWD}/src"

# Solution 2: Install in development mode
pip install -e .

# Solution 3: Fix imports
# Instead of: from agents.base_agent import BaseAgent
# Use: from src.agents.base_agent import BaseAgent
```

#### Error: "Cannot import name 'BaseAgent'"
```python
# Check file structure
src/
├── __init__.py  # Must exist!
├── agents/
│   ├── __init__.py  # Must exist!
│   └── base_agent.py
```

### 🐍 AST Parsing Errors

#### Error: "SyntaxError in ast.parse()"
```python
# Problem: Invalid Python syntax
code = "def func() pass"  # Missing colon

# Solution: Validate syntax first
def safe_parse(code: str):
    try:
        return ast.parse(code)
    except SyntaxError as e:
        print(f"Syntax error at line {e.lineno}: {e.msg}")
        return None
```

#### Error: "AttributeError: 'NoneType' object has no attribute 'lineno'"
```python
# Problem: Not all AST nodes have line numbers
# Solution: Check before accessing
if hasattr(node, 'lineno'):
    line_number = node.lineno
else:
    line_number = 0  # or parent's line number
```

### 🔗 Integration Issues

#### GitHub Copilot Not Providing Suggestions
1. **Check Copilot Status**
```bash
gh copilot status
```

2. **Restart VS Code**
- Close all VS Code windows
- Clear VS Code cache: `rm -rf ~/.config/Code/Cache/*`
- Reopen VS Code

3. **Check File Type**
- Ensure file has proper extension (.py, .js, etc.)
- Check if language is set correctly in VS Code

#### Azure Connection Failures
```python
# Error: DefaultAzureCredential failed
# Solution: Login to Azure
import subprocess
subprocess.run(["az", "login"], check=True)

# Or use specific credential
from azure.identity import AzureCliCredential
credential = AzureCliCredential()
```

### ⚡ Performance Issues

#### Agent Running Slowly
1. **Profile the Code**
```python
import cProfile
import pstats

profiler = cProfile.Profile()
profiler.enable()

# Run your agent
agent.process_request(request)

profiler.disable()
stats = pstats.Stats(profiler)
stats.sort_stats('cumulative')
stats.print_stats(10)  # Top 10 slow functions
```

2. **Check for Redundant Operations**
```python
# ❌ Bad: Parsing multiple times
for item in items:
    tree = ast.parse(code)  # Parsing same code repeatedly
    process(tree, item)

# ✅ Good: Parse once
tree = ast.parse(code)
for item in items:
    process(tree, item)
```

3. **Use Caching**
```python
from functools import lru_cache

@lru_cache(maxsize=128)
def expensive_analysis(code: str) -> dict:
    # This will be cached
    return analyze(code)
```

### 🧪 Testing Failures

#### Tests Pass Individually but Fail Together
```python
# Problem: Shared state between tests
# Solution: Use fixtures and cleanup

import pytest

@pytest.fixture
def clean_agent():
    agent = TestAgent()
    yield agent
    # Cleanup after test
    agent.cleanup()
```

#### Mock Not Working
```python
# ❌ Wrong: Mocking wrong path
@patch('agents.external_api.call')

# ✅ Correct: Mock where it's used
@patch('src.agents.code_review_agent.external_api.call')
```

### 💾 Memory Issues

#### High Memory Usage
1. **Clear Large Objects**
```python
# After processing large data
del large_data
import gc
gc.collect()
```

2. **Use Generators**
```python
# ❌ Bad: Loading all at once
def get_all_files():
    return [process(f) for f in files]

# ✅ Good: Generator
def get_all_files():
    for f in files:
        yield process(f)
```

### 🔐 Security Errors

#### Permission Denied
```python
# Error: PermissionError when accessing files
# Solution: Check file permissions
import os
import stat

# Make file readable
os.chmod('file.py', stat.S_IRUSR | stat.S_IWUSR)

# Or run with appropriate permissions
# sudo python script.py  # Only if absolutely necessary
```

#### SSL Certificate Errors
```python
# For development only!
import ssl
ssl._create_default_https_context = ssl._create_unverified_context

# Better solution: Add certificates
import certifi
os.environ['SSL_CERT_FILE'] = certifi.where()
```

### 🔄 Async/Await Issues

#### "RuntimeError: This event loop is already running"
```python
# In Jupyter notebooks
import nest_asyncio
nest_asyncio.apply()

# Or use asyncio.create_task()
task = asyncio.create_task(agent.async_method())
```

#### Coroutine Never Awaited Warning
```python
# ❌ Wrong
result = agent.async_process(data)

# ✅ Correct
result = await agent.async_process(data)

# Or in sync context
result = asyncio.run(agent.async_process(data))
```

## 🛠️ Debugging Techniques

### 1. Strategic Print Debugging
```python
def debug_agent_execution():
    print(f"🔍 Starting agent execution")
    print(f"📊 Input data: {data[:100]}...")  # First 100 chars
    
    result = agent.process(data)
    
    print(f"✅ Execution complete")
    print(f"📈 Result metrics: {result.metrics}")
    
    return result
```

### 2. Interactive Debugging
```python
# Add breakpoint
import pdb; pdb.set_trace()

# Or use VS Code debugger
# Add this to launch.json:
{
    "name": "Debug Agent",
    "type": "python",
    "request": "launch",
    "program": "${workspaceFolder}/src/main.py",
    "console": "integratedTerminal",
    "env": {
        "PYTHONPATH": "${workspaceFolder}/src"
    }
}
```

### 3. Logging Best Practices
```python
import logging
import sys

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('agent.log'),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)

# Use structured logging
logger.info("Agent started", extra={
    "agent_type": "CodeReview",
    "version": "1.0.0",
    "config": config
})
```

## 🔍 Validation Scripts

### Quick Agent Health Check
```python
# scripts/health_check.py
def check_agent_health():
    checks = []
    
    # Check imports
    try:
        from src.agents.base_agent import BaseAgent
        checks.append(("✅", "Imports working"))
    except ImportError as e:
        checks.append(("❌", f"Import error: {e}"))
    
    # Check agent creation
    try:
        agent = CodeReviewAgent()
        checks.append(("✅", "Agent creation successful"))
    except Exception as e:
        checks.append(("❌", f"Agent creation failed: {e}"))
    
    # Check basic operation
    try:
        result = agent.analyze("def test(): pass")
        checks.append(("✅", "Basic operation working"))
    except Exception as e:
        checks.append(("❌", f"Operation failed: {e}"))
    
    # Print results
    print("\n🏥 Agent Health Check Results:")
    for status, message in checks:
        print(f"{status} {message}")
    
    return all(status == "✅" for status, _ in checks)

if __name__ == "__main__":
    healthy = check_agent_health()
    sys.exit(0 if healthy else 1)
```

## 📞 Getting Additional Help

If you're still stuck:

1. **Check Logs**: Always check logs first
   ```bash
   tail -f agent.log
   ```

2. **Minimal Reproduction**: Create smallest code that shows the problem
   ```python
   # minimal_repro.py
   from src.agents.base_agent import BaseAgent
   
   # Minimal code that demonstrates the issue
   agent = BaseAgent()
   # Error happens here
   ```

3. **System Information**: Gather environment details
   ```bash
   python --version
   pip list | grep -E "(ast|azure|openai)"
   echo $PYTHONPATH
   ```

4. **Community Support**:
   - Post in GitHub Discussions with:
     - Error message (full traceback)
     - Minimal reproduction code
     - System information
     - What you've already tried

## 🎯 Prevention Tips

1. **Always Use Virtual Environments**
   ```bash
   python -m venv venv
   source venv/bin/activate
   ```

2. **Pin Dependencies**
   ```txt
   # requirements.txt
   ast==0.0.2
   azure-identity==1.12.0
   openai==1.10.0
   ```

3. **Write Tests Early**
   - Test edge cases
   - Test error conditions
   - Test integrations

4. **Use Type Hints**
   ```python
   def process(data: str) -> Dict[str, Any]:
       # Type hints help catch errors early
       pass
   ```

Remember: Most issues have been encountered before. Don't hesitate to search error messages and check the documentation!