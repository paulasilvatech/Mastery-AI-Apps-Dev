# Exercise 3: Architecture Decision Agent (⭐⭐⭐ Hard - 60 minutes)

## 🎯 Objective
Build an advanced AI agent that analyzes codebases, identifies architectural issues, suggests improvements, and generates Architecture Decision Records (ADRs) with implementation plans.

## 🧠 What You'll Learn
- Advanced code analysis techniques
- Architectural pattern recognition
- Decision-making algorithms
- ADR generation and management
- Implementation roadmap creation
- Trade-off analysis

## 📋 Prerequisites
- Completed Exercises 1 & 2
- Strong understanding of software architecture patterns
- Knowledge of architectural anti-patterns
- Familiarity with ADR format
- Experience with dependency analysis

## 📚 Background

An architecture decision agent must:
- Analyze code structure and dependencies
- Identify architectural patterns and anti-patterns
- Suggest improvements based on best practices
- Generate detailed ADRs with rationale
- Create implementation roadmaps
- Track architecture evolution

## 🛠️ Instructions

### Step 1: Design the Architecture Decision Agent

**Copilot Prompt Suggestion:**
```python
# Create an architecture decision agent that:
# - Analyzes code architecture using multiple strategies
# - Identifies patterns, anti-patterns, and code smells
# - Suggests architectural improvements
# - Generates ADRs with full context and rationale
# - Creates implementation plans with effort estimates
# - Tracks architecture decisions over time
# - Provides trade-off analysis for each decision
# Use multiple analysis strategies and decision frameworks
```

