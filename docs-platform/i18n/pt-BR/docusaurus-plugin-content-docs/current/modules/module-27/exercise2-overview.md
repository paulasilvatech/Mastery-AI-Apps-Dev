---
sidebar_position: 3
title: "Exercise 2: Overview"
description: "## 🎯 Objective"
---

# Exercício 2: Business Rule Extraction (⭐⭐ Médio - 45 minutos)

## 🎯 Objective
Extract complex business logic from COBOL programs and transform it into a modern, AI-enhanced rules engine with explainable decision-making capabilities.

## 🧠 O Que Você Aprenderá
- Business rule identification in COBOL
- Rule extraction and formalization
- Modern rules engine implementation
- AI enhancement for rule optimization
- Decision tree visualization
- Rule validation and testing

## 📋 Pré-requisitos
- Completard Exercício 1 (COBOL Analyzer)
- Python ambiente with required packages
- Understanding of business rules concepts
- Basic knowledge of decision trees

## 📚 Voltarground

COBOL programs often contain critical business logic embedded in procedural code:

- **Validation Rules**: Data integrity checks
- **Calculation Logic**: Complex business formulas
- **Decision Trees**: Nested IF-ELSE structures
- **Business Policies**: Encoded business requirements
- **Compliance Rules**: Regulatory requirements

Modern rules engines provide:
- **Separation of Concerns**: Business logic separate from code
- **Maintainability**: Rules can be modified without recompiling
- **Explainability**: Clear decision paths
- **AI Enhancement**: Optimize and learn from patterns
- **Versão Control**: Trilha rule changes over time

## 🏗️ Rule Extraction Architecture

```mermaid
graph TB
    subgraph "COBOL Analysis"
        SRC[COBOL Source]
        AST[AST Parser]
        LOGIC[Logic Extractor]
    end
    
    subgraph "Rule Processing"
        NORM[Rule Normalizer]
        FORM[Rule Formalizer]
        VAL[Rule Validator]
    end
    
    subgraph "Rules Engine"
        REPO[Rule Repository]
        ENG[Execution Engine]
        EXPL[Explainer]
    end
    
    subgraph "AI Enhancement"
        OPT[Rule Optimizer]
        LEARN[Pattern Learner]
        PRED[Predictor]
    end
    
    subgraph "Output"
        DSL[Rules DSL]
        API[Rules API]
        UI[Rules UI]
        VIZ[Decision Trees]
    end
    
    SRC --&gt; AST
    AST --&gt; LOGIC
    LOGIC --&gt; NORM
    
    NORM --&gt; FORM
    FORM --&gt; VAL
    VAL --&gt; REPO
    
    REPO --&gt; ENG
    ENG --&gt; EXPL
    
    REPO --&gt; OPT
    OPT --&gt; LEARN
    LEARN --&gt; PRED
    
    ENG --&gt; API
    EXPL --&gt; VIZ
    REPO --&gt; DSL
    API --&gt; UI
    
    style ENG fill:#10B981
    style OPT fill:#3B82F6
    style API fill:#F59E0B
```

## 🛠️ Step-by-Step Instructions

### Step 1: Create Business Logic Extractor

**Copilot Prompt Suggestion:**
```python
# Create a COBOL business logic extractor that:
# - Identifies IF-THEN-ELSE structures
# - Extracts COMPUTE statements and formulas
# - Finds validation conditions
# - Maps decision paths
# - Handles nested logic and EVALUATE statements
# Convert to intermediate representation for rules
```

