#!/usr/bin/env python3
"""
Smart Content Restoration Script
Automatically maps and restores module content from the content directory
"""

import os
import shutil
import re
from pathlib import Path
from typing import Dict, List, Tuple

# Colors for terminal output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    PURPLE = '\033[0;35m'
    NC = '\033[0m'  # No Color

def print_header(message: str):
    print(f"\n{Colors.BLUE}{'='*50}{Colors.NC}")
    print(f"{Colors.BLUE}{message}{Colors.NC}")
    print(f"{Colors.BLUE}{'='*50}{Colors.NC}\n")

def print_success(message: str):
    print(f"{Colors.GREEN}✓ {message}{Colors.NC}")

def print_info(message: str):
    print(f"{Colors.PURPLE}ℹ {message}{Colors.NC}")

def print_warning(message: str):
    print(f"{Colors.YELLOW}⚠️  {message}{Colors.NC}")

def print_error(message: str):
    print(f"{Colors.RED}❌ {message}{Colors.NC}")

class ContentRestorer:
    def __init__(self, content_dir: str = "content", modules_dir: str = "modules"):
        self.content_dir = Path(content_dir)
        self.modules_dir = Path(modules_dir)
        self.file_mappings = self._create_file_mappings()
        self.restoration_log = []
        
    def _create_file_mappings(self) -> Dict[str, str]:
        """Create mappings from filename patterns to destination paths"""
        return {
            # Markdown files
            r"module-(\d+)-README\.md": r"modules/module-\1/README.md",
            r"module-(\d+)\.md": r"modules/module-\1/README.md",
            
            # Exercise instructions
            r"module-(\d+)-exercise1-part1\.md": r"modules/module-\1/exercises/exercise1-easy/instructions/part1.md",
            r"module-(\d+)-exercise1-part2\.md": r"modules/module-\1/exercises/exercise1-easy/instructions/part2.md",
            r"module-(\d+)-exercise1-part3\.md": r"modules/module-\1/exercises/exercise1-easy/instructions/part3.md",
            r"module-(\d+)-exercise2-part1\.md": r"modules/module-\1/exercises/exercise2-medium/instructions/part1.md",
            r"module-(\d+)-exercise2-part2\.md": r"modules/module-\1/exercises/exercise2-medium/instructions/part2.md",
            r"module-(\d+)-exercise2-part3\.md": r"modules/module-\1/exercises/exercise2-medium/instructions/part3.md",
            r"module-(\d+)-exercise3-part1\.md": r"modules/module-\1/exercises/exercise3-hard/instructions/part1.md",
            r"module-(\d+)-exercise3-part2\.md": r"modules/module-\1/exercises/exercise3-hard/instructions/part2.md",
            r"module-(\d+)-exercise3-part3\.md": r"modules/module-\1/exercises/exercise3-hard/instructions/part3.md",
            
            # Module documents
            r"module-(\d+)-prerequisites\.md": r"modules/module-\1/prerequisites.md",
            r"module-(\d+)-best-practices\.md": r"modules/module-\1/best-practices.md",
            r"module-(\d+)-troubleshooting\.md": r"modules/module-\1/troubleshooting.md",
            
            # Resources
            r"module-(\d+)-common-patterns\.md": r"modules/module-\1/resources/common-patterns.md",
            r"module-(\d+)-prompt-templates\.md": r"modules/module-\1/resources/prompt-templates.md",
            r"module-(\d+)-project-readme\.md": r"modules/module-\1/resources/project-template.md",
            
            # Python files - Solutions
            r"module-(\d+)-exercise1-solution\.py": r"modules/module-\1/exercises/exercise1-easy/solution/solution.py",
            r"module-(\d+)-exercise2-solution.*\.py": r"modules/module-\1/exercises/exercise2-medium/solution/",
            r"module-(\d+)-exercise3-solution.*\.py": r"modules/module-\1/exercises/exercise3-hard/solution/",
            
            # Python files - Starters
            r"module-(\d+)-exercise1-starter\.py": r"modules/module-\1/exercises/exercise1-easy/starter/starter.py",
            r"module-(\d+)-exercise2-starter.*\.py": r"modules/module-\1/exercises/exercise2-medium/starter/",
            r"module-(\d+)-exercise3-starter.*\.py": r"modules/module-\1/exercises/exercise3-hard/starter/",
            
            # Python files - Tests
            r"module-(\d+)-.*test.*\.py": r"modules/module-\1/resources/",
            r"module-(\d+)-utils.*\.py": r"modules/module-\1/resources/",
            
            # Shell scripts
            r"module-(\d+)-.*\.sh": r"modules/module-\1/resources/",
        }
    
    def find_content_files(self) -> List[Path]:
        """Find all content files in the content directory"""
        if not self.content_dir.exists():
            print_error(f"Content directory '{self.content_dir}' not found!")
            return []
        
        files = []
        for ext in ['*.md', '*.py', '*.sh', '*.yml', '*.yaml', '*.json']:
            files.extend(self.content_dir.glob(ext))
        
        return sorted(files)
    
    def determine_destination(self, source_file: Path) -> Path:
        """Determine the destination path for a source file"""
        filename = source_file.name
        
        for pattern, destination in self.file_mappings.items():
            match = re.match(pattern, filename)
            if match:
                dest_path = re.sub(pattern, destination, filename)
                return Path(dest_path)
        
        # Default: put unmatched files in resources
        module_match = re.match(r"module-(\d+)-.*", filename)
        if module_match:
            module_num = module_match.group(1)
            return Path(f"modules/module-{module_num}/resources/{filename}")
        
        return None
    
    def restore_file(self, source: Path, destination: Path) -> bool:
        """Restore a single file to its destination"""
        try:
            # Create destination directory
            destination.parent.mkdir(parents=True, exist_ok=True)
            
            # Copy file
            shutil.copy2(source, destination)
            
            # Make shell scripts executable
            if destination.suffix == '.sh':
                os.chmod(destination, 0o755)
            
            self.restoration_log.append((source.name, str(destination), "✅ Success"))
            return True
            
        except Exception as e:
            self.restoration_log.append((source.name, str(destination), f"❌ Error: {e}"))
            return False
    
    def restore_all(self):
        """Restore all content files"""
        print_header("🔄 Smart Content Restoration")
        
        # Find all content files
        content_files = self.find_content_files()
        print_info(f"Found {len(content_files)} files in content directory")
        
        if not content_files:
            print_error("No content files found!")
            return
        
        # Process each file
        success_count = 0
        for source_file in content_files:
            destination = self.determine_destination(source_file)
            
            if destination:
                if self.restore_file(source_file, destination):
                    success_count += 1
                    print_success(f"{source_file.name} → {destination}")
            else:
                print_warning(f"No mapping found for {source_file.name}")
        
        # Generate report
        self.generate_report(success_count, len(content_files))
    
    def generate_report(self, success_count: int, total_count: int):
        """Generate a detailed restoration report"""
        print_header("📊 Restoration Report")
        
        with open("SMART_RESTORATION_REPORT.md", "w") as f:
            f.write("# 🤖 Smart Content Restoration Report\n\n")
            f.write(f"**Date**: {os.popen('date').read().strip()}\n\n")
            f.write(f"## Summary\n\n")
            f.write(f"- **Total Files Found**: {total_count}\n")
            f.write(f"- **Successfully Restored**: {success_count}\n")
            f.write(f"- **Failed/Skipped**: {total_count - success_count}\n\n")
            
            f.write("## Restoration Details\n\n")
            f.write("| Source File | Destination | Status |\n")
            f.write("|-------------|-------------|--------|\n")
            
            for source, dest, status in self.restoration_log:
                f.write(f"| {source} | {dest} | {status} |\n")
            
            f.write("\n## Module Coverage\n\n")
            
            # Check module coverage
            for i in range(1, 31):
                module_dir = Path(f"modules/module-{i:02d}")
                if module_dir.exists():
                    file_count = len(list(module_dir.rglob("*.*")))
                    status = "✅ Complete" if file_count > 5 else "⚠️  Partial"
                    f.write(f"- Module {i:02d}: {status} ({file_count} files)\n")
        
        print_success(f"Report generated: SMART_RESTORATION_REPORT.md")
        print_info(f"Successfully restored {success_count}/{total_count} files")

def main():
    """Main execution"""
    # Check if we're in the right directory
    if not os.path.exists("README.md") or not os.path.exists("modules"):
        print_error("Please run this script from the workshop root directory")
        return
    
    # Create and run restorer
    restorer = ContentRestorer()
    restorer.restore_all()
    
    print_header("✅ Smart Restoration Complete!")
    print_info("Next steps:")
    print("  1. Review SMART_RESTORATION_REPORT.md")
    print("  2. Check a few modules for accuracy")
    print("  3. Run navigation scripts if needed")
    print("  4. Commit and push changes")

if __name__ == "__main__":
    main()
