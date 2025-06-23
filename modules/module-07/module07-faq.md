# Module 07: Frequently Asked Questions

## 🤔 General Questions

### Q: What makes this module different from typical web development tutorials?
**A:** This module focuses on **AI-assisted development** throughout the entire process. Instead of writing everything from scratch, you'll learn to leverage GitHub Copilot to:
- Generate components and APIs rapidly
- Implement complex features with AI suggestions
- Apply best practices automatically
- Debug and optimize with AI assistance

### Q: Do I need prior React or FastAPI experience?
**A:** Basic knowledge helps, but isn't required. The exercises are designed to guide you step-by-step, and Copilot will help generate the code. Focus on understanding the patterns rather than memorizing syntax.

### Q: How long should each exercise really take?
**A:** Times are estimates for focused work:
- Exercise 1: 30-45 minutes (can be done in 25 with Copilot)
- Exercise 2: 45-60 minutes (40 minutes if familiar with auth)
- Exercise 3: 60-90 minutes (depends on Docker experience)

Take your time to understand the concepts - speed comes with practice.

## 💻 Technical Questions

### Q: Why use Vite instead of Create React App?
**A:** Vite offers:
- ⚡ Instant server start (vs 20-30 seconds)
- 🔥 Lightning fast HMR (Hot Module Replacement)
- 📦 Smaller bundle sizes
- 🛠️ Better TypeScript support out of the box
- 🎯 Modern tooling that Copilot understands well

### Q: Can I use npm instead of pnpm?
**A:** Yes! All commands work with npm:
```bash
# pnpm install → npm install
# pnpm add package → npm install package
# pnpm run dev → npm run dev
```
pnpm is faster and uses less disk space, but npm works perfectly fine.

### Q: Why FastAPI over Django or Flask?
**A:** FastAPI provides:
- 🚀 Automatic API documentation
- 📋 Built-in validation with Pydantic
- ⚡ Async support by default
- 🤖 Excellent Copilot integration
- 📝 Type hints throughout

### Q: Do I need PostgreSQL for Exercise 2?
**A:** PostgreSQL is recommended for production-like experience, but you can use SQLite:
```python
# Change in config.py:
DATABASE_URL = "sqlite:///./blog.db"  # Instead of postgresql://...
```

## 🤖 Copilot Questions

### Q: Copilot isn't suggesting anything useful. What's wrong?
**A:** Try these fixes:
1. **Provide more context**:
   ```python
   # ❌ Bad: Create function
   # ✅ Good: Create FastAPI endpoint to get all todos with pagination
   ```

2. **Use descriptive variable names**:
   ```typescript
   // ❌ Bad: const d = getData()
   // ✅ Good: const todoItems = await fetchTodos()
   ```

3. **Write comments first**:
   ```python
   # Get all posts by user with comments count
   # Include author information
   # Sort by created date descending
   # Then press Tab or Enter
   ```

### Q: Should I accept every Copilot suggestion?
**A:** No! Always:
- ✅ Review for security issues
- ✅ Check for logical errors
- ✅ Ensure it matches your requirements
- ✅ Verify it follows project patterns
- ❌ Don't blindly accept complex logic

### Q: How do I get Copilot to generate tests?
**A:** Use specific test prompts:
```python
# Test: Create unit tests for todo CRUD operations
# Include: happy path, validation errors, authentication
# Use: pytest with async support
```

## 🔧 Setup Issues

### Q: "Port already in use" error
**A:** Common issue with hot-reloading. Solutions:

```bash
# Find and kill process on port 8000
lsof -ti:8000 | xargs kill -9

# Or use different port
uvicorn app.main:app --port 8001
```

### Q: Docker commands are slow on Mac
**A:** Docker Desktop on Mac can be slow. Try:
1. Increase Docker memory: Preferences → Resources → Memory: 4GB+
2. Use native PostgreSQL for development
3. Enable virtualization framework options

### Q: Frontend not connecting to backend
**A:** Check CORS settings:
```python
# backend/app/main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],  # Vite default port
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## 🚀 Best Practices Questions

### Q: How should I structure my prompts for Copilot?
**A:** Follow this pattern:
1. **What**: Describe what you want
2. **How**: Specify implementation details
3. **Constraints**: Add requirements
4. **Example**: Provide sample input/output

Example:
```typescript
// Create a React hook for WebSocket connections that:
// - Auto-reconnects on disconnect
// - Handles authentication
// - Provides connection status
// - Queues messages when offline
// - Uses exponential backoff
// Example: const { send, status } = useWebSocket(url, token)
```

### Q: Should I commit generated code as-is?
**A:** Never! Always:
1. Review and understand the code
2. Add proper error handling
3. Include appropriate logging
4. Write tests
5. Document complex logic
6. Refactor for readability

### Q: How do I handle secrets in development?
**A:** Use environment variables:
```bash
# .env (never commit this!)
DATABASE_URL=postgresql://user:pass@localhost/db
JWT_SECRET=your-secret-key
OPENAI_API_KEY=sk-...

# .env.example (commit this!)
DATABASE_URL=postgresql://user:pass@localhost/db
JWT_SECRET=generate-a-secret-key
OPENAI_API_KEY=your-api-key-here
```

## 📊 Exercise-Specific Questions

### Exercise 1: Todo App
**Q: Why is the AI suggestion feature using random suggestions?**
A: It's a mock implementation to demonstrate the pattern. In production, you'd integrate with OpenAI or similar:
```python
# Real implementation would be:
async def suggest_next_todo(user_context):
    response = await openai.Completion.create(
        prompt=f"Suggest next task for: {user_context}",
        max_tokens=50
    )
    return response.choices[0].text
```

### Exercise 2: Blog Platform
**Q: How do I implement real rich text editing?**
A: The exercise uses basic textarea. For production, integrate Tiptap or Slate:
```bash
npm install @tiptap/react @tiptap/starter-kit
```

### Exercise 3: AI Dashboard
**Q: Do I need Kubernetes for the dashboard?**
A: No, it's mocked in development. The patterns you learn apply when you have real Kubernetes later.

## 🎓 Learning Path Questions

### Q: What should I focus on in each exercise?
**A:**
- **Exercise 1**: Basic full-stack flow, CRUD operations
- **Exercise 2**: Authentication, complex state, file handling
- **Exercise 3**: Real-time data, WebSockets, monitoring patterns

### Q: How do I know if I've mastered the module?
**A:** You should be able to:
- ✅ Build a simple CRUD app in 30 minutes
- ✅ Implement auth without looking up docs
- ✅ Handle real-time updates smoothly
- ✅ Deploy to production confidently
- ✅ Debug issues independently

### Q: What's the most important skill from this module?
**A:** Learning to **prompt Copilot effectively** for web development. The frameworks may change, but AI-assisted development is the future.

## 🆘 Still Stuck?

1. Check the [troubleshooting guide](./troubleshooting.md)
2. Review the [best practices](./best-practices.md)
3. Look at the solution code in each exercise
4. Post in the module discussions with:
   - Your error message
   - What you've tried
   - Minimal code example
   - Environment details

Remember: Every developer gets stuck. The key is learning how to get unstuck efficiently!