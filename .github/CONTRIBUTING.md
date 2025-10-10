# Contributing to Popplex

Thank you for considering contributing to Popplex! This document provides guidelines and information for contributors.

## Development Setup

### Prerequisites

1. **Elixir & Erlang**: Install via your preferred method (asdf, homebrew, etc.)
2. **Poppler**: Required for PDF operations
   - macOS: `brew install poppler pkg-config`
   - Ubuntu: `sudo apt-get install libpoppler-cpp-dev poppler-utils pkg-config build-essential`
3. **C++ Compiler**: Required for building the NIF (gcc or clang with C++11 support)

### Getting Started

```bash
# Clone the repository
git clone https://github.com/mylanconnolly/popplex.git
cd popplex

# Install dependencies
mix deps.get

# Compile the project (including C++ NIF)
mix compile

# Run tests
mix test

# Run all tests including integration tests
mix test --include integration
```

## Code Quality Standards

### Before Submitting

Ensure your code passes all quality checks:

```bash
# Format code
mix format

# Check formatting
mix format --check-formatted

# Compile with warnings as errors
mix compile --warnings-as-errors

# Run full test suite
mix test --include integration
```

### Code Style

- Follow the [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
- Use `mix format` to automatically format your code
- Write descriptive commit messages
- Add tests for new features
- Update documentation as needed

## Testing

### Test Structure

- **Unit tests**: Tests that don't require actual PDF files (error handling, validation, etc.)
- **Integration tests**: Tests that work with real PDF files (tagged with `@tag :integration`)

### Running Tests

```bash
# Run only unit tests (fast)
mix test --exclude integration

# Run all tests including integration
mix test --include integration

# Run a specific test file
mix test test/popplex_test.exs

# Run tests matching a pattern
mix test --only describe:"combine_pdfs/2"
```

### Adding Tests

When adding new features:
1. Add unit tests for error cases and edge conditions
2. Add integration tests for successful operations
3. Ensure tests clean up any created files
4. Use descriptive test names

## Pull Request Process

1. **Fork the repository** and create a new branch for your feature
2. **Write tests** for your changes
3. **Update documentation** in code comments and README if needed
4. **Ensure CI passes** - all tests and checks must pass
5. **Submit a pull request** with a clear description of changes

### PR Checklist

- [ ] Tests added/updated and passing
- [ ] Code formatted with `mix format`
- [ ] Documentation updated
- [ ] CI checks passing
- [ ] Commit messages are clear and descriptive

## Continuous Integration

The project uses GitHub Actions for CI. On every push and pull request:

- Tests run against multiple Elixir/OTP versions (1.16-1.18, OTP 26-27)
- Code formatting is checked
- Static analysis is performed
- Both unit and integration tests run

You can see the CI configuration in `.github/workflows/ci.yml`.

## Architecture

### Project Structure

```
popplex/
├── c_src/              # C++ NIF implementation
│   └── popplex_nif.cpp # Poppler wrapper
├── lib/
│   ├── popplex.ex      # Public API
│   └── popplex/
│       └── nif.ex      # NIF loader
├── test/
│   ├── popplex_test.exs
│   └── fixtures/       # Test PDF files
├── Makefile            # NIF compilation
└── mix.exs             # Project configuration
```

### Adding New Features

1. **NIF functions**: Add to `c_src/popplex_nif.cpp` and export in `ERL_NIF_INIT`
2. **NIF loader stubs**: Add stub functions to `lib/popplex/nif.ex`
3. **Public API**: Add user-facing functions to `lib/popplex.ex`
4. **Tests**: Add to `test/popplex_test.exs`
5. **Documentation**: Update README.md with examples

## Reporting Issues

When reporting issues, please include:

- Elixir and OTP versions (`elixir --version`)
- Poppler version (`pkg-config --modversion poppler-cpp`)
- Operating system and version
- Steps to reproduce
- Expected vs actual behavior
- Error messages or stack traces

## Questions?

Feel free to open an issue for questions or discussions about the project.

## License

By contributing to Popplex, you agree that your contributions will be licensed under the MIT License.
