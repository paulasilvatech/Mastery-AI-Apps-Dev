# Exercise 1: Utility Functions Library (⭐ Easy)

Welcome to Module 05, Exercise 1! In this exercise, you'll create a comprehensive utility functions library while learning how to use GitHub Copilot for documentation and code quality.

## 🎯 Learning Objectives

- Create well-documented utility functions
- Use GitHub Copilot to generate code from comments
- Apply proper type hints and docstrings
- Implement error handling and validation
- Write clean, maintainable code

## 📋 Exercise Structure

This exercise focuses on building a collection of utility functions that are commonly needed in programming projects:

1. **Email Validation** - Validate email addresses using regex
2. **Phone Number Formatting** - Format US phone numbers consistently
3. **URL Parsing** - Extract components from URLs
4. **Password Generation** - Create secure random passwords
5. **File Checksums** - Calculate MD5 and SHA256 hashes
6. **Temperature Conversion** - Convert between C, F, and K
7. **Credit Card Validation** - Implement Luhn algorithm
8. **Date Parsing** - Handle multiple date formats

## 🚀 Getting Started

1. Open the `starter/utils.py` file in VS Code
2. Ensure GitHub Copilot is active
3. Follow the TODO comments in the file
4. Let Copilot help you implement each function
5. Test your implementation with the provided tests

## 📁 Files

- `starter/utils.py` - Starting template with TODOs
- `solution/utils.py` - Complete implementation
- `tests/test_utils.py` - Unit tests for validation
- `README.md` - This file

## 💡 Tips for Success

1. **Write Clear Comments**: Before implementing each function, write a detailed comment describing what it should do
2. **Use Type Hints**: Add type hints to help Copilot understand expected inputs/outputs
3. **Start Simple**: Implement basic functionality first, then add error handling
4. **Test Incrementally**: Test each function as you complete it
5. **Review Suggestions**: Don't accept Copilot suggestions blindly - review and understand the code

## 🧪 Testing Your Code

```bash
# Navigate to the exercise directory
cd modules/module-05/exercises/exercise1-easy

# Run the starter file to see TODOs
python starter/utils.py

# Run tests (after implementation)
python -m pytest tests/test_utils.py -v
```

## ✅ Success Criteria

You've completed this exercise when:
- [ ] All 8 utility functions are implemented
- [ ] Each function has proper docstrings
- [ ] Type hints are used throughout
- [ ] Error handling is implemented
- [ ] All tests pass
- [ ] Code follows PEP 8 style guidelines

## 🎉 Congratulations!

Once you complete this exercise, you'll have:
- A reusable utility library
- Experience with Copilot-assisted development
- Understanding of documentation best practices
- Practice with error handling and validation

Continue to Exercise 2 to learn about code refactoring!