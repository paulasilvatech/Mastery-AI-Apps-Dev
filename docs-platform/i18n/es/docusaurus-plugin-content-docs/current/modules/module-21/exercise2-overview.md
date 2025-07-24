---
sidebar_position: 2
title: "Exercise 2: Overview"
description: "## 🎯 Objective"
---

# Ejercicio 2: Create a Code Revisar Agent with Custom Rules (⭐⭐ Medio - 45 minutos)

## 🎯 Objective
Build an intelligent code review agent that automatically analyzes code changes, applies custom review rules, and provides actionable feedback similar to a senior developer.

## 🧠 Lo Que Aprenderás
- Implementing complex agent logic
- Creating custom review rules
- Analyzing code diffs and changes
- Generating contextual feedback
- Integrating with version control

## 📋 Prerrequisitos
- Completard Ejercicio 1
- Understanding of code analysis
- Familiarity with Git concepts

## 📚 Atrásground

A code review agent can:
- Analyze code changes automatically
- Apply consistent review standards
- Detect potential issues early
- Provide educational feedback
- Ruta code quality trends

## 🛠️ Instructions

### Step 1: Create Revisar Agent Architecture

**Copilot Prompt Suggestion:**
```python
# Design a code review agent that:
# - Analyzes code diffs
# - Applies multiple review rules
# - Generates structured feedback
# - Tracks issues by severity
# - Provides fix suggestions
# - Supports multiple languages
# Use strategy pattern for rules
```

Create `src/agents/code_review_agent.py`:
```python
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import List, Dict, Any, Optional, Set
from enum import Enum
import ast
import re
from datetime import datetime

class Severity(Enum):
    """Issue severity levels"""
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"

@dataclass
class CodeIssue:
    """Represents a code review issue"""
    line_number: int
    severity: Severity
    category: str
    message: str
    suggestion: Optional[str] = None
    code_snippet: Optional[str] = None
    rule_id: Optional[str] = None

@dataclass
class CodeDiff:
    """Represents a code change"""
    file_path: str
    old_content: str
    new_content: str
    added_lines: List[int]
    removed_lines: List[int]
    modified_lines: List[int]

@dataclass
class ReviewResult:
    """Complete review result"""
    issues: List[CodeIssue]
    metrics: Dict[str, Any]
    summary: str
    passed: bool
    timestamp: datetime

class ReviewRule(ABC):
    """Base class for review rules"""
    
    def __init__(self, rule_id: str, severity: Severity):
        self.rule_id = rule_id
        self.severity = severity
    
    @abstractmethod
    def check(self, diff: CodeDiff) -&gt; List[CodeIssue]:
        """Check code against this rule"""
        pass
    
    @abstractmethod
    def description(self) -&gt; str:
        """Get rule description"""
        pass

class CodeReviewAgent:
    """Intelligent code review agent with custom rules"""
    
    def __init__(self, name: str = "CodeReviewAgent"):
        self.name = name
        self.rules: Dict[str, List[ReviewRule]] = {
            'python': [],
            'javascript': [],
            'typescript': [],
            'general': []
        }
        self._initialize_default_rules()
    
    def _initialize_default_rules(self):
        """Initialize default review rules"""
        # Python rules
        self.add_rule('python', SecurityRule())
        self.add_rule('python', ComplexityRule())
        self.add_rule('python', NamingConventionRule())
        self.add_rule('python', DocumentationRule())
        self.add_rule('python', ErrorHandlingRule())
        
        # General rules
        self.add_rule('general', TodoCommentRule())
        self.add_rule('general', LargeFileRule())
        self.add_rule('general', DuplicateCodeRule())
    
    def add_rule(self, language: str, rule: ReviewRule):
        """Add a custom review rule"""
        if language not in self.rules:
            self.rules[language] = []
        self.rules[language].append(rule)
    
    def review_changes(self, diffs: List[CodeDiff]) -&gt; ReviewResult:
        """Review code changes and generate feedback"""
        all_issues = []
        metrics = {
            'files_reviewed': len(diffs),
            'total_lines_changed': 0,
            'issues_by_severity': {{s.value: 0 for s in Severity}},
            'issues_by_category': {{}}
        }
        
        for diff in diffs:
            # Determine language
            language = self._detect_language(diff.file_path)
            
            # Apply language-specific rules
            if language in self.rules:
                for rule in self.rules[language]:
                    issues = rule.check(diff)
                    all_issues.extend(issues)
            
            # Apply general rules
            for rule in self.rules['general']:
                issues = rule.check(diff)
                all_issues.extend(issues)
            
            # Update metrics
            metrics['total_lines_changed'] += len(diff.added_lines) + len(diff.modified_lines)
        
        # Categorize issues
        for issue in all_issues:
            metrics['issues_by_severity'][issue.severity.value] += 1
            if issue.category not in metrics['issues_by_category']:
                metrics['issues_by_category'][issue.category] = 0
            metrics['issues_by_category'][issue.category] += 1
        
        # Generate summary
        summary = self._generate_summary(all_issues, metrics)
        
        # Determine if review passed
        passed = not any(issue.severity in [Severity.ERROR, Severity.CRITICAL] 
                        for issue in all_issues)
        
        return ReviewResult(
            issues=all_issues,
            metrics=metrics,
            summary=summary,
            passed=passed,
            timestamp=datetime.now()
        )
    
    def _detect_language(self, file_path: str) -&gt; str:
        """Detect programming language from file extension"""
        extensions = {
            '.py': 'python',
            '.js': 'javascript',
            '.ts': 'typescript',
            '.jsx': 'javascript',
            '.tsx': 'typescript'
        }
        
        for ext, lang in extensions.items():
            if file_path.endswith(ext):
                return lang
        
        return 'general'
    
    def _generate_summary(self, issues: List[CodeIssue], metrics: Dict) -&gt; str:
        """Generate human-readable summary"""
        if not issues:
            return "✅ Code review passed! No issues found."
        
        summary_parts = [
            f"📊 Reviewed {metrics['files_reviewed']} files with {metrics['total_lines_changed']} lines changed.",
            f"Found {len(issues)} issues:"
        ]
        
        for severity in Severity:
            count = metrics['issues_by_severity'][severity.value]
            if count &gt; 0:
                emoji = {
                    Severity.INFO: "ℹ️",
                    Severity.WARNING: "⚠️",
                    Severity.ERROR: "❌",
                    Severity.CRITICAL: "🚨"
                }[severity]
                summary_parts.append(f"  {emoji} {count} {severity.value}")
        
        return "\n".join(summary_parts)
```

