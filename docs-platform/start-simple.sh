#!/bin/bash

echo "=== Starting Docusaurus (Simple Method) ==="
echo ""

# Navigate to directory
cd /Users/paulasilva/Documents/paulasilvatech/GH-Repos/Mastery-AI-Apps-Dev/docs-platform

# Kill any existing processes
echo "1. Cleaning up old processes..."
pkill -f "npm.*serve" 2>/dev/null || true
pkill -f docusaurus 2>/dev/null || true

# Start server
echo "2. Starting server..."
npm run serve

# This will keep running until you press Ctrl+C