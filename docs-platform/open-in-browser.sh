#!/bin/bash

echo "Opening Docusaurus in your default browser..."
echo ""

# Try different URLs
urls=(
    "http://127.0.0.1:3000"
    "http://localhost:3000"
    "http://192.168.86.56:3000"
)

for url in "${urls[@]}"; do
    echo "Trying to open: $url"
    
    # macOS command to open in browser
    open "$url" 2>/dev/null
    
    # Wait a bit to see if it works
    sleep 2
    
    # Check if the server responds
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200"; then
        echo "✅ Successfully opened: $url"
        break
    else
        echo "❌ Failed to connect to: $url"
    fi
done

echo ""
echo "If the browser didn't open automatically, try:"
echo "1. Open Safari/Chrome/Firefox manually"
echo "2. Clear all browser data (Cmd+Shift+Delete)"
echo "3. Type one of these URLs in the address bar:"
for url in "${urls[@]}"; do
    echo "   - $url"
done