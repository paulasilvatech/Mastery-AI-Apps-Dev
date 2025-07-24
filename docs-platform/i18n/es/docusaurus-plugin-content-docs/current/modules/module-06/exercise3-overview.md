---
sidebar_position: 4
title: "Exercise 3: Overview"
description: "## 🎯 Objective"
---

# Ejercicio 3: Real-time Collaboration Platform (⭐⭐⭐ Difícil)

## 🎯 Objective

Build a real-time collaboration platform that demonstrates mastery of multi-file projects, combining backend WebSocket servers, frontend applications, shared libraries, and complex state management—all orchestrated with GitHub Copilot's advanced workspace features.

**Duración**: 60-90 minutos  
**Difficulty**: ⭐⭐⭐ (Difícil)  
**Success Rate**: 60%

## 📋 Learning Goals

Al completar este ejercicio, usted:
1. Orchestrate complex multi-component systems with AI
2. Manage shared code between frontend and backend
3. Implement real-time bidirectional communication
4. Handle distributed state synchronization
5. Master Copilot Agent mode for large-scale refactoring
6. Apply all workspace navigation techniques

## 🏗️ What You'll Build

A real-time collaborative document editor featuring:
- Multi-user document editing
- Live cursor tracking
- User presence indicators
- Change history and versioning
- Conflict resolution
- Room-based collaboration
- Rich text editing support

## 📁 Project Structure

```
collab-platform/
├── backend/
│   ├── src/
│   │   ├── __init__.py
│   │   ├── api/
│   │   │   ├── __init__.py
│   │   │   ├── http/
│   │   │   │   ├── auth.py
│   │   │   │   ├── documents.py
│   │   │   │   └── rooms.py
│   │   │   └── websocket/
│   │   │       ├── __init__.py
│   │   │       ├── connection_manager.py
│   │   │       ├── handlers/
│   │   │       │   ├── document.py
│   │   │       │   ├── cursor.py
│   │   │       │   └── presence.py
│   │   │       └── events.py
│   │   ├── core/
│   │   │   ├── __init__.py
│   │   │   ├── config.py
│   │   │   ├── database.py
│   │   │   └── security.py
│   │   ├── models/
│   │   │   ├── __init__.py
│   │   │   ├── user.py
│   │   │   ├── document.py
│   │   │   ├── room.py
│   │   │   └── change.py
│   │   ├── services/
│   │   │   ├── __init__.py
│   │   │   ├── document_service.py
│   │   │   ├── sync_service.py
│   │   │   ├── conflict_resolver.py
│   │   │   └── presence_service.py
│   │   ├── utils/
│   │   │   ├── __init__.py
│   │   │   └── diff.py
│   │   └── main.py
│   ├── tests/
│   └── requirements.txt
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── Editor/
│   │   │   ├── Presence/
│   │   │   ├── Sidebar/
│   │   │   └── Toolbar/
│   │   ├── hooks/
│   │   │   ├── useWebSocket.ts
│   │   │   ├── useDocument.ts
│   │   │   └── usePresence.ts
│   │   ├── lib/
│   │   │   ├── websocket-client.ts
│   │   │   ├── document-sync.ts
│   │   │   └── cursor-tracker.ts
│   │   ├── pages/
│   │   ├── services/
│   │   └── types/
│   ├── package.json
│   └── tsconfig.json
├── shared/
│   ├── src/
│   │   ├── types/
│   │   │   ├── events.ts
│   │   │   ├── document.ts
│   │   │   └── user.ts
│   │   ├── utils/
│   │   │   └── validation.ts
│   │   └── index.ts
│   ├── package.json
│   └── tsconfig.json
├── docker-compose.yml
└── README.md
```

## 🚀 Step-by-Step Instructions

### Step 1: Initialize the Monorepo

1. Create the project structure:
```bash
mkdir collab-platform
cd collab-platform
```

2. **Use Copilot Agent for Initial Setup:**
   - Abrir VS Code: `code .`
   - Abrir Copilot Chat in Agent mode
   - Prompt: "Create a monorepo structure for a real-time collaboration platform with backend (Python/FastAPI), frontend (TypeScript/React), and shared types. Include all necessary config files."

### Step 2: Configurar ComParteird Types Library

1. Navigate to `shared/` directory

2. Create `package.json`:
```json
{
  "name": "@collab/shared",
  "version": "1.0.0",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc",
    "watch": "tsc -w"
  }
}
```

3. **Multi-file Type Generation:**
   - Abrir all files in `shared/src/types/`
   - Editar mode: "Create TypeScript interfaces for WebSocket events, document operations, user presence, and cursor positions. Make them compatible with both frontend and Python backend."

### Step 3: Implement Atrásend WebSocket Server

1. Set up backend ambiente:
```bash
cd backend
python -m venv venv
source venv/bin/activate
```

2. Create `requirements.txt`:
```txt
fastapi==0.104.1
uvicorn[standard]==0.24.0
websockets==12.0
sqlalchemy==2.0.23
redis==5.0.1
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
pydantic==2.5.0
pytest==7.4.3
pytest-asyncio==0.21.1
```

3. **Connection Manager Implementation:**
   - Abrir `src/api/websocket/connection_manager.py`
   - Copilot prompt:
   ```python
   # Create a ConnectionManager class that:
   # - Manages WebSocket connections by room
   # - Handles user join/leave events
   # - Broadcasts messages to room participants
   # - Tracks user presence and cursor positions
   # - Implements heartbeat/ping mechanism
   # Use Redis for distributed state
   ```

### Step 4: Document Synchronization Service

1. **Use @workspace for Analysis:**
   - In Copilot Chat: `@workspace analyze the shared types and create a document synchronization service that handles concurrent edits`

