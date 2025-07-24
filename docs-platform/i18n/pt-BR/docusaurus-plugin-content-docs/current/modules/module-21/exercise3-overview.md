---
sidebar_position: 3
title: "Exercise 3: Overview"
description: "## 🎯 Objective"
---

# Exercício 3: Develop a Multi-Step Refactoring Agent (⭐⭐⭐ Difícil - 60 minutos)

## 🎯 Objective
Build an advanced AI agent that can analyze code, plan multi-step refactoring operations, execute them safely, and verify the results - all while maintaining code functionality and improving quality.

## 🧠 O Que Você Aprenderá
- Complex agent orchestration
- Multi-step planning and execution
- Code transformation techniques
- Rollback and safety mechanisms
- Testing integration
- Progress tracking and reporting

## 📋 Pré-requisitos
- Completard Exercícios 1 & 2
- Strong understanding of AST manipulation
- Experience with code transformations
- Knowledge of testing frameworks

## 📚 Voltarground

A refactoring agent must:
- Analyze code structure deeply
- Plan transformation sequences
- Execute changes incrementally
- Verify correctness at each step
- Rollback on failures
- Provide detailed progress updates

## 🛠️ Instructions

### Step 1: Design the Refactoring Agent Architecture

**Copilot Prompt Suggestion:**
```python
# Design a sophisticated refactoring agent that:
# - Analyzes code to identify refactoring opportunities
# - Creates multi-step refactoring plans
# - Executes transformations safely
# - Validates each step with tests
# - Supports rollback on failure
# - Tracks progress and generates reports
# Use command pattern for refactoring operations
```

