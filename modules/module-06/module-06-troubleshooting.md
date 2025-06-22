# Module 06 Troubleshooting Guide

## 🔧 Common Issues and Solutions

This guide addresses specific issues you might encounter while working with multi-file projects and GitHub Copilot workspace features.

## 🤖 Copilot Workspace Issues

### Issue: @workspace Command Not Working

**Symptoms:**
- Typing `@workspace` doesn't show any suggestions
- Error: "Workspace features not available"

**Solutions:**

1. **Verify VS Code is opened at project root:**
   ```bash
   # Close VS Code and reopen at the correct level
   cd /path/to/project-root
   code .
   ```

2. **Check Copilot Chat is enabled:**
   - Press `Ctrl+Shift+P` (Cmd+Shift+P on Mac)
   - Type "GitHub Copilot: Enable Chat"
   - Ensure it's activated

3. **Update extensions:**
   ```
   Extensions → Search "GitHub Copilot" → Update all
   ```

4. **Verify workspace trust:**
   - Check for "Restricted Mode" banner
   - Trust the workspace if prompted

### Issue: Copilot Not Recognizing File Relationships

**Symptoms:**
- Import suggestions are incorrect
- Cross-file references not working
- Context seems limited to current file

**Solutions:**

1. **Open related files in tabs:**
   ```python
   # Keep these files open when working on a service:
   - service_file.py (current)
   - related_model.py
   - repository.py
   - __init__.py files
   ```

2. **Use explicit imports:**
   ```python
   # Be specific in early files
   from src.models.product import Product  # Full path
   # Copilot will learn your structure
   ```

3. **Create workspace configuration:**
   ```json
   // .vscode/settings.json
   {
     "python.analysis.extraPaths": ["./src"],
     "python.autoComplete.extraPaths": ["./src"]
   }
   ```

### Issue: Edit Mode Not Selecting Multiple Files

**Symptoms:**
- Can only edit one file at a time
- Multi-file selection not working

**Solutions:**

1. **Correct selection method:**
   - Open Copilot Chat
   - Click "Edit" button
   - Hold Ctrl/Cmd while clicking files
   - Or use file picker dialog

2. **Alternative approach:**
   - Use `@workspace` in chat first
   - Then switch to Edit mode
   - Files mentioned will be pre-selected

## 🐍 Python Multi-File Issues

### Issue: Import Errors - "Module Not Found"

**Symptoms:**
```python
ImportError: No module named 'src.models'
```

**Solutions:**

1. **Add project root to Python path:**
   ```python
   # In your main.py or conftest.py
   import sys
   from pathlib import Path
   sys.path.append(str(Path(__file__).parent.parent))
   ```

2. **Use proper package structure:**
   ```
   src/
   ├── __init__.py  # Must exist!
   ├── models/
   │   ├── __init__.py  # Must exist!
   │   └── product.py
   ```

3. **Install package in development mode:**
   ```bash
   # Create setup.py in project root
   pip install -e .
   ```

### Issue: Circular Import Errors

**Symptoms:**
```python
ImportError: cannot import name 'X' from partially initialized module
```

**Solutions:**

1. **Use TYPE_CHECKING:**
   ```python
   from typing import TYPE_CHECKING
   
   if TYPE_CHECKING:
       from .product_service import ProductService
   ```

2. **Restructure dependencies:**
   ```python
   # Bad: Circular dependency
   # product_service.py imports from product_repository.py
   # product_repository.py imports from product_service.py
   
   # Good: One-way dependency
   # product_service.py imports from product_repository.py
   # product_repository.py has no service imports
   ```

3. **Use dependency injection:**
   ```python
   class ProductService:
       def __init__(self, repository):
           self.repository = repository
           # Don't import, receive as parameter
   ```

## 🔄 Multi-File Refactoring Issues

### Issue: Incomplete Refactoring Across Files

**Symptoms:**
- Some files missed during rename
- Inconsistent changes
- Broken imports after refactoring

**Solutions:**

1. **Use Copilot systematically:**
   ```
   @workspace find all references to OldClassName
   @workspace rename OldClassName to NewClassName in all files
   ```

2. **Verify changes:**
   ```bash
   # Search for old names
   grep -r "OldClassName" src/
   ```

3. **Fix imports manually if needed:**
   - Use Find & Replace (Ctrl+Shift+H)
   - Search in files for old references
   - Update one by one for safety

### Issue: Agent Mode Creating Incorrect Structure

**Symptoms:**
- Files created in wrong locations
- Incorrect file naming
- Missing __init__.py files

**Solutions:**

1. **Be specific in prompts:**
   ```
   # Bad: "Create a service"
   # Good: "Create src/services/product_service.py with ProductService class"
   ```

2. **Provide structure context:**
   ```
   # Show current structure first
   tree src/
   # Then ask for new files
   ```

## 🧪 Testing Issues

### Issue: Tests Can't Find Application Modules

**Symptoms:**
```python
pytest: ImportError: cannot import name 'ProductService'
```

