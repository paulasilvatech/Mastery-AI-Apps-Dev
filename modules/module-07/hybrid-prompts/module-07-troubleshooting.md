# Module 07 - Comprehensive Troubleshooting Guide

## 🔧 Overview

This guide helps you resolve common issues encountered in Module 07 exercises, covering both GitHub Copilot approaches and web development challenges.

## 🤖 GitHub Copilot Issues

### Code Suggestions Not Appearing

#### Symptoms
- No inline suggestions when typing
- Tab key doesn't complete code
- Ghost text not showing

#### Solutions

```markdown
# Copilot Agent Prompt:
Help me troubleshoot GitHub Copilot code suggestions:

1. Check Copilot status in VS Code
2. Verify subscription is active
3. Test with a simple JavaScript function
4. Check network connectivity
5. Review VS Code settings

Provide diagnostic commands and fixes.
```

**Manual Steps:**
1. Check status bar: Look for Copilot icon
2. Run command: `GitHub Copilot: Status`
3. Verify settings:
   ```json
   {
     "github.copilot.enable": {
       "*": true,
       "javascript": true,
       "python": true,
       "markdown": true
     }
   }
   ```
4. Restart VS Code
5. Sign out and back into GitHub

### Agent Mode (Chat) Not Responding

#### Symptoms
- Chat window opens but no responses
- "Thinking" indicator stuck
- Error messages in chat

#### Solutions
1. **Check Extension Version**
   ```bash
   code --list-extensions --show-versions | grep copilot
   # Should show latest versions
   ```

2. **Clear Chat Context**
   - Click "New Chat" button
   - Start with simpler prompt
   - Avoid very long prompts initially

3. **Network Issues**
   - Check proxy settings
   - Verify firewall allows GitHub
   - Test with mobile hotspot

## 🎨 Frontend Issues (React/Vite)

### Vite Dev Server Not Starting

#### Symptom
```
Error: Cannot find module 'vite'
```

#### Solutions
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install

# If still failing, try with legacy peer deps
npm install --legacy-peer-deps

# Check Node version (must be 16+)
node --version
```

### React Component Not Rendering

#### Symptom
- Blank page
- Console errors about mounting

#### Debugging Steps
```javascript
// Add console logs to debug
console.log('Component mounting...');

// Check if root element exists
const root = document.getElementById('root');
if (!root) {
  console.error('Root element not found!');
}

// Verify imports
import React from 'react'; // Sometimes needed explicitly
```

### Tailwind CSS Not Working

#### Symptom
- Classes not applying
- No styling visible

#### Solutions
```bash
# Ensure Tailwind is configured
npx tailwindcss init -p

# Check tailwind.config.js
module.exports = {
  content: [
    "./index.html",
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  // ... rest of config
}

# Verify CSS import in main.jsx
import './index.css'
```

### CORS Errors with Backend

#### Symptom
```
Access to fetch at 'http://localhost:8000' from origin 'http://localhost:5173' has been blocked by CORS policy
```

#### Solutions

**Frontend proxy configuration:**
```javascript
// vite.config.js
export default {
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, '')
      }
    }
  }
}
```

**Backend CORS configuration:**
```python
# FastAPI backend
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## 🐍 Backend Issues (Python/FastAPI)

### FastAPI Import Errors

#### Symptom
```
ModuleNotFoundError: No module named 'fastapi'
```

#### Solutions
```bash
# Ensure virtual environment is activated
# Windows
.\venv\Scripts\activate
# Mac/Linux
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt

# Or install manually
pip install fastapi uvicorn[standard] sqlalchemy
```

### Database Connection Issues

#### Symptom
```
sqlalchemy.exc.OperationalError: unable to open database file
```

#### Solutions
```python
# Check database URL format
DATABASE_URL = "sqlite:///./todos.db"  # Note the three slashes

# Ensure directory exists
import os
os.makedirs("data", exist_ok=True)
DATABASE_URL = "sqlite:///./data/todos.db"

# For absolute paths
import os
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATABASE_URL = f"sqlite:///{BASE_DIR}/todos.db"
```

### Uvicorn Not Starting

#### Symptom
```
Error: No module named 'main'
```

#### Solutions
```bash
# Ensure you're in the correct directory
cd backend

# Check file exists
ls main.py

# Run with full path
python -m uvicorn main:app --reload

# Or specify host and port
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Pydantic Validation Errors

#### Symptom
```
pydantic.error_wrappers.ValidationError
```

#### Solutions
```python
# Add validation to models
from pydantic import BaseModel, validator

class TodoCreate(BaseModel):
    title: str
    completed: bool = False
    
    @validator('title')
    def title_not_empty(cls, v):
        if not v.strip():
            raise ValueError('Title cannot be empty')
        return v
```

## 🤖 OpenAI API Issues (Exercise 3)

### API Key Not Working

#### Symptom
```
openai.error.AuthenticationError: Invalid API key
```

#### Solutions
```python
# Check .env file format
OPENAI_API_KEY=sk-...  # No quotes!

# Verify loading
from dotenv import load_dotenv
import os

load_dotenv()
api_key = os.getenv("OPENAI_API_KEY")
print(f"Key loaded: {api_key[:8]}...")  # Show first 8 chars only

# Test directly
import openai
openai.api_key = "sk-..."  # For testing only!
```

### Rate Limit Errors

#### Symptom
```
openai.error.RateLimitError: Rate limit exceeded
```

#### Solutions
```python
# Implement retry logic
import time
from tenacity import retry, wait_exponential, stop_after_attempt

