#!/usr/bin/env python3
"""
Convert all 30 modules from source to Docusaurus format
"""

import os
import re
import shutil
from pathlib import Path
from typing import Dict, List, Tuple

# Paths
SOURCE_BASE = Path("/Users/paulasilva/Documents/paulasilvatech/GH-Repos/Mastery-AI-Apps-Dev/modules")
DOCS_BASE = Path("/Users/paulasilva/Documents/paulasilvatech/GH-Repos/Mastery-AI-Apps-Dev/docs-platform/docs/modules")

# Module metadata
MODULE_TRACKS = {
    range(1, 6): ("🟢 Fundamentals", "beginner"),
    range(6, 11): ("🔵 Intermediate", "intermediate"),
    range(11, 16): ("🟠 Advanced", "advanced"),
    range(16, 21): ("🔴 Enterprise", "enterprise"),
    range(21, 26): ("🟣 AI Agents", "ai-agents"),
    range(26, 29): ("⭐ Enterprise Mastery", "mastery"),
    range(29, 31): ("🏆 Mastery Validation", "validation")
}

def get_track_info(module_num: int) -> Tuple[str, str]:
    """Get track name and difficulty for a module"""
    for range_obj, (track, difficulty) in MODULE_TRACKS.items():
        if module_num in range_obj:
            return track, difficulty
    return "📚 General", "general"

def clean_content_for_docusaurus(content: str) -> str:
    """Clean and prepare content for Docusaurus"""
    # Remove any existing frontmatter
    content = re.sub(r'^---\n.*?\n---\n', '', content, flags=re.DOTALL)
    
    # Fix image paths
    content = re.sub(r'!\[(.*?)\]\(\./(.*?)\)', r'![\1](/img/modules/\2)', content)
    
    # Fix internal links
    content = re.sub(r'\]\(\./(.*?)\.md\)', r'](./\1)', content)
    
    return content.strip()

def create_frontmatter(module_num: int, title: str, description: str, sidebar_position: int = 1) -> str:
    """Create Docusaurus frontmatter"""
    track, difficulty = get_track_info(module_num)
    
    return f"""---
sidebar_position: {sidebar_position}
title: "{title}"
description: "{description}"
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';
"""

def process_readme(module_num: int, source_path: Path, dest_path: Path):
    """Process module README file"""
    if not source_path.exists():
        print(f"  ⚠️  README not found for module {module_num}")
        return
    
    content = source_path.read_text(encoding='utf-8')
    
    # Extract title and description
    title_match = re.search(r'^#\s+(.+?)$', content, re.MULTILINE)
    title = title_match.group(1) if title_match else f"Module {module_num:02d}"
    
    # Get first paragraph as description
    desc_match = re.search(r'^#+.*?\n\n(.+?)(?:\n\n|$)', content, re.MULTILINE | re.DOTALL)
    description = desc_match.group(1).strip() if desc_match else "Workshop module"
    description = re.sub(r'\s+', ' ', description)[:160]  # Clean and limit length
    
    # Clean content
    cleaned_content = clean_content_for_docusaurus(content)
    
    # Add frontmatter
    frontmatter = create_frontmatter(module_num, title, description)
    
    # Add module header
    track, difficulty = get_track_info(module_num)
    header = f"""
# {title}

<div className="module-header">
  <div className="module-info">
    <span className="difficulty-badge {difficulty}">{track}</span>
    <span className="duration-badge">⏱️ 3 hours</span>
  </div>
</div>

"""
    
    # Write file
    final_content = frontmatter + header + cleaned_content
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    dest_path.write_text(final_content, encoding='utf-8')
    print(f"  ✅ Created index.md")

def process_exercise_files(module_num: int, source_dir: Path, dest_dir: Path):
    """Process all exercise files for a module"""
    exercise_patterns = [
        (r'exercise(\d+)-part(\d+)\.md', 'exercise{}-part{}.md'),
        (r'exercise(\d+)\.md', 'exercise{}-overview.md'),
        (r'module-\d+-exercise(\d+)-part(\d+)\.md', 'exercise{}-part{}.md'),
        (r'module-\d+-exercise(\d+)\.md', 'exercise{}-overview.md'),
    ]
    
    processed_files = set()
    sidebar_position = 2
    
    for file_path in source_dir.glob('*.md'):
        if file_path.name == 'README.md':
            continue
            
        # Try to match exercise patterns
        for pattern, output_format in exercise_patterns:
            match = re.match(pattern, file_path.name)
            if match:
                groups = match.groups()
                if len(groups) == 2:
                    exercise_num, part_num = groups
                    dest_name = output_format.format(exercise_num, part_num)
                    title = f"Exercise {exercise_num}: Part {part_num}"
                else:
                    exercise_num = groups[0]
                    dest_name = output_format.format(exercise_num)
                    title = f"Exercise {exercise_num}: Overview"
                
                # Read and process content
                content = file_path.read_text(encoding='utf-8')
                cleaned_content = clean_content_for_docusaurus(content)
                
                # Extract description from content
                desc_match = re.search(r'^#+.*?\n\n(.+?)(?:\n\n|$)', content, re.MULTILINE | re.DOTALL)
                description = desc_match.group(1).strip() if desc_match else f"Exercise {exercise_num}"
                description = re.sub(r'\s+', ' ', description)[:160]
                
                # Create frontmatter
                frontmatter = f"""---
sidebar_position: {sidebar_position}
title: "{title}"
description: "{description}"
---

"""
                
                # Write file
                dest_path = dest_dir / dest_name
                dest_path.write_text(frontmatter + cleaned_content, encoding='utf-8')
                processed_files.add(dest_name)
                sidebar_position += 1
                print(f"  ✅ Created {dest_name}")
                break
    
    # Ensure we have all exercise parts (3 exercises x 3 parts each)
    for exercise_num in range(1, 4):
        for part_num in range(1, 4):
            expected_file = f"exercise{exercise_num}-part{part_num}.md"
            if expected_file not in processed_files:
                # Create a placeholder
                content = f"""---
sidebar_position: {sidebar_position}
title: "Exercise {exercise_num}: Part {part_num}"
description: "Complete this exercise to practice Module {module_num:02d} concepts"
---

# Exercise {exercise_num}: Part {part_num}

## 🎯 Objectives

This exercise will help you practice the concepts learned in Module {module_num:02d}.

## 📝 Coming Soon

This exercise content is being prepared. Please check back soon or refer to the main module materials.

## 🚀 In the Meantime

- Review the module README
- Practice with the available exercises
- Join our community discussions for help
"""
                dest_path = dest_dir / expected_file
                dest_path.write_text(content, encoding='utf-8')
                sidebar_position += 1
                print(f"  ⚠️  Created placeholder for {expected_file}")