Create `extractors/business_logic_extractor.py`:
```python
import re
from dataclasses import dataclass, field
from typing import List, Dict, Optional, Tuple, Any
from enum import Enum
import ast

class RuleType(Enum):
    VALIDATION = "validation"
    CALCULATION = "calculation"
    DECISION = "decision"
    ASSIGNMENT = "assignment"
    CONDITIONAL = "conditional"

class OperatorType(Enum):
    EQUALS = "="
    NOT_EQUALS = "!="
    GREATER_THAN = "&gt;"
    LESS_THAN = "&lt;"
    GREATER_EQUAL = "&gt;="
    LESS_EQUAL = "&lt;="
    AND = "AND"
    OR = "OR"
    NOT = "NOT"

@dataclass
class Condition:
    """Represents a condition in business logic"""
    left_operand: str
    operator: OperatorType
    right_operand: str
    is_complex: bool = False
    sub_conditions: List['Condition'] = field(default_factory=list)
    
    def to_dict(self) -&gt; Dict:
        return {
            "left": self.left_operand,
            "operator": self.operator.value,
            "right": self.right_operand,
            "complex": self.is_complex,
            "sub_conditions": [c.to_dict() for c in self.sub_conditions]
        }

@dataclass
class Action:
    """Represents an action to take"""
    action_type: str
    target: str
    value: Optional[str] = None
    formula: Optional[str] = None
    
    def to_dict(self) -&gt; Dict:
        return {
            "type": self.action_type,
            "target": self.target,
            "value": self.value,
            "formula": self.formula
        }

@dataclass
class BusinessRule:
    """Represents an extracted business rule"""
    rule_id: str
    rule_type: RuleType
    name: str
    description: str
    source_location: str
    conditions: List[Condition]
    actions: List[Action]
    else_actions: List[Action] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -&gt; Dict:
        return {
            "id": self.rule_id,
            "type": self.rule_type.value,
            "name": self.name,
            "description": self.description,
            "source": self.source_location,
            "conditions": [c.to_dict() for c in self.conditions],
            "actions": [a.to_dict() for a in self.actions],
            "else_actions": [a.to_dict() for a in self.else_actions],
            "metadata": self.metadata
        }

class BusinessLogicExtractor:
    """Extract business logic from COBOL code"""
    
    def __init__(self):
        self.rules = []
        self.rule_counter = 0
        self.current_procedure = ""
        
    def extract_rules(self, cobol_code: str, program_name: str = "UNKNOWN") -&gt; List[BusinessRule]:
        """Extract all business rules from COBOL code"""
        self.rules = []
        self.rule_counter = 0
        
        # Split into lines for processing
        lines = cobol_code.split('\n')
        
        # Process line by line
        i = 0
        while i &lt; len(lines):
            line = lines[i].strip()
            
            # Track current procedure
            if re.match(r'^[A-Z][\w-]*\s*\.$', line):
                self.current_procedure = line.split('.')[0].strip()
            
            # Extract different types of rules
            if self._is_if_statement(line):
                rule = self._extract_if_rule(lines, i)
                if rule:
                    self.rules.append(rule)
                    
            elif self._is_evaluate_statement(line):
                rules = self._extract_evaluate_rules(lines, i)
                self.rules.extend(rules)
                
            elif self._is_compute_statement(line):
                rule = self._extract_compute_rule(line, i)
                if rule:
                    self.rules.append(rule)
                    
            elif self._is_validation_statement(line):
                rule = self._extract_validation_rule(lines, i)
                if rule:
                    self.rules.append(rule)
            
            i += 1
        
        return self.rules
    
    def _is_if_statement(self, line: str) -&gt; bool:
        """Check if line starts an IF statement"""
        return bool(re.match(r'^\s*IF\s+', line, re.IGNORECASE))
    
    def _is_evaluate_statement(self, line: str) -&gt; bool:
        """Check if line starts an EVALUATE statement"""
        return bool(re.match(r'^\s*EVALUATE\s+', line, re.IGNORECASE))
    
    def _is_compute_statement(self, line: str) -&gt; bool:
        """Check if line is a COMPUTE statement"""
        return bool(re.match(r'^\s*COMPUTE\s+', line, re.IGNORECASE))
    
    def _is_validation_statement(self, line: str) -&gt; bool:
        """Check if line contains validation logic"""
        validation_keywords = ['INVALID', 'ERROR', 'NOT NUMERIC', 'NOT ALPHABETIC']
        return any(keyword in line.upper() for keyword in validation_keywords)
    
    def _extract_if_rule(self, lines: List[str], start_idx: int) -&gt; Optional[BusinessRule]:
        """Extract IF-THEN-ELSE rule"""
        self.rule_counter += 1
        rule_id = f"RULE_{self.rule_counter:04d}"
        
        # Parse condition
        condition_text = ""
        actions = []
        else_actions = []
        i = start_idx
        
        # Extract condition
        while i &lt; len(lines) and 'THEN' not in lines[i].upper():
            condition_text += " " + lines[i].strip()
            i += 1
        
        # Parse condition
        condition = self._parse_condition(condition_text)
        if not condition:
            return None
        
        # Extract THEN actions
        in_then = True
        while i &lt; len(lines):
            line = lines[i].strip()
            
            if 'ELSE' in line.upper():
                in_then = False
            elif 'END-IF' in line.upper():
                break
            else:
                action = self._parse_action(line)
                if action:
                    if in_then:
                        actions.append(action)
                    else:
                        else_actions.append(action)
            i += 1
        
        # Create rule
        rule_name = f"{self.current_procedure}_IF_{self.rule_counter}"
        
        return BusinessRule(
            rule_id=rule_id,
            rule_type=RuleType.DECISION,
            name=rule_name,
            description=f"IF rule from {self.current_procedure}",
            source_location=f"{self.current_procedure}:line_{start_idx}",
            conditions=[condition],
            actions=actions,
            else_actions=else_actions,
            metadata={
                "complexity": self._calculate_complexity(condition),
                "procedure": self.current_procedure
            }
        )
    
    def _extract_evaluate_rules(self, lines: List[str], start_idx: int) -&gt; List[BusinessRule]:
        """Extract EVALUATE statement as multiple rules"""
        rules = []
        base_rule_id = f"EVAL_{self.rule_counter:04d}"
        
        # Find the subject of EVALUATE
        evaluate_line = lines[start_idx]
        subject_match = re.search(r'EVALUATE\s+(\S+)', evaluate_line, re.IGNORECASE)
        if not subject_match:
            return rules
        
        subject = subject_match.group(1)
        
        # Parse WHEN clauses
        i = start_idx + 1
        when_counter = 0
        
        while i &lt; len(lines):
            line = lines[i].strip()
            
            if 'END-EVALUATE' in line.upper():
                break
                
            if line.upper().startswith('WHEN'):
                when_counter += 1
                self.rule_counter += 1
                
                # Extract condition value
                when_match = re.search(r'WHEN\s+(.+)', line, re.IGNORECASE)
                if when_match:
                    value = when_match.group(1).strip()
                    
                    # Create condition
                    if value.upper() == 'OTHER':
                        condition = Condition(
                            left_operand=subject,
                            operator=OperatorType.NOT_EQUALS,
                            right_operand="*"
                        )
                    else:
                        condition = Condition(
                            left_operand=subject,
                            operator=OperatorType.EQUALS,
                            right_operand=value
                        )
                    
                    # Extract actions until next WHEN
                    actions = []
                    j = i + 1
                    while j &lt; len(lines):
                        action_line = lines[j].strip()
                        if action_line.upper().startswith('WHEN') or 'END-EVALUATE' in action_line.upper():
                            break
                        action = self._parse_action(action_line)
                        if action:
                            actions.append(action)
                        j += 1
                    
                    # Create rule
                    rule = BusinessRule(
                        rule_id=f"{base_rule_id}_{when_counter}",
                        rule_type=RuleType.DECISION,
                        name=f"{self.current_procedure}_WHEN_{value}",
                        description=f"EVALUATE WHEN {value} from {self.current_procedure}",
                        source_location=f"{self.current_procedure}:line_{i}",
                        conditions=[condition],
                        actions=actions,
                        metadata={
                            "evaluate_subject": subject,
                            "when_value": value,
                            "procedure": self.current_procedure
                        }
                    )
                    
                    rules.append(rule)
            
            i += 1
        
        return rules
    
    def _extract_compute_rule(self, line: str, line_idx: int) -&gt; Optional[BusinessRule]:
        """Extract COMPUTE rule"""
        self.rule_counter += 1
        
        # Parse COMPUTE statement
        compute_match = re.match(r'COMPUTE\s+(\S+)\s*=\s*(.+)', line, re.IGNORECASE)
        if not compute_match:
            return None
        
        target = compute_match.group(1)
        formula = compute_match.group(2).strip()
        
        # Remove trailing period
        if formula.endswith('.'):
            formula = formula[:-1]
        
        # Create action
        action = Action(
            action_type="calculate",
            target=target,
            formula=formula
        )
        
        # Create rule
        return BusinessRule(
            rule_id=f"CALC_{self.rule_counter:04d}",
            rule_type=RuleType.CALCULATION,
            name=f"{self.current_procedure}_COMPUTE_{target}",
            description=f"Calculation for {target}",
            source_location=f"{self.current_procedure}:line_{line_idx}",
            conditions=[],
            actions=[action],
            metadata={
                "formula": formula,
                "variables": self._extract_variables(formula),
                "procedure": self.current_procedure
            }
        )
    
    def _extract_validation_rule(self, lines: List[str], start_idx: int) -&gt; Optional[BusinessRule]:
        """Extract validation rules"""
        self.rule_counter += 1
        line = lines[start_idx]
        
        # Common validation patterns
        patterns = [
            (r'IF\s+(\S+)\s+NOT NUMERIC', 'numeric_validation'),
            (r'IF\s+(\S+)\s+NOT ALPHABETIC', 'alphabetic_validation'),
            (r'IF\s+(\S+)\s+(?:=|IS)\s*(?:SPACES|ZERO|LOW-VALUES)', 'empty_validation'),
            (r'IF\s+(\S+)\s+INVALID', 'invalid_validation')
        ]
        
        for pattern, validation_type in patterns:
            match = re.search(pattern, line, re.IGNORECASE)
            if match:
                field = match.group(1)
                
                # Create condition based on validation type
                if validation_type == 'numeric_validation':
                    condition = Condition(
                        left_operand=f"IS_NUMERIC({field})",
                        operator=OperatorType.EQUALS,
                        right_operand="FALSE"
                    )
                elif validation_type == 'alphabetic_validation':
                    condition = Condition(
                        left_operand=f"IS_ALPHABETIC({field})",
                        operator=OperatorType.EQUALS,
                        right_operand="FALSE"
                    )
                elif validation_type == 'empty_validation':
                    condition = Condition(
                        left_operand=field,
                        operator=OperatorType.EQUALS,
                        right_operand="EMPTY"
                    )
                else:
                    condition = Condition(
                        left_operand=f"IS_VALID({field})",
                        operator=OperatorType.EQUALS,
                        right_operand="FALSE"
                    )
                
                # Extract error action
                actions = []
                if start_idx + 1 &lt; len(lines):
                    next_line = lines[start_idx + 1].strip()
                    if 'MOVE' in next_line.upper() or 'DISPLAY' in next_line.upper():
                        action = self._parse_action(next_line)
                        if action:
                            actions.append(action)
                
                return BusinessRule(
                    rule_id=f"VAL_{self.rule_counter:04d}",
                    rule_type=RuleType.VALIDATION,
                    name=f"{self.current_procedure}_{validation_type}_{field}",
                    description=f"Validation rule for {field}",
                    source_location=f"{self.current_procedure}:line_{start_idx}",
                    conditions=[condition],
                    actions=actions,
                    metadata={
                        "field": field,
                        "validation_type": validation_type,
                        "procedure": self.current_procedure
                    }
                )
        
        return None
    
    def _parse_condition(self, condition_text: str) -&gt; Optional[Condition]:
        """Parse a condition string into Condition object"""
        # Clean up the condition text
        condition_text = condition_text.replace('IF', '', 1).strip()
        
        # Handle complex conditions with AND/OR
        if ' AND ' in condition_text.upper() or ' OR ' in condition_text.upper():
            return self._parse_complex_condition(condition_text)
        
        # Parse simple condition
        # Common patterns
        patterns = [
            r'(\S+)\s+(?:IS\s+)?(?:=|EQUAL TO)\s+(.+)',
            r'(\S+)\s+(?:IS\s+)?(?:&gt;|GREATER THAN)\s+(.+)',
            r'(\S+)\s+(?:IS\s+)?(?:&lt;|LESS THAN)\s+(.+)',
            r'(\S+)\s+(?:IS\s+)?(?:&gt;=|GREATER THAN OR EQUAL TO)\s+(.+)',
            r'(\S+)\s+(?:IS\s+)?(?:&lt;=|LESS THAN OR EQUAL TO)\s+(.+)',
            r'(\S+)\s+(?:IS\s+)?(?:NOT EQUAL TO|&lt;&gt;)\s+(.+)',
        ]
        
        operators = [
            OperatorType.EQUALS,
            OperatorType.GREATER_THAN,
            OperatorType.LESS_THAN,
            OperatorType.GREATER_EQUAL,
            OperatorType.LESS_EQUAL,
            OperatorType.NOT_EQUALS
        ]
        
        for pattern, op in zip(patterns, operators):
            match = re.search(pattern, condition_text, re.IGNORECASE)
            if match:
                return Condition(
                    left_operand=match.group(1),
                    operator=op,
                    right_operand=match.group(2).strip()
                )
        
        # Handle special conditions (88 level conditions)
        if re.match(r'^\S+$', condition_text):
            return Condition(
                left_operand=condition_text,
                operator=OperatorType.EQUALS,
                right_operand="TRUE"
            )
        
        return None
    
    def _parse_complex_condition(self, condition_text: str) -&gt; Condition:
        """Parse complex condition with AND/OR"""
        # This is a simplified version - real implementation would need proper parsing
        if ' AND ' in condition_text.upper():
            parts = re.split(r'\s+AND\s+', condition_text, flags=re.IGNORECASE)
            sub_conditions = [self._parse_condition(part) for part in parts]
            
            return Condition(
                left_operand="COMPLEX",
                operator=OperatorType.AND,
                right_operand="COMPLEX",
                is_complex=True,
                sub_conditions=[c for c in sub_conditions if c]
            )
        
        elif ' OR ' in condition_text.upper():
            parts = re.split(r'\s+OR\s+', condition_text, flags=re.IGNORECASE)
            sub_conditions = [self._parse_condition(part) for part in parts]
            
            return Condition(
                left_operand="COMPLEX",
                operator=OperatorType.OR,
                right_operand="COMPLEX",
                is_complex=True,
                sub_conditions=[c for c in sub_conditions if c]
            )
        
        return self._parse_condition(condition_text)
    
    def _parse_action(self, line: str) -&gt; Optional[Action]:
        """Parse an action from a line"""
        line = line.strip()
        
        # MOVE statement
        move_match = re.match(r'MOVE\s+(\S+)\s+TO\s+(\S+)', line, re.IGNORECASE)
        if move_match:
            return Action(
                action_type="assign",
                target=move_match.group(2),
                value=move_match.group(1)
            )
        
        # PERFORM statement
        perform_match = re.match(r'PERFORM\s+(\S+)', line, re.IGNORECASE)
        if perform_match:
            return Action(
                action_type="perform",
                target=perform_match.group(1)
            )
        
        # DISPLAY statement
        display_match = re.match(r'DISPLAY\s+(.+)', line, re.IGNORECASE)
        if display_match:
            return Action(
                action_type="display",
                target="console",
                value=display_match.group(1).strip('"')
            )
        
        # ADD statement
        add_match = re.match(r'ADD\s+(\S+)\s+TO\s+(\S+)', line, re.IGNORECASE)
        if add_match:
            return Action(
                action_type="calculate",
                target=add_match.group(2),
                formula=f"{add_match.group(2)} + {add_match.group(1)}"
            )
        
        # SUBTRACT statement
        subtract_match = re.match(r'SUBTRACT\s+(\S+)\s+FROM\s+(\S+)', line, re.IGNORECASE)
        if subtract_match:
            return Action(
                action_type="calculate",
                target=subtract_match.group(2),
                formula=f"{subtract_match.group(2)} - {subtract_match.group(1)}"
            )
        
        return None
    
    def _calculate_complexity(self, condition: Condition) -&gt; int:
        """Calculate complexity score for a condition"""
        if not condition.is_complex:
            return 1
        
        complexity = 1
        for sub in condition.sub_conditions:
            complexity += self._calculate_complexity(sub)
        
        return complexity
    
    def _extract_variables(self, formula: str) -&gt; List[str]:
        """Extract variable names from a formula"""
        # Remove operators and numbers
        tokens = re.findall(r'[A-Za-z][\w-]*', formula)
        return list(set(tokens))
```