Create `src/agents/architecture_agent.py`:
```python
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import List, Dict, Any, Optional, Set, Tuple
from enum import Enum
from datetime import datetime
import ast
import os
from pathlib import Path
import networkx as nx
import json
from collections import defaultdict

class ArchitecturePattern(Enum):
    """Common architecture patterns"""
    LAYERED = "layered"
    MVC = "mvc"
    MVP = "mvp"
    MVVM = "mvvm"
    HEXAGONAL = "hexagonal"
    MICROSERVICES = "microservices"
    MONOLITHIC = "monolithic"
    EVENT_DRIVEN = "event_driven"
    PIPELINE = "pipeline"
    PLUGIN = "plugin"

class AntiPattern(Enum):
    """Common anti-patterns"""
    GOD_CLASS = "god_class"
    SPAGHETTI_CODE = "spaghetti_code"
    CIRCULAR_DEPENDENCY = "circular_dependency"
    ANEMIC_DOMAIN = "anemic_domain"
    FEATURE_ENVY = "feature_envy"
    INAPPROPRIATE_INTIMACY = "inappropriate_intimacy"
    BLOB = "blob"
    LAVA_FLOW = "lava_flow"

class DecisionStatus(Enum):
    """ADR status"""
    PROPOSED = "proposed"
    ACCEPTED = "accepted"
    DEPRECATED = "deprecated"
    SUPERSEDED = "superseded"

@dataclass
class CodeMetrics:
    """Metrics for code analysis"""
    loc: int = 0
    complexity: int = 0
    coupling: int = 0
    cohesion: float = 0.0
    dependencies: int = 0
    test_coverage: float = 0.0
    
@dataclass
class ArchitecturalIssue:
    """Represents an architectural issue"""
    issue_type: str
    severity: str  # low, medium, high, critical
    location: str
    description: str
    impact: str
    metrics: Dict[str, Any]
    suggested_pattern: Optional[ArchitecturePattern] = None
    
@dataclass
class ArchitectureDecision:
    """Architecture Decision Record (ADR)"""
    id: str
    title: str
    status: DecisionStatus
    context: str
    decision: str
    consequences: Dict[str, List[str]]  # positive, negative, neutral
    alternatives: List[Dict[str, Any]]
    created_date: datetime
    updated_date: datetime
    author: str
    related_issues: List[ArchitecturalIssue]
    implementation_plan: Optional['ImplementationPlan'] = None
    
@dataclass
class ImplementationPlan:
    """Plan for implementing architectural changes"""
    phases: List['ImplementationPhase']
    total_effort_hours: int
    risk_assessment: Dict[str, Any]
    dependencies: List[str]
    rollback_strategy: str
    
@dataclass
class ImplementationPhase:
    """Single phase of implementation"""
    name: str
    description: str
    tasks: List[str]
    effort_hours: int
    prerequisites: List[str]
    deliverables: List[str]

class ArchitectureDecisionAgent:
    """Agent for analyzing architecture and making decisions"""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.dependency_graph = nx.DiGraph()
        self.module_metrics: Dict[str, CodeMetrics] = {}
        self.issues: List[ArchitecturalIssue] = []
        self.decisions: List[ArchitectureDecision] = []
        self.analyzers = self._init_analyzers()
        self.pattern_detectors = self._init_pattern_detectors()
        
    def _init_analyzers(self) -> List['ArchitectureAnalyzer']:
        """Initialize architecture analyzers"""
        return [
            DependencyAnalyzer(),
            ComplexityAnalyzer(),
            PatternAnalyzer(),
            CouplingAnalyzer(),
            TestCoverageAnalyzer()
        ]
    
    def _init_pattern_detectors(self) -> Dict[ArchitecturePattern, 'PatternDetector']:
        """Initialize pattern detectors"""
        return {
            ArchitecturePattern.LAYERED: LayeredPatternDetector(),
            ArchitecturePattern.MVC: MVCPatternDetector(),
            ArchitecturePattern.HEXAGONAL: HexagonalPatternDetector(),
            ArchitecturePattern.MICROSERVICES: MicroservicesDetector()
        }
    
    def analyze_architecture(self) -> Dict[str, Any]:
        """Perform comprehensive architecture analysis"""
        print("🔍 Analyzing project architecture...")
        
        # Build dependency graph
        self._build_dependency_graph()
        
        # Run analyzers
        for analyzer in self.analyzers:
            analyzer_issues = analyzer.analyze(self.project_root, self.dependency_graph)
            self.issues.extend(analyzer_issues)
        
        # Detect patterns
        detected_patterns = self._detect_patterns()
        
        # Calculate overall metrics
        overall_metrics = self._calculate_overall_metrics()
        
        # Identify improvement opportunities
        improvements = self._identify_improvements()
        
        return {
            'detected_patterns': detected_patterns,
            'issues': self.issues,
            'metrics': overall_metrics,
            'improvements': improvements,
            'dependency_graph_stats': {
                'nodes': self.dependency_graph.number_of_nodes(),
                'edges': self.dependency_graph.number_of_edges(),
                'cycles': list(nx.simple_cycles(self.dependency_graph))
            }
        }
    
    def _build_dependency_graph(self):
        """Build module dependency graph"""
        for py_file in self.project_root.rglob("*.py"):
            if '__pycache__' in str(py_file):
                continue
                
            module_name = self._path_to_module(py_file)
            self.dependency_graph.add_node(module_name)
            
            # Analyze imports
            try:
                with open(py_file, 'r', encoding='utf-8') as f:
                    tree = ast.parse(f.read())
                    
                for node in ast.walk(tree):
                    if isinstance(node, ast.Import):
                        for alias in node.names:
                            dep_module = alias.name
                            if self._is_internal_module(dep_module):
                                self.dependency_graph.add_edge(module_name, dep_module)
                                
                    elif isinstance(node, ast.ImportFrom):
                        if node.module and self._is_internal_module(node.module):
                            self.dependency_graph.add_edge(module_name, node.module)
                            
            except Exception as e:
                print(f"Error analyzing {py_file}: {e}")
    
    def _detect_patterns(self) -> List[Tuple[ArchitecturePattern, float]]:
        """Detect architectural patterns with confidence scores"""
        detected = []
        
        for pattern, detector in self.pattern_detectors.items():
            confidence = detector.detect(self.project_root, self.dependency_graph)
            if confidence > 0.5:
                detected.append((pattern, confidence))
                
        return sorted(detected, key=lambda x: x[1], reverse=True)
    
    def _identify_improvements(self) -> List[Dict[str, Any]]:
        """Identify architectural improvements"""
        improvements = []
        
        # Check for circular dependencies
        cycles = list(nx.simple_cycles(self.dependency_graph))
        if cycles:
            improvements.append({
                'issue': 'Circular Dependencies',
                'severity': 'high',
                'description': f"Found {len(cycles)} circular dependencies",
                'suggestion': 'Apply Dependency Inversion Principle',
                'pattern': ArchitecturePattern.HEXAGONAL
            })
        
        # Check for god classes
        for module, metrics in self.module_metrics.items():
            if metrics.loc > 500 and metrics.complexity > 50:
                improvements.append({
                    'issue': 'God Class',
                    'severity': 'high',
                    'module': module,
                    'description': f"Module {module} is too large and complex",
                    'suggestion': 'Split into smaller, focused modules'
                })
        
        # Check coupling
        high_coupling_modules = [
            module for module, metrics in self.module_metrics.items()
            if metrics.coupling > 10
        ]
        if high_coupling_modules:
            improvements.append({
                'issue': 'High Coupling',
                'severity': 'medium',
                'modules': high_coupling_modules,
                'description': 'These modules have too many dependencies',
                'suggestion': 'Introduce interfaces or apply facade pattern'
            })
        
        return improvements
    
    def generate_adr(self, issue: ArchitecturalIssue, 
                    solution_pattern: ArchitecturePattern) -> ArchitectureDecision:
        """Generate Architecture Decision Record"""
        
        # Analyze trade-offs
        trade_offs = self._analyze_trade_offs(issue, solution_pattern)
        
        # Generate alternatives
        alternatives = self._generate_alternatives(issue, solution_pattern)
        
        # Create implementation plan
        implementation_plan = self._create_implementation_plan(issue, solution_pattern)
        
        adr = ArchitectureDecision(
            id=f"ADR-{len(self.decisions) + 1:04d}",
            title=f"Refactor {issue.location} to {solution_pattern.value} pattern",
            status=DecisionStatus.PROPOSED,
            context=self._generate_context(issue),
            decision=self._generate_decision(issue, solution_pattern),
            consequences=trade_offs,
            alternatives=alternatives,
            created_date=datetime.now(),
            updated_date=datetime.now(),
            author="Architecture Decision Agent",
            related_issues=[issue],
            implementation_plan=implementation_plan
        )
        
        self.decisions.append(adr)
        return adr
    
    def _analyze_trade_offs(self, issue: ArchitecturalIssue, 
                          pattern: ArchitecturePattern) -> Dict[str, List[str]]:
        """Analyze trade-offs of applying a pattern"""
        trade_offs = {
            'positive': [],
            'negative': [],
            'neutral': []
        }
        
        # Pattern-specific trade-offs
        if pattern == ArchitecturePattern.HEXAGONAL:
            trade_offs['positive'].extend([
                "Clear separation of business logic from infrastructure",
                "Improved testability through ports and adapters",
                "Easier to swap infrastructure components",
                "Better adherence to SOLID principles"
            ])
            trade_offs['negative'].extend([
                "Increased initial complexity",
                "More boilerplate code required",
                "Learning curve for team members",
                "Potential over-engineering for simple domains"
            ])
            trade_offs['neutral'].extend([
                "Requires clear domain boundaries",
                "Changes project structure significantly"
            ])
            
        elif pattern == ArchitecturePattern.MICROSERVICES:
            trade_offs['positive'].extend([
                "Independent deployment and scaling",
                "Technology diversity possible",
                "Fault isolation between services",
                "Team autonomy"
            ])
            trade_offs['negative'].extend([
                "Increased operational complexity",
                "Network latency between services",
                "Data consistency challenges",
                "Requires sophisticated monitoring"
            ])
            
        return trade_offs
    
    def _generate_alternatives(self, issue: ArchitecturalIssue, 
                             chosen_pattern: ArchitecturePattern) -> List[Dict[str, Any]]:
        """Generate alternative solutions"""
        alternatives = []
        
        # Always include "do nothing" option
        alternatives.append({
            'name': 'Maintain Status Quo',
            'description': 'Keep current architecture',
            'pros': ['No implementation effort', 'No risk of breaking changes'],
            'cons': ['Technical debt continues to grow', 'Issue remains unresolved'],
            'effort': 0
        })
        
        # Add pattern-specific alternatives
        if issue.issue_type == AntiPattern.GOD_CLASS.value:
            alternatives.extend([
                {
                    'name': 'Extract Services',
                    'description': 'Break into multiple service classes',
                    'pros': ['Simpler than full pattern', 'Incremental approach'],
                    'cons': ['May not address root cause', 'Risk of creating anemic services'],
                    'effort': 40
                },
                {
                    'name': 'Apply Facade Pattern',
                    'description': 'Keep internals but provide clean interface',
                    'pros': ['Minimal changes to existing code', 'Quick to implement'],
                    'cons': ['Doesn't reduce complexity', 'Just hides the problem'],
                    'effort': 20
                }
            ])
            
        return alternatives
    
    def _create_implementation_plan(self, issue: ArchitecturalIssue,
                                  pattern: ArchitecturePattern) -> ImplementationPlan:
        """Create detailed implementation plan"""
        phases = []
        
        # Phase 1: Preparation
        phases.append(ImplementationPhase(
            name="Preparation and Analysis",
            description="Analyze current state and prepare for refactoring",
            tasks=[
                "Create comprehensive test suite for affected modules",
                "Document current behavior and interfaces",
                "Set up feature flags for gradual rollout",
                "Create architecture diagrams"
            ],
            effort_hours=40,
            prerequisites=[],
            deliverables=["Test suite", "Documentation", "Architecture diagrams"]
        ))
        
        # Phase 2: Restructuring
        if pattern == ArchitecturePattern.HEXAGONAL:
            phases.append(ImplementationPhase(
                name="Domain Model Extraction",
                description="Extract pure domain model from infrastructure",
                tasks=[
                    "Identify domain entities and value objects",
                    "Extract business rules into domain layer",
                    "Create domain services",
                    "Remove infrastructure dependencies from domain"
                ],
                effort_hours=80,
                prerequisites=["Preparation and Analysis"],
                deliverables=["Pure domain model", "Domain services"]
            ))
            
            phases.append(ImplementationPhase(
                name="Port Definition",
                description="Define ports (interfaces) for the domain",
                tasks=[
                    "Define input ports (use cases)",
                    "Define output ports (driven adapters)",
                    "Create port interfaces",
                    "Update domain to use ports"
                ],
                effort_hours=60,
                prerequisites=["Domain Model Extraction"],
                deliverables=["Port interfaces", "Use case definitions"]
            ))
            
            phases.append(ImplementationPhase(
                name="Adapter Implementation",
                description="Implement adapters for all ports",
                tasks=[
                    "Create REST API adapters",
                    "Implement database adapters",
                    "Create external service adapters",
                    "Implement message queue adapters"
                ],
                effort_hours=100,
                prerequisites=["Port Definition"],
                deliverables=["Working adapters", "Integration tests"]
            ))
        
        # Calculate total effort
        total_effort = sum(phase.effort_hours for phase in phases)
        
        # Risk assessment
        risk_assessment = {
            'technical_risk': 'medium',
            'business_risk': 'low',
            'timeline_risk': 'medium',
            'mitigation_strategies': [
                "Implement behind feature flags",
                "Maintain backward compatibility",
                "Gradual rollout with monitoring",
                "Automated rollback capability"
            ]
        }
        
        # Rollback strategy
        rollback_strategy = """
        1. Feature flags allow instant rollback
        2. Keep old implementation available for 2 sprints
        3. Database changes are backward compatible
        4. API versioning maintains compatibility
        5. Automated tests verify both implementations
        """
        
        return ImplementationPlan(
            phases=phases,
            total_effort_hours=total_effort,
            risk_assessment=risk_assessment,
            dependencies=["No ongoing major features", "Team availability"],
            rollback_strategy=rollback_strategy
        )
    
    def _calculate_overall_metrics(self) -> Dict[str, Any]:
        """Calculate overall architecture metrics"""
        total_loc = sum(m.loc for m in self.module_metrics.values())
        avg_complexity = sum(m.complexity for m in self.module_metrics.values()) / len(self.module_metrics) if self.module_metrics else 0
        
        # Calculate modularity score
        modularity_score = self._calculate_modularity_score()
        
        # Calculate maintainability index
        maintainability_index = self._calculate_maintainability_index()
        
        return {
            'total_lines_of_code': total_loc,
            'average_complexity': avg_complexity,
            'number_of_modules': len(self.module_metrics),
            'modularity_score': modularity_score,
            'maintainability_index': maintainability_index,
            'coupling_score': self._calculate_coupling_score(),
            'cohesion_score': self._calculate_cohesion_score()
        }
    
    def _calculate_modularity_score(self) -> float:
        """Calculate modularity score (0-1)"""
        if not self.dependency_graph.nodes():
            return 0.0
            
        # Use community detection
        try:
            import community
            partition = community.best_partition(self.dependency_graph.to_undirected())
            modularity = community.modularity(partition, self.dependency_graph.to_undirected())
            return max(0.0, min(1.0, modularity))
        except:
            # Fallback to simple metric
            nodes = self.dependency_graph.number_of_nodes()
            edges = self.dependency_graph.number_of_edges()
            if nodes == 0:
                return 0.0
            return 1.0 - (edges / (nodes * (nodes - 1)))
    
    def _calculate_maintainability_index(self) -> float:
        """Calculate maintainability index"""
        # Simplified version of Maintainability Index
        # MI = 171 - 5.2 * ln(V) - 0.23 * CC - 16.2 * ln(LOC)
        # where V = Halstead Volume, CC = Cyclomatic Complexity, LOC = Lines of Code
        
        total_loc = sum(m.loc for m in self.module_metrics.values())
        avg_complexity = sum(m.complexity for m in self.module_metrics.values()) / len(self.module_metrics) if self.module_metrics else 1
        
        if total_loc == 0:
            return 100.0
            
        import math
        mi = 171 - 0.23 * avg_complexity - 16.2 * math.log(total_loc)
        
        # Normalize to 0-100
        return max(0.0, min(100.0, mi))
    
    def save_decisions(self, output_dir: Path):
        """Save ADRs to files"""
        adr_dir = output_dir / "architecture-decisions"
        adr_dir.mkdir(parents=True, exist_ok=True)
        
        for decision in self.decisions:
            filename = f"{decision.id}-{decision.title.lower().replace(' ', '-')}.md"
            filepath = adr_dir / filename
            
            with open(filepath, 'w') as f:
                f.write(self._format_adr_markdown(decision))
    
    def _format_adr_markdown(self, decision: ArchitectureDecision) -> str:
        """Format ADR as markdown"""
        md = f"""# {decision.id}: {decision.title}

**Date**: {decision.created_date.strftime('%Y-%m-%d')}
**Status**: {decision.status.value}
**Author**: {decision.author}

## Context

{decision.context}

## Decision

{decision.decision}

## Consequences

### Positive
{chr(10).join(f"- {c}" for c in decision.consequences['positive'])}

### Negative
{chr(10).join(f"- {c}" for c in decision.consequences['negative'])}

### Neutral
{chr(10).join(f"- {c}" for c in decision.consequences['neutral'])}

## Alternatives Considered

"""
        for alt in decision.alternatives:
            md += f"""### {alt['name']}
{alt['description']}

**Pros**: {', '.join(alt['pros'])}
**Cons**: {', '.join(alt['cons'])}
**Effort**: {alt['effort']} hours

"""
        
        if decision.implementation_plan:
            md += f"""## Implementation Plan

**Total Effort**: {decision.implementation_plan.total_effort_hours} hours
**Risk Level**: {decision.implementation_plan.risk_assessment['technical_risk']}

### Phases
"""
            for i, phase in enumerate(decision.implementation_plan.phases, 1):
                md += f"""
#### Phase {i}: {phase.name}
{phase.description}

**Tasks**:
{chr(10).join(f"- {task}" for task in phase.tasks)}

**Effort**: {phase.effort_hours} hours
**Deliverables**: {', '.join(phase.deliverables)}
"""
        
        return md
    
    def _path_to_module(self, path: Path) -> str:
        """Convert file path to module name"""
        relative = path.relative_to(self.project_root)
        parts = relative.with_suffix('').parts
        return '.'.join(parts)
    
    def _is_internal_module(self, module: str) -> bool:
        """Check if module is internal to project"""
        # Simple check - can be improved
        return not module.startswith(('os', 'sys', 'json', 'datetime', 
                                    'typing', 'collections', 'itertools'))
    
    def _generate_context(self, issue: ArchitecturalIssue) -> str:
        """Generate context section for ADR"""
        return f"""
The module {issue.location} has been identified as having {issue.issue_type} issues.

**Current State**:
- Severity: {issue.severity}
- Impact: {issue.impact}
- Metrics: {json.dumps(issue.metrics, indent=2)}

{issue.description}

This is causing maintainability issues and making it difficult to:
- Add new features
- Fix bugs efficiently
- Onboard new team members
- Ensure consistent behavior
"""
    
    def _generate_decision(self, issue: ArchitecturalIssue, 
                         pattern: ArchitecturePattern) -> str:
        """Generate decision section for ADR"""
        return f"""
We will refactor {issue.location} to follow the {pattern.value} pattern.

This involves:
1. Restructuring the code to follow {pattern.value} principles
2. Extracting clear boundaries and interfaces
3. Implementing proper separation of concerns
4. Adding comprehensive tests to ensure behavior is preserved

The {pattern.value} pattern was chosen because:
- It directly addresses the {issue.issue_type} problem
- It aligns with our overall architecture goals
- It provides a proven solution to this type of issue
- The team has experience with this pattern
"""
    
    def _calculate_coupling_score(self) -> float:
        """Calculate coupling score"""
        if not self.module_metrics:
            return 0.0
            
        total_coupling = sum(m.coupling for m in self.module_metrics.values())
        max_possible = len(self.module_metrics) * (len(self.module_metrics) - 1)
        
        if max_possible == 0:
            return 0.0
            
        return total_coupling / max_possible
    
    def _calculate_cohesion_score(self) -> float:
        """Calculate average cohesion score"""
        if not self.module_metrics:
            return 0.0
            
        return sum(m.cohesion for m in self.module_metrics.values()) / len(self.module_metrics)

# Architecture Analyzers

class ArchitectureAnalyzer(ABC):
    """Base class for architecture analyzers"""
    
    @abstractmethod
    def analyze(self, project_root: Path, 
                dependency_graph: nx.DiGraph) -> List[ArchitecturalIssue]:
        pass

class DependencyAnalyzer(ArchitectureAnalyzer):
    """Analyzes dependencies for issues"""
    
    def analyze(self, project_root: Path, 
                dependency_graph: nx.DiGraph) -> List[ArchitecturalIssue]:
        issues = []
        
        # Check for circular dependencies
        cycles = list(nx.simple_cycles(dependency_graph))
        for cycle in cycles:
            issues.append(ArchitecturalIssue(
                issue_type=AntiPattern.CIRCULAR_DEPENDENCY.value,
                severity="high",
                location=" -> ".join(cycle + [cycle[0]]),
                description=f"Circular dependency detected: {' -> '.join(cycle + [cycle[0]])}",
                impact="Makes code hard to understand and maintain",
                metrics={'cycle_length': len(cycle)}
            ))
        
        # Check for high fan-out (too many dependencies)
        for node in dependency_graph.nodes():
            out_degree = dependency_graph.out_degree(node)
            if out_degree > 10:
                issues.append(ArchitecturalIssue(
                    issue_type="high_fan_out",
                    severity="medium",
                    location=node,
                    description=f"Module {node} has too many dependencies ({out_degree})",
                    impact="High coupling, difficult to change",
                    metrics={'dependencies': out_degree}
                ))
        
        return issues

class ComplexityAnalyzer(ArchitectureAnalyzer):
    """Analyzes code complexity"""
    
    def analyze(self, project_root: Path, 
                dependency_graph: nx.DiGraph) -> List[ArchitecturalIssue]:
        issues = []
        
        for py_file in project_root.rglob("*.py"):
            if '__pycache__' in str(py_file):
                continue
                
            try:
                with open(py_file, 'r', encoding='utf-8') as f:
                    tree = ast.parse(f.read())
                    
                # Check for god classes
                for node in ast.walk(tree):
                    if isinstance(node, ast.ClassDef):
                        methods = [n for n in node.body if isinstance(n, ast.FunctionDef)]
                        if len(methods) > 20:
                            issues.append(ArchitecturalIssue(
                                issue_type=AntiPattern.GOD_CLASS.value,
                                severity="high",
                                location=f"{py_file}::{node.name}",
                                description=f"Class {node.name} has too many methods ({len(methods)})",
                                impact="Violates Single Responsibility Principle",
                                metrics={'method_count': len(methods)},
                                suggested_pattern=ArchitecturePattern.HEXAGONAL
                            ))
                            
            except Exception as e:
                print(f"Error analyzing {py_file}: {e}")
                
        return issues

# Pattern Detectors

class PatternDetector(ABC):
    """Base class for pattern detection"""
    
    @abstractmethod
    def detect(self, project_root: Path, dependency_graph: nx.DiGraph) -> float:
        """Return confidence score (0-1) that pattern is present"""
        pass

class LayeredPatternDetector(PatternDetector):
    """Detects layered architecture pattern"""
    
    def detect(self, project_root: Path, dependency_graph: nx.DiGraph) -> float:
        # Look for common layer names
        layer_keywords = ['presentation', 'business', 'data', 'domain', 'service', 'repository']
        
        nodes = list(dependency_graph.nodes())
        layer_nodes = [n for n in nodes if any(keyword in n.lower() for keyword in layer_keywords)]
        
        if not nodes:
            return 0.0
            
        # Check if dependencies flow in one direction
        violations = 0
        for edge in dependency_graph.edges():
            # Simplified check - real implementation would be more sophisticated
            if 'data' in edge[0] and 'presentation' in edge[1]:
                violations += 1
                
        confidence = len(layer_nodes) / len(nodes)
        if violations > 0:
            confidence *= 0.5
            
        return confidence

class MVCPatternDetector(PatternDetector):
    """Detects MVC pattern"""
    
    def detect(self, project_root: Path, dependency_graph: nx.DiGraph) -> float:
        mvc_keywords = ['model', 'view', 'controller', 'models', 'views', 'controllers']
        
        nodes = list(dependency_graph.nodes())
        mvc_nodes = [n for n in nodes if any(keyword in n.lower() for keyword in mvc_keywords)]
        
        if not nodes:
            return 0.0
            
        # Check for proper MVC structure
        has_models = any('model' in n.lower() for n in nodes)
        has_views = any('view' in n.lower() for n in nodes)
        has_controllers = any('controller' in n.lower() for n in nodes)
        
        if has_models and has_views and has_controllers:
            return 0.8
        elif has_models and (has_views or has_controllers):
            return 0.5
        else:
            return len(mvc_nodes) / len(nodes) * 0.3

class HexagonalPatternDetector(PatternDetector):
    """Detects hexagonal architecture"""
    
    def detect(self, project_root: Path, dependency_graph: nx.DiGraph) -> float:
        hex_keywords = ['port', 'adapter', 'domain', 'application', 'infrastructure']
        
        nodes = list(dependency_graph.nodes())
        hex_nodes = [n for n in nodes if any(keyword in n.lower() for keyword in hex_keywords)]
        
        if not nodes:
            return 0.0
            
        # Check for ports and adapters
        has_ports = any('port' in n.lower() for n in nodes)
        has_adapters = any('adapter' in n.lower() for n in nodes)
        has_domain = any('domain' in n.lower() for n in nodes)
        
        if has_ports and has_adapters and has_domain:
            return 0.9
        elif has_domain and (has_ports or has_adapters):
            return 0.6
        else:
            return len(hex_nodes) / len(nodes) * 0.3

class MicroservicesDetector(PatternDetector):
    """Detects microservices architecture"""
    
    def detect(self, project_root: Path, dependency_graph: nx.DiGraph) -> float:
        # Look for service boundaries
        service_keywords = ['service', 'api', 'endpoint', 'gateway']
        
        nodes = list(dependency_graph.nodes())
        service_nodes = [n for n in nodes if any(keyword in n.lower() for keyword in service_keywords)]
        
        # Check for multiple services
        services = defaultdict(list)
        for node in nodes:
            parts = node.split('.')
            if len(parts) > 1 and 'service' in parts[0].lower():
                services[parts[0]].append(node)
        
        if len(services) >= 3:
            return 0.8
        elif len(services) >= 2:
            return 0.5
        else:
            return 0.2

class CouplingAnalyzer(ArchitectureAnalyzer):
    """Analyzes coupling between modules"""
    
    def analyze(self, project_root: Path, 
                dependency_graph: nx.DiGraph) -> List[ArchitecturalIssue]:
        issues = []
        
        # Calculate afferent and efferent coupling
        for node in dependency_graph.nodes():
            afferent = dependency_graph.in_degree(node)   # Dependencies on this module
            efferent = dependency_graph.out_degree(node)  # This module's dependencies
            
            instability = efferent / (afferent + efferent) if (afferent + efferent) > 0 else 0
            
            # High instability with high responsibility is problematic
            if instability > 0.8 and afferent > 5:
                issues.append(ArchitecturalIssue(
                    issue_type="unstable_dependency",
                    severity="medium",
                    location=node,
                    description=f"Module {node} is unstable but heavily depended upon",
                    impact="Changes to this module affect many others",
                    metrics={
                        'afferent_coupling': afferent,
                        'efferent_coupling': efferent,
                        'instability': instability
                    }
                ))
        
        return issues

class TestCoverageAnalyzer(ArchitectureAnalyzer):
    """Analyzes test coverage (simplified)"""
    
    def analyze(self, project_root: Path, 
                dependency_graph: nx.DiGraph) -> List[ArchitecturalIssue]:
        issues = []
        
        # Find test files
        test_files = list(project_root.rglob("test_*.py")) + list(project_root.rglob("*_test.py"))
        source_files = [f for f in project_root.rglob("*.py") 
                       if not any(t in str(f) for t in ['test', '__pycache__'])]
        
        # Simple heuristic: check if modules have corresponding tests
        for source in source_files:
            module_name = source.stem
            has_test = any(module_name in str(test) for test in test_files)
            
            if not has_test:
                issues.append(ArchitecturalIssue(
                    issue_type="missing_tests",
                    severity="medium",
                    location=str(source),
                    description=f"Module {module_name} has no tests",
                    impact="Code changes may introduce bugs",
                    metrics={'has_tests': False}
                ))
        
        return issues
```

