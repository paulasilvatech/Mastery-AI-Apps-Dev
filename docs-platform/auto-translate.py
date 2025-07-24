#!/usr/bin/env python3
"""
Automatic translation script for Docusaurus i18n
Translates all documentation from English to Portuguese-BR and Spanish
"""

import os
import json
import shutil
from pathlib import Path
from googletrans import Googletrans

# Initialize translator
translator = Googletrans()

# Define language mappings
LOCALES = {
    'pt-BR': 'pt',
    'es': 'es'
}

def translate_text(text, target_lang):
    """Translate text to target language"""
    try:
        if not text or text.strip() == '':
            return text
        
        # Don't translate code blocks
        if text.startswith('```') and text.endswith('```'):
            return text
            
        result = translator.translate(text, dest=target_lang)
        return result.text
    except Exception as e:
        print(f"Translation error: {e}")
        return text

def translate_json_file(file_path, target_lang):
    """Translate JSON file content"""
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    translated_data = {}
    for key, value in data.items():
        if isinstance(value, dict) and 'message' in value:
            translated_data[key] = {
                'message': translate_text(value['message'], target_lang),
                'description': value.get('description', '')
            }
        elif isinstance(value, str):
            translated_data[key] = translate_text(value, target_lang)
        else:
            translated_data[key] = value
    
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(translated_data, f, ensure_ascii=False, indent=2)

def translate_markdown_file(source_file, target_file, target_lang):
    """Translate markdown file content"""
    with open(source_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Split content into lines
    lines = content.split('\n')
    translated_lines = []
    
    in_code_block = False
    for line in lines:
        # Check for code blocks
        if line.strip().startswith('```'):
            in_code_block = not in_code_block
            translated_lines.append(line)
        elif in_code_block:
            # Don't translate code
            translated_lines.append(line)
        elif line.strip().startswith('---') and len(translated_lines) < 10:
            # Don't translate frontmatter
            translated_lines.append(line)
        elif line.strip() == '' or line.strip().startswith('#'):
            # Translate headers but preserve formatting
            if line.strip().startswith('#'):
                header_level = len(line) - len(line.lstrip('#'))
                header_text = line.lstrip('#').strip()
                if header_text:
                    translated_header = translate_text(header_text, target_lang)
                    translated_lines.append('#' * header_level + ' ' + translated_header)
                else:
                    translated_lines.append(line)
            else:
                translated_lines.append(line)
        else:
            # Translate regular text
            translated_lines.append(translate_text(line, target_lang))
    
    # Create target directory if it doesn't exist
    os.makedirs(os.path.dirname(target_file), exist_ok=True)
    
    with open(target_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(translated_lines))

def main():
    """Main translation function"""
    print("🌐 Starting automatic translation...")
    
    # Translate UI strings
    for locale, lang_code in LOCALES.items():
        print(f"\n📝 Translating UI strings to {locale}...")
        
        # Translate JSON files
        json_files = [
            f'i18n/{locale}/code.json',
            f'i18n/{locale}/docusaurus-theme-classic/navbar.json',
            f'i18n/{locale}/docusaurus-theme-classic/footer.json',
            f'i18n/{locale}/docusaurus-plugin-content-docs/current.json'
        ]
        
        for json_file in json_files:
            if os.path.exists(json_file):
                print(f"  Translating {json_file}...")
                translate_json_file(json_file, lang_code)
    
    # Copy and translate documentation
    for locale, lang_code in LOCALES.items():
        print(f"\n📚 Translating documentation to {locale}...")
        
        # Source and target directories
        source_dir = 'docs'
        target_dir = f'i18n/{locale}/docusaurus-plugin-content-docs/current'
        
        # Remove existing translations
        if os.path.exists(target_dir):
            shutil.rmtree(target_dir)
        
        # Copy directory structure
        shutil.copytree(source_dir, target_dir)
        
        # Translate all markdown files
        for md_file in Path(target_dir).rglob('*.md'):
            print(f"  Translating {md_file.name}...")
            source_file = str(md_file).replace(target_dir, source_dir)
            translate_markdown_file(source_file, str(md_file), lang_code)
        
        for mdx_file in Path(target_dir).rglob('*.mdx'):
            print(f"  Translating {mdx_file.name}...")
            source_file = str(mdx_file).replace(target_dir, source_dir)
            translate_markdown_file(source_file, str(mdx_file), lang_code)
    
    print("\n✅ Translation completed!")
    print("\n📌 Next steps:")
    print("1. Review translations for accuracy")
    print("2. Run 'npm start' to test English version")
    print("3. Run 'npm run start:pt-BR' to test Portuguese version")
    print("4. Run 'npm run start:es' to test Spanish version")

if __name__ == "__main__":
    main()