#!/usr/bin/env python3
"""
Fix all MDX compilation errors comprehensively
"""

import re
from pathlib import Path

def fix_mdx_comprehensive(content: str) -> str:
    """Fix all MDX issues comprehensively"""
    
    # Fix all HTML entities in JSX context
    # Replace &gt; with > and &lt; with < when they appear in className or similar
    content = re.sub(r'<div className="([^"]*?)&gt;([^"]*?)"', r'<div className="\1>\2"', content)
    content = re.sub(r'<div className="([^"]*?)&lt;([^"]*?)"', r'<div className="\1<\2"', content)
    content = re.sub(r'<span className="([^"]*?)&gt;([^"]*?)"', r'<span className="\1>\2"', content)
    content = re.sub(r'<span className="([^"]*?)&lt;([^"]*?)"', r'<span className="\1<\2"', content)
    
    # Fix any remaining HTML entities within JSX tags
    def fix_jsx_tag(match):
        tag_content = match.group(0)
        # Replace entities within the tag
        tag_content = tag_content.replace('&gt;', '>')
        tag_content = tag_content.replace('&lt;', '<')
        tag_content = tag_content.replace('&amp;', '&')
        return tag_content
    
    # Fix JSX tags that might have entities
    content = re.sub(r'<[^>]+>', fix_jsx_tag, content)
    
    # Fix blockquotes that were converted to entities
    content = re.sub(r'^&gt;\s+', '> ', content, flags=re.MULTILINE)
    
    # Fix code blocks that might have entities
    def fix_code_block(match):
        code_content = match.group(2)
        # Keep entities in code blocks as they should be displayed
        return match.group(1) + code_content + match.group(3)
    
    content = re.sub(r'(```[^\n]*\n)(.*?)(```)', fix_code_block, content, flags=re.DOTALL)
    
    # Fix inline code that might have entities
    def fix_inline_code(match):
        return match.group(0)  # Keep inline code as is
    
    content = re.sub(r'`[^`]+`', fix_inline_code, content)
    
    # Fix problematic arrow functions in JSX
    content = re.sub(r'->\s*([A-Za-z])', r'→ \1', content)
    
    # Remove duplicate headers
    lines = content.split('\n')
    new_lines = []
    prev_line = None
    
    for line in lines:
        # Skip duplicate headers
        if line.startswith('#') and prev_line and line == prev_line:
            continue
        new_lines.append(line)
        prev_line = line
    
    content = '\n'.join(new_lines)
    
    return content

def process_file(file_path: Path):
    """Process a single file"""
    try:
        content = file_path.read_text(encoding='utf-8')
        original_content = content
        fixed_content = fix_mdx_comprehensive(content)
        
        if original_content != fixed_content:
            file_path.write_text(fixed_content, encoding='utf-8')
            print(f"✅ Fixed: {file_path.name}")
            # Show what was changed
            if '&gt;' in original_content and '&gt;' not in fixed_content:
                print(f"   - Fixed HTML entities in JSX")
            if '#' in original_content and content.count('#') != fixed_content.count('#'):
                print(f"   - Removed duplicate headers")
        
    except Exception as e:
        print(f"❌ Error processing {file_path}: {e}")

def main():
    """Fix all MDX files"""
    
    base_path = Path("/Users/paulasilva/Documents/paulasilvatech/GH-Repos/Mastery-AI-Apps-Dev/docs-platform")
    
    print("🔍 Fixing all MDX files...")
    
    # Process all markdown files
    fixed_count = 0
    for md_file in base_path.glob("docs/**/*.md"):
        process_file(md_file)
        fixed_count += 1
    
    print(f"\n✅ Processed {fixed_count} files!")
    print("\n💡 Run 'npm run build' to verify all issues are fixed.")

if __name__ == "__main__":
    main()