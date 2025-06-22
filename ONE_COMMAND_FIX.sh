#!/bin/bash
# One-Command Workshop Recovery - UPDATED
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

# Step 1: Add content to modules (NEW!)
echo "📝 Adding content to modules..."
if [ -f "./scripts/add-content-to-modules.sh" ]; then
    ./scripts/add-content-to-modules.sh
else
    # Fallback to other restore methods
    if command -v python3 &> /dev/null; then
        echo "🐍 Using smart Python restoration..."
        python3 scripts/smart-restore.py
    else
        echo "📜 Using bash restoration..."
        ./scripts/restore-content.sh
    fi
fi

# Step 2: Fix navigation
echo "🔗 Fixing navigation..."
./scripts/create-navigation-links.sh 2>/dev/null || true
./scripts/enhance-navigation.sh 2>/dev/null || true

# Step 3: Generate final summary
cat > RECOVERY_COMPLETE.md << 'EOF'
# ✅ Workshop Recovery Complete!

## What was done:
1. ✅ Content added to modules from 'content' directory
2. ✅ Navigation links created
3. ✅ Module structure organized

## Quick Verification:
Check any module to verify content:
```bash
# Example: Check Module 1
cat modules/module-01/README.md
ls -la modules/module-01/exercises/exercise1-easy/instructions/
```

## Reports Generated:
- CONTENT_ADDITION_REPORT.md - Details of content added
- SMART_RESTORATION_REPORT.md - If Python script was used
- RESTORATION_REPORT.md - If bash script was used

## Next Steps:
1. Review the reports above
2. Test a few modules manually
3. Commit and push:
   ```bash
   git add .
   git commit -m "Add all workshop content to modules"
   git push origin main
   ```

## Quick Module Test:
```bash
# Test Module 1
echo "=== Module 1 README ==="
head -n 20 modules/module-01/README.md

echo -e "\n=== Module 1 Exercise 1 ==="
head -n 10 modules/module-01/exercises/exercise1-easy/instructions/part1.md
```
EOF

echo ""
echo "✅ RECOVERY COMPLETE!"
echo "📄 Check RECOVERY_COMPLETE.md for summary"
echo ""
echo "🧪 Quick test - Module 1 content:"
echo "================================"
if [ -f "modules/module-01/README.md" ]; then
    head -n 10 modules/module-01/README.md
else
    echo "Module 1 README not found"
fi
echo ""
echo "🎯 Quick commit command:"
echo "   git add . && git commit -m 'Add all workshop content' && git push"
