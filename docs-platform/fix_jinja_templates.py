#!/usr/bin/env python3
"""
Fix Jinja2 template syntax in MDX files
"""

import re
from pathlib import Path

def fix_jinja_templates(content: str) -> str:
    """Fix Jinja2 template syntax that conflicts with MDX"""
    
    # Wrap Jinja2 templates in code blocks
    lines = content.split('\n')
    new_lines = []
    in_jinja = False
    
    for i, line in enumerate(lines):
        # Detect start of Jinja2 template
        if ('{%' in line or '{{' in line) and not line.strip().startswith('```'):
            if not in_jinja:
                # Add code block start before Jinja2 content
                new_lines.append('```jinja2')
                in_jinja = True
        
        # Detect end of Jinja2 template section
        elif in_jinja and not ('{%' in line or '{{' in line) and line.strip() and not line.startswith('#') and not line.startswith('-'):
            # Close the code block
            new_lines.append('```')
            in_jinja = False
        
        new_lines.append(line)
    
    # Close any unclosed code block
    if in_jinja:
        new_lines.append('```')
    
    return '\n'.join(new_lines)

def process_file(file_path: Path):
    """Process a single file"""
    try:
        content = file_path.read_text(encoding='utf-8')
        
        # Check if file contains Jinja2 templates
        if '{%' in content or '{{' in content:
            fixed_content = fix_jinja_templates(content)
            
            if content != fixed_content:
                file_path.write_text(fixed_content, encoding='utf-8')
                print(f"✅ Fixed Jinja2 templates in: {file_path.name}")
                return True
        
        return False
        
    except Exception as e:
        print(f"❌ Error processing {file_path}: {e}")
        return False

def main():
    """Fix Jinja2 template files"""
    
    base_path = Path("/Users/paulasilva/Documents/paulasilvatech/GH-Repos/Mastery-AI-Apps-Dev/docs-platform/docs/modules")
    
    # Known problematic files
    problem_files = [
        "module-22/exercise1-part2.md",
        "module-27/exercise1-overview.md"
    ]
    
    print("🔧 Fixing Jinja2 template syntax in MDX files...")
    
    for file_rel_path in problem_files:
        file_path = base_path / file_rel_path
        if file_path.exists():
            process_file(file_path)
        else:
            print(f"⚠️  File not found: {file_path}")
    
    print("\n✅ Done!")

if __name__ == "__main__":
    main()