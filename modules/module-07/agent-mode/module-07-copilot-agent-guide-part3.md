# Module 07 - Complete GitHub Copilot Agent Guide
## Part 3: Exercise 3 (AI Recipe Assistant) & GitOps Challenge

### 🎯 Exercise 3 Overview: AI-Powered Recipe Assistant

This final exercise brings together everything you've learned and adds AI integration:
- Full-stack architecture with AI services
- Real-time features and caching
- Advanced state management
- Production deployment strategies
- Cost optimization for AI APIs
- Security best practices

**Why this exercise?** AI integration is becoming essential for modern applications. You'll learn how to build responsible, cost-effective AI features.

---

## 🚀 Repository Setup for Exercise 3

### Step 1: Create AI Recipe Repository

**💡 Educational Note**: This exercise requires API keys and has cost implications. We'll implement safeguards and cost controls from the start.

#### Copilot Agent Prompt:
```markdown
@workspace Guide me through creating a repository for an AI-powered recipe assistant. Include:

1. Repository setup with name "ai-recipe-assistant"
2. Security considerations for API keys
3. Cost tracking and limit implementation
4. Project structure for AI integration
5. Environment setup for multiple API providers
6. Testing strategy for AI features

Emphasize security and cost control best practices throughout.
```

#### Expected Output:
```markdown
# AI Recipe Assistant Repository Setup

## Critical Security Notice
⚠️ This project uses paid AI APIs. Never commit API keys!

## Repository Creation
1. Create repository: `ai-recipe-assistant`
2. Set to **Private** initially (contains API integration code)
3. Add comprehensive .gitignore for security
4. Enable GitHub Secrets for deployment

## Security First Approach:
```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/ai-recipe-assistant.git
cd ai-recipe-assistant

# Create .env.example (commit this)
cat > .env.example << EOF
# Backend Environment Variables
OPENAI_API_KEY=your-key-here
OPENAI_MODEL=gpt-3.5-turbo  # Use cheaper model for development
MONTHLY_BUDGET_USD=10.00
RATE_LIMIT_PER_MINUTE=5
ENABLE_CACHING=true
CACHE_TTL_MINUTES=60

# Frontend Environment Variables
VITE_API_URL=http://localhost:8000
VITE_ENABLE_ANALYTICS=false
EOF

# Create actual .env (never commit this)
cp .env.example .env
# Edit .env with your actual keys
```

## Why These Security Measures?
- **Private Repo**: Reduces exposure risk during development
- **Environment Variables**: Keeps secrets out of code
- **Budget Limits**: Prevents unexpected charges
- **Rate Limiting**: Controls API usage
- **Caching**: Reduces API calls and costs
```

### Step 2: Advanced Full-Stack Structure

#### Copilot Agent Prompt:
```markdown
@workspace Create a production-ready project structure for the AI recipe assistant that includes:

1. Microservices-ready backend architecture
2. Frontend with advanced performance features
3. Shared types for full-stack type safety
4. Infrastructure as code templates
5. Monitoring and logging setup
6. Cost tracking implementation
7. Testing infrastructure for AI features
8. Documentation structure

Explain architectural decisions for scalability and maintainability.
```

