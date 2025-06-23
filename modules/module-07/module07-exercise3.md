# Exercise 3: AI Recipe Assistant (60 minutes)

## 🎯 Overview

Build an AI-powered recipe platform that generates recipes from ingredients, suggests substitutions, and provides a delightful cooking experience. This exercise integrates real AI capabilities using OpenAI.

## 🚀 Quick Start

### Step 1: Setup (5 minutes)

```bash
# Terminal 1 - Backend
cd exercises/exercise-3-recipes/starter/backend
source venv/bin/activate
pip install -r requirements.txt

# Copy and configure environment
cp .env.example .env
# Edit .env and add your OpenAI API key

# Start backend
uvicorn main:app --reload

# Terminal 2 - Frontend
cd exercises/exercise-3-recipes/starter/frontend
npm install
npm run dev
```

### Step 2: Configure API Key

1. Get your OpenAI API key from https://platform.openai.com/api-keys
2. Edit `backend/.env`:
   ```
   OPENAI_API_KEY=sk-...your-key-here
   ```

## 📝 Implementation Guide

### Part 1: Backend AI Integration (15 minutes)

Create `main.py` with AI capabilities:

```python
# Copilot Prompt: Create a FastAPI recipe app with:
# - OpenAI integration for recipe generation
# - Endpoint: POST /api/generate-recipe
# - Input: ingredients list, cuisine type, dietary restrictions
# - Generate detailed recipe with title, ingredients, instructions
# - Error handling for API failures
# - Rate limiting to prevent abuse
# - CORS for frontend access

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import openai
import os
from dotenv import load_dotenv
import json

load_dotenv()
openai.api_key = os.getenv("OPENAI_API_KEY")

# Let Copilot build the complete API!
```

**Key Endpoints to Create:**
1. `POST /api/generate-recipe` - AI recipe generation
2. `POST /api/suggest-substitutions` - Ingredient substitutions
3. `POST /api/analyze-image` - (Bonus) Image ingredient detection
4. `GET /api/recipes/search` - Search saved recipes

### Part 2: Recipe Generation Logic (10 minutes)

```python
# Copilot Prompt: Create recipe generation with:
# - Smart prompt engineering for better results
# - Structured JSON response
# - Cooking tips and variations
# - Nutritional estimates
# - Error handling and retries

async def generate_recipe_prompt(ingredients: List[str], cuisine: str = None, dietary: str = None):
    prompt = f"""
    Create a detailed recipe using these ingredients: {', '.join(ingredients)}
    Cuisine preference: {cuisine or 'any'}
    Dietary restrictions: {dietary or 'none'}
    
    Return a JSON object with:
    - title: creative recipe name
    - description: appetizing description
    - prepTime: minutes
    - cookTime: minutes  
    - servings: number
    - ingredients: [{item: string, amount: string}]
    - instructions: step by step array
    - tips: cooking tips array
    - nutritionEstimate: {calories: number, protein: string}
    """
    
    # Let Copilot complete the OpenAI call
```

### Part 3: Frontend Recipe UI (15 minutes)

Create an engaging `App.jsx`:

```javascript
// Copilot Prompt: Create a recipe app UI with:
// - Ingredient input with tag-style chips
// - Cuisine selector (Italian, Asian, Mexican, etc.)
// - Dietary options (Vegetarian, Vegan, Gluten-free)
// - Generate recipe button with loading state
// - Beautiful recipe card display
// - Print and save functionality
// - Modern design with food emojis

import { useState } from 'react'
import axios from 'axios'
import { 
  PlusIcon, 
  XMarkIcon, 
  ClockIcon, 
  UserGroupIcon,
  SparklesIcon,
  PrinterIcon,
  HeartIcon 
} from '@heroicons/react/24/outline'

function App() {
  // Let Copilot create the complete UI!
}
```

### Part 4: Recipe Display Component (10 minutes)

```javascript
// Copilot Prompt: Create RecipeCard component that:
// - Shows recipe title with gradient text
// - Prep/cook time with clock icons
// - Ingredients with checkboxes (track what you have)
// - Step-by-step instructions with numbers
// - Tips section with lightbulb emoji
// - Nutrition info in a subtle footer
// - Print-friendly layout
// - Save to favorites (localStorage)

function RecipeCard({ recipe, onSave }) {
  const [checkedIngredients, setCheckedIngredients] = useState([])
  
  // Beautiful recipe presentation
}
```

### Part 5: Smart Features (10 minutes)

```javascript
// Copilot Prompt: Add intelligent features:
// 1. Ingredient suggestions as you type
// 2. "Surprise me" button for random ingredients
// 3. Recipe history in sidebar
// 4. Filters for quick/easy recipes
// 5. Share recipe via URL
// 6. Export shopping list

// Common ingredients for autocomplete
const commonIngredients = [
  'chicken', 'rice', 'pasta', 'tomatoes', 'onion', 
  'garlic', 'cheese', 'eggs', 'milk', 'flour'
]

// Implement smart features
```

