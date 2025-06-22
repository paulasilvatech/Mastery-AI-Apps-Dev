# Module 03: Independent Project - AI Prompt Optimizer

## 🎯 Project Overview

Build an **AI Prompt Optimizer** tool that helps developers write better prompts for GitHub Copilot. This project will demonstrate your mastery of effective prompting techniques by creating a system that analyzes, improves, and manages prompts.

## 🏗️ Project Options

Choose one of these three project variants based on your interest:

### Option 1: Prompt Analysis Tool (Recommended)
Build a tool that analyzes prompts and provides improvement suggestions.

**Features:**
- Analyze prompt clarity and specificity
- Detect missing context or examples
- Suggest improvements
- Score prompt effectiveness
- Generate optimized versions

### Option 2: Prompt Pattern Manager
Create a system for managing and sharing prompt patterns.

**Features:**
- Store categorized prompt patterns
- Search and filter patterns
- Track usage and effectiveness
- Export/import pattern libraries
- Team collaboration features

### Option 3: Interactive Prompt Builder
Develop a guided prompt creation tool.

**Features:**
- Step-by-step prompt building
- Context awareness checking
- Real-time preview
- Template customization
- Best practice validation

## 📋 Requirements

### Core Requirements (All Options)
1. **Context Optimization**
   - Implement context analysis
   - Provide context improvement suggestions
   - Show context window visualization

2. **Prompt Engineering**
   - Support multiple prompt patterns
   - Include example management
   - Handle constraint specification

3. **Validation**
   - Check prompt completeness
   - Validate against best practices
   - Provide actionable feedback

4. **Documentation**
   - Comprehensive README
   - Usage examples
   - API documentation (if applicable)

### Technical Requirements
- Python 3.8+
- Type hints throughout
- Unit tests (minimum 70% coverage)
- Clean, modular architecture
- Follows PEP 8 style guide

## 🚀 Getting Started

### Project Structure
```
prompt-optimizer/
├── README.md
├── requirements.txt
├── setup.py
├── src/
│   ├── __init__.py
│   ├── analyzer.py      # Prompt analysis logic
│   ├── optimizer.py     # Optimization engine
│   ├── patterns.py      # Pattern management
│   └── utils.py         # Helper functions
├── tests/
│   ├── test_analyzer.py
│   ├── test_optimizer.py
│   └── test_patterns.py
├── examples/
│   ├── basic_usage.py
│   └── advanced_patterns.py
└── docs/
    ├── api.md
    └── patterns.md
```

### Sample Implementation Start

```python
# src/analyzer.py
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
from enum import Enum

class PromptQuality(Enum):
    POOR = "poor"
    FAIR = "fair"
    GOOD = "good"
    EXCELLENT = "excellent"

@dataclass
class PromptAnalysis:
    """Analysis results for a prompt."""
    quality: PromptQuality
    score: float  # 0-100
    issues: List[str]
    suggestions: List[str]
    optimized_version: Optional[str] = None

class PromptAnalyzer:
    """Analyzes prompts for effectiveness."""
    
    def __init__(self):
        self.rules = self._load_rules()
    
    def analyze(self, prompt: str, context: Optional[str] = None) -> PromptAnalysis:
        """
        Analyze a prompt for effectiveness.
        
        Args:
            prompt: The prompt text to analyze
            context: Optional surrounding code context
            
        Returns:
            PromptAnalysis object with results
        """
        # TODO: Implement analysis logic
        # Check for:
        # - Specificity
        # - Examples
        # - Constraints
        # - Clarity
        # - Context usage
```

## 📊 Evaluation Criteria

Your project will be evaluated on:

1. **Functionality** (40%)
   - Core features work correctly
   - Handles edge cases
   - Provides valuable output

2. **Code Quality** (30%)
   - Clean, readable code
   - Proper use of prompting principles
   - Good architecture

3. **Documentation** (20%)
   - Clear README
   - Usage examples
   - API documentation

4. **Innovation** (10%)
   - Creative features
   - Novel approaches
   - Extra functionality

## 💡 Implementation Ideas

### Prompt Scoring Algorithm
```python
def calculate_prompt_score(prompt: str) -> float:
    """Score a prompt from 0-100."""
    score = 100.0
    
    # Check length (optimal: 50-200 chars)
    if len(prompt) < 20:
        score -= 20  # Too short
    elif len(prompt) > 500:
        score -= 10  # Too long
    
    # Check for specificity markers
    specificity_words = ['create', 'implement', 'validate', 'return']
    if not any(word in prompt.lower() for word in specificity_words):
        score -= 15
    
    # Check for examples
    if 'example:' in prompt.lower() or '->' in prompt:
        score += 10
    
    # More checks...
    return max(0, min(100, score))
```

### Pattern Detection
```python
def detect_pattern_type(prompt: str) -> str:
    """Detect which pattern type the prompt follows."""
    patterns = {
        'specification': ['input:', 'output:', 'rules:'],
        'example': ['example:', '->', 'input/output'],
        'algorithm': ['step', 'algorithm:', '1.', '2.'],
        'todo': ['todo:', 'implement', 'create']
    }
    
    for pattern_type, markers in patterns.items():
        if any(marker in prompt.lower() for marker in markers):
            return pattern_type
    
    return 'generic'
```

## 🎯 Bonus Challenges

1. **Machine Learning Integration**
   - Train a model on effective prompts
   - Predict prompt success rate
   - Generate prompts automatically

2. **IDE Integration**
   - VS Code extension
   - Real-time prompt analysis
   - Inline suggestions

3. **Team Features**
   - Shared pattern libraries
   - Prompt effectiveness tracking
   - Analytics dashboard

## 📚 Resources

- [Module 03 Materials](../)
- [Prompt Engineering Guide](https://www.promptingguide.ai/)
- [Python Best Practices](https://docs.python-guide.org/)
- [GitHub Copilot Docs](https://docs.github.com/copilot)

## 🏁 Submission Guidelines

1. **Code Repository**
   - Push to GitHub
   - Include all source code
   - Add .gitignore for Python

2. **Documentation**
   - Complete README
   - Installation instructions
   - Usage examples
   - Architecture explanation

3. **Demo Video** (Optional)
   - 3-5 minute demonstration
   - Show key features
   - Explain design decisions

## ⏰ Timeline

- **Week 1**: Design and core implementation
- **Week 2**: Testing and refinement
- **Week 3**: Documentation and polish
- **Week 4**: Submission and review

## 🆘 Getting Help

- Post questions in Module 03 Discussions
- Attend office hours
- Review exercise solutions for patterns
- Ask in #module-03-project Slack channel

---

🚀 **Ready to build something amazing? Choose your project variant and start coding!**

💡 **Tip**: Use the prompting techniques you learned in this module to help build your project. Let Copilot assist you, but remember to apply the optimization principles you've learned!