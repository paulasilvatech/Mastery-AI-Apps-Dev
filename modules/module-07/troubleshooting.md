# Troubleshooting Guide - Module 07

## 🔍 Overview

This guide helps you resolve common issues when building web applications with AI. Solutions are organized by category for quick reference.

## 🤖 GitHub Copilot Issues

### Copilot Not Providing Suggestions

**Symptoms:**
- No code completions appearing
- Gray Copilot icon in status bar
- "GitHub Copilot is not available" message

**Solutions:**

1. **Check Copilot Status**
   ```bash
   # In VS Code, check bottom status bar
   # Should show "GitHub Copilot" not "GitHub Copilot (Off)"
   ```

2. **Verify Subscription**
   - Visit https://github.com/settings/copilot
   - Ensure subscription is active
   - Check if organization allows Copilot

3. **Re-authenticate**
   ```bash
   # Command Palette (Cmd/Ctrl + Shift + P)
   > GitHub Copilot: Sign Out
   > GitHub Copilot: Sign In
   ```

4. **Reset VS Code**
   - Disable all extensions except Copilot
   - Restart VS Code
   - Re-enable extensions one by one

### Poor Quality Suggestions

**Problem:** Copilot suggestions are irrelevant or low quality

**Solutions:**

1. **Improve Context**
   ```javascript
   // ❌ Poor context
   // function

   // ✅ Good context
   // Create a function that validates email addresses
   // Should return true for valid emails, false otherwise
   // Examples: user@email.com (valid), user@.com (invalid)
   function validateEmail(email) {
   ```

2. **Clear File Context**
   - Remove unnecessary comments
   - Keep related code together
   - Use consistent naming

3. **Use Type Hints**
   ```python
   # Python with type hints
   def calculate_recipe_time(
       prep_time: int, 
       cook_time: int
   ) -> dict[str, int]:
   ```

## 🌐 Frontend Issues

### React App Not Starting

**Error:** `Module not found` or `Cannot resolve dependency`

**Solutions:**

1. **Clean Install**
   ```bash
   rm -rf node_modules package-lock.json
   npm install
   ```

2. **Clear Cache**
   ```bash
   npm cache clean --force
   ```

3. **Check Node Version**
   ```bash
   node --version  # Should be 18.x or higher
   nvm use 18      # If using nvm
   ```

### CORS Errors

**Error:** `Access to fetch at 'http://localhost:8000' from origin 'http://localhost:5173' has been blocked by CORS policy`

**Solutions:**

1. **Backend Fix (FastAPI)**
   ```python
   from fastapi.middleware.cors import CORSMiddleware

   app.add_middleware(
       CORSMiddleware,
       allow_origins=["http://localhost:5173", "http://localhost:3000"],
       allow_credentials=True,
       allow_methods=["*"],
       allow_headers=["*"],
   )
   ```

2. **Development Proxy (Vite)**
   ```javascript
   // vite.config.js
   export default {
     server: {
       proxy: {
         '/api': {
           target: 'http://localhost:8000',
           changeOrigin: true,
         }
       }
     }
   }
   ```

### State Not Updating

**Problem:** UI not reflecting state changes

**Solutions:**

1. **Avoid Direct Mutation**
   ```javascript
   // ❌ Wrong - Direct mutation
   const addTodo = (todo) => {
     todos.push(todo)
     setTodos(todos)
   }

   // ✅ Correct - New array
   const addTodo = (todo) => {
     setTodos([...todos, todo])
   }
   ```

2. **Use Functional Updates**
   ```javascript
   // When state depends on previous state
   setCount(prevCount => prevCount + 1)
   ```

### Tailwind Classes Not Working

**Problem:** Tailwind styles not applying

**Solutions:**

1. **Check Configuration**
   ```javascript
   // tailwind.config.js
   module.exports = {
     content: [
       "./index.html",
       "./src/**/*.{js,ts,jsx,tsx}",  // Ensure all files included
     ],
   }
   ```

2. **Import CSS**
   ```css
   /* src/index.css or App.css */
   @tailwind base;
   @tailwind components;
   @tailwind utilities;
   ```

3. **Restart Dev Server**
   ```bash
   # Ctrl+C to stop
   npm run dev
   ```

## 🔧 Backend Issues

### FastAPI Not Starting

**Error:** `ModuleNotFoundError` or `Import Error`

**Solutions:**

1. **Activate Virtual Environment**
   ```bash
   # Windows
   venv\Scripts\activate

   # macOS/Linux
   source venv/bin/activate
   ```

2. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   # or
   pip install fastapi uvicorn sqlalchemy python-dotenv
   ```

3. **Check Python Version**
   ```bash
   python --version  # Should be 3.9+
   ```

### Database Connection Errors

**Error:** `sqlalchemy.exc.OperationalError`

**Solutions:**

1. **SQLite Issues**
   ```python
   # Use absolute path for SQLite
   import os
   BASE_DIR = os.path.dirname(os.path.abspath(__file__))
   DATABASE_URL = f"sqlite:///{os.path.join(BASE_DIR, 'app.db')}"
   ```

2. **Create Tables**
   ```python
   # In main.py
   from database import engine, Base
   Base.metadata.create_all(bind=engine)
   ```

3. **PostgreSQL Connection**
   ```python
   # Check connection string format
   DATABASE_URL = "postgresql://user:password@localhost:5432/dbname"
   ```

### API Endpoint 404

**Problem:** Endpoints returning 404

**Solutions:**

1. **Check Route Registration**
   ```python
   # Ensure routes are included
   app.include_router(recipe_router, prefix="/api")
   ```

2. **Verify URL Path**
   ```bash
   # Check exact path in browser
   http://localhost:8000/docs  # FastAPI auto-docs
   ```

3. **Debug Routes**
   ```python
   # List all routes
   for route in app.routes:
       print(f"{route.methods} {route.path}")
   ```

## 🤖 AI Integration Issues

### OpenAI API Errors

**Error:** `openai.error.AuthenticationError`

**Solutions:**

1. **Check API Key**
   ```python
   import os
   print(os.getenv("OPENAI_API_KEY"))  # Should not be None
   ```

2. **Load Environment Variables**
   ```python
   from dotenv import load_dotenv
   load_dotenv()  # Must be before accessing env vars
   ```

3. **Verify .env File**
   ```bash
   # .env file in project root
   OPENAI_API_KEY=sk-...your-key-here
   ```

### Rate Limit Errors

**Error:** `openai.error.RateLimitError`

**Solutions:**

1. **Implement Retry Logic**
   ```python
   import time
   from tenacity import retry, wait_exponential, stop_after_attempt

   @retry(
       wait=wait_exponential(multiplier=1, min=4, max=10),
       stop=stop_after_attempt(3)
   )
   async def call_openai(prompt):
       return await openai.Completion.create(...)
   ```

2. **Add Rate Limiting**
   ```python
   from slowapi import Limiter
   limiter = Limiter(key_func=get_remote_address)

   @app.post("/api/generate")
   @limiter.limit("5/minute")
   async def generate_content(request: Request):
   ```

### AI Response Quality Issues

**Problem:** Poor or inconsistent AI responses

**Solutions:**

1. **Improve Prompts**
   ```python
   # Be specific and provide examples
   prompt = """
   Create a recipe using these ingredients: {ingredients}
   
   Format the response as JSON with these fields:
   - title: string
   - cookTime: number (minutes)
   - ingredients: array of {item: string, amount: string}
   - instructions: array of strings
   
   Example:
   {
     "title": "Pasta Primavera",
     "cookTime": 30,
     ...
   }
   """
   ```

2. **Temperature Settings**
   ```python
   # Lower = more consistent, Higher = more creative
   response = openai.Completion.create(
       temperature=0.7,  # Adjust between 0-1
       max_tokens=500
   )
   ```

## 🚀 Deployment Issues

### Build Failures

**Error:** `npm run build` fails

**Solutions:**

1. **Fix TypeScript Errors**
   ```bash
   # Check for TS errors
   npx tsc --noEmit
   ```

2. **Environment Variables**
   ```javascript
   // Use correct prefix for Vite
   const API_URL = import.meta.env.VITE_API_URL
   ```

3. **Clear Build Cache**
   ```bash
   rm -rf dist .vite node_modules/.vite
   npm run build
   ```

### Deployment Environment Issues

**Problem:** Works locally but not in production

**Solutions:**

1. **Environment Variables**
   ```bash
   # Vercel/Netlify: Add in dashboard
   # Railway: Add in settings
   # Don't forget VITE_ prefix for frontend
   ```

2. **API URLs**
   ```javascript
   // Use environment-specific URLs
   const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'
   ```

3. **Build Commands**
   ```json
   // package.json
   {
     "scripts": {
       "build": "vite build",
       "preview": "vite preview"  // Test production build
     }
   }
   ```

## 🛠️ Performance Issues

### Slow API Responses

**Solutions:**

1. **Add Caching**
   ```python
   from functools import lru_cache

   @lru_cache(maxsize=100)
   def get_cached_data(key):
       return expensive_operation(key)
   ```

2. **Database Indexes**
   ```python
   class Recipe(Base):
       title = Column(String, index=True)
       created_at = Column(DateTime, index=True)
   ```

3. **Optimize Queries**
   ```python
   # Eager loading
   recipes = db.query(Recipe).options(
       joinedload(Recipe.ingredients)
   ).all()
   ```

### Frontend Performance

**Solutions:**

1. **Lazy Loading**
   ```javascript
   const HeavyComponent = lazy(() => import('./HeavyComponent'))
   ```

2. **Debounce User Input**
   ```javascript
   const debouncedSearch = useMemo(
     () => debounce(handleSearch, 500),
     []
   )
   ```

3. **Optimize Images**
   ```javascript
   // Use appropriate sizes
   <img 
     srcSet="small.jpg 300w, medium.jpg 768w, large.jpg 1200w"
     sizes="(max-width: 300px) 300px, (max-width: 768px) 768px, 1200px"
     loading="lazy"
   />
   ```

## 💡 General Debugging Tips

### 1. Check Browser Console
```javascript
// Add debug logs
console.log('State:', { todos, loading, error })
```

### 2. Network Tab
- Check API calls
- Verify request/response payloads
- Look for failed requests

### 3. React DevTools
- Inspect component props/state
- Check component re-renders
- Profile performance

### 4. Backend Logs
```python
# Add logging
import logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

logger.debug(f"Received request: {request_data}")
```

### 5. Database Inspection
```bash
# SQLite
sqlite3 app.db
.tables
.schema recipes

# PostgreSQL
psql -d yourdb
\dt
\d recipes
```

## 🆘 Still Stuck?

1. **Search Specific Error**
   - Copy exact error message
   - Search on Stack Overflow
   - Check GitHub issues

2. **Minimal Reproduction**
   - Create smallest example that shows problem
   - Remove unrelated code
   - Share in forums

3. **Community Help**
   - Course discussion forum
   - Stack Overflow with proper tags
   - Framework-specific Discord/Slack

4. **AI Debugging**
   ```
   "I'm getting this error: [paste error]
   Here's my code: [paste relevant code]
   What could be causing this?"
   ```

Remember: Most errors have been encountered before. Stay calm, read error messages carefully, and work through solutions systematically!