### Part 6: Image Upload (Bonus - 10 minutes)

```javascript
// Copilot Prompt: Add image features:
// - Upload recipe photo
// - Drag and drop support
// - Image preview before upload
// - Store image URL with recipe
// - Display in recipe card

import { useDropzone } from 'react-dropzone'

function ImageUpload({ onImageSelected }) {
  // Implement dropzone
}
```

## 🎨 UI Design & Styling

### Modern Recipe Card Design

```javascript
// Copilot Prompts for beautiful UI:
// "Create a recipe card with frosted glass effect"
// "Add subtle animations when recipe generates"
// "Use food emojis throughout the UI"
// "Create a loading skeleton that looks like a recipe"
// "Add confetti when saving a favorite recipe"
```

### Color Scheme

```javascript
// Warm, food-inspired colors
const colors = {
  primary: 'orange-500',
  secondary: 'green-600',
  accent: 'red-500',
  background: 'amber-50'
}
```

## 💡 Advanced Features

### 1. Substitution Engine

```python
# Backend endpoint for smart substitutions
@app.post("/api/suggest-substitutions")
async def suggest_substitutions(ingredient: str):
    prompt = f"Suggest 3 cooking substitutions for {ingredient} with ratios"
    # Complete with OpenAI
```

### 2. Recipe Collections

```javascript
// Save and organize recipes
const collections = {
  'Quick Meals': [],
  'Date Night': [],
  'Meal Prep': []
}
```

### 3. Meal Planning

```javascript
// Weekly meal planner
// Copilot: Create a 7-day meal planning grid
```

## 🐛 Troubleshooting

### OpenAI API Issues

```python
# Check API key
print(f"API Key configured: {'Yes' if openai.api_key else 'No'}")

# Handle rate limits
try:
    response = await openai.ChatCompletion.create(...)
except openai.error.RateLimitError:
    raise HTTPException(429, "Too many requests, please try again later")
```

### CORS Problems

```python
# Ensure CORS allows your frontend URL
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## ✅ Testing Checklist

- [ ] Can input multiple ingredients
- [ ] Recipe generates successfully
- [ ] Loading state shows during generation
- [ ] Recipe displays beautifully
- [ ] Can save favorite recipes
- [ ] Dietary restrictions work
- [ ] Error messages are user-friendly
- [ ] UI is responsive on mobile

## 🎯 Test Scenarios

1. **Basic Recipe**
   - Ingredients: chicken, rice, broccoli
   - Should generate a complete meal

2. **Dietary Restrictions**
   - Ingredients: tofu, vegetables
   - Dietary: Vegan
   - Should respect restrictions

3. **Cuisine Specific**
   - Ingredients: pasta, tomatoes, basil
   - Cuisine: Italian
   - Should generate Italian dish

4. **Error Handling**
   - Try with only 1 ingredient
   - Test with invalid API key
   - Check rate limit handling

## 🚀 Deployment (5 minutes)

### Deploy Backend to Railway

```bash
# In backend folder
echo "web: uvicorn main:app --host 0.0.0.0 --port $PORT" > Procfile
pip freeze > requirements.txt

# Deploy with Railway CLI
railway login
railway init
railway up
```

### Deploy Frontend to Vercel

```bash
# In frontend folder
npm run build
npx vercel --prod

# Set environment variable
# VITE_API_URL = your-railway-url
```

## 🎉 Completed?

Congratulations! You've built a production-ready AI recipe assistant!

**What You Achieved:**
- 🤖 Real AI integration with OpenAI
- 🍳 Smart recipe generation
- 🎨 Beautiful, modern UI
- 📱 Responsive design
- 🚀 Deployed to production

**Final Steps:**
1. Test your deployed app
2. Share the URL with classmates
3. Commit your final code

```bash
git add .
git commit -m "Complete Exercise 3: AI Recipe Assistant"
git push
```

## 🏆 Module Complete!

You've successfully completed Module 07! In just 3 hours, you've:
- Built 3 complete full-stack applications
- Integrated real AI capabilities
- Used GitHub Copilot for rapid development
- Deployed to production

**Key Takeaways:**
- AI can dramatically accelerate development
- Focus on features, let Copilot handle boilerplate
- Modern web apps can be built in hours, not days

---

**What's Next?**
- Enhance your apps with more features
- Combine all three exercises into one super app
- Continue to Module 08: API Development
- Share your creations on social media!

🎊 **Excellent work! You're now an AI-powered web developer!** 🎊