### Step 2: Create Demo Implementation

Create `src/architecture_demo.py`:
```python
"""Demo script for architecture decision agent"""

from pathlib import Path
from src.agents.architecture_agent import (
    ArchitectureDecisionAgent, ArchitecturePattern, AntiPattern
)

# Sample project structure for demo
def create_demo_project(root_dir: Path):
    """Create a demo project with architectural issues"""
    
    # Create directories
    (root_dir / "src").mkdir(parents=True, exist_ok=True)
    (root_dir / "src" / "models").mkdir(exist_ok=True)
    (root_dir / "src" / "services").mkdir(exist_ok=True)
    (root_dir / "src" / "utils").mkdir(exist_ok=True)
    
    # Create a god class
    god_class_code = '''
"""User management module with too many responsibilities"""

import json
import hashlib
import smtplib
from datetime import datetime
from typing import List, Dict, Optional

class UserManager:
    """Handles everything related to users - a god class anti-pattern"""
    
    def __init__(self):
        self.users = {}
        self.sessions = {}
        self.email_queue = []
        self.audit_log = []
        self.cache = {}
        
    # User CRUD operations
    def create_user(self, username: str, email: str, password: str) -> Dict:
        user_id = self._generate_id()
        hashed_password = self._hash_password(password)
        
        user = {
            'id': user_id,
            'username': username,
            'email': email,
            'password': hashed_password,
            'created_at': datetime.now(),
            'last_login': None,
            'profile': {},
            'settings': {},
            'permissions': []
        }
        
        self.users[user_id] = user
        self._send_welcome_email(email)
        self._log_action('user_created', user_id)
        return user
    
    def update_user(self, user_id: str, data: Dict) -> bool:
        if user_id not in self.users:
            return False
            
        self.users[user_id].update(data)
        self._invalidate_cache(user_id)
        self._log_action('user_updated', user_id)
        return True
    
    def delete_user(self, user_id: str) -> bool:
        if user_id not in self.users:
            return False
            
        del self.users[user_id]
        self._cleanup_sessions(user_id)
        self._log_action('user_deleted', user_id)
        return True
    
    # Authentication
    def login(self, username: str, password: str) -> Optional[str]:
        user = self._find_user_by_username(username)
        if not user:
            return None
            
        if not self._verify_password(password, user['password']):
            return None
            
        session_id = self._create_session(user['id'])
        user['last_login'] = datetime.now()
        self._log_action('user_login', user['id'])
        return session_id
    
    def logout(self, session_id: str) -> bool:
        if session_id not in self.sessions:
            return False
            
        user_id = self.sessions[session_id]
        del self.sessions[session_id]
        self._log_action('user_logout', user_id)
        return True
    
    # Email operations
    def _send_welcome_email(self, email: str):
        self.email_queue.append({
            'to': email,
            'subject': 'Welcome!',
            'body': 'Welcome to our platform!'
        })
    
    def send_password_reset(self, email: str):
        user = self._find_user_by_email(email)
        if user:
            token = self._generate_reset_token(user['id'])
            self.email_queue.append({
                'to': email,
                'subject': 'Password Reset',
                'body': f'Reset your password: {token}'
            })
    
    def process_email_queue(self):
        while self.email_queue:
            email = self.email_queue.pop(0)
            self._send_email(email)
    
    # Profile management
    def update_profile(self, user_id: str, profile_data: Dict):
        if user_id in self.users:
            self.users[user_id]['profile'].update(profile_data)
            self._invalidate_cache(user_id)
    
    def upload_avatar(self, user_id: str, image_data: bytes):
        # Process and store avatar
        pass
    
    # Settings management
    def update_settings(self, user_id: str, settings: Dict):
        if user_id in self.users:
            self.users[user_id]['settings'].update(settings)
    
    def get_user_preferences(self, user_id: str) -> Dict:
        if user_id in self.users:
            return self.users[user_id]['settings']
        return {}
    
    # Permission management
    def grant_permission(self, user_id: str, permission: str):
        if user_id in self.users:
            if permission not in self.users[user_id]['permissions']:
                self.users[user_id]['permissions'].append(permission)
                self._log_action('permission_granted', user_id, {'permission': permission})
    
    def revoke_permission(self, user_id: str, permission: str):
        if user_id in self.users:
            if permission in self.users[user_id]['permissions']:
                self.users[user_id]['permissions'].remove(permission)
                self._log_action('permission_revoked', user_id, {'permission': permission})
    
    def check_permission(self, user_id: str, permission: str) -> bool:
        if user_id in self.users:
            return permission in self.users[user_id]['permissions']
        return False
    
    # Analytics
    def get_user_stats(self) -> Dict:
        total_users = len(self.users)
        active_sessions = len(self.sessions)
        
        return {
            'total_users': total_users,
            'active_sessions': active_sessions,
            'emails_pending': len(self.email_queue)
        }
    
    def generate_user_report(self, start_date: datetime, end_date: datetime) -> List[Dict]:
        report = []
        for user in self.users.values():
            if start_date <= user['created_at'] <= end_date:
                report.append({
                    'id': user['id'],
                    'username': user['username'],
                    'created_at': user['created_at'],
                    'last_login': user['last_login']
                })
        return report
    
    # Caching
    def get_user_from_cache(self, user_id: str) -> Optional[Dict]:
        return self.cache.get(user_id)
    
    def cache_user(self, user_id: str, user_data: Dict):
        self.cache[user_id] = user_data
    
    def _invalidate_cache(self, user_id: str):
        if user_id in self.cache:
            del self.cache[user_id]
    
    # Audit logging
    def _log_action(self, action: str, user_id: str, details: Dict = None):
        self.audit_log.append({
            'action': action,
            'user_id': user_id,
            'timestamp': datetime.now(),
            'details': details or {}
        })
    
    def get_audit_log(self, user_id: str = None) -> List[Dict]:
        if user_id:
            return [log for log in self.audit_log if log['user_id'] == user_id]
        return self.audit_log
    
    # Helper methods
    def _generate_id(self) -> str:
        return hashlib.md5(str(datetime.now()).encode()).hexdigest()
    
    def _hash_password(self, password: str) -> str:
        return hashlib.sha256(password.encode()).hexdigest()
    
    def _verify_password(self, password: str, hashed: str) -> bool:
        return self._hash_password(password) == hashed
    
    def _find_user_by_username(self, username: str) -> Optional[Dict]:
        for user in self.users.values():
            if user['username'] == username:
                return user
        return None
    
    def _find_user_by_email(self, email: str) -> Optional[Dict]:
        for user in self.users.values():
            if user['email'] == email:
                return user
        return None
    
    def _create_session(self, user_id: str) -> str:
        session_id = self._generate_id()
        self.sessions[session_id] = user_id
        return session_id
    
    def _cleanup_sessions(self, user_id: str):
        sessions_to_remove = [
            sid for sid, uid in self.sessions.items() if uid == user_id
        ]
        for sid in sessions_to_remove:
            del self.sessions[sid]
    
    def _generate_reset_token(self, user_id: str) -> str:
        return hashlib.md5(f"{user_id}{datetime.now()}".encode()).hexdigest()
    
    def _send_email(self, email_data: Dict):
        # Actual email sending logic
        print(f"Sending email to {email_data['to']}: {email_data['subject']}")
'''
    
    # Write god class
    (root_dir / "src" / "models" / "user_manager.py").write_text(god_class_code)
    
    # Create circular dependency
    service_a = '''
"""Service A with circular dependency"""
from src.services.service_b import ServiceB

class ServiceA:
    def __init__(self):
        self.service_b = ServiceB()
    
    def process(self):
        return self.service_b.helper()
'''
    
    service_b = '''
"""Service B with circular dependency"""
from src.services.service_a import ServiceA

class ServiceB:
    def __init__(self):
        self.service_a = None  # Will create circular dependency if initialized
    
    def helper(self):
        return "processed"
    
    def do_something(self):
        if not self.service_a:
            self.service_a = ServiceA()
        return self.service_a.process()
'''
    
    # Write circular dependency files
    (root_dir / "src" / "services" / "service_a.py").write_text(service_a)
    (root_dir / "src" / "services" / "service_b.py").write_text(service_b)
    
    # Create high coupling example
    data_processor = '''
"""Data processor with high coupling"""
from src.models.user_manager import UserManager
from src.services.service_a import ServiceA
from src.services.service_b import ServiceB
from src.utils.helpers import *
import json
import csv
import xml.etree.ElementTree as ET

class DataProcessor:
    def __init__(self):
        self.user_manager = UserManager()
        self.service_a = ServiceA()
        self.service_b = ServiceB()
        
    def process_user_data(self, data):
        # Too many dependencies and responsibilities
        users = self.user_manager.get_all_users()
        processed = self.service_a.process()
        result = self.service_b.do_something()
        
        # Multiple format handling
        if isinstance(data, str):
            if data.endswith('.json'):
                return self.process_json(data)
            elif data.endswith('.csv'):
                return self.process_csv(data)
            elif data.endswith('.xml'):
                return self.process_xml(data)
                
        return None
'''
    
    (root_dir / "src" / "utils" / "data_processor.py").write_text(data_processor)
    
    # Create helpers
    helpers = '''
"""Utility functions"""

def helper_function_1():
    pass

def helper_function_2():
    pass
'''
    
    (root_dir / "src" / "utils" / "helpers.py").write_text(helpers)
    
    # Create __init__ files
    for dir_path in root_dir.rglob("*/"):
        if dir_path.is_dir() and not dir_path.name.startswith('.'):
            (dir_path / "__init__.py").touch()

def main():
    """Run architecture decision agent demo"""
    
    # Create demo project
    demo_root = Path("demo_architecture_project")
    print("🏗️ Creating demo project...")
    create_demo_project(demo_root)
    
    # Create agent
    print("\n🤖 Initializing Architecture Decision Agent...")
    agent = ArchitectureDecisionAgent(demo_root)
    
    # Analyze architecture
    print("\n🔍 Analyzing project architecture...")
    analysis = agent.analyze_architecture()
    
    # Display results
    print("\n📊 Analysis Results:")
    print(f"\nDetected Patterns:")
    for pattern, confidence in analysis['detected_patterns']:
        print(f"  - {pattern.value}: {confidence:.2%} confidence")
    
    print(f"\n🚨 Issues Found: {len(analysis['issues'])}")
    for issue in analysis['issues'][:5]:  # Show first 5 issues
        print(f"\n  Issue: {issue.issue_type}")
        print(f"  Severity: {issue.severity}")
        print(f"  Location: {issue.location}")
        print(f"  Description: {issue.description}")
        if issue.suggested_pattern:
            print(f"  Suggested Pattern: {issue.suggested_pattern.value}")
    
    print(f"\n📈 Architecture Metrics:")
    metrics = analysis['metrics']
    print(f"  - Total LOC: {metrics['total_lines_of_code']}")
    print(f"  - Average Complexity: {metrics['average_complexity']:.2f}")
    print(f"  - Modularity Score: {metrics['modularity_score']:.2%}")
    print(f"  - Maintainability Index: {metrics['maintainability_index']:.2f}")
    
    print(f"\n🔗 Dependency Graph:")
    graph_stats = analysis['dependency_graph_stats']
    print(f"  - Modules: {graph_stats['nodes']}")
    print(f"  - Dependencies: {graph_stats['edges']}")
    print(f"  - Circular Dependencies: {len(graph_stats['cycles'])}")
    
    # Generate ADRs for top issues
    print("\n📝 Generating Architecture Decision Records...")
    
    # Find the god class issue
    god_class_issue = next((i for i in analysis['issues'] 
                           if i.issue_type == AntiPattern.GOD_CLASS.value), None)
    
    if god_class_issue:
        print(f"\n  Generating ADR for: {god_class_issue.location}")
        adr = agent.generate_adr(god_class_issue, ArchitecturePattern.HEXAGONAL)
        
        print(f"\n  ADR {adr.id}: {adr.title}")
        print(f"  Status: {adr.status.value}")
        print(f"  Total Effort: {adr.implementation_plan.total_effort_hours} hours")
        print(f"  Phases: {len(adr.implementation_plan.phases)}")
        
        # Save ADRs
        output_dir = Path("architecture_decisions_output")
        agent.save_decisions(output_dir)
        print(f"\n✅ ADRs saved to: {output_dir}")
    
    # Generate improvement roadmap
    print("\n🗺️ Improvement Roadmap:")
    improvements = analysis['improvements']
    for i, improvement in enumerate(improvements, 1):
        print(f"\n  {i}. {improvement['issue']}")
        print(f"     Severity: {improvement['severity']}")
        print(f"     Suggestion: {improvement['suggestion']}")
        if 'pattern' in improvement:
            print(f"     Recommended Pattern: {improvement['pattern'].value}")

if __name__ == "__main__":
    main()
```

