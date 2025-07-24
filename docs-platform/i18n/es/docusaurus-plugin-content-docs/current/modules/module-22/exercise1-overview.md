---
sidebar_position: 3
title: "Exercise 1: Overview"
description: "## 🎯 Objective"
---

# Ejercicio 1: Documentación Generation Agent (⭐ Fácil - 30 minutos)

## 🎯 Objective
Build a custom agent that automatically generates and maintains documentation by analyzing code structure, extracting metadata, and creating comprehensive documentation in multiple formats.

## 🧠 Lo Que Aprenderás
- Custom agent architecture design
- Code analysis and metadata extraction
- Template-based generation
- Multi-format output handling
- Documentación versioning

## 📋 Prerrequisitos
- Completard Módulo 21
- Understanding of AST (Abstract Syntax Tree)
- Basic knowledge of documentation formats (Markdown, RST)
- Familiarity with Jinja2 templating

## 📚 Atrásground

A documentation agent must:
- Analyze code structure and patterns
- Extract meaningful information
- Generate human-readable documentation
- Maintain consistency across projects
- Actualizar documentation as code changes

## 🛠️ Instructions

### Step 1: Design the Documentación Agent Architecture

**Copilot Prompt Suggestion:**
```python
# Create a documentation generation agent that:
# - Analyzes Python modules and classes
# - Extracts docstrings, type hints, and metadata
# - Generates documentation in multiple formats
# - Maintains documentation templates
# - Tracks documentation coverage
# - Supports incremental updates
# Use template method pattern for different formats
```