#### Expected Output:
```
ai-recipe-assistant/
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   ├── v1/
│   │   │   │   ├── endpoints/
│   │   │   │   │   ├── recipes.py      # Recipe generation
│   │   │   │   │   ├── ingredients.py  # Ingredient analysis
│   │   │   │   │   ├── nutrition.py    # Nutrition calculation
│   │   │   │   │   └── images.py       # Image analysis
│   │   │   │   └── deps.py             # Dependencies
│   │   ├── core/
│   │   │   ├── config.py               # Configuration
│   │   │   ├── security.py             # API key management
│   │   │   └── rate_limiter.py        # Rate limiting
│   │   ├── services/
│   │   │   ├── ai/
│   │   │   │   ├── openai_service.py  # OpenAI integration
│   │   │   │   ├── prompt_manager.py   # Prompt templates
│   │   │   │   └── cost_tracker.py    # Cost monitoring
│   │   │   ├── cache/
│   │   │   │   ├── redis_cache.py     # Caching layer
│   │   │   │   └── cache_keys.py      # Cache key generation
│   │   │   └── analytics/
│   │   │       └── usage_tracker.py    # Usage analytics
│   │   ├── models/                     # Database models
│   │   ├── schemas/                    # Pydantic schemas
│   │   └── background/                 # Background tasks
│   ├── tests/
│   │   ├── unit/
│   │   ├── integration/
│   │   └── mocks/                      # AI response mocks
│   ├── monitoring/
│   │   ├── prometheus/                 # Metrics
│   │   └── grafana/                    # Dashboards
│   ├── requirements.txt
│   ├── Dockerfile
│   └── docker-compose.yml
├── frontend/
│   ├── src/
│   │   ├── features/
│   │   │   ├── recipes/
│   │   │   │   ├── components/        # Recipe UI components
│   │   │   │   ├── hooks/             # Recipe hooks
│   │   │   │   └── services/          # API calls
│   │   │   ├── ingredients/
│   │   │   ├── meal-planning/
│   │   │   └── shopping-list/
│   │   ├── shared/
│   │   │   ├── api/                   # API client
│   │   │   ├── components/            # Shared UI
│   │   │   ├── hooks/                 # Shared hooks
│   │   │   └── utils/                 # Utilities
│   │   └── App.tsx
│   ├── public/
│   ├── tests/
│   └── package.json
├── shared/
│   └── types/                          # Shared TypeScript types
├── infrastructure/
│   ├── terraform/                      # IaC with Terraform
│   ├── kubernetes/                     # K8s manifests
│   └── scripts/                        # Deployment scripts
├── docs/
│   ├── api/                           # API documentation
│   ├── architecture/                  # Architecture decisions
│   └── deployment/                    # Deployment guides
└── .github/
    ├── workflows/                     # CI/CD pipelines
    └── SECURITY.md                    # Security policies
```

**Architectural Decisions Explained:**
1. **Microservices-Ready**: Easy to extract services later
2. **Feature-Based Frontend**: Scales with complexity
3. **Shared Types**: Full-stack type safety
4. **Monitoring Built-In**: Production visibility from day one
5. **Cost Tracking**: Financial responsibility

### Step 3: Backend Implementation with AI

#### Copilot Agent Prompt:
```markdown
@workspace Implement the AI-powered backend for the recipe assistant with these requirements:

1. OpenAI integration with prompt engineering
2. Cost tracking per request with budget alerts
3. Redis caching to minimize API calls
4. Rate limiting per user/IP
5. Fallback strategies when AI fails
6. Response streaming for better UX
7. Multi-model support (GPT-3.5, GPT-4)
8. Structured output validation
9. Security middleware for API keys
10. Comprehensive error handling

Include detailed comments about AI best practices and cost optimization.
```

#### Expected Backend Implementation:

