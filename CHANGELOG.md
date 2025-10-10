# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-10-10

### Added
- Initial release of Popplex - Elixir NIF wrapper for Poppler PDF library
- **Get page count** - `Popplex.get_page_count/1` function to retrieve the number of pages in a PDF file
  - Returns `{:ok, count}` on success or `{:error, reason}` on failure
  - Supports both string and charlist paths
  - Fast NIF-based implementation using Poppler C++ API
- **Extract text content** - `Popplex.get_text/2` function to extract text from PDF documents
  - Extract text from all pages (default behavior)
  - Extract text from a specific page using `page: n` option (0-indexed)
  - Returns extracted text as binary string
  - Handles multi-page documents with page separators
- **Combine PDFs** - `Popplex.combine_pdfs/2` function to merge multiple PDF files
  - Uses `pdfunite` command-line tool (part of Poppler utilities)
  - Validates minimum 2 input files required
  - Checks file existence with helpful error messages
  - Returns `{:ok, output_path}` on success
- C++ NIF implementation (`c_src/popplex_nif.cpp`) using Poppler library
  - Memory-safe with RAII patterns and smart pointers
  - Proper error handling and informative error messages
  - Binary string returns for UTF-8 text content
- Comprehensive test suite
  - Unit tests for error cases and edge conditions
  - Integration tests with real PDF fixtures
  - 11 tests covering all major functionality
- Build system with `elixir_make`
  - Cross-platform Makefile for macOS and Linux
  - Automatic NIF compilation during `mix compile`
  - pkg-config integration for Poppler dependencies
- Complete documentation
  - Installation instructions for multiple platforms
  - Usage examples with error handling
  - API documentation with @spec types
  - Development guide and testing instructions
- GitHub Actions CI/CD pipeline
  - Tests against multiple Elixir/OTP version combinations (1.16-1.18, OTP 26-27)
  - Automated dependency installation (Poppler, build tools)
  - Unit and integration test runs
  - Code formatting and static analysis checks
  - Dependency caching for faster builds
- Contributing guidelines in `.github/CONTRIBUTING.md`
  - Development setup instructions
  - Code quality standards
  - PR process and checklist

### Technical Details
- Elixir 1.18+ compatibility
- OTP 26+ support
- C++11 standard
- Poppler C++ API binding
- NIF-based for native performance on page count and text extraction
- Command-line tool integration for PDF combining

[Unreleased]: https://github.com/mylanconnolly/popplex/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/mylanconnolly/popplex/releases/tag/v0.1.0
