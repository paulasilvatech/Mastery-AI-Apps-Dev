#!/usr/bin/env python3
"""
Fix f-string curly braces in Python code blocks within MDX
"""

import re
from pathlib import Path

def fix_fstring_braces(content: str) -> str:
    """Fix f-string braces that confuse MDX parser"""
    
    lines = content.split('\n')
    fixed_lines = []
    in_code_block = False
    code_lang = None
    in_fstring = False
    
    for i, line in enumerate(lines):
        # Track code blocks
        if line.strip().startswith('```'):
            if not in_code_block:
                in_code_block = True
                code_lang = line.strip()[3:].strip()
            else:
                in_code_block = False
                code_lang = None
                in_fstring = False
        
        # If we're in a Python code block
        if in_code_block and code_lang in ['python', 'py']:
            # Check if we're starting an f-string
            if 'prompt = f"""' in line:
                in_fstring = True
            elif '"""' in line and in_fstring and 'prompt = f"""' not in line:
                in_fstring = False
            
            # If we're inside an f-string, double the curly braces
            if in_fstring and '{' in line and not line.strip().startswith('#'):
                # Don't double braces that are already doubled
                if '{{' not in line:
                    # Replace single braces with double braces
                    line = re.sub(r'\{([^{])', r'{{\1', line)
                    line = re.sub(r'([^}])\}', r'\1}}', line)
        
        fixed_lines.append(line)
    
    return '\n'.join(fixed_lines)

def process_file(file_path: Path):
    """Process a single file"""
    try:
        content = file_path.read_text(encoding='utf-8')
        fixed_content = fix_fstring_braces(content)
        
        if content != fixed_content:
            file_path.write_text(fixed_content, encoding='utf-8')
            print(f"✅ Fixed f-string braces in: {file_path.name}")
            return True
        else:
            print(f"ℹ️  No changes needed in: {file_path.name}")
            return False
        
    except Exception as e:
        print(f"❌ Error processing {file_path}: {e}")
        return False

def main():
    """Fix f-string brace issues"""
    
    base_path = Path("/Users/paulasilva/Documents/paulasilvatech/GH-Repos/Mastery-AI-Apps-Dev/docs-platform/docs/modules")
    
    # File with f-string issues
    problem_file = "module-27/exercise1-overview.md"
    
    print("🔧 Fixing f-string braces in MDX files...")
    
    file_path = base_path / problem_file
    if file_path.exists():
        process_file(file_path)
    else:
        print(f"⚠️  File not found: {file_path}")
    
    print("\n✅ Done!")

if __name__ == "__main__":
    main()