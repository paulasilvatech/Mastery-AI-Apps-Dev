#!/usr/bin/env python3
"""
Fix all curly brace issues in MDX files
"""

import re
from pathlib import Path

def fix_curly_braces(content: str) -> str:
    """Fix various curly brace patterns that confuse MDX"""
    
    # Fix quadruple curly braces {{{{ }}}} -> single { }
    content = re.sub(r'\{\{\{\{', '{', content)
    content = re.sub(r'\}\}\}\}', '}', content)
    
    # Fix CSS double curly braces inside HTML templates (these should stay double)
    # Leave CSS rules as {{ }} since they're inside a string literal
    
    return content

def process_file(file_path: Path):
    """Process a single file"""
    try:
        content = file_path.read_text(encoding='utf-8')
        fixed_content = fix_curly_braces(content)
        
        if content != fixed_content:
            file_path.write_text(fixed_content, encoding='utf-8')
            print(f"✅ Fixed curly braces in: {file_path.name}")
            return True
        else:
            print(f"ℹ️  No changes needed in: {file_path.name}")
            return False
        
    except Exception as e:
        print(f"❌ Error processing {file_path}: {e}")
        return False

def main():
    """Fix curly brace issues"""
    
    base_path = Path("/Users/paulasilva/Documents/paulasilvatech/GH-Repos/Mastery-AI-Apps-Dev/docs-platform/docs/modules")
    
    # Files with curly brace issues
    problem_files = [
        "module-22/exercise1-part2.md",
        "module-27/exercise1-overview.md"
    ]
    
    print("🔧 Fixing curly brace issues in MDX files...")
    
    for file_rel_path in problem_files:
        file_path = base_path / file_rel_path
        if file_path.exists():
            process_file(file_path)
        else:
            print(f"⚠️  File not found: {file_path}")
    
    print("\n✅ Done!")

if __name__ == "__main__":
    main()