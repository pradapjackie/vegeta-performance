#!/bin/bash

# View Vegeta Test Results
# Usage: ./scripts/view-results.sh [result-file]

set -e

RESULT_FILE=${1:-"tests/results/latest.bin"}

# Check if vegeta is installed
if ! command -v vegeta &> /dev/null; then
    echo "Error: vegeta is not installed"
    echo "Install with: brew install vegeta"
    exit 1
fi

# Check if result file exists
if [ ! -f "$RESULT_FILE" ]; then
    echo "Error: Result file not found: $RESULT_FILE"
    echo "Available results in tests/results/:"
    ls -lh tests/results/*.bin 2>/dev/null || echo "No results found"
    exit 1
fi

echo "=== Vegeta Test Results ==="
echo "File: $RESULT_FILE"
echo ""

# Display text report
echo "--- Text Report ---"
vegeta report "$RESULT_FILE"

echo ""
echo "--- JSON Report ---"
vegeta report -type=json "$RESULT_FILE" | jq '.' || vegeta report -type=json "$RESULT_FILE"

echo ""
echo "--- Visualization ---"
echo "To create a plot:"
echo "  vegeta plot $RESULT_FILE > plot.html && open plot.html"


