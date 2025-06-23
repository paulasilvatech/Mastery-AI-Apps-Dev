# Blog Platform - Starter Code

## Overview

This directory contains the starting template for building an AI-enhanced blog platform. You'll implement features step by step following the instructions.

## Structure

```
starter/
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── models.py      # TODO: Complete database models
│   │   ├── schemas.py     # TODO: Add Pydantic schemas
│   │   ├── auth.py        # TODO: Implement authentication
│   │   └── main.py        # TODO: Add API endpoints
│   └── requirements.txt
├── frontend/
│   ├── src/
│   │   ├── components/    # TODO: Build React components
│   │   ├── services/      # TODO: API integration
│   │   └── App.js         # TODO: Main application
│   └── package.json
└── docker-compose.yml     # Pre-configured for development
```

## Getting Started

1. **Backend Setup**:
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate  # Windows: .\venv\Scripts\activate
   pip install -r requirements.txt
   ```

2. **Frontend Setup**:
   ```bash
   cd frontend
   npm install
   ```

3. **Start Development**:
   ```bash
   # Terminal 1 - Backend
   cd backend
   python -m uvicorn app.main:app --reload
   
   # Terminal 2 - Frontend
   cd frontend
   npm run dev
   ```

## Your Tasks

### Phase 1: Database & Models
- [ ] Define User model with authentication fields
- [ ] Create BlogPost model with relationships
- [ ] Add Comment model with nested structure
- [ ] Set up database migrations

### Phase 2: API Development
- [ ] Implement JWT authentication
- [ ] Create CRUD endpoints for posts
- [ ] Add comment system with threading
- [ ] Implement search functionality

### Phase 3: Frontend Development
- [ ] Build authentication flow
- [ ] Create post editor with markdown
- [ ] Implement comment system
- [ ] Add search and filtering

### Phase 4: AI Features
- [ ] AI-powered content suggestions
- [ ] Automatic tag generation
- [ ] Content moderation
- [ ] SEO optimization

## Copilot Tips

1. **For Models**: Start with comments describing relationships
2. **For API**: Use type hints and docstrings
3. **For Frontend**: Describe component props clearly
4. **For AI**: Be specific about integration points

## Resources

- FastAPI: https://fastapi.tiangolo.com/
- SQLAlchemy: https://docs.sqlalchemy.org/
- React: https://react.dev/
- JWT: https://jwt.io/

Good luck! Use GitHub Copilot to accelerate your development!