**Solutions:**

1. **Configure pytest path:**
   ```ini
   # pytest.ini or pyproject.toml
   [tool.pytest.ini_options]
   pythonpath = ["."]
   testpaths = ["tests"]
   ```

2. **Add conftest.py:**
   ```python
   # tests/conftest.py
   import sys
   from pathlib import Path
   
   # Add src to path
   sys.path.insert(0, str(Path(__file__).parent.parent / "src"))
   ```

3. **Use proper test structure:**
   ```
   project/
   ├── src/
   │   └── services/
   │       └── product_service.py
   ├── tests/
   │   ├── conftest.py
   │   └── services/
   │       └── test_product_service.py
   ```

### Issue: Async Test Failures

**Symptoms:**
- "RuntimeError: There is no current event loop"
- Tests hang or timeout

**Solutions:**

1. **Use pytest-asyncio:**
   ```python
   # Install: pip install pytest-asyncio
   
   # In test file
   import pytest
   
   @pytest.mark.asyncio
   async def test_async_method():
       result = await async_function()
       assert result
   ```

2. **Configure async fixtures:**
   ```python
   # conftest.py
   import pytest
   import asyncio
   
   @pytest.fixture(scope="session")
   def event_loop():
       loop = asyncio.get_event_loop_policy().new_event_loop()
       yield loop
       loop.close()
   ```

## 💾 File Management Issues

### Issue: Too Many Files Open

**Symptoms:**
- VS Code becomes slow
- Copilot suggestions delayed
- Memory usage high

**Solutions:**

1. **Close unnecessary files:**
   - Right-click tab → "Close Others"
   - Keep only relevant files open

2. **Use workspace folders:**
   ```json
   // .code-workspace file
   {
     "folders": [
       {"path": "src"},
       {"path": "tests"}
     ]
   }
   ```

3. **Exclude large directories:**
   ```json
   // .vscode/settings.json
   {
     "files.exclude": {
       "**/node_modules": true,
       "**/.git": true,
       "**/venv": true
     }
   }
   ```

## 🔍 Copilot Context Issues

### Issue: Suggestions Not Relevant to Project

**Symptoms:**
- Generic code suggestions
- Ignoring project patterns
- Wrong coding style

**Solutions:**

1. **Create .copilot directory:**
   ```markdown
   # .copilot/instructions.md
   Project: Task Management System
   Language: Python 3.11
   Style: PEP 8
   Testing: pytest
   Patterns: Repository pattern, dependency injection
   ```

2. **Use consistent patterns:**
   ```python
   # Establish patterns early
   class BaseService:
       """All services inherit from this."""
       pass
   
   # Copilot will follow the pattern
   ```

3. **Provide context in prompts:**
   ```python
   # Create a ProductService following the same pattern as UserService
   # with dependency injection and async methods
   ```

## 🚀 Performance Issues

### Issue: Slow Multi-File Operations

**Symptoms:**
- Long delays in Edit mode
- Timeouts in Agent mode
- Incomplete operations

**Solutions:**

1. **Break down large operations:**
   ```
   # Instead of: "Refactor entire application"
   # Do: "Refactor models folder"
   # Then: "Update services to match new models"
   ```

2. **Reduce file scope:**
   - Select only necessary files
   - Work on one module at a time

3. **Clear VS Code cache:**
   ```bash
   # Clear extension cache
   rm -rf ~/.vscode/extensions/github.copilot-*
   # Reinstall extensions
   ```

## 📝 Documentation Issues

### Issue: Copilot Not Following Project Documentation Style

**Solutions:**

1. **Create documentation template:**
   ```python
   def example_function(param: str) -> dict:
       """Brief description.
       
       Args:
           param: Description of parameter.
           
       Returns:
           Description of return value.
           
       Raises:
           ValueError: When param is invalid.
       """
   ```

2. **Use consistent docstring format:**
   - Choose Google, NumPy, or Sphinx style
   - Stick to it throughout project

## 🆘 Emergency Fixes

### Complete Reset

If nothing else works:

1. **Close VS Code completely**
2. **Clear Copilot cache:**
   ```bash
   # macOS/Linux
   rm -rf ~/.config/github-copilot
   
   # Windows
   rmdir /s %APPDATA%\github-copilot
   ```
3. **Reinstall extensions:**
   - Uninstall GitHub Copilot
   - Uninstall GitHub Copilot Chat
   - Restart VS Code
   - Reinstall both extensions
4. **Re-authenticate:**
   - Sign out of GitHub
   - Sign back in
   - Verify Copilot subscription

## 📞 Getting Help

If issues persist:

1. **Check Copilot status:** https://githubstatus.com
2. **Review logs:**
   - View → Output → GitHub Copilot
3. **Report issues:** https://github.com/community/community
4. **Workshop discussions:** Use the repository discussions

---

**Remember:** Most issues are related to context and file organization. Keep your workspace clean and well-structured for best results!