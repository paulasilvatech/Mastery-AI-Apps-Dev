---
sidebar_position: 9
title: "Exercise 3: Part 1"
description: "## 🎯 Exercise Overview"
---

# Exercício 3: Quality Automation System (⭐⭐⭐ Difícil)

## 🎯 Visão Geral do Exercício

**Duração**: 60-90 minutos  
**Difficulty**: ⭐⭐⭐ (Difícil)  
**Success Rate**: 60%

In this advanced exercise, you'll build a complete code quality automation system that integrates documentation generation, refactoring, and continuous quality monitoring. This produção-ready system will enforce standards, track metrics, and integrate with CI/CD pipelines.

## 🎓 Objetivos de Aprendizagem

Ao completar este exercício, você irá:
- Build an integrated quality enforcement system
- Implement automated quality gates
- Create real-time quality monitoring
- Set up CI/CD integration
- Generate comprehensive quality reports
- Design quality dashboards

## 📋 Pré-requisitos

- ✅ Completard Exercícios 1 and 2
- ✅ Understanding of CI/CD concepts
- ✅ Basic knowledge of GitHub Actions
- ✅ Familiarity with quality metrics

## 🏗️ What You'll Build

A **Completar Quality Automation System** that:
- Monitors code quality in real-time
- Enforces documentation standards
- Automatically suggests improvements
- Integrates with CI/CD pipelines
- Generates quality dashboards
- Trilhas metrics over time

## 📁 Project Structure

```
exercise3-hard/
├── README.md                    # This file
├── instructions/
│   ├── part1.md                # System architecture (this file)
│   ├── part2.md                # Implementation
│   └── part3.md                # CI/CD and dashboards
├── starter/
│   ├── quality_system.py       # Main system
│   ├── monitors/               # Quality monitors
│   ├── reporters/              # Report generators
│   ├── integrations/           # CI/CD integrations
│   └── config/                 # Configuration
├── solution/
│   ├── quality_system.py
│   ├── monitors/
│   ├── reporters/
│   ├── integrations/
│   ├── dashboards/
│   └── tests/
└── resources/
    ├── metrics_guide.md
    ├── ci_templates/
    └── dashboard_examples/
```

## 🚀 Partee 1: System Architecture and Foundation

### Step 1: Understanding Quality Metrics

Before building, let's understand the key metrics we'll track:

1. **Code Quality Metrics**
   - Cyclomatic Complexity
   - Lines of Code (LOC)
   - Comment Ratio
   - Test Coverage
   - Documentação Coverage

2. **Maintainability Metrics**
   - Technical Debt
   - Code Duplication
   - Coupling/Cohesion
   - Maintainability Index

3. **Team Metrics**
   - Code Revisar Time
   - Defect Density
   - Refactoring Frequency
   - Documentação Atualizars

### Step 2: Design the System Architecture

```python
#!/usr/bin/env python3
"""
Comprehensive Code Quality Automation System
Integrates documentation, refactoring, and monitoring
"""

import asyncio
from typing import Dict, List, Optional, Any, Set
from pathlib import Path
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
import json

class QualityLevel(Enum):
    """Overall quality assessment levels."""
    EXCELLENT = auto()  # 90-100%
    GOOD = auto()       # 80-89%
    FAIR = auto()       # 70-79%
    POOR = auto()       # 60-69%
    CRITICAL = auto()   # Less than 60%

@dataclass
class QualityMetrics:
    """Container for all quality metrics."""
    timestamp: datetime = field(default_factory=datetime.now)
    
    # Code metrics
    lines_of_code: int = 0
    cyclomatic_complexity: float = 0.0
    comment_ratio: float = 0.0
    
    # Quality metrics
    documentation_coverage: float = 0.0
    test_coverage: float = 0.0
    code_duplication: float = 0.0
    
    # Smell metrics
    total_smells: int = 0
    critical_smells: int = 0
    
    # Calculated scores
    maintainability_index: float = 0.0
    overall_quality: float = 0.0
    quality_level: QualityLevel = QualityLevel.FAIR

# Create a comprehensive quality system that:
# - Monitors code quality in real-time
# - Integrates documentation and refactoring tools
# - Provides actionable insights
# - Enforces quality standards
# - Generates reports and dashboards
class QualityAutomationSystem:
```

**🤖 Copilot Prompt Suggestion #1:**
```python
# Design the QualityAutomationSystem with these components:
# 1. Core initialization:
#    - __init__(self, config: QualityConfig)
#    - Setup monitors, analyzers, and reporters
# 2. Main monitoring methods:
#    - monitor_file(self, filepath: Path) -&gt; QualityMetrics
#    - monitor_project(self, project_path: Path) -&gt; ProjectMetrics
#    - watch_realtime(self, path: Path) -&gt; AsyncIterator[QualityEvent]
# 3. Quality enforcement:
#    - enforce_standards(self, metrics: QualityMetrics) -&gt; List[QualityIssue]
#    - suggest_improvements(self, issues: List[QualityIssue]) -&gt; List[Improvement]
# 4. Integration methods:
#    - export_for_ci(self, metrics: QualityMetrics) -&gt; Dict
#    - generate_badge(self, quality_level: QualityLevel) -&gt; str
# 5. Reporting:
#    - generate_report(self, metrics: QualityMetrics, format: str) -&gt; str
#    - create_dashboard(self, historical_data: List[QualityMetrics]) -&gt; str
```