### Step 3: Create Tests

Create `tests/test_architecture_agent.py`:
```python
import pytest
from pathlib import Path
from src.agents.architecture_agent import (
    ArchitectureDecisionAgent, ArchitecturalIssue, 
    ArchitecturePattern, AntiPattern, DecisionStatus
)

class TestArchitectureAgent:
    @pytest.fixture
    def test_project(self, tmp_path):
        """Create test project structure"""
        # Create directories
        (tmp_path / "src").mkdir()
        
        # Create a simple module
        simple_module = '''
def hello():
    return "Hello, World!"
'''
        (tmp_path / "src" / "simple.py").write_text(simple_module)
        
        # Create module with god class
        god_class = '''
class EverythingManager:
    """ + "\\n".join([f"    def method_{i}(self): pass" for i in range(25)]) + '''
'''
        (tmp_path / "src" / "god_class.py").write_text(god_class)
        
        return tmp_path
    
    @pytest.fixture
    def agent(self, test_project):
        return ArchitectureDecisionAgent(test_project)
    
    def test_agent_initialization(self, agent):
        """Test agent initializes correctly"""
        assert agent.project_root.exists()
        assert len(agent.analyzers) > 0
        assert len(agent.pattern_detectors) > 0
    
    def test_dependency_graph_building(self, agent):
        """Test dependency graph construction"""
        agent._build_dependency_graph()
        
        assert agent.dependency_graph.number_of_nodes() > 0
    
    def test_issue_detection(self, agent):
        """Test architectural issue detection"""
        analysis = agent.analyze_architecture()
        
        assert 'issues' in analysis
        assert len(analysis['issues']) > 0
        
        # Should detect god class
        god_class_issues = [i for i in analysis['issues'] 
                           if i.issue_type == AntiPattern.GOD_CLASS.value]
        assert len(god_class_issues) > 0
    
    def test_adr_generation(self, agent):
        """Test ADR generation"""
        # Create test issue
        issue = ArchitecturalIssue(
            issue_type=AntiPattern.GOD_CLASS.value,
            severity="high",
            location="test_module.py",
            description="Test god class",
            impact="High maintenance cost",
            metrics={'method_count': 30}
        )
        
        # Generate ADR
        adr = agent.generate_adr(issue, ArchitecturePattern.HEXAGONAL)
        
        assert adr.id.startswith("ADR-")
        assert adr.status == DecisionStatus.PROPOSED
        assert len(adr.consequences['positive']) > 0
        assert len(adr.consequences['negative']) > 0
        assert adr.implementation_plan is not None
        assert adr.implementation_plan.total_effort_hours > 0
    
    def test_pattern_detection(self, agent):
        """Test architecture pattern detection"""
        patterns = agent._detect_patterns()
        
        # Should return list of (pattern, confidence) tuples
        assert isinstance(patterns, list)
        for pattern, confidence in patterns:
            assert isinstance(pattern, ArchitecturePattern)
            assert 0 <= confidence <= 1
    
    def test_metrics_calculation(self, agent):
        """Test metrics calculation"""
        analysis = agent.analyze_architecture()
        metrics = analysis['metrics']
        
        assert 'total_lines_of_code' in metrics
        assert 'average_complexity' in metrics
        assert 'modularity_score' in metrics
        assert 'maintainability_index' in metrics
        
        assert metrics['modularity_score'] >= 0
        assert metrics['maintainability_index'] >= 0

class TestArchitecturalAnalyzers:
    def test_complexity_analyzer(self, tmp_path):
        """Test complexity analysis"""
        from src.agents.architecture_agent import ComplexityAnalyzer
        
        # Create complex file
        complex_code = '''
class ComplexClass:
''' + '\n'.join([f'    def method_{i}(self): pass' for i in range(30)])
        
        (tmp_path / "complex.py").write_text(complex_code)
        
        analyzer = ComplexityAnalyzer()
        issues = analyzer.analyze(tmp_path, nx.DiGraph())
        
        assert len(issues) > 0
        assert issues[0].issue_type == AntiPattern.GOD_CLASS.value
    
    def test_dependency_analyzer(self):
        """Test dependency analysis"""
        from src.agents.architecture_agent import DependencyAnalyzer
        
        # Create graph with cycle
        graph = nx.DiGraph()
        graph.add_edge("A", "B")
        graph.add_edge("B", "C")
        graph.add_edge("C", "A")
        
        analyzer = DependencyAnalyzer()
        issues = analyzer.analyze(Path("."), graph)
        
        assert len(issues) > 0
        assert issues[0].issue_type == AntiPattern.CIRCULAR_DEPENDENCY.value

class TestPatternDetectors:
    def test_layered_pattern_detection(self, tmp_path):
        """Test layered pattern detection"""
        from src.agents.architecture_agent import LayeredPatternDetector
        
        # Create layered structure
        (tmp_path / "presentation").mkdir()
        (tmp_path / "business").mkdir()
        (tmp_path / "data").mkdir()
        
        graph = nx.DiGraph()
        graph.add_node("presentation.views")
        graph.add_node("business.services")
        graph.add_node("data.repositories")
        
        detector = LayeredPatternDetector()
        confidence = detector.detect(tmp_path, graph)
        
        assert confidence > 0.5
```

