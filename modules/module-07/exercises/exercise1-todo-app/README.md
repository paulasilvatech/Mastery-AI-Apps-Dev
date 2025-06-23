# Exercise 1: Full-Stack Todo Application

## 📋 Overview

Build a complete full-stack Todo application using modern web technologies. This exercise teaches you how to create a production-ready application with React frontend, Node.js backend, database integration, and proper DevOps practices.

## 🎯 Learning Objectives

By completing this exercise, you will:

- ✅ Build a React frontend with TypeScript
- ✅ Create a RESTful API with Express.js
- ✅ Implement database operations (MongoDB/PostgreSQL)
- ✅ Add authentication and authorization
- ✅ Write comprehensive tests (unit & integration)
- ✅ Containerize the application with Docker
- ✅ Set up CI/CD pipelines
- ✅ Deploy to cloud platforms

## 📁 Structure

```
exercise1-todo-app/
├── README.md                   # This file
├── instructions/               # Step-by-step guides
│   ├── part1.md               # Backend development
│   ├── part2.md               # Frontend development
│   └── part3.md               # Deployment & DevOps
├── setup.sh                   # Environment setup script
├── starter/                   # Starting templates
│   ├── backend/              # Backend starter code
│   │   ├── src/             # Source files
│   │   ├── tests/           # Test files
│   │   ├── package.json     # Dependencies
│   │   └── Dockerfile       # Container config
│   └── frontend/            # Frontend starter code
│       ├── src/             # React components
│       ├── public/          # Static assets
│       ├── package.json     # Dependencies
│       └── Dockerfile       # Container config
├── solution/                  # Complete implementation
│   ├── backend/              # Full backend solution
│   │   ├── src/
│   │   │   ├── models/      # Data models
│   │   │   ├── routes/      # API routes
│   │   │   ├── middleware/  # Custom middleware
│   │   │   ├── services/    # Business logic
│   │   │   └── app.js       # Express app
│   │   ├── tests/           # All tests
│   │   └── docker-compose.yml
│   └── frontend/            # Full frontend solution
│       ├── src/
│       │   ├── components/  # React components
│       │   ├── hooks/       # Custom hooks
│       │   ├── services/    # API services
│       │   ├── store/       # State management
│       │   └── App.tsx      # Main component
│       └── tests/           # Frontend tests
└── tests/                     # E2E tests
    ├── cypress/              # Cypress tests
    └── postman/              # API tests
```

## 🚀 Getting Started

### Prerequisites

1. **Node.js**: Version 18.x or later
   ```bash
   node --version
   ```

2. **Docker**: For containerization
   ```bash
   docker --version
   ```

3. **Git**: For version control

4. **Database**: MongoDB or PostgreSQL
   - MongoDB: `mongod --version`
   - PostgreSQL: `psql --version`

5. **Code Editor**: VS Code recommended

### Quick Start

1. **Clone and setup**:
   ```bash
   cd exercise1-todo-app
   ./setup.sh
   ```

2. **Start the backend**:
   ```bash
   cd starter/backend
   npm install
   npm run dev
   ```

3. **Start the frontend**:
   ```bash
   cd starter/frontend
   npm install
   npm start
   ```

4. **Access the application**:
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:5000
   - API Docs: http://localhost:5000/api-docs

## 📚 Exercise Parts

### Part 1: Backend Development (45 mins)
- Set up Express.js server
- Create Todo CRUD endpoints
- Implement database models
- Add input validation
- Write API tests

### Part 2: Frontend Development (60 mins)
- Create React components
- Implement state management
- Connect to backend API
- Add user authentication
- Style with CSS/Tailwind

### Part 3: Deployment & DevOps (45 mins)
- Containerize applications
- Set up GitHub Actions
- Deploy to cloud (Azure/AWS)
- Configure monitoring
- Implement logging

## 🎨 Features to Implement