### Step 2: Create Modern Rules Engine

Create `rules_engine/rule_engine.py`:
```python
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
from datetime import datetime
import json
import uuid
from enum import Enum

class RuleStatus(Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    DRAFT = "draft"
    DEPRECATED = "deprecated"

@dataclass
class RuleExecutionContext:
    """Context for rule execution"""
    data: Dict[str, Any]
    metadata: Dict[str, Any] = None
    trace: List[Dict] = None
    
    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}
        if self.trace is None:
            self.trace = []
    
    def get_value(self, path: str) -&gt; Any:
        """Get value from context using dot notation"""
        parts = path.split('.')
        value = self.data
        
        for part in parts:
            if isinstance(value, dict) and part in value:
                value = value[part]
            else:
                return None
        
        return value
    
    def set_value(self, path: str, value: Any):
        """Set value in context using dot notation"""
        parts = path.split('.')
        target = self.data
        
        for i, part in enumerate(parts[:-1]):
            if part not in target:
                target[part] = {}
            target = target[part]
        
        target[parts[-1]] = value
    
    def add_trace(self, event: Dict):
        """Add execution trace event"""
        self.trace.append({
            "timestamp": datetime.now().isoformat(),
            **event
        })

class RuleEngine:
    """Modern rule execution engine"""
    
    def __init__(self):
        self.rules = {}
        self.rule_sets = {}
        self.execution_stats = {}
    
    def register_rule(self, rule_id: str, rule_def: Dict):
        """Register a rule in the engine"""
        self.rules[rule_id] = {
            "id": rule_id,
            "status": RuleStatus.ACTIVE,
            "created": datetime.now().isoformat(),
            "version": 1,
            **rule_def
        }
    
    def create_rule_set(self, name: str, rule_ids: List[str], 
                       execution_order: str = "sequential") -&gt; str:
        """Create a rule set for grouped execution"""
        rule_set_id = str(uuid.uuid4())
        
        self.rule_sets[rule_set_id] = {
            "id": rule_set_id,
            "name": name,
            "rules": rule_ids,
            "execution_order": execution_order,
            "created": datetime.now().isoformat()
        }
        
        return rule_set_id
    
    def execute_rule(self, rule_id: str, context: RuleExecutionContext) -&gt; Dict[str, Any]:
        """Execute a single rule"""
        if rule_id not in self.rules:
            raise ValueError(f"Rule {rule_id} not found")
        
        rule = self.rules[rule_id]
        
        if rule.get("status") != RuleStatus.ACTIVE:
            return {
                "rule_id": rule_id,
                "executed": False,
                "reason": f"Rule status is {{rule.get('status')}}"
            }
        
        # Start execution
        start_time = datetime.now()
        context.add_trace({
            "event": "rule_start",
            "rule_id": rule_id,
            "rule_name": rule.get("name")
        })
        
        try:
            # Evaluate conditions
            conditions_met = self._evaluate_conditions(rule.get("conditions", []), context)
            
            # Execute actions based on condition result
            if conditions_met:
                actions_executed = self._execute_actions(rule.get("actions", []), context)
                result = {
                    "rule_id": rule_id,
                    "executed": True,
                    "conditions_met": True,
                    "actions_executed": actions_executed
                }
            else:
                # Execute else actions if conditions not met
                else_actions = rule.get("else_actions", [])
                if else_actions:
                    actions_executed = self._execute_actions(else_actions, context)
                    result = {
                        "rule_id": rule_id,
                        "executed": True,
                        "conditions_met": False,
                        "else_actions_executed": actions_executed
                    }
                else:
                    result = {
                        "rule_id": rule_id,
                        "executed": True,
                        "conditions_met": False,
                        "actions_executed": []
                    }
            
            # Record execution
            execution_time = (datetime.now() - start_time).total_seconds()
            context.add_trace({
                "event": "rule_complete",
                "rule_id": rule_id,
                "execution_time": execution_time,
                "result": result
            })
            
            # Update statistics
            self._update_stats(rule_id, execution_time, conditions_met)
            
            return result
            
        except Exception as e:
            context.add_trace({
                "event": "rule_error",
                "rule_id": rule_id,
                "error": str(e)
            })
            
            return {
                "rule_id": rule_id,
                "executed": False,
                "error": str(e)
            }
    
    def execute_rule_set(self, rule_set_id: str, 
                        context: RuleExecutionContext) -&gt; Dict[str, Any]:
        """Execute a rule set"""
        if rule_set_id not in self.rule_sets:
            raise ValueError(f"Rule set {rule_set_id} not found")
        
        rule_set = self.rule_sets[rule_set_id]
        results = []
        
        context.add_trace({
            "event": "rule_set_start",
            "rule_set_id": rule_set_id,
            "rule_set_name": rule_set.get("name")
        })
        
        # Execute rules based on execution order
        if rule_set.get("execution_order") == "sequential":
            for rule_id in rule_set.get("rules", []):
                result = self.execute_rule(rule_id, context)
                results.append(result)
                
                # Stop on first matching rule if specified
                if rule_set.get("stop_on_first_match") and result.get("conditions_met"):
                    break
        
        elif rule_set.get("execution_order") == "parallel":
            # In real implementation, this would use async/threading
            for rule_id in rule_set.get("rules", []):
                result = self.execute_rule(rule_id, context)
                results.append(result)
        
        context.add_trace({
            "event": "rule_set_complete",
            "rule_set_id": rule_set_id,
            "rules_executed": len(results)
        })
        
        return {
            "rule_set_id": rule_set_id,
            "results": results,
            "context": context.data
        }
    
    def _evaluate_conditions(self, conditions: List[Dict], 
                           context: RuleExecutionContext) -&gt; bool:
        """Evaluate rule conditions"""
        if not conditions:
            return True
        
        for condition in conditions:
            if condition.get("complex"):
                # Handle complex conditions
                result = self._evaluate_complex_condition(condition, context)
            else:
                # Simple condition
                result = self._evaluate_simple_condition(condition, context)
            
            # All conditions must be true (AND logic by default)
            if not result:
                return False
        
        return True
    
    def _evaluate_simple_condition(self, condition: Dict, 
                                 context: RuleExecutionContext) -&gt; bool:
        """Evaluate a simple condition"""
        left_value = self._resolve_value(condition.get("left"), context)
        right_value = self._resolve_value(condition.get("right"), context)
        operator = condition.get("operator")
        
        # Type conversion for comparison
        left_value, right_value = self._normalize_values(left_value, right_value)
        
        # Evaluate based on operator
        if operator == "=":
            return left_value == right_value
        elif operator == "!=":
            return left_value != right_value
        elif operator == "&gt;":
            return left_value &gt; right_value
        elif operator == "&lt;":
            return left_value &lt; right_value
        elif operator == "&gt;=":
            return left_value &gt;= right_value
        elif operator == "&lt;=":
            return left_value &lt;= right_value
        else:
            raise ValueError(f"Unknown operator: {operator}")
    
    def _evaluate_complex_condition(self, condition: Dict, 
                                  context: RuleExecutionContext) -&gt; bool:
        """Evaluate complex condition with AND/OR"""
        operator = condition.get("operator")
        sub_conditions = condition.get("sub_conditions", [])
        
        if operator == "AND":
            return all(self._evaluate_conditions([sub], context) 
                      for sub in sub_conditions)
        elif operator == "OR":
            return any(self._evaluate_conditions([sub], context) 
                      for sub in sub_conditions)
        else:
            return False
    
    def _execute_actions(self, actions: List[Dict], 
                        context: RuleExecutionContext) -&gt; List[Dict]:
        """Execute rule actions"""
        executed_actions = []
        
        for action in actions:
            action_type = action.get("type")
            
            if action_type == "assign":
                target = action.get("target")
                value = self._resolve_value(action.get("value"), context)
                context.set_value(target, value)
                
                executed_actions.append({
                    "type": "assign",
                    "target": target,
                    "value": value
                })
            
            elif action_type == "calculate":
                target = action.get("target")
                formula = action.get("formula")
                result = self._evaluate_formula(formula, context)
                context.set_value(target, result)
                
                executed_actions.append({
                    "type": "calculate",
                    "target": target,
                    "result": result
                })
            
            elif action_type == "perform":
                # In real implementation, this would call external functions
                executed_actions.append({
                    "type": "perform",
                    "target": action.get("target")
                })
            
            elif action_type == "display":
                # Log or output message
                message = self._resolve_value(action.get("value"), context)
                executed_actions.append({
                    "type": "display",
                    "message": message
                })
        
        return executed_actions
    
    def _resolve_value(self, value: Any, context: RuleExecutionContext) -&gt; Any:
        """Resolve value from context or return literal"""
        if isinstance(value, str):
            # Check if it's a variable reference
            if value.startswith("$"):
                return context.get_value(value[1:])
            # Check for function calls
            elif value.startswith("IS_NUMERIC("):
                var_name = value[11:-1]
                var_value = context.get_value(var_name)
                return str(var_value).replace('.', '').replace('-', '').isdigit()
            elif value.startswith("IS_ALPHABETIC("):
                var_name = value[14:-1]
                var_value = context.get_value(var_name)
                return str(var_value).isalpha()
            elif value == "TRUE":
                return True
            elif value == "FALSE":
                return False
            elif value == "EMPTY":
                return ""
        
        return value
    
    def _normalize_values(self, left: Any, right: Any) -&gt; Tuple[Any, Any]:
        """Normalize values for comparison"""
        # Try to convert to numbers if possible
        try:
            left_num = float(left)
            right_num = float(right)
            return left_num, right_num
        except:
            # Compare as strings
            return str(left), str(right)
    
    def _evaluate_formula(self, formula: str, context: RuleExecutionContext) -&gt; Any:
        """Evaluate a mathematical formula"""
        # Replace variables with values
        tokens = re.findall(r'[A-Za-z][\w-]*', formula)
        
        eval_formula = formula
        for token in tokens:
            value = context.get_value(token)
            if value is not None:
                eval_formula = eval_formula.replace(token, str(value))
        
        # Safely evaluate the formula
        try:
            # Use ast.literal_eval for safety in production
            result = eval(eval_formula)
            return result
        except:
            return None
    
    def _update_stats(self, rule_id: str, execution_time: float, conditions_met: bool):
        """Update execution statistics"""
        if rule_id not in self.execution_stats:
            self.execution_stats[rule_id] = {
                "total_executions": 0,
                "conditions_met_count": 0,
                "total_execution_time": 0,
                "avg_execution_time": 0
            }
        
        stats = self.execution_stats[rule_id]
        stats["total_executions"] += 1
        stats["total_execution_time"] += execution_time
        stats["avg_execution_time"] = stats["total_execution_time"] / stats["total_executions"]
        
        if conditions_met:
            stats["conditions_met_count"] += 1
```

