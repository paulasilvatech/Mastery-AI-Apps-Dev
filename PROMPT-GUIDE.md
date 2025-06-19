# 🤖 AI Prompt Engineering Guide

## Core Principles

### 1. Be Specific and Clear
❌ "Fix this code"
✅ "Fix the null pointer exception in the getUserById function on line 42"

### 2. Provide Context
❌ "Write a function"
✅ "Write a TypeScript function that validates email addresses using regex and returns a boolean"

### 3. Define Constraints
❌ "Make it faster"
✅ "Optimize this function to run in O(n) time complexity instead of O(n²)"

## Prompt Patterns

### The CRISP Pattern
- **C**ontext: Set the scene
- **R**ole: Define AI's role
- **I**nstructions: Clear steps
- **S**pecifications: Technical requirements
- **P**roduct: Expected output

Example:
```
Context: I'm building a React e-commerce app
Role: Act as a senior React developer
Instructions: Create a shopping cart component
Specifications: Use TypeScript, Redux Toolkit, and Material-UI
Product: A complete CartComponent.tsx with add/remove functionality
```

### The Few-Shot Pattern
Provide examples of desired output:
```
Convert these functions to TypeScript:
JavaScript: function add(a, b) { return a + b; }
TypeScript: function add(a: number, b: number): number { return a + b; }

Now convert: function multiply(x, y) { return x * y; }
```

### The Chain-of-Thought Pattern
Break complex tasks into steps:
```
Help me refactor this monolithic function:
1. First, identify the main responsibilities
2. Extract each responsibility into a separate function
3. Create appropriate interfaces
4. Add error handling
5. Write unit tests
```

## Best Practices by Tool

### GitHub Copilot
- Write descriptive function names
- Add detailed comments before functions
- Use consistent coding style
- Start with function signature

### Claude/GPT-4
- Use markdown for code blocks
- Specify language and framework versions
- Include error messages verbatim
- Ask for explanations with code

### Cursor AI
- Use Cmd+K for quick edits
- Cmd+L for chat context
- Reference specific files with @filename
- Use "Apply" for direct code changes

## Common Mistakes to Avoid

### 1. Vague Instructions
❌ "Make it better"
✅ "Improve performance by implementing caching"

### 2. Missing Context
❌ "Fix the bug"
✅ "Fix the race condition in the async user fetch function"

### 3. Oversized Requests
❌ "Build me a complete app"
✅ "Create the user authentication module"

### 4. No Success Criteria
❌ "Optimize this"
✅ "Reduce memory usage by 50% while maintaining functionality"

## Advanced Techniques

### Meta-Prompting
```
"What additional information would help you provide a better solution for [task]?"
```

### Iterative Refinement
```
1. "Create a basic version"
2. "Now add error handling"
3. "Optimize for performance"
4. "Add comprehensive tests"
```

### Role-Based Prompting
```
"As a security expert, review this code for vulnerabilities"
"As a performance engineer, identify bottlenecks"
"As a UX designer, suggest UI improvements"
```

## Testing AI Output

Always verify AI-generated code:
1. **Syntax**: Does it compile/run?
2. **Logic**: Does it solve the problem?
3. **Edge Cases**: How does it handle errors?
4. **Performance**: Is it efficient?
5. **Security**: Are there vulnerabilities?
6. **Maintainability**: Is it readable and documented?

## Prompt Templates

### Bug Fixing
```
Bug: [Describe the issue]
Error Message: [Paste exact error]
Code: [Relevant code snippet]
Expected: [What should happen]
Actual: [What happens instead]
Environment: [Language/Framework versions]
```

### Feature Implementation
```
Feature: [Name]
Requirements:
- [Requirement 1]
- [Requirement 2]
Constraints:
- [Technical constraints]
- [Business constraints]
Similar to: [Reference implementation]
```

### Code Review
```
Review this code for:
1. Bugs and errors
2. Performance issues
3. Security vulnerabilities
4. Code style violations
5. Suggested improvements

[Paste code]
```

## Remember
- AI is a tool, not a replacement for understanding
- Always review and test generated code
- Learn from AI suggestions to improve your skills
- Combine AI with human creativity for best results 