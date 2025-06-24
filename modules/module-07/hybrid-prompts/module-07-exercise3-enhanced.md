# Exercise 3: AI Recipe Assistant - Enhanced Guide (60 minutes)

## 🎯 Overview

Build an AI-powered recipe platform using GitHub Copilot's full capabilities:
- **Code Suggestion Mode**: Learn API integration patterns step-by-step
- **Agent Mode**: Rapidly prototype AI features and complex integrations

## 🤖 Development Approach Strategy

### Code Suggestions Excel At:
- Understanding OpenAI API patterns
- Building API endpoints methodically
- Learning error handling patterns
- Debugging API responses

### Agent Mode Excels At:
- Complete API architecture
- Complex prompt engineering
- Full-stack integration
- Production-ready features

## 📋 Prerequisites & Environment Setup

### Comprehensive Prerequisites Check

```markdown
# Copilot Agent Prompt:
Create a complete environment validator for an AI Recipe Assistant:

Check Requirements:
1. Development Tools:
   - Python 3.11+ with pip and venv
   - Node.js 18+ and npm
   - Git configured
   - Docker (optional for containers)
   - Azure CLI for deployment

2. API Keys and Accounts:
   - OpenAI API key validation
   - Check API quota and limits
   - Azure subscription
   - GitHub account with Copilot

3. Python Packages:
   - FastAPI and uvicorn
   - openai library
   - python-dotenv
   - httpx for async requests
   - Pillow for image processing

4. Security Checks:
   - .env file exists with template
   - .gitignore properly configured
   - No hardcoded secrets
   - HTTPS certificates for local dev

Create an interactive script that:
- Validates each requirement
- Tests OpenAI API connection
- Estimates API costs
- Sets up secure environment
- Creates project structure
- Initializes git repository

Include cost warnings and best practices.
```

**💡 Important**: OpenAI API costs money. Start with GPT-3.5-turbo for testing (cheaper) before using GPT-4.

## 🚀 Step-by-Step Implementation

### Step 1: Secure Project Setup (5 minutes)

#### Option A: Code Suggestion Approach

```bash
# Create project structure with security in mind
mkdir ai-recipe-assistant
cd ai-recipe-assistant

# Backend setup
mkdir backend
cd backend

# Create .env.example with comments
# OpenAI API configuration - NEVER commit actual keys
# OPENAI_API_KEY=sk-... (your key here)
# OPENAI_MODEL=gpt-3.5-turbo
# RATE_LIMIT_PER_MINUTE=5
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create a production-ready AI recipe assistant project:

Project Structure:
1. Security-First Setup:
   - backend/ (FastAPI + OpenAI)
   - frontend/ (React + Vite)
   - infrastructure/ (Bicep templates)
   - .github/workflows/ (CI/CD)
   - tests/ (comprehensive testing)
   - docs/ (API documentation)

2. Backend Configuration:
   File: backend/requirements.txt
   - fastapi==0.104.1
   - uvicorn[standard]
   - openai>=1.0.0
   - python-dotenv
   - redis (for caching)
   - slowapi (rate limiting)
   - pydantic[email]
   - asyncio
   - aiohttp
   - tenacity (for retries)

3. Environment Setup:
   File: backend/.env.example
   ```
   # OpenAI Configuration
   OPENAI_API_KEY=your-key-here
   OPENAI_MODEL=gpt-3.5-turbo
   OPENAI_MAX_TOKENS=2000
   OPENAI_TEMPERATURE=0.7
   
   # Rate Limiting
   RATE_LIMIT_PER_MINUTE=10
   RATE_LIMIT_PER_DAY=1000
   
   # Redis Cache
   REDIS_URL=redis://localhost:6379
   CACHE_TTL=3600
   
   # Security
   API_KEY=your-internal-api-key
   ALLOWED_ORIGINS=http://localhost:5173
   
   # Azure (for deployment)
   AZURE_STORAGE_CONNECTION=
   ```

4. Frontend Setup:
   - TypeScript configuration
   - Tailwind with custom theme
   - Environment validation
   - API client with interceptors

5. Docker Configuration:
   - Multi-stage Dockerfile
   - docker-compose for local dev
   - Health checks
   - Volume mounts for development

Include security scanning and dependency management.
```

**💡 Exploration Tip**: Add API key management UI! Let users bring their own OpenAI API keys for cost control.

### Step 2: AI-Powered Backend (15 minutes)

#### Option A: Code Suggestion Approach

