#!/bin/bash

echo "=== Starting Docusaurus Server on All Interfaces ==="
echo ""
echo "Killing any existing processes on port 3000..."
lsof -ti:3000 | xargs kill -9 2>/dev/null || true

echo ""
echo "Starting server..."
echo ""

# Start with host 0.0.0.0 to listen on all interfaces
npm run serve -- --host 0.0.0.0 --port 3000 &

sleep 3

echo ""
echo "=== Server Started Successfully! ==="
echo ""
echo "You can access the site at:"
echo ""
echo "  Local Machine:"
echo "  - http://localhost:3000"
echo "  - http://127.0.0.1:3000"
echo ""
echo "  From Other Devices on Your Network:"
echo "  - http://$(ipconfig getifaddr en0 2>/dev/null || echo 'YOUR_IP'):3000"
echo ""
echo "  Alternative IPs:"
ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print "  - http://" $2 ":3000"}'
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Keep the script running
wait