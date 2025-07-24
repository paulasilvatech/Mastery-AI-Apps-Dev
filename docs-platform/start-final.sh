#!/bin/bash

echo "=== FINAL Docusaurus Start Solution ==="
echo ""

# Kill all existing processes
echo "1. Killing ALL node/npm processes on port 3000..."
lsof -ti:3000 | xargs kill -9 2>/dev/null || true
pkill -f "node.*docusaurus" 2>/dev/null || true
pkill -f "npm.*serve" 2>/dev/null || true
pkill -f "npm.*start" 2>/dev/null || true

# Wait a bit
sleep 2

# Check if build exists
if [ ! -d "build" ]; then
    echo "2. Build directory not found. Creating production build..."
    npm run build
fi

# Try different methods to start
echo "3. Starting server..."
echo ""

# Method 1: Try with explicit host binding
echo "Attempting Method 1: Binding to all interfaces..."
npm run serve -- --host 0.0.0.0 --port 3000 &
SERVER_PID=$!

# Wait for startup
sleep 5

# Test connection
echo ""
echo "4. Testing connection..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200"; then
    echo "✅ SUCCESS! Server is accessible at http://localhost:3000"
    open http://localhost:3000
else
    echo "❌ Method 1 failed. Trying Method 2..."
    kill $SERVER_PID 2>/dev/null || true
    
    # Method 2: Use Python server as fallback
    echo ""
    echo "Starting with Python HTTP server..."
    cd build
    python3 -m http.server 3000 &
    PYTHON_PID=$!
    
    sleep 3
    echo ""
    echo "✅ Python server started!"
    echo "Access the site at: http://localhost:3000"
    open http://localhost:3000
fi

echo ""
echo "=== IMPORTANT ==="
echo "If you still cannot access the site:"
echo ""
echo "1. Open Terminal and run:"
echo "   cd $(pwd)"
echo "   npx serve build -l 3000"
echo ""
echo "2. Or use Python:"
echo "   cd build"
echo "   python3 -m http.server 3000"
echo ""
echo "3. Check your Mac's Security & Privacy settings"
echo "4. Temporarily disable any VPN or firewall"
echo ""

# Keep script running
wait