### Core Features
- ✅ Create new todos
- ✅ List all todos
- ✅ Update todo status
- ✅ Delete todos
- ✅ Filter todos (all/active/completed)
- ✅ Mark all as complete

### Advanced Features
- 🎯 User authentication
- 🎯 Todo categories/tags
- 🎯 Due dates & reminders
- 🎯 Search functionality
- 🎯 Drag & drop reordering
- 🎯 Dark mode toggle

## 🏗️ Architecture

### Backend Stack
- **Framework**: Express.js
- **Language**: JavaScript/TypeScript
- **Database**: MongoDB with Mongoose / PostgreSQL with Prisma
- **Authentication**: JWT tokens
- **Validation**: Joi/Express-validator
- **Testing**: Jest & Supertest

### Frontend Stack
- **Framework**: React 18
- **Language**: TypeScript
- **State**: Context API / Redux Toolkit
- **Styling**: Tailwind CSS / Material-UI
- **HTTP Client**: Axios
- **Testing**: React Testing Library

### DevOps Stack
- **Containers**: Docker & Docker Compose
- **CI/CD**: GitHub Actions
- **Cloud**: Azure App Service / AWS ECS
- **Monitoring**: Application Insights
- **Logging**: Winston / Morgan

## 📊 Success Criteria

### Functionality
- [ ] ✅ All CRUD operations work correctly
- [ ] ✅ Data persists in database
- [ ] ✅ Frontend updates in real-time
- [ ] ✅ Authentication protects routes
- [ ] ✅ Error handling is robust

### Code Quality
- [ ] ✅ Code follows style guide
- [ ] ✅ TypeScript types are proper
- [ ] ✅ No console errors/warnings
- [ ] ✅ Tests have >80% coverage
- [ ] ✅ Docker builds successfully

### Deployment
- [ ] ✅ CI/CD pipeline passes
- [ ] ✅ Application deploys cleanly
- [ ] ✅ Health checks pass
- [ ] ✅ Monitoring is active
- [ ] ✅ Logs are accessible

## 🛠️ Troubleshooting

### Common Issues

1. **Port already in use**:
   ```bash
   # Find process using port
   lsof -i :3000
   # Kill process
   kill -9 <PID>
   ```

2. **Database connection fails**:
   - Check if database is running
   - Verify connection string
   - Check firewall settings

3. **CORS errors**:
   - Ensure backend allows frontend origin
   - Check API endpoint URLs

### Debug Commands

```bash
# Backend logs
npm run dev:debug

# Frontend debug
npm start -- --inspect

# Database queries
npm run db:debug

# Test specific file
npm test -- --watch todo.test.js
```

## 🏆 Bonus Challenges

1. **Real-time Updates**: Add WebSocket support
2. **Offline Support**: Implement PWA features
3. **Multi-tenant**: Support multiple users
4. **API Rate Limiting**: Prevent abuse
5. **Internationalization**: Multi-language support

## 📖 Resources

- 📚 [React Documentation](https://react.dev/)
- 🚀 [Express.js Guide](https://expressjs.com/)
- 🗄️ [MongoDB University](https://university.mongodb.com/)
- 🐳 [Docker Documentation](https://docs.docker.com/)
- 🔧 [Jest Testing](https://jestjs.io/)
- 📊 [GitHub Actions](https://docs.github.com/actions)

## 🤝 Need Help?

1. Check the solution code for reference
2. Review error messages carefully
3. Use browser DevTools for debugging
4. Check the [Module 7 Troubleshooting Guide](../../troubleshooting.md)

## ⏭️ Next Steps

After completing this exercise:
1. Add more advanced features
2. Improve performance (caching, pagination)
3. Move to [Exercise 2: Blog Platform](../exercise2-blog-platform/)
4. Deploy to production with a custom domain

---

**Remember**: Building full-stack applications requires patience and practice. Focus on one feature at a time and test as you go! 🚀
