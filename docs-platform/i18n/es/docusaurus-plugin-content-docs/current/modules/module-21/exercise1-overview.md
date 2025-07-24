---
sidebar_position: 4
title: "Exercise 1: Overview"
description: "## 🎯 Objective"
---

# Ejercicio 1: Build Your First Copilot Agent Extension (⭐ Fácil - 30 minutos)

## 🎯 Objective
Create your first GitHub Copilot agent extension that enhances code suggestions with custom logic and domain-specific knowledge.

## 🧠 Lo Que Aprenderás
- GitHub Copilot agent architecture
- Creating custom agent extensions
- Implementing suggestion filters
- Adding domain-specific context

## 📋 Prerrequisitos
- GitHub Copilot active in VS Code
- Python ambiente set up
- Basic understanding of decorators

## 📚 Atrásground

GitHub Copilot agents allow you to:
- Customize code suggestions
- Add business logic validation
- Inject domain knowledge
- Filtrar inappropriate suggestions

## 🛠️ Instructions

### Step 1: Configurar Agent Project

Create the project structure:
```bash
mkdir copilot-agent-extension
cd copilot-agent-extension

# Create directory structure
mkdir -p src/agents src/utils tests
touch src/__init__.py src/agents/__init__.py
```

### Step 2: Create Base Agent Class

**Copilot Prompt Suggestion:**
```python
# Create a base Copilot agent class that:
# - Implements the agent interface
# - Provides hooks for customization
# - Handles suggestion filtering
# - Manages context injection
# - Includes logging capabilities
# Use abstract base class pattern
```

Create `src/agents/base_agent.py`:
```python
from abc import ABC, abstractmethod
from typing import List, Dict, Any, Optional
import logging
from dataclasses import dataclass

@dataclass
class CodeContext:
    """Context information for code generation"""
    file_path: str
    language: str
    current_line: int
    surrounding_code: str
    project_context: Dict[str, Any]

@dataclass
class CodeSuggestion:
    """A code suggestion from the agent"""
    code: str
    confidence: float
    explanation: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None

class BaseCopilotAgent(ABC):
    """Base class for GitHub Copilot agent extensions"""
    
    def __init__(self, name: str):
        self.name = name
        self.logger = logging.getLogger(f"agent.{name}")
        self.initialize()
    
    @abstractmethod
    def initialize(self) -&gt; None:
        """Initialize the agent with any required resources"""
        pass
    
    @abstractmethod
    def process_context(self, context: CodeContext) -&gt; Dict[str, Any]:
        """Process and enhance the code context"""
        pass
    
    @abstractmethod
    def generate_suggestions(
        self, 
        context: CodeContext, 
        num_suggestions: int = 3
    ) -&gt; List[CodeSuggestion]:
        """Generate code suggestions based on context"""
        pass
    
    @abstractmethod
    def filter_suggestion(self, suggestion: CodeSuggestion) -&gt; bool:
        """Filter suggestions based on custom rules"""
        pass
    
    def enhance_suggestion(self, suggestion: CodeSuggestion) -&gt; CodeSuggestion:
        """Enhance a suggestion with additional metadata"""
        # Default implementation - can be overridden
        return suggestion
```

### Step 3: Implement Domain-Specific Agent

**Copilot Prompt Suggestion:**
```python
# Create a Python best practices agent that:
# - Enforces PEP 8 compliance
# - Suggests type hints
# - Adds proper error handling
# - Includes docstrings
# - Validates security practices
# Inherit from BaseCopilotAgent
```