## 🏃 Running the Architecture Agent

1. **Basic Usage**:
```python
from pathlib import Path
from src.agents.architecture_agent import ArchitectureDecisionAgent

# Create agent for your project
agent = ArchitectureDecisionAgent(Path("your_project"))

# Analyze architecture
analysis = agent.analyze_architecture()

# Generate ADRs for issues
for issue in analysis['issues'][:3]:
    if issue.suggested_pattern:
        adr = agent.generate_adr(issue, issue.suggested_pattern)
        print(f"Generated: {adr.title}")

# Save decisions
agent.save_decisions(Path("output"))
```

2. **Custom Analysis**:
```python
# Add custom analyzer
from src.agents.architecture_agent import ArchitectureAnalyzer

class SecurityAnalyzer(ArchitectureAnalyzer):
    def analyze(self, project_root, dependency_graph):
        # Custom security analysis
        pass

agent.analyzers.append(SecurityAnalyzer())
```

## 🎯 Validation

Run the validation script:
```bash
python scripts/validate_exercise3.py
```

Expected output:
```
✅ Architecture agent implemented
✅ Pattern detection working
✅ Issue identification correct
✅ ADR generation functional
✅ Implementation plans created
✅ Trade-off analysis complete

Score: 100/100
```

## 🚀 Extension Challenges

1. **ML-Based Pattern Recognition**: Use machine learning to detect patterns
2. **Real-time Monitoring**: Track architecture drift over time
3. **IDE Integration**: VS Code extension for architecture insights
4. **Team Collaboration**: Multi-user ADR approval workflow
5. **Cost Analysis**: Estimate refactoring costs based on team metrics

## 📚 Additional Resources

- [C4 Model](https://c4model.com/)
- [Architecture Decision Records](https://adr.github.io/)
- [Software Architecture Patterns](https://www.oreilly.com/library/view/software-architecture-patterns/9781491971437/)
- [Refactoring to Patterns](https://martinfowler.com/books/refactoringToPatterns.html)

## 🎉 Congratulations!

You've completed Module 22! You've mastered:
- ✅ Custom agent architecture design
- ✅ Complex state and memory management
- ✅ Specialized tool integration
- ✅ Domain-specific agent development
- ✅ Advanced error handling and resilience

## ⏭️ Next Module

Ready to continue? Move on to [Module 23: Model Context Protocol (MCP)](../../module-23-mcp/README.md) where you'll learn to implement the protocol that enables universal agent communication!