### Step 3: Create AI Rule Optimizer

Create `rules_engine/ai_rule_optimizer.py`:
```python
import openai
import json
from typing import List, Dict, Optional, Tuple
import numpy as np
from collections import Counter
from datetime import datetime
import pandas as pd

class AIRuleOptimizer:
    """AI-powered rule optimization and learning"""
    
    def __init__(self, api_key: str):
        self.api_key = api_key
        openai.api_key = api_key
        self.optimization_history = []
    
    def optimize_rules(self, rules: List[Dict], 
                      execution_stats: Dict[str, Dict]) -&gt; List[Dict]:
        """Optimize rules based on execution statistics"""
        
        # Analyze rule performance
        performance_analysis = self._analyze_performance(rules, execution_stats)
        
        # Get AI recommendations
        recommendations = self._get_ai_recommendations(rules, performance_analysis)
        
        # Apply optimizations
        optimized_rules = self._apply_optimizations(rules, recommendations)
        
        # Record optimization
        self.optimization_history.append({
            "timestamp": datetime.now().isoformat(),
            "original_rules": len(rules),
            "optimized_rules": len(optimized_rules),
            "recommendations": recommendations
        })
        
        return optimized_rules
    
    def _analyze_performance(self, rules: List[Dict], 
                           execution_stats: Dict[str, Dict]) -&gt; Dict:
        """Analyze rule performance metrics"""
        analysis = {
            "total_rules": len(rules),
            "executed_rules": len(execution_stats),
            "performance_metrics": {{}},
            "bottlenecks": [],
            "unused_rules": []
        }
        
        # Identify performance issues
        for rule in rules:
            rule_id = rule.get("id")
            stats = execution_stats.get(rule_id, {})
            
            if not stats:
                analysis["unused_rules"].append(rule_id)
                continue
            
            # Calculate metrics
            hit_rate = stats.get("conditions_met_count", 0) / max(stats.get("total_executions", 1), 1)
            avg_time = stats.get("avg_execution_time", 0)
            
            analysis["performance_metrics"][rule_id] = {
                "hit_rate": hit_rate,
                "avg_execution_time": avg_time,
                "total_executions": stats.get("total_executions", 0)
            }
            
            # Identify bottlenecks
            if avg_time &gt; 0.1:  # More than 100ms
                analysis["bottlenecks"].append({
                    "rule_id": rule_id,
                    "avg_time": avg_time,
                    "reason": "slow_execution"
                })
            
            if hit_rate &lt; 0.01 and stats.get("total_executions", 0) &gt; 100:
                analysis["bottlenecks"].append({
                    "rule_id": rule_id,
                    "hit_rate": hit_rate,
                    "reason": "low_hit_rate"
                })
        
        return analysis
    
    def _get_ai_recommendations(self, rules: List[Dict], 
                               performance_analysis: Dict) -&gt; List[Dict]:
        """Get AI-powered optimization recommendations"""
        
        # Prepare context for AI
        context = {
            "total_rules": len(rules),
            "performance_summary": performance_analysis,
            "sample_rules": rules[:5]  # Send sample for analysis
        }
        
        prompt = f"""
        Analyze these business rules and performance metrics, provide optimization recommendations:
        
        Performance Analysis:
        {json.dumps(performance_analysis, indent=2)}
        
        Sample Rules:
        {json.dumps(context['sample_rules'], indent=2)}
        
        Provide recommendations in JSON format:
        {{
            "optimizations": [
                {{
                    "type": "merge|reorder|simplify|cache|remove",
                    "target_rules": ["rule_ids"],
                    "description": "explanation",
                    "expected_improvement": "percentage or description"
                }}
            ],
            "patterns": ["identified patterns"],
            "suggestions": ["general suggestions"]
        }}
        
        Focus on:
        1. Rules that can be merged or simplified
        2. Execution order optimization
        3. Caching opportunities
        4. Dead code elimination
        5. Performance bottlenecks
        """
        
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[
                {{"role": "system", "content": "You are a business rule optimization expert."}},
                {{"role": "user", "content": prompt}}
            ],
            temperature=0.3,
            max_tokens=2000
        )
        
        try:
            recommendations = json.loads(response.choices[0].message.content)
            return recommendations.get("optimizations", [])
        except:
            return []
    
    def _apply_optimizations(self, rules: List[Dict], 
                           recommendations: List[Dict]) -&gt; List[Dict]:
        """Apply optimization recommendations"""
        optimized_rules = rules.copy()
        
        for recommendation in recommendations:
            opt_type = recommendation.get("type")
            
            if opt_type == "merge":
                optimized_rules = self._merge_rules(
                    optimized_rules, 
                    recommendation.get("target_rules", [])
                )
            
            elif opt_type == "reorder":
                optimized_rules = self._reorder_rules(
                    optimized_rules,
                    recommendation
                )
            
            elif opt_type == "simplify":
                optimized_rules = self._simplify_rules(
                    optimized_rules,
                    recommendation.get("target_rules", [])
                )
            
            elif opt_type == "remove":
                optimized_rules = self._remove_rules(
                    optimized_rules,
                    recommendation.get("target_rules", [])
                )
        
        return optimized_rules
    
    def _merge_rules(self, rules: List[Dict], target_ids: List[str]) -&gt; List[Dict]:
        """Merge similar rules"""
        if len(target_ids) &lt; 2:
            return rules
        
        # Find rules to merge
        rules_to_merge = [r for r in rules if r.get("id") in target_ids]
        other_rules = [r for r in rules if r.get("id") not in target_ids]
        
        if len(rules_to_merge) &lt; 2:
            return rules
        
        # Create merged rule
        merged_rule = {
            "id": f"MERGED_{{datetime.now().strftime('%Y%m%d%H%M%S')}}",
            "name": f"Merged from {{', '.join([r.get('name', r.get('id')) for r in rules_to_merge])}}",
            "type": rules_to_merge[0].get("type"),
            "conditions": [],
            "actions": []
        }
        
        # Merge conditions with OR logic
        all_conditions = []
        for rule in rules_to_merge:
            rule_conditions = rule.get("conditions", [])
            if rule_conditions:
                all_conditions.append({
                    "complex": True,
                    "operator": "AND",
                    "sub_conditions": rule_conditions
                })
        
        if len(all_conditions) &gt; 1:
            merged_rule["conditions"] = [{
                "complex": True,
                "operator": "OR",
                "sub_conditions": all_conditions
            }]
        else:
            merged_rule["conditions"] = all_conditions[0].get("sub_conditions", [])
        
        # Merge actions (remove duplicates)
        seen_actions = set()
        for rule in rules_to_merge:
            for action in rule.get("actions", []):
                action_key = f"{action.get('type')}_{action.get('target')}"
                if action_key not in seen_actions:
                    merged_rule["actions"].append(action)
                    seen_actions.add(action_key)
        
        return other_rules + [merged_rule]
    
    def _reorder_rules(self, rules: List[Dict], recommendation: Dict) -&gt; List[Dict]:
        """Reorder rules for better performance"""
        # Simple implementation - move high hit rate rules first
        rule_scores = {}
        
        for rule in rules:
            # Calculate score based on recommendation
            score = 0
            rule_id = rule.get("id")
            
            # Prioritize validation rules
            if rule.get("type") == "validation":
                score += 100
            
            # Consider complexity
            conditions = rule.get("conditions", [])
            complexity = len(conditions)
            score -= complexity * 10
            
            rule_scores[rule_id] = score
        
        # Sort rules by score
        sorted_rules = sorted(rules, key=lambda r: rule_scores.get(r.get("id"), 0), reverse=True)
        
        return sorted_rules
    
    def _simplify_rules(self, rules: List[Dict], target_ids: List[str]) -&gt; List[Dict]:
        """Simplify complex rules"""
        simplified_rules = []
        
        for rule in rules:
            if rule.get("id") in target_ids:
                simplified = self._simplify_single_rule(rule)
                simplified_rules.append(simplified)
            else:
                simplified_rules.append(rule)
        
        return simplified_rules
    
    def _simplify_single_rule(self, rule: Dict) -&gt; Dict:
        """Simplify a single rule"""
        simplified = rule.copy()
        
        # Simplify conditions
        conditions = rule.get("conditions", [])
        if conditions:
            # Remove redundant conditions
            simplified["conditions"] = self._remove_redundant_conditions(conditions)
        
        # Optimize actions
        actions = rule.get("actions", [])
        if actions:
            # Combine consecutive assignments to same target
            simplified["actions"] = self._optimize_actions(actions)
        
        return simplified
    
    def _remove_redundant_conditions(self, conditions: List[Dict]) -&gt; List[Dict]:
        """Remove redundant conditions"""
        # Simple implementation - remove exact duplicates
        seen = set()
        unique_conditions = []
        
        for condition in conditions:
            condition_key = json.dumps(condition, sort_keys=True)
            if condition_key not in seen:
                seen.add(condition_key)
                unique_conditions.append(condition)
        
        return unique_conditions
    
    def _optimize_actions(self, actions: List[Dict]) -&gt; List[Dict]:
        """Optimize action sequence"""
        optimized = []
        last_target = None
        
        for action in actions:
            # Skip consecutive assignments to same target (keep last)
            if action.get("type") == "assign" and action.get("target") == last_target:
                optimized[-1] = action  # Replace with latest
            else:
                optimized.append(action)
                last_target = action.get("target") if action.get("type") == "assign" else None
        
        return optimized
    
    def _remove_rules(self, rules: List[Dict], target_ids: List[str]) -&gt; List[Dict]:
        """Remove specified rules"""
        return [r for r in rules if r.get("id") not in target_ids]
    
    def learn_from_execution(self, execution_traces: List[Dict]) -&gt; Dict:
        """Learn patterns from execution traces"""
        patterns = {
            "common_paths": [],
            "bottlenecks": [],
            "anomalies": [],
            "optimization_opportunities": []
        }
        
        # Analyze execution paths
        path_counter = Counter()
        timing_data = []
        
        for trace in execution_traces:
            # Extract execution path
            path = []
            total_time = 0
            
            for event in trace.get("trace", []):
                if event.get("event") == "rule_complete":
                    rule_id = event.get("rule_id")
                    exec_time = event.get("execution_time", 0)
                    path.append(rule_id)
                    total_time += exec_time
                    
                    timing_data.append({
                        "rule_id": rule_id,
                        "execution_time": exec_time
                    })
            
            if path:
                path_key = " -&gt; ".join(path)
                path_counter[path_key] += 1
        
        # Identify common paths
        total_executions = sum(path_counter.values())
        for path, count in path_counter.most_common(10):
            frequency = count / total_executions
            patterns["common_paths"].append({
                "path": path,
                "frequency": frequency,
                "count": count
            })
        
        # Identify bottlenecks
        if timing_data:
            df = pd.DataFrame(timing_data)
            slow_rules = df.groupby('rule_id')['execution_time'].agg(['mean', 'max', 'count'])
            slow_rules = slow_rules[slow_rules['mean'] &gt; 0.05]  # Rules taking &gt; 50ms on average
            
            for rule_id, row in slow_rules.iterrows():
                patterns["bottlenecks"].append({
                    "rule_id": rule_id,
                    "avg_time": row['mean'],
                    "max_time": row['max'],
                    "executions": row['count']
                })
        
        # Use AI to identify optimization opportunities
        if patterns["common_paths"]:
            opportunities = self._identify_ai_opportunities(patterns)
            patterns["optimization_opportunities"] = opportunities
        
        return patterns
    
    def _identify_ai_opportunities(self, patterns: Dict) -&gt; List[Dict]:
        """Use AI to identify optimization opportunities from patterns"""
        
        prompt = f"""
        Analyze these execution patterns and identify optimization opportunities:
        
        Common Execution Paths:
        {json.dumps(patterns['common_paths'], indent=2)}
        
        Performance Bottlenecks:
        {json.dumps(patterns['bottlenecks'], indent=2)}
        
        Identify:
        1. Rules that always execute together (candidates for merging)
        2. Rules that rarely execute (candidates for removal)
        3. Performance optimization opportunities
        4. Caching opportunities
        
        Return as JSON list of opportunities.
        """
        
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[
                {{"role": "system", "content": "You are a performance optimization expert."}},
                {{"role": "user", "content": prompt}}
            ],
            temperature=0.2,
            max_tokens=1000
        )
        
        try:
            opportunities = json.loads(response.choices[0].message.content)
            return opportunities
        except:
            return []
```

