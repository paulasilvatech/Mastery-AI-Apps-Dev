#!/bin/bash

echo "=== Fixing Docusaurus ChunkLoadError ==="
echo ""

# Stop any running docusaurus processes
echo "1. Stopping any running Docusaurus processes..."
pkill -f docusaurus || echo "No running processes found"
pkill -f "npm.*start" || echo "No npm start processes found"
sleep 2
echo ""

# Clear all caches and temporary files
echo "2. Clearing Docusaurus cache..."
npm run clear || echo "Failed to clear cache"
echo ""

# Remove .docusaurus directory
echo "3. Removing .docusaurus build directory..."
rm -rf .docusaurus
echo ""

# Remove node_modules and reinstall
echo "4. Reinstalling dependencies..."
echo "This may take a few minutes..."
rm -rf node_modules package-lock.json
npm install
echo ""

# Clear browser cache reminder
echo "5. Browser cache clearing instructions:"
echo "   - Chrome/Edge: Ctrl+Shift+R (Cmd+Shift+R on Mac)"
echo "   - Firefox: Ctrl+F5 (Cmd+Shift+R on Mac)"
echo "   - Safari: Cmd+Option+E then reload"
echo ""
echo "   Or try opening in an incognito/private window"
echo ""

# Try different start methods
echo "6. Starting Docusaurus with clean build..."
echo ""
echo "Try these commands in order until one works:"
echo ""
echo "Option 1 - Standard start with clean build:"
echo "npm run clear && npm start"
echo ""
echo "Option 2 - Start with host binding:"
echo "npm run clear && npm start -- --host 0.0.0.0"
echo ""
echo "Option 3 - Production build (more stable):"
echo "npm run build && npm run serve"
echo ""
echo "Option 4 - Start with polling (for file system issues):"
echo "npm start -- --poll 1000"
echo ""

# Additional troubleshooting
echo "7. If the error persists:"
echo "   a) Try a different browser"
echo "   b) Disable browser extensions (especially ad blockers)"
echo "   c) Check if antivirus/firewall is blocking files"
echo "   d) Try accessing from 127.0.0.1 instead of localhost"
echo ""

echo "=== Fix script completed ==="