2. Abrir `src/services/sync_service.py`:
```python
# Implement Operational Transformation (OT) for:
# - Text insertions and deletions
# - Cursor position updates
# - Conflict resolution
# - Change history tracking
# Reference the shared types from the frontend
```

3. **Conflict Resolution Strategy:**
   - Use Copilot Agent: "Implement a conflict resolver that uses operational transformation to merge concurrent edits while preserving user intent"

### Step 5: Frontend Implementation

1. Set up frontend:
```bash
cd ../frontend
npm init -y
npm install react react-dom typescript @types/react @types/react-dom
npm install vite @vitejs/plugin-react
npm install socket.io-client quill react-quill
npm link ../shared
```

2. **WebSocket Hook Creation:**
   - Abrir `src/hooks/useWebSocket.ts`
   - Editar mode with multiple hooks files selected
   - Prompt: "Create React hooks for WebSocket connection, document synchronization, and presence tracking. Include automatic reconnection and error handling."

3. **Editaror Component:**
   ```typescript
   // In src/components/Editor/CollaborativeEditor.tsx
   // Create a Quill-based editor that:
   // - Sends changes via WebSocket
   // - Applies remote changes
   // - Shows other users' cursors
   // - Displays presence indicators
   ```

### Step 6: Implement Real-time Features

1. **Cursor Rutaing:**
   - Use @workspace: "Find all cursor-related types and create a cursor tracking system"
   - Implement smooth cursor animations
   - Color-code different users

2. **Presence System:**
   - Real-time user list
   - Online/offline indicators
   - User avatars and names

3. **Change Historial:**
   - Ruta all document changes
   - Implement undo/redo
   - Show revision history

### Step 7: Database and Persistence

1. **Database Models:**
   - Select all model files
   - Agent mode: "Create SQLAlchemy models for users, documents, rooms, and change history with proper relationships and indexes for performance"

2. **Redis Integration:**
   ```python
   # In src/core/redis.py
   # Set up Redis for:
   # - Active connections tracking
   # - Document state caching
   # - Presence information
   # - Distributed locks for critical sections
   ```

### Step 8: Integration Testing

1. **Create Integration Tests:**
   - Abrir `backend/tests/test_websocket.py`
   - Prompt: "Create integration tests that simulate multiple users editing a document simultaneously"

2. **Frontend E2E Tests:**
   ```bash
   cd frontend
   npm install -D playwright @playwright/test
   ```
   - Create tests for multi-user scenarios

### Step 9: Docker Configuration

1. Create `docker-compose.yml`:
```yaml
# Use Copilot to generate a complete docker-compose file with:
# - Backend service
# - Frontend service  
# - PostgreSQL database
# - Redis
# - Nginx reverse proxy
```

### Step 10: Performance Optimization

1. **Use Copilot for Analysis:**
   ```
   @workspace identify performance bottlenecks in the WebSocket handling and suggest optimizations
   ```

2. Implement suggested optimizations:
   - Message batching
   - Debouncing cursor updates
   - Efficient diff algorithms
   - Connection pooling

## 🎯 Validation Criteria

Your implementation should:
- [ ] Support 10+ concurrent users
- [ ] Handle network disconnections gracefully
- [ ] Resolve editing conflicts correctly
- [ ] Show real-time cursor positions
- [ ] Maintain document integrity
- [ ] Include comprehensive error handling
- [ ] Provide smooth user experience

## 💡 Master-Level Copilot Techniques

1. **Cross-Stack Refactoring:**
   ```
   @workspace update all WebSocket event names from snake_case to camelCase across frontend and backend
   ```

2. **Architecture Analysis:**
   ```
   @workspace create a sequence diagram showing the flow of a document edit from frontend to backend and back
   ```

3. **Performance Profiling:**
   ```
   @workspace add performance logging to all WebSocket message handlers
   ```

4. **Security Audit:**
   ```
   @workspace check for potential security vulnerabilities in WebSocket handlers
   ```

## 🐛 Avanzado Troubleshooting

### WebSocket Connection Issues
- Verificar CORS configuration
- Verify WebSocket upgrade headers
- Monitor connection pool limits

### Synchronization Problems
- Implement vector clocks
- Add operation sequencing
- Use distributed locks

### Performance Degradation
- Perfil message processing
- Implement message queuing
- Use connection pooling

## 🚀 Extension Challenges

1. **Add Voice/Video Chat**
   - Integrate WebRTC
   - Implement signaling server
   - Add media controls

2. **Collaborative Drawing**
   - Add whiteboard feature
   - Sync drawing operations
   - Implement shape tools

3. **AI Assistant Integration**
   - Add AI-powered suggestions
   - Grammar checking
   - Auto-completion

4. **Mobile Support**
   - Create React Native app
   - Optimize for touch
   - Handle offline mode

## 📊 Architecture Mejores Prácticas

- Use event sourcing for document changes
- Implement CQRS for read/write separation
- Add circuit breakers for external services
- Use message queues for async operations
- Implement proper logging and monitoring

## ✅ Mastery Verificarlist

- [ ] All real-time features work smoothly
- [ ] System handles concurrent edits correctly
- [ ] Presence system updates instantly
- [ ] Cursor tracking is accurate
- [ ] Document state remains consistent
- [ ] Error recovery is seamless
- [ ] Performance is optimized
- [ ] Code is well-organized across 20+ files
- [ ] Used all Copilot workspace features effectively

## 🎉 Congratulations!

You've built a producción-grade real-time collaboration platform! This exercise demonstrates mastery of:
- Complex multi-file architectures
- Cross-stack desarrollo
- Real-time system design
- Avanzado Copilot techniques

---

**What's Next?** 
- Apply these techniques to your own projects
- Explore Module 7 for web application patterns
- Share your implementation with the community!