### Step 4: Create Rule Converter

Create `converters/rule_converter.py`:
```python
from typing import List, Dict, Any
import yaml
import json
from datetime import datetime

class RuleConverter:
    """Convert between different rule formats"""
    
    def __init__(self):
        self.supported_formats = ['json', 'yaml', 'drools', 'python', 'sql']
    
    def convert_to_drools(self, rules: List[Dict]) -&gt; str:
        """Convert rules to Drools DRL format"""
        drl_content = f"""
package com.enterprise.rules

import java.util.Map;
import java.util.HashMap;

// Generated from COBOL extraction on {datetime.now().isoformat()}
"""
        
        for rule in rules:
            drl_content += self._rule_to_drools(rule)
        
        return drl_content
    
    def _rule_to_drools(self, rule: Dict) -&gt; str:
        """Convert single rule to Drools format"""
        rule_name = rule.get("name", rule.get("id")).replace("-", "_")
        
        drl = f"""
rule "{rule_name}"
    when
"""
        
        # Add conditions
        conditions = rule.get("conditions", [])
        for i, condition in enumerate(conditions):
            if i &gt; 0:
                drl += "        and\n"
            drl += f"        $context : Map({self._condition_to_drools(condition)})\n"
        
        drl += "    then\n"
        
        # Add actions
        actions = rule.get("actions", [])
        for action in actions:
            drl += f"        {self._action_to_drools(action)}\n"
        
        drl += "end\n"
        
        return drl
    
    def _condition_to_drools(self, condition: Dict) -&gt; str:
        """Convert condition to Drools syntax"""
        left = condition.get("left")
        operator = condition.get("operator")
        right = condition.get("right")
        
        # Map operators
        operator_map = {
            "=": "==",
            "!=": "!=",
            "&gt;": "&gt;",
            "&lt;": "&lt;",
            "&gt;=": "&gt;=",
            "&lt;=": "&lt;="
        }
        
        drools_op = operator_map.get(operator, "==")
        
        return f'get("{left}") {drools_op} "{right}"'
    
    def _action_to_drools(self, action: Dict) -&gt; str:
        """Convert action to Drools syntax"""
        action_type = action.get("type")
        
        if action_type == "assign":
            return f'$context.put("{action.get("target")}", "{action.get("value")}");'
        elif action_type == "calculate":
            return f'// Calculate: {action.get("formula")}'
        else:
            return f'// {action_type}: {action.get("target")}'
    
    def convert_to_python(self, rules: List[Dict]) -&gt; str:
        """Convert rules to Python code"""
        py_content = f'''"""
Business rules extracted from COBOL
Generated on: {datetime.now().isoformat()}
"""

from typing import Dict, Any, List
from dataclasses import dataclass
import re

@dataclass
class RuleContext:
    data: Dict[str, Any]
    
    def get(self, key: str) -&gt; Any:
        return self.data.get(key)
    
    def set(self, key: str, value: Any):
        self.data[key] = value

class BusinessRules:
    """Generated business rules from COBOL"""
    
    def __init__(self):
        self.execution_trace = []
    
'''
        
        # Generate methods for each rule
        for rule in rules:
            py_content += self._rule_to_python(rule)
        
        # Add main execution method
        py_content += '''
    def execute_all(self, context: RuleContext) -&gt; List[str]:
        """Execute all rules in sequence"""
        executed = []
        
'''
        
        for rule in rules:
            method_name = self._rule_name_to_method(rule.get("name", rule.get("id")))
            py_content += f'''        if self.{method_name}(context):
            executed.append("{rule.get('id')}")
        
'''
        
        py_content += '''        return executed
'''
        
        return py_content
    
    def _rule_to_python(self, rule: Dict) -&gt; str:
        """Convert single rule to Python method"""
        method_name = self._rule_name_to_method(rule.get("name", rule.get("id")))
        
        py_method = f'''
    def {method_name}(self, context: RuleContext) -&gt; bool:
        """
        {rule.get('description', 'Business rule')}
        Source: {rule.get('source', 'Unknown')}
        """
'''
        
        # Add conditions
        conditions = rule.get("conditions", [])
        if conditions:
            py_method += "        if "
            for i, condition in enumerate(conditions):
                if i &gt; 0:
                    py_method += " and "
                py_method += self._condition_to_python(condition)
            py_method += ":\n"
            
            # Add actions
            for action in rule.get("actions", []):
                py_method += f"            {self._action_to_python(action)}\n"
            
            py_method += "            return True\n"
            
            # Add else actions if any
            else_actions = rule.get("else_actions", [])
            if else_actions:
                py_method += "        else:\n"
                for action in else_actions:
                    py_method += f"            {self._action_to_python(action)}\n"
                py_method += "            return False\n"
            else:
                py_method += "        return False\n"
        else:
            # No conditions - always execute
            for action in rule.get("actions", []):
                py_method += f"        {self._action_to_python(action)}\n"
            py_method += "        return True\n"
        
        return py_method
    
    def _condition_to_python(self, condition: Dict) -&gt; str:
        """Convert condition to Python syntax"""
        if condition.get("complex"):
            # Handle complex conditions
            operator = condition.get("operator")
            sub_conditions = condition.get("sub_conditions", [])
            
            if operator == "AND":
                return "(" + " and ".join(self._condition_to_python(c) for c in sub_conditions) + ")"
            elif operator == "OR":
                return "(" + " or ".join(self._condition_to_python(c) for c in sub_conditions) + ")"
        else:
            # Simple condition
            left = condition.get("left")
            operator = condition.get("operator")
            right = condition.get("right")
            
            # Handle special functions
            if left.startswith("IS_NUMERIC("):
                var_name = left[11:-1]
                return f'str(context.get("{var_name}")).replace(".", "").replace("-", "").isdigit()'
            
            # Map operators
            operator_map = {
                "=": "==",
                "!=": "!=",
                "&gt;": "&gt;",
                "&lt;": "&lt;",
                "&gt;=": "&gt;=",
                "&lt;=": "&lt;="
            }
            
            py_op = operator_map.get(operator, "==")
            
            # Quote string values
            if isinstance(right, str) and not right.isdigit():
                right = f'"{right}"'
            
            return f'context.get("{left}") {py_op} {right}'
    
    def _action_to_python(self, action: Dict) -&gt; str:
        """Convert action to Python code"""
        action_type = action.get("type")
        
        if action_type == "assign":
            value = action.get("value")
            if isinstance(value, str) and not value.isdigit():
                value = f'"{value}"'
            return f'context.set("{action.get("target")}", {value})'
        
        elif action_type == "calculate":
            formula = action.get("formula")
            # Simple formula conversion
            formula = formula.replace(" ", "")
            for var in re.findall(r'[A-Za-z][\w-]*', formula):
                if var not in ['math', 'int', 'float', 'str']:
                    formula = formula.replace(var, f'context.get("{var}")')
            return f'context.set("{action.get("target")}", {formula})'
        
        elif action_type == "display":
            return f'print({action.get("value")})'
        
        elif action_type == "perform":
            return f'# Call procedure: {action.get("target")}'
        
        else:
            return f'# {action_type}: {action}'
    
    def _rule_name_to_method(self, name: str) -&gt; str:
        """Convert rule name to valid Python method name"""
        # Replace invalid characters
        method_name = name.lower()
        method_name = re.sub(r'[^a-z0-9_]', '_', method_name)
        method_name = re.sub(r'_+', '_', method_name)
        method_name = method_name.strip('_')
        
        # Ensure it starts with letter
        if method_name and method_name[0].isdigit():
            method_name = f'rule_{method_name}'
        
        return method_name or 'unnamed_rule'
    
    def export_to_yaml(self, rules: List[Dict], filepath: str):
        """Export rules to YAML format"""
        export_data = {
            "metadata": {
                "version": "1.0",
                "generated": datetime.now().isoformat(),
                "source": "COBOL extraction",
                "rule_count": len(rules)
            },
            "rules": rules
        }
        
        with open(filepath, 'w') as f:
            yaml.dump(export_data, f, default_flow_style=False, sort_keys=False)
    
    def export_to_json(self, rules: List[Dict], filepath: str):
        """Export rules to JSON format"""
        export_data = {
            "metadata": {
                "version": "1.0",
                "generated": datetime.now().isoformat(),
                "source": "COBOL extraction",
                "rule_count": len(rules)
            },
            "rules": rules
        }
        
        with open(filepath, 'w') as f:
            json.dump(export_data, f, indent=2)
```