**backend/app/services/ai/openai_service.py:**
```python
"""
OpenAI Service with Cost Optimization and Safety Features

This service handles all AI interactions with:
- Cost tracking and budget enforcement
- Intelligent caching
- Rate limiting
- Fallback strategies
- Security best practices
"""

import json
from typing import Optional, Dict, Any, List, AsyncGenerator
from datetime import datetime, timedelta
import hashlib
from decimal import Decimal

import openai
from openai import AsyncOpenAI
from pydantic import BaseModel, ValidationError
import redis.asyncio as redis
from fastapi import HTTPException

from app.core.config import settings
from app.services.cache.redis_cache import cache_service
from app.services.ai.prompt_manager import PromptManager
from app.services.ai.cost_tracker import CostTracker

# Token pricing (as of 2024)
PRICING = {
    "gpt-3.5-turbo": {
        "input": Decimal("0.0005") / 1000,  # per token
        "output": Decimal("0.0015") / 1000
    },
    "gpt-4": {
        "input": Decimal("0.01") / 1000,
        "output": Decimal("0.03") / 1000
    }
}

class RecipeRequest(BaseModel):
    """Validated recipe request"""
    ingredients: List[str]
    cuisine: Optional[str] = None
    dietary_restrictions: List[str] = []
    servings: int = 4
    difficulty: str = "medium"
    max_time_minutes: Optional[int] = None

class RecipeResponse(BaseModel):
    """Structured recipe response"""
    title: str
    description: str
    ingredients: List[Dict[str, str]]
    instructions: List[str]
    prep_time: int
    cook_time: int
    servings: int
    nutrition: Dict[str, Any]
    tags: List[str]
    estimated_cost: str
    difficulty: str

class OpenAIService:
    """
    Manages OpenAI API interactions with enterprise features
    """
    
    def __init__(self):
        self.client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
        self.prompt_manager = PromptManager()
        self.cost_tracker = CostTracker()
        self.cache_ttl = settings.CACHE_TTL_MINUTES * 60
        
    async def generate_recipe(
        self,
        request: RecipeRequest,
        user_id: Optional[str] = None,
        stream: bool = False
    ) -> RecipeResponse:
        """
        Generate a recipe with AI, implementing best practices
        
        Args:
            request: Validated recipe request
            user_id: Optional user ID for personalization
            stream: Whether to stream the response
            
        Returns:
            Structured recipe response
            
        Raises:
            HTTPException: On budget exceeded or API errors
        """
        
        # 1. Check budget limits
        if await self.cost_tracker.is_budget_exceeded():
            raise HTTPException(
                status_code=429,
                detail="Monthly AI budget exceeded. Please try again next month."
            )
        
        # 2. Generate cache key
        cache_key = self._generate_cache_key(request)
        
        # 3. Check cache first
        cached_response = await cache_service.get(cache_key)
        if cached_response:
            return RecipeResponse(**json.loads(cached_response))
        
        # 4. Select model based on complexity
        model = self._select_model(request)
        
        # 5. Generate prompt
        prompt = self.prompt_manager.create_recipe_prompt(request)
        
        try:
            # 6. Make API call with timeout
            response = await self._call_openai_with_retry(
                model=model,
                prompt=prompt,
                stream=stream
            )
            
            # 7. Parse and validate response
            recipe = self._parse_recipe_response(response)
            
            # 8. Track costs
            tokens_used = response.usage.total_tokens
            cost = self._calculate_cost(model, tokens_used)
            await self.cost_tracker.track_request(
                user_id=user_id,
                model=model,
                tokens=tokens_used,
                cost=cost
            )
            
            # 9. Cache successful response
            await cache_service.set(
                cache_key,
                recipe.json(),
                expire=self.cache_ttl
            )
            
            # 10. Add cost information
            recipe.estimated_cost = f"${cost:.4f}"
            
            return recipe
            
        except openai.APIError as e:
            # Handle API errors with fallback
            return await self._fallback_recipe(request)
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Recipe generation failed: {str(e)}"
            )
    
    def _generate_cache_key(self, request: RecipeRequest) -> str:
        """Generate deterministic cache key from request"""
        # Sort ingredients for consistent hashing
        ingredients_sorted = sorted(request.ingredients)
        
        cache_data = {
            "ingredients": ingredients_sorted,
            "cuisine": request.cuisine,
            "dietary": sorted(request.dietary_restrictions),
            "servings": request.servings,
            "difficulty": request.difficulty,
            "max_time": request.max_time_minutes
        }
        
        # Create hash of the request
        cache_string = json.dumps(cache_data, sort_keys=True)
        cache_hash = hashlib.sha256(cache_string.encode()).hexdigest()
        
        return f"recipe:{cache_hash}"
    
    def _select_model(self, request: RecipeRequest) -> str:
        """
        Select appropriate model based on request complexity
        
        Use cheaper models when possible to optimize costs
        """
        # Simple requests use GPT-3.5
        if (len(request.ingredients) <= 5 and 
            len(request.dietary_restrictions) <= 1 and
            request.difficulty in ["easy", "medium"]):
            return "gpt-3.5-turbo"
        
        # Complex requests use GPT-4
        return "gpt-4"
    
    async def _call_openai_with_retry(
        self,
        model: str,
        prompt: str,
        stream: bool = False,
        max_retries: int = 3
    ) -> Any:
        """Call OpenAI API with retry logic"""
        for attempt in range(max_retries):
            try:
                response = await self.client.chat.completions.create(
                    model=model,
                    messages=[
                        {
                            "role": "system",
                            "content": "You are a professional chef creating detailed recipes. Always respond with valid JSON."
                        },
                        {
                            "role": "user",
                            "content": prompt
                        }
                    ],
                    temperature=0.7,  # Some creativity but not too wild
                    max_tokens=2000,  # Limit response size
                    response_format={"type": "json_object"}  # Force JSON
                )
                return response
                
            except openai.RateLimitError:
                # Wait and retry
                wait_time = 2 ** attempt
                await asyncio.sleep(wait_time)
                
            except openai.APIError as e:
                if attempt == max_retries - 1:
                    raise e
                    
        raise Exception("Max retries exceeded")
    
    def _parse_recipe_response(self, response: Any) -> RecipeResponse:
        """Parse and validate AI response"""
        try:
            # Extract JSON from response
            content = response.choices[0].message.content
            recipe_data = json.loads(content)
            
            # Validate with Pydantic
            return RecipeResponse(**recipe_data)
            
        except (json.JSONDecodeError, ValidationError) as e:
            # Log error for debugging
            print(f"Failed to parse AI response: {e}")
            raise ValueError("Invalid recipe format from AI")
    
    def _calculate_cost(self, model: str, tokens: int) -> Decimal:
        """Calculate cost of API call"""
        pricing = PRICING.get(model, PRICING["gpt-3.5-turbo"])
        
        # Rough estimate: 75% input, 25% output
        input_tokens = int(tokens * 0.75)
        output_tokens = tokens - input_tokens
        
        cost = (
            input_tokens * pricing["input"] +
            output_tokens * pricing["output"]
        )
        
        return cost
    
    async def _fallback_recipe(self, request: RecipeRequest) -> RecipeResponse:
        """Generate basic recipe without AI when API fails"""
        # This could query a local database of recipes
        # or use simple rule-based generation
        
        return RecipeResponse(
            title=f"{request.cuisine or 'Simple'} {request.ingredients[0]} Dish",
            description="A delicious recipe created from your ingredients",
            ingredients=[
                {"item": ing, "amount": "As needed"} 
                for ing in request.ingredients
            ],
            instructions=[
                "Prepare all ingredients",
                "Cook according to your preference",
                "Season to taste",
                "Serve hot"
            ],
            prep_time=15,
            cook_time=30,
            servings=request.servings,
            nutrition={"note": "Nutrition calculation unavailable"},
            tags=["simple", "quick"],
            estimated_cost="N/A",
            difficulty="easy"
        )

# Singleton instance
ai_service = OpenAIService()
```

