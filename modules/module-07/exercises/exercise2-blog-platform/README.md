# Exercise 2: Blog Platform with AI Features (⭐⭐ Medium)

## Overview

In this exercise, you'll build a full-featured blog platform with AI-powered content assistance. This intermediate exercise introduces authentication, rich text editing, and more complex state management patterns.

## Learning Objectives

- Implement user authentication with JWT tokens
- Build a rich text editor with AI assistance
- Create a comment system with moderation
- Apply SEO optimization techniques
- Handle image uploads and management

## Instructions

The complete instructions for this exercise are divided into parts:

1. **Part 1**: [Authentication and Backend Setup](./instructions/part1.md)
2. **Part 2**: [Blog Post Management](./instructions/part2.md)
3. **Part 3**: [Comments and AI Features](./instructions/part3.md)

## Project Structure

```
exercise2-blog-platform/
├── README.md          # This file
├── instructions/      # Step-by-step guides
│   ├── part1.md      # Auth & backend setup
│   ├── part2.md      # Blog functionality
│   └── part3.md      # Comments & AI
├── starter/          # Starting code templates
│   ├── backend/
│   └── frontend/
├── solution/         # Complete working solution
│   ├── backend/
│   └── frontend/
└── tests/           # Validation tests
    ├── backend/
    └── frontend/
```

## Prerequisites

- Completed Exercise 1 or equivalent experience
- Understanding of authentication concepts
- Basic knowledge of rich text editing
- GitHub Copilot enabled in VS Code

## Quick Start

```bash
# Navigate to exercise directory
cd exercises/exercise2-blog-platform

# Run setup script
./setup.sh

# Start development
code .
```

## Duration

**Expected Time**: 45-60 minutes
- Setup & Auth: 20 minutes
- Blog Features: 20 minutes
- Comments & AI: 20 minutes

## Key Features

- **User Management**
  - Registration with email verification
  - JWT-based authentication
  - User profiles with avatars

- **Blog Posts**
  - Rich text editor (Markdown/WYSIWYG)
  - AI-powered content suggestions
  - Draft and publish states
  - Categories and tags

- **Comments System**
  - Nested comments support
  - AI-powered moderation
  - Real-time updates

- **SEO & Performance**
  - Meta tags management
  - Server-side rendering ready
  - Image optimization
  - Caching strategies

## Success Criteria

- [ ] Users can register and login securely
- [ ] Authors can create, edit, and delete posts
- [ ] Rich text editor works with AI suggestions
- [ ] Comments system supports threading
- [ ] SEO meta tags are properly generated
- [ ] All tests pass successfully
