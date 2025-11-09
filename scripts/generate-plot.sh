#!/bin/bash

# Generate HTML Plot from Vegeta Results
# Usage: ./scripts/generate-plot.sh [result-file]

set -e

RESULT_FILE=${1:-"tests/results/latest.bin"}
PLOT_FILE="tests/results/plot-$(date +"%Y%m%d-%H%M%S").html"

# Check if vegeta is installed
if ! command -v vegeta &> /dev/null; then
    echo "Error: vegeta is not installed"
    exit 1
fi

# Check if result file exists
if [ ! -f "$RESULT_FILE" ]; then
    echo "Error: Result file not found: $RESULT_FILE"
    exit 1
fi

echo "Generating plot..."
vegeta plot -title="Vegeta Load Test Results" "$RESULT_FILE" > "$PLOT_FILE"

echo "Plot generated: $PLOT_FILE"
if [ -n "$CI" ]; then
    echo "CI environment detected; skipping automatic browser launch."
else
    echo "Opening in browser..."
    if command -v open &> /dev/null; then
        open "$PLOT_FILE"
    elif command -v xdg-open &> /dev/null; then
        xdg-open "$PLOT_FILE"
    else
        echo "Please open $PLOT_FILE in your browser"
    fi
fi


