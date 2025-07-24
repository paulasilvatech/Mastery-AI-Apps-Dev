#!/usr/bin/env python3
"""
Fix MDX compilation errors in the documentation
"""

import re
from pathlib import Path

def fix_mdx_content(content: str) -> str:
    """Fix common MDX issues"""
    
    # Fix HTML tags that start with numbers
    # Replace <1> with &lt;1&gt; etc
    content = re.sub(r'<(\d+)>', r'&lt;\1&gt;', content)
    
    # Fix closing tags
    content = re.sub(r'</(\d+)>', r'&lt;/\1&gt;', content)
    
    # Fix expressions in JSX that might cause issues
    # Look for patterns like {expression}
    content = re.sub(r'\{(\d+[^}]*)\}', r'{\`\1\`}', content)
    
    # Escape standalone < and > that might be interpreted as JSX
    content = re.sub(r'(?<!\w)<(?!\w|/)', '&lt;', content)
    content = re.sub(r'(?<!\w)>(?!\w)', '&gt;', content)
    
    return content

def process_file(file_path: Path):
    """Process a single file"""
    try:
        content = file_path.read_text(encoding='utf-8')
        fixed_content = fix_mdx_content(content)
        
        if content != fixed_content:
            file_path.write_text(fixed_content, encoding='utf-8')
            print(f"✅ Fixed: {file_path}")
        
    except Exception as e:
        print(f"❌ Error processing {file_path}: {e}")

def main():
    """Fix MDX errors in specific files"""
    
    problem_files = [
        "docs/modules/module-16/exercise3-overview.md",
        "docs/modules/module-17/exercise2-part1.md", 
        "docs/modules/module-18/exercise3-overview.md",
        "docs/modules/module-19/exercise2-overview.md",
        "docs/modules/module-26/exercise2-overview.md",
        "docs/modules/module-27/exercise1-overview.md",
        "docs/modules/module-28/index.md",
        "docs/modules/module-29/exercise1-part3.md",
        "docs/modules/module-29/exercise2-part3.md",
        "docs/modules/module-29/index.md"
    ]
    
    base_path = Path("/Users/paulasilva/Documents/paulasilvatech/GH-Repos/Mastery-AI-Apps-Dev/docs-platform")
    
    for file_name in problem_files:
        file_path = base_path / file_name
        if file_path.exists():
            process_file(file_path)
        else:
            print(f"⚠️  File not found: {file_path}")
    
    # Also process all MDX files to catch any other issues
    print("\n🔍 Scanning all MDX files for potential issues...")
    for mdx_file in base_path.glob("docs/**/*.md"):
        process_file(mdx_file)
    
    print("\n✅ MDX error fixing complete!")

if __name__ == "__main__":
    main()