def process_prerequisites(module_num: int, source_dir: Path, dest_dir: Path):
    """Process prerequisites file"""
    source_files = ['prerequisites.md', f'module-{module_num:02d}-prerequisites.md']
    
    for source_name in source_files:
        source_path = source_dir / source_name
        if source_path.exists():
            content = source_path.read_text(encoding='utf-8')
            cleaned_content = clean_content_for_docusaurus(content)
            
            frontmatter = f"""---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module {module_num:02d}"
---

"""
            dest_path = dest_dir / 'prerequisites.md'
            dest_path.write_text(frontmatter + cleaned_content, encoding='utf-8')
            print(f"  ✅ Created prerequisites.md")
            return
    
    # Create default prerequisites
    content = f"""---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module {module_num:02d}"
---

# Prerequisites for Module {module_num:02d}

## Required Knowledge

- Completion of previous modules
- Basic programming knowledge
- Familiarity with command line

## Technical Requirements

- GitHub account with Copilot access
- VS Code or compatible IDE
- Stable internet connection

## Setup Instructions

Please refer to the workshop setup guide for detailed instructions.
"""
    dest_path = dest_dir / 'prerequisites.md'
    dest_path.write_text(content, encoding='utf-8')
    print(f"  ⚠️  Created default prerequisites.md")

def create_category_file(module_num: int, dest_dir: Path):
    """Create _category_.json for module"""
    track, _ = get_track_info(module_num)
    
    category_data = f"""{{
  "label": "Module {module_num:02d}",
  "position": {module_num},
  "link": {{
    "type": "doc",
    "id": "modules/module-{module_num:02d}/index"
  }},
  "customProps": {{
    "track": "{track}",
    "duration": "3 hours"
  }}
}}
"""
    
    category_path = dest_dir / '_category_.json'
    category_path.write_text(category_data, encoding='utf-8')
    print(f"  ✅ Created _category_.json")

def process_module(module_num: int):
    """Process a single module"""
    print(f"\n📦 Processing Module {module_num:02d}...")
    
    source_dir = SOURCE_BASE / f"module-{module_num:02d}"
    dest_dir = DOCS_BASE / f"module-{module_num:02d}"
    
    if not source_dir.exists():
        print(f"  ❌ Source directory not found: {source_dir}")
        return
    
    # Create destination directory
    dest_dir.mkdir(parents=True, exist_ok=True)
    
    # Process README
    readme_path = source_dir / "README.md"
    index_path = dest_dir / "index.md"
    process_readme(module_num, readme_path, index_path)
    
    # Process exercise files
    process_exercise_files(module_num, source_dir, dest_dir)
    
    # Process prerequisites
    process_prerequisites(module_num, source_dir, dest_dir)
    
    # Create category file
    create_category_file(module_num, dest_dir)
    
    # Copy any additional resources
    for resource_dir in ['resources', 'images', 'diagrams']:
        source_resource = source_dir / resource_dir
        if source_resource.exists() and source_resource.is_dir():
            dest_resource = dest_dir / resource_dir
            if dest_resource.exists():
                shutil.rmtree(dest_resource)
            shutil.copytree(source_resource, dest_resource)
            print(f"  ✅ Copied {resource_dir}/")

def main():
    """Main conversion process"""
    print("🚀 Starting module conversion process...")
    print(f"📂 Source: {SOURCE_BASE}")
    print(f"📂 Destination: {DOCS_BASE}")
    
    # Ensure destination exists
    DOCS_BASE.mkdir(parents=True, exist_ok=True)
    
    # Process all 30 modules
    for module_num in range(1, 31):
        process_module(module_num)
    
    print("\n✅ Conversion complete!")
    print("\n📋 Next steps:")
    print("1. Review the converted modules")
    print("2. Update the sidebars.ts configuration")
    print("3. Test the documentation site")
    print("4. Fix any broken links or formatting issues")

if __name__ == "__main__":
    main()