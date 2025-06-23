# Module 07: Frequently Asked Questions

## 🎯 General Module Questions

### Q: How long should each exercise take?
**A:** The exercises are designed with the following time estimates:
- Exercise 1 (Todo App): 30-45 minutes
- Exercise 2 (Blog Platform): 45-60 minutes
- Exercise 3 (AI Dashboard): 60-90 minutes

However, these are estimates. Take the time you need to understand the concepts fully.

### Q: Can I use different technologies than specified?
**A:** While the exercises are designed for FastAPI and React, the concepts apply to other frameworks. However:
- Starter code and solutions use the specified stack
- Support materials assume FastAPI/React
- For best learning experience, follow the prescribed stack
- Apply learnings to your preferred stack afterward

### Q: What if I get stuck on an exercise?
**A:** Follow this troubleshooting sequence:
1. Check the troubleshooting guide for common issues
2. Review the instructions - you may have missed a step
3. Look at the starter code for hints
4. Use GitHub Copilot with more specific prompts
5. Check the solution but try to understand, not copy
6. Post in the discussion forum with specific questions

## 🤖 GitHub Copilot Questions

### Q: Copilot isn't giving me good suggestions. What should I do?
**A:** Improve Copilot's suggestions by:
1. **Write clear comments first**:
   ```python
   # Create a function that validates email addresses using regex
   # Should return True for valid emails, False otherwise
   # Handle edge cases like missing @ or invalid domains
   ```

2. **Use descriptive names**:
   ```python
   def validate_email_address(email: str) -> bool:
       # Copilot understands the intent from the function name
   ```

3. **Provide context**:
   ```python
   # This is part of a user registration system
   # We need to ensure emails are valid before creating accounts
   ```

### Q: Should I accept all Copilot suggestions?
**A:** No! Always:
- Review suggestions for correctness
- Check for security issues
- Ensure code follows best practices
- Verify the logic matches your requirements
- Test the generated code

### Q: How do I get Copilot to generate tests?
**A:** Use explicit test prompts:
```python
# Test the validate_email function with:
# - Valid emails (test@example.com)
# - Invalid emails (no @, multiple @, etc.)
# - Edge cases (empty string, None)
# Use pytest and parametrize for multiple test cases
```

## 💻 Technical Questions

### Q: Why use FastAPI instead of Flask/Django?
**A:** FastAPI was chosen because:
- Modern async support
- Automatic API documentation
- Type hints integration
- Built-in validation with Pydantic
- Excellent performance
- Great developer experience

The concepts you learn apply to other frameworks too.

### Q: Why React with TypeScript instead of JavaScript?
**A:** TypeScript provides:
- Better IDE support and autocomplete
- Catch errors at compile time
- Improved refactoring capabilities
- Better integration with Copilot
- Industry standard for large applications

### Q: Do I need to understand everything about WebSockets for Exercise 3?
**A:** You need to understand:
- Basic WebSocket concepts (persistent connection)
- Client-side connection handling
- Sending/receiving messages
- Basic error handling

The exercise provides most of the WebSocket code; focus on understanding how it works.

## 🔧 Setup and Environment Questions

### Q: Can I use npm instead of yarn?
**A:** Yes, absolutely. All commands have npm equivalents:
- `yarn install` → `npm install`
- `yarn dev` → `npm run dev`
- `yarn build` → `npm run build`

### Q: Do I need to use Docker?
**A:** Docker is:
- Required for the deployment section of exercises
- Optional for local development
- Recommended for consistent environments
- Essential for production deployment understanding

### Q: Can I use a different database than SQLite?
**A:** Yes, but:
- SQLite is simplest for learning
- No additional setup required
- Solutions use SQLite
- PostgreSQL code is very similar
- Update connection string and dependencies

### Q: My frontend and backend ports are different. Is that okay?
**A:** Yes, just ensure:
- CORS is configured for your frontend URL
- API client points to correct backend URL
- Update any hardcoded URLs

## 📚 Learning Path Questions

### Q: I'm struggling with Exercise 2. Should I skip to Exercise 3?
**A:** No, the exercises build on each other:
- Exercise 1: Basic full-stack concepts
- Exercise 2: Authentication and advanced features
- Exercise 3: Real-time and performance

Complete them in order for best results.

### Q: How do I know if I'm ready for the next module?
**A:** You're ready when you can:
- Complete all exercises without looking at solutions
- Explain how the frontend and backend communicate
- Debug common issues independently
- Build a simple full-stack app from scratch

### Q: Should I memorize all the code patterns?
**A:** No, focus on understanding:
- When to use different patterns
- How components interact
- Why certain decisions are made
- How to find solutions with Copilot

## 🚀 Project and Career Questions

### Q: How do these skills apply to real jobs?
**A:** These are highly marketable skills:
- Full-stack development is in high demand
- AI-assisted development is the future
- Modern tech stack (FastAPI/React) is widely used
- Production deployment knowledge is essential

### Q: What should I build for my portfolio?
**A:** After this module, consider building:
- Enhanced todo app with team features
- Personal blog with CMS
- Real-time chat application
- Dashboard for data visualization
- API-driven mobile app backend

### Q: How do I showcase AI-assisted development skills?
**A:** In your portfolio:
- Mention GitHub Copilot usage in project descriptions
- Show before/after productivity metrics
- Demonstrate complex features built quickly
- Include AI prompt engineering examples
- Share development process videos

## 🐛 Common Errors and Solutions

### Q: "Module not found" errors in Python?
**A:** Check:
- Virtual environment is activated
- All requirements are installed
- Correct import paths
- `__init__.py` files exist

### Q: "Cannot find module" errors in React?
**A:** Verify:
- Dependencies are installed
- Import paths are correct
- File extensions in imports
- TypeScript configuration

### Q: CORS errors in the browser?
**A:** Ensure:
- Backend CORS middleware is configured
- Frontend URL is in allowed origins
- Credentials flag matches on both ends
- Headers are properly set

### Q: Database migration errors?
**A:** Try:
- Delete the database file
- Re-run migrations
- Check model definitions
- Verify database URL

## 💡 Best Practices Questions

### Q: How should I structure larger applications?
**A:** Follow these patterns:
- Separate concerns (models, schemas, routes)
- Use consistent naming conventions
- Implement proper error handling
- Add logging from the start
- Write tests as you develop

### Q: When should I optimize for performance?
**A:** Follow this approach:
1. Make it work first
2. Make it right (clean code)
3. Make it fast (only if needed)
4. Measure before optimizing
5. Optimize the bottlenecks

### Q: How much should I comment my code?
**A:** Comment:
- Complex business logic
- Non-obvious decisions
- API endpoints (what they do)
- Workarounds and their reasons
- Don't comment obvious code

## 🎯 Module Completion Questions

### Q: I finished the exercises. What now?
**A:** Next steps:
1. Complete the independent project
2. Review and refactor your code
3. Add extra features to exercises
4. Help others in the forum
5. Prepare for Module 8

### Q: How do I get my completion certificate?
**A:** Complete:
- All three exercises
- Independent project
- Module assessment
- Feedback survey

### Q: Can I come back to this module later?
**A:** Yes! The materials remain available. Consider revisiting to:
- Try different approaches
- Implement advanced features
- Update to newer versions
- Mentor other learners

## 📞 Getting Additional Help

If your question isn't answered here:
1. Check the module troubleshooting guide
2. Search the GitHub discussions
3. Ask in the module-specific forum
4. Attend office hours
5. Create a detailed GitHub issue

Remember: There are no stupid questions! Everyone learns differently, and asking questions helps the entire community.