Create `src/agents/documentation_agent.py`:
```python
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import List, Dict, Any, Optional, Set
from pathlib import Path
import ast
import inspect
from datetime import datetime
from enum import Enum
import jinja2

class DocFormat(Enum):
    """Supported documentation formats"""
    MARKDOWN = "markdown"
    RESTRUCTURED_TEXT = "rst"
    HTML = "html"
    API_JSON = "json"

@dataclass
class CodeEntity:
    """Represents a code entity to document"""
    name: str
    type: str  # module, class, function, method
    docstring: Optional[str]
    signature: Optional[str]
    parameters: List[Dict[str, Any]]
    returns: Optional[Dict[str, Any]]
    raises: List[str]
    examples: List[str]
    source_file: str
    line_number: int
    parent: Optional[str] = None
    decorators: List[str] = field(default_factory=list)
    type_hints: Dict[str, str] = field(default_factory=dict)
    complexity: int = 0
    
@dataclass
class DocumentationConfig:
    """Configuration for documentation generation"""
    project_name: str
    version: str
    author: str
    formats: List[DocFormat]
    output_dir: Path
    template_dir: Path
    include_private: bool = False
    include_source: bool = True
    max_line_length: int = 80
    
class DocumentationAgent:
    """Agent for automatic documentation generation"""
    
    def __init__(self, config: DocumentationConfig):
        self.config = config
        self.entities: List[CodeEntity] = []
        self.template_engine = self._setup_templates()
        self.analyzers = self._setup_analyzers()
        self.generators = self._setup_generators()
        self.memory = DocumentationMemory()
        
    def _setup_templates(self) -&gt; jinja2.Environment:
        """Set up Jinja2 template engine"""
        loader = jinja2.FileSystemLoader(self.config.template_dir)
        env = jinja2.Environment(
            loader=loader,
            autoescape=jinja2.select_autoescape(['html', 'xml'])
        )
        
        # Add custom filters
        env.filters['format_signature'] = self._format_signature
        env.filters['format_type'] = self._format_type_hint
        
        return env
    
    def _setup_analyzers(self) -&gt; Dict[str, 'CodeAnalyzer']:
        """Set up code analyzers for different languages"""
        return {
            'python': PythonAnalyzer(self.config),
            # Add more analyzers as needed
        }
    
    def _setup_generators(self) -&gt; Dict[DocFormat, 'DocGenerator']:
        """Set up documentation generators for different formats"""
        return {
            DocFormat.MARKDOWN: MarkdownGenerator(self.template_engine),
            DocFormat.RESTRUCTURED_TEXT: RSTGenerator(self.template_engine),
            DocFormat.HTML: HTMLGenerator(self.template_engine),
            DocFormat.API_JSON: JSONGenerator(),
        }
    
    def analyze_project(self, project_path: Path) -&gt; Dict[str, Any]:
        """Analyze entire project and extract documentation data"""
        self.entities.clear()
        stats = {
            'total_files': 0,
            'documented_entities': 0,
            'undocumented_entities': 0,
            'coverage': 0.0
        }
        
        # Find all Python files
        for py_file in project_path.rglob("*.py"):
            if self._should_skip_file(py_file):
                continue
                
            stats['total_files'] += 1
            
            # Analyze file
            analyzer = self.analyzers.get('python')
            if analyzer:
                file_entities = analyzer.analyze_file(py_file)
                self.entities.extend(file_entities)
                
                # Update statistics
                for entity in file_entities:
                    if entity.docstring:
                        stats['documented_entities'] += 1
                    else:
                        stats['undocumented_entities'] += 1
        
        # Calculate coverage
        total_entities = stats['documented_entities'] + stats['undocumented_entities']
        if total_entities &gt; 0:
            stats['coverage'] = stats['documented_entities'] / total_entities
            
        # Store in memory for incremental updates
        self.memory.store_analysis(project_path, self.entities, stats)
        
        return stats
    
    def generate_documentation(self) -&gt; Dict[DocFormat, Path]:
        """Generate documentation in all configured formats"""
        generated_files = {}
        
        # Organize entities by type and module
        organized = self._organize_entities()
        
        # Generate documentation for each format
        for doc_format in self.config.formats:
            generator = self.generators.get(doc_format)
            if generator:
                output_path = generator.generate(
                    organized,
                    self.config,
                    self.config.output_dir
                )
                generated_files[doc_format] = output_path
                
        # Generate index/overview
        self._generate_index(organized, generated_files)
        
        return generated_files
    
    def update_documentation(self, changed_files: List[Path]) -&gt; Dict[DocFormat, Path]:
        """Incrementally update documentation for changed files"""
        # Get previous analysis from memory
        previous_entities = self.memory.get_entities()
        
        # Re-analyze only changed files
        updated_entities = []
        for file_path in changed_files:
            analyzer = self.analyzers.get('python')
            if analyzer:
                # Remove old entities from this file
                self.entities = [e for e in self.entities 
                               if e.source_file != str(file_path)]
                
                # Add new entities
                new_entities = analyzer.analyze_file(file_path)
                self.entities.extend(new_entities)
                updated_entities.extend(new_entities)
        
        # Regenerate only affected documentation
        return self.generate_documentation()
    
    def _should_skip_file(self, file_path: Path) -&gt; bool:
        """Check if file should be skipped"""
        skip_patterns = ['__pycache__', 'venv', 'env', '.git', 'build', 'dist']
        return any(pattern in str(file_path) for pattern in skip_patterns)
    
    def _organize_entities(self) -&gt; Dict[str, Any]:
        """Organize entities by module and type"""
        organized = {
            'modules': {{}},
            'classes': {{}},
            'functions': {{}},
            'constants': []
        }
        
        for entity in self.entities:
            if entity.type == 'module':
                organized['modules'][entity.name] = entity
            elif entity.type == 'class':
                module = entity.source_file
                if module not in organized['classes']:
                    organized['classes'][module] = []
                organized['classes'][module].append(entity)
            elif entity.type in ['function', 'method']:
                module = entity.source_file
                if module not in organized['functions']:
                    organized['functions'][module] = []
                organized['functions'][module].append(entity)
                
        return organized
    
    def _generate_index(self, organized: Dict[str, Any], 
                       generated_files: Dict[DocFormat, Path]):
        """Generate index/overview page"""
        # Create index for each format
        for doc_format, output_path in generated_files.items():
            generator = self.generators.get(doc_format)
            if generator and hasattr(generator, 'generate_index'):
                generator.generate_index(organized, output_path.parent)
    
    def _format_signature(self, entity: CodeEntity) -&gt; str:
        """Format function/method signature"""
        if not entity.signature:
            return entity.name
            
        # Format parameters nicely
        params = []
        for param in entity.parameters:
            param_str = param['name']
            if param.get('type'):
                param_str += f": {{param['type']}}"
            if param.get('default'):
                param_str += f" = {param['default']}"
            params.append(param_str)
            
        return f"{entity.name}({', '.join(params)})"
    
    def _format_type_hint(self, type_hint: str) -&gt; str:
        """Format type hints for readability"""
        # Simplify complex type hints
        replacements = {
            'typing.': '',
            'Optional[': 'Optional[',
            'List[': 'List[',
            'Dict[': 'Dict[',
        }
        
        for old, new in replacements.items():
            type_hint = type_hint.replace(old, new)
            
        return type_hint

class DocumentationMemory:
    """Memory system for documentation agent"""
    
    def __init__(self):
        self.analyses: Dict[str, Dict[str, Any]] = {}
        self.generation_history: List[Dict[str, Any]] = []
        
    def store_analysis(self, project_path: Path, entities: List[CodeEntity], 
                      stats: Dict[str, Any]):
        """Store analysis results"""
        self.analyses[str(project_path)] = {
            'entities': entities,
            'stats': stats,
            'timestamp': datetime.now()
        }
    
    def get_entities(self) -&gt; List[CodeEntity]:
        """Get all stored entities"""
        all_entities = []
        for analysis in self.analyses.values():
            all_entities.extend(analysis['entities'])
        return all_entities
    
    def get_stats(self, project_path: Path) -&gt; Optional[Dict[str, Any]]:
        """Get statistics for a project"""
        analysis = self.analyses.get(str(project_path))
        return analysis['stats'] if analysis else None
```

