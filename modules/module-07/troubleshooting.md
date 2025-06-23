# Module 07: Troubleshooting Guide

## 🔧 Common Issues and Solutions

### 🐍 Python/Backend Issues

#### FastAPI Server Won't Start
```bash
# Error: ModuleNotFoundError: No module named 'fastapi'
```
**Solution:**
```bash
cd backend
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt
```

#### Database Connection Errors
```bash
# Error: sqlalchemy.exc.OperationalError: unable to open database file
```
**Solution:**
1. Ensure you're in the backend directory
2. Check file permissions
3. Delete existing database and let it recreate:
```bash
rm todos.db
python run.py
```

#### CORS Errors in Browser Console
```
Access to fetch at 'http://localhost:8000' from origin 'http://localhost:5173' has been blocked by CORS policy
```
**Solution:**
Ensure CORS middleware is properly configured in `main.py`:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### ⚛️ React/Frontend Issues

#### Vite Dev Server Port Conflict
```bash
# Error: Port 5173 is already in use
```
**Solution:**
1. Kill the process using the port:
```bash
# macOS/Linux
lsof -ti:5173 | xargs kill -9

# Windows
netstat -ano | findstr :5173
taskkill /PID <PID> /F
```
2. Or use a different port:
```bash
npm run dev -- --port 3000
```

#### TypeScript Errors
```typescript
// Error: Property 'todo' does not exist on type 'never'
```
**Solution:**
1. Ensure all interfaces are properly defined
2. Check imports are correct
3. Restart TypeScript server in VS Code: `Cmd/Ctrl + Shift + P` → "TypeScript: Restart TS Server"

#### Tailwind CSS Not Working
**Symptoms:** Classes not applying, no styling
**Solution:**
1. Ensure Tailwind is imported in `index.css`:
```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```
2. Check `tailwind.config.js` content paths:
```javascript
content: [
  "./index.html",
  "./src/**/*.{js,ts,jsx,tsx}",
]
```
3. Restart dev server

### 🤖 GitHub Copilot Issues

#### Copilot Not Suggesting Code
**Solution:**
1. Check Copilot status: Click Copilot icon in status bar
2. Ensure you're signed in: `Cmd/Ctrl + Shift + P` → "GitHub Copilot: Sign In"
3. Check file type is supported (`.py`, `.ts`, `.tsx`, etc.)
4. Try explicit comment prompts:
```python
# Create a function that validates email addresses
```

#### Copilot Suggestions Are Irrelevant
**Solution:**
1. Provide more context in comments
2. Use descriptive variable/function names
3. Include type hints (Python) or TypeScript types
4. Break complex tasks into smaller prompts

### 🔌 WebSocket Issues (Exercise 3)

#### WebSocket Connection Fails
```javascript
// Error: WebSocket connection to 'ws://localhost:8000/ws' failed
```
**Solution:**
1. Ensure WebSocket endpoint is implemented in backend
2. Check if regular HTTP endpoints work first
3. Use correct WebSocket URL:
```javascript
const ws = new WebSocket('ws://localhost:8000/ws');
```

#### WebSocket Messages Not Received
**Solution:**
1. Check message format (must be JSON)
2. Ensure proper error handling:
```javascript
ws.onerror = (error) => console.error('WebSocket error:', error);
ws.onclose = (event) => console.log('WebSocket closed:', event);
```

### 🐳 Docker Issues

#### Docker Build Fails
```bash
# Error: docker: Cannot connect to the Docker daemon
```
**Solution:**
1. Ensure Docker Desktop is running
2. Check Docker service:
```bash
docker version
docker ps
```

#### Container Can't Connect to Database
**Solution:**
Use Docker networking:
```yaml
services:
  backend:
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/dbname
  db:
    image: postgres:15
```

### 📦 Dependency Issues

#### npm Install Hangs
**Solution:**
1. Clear npm cache:
```bash
npm cache clean --force
```
2. Delete lock file and reinstall:
```bash
rm package-lock.json node_modules
npm install
```

#### Python Package Conflicts
**Solution:**
1. Use virtual environment:
```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```
2. Update pip:
```bash
pip install --upgrade pip
```

### 🧪 Testing Issues

#### Tests Can't Find Modules
```python
# ImportError: No module named 'app'
```
**Solution:**
Add parent directory to Python path in test files:
```python
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
```

#### React Testing Library Errors
**Solution:**
Ensure testing dependencies are installed:
```bash
npm install -D @testing-library/react @testing-library/jest-dom vitest
```

### 🚀 Deployment Issues

#### Environment Variables Not Loading
**Solution:**
1. Create `.env` file in correct location
2. Use python-dotenv:
```python
from dotenv import load_dotenv
load_dotenv()
```
3. For React, prefix with `VITE_`:
```env
VITE_API_URL=http://localhost:8000
```

#### Build Fails in Production
**Solution:**
1. Check all dependencies are in `requirements.txt` or `package.json`
2. Ensure build commands are correct:
```bash
# Backend
pip install -r requirements.txt

# Frontend
npm ci
npm run build
```

## 💡 Pro Tips

### Debugging Strategies
1. **Use Browser DevTools**
   - Network tab for API calls
   - Console for JavaScript errors
   - React DevTools for component state

2. **Backend Debugging**
   - Add print statements or use debugger
   - Check FastAPI automatic docs: `http://localhost:8000/docs`
   - Use `logging` module for better debugging

3. **VS Code Debugging**
   - Set breakpoints in code
   - Use Debug Console
   - Configure `launch.json` for both frontend and backend

### Performance Tips
1. **Frontend**
   - Use React.memo for expensive components
   - Implement virtual scrolling for long lists
   - Optimize images with lazy loading

2. **Backend**
   - Use database indexes
   - Implement caching
   - Use async/await properly

### Best Practices
1. **Always use version control**
   ```bash
   git add .
   git commit -m "descriptive message"
   ```

2. **Keep dependencies updated**
   ```bash
   # Check outdated packages
   npm outdated
   pip list --outdated
   ```

3. **Write tests as you go**
   - Unit tests for utilities
   - Integration tests for APIs
   - Component tests for UI

## 🆘 Still Stuck?

1. **Check the exercise solution** in the `solution/` directory
2. **Search error messages** - someone else likely had the same issue
3. **Ask in GitHub Discussions** with:
   - Error message
   - What you've tried
   - Relevant code snippets
4. **Review the module resources** for additional guidance

Remember: Every error is a learning opportunity! 🚀
