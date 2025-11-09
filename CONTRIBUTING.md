# Contributing to Vegeta Load Testing Framework

## Adding New Test Targets

1. Create a new file in `tests/targets/`
2. Add your HTTP requests following Vegeta format:

```
GET http://example.com/api/v1/users
POST http://example.com/api/v1/data
Content-Type: application/json

{"key": "value"}
```

3. Run your test:
```bash
make test TARGETS=tests/targets/your-test.txt
```

## GitHub Actions Integration

### Triggering Tests Manually

You can manually trigger tests via GitHub Actions with custom parameters:
- `test_target`: URL to test
- `rate`: Requests per second
- `duration`: Test duration
- `skip_server`: Skip starting test server

### Adding Custom Test Scenarios

Edit `.github/workflows/load-test.yml` to add your test scenarios.

### Test Results

Results are automatically uploaded as artifacts and can be downloaded from the Actions tab.

## Running Tests Locally

See the main README for installation and usage instructions.

## Reporting Issues

Please file issues in the project repository with:
- Test configuration
- Expected vs actual results
- Environment details