```python
# backend/main.py
from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
import openai
import os
from dotenv import load_dotenv

# Load environment variables securely
load_dotenv()

# Configure OpenAI with error handling
# Check if API key exists, validate format
# Set up retry logic for API calls

class RecipeRequest(BaseModel):
    # Define request model with validation
    # ingredients: list of strings (min 2, max 20)
    # cuisine: optional string with enum values
    # dietary_restrictions: optional list
    # servings: int between 1-12
    
# Create recipe generation endpoint with:
# - Input validation
# - Rate limiting
# - Cost estimation
# - Error handling
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create a sophisticated AI recipe backend with production features:

Core API Implementation:
File: backend/main.py

1. Advanced Recipe Generation:
   ```python
   POST /api/v1/recipes/generate
   - Structured prompt engineering
   - Multiple recipe variations
   - Cooking difficulty levels
   - Equipment requirements
   - Shopping list generation
   - Wine pairing suggestions
   - Nutritional analysis
   - Cost estimation
   ```

2. Intelligent Features:
   ```python
   POST /api/v1/recipes/improve
   - Enhance existing recipes
   - Healthier alternatives
   - Dietary adaptations
   
   POST /api/v1/recipes/substitute
   - Smart ingredient substitutions
   - Allergy considerations
   - Available ingredients matching
   
   POST /api/v1/recipes/meal-plan
   - Weekly meal planning
   - Grocery optimization
   - Leftover utilization
   ```

3. Image Analysis (Advanced):
   ```python
   POST /api/v1/analyze/image
   - Detect ingredients from photos
   - Suggest recipes from fridge photos
   - Cooking progress analysis
   ```

4. Caching Strategy:
   - Redis for API responses
   - Embedding cache for similarity
   - User preference cache
   - Invalidation strategies

5. Cost Management:
   - Token counting before requests
   - Cost estimation per request
   - Daily/monthly limits
   - User quotas
   - Fallback to cheaper models

6. Error Handling:
   - Retry with exponential backoff
   - Graceful degradation
   - Fallback responses
   - User-friendly error messages

7. Monitoring:
   - Request logging
   - Performance metrics
   - Cost tracking
   - Error rates
   - User analytics

Include comprehensive tests and documentation.
```

**💡 Exploration Tip**: Add recipe style transfer! "Make this recipe in the style of Gordon Ramsay" or "Simplify for kids".

### Step 3: Interactive Frontend (15 minutes)

#### Option A: Code Suggestion Approach

```javascript
// frontend/src/App.jsx
import { useState } from 'react'
import axios from 'axios'

// Create a recipe generation UI with:
// - Ingredient input with autocomplete
// - Dietary restriction checkboxes
// - Cuisine selector with flags
// - Loading states with skeleton
// - Error handling with retry

function App() {
  // State for ingredients array
  // State for generated recipe
  // State for loading and errors
  
  // Function to add ingredients with validation
  // Function to generate recipe with cost warning
  // Function to save favorite recipes
}
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create a stunning AI recipe frontend with advanced UX:

Complete Frontend Implementation:
File: frontend/src/App.jsx (and components)

1. Intelligent Input System:
   Components to create:
   - IngredientInput.jsx
     * Autocomplete with common ingredients
     * Voice input support
     * Barcode scanning (mobile)
     * Quantity suggestions
     * Visual ingredient chips
   
   - DietaryFilters.jsx
     * Visual diet icons
     * Allergy warnings
     * Calorie targets
     * Macro tracking

   - CuisineSelector.jsx
     * World map interface
     * Popular cuisines carousel
     * Fusion options
     * Regional sub-cuisines

2. Recipe Generation UI:
   - RecipeGenerator.jsx
     * Multi-step wizard
     * Real-time cost estimation
     * Difficulty selector
     * Time constraints
     * Equipment available
     * Serving size slider
   
   - GeneratingAnimation.jsx
     * Chef animation
     * Fun food facts while waiting
     * Progress indicators
     * Cancel option

3. Recipe Display:
   - RecipeCard.jsx
     * Beautiful typography
     * Step-by-step mode
     * Cooking timer integration
     * Ingredient checklist
     * Video placeholder
     * Print-friendly view
     * Share functionality
   
   - NutritionInfo.jsx
     * Visual charts
     * Daily value percentages
     * Comparison with alternatives
     * Health score

4. Advanced Features:
   - RecipeHistory.jsx
     * Visual timeline
     * Favorite management
     * Rating system
     * Notes and modifications
     * Re-generate variations
   
   - MealPlanner.jsx
     * Drag-drop calendar
     * Shopping list aggregation
     * Prep schedule
     * Leftover tracking

   - RecipeChat.jsx
     * Ask questions about recipe
     * Cooking tips chat
     * Technique explanations
     * Real-time adjustments

5. Gamification:
   - Cooking achievements
   - Recipe streak counter
   - Skill level progression
   - Community challenges
   - Badge collection

6. Performance:
   - Image lazy loading
   - Virtual scrolling
   - Service worker caching
   - Optimistic updates
   - Background sync

Include TypeScript definitions and Storybook stories.
```

