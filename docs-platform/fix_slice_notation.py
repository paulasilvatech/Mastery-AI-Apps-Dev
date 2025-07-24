#!/usr/bin/env python3
"""
Fix Python slice notation [:n] to [0:n] in MDX files
"""

import re
from pathlib import Path

def fix_slice_notation(content: str) -> str:
    """Fix Python slice notation that confuses MDX parser"""
    
    # Replace [:number] with [0:number]
    content = re.sub(r'\[:(\d+)\]', r'[0:\1]', content)
    
    return content

def main():
    """Fix slice notation in module-27"""
    
    file_path = Path("/Users/paulasilva/Documents/paulasilvatech/GH-Repos/Mastery-AI-Apps-Dev/docs-platform/docs/modules/module-27/exercise1-overview.md")
    
    print("🔧 Fixing Python slice notation in MDX files...")
    
    if file_path.exists():
        content = file_path.read_text(encoding='utf-8')
        fixed_content = fix_slice_notation(content)
        
        if content != fixed_content:
            file_path.write_text(fixed_content, encoding='utf-8')
            print(f"✅ Fixed slice notation in: {file_path.name}")
        else:
            print(f"ℹ️  No changes needed")
    else:
        print(f"❌ File not found: {file_path}")

if __name__ == "__main__":
    main()