# Troubleshooting Guide - Module 05

## 🔧 Common Issues and Solutions

### Documentation Generation Issues

#### Problem: AST Parsing Fails
**Symptoms**: 
- `SyntaxError` when parsing Python files
- Documentation generator crashes

**Solutions**:
```python
# 1. Check Python version compatibility
import sys
print(f"Python version: {sys.version}")
# Ensure using Python 3.11+

# 2. Handle encoding issues
def parse_file_safe(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return ast.parse(f.read())
    except UnicodeDecodeError:
        # Try with different encoding
        with open(filepath, 'r', encoding='latin-1') as f:
            return ast.parse(f.read())

# 3. Skip files with syntax errors
def parse_with_fallback(filepath):
    try:
        return ast.parse(filepath.read_text())
    except SyntaxError as e:
        print(f"Skipping {filepath}: {e}")
        return None
```

#### Problem: Docstring Format Not Recognized
**Symptoms**:
- Generated docstrings look wrong
- Format doesn't match style guide

**Solutions**:
```python
# Explicitly set docstring style
generator = DocumentationGenerator(style=DocStyle.GOOGLE)

# Validate format
def validate_docstring_format(docstring: str, style: DocStyle) -> bool:
    if style == DocStyle.GOOGLE:
        return "Args:" in docstring and "Returns:" in docstring
    elif style == DocStyle.NUMPY:
        return "Parameters\n----------" in docstring
    elif style == DocStyle.SPHINX:
        return ":param" in docstring
```

### Refactoring Issues

#### Problem: Refactoring Breaks Code
**Symptoms**:
- Tests fail after refactoring
- Import errors or undefined variables

**Solutions**:
```python
# 1. Always create backup
import shutil
shutil.copy2(original_file, f"{original_file}.backup")

# 2. Validate refactored code
def validate_refactoring(original: str, refactored: str) -> bool:
    # Parse both versions
    try:
        original_ast = ast.parse(original)
        refactored_ast = ast.parse(refactored)
    except SyntaxError:
        return False
    
    # Check imports preserved
    original_imports = extract_imports(original_ast)
    refactored_imports = extract_imports(refactored_ast)
    
    if original_imports != refactored_imports:
        print("Warning: Imports changed!")
        return False
    
    return True

# 3. Test in isolated environment
def test_refactoring_safe(code: str):
    with tempfile.NamedTemporaryFile(mode='w', suffix='.py') as f:
        f.write(code)
        f.flush()
        
        # Run tests on temp file
        result = subprocess.run(
            [sys.executable, '-m', 'pytest', f.name],
            capture_output=True
        )
        return result.returncode == 0
```

#### Problem: Complex Code Not Refactored
**Symptoms**:
- Refactoring skipped for complex functions
- "Unable to refactor" messages

**Solutions**:
```python
# Break down complex refactorings
class IncrementalRefactoring:
    """Apply refactorings incrementally."""
    
    def refactor_complex_function(self, func_code: str):
        steps = [
            self.extract_validation,
            self.simplify_conditionals,
            self.extract_calculations,
            self.remove_duplication
        ]
        
        current_code = func_code
        for step in steps:
            try:
                current_code = step(current_code)
                # Validate after each step
                if not self.is_valid(current_code):
                    return previous_code
                previous_code = current_code
            except Exception as e:
                print(f"Step {step.__name__} failed: {e}")
                continue
                
        return current_code
```

### Quality System Issues

#### Problem: High Memory Usage
**Symptoms**:
- System slows down over time
- Memory errors on large projects

**Solutions**:
```python
# 1. Process files in batches
async def analyze_large_project(project_path: Path):
    python_files = list(project_path.rglob("*.py"))
    batch_size = 50
    
    for i in range(0, len(python_files), batch_size):
        batch = python_files[i:i + batch_size]
        await analyze_batch(batch)
        
        # Force garbage collection
        import gc
        gc.collect()

# 2. Use streaming for large files
async def analyze_large_file(filepath: Path):
    metrics = QualityMetrics()
    
    async with aiofiles.open(filepath, 'r') as f:
        chunk_size = 1000  # lines
        lines = []
        
        async for line in f:
            lines.append(line)
            
            if len(lines) >= chunk_size:
                # Process chunk
                await process_code_chunk(''.join(lines))
                lines = []
        
        # Process remaining
        if lines:
            await process_code_chunk(''.join(lines))

# 3. Limit concurrent operations
semaphore = asyncio.Semaphore(5)  # Max 5 concurrent

async def analyze_with_limit(filepath):
    async with semaphore:
        return await analyze_file(filepath)
```

#### Problem: Dashboard Not Updating
**Symptoms**:
- Real-time updates not showing
- WebSocket connection errors