**💡 Exploration Tip**: Add a "Cooking Mode"! Large text, voice commands, and screen stays on while cooking.

### Step 4: AI Prompt Engineering (10 minutes)

#### Option A: Code Suggestion Approach

```python
# backend/prompts.py
# Create sophisticated prompts for better recipes

def create_recipe_prompt(ingredients, preferences):
    # Build a structured prompt that returns JSON
    # Include cooking times, difficulty, tips
    # Add personality to the recipe
    # Ensure food safety guidelines
    
system_prompt = """
You are a professional chef AI assistant...
# Let Copilot complete with best practices
"""
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create an advanced prompt engineering system:

Prompt Management System:
File: backend/services/prompt_service.py

1. Dynamic Prompt Templates:
   ```python
   class PromptTemplates:
       RECIPE_GENERATION = """
       You are a Michelin-starred chef AI with expertise in:
       - Global cuisines and fusion cooking
       - Dietary adaptations and allergies
       - Cost-effective meal planning
       - Nutritional optimization
       
       Create a recipe using: {ingredients}
       Constraints: {constraints}
       Style: {cooking_style}
       
       Return JSON with:
       - title: Creative, appetizing name
       - story: Brief origin or inspiration
       - difficulty: 1-5 with explanation
       - prep_time: realistic estimate
       - cook_time: active cooking time
       - total_time: including resting
       - servings: {servings}
       - ingredients: [{
           item: name,
           amount: with units,
           preparation: diced, sliced, etc,
           substitutions: [alternatives],
           notes: tips
         }]
       - equipment: required tools
       - instructions: [{
           step: number,
           action: clear description,
           time: duration,
           temperature: if applicable,
           technique_tip: pro advice,
           common_mistakes: what to avoid
         }]
       - plating: presentation advice
       - wine_pairing: suggestions
       - variations: 3 creative twists
       - leftovers: storage and reuse
       - nutrition: detailed breakdown
       """
   ```

2. Prompt Optimization:
   - A/B testing different prompts
   - Success rate tracking
   - User feedback integration
   - Prompt versioning
   - Temperature tuning

3. Context Enhancement:
   - User preference learning
   - Seasonal adjustments
   - Regional adaptations
   - Skill level matching
   - Previous recipe context

4. Safety and Quality:
   - Food safety validation
   - Allergen checking
   - Instruction clarity scoring
   - Complexity validation
   - Output sanitization

5. Multi-Model Strategy:
   - GPT-4 for complex recipes
   - GPT-3.5 for simple queries
   - Fallback chains
   - Model performance comparison
   - Cost optimization logic

Include prompt testing suite and metrics.
```

**💡 Exploration Tip**: Create "Chef Personalities"! Gordon Ramsay mode, Julia Child mode, or Grandma's style.

### Step 5: Azure Deployment (15 minutes)

#### Complete Azure Infrastructure

```markdown
# Copilot Agent Prompt:
Create production-ready Azure deployment for AI Recipe Assistant:

Infrastructure as Code:
File: infrastructure/main.bicep

1. Core Resources:
   ```bicep
   // Resource Group
   resource rg 'Microsoft.Resources/resourceGroups@2021-04-01'
   
   // App Service Plan (Linux, B2 minimum for AI workloads)
   resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01'
   
   // Backend Web App (Python 3.11)
   resource backendApp 'Microsoft.Web/sites@2021-02-01' = {
     properties: {
       siteConfig: {
         pythonVersion: '3.11'
         appSettings: [
           {
             name: 'OPENAI_API_KEY'
             value: '@Microsoft.KeyVault(SecretUri=${keyVault.properties.vaultUri}secrets/openai-key/)'
           }
         ]
       }
     }
   }
   
   // Frontend Static Web App
   resource frontendApp 'Microsoft.Web/staticSites@2021-02-01'
   
   // Redis Cache for API responses
   resource redis 'Microsoft.Cache/redis@2021-06-01' = {
     properties: {
       sku: {
         name: 'Basic'
         family: 'C'
         capacity: 0
       }
     }
   }
   
   // Key Vault for secrets
   resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview'
   
   // Application Insights
   resource appInsights 'Microsoft.Insights/components@2020-02-02'
   
   // API Management (optional for rate limiting)
   resource apiManagement 'Microsoft.ApiManagement/service@2021-08-01'
   
   // Cosmos DB for recipe storage
   resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts@2021-06-15'
   ```

2. Security Configuration:
   - Managed identities
   - Private endpoints
   - Network restrictions
   - WAF rules
   - DDoS protection

3. CI/CD Pipeline:
   File: .github/workflows/deploy-azure.yml
   ```yaml
   name: Deploy to Azure
   on:
     push:
       branches: [main]
   
   jobs:
     test:
       # Run all tests
       # Security scanning
       # Cost estimation
     
     deploy-infrastructure:
       # Deploy Bicep templates
       # Validate resources
     
     deploy-backend:
       # Build Python app
       # Run migrations
       # Deploy to App Service
       # Health checks
     
     deploy-frontend:
       # Build React app
       # Optimize assets
       # Deploy to Static Web App
       # Purge CDN
     
     integration-tests:
       # End-to-end tests
       # Performance tests
       # Security tests
   ```

4. Monitoring Setup:
   - Cost alerts
   - Performance metrics
   - API usage tracking
   - Error notifications
   - Custom dashboards

5. Disaster Recovery:
   - Automated backups
   - Multi-region setup
   - Failover procedures
   - Data replication

Include one-click deployment scripts and documentation.
```