### Step 5: Create Main Application

Create `main_rule_extractor.py`:
```python
#!/usr/bin/env python3
"""
Business Rule Extractor - Extract and modernize COBOL business logic
"""

import argparse
import sys
import os
from pathlib import Path
import json
from datetime import datetime

from extractors.business_logic_extractor import BusinessLogicExtractor
from rules_engine.rule_engine import RuleEngine, RuleExecutionContext
from rules_engine.ai_rule_optimizer import AIRuleOptimizer
from converters.rule_converter import RuleConverter
from visualizers.rule_visualizer import RuleVisualizer

def extract_rules_from_cobol(filepath: str) -&gt; List[Dict]:
    """Extract business rules from COBOL file"""
    print(f"\n📄 Extracting rules from: {filepath}")
    
    # Read COBOL source
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        cobol_code = f.read()
    
    # Extract rules
    extractor = BusinessLogicExtractor()
    rules = extractor.extract_rules(cobol_code, Path(filepath).stem)
    
    print(f"✅ Extracted {len(rules)} business rules")
    
    # Convert to dict format
    return [rule.to_dict() for rule in rules]

def test_rules(rules: List[Dict], test_data: Dict = None):
    """Test extracted rules with sample data"""
    print("\n🧪 Testing extracted rules...")
    
    # Create rule engine
    engine = RuleEngine()
    
    # Register rules
    for rule in rules:
        engine.register_rule(rule['id'], rule)
    
    # Default test data if none provided
    if test_data is None:
        test_data = {
            "CUST-BALANCE": 15000,
            "CUST-STATUS": "A",
            "CUST-ID": "123456",
            "ORDER-AMOUNT": 500,
            "PAYMENT-TYPE": "CREDIT"
        }
    
    # Create execution context
    context = RuleExecutionContext(test_data)
    
    # Execute rules
    results = []
    for rule in rules:
        result = engine.execute_rule(rule['id'], context)
        results.append(result)
        
        if result.get('executed'):
            print(f"  ✓ {rule['name']}: {'Matched' if result.get('conditions_met') else 'Not matched'}")
    
    print(f"\n📊 Test Results:")
    print(f"  - Total rules: {len(rules)}")
    print(f"  - Executed: {sum(1 for r in results if r.get('executed'))}")
    print(f"  - Conditions met: {sum(1 for r in results if r.get('conditions_met'))}")
    print(f"  - Final context: {json.dumps(context.data, indent=2)}")
    
    return results

def optimize_rules(rules: List[Dict], api_key: str = None) -&gt; List[Dict]:
    """Optimize rules using AI"""
    print("\n🤖 Optimizing rules with AI...")
    
    if not api_key:
        api_key = os.getenv("OPENAI_API_KEY")
        
    if not api_key:
        print("⚠️ No OpenAI API key provided. Skipping optimization.")
        return rules
    
    optimizer = AIRuleOptimizer(api_key)
    
    # Simulate some execution stats for optimization
    fake_stats = {}
    for rule in rules:
        fake_stats[rule['id']] = {
            "total_executions": 1000,
            "conditions_met_count": 250,
            "avg_execution_time": 0.01
        }
    
    optimized = optimizer.optimize_rules(rules, fake_stats)
    
    print(f"✅ Optimization complete. Rules: {len(rules)} → {len(optimized)}")
    
    return optimized

def convert_rules(rules: List[Dict], output_format: str, output_dir: str):
    """Convert rules to different formats"""
    print(f"\n📝 Converting rules to {output_format}...")
    
    converter = RuleConverter()
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    if output_format == "python":
        py_code = converter.convert_to_python(rules)
        filepath = output_path / f"business_rules_{timestamp}.py"
        filepath.write_text(py_code)
        print(f"✅ Python code saved to: {filepath}")
        
    elif output_format == "drools":
        drl_code = converter.convert_to_drools(rules)
        filepath = output_path / f"business_rules_{timestamp}.drl"
        filepath.write_text(drl_code)
        print(f"✅ Drools rules saved to: {filepath}")
        
    elif output_format == "yaml":
        filepath = output_path / f"business_rules_{timestamp}.yaml"
        converter.export_to_yaml(rules, str(filepath))
        print(f"✅ YAML rules saved to: {filepath}")
        
    elif output_format == "json":
        filepath = output_path / f"business_rules_{timestamp}.json"
        converter.export_to_json(rules, str(filepath))
        print(f"✅ JSON rules saved to: {filepath}")

def visualize_rules(rules: List[Dict], output_dir: str):
    """Visualize rules as decision trees"""
    print("\n📊 Visualizing rules...")
    
    visualizer = RuleVisualizer()
    output_path = Path(output_dir)
    
    # Generate decision tree
    tree_path = output_path / "decision_tree.png"
    visualizer.create_decision_tree(rules, str(tree_path))
    print(f"✅ Decision tree saved to: {tree_path}")
    
    # Generate rule flow diagram
    flow_path = output_path / "rule_flow.png"
    visualizer.create_rule_flow(rules, str(flow_path))
    print(f"✅ Rule flow saved to: {flow_path}")
    
    # Generate complexity chart
    complexity_path = output_path / "complexity_chart.png"
    visualizer.create_complexity_chart(rules, str(complexity_path))
    print(f"✅ Complexity chart saved to: {complexity_path}")

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Extract and modernize business rules from COBOL",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Extract rules from COBOL
  python main_rule_extractor.py extract PAYROLL.cbl
  
  # Extract and test rules
  python main_rule_extractor.py extract PAYROLL.cbl --test
  
  # Extract, optimize, and convert
  python main_rule_extractor.py extract PAYROLL.cbl --optimize --convert python
  
  # Full pipeline
  python main_rule_extractor.py extract PAYROLL.cbl --test --optimize --convert python --visualize
        """
    )
    
    parser.add_argument('command', choices=['extract'], help='Command to run')
    parser.add_argument('file', help='COBOL file to process')
    parser.add_argument('--test', action='store_true', help='Test extracted rules')
    parser.add_argument('--optimize', action='store_true', help='Optimize rules with AI')
    parser.add_argument('--convert', choices=['python', 'drools', 'yaml', 'json'], 
                       help='Convert to format')
    parser.add_argument('--visualize', action='store_true', help='Generate visualizations')
    parser.add_argument('--output-dir', default='output', help='Output directory')
    
    args = parser.parse_args()
    
    if args.command == 'extract':
        # Extract rules
        rules = extract_rules_from_cobol(args.file)
        
        # Save extracted rules
        output_path = Path(args.output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        
        rules_file = output_path / f"extracted_rules_{Path(args.file).stem}.json"
        with open(rules_file, 'w') as f:
            json.dump(rules, f, indent=2)
        print(f"\n💾 Extracted rules saved to: {rules_file}")
        
        # Test if requested
        if args.test:
            test_results = test_rules(rules)
        
        # Optimize if requested
        if args.optimize:
            rules = optimize_rules(rules)
        
        # Convert if requested
        if args.convert:
            convert_rules(rules, args.convert, args.output_dir)
        
        # Visualize if requested
        if args.visualize:
            visualize_rules(rules, args.output_dir)
        
        print("\n✅ Rule extraction complete!")

if __name__ == "__main__":
    main()
```

