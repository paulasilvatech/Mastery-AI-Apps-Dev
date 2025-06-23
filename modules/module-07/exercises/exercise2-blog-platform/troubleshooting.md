# Exercise 2: Blog Platform - Troubleshooting Guide

## Common Issues and Solutions

### 🔴 Database Connection Issues

#### PostgreSQL Connection Refused
```
Error: could not connect to server: Connection refused
```

**Solution:**
1. Ensure PostgreSQL is running:
   ```bash
   # macOS/Linux
   sudo systemctl status postgresql
   
   # Windows
   sc query postgresql
   ```

2. Check connection string in `.env`:
   ```
   DATABASE_URL=postgresql://username:password@localhost:5432/blogdb
   ```

3. Create database if not exists:
   ```bash
   createdb blogdb
   ```

#### SQLAlchemy Import Error
```
ImportError: cannot import name 'declarative_base' from 'sqlalchemy.ext.declarative'
```

**Solution:**
Update import for SQLAlchemy 2.0+:
```python
from sqlalchemy.orm import declarative_base
# Instead of:
# from sqlalchemy.ext.declarative import declarative_base
```

### 🔐 Authentication Issues

#### JWT Token Invalid
```
Error: Could not validate credentials
```

**Solution:**
1. Check JWT secret in `.env`:
   ```
   SECRET_KEY=your-secret-key-here
   ```

2. Verify token expiration:
   ```python
   ACCESS_TOKEN_EXPIRE_MINUTES = 30  # Increase if needed
   ```

3. Clear browser cookies/localStorage

#### Password Hashing Error
```
Error: bcrypt: invalid salt
```

**Solution:**
```python
# Ensure proper bcrypt context
from passlib.context import CryptContext
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
```

### 🎨 Frontend Issues

#### Vite Port Already in Use
```
Error: Port 5173 is already in use
```

**Solution:**
1. Kill process on port:
   ```bash
   # Find process
   lsof -i :5173  # macOS/Linux
   netstat -ano | findstr :5173  # Windows
   
   # Kill process
   kill -9 <PID>  # macOS/Linux
   taskkill /PID <PID> /F  # Windows
   ```

2. Or change port in `vite.config.js`:
   ```javascript
   export default {
     server: {
       port: 3001
     }
   }
   ```

#### React Query Errors
```
Error: No QueryClient set, use QueryClientProvider
```

**Solution:**
Wrap App in QueryClientProvider:
```jsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

const queryClient = new QueryClient()

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      {/* Your app */}
    </QueryClientProvider>
  )
}
```

### 🔍 Search/Elasticsearch Issues

#### Elasticsearch Connection Failed
```
Error: Connection error: connect ECONNREFUSED 127.0.0.1:9200
```

**Solution:**
1. Start Elasticsearch:
   ```bash
   # Docker
   docker run -p 9200:9200 -e "discovery.type=single-node" elasticsearch:8.11.0
   ```

2. Or disable in development:
   ```python
   # In config.py
   ENABLE_ELASTICSEARCH = os.getenv("ENABLE_ELASTICSEARCH", "false") == "true"
   ```

### 🤖 AI Integration Issues

#### OpenAI API Key Invalid
```
Error: Invalid API key provided
```

**Solution:**
1. Check `.env` file:
   ```
   OPENAI_API_KEY=sk-...
   ```

2. Verify API key at https://platform.openai.com/api-keys

#### Rate Limiting
```
Error: Rate limit exceeded
```

**Solution:**
1. Implement retry logic:
   ```python
   from tenacity import retry, wait_exponential, stop_after_attempt
   
   @retry(wait=wait_exponential(multiplier=1, min=4, max=10), 
          stop=stop_after_attempt(3))
   def call_openai_api():
       # API call
   ```

2. Use caching for repeated requests

### 🐛 General Debugging Tips

1. **Check Logs**:
   ```bash
   # Backend logs
   uvicorn app.main:app --log-level debug
   
   # Frontend console
   # Open browser DevTools (F12)
   ```

2. **Database Queries**:
   ```python
   # Enable SQL logging
   engine = create_engine(DATABASE_URL, echo=True)
   ```

3. **API Testing**:
   - Use Thunder Client or Postman
   - Check request/response in Network tab

4. **React DevTools**:
   - Install React Developer Tools extension
   - Inspect component state and props

### 📝 Environment Variables Checklist

```bash
# .env file
DATABASE_URL=postgresql://user:password@localhost:5432/blogdb
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
OPENAI_API_KEY=sk-...
ELASTICSEARCH_URL=http://localhost:9200
REDIS_URL=redis://localhost:6379/0
```

### 🆘 Getting Help

1. Check error messages carefully
2. Search error in project issues
3. Review similar exercises solutions
4. Use Copilot chat for debugging:
   ```
   "Help me debug this error: [paste error]"
   ```

Remember: Most issues are configuration-related. Double-check your setup!