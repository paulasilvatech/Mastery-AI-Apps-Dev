#!/usr/bin/env python3
"""
Module Completion Report Generator
Generates a detailed report of what's missing in each module
"""

import os
import json
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple

class ModuleValidator:
    def __init__(self, base_path: str = "modules"):
        self.base_path = Path(base_path)
        self.required_files = [
            "README.md",
            "prerequisites.md",
            "best-practices.md"
        ]
        self.required_dirs = ["exercises", "resources"]
        self.exercise_levels = ["easy", "medium", "hard"]
        
    def validate_all_modules(self) -> Dict:
        """Validate all 30 modules and return a comprehensive report"""
        report = {
            "timestamp": datetime.now().isoformat(),
            "summary": {
                "total_modules": 30,
                "existing_modules": 0,
                "complete_modules": 0,
                "incomplete_modules": 0,
                "missing_modules": 0
            },
            "modules": {},
            "action_items": []
        }
        
        for i in range(1, 31):
            module_num = f"{i:02d}"
            module_path = self.base_path / f"module-{module_num}"
            
            if module_path.exists():
                report["summary"]["existing_modules"] += 1
                module_report = self.validate_module(module_path, i)
                report["modules"][f"module-{module_num}"] = module_report
                
                if module_report["status"] == "complete":
                    report["summary"]["complete_modules"] += 1
                else:
                    report["summary"]["incomplete_modules"] += 1
                    
                # Generate action items
                for missing in module_report["missing_items"]:
                    report["action_items"].append({
                        "module": f"module-{module_num}",
                        "type": missing["type"],
                        "item": missing["item"],
                        "priority": missing["priority"]
                    })
            else:
                report["summary"]["missing_modules"] += 1
                report["modules"][f"module-{module_num}"] = {
                    "status": "missing",
                    "exists": False
                }
                report["action_items"].append({
                    "module": f"module-{module_num}",
                    "type": "directory",
                    "item": "entire module",
                    "priority": "high"
                })
        
        return report
    
    def validate_module(self, module_path: Path, module_num: int) -> Dict:
        """Validate a single module"""
        module_report = {
            "status": "incomplete",
            "exists": True,
            "completeness": 0,
            "has_files": {},
            "has_dirs": {},
            "exercises": {
                "count": 0,
                "levels": {}
            },
            "missing_items": []
        }
        
        total_checks = 0
        passed_checks = 0
        
        # Check required files
        for req_file in self.required_files:
            total_checks += 1
            file_path = module_path / req_file
            exists = file_path.exists()
            module_report["has_files"][req_file] = exists
            
            if exists:
                passed_checks += 1
            else:
                priority = "high" if req_file == "README.md" else "medium"
                module_report["missing_items"].append({
                    "type": "file",
                    "item": req_file,
                    "priority": priority
                })
        
        # Check required directories
        for req_dir in self.required_dirs:
            total_checks += 1
            dir_path = module_path / req_dir
            exists = dir_path.exists()
            module_report["has_dirs"][req_dir] = exists
            
            if exists:
                passed_checks += 1
            else:
                priority = "high" if req_dir == "exercises" else "low"
                module_report["missing_items"].append({
                    "type": "directory",
                    "item": req_dir,
                    "priority": priority
                })
        
        # Check exercises
        exercises_path = module_path / "exercises"
        if exercises_path.exists():
            # Count exercise directories
            exercise_dirs = [d for d in exercises_path.iterdir() if d.is_dir()]
            module_report["exercises"]["count"] = len(exercise_dirs)
            
            # Check for each difficulty level
            for level in self.exercise_levels:
                total_checks += 1
                found = False
                
                for exercise_dir in exercise_dirs:
                    if level in exercise_dir.name.lower():
                        found = True
                        module_report["exercises"]["levels"][level] = exercise_dir.name
                        passed_checks += 1
                        break
                
                if not found:
                    module_report["exercises"]["levels"][level] = None
                    module_report["missing_items"].append({
                        "type": "exercise",
                        "item": f"exercise-{level}",
                        "priority": "high"
                    })
            
            # Check exercise structure
            for exercise_dir in exercise_dirs:
                # Check for required subdirectories in each exercise
                for subdir in ["instructions", "starter", "solution"]:
                    total_checks += 1
                    if (exercise_dir / subdir).exists():
                        passed_checks += 1
                    else:
                        module_report["missing_items"].append({
                            "type": "exercise_component",
                            "item": f"{exercise_dir.name}/{subdir}",
                            "priority": "medium"
                        })
        
        # Calculate completeness
        module_report["completeness"] = round((passed_checks / total_checks * 100) if total_checks > 0 else 0, 1)
        
        # Determine status
        if module_report["completeness"] == 100:
            module_report["status"] = "complete"
        elif module_report["completeness"] >= 80:
            module_report["status"] = "nearly_complete"
        elif module_report["completeness"] >= 50:
            module_report["status"] = "partial"
        else:
            module_report["status"] = "incomplete"
        
        return module_report
    
    def generate_markdown_report(self, report: Dict) -> str:
        """Generate a markdown formatted report"""
        md = []
        md.append("# 📊 Module Completion Report")
        md.append(f"\n*Generated: {report['timestamp']}*\n")
        
        # Summary
        md.append("## 📈 Summary")
        summary = report["summary"]
        md.append(f"- **Total Modules**: {summary['total_modules']}")
        md.append(f"- **Existing Modules**: {summary['existing_modules']}")
        md.append(f"- **Complete Modules**: {summary['complete_modules']} ✅")
        md.append(f"- **Incomplete Modules**: {summary['incomplete_modules']} ⚠️")
        md.append(f"- **Missing Modules**: {summary['missing_modules']} ❌")
        
        completion_rate = (summary['complete_modules'] / summary['total_modules']) * 100
        md.append(f"\n**Overall Completion**: {completion_rate:.1f}%")
        
        # Module Status Table
        md.append("\n## 📋 Module Status")
        md.append("\n| Module | Status | Completeness | Files | Exercises |")
        md.append("|--------|--------|--------------|-------|-----------|")
        
        for module_name, module_data in sorted(report["modules"].items()):
            if not module_data["exists"]:
                md.append(f"| {module_name} | ❌ Missing | 0% | - | - |")
            else:
                status_icon = {
                    "complete": "✅",
                    "nearly_complete": "🔵",
                    "partial": "🟡",
                    "incomplete": "🟠",
                    "missing": "❌"
                }.get(module_data["status"], "❓")
                
                files_count = sum(1 for v in module_data["has_files"].values() if v)
                exercises_count = module_data["exercises"]["count"]
                
                md.append(f"| {module_name} | {status_icon} {module_data['status'].replace('_', ' ').title()} | {module_data['completeness']}% | {files_count}/3 | {exercises_count}/3 |")
        
        # Priority Action Items
        md.append("\n## 🎯 Priority Action Items")
        
        high_priority = [item for item in report["action_items"] if item["priority"] == "high"]
        medium_priority = [item for item in report["action_items"] if item["priority"] == "medium"]
        low_priority = [item for item in report["action_items"] if item["priority"] == "low"]
        
        if high_priority:
            md.append("\n### 🔴 High Priority")
            for item in high_priority[:10]:  # Show top 10
                md.append(f"- **{item['module']}**: Create {item['type']} `{item['item']}`")
        
        if medium_priority:
            md.append("\n### 🟡 Medium Priority")
            for item in medium_priority[:5]:  # Show top 5
                md.append(f"- **{item['module']}**: Add {item['type']} `{item['item']}`")
        
        # Module Details
        md.append("\n## 📁 Module Details")
        
        for module_name, module_data in sorted(report["modules"].items()):
            if module_data["exists"] and module_data["status"] != "complete":
                md.append(f"\n### {module_name}")
                
                if module_data["missing_items"]:
                    md.append("\n**Missing:**")
                    for item in module_data["missing_items"]:
                        md.append(f"- {item['type']}: `{item['item']}`")
        
        return "\n".join(md)
    
    def generate_action_script(self, report: Dict) -> str:
        """Generate a bash script to create missing structure"""
        script = []
        script.append("#!/bin/bash")
        script.append("# Auto-generated script to complete module structure")
        script.append("# Generated: " + report['timestamp'])
        script.append("")
        script.append("set -e")
        script.append("")
        
        # Colors
        script.append("GREEN='\\033[0;32m'")
        script.append("YELLOW='\\033[0;33m'")
        script.append("NC='\\033[0m'")
        script.append("")
        
        script.append('echo "🚀 Creating missing module structure..."')
        script.append("")
        
        # Create missing modules
        for module_name, module_data in sorted(report["modules"].items()):
            if not module_data["exists"]:
                script.append(f'echo -e "${{YELLOW}}Creating {module_name}...${{NC}}"')
                script.append(f'mkdir -p modules/{module_name}')
                script.append(f'mkdir -p modules/{module_name}/exercises')
                script.append(f'mkdir -p modules/{module_name}/resources')
                
                # Create basic files
                script.append(f'touch modules/{module_name}/README.md')
                script.append(f'touch modules/{module_name}/prerequisites.md')
                script.append(f'touch modules/{module_name}/best-practices.md')
                
                # Create exercise structure
                for i, level in enumerate(["easy", "medium", "hard"], 1):
                    script.append(f'mkdir -p modules/{module_name}/exercises/exercise{i}-{level}')
                    script.append(f'mkdir -p modules/{module_name}/exercises/exercise{i}-{level}/instructions')
                    script.append(f'mkdir -p modules/{module_name}/exercises/exercise{i}-{level}/starter')
                    script.append(f'mkdir -p modules/{module_name}/exercises/exercise{i}-{level}/solution')
                
                script.append("")
        
        # Create missing files in existing modules
        for module_name, module_data in sorted(report["modules"].items()):
            if module_data["exists"] and module_data["missing_items"]:
                script.append(f'echo -e "${{YELLOW}}Completing {module_name}...${{NC}}"')
                
                for item in module_data["missing_items"]:
                    if item["type"] == "file":
                        script.append(f'touch modules/{module_name}/{item["item"]}')
                    elif item["type"] == "directory":
                        script.append(f'mkdir -p modules/{module_name}/{item["item"]}')
                    elif item["type"] == "exercise":
                        level = item["item"].split("-")[1]
                        num = {"easy": 1, "medium": 2, "hard": 3}.get(level, 1)
                        script.append(f'mkdir -p modules/{module_name}/exercises/exercise{num}-{level}')
                        script.append(f'mkdir -p modules/{module_name}/exercises/exercise{num}-{level}/instructions')
                        script.append(f'mkdir -p modules/{module_name}/exercises/exercise{num}-{level}/starter')
                        script.append(f'mkdir -p modules/{module_name}/exercises/exercise{num}-{level}/solution')
                
                script.append("")
        
        script.append('echo -e "${GREEN}✅ Module structure creation complete!${NC}"')
        script.append('echo "Run ./scripts/validate-workshop-complete.sh to verify"')
        
        return "\n".join(script)


