#!/usr/bin/env python3
"""
Fix final MDX compilation errors in module-22 and module-27
"""

import re
from pathlib import Path

def fix_mdx_compilation_errors(content: str) -> str:
    """Fix specific MDX compilation errors"""
    
    # Fix dictionary syntax in code blocks that might be interpreted as JSX
    # Look for patterns like entity_data = { on line 206-207
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
        
        # If we're in a Python code block and the line contains a dictionary assignment
        if in_code_block and code_lang in ['python', 'py']:
            # Check if this line might cause MDX parsing issues
            if '= {' in line and not line.strip().startswith('#'):
                # Add a comment to help MDX parser
                if not line.strip().endswith('{'):
                    fixed_lines.append(line)
                else:
                    # Split the assignment to avoid MDX confusion
                    indent = len(line) - len(line.lstrip())
                    var_part = line.split('= {')[0]
                    fixed_lines.append(f"{var_part}= {{  # noqa")
            elif re.search(r'^\s*{\s*\w+', line):
                # Lines starting with { followed by identifier (like {self._format...)
                # Wrap in parentheses to avoid JSX interpretation
                indent = len(line) - len(line.lstrip())
                content = line.strip()
                fixed_lines.append(f"{' ' * indent}({content})")
            else:
                fixed_lines.append(line)
        else:
            fixed_lines.append(line)
    
    return '\n'.join(fixed_lines)

def process_file(file_path: Path):
    """Process a single file"""
    try:
        content = file_path.read_text(encoding='utf-8')
        fixed_content = fix_mdx_compilation_errors(content)
        
        if content != fixed_content:
            file_path.write_text(fixed_content, encoding='utf-8')
            print(f"✅ Fixed MDX errors in: {file_path.name}")
            return True
        else:
            print(f"ℹ️  No changes needed in: {file_path.name}")
            return False
        
    except Exception as e:
        print(f"❌ Error processing {file_path}: {e}")
        return False

def main():
    """Fix final MDX compilation errors"""
    
    base_path = Path("/Users/paulasilva/Documents/paulasilvatech/GH-Repos/Mastery-AI-Apps-Dev/docs-platform/docs/modules")
    
    # Files with compilation errors
    problem_files = [
        "module-22/exercise1-part2.md",
        "module-27/exercise1-overview.md"
    ]
    
    print("🔧 Fixing final MDX compilation errors...")
    
    for file_rel_path in problem_files:
        file_path = base_path / file_rel_path
        if file_path.exists():
            process_file(file_path)
        else:
            print(f"⚠️  File not found: {file_path}")
    
    print("\n✅ Done!")

if __name__ == "__main__":
    main()