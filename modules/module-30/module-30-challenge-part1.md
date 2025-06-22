# Ultimate Mastery Challenge - Hour 1: Foundation to Intermediate

## 🎯 Challenge Scenario: AI-Powered E-Learning Platform

You've been hired by **MasteryEd**, a startup that wants to revolutionize online education with AI. They need a comprehensive platform that leverages AI to personalize learning experiences, automate content generation, and provide intelligent tutoring.

## 📋 Hour 1 Requirements (Minutes 0-60)

### Core Application Development

During this first hour, you must build the foundation of the MasteryEd platform, demonstrating mastery of modules 1-10.

### 🔨 Tasks to Complete

#### 1. Project Setup & Architecture (Minutes 0-15)
Create the initial project structure with AI assistance:

```python
# Copilot Prompt Suggestion:
# Create a modern Python project structure for an AI-powered e-learning platform with:
# - FastAPI for the backend
# - PostgreSQL for data persistence  
# - Redis for caching
# - Proper folder structure following best practices
# - Configuration management
# - Logging setup
```

**Deliverables:**
- Project scaffold with proper structure
- Requirements files for all dependencies
- Configuration system (using environment variables)
- Basic logging configuration
- Git repository initialized with .gitignore

#### 2. Core Models & Database (Minutes 15-30)
Design and implement the data layer:

```python
# Copilot Prompt Suggestion:
# Create SQLAlchemy models for an e-learning platform with:
# - Users (students, instructors, admins)
# - Courses with modules and lessons
# - Enrollments and progress tracking
# - AI-generated content storage
# - Assessment questions and answers
# Include proper relationships, indexes, and constraints
```

**Required Models:**
- User (with roles: student, instructor, admin)
- Course (with metadata and AI features flags)
- Module (course sections)
- Lesson (with content and AI-generated summaries)
- Enrollment (user-course relationship)
- Progress (tracking completion)
- Assessment (quizzes/tests)
- AIContent (storing generated content)

#### 3. API Implementation (Minutes 30-45)
Build the core API endpoints:

```python
# Copilot Prompt Suggestion:
# Implement FastAPI endpoints for:
# - User authentication (JWT-based)
# - Course CRUD operations
# - Enrollment management
# - Progress tracking
# - AI content generation triggers
# Include proper validation, error handling, and documentation
```

**Required Endpoints:**
- **Auth**: `/api/auth/register`, `/api/auth/login`, `/api/auth/refresh`
- **Users**: `/api/users/me`, `/api/users/{id}` 
- **Courses**: Full CRUD at `/api/courses`
- **Enrollments**: `/api/enrollments`, `/api/users/me/courses`
- **Progress**: `/api/progress/update`, `/api/progress/course/{id}`
- **AI Features**: `/api/ai/summarize`, `/api/ai/generate-quiz`

#### 4. Real-time Features & Initial Testing (Minutes 45-60)
Add WebSocket support and basic tests:

```python
# Copilot Prompt Suggestion:
# Add WebSocket support for:
# - Real-time progress updates
# - Live chat for course discussions
# - Notification system
# Plus create comprehensive tests for all endpoints
```

**Features to Implement:**
- WebSocket endpoint for real-time updates
- Progress synchronization across devices
- Basic chat functionality per course
- Notification service structure
- Unit tests for models
- Integration tests for APIs
- Basic load test setup

### 📊 Evaluation Criteria - Hour 1

#### Code Quality (10 points)
- Clean, well-organized code structure
- Proper use of design patterns
- Consistent naming conventions
- Appropriate comments and docstrings

#### AI Utilization (10 points)
- Effective use of GitHub Copilot
- Quality of generated code
- Proper validation of AI suggestions
- Creative problem-solving with AI

#### Functionality (15 points)
- All required features working
- Proper error handling
- Data validation implemented
- API documentation complete

#### Testing (5 points)
- Unit tests for critical functions
- API endpoint tests
- Test coverage > 70%
- Tests actually pass

### 💡 Tips for Hour 1

1. **Start Fast**: Use Copilot to generate boilerplate quickly
2. **Think Modular**: Create reusable components
3. **Document Early**: Add docstrings as you code
4. **Test Continuously**: Run tests after each major feature
5. **Commit Often**: Show your progress with meaningful commits

### 🛠️ Suggested Technology Stack

```python
# Backend
fastapi==0.104.1
uvicorn==0.24.0
sqlalchemy==2.0.23
alembic==1.12.1
psycopg2-binary==2.9.9
redis==5.0.1
python-jose==3.3.0
passlib==1.7.4
python-multipart==0.0.6

# AI/ML
openai==1.3.0
langchain==0.0.335
numpy==1.24.3
pandas==2.0.3

# Testing
pytest==7.4.3
pytest-asyncio==0.21.1
httpx==0.25.2
```

### 🚨 Common Pitfalls to Avoid

- ❌ Spending too much time on perfect architecture
- ❌ Over-complicating the initial implementation
- ❌ Forgetting to handle async properly in FastAPI
- ❌ Not testing AI integration points
- ❌ Leaving database migrations for later

### ✅ Hour 1 Checklist

Before moving to Hour 2, ensure you have:
- [ ] Working API with authentication
- [ ] Database models and migrations
- [ ] Core CRUD operations functional
- [ ] Real-time WebSocket working
- [ ] Basic test suite passing
- [ ] All code committed to Git
- [ ] API documentation accessible

### 🎯 Stretch Goals (If Time Permits)

- Add API rate limiting
- Implement basic caching with Redis
- Create database seed script
- Add Swagger UI customization
- Implement basic analytics endpoints

---

## 🏃 Ready for Hour 2?

Once you've completed Hour 1 requirements:
1. Commit all changes: `git commit -m "Hour 1 complete: Foundation implemented"`
2. Run final test suite: `pytest`
3. Ensure API is running: `uvicorn main:app --reload`
4. Take a 2-minute break (stay focused!)
5. Move to Hour 2 instructions

**Remember**: The goal is a working foundation, not perfection. Keep momentum and trust your training!