#!/bin/bash

echo "=== Fixing Docusaurus Chunk Loading Issues ==="
echo ""

# 1. Stop all running processes
echo "1. Stopping all Docusaurus processes..."
pkill -f docusaurus 2>/dev/null || true
pkill -f "npm.*start" 2>/dev/null || true
lsof -ti:3000 | xargs kill -9 2>/dev/null || true

# 2. Clean everything
echo "2. Deep cleaning all caches and builds..."
rm -rf .docusaurus
rm -rf build
rm -rf node_modules/.cache
rm -rf .cache
rm -rf temp

# 3. Clear npm cache
echo "3. Clearing npm cache..."
npm cache clean --force

# 4. Reinstall dependencies
echo "4. Reinstalling dependencies..."
rm -rf node_modules
rm package-lock.json
npm install

# 5. Build production version
echo "5. Building production version..."
npm run build

# 6. Serve production build
echo "6. Starting production server..."
npm run serve -- --host 127.0.0.1 --port 3000 &

sleep 5

echo ""
echo "=== FIXED! ==="
echo ""
echo "The production build should now be running at:"
echo "- http://127.0.0.1:3000"
echo "- http://localhost:3000"
echo ""
echo "This build is more stable and should not have chunk loading errors."
echo ""
echo "Press Ctrl+C to stop the server"

wait