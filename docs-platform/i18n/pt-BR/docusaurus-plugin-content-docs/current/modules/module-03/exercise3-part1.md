---
sidebar_position: 4
title: "Exercise 3: Part 1"
description: "## 🎯 Part 1: System Architecture and Foundation (20-30 minutes)"
---

# Exercício 3: Custom Instruction System - Partee 1

## 🎯 Partee 1: System Architecture and Foundation (20-30 minutos)

In this part, you'll design and build the architecture for a comprehensive custom instruction system that can manage project-specific Copilot configurations.

## 📚 Understanding Custom Instructions

### What Are Custom Instructions?

Custom instructions are project-specific configurations that guide GitHub Copilot to:
- Seguir team coding standards
- Use preferred patterns and libraries
- Avoid certain approaches
- Generate domain-specific code
- Maintain consistency across the team

### System Requirements

1. **Multi-Project Support** - Handle different projects with unique requirements
2. **Hierarchical Configuration** - Global → Team → Project → File level
3. **Dynamic Atualizars** - Instructions update as context changes
4. **Performance** - Fast instruction retrieval and generation
5. **Extensibility** - Fácil to add new instruction types

## 🛠️ Building the Foundation

### Step 1: Create Configuration Schemas

Comece com `starter/config/schemas.py`:

```python
#!/usr/bin/env python3
"""
Configuration schemas for the instruction system
Uses Pydantic for validation and serialization
"""

from typing import List, Dict, Optional, Any, Set
from datetime import datetime
from pathlib import Path
from pydantic import BaseModel, Field, validator
from enum import Enum

class ComplexityLevel(str, Enum):
    """Code complexity levels."""
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"
    EXPERT = "expert"

class CodingStandard(str, Enum):
    """Supported coding standards."""
    PEP8 = "pep8"
    GOOGLE = "google"
    AIRBNB = "airbnb"
    CUSTOM = "custom"

class InstructionScope(str, Enum):
    """Scope levels for instructions."""
    GLOBAL = "global"
    TEAM = "team"
    PROJECT = "project"
    DIRECTORY = "directory"
    FILE = "file"

class BaseInstruction(BaseModel):
    """Base instruction configuration."""
    id: str = Field(..., description="Unique instruction ID")
    name: str = Field(..., description="Human-readable name")
    scope: InstructionScope
    priority: int = Field(default=0, ge=0, le=100)
    enabled: bool = Field(default=True)
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)
    
    class Config:
        use_enum_values = True
```

### Step 2: Define Project Configuration

```python
class ProjectConfig(BaseModel):
    """Project-specific configuration."""
    project_id: str
    name: str
    description: Optional[str] = None
    root_path: Path
    
    # Language and framework
    primary_language: str
    secondary_languages: List[str] = Field(default_factory=list)
    framework: Optional[str] = None
    framework_version: Optional[str] = None
    
    # Coding standards
    coding_standard: CodingStandard = CodingStandard.PEP8
    complexity_level: ComplexityLevel = ComplexityLevel.INTERMEDIATE
    
    # Custom patterns and rules
    preferred_patterns: Dict[str, str] = Field(default_factory=dict)
    avoided_patterns: List[str] = Field(default_factory=list)
    required_imports: Dict[str, List[str]] = Field(default_factory=dict)
    
    # Domain-specific rules
    domain: Optional[str] = None
    domain_terms: Dict[str, str] = Field(default_factory=dict)
    business_rules: List[str] = Field(default_factory=list)
    
    # Performance preferences
    prefer_async: bool = False
    optimize_for: Optional[str] = None  # "speed", "memory", "readability"
    
    @validator('root_path')
    def validate_root_path(cls, v):
        """Ensure root path exists."""
        if not v.exists():
            raise ValueError(f"Root path {v} does not exist")
        return v
```

### Step 3: Create Team Standards

```python
class TeamStandards(BaseModel):
    """Team-wide coding standards."""
    team_id: str
    team_name: str
    
    # Naming conventions
    naming_conventions: Dict[str, str] = Field(
        default_factory=lambda: {
            "function": "snake_case",
            "class": "PascalCase",
            "constant": "UPPER_SNAKE_CASE",
            "variable": "snake_case"
        }
    )
    
    # Documentation requirements
    require_docstrings: bool = True
    docstring_style: str = "google"  # google, numpy, sphinx
    min_docstring_length: int = 10
    
    # Code structure
    max_line_length: int = 88
    max_function_length: int = 50
    max_file_length: int = 500
    max_complexity: int = 10
    
    # Required practices
    require_type_hints: bool = True
    require_tests: bool = True
    test_coverage_threshold: float = 0.8
    
    # Forbidden practices
    forbidden_imports: List[str] = Field(default_factory=list)
    forbidden_functions: List[str] = Field(default_factory=list)
    
    # Review requirements
    require_review: bool = True
    min_reviewers: int = 1
```