### Step 2: Implement Code Analyzer

**Copilot Prompt Suggestion:**
```python
# Create a Python code analyzer that:
# - Parses Python files using AST
# - Extracts all documentable entities
# - Captures type hints and signatures
# - Identifies code patterns and complexity
# - Handles edge cases gracefully
```

Create `src/analyzers/python_analyzer.py`:
```python
import ast
import inspect
from typing import List, Dict, Any, Optional, Tuple
from pathlib import Path
import re

class PythonAnalyzer:
    """Analyzer for Python source code"""
    
    def __init__(self, config):
        self.config = config
        self.current_file = None
        self.current_class = None
        
    def analyze_file(self, file_path: Path) -&gt; List[CodeEntity]:
        """Analyze a Python file and extract entities"""
        entities = []
        self.current_file = str(file_path)
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                source = f.read()
                
            tree = ast.parse(source)
            
            # Extract module docstring
            module_doc = ast.get_docstring(tree)
            if module_doc:
                entities.append(CodeEntity(
                    name=file_path.stem,
                    type='module',
                    docstring=module_doc,
                    signature=None,
                    parameters=[],
                    returns=None,
                    raises=[],
                    examples=self._extract_examples(module_doc),
                    source_file=self.current_file,
                    line_number=1
                ))
            
            # Walk the AST
            for node in ast.walk(tree):
                if isinstance(node, ast.ClassDef):
                    class_entity = self._analyze_class(node, source)
                    if class_entity:
                        entities.append(class_entity)
                        
                elif isinstance(node, ast.FunctionDef):
                    if not self._is_inside_class(node, tree):
                        func_entity = self._analyze_function(node, source)
                        if func_entity:
                            entities.append(func_entity)
                            
                elif isinstance(node, ast.AsyncFunctionDef):
                    if not self._is_inside_class(node, tree):
                        func_entity = self._analyze_function(node, source, is_async=True)
                        if func_entity:
                            entities.append(func_entity)
                            
        except Exception as e:
            print(f"Error analyzing {file_path}: {e}")
            
        return entities
    
    def _analyze_class(self, node: ast.ClassDef, source: str) -&gt; Optional[CodeEntity]:
        """Analyze a class definition"""
        if self._should_skip_entity(node.name):
            return None
            
        docstring = ast.get_docstring(node)
        
        # Extract base classes
        bases = [self._get_name(base) for base in node.bases]
        
        # Extract decorators
        decorators = [self._get_decorator_name(d) for d in node.decorator_list]
        
        entity = CodeEntity(
            name=node.name,
            type='class',
            docstring=docstring,
            signature=f"class {node.name}({', '.join(bases)})" if bases else f"class {node.name}",
            parameters=[],  # Classes don't have parameters
            returns=None,
            raises=[],
            examples=self._extract_examples(docstring) if docstring else [],
            source_file=self.current_file,
            line_number=node.lineno,
            decorators=decorators
        )
        
        # Analyze methods
        self.current_class = node.name
        for item in node.body:
            if isinstance(item, (ast.FunctionDef, ast.AsyncFunctionDef)):
                method_entity = self._analyze_function(item, source, is_method=True)
                if method_entity:
                    method_entity.parent = node.name
                    # Note: In a real implementation, you'd store methods separately
                    
        self.current_class = None
        
        return entity
    
    def _analyze_function(self, node: ast.FunctionDef, source: str, 
                         is_method: bool = False, is_async: bool = False) -&gt; Optional[CodeEntity]:
        """Analyze a function or method definition"""
        if self._should_skip_entity(node.name):
            return None
            
        docstring = ast.get_docstring(node)
        
        # Extract parameters
        parameters = self._extract_parameters(node)
        
        # Extract return type
        returns = self._extract_return_type(node, docstring)
        
        # Extract raised exceptions
        raises = self._extract_raises(node, docstring)
        
        # Extract decorators
        decorators = [self._get_decorator_name(d) for d in node.decorator_list]
        
        # Calculate complexity
        complexity = self._calculate_complexity(node)
        
        # Build signature
        signature = self._build_signature(node, is_async)
        
        entity = CodeEntity(
            name=node.name,
            type='method' if is_method else 'function',
            docstring=docstring,
            signature=signature,
            parameters=parameters,
            returns=returns,
            raises=raises,
            examples=self._extract_examples(docstring) if docstring else [],
            source_file=self.current_file,
            line_number=node.lineno,
            decorators=decorators,
            complexity=complexity
        )
        
        return entity
    
    def _extract_parameters(self, node: ast.FunctionDef) -&gt; List[Dict[str, Any]]:
        """Extract function parameters with types and defaults"""
        parameters = []
        
        # Positional arguments
        for i, arg in enumerate(node.args.args):
            param = {
                'name': arg.arg,
                'type': None,
                'default': None,
                'kind': 'positional'
            }
            
            # Get type annotation
            if arg.annotation:
                param['type'] = ast.unparse(arg.annotation)
                
            # Get default value
            defaults_offset = len(node.args.args) - len(node.args.defaults)
            if i &gt;= defaults_offset:
                default_index = i - defaults_offset
                param['default'] = ast.unparse(node.args.defaults[default_index])
                
            parameters.append(param)
        
        # *args
        if node.args.vararg:
            param = {
                'name': f"*{{node.args.vararg.arg}}",
                'type': ast.unparse(node.args.vararg.annotation) if node.args.vararg.annotation else None,
                'default': None,
                'kind': 'var_positional'
            }
            parameters.append(param)
        
        # **kwargs
        if node.args.kwarg:
            param = {
                'name': f"**{{node.args.kwarg.arg}}",
                'type': ast.unparse(node.args.kwarg.annotation) if node.args.kwarg.annotation else None,
                'default': None,
                'kind': 'var_keyword'
            }
            parameters.append(param)
            
        return parameters
    
    def _extract_return_type(self, node: ast.FunctionDef, docstring: str) -&gt; Optional[Dict[str, Any]]:
        """Extract return type from annotation or docstring"""
        return_info = {
            'type': None,
            'description': None
        }
        
        # From annotation
        if node.returns:
            return_info['type'] = ast.unparse(node.returns)
        
        # From docstring
        if docstring:
            returns_match = re.search(r':returns?:\s*(.+)', docstring)
            if returns_match:
                return_info['description'] = returns_match.group(1).strip()
                
            rtype_match = re.search(r':rtype:\s*(.+)', docstring)
            if rtype_match and not return_info['type']:
                return_info['type'] = rtype_match.group(1).strip()
                
        return return_info if return_info['type'] or return_info['description'] else None
    
    def _extract_raises(self, node: ast.FunctionDef, docstring: str) -&gt; List[str]:
        """Extract raised exceptions from code and docstring"""
        raises = set()
        
        # From code
        for child in ast.walk(node):
            if isinstance(child, ast.Raise):
                if child.exc:
                    if isinstance(child.exc, ast.Call):
                        raises.add(self._get_name(child.exc.func))
                    elif isinstance(child.exc, ast.Name):
                        raises.add(child.exc.id)
        
        # From docstring
        if docstring:
            raises_matches = re.findall(r':raises?\s+(\w+):', docstring)
            raises.update(raises_matches)
            
        return list(raises)
    
    def _extract_examples(self, docstring: str) -&gt; List[str]:
        """Extract examples from docstring"""
        if not docstring:
            return []
            
        examples = []
        
        # Look for &gt;&gt;&gt; examples
        example_pattern = r'&gt;&gt;&gt;\s*(.+?)(?=\n(?:&gt;&gt;&gt;|\s*$))'
        examples.extend(re.findall(example_pattern, docstring, re.MULTILINE))
        
        # Look for Example: sections
        example_section = re.search(r'Example[s]?:\s*\n(.+?)(?=\n\n|\Z)', docstring, re.DOTALL)
        if example_section:
            examples.append(example_section.group(1).strip())
            
        return examples
    
    def _calculate_complexity(self, node: ast.FunctionDef) -&gt; int:
        """Calculate cyclomatic complexity"""
        complexity = 1
        
        for child in ast.walk(node):
            if isinstance(child, (ast.If, ast.While, ast.For, ast.ExceptHandler)):
                complexity += 1
            elif isinstance(child, ast.BoolOp):
                complexity += len(child.values) - 1
                
        return complexity
    
    def _build_signature(self, node: ast.FunctionDef, is_async: bool) -&gt; str:
        """Build function signature"""
        prefix = "async " if is_async else ""
        params = []
        
        for param in self._extract_parameters(node):
            param_str = param['name']
            if param['type']:
                param_str = f"{param['name']}: {param['type']}"
            if param['default']:
                param_str += f" = {param['default']}"
            params.append(param_str)
        
        signature = f"{prefix}def {node.name}({', '.join(params)})"
        
        if node.returns:
            signature += f" -&gt; {ast.unparse(node.returns)}"
            
        return signature
    
    def _should_skip_entity(self, name: str) -&gt; bool:
        """Check if entity should be skipped"""
        if not self.config.include_private and name.startswith('_'):
            return True
        return False
    
    def _is_inside_class(self, node: ast.AST, tree: ast.AST) -&gt; bool:
        """Check if node is inside a class definition"""
        for parent in ast.walk(tree):
            if isinstance(parent, ast.ClassDef):
                for child in parent.body:
                    if child is node:
                        return True
        return False
    
    def _get_name(self, node: ast.AST) -&gt; str:
        """Get name from various AST nodes"""
        if isinstance(node, ast.Name):
            return node.id
        elif isinstance(node, ast.Attribute):
            return f"{self._get_name(node.value)}.{node.attr}"
        elif hasattr(node, 'id'):
            return node.id
        return str(node)
    
    def _get_decorator_name(self, decorator: ast.AST) -&gt; str:
        """Get decorator name"""
        if isinstance(decorator, ast.Name):
            return decorator.id
        elif isinstance(decorator, ast.Call):
            return self._get_name(decorator.func)
        elif isinstance(decorator, ast.Attribute):
            return f"{self._get_name(decorator.value)}.{decorator.attr}"
        return str(decorator)
```