**💡 Exploration Tip**: Add Azure Cognitive Services for multilingual support! Translate recipes in real-time.

### Step 6: Production Features (10 minutes)

#### Advanced Production Implementation

```markdown
# Copilot Agent Prompt:
Add enterprise-grade features to the AI Recipe Assistant:

1. User Management System:
   - Azure AD B2C integration
   - User profiles and preferences
   - Recipe collections
   - Sharing and collaboration
   - Usage quotas and billing

2. Advanced Analytics:
   - User behavior tracking
   - Popular ingredients trends
   - Recipe success rates
   - A/B testing framework
   - Custom events tracking

3. Performance Optimization:
   - CDN for static assets
   - Image optimization pipeline
   - API response compression
   - Database query optimization
   - Caching strategies

4. Compliance and Security:
   - GDPR compliance tools
   - Data export functionality
   - Audit logging
   - Penetration testing setup
   - Security headers

5. Business Features:
   - Subscription management
   - Payment integration
   - Email notifications
   - PDF recipe books
   - White-label options

Choose priority features based on your use case.
```

## 🎯 Challenge Extensions

### Push Beyond the Basics

```markdown
# Copilot Agent Prompt for Ultimate Features:

Transform the AI Recipe Assistant into a culinary platform:

1. Visual AI Features:
   - Real-time cooking guidance with camera
   - Plating suggestions with AR
   - Ingredient recognition from photos
   - Cooking technique analysis
   - Done-ness detection

2. Social Platform:
   - Recipe sharing community
   - Live cooking sessions
   - Chef competitions
   - Recipe NFTs
   - Ingredient marketplace

3. Restaurant Integration:
   - Menu analysis
   - Restaurant recipe recreation
   - Chef collaborations
   - Delivery integration
   - Virtual cooking classes

4. Health Integration:
   - Fitness app sync
   - Meal tracking
   - Doctor diet plans
   - Allergy management
   - Medication interactions

5. Smart Kitchen:
   - IoT device control
   - Automated shopping lists
   - Inventory management
   - Expiration tracking
   - Waste reduction

Build one complete vertical integration!
```

## ✅ Production Readiness Checklist

### Core Functionality
- [ ] Recipe generation working
- [ ] Error handling comprehensive
- [ ] Rate limiting implemented
- [ ] Caching layer active
- [ ] Cost tracking enabled

### Security & Compliance
- [ ] API keys secured
- [ ] HTTPS only
- [ ] Input validation
- [ ] Output sanitization
- [ ] Audit logging

### Performance
- [ ] Response time < 3s
- [ ] Concurrent user support
- [ ] CDN configured
- [ ] Database optimized
- [ ] Monitoring active

### Deployment
- [ ] Azure resources deployed
- [ ] CI/CD pipeline working
- [ ] Backup strategy
- [ ] Scaling configured
- [ ] Alerts set up

## 🎉 Mastery Achieved!

You've built a production-ready AI application using:
- **Code Suggestions** for learning AI integration patterns
- **Agent Mode** for complex architectural decisions
- **Azure** for enterprise deployment

**Reflection Points:**
1. How much did the AI assistance speed up development?
2. What unique features did you add?
3. How would you monetize this application?

**Portfolio Showcase:**
- Add OpenAI integration experience
- Demonstrate cloud deployment skills
- Show cost optimization strategies
- Highlight security implementations

**Next Steps:**
- Combine all three exercises into a productivity suite
- Create a mobile app version
- Build a business plan
- Teach others these AI techniques

**Remember**: You're not just a developer now—you're an AI-augmented engineer capable of building sophisticated applications at unprecedented speed!