Create `src/agents/python_best_practices_agent.py`:
```python
import ast
import re
from typing import List, Dict, Any
from .base_agent import BaseCopilotAgent, CodeContext, CodeSuggestion

class PythonBestPracticesAgent(BaseCopilotAgent):
    """Agent that enforces Python best practices in code suggestions"""
    
    def initialize(self) -&gt; None:
        """Initialize Python-specific rules and patterns"""
        self.pep8_rules = {
            'max_line_length': 79,
            'indent_size': 4,
            'naming_conventions': {
                'function': r'^[a-z_][a-z0-9_]*$',
                'class': r'^[A-Z][a-zA-Z0-9]*$',
                'constant': r'^[A-Z_][A-Z0-9_]*$'
            }
        }
        
        self.security_patterns = [
            r'eval\s*\(',
            r'exec\s*\(',
            r'__import__\s*\(',
            r'pickle\.loads\s*\('
        ]
    
    def process_context(self, context: CodeContext) -&gt; Dict[str, Any]:
        """Analyze Python code context"""
        enhanced_context = {
            'original': context,
            'imports': self._extract_imports(context.surrounding_code),
            'functions': self._extract_functions(context.surrounding_code),
            'classes': self._extract_classes(context.surrounding_code),
            'has_type_hints': self._check_type_hints(context.surrounding_code)
        }
        return enhanced_context
    
    def generate_suggestions(
        self, 
        context: CodeContext, 
        num_suggestions: int = 3
    ) -&gt; List[CodeSuggestion]:
        """Generate Python-specific code suggestions"""
        suggestions = []
        
        # Analyze what type of code is needed
        if self._needs_function(context):
            suggestions.extend(self._generate_function_suggestions(context))
        elif self._needs_class(context):
            suggestions.extend(self._generate_class_suggestions(context))
        else:
            suggestions.extend(self._generate_general_suggestions(context))
        
        # Filter and rank suggestions
        filtered = [s for s in suggestions if self.filter_suggestion(s)]
        enhanced = [self.enhance_suggestion(s) for s in filtered]
        
        # Return top suggestions
        return sorted(enhanced, key=lambda s: s.confidence, reverse=True)[:num_suggestions]
    
    def filter_suggestion(self, suggestion: CodeSuggestion) -&gt; bool:
        """Filter out suggestions that don't meet Python best practices"""
        code = suggestion.code
        
        # Check for security issues
        for pattern in self.security_patterns:
            if re.search(pattern, code):
                self.logger.warning(f"Security issue detected: {pattern}")
                return False
        
        # Check line length
        for line in code.split('\n'):
            if len(line) &gt; self.pep8_rules['max_line_length']:
                return False
        
        # Validate syntax
        try:
            ast.parse(code)
        except SyntaxError:
            return False
        
        return True
    
    def enhance_suggestion(self, suggestion: CodeSuggestion) -&gt; CodeSuggestion:
        """Add type hints and docstrings to suggestions"""
        enhanced_code = self._add_type_hints(suggestion.code)
        enhanced_code = self._add_docstring(enhanced_code)
        
        suggestion.code = enhanced_code
        suggestion.metadata = {
            'enhanced': True,
            'pep8_compliant': True,
            'has_type_hints': True,
            'has_docstring': True
        }
        
        return suggestion
    
    # Helper methods
    def _extract_imports(self, code: str) -&gt; List[str]:
        """Extract import statements from code"""
        # Implementation here
        pass
    
    def _extract_functions(self, code: str) -&gt; List[str]:
        """Extract function definitions from code"""
        # Implementation here
        pass
    
    def _extract_classes(self, code: str) -&gt; List[str]:
        """Extract class definitions from code"""
        # Implementation here
        pass
    
    def _check_type_hints(self, code: str) -&gt; bool:
        """Check if code uses type hints"""
        # Implementation here
        pass
    
    def _needs_function(self, context: CodeContext) -&gt; bool:
        """Determine if context needs a function"""
        # Implementation here
        pass
    
    def _needs_class(self, context: CodeContext) -&gt; bool:
        """Determine if context needs a class"""
        # Implementation here
        pass
    
    def _generate_function_suggestions(self, context: CodeContext) -&gt; List[CodeSuggestion]:
        """Generate function suggestions"""
        # Implementation here
        pass
    
    def _generate_class_suggestions(self, context: CodeContext) -&gt; List[CodeSuggestion]:
        """Generate class suggestions"""
        # Implementation here
        pass
    
    def _generate_general_suggestions(self, context: CodeContext) -&gt; List[CodeSuggestion]:
        """Generate general code suggestions"""
        # Implementation here
        pass
    
    def _add_type_hints(self, code: str) -&gt; str:
        """Add type hints to code"""
        # Implementation here
        pass
    
    def _add_docstring(self, code: str) -&gt; str:
        """Add docstring to code"""
        # Implementation here
        pass
```

### Step 4: Create Agent Integration