Create `src/agents/refactoring_agent.py`:
```python
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import List, Dict, Any, Optional, Callable, Set, Tuple
from enum import Enum
import ast
import copy
import difflib
from datetime import datetime
import hashlib

class RefactoringType(Enum):
    """Types of refactoring operations"""
    EXTRACT_METHOD = "extract_method"
    EXTRACT_VARIABLE = "extract_variable"
    RENAME = "rename"
    INLINE = "inline"
    MOVE_METHOD = "move_method"
    SIMPLIFY_CONDITIONAL = "simplify_conditional"
    REMOVE_DUPLICATION = "remove_duplication"
    INTRODUCE_PARAMETER_OBJECT = "introduce_parameter_object"
    REPLACE_MAGIC_NUMBER = "replace_magic_number"
    SPLIT_LARGE_CLASS = "split_large_class"

class RefactoringStatus(Enum):
    """Status of refactoring operation"""
    PLANNED = "planned"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"
    ROLLED_BACK = "rolled_back"

@dataclass
class CodeSnapshot:
    """Snapshot of code state"""
    content: str
    timestamp: datetime
    hash: str
    metrics: Dict[str, Any]
    
    @staticmethod
    def create(content: str) -&gt; 'CodeSnapshot':
        """Create a snapshot with metrics"""
        return CodeSnapshot(
            content=content,
            timestamp=datetime.now(),
            hash=hashlib.sha256(content.encode()).hexdigest(),
            metrics=CodeMetrics.calculate(content)
        )

@dataclass
class RefactoringStep:
    """Single step in a refactoring plan"""
    id: str
    type: RefactoringType
    description: str
    target: Any  # AST node or identifier
    parameters: Dict[str, Any]
    dependencies: List[str] = field(default_factory=list)
    status: RefactoringStatus = RefactoringStatus.PLANNED
    
class RefactoringPlan:
    """Multi-step refactoring plan"""
    
    def __init__(self, name: str, goal: str):
        self.name = name
        self.goal = goal
        self.steps: List[RefactoringStep] = []
        self.current_step: int = 0
        self.snapshots: List[CodeSnapshot] = []
        self.test_suite: Optional[Callable] = None
        
    def add_step(self, step: RefactoringStep):
        """Add a refactoring step"""
        self.steps.append(step)
        
    def get_next_step(self) -&gt; Optional[RefactoringStep]:
        """Get next executable step"""
        if self.current_step &lt; len(self.steps):
            return self.steps[self.current_step]
        return None
    
    def mark_step_complete(self):
        """Mark current step as complete"""
        if self.current_step &lt; len(self.steps):
            self.steps[self.current_step].status = RefactoringStatus.COMPLETED
            self.current_step += 1
    
    def can_rollback(self) -&gt; bool:
        """Check if rollback is possible"""
        return len(self.snapshots) &gt; 1

class RefactoringOperation(ABC):
    """Base class for refactoring operations"""
    
    @abstractmethod
    def analyze(self, code: str) -&gt; List[Dict[str, Any]]:
        """Analyze code for refactoring opportunities"""
        pass
    
    @abstractmethod
    def plan(self, code: str, target: Any) -&gt; RefactoringStep:
        """Create a refactoring step"""
        pass
    
    @abstractmethod
    def execute(self, code: str, step: RefactoringStep) -&gt; str:
        """Execute the refactoring"""
        pass
    
    @abstractmethod
    def validate(self, old_code: str, new_code: str) -&gt; bool:
        """Validate the refactoring preserved behavior"""
        pass

class RefactoringAgent:
    """Advanced multi-step refactoring agent"""
    
    def __init__(self, name: str = "RefactoringAgent"):
        self.name = name
        self.operations: Dict[RefactoringType, RefactoringOperation] = {}
        self.current_plan: Optional[RefactoringPlan] = None
        self.history: List[RefactoringPlan] = []
        self._initialize_operations()
        
    def _initialize_operations(self):
        """Register refactoring operations"""
        self.register_operation(RefactoringType.EXTRACT_METHOD, ExtractMethodOperation())
        self.register_operation(RefactoringType.EXTRACT_VARIABLE, ExtractVariableOperation())
        self.register_operation(RefactoringType.RENAME, RenameOperation())
        self.register_operation(RefactoringType.SIMPLIFY_CONDITIONAL, SimplifyConditionalOperation())
        self.register_operation(RefactoringType.REPLACE_MAGIC_NUMBER, ReplaceMagicNumberOperation())
        
    def register_operation(self, type: RefactoringType, operation: RefactoringOperation):
        """Register a refactoring operation"""
        self.operations[type] = operation
        
    def analyze_code(self, code: str) -&gt; Dict[RefactoringType, List[Dict[str, Any]]]:
        """Analyze code for all refactoring opportunities"""
        opportunities = {}
        
        for ref_type, operation in self.operations.items():
            try:
                opps = operation.analyze(code)
                if opps:
                    opportunities[ref_type] = opps
            except Exception as e:
                print(f"Error analyzing {ref_type}: {e}")
                
        return opportunities
    
    def create_refactoring_plan(
        self, 
        code: str, 
        goal: str,
        selected_refactorings: List[Tuple[RefactoringType, Any]]
    ) -&gt; RefactoringPlan:
        """Create a multi-step refactoring plan"""
        plan = RefactoringPlan(f"Refactoring_{datetime.now().timestamp()}", goal)
        
        # Add initial snapshot
        plan.snapshots.append(CodeSnapshot.create(code))
        
        # Create steps for each selected refactoring
        for ref_type, target in selected_refactorings:
            operation = self.operations[ref_type]
            step = operation.plan(code, target)
            plan.add_step(step)
            
        # Optimize step order based on dependencies
        self._optimize_step_order(plan)
        
        self.current_plan = plan
        return plan
    
    def execute_plan(
        self, 
        code: str,
        plan: RefactoringPlan,
        test_suite: Optional[Callable] = None,
        progress_callback: Optional[Callable] = None
    ) -&gt; Tuple[str, Dict[str, Any]]:
        """Execute a refactoring plan"""
        current_code = code
        execution_report = {
            'started_at': datetime.now(),
            'steps_completed': 0,
            'steps_failed': 0,
            'rollbacks': 0,
            'final_metrics': {{}},
            'step_details': []
        }
        
        plan.test_suite = test_suite
        
        # Verify initial tests pass
        if test_suite and not self._run_tests(test_suite, current_code):
            raise Exception("Initial tests failed")
            
        while True:
            step = plan.get_next_step()
            if not step:
                break
                
            # Update progress
            if progress_callback:
                progress_callback(f"Executing: {step.description}", plan.current_step, len(plan.steps))
            
            try:
                # Execute refactoring
                step.status = RefactoringStatus.IN_PROGRESS
                operation = self.operations[step.type]
                new_code = operation.execute(current_code, step)
                
                # Validate transformation
                if not operation.validate(current_code, new_code):
                    raise Exception("Validation failed")
                    
                # Run tests if available
                if test_suite and not self._run_tests(test_suite, new_code):
                    raise Exception("Tests failed after refactoring")
                
                # Success - update state
                current_code = new_code
                plan.snapshots.append(CodeSnapshot.create(current_code))
                plan.mark_step_complete()
                execution_report['steps_completed'] += 1
                
                execution_report['step_details'].append({
                    'step': step.description,
                    'status': 'success',
                    'timestamp': datetime.now()
                })
                
            except Exception as e:
                # Failure - attempt rollback
                execution_report['steps_failed'] += 1
                execution_report['step_details'].append({
                    'step': step.description,
                    'status': 'failed',
                    'error': str(e),
                    'timestamp': datetime.now()
                })
                
                if plan.can_rollback():
                    # Rollback to last known good state
                    current_code = plan.snapshots[-1].content
                    plan.snapshots.pop()
                    execution_report['rollbacks'] += 1
                    
                    if progress_callback:
                        progress_callback(f"Rolled back due to: {e}", plan.current_step, len(plan.steps))
                
                break
        
        # Calculate final metrics
        execution_report['completed_at'] = datetime.now()
        execution_report['duration'] = (
            execution_report['completed_at'] - execution_report['started_at']
        ).total_seconds()
        execution_report['final_metrics'] = CodeMetrics.calculate(current_code)
        
        # Save to history
        self.history.append(plan)
        
        return current_code, execution_report
    
    def _optimize_step_order(self, plan: RefactoringPlan):
        """Optimize step execution order based on dependencies"""
        # Topological sort based on dependencies
        # Simple implementation - can be enhanced
        pass
    
    def _run_tests(self, test_suite: Callable, code: str) -&gt; bool:
        """Run test suite against code"""
        try:
            # Create temporary module and run tests
            # This is simplified - real implementation would be more robust
            return test_suite(code)
        except Exception:
            return False
    
    def generate_report(self, plan: RefactoringPlan, execution_report: Dict[str, Any]) -&gt; str:
        """Generate detailed refactoring report"""
        report_lines = [
            f"# Refactoring Report: {plan.name}",
            f"\n**Goal**: {plan.goal}",
            f"**Duration**: {execution_report['duration']:.2f} seconds",
            f"**Status**: {'✅ Completed' if execution_report['steps_completed'] == len(plan.steps) else '⚠️ Partial'}",
            "",
            "## Summary",
            f"- Steps planned: {len(plan.steps)}",
            f"- Steps completed: {execution_report['steps_completed']}",
            f"- Steps failed: {execution_report['steps_failed']}",
            f"- Rollbacks: {execution_report['rollbacks']}",
            "",
            "## Step Details",
            ""
        ]
        
        for detail in execution_report['step_details']:
            status_emoji = "✅" if detail['status'] == 'success' else "❌"
            report_lines.append(f"{status_emoji} {detail['step']}")
            if 'error' in detail:
                report_lines.append(f"   Error: {detail['error']}")
            report_lines.append("")
        
        # Add before/after comparison
        if len(plan.snapshots) &gt; 1:
            report_lines.extend([
                "## Code Changes",
                "",
                "### Metrics Comparison",
                ""
            ])
            
            initial_metrics = plan.snapshots[0].metrics
            final_metrics = execution_report['final_metrics']
            
            for metric, initial_value in initial_metrics.items():
                final_value = final_metrics.get(metric, initial_value)
                change = final_value - initial_value
                if change != 0:
                    direction = "📈" if change &gt; 0 else "📉"
                    report_lines.append(f"- {metric}: {initial_value} → {final_value} {direction}")
        
        return '\n'.join(report_lines)

class CodeMetrics:
    """Calculate code quality metrics"""
    
    @staticmethod
    def calculate(code: str) -&gt; Dict[str, Any]:
        """Calculate various code metrics"""
        try:
            tree = ast.parse(code)
            
            metrics = {
                'lines_of_code': len(code.split('\n')),
                'num_functions': 0,
                'num_classes': 0,
                'avg_function_length': 0,
                'max_complexity': 0,
                'num_docstrings': 0
            }
            
            function_lengths = []
            
            for node in ast.walk(tree):
                if isinstance(node, ast.FunctionDef):
                    metrics['num_functions'] += 1
                    # Calculate function length
                    if hasattr(node, 'end_lineno') and hasattr(node, 'lineno'):
                        length = node.end_lineno - node.lineno + 1
                        function_lengths.append(length)
                    # Check for docstring
                    if ast.get_docstring(node):
                        metrics['num_docstrings'] += 1
                        
                elif isinstance(node, ast.ClassDef):
                    metrics['num_classes'] += 1
                    if ast.get_docstring(node):
                        metrics['num_docstrings'] += 1
            
            if function_lengths:
                metrics['avg_function_length'] = sum(function_lengths) / len(function_lengths)
                
            return metrics
            
        except Exception:
            return {}
```

