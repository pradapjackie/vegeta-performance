#!/bin/bash

# Vegeta Load Testing Runner
# Usage: ./scripts/run-test.sh <targets-file> [rate] [duration] [name]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration with defaults
TARGETS_FILE=${1:-"tests/targets/example-get.txt"}
RATE=${2:-"100/s"}
DURATION=${3:-"30s"}
TEST_NAME=${4:-"load-test"}

# Colors for output
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
RESULTS_DIR="tests/results"
RESULT_FILE="${RESULTS_DIR}/${TEST_NAME}-${TIMESTAMP}.bin"
REPORT_FILE="${RESULTS_DIR}/${TEST_NAME}-${TIMESTAMP}.txt"

# Check if vegeta is installed
if ! command -v vegeta &> /dev/null; then
    echo -e "${RED}Error: vegeta is not installed${NC}"
    echo "Install with: brew install vegeta"
    exit 1
fi

# Check if targets file exists
if [ ! -f "$TARGETS_FILE" ]; then
    echo -e "${RED}Error: Targets file not found: $TARGETS_FILE${NC}"
    exit 1
fi

# Create results directory if it doesn't exist
mkdir -p "$RESULTS_DIR"

echo -e "${GREEN}=== Vegeta Load Test ===${NC}"
echo "Targets: $TARGETS_FILE"
echo "Rate: $RATE"
echo "Duration: $DURATION"
echo "Results: $RESULT_FILE"
echo ""

# Check if running inside Docker (for GitHub Actions)
if [ -f /.dockerenv ] || [ -n "$CI" ]; then
    echo -e "${YELLOW}Running in CI environment${NC}"
fi

# Run the attack
echo -e "${GREEN}Starting attack...${NC}"
cat "$TARGETS_FILE" | \
    vegeta attack \
        -rate="$RATE" \
        -duration="$DURATION" \
        -timeout=30s \
        -workers=10 \
        > "$RESULT_FILE"

# Generate text report
echo ""
echo -e "${GREEN}Generating report...${NC}"
vegeta report "$RESULT_FILE" > "$REPORT_FILE"

# Display results
echo ""
echo -e "${GREEN}=== Test Results ===${NC}"
cat "$REPORT_FILE"

# Check for errors
ERRORS=$(vegeta report "$RESULT_FILE" | grep -E "Success|Error" || true)
echo ""
echo -e "${GREEN}Errors during test:${NC}"
vegeta report "$RESULT_FILE" | grep -A 5 "Errors" || echo "No errors found"

echo ""
echo -e "${GREEN}Results saved to: ${NC}$RESULT_FILE"
echo -e "${GREEN}Report saved to: ${NC}$REPORT_FILE"

# Create a symlink to latest
ln -sf "$(basename "$RESULT_FILE")" "${RESULTS_DIR}/latest.bin"
ln -sf "$(basename "$REPORT_FILE")" "${RESULTS_DIR}/latest.txt"

echo ""
echo -e "${GREEN}To view results:${NC}"
echo "  vegeta report ${RESULT_FILE}"
echo "  vegeta report -type=json ${RESULT_FILE}"
echo "  vegeta plot ${RESULT_FILE} > plot.html && open plot.html"


