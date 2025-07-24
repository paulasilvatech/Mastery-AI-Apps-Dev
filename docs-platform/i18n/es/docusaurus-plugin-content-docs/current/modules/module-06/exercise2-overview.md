---
sidebar_position: 3
title: "Exercise 2: Overview"
description: "## 🎯 Objective"
---

# Ejercicio 2: E-Commerce Microservice (⭐⭐ Medio)

## 🎯 Objective

Build a RESTful microservice for an e-commerce platform that showcases advanced multi-file project management with GitHub Copilot. You'll create a properly structured API with models, repositories, services, and controllers while leveraging Copilot's workspace capabilities.

**Duración**: 45-60 minutos  
**Difficulty**: ⭐⭐ (Medio)  
**Success Rate**: 80%

## 📋 Learning Goals

Al completar este ejercicio, usted:
1. Design complex multi-layer architectures with AI assistance
2. Use Copilot Agent mode for generating related files
3. Implement database models with relationships
4. Create RESTful APIs with proper separation of concerns
5. Master cross-file navigation and refactoring

## 🏗️ What You'll Build

An e-commerce microservice featuring:
- Product catalog management
- Category organization
- Inventory tracking
- RESTful API endpoints
- Database integration with SQLAlchemy
- Comprehensive validation
- API documentation with Swagger/AbrirAPI

## 📁 Project Structure

```
ecommerce-service/
├── src/
│   ├── __init__.py
│   ├── api/
│   │   ├── __init__.py
│   │   ├── dependencies.py
│   │   └── v1/
│   │       ├── __init__.py
│   │       ├── endpoints/
│   │       │   ├── __init__.py
│   │       │   ├── products.py
│   │       │   ├── categories.py
│   │       │   └── inventory.py
│   │       └── schemas/
│   │           ├── __init__.py
│   │           ├── product.py
│   │           ├── category.py
│   │           └── inventory.py
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py
│   │   └── database.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── product.py
│   │   ├── category.py
│   │   └── inventory.py
│   ├── repositories/
│   │   ├── __init__.py
│   │   ├── base.py
│   │   ├── product.py
│   │   └── category.py
│   ├── services/
│   │   ├── __init__.py
│   │   ├── product_service.py
│   │   ├── category_service.py
│   │   └── inventory_service.py
│   └── main.py
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   ├── test_api/
│   ├── test_services/
│   └── test_repositories/
├── alembic/
│   └── versions/
├── alembic.ini
├── requirements.txt
├── .env.example
└── docker-compose.yml
```

## 🚀 Step-by-Step Instructions

### Step 1: Project Setup with Copilot Agent

1. Create the base directory:
```bash
mkdir ecommerce-service
cd ecommerce-service
code .
```

2. **Use Copilot Agent Mode:**
   - Abrir Copilot Chat
   - Click on the sparkle icon (Agent mode)
   - Prompt: "Create a complete project structure for a FastAPI e-commerce microservice with products, categories, and inventory management. Include all necessary folders and __init__.py files."

3. Create virtual ambiente:
```bash
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
```

4. Create `requirements.txt`:
```txt
fastapi==0.104.1
uvicorn[standard]==0.24.0
sqlalchemy==2.0.23
alembic==1.12.1
psycopg2-binary==2.9.9
pydantic==2.5.0
pydantic-settings==2.1.0
python-dotenv==1.0.0
pytest==7.4.3
pytest-asyncio==0.21.1
httpx==0.25.2
```

### Step 2: Configure Database and Core Configuraciones

1. Create `.env.example`:
```env
DATABASE_URL=postgresql://user:password@localhost/ecommerce_db
SECRET_KEY=your-secret-key
DEBUG=True
```

2. Abrir `src/core/config.py` and use this prompt:
```python
# Create a Settings class using pydantic-settings that:
# - Loads from .env file
# - Has database_url, secret_key, debug mode
# - Includes API versioning
# - Has CORS origins configuration
# Use functools.lru_cache for settings instance
```

3. **Workspace Tip:** Keep `.env.example` open while creating config.py

### Step 3: Create Database Models

1. Abrir `src/core/database.py`:
```python
# Create SQLAlchemy database setup with:
# - Async session support
# - Base declarative class
# - get_db dependency for FastAPI
```

2. **Multi-file Model Creation:**
   - Select all model files in the models folder
   - Use Editar mode
   - Prompt: "Create SQLAlchemy models for products, categories, and inventory with proper relationships. Products belong to categories, inventory tracks product stock."

**Expected models:**
- Category: id, name, description, created_at
- Product: id, name, description, price, category_id, created_at, updated_at
- Inventory: id, product_id, quantity, reserved_quantity, last_updated

### Step 4: Implement Repository Pattern

