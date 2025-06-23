#!/bin/bash
# scripts/check-prerequisites.sh
# Validates all prerequisites for Module 07

set -e

echo "🔍 Checking Module 07 Prerequisites..."
echo "===================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track if all checks pass
ALL_PASS=true

# Function to check command exists
check_command() {
    local cmd=$1
    local min_version=$2
    local version_cmd=$3
    
    if command -v $cmd &> /dev/null; then
        if [ -n "$version_cmd" ]; then
            version=$($version_cmd 2>&1 | head -1)
            echo -e "${GREEN}✓${NC} $cmd installed: $version"
        else
            echo -e "${GREEN}