### Step 4: Build Instruction Registry

Create `starter/instruction_system.py`:

```python
"""
Core instruction system implementation
"""

from typing import Dict, List, Optional, Set, Tuple
from pathlib import Path
import json
import yaml
from datetime import datetime
import hashlib

from config.schemas import (
    ProjectConfig, TeamStandards, InstructionScope,
    BaseInstruction, ComplexityLevel
)

class InstructionRegistry:
    """Central registry for all instructions."""
    
    def __init__(self, storage_path: Path = Path(".copilot/instructions")):
        self.storage_path = storage_path
        self.storage_path.mkdir(parents=True, exist_ok=True)
        
        # In-memory caches
        self._projects: Dict[str, ProjectConfig] = {}
        self._teams: Dict[str, TeamStandards] = {}
        self._instructions: Dict[str, List[BaseInstruction]] = {}
        self._file_cache: Dict[str, str] = {}
        
        # Load existing configurations
        self._load_configurations()
    
    def register_project(self, config: ProjectConfig) -&gt; None:
        """Register a new project configuration."""
        self._projects[config.project_id] = config
        self._save_project(config)
        print(f"✅ Registered project: {config.name}")
    
    def register_team(self, standards: TeamStandards) -&gt; None:
        """Register team standards."""
        self._teams[standards.team_id] = standards
        self._save_team(standards)
        print(f"✅ Registered team: {standards.team_name}")
```

**🤖 Copilot Prompt Suggestion #1:**
```python
# Add methods to the InstructionRegistry class:
# 1. get_applicable_instructions(file_path: Path) -&gt; List[BaseInstruction]
#    - Find all instructions that apply to a file
#    - Consider scope hierarchy (global → file)
#    - Sort by priority
# 2. _calculate_file_hash(file_path: Path) -&gt; str
#    - Calculate hash for cache invalidation
# 3. _load_configurations() -&gt; None
#    - Load all saved configurations from disk
# 4. _save_project(config: ProjectConfig) -&gt; None
#    - Save project config to disk (JSON)

def get_applicable_instructions(self, file_path: Path) -&gt; List[BaseInstruction]:
    """Get all instructions applicable to a file."""
    # Copilot will implement the hierarchy logic
```

### Step 5: Create Instruction Builder

```python
class InstructionBuilder:
    """Build custom instructions from configurations."""
    
    def __init__(self, registry: InstructionRegistry):
        self.registry = registry
        self.template_cache = {}
    
    def build_file_instructions(
        self, 
        file_path: Path,
        project_id: str,
        team_id: Optional[str] = None
    ) -&gt; str:
        """
        Build complete instructions for a file.
        
        Combines:
        - Team standards
        - Project configuration
        - File-specific rules
        - Context awareness
        """
        instructions = []
        
        # Get configurations
        project = self.registry.get_project(project_id)
        team = self.registry.get_team(team_id) if team_id else None
        
        # Add header
        instructions.append(self._build_header(project, file_path))
        
        # Add language-specific instructions
        instructions.append(self._build_language_section(project, file_path))
        
        # Add coding standards
        if team:
            instructions.append(self._build_standards_section(team))
        
        # Add project-specific patterns
        instructions.append(self._build_patterns_section(project))
        
        # Add domain rules
        if project.domain:
            instructions.append(self._build_domain_section(project))
        
        # Add file-specific instructions
        file_instructions = self._get_file_specific_instructions(file_path)
        if file_instructions:
            instructions.append(file_instructions)
        
        return "\n\n".join(filter(None, instructions))
```

### Step 6: Implement Context Detection