### Step 3: Create Quality Monitors

Build specialized monitors for different aspects:

```python
# monitors/base.py
from abc import ABC, abstractmethod
from typing import Any, Dict

class QualityMonitor(ABC):
    """Base class for all quality monitors."""
    
    def __init__(self, name: str):
        self.name = name
        self.enabled = True
    
    @abstractmethod
    async def analyze(self, code: str, filepath: Path) -&gt; Dict[str, Any]:
        """Analyze code and return metrics."""
        pass
    
    @abstractmethod
    def get_thresholds(self) -&gt; Dict[str, float]:
        """Return quality thresholds for this monitor."""
        pass
```

Create specific monitors:

```python
# monitors/complexity_monitor.py
import ast
from radon.complexity import cc_visit
from radon.metrics import h_visit

class ComplexityMonitor(QualityMonitor):
    """Monitor code complexity metrics."""
    
    def __init__(self):
        super().__init__("Complexity Monitor")
        self.thresholds = {
            "max_complexity": 10,
            "max_function_length": 50,
            "max_class_length": 200
        }
    
    async def analyze(self, code: str, filepath: Path) -&gt; Dict[str, Any]:
        """Analyze code complexity."""
        # Parse code and calculate complexity
        # Use radon for cyclomatic complexity
        # Calculate Halstead metrics
        # Identify complex functions
        # Return detailed metrics
```

**🤖 Copilot Prompt Suggestion #2:**
```python
# Implement comprehensive complexity analysis:
# 1. Parse code using ast
# 2. Calculate cyclomatic complexity:
#    - Use radon.complexity.cc_visit()
#    - Track per-function complexity
#    - Flag functions exceeding threshold
# 3. Calculate Halstead metrics:
#    - Volume, difficulty, effort
#    - Time to implement
# 4. Measure nesting depth:
#    - Track maximum nesting
#    - Identify deeply nested blocks
# 5. Return structured metrics:
#    {
#        "cyclomatic_complexity": average_cc,
#        "max_complexity": max_cc,
#        "complex_functions": [list of functions],
#        "halstead_metrics": {{...}},
#        "nesting_depth": max_depth
#    }
# Include line numbers for issues
```

### Step 4: Create Documentação Monitor

Build on Exercício 1's work:

```python
# monitors/documentation_monitor.py
from doc_generator import DocumentationGenerator

class DocumentationMonitor(QualityMonitor):
    """Monitor documentation quality and coverage."""
    
    def __init__(self):
        super().__init__("Documentation Monitor")
        self.doc_generator = DocumentationGenerator()
        self.thresholds = {
            "min_coverage": 80.0,
            "require_examples": True,
            "require_type_hints": True
        }
    
    async def analyze(self, code: str, filepath: Path) -&gt; Dict[str, Any]:
        """Analyze documentation quality."""
        # Check documentation coverage
        # Validate docstring quality
        # Check for missing type hints
        # Verify example code
        # Calculate documentation score
```

### Step 5: Create Code Smell Monitor

Integrate with Exercício 2's refactoring assistant:

```python
# monitors/smell_monitor.py
from refactoring_assistant import RefactoringAssistant

class CodeSmellMonitor(QualityMonitor):
    """Monitor code smells and refactoring opportunities."""
    
    def __init__(self):
        super().__init__("Code Smell Monitor")
        self.refactoring_assistant = RefactoringAssistant()
        self.smell_weights = {
            SmellType.LONG_METHOD: 2.0,
            SmellType.COMPLEX_CONDITIONAL: 1.5,
            SmellType.DUPLICATE_CODE: 3.0
        }
    
    async def analyze(self, code: str, filepath: Path) -&gt; Dict[str, Any]:
        """Detect and categorize code smells."""
        # Run smell detection
        # Calculate weighted smell score
        # Identify critical issues
        # Suggest prioritized fixes
```

### Step 6: Create Test Coverage Monitor

Monitor test quality:

```python
# monitors/test_monitor.py
import coverage
import pytest

class TestCoverageMonitor(QualityMonitor):
    """Monitor test coverage and quality."""
    
    async def analyze(self, code: str, filepath: Path) -&gt; Dict[str, Any]:
        """Analyze test coverage and quality."""
        # Find associated test files
        # Run coverage analysis
        # Check test quality metrics
        # Identify untested code
        # Calculate coverage score
```