### Step 2: Implement Revisar Rules

**Copilot Prompt Suggestion:**
```python
# Implement specific review rules:
# 1. SecurityRule - detect security vulnerabilities
# 2. ComplexityRule - check cyclomatic complexity
# 3. NamingConventionRule - enforce naming standards
# 4. DocumentationRule - ensure proper documentation
# 5. ErrorHandlingRule - verify error handling
# Each rule should provide detailed feedback
```

Create `src/agents/review_rules.py`:
```python
import ast
import re
from typing import List, Set
from .code_review_agent import ReviewRule, CodeIssue, CodeDiff, Severity

class SecurityRule(ReviewRule):
    """Detects common security vulnerabilities"""
    
    def __init__(self):
        super().__init__("SECURITY", Severity.CRITICAL)
        self.vulnerable_patterns = [
            (r'eval\s*\(', "Use of eval() is dangerous"),
            (r'exec\s*\(', "Use of exec() is dangerous"),
            (r'__import__\s*\(', "Dynamic imports can be risky"),
            (r'pickle\.loads?\s*\(', "Pickle can execute arbitrary code"),
            (r'input\s*\(\s*\)', "Use of input() in Python 2 is dangerous"),
            (r'shell\s*=\s*True', "Shell injection vulnerability"),
            (r'password\s*=\s*["\'].*["\']', "Hardcoded password detected"),
            (r'api_key\s*=\s*["\'].*["\']', "Hardcoded API key detected")
        ]
    
    def check(self, diff: CodeDiff) -&gt; List[CodeIssue]:
        issues = []
        lines = diff.new_content.split('\n')
        
        for line_num, line in enumerate(lines, 1):
            if line_num not in diff.added_lines and line_num not in diff.modified_lines:
                continue
            
            for pattern, message in self.vulnerable_patterns:
                if re.search(pattern, line, re.IGNORECASE):
                    issues.append(CodeIssue(
                        line_number=line_num,
                        severity=self.severity,
                        category="Security",
                        message=message,
                        suggestion="Consider using a safer alternative",
                        code_snippet=line.strip(),
                        rule_id=self.rule_id
                    ))
        
        return issues
    
    def description(self) -&gt; str:
        return "Checks for common security vulnerabilities"

class ComplexityRule(ReviewRule):
    """Checks code complexity"""
    
    def __init__(self, max_complexity: int = 10):
        super().__init__("COMPLEXITY", Severity.WARNING)
        self.max_complexity = max_complexity
    
    def check(self, diff: CodeDiff) -&gt; List[CodeIssue]:
        issues = []
        
        try:
            tree = ast.parse(diff.new_content)
            
            for node in ast.walk(tree):
                if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                    complexity = self._calculate_complexity(node)
                    
                    if complexity &gt; self.max_complexity:
                        issues.append(CodeIssue(
                            line_number=node.lineno,
                            severity=self.severity,
                            category="Complexity",
                            message=f"Function '{node.name}' has complexity {complexity} (max: {self.max_complexity})",
                            suggestion="Consider breaking this function into smaller, more focused functions",
                            rule_id=self.rule_id
                        ))
        
        except SyntaxError:
            # Not valid Python, skip complexity check
            pass
        
        return issues
    
    def _calculate_complexity(self, node: ast.AST) -&gt; int:
        """Calculate cyclomatic complexity"""
        complexity = 1
        
        for child in ast.walk(node):
            if isinstance(child, (ast.If, ast.While, ast.For, ast.AsyncFor,
                                ast.ExceptHandler, ast.With, ast.AsyncWith)):
                complexity += 1
            elif isinstance(child, ast.BoolOp):
                complexity += len(child.values) - 1
        
        return complexity
    
    def description(self) -&gt; str:
        return f"Ensures functions don't exceed complexity of {self.max_complexity}"

class NamingConventionRule(ReviewRule):
    """Enforces naming conventions"""
    
    def __init__(self):
        super().__init__("NAMING", Severity.INFO)
        self.patterns = {
            'function': (r'^[a-z_][a-z0-9_]*$', "snake_case"),
            'class': (r'^[A-Z][a-zA-Z0-9]*$', "PascalCase"),
            'constant': (r'^[A-Z_][A-Z0-9_]*$', "UPPER_SNAKE_CASE")
        }
    
    def check(self, diff: CodeDiff) -&gt; List[CodeIssue]:
        issues = []
        
        try:
            tree = ast.parse(diff.new_content)
            
            for node in ast.walk(tree):
                if isinstance(node, ast.FunctionDef):
                    if not re.match(self.patterns['function'][0], node.name):
                        issues.append(CodeIssue(
                            line_number=node.lineno,
                            severity=self.severity,
                            category="Naming",
                            message=f"Function '{node.name}' should use {self.patterns['function'][1]}",
                            suggestion=f"Rename to '{self._to_snake_case(node.name)}'",
                            rule_id=self.rule_id
                        ))
                
                elif isinstance(node, ast.ClassDef):
                    if not re.match(self.patterns['class'][0], node.name):
                        issues.append(CodeIssue(
                            line_number=node.lineno,
                            severity=self.severity,
                            category="Naming",
                            message=f"Class '{node.name}' should use {self.patterns['class'][1]}",
                            suggestion=f"Rename to '{self._to_pascal_case(node.name)}'",
                            rule_id=self.rule_id
                        ))
        
        except SyntaxError:
            pass
        
        return issues
    
    def _to_snake_case(self, name: str) -&gt; str:
        """Convert to snake_case"""
        return re.sub(r'(?&lt;!^)(?=[A-Z])', '_', name).lower()
    
    def _to_pascal_case(self, name: str) -&gt; str:
        """Convert to PascalCase"""
        return ''.join(word.capitalize() for word in name.split('_'))
    
    def description(self) -&gt; str:
        return "Enforces Python naming conventions"

class DocumentationRule(ReviewRule):
    """Ensures proper documentation"""
    
    def __init__(self):
        super().__init__("DOCUMENTATION", Severity.WARNING)
    
    def check(self, diff: CodeDiff) -&gt; List[CodeIssue]:
        issues = []
        
        try:
            tree = ast.parse(diff.new_content)
            
            for node in ast.walk(tree):
                if isinstance(node, (ast.FunctionDef, ast.ClassDef)):
                    if not ast.get_docstring(node):
                        node_type = "Function" if isinstance(node, ast.FunctionDef) else "Class"
                        issues.append(CodeIssue(
                            line_number=node.lineno,
                            severity=self.severity,
                            category="Documentation",
                            message=f"{node_type} '{node.name}' is missing a docstring",
                            suggestion=f'Add a docstring explaining what this {node_type.lower()} does',
                            rule_id=self.rule_id
                        ))
        
        except SyntaxError:
            pass
        
        return issues
    
    def description(self) -&gt; str:
        return "Ensures all functions and classes have docstrings"

class ErrorHandlingRule(ReviewRule):
    """Checks for proper error handling"""
    
    def __init__(self):
        super().__init__("ERROR_HANDLING", Severity.ERROR)
    
    def check(self, diff: CodeDiff) -&gt; List[CodeIssue]:
        issues = []
        
        try:
            tree = ast.parse(diff.new_content)
            
            for node in ast.walk(tree):
                if isinstance(node, ast.ExceptHandler):
                    # Check for bare except
                    if node.type is None:
                        issues.append(CodeIssue(
                            line_number=node.lineno,
                            severity=self.severity,
                            category="Error Handling",
                            message="Bare 'except:' clause catches all exceptions",
                            suggestion="Specify the exception type you want to catch",
                            rule_id=self.rule_id
                        ))
                    
                    # Check for pass in except
                    if len(node.body) == 1 and isinstance(node.body[0], ast.Pass):
                        issues.append(CodeIssue(
                            line_number=node.lineno,
                            severity=Severity.WARNING,
                            category="Error Handling",
                            message="Exception is caught but not handled",
                            suggestion="Log the error or handle it appropriately",
                            rule_id=self.rule_id
                        ))
        
        except SyntaxError:
            pass
        
        return issues
    
    def description(self) -&gt; str:
        return "Ensures proper exception handling"

# General rules that apply to all languages

class TodoCommentRule(ReviewRule):
    """Finds TODO/FIXME comments"""
    
    def __init__(self):
        super().__init__("TODO_COMMENTS", Severity.INFO)
    
    def check(self, diff: CodeDiff) -&gt; List[CodeIssue]:
        issues = []
        lines = diff.new_content.split('\n')
        
        todo_pattern = r'#\s*(TODO|FIXME|HACK|XXX|BUG)[\s:]+(.+)'
        
        for line_num, line in enumerate(lines, 1):
            if line_num not in diff.added_lines and line_num not in diff.modified_lines:
                continue
            
            match = re.search(todo_pattern, line, re.IGNORECASE)
            if match:
                tag = match.group(1).upper()
                comment = match.group(2).strip()
                
                issues.append(CodeIssue(
                    line_number=line_num,
                    severity=self.severity,
                    category="Maintenance",
                    message=f"{tag} comment found: {comment}",
                    suggestion="Consider creating a GitHub issue to track this",
                    code_snippet=line.strip(),
                    rule_id=self.rule_id
                ))
        
        return issues
    
    def description(self) -&gt; str:
        return "Tracks TODO and FIXME comments"

class LargeFileRule(ReviewRule):
    """Warns about large files"""
    
    def __init__(self, max_lines: int = 500):
        super().__init__("LARGE_FILE", Severity.WARNING)
        self.max_lines = max_lines
    
    def check(self, diff: CodeDiff) -&gt; List[CodeIssue]:
        issues = []
        lines = diff.new_content.split('\n')
        
        if len(lines) &gt; self.max_lines:
            issues.append(CodeIssue(
                line_number=1,
                severity=self.severity,
                category="Maintainability",
                message=f"File has {len(lines)} lines (max recommended: {self.max_lines})",
                suggestion="Consider splitting this file into smaller, more focused modules",
                rule_id=self.rule_id
            ))
        
        return issues
    
    def description(self) -&gt; str:
        return f"Warns when files exceed {self.max_lines} lines"

class DuplicateCodeRule(ReviewRule):
    """Detects duplicate code blocks"""
    
    def __init__(self, min_lines: int = 5):
        super().__init__("DUPLICATE_CODE", Severity.WARNING)
        self.min_lines = min_lines
    
    def check(self, diff: CodeDiff) -&gt; List[CodeIssue]:
        issues = []
        lines = diff.new_content.split('\n')
        
        # Simple duplicate detection - looks for exact matches
        seen_blocks = {}
        
        for i in range(len(lines) - self.min_lines + 1):
            block = '\n'.join(lines[i:i + self.min_lines])
            block_stripped = '\n'.join(line.strip() for line in lines[i:i + self.min_lines])
            
            if block_stripped and all(line.strip() for line in lines[i:i + self.min_lines]):
                if block_stripped in seen_blocks:
                    issues.append(CodeIssue(
                        line_number=i + 1,
                        severity=self.severity,
                        category="Duplication",
                        message=f"Duplicate code block found (also at line {seen_blocks[block_stripped]})",
                        suggestion="Extract common code into a function or method",
                        rule_id=self.rule_id
                    ))
                else:
                    seen_blocks[block_stripped] = i + 1
        
        return issues
    
    def description(self) -&gt; str:
        return f"Detects code blocks duplicated across {self.min_lines}+ lines"
```