Create `src/copilot_integration.py`:
```python
# Copilot Prompt Suggestion:
# Create an integration layer that:
# - Connects to GitHub Copilot
# - Routes requests to appropriate agents
# - Handles agent lifecycle
# - Manages suggestion caching
# - Provides metrics and logging

from typing import Dict, List, Optional
from .agents.base_agent import BaseCopilotAgent, CodeContext, CodeSuggestion
from .agents.python_best_practices_agent import PythonBestPracticesAgent
import logging

class CopilotAgentManager:
    """Manages multiple Copilot agents and routes requests"""
    
    def __init__(self):
        self.agents: Dict[str, BaseCopilotAgent] = {}
        self.logger = logging.getLogger("CopilotAgentManager")
        self._initialize_agents()
    
    def _initialize_agents(self):
        """Initialize all available agents"""
        # Register Python agent
        self.register_agent("python", PythonBestPracticesAgent("python"))
        
    def register_agent(self, language: str, agent: BaseCopilotAgent):
        """Register a new agent for a specific language"""
        self.agents[language] = agent
        self.logger.info(f"Registered agent for {language}: {agent.name}")
    
    def get_suggestions(
        self, 
        context: CodeContext, 
        num_suggestions: int = 3
    ) -&gt; List[CodeSuggestion]:
        """Get code suggestions from the appropriate agent"""
        agent = self.agents.get(context.language)
        
        if not agent:
            self.logger.warning(f"No agent found for language: {context.language}")
            return []
        
        try:
            # Process context
            enhanced_context = agent.process_context(context)
            
            # Generate suggestions
            suggestions = agent.generate_suggestions(context, num_suggestions)
            
            self.logger.info(
                f"Generated {len(suggestions)} suggestions for {context.language}"
            )
            
            return suggestions
            
        except Exception as e:
            self.logger.error(f"Error generating suggestions: {e}")
            return []
```

### Step 5: Test Your Agent

Create `tests/test_python_agent.py`:
```python
import pytest
from src.agents.python_best_practices_agent import PythonBestPracticesAgent
from src.agents.base_agent import CodeContext, CodeSuggestion

def test_agent_initialization():
    """Test agent initializes correctly"""
    agent = PythonBestPracticesAgent("test")
    assert agent.name == "test"
    assert agent.pep8_rules is not None

def test_security_filtering():
    """Test agent filters dangerous code"""
    agent = PythonBestPracticesAgent("test")
    
    # Create suggestion with eval()
    dangerous_suggestion = CodeSuggestion(
        code="result = eval(user_input)",
        confidence=0.9
    )
    
    assert not agent.filter_suggestion(dangerous_suggestion)

def test_pep8_compliance():
    """Test agent enforces PEP 8"""
    agent = PythonBestPracticesAgent("test")
    
    # Create suggestion with long line
    long_line_suggestion = CodeSuggestion(
        code="x = 'a' * 100  # This is a very long line that exceeds 79 characters according to PEP 8",
        confidence=0.8
    )
    
    assert not agent.filter_suggestion(long_line_suggestion)

# Run tests
if __name__ == "__main__":
    pytest.main([__file__])
```

## 🏃 Running Your Agent

1. **Start the agent manager**:
```python
from src.copilot_integration import CopilotAgentManager
from src.agents.base_agent import CodeContext

# Initialize manager
manager = CopilotAgentManager()

# Create context
context = CodeContext(
    file_path="example.py",
    language="python",
    current_line=10,
    surrounding_code="def calculate_total(items):\n    # Need to implement\n    pass",
    project_context={{"type": "e-commerce", "framework": "django"}}
)

# Get suggestions
suggestions = manager.get_suggestions(context, num_suggestions=3)

for i, suggestion in enumerate(suggestions):
    print(f"\nSuggestion {i+1} (confidence: {suggestion.confidence}):")
    print(suggestion.code)
    if suggestion.explanation:
        print(f"Explanation: {suggestion.explanation}")
```

## 🎯 Validation

Run the validation script to ensure your implementation is correct:
```bash
python scripts/validate_exercise1.py
```

Expected output:
```
✅ Base agent class implemented correctly
✅ Python agent follows best practices
✅ Security filtering works
✅ PEP 8 compliance enforced
✅ Agent manager routes requests properly
✅ All tests pass!

Score: 100/100
```

## 🚀 Extension Challenges

Once you've completed the basic implementation, try these extensions:

1. **Add More Idiomas**: Create agents for JavaScript, TypeScript, or Java
2. **Implement Caching**: Cache frequent suggestions for performance
3. **Add Metrics**: Ruta suggestion acceptance rates
4. **Create Custom Rules**: Add project-specific coding standards
5. **Implement Learning**: Make the agent learn from accepted/rejected suggestions

## 📚 Additional Recursos

- [GitHub Copilot SDK Documentación](https://docs.github.com/copilot/sdk)
- [Python AST Módulo](https://docs.python.org/3/library/ast.html)
- [PEP 8 Style Guía](https://pep8.org/)

## ⏭️ Siguiente Ejercicio

Ready for more? Move on to [Ejercicio 2: Code Revisar Agent](../exercise2-medium/README.md) where you'll build an agent that automatically reviews code!