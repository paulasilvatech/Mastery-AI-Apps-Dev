#!/usr/bin/env python3
"""
Module 05 Exercise Validation Script
Validates completion of documentation and code quality exercises
"""

import ast
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import subprocess
import json
import importlib.util

class ExerciseValidator:
    """Validate Module 05 exercise completion."""
    
    def __init__(self):
        self.results = {
            "exercise1": {"passed": 0, "total": 0, "details": []},
            "exercise2": {"passed": 0, "total": 0, "details": []},
            "exercise3": {"passed": 0, "total": 0, "details": []},
        }
        
    def validate_all(self) -> bool:
        """Run all validations and return overall pass/fail."""
        print("🔍 Module 05 Exercise Validator")
        print("=" * 50)
        
        # Check Exercise 1: Documentation Generator
        print("\n📝 Exercise 1: Documentation Generator")
        self.validate_exercise1()
        
        # Check Exercise 2: Refactoring Assistant
        print("\n🔨 Exercise 2: Refactoring Assistant")
        self.validate_exercise2()
        
        # Check Exercise 3: Quality Automation System
        print("\n📊 Exercise 3: Quality Automation System")
        self.validate_exercise3()
        
        # Summary
        self.print_summary()
        
        # Return True if all exercises pass
        return all(
            ex["passed"] == ex["total"] 
            for ex in self.results.values()
        )
    
    def validate_exercise1(self):
        """Validate Documentation Generator exercise."""
        exercise_path = Path("exercises/exercise1-easy/solution")
        
        # Check 1: Main file exists
        main_file = exercise_path / "doc_generator.py"
        self.check(
            "exercise1",
            "Main file exists",
            main_file.exists()
        )
        
        if not main_file.exists():
            return
        
        # Check 2: Can parse the file
        try:
            tree = ast.parse(main_file.read_text())
            self.check("exercise1", "Valid Python syntax", True)
        except SyntaxError:
            self.check("exercise1", "Valid Python syntax", False)
            return
        
        # Check 3: Required classes exist
        classes = [node.name for node in ast.walk(tree) if isinstance(node, ast.ClassDef)]
        self.check(
            "exercise1",
            "DocumentationGenerator class exists",
            "DocumentationGenerator" in classes
        )
        
        # Check 4: Required methods exist
        if "DocumentationGenerator" in classes:
            methods = self.get_class_methods(tree, "DocumentationGenerator")
            required_methods = [
                "parse_file",
                "extract_functions",
                "generate_docstring",
                "generate_readme"
            ]
            
            for method in required_methods:
                self.check(
                    "exercise1",
                    f"Method {method} exists",
                    method in methods
                )
        
        # Check 5: Tests exist
        test_file = exercise_path / "tests" / "test_doc_generator.py"
        self.check(
            "exercise1",
            "Test file exists",
            test_file.exists()
        )
        
        # Check 6: Can import and run basic test
        try:
            sys.path.insert(0, str(exercise_path))
            from doc_generator import DocumentationGenerator, DocStyle
            
            # Test instantiation
            gen = DocumentationGenerator(style=DocStyle.GOOGLE)
            self.check("exercise1", "Can instantiate DocumentationGenerator", True)
            
            # Test basic functionality
            test_code = '''
def hello(name: str) -> str:
    return f"Hello, {name}!"
'''
            tree = ast.parse(test_code)
            functions = gen.extract_functions(tree)
            self.check(
                "exercise1",
                "Can extract functions",
                len(functions) > 0
            )
            
        except Exception as e:
            self.check(
                "exercise1",
                "Can import and run",
                False,
                f"Error: {str(e)}"
            )
        finally:
            sys.path.pop(0)
    
    def validate_exercise2(self):
        """Validate Refactoring Assistant exercise."""
        exercise_path = Path("exercises/exercise2-medium/solution")
        
        # Check 1: Main file exists
        main_file = exercise_path / "refactoring_assistant.py"
        self.check(
            "exercise2",
            "Main file exists",
            main_file.exists()
        )
        
        if not main_file.exists():
            return
        
        # Check 2: Required classes and enums
        try:
            tree = ast.parse(main_file.read_text())
            classes = [node.name for node in ast.walk(tree) if isinstance(node, ast.ClassDef)]
            
            self.check(
                "exercise2",
                "RefactoringAssistant class exists",
                "RefactoringAssistant" in classes
            )
            
            self.check(
                "exercise2",
                "SmellType enum exists",
                "SmellType" in classes
            )
            
            self.check(
                "exercise2",
                "CodeSmell class exists",
                "CodeSmell" in classes
            )
            
        except SyntaxError:
            self.check("exercise2", "Valid Python syntax", False)
            return
        
        # Check 3: Smell detection methods
        if "RefactoringAssistant" in classes:
            methods = self.get_class_methods(tree, "RefactoringAssistant")
            smell_methods = [
                "_detect_long_methods",
                "_detect_long_parameter_lists",
                "_detect_duplicate_code",
                "_detect_complex_conditionals"
            ]
            
            for method in smell_methods:
                self.check(
                    "exercise2",
                    f"Smell detector {method} exists",
                    method in methods
                )
        
        # Check 4: Refactoring implementations
        refactoring_dir = exercise_path / "refactorings"
        self.check(
            "exercise2",
            "Refactorings directory exists",
            refactoring_dir.exists()
        )
        
        if refactoring_dir.exists():
            refactoring_files = list(refactoring_dir.glob("*.py"))
            self.check(
                "exercise2",
                "At least 3 refactoring implementations",
                len(refactoring_files) >= 3
            )
    
    def validate_exercise3(self):
        """Validate Quality Automation System exercise."""
        exercise_path = Path("exercises/exercise3-hard/solution")
        
        # Check 1: Main system file
        main_file = exercise_path / "quality_system.py"
        self.check(
            "exercise3",
            "Main system file exists",
            main_file.exists()
        )
        
        if not main_file.exists():
            return
        
        # Check 2: Component directories
        components = ["monitors", "reporters", "integrations", "dashboards"]
        for component in components:
            component_dir = exercise_path / component
            self.check(
                "exercise3",
                f"{component} directory exists",
                component_dir.exists()
            )
        
        # Check 3: Monitor implementations
        monitors_dir = exercise_path / "monitors"
        if monitors_dir.exists():
            monitor_files = list(monitors_dir.glob("*_monitor.py"))
            self.check(
                "exercise3",
                "At least 4 quality monitors",
                len(monitor_files) >= 4
            )
        
        # Check 4: CI/CD integration
        ci_file = exercise_path / "integrations" / "github_actions.py"
        self.check(
            "exercise3",
            "GitHub Actions integration exists",
            ci_file.exists()
        )
        
        # Check 5: Dashboard implementation
        dashboard_file = exercise_path / "dashboards" / "quality_dashboard.py"
        self.check(
            "exercise3",
            "Dashboard implementation exists",
            dashboard_file.exists()
        )
        
        # Check 6: Configuration support
        config_file = exercise_path / "config" / "quality_config.py"
        self.check(
            "exercise3",
            "Configuration system exists",
            config_file.exists() or (exercise_path / "config.py").exists()
        )
        
        # Check 7: Docker deployment
        docker_file = exercise_path.parent / "deployment" / "docker-compose.yml"
        self.check(
            "exercise3",
            "Docker deployment configuration",
            docker_file.exists() or (exercise_path / "Dockerfile").exists()
        )
    
    def check(self, exercise: str, test_name: str, passed: bool, details: str = ""):
        """Record a test result."""
        self.results[exercise]["total"] += 1
        if passed:
            self.results[exercise]["passed"] += 1
            print(f"  ✅ {test_name}")
        else:
            print(f"  ❌ {test_name}")
            if details:
                print(f"     {details}")
        
        self.results[exercise]["details"].append({
            "test": test_name,
            "passed": passed,
            "details": details
        })
    
    def get_class_methods(self, tree: ast.Module, class_name: str) -> List[str]:
        """Extract method names from a class."""
        methods = []
        for node in ast.walk(tree):
            if isinstance(node, ast.ClassDef) and node.name == class_name:
                for item in node.body:
                    if isinstance(item, ast.FunctionDef):
                        methods.append(item.name)
        return methods
    
    def print_summary(self):
        """Print validation summary."""
        print("\n" + "=" * 50)
        print("📊 VALIDATION SUMMARY")
        print("=" * 50)
        
        total_passed = 0
        total_tests = 0
        
        for exercise, results in self.results.items():
            passed = results["passed"]
            total = results["total"]
            total_passed += passed
            total_tests += total
            
            percentage = (passed / total * 100) if total > 0 else 0
            status = "✅ PASS" if passed == total else "❌ FAIL"
            
            print(f"\n{exercise.upper()}:")
            print(f"  Status: {status}")
            print(f"  Passed: {passed}/{total} ({percentage:.1f}%)")
        
        print("\n" + "-" * 50)
        overall_percentage = (total_passed / total_tests * 100) if total_tests > 0 else 0
        overall_status = "✅ ALL EXERCISES COMPLETE!" if total_passed == total_tests else "❌ INCOMPLETE"
        
        print(f"OVERALL: {overall_status}")
        print(f"Total: {total_passed}/{total_tests} ({overall_percentage:.1f}%)")
        
        if total_passed < total_tests:
            print("\n💡 Tips:")
            print("- Review the failed checks above")
            print("- Ensure all files are in the correct locations")
            print("- Check that all required methods are implemented")
            print("- Run tests locally to debug issues")
    
    def export_results(self, filename: str = "validation_results.json"):
        """Export results to JSON file."""
        with open(filename, 'w') as f:
            json.dump(self.results, f, indent=2)
        print(f"\n📄 Results exported to {filename}")


def main():
    """Run the validation script."""
    validator = ExerciseValidator()
    
    # Check if we're in the right directory
    if not Path("exercises").exists():
        print("❌ Error: Must run from module-05 directory")
        print("   Current directory:", Path.cwd())
        sys.exit(1)
    
    # Run validation
    all_passed = validator.validate_all()
    
    # Export results
    validator.export_results()
    
    # Exit with appropriate code
    sys.exit(0 if all_passed else 1)


if __name__ == "__main__":
    main()