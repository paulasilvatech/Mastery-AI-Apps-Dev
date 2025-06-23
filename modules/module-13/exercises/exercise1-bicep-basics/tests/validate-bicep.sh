#!/bin/bash
# validate-bicep.sh - Validate Bicep templates

set -e

echo "🔍 Validating Bicep Templates"
echo "============================="

# Check if we're in the right directory
if [ ! -f "../solution/main.bicep" ] && [ ! -f "../starter/main.bicep" ]; then
    echo "❌ Error: No Bicep files found. Run this script from the tests directory."
    exit 1
fi

# Function to validate a Bicep file
validate_bicep() {
    local file=$1
    local filename=$(basename "$file")
    
    echo -e "\n📄 Validating: $filename"
    
    # Check if file exists
    if [ ! -f "$file" ]; then
        echo "  ⏭️  File not found, skipping"
        return
    fi
    
    # Validate Bicep syntax
    if az bicep build --file "$file" --stdout > /dev/null 2>&1; then
        echo "  ✅ Syntax validation passed"
    else
        echo "  ❌ Syntax validation failed"
        az bicep build --file "$file"
        return 1
    fi
    
    # Check for required parameters
    echo "  🔍 Checking parameters..."
    if grep -q "param appName" "$file" && \
       grep -q "param environment" "$file" && \
       grep -q "param location" "$file"; then
        echo "  ✅ Required parameters found"
    else
        echo "  ⚠️  Some required parameters might be missing"
    fi
    
    # Check for resources
    echo "  🔍 Checking resources..."
    local resource_count=$(grep -c "^resource" "$file" || true)
    echo "  📊 Found $resource_count resource definitions"
    
    # Check for outputs
    echo "  🔍 Checking outputs..."
    if grep -q "^output" "$file"; then
        echo "  ✅ Outputs defined"
    else
        echo "  ⚠️  No outputs found"
    fi
    
    # Check for hardcoded values
    echo "  🔍 Checking for hardcoded values..."
    if grep -E "(password|Password|SECRET|secret)\s*[:=]\s*['\"][^'\"]+['\"]" "$file" | grep -v "@secure()" > /dev/null; then
        echo "  ⚠️  Warning: Possible hardcoded secrets found"
    else
        echo "  ✅ No obvious hardcoded secrets"
    fi
}

# Validate starter template
if [ -f "../starter/main.bicep" ]; then
    validate_bicep "../starter/main.bicep"
fi

# Validate solution template
if [ -f "../solution/main.bicep" ]; then
    validate_bicep "../solution/main.bicep"
fi

# Check parameter files
echo -e "\n📄 Checking parameter files"
for param_file in ../solution/parameters*.json ../starter/parameters*.json; do
    if [ -f "$param_file" ]; then
        filename=$(basename "$param_file")
        if jq empty "$param_file" 2>/dev/null; then
            echo "  ✅ $filename is valid JSON"
        else
            echo "  ❌ $filename has invalid JSON"
        fi
    fi
done

echo -e "\n✅ Validation complete!"
echo "============================="
echo "Next steps:"
echo "  1. Deploy using: az deployment group create ..."
echo "  2. Run functional tests: ./test-deployment.sh"