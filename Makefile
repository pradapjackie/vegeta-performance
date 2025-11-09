.PHONY: help install test plot clean

# Default variables
RATE ?= 100/s
DURATION ?= 30s
TARGETS ?= tests/targets/example-get.txt
TEST_NAME ?= load-test

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

install: ## Install Vegeta
	@echo "Installing Vegeta..."
	@if command -v vegeta &> /dev/null; then \
		echo "Vegeta is already installed"; \
		vegeta -version; \
	else \
		echo "Please install vegeta:"; \
		echo "  brew install vegeta  # macOS"; \
		echo "  or visit: https://github.com/tsenart/vegeta/releases"; \
	fi

test: ## Run load test
	@echo "Running load test..."
	@echo "Targets: $(TARGETS)"
	@echo "Rate: $(RATE)"
	@echo "Duration: $(DURATION)"
	@bash scripts/run-test.sh $(TARGETS) $(RATE) $(DURATION) $(TEST_NAME)

serve: ## Start the lightweight HTTP server for local testing
	@python3 scripts/test-server.py

view: ## View latest test results
	@bash scripts/view-results.sh

plot: ## Generate HTML plot from latest results
	@bash scripts/generate-plot.sh

clean: ## Clean test results
	@echo "Cleaning test results..."
	@rm -f tests/results/*
	@rm -f plot.html
	@echo "Clean complete"

results: ## List all test results
	@echo "Available test results:"
	@ls -lh tests/results/*.bin 2>/dev/null || echo "No results found"

quick: ## Run a quick 10s test
	@make test RATE=50/s DURATION=10s

intense: ## Run an intense test
	@make test RATE=1000/s DURATION=60s TEST_NAME=intense

health-check: ## Run health check test
	@echo "Checking health endpoints..."
	@cat tests/targets/example-get.txt | vegeta attack -rate=10/s -duration=5s | vegeta report

benchmark: ## Run benchmark tests
	@echo "Running benchmark tests..."
	@for rate in 10/s 50/s 100/s 200/s; do \
		echo ""; \
		echo "Testing at $$rate..."; \
		cat tests/targets/example-get.txt | \
			vegeta attack -rate=$$rate -duration=10s | \
			vegeta report | grep -E "Requests|Duration|Success"; \
	done

ci: ## Run tests for CI (shortened)
	@PORT_PIDS=$$(lsof -t -i tcp:8080 2>/dev/null); \
	if [ -n "$$PORT_PIDS" ]; then \
		echo "Ensuring port 8080 is free..."; \
		echo "Killing PID(s): $$PORT_PIDS"; \
		kill $$PORT_PIDS || true; \
		sleep 1; \
		PORT_PIDS=$$(lsof -t -i tcp:8080 2>/dev/null); \
		if [ -n "$$PORT_PIDS" ]; then \
			echo "Force killing PID(s): $$PORT_PIDS"; \
			kill -9 $$PORT_PIDS || true; \
			sleep 1; \
		fi; \
	fi; \
	echo "Starting test server..."; \
	python3 scripts/test-server.py & \
	SERVER_PID=$$!; \
	sleep 2; \
	bash scripts/run-test.sh tests/targets/example-get.txt 50/s 10s ci-test; \
	CI=1 bash scripts/generate-plot.sh; \
	echo "Stopping test server (PID: $$SERVER_PID)..."; \
	if [ -n "$$SERVER_PID" ] && kill -0 $$SERVER_PID 2>/dev/null; then \
		kill $$SERVER_PID; \
		wait $$SERVER_PID 2>/dev/null || true; \
		echo "Test server stopped."; \
	else \
		echo "Test server was not running."; \
	fi

.DEFAULT_GOAL := help


