# GitHub Copilot Prompts Collection - Module 07

## 🎯 Overview

This collection contains the most effective Copilot prompts for building web applications. Copy and adapt these for your projects.

## 📝 Exercise 1: Todo App Prompts

### Frontend Components

```javascript
// Complete Todo App
// Create a complete todo app component with:
// - State management using useState for todos array
// - Input field with "Add Todo" button
// - Todo list showing checkbox, text, and delete button
// - Filter buttons for All/Active/Completed
// - Todo counter showing "X items left"
// - Mark all complete functionality
// - Clear completed button
// - Use Tailwind CSS with modern gradient background
// - Add smooth transitions and hover effects

// Todo Item Component
// Create a TodoItem component that:
// - Shows checkbox that toggles completion
// - Displays todo text with strikethrough when completed
// - Has delete button with trash icon (use emoji)
// - Double-click to edit todo text
// - Escape key cancels edit, Enter saves
// - Smooth fade animations

// Filter Component  
// Create filter buttons that:
// - Show All, Active, Completed options
// - Highlight active filter
// - Update todo visibility
// - Show count badge for each filter
```

### Backend API

```python
# Complete FastAPI Todo Backend
# Create a FastAPI todo API with:
# - SQLAlchemy model: Todo(id, title, completed, created_at)
# - SQLite database with in-memory option
# - CRUD endpoints:
#   GET /todos - return all todos
#   POST /todos - create new todo
#   PUT /todos/{id} - update todo
#   DELETE /todos/{id} - delete todo
# - Pydantic models for validation
# - CORS middleware for localhost:5173
# - Error handling with proper status codes
# - Startup event to create tables

# Database Models
# Create SQLAlchemy models for:
# - Todo with id (auto-increment), title (string), completed (boolean)
# - Timestamps for created_at and updated_at
# - Method to convert to dictionary
# - Database session management
```

## 📝 Exercise 2: Notes App Prompts

### Layout & Structure

```javascript
// Three-Column Layout
// Create a responsive three-column layout:
// - Left sidebar (300px): note list with search
// - Center (flex-1): markdown editor
// - Right (flex-1): preview pane
// - Collapsible sidebar on mobile
// - Resizable panels with drag handle
// - Dark mode support with toggle

// Note List Component
// Create a NoteList component showing:
// - Note title (first line of content)
// - Preview text (first 100 chars)
// - Tags as colored badges
// - Relative timestamp (2 hours ago)
// - Selected state highlighting
// - Delete button on hover
// - Search highlighting in results
```

### Smart Features

```javascript
// Auto-tagging System
// Create auto-tagging that:
// - Extracts #hashtags from content
// - Identifies @mentions
// - Detects keywords: meeting, todo, idea, important
// - Suggests tags based on content
// - Different colors for tag types
// - Click tag to filter notes
// Return array of unique tags

// Fuzzy Search Implementation
// Implement search using Fuse.js that:
// - Searches in title, content, and tags
// - Shows results instantly as typing
// - Highlights matched terms
// - Shows match score/relevance
// - Clears with Escape key
// - Shows "No results found" message
// - Debounced by 300ms
```

### Markdown Editor

```javascript
// Split-View Markdown Editor
// Create editor with @uiw/react-md-editor:
// - Editor on left, preview on right
// - Synchronized scrolling
// - Custom toolbar with common actions
// - Support for:
//   - Tables
//   - Task lists
//   - Code blocks with syntax highlighting
//   - Images via drag-drop
// - Keyboard shortcuts (Cmd+B for bold, etc)
// - Auto-save indicator
```

## 📝 Exercise 3: Recipe AI Prompts

### AI Integration

```python
# OpenAI Recipe Generation
# Create recipe generation endpoint that:
# - Accepts: ingredients[], cuisine, dietary_restrictions
# - Constructs detailed prompt for OpenAI
# - Returns JSON with:
#   - title: creative recipe name
#   - description: appetizing description  
#   - prepTime: in minutes
#   - cookTime: in minutes
#   - servings: number
#   - ingredients: [{item, amount}]
#   - instructions: step-by-step array
#   - tips: cooking tips
#   - nutrition: {calories, protein, carbs, fat}
# - Handles API errors gracefully
# - Implements retry logic
# - Rate limiting (5 requests/minute)

# Substitution Suggestions
# Create endpoint for ingredient substitutions:
# - Input: ingredient name, dietary preference
# - Returns 3 alternatives with:
#   - Substitute name
#   - Conversion ratio
#   - Flavor impact
#   - Usage notes
# - Consider allergies and dietary restrictions
```

### Frontend Components

