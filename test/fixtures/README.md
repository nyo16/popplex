# Test Fixtures

This directory should contain sample PDF files for integration testing.

## Required Files

- `sample.pdf` - A sample PDF file with at least one page for testing basic functionality

You can create a simple test PDF or download one from a public source.

## Running Integration Tests

To run integration tests with actual PDF files:

```bash
mix test --include integration
```

To run only unit tests (without PDF files):

```bash
mix test --exclude integration
```