### Step 2: Implement Refactoring Operations

**Copilot Prompt Suggestion:**
```python
# Implement specific refactoring operations:
# 1. ExtractMethodOperation - extract code into new method
# 2. ExtractVariableOperation - extract expression to variable
# 3. RenameOperation - rename identifiers consistently
# 4. SimplifyConditionalOperation - simplify complex conditions
# 5. ReplaceMagicNumberOperation - replace literals with constants
# Each should handle edge cases and preserve behavior
```

Create `src/agents/refactoring_operations.py`:
```python
import ast
import re
from typing import List, Dict, Any, Set, Tuple
from .refactoring_agent import RefactoringOperation, RefactoringStep, RefactoringType

class ExtractMethodOperation(RefactoringOperation):
    """Extract code block into a separate method"""
    
    def analyze(self, code: str) -&gt; List[Dict[str, Any]]:
        """Find code blocks suitable for method extraction"""
        opportunities = []
        
        try:
            tree = ast.parse(code)
            
            for node in ast.walk(tree):
                if isinstance(node, ast.FunctionDef):
                    # Look for long functions
                    if hasattr(node, 'end_lineno') and hasattr(node, 'lineno'):
                        length = node.end_lineno - node.lineno + 1
                        if length &gt; 20:
                            # Find extractable blocks
                            blocks = self._find_extractable_blocks(node)
                            for block in blocks:
                                opportunities.append({
                                    'function': node.name,
                                    'lines': block['lines'],
                                    'complexity': block['complexity'],
                                    'description': f"Extract lines {{block['lines'][0]}}-{{block['lines'][-1]}} from {{node.name}}"
                                })
        
        except Exception as e:
            print(f"Error in extract method analysis: {e}")
            
        return opportunities
    
    def plan(self, code: str, target: Dict[str, Any]) -&gt; RefactoringStep:
        """Plan method extraction"""
        return RefactoringStep(
            id=f"extract_method_{target['function']}_{target['lines'][0]}",
            type=RefactoringType.EXTRACT_METHOD,
            description=target['description'],
            target=target,
            parameters={
                'method_name': f"_extracted_method_{{target['lines'][0]}}",
                'extract_variables': True
            }
        )
    
    def execute(self, code: str, step: RefactoringStep) -&gt; str:
        """Execute method extraction"""
        # Parse code
        tree = ast.parse(code)
        target = step.target
        
        # Find the function containing the code to extract
        transformer = MethodExtractor(
            target['function'],
            target['lines'],
            step.parameters['method_name']
        )
        
        # Transform the AST
        new_tree = transformer.visit(tree)
        
        # Convert back to code
        return ast.unparse(new_tree)
    
    def validate(self, old_code: str, new_code: str) -&gt; bool:
        """Validate extraction preserved behavior"""
        # Basic validation - ensure code still parses
        try:
            ast.parse(new_code)
            # More sophisticated validation could compare execution results
            return True
        except:
            return False
    
    def _find_extractable_blocks(self, func_node: ast.FunctionDef) -&gt; List[Dict[str, Any]]:
        """Find blocks of code suitable for extraction"""
        blocks = []
        
        # Look for consecutive statements that form logical blocks
        body = func_node.body
        i = 0
        
        while i &lt; len(body):
            # Find sequences of related statements
            block_start = i
            block_statements = []
            
            # Simple heuristic: group statements until control flow change
            while i &lt; len(body) and not isinstance(body[i], (ast.If, ast.For, ast.While, ast.Return)):
                block_statements.append(body[i])
                i += 1
            
            if len(block_statements) &gt;= 3:  # Minimum block size
                blocks.append({
                    'lines': [s.lineno for s in block_statements if hasattr(s, 'lineno')],
                    'complexity': len(block_statements),
                    'statements': block_statements
                })
            
            i = max(i + 1, block_start + 1)
        
        return blocks

class MethodExtractor(ast.NodeTransformer):
    """AST transformer for method extraction"""
    
    def __init__(self, target_function: str, lines_to_extract: List[int], new_method_name: str):
        self.target_function = target_function
        self.lines_to_extract = set(lines_to_extract)
        self.new_method_name = new_method_name
        self.extracted_code = []
        self.required_variables = set()
        self.modified_variables = set()
    
    def visit_FunctionDef(self, node: ast.FunctionDef):
        if node.name == self.target_function:
            # Process the target function
            new_body = []
            extracted_statements = []
            
            for stmt in node.body:
                if hasattr(stmt, 'lineno') and stmt.lineno in self.lines_to_extract:
                    extracted_statements.append(stmt)
                    # Analyze variables
                    self._analyze_variables(stmt)
                else:
                    new_body.append(stmt)
            
            if extracted_statements:
                # Create method call
                call_args = [ast.Name(id=var, ctx=ast.Load()) for var in sorted(self.required_variables)]
                method_call = ast.Expr(
                    value=ast.Call(
                        func=ast.Attribute(
                            value=ast.Name(id='self', ctx=ast.Load()),
                            attr=self.new_method_name,
                            ctx=ast.Load()
                        ),
                        args=call_args,
                        keywords=[]
                    )
                )
                
                # Insert method call where extracted code was
                insert_index = len(new_body)
                for i, stmt in enumerate(new_body):
                    if hasattr(stmt, 'lineno') and stmt.lineno &gt; min(self.lines_to_extract):
                        insert_index = i
                        break
                
                new_body.insert(insert_index, method_call)
                node.body = new_body
                
                # Store extracted code for later
                self.extracted_code = extracted_statements
        
        self.generic_visit(node)
        return node
    
    def _analyze_variables(self, node):
        """Analyze variable usage in extracted code"""
        # Simplified - real implementation would be more thorough
        for child in ast.walk(node):
            if isinstance(child, ast.Name):
                if isinstance(child.ctx, ast.Load):
                    self.required_variables.add(child.id)
                elif isinstance(child.ctx, ast.Store):
                    self.modified_variables.add(child.id)

class ExtractVariableOperation(RefactoringOperation):
    """Extract repeated expressions into variables"""
    
    def analyze(self, code: str) -&gt; List[Dict[str, Any]]:
        """Find repeated expressions"""
        opportunities = []
        
        try:
            tree = ast.parse(code)
            expression_counts = {}
            
            # Count expression occurrences
            for node in ast.walk(tree):
                if isinstance(node, (ast.BinOp, ast.Call, ast.Attribute)):
                    expr_str = ast.unparse(node)
                    if len(expr_str) &gt; 10:  # Minimum expression size
                        if expr_str not in expression_counts:
                            expression_counts[expr_str] = []
                        if hasattr(node, 'lineno'):
                            expression_counts[expr_str].append(node.lineno)
            
            # Find expressions used multiple times
            for expr, lines in expression_counts.items():
                if len(lines) &gt;= 2:
                    opportunities.append({
                        'expression': expr,
                        'occurrences': len(lines),
                        'lines': lines,
                        'description': f"Extract '{{expr[:30]}}...' used {{len(lines)}} times"
                    })
        
        except Exception as e:
            print(f"Error in extract variable analysis: {e}")
        
        return opportunities
    
    def plan(self, code: str, target: Dict[str, Any]) -&gt; RefactoringStep:
        """Plan variable extraction"""
        var_name = self._suggest_variable_name(target['expression'])
        
        return RefactoringStep(
            id=f"extract_var_{hash(target['expression'])}",
            type=RefactoringType.EXTRACT_VARIABLE,
            description=f"Extract '{target['expression'][:30]}...' to variable '{var_name}'",
            target=target,
            parameters={
                'variable_name': var_name,
                'expression': target['expression']
            }
        )
    
    def execute(self, code: str, step: RefactoringStep) -&gt; str:
        """Execute variable extraction"""
        # This is simplified - real implementation would use AST transformation
        expression = step.parameters['expression']
        var_name = step.parameters['variable_name']
        
        # Find first occurrence and add variable assignment
        lines = code.split('\n')
        first_occurrence_line = min(step.target['lines']) - 1
        
        # Add variable assignment before first use
        indent = len(lines[first_occurrence_line]) - len(lines[first_occurrence_line].lstrip())
        assignment = ' ' * indent + f"{var_name} = {expression}"
        lines.insert(first_occurrence_line, assignment)
        
        # Replace all occurrences
        result_lines = []
        for i, line in enumerate(lines):
            if expression in line:
                line = line.replace(expression, var_name)
            result_lines.append(line)
        
        return '\n'.join(result_lines)
    
    def validate(self, old_code: str, new_code: str) -&gt; bool:
        """Validate variable extraction"""
        try:
            # Ensure both parse correctly
            ast.parse(old_code)
            ast.parse(new_code)
            return True
        except:
            return False
    
    def _suggest_variable_name(self, expression: str) -&gt; str:
        """Suggest a meaningful variable name"""
        # Simple heuristic - can be improved
        if 'calculate' in expression:
            return 'calculated_value'
        elif 'get' in expression:
            return 'retrieved_value'
        elif '+' in expression or '-' in expression:
            return 'computed_result'
        else:
            return 'extracted_value'

class RenameOperation(RefactoringOperation):
    """Rename identifiers consistently"""
    
    def analyze(self, code: str) -&gt; List[Dict[str, Any]]:
        """Find poorly named identifiers"""
        opportunities = []
        
        try:
            tree = ast.parse(code)
            
            # Check variable names
            for node in ast.walk(tree):
                if isinstance(node, ast.Name):
                    if len(node.id) == 1 or node.id in ['tmp', 'temp', 'var', 'val']:
                        opportunities.append({
                            'identifier': node.id,
                            'type': 'variable',
                            'description': f"Rename poorly named variable '{{node.id}}'"
                        })
                
                elif isinstance(node, ast.FunctionDef):
                    if not self._is_good_name(node.name, 'function'):
                        opportunities.append({
                            'identifier': node.name,
                            'type': 'function',
                            'description': f"Rename function '{{node.name}}' to follow conventions"
                        })
        
        except Exception as e:
            print(f"Error in rename analysis: {e}")
        
        return opportunities
    
    def plan(self, code: str, target: Dict[str, Any]) -&gt; RefactoringStep:
        """Plan rename operation"""
        new_name = self._suggest_better_name(target['identifier'], target['type'])
        
        return RefactoringStep(
            id=f"rename_{target['identifier']}",
            type=RefactoringType.RENAME,
            description=f"Rename '{target['identifier']}' to '{new_name}'",
            target=target,
            parameters={
                'old_name': target['identifier'],
                'new_name': new_name
            }
        )
    
    def execute(self, code: str, step: RefactoringStep) -&gt; str:
        """Execute rename operation"""
        old_name = step.parameters['old_name']
        new_name = step.parameters['new_name']
        
        # Use AST to ensure we only rename the right identifiers
        tree = ast.parse(code)
        renamer = IdentifierRenamer(old_name, new_name)
        new_tree = renamer.visit(tree)
        
        return ast.unparse(new_tree)
    
    def validate(self, old_code: str, new_code: str) -&gt; bool:
        """Validate rename operation"""
        try:
            # Parse both versions
            old_tree = ast.parse(old_code)
            new_tree = ast.parse(new_code)
            
            # Ensure structure is the same
            return self._compare_structure(old_tree, new_tree)
        except:
            return False
    
    def _is_good_name(self, name: str, identifier_type: str) -&gt; bool:
        """Check if name follows conventions"""
        if identifier_type == 'function':
            return bool(re.match(r'^[a-z][a-z0-9_]*$', name)) and len(name) &gt; 3
        elif identifier_type == 'variable':
            return len(name) &gt; 1 and name not in ['tmp', 'temp', 'var', 'val']
        return True
    
    def _suggest_better_name(self, old_name: str, identifier_type: str) -&gt; str:
        """Suggest a better name"""
        # Simple suggestions - can be enhanced with context
        suggestions = {
            'i': 'index',
            'j': 'inner_index',
            'k': 'counter',
            'tmp': 'temporary_value',
            'temp': 'temporary_result',
            'var': 'variable_value',
            'val': 'current_value'
        }
        
        return suggestions.get(old_name, f"renamed_{old_name}")
    
    def _compare_structure(self, tree1: ast.AST, tree2: ast.AST) -&gt; bool:
        """Compare AST structure (ignoring names)"""
        # Simplified comparison
        return type(tree1) == type(tree2)

class IdentifierRenamer(ast.NodeTransformer):
    """AST transformer for renaming identifiers"""
    
    def __init__(self, old_name: str, new_name: str):
        self.old_name = old_name
        self.new_name = new_name
        self.in_function_def = False
    
    def visit_Name(self, node: ast.Name):
        if node.id == self.old_name:
            node.id = self.new_name
        return node
    
    def visit_FunctionDef(self, node: ast.FunctionDef):
        if node.name == self.old_name:
            node.name = self.new_name
        self.generic_visit(node)
        return node
    
    def visit_arg(self, node: ast.arg):
        if node.arg == self.old_name:
            node.arg = self.new_name
        return node

class SimplifyConditionalOperation(RefactoringOperation):
    """Simplify complex conditional expressions"""
    
    def analyze(self, code: str) -&gt; List[Dict[str, Any]]:
        """Find complex conditionals"""
        opportunities = []
        
        try:
            tree = ast.parse(code)
            
            for node in ast.walk(tree):
                if isinstance(node, ast.If):
                    complexity = self._calculate_condition_complexity(node.test)
                    
                    if complexity &gt; 3:
                        opportunities.append({
                            'line': node.lineno,
                            'complexity': complexity,
                            'condition': ast.unparse(node.test),
                            'description': f"Simplify complex condition at line {{node.lineno}}"
                        })
        
        except Exception as e:
            print(f"Error in conditional analysis: {e}")
        
        return opportunities
    
    def plan(self, code: str, target: Dict[str, Any]) -&gt; RefactoringStep:
        """Plan conditional simplification"""
        return RefactoringStep(
            id=f"simplify_cond_{target['line']}",
            type=RefactoringType.SIMPLIFY_CONDITIONAL,
            description=target['description'],
            target=target,
            parameters={
                'extract_to_variable': True,
                'use_guard_clauses': True
            }
        )
    
    def execute(self, code: str, step: RefactoringStep) -&gt; str:
        """Execute conditional simplification"""
        # This is a simplified implementation
        # Real implementation would properly transform the AST
        tree = ast.parse(code)
        simplifier = ConditionalSimplifier(step.target['line'])
        new_tree = simplifier.visit(tree)
        
        return ast.unparse(new_tree)
    
    def validate(self, old_code: str, new_code: str) -&gt; bool:
        """Validate simplification preserved logic"""
        # Would need semantic analysis for full validation
        try:
            ast.parse(new_code)
            return True
        except:
            return False
    
    def _calculate_condition_complexity(self, node: ast.AST) -&gt; int:
        """Calculate complexity of conditional expression"""
        complexity = 0
        
        for child in ast.walk(node):
            if isinstance(child, (ast.And, ast.Or)):
                complexity += 1
            elif isinstance(child, ast.BoolOp):
                complexity += len(child.values) - 1
            elif isinstance(child, ast.Compare):
                complexity += len(child.ops)
        
        return complexity

class ConditionalSimplifier(ast.NodeTransformer):
    """Simplify conditional expressions"""
    
    def __init__(self, target_line: int):
        self.target_line = target_line
    
    def visit_If(self, node: ast.If):
        if hasattr(node, 'lineno') and node.lineno == self.target_line:
            # Extract complex condition to variable
            condition_var = ast.Name(id='condition_met', ctx=ast.Store())
            
            # Create assignment
            assign = ast.Assign(
                targets=[condition_var],
                value=node.test
            )
            
            # Simplify the if statement
            node.test = ast.Name(id='condition_met', ctx=ast.Load())
            
            # Return both assignment and simplified if
            return [assign, node]
        
        self.generic_visit(node)
        return node

class ReplaceMagicNumberOperation(RefactoringOperation):
    """Replace magic numbers with named constants"""
    
    def analyze(self, code: str) -&gt; List[Dict[str, Any]]:
        """Find magic numbers in code"""
        opportunities = []
        
        try:
            tree = ast.parse(code)
            
            for node in ast.walk(tree):
                if isinstance(node, ast.Constant):
                    if isinstance(node.value, (int, float)):
                        # Ignore common values like 0, 1, -1
                        if node.value not in [0, 1, -1, 2]:
                            opportunities.append({
                                'value': node.value,
                                'line': getattr(node, 'lineno', 0),
                                'description': f"Replace magic number {{node.value}} with named constant"
                            })
        
        except Exception as e:
            print(f"Error in magic number analysis: {e}")
        
        return opportunities
    
    def plan(self, code: str, target: Dict[str, Any]) -&gt; RefactoringStep:
        """Plan magic number replacement"""
        const_name = self._suggest_constant_name(target['value'])
        
        return RefactoringStep(
            id=f"replace_magic_{target['value']}",
            type=RefactoringType.REPLACE_MAGIC_NUMBER,
            description=target['description'],
            target=target,
            parameters={
                'constant_name': const_name,
                'value': target['value']
            }
        )
    
    def execute(self, code: str, step: RefactoringStep) -&gt; str:
        """Execute magic number replacement"""
        value = step.parameters['value']
        const_name = step.parameters['constant_name']
        
        # Add constant definition at module level
        lines = code.split('\n')
        
        # Find imports end
        import_end = 0
        for i, line in enumerate(lines):
            if line.strip() and not line.startswith(('import', 'from', '#')):
                import_end = i
                break
        
        # Insert constant definition
        lines.insert(import_end, f"\n{const_name} = {value}\n")
        
        # Replace all occurrences
        code = '\n'.join(lines)
        tree = ast.parse(code)
        replacer = MagicNumberReplacer(value, const_name)
        new_tree = replacer.visit(tree)
        
        return ast.unparse(new_tree)
    
    def validate(self, old_code: str, new_code: str) -&gt; bool:
        """Validate magic number replacement"""
        try:
            ast.parse(new_code)
            return True
        except:
            return False
    
    def _suggest_constant_name(self, value: float) -&gt; str:
        """Suggest name for constant"""
        # Common patterns
        if value == 3.14159 or str(value).startswith('3.14'):
            return 'PI'
        elif value == 86400:
            return 'SECONDS_PER_DAY'
        elif value == 3600:
            return 'SECONDS_PER_HOUR'
        elif value == 60:
            return 'SECONDS_PER_MINUTE'
        else:
            return f"CONSTANT_{str(value).replace('.', '_')}"

class MagicNumberReplacer(ast.NodeTransformer):
    """Replace magic numbers with constants"""
    
    def __init__(self, value: float, const_name: str):
        self.value = value
        self.const_name = const_name
    
    def visit_Constant(self, node: ast.Constant):
        if node.value == self.value:
            return ast.Name(id=self.const_name, ctx=ast.Load())
        return node
```

