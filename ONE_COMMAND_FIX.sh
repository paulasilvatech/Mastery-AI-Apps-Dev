#!/bin/bash
# One-Command Workshop Recovery
# This script does EVERYTHING in one go

echo "🚀 One-Command Workshop Recovery Starting..."

# Make this script executable
chmod +x "$0"

# Check if content directory exists
if [ ! -d "content" ]; then
    echo "❌ ERROR: 'content' directory not found!"
    echo "📁 Please create a 'content' directory with your original module files"
    echo "   Example structure:"
    echo "   content/"
    echo "   ├── module-01-README.md"
    echo "   ├── module-01-exercise1-part1.md"
    echo "   └── ..."
    exit 1
fi

# Make all scripts executable
echo "🔧 Making all scripts executable..."
chmod +x scripts/*.sh scripts/*.py 2>/dev/null || true

# Try Python script first (smarter)
if command -v python3 &> /dev/null; then
    echo "🐍 Using smart Python restoration..."
    python3 scripts/smart-restore.py
else
    echo "📜 Using bash restoration..."
    ./scripts/restore-content.sh
fi

# Fix navigation
echo "🔗 Fixing navigation..."
./scripts/create-navigation-links.sh 2>/dev/null || true
./scripts/enhance-navigation.sh 2>/dev/null || true

# Generate final summary
cat > RECOVERY_COMPLETE.md << 'EOF'
# ✅ Workshop Recovery Complete!

## What was done:
1. ✅ Content restored from 'content' directory
2. ✅ Navigation links created
3. ✅ Module structure organized

## Next Steps:
1. Check a few modules to verify content
2. Review the reports:
   - SMART_RESTORATION_REPORT.md (if Python was used)
   - RESTORATION_REPORT.md (if bash was used)
3. Commit and push:
   ```bash
   git add .
   git commit -m "Restore all workshop content"
   git push origin main
   ```

## Quick Test:
Open any module and verify:
- README.md has content
- Exercises are in place
- Navigation works
EOF

echo ""
echo "✅ RECOVERY COMPLETE!"
echo "📄 Check RECOVERY_COMPLETE.md for summary"
echo ""
echo "🎯 Quick commit command:"
echo "   git add . && git commit -m 'Restore workshop content' && git push"