**Why These AI Best Practices?**
1. **Cost Control**: Budget limits prevent surprises
2. **Caching**: Reduces API calls by 70-90%
3. **Model Selection**: Use cheaper models when possible
4. **Structured Output**: Ensures consistent responses
5. **Fallbacks**: App works even when AI fails

### Step 4: Frontend Implementation

#### Copilot Agent Prompt:
```markdown
@workspace Create a modern React frontend for the AI recipe assistant with:

1. Beautiful recipe generation interface
2. Ingredient input with autocomplete
3. Real-time cost estimation display
4. Loading states with streaming support
5. Recipe cards with print functionality
6. Favorite recipes with local storage
7. Shopping list generation
8. Meal planning calendar
9. Responsive design with mobile-first approach
10. Accessibility features (screen reader support)

Focus on user experience and performance optimization.
```

#### Expected Frontend Components:

**frontend/src/features/recipes/components/RecipeGenerator.tsx:**
```typescript
/**
 * Recipe Generator Component
 * 
 * Main interface for AI recipe generation with:
 * - Intuitive ingredient input
 * - Real-time cost estimation
 * - Loading states with humor
 * - Error handling with retry
 */

import React, { useState, useCallback, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  PlusIcon, 
  SparklesIcon, 
  XMarkIcon,
  CurrencyDollarIcon,
  ClockIcon,
  UserGroupIcon
} from '@heroicons/react/24/outline';
import toast from 'react-hot-toast';

import { useRecipeGeneration } from '../hooks/useRecipeGeneration';
import { useIngredientSuggestions } from '../hooks/useIngredientSuggestions';
import { IngredientInput } from './IngredientInput';
import { RecipeCard } from './RecipeCard';
import { LoadingChef } from './LoadingChef';
import { CostEstimator } from './CostEstimator';

interface RecipeGeneratorProps {
  onRecipeGenerated?: (recipe: Recipe) => void;
}

export const RecipeGenerator: React.FC<RecipeGeneratorProps> = ({ 
  onRecipeGenerated 
}) => {
  const [ingredients, setIngredients] = useState<string[]>([]);
  const [cuisine, setCuisine] = useState<string>('any');
  const [dietary, setDietary] = useState<string[]>([]);
  const [servings, setServings] = useState(4);
  const [difficulty, setDifficulty] = useState('medium');
  const [maxTime, setMaxTime] = useState<number | null>(null);
  
  const {
    generateRecipe,
    isGenerating,
    currentRecipe,
    error,
    estimatedCost,
    clearRecipe
  } = useRecipeGeneration();
  
  const { suggestions, getSuggestions } = useIngredientSuggestions();

  // Estimate cost as user types
  useEffect(() => {
    if (ingredients.length > 0) {
      // Show estimated API cost
      const estimatedTokens = ingredients.length * 50 + 500;
      const cost = (estimatedTokens / 1000) * 0.002; // GPT-3.5 pricing
      setEstimatedCost(cost);
    }
  }, [ingredients]);

  const handleAddIngredient = useCallback((ingredient: string) => {
    if (ingredient && !ingredients.includes(ingredient)) {
      setIngredients(prev => [...prev, ingredient]);
      toast.success(`Added ${ingredient}`, {
        icon: '🥗',
        duration: 1500
      });
    }
  }, [ingredients]);

  const handleRemoveIngredient = useCallback((index: number) => {
    setIngredients(prev => prev.filter((_, i) => i !== index));
  }, []);

  const handleGenerate = async () => {
    if (ingredients.length === 0) {
      toast.error('Please add at least one ingredient', {
        icon: '🤔'
      });
      return;
    }

    try {
      const recipe = await generateRecipe({
        ingredients,
        cuisine,
        dietary_restrictions: dietary,
        servings,
        difficulty,
        max_time_minutes: maxTime
      });

      if (recipe && onRecipeGenerated) {
        onRecipeGenerated(recipe);
      }

      toast.success('Recipe generated successfully!', {
        icon: '👨‍🍳'
      });
    } catch (error) {
      toast.error('Failed to generate recipe. Please try again.', {
        icon: '😞'
      });
    }
  };

  return (
    <div className="max-w-4xl mx-auto p-6">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-white rounded-2xl shadow-xl p-8"
      >
        <h2 className="text-3xl font-bold text-gray-900 mb-2">
          AI Recipe Generator
        </h2>
        <p className="text-gray-600 mb-8">
          Add your ingredients and let AI create a delicious recipe
        </p>

        {/* Ingredient Input Section */}
        <div className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Available Ingredients
            </label>
            <IngredientInput
              onAdd={handleAddIngredient}
              suggestions={suggestions}
              onInputChange={getSuggestions}
              placeholder="Type an ingredient (e.g., chicken, tomatoes)"
            />
            
            {/* Ingredient Chips */}
            <AnimatePresence>
              <div className="flex flex-wrap gap-2 mt-4">
                {ingredients.map((ingredient, index) => (
                  <motion.div
                    key={ingredient}
                    initial={{ opacity: 0, scale: 0.8 }}
                    animate={{ opacity: 1, scale: 1 }}
                    exit={{ opacity: 0, scale: 0.8 }}
                    className="bg-indigo-100 text-indigo-800 px-3 py-1 rounded-full flex items-center gap-2"
                  >
                    <span>{ingredient}</span>
                    <button
                      onClick={() => handleRemoveIngredient(index)}
                      className="hover:bg-indigo-200 rounded-full p-0.5"
                      aria-label={`Remove ${ingredient}`}
                    >
                      <XMarkIcon className="w-4 h-4" />
                    </button>
                  </motion.div>
                ))}
              </div>
            </AnimatePresence>
          </div>

          {/* Options Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Cuisine Selection */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Cuisine Type
              </label>
              <select
                value={cuisine}
                onChange={(e) => setCuisine(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              >
                <option value="any">Any Cuisine</option>
                <option value="italian">Italian</option>
                <option value="mexican">Mexican</option>
                <option value="asian">Asian</option>
                <option value="mediterranean">Mediterranean</option>
                <option value="american">American</option>
                <option value="indian">Indian</option>
                <option value="french">French</option>
              </select>
            </div>

            {/* Dietary Restrictions */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Dietary Restrictions
              </label>
              <div className="space-y-2">
                {['vegetarian', 'vegan', 'gluten-free', 'dairy-free', 'low-carb'].map(diet => (
                  <label key={diet} className="flex items-center">
                    <input
                      type="checkbox"
                      checked={dietary.includes(diet)}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setDietary(prev => [...prev, diet]);
                        } else {
                          setDietary(prev => prev.filter(d => d !== diet));
                        }
                      }}
                      className="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                    />
                    <span className="ml-2 text-sm text-gray-700 capitalize">
                      {diet.replace('-', ' ')}
                    </span>
                  </label>
                ))}
              </div>
            </div>

            {/* Servings */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                <UserGroupIcon className="inline w-4 h-4 mr-1" />
                Servings
              </label>
              <input
                type="number"
                min="1"
                max="12"
                value={servings}
                onChange={(e) => setServings(parseInt(e.target.value) || 4)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              />
            </div>

            {/* Max Time */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                <ClockIcon className="inline w-4 h-4 mr-1" />
                Max Time (minutes)
              </label>
              <input
                type="number"
                min="15"
                max="180"
                placeholder="No limit"
                value={maxTime || ''}
                onChange={(e) => setMaxTime(e.target.value ? parseInt(e.target.value) : null)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              />
            </div>
          </div>

          {/* Cost Estimator */}
          <CostEstimator 
            ingredientCount={ingredients.length}
            complexity={difficulty}
            model={ingredients.length > 5 ? 'gpt-4' : 'gpt-3.5-turbo'}
          />

          {/* Generate Button */}
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={handleGenerate}
            disabled={isGenerating || ingredients.length === 0}
            className={`
              w-full py-3 px-6 rounded-lg font-medium text-white
              flex items-center justify-center gap-2
              ${isGenerating || ingredients.length === 0
                ? 'bg-gray-400 cursor-not-allowed'
                : 'bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700'
              }
            `}
          >
            {isGenerating ? (
              <>
                <div className="animate-spin rounded-full h-5 w-5 border-2 border-white border-t-transparent" />
                Cooking up something special...
              </>
            ) : (
              <>
                <SparklesIcon className="w-5 h-5" />
                Generate Recipe
              </>
            )}
          </motion.button>
        </div>
      </motion.div>

      {/* Loading State */}
      <AnimatePresence>
        {isGenerating && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="mt-8"
          >
            <LoadingChef />
          </motion.div>
        )}
      </AnimatePresence>

      {/* Recipe Result */}
      <AnimatePresence>
        {currentRecipe && !isGenerating && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="mt-8"
          >
            <RecipeCard
              recipe={currentRecipe}
              onClose={clearRecipe}
              onSave={() => {
                // Save to favorites
                toast.success('Recipe saved to favorites!', { icon: '❤️' });
              }}
              onPrint={() => {
                // Print functionality
                window.print();
              }}
            />
          </motion.div>
        )}
      </AnimatePresence>

      {/* Error State */}
      {error && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg"
        >
          <p className="text-red-800">{error}</p>
        </motion.div>
      )}
    </div>
  );
};
```