```python
class ContextDetector:
    """Detect context from code and project structure."""
    
    def __init__(self):
        self.framework_indicators = {
            'fastapi': ['from fastapi import', 'FastAPI()'],
            'django': ['from django.', 'django.conf'],
            'flask': ['from flask import', 'Flask(__name__)'],
            'pytest': ['import pytest', 'def test_'],
            'numpy': ['import numpy', 'np.array'],
            'pandas': ['import pandas', 'pd.DataFrame']
        }
    
    def detect_file_context(self, file_path: Path) -&gt; Dict[str, Any]:
        """Detect context from a specific file."""
        context = {
            'file_type': file_path.suffix,
            'file_name': file_path.stem,
            'directory': file_path.parent.name,
            'frameworks': [],
            'patterns': [],
            'complexity': ComplexityLevel.INTERMEDIATE
        }
        
        if file_path.exists() and file_path.suffix == '.py':
            content = file_path.read_text()
            
            # Detect frameworks
            for framework, indicators in self.framework_indicators.items():
                if any(indicator in content for indicator in indicators):
                    context['frameworks'].append(framework)
            
            # Detect patterns
            if 'class' in content:
                context['patterns'].append('object-oriented')
            if 'async def' in content:
                context['patterns'].append('async')
            if '@' in content and 'def' in content:
                context['patterns'].append('decorators')
            
            # Estimate complexity
            lines = content.split('\n')
            if len(lines) &gt; 200:
                context['complexity'] = ComplexityLevel.ADVANCED
            elif len(lines) &lt; 50:
                context['complexity'] = ComplexityLevel.BEGINNER
        
        return context
```

**🤖 Copilot Prompt Suggestion #2:**
```python
# Create a method to detect project-wide context:
# Should analyze:
# - Project structure (directories, files)
# - Dependencies (requirements.txt, package.json)
# - Configuration files (.env, config.yaml)
# - Test structure and coverage
# - Documentation presence
# Return comprehensive project context

def detect_project_context(self, root_path: Path) -&gt; Dict[str, Any]:
    """Detect context from entire project."""
    # Copilot will implement project analysis
```

### Step 7: Create Instruction Storage

```python
class InstructionStorage:
    """Handle persistent storage of instructions."""
    
    def __init__(self, base_path: Path):
        self.base_path = base_path
        self.base_path.mkdir(parents=True, exist_ok=True)
        
        # Create directory structure
        (self.base_path / "projects").mkdir(exist_ok=True)
        (self.base_path / "teams").mkdir(exist_ok=True)
        (self.base_path / "instructions").mkdir(exist_ok=True)
        (self.base_path / "templates").mkdir(exist_ok=True)
    
    def save_project(self, config: ProjectConfig) -&gt; None:
        """Save project configuration."""
        file_path = self.base_path / "projects" / f"{config.project_id}.json"
        with open(file_path, 'w') as f:
            json.dump(config.dict(), f, indent=2, default=str)
    
    def load_project(self, project_id: str) -&gt; Optional[ProjectConfig]:
        """Load project configuration."""
        file_path = self.base_path / "projects" / f"{project_id}.json"
        if file_path.exists():
            with open(file_path, 'r') as f:
                data = json.load(f)
                return ProjectConfig(**data)
        return None
    
    def list_projects(self) -&gt; List[str]:
        """List all project IDs."""
        project_dir = self.base_path / "projects"
        return [f.stem for f in project_dir.glob("*.json")]
```

## 📊 Testing Your Architecture

Create a test script to verify the foundation:

```python
# test_architecture.py
from pathlib import Path
from instruction_system import InstructionRegistry, InstructionBuilder
from config.schemas import ProjectConfig, TeamStandards, ComplexityLevel

# Create registry
registry = InstructionRegistry()

# Register a project
project = ProjectConfig(
    project_id="webapp-001",
    name="E-commerce API",
    root_path=Path.cwd(),
    primary_language="python",
    framework="fastapi",
    complexity_level=ComplexityLevel.ADVANCED,
    domain="e-commerce",
    preferred_patterns={
        "validation": "pydantic models",
        "database": "async SQLAlchemy",
        "testing": "pytest with fixtures"
    }
)
registry.register_project(project)

# Register team standards
team = TeamStandards(
    team_id="backend-team",
    team_name="Backend Development Team",
    require_type_hints=True,
    max_line_length=88,
    docstring_style="google"
)
registry.register_team(team)

# Build instructions for a file
builder = InstructionBuilder(registry)
instructions = builder.build_file_instructions(
    file_path=Path("api/endpoints/users.py"),
    project_id="webapp-001",
    team_id="backend-team"
)

print("Generated Instructions:")
print(instructions)
```

## 🎯 Partee 1 Resumo

You've built:
1. Comprehensive configuration schemas
2. Project and team management system
3. Instruction registry with caching
4. Context detection capabilities
5. Persistent storage system
6. Instruction builder foundation

## 💡 Key Architecture Decisions

- **Pydantic Models** - Type safety and validation
- **Hierarchical Scopes** - Flexible instruction application
- **Caching Strategy** - Performance optimization
- **Modular Design** - Fácil to extend and maintain
- **File-based Storage** - Simple and portable

---

✅ **Excellent foundation! Continue to Part 2 to implement the core functionality!**