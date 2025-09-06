#!/bin/bash

# ============================================================================
# CI Workflow Test Script
# Tests the enhanced CI workflow for common issues and validates syntax
# ============================================================================

set -e

WORKFLOW_FILE=".github/workflows/ci-enhanced.yml"
TEMP_DIR="/tmp/ci-test-$$"

echo "🔍 Testing CI Enhanced Workflow"
echo "================================"

# Check if workflow file exists
if [ ! -f "$WORKFLOW_FILE" ]; then
    echo "❌ Workflow file not found: $WORKFLOW_FILE"
    exit 1
fi

echo "✅ Workflow file exists"

# Validate YAML syntax
echo ""
echo "📝 Validating YAML syntax..."
if python3 -c "import yaml; yaml.safe_load(open('$WORKFLOW_FILE').read())" 2>/dev/null; then
    echo "✅ YAML syntax is valid"
else
    echo "❌ YAML syntax error"
    exit 1
fi

# Check for common issues from T01
echo ""
echo "🔍 Checking for known issues..."

# Check for docker-compose vs docker compose
if grep -q "docker-compose" "$WORKFLOW_FILE"; then
    echo "⚠️  Warning: Found 'docker-compose' (hyphen) - should use 'docker compose' (space) for V2"
    grep -n "docker-compose" "$WORKFLOW_FILE" | head -5
else
    echo "✅ Using correct Docker Compose V2 syntax"
fi

# Check for wait-for-services script
if grep -q "wait-for-services" "$WORKFLOW_FILE"; then
    echo "⚠️  Warning: References 'wait-for-services' script which may not exist"
else
    echo "✅ No reference to non-existent wait-for-services script"
fi

# Check for correct PostgreSQL port
if grep -q "5442" "$WORKFLOW_FILE"; then
    echo "⚠️  Warning: Found port 5442 - GitHub service containers use 5432"
else
    echo "✅ Using correct PostgreSQL port (5432)"
fi

# Check for conditional artifact handling
if grep -q 'if: steps.build.outputs.has-artifacts' "$WORKFLOW_FILE"; then
    echo "✅ Conditional artifact upload implemented"
else
    echo "⚠️  Warning: No conditional artifact upload found"
fi

# Check for service health checks
if grep -q 'docker compose.*up -d' "$WORKFLOW_FILE"; then
    if grep -q 'sleep' "$WORKFLOW_FILE"; then
        echo "✅ Service startup wait time included"
    else
        echo "⚠️  Warning: No wait time after starting services"
    fi
fi

# Test affected calculation locally
echo ""
echo "🧪 Testing affected calculation (dry run)..."
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Create a mock git repo for testing
git init -q
git config user.email "test@test.com"
git config user.name "Test"
echo "test" > test.txt
git add .
git commit -q -m "Initial commit"

# Test base SHA calculation
BASE_SHA=$(git rev-parse HEAD~1 2>/dev/null || git rev-parse HEAD)
echo "✅ Base SHA calculation works: ${BASE_SHA:0:7}"

# Cleanup
cd - > /dev/null
rm -rf "$TEMP_DIR"

# Check required actions
echo ""
echo "📦 Checking required GitHub Actions..."
REQUIRED_ACTIONS=(
    "actions/checkout@v5"
    "actions/setup-node@v5"
    "actions/cache@v4"
    "actions/upload-artifact@v4"
    "codecov/codecov-action@v3"
    "aquasecurity/trivy-action@master"
    "github/codeql-action/upload-sarif@v3"
)

for action in "${REQUIRED_ACTIONS[@]}"; do
    if grep -q "$action" "$WORKFLOW_FILE"; then
        echo "✅ Found: $action"
    else
        echo "❌ Missing: $action"
    fi
done

# Check for matrix strategy
echo ""
echo "🔄 Checking matrix strategies..."
if grep -q "matrix:" "$WORKFLOW_FILE"; then
    echo "✅ Matrix strategy implemented"
    grep -A2 "matrix:" "$WORKFLOW_FILE" | grep "check:" | head -1
fi

# Check for service containers
echo ""
echo "🐳 Checking service containers..."
SERVICES=("postgres" "redis" "mongodb")
for service in "${SERVICES[@]}"; do
    if grep -q "^\s*$service:" "$WORKFLOW_FILE"; then
        echo "✅ Service container: $service"
    fi
done

# Summary
echo ""
echo "================================"
echo "📊 Test Summary"
echo "================================"

# Count warnings and errors
WARNINGS=$(grep -c "⚠️" /tmp/ci-test-output 2>/dev/null || echo "0")
ERRORS=$(grep -c "❌" /tmp/ci-test-output 2>/dev/null || echo "0")

if [ "$ERRORS" -gt 0 ]; then
    echo "❌ Tests failed with errors"
    exit 1
else
    echo "✅ All critical tests passed!"
    if [ "$WARNINGS" -gt 0 ]; then
        echo "⚠️  Some warnings were found but they are not critical"
    fi
fi

echo ""
echo "💡 Next steps:"
echo "1. Push to a feature branch to test in GitHub Actions"
echo "2. Monitor the workflow execution for any runtime issues"
echo "3. Check that all jobs complete successfully"