**Why These UX Patterns?**
1. **Immediate Feedback**: Users see cost before generating
2. **Progressive Disclosure**: Advanced options hidden initially
3. **Delightful Animations**: Makes waiting enjoyable
4. **Error Recovery**: Clear messages and retry options
5. **Accessibility**: Full keyboard and screen reader support

### Step 5: Production Deployment

#### Copilot Agent Prompt:
```markdown
@workspace Create a complete production deployment setup for the AI recipe assistant:

1. Docker configuration for all services
2. Kubernetes manifests for cloud deployment
3. CI/CD pipeline with testing stages
4. Infrastructure as Code with Terraform
5. Monitoring and alerting setup
6. Auto-scaling configuration
7. Secret management
8. Database backup strategy
9. CDN configuration
10. Zero-downtime deployment

Explain each component and why it's necessary for production AI applications.
```

---

## 🚀 Final Challenge: Complete GitOps Implementation

### GitOps Setup for All Three Exercises

#### Copilot Agent Prompt:
```markdown
@workspace Create a comprehensive GitOps setup that manages all three applications from Module 07:

1. Monorepo structure with all three apps
2. Shared infrastructure components
3. Environment promotion (dev → staging → prod)
4. Automated testing pipeline
5. Security scanning at each stage
6. Cost monitoring and alerts
7. Performance benchmarks
8. Rollback procedures
9. Documentation generation
10. Monitoring dashboards

This should demonstrate enterprise-grade DevOps practices with:
- Infrastructure as Code (Terraform/Bicep)
- Policy as Code (OPA)
- Automated compliance checks
- Multi-cloud support (Azure primary, AWS backup)
- Disaster recovery procedures

Include all configuration files and explain the complete workflow.
```