**🤖 Copilot Prompt Suggestion #3:**
```python
# Implement test coverage monitoring:
# 1. Locate test files:
#    - Find test_*.py or *_test.py
#    - Check tests/ directory
# 2. Run coverage analysis:
#    cov = coverage.Coverage()
#    cov.start()
#    # Run tests
#    cov.stop()
#    cov.save()
# 3. Extract metrics:
#    - Line coverage percentage
#    - Branch coverage
#    - Missing lines
# 4. Analyze test quality:
#    - Test count vs code size
#    - Assert density
#    - Test naming consistency
# 5. Generate recommendations:
#    - Priority areas for testing
#    - Suggested test cases
# Return comprehensive report
```

### Step 7: Create the Metrics Calculator

Build a system to calculate overall quality:

```python
class MetricsCalculator:
    """Calculate composite quality metrics."""
    
    def __init__(self, weights: Optional[Dict[str, float]] = None):
        self.weights = weights or {
            "documentation": 0.25,
            "test_coverage": 0.25,
            "complexity": 0.20,
            "smells": 0.20,
            "duplication": 0.10
        }
    
    def calculate_maintainability_index(self, metrics: Dict[str, Any]) -&gt; float:
        """
        Calculate Maintainability Index (MI).
        
        MI = 171 - 5.2 * ln(V) - 0.23 * CC - 16.2 * ln(LOC)
        Where:
        - V = Halstead Volume
        - CC = Cyclomatic Complexity
        - LOC = Lines of Code
        """
        # Implement MI calculation
        # Normalize to 0-100 scale
        # Apply adjustments for language
        # Return final score
    
    def calculate_overall_quality(self, metrics: QualityMetrics) -&gt; float:
        """Calculate weighted overall quality score."""
        # Apply weights to each metric
        # Normalize scores
        # Calculate weighted average
        # Apply penalties for critical issues
        # Return 0-100 score
```

### Step 8: Design Quality Rules Engine

Create a flexible rules system:

```python
@dataclass
class QualityRule:
    """Defines a quality rule to enforce."""
    name: str
    description: str
    metric: str
    operator: str  # "&gt;=", "&lt;=", "==", etc.
    threshold: float
    severity: str  # "error", "warning", "info"
    auto_fix: bool = False

class QualityRulesEngine:
    """Enforce quality rules and standards."""
    
    def __init__(self, rules: List[QualityRule]):
        self.rules = rules
        self.results = []
    
    def evaluate(self, metrics: QualityMetrics) -&gt; List[RuleViolation]:
        """Evaluate all rules against metrics."""
        violations = []
        
        for rule in self.rules:
            # Get metric value
            metric_value = getattr(metrics, rule.metric, None)
            
            if metric_value is not None:
                # Evaluate rule
                if not self._evaluate_condition(
                    metric_value, 
                    rule.operator, 
                    rule.threshold
                ):
                    violations.append(
                        RuleViolation(
                            rule=rule,
                            actual_value=metric_value,
                            timestamp=datetime.now()
                        )
                    )
        
        return violations
```

**🤖 Copilot Prompt Suggestion #4:**
```python
# Implement comprehensive rules engine:
# 1. Define default quality rules:
#    - Min documentation coverage: 80%
#    - Max cyclomatic complexity: 10
#    - Min test coverage: 70%
#    - Max duplication: 5%
# 2. Support rule conditions:
#    - Simple: metric &gt;= threshold
#    - Complex: (metric1 &gt; X) AND (metric2 &lt; Y)
#    - Contextual: different for test files
# 3. Rule actions:
#    - Block CI/CD on violations
#    - Auto-fix if possible
#    - Create GitHub issues
# 4. Rule customization:
#    - Load from config file
#    - Override per project
#    - Team-specific rules
# 5. Reporting:
#    - Group by severity
#    - Show trends over time
# Include helpful fix suggestions
```

## ✅ Progress Verificarpoint

At this point, you should have:
- ✅ Designed the system architecture
- ✅ Created quality metrics structure
- ✅ Built specialized monitors
- ✅ Implemented metrics calculation
- ✅ Designed rules engine
- ✅ Set up quality thresholds

### Architecture Validation

Verify your system design:

```python
# test_architecture.py
system = QualityAutomationSystem()

# Test monitors
assert len(system.monitors) &gt;= 4
assert all(hasattr(m, 'analyze') for m in system.monitors)

# Test metrics
metrics = QualityMetrics()
assert hasattr(metrics, 'overall_quality')
assert metrics.quality_level in QualityLevel

# Test rules
engine = QualityRulesEngine(default_rules())
violations = engine.evaluate(metrics)
assert isinstance(violations, list)
```

## 🎯 Partee 1 Resumo

You've successfully:
1. Designed a comprehensive quality system architecture
2. Created specialized quality monitors
3. Built metrics calculation framework
4. Implemented rules engine for enforcement
5. Established quality thresholds and standards

**Próximo**: Continuar to Partee 2 where we'll implement the complete system with real-time monitoring and reporting!

---

💡 **Pro Tip**: Start with a modular design. Each monitor should be independent so you can enable/disable features based on project needs!