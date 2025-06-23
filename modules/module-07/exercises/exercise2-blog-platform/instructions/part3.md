# Exercise 2: Blog Platform with AI Features (Part 3)

## 📋 Step 3: Complete Backend & Start Frontend (15 minutes)

### 3.1 Main Application

Create `backend/app/main.py`:

**Copilot Prompt Suggestion:**
```python
# Create main FastAPI application that:
# - Includes all routers (auth, posts, comments)
# - Configures CORS for frontend
# - Serves static files for uploads
# - Has health check endpoint
# - Includes API documentation customization
# - Handles global exception handling
# Initialize database on startup
```

**Expected Copilot Output:**
```python
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
import logging

from .core.config import settings
from .core.database import init_db
from .api import auth, posts, comments
from .services.upload import upload_service

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.VERSION,
    description="AI-Powered Blog Platform with rich features",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files for uploads
app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

# Include routers
app.include_router(auth.router, prefix=f"{settings.API_PREFIX}")
app.include_router(posts.router, prefix=f"{settings.API_PREFIX}")
app.include_router(comments.router, prefix=f"{settings.API_PREFIX}")

# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Global exception: {str(exc)}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"}
    )

# Startup event
@app.on_event("startup")
async def startup_event():
    """Initialize application on startup"""
    logger.info("Starting AI Blog Platform...")
    init_db()
    logger.info("Database initialized")

# Health check
@app.get("/health")
async def health_check():
    """Application health check"""
    return {
        "status": "healthy",
        "version": settings.VERSION,
        "service": settings.APP_NAME
    }

# Root endpoint
@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": f"Welcome to {settings.APP_NAME}",
        "version": settings.VERSION,
        "docs": "/docs"
    }
```

### 3.2 AI Content Service

Create `backend/app/services/ai_service.py`:

**Copilot Prompt Suggestion:**
```python
# Create AI content generation service:
# - Generate blog post titles from topic
# - Create excerpts from content
# - Suggest tags based on content
# - Generate content outlines
# - Mock implementation (can be replaced with OpenAI)
# Include error handling and response formatting
```

