# Best Practices for AI-Powered Web Development

## 🎯 Overview

This guide provides production-ready patterns and best practices for building web applications with GitHub Copilot and AI integration. Apply these principles to create maintainable, scalable, and secure applications.

## 🤖 GitHub Copilot Best Practices

### 1. Effective Prompting Strategies

#### Be Specific and Contextual
```javascript
// ❌ Poor: Too vague
// Create a form

// ✅ Good: Specific requirements
// Create a React form component with:
// - Email and password fields with validation
// - Show/hide password toggle
// - Loading state during submission
// - Error messages below each field
// - Tailwind CSS styling with focus states
```

#### Provide Examples in Comments
```python
# ✅ Good: Clear example helps Copilot understand the pattern
# Create endpoint that accepts: {"ingredients": ["tomato", "pasta", "basil"]}
# And returns: {"recipes": [{"title": "...", "cookTime": 30, ...}]}
@app.post("/api/recipes/search")
```

#### Build Incrementally
```javascript
// Step 1: Basic structure
// Create a recipe card component

// Step 2: Add interactivity
// Add favorite button that toggles on click

// Step 3: Enhance UX
// Add loading skeleton while image loads
```

### 2. Code Quality with AI

#### Review and Refactor
```javascript
// Always review Copilot suggestions for:
// 1. Security vulnerabilities
// 2. Performance implications
// 3. Accessibility compliance
// 4. Error handling completeness

// Example: Copilot might suggest
const handleSubmit = (data) => {
  fetch('/api/submit', { method: 'POST', body: data })
}

// Improve to:
const handleSubmit = async (data) => {
  try {
    const response = await fetch('/api/submit', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    })
    if (!response.ok) throw new Error('Submission failed')
    return await response.json()
  } catch (error) {
    console.error('Submit error:', error)
    throw error
  }
}
```

#### Maintain Consistency
```javascript
// Define patterns once, let Copilot follow
// utils/api.js
export const apiCall = async (endpoint, options = {}) => {
  const response = await fetch(`${API_URL}${endpoint}`, {
    headers: { 'Content-Type': 'application/json' },
    ...options
  })
  if (!response.ok) throw new Error(`API error: ${response.status}`)
  return response.json()
}

// Then use consistently:
// Copilot will learn your pattern
const data = await apiCall('/recipes', { method: 'GET' })
```

## 🏗️ Architecture Patterns

### 1. Component Structure

#### Container/Presenter Pattern
```javascript
// RecipeContainer.jsx - Logic and state
function RecipeContainer() {
  const [recipes, setRecipes] = useState([])
  const [loading, setLoading] = useState(true)
  
  useEffect(() => {
    fetchRecipes().then(setRecipes).finally(() => setLoading(false))
  }, [])
  
  return <RecipeList recipes={recipes} loading={loading} />
}

// RecipeList.jsx - Pure presentation
function RecipeList({ recipes, loading }) {
  if (loading) return <LoadingSkeleton />
  return recipes.map(recipe => <RecipeCard key={recipe.id} {...recipe} />)
}
```

#### Custom Hooks for Reusability
```javascript
// hooks/useApi.js
function useApi(endpoint) {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  
  useEffect(() => {
    apiCall(endpoint)
      .then(setData)
      .catch(setError)
      .finally(() => setLoading(false))
  }, [endpoint])
  
  return { data, loading, error }
}

// Usage
function RecipePage() {
  const { data: recipes, loading, error } = useApi('/recipes')
  // Component logic
}
```

### 2. State Management

#### Local State First
```javascript
// Use local state for component-specific data
const [isOpen, setIsOpen] = useState(false)

// Use context for shared state
const ThemeContext = createContext()

// Use external state (Zustand) for complex apps
const useStore = create((set) => ({
  recipes: [],
  addRecipe: (recipe) => set((state) => ({ 
    recipes: [...state.recipes, recipe] 
  }))
}))
```