### Step 3: Implement Documentación Generators

**Copilot Prompt Suggestion:**
```python
# Create documentation generators for different formats:
# - MarkdownGenerator with GitHub-flavored markdown
# - RSTGenerator for Sphinx documentation
# - HTMLGenerator with modern styling
# - JSONGenerator for API documentation
# Each should use templates and handle all entity types
```

Create `src/generators/markdown_generator.py`:
```python
from pathlib import Path
from typing import Dict, Any, List
import jinja2
from datetime import datetime

class MarkdownGenerator:
    """Generator for Markdown documentation"""
    
    def __init__(self, template_engine: jinja2.Environment):
        self.template_engine = template_engine
        self.toc_entries = []
        
    def generate(self, organized: Dict[str, Any], config: Any, 
                output_dir: Path) -&gt; Path:
        """Generate Markdown documentation"""
        output_dir = output_dir / "markdown"
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Generate module pages
        for module_name, module_entity in organized['modules'].items():
            self._generate_module_page(module_name, module_entity, 
                                     organized, output_dir)
        
        # Generate API reference
        api_path = self._generate_api_reference(organized, output_dir)
        
        # Generate main index
        index_path = self._generate_main_index(organized, config, output_dir)
        
        return index_path
    
    def _generate_module_page(self, module_name: str, module_entity: Any,
                            organized: Dict[str, Any], output_dir: Path):
        """Generate documentation for a single module"""
        template = self.template_engine.get_template('markdown/module.md.j2')
        
        # Gather module data
        module_data = {
            'module': module_entity,
            'classes': organized['classes'].get(module_entity.source_file, []),
            'functions': organized['functions'].get(module_entity.source_file, []),
            'generated_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }
        
        # Render template
        content = template.render(**module_data)
        
        # Write file
        output_file = output_dir / f"{module_name}.md"
        output_file.write_text(content)
        
        # Add to TOC
        self.toc_entries.append({
            'title': module_name,
            'path': f"{{module_name}}.md",
            'type': 'module'
        })
    
    def _generate_api_reference(self, organized: Dict[str, Any], 
                              output_dir: Path) -&gt; Path:
        """Generate complete API reference"""
        template = self.template_engine.get_template('markdown/api_reference.md.j2')
        
        # Organize by type
        api_data = {
            'modules': list(organized['modules'].values()),
            'all_classes': [],
            'all_functions': [],
            'generated_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }
        
        # Flatten classes and functions
        for classes in organized['classes'].values():
            api_data['all_classes'].extend(classes)
        for functions in organized['functions'].values():
            api_data['all_functions'].extend(functions)
        
        # Sort alphabetically
        api_data['all_classes'].sort(key=lambda x: x.name)
        api_data['all_functions'].sort(key=lambda x: x.name)
        
        # Render
        content = template.render(**api_data)
        
        # Write
        output_file = output_dir / "api_reference.md"
        output_file.write_text(content)
        
        return output_file
    
    def _generate_main_index(self, organized: Dict[str, Any], config: Any,
                           output_dir: Path) -&gt; Path:
        """Generate main index/README"""
        template = self.template_engine.get_template('markdown/index.md.j2')
        
        # Calculate statistics
        stats = {
            'total_modules': len(organized['modules']),
            'total_classes': sum(len(classes) for classes in organized['classes'].values()),
            'total_functions': sum(len(funcs) for funcs in organized['functions'].values()),
        }
        
        # Prepare data
        index_data = {
            'project_name': config.project_name,
            'version': config.version,
            'author': config.author,
            'stats': stats,
            'toc_entries': self.toc_entries,
            'generated_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }
        
        # Render
        content = template.render(**index_data)
        
        # Write
        output_file = output_dir / "README.md"
        output_file.write_text(content)
        
        return output_file
    
    def generate_index(self, organized: Dict[str, Any], output_dir: Path):
        """Generate index page for cross-references"""
        template = self.template_engine.get_template('markdown/cross_reference.md.j2')
        
        # Build cross-reference data
        xref_data = {
            '