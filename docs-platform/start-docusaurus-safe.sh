#!/bin/bash

echo "=== Safe Docusaurus Start Script ==="
echo ""

# Change to the docs-platform directory
cd "$(dirname "$0")"

# Kill any existing processes
echo "1. Cleaning up any existing processes..."
pkill -f docusaurus 2>/dev/null
pkill -f "npm.*start" 2>/dev/null
sleep 2

# Clear all caches
echo "2. Clearing all caches..."
npm run clear

# Check node_modules
echo "3. Checking dependencies..."
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

# Start with different options based on user choice
echo ""
echo "4. Choose how to start Docusaurus:"
echo "   1) Standard mode (localhost only)"
echo "   2) Network mode (accessible from other devices)"
echo "   3) Production build (most stable)"
echo "   4) Debug mode (with verbose output)"
echo ""
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        echo "Starting in standard mode..."
        echo "Access at: http://localhost:3000"
        npm start
        ;;
    2)
        echo "Starting in network mode..."
        IP=$(ifconfig | grep -E "inet " | grep -v "127.0.0.1" | head -1 | awk '{print $2}')
        echo "Access at:"
        echo "  - http://localhost:3000"
        echo "  - http://127.0.0.1:3000"
        echo "  - http://$IP:3000"
        npm start -- --host 0.0.0.0
        ;;
    3)
        echo "Building for production..."
        npm run build
        echo "Starting production server..."
        echo "Access at: http://localhost:3000"
        npm run serve
        ;;
    4)
        echo "Starting in debug mode..."
        echo "Access at: http://localhost:3000"
        DEBUG=* npm start
        ;;
    *)
        echo "Invalid choice. Starting in standard mode..."
        npm start
        ;;
esac