#### Optimistic Updates
```javascript
// Update UI immediately, rollback on error
const toggleFavorite = async (recipeId) => {
  // Optimistic update
  setRecipes(prev => prev.map(r => 
    r.id === recipeId ? { ...r, isFavorite: !r.isFavorite } : r
  ))
  
  try {
    await apiCall(`/recipes/${recipeId}/favorite`, { method: 'POST' })
  } catch (error) {
    // Rollback on error
    setRecipes(prev => prev.map(r => 
      r.id === recipeId ? { ...r, isFavorite: !r.isFavorite } : r
    ))
    toast.error('Failed to update favorite')
  }
}
```

## 🔐 Security Best Practices

### 1. Input Validation

#### Frontend Validation
```javascript
// Always validate on frontend for UX
const validateEmail = (email) => {
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return regex.test(email)
}

// But never trust frontend validation alone
```

#### Backend Validation
```python
from pydantic import BaseModel, validator, EmailStr

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    
    @validator('password')
    def password_strength(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters')
        return v
```

### 2. API Security

#### Authentication
```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer()

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        return payload
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )
```

#### Rate Limiting
```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

@app.post("/api/generate-recipe")
@limiter.limit("5/minute")
async def generate_recipe(request: Request, data: RecipeRequest):
    # Prevents API abuse
```

### 3. Environment Security

#### Never Commit Secrets
```bash
# .env
OPENAI_API_KEY=sk-...
DATABASE_URL=postgresql://...

# .gitignore
.env
.env.local
.env.*.local
```

#### Use Environment Variables
```javascript
// Frontend
const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

// Backend
import os
from dotenv import load_dotenv

load_dotenv()
API_KEY = os.getenv('OPENAI_API_KEY')
```

## ⚡ Performance Optimization

### 1. Frontend Performance

#### Code Splitting
```javascript
// Lazy load heavy components
const RecipeEditor = lazy(() => import('./components/RecipeEditor'))

function App() {
  return (
    <Suspense fallback={<LoadingSpinner />}>
      <RecipeEditor />
    </Suspense>
  )
}
```

#### Image Optimization
```javascript
// Use modern formats and lazy loading
<img 
  src={recipe.image} 
  alt={recipe.title}
  loading="lazy"
  decoding="async"
  width={400}
  height={300}
/>

// Or use Next.js Image component
import Image from 'next/image'
```

#### Debouncing
```javascript
// Prevent excessive API calls
import { useMemo } from 'react'
import debounce from 'lodash/debounce'

function SearchBar({ onSearch }) {
  const debouncedSearch = useMemo(
    () => debounce(onSearch, 500),
    [onSearch]
  )
  
  return (
    <input onChange={(e) => debouncedSearch(e.target.value)} />
  )
}
```

### 2. Backend Performance

#### Caching
```python
from functools import lru_cache
import redis

redis_client = redis.Redis()

@lru_cache(maxsize=100)
def get_cached_recipe(recipe_id: str):
    # Memory cache for frequent requests
    return fetch_recipe_from_db(recipe_id)

# Redis for distributed cache
async def get_recipe(recipe_id: str):
    cached = redis_client.get(f"recipe:{recipe_id}")
    if cached:
        return json.loads(cached)
    
    recipe = await fetch_recipe_from_db(recipe_id)
    redis_client.setex(f"recipe:{recipe_id}", 3600, json.dumps(recipe))
    return recipe
```

#### Database Optimization
```python
# Use indexes
class Recipe(Base):
    __tablename__ = "recipes"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    created_at = Column(DateTime, index=True)

# Eager loading to prevent N+1
recipes = db.query(Recipe).options(
    joinedload(Recipe.ingredients)
).all()
```

## 🧪 Testing Strategies

### 1. Component Testing

```javascript
// RecipeCard.test.jsx
import { render, screen, fireEvent } from '@testing-library/react'
import RecipeCard from './RecipeCard'

test('renders recipe title and toggles favorite', () => {
  const recipe = { id: 1, title: 'Test Recipe', isFavorite: false }
  const onToggleFavorite = jest.fn()
  
  render(<RecipeCard {...recipe} onToggleFavorite={onToggleFavorite} />)
  
  expect(screen.getByText('Test Recipe')).toBeInTheDocument()
  
  fireEvent.click(screen.getByRole('button', { name: /favorite/i }))
  expect(onToggleFavorite).toHaveBeenCalledWith(1)
})
```

