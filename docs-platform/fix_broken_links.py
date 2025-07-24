#!/usr/bin/env python3
"""
Fix common broken links in the documentation
"""

import os
import re
from pathlib import Path

def fix_links_in_file(filepath):
    """Fix broken links in a single file"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Fix common broken link patterns
    replacements = [
        # Fix module-XX-exerciseY-partZ.md links
        (r'\(module-(\d+)-exercise(\d+)-part(\d+)\.md\)', r'(./exercise\2-part\3)'),
        
        # Fix troubleshooting.md links
        (r'\(troubleshooting\.md\)', r'(/docs/guias/troubleshooting)'),
        
        # Fix README.md links
        (r'\(README\.md\)', r'(./index)'),
        
        # Fix part2.md, part3.md links
        (r'\(part2\.md\)', r'(./exercise1-part2)'),
        (r'\(part3\.md\)', r'(./exercise1-part3)'),
        (r'\(part2-implementation\.md\)', r'(./exercise1-part2)'),
        (r'\(part3-testing\.md\)', r'(./exercise1-part3)'),
        (r'\(part3-integration\.md\)', r'(./exercise1-part3)'),
        
        # Fix ../exerciseX-name/ links
        (r'\(\.\./exercise(\d+)-[\w-]+/\)', r'(/docs/modules/module-{}/exercise\1-overview)'),
        
        # Fix resources/ links
        (r'\(resources/([\w-]+)\.md\)', r'(/docs/resources/\1)'),
        (r'\(resources/([\w-]+)/\)', r'(/docs/resources/\1)'),
        
        # Fix exercises/ links
        (r'\(exercises/exercise(\d+)-[\w-]+/README\.md\)', r'(./exercise\1-overview)'),
        (r'\(exercises/exercise(\d+)-[\w-]+/\)', r'(./exercise\1-overview)'),
        
        # Fix ../../FAQ.md and similar
        (r'\(\.\./\.\./FAQ\.md\)', r'(/docs/guias/faq)'),
        (r'\(\.\./\.\./module-(\d+)-[\w-]+/README\.md\)', r'(/docs/modules/module-\1/)'),
        
        # Fix project-readme.md
        (r'\(project-readme\.md\)', r'(./index)'),
        
        # Fix ./troubleshooting
        (r'\(\./troubleshooting\)', r'(/docs/guias/troubleshooting)'),
        
        # Fix ./partX
        (r'\(\./part2\)', r'(./exercise1-part2)'),
        (r'\(\./part3\)', r'(./exercise1-part3)'),
    ]
    
    for pattern, replacement in replacements:
        content = re.sub(pattern, replacement, content)
    
    # Special handling for module number placeholders
    if 'module-{}' in content:
        # Extract module number from file path
        match = re.search(r'module-(\d+)', str(filepath))
        if match:
            module_num = match.group(1)
            content = content.replace('module-{}', f'module-{module_num}')
    
    # Only write if content changed
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def fix_all_links():
    """Fix links in all markdown files"""
    docs_dir = Path("/Users/paulasilva/Documents/paulasilvatech/GH-Repos/Mastery-AI-Apps-Dev/docs-platform/docs")
    
    fixed_count = 0
    total_count = 0
    
    for md_file in docs_dir.rglob("*.md"):
        total_count += 1
        if fix_links_in_file(md_file):
            fixed_count += 1
            print(f"✅ Fixed links in: {md_file.relative_to(docs_dir)}")
    
    print(f"\n📊 Summary: Fixed {fixed_count} files out of {total_count} total files")

if __name__ == "__main__":
    fix_all_links()