#!/usr/bin/env python3
"""
Final comprehensive MDX fix for all compilation errors
"""

import re
from pathlib import Path

def aggressive_mdx_fix(content: str) -> str:
    """Aggressively fix all MDX issues"""
    
    # Fix all instances of < followed by a number or in comparisons
    content = re.sub(r'<(\d+)', r'Less than \1', content)
    content = re.sub(r'<\s*(\d+)', r'Less than \1', content)
    
    # Fix percentage comparisons
    content = re.sub(r'<\s*0\.(\d+)%', r'Less than 0.\1%', content)
    
    # Fix time comparisons
    content = re.sub(r'<(\d+)ms', r'Less than \1ms', content)
    content = re.sub(r'<(\d+)\s*ms', r'Less than \1ms', content)
    content = re.sub(r'<(\d+)s\b', r'Less than \1s', content)
    content = re.sub(r'<(\d+)\s*second', r'Less than \1 second', content)
    content = re.sub(r'<(\d+)\s*minute', r'Less than \1 minute', content)
    
    # Fix curly braces in code blocks more aggressively
    lines = content.split('\n')
    in_code_block = False
    code_block_lang = None
    new_lines = []
    
    for line in lines:
        # Check for code block start/end
        if line.strip().startswith('```'):
            in_code_block = not in_code_block
            if in_code_block:
                code_block_lang = line.strip()[3:].strip()
            else:
                code_block_lang = None
            new_lines.append(line)
            continue
        
        # If in code block, escape curly braces in certain contexts
        if in_code_block and code_block_lang in ['python', 'javascript', 'typescript', 'json']:
            # Only escape if line contains dictionary-like structures
            if '{' in line and '}' in line and ('":' in line or "': " in line):
                # This looks like a dictionary/JSON, escape the braces
                line = line.replace('{', '{{').replace('}', '}}')
        
        new_lines.append(line)
    
    content = '\n'.join(new_lines)
    
    # Fix any remaining comparison operators outside code blocks
    # But be careful not to break actual code
    lines = content.split('\n')
    new_lines = []
    in_code_block = False
    
    for line in lines:
        if line.strip().startswith('```'):
            in_code_block = not in_code_block
            new_lines.append(line)
            continue
        
        if not in_code_block:
            # Fix comparisons in regular text
            line = re.sub(r'(\s|^)<(\d+)', r'\1Less than \2', line)
            line = re.sub(r'(\s|^)>(\d+)', r'\1Greater than \2', line)
        
        new_lines.append(line)
    
    return '\n'.join(new_lines)

def process_file(file_path: Path):
    """Process a single file"""
    try:
        content = file_path.read_text(encoding='utf-8')
        fixed_content = aggressive_mdx_fix(content)
        
        if content != fixed_content:
            file_path.write_text(fixed_content, encoding='utf-8')
            print(f"✅ Fixed: {file_path.name}")
            return True
        return False
        
    except Exception as e:
        print(f"❌ Error processing {file_path}: {e}")
        return False

def main():
    """Fix all MDX files with known issues"""
    
    base_path = Path("/Users/paulasilva/Documents/paulasilvatech/GH-Repos/Mastery-AI-Apps-Dev/docs-platform/docs/modules")
    
    # Files with known issues
    problem_files = [
        "module-09/exercise3-overview.md",
        "module-10/exercise3-part3.md",
        "module-10/index.md",
        "module-15/exercise2-overview.md",
        "module-15/exercise3-overview.md",
        "module-17/index.md",
        "module-18/exercise2-part2.md",
        "module-18/exercise3-overview.md",
        "module-18/index.md",
        "module-22/exercise1-part2.md",
        "module-25/exercise3-overview.md",
        "module-25/index.md",
        "module-26/index.md",
        "module-27/exercise1-overview.md"
    ]
    
    print("🔧 Fixing known problematic MDX files...")
    fixed_count = 0
    
    for file_rel_path in problem_files:
        file_path = base_path / file_rel_path
        if file_path.exists():
            if process_file(file_path):
                fixed_count += 1
        else:
            print(f"⚠️  File not found: {file_path}")
    
    # Also process all module index files
    print("\n🔍 Processing all module index files...")
    for index_file in base_path.glob("*/index.md"):
        if process_file(index_file):
            fixed_count += 1
    
    # And all exercise files
    print("\n🔍 Processing all exercise files...")
    for exercise_file in base_path.glob("*/exercise*.md"):
        if process_file(exercise_file):
            fixed_count += 1
    
    print(f"\n✅ Fixed {fixed_count} files total!")
    print("\n💡 Run 'npm run build' to verify all issues are resolved.")

if __name__ == "__main__":
    main()