**Expected Copilot Output:**
```python
import random
from typing import List, Optional
from ..schemas.schemas import AIContentRequest, AIContentResponse

class AIContentService:
    """AI content generation service - Mock implementation"""
    
    def __init__(self):
        # In production, initialize OpenAI client here
        self.mock_responses = {
            "title": [
                "10 Revolutionary Ways AI is Transforming Software Development",
                "The Ultimate Guide to Building Scalable Web Applications",
                "Why Every Developer Should Learn Cloud Architecture in 2024",
                "Mastering Microservices: A Comprehensive Tutorial",
                "From Zero to Hero: Your Journey in Full-Stack Development"
            ],
            "excerpt": [
                "Discover the cutting-edge techniques that are revolutionizing how we build software. This comprehensive guide explores the latest trends and best practices.",
                "Learn the essential skills and strategies needed to excel in modern web development. From frontend frameworks to backend architecture.",
                "Dive deep into the world of cloud-native applications and microservices. Understand the patterns and practices that power today's most successful platforms."
            ],
            "content": [
                """## Introduction\n\nIn today's rapidly evolving tech landscape, staying ahead means embracing new paradigms and technologies.\n\n## Key Concepts\n\n### 1. Architecture First\nBuilding scalable applications starts with solid architectural decisions.\n\n### 2. Performance Optimization\nEvery millisecond counts in user experience.\n\n### 3. Security by Design\nSecurity isn't an afterthought—it's a fundamental requirement.\n\n## Best Practices\n\n- Always write clean, maintainable code\n- Implement comprehensive testing\n- Document your decisions\n- Embrace continuous learning\n\n## Conclusion\n\nThe journey of a thousand miles begins with a single step. Start building today!"""
            ],
            "tags": [
                ["AI", "Machine Learning", "Software Development", "Technology"],
                ["Web Development", "Full Stack", "JavaScript", "Python"],
                ["Cloud Computing", "AWS", "DevOps", "Scalability"],
                ["Microservices", "Architecture", "Docker", "Kubernetes"]
            ]
        }
    
    async def generate_content(self, request: AIContentRequest) -> AIContentResponse:
        """Generate content based on type and prompt"""
        
        # In production, this would call OpenAI API
        # For now, return mock responses
        
        if request.type == "title":
            generated = self._generate_title(request.prompt)
        elif request.type == "excerpt":
            generated = self._generate_excerpt(request.prompt, request.context)
        elif request.type == "content":
            generated = self._generate_content(request.prompt)
        elif request.type == "tags":
            generated = self._generate_tags(request.prompt, request.context)
        else:
            generated = "Invalid content type requested"
        
        # Mock token count
        tokens_used = len(generated.split()) * 2
        
        return AIContentResponse(
            generated_text=generated,
            tokens_used=tokens_used
        )
    
    def _generate_title(self, prompt: str) -> str:
        """Generate blog post title"""
        # Simple mock: combine prompt with template
        templates = [
            f"The Complete Guide to {prompt}",
            f"Mastering {prompt}: Tips and Tricks",
            f"Why {prompt} Matters in Modern Development",
            f"{prompt}: Everything You Need to Know",
            f"Building Better Software with {prompt}"
        ]
        
        return random.choice(templates) if prompt else random.choice(self.mock_responses["title"])
    
    def _generate_excerpt(self, prompt: str, context: Optional[str]) -> str:
        """Generate post excerpt"""
        if context:
            # Extract first paragraph or generate summary
            lines = context.split('\n')
            for line in lines:
                if len(line.strip()) > 50:
                    return line.strip()[:200] + "..."
        
        return random.choice(self.mock_responses["excerpt"])
    
    def _generate_content(self, prompt: str) -> str:
        """Generate post content"""
        if not prompt:
            return random.choice(self.mock_responses["content"])
        
        # Generate structured content
        return f"""## Introduction

{prompt} is a crucial topic in modern software development. Let's explore the key concepts and best practices.

## Understanding {prompt}

### What is {prompt}?

{prompt} represents a fundamental approach to building robust and scalable applications.

### Why is it Important?

1. **Efficiency**: Streamlines development processes
2. **Scalability**: Enables growth without major refactoring
3. **Maintainability**: Makes code easier to understand and modify

## Implementation Guide

### Step 1: Planning
Start by understanding your requirements and constraints.

### Step 2: Design
Create a solid architectural foundation.

### Step 3: Development
Implement with best practices in mind.

### Step 4: Testing
Ensure reliability through comprehensive testing.

## Best Practices

- Follow established patterns and conventions
- Write self-documenting code
- Implement proper error handling
- Consider performance from the start

## Common Pitfalls to Avoid

1. Over-engineering solutions
2. Ignoring security considerations
3. Lacking proper documentation
4. Skipping testing phases

## Conclusion

Mastering {prompt} is a journey that requires continuous learning and practice. Start small, iterate often, and always seek to improve.

## Further Reading

- Official documentation
- Community best practices
- Case studies and real-world examples"""
    
    def _generate_tags(self, prompt: str, context: Optional[str]) -> str:
        """Generate relevant tags"""
        # In production, analyze content to suggest tags
        tags = random.choice(self.mock_responses["tags"])
        return ", ".join(tags)

# Singleton instance
ai_service = AIContentService()
```

### 3.3 Add AI Endpoint

Create `backend/app/api/ai.py`:

```python
from fastapi import APIRouter, Depends
from ..schemas.schemas import AIContentRequest, AIContentResponse
from ..services.ai_service import ai_service
from ..core.security import get_current_user

router = APIRouter(prefix="/ai", tags=["ai"])

@router.post("/generate", response_model=AIContentResponse)
async def generate_content(
    request: AIContentRequest,
    current_user = Depends(get_current_user)
):
    """Generate AI content for blog posts"""
    return await ai_service.generate_content(request)
```

Update `backend/app/main.py` to include AI router:
```python
from .api import auth, posts, comments, ai

# Add after other routers
app.include_router(ai.router, prefix=f"{settings.API_PREFIX}")
```

### 3.4 Create Backend Run Script

Create `backend/run.py`:

```python
import uvicorn

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
```

## 📋 Step 4: Frontend Setup (15 minutes)

