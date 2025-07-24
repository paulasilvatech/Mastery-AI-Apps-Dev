#!/bin/bash

echo "=== Docusaurus Access Diagnostic Script ==="
echo ""

# Check if npm is installed
echo "1. Checking npm installation:"
npm --version || echo "❌ npm not found!"
echo ""

# Check if node is installed
echo "2. Checking node installation:"
node --version || echo "❌ node not found!"
echo ""

# Check current directory
echo "3. Current directory:"
pwd
echo ""

# Check if package.json exists
echo "4. Checking package.json:"
if [ -f "package.json" ]; then
    echo "✅ package.json found"
else
    echo "❌ package.json not found!"
fi
echo ""

# Check if node_modules exists
echo "5. Checking node_modules:"
if [ -d "node_modules" ]; then
    echo "✅ node_modules directory exists"
else
    echo "❌ node_modules not found! Run: npm install"
fi
echo ""

# Check port 3000
echo "6. Checking port 3000:"
lsof -i :3000 2>/dev/null || echo "✅ Port 3000 is free"
echo ""

# Check firewall status
echo "7. Checking firewall status:"
sudo pfctl -s info 2>/dev/null | head -5 || echo "Could not check firewall (needs sudo)"
echo ""

# Get all network interfaces
echo "8. Available network interfaces:"
ifconfig | grep -E "^[a-z]|inet " | grep -B1 "inet " | grep -v "127.0.0.1" | head -10
echo ""

# Try to start the server with different configurations
echo "9. Starting Docusaurus with different configurations..."
echo ""

echo "Option A - Standard localhost (http://localhost:3000):"
echo "npm start"
echo ""

echo "Option B - All interfaces (http://0.0.0.0:3000 or http://YOUR_IP:3000):"
echo "npm start -- --host 0.0.0.0"
echo ""

echo "Option C - Specific IP binding (http://192.168.x.x:3000):"
IP=$(ifconfig | grep -E "inet " | grep -v "127.0.0.1" | head -1 | awk '{print $2}')
echo "npm start -- --host $IP"
echo ""

echo "Option D - Different port (http://localhost:4000):"
echo "npm start -- --port 4000"
echo ""

echo "Option E - Production build served locally:"
echo "npm run build && npm run serve"
echo ""

# Check for common issues
echo "10. Common issues to check:"
echo "- [ ] Is the terminal still running the npm start command?"
echo "- [ ] Are you accessing the correct URL in your browser?"
echo "- [ ] Is your browser blocking local connections?"
echo "- [ ] Do you have any proxy settings that might interfere?"
echo "- [ ] Are there any security software blocking the connection?"
echo ""

echo "11. Quick test URLs to try:"
echo "- http://localhost:3000"
echo "- http://127.0.0.1:3000"
echo "- http://0.0.0.0:3000"
if [ ! -z "$IP" ]; then
    echo "- http://$IP:3000"
fi
echo ""

echo "=== End of diagnostic ==="