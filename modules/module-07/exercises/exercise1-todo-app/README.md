# Exercise 1: AI-Powered Todo Application (⭐ Easy)

## Overview

In this exercise, you'll build a modern todo application with both frontend and backend, leveraging GitHub Copilot to accelerate development. This foundational exercise teaches full-stack development patterns with AI assistance.

## Learning Objectives

- Create a responsive React frontend with Copilot
- Build a FastAPI backend with database integration
- Implement real-time updates using WebSockets
- Generate AI-powered task suggestions
- Deploy the application using Docker

## Instructions

The complete instructions for this exercise are divided into parts:

1. **Part 1**: [Setup and Backend Development](./instructions/part1.md)
2. **Part 2**: [Frontend Implementation](./instructions/part2.md)
3. **Part 3**: [AI Features and Deployment](./instructions/part3.md)

## Project Structure

```
exercise1-todo-app/
├── README.md          # This file
├── instructions/      # Step-by-step guides
│   ├── part1.md      # Backend setup
│   ├── part2.md      # Frontend development
│   └── part3.md      # AI features & deployment
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

- Python 3.11+ with pip
- Node.js 18+ with npm
- Docker Desktop running
- GitHub Copilot enabled in VS Code
- Basic React and FastAPI knowledge

## Quick Start

```bash
# Navigate to exercise directory
cd exercises/exercise1-todo-app

# Run setup script
./setup.sh

# Start development
code .
```

## Duration

**Expected Time**: 30-45 minutes
- Setup: 5 minutes
- Backend: 15 minutes
- Frontend: 15 minutes
- Testing: 10 minutes

## Success Criteria

- [ ] Backend API responds to all CRUD operations
- [ ] Frontend displays and updates todos in real-time
- [ ] AI suggestions work when adding new tasks
- [ ] Application runs in Docker containers
- [ ] All tests pass successfully