1. Create `src/repositories/base.py`:
```python
# Create a generic BaseRepository class with:
# - Generic type parameters
# - CRUD operations: create, get, get_all, update, delete
# - Pagination support
# - Use SQLAlchemy async sessions
```

2. **Use Copilot Chat for consistency:**
   ```
   @workspace Based on the BaseRepository in base.py, create ProductRepository and CategoryRepository with additional methods for business logic
   ```

### Step 5: Build Service Layer

1. Abrir `src/services/product_service.py`

2. **Agent Mode for Service Generation:**
   - Select service files
   - Use Agent mode
   - Prompt: "Create service classes that use the repositories and implement business logic including inventory checks when creating products, category validation, and stock management"

Service methods should include:
- Product creation with inventory initialization
- Stock updates with validation
- Low stock alerts
- Category assignment validation

### Step 6: Create API Endpoints

1. **Pydantic Schemas First:**
   - Navigate to `src/api/v1/schemas/`
   - Use Copilot to generate request/response schemas:
   ```python
   # Create Pydantic schemas for:
   # - ProductCreate, ProductUpdate, ProductResponse
   # - Include validation rules
   # - Reference the SQLAlchemy models for field types
   ```

2. **API Endpoints with Copilot Editar:**
   - Select all endpoint files
   - Editar mode prompt: "Create FastAPI endpoints for products, categories, and inventory. Include proper error handling, pagination, and filtering."

### Step 7: Wire Everything Together

1. Abrir `src/main.py`:
```python
# Create FastAPI application that:
# - Includes all routers
# - Sets up CORS
# - Adds exception handlers
# - Includes health check endpoint
# - Configures Swagger UI
```

2. **Workspace verification:**
   - In Copilot Chat: `@workspace verify all endpoints are properly imported in main.py`

### Step 8: Database Migrations

1. Initialize Alembic:
```bash
alembic init alembic
```

2. Actualizar `alembic.ini` with your database URL

3. Create initial migration:
```bash
alembic revision --autogenerate -m "Initial models"
alembic upgrade head
```

### Step 9: Comprehensive Testing

1. Create `tests/conftest.py`:
```python
# Create pytest fixtures for:
# - Test database
# - Test client
# - Sample data factories
# Use @workspace to check all models that need factories
```

2. **Test Generation with Agent:**
   - Agent mode: "Generate comprehensive tests for all API endpoints including success cases, validation errors, and edge cases"

### Step 10: Run and Validate

1. Start the database:
```bash
docker-compose up -d postgres
```

2. Run migrations:
```bash
alembic upgrade head
```

3. Start the service:
```bash
uvicorn src.main:app --reload
```

4. Test the API:
   - Visit http://localhost:8000/docs
   - Test CRUD operations for all endpoints

## 🎯 Validation Criteria

Your implementation should:
- [ ] Have proper separation of concerns across layers
- [ ] Include all CRUD operations for each entity
- [ ] Implement proper error handling
- [ ] Use dependency injection
- [ ] Include API documentation
- [ ] Pass all integration tests
- [ ] Handle database transactions properly

## 💡 Avanzado Copilot Techniques

1. **Cross-file Refactoring:**
   ```
   @workspace rename all instances of 'item' to 'product' across the codebase
   ```

2. **Dependency Analysis:**
   ```
   @workspace show me all files that import from models.product
   ```

3. **Pattern Matching:**
   ```
   @workspace find all endpoints that don't have proper error handling
   ```

4. **Architecture Validation:**
   ```
   @workspace verify that no API endpoints directly import from models (should use services)
   ```

## 🐛 Troubleshooting

### Circular Import Issues
- Ensure proper use of TYPE_CHECKING
- Use string forward references in relationships

### Async/Await Problems
- Consistency in async functions
- Proper session handling in repositories

### Schema Validation Errors
- Verificar Pydantic model field types
- Verify optional vs required fields

## 🚀 Extension Challenges

1. **Add Buscar Functionality**
   - Implement full-text search for products
   - Add filtering by multiple criteria

2. **Implement Caching**
   - Add Redis for frequently accessed data
   - Cache invalidation strategies

3. **Add Authentication**
   - JWT token authentication
   - Role-based access control

4. **Event Sourcing**
   - Ruta all inventory changes
   - Implement audit log

## 📊 Performance Considerations

- Use database indexes for foreign keys
- Implement query optimization
- Add response caching headers
- Use connection pooling

## ✅ Completion Verificarlist

- [ ] All endpoints return proper HTTP status codes
- [ ] Pagination works across all list endpoints
- [ ] Database relationships are properly configurado
- [ ] Tests cover at least 80% of code
- [ ] API documentation is complete and accurate
- [ ] Used all three Copilot modes effectively
- [ ] No direct database access from API layer

---

**Excellent work!** You've built a production-ready microservice. Ready for the ultimate challenge? Move on to Exercise 3!