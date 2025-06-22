#!/usr/bin/env python3
"""
Context Optimization Validation Script
Tests if your code is optimally structured for GitHub Copilot
"""

import ast
import sys
from pathlib import Path
from typing import Dict, List, Tuple
import importlib.util

class ContextValidator:
    """Validates context optimization in task manager code."""
    
    def __init__(self, file_path: str = "task_manager.py"):
        self.file_path = Path(file_path)
        self.results = {
            "import_organization": False,
            "class_structure": False,
            "function_grouping": False,
            "comment_quality": False,
            "type_hints": False,
            "pattern_consistency": False
        }
        self.details = []
        
    def validate(self) -> bool:
        """Run all validation checks."""
        if not self.file_path.exists():
            print(f"❌ File not found: {self.file_path}")
            return False
            
        with open(self.file_path, 'r') as f:
            self.content = f.read()
            
        try:
            self.tree = ast.parse(self.content)
        except SyntaxError as e:
            print(f"❌ Syntax error in file: {e}")
            return False
            
        # Run all checks
        self.check_import_organization()
        self.check_class_structure()
        self.check_function_grouping()
        self.check_comment_quality()
        self.check_type_hints()
        self.check_pattern_consistency()
        
        return self.print_results()
        
    def check_import_organization(self):
        """Check if imports are well-organized."""
        imports = [node for node in ast.walk(self.tree) if isinstance(node, (ast.Import, ast.ImportFrom))]
        
        if not imports:
            self.details.append("No imports found")
            return
            
        # Check for import grouping
        import_lines = []
        for imp in imports:
            import_lines.append(imp.lineno)
            
        # Check if imports are at the top
        first_non_import = None
        for node in self.tree.body:
            if not isinstance(node, (ast.Import, ast.ImportFrom)) and not isinstance(node, ast.Expr):
                first_non_import = node.lineno
                break
                
        imports_organized = all(line < first_non_import for line in import_lines if first_non_import)
        
        # Check for proper typing imports
        has_typing = any(
            isinstance(node, ast.ImportFrom) and node.module == 'typing'
            for node in imports
        )
        
        self.results["import_organization"] = imports_organized and has_typing
        if not imports_organized:
            self.details.append("Imports should be at the top of the file")
        if not has_typing:
            self.details.append("Missing typing imports for type hints")
            
    def check_class_structure(self):
        """Check if classes are well-structured."""
        classes = [node for node in ast.walk(self.tree) if isinstance(node, ast.ClassDef)]
        
        task_class = None
        manager_class = None
        
        for cls in classes:
            if cls.name == "Task":
                task_class = cls
            elif "Manager" in cls.name:
                manager_class = cls
                
        # Check Task class
        if task_class:
            # Check for dataclass decorator
            has_dataclass = any(
                isinstance(dec, ast.Name) and dec.id == 'dataclass'
                for dec in task_class.decorator_list
            )
            
            # Check for appropriate fields
            has_init = any(isinstance(node, ast.FunctionDef) and node.name == '__init__' 
                          for node in task_class.body)
            
            if has_dataclass or has_init:
                self.results["class_structure"] = True
            else:
                self.details.append("Task class missing proper initialization")
        else:
            self.details.append("No Task class found")
            
        if not manager_class:
            self.details.append("No TaskManager class found")
            
    def check_function_grouping(self):
        """Check if related functions are grouped together."""
        if not hasattr(self, 'tree'):
            return
            
        # Find TaskManager class
        manager_class = None
        for node in ast.walk(self.tree):
            if isinstance(node, ast.ClassDef) and "Manager" in node.name:
                manager_class = node
                break
                
        if not manager_class:
            return
            
        # Check for CRUD method grouping
        methods = [n.name for n in manager_class.body if isinstance(n, ast.FunctionDef)]
        
        crud_methods = ['add', 'get', 'update', 'delete', 'list', 'create', 'remove']
        crud_found = [m for m in methods if any(crud in m.lower() for crud in crud_methods)]
        
        if len(crud_found) >= 3:
            self.results["function_grouping"] = True
        else:
            self.details.append(f"Only found {len(crud_found)} CRUD methods, expected at least 3")
            
    def check_comment_quality(self):
        """Check for strategic comments."""
        # Count different types of comments
        lines = self.content.split('\n')
        
        todo_comments = sum(1 for line in lines if 'TODO:' in line or 'todo:' in line.lower())
        section_comments = sum(1 for line in lines if '===' in line or '---' in line)
        docstrings = len([node for node in ast.walk(self.tree) 
                         if isinstance(node, (ast.FunctionDef, ast.ClassDef)) and ast.get_docstring(node)])
        
        # Check for descriptive comments before complex methods
        complex_comments = sum(1 for i, line in enumerate(lines) 
                             if i > 0 and line.strip().startswith('#') and 
                             len(line.strip()) > 20 and
                             i + 1 < len(lines) and 'def ' in lines[i + 1])
        
        total_quality_indicators = (
            (todo_comments > 0) + 
            (section_comments > 0) + 
            (docstrings > 3) + 
            (complex_comments > 1)
        )
        
        self.results["comment_quality"] = total_quality_indicators >= 2
        
        if docstrings < 3:
            self.details.append(f"Only {docstrings} docstrings found, aim for more")
            
    def check_type_hints(self):
        """Check for proper type hint usage."""
        functions = [node for node in ast.walk(self.tree) if isinstance(node, ast.FunctionDef)]
        
        total_functions = len(functions)
        typed_functions = 0
        
        for func in functions:
            # Check return type
            has_return_type = func.returns is not None
            
            # Check parameter types
            typed_params = sum(1 for arg in func.args.args if arg.annotation is not None)
            total_params = len(func.args.args)
            
            if has_return_type and (total_params == 0 or typed_params > 0):
                typed_functions += 1
                
        if total_functions > 0:
            type_coverage = typed_functions / total_functions
            self.results["type_hints"] = type_coverage >= 0.6
            
            if type_coverage < 0.6:
                self.details.append(f"Type hint coverage: {type_coverage:.0%}, aim for 60%+")
        else:
            self.details.append("No functions found to check type hints")
            
    def check_pattern_consistency(self):
        """Check for consistent patterns."""
        # Find patterns in method names
        if not hasattr(self, 'tree'):
            return
            
        manager_class = None
        for node in ast.walk(self.tree):
            if isinstance(node, ast.ClassDef) and "Manager" in node.name:
                manager_class = node
                break
                
        if not manager_class:
            return
            
        methods = [n.name for n in manager_class.body if isinstance(n, ast.FunctionDef)]
        
        # Check for consistent naming patterns
        patterns = {
            'get_': [m for m in methods if m.startswith('get_')],
            'add_': [m for m in methods if m.startswith('add_')],
            'update_': [m for m in methods if m.startswith('update_')],
            'delete_': [m for m in methods if m.startswith('delete_') or m.startswith('remove_')]
        }
        
        consistent_patterns = sum(1 for p, matches in patterns.items() if len(matches) >= 1)
        
        self.results["pattern_consistency"] = consistent_patterns >= 2
        
        if consistent_patterns < 2:
            self.details.append("Use consistent method naming patterns (get_, add_, update_, etc.)")
            
    def print_results(self) -> bool:
        """Print validation results."""
        print("\n" + "="*50)
        print("Context Optimization Validation Results")
        print("="*50 + "\n")
        
        all_passed = True
        
        for check, passed in self.results.items():
            status = "✅" if passed else "❌"
            check_name = check.replace("_", " ").title()
            print(f"{status} {check_name}: {'PASSED' if passed else 'FAILED'}")
            if not passed:
                all_passed = False
                
        if self.details:
            print("\n📝 Details:")
            for detail in self.details:
                print(f"   - {detail}")
                
        print("\n" + "="*50)
        
        if all_passed:
            print("🎉 All checks passed! Your code is well-optimized for Copilot.")
        else:
            passed_count = sum(self.results.values())
            total_count = len(self.results)
            print(f"📊 Score: {passed_count}/{total_count} checks passed")
            print("\n💡 Tip: Review the failed checks and improve your code structure.")
            
        return all_passed


def main():
    """Run the validator."""
    if len(sys.argv) > 1:
        file_path = sys.argv[1]
    else:
        file_path = "task_manager.py"
        
    validator = ContextValidator(file_path)
    validator.validate()


if __name__ == "__main__":
    main()
