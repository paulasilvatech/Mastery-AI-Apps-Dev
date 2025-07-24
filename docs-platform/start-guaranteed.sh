#!/bin/bash

echo "=== Guaranteed Docusaurus Start Script ==="
echo ""

# Kill any process on port 3000
echo "1. Killing any process on port 3000..."
lsof -ti:3000 | xargs kill -9 2>/dev/null || true
pkill -f docusaurus 2>/dev/null || true
pkill -f "npm.*start" 2>/dev/null || true

echo "2. Cleaning cache..."
rm -rf .docusaurus 2>/dev/null
rm -rf node_modules/.cache 2>/dev/null

echo "3. Starting Docusaurus in development mode..."
echo ""

# Start with explicit host and port
npm start -- --host 127.0.0.1 --port 3000 &
SERVER_PID=$!

echo "4. Waiting for server to start (PID: $SERVER_PID)..."
echo ""

# Wait for server to be ready
for i in {1..30}; do
    if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000 | grep -q "200"; then
        echo ""
        echo "✅ SUCCESS! Server is running!"
        echo ""
        echo "=== ACCESS THE SITE ==="
        echo "Opening in your browser..."
        open http://127.0.0.1:3000
        echo ""
        echo "Manual access URLs:"
        echo "- http://127.0.0.1:3000"
        echo "- http://localhost:3000"
        echo ""
        echo "Server PID: $SERVER_PID"
        echo "To stop: kill $SERVER_PID"
        echo ""
        # Keep the script running
        wait $SERVER_PID
        exit 0
    fi
    echo -n "."
    sleep 2
done

echo ""
echo "❌ Server failed to start after 60 seconds"
echo ""
echo "Checking for errors..."
ps aux | grep $SERVER_PID