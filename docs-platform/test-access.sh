#!/bin/bash

echo "=== Testing Docusaurus Access ==="
echo ""

# Test localhost
echo "1. Testing http://localhost:3000..."
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null)
if [ "$response" == "200" ]; then
    echo "✅ SUCCESS: Server is responding at http://localhost:3000"
    echo ""
    echo "Opening in your default browser..."
    open http://localhost:3000
else
    echo "❌ FAILED: Cannot reach http://localhost:3000 (HTTP $response)"
fi

echo ""
echo "2. Testing http://127.0.0.1:3000..."
response=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000 2>/dev/null)
if [ "$response" == "200" ]; then
    echo "✅ SUCCESS: Server is responding at http://127.0.0.1:3000"
else
    echo "❌ FAILED: Cannot reach http://127.0.0.1:3000 (HTTP $response)"
fi

echo ""
echo "3. Checking if port 3000 is open..."
if lsof -i :3000 >/dev/null 2>&1; then
    echo "✅ Port 3000 is OPEN and listening"
    echo ""
    echo "Process using port 3000:"
    lsof -i :3000 | grep LISTEN
else
    echo "❌ Port 3000 is NOT open"
fi

echo ""
echo "4. Checking firewall status..."
if /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | grep -q "disabled"; then
    echo "✅ Firewall is disabled"
else
    echo "⚠️  Firewall is enabled - this might block access"
    echo "   To disable temporarily: sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off"
fi

echo ""
echo "=== TROUBLESHOOTING TIPS ==="
echo ""
echo "If you still cannot access the site:"
echo ""
echo "1. Try a different browser:"
echo "   - Safari: open -a Safari http://localhost:3000"
echo "   - Chrome: open -a 'Google Chrome' http://localhost:3000"
echo "   - Firefox: open -a Firefox http://localhost:3000"
echo ""
echo "2. Clear DNS cache:"
echo "   sudo dscacheutil -flushcache"
echo ""
echo "3. Check /etc/hosts file:"
echo "   cat /etc/hosts | grep localhost"
echo "   Should show: 127.0.0.1 localhost"
echo ""
echo "4. Try incognito/private mode"
echo ""
echo "5. Disable VPN if you're using one"
echo ""