### Step 3: Create Integration Layer

**Copilot Prompt Suggestion:**
```python
# Create an integration that:
# - Connects to Git repositories
# - Extracts code diffs
# - Runs the review agent
# - Formats results for different outputs
# - Integrates with GitHub/GitLab APIs
```

Create `src/review_integration.py`:
```python
import subprocess
from typing import List, Optional, Dict
from pathlib import Path
import json
from .agents.code_review_agent import CodeReviewAgent, CodeDiff, ReviewResult

class GitIntegration:
    """Integrates code review agent with Git"""
    
    def __init__(self, repo_path: str):
        self.repo_path = Path(repo_path)
        self.agent = CodeReviewAgent()
    
    def review_commit(self, commit_hash: str) -&gt; ReviewResult:
        """Review a specific commit"""
        diffs = self._get_commit_diffs(commit_hash)
        return self.agent.review_changes(diffs)
    
    def review_branch(self, target_branch: str = "main") -&gt; ReviewResult:
        """Review changes in current branch against target"""
        diffs = self._get_branch_diffs(target_branch)
        return self.agent.review_changes(diffs)
    
    def review_staged(self) -&gt; ReviewResult:
        """Review staged changes"""
        diffs = self._get_staged_diffs()
        return self.agent.review_changes(diffs)
    
    def _get_commit_diffs(self, commit_hash: str) -&gt; List[CodeDiff]:
        """Extract diffs from a commit"""
        # Implementation using git diff
        pass
    
    def _get_branch_diffs(self, target_branch: str) -&gt; List[CodeDiff]:
        """Extract diffs between branches"""
        # Implementation using git diff
        pass
    
    def _get_staged_diffs(self) -&gt; List[CodeDiff]:
        """Extract staged diffs"""
        # Implementation using git diff --staged
        pass
    
    def format_result_markdown(self, result: ReviewResult) -&gt; str:
        """Format review result as Markdown"""
        md_lines = [
            "# Code Review Result",
            f"\n{result.summary}\n",
            f"**Review Time**: {result.timestamp.strftime('%Y-%m-%d %H:%M:%S')}",
            f"**Status**: {'✅ PASSED' if result.passed else '❌ FAILED'}\n"
        ]
        
        if result.issues:
            md_lines.append("## Issues Found\n")
            
            # Group by severity
            for severity in ['critical', 'error', 'warning', 'info']:
                severity_issues = [i for i in result.issues if i.severity.value == severity]
                
                if severity_issues:
                    emoji = {
                        'critical': '🚨',
                        'error': '❌',
                        'warning': '⚠️',
                        'info': 'ℹ️'
                    }[severity]
                    
                    md_lines.append(f"### {emoji} {severity.upper()} ({len(severity_issues)})\n")
                    
                    for issue in severity_issues:
                        md_lines.extend([
                            f"**Line {issue.line_number}**: {issue.message}",
                            f"- Category: {issue.category}",
                            f"- Rule: {issue.rule_id}"
                        ])
                        
                        if issue.code_snippet:
                            md_lines.append(f"- Code: `{issue.code_snippet}`")
                        
                        if issue.suggestion:
                            md_lines.append(f"- Suggestion: {issue.suggestion}")
                        
                        md_lines.append("")
        
        # Add metrics
        md_lines.extend([
            "\n## Metrics\n",
            f"- Files reviewed: {result.metrics['files_reviewed']}",
            f"- Lines changed: {result.metrics['total_lines_changed']}",
            f"- Total issues: {len(result.issues)}"
        ])
        
        return '\n'.join(md_lines)
```