### 4.1 Create React Application

```bash
# From exercise2-blog-platform directory
npm create vite@latest frontend -- --template react-ts
cd frontend
npm install

# Install dependencies
npm install axios react-router-dom @tanstack/react-query
npm install react-hook-form @hookform/resolvers zod
npm install react-markdown remark-gfm
npm install @tiptap/react @tiptap/starter-kit @tiptap/extension-image
npm install react-hot-toast
npm install -D @types/react @types/react-dom tailwindcss postcss autoprefixer
```

### 4.2 Configure Tailwind CSS

```bash
npx tailwindcss init -p
```

Update `tailwind.config.js`:

**Copilot Prompt Suggestion:**
```javascript
// Configure Tailwind for blog platform with:
// - Custom colors for brand
// - Typography plugin for blog content
// - Forms plugin for better form styling
// - Responsive design utilities
```

**Expected Copilot Output:**
```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#f0f9ff',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          900: '#1e3a8a',
        },
        accent: {
          500: '#8b5cf6',
          600: '#7c3aed',
        }
      },
      typography: {
        DEFAULT: {
          css: {
            maxWidth: 'none',
            color: '#333',
            a: {
              color: '#3b82f6',
              '&:hover': {
                color: '#2563eb',
              },
            },
          },
        },
      },
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
    require('@tailwindcss/forms'),
  ],
}
```

Install Tailwind plugins:
```bash
npm install -D @tailwindcss/typography @tailwindcss/forms
```

### 4.3 Project Structure

Create the following structure:
```
frontend/src/
├── api/
│   ├── client.ts
│   ├── auth.ts
│   ├── posts.ts
│   └── types.ts
├── components/
│   ├── auth/
│   ├── blog/
│   ├── editor/
│   └── layout/
├── contexts/
│   └── AuthContext.tsx
├── hooks/
│   ├── useAuth.ts
│   └── usePosts.ts
├── pages/
│   ├── Home.tsx
│   ├── Login.tsx
│   ├── Register.tsx
│   ├── CreatePost.tsx
│   ├── PostDetail.tsx
│   └── Dashboard.tsx
├── utils/
│   └── formatters.ts
├── App.tsx
├── main.tsx
└── index.css
```

### 4.4 API Client Setup

Create `src/api/client.ts`:

**Copilot Prompt Suggestion:**
```typescript
// Create axios client with:
// - Base URL for backend API
// - Request/response interceptors
// - Auth token injection
// - Error handling
// - Request retry logic
```

**Expected Copilot Output:**
```typescript
import axios, { AxiosError } from 'axios';
import toast from 'react-hot-toast';

const API_BASE_URL = 'http://localhost:8000/api/v1';

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor for error handling
apiClient.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const message = error.response?.data?.detail || 'An error occurred';
    
    if (error.response?.status === 401) {
      // Unauthorized - redirect to login
      localStorage.removeItem('access_token');
      window.location.href = '/login';
      toast.error('Session expired. Please login again.');
    } else if (error.response?.status >= 500) {
      toast.error('Server error. Please try again later.');
    } else {
      toast.error(message);
    }
    
    return Promise.reject(error);
  }
);
```

## ✅ Checkpoint 3

Before continuing with frontend components:
- [ ] Backend server runs without errors
- [ ] All API endpoints are accessible
- [ ] File upload directory is created
- [ ] Frontend project is set up
- [ ] Tailwind CSS is configured
- [ ] API client is ready

### Test the Backend

1. Start the backend:
   ```bash
   cd backend
   python run.py
   ```

2. Access API docs: http://localhost:8000/docs

3. Test registration:
   ```bash
   curl -X POST http://localhost:8000/api/v1/auth/register \
     -H "Content-Type: application/json" \
     -d '{"username": "testuser", "email": "test@example.com", "password": "Test1234!"}'
   ```

## 🎯 Next Steps

Continue to Part 4 for:
- Complete frontend implementation
- Rich text editor setup
- Authentication flow
- Blog post management
- Comment system
- Final integration

The blog platform is taking shape! The backend is fully functional with authentication, post management, comments, and file uploads. The frontend structure is ready for component implementation.