**Solutions**:
```python
# 1. Check WebSocket connection
class WebSocketDebugger:
    def __init__(self, socketio):
        self.socketio = socketio
        self.socketio.on_error_default(self.error_handler)
    
    def error_handler(self, e):
        print(f"WebSocket error: {e}")
        # Log full traceback
        import traceback
        traceback.print_exc()

# 2. Implement reconnection logic
const socket = io({
    reconnection: true,
    reconnectionDelay: 1000,
    reconnectionAttempts: 5
});

socket.on('connect_error', (error) => {
    console.log('Connection failed:', error);
    // Show offline indicator
});

# 3. Debug CORS issues
app = Flask(__name__)
CORS(app, origins=['http://localhost:3000'])
socketio = SocketIO(app, cors_allowed_origins="*", logger=True)
```

### CI/CD Integration Issues

#### Problem: GitHub Actions Failing
**Symptoms**:
- Quality checks fail in CI but pass locally
- "Command not found" errors

**Solutions**:
```yaml
# 1. Ensure proper setup in workflow
name: Quality Check
on: [push, pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
          
      - name: Cache dependencies
        uses: actions/cache@v3
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('requirements.txt') }}
          
      - name: Install dependencies
        run: |
          pip install --upgrade pip
          pip install -r requirements.txt
          pip install -e .  # Install package
          
      - name: Run quality checks
        run: |
          # Ensure module is importable
          python -c "import quality_system; print('Import successful')"
          python -m quality_system analyze .
```

### Performance Issues

#### Problem: Slow Analysis
**Symptoms**:
- Analysis takes too long
- Timeouts on large files

**Solutions**:
```python
# 1. Use caching
from functools import lru_cache
import hashlib

class CachedAnalyzer:
    def __init__(self):
        self.cache = {}
    
    def get_file_hash(self, filepath: Path) -> str:
        """Get hash of file content."""
        content = filepath.read_bytes()
        return hashlib.md5(content).hexdigest()
    
    async def analyze_with_cache(self, filepath: Path):
        file_hash = self.get_file_hash(filepath)
        
        if file_hash in self.cache:
            print(f"Using cached results for {filepath}")
            return self.cache[file_hash]
        
        result = await self.analyze_file(filepath)
        self.cache[file_hash] = result
        return result

# 2. Parallelize operations
async def analyze_parallel(files: List[Path]):
    # Limit concurrent operations
    sem = asyncio.Semaphore(10)
    
    async def analyze_limited(filepath):
        async with sem:
            return await analyze_file(filepath)
    
    tasks = [analyze_limited(f) for f in files]
    return await asyncio.gather(*tasks)

# 3. Skip unnecessary checks
def should_analyze(filepath: Path) -> bool:
    # Skip generated files
    if '__pycache__' in filepath.parts:
        return False
    if filepath.name.endswith('_pb2.py'):  # Protocol buffers
        return False
    if 'migrations' in filepath.parts:  # Django migrations
        return False
    return True
```

## 🐛 Debugging Techniques

### Enable Debug Logging
```python
import logging

# Configure detailed logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('quality_debug.log'),
        logging.StreamHandler()
    ]
)

# Add debug points
logger = logging.getLogger(__name__)

def analyze_code(code: str):
    logger.debug(f"Analyzing code of length: {len(code)}")
    try:
        result = perform_analysis(code)
        logger.debug(f"Analysis successful: {result}")
        return result
    except Exception as e:
        logger.error(f"Analysis failed: {e}", exc_info=True)
        raise
```

### Use Interactive Debugger
```python
# Add breakpoints for debugging
def complex_refactoring(code: str):
    import pdb
    
    # Set breakpoint
    pdb.set_trace()
    
    # Now you can inspect variables
    # n - next line
    # s - step into
    # c - continue
    # p variable - print variable
    
    result = refactor(code)
    return result
```

### Profile Performance
```python
import cProfile
import pstats

def profile_analysis():
    profiler = cProfile.Profile()
    profiler.enable()
    
    # Run analysis
    analyze_project(Path("my_project"))
    
    profiler.disable()
    
    # Print stats
    stats = pstats.Stats(profiler)
    stats.sort_stats('cumulative')
    stats.print_stats(20)  # Top 20 functions
```

## 🆘 Getting Help

### Check Logs
```bash
# View quality system logs
tail -f quality_system.log

# Check specific component
grep "ERROR" quality_system.log | tail -20

# View with context
grep -B 5 -A 5 "Exception" quality_system.log
```

### Diagnostic Commands
```bash
# Check system status
python -m quality_system status

# Validate configuration
python -m quality_system validate-config

# Test specific component
python -m quality_system test --component documentation

# Generate diagnostic report
python -m quality_system diagnose --output diagnostic.txt
```

### Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `ModuleNotFoundError: quality_system` | Package not installed | Run `pip install -e .` |
| `ast.parse() failed` | Invalid Python syntax | Check file with `python -m py_compile file.py` |
| `Connection refused` | Service not running | Start services with `docker-compose up` |
| `Out of memory` | Large project | Increase memory limit or use batching |
| `Permission denied` | File permissions | Check file ownership and permissions |

## 📞 Support Resources

- Module Slack Channel: #module-05-help
- GitHub Issues: [Report bugs](https://github.com/workshop/issues)
- Stack Overflow Tag: `quality-automation-system`
- Email Support: workshop-support@example.com

---

💡 **Remember**: Most issues can be solved by checking logs, validating input, and ensuring all dependencies are installed correctly.