### Step 3: Create Test Framework Integration

Create `src/refactoring_tests.py`:
```python
"""Test framework for validating refactoring operations"""

import ast
import unittest
from typing import Callable, Dict, Any
import tempfile
import subprocess
import sys

class RefactoringTestRunner:
    """Runs tests to validate refactoring operations"""
    
    @staticmethod
    def create_test_suite(test_file_path: str) -&gt; Callable:
        """Create a test suite from a test file"""
        
        def run_tests(refactored_code: str) -&gt; bool:
            """Run tests against refactored code"""
            try:
                # Create temporary file with refactored code
                with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
                    f.write(refactored_code)
                    temp_file = f.name
                
                # Run tests
                result = subprocess.run(
                    [sys.executable, '-m', 'pytest', test_file_path, '-v'],
                    env={{'REFACTORED_MODULE': temp_file}},
                    capture_output=True,
                    text=True
                )
                
                return result.returncode == 0
                
            except Exception as e:
                print(f"Test execution error: {e}")
                return False
        
        return run_tests
```

### Step 4: Create Demo Script

Create `demo_refactoring_agent.py`:
```python
"""Demo script showing the refactoring agent in action"""

from src.agents.refactoring_agent import RefactoringAgent, RefactoringType
from src.refactoring_tests import RefactoringTestRunner

# Sample code to refactor
sample_code = '''
def process_orders(orders):
    total = 0
    for order in orders:
        # Calculate discount
        if order['amount'] &gt; 100:
            if order['customer_type'] == 'premium':
                discount = order['amount'] * 0.2
            else:
                discount = order['amount'] * 0.1
        else:
            discount = 0
        
        # Apply discount
        final_amount = order['amount'] - discount
        
        # Add tax
        tax = final_amount * 0.08
        final_amount = final_amount + tax
        
        # Update total
        total = total + final_amount
        
        # Store result
        order['final_amount'] = final_amount
        order['discount'] = discount
        order['tax'] = tax
    
    # Calculate average
    if len(orders) &gt; 0:
        avg = total / len(orders)
    else:
        avg = 0
    
    return total, avg

def validate_email(email):
    if '@' in email:
        if '.' in email.split('@')[1]:
            return True
    return False

def calculate_metrics(data):
    count = 0
    sum = 0
    for i in range(len(data)):
        if data[i] &gt; 10:
            count = count + 1
            sum = sum + data[i]
    
    if count &gt; 0:
        avg = sum / count
    else:
        avg = 0
    
    return count, sum, avg
'''

def main():
    # Create agent
    agent = RefactoringAgent()
    
    # Analyze code
    print("🔍 Analyzing code for refactoring opportunities...\n")
    opportunities = agent.analyze_code(sample_code)
    
    # Display opportunities
    for ref_type, opps in opportunities.items():
        print(f"\n{ref_type.value}:")
        for opp in opps[:3]:  # Show first 3
            print(f"  - {opp['description']}")
    
    # Create refactoring plan
    print("\n📋 Creating refactoring plan...\n")
    
    selected_refactorings = [
        (RefactoringType.EXTRACT_METHOD, opportunities[RefactoringType.EXTRACT_METHOD][0]),
        (RefactoringType.SIMPLIFY_CONDITIONAL, opportunities[RefactoringType.SIMPLIFY_CONDITIONAL][0]),
        (RefactoringType.REPLACE_MAGIC_NUMBER, opportunities[RefactoringType.REPLACE_MAGIC_NUMBER][0])
    ]
    
    plan = agent.create_refactoring_plan(
        sample_code,
        "Improve code quality and maintainability",
        selected_refactorings
    )
    
    # Execute plan
    print("🚀 Executing refactoring plan...\n")
    
    def progress_callback(message, current, total):
        print(f"[{current}/{total}] {message}")
    
    refactored_code, report = agent.execute_plan(
        sample_code,
        plan,
        test_suite=None,  # Would include tests in real scenario
        progress_callback=progress_callback
    )
    
    # Generate report
    print("\n📊 Refactoring Report:\n")
    print(agent.generate_report(plan, report))
    
    # Show before/after
    print("\n🔄 Code Comparison:")
    print(f"Original: {len(sample_code.split())} lines")
    print(f"Refactored: {len(refactored_code.split())} lines")
    
    # Save refactored code
    with open('refactored_code.py', 'w') as f:
        f.write(refactored_code)
    print("\n✅ Refactored code saved to 'refactored_code.py'")

if __name__ == "__main__":
    main()
```

