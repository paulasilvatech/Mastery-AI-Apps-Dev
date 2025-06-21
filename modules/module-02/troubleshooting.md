# Module 02 - Troubleshooting Guide

## 🔧 Common Issues and Solutions

This guide addresses specific issues you might encounter while working with GitHub Copilot's core features in Module 02.

## 📋 Table of Contents

1. [Suggestion Issues](#suggestion-issues)
2. [Multi-File Problems](#multi-file-problems)
3. [Performance Issues](#performance-issues)
4. [Context Problems](#context-problems)
5. [Mode-Specific Issues](#mode-specific-issues)
6. [Exercise-Specific Issues](#exercise-specific-issues)

## 1. Suggestion Issues

### 🚫 No Suggestions Appearing

**Symptoms:**
- Ghost text not showing
- Tab key does nothing
- No inline suggestions

**Solutions:**

1. **Check Copilot Status**
   ```bash
   gh copilot status
   ```
   
2. **Verify VS Code Settings**
   - Open Command Palette (Ctrl/Cmd + Shift + P)
   - Type "Preferences: Open Settings (JSON)"
   - Ensure these settings:
   ```json
   {
     "github.copilot.enable": {
       "*": true,
       "plaintext": false,
       "markdown": true,
       "scminput": false
     },
     "github.copilot.inlineSuggest.enable": true,
     "editor.inlineSuggest.enabled": true
   }
   ```

3. **Reset Copilot**
   - Command Palette → "GitHub Copilot: Reset Session"
   - Restart VS Code

### 🚫 Poor Quality Suggestions

**Symptoms:**
- Irrelevant completions
- Incorrect syntax
- Repetitive suggestions

**Solutions:**

1. **Improve Context**
   ```python
   # ❌ Poor context
   def calc(x, y):
       pass
   
   # ✅ Better context
   def calculate_monthly_compound_interest(
       principal: float, 
       annual_rate: float, 
       years: int
   ) -> float:
       """Calculate compound interest with monthly compounding."""
   ```

2. **Clear File Context**
   - Remove irrelevant code from file
   - Close unrelated files
   - Use focused workspaces

3. **Prime with Examples**
   ```python
   # Example: Convert "John Doe" -> {"first": "John", "last": "Doe"}
   def parse_full_name(full_name: str) -> dict:
       # Copilot will follow the example pattern
   ```

### 🚫 Suggestions in Wrong Language

**Symptoms:**
- JavaScript suggestions in Python file
- Mixed language completions

**Solutions:**

1. **Check File Extension**
   - Ensure correct extension (.py for Python)
   - Save unsaved files with proper extension

2. **Set Language Mode**
   - Click language indicator in status bar
   - Select correct language

3. **Clean Workspace**
   ```bash
   # Remove cache
   rm -rf .vscode/.copilot-cache
   ```

## 2. Multi-File Problems

### 🚫 Context Not Recognized Across Files

**Symptoms:**
- Copilot doesn't recognize imports
- Type hints from other files ignored
- Inconsistent patterns

**Solutions:**

1. **Open Related Files**
   ```bash
   # Open all related files
   code models/*.py services/*.py
   ```

2. **Use Split View**
   - View → Editor Layout → Two Columns
   - Keep related files visible

3. **Import Order**
   ```python
   # Put imports at top for better context
   from models.user import User
   from typing import List, Optional
   
   def get_users() -> List[User]:
       # Copilot now knows User type
   ```

### 🚫 Refactoring Not Synchronized

**Symptoms:**
- Changes in one file not reflected in suggestions
- Outdated method names suggested

**Solutions:**

1. **Save All Files**
   - File → Save All (Ctrl/Cmd + K, S)

2. **Refresh Copilot Context**
   - Close and reopen affected files
   - Or restart VS Code

3. **Use Find and Replace**
   - Ctrl/Cmd + Shift + F for project-wide changes

## 3. Performance Issues

### 🚫 Slow Suggestions

**Symptoms:**
- Long delay before suggestions
- VS Code becomes sluggish
- High CPU usage

**Solutions:**

1. **Reduce File Size**
   ```python
   # Split large files
   # Before: one 2000-line file
   # After: multiple 200-300 line modules
   ```

2. **Disable Unnecessary Extensions**
   - View → Extensions
   - Disable non-essential extensions

3. **Optimize Settings**
   ```json
   {
     "github.copilot.inlineSuggest.enableAutoCompletions": true,
     "github.copilot.editor.enableCodeActions": false,
     "editor.suggestOnTriggerCharacters": false
   }
   ```

### 🚫 Memory Issues

**Symptoms:**
- VS Code crashes
- "Out of memory" errors

**Solutions:**

1. **Increase Memory Limit**
   ```bash
   # In VS Code settings.json
   "files.maxMemoryForLargeFilesMB": 4096
   ```

2. **Close Unused Files**
   - Use Explorer → Close All Editors

3. **Restart Periodically**
   - Restart VS Code every few hours

## 4. Context Problems

### 🚫 Wrong Context Inferred

**Symptoms:**
- Suggestions for different framework
- Incorrect assumptions about code

**Solutions:**

1. **Explicit Context Comments**
   ```python
   # Using FastAPI framework with SQLAlchemy ORM
   # Following repository pattern
   from fastapi import FastAPI
   from sqlalchemy.orm import Session
   ```

2. **Remove Conflicting Code**
   - Delete or comment out old implementations
   - Clear misleading examples

3. **Use Type Annotations**
   ```python
   from typing import Protocol
   
   class Repository(Protocol):
       """Define expected interface clearly."""
   ```

### 🚫 Lost Context After Edit

**Symptoms:**
- Good suggestions suddenly stop
- Previously working patterns fail

**Solutions:**

1. **Undo/Redo Trick**
   - Ctrl/Cmd + Z (undo)
   - Ctrl/Cmd + Shift + Z (redo)
   - This can refresh context

2. **Rewrite Trigger Line**
   - Delete and retype the line before cursor
   - Helps Copilot re-analyze context

## 5. Mode-Specific Issues

### 🚫 Chat Mode Not Working

**Symptoms:**
- Chat panel empty
- No response to queries

**Solutions:**

1. **Check Chat Availability**
   - Ensure GitHub Copilot Chat extension installed
   - Verify subscription includes Chat

2. **Reset Chat Session**
   - Click "New Chat" button
   - Or Command Palette → "GitHub Copilot: New Chat"

### 🚫 Edit Mode Problems

**Symptoms:**
- Can't trigger multi-file edits
- Edit suggestions not applying

**Solutions:**

1. **Proper Selection**
   - Select complete code blocks
   - Include function signatures

2. **Clear Instructions**
   ```
   # Instead of: "refactor this"
   # Use: "Extract database logic into a repository class with save and get methods"
   ```

## 6. Exercise-Specific Issues

### 🚫 Exercise 1: Pattern Library Issues

**Problem**: Copilot suggests overly complex implementations

**Solution**:
```python
# Add complexity hints
# Simple implementation needed for learning
class Stack:
    """Basic stack with list backing. No thread safety needed."""
```

### 🚫 Exercise 2: Multi-File Refactoring Issues

**Problem**: Losing track of changes across files

**Solution**:
1. Use Git to track changes
   ```bash
   git add -A
   git commit -m "Before refactoring"
   ```

2. Work on one aspect at a time
   - First: Add type hints everywhere
   - Then: Extract common patterns
   - Finally: Reorganize structure

### 🚫 Exercise 3: Context Optimization Issues

**Problem**: Custom instructions not being followed

**Solution**:
1. **Verify .copilot/instructions.md**
   ```markdown
   # Ensure clear, specific instructions
   Always use type hints
   Follow PEP 8 strictly
   Include comprehensive error handling
   ```

2. **Reference in Code**
   ```python
   # Following project custom instructions:
   # - Type hints required
   # - Google-style docstrings
   ```

## 🔍 Diagnostic Tools

### VS Code Developer Tools
1. Help → Toggle Developer Tools
2. Check Console for errors
3. Look for Copilot-related messages

### Copilot Logs
```bash
# View Copilot logs
code ~/.copilot/logs/

# Check for error patterns
grep -i error ~/.copilot/logs/*.log
```

### Network Diagnostics
```bash
# Test GitHub connectivity
curl -I https://api.github.com

# Check proxy settings if behind firewall
echo $HTTP_PROXY
echo $HTTPS_PROXY
```

## 🆘 When All Else Fails

1. **Complete Reset**
   ```bash
   # Backup settings first
   cp -r ~/.vscode ~/.vscode-backup
   
   # Reset Copilot
   rm -rf ~/.copilot
   gh auth logout
   gh auth login
   ```

2. **Fresh Installation**
   - Uninstall Copilot extensions
   - Restart VS Code
   - Reinstall extensions
   - Re-authenticate

3. **Contact Support**
   - GitHub Support: https://support.github.com
   - Include:
     - VS Code version
     - Copilot extension version
     - Error messages
     - Steps to reproduce

## 📋 Prevention Checklist

- [ ] Keep VS Code updated
- [ ] Update Copilot extensions regularly
- [ ] Maintain clean, organized code
- [ ] Use version control
- [ ] Regular VS Code restarts
- [ ] Monitor system resources
- [ ] Follow coding conventions
- [ ] Clear, descriptive naming

---

**Remember**: Most Copilot issues are related to context. When in doubt, improve your code clarity and Copilot will perform better!