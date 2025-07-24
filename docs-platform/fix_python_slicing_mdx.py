#!/usr/bin/env python3
"""
Fix Python slicing syntax in MDX files that's being misinterpreted as JSX
"""

import re
from pathlib import Path

def fix_python_slicing(content: str) -> str:
    """Fix Python slicing syntax that confuses MDX parser"""
    
    lines = content.split('\n')
    fixed_lines = []
    in_code_block = False
    code_lang = None
    
    for i, line in enumerate(lines):
        # Track code blocks
        if line.strip().startswith('```'):
            if not in_code_block:
                in_code_block = True
                code_lang = line.strip()[3:].strip()
            else:
                in_code_block = False
                code_lang = None
        
        # If we're in a Python code block and inside an f-string
        if in_code_block and code_lang in ['python', 'py']:
            # Look for patterns like {something[x:y]} in f-strings
            if '{' in line and '[' in line and ':' in line and ']' in line:
                # This is inside an f-string with slicing - escape it
                # Replace the problematic slicing with a method call
                line = line.replace('program.data_items[:20]', 'program.data_items[0:20]')
                line = line.replace('program.procedures)', 'program.procedures')
        
        fixed_lines.append(line)
    
    return '\n'.join(fixed_lines)

def process_file(file_path: Path):
    """Process a single file"""
    try:
        content = file_path.read_text(encoding='utf-8')
        fixed_content = fix_python_slicing(content)
        
        if content != fixed_content:
            file_path.write_text(fixed_content, encoding='utf-8')
            print(f"✅ Fixed Python slicing syntax in: {file_path.name}")
            return True
        else:
            print(f"ℹ️  No changes needed in: {file_path.name}")
            return False
        
    except Exception as e:
        print(f"❌ Error processing {file_path}: {e}")
        return False

def main():
    """Fix Python slicing syntax issues"""
    
    base_path = Path("/Users/paulasilva/Documents/paulasilvatech/GH-Repos/Mastery-AI-Apps-Dev/docs-platform/docs/modules")
    
    # File with Python slicing issues
    problem_file = "module-27/exercise1-overview.md"
    
    print("🔧 Fixing Python slicing syntax in MDX files...")
    
    file_path = base_path / problem_file
    if file_path.exists():
        process_file(file_path)
    else:
        print(f"⚠️  File not found: {file_path}")
    
    print("\n✅ Done!")

if __name__ == "__main__":
    main()