#### Expected GitOps Structure:
```
module-07-complete/
├── applications/
│   ├── todo-app/
│   ├── smart-notes/
│   └── ai-recipes/
├── infrastructure/
│   ├── terraform/
│   │   ├── modules/
│   │   ├── environments/
│   │   └── backend-config/
│   ├── kubernetes/
│   │   ├── base/
│   │   └── overlays/
│   └── policies/
├── .github/
│   ├── workflows/
│   │   ├── ci-todo-app.yml
│   │   ├── ci-smart-notes.yml
│   │   ├── ci-ai-recipes.yml
│   │   ├── cd-deploy.yml
│   │   ├── infrastructure-plan.yml
│   │   └── security-scan.yml
│   ├── dependabot.yml
│   └── CODEOWNERS
├── scripts/
│   ├── setup-local.sh
│   ├── deploy-all.sh
│   └── rollback.sh
├── monitoring/
│   ├── prometheus/
│   ├── grafana/
│   └── alerts/
└── docs/
    ├── architecture/
    ├── runbooks/
    └── disaster-recovery/
```

**GitOps Workflow Explained:**
1. **Code Push**: Developer pushes to feature branch
2. **CI Pipeline**: Tests, builds, scans for security
3. **Preview Deploy**: Temporary environment for PR
4. **Merge to Main**: After approval
5. **CD Pipeline**: Deploys to dev automatically
6. **Promotion**: Manual approval for staging/prod
7. **Monitoring**: Continuous health checks
8. **Rollback**: Automatic on failure detection