### 2. API Testing

```python
# test_api.py
from fastapi.testclient import TestClient

client = TestClient(app)

def test_generate_recipe():
    response = client.post("/api/generate-recipe", json={
        "ingredients": ["tomato", "pasta"],
        "cuisine": "Italian"
    })
    assert response.status_code == 200
    assert "title" in response.json()
```

## 📦 Deployment Best Practices

### 1. Environment Configuration

```javascript
// config.js
export const config = {
  API_URL: process.env.NODE_ENV === 'production' 
    ? 'https://api.recipes.com' 
    : 'http://localhost:8000',
  ENABLE_ANALYTICS: process.env.NODE_ENV === 'production'
}
```

### 2. Health Checks

```python
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.now(),
        "version": "1.0.0"
    }
```

### 3. Error Monitoring

```javascript
// Integrate error tracking
import * as Sentry from "@sentry/react"

Sentry.init({
  dsn: process.env.REACT_APP_SENTRY_DSN,
  environment: process.env.NODE_ENV,
})
```

## 🎨 UI/UX Best Practices

### 1. Loading States

```javascript
// Show skeletons, not spinners
function RecipeListSkeleton() {
  return (
    <div className="grid grid-cols-3 gap-4">
      {[...Array(6)].map((_, i) => (
        <div key={i} className="animate-pulse">
          <div className="bg-gray-300 h-48 rounded-lg mb-4" />
          <div className="bg-gray-300 h-4 w-3/4 rounded mb-2" />
          <div className="bg-gray-300 h-4 w-1/2 rounded" />
        </div>
      ))}
    </div>
  )
}
```

### 2. Error Handling

```javascript
// User-friendly error messages
const errorMessages = {
  'NETWORK_ERROR': 'Unable to connect. Please check your internet connection.',
  'API_ERROR': 'Something went wrong. Please try again.',
  'AUTH_ERROR': 'Please log in to continue.',
}

function ErrorBoundary({ children }) {
  return (
    <ErrorBoundaryComponent
      fallback={({ error }) => (
        <div className="error-container">
          <h2>Oops! Something went wrong</h2>
          <p>{errorMessages[error.code] || errorMessages.API_ERROR}</p>
          <button onClick={() => window.location.reload()}>
            Try Again
          </button>
        </div>
      )}
    >
      {children}
    </ErrorBoundaryComponent>
  )
}
```

### 3. Accessibility

```javascript
// Always include ARIA labels and keyboard navigation
<button
  onClick={toggleFavorite}
  aria-label={isFavorite ? 'Remove from favorites' : 'Add to favorites'}
  aria-pressed={isFavorite}
  className="focus:outline-none focus:ring-2 focus:ring-blue-500"
>
  <HeartIcon className={isFavorite ? 'text-red-500' : 'text-gray-400'} />
</button>
```

## 🚀 Continuous Improvement

### 1. Analytics Integration

```javascript
// Track user interactions
const trackEvent = (action, category, label) => {
  if (window.gtag) {
    window.gtag('event', action, {
      event_category: category,
      event_label: label
    })
  }
}

// Usage
trackEvent('generate_recipe', 'AI', 'ingredients_count_5')
```

### 2. A/B Testing

```javascript
// Simple feature flag system
const features = {
  newRecipeCard: process.env.REACT_APP_NEW_RECIPE_CARD === 'true'
}

function RecipeDisplay({ recipe }) {
  return features.newRecipeCard 
    ? <NewRecipeCard {...recipe} /> 
    : <RecipeCard {...recipe} />
}
```

## 📚 Summary

Remember these key principles:

1. **Let Copilot help, but always review** - AI is a tool, not a replacement for thinking
2. **Start simple, iterate fast** - Build MVP first, enhance later
3. **User experience over features** - Fast, reliable, and intuitive wins
4. **Security is not optional** - Validate inputs, sanitize outputs, protect APIs
5. **Performance matters** - Optimize images, debounce inputs, cache responses
6. **Test what matters** - Focus on critical paths and user journeys
7. **Deploy early and often** - Get feedback from real users

The best AI-powered applications feel magical to users while being built on solid engineering principles!