## 🏃 Running the Exercício

1. **Create a sample COBOL program with business rules:**
```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ORDER-PROCESSING.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 ORDER-RECORD.
          05 ORDER-ID          PIC 9(8).
          05 CUSTOMER-ID       PIC 9(6).
          05 ORDER-AMOUNT      PIC 9(7)V99.
          05 ORDER-TYPE        PIC X.
             88 RETAIL-ORDER   VALUE 'R'.
             88 WHOLESALE-ORDER VALUE 'W'.
          05 PAYMENT-TYPE      PIC X(10).
          05 DISCOUNT-RATE     PIC V99.
          05 FINAL-AMOUNT      PIC 9(7)V99.
       
       01 CUSTOMER-RECORD.
          05 CUST-ID           PIC 9(6).
          05 CUST-TYPE         PIC X.
             88 PREMIUM-CUST   VALUE 'P'.
             88 REGULAR-CUST   VALUE 'R'.
          05 CREDIT-LIMIT      PIC 9(7)V99.
          05 CURRENT-BALANCE   PIC 9(7)V99.
       
       PROCEDURE DIVISION.
       MAIN-PROCESS.
           PERFORM VALIDATE-ORDER
           PERFORM CALCULATE-DISCOUNT
           PERFORM CHECK-CREDIT
           PERFORM FINALIZE-ORDER
           STOP RUN.
       
       VALIDATE-ORDER.
           IF ORDER-AMOUNT = ZERO
              DISPLAY "ERROR: Order amount cannot be zero"
              MOVE 'N' TO ORDER-STATUS
           END-IF
           
           IF ORDER-TYPE NOT = 'R' AND ORDER-TYPE NOT = 'W'
              DISPLAY "ERROR: Invalid order type"
              MOVE 'N' TO ORDER-STATUS
           END-IF.
       
       CALCULATE-DISCOUNT.
           EVALUATE TRUE
               WHEN PREMIUM-CUST AND ORDER-AMOUNT &gt; 10000
                   MOVE 0.15 TO DISCOUNT-RATE
               WHEN PREMIUM-CUST
                   MOVE 0.10 TO DISCOUNT-RATE
               WHEN REGULAR-CUST AND ORDER-AMOUNT &gt; 5000
                   MOVE 0.05 TO DISCOUNT-RATE
               WHEN OTHER
                   MOVE 0.00 TO DISCOUNT-RATE
           END-EVALUATE
           
           COMPUTE FINAL-AMOUNT = ORDER-AMOUNT * (1 - DISCOUNT-RATE).
       
       CHECK-CREDIT.
           IF PAYMENT-TYPE = "CREDIT"
              COMPUTE NEW-BALANCE = CURRENT-BALANCE + FINAL-AMOUNT
              IF NEW-BALANCE &gt; CREDIT-LIMIT
                 DISPLAY "ERROR: Credit limit exceeded"
                 MOVE 'N' TO ORDER-STATUS
              ELSE
                 MOVE NEW-BALANCE TO CURRENT-BALANCE
              END-IF
           END-IF.
       
       FINALIZE-ORDER.
           IF ORDER-STATUS = 'Y'
              DISPLAY "Order approved. Final amount: " FINAL-AMOUNT
           ELSE
              DISPLAY "Order rejected"
           END-IF.
```