def main():
    """Main function to run the validation"""
    validator = ModuleValidator()
    
    print("🔍 Analyzing module structure...")
    report = validator.validate_all_modules()
    
    # Save JSON report
    with open("module-completion-report.json", "w") as f:
        json.dump(report, f, indent=2)
    print("✅ Saved detailed report to module-completion-report.json")
    
    # Save Markdown report
    markdown_report = validator.generate_markdown_report(report)
    with open("MODULE-STATUS.md", "w") as f:
        f.write(markdown_report)
    print("✅ Saved markdown report to MODULE-STATUS.md")
    
    # Generate action script if needed
    if report["summary"]["incomplete_modules"] > 0 or report["summary"]["missing_modules"] > 0:
        action_script = validator.generate_action_script(report)
        with open("complete-modules.sh", "w") as f:
            f.write(action_script)
        os.chmod("complete-modules.sh", 0o755)
        print("✅ Generated complete-modules.sh script")
        print("\n📝 Run ./complete-modules.sh to create missing structure")
    
    # Print summary
    print(f"\n📊 Summary:")
    print(f"   Complete modules: {report['summary']['complete_modules']}/30")
    print(f"   Incomplete modules: {report['summary']['incomplete_modules']}")
    print(f"   Missing modules: {report['summary']['missing_modules']}")
    
    completion_rate = (report['summary']['complete_modules'] / 30) * 100
    print(f"\n   Overall completion: {completion_rate:.1f}%")


if __name__ == "__main__":
    main()
