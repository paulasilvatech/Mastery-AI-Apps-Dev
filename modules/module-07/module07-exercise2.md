# Exercise 2: Smart Notes Platform (60 minutes)

## 🎯 Overview

Build an intelligent note-taking application with markdown support, auto-tagging, and full-text search. This exercise focuses on creating smart features using AI assistance.

## 🚀 Quick Start

### Step 1: Setup (3 minutes)

```bash
# Navigate to exercise folder
cd exercises/exercise-2-notes/starter/frontend

# Install dependencies (should be pre-installed)
npm install

# Additional packages needed
npm install @uiw/react-md-editor react-icons fuse.js uuid date-fns

# Start the development server
npm run dev
```

### Step 2: Access Your App

- Check the **PORTS** tab
- Click the 🌐 icon next to port 5173
- App opens in a new browser tab

## 📝 Implementation Guide

### Part 1: App Layout & Structure (10 minutes)

Create the main `App.jsx`:

```javascript
// Copilot Prompt: Create a note-taking app with:
// - Three-column layout: sidebar (note list), editor, preview
// - Header with search bar and new note button
// - Dark mode toggle
// - Responsive design that collapses to mobile view
// - Use Tailwind CSS for all styling

import { useState, useEffect } from 'react'
import MDEditor from '@uiw/react-md-editor'
import { FiSearch, FiPlus, FiTag, FiTrash2, FiMoon, FiSun } from 'react-icons/fi'
import Fuse from 'fuse.js'
import { v4 as uuidv4 } from 'uuid'
import { format, formatDistanceToNow } from 'date-fns'

function App() {
  // Let Copilot build the complete layout!
}
```

**Key Components to Generate:**
1. `<Sidebar />` - Note list with search
2. `<Editor />` - Markdown editor
3. `<Preview />` - Rendered markdown
4. `<SearchBar />` - Fuzzy search input

### Part 2: Note Management (15 minutes)

```javascript
// Copilot Prompt: Add note CRUD operations:
// - Note structure: { id, title, content, tags, createdAt, updatedAt }
// - Create new note with default title "Untitled Note"
// - Update note content with auto-save (debounced 500ms)
// - Delete note with confirmation
// - Select note to edit
// - Extract title from first line of content

const [notes, setNotes] = useState([])
const [selectedNoteId, setSelectedNoteId] = useState(null)
const [searchTerm, setSearchTerm] = useState('')

// Let Copilot implement all CRUD functions!
```

### Part 3: Markdown Editor Integration (10 minutes)

```javascript
// Copilot Prompt: Integrate markdown editor:
// - Split view: editor on left, preview on right
// - Sync scrolling between editor and preview
// - Support GFM (GitHub Flavored Markdown)
// - Toolbar with common formatting buttons
// - Keyboard shortcuts (Cmd/Ctrl + B for bold, etc.)

function NoteEditor({ note, onUpdateNote }) {
  // Copilot will create the editor component
}
```

### Part 4: Smart Auto-tagging (10 minutes)

```javascript
// Copilot Prompt: Implement intelligent auto-tagging:
// - Extract #hashtags from content
// - Detect @mentions
// - Identify keywords: "meeting", "todo", "idea", "important"
// - Auto-tag based on content patterns
// - Display tags as colorful badges
// - Click tag to filter notes

function extractTags(content) {
  // Let Copilot implement smart extraction
}

function TagList({ tags, onTagClick, onTagRemove }) {
  // Colorful, interactive tag display
}
```

### Part 5: Full-Text Search (10 minutes)

```javascript
// Copilot Prompt: Implement fuzzy search with Fuse.js:
// - Search in title, content, and tags
// - Highlight matched terms
// - Show match score
// - Instant results as you type
// - Clear search with Escape key
// - Show "No results" message

const fuseOptions = {
  keys: ['title', 'content', 'tags'],
  threshold: 0.3,
  includeScore: true,
  includeMatches: true
}

// Search implementation
```

### Part 6: Persistence & Polish (5 minutes)

```javascript
// Copilot Prompt: Add localStorage persistence:
// - Save notes to localStorage on every change
// - Load notes on app startup
// - Handle corrupted data gracefully
// - Add import/export functionality
// - Show save indicator

// Auto-save to localStorage
useEffect(() => {
  localStorage.setItem('smart-notes', JSON.stringify(notes))
}, [notes])
```

## 🎨 UI Enhancements

### Color Scheme & Themes

```javascript
// Copilot Prompts for styling:
// "Add a gradient background with subtle animation"
// "Create smooth transitions between light/dark mode"
// "Style the sidebar with glassmorphism effect"
// "Add hover effects to note items"
// "Create a floating action button for new notes"
```

### Empty States & Loading

```javascript
// Copilot: Create beautiful empty states:
// - "No notes yet" with illustration
// - "No search results" with suggestions
// - Loading skeletons while searching
// - Tooltips for all actions
```

## 💡 Advanced Features

### Quick Add Features

```javascript
// 1. Note Templates
// Copilot: Add template selector for new notes:
// - Meeting notes template
// - Daily journal template  
// - Project planning template

// 2. Quick Actions
// Copilot: Add command palette (Cmd/Ctrl + K):
// - Quick search
// - Create note
// - Toggle dark mode
// - Export all notes

// 3. Rich Media
// Copilot: Support image paste from clipboard
// - Drag & drop images
// - Image preview in markdown
```

## 🐛 Common Issues & Fixes

### Markdown Editor Not Rendering?
```javascript
// Ensure you import the CSS
import '@uiw/react-md-editor/markdown-editor.css'
import '@uiw/react-markdown-preview/markdown.css'
```

### Search Too Slow?
```javascript
// Debounce the search
const debouncedSearch = useMemo(
  () => debounce((term) => setSearchTerm(term), 300),
  []
)
```

### Tags Not Extracting?
```javascript
// Simple regex patterns
const hashtags = content.match(/#\w+/g) || []
const mentions = content.match(/@\w+/g) || []
```

## ✅ Feature Checklist

- [ ] Three-column responsive layout
- [ ] Create, edit, delete notes
- [ ] Markdown editor with live preview
- [ ] Auto-tagging system working
- [ ] Fuzzy search implemented
- [ ] Dark mode toggle
- [ ] localStorage persistence
- [ ] Keyboard shortcuts
- [ ] Mobile responsive

## 🎯 Testing Your App

1. **Create Multiple Notes**
   - Try different content types
   - Add hashtags and mentions
   - Check auto-tagging

2. **Search Functionality**
   - Search by title
   - Search by content
   - Search by tags

3. **Persistence**
   - Refresh the page
   - Notes should remain

4. **Responsive Design**
   - Resize browser window
   - Test mobile view

## 🚀 Bonus Challenges

1. **Collaboration Features**
   ```javascript
   // Copilot: Add note sharing via URL
   ```

2. **Export Options**
   ```javascript
   // Copilot: Export notes as Markdown, PDF, or JSON
   ```

3. **Voice Notes**
   ```javascript
   // Copilot: Add voice-to-text for note creation
   ```

## 🎉 Completed?

Excellent work! You've built a smart note-taking app with AI features.

**What You Achieved:**
- 📝 Full markdown editing
- 🏷️ Intelligent auto-tagging
- 🔍 Powerful search
- 💾 Persistent storage
- 🎨 Beautiful UI

**Next Steps:**
1. Commit your work
2. Take a short break
3. Move on to Exercise 3: AI Recipe Assistant

```bash
git add .
git commit -m "Complete Exercise 2: Smart Notes Platform"
```

---

**Pro Tip**: The best note apps disappear and let you focus on writing. Keep the UI minimal and the features powerful!