2. **Extract business rules:**
```bash
python main_rule_extractor.py extract ORDER-PROCESSING.cbl --test
```

3. **Optimize and convert rules:**
```bash
# With AI optimization
export OPENAI_API_KEY="your-key"
python main_rule_extractor.py extract ORDER-PROCESSING.cbl --optimize --convert python

# Convert to multiple formats
python main_rule_extractor.py extract ORDER-PROCESSING.cbl --convert yaml --convert drools
```

4. **Generate visualizations:**
```bash
python main_rule_extractor.py extract ORDER-PROCESSING.cbl --visualize
```

5. **Test the generated Python rules:**
```python
# Import generated rules
from output.business_rules_20240115_120000 import BusinessRules, RuleContext

# Create test context
context = RuleContext({
    "ORDER-AMOUNT": 15000,
    "ORDER-TYPE": "R",
    "CUSTOMER-TYPE": "P",
    "PAYMENT-TYPE": "CREDIT",
    "CREDIT-LIMIT": 50000,
    "CURRENT-BALANCE": 10000
})

# Execute rules
rules = BusinessRules()
executed = rules.execute_all(context)

print(f"Executed rules: {executed}")
print(f"Final discount: {context.get('DISCOUNT-RATE')}")
print(f"Final amount: {context.get('FINAL-AMOUNT')}")
```

## 🎯 Validation

Your rule extraction system should now:
- ✅ Extract IF-THEN-ELSE logic from COBOL
- ✅ Identify EVALUATE statements as rules
- ✅ Extract calculations and formulas
- ✅ Detect validation rules
- ✅ Convert to modern rule engine format
- ✅ Generate executable Python code
- ✅ Optimize rules using AI
- ✅ Visualize decision flows

## 🚀 Bonus Challenges

1. **Avançado Pattern Recognition:**
   - Extract nested condition logic
   - Handle COBOL 88-level conditions
   - Identify rule dependencies

2. **Machine Learning Enhancement:**
   - Train ML model on historical executions
   - Predict rule outcomes
   - Suggest rule improvements

3. **Real-time Rule Management:**
   - Build web UI for rule editing
   - Versão control for rules
   - A/B testing framework

4. **Integration Features:**
   - Export to IBM ODM
   - Camunda DMN format
   - Microsoft Rules Engine

## 📚 Additional Recursos

- [Business Rules Engines Visão Geral](https://martinfowler.com/bliki/RulesEngine.html)
- [Drools Documentação](https://www.drools.org/learn/documentation.html)
- [DMN Specification](https://www.omg.org/dmn/)
- [COBOL Business Logic Patterns](https://www.ibm.com/docs/en/cobol-compiler)

## ⏭️ Próximo Exercício

Ready for the complete migration? Move on to [Exercício 3: Hybrid Banking System](/docs/modules/module-27/exercise3-overview) where you'll create a produção system with COBOL and modern AI working together!