@retry(
    wait=wait_exponential(multiplier=1, min=4, max=10),
    stop=stop_after_attempt(3)
)
def call_openai_api():
    # Your API call here
    pass

# Add rate limiting
from slowapi import Limiter
limiter = Limiter(key_func=lambda: "global")

@app.post("/generate")
@limiter.limit("5/minute")
async def generate_recipe(request: Request):
    # Your endpoint logic
```

### High API Costs

#### Prevention Strategies
```python
# Use cheaper models for testing
model = "gpt-3.5-turbo"  # Instead of gpt-4

# Limit token usage
max_tokens = 500  # Reasonable for recipes

# Cache responses
from functools import lru_cache

@lru_cache(maxsize=100)
def generate_cached_response(prompt_hash):
    # Generate only if not cached
    pass

# Add cost estimation
def estimate_cost(prompt, max_tokens):
    prompt_tokens = len(prompt.split()) * 1.3  # Rough estimate
    total_tokens = prompt_tokens + max_tokens
    cost = (total_tokens / 1000) * 0.002  # GPT-3.5 pricing
    return cost
```

## 🚀 Deployment Issues

### Build Failures

#### Symptom
```
npm run build
> vite build
error during build:
```

#### Solutions
```bash
# Clear cache and rebuild
rm -rf dist node_modules package-lock.json
npm install
npm run build

# Check for TypeScript errors
npx tsc --noEmit

# Look for import issues
# Ensure all imports use correct extensions
import Component from './Component' // ❌
import Component from './Component.jsx' // ✅
```

### Environment Variables Not Working in Production

#### Solutions
```javascript
// For Vite apps, use import.meta.env
const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8000'

// Build with env vars
VITE_API_URL=https://api.production.com npm run build
```

## 🛠️ General Debugging Techniques

### Enable Verbose Logging

**Frontend:**
```javascript
// Add debug logging
if (import.meta.env.DEV) {
  console.log('Debug mode enabled');
  window.DEBUG = true;
}

// Use conditional logging
window.DEBUG && console.log('Detailed info:', data);
```

**Backend:**
```python
# Enable FastAPI debug mode
app = FastAPI(debug=True)

# Add logging
import logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

@app.post("/api/todos")
async def create_todo(todo: TodoCreate):
    logger.debug(f"Creating todo: {todo}")
    # ... rest of function
```

### Browser DevTools Tips

1. **Network Tab**
   - Check request/response headers
   - Verify payload format
   - Look for CORS issues

2. **Console Errors**
   - Expand error stack traces
   - Look for the originating file
   - Check for typos in imports

3. **React DevTools**
   - Install React DevTools extension
   - Inspect component props and state
   - Track re-renders

### Performance Issues

#### Slow Frontend
```javascript
// Use React.memo for expensive components
const ExpensiveComponent = React.memo(({ data }) => {
  // Component logic
});

// Implement virtualization for long lists
import { FixedSizeList } from 'react-window';

// Lazy load components
const HeavyComponent = React.lazy(() => import('./HeavyComponent'));
```

#### Slow API Responses
```python
# Add caching
from functools import lru_cache

@lru_cache(maxsize=100)
def expensive_operation(param):
    # Cached operation
    pass

# Use async operations
async def fetch_data():
    # Async DB queries
    pass

# Add pagination
@app.get("/todos")
async def get_todos(skip: int = 0, limit: int = 10):
    return todos[skip:skip + limit]
```

## 🔍 Diagnostic Scripts

### Health Check Script

Create `check-health.sh`:
```bash
#!/bin/bash

echo "🏥 Running Module 07 Health Check..."

# Check frontend
echo -n "Frontend (http://localhost:5173): "
curl -s -o /dev/null -w "%{http_code}" http://localhost:5173 || echo "Not running"

# Check backend
echo -n "Backend (http://localhost:8000): "
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/docs || echo "Not running"

# Check API endpoint
echo -n "API Health: "
curl -s http://localhost:8000/health || echo "Not available"

# Check disk space
echo "Disk usage:"
df -h . | tail -1

# Check memory
echo "Memory usage:"
free -h 2>/dev/null || vm_stat 2>/dev/null || echo "Not available"
```

## 🆘 Getting Additional Help

### Resources
1. **Module Discussions**: GitHub Discussions for peer help
2. **Office Hours**: Weekly instructor sessions
3. **Slack Channel**: #module-07-help
4. **Documentation**: 
   - [React Docs](https://react.dev)
   - [FastAPI Docs](https://fastapi.tiangolo.com)
   - [Vite Docs](https://vitejs.dev)

### Diagnostic Information to Collect

When asking for help, include:
```bash
# System info
uname -a  # or systeminfo on Windows
node --version
python --version
npm --version

# Error context
# Copy the full error message
# Include relevant code snippets
# Share browser console errors
# Provide network request details
```

## ✅ Prevention Tips

1. **Always use virtual environments for Python**
2. **Keep dependencies up to date**
3. **Use consistent Node versions (nvm)**
4. **Test in incognito mode (cache issues)**
5. **Commit working code frequently**
6. **Read error messages carefully**
7. **Check the browser console first**

---

**Still stuck?** Don't hesitate to ask for help in the workshop discussions. Include error messages, what you've tried, and diagnostic information for faster resolution!