## 🏃 Running the Refactoring Agent

1. **Basic Usage**:
```bash
python demo_refactoring_agent.py
```

2. **With Your Own Code**:
```python
from src.agents.refactoring_agent import RefactoringAgent

# Load your code
with open('your_module.py', 'r') as f:
    code = f.read()

# Create and run agent
agent = RefactoringAgent()
opportunities = agent.analyze_code(code)

# Select refactorings and execute
# ... (see demo script)
```

## 🎯 Validation

Run the comprehensive validation:
```bash
python scripts/validate_exercise3.py
```

Expected output:
```
✅ Refactoring agent architecture complete
✅ All refactoring operations implemented
✅ Multi-step planning works correctly
✅ Rollback mechanism functional
✅ Test integration successful
✅ Progress tracking accurate
✅ Report generation comprehensive

Score: 100/100
```

## 🚀 Extension Challenges

1. **Machine Learning Integration**: Use ML to suggest refactorings
2. **Parallel Execution**: Execute independent refactorings in parallel
3. **IDE Plugin**: Create VS Code extension for interactive refactoring
4. **Team Patterns**: Learn team-specific refactoring patterns
5. **Performance Impact**: Measure performance impact of refactorings

## 📚 Additional Recursos

- [Refactoring by Martin Fowler](https://refactoring.com/)
- [AST Documentação](https://docs.python.org/3/library/ast.html)
- [Automated Refactoring Research](https://github.com/topics/automated-refactoring)

## 🎉 Congratulations!

You've completed Módulo 21! You've mastered:
- ✅ AI agent architectures
- ✅ GitHub Copilot agent extensions
- ✅ Complex agent orchestration
- ✅ Multi-step planning and execution
- ✅ Production-ready agent desenvolvimento

## ⏭️ Próximo Módulo

Ready to continue? Move on to [Módulo 22: Building Custom Agents](/docs/modules/module-22/) where you'll create even more sophisticated agents!