### Step 4: Test the Revisar Agent

Create `tests/test_code_review_agent.py`:
```python
import pytest
from src.agents.code_review_agent import (
    CodeReviewAgent, CodeDiff, Severity
)
from src.agents.review_rules import *

def test_security_rule():
    """Test security vulnerability detection"""
    agent = CodeReviewAgent()
    
    # Create diff with security issues
    diff = CodeDiff(
        file_path="vulnerable.py",
        old_content="",
        new_content="""
password = "hardcoded123"
user_input = input()
result = eval(user_input)
""",
        added_lines=[1, 2, 3],
        removed_lines=[],
        modified_lines=[]
    )
    
    result = agent.review_changes([diff])
    
    # Should find security issues
    assert not result.passed
    security_issues = [i for i in result.issues if i.category == "Security"]
    assert len(security_issues) &gt;= 2

def test_complexity_rule():
    """Test complexity detection"""
    agent = CodeReviewAgent()
    
    # Create complex function
    diff = CodeDiff(
        file_path="complex.py",
        old_content="",
        new_content="""
def complex_function(x):
    if x &gt; 0:
        if x &gt; 10:
            if x &gt; 20:
                if x &gt; 30:
                    if x &gt; 40:
                        if x &gt; 50:
                            return "very high"
                        return "high"
                    return "medium-high"
                return "medium"
            return "low-medium"
        return "low"
    return "zero or negative"
""",
        added_lines=list(range(1, 15)),
        removed_lines=[],
        modified_lines=[]
    )
    
    result = agent.review_changes([diff])
    
    # Should find complexity issue
    complexity_issues = [i for i in result.issues if i.category == "Complexity"]
    assert len(complexity_issues) &gt; 0

def test_custom_rule():
    """Test adding custom rules"""
    agent = CodeReviewAgent()
    
    # Create custom rule
    class PrintStatementRule(ReviewRule):
        def __init__(self):
            super().__init__("NO_PRINT", Severity.WARNING)
        
        def check(self, diff: CodeDiff) -&gt; List[CodeIssue]:
            issues = []
            lines = diff.new_content.split('\n')
            
            for line_num, line in enumerate(lines, 1):
                if 'print(' in line:
                    issues.append(CodeIssue(
                        line_number=line_num,
                        severity=self.severity,
                        category="Debug",
                        message="Print statement found",
                        suggestion="Use logging instead of print",
                        rule_id=self.rule_id
                    ))
            
            return issues
        
        def description(self) -&gt; str:
            return "Prevents print statements in production code"
    
    # Add custom rule
    agent.add_rule('python', PrintStatementRule())
    
    # Test it
    diff = CodeDiff(
        file_path="debug.py",
        old_content="",
        new_content='print("Debug info")',
        added_lines=[1],
        removed_lines=[],
        modified_lines=[]
    )
    
    result = agent.review_changes([diff])
    debug_issues = [i for i in result.issues if i.category == "Debug"]
    assert len(debug_issues) == 1
```