```javascript
// Recipe Input Interface
// Create ingredient input component:
// - Text input with "Add" button
// - Ingredients display as colorful chips/tags
// - Click X to remove ingredient
// - Minimum 3 ingredients validation
// - Autocomplete common ingredients
// - "Surprise me" button for random ingredients
// - Cuisine dropdown (Italian, Asian, Mexican, etc)
// - Dietary checkboxes (Vegetarian, Vegan, Gluten-free)

// Recipe Card Display
// Create beautiful recipe card showing:
// - Recipe title with gradient text effect
// - Prep/cook time with clock icons
// - Servings with person icon
// - Ingredients list with checkboxes
// - Step-by-step instructions (numbered)
// - Tips section with lightbulb emoji
// - Nutrition info in footer
// - Print button
// - Save to favorites (heart icon)
// - Share button
```

### Advanced Features

```javascript
// Image Upload with Dropzone
// Create image upload component:
// - Drag and drop area
// - Click to select file
// - Preview before upload
// - Progress bar during upload
// - File size validation (max 5MB)
// - Accepted formats: jpg, png, webp
// - Compress image before upload
// - Display uploaded image in recipe

// Recipe Collections
// Implement recipe collections:
// - Save recipes to localStorage
// - Organize in collections (Breakfast, Dinner, etc)
// - Search within collections
// - Export collection as JSON
// - Import recipes from JSON
// - Share collection via URL
```

## 🎨 Styling Prompts

### Tailwind CSS Patterns

```javascript
// Modern Gradient Background
// Add gradient background:
// - Use bg-gradient-to-br from-blue-50 to-indigo-100
// - Add subtle pattern overlay
// - Dark mode: from-gray-900 to-gray-800

// Card Styling
// Style cards with:
// - White background with shadow-lg
// - Rounded-xl corners
// - Hover: shadow-xl transform scale-[1.02]
// - Transition-all duration-200
// - Dark mode: bg-gray-800

// Button Styles
// Create button styles:
// - Primary: bg-blue-600 hover:bg-blue-700 text-white
// - Secondary: bg-gray-200 hover:bg-gray-300
// - Danger: bg-red-600 hover:bg-red-700
// - All with: px-4 py-2 rounded-lg transition-colors
// - Focus: ring-2 ring-offset-2
```

### Animations

```javascript
// Loading States
// Create loading skeleton:
// - Pulse animation for placeholder content
// - Match exact layout of loaded content
// - Subtle shimmer effect
// - Stagger animation for multiple items

// Transitions
// Add smooth transitions:
// - Fade in new items (opacity + translateY)
// - Slide out deleted items
// - Accordion expand/collapse
// - Tab switching with slide
// - Modal with backdrop fade
```

## 🛠️ Utility Prompts

### Error Handling

```javascript
// API Error Handling
// Create error handling for API calls:
// - Try-catch wrapper
// - User-friendly error messages
// - Toast notifications for errors
// - Retry logic with exponential backoff
// - Loading states during requests
// - Fallback UI for failures

// Form Validation
// Add form validation:
// - Required field checking
// - Email format validation
// - Minimum length requirements
// - Real-time validation feedback
// - Error messages below fields
// - Disable submit until valid
```

### Performance

```javascript
// Debounce Implementation
// Create debounced function for:
// - Search input (500ms delay)
// - Auto-save (1000ms delay)
// - Window resize handlers
// - API calls on typing
// Use useCallback to memoize

// Lazy Loading
// Implement lazy loading for:
// - Images with loading="lazy"
// - Components with React.lazy
// - Infinite scroll for lists
// - Virtual scrolling for large lists
// - Code splitting for routes
```

## 💡 Pro Tips

1. **Be Specific**: The more details in your prompt, the better the result
2. **Iterate**: Start simple, then add features incrementally
3. **Context Matters**: Include relevant imports and types in your file
4. **Learn Patterns**: Copilot learns from your code style
5. **Review Output**: Always review and test generated code

## 🚀 Quick Copy Templates

### Full Component Template
```javascript
// Create a [ComponentName] component that:
// - [Main functionality]
// - [UI requirements]
// - [State management needs]
// - [Event handlers]
// - [Styling requirements]
// - [Accessibility features]
```

### API Endpoint Template
```python
# Create [endpoint_name] endpoint that:
# - Method: [GET/POST/PUT/DELETE]
# - Path: [/api/path]
# - Input: [request model]
# - Process: [business logic]
# - Output: [response model]
# - Errors: [error handling]
```

### Feature Template
```javascript
// Implement [feature_name] that:
// - When: [trigger condition]
// - Does: [main action]
// - Shows: [UI feedback]
// - Handles: [edge cases]
// - Persists: [data storage]
```

Remember: These prompts are starting points. Adapt them to your specific needs and let Copilot's AI help you build faster!