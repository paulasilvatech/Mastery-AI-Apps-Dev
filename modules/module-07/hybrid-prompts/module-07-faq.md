# Module 07 - Frequently Asked Questions (FAQ)

## ❓ General Questions

### Q: How long does Module 07 take to complete?
**A:** Module 07 is designed for 3 hours total:
- Exercise 1 (Todo App): 45 minutes
- Exercise 2 (Smart Notes): 60 minutes  
- Exercise 3 (AI Recipes): 60 minutes
- Deployment and exploration: 15 minutes

Most students complete it in 3-4 hours depending on exploration depth.

### Q: What's the difference between Code Suggestions and Agent Mode?
**A:** 
- **Code Suggestions**: Inline AI that completes code as you type. Great for learning syntax and building incrementally.
- **Agent Mode (Chat)**: Conversational AI that generates complete solutions. Perfect for scaffolding and complex features.

Think of it as precision tool vs. power tool - both are valuable!

### Q: Can I skip exercises?
**A:** While possible, we recommend completing them in order:
- Exercise 1 teaches React/FastAPI basics
- Exercise 2 builds on those skills
- Exercise 3 integrates everything with AI

Each exercise introduces new concepts used in later ones.

## 🛠️ Technical Questions

### Q: Do I need to know React before starting?
**A:** Basic JavaScript knowledge is helpful, but not required. The exercises teach React progressively:
- Exercise 1: Basic components and state
- Exercise 2: Advanced hooks and libraries
- Exercise 3: Complex integrations

Copilot helps you learn as you build!

### Q: Which Python version should I use?
**A:** Python 3.11 or higher is required. Some features used in the exercises need modern Python:
```bash
# Check your version
python --version  # Should show 3.11.x or higher

# If using older version, upgrade:
# Windows: Download from python.org
# Mac: brew install python@3.11
# Linux: sudo apt install python3.11
```

### Q: Why use Vite instead of Create React App?
**A:** Vite offers several advantages:
- ⚡ Much faster startup and hot reload
- 📦 Smaller bundle sizes
- 🔧 Better TypeScript support
- 🚀 Modern development experience
- 🔌 Easy proxy configuration for API calls

### Q: Is TypeScript required?
**A:** No, all exercises use JavaScript for simplicity. However, you can easily add TypeScript:
```bash
# In your project
npm install -D typescript @types/react @types/node
npx tsc --init
# Rename .jsx files to .tsx
```

## 💰 Cost Questions

### Q: How much will the OpenAI API cost?
**A:** For Exercise 3, expect minimal costs:
- Development/testing: $0.50 - $2.00
- Using GPT-3.5-turbo (recommended for learning)
- Set usage limits in OpenAI dashboard
- Use caching to reduce API calls

**Cost-saving tips:**
```python
# Use cheaper model for testing
model = "gpt-3.5-turbo"  # ~10x cheaper than GPT-4

# Implement caching
from functools import lru_cache

# Set reasonable limits
max_tokens = 500  # Enough for recipes
```

### Q: Are there free alternatives to OpenAI?
**A:** Yes! Several options:
1. **Groq** - Fast inference, free tier
2. **Google Gemini** - Free API tier
3. **Anthropic Claude** - Via API (paid)
4. **Local models** - Ollama with Llama 2

Modify the code to use different providers:
```python
# Example with Groq
from groq import Groq
client = Groq(api_key="your-key")
```

### Q: Do I need Azure for deployment?
**A:** No, Azure is optional. Free alternatives:
- **Vercel**: Great for React apps
- **Railway**: Full-stack deployment
- **Render**: Free tier available
- **Netlify + Heroku**: Classic combo
- **GitHub Pages**: For static sites

## 🤖 Copilot Questions

### Q: My Copilot suggestions aren't appearing. Help!
**A:** Common fixes:
1. Check subscription status at github.com/settings/copilot
2. Ensure VS Code extension is updated
3. Sign out and back in:
   - Cmd/Ctrl + Shift + P → "Sign out"
   - Restart VS Code
   - Sign back in
4. Check file type is recognized (.jsx, .py)
5. Try a simple test:
   ```javascript
   // Create a function to add two numbers
   ```

### Q: Agent Mode gives generic responses. How to improve?
**A:** Better prompts get better results:

❌ **Poor**: "Create a todo app"

✅ **Good**: "Create a React todo app with:
- State management using useState
- Add, edit, delete functionality  
- Local storage persistence
- Tailwind CSS styling
- Keyboard shortcuts
- Animation on add/remove"

### Q: Should I accept all Copilot suggestions?
**A:** No! Think critically:
- ✅ Accept: Boilerplate, common patterns, syntax help
- ⚠️ Review: Business logic, security code, API calls
- ❌ Reject: Code that looks wrong or insecure
- 🤔 Modify: Suggestions that are close but need tweaks

## 🏗️ Architecture Questions

### Q: Should I use a single repository or separate repos?
**A:** For Module 07, we recommend a monorepo structure:
```
module-07-project/
├── backend/      # FastAPI
├── frontend/     # React
├── shared/       # Common types/utils
└── deployment/   # Docker, configs
```

Benefits: Easier development, shared commits, unified deployment

### Q: How do I handle environment variables?
**A:** Best practices:

**Frontend (.env)**:
```bash
VITE_API_URL=http://localhost:8000
VITE_APP_NAME=My App
# VITE_ prefix required for Vite
```

**Backend (.env)**:
```bash
DATABASE_URL=sqlite:///./app.db
SECRET_KEY=your-secret-key
OPENAI_API_KEY=sk-...
```

**Never commit .env files!** Use .env.example instead.

### Q: What database should I use?
**A:** Depends on your needs:

| Database | When to Use | Pros | Cons |
|----------|------------|------|------|
| SQLite | Learning, prototypes | Simple, no setup | Not for production |
| PostgreSQL | Production apps | Full-featured, reliable | Needs installation |
| MongoDB | Document storage | Flexible schema | Different paradigm |
| Redis | Caching, sessions | Very fast | In-memory only |

Start with SQLite, migrate later if needed.

## 🚀 Deployment Questions

### Q: How do I deploy the frontend and backend together?
**A:** Several approaches:

1. **Separate deployments** (Recommen