## 🏃 Running the Revisar Agent

Create a script to run reviews:
```python
# review_code.py
from src.review_integration import GitIntegration
import sys

def main():
    # Initialize integration
    git = GitIntegration(".")
    
    # Review staged changes
    print("🔍 Reviewing staged changes...\n")
    result = git.review_staged()
    
    # Print formatted result
    print(git.format_result_markdown(result))
    
    # Exit with appropriate code
    sys.exit(0 if result.passed else 1)

if __name__ == "__main__":
    main()
```

## 🎯 Validation

Run the validation script:
```bash
python scripts/validate_exercise2.py
```

Expected output:
```
✅ Code review agent implemented
✅ All default rules working
✅ Custom rules can be added
✅ Git integration functional
✅ Markdown formatting correct
✅ Metrics tracked accurately

Score: 100/100
```

## 🚀 Extension Challenges

1. **Add Idioma Support**: Extend to JavaScript, TypeScript, Go
2. **Machine Learning**: Use ML to detect code smells
3. **Auto-Fix**: Implement automatic fix suggestions
4. **IDE Integration**: Create VS Code extension
5. **Team Rules**: Load team-specific rules from config

## 📚 Additional Recursos

- [AST Módulo Documentación](https://docs.python.org/3/library/ast.html)
- [Git Diff Format](https://git-scm.com/docs/diff-format)
- [Code Revisar Mejores Prácticas](https://google.github.io/eng-practices/review/)

## ⏭️ Siguiente Ejercicio

Ready for the ultimate challenge? Move on to [Ejercicio 3: Multi-Step Refactoring Agent](../exercise3-hard/README.md)!