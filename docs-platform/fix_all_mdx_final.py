#!/usr/bin/env python3
"""
Final comprehensive fix for all MDX issues in module-27
"""

import re
from pathlib import Path

def fix_module_27_comprehensively(file_path: Path):
    """Fix all MDX parsing issues in module-27"""
    
    content = file_path.read_text(encoding='utf-8')
    
    # Replace all f-strings with regular string concatenation to avoid MDX parsing issues
    # This is a more aggressive approach but ensures compatibility
    
    # Fix all prompt = f""" patterns
    content = re.sub(
        r'prompt = f"""(.*?)"""',
        lambda m: 'prompt = (' + convert_fstring_to_concat(m.group(1)) + ')',
        content,
        flags=re.DOTALL
    )
    
    # Fix all json.dumps calls with f-strings
    content = re.sub(
        r'\{json\.dumps\(([^)]+)\)\[:\d+\]\}',
        r'" + json.dumps(\1)[:1000] + "',
        content
    )
    
    # Fix any remaining single { or } in f-strings that might cause issues
    lines = content.split('\n')
    fixed_lines = []
    in_python_block = False
    
    for line in lines:
        if line.strip().startswith('```python') or line.strip().startswith('```py'):
            in_python_block = True
        elif line.strip() == '```':
            in_python_block = False
        
        if in_python_block:
            # Fix dictionary literals in certain contexts
            if 'messages=[' in line or 'procedure.statements.append(' in line:
                # Already handled by previous fixes
                pass
            # Fix any f-string interpolations that might have issues
            elif 'f"' in line and '{' in line:
                # Convert problematic f-strings to concatenation
                line = re.sub(r'f"([^"]*)\{([^}]+)\}([^"]*)"', r'"\1" + str(\2) + "\3"', line)
        
        fixed_lines.append(line)
    
    return '\n'.join(fixed_lines)

def convert_fstring_to_concat(fstring_content):
    """Convert f-string content to string concatenation"""
    lines = fstring_content.strip().split('\n')
    parts = []
    
    for line in lines:
        if '{' in line and '}' in line:
            # Extract the parts before, inside, and after {}
            pattern = r'([^{]*)\{([^}]+)\}(.*)'
            match = re.match(pattern, line)
            if match:
                before, expr, after = match.groups()
                parts.append(f'"{before}" + str({expr}) + "{after}\\n"')
            else:
                parts.append(f'"{line}\\n"')
        else:
            parts.append(f'"{line}\\n"')
    
    return '\n    + '.join(parts)

def main():
    """Fix all MDX issues"""
    
    file_path = Path("/Users/paulasilva/Documents/paulasilvatech/GH-Repos/Mastery-AI-Apps-Dev/docs-platform/docs/modules/module-27/exercise1-overview.md")
    
    if not file_path.exists():
        print(f"❌ File not found: {file_path}")
        return
    
    print("🔧 Applying comprehensive MDX fixes to module-27...")
    
    try:
        # Read current content
        original_content = file_path.read_text(encoding='utf-8')
        
        # Apply fixes
        fixed_content = fix_module_27_comprehensively(file_path)
        
        # Write back
        file_path.write_text(fixed_content, encoding='utf-8')
        
        print("✅ Applied comprehensive fixes to module-27")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()