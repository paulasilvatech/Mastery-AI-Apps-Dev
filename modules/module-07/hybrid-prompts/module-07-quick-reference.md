# Module 07 - Quick Reference Guide: Code Suggestions vs Agent Mode

## 🚀 At a Glance Comparison

| Task | Code Suggestions | Agent Mode |
|------|-----------------|------------|
| **Create React component** | `// Create a todo item component with checkbox` | "Create complete todo component with edit, delete, and animations" |
| **Add API endpoint** | `# Create FastAPI endpoint for getting todos` | "Create CRUD API with validation, error handling, and documentation" |
| **Style with Tailwind** | `// Add Tailwind classes for card layout` | "Design a modern UI with gradients, shadows, and responsive layout" |
| **Integrate OpenAI** | `# Function to call OpenAI API` | "Create AI service with retry logic, caching, and cost management" |

## 📝 Exercise 1: Todo App - Quick Commands

### Code Suggestions Approach

```javascript
// Frontend - React Component
// Create a todo list component that:
// - Maps through todos array
// - Shows checkbox, title, and delete button
// - Handles toggle and delete actions
// - Uses Tailwind for styling
```

```python
# Backend - FastAPI Endpoint
# Create a POST endpoint /todos that:
# - Accepts todo title in request body
# - Validates input with Pydantic
# - Saves to SQLite database
# - Returns created todo with 201 status
```

### Agent Mode Approach

```markdown
Create a full-stack todo application:

Frontend:
- React with TypeScript
- State management with useReducer
- Optimistic updates
- Drag-and-drop reordering
- Keyboard shortcuts
- Dark mode toggle
- Export/import functionality

Backend:
- FastAPI with async SQLAlchemy
- JWT authentication
- Rate limiting
- Pagination and filtering
- Bulk operations
- WebSocket for real-time updates

Include tests and deployment configuration.
```

## 🌟 Exercise 2: Smart Notes - Quick Commands

### Code Suggestions Approach

```javascript
// Markdown editor setup
// Import and configure @uiw/react-md-editor
// Add custom toolbar buttons
// Enable preview mode toggle
// Add keyboard shortcuts for formatting

// Auto-save functionality
// Create useAutoSave hook that:
// - Debounces changes by 1 second
// - Saves to localStorage
// - Shows save indicator
```

### Agent Mode Approach

```markdown
Create an advanced notes application:

Core Features:
- Rich markdown editor with live preview
- Automatic tag extraction (#hashtag, @mention)
- Full-text fuzzy search with highlighting
- Note templates and snippets
- Version history with diff view
- Collaborative editing with CRDTs

Advanced Features:
- AI-powered summarization
- Voice-to-text notes
- OCR for image notes
- Mind map visualization
- Export to multiple formats
- Plugin system for extensions

Include PWA configuration and offline support.
```

## 🤖 Exercise 3: AI Recipe Assistant - Quick Commands

### Code Suggestions Approach

```python
# OpenAI integration
# Create function to generate recipe from ingredients
# Use GPT-3.5-turbo for cost efficiency
# Parse response as JSON
# Handle API errors gracefully

# Implement caching
# Use Redis or in-memory cache
# Cache by ingredients hash
# Set 1-hour expiration
```

### Agent Mode Approach

```markdown
Create an AI-powered recipe platform:

AI Features:
- Multi-step recipe generation with:
  - Ingredients list with substitutions
  - Step-by-step instructions with timing
  - Nutritional information
  - Difficulty rating
  - Cost estimation
  
Smart Features:
- Image recognition for ingredients
- Dietary restriction handling
- Recipe scaling calculator
- Shopping list generator
- Meal planning assistant
- Wine pairing suggestions

Infrastructure:
- Token usage tracking
- Cost monitoring dashboard
- A/B testing for prompts
- Multi-model support (GPT-3.5/4)
- Fallback strategies

Include rate limiting and security measures.
```

## 🛠️ Common Patterns

### React Component Structure

**Code Suggestions:**
```javascript
// Create functional component with:
// - useState for local state
// - useEffect for side effects
// - Event handlers
// - Conditional rendering
function MyComponent() {
  // Copilot will complete...
}
```

**Agent Mode:**
```markdown
Generate a React component with:
- TypeScript interfaces
- Custom hooks for logic
- Error boundaries
- Loading states
- Memoization for performance
- Unit tests with React Testing Library
- Storybook stories
```

### API Endpoint Pattern

