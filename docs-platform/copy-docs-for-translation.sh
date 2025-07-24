#!/bin/bash

echo "📋 Copying all documentation for translation..."

# Create directories and copy all docs
for locale in "pt-BR" "es"; do
    echo "📁 Processing $locale..."
    
    # Remove existing content
    rm -rf "i18n/$locale/docusaurus-plugin-content-docs/current"
    
    # Copy entire docs structure
    cp -r docs "i18n/$locale/docusaurus-plugin-content-docs/current"
    
    echo "✅ Copied all docs to i18n/$locale/"
done

echo ""
echo "✨ Done! All documentation has been copied for translation."
echo ""
echo "📌 Next steps:"
echo "1. The content is now available in all languages (currently in English)"
echo "2. To translate, edit files in:"
echo "   - i18n/pt-BR/docusaurus-plugin-content-docs/current/"
echo "   - i18n/es/docusaurus-plugin-content-docs/current/"
echo "3. The language selector should now work properly!"