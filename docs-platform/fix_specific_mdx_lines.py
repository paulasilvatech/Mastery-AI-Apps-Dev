#!/usr/bin/env python3
"""
Fix specific MDX lines causing compilation errors
"""

from pathlib import Path

def fix_module_22_line_207(file_path: Path):
    """Fix line 207 in module-22/exercise1-part2.md"""
    content = file_path.read_text(encoding='utf-8')
    lines = content.split('\n')
    
    # The error is at line 207 (0-indexed 206)
    if len(lines) > 206 and "'name': entity.name," in lines[206]:
        # This line is inside a Python dictionary in a code block, should be fine
        # But let's check context
        print(f"Line 207: {lines[206]}")
        print(f"Line 206: {lines[205]}")
        print(f"Line 208: {lines[207]}")
    
    return content

def fix_module_27_line_739(file_path: Path):
    """Fix line 739 in module-27/exercise1-overview.md"""
    content = file_path.read_text(encoding='utf-8')
    lines = content.split('\n')
    
    # The error is at line 739 (0-indexed 738)
    if len(lines) > 738:
        # Line contains: {self._format_data_items(program.data_items[:20])}
        # This is inside a Python f-string but MDX is trying to parse it as JSX
        
        # Find the problematic section
        for i in range(730, min(750, len(lines))):
            if '{self._format_data_items' in lines[i] or '{self._format_procedures' in lines[i]:
                # These are inside a triple-quoted string in Python
                # Need to escape or modify to prevent MDX parsing
                lines[i] = lines[i].replace('{self._format_data_items(program.data_items[:20])}', 
                                          '{{self._format_data_items(program.data_items[:20])}}')
                lines[i] = lines[i].replace('{self._format_procedures(program.procedures)}',
                                          '{{self._format_procedures(program.procedures)}}')
                print(f"Fixed line {i+1}: {lines[i]}")
    
    return '\n'.join(lines)

def main():
    """Fix specific MDX compilation errors"""
    
    base_path = Path("/Users/paulasilva/Documents/paulasilvatech/GH-Repos/Mastery-AI-Apps-Dev/docs-platform/docs/modules")
    
    print("🔧 Fixing specific MDX compilation errors...")
    
    # Fix module-27 (this is the main issue)
    file_path = base_path / "module-27/exercise1-overview.md"
    if file_path.exists():
        fixed_content = fix_module_27_line_739(file_path)
        file_path.write_text(fixed_content, encoding='utf-8')
        print("✅ Fixed module-27/exercise1-overview.md")
    
    # Check module-22
    file_path = base_path / "module-22/exercise1-part2.md"
    if file_path.exists():
        content = fix_module_22_line_207(file_path)
        # No changes needed for module-22
        print("ℹ️  module-22/exercise1-part2.md appears correct")
    
    print("\n✅ Done!")

if __name__ == "__main__":
    main()