**Code Suggestions:**
```python
# Create REST endpoint with:
# - Pydantic model validation
# - Database operations
# - Error handling
# - Response model
@app.post("/api/resource")
async def create_resource(
    # Let Copilot complete
):
```

**Agent Mode:**
```markdown
Create a complete REST API with:
- CRUD operations
- Authentication middleware
- Request validation
- Rate limiting
- Caching layer
- API versioning
- OpenAPI documentation
- Integration tests
```

### State Management

**Code Suggestions:**
```javascript
// Create custom hook for state management
// useLocalStorage hook with:
// - Generic type support
// - JSON serialization
// - Error handling
// - SSR safety
```

**Agent Mode:**
```markdown
Implement state management solution:
- Global state with Context API
- Local storage persistence
- State synchronization across tabs
- Undo/redo functionality
- State debugging tools
- Migration strategies
- Performance optimization
```

## 💡 Pro Tips for Each Approach

### Code Suggestions Tips
1. **Write Clear Comments**: Be specific about what you want
2. **Build Incrementally**: Let Copilot complete one piece at a time
3. **Provide Context**: Keep related code visible
4. **Use Examples**: Show one example, Copilot learns the pattern

### Agent Mode Tips
1. **Be Comprehensive**: Include all requirements upfront
2. **Specify Constraints**: Mention performance, security needs
3. **Ask for Best Practices**: Request production-ready code
4. **Iterate**: Refine the generated code with follow-ups

## 🔍 Quick Debugging

### When Code Suggestions Struggle
```javascript
// If suggestions aren't appearing:
// 1. Check file type (.jsx, .py)
// 2. Ensure Copilot is enabled
// 3. Try a simpler comment
// 4. Provide more context above
// 5. Accept partial suggestions and continue
```

### When Agent Mode Needs Guidance
```markdown
If responses are too generic:
1. Add specific tech stack requirements
2. Include example inputs/outputs
3. Mention edge cases to handle
4. Request specific file structure
5. Ask for implementation details
```

## 📊 Decision Matrix

| Use Code Suggestions When... | Use Agent Mode When... |
|------------------------------|------------------------|
| Learning new syntax | Need complete solution |
| Making incremental changes | Starting from scratch |
| Understanding line-by-line | Want architecture advice |
| Debugging specific issues | Need multiple files |
| Want fine control | Want rapid prototype |
| Building step-by-step | Time is critical |

## 🎯 Quick Wins

### Instant React Components
```javascript
// Todo item with animations
// Card component with gradient
// Modal with backdrop
// Responsive navigation menu
// Loading skeleton
```

### Instant API Endpoints
```python
# Health check endpoint
# File upload handler
# Pagination helper
# JWT authentication
# Rate limiter decorator
```

### Instant UI Enhancements
```javascript
// Dark mode toggle
// Smooth scroll behavior
// Toast notifications
// Keyboard shortcuts
// Copy to clipboard
```

## 🚨 Emergency Commands

### Quick Frontend Fixes
```bash
# React not updating
rm -rf node_modules package-lock.json && npm install

# Clear all caches
npm cache clean --force

# Reset to working state
git stash && git checkout main && git pull
```

### Quick Backend Fixes
```bash
# Kill process on port
lsof -ti:8000 | xargs kill -9

# Recreate virtual environment
rm -rf venv && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt

# Reset database
rm todos.db && python init_db.py
```

### Quick Deployment
```bash
# Build and preview production
npm run build && npm run preview

# Quick Python deployment check
pip freeze > requirements.txt
python -m pytest
uvicorn main:app --host 0.0.0.0 --port $PORT
```

## 📚 Essential Links

- **React Docs**: https://react.dev
- **FastAPI Docs**: https://fastapi.tiangolo.com
- **Tailwind Playground**: https://play.tailwindcss.com
- **OpenAI Playground**: https://platform.openai.com/playground
- **Regex Tester**: https://regex101.com
- **JSON Formatter**: https://jsonformatter.curiousconcept.com

## 🎮 Keyboard Shortcuts

### VS Code + Copilot
- `Tab` - Accept suggestion
- `Esc` - Dismiss suggestion
- `Alt + ]` - Next suggestion
- `Alt + [` - Previous suggestion
- `Ctrl + Enter` - Show all suggestions

### Development
- `Ctrl + C` - Stop server
- `rs` - Restart nodemon
- `Ctrl + Shift + R` - Hard reload browser
- `Ctrl + K` - Clear terminal

---

**Remember**: This is a quick reference. For detailed explanations, see the full exercise guides. Mix and match approaches for maximum productivity! 🚀