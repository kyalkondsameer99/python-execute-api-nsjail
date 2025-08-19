#!/bin/bash

# Test script for Python Execute API
# This script tests various API endpoints and functionality

set -e

# Default values
API_URL=${1:-"http://localhost:8081"}
TIMEOUT=30

echo "🧪 Testing Python Execute API at: $API_URL"
echo "⏱️  Timeout: ${TIMEOUT}s"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
test_endpoint() {
    local test_name="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    local expected_status="$5"
    
    echo -n "Testing $test_name... "
    
    if [ -n "$data" ]; then
        response=$(curl -s -w "%{http_code}" -X "$method" "$API_URL$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data" \
            --max-time $TIMEOUT)
    else
        response=$(curl -s -w "%{http_code}" -X "$method" "$API_URL$endpoint" \
            --max-time $TIMEOUT)
    fi
    
    # Extract status code (last line)
    status_code=$(echo "$response" | tail -n1)
    # Extract response body (everything except last line)
    response_body=$(echo "$response" | sed '$d')
    
    if [ "$status_code" = "$expected_status" ]; then
        echo -e "${GREEN}✅ PASS${NC}"
        if [ "$expected_status" = "200" ]; then
            echo "   Response: $response_body"
        fi
    else
        echo -e "${RED}❌ FAIL${NC}"
        echo "   Expected: $expected_status, Got: $status_code"
        echo "   Response: $response_body"
        return 1
    fi
    echo ""
}

# Test 1: Health check
test_endpoint "Health Check" "GET" "/healthz" "" "200"

# Test 2: Basic Python execution
test_endpoint "Basic Python Execution" "POST" "/execute" \
    '{"script": "def main():\n    return {\"message\": \"Hello World\", \"status\": \"success\"}\n"}' \
    "200"

# Test 3: Python with numpy and pandas
test_endpoint "Python with Libraries" "POST" "/execute" \
    '{"script": "def main():\n    import numpy as np\n    import pandas as pd\n    data = np.array([1, 2, 3, 4, 5])\n    df = pd.DataFrame({\"numbers\": data})\n    return {\"sum\": int(np.sum(data)), \"mean\": float(np.mean(data)), \"shape\": list(df.shape)}\n"}' \
    "200"

# Test 4: Python with print statements
test_endpoint "Python with Print Statements" "POST" "/execute" \
    '{"script": "def main():\n    print(\"Processing...\")\n    print(\"Almost done...\")\n    result = 42\n    print(f\"Result: {result}\")\n    return {\"answer\": result, \"message\": \"Calculation complete\"}\n"}' \
    "200"

# Test 5: Missing main function (should fail)
test_endpoint "Missing Main Function" "POST" "/execute" \
    '{"script": "print(\"Hello\")\nreturn {\"test\": \"value\"}\n"}' \
    "400"

# Test 6: Non-JSON return (should fail)
test_endpoint "Non-JSON Return" "POST" "/execute" \
    '{"script": "def main():\n    return \"This is a string, not a dict\"\n"}' \
    "400"

# Test 7: Invalid JSON (should fail)
test_endpoint "Invalid JSON" "POST" "/execute" \
    '{"script": "def main():\n    return {\"test": "missing quote"}\n"}' \
    "400"

# Test 8: Empty script (should fail)
test_endpoint "Empty Script" "POST" "/execute" \
    '{"script": ""}' \
    "400"

# Test 9: Missing script field (should fail)
test_endpoint "Missing Script Field" "POST" "/execute" \
    '{"code": "def main():\n    return {\"test\": \"value\"}\n"}' \
    "400"

# Test 10: Script too long (should fail if limit is low)
# This test might pass if the limit is high enough
test_endpoint "Long Script" "POST" "/execute" \
    '{"script": "def main():\n    '$(printf 'x%.0s' {1..1000})'\n    return {\"length\": \"very long\"}\n"}' \
    "200"

echo "🎉 All tests completed!"
echo ""
echo "📊 Summary:"
echo "   - Health check: ✅"
echo "   - Basic execution: ✅"
echo "   - Library access: ✅"
echo "   - Print capture: ✅"
echo "   - Error handling: ✅"
echo "   - Input validation: ✅"
echo ""
echo "🚀 API is working correctly!"