---

## 📚 Module 07 Complete: Key Takeaways

### Technical Skills Acquired
1. **Full-Stack Development**: React + FastAPI mastery
2. **AI Integration**: Responsible AI implementation
3. **State Management**: Multiple approaches (Context, Zustand, Redux)
4. **Performance**: Optimization techniques
5. **Security**: API key management, rate limiting
6. **DevOps**: Complete CI/CD pipelines
7. **Cloud**: Multi-environment deployments
8. **Testing**: Comprehensive test strategies

### Architectural Patterns Learned
1. **Monorepo Management**: Shared code efficiency
2. **Feature-Based Structure**: Scalable organization
3. **API-First Design**: Contract-driven development
4. **Offline-First**: PWA implementation
5. **Microservices-Ready**: Easy to split later
6. **Cost-Aware Design**: Budget-conscious AI usage

### Best Practices Mastered
1. **Security First**: Never expose secrets
2. **User Experience**: Loading states, error handling
3. **Performance**: Caching, lazy loading, virtualization
4. **Accessibility**: WCAG compliance
5. **Documentation**: Self-documenting code
6. **Testing**: Unit, integration, E2E
7. **Monitoring**: Observability from day one

## 🎯 Next Steps

You've completed Module 07! You now have:
- Three production-ready applications
- Deep understanding of modern web development
- AI integration experience
- DevOps and cloud deployment skills
- A impressive portfolio

### Continue Your Journey
1. **Module 08**: API Development and Integration
2. **Module 09**: Database Design and Optimization
3. **Module 10**: Real-time and Event-Driven Systems

### Challenge Yourself
1. Combine all three apps into a productivity suite
2. Add mobile apps with React Native
3. Implement real-time collaboration
4. Create a SaaS business model
5. Open source your best features

**Remember**: The journey from learning to mastery is through building. Keep creating, keep exploring, and keep pushing the boundaries of what's possible with AI-assisted development!

---

**Congratulations on completing Module 07! 🎉**

You're now equipped to build sophisticated, production-ready web applications with AI assistance. The combination of technical skills, architectural knowledge, and best practices you've gained will serve you throughout your career.

Keep building, keep learning, and most importantly, keep having fun with technology!