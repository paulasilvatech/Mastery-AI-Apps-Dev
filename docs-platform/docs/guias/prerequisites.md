---
id: prerequisites
title: Prerequisites
sidebar_label: Prerequisites
sidebar_position: 2
---

# Prerequisites

Everything you need to know before starting the AI Applications Development workshop.

## Overview

This guide outlines the technical requirements, knowledge prerequisites, and setup needed to successfully complete this workshop. Don't worry if you don't meet all requirements perfectly - we'll help you get up to speed!

## Required Knowledge

### Programming Fundamentals

You should be comfortable with:

- **Variables and data types**: strings, numbers, lists, dictionaries
- **Control flow**: if/else statements, loops
- **Functions**: defining and calling functions
- **Basic debugging**: reading error messages, using print statements

### Python Basics (Preferred)

While not strictly required, Python knowledge is highly beneficial:

```python
# You should understand code like this:
def greet(name):
    return f"Hello, {name}!"

names = ["Alice", "Bob", "Charlie"]
for name in names:
    print(greet(name))
```

If you're new to Python, we recommend:
- [Python.org Tutorial](https://docs.python.org/3/tutorial/)
- [Python for Beginners](https://www.python.org/about/gettingstarted/)

### Command Line Familiarity

Basic terminal/command prompt usage:

```bash
# Navigate directories
cd my-project

# List files
ls -la  # Mac/Linux
dir     # Windows

# Run Python scripts
python script.py

# Install packages
pip install package-name
```

## System Requirements

### Hardware

**Minimum Requirements:**
- **Processor**: Any modern CPU (Intel i5/AMD Ryzen 5 or better)
- **RAM**: 8GB (16GB recommended)
- **Storage**: 10GB free space
- **Internet**: Stable broadband connection

**Optional (for local models):**
- **GPU**: NVIDIA GPU with 6GB+ VRAM
- **RAM**: 16GB+ for larger models

### Operating System

Supported platforms:
- **Windows**: 10 or 11
- **macOS**: 10.15 (Catalina) or later
- **Linux**: Ubuntu 20.04+ or equivalent

## Software Requirements

### Essential Tools

1. **Python 3.8+**
   ```bash
   # Check your version
   python --version
   # or
   python3 --version
   ```

2. **Git**
   ```bash
   # Check if installed
   git --version
   ```

3. **Code Editor**
   
   We recommend VS Code with extensions:
   - Python
   - Pylance
   - Jupyter
   - GitLens

4. **Node.js** (for web interfaces)
   ```bash
   # Check if installed
   node --version
   npm --version
   ```

### Package Manager

Ensure pip is updated:
```bash
python -m pip install --upgrade pip
```

## Account Requirements

You'll need to create accounts for:

### 1. GitHub
- Sign up at [github.com](https://github.com)
- Used for: Code hosting, collaboration

### 2. OpenAI (Recommended)
- Sign up at [platform.openai.com](https://platform.openai.com)
- Used for: GPT models access
- Note: Requires payment for API usage

### 3. Anthropic Claude (Optional)
- Sign up at [anthropic.com](https://anthropic.com)
- Used for: Claude model access

### 4. Hugging Face (Optional)
- Sign up at [huggingface.co](https://huggingface.co)
- Used for: Open-source models

## Environment Setup

### 1. Create a Workshop Directory

```bash
# Create and navigate to your workshop folder
mkdir ai-workshop
cd ai-workshop
```

### 2. Set Up Python Virtual Environment

```bash
# Create virtual environment
python -m venv venv

# Activate it
# On Windows:
venv\Scripts\activate
# On Mac/Linux:
source venv/bin/activate
```

### 3. Install Base Dependencies

Create a `requirements.txt` file:

```txt
openai>=1.0.0
python-dotenv>=1.0.0
requests>=2.31.0
numpy>=1.24.0
pandas>=2.0.0
jupyterlab>=4.0.0
streamlit>=1.28.0
langchain>=0.1.0
chromadb>=0.4.0
tiktoken>=0.5.0
```

Install packages:
```bash
pip install -r requirements.txt
```

## API Keys Setup

### 1. Create .env File

Create a `.env` file in your project root:

```bash
# .env
OPENAI_API_KEY=your-api-key-here
ANTHROPIC_API_KEY=your-api-key-here
HUGGINGFACE_API_KEY=your-api-key-here
```

### 2. Load Environment Variables

```python
from dotenv import load_dotenv
import os

load_dotenv()

# Access keys securely
openai_key = os.getenv("OPENAI_API_KEY")
```

### 3. Secure Your Keys

Add to `.gitignore`:
```
.env
*.key
*_secret*
```

## Knowledge Check

Before starting, you should be able to:

- [ ] Write a simple Python function
- [ ] Use pip to install packages
- [ ] Create and activate a virtual environment
- [ ] Clone a Git repository
- [ ] Create and edit text files
- [ ] Run Python scripts from command line
- [ ] Understand basic JSON structure
- [ ] Make HTTP requests (conceptually)

## Recommended Preparation

### If New to Python

1. Complete a basic Python tutorial (3-5 hours)
2. Practice with simple scripts
3. Learn about pip and virtual environments

### If New to APIs

1. Understand REST API basics
2. Learn about API keys and authentication
3. Practice making HTTP requests

### If New to AI/ML

1. Read about Large Language Models (LLMs)
2. Understand tokens and context windows
3. Learn basic prompt engineering concepts

## Quick Skills Assessment

Try this simple exercise:

```python
# Can you understand and modify this code?

import requests

def get_joke():
    """Fetch a random joke from an API"""
    url = "https://official-joke-api.appspot.com/random_joke"
    response = requests.get(url)
    
    if response.status_code == 200:
        joke = response.json()
        return f"{joke['setup']} - {joke['punchline']}"
    else:
        return "Couldn't fetch a joke!"

# Test it
print(get_joke())
```

If you can:
- Understand what this code does
- Modify it to fetch a different API
- Handle potential errors

You're ready for the workshop!

## Getting Help

### Before the Workshop

- Join our Discord/Slack community
- Review this prerequisites guide
- Complete any recommended tutorials
- Test your environment setup

### During the Workshop

- Ask questions in the chat
- Use the troubleshooting guide
- Pair with other participants
- Attend office hours

## Troubleshooting Common Issues

### Python Not Found

```bash
# Windows: Add Python to PATH
# Mac/Linux: Use python3 instead of python
```

### Permission Errors

```bash
# Use pip with user flag
pip install --user package-name
```

### SSL Certificate Errors

```bash
# Temporary fix (not for production!)
pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org package-name
```

## Final Checklist

Before starting the workshop:

- [ ] Python 3.8+ installed and working
- [ ] Git installed and configured
- [ ] Code editor ready (VS Code recommended)
- [ ] Virtual environment created
- [ ] Can install Python packages
- [ ] API accounts created (at least OpenAI)
- [ ] Comfortable with basic programming

## Next Steps

Once you've completed the prerequisites:

1. Review the [Quick Start Guide](./quick-start.md)
2. Set up your [Local Development Environment](./setup-local.md)
3. Join the workshop community
4. Get ready to build amazing AI applications!

Remember: The goal is to learn and build. Don't let perfect be the enemy of good - start where you are and improve as you go!