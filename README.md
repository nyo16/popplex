# Popplex

[![CI](https://github.com/mylanconnolly/popplex/actions/workflows/ci.yml/badge.svg)](https://github.com/mylanconnolly/popplex/actions/workflows/ci.yml)

An Elixir NIF (Native Implemented Function) wrapper for the Poppler PDF library, providing fast and efficient PDF processing capabilities.

## Features

- **Get page count** - Quickly determine the number of pages in a PDF
- **Extract text** - Extract text content from entire documents or specific pages
- **Combine PDFs** - Merge multiple PDF files into one

## Prerequisites

Before using Popplex, you need to have Poppler installed on your system:

### macOS
```bash
brew install poppler pkg-config
```

### Ubuntu/Debian
```bash
sudo apt-get install libpoppler-cpp-dev pkg-config
```

### Fedora/RHEL
```bash
sudo dnf install poppler-cpp-devel pkgconfig
```

### Arch Linux
```bash
sudo pacman -S poppler pkgconf
```

## Installation

Add `popplex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:popplex, "~> 0.1.0"}
  ]
end
```

Then run:

```bash
mix deps.get
mix compile
```

The NIF will be automatically compiled during the build process.

## Usage

### Get Page Count

```elixir
# Get the number of pages in a PDF
{:ok, count} = Popplex.get_page_count("document.pdf")
IO.puts("The PDF has #{count} pages")
```

### Extract Text

```elixir
# Extract text from all pages
{:ok, text} = Popplex.get_text("document.pdf")

# Extract text from a specific page (0-indexed)
{:ok, first_page} = Popplex.get_text("document.pdf", page: 0)
{:ok, second_page} = Popplex.get_text("document.pdf", page: 1)

# Explicitly extract all pages
{:ok, all_text} = Popplex.get_text("document.pdf", all: true)
```

### Combine PDFs

```elixir
# Merge multiple PDFs into one
{:ok, output} = Popplex.combine_pdfs(
  ["file1.pdf", "file2.pdf", "file3.pdf"],
  "combined.pdf"
)

# Verify the combined PDF
{:ok, count} = Popplex.get_page_count("combined.pdf")
IO.puts("Combined PDF has #{count} pages")
```

## Error Handling

All functions return `{:ok, result}` on success or `{:error, reason}` on failure:

```elixir
case Popplex.get_page_count("document.pdf") do
  {:ok, count} ->
    IO.puts("Success! Page count: #{count}")
    
  {:error, reason} ->
    IO.puts("Error: #{reason}")
end
```

Common error scenarios:
- File doesn't exist: `"Failed to open PDF document"`
- PDF is password protected: `"PDF document is locked"`
- Invalid page number: `"Page number out of range"`

## Development

### Building from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/popplex.git
cd popplex

# Get dependencies
mix deps.get

# Compile (including the NIF)
mix compile

# Run tests
mix test

# Run integration tests (requires sample PDF files)
mix test --include integration
```

### Testing

Unit tests can be run without any PDF files:
```bash
mix test --exclude integration
```

For integration tests, place sample PDF files in `test/fixtures/` and run:
```bash
mix test --include integration
```

### Continuous Integration

The project uses GitHub Actions for CI, which:
- Tests against multiple Elixir/OTP version combinations
- Runs both unit and integration tests
- Performs static analysis and code formatting checks
- Automatically installs Poppler and dependencies

The CI workflow runs on:
- Every push to `main`/`master` branch
- Every pull request

You can view the CI status in the badge at the top of this README.

## How It Works

Popplex uses Erlang's NIF (Native Implemented Function) interface to call C++ code that wraps the Poppler library. This provides:

- **Performance**: Near-native speed for PDF operations
- **Direct library access**: Full access to Poppler's capabilities
- **Memory efficiency**: Minimal copying between Erlang and C++

The architecture consists of:
1. **C++ NIF layer** (`c_src/popplex_nif.cpp`) - Interfaces with Poppler
2. **NIF loader** (`lib/popplex/nif.ex`) - Loads the compiled NIF
3. **Public API** (`lib/popplex.ex`) - User-friendly Elixir interface

## Limitations

- Password-protected PDFs are not currently supported for text extraction
- Some PDF features (forms, annotations, etc.) are not exposed in the API
- PDF combining uses the `pdfunite` command-line tool rather than a NIF (spawns external process)

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

## License

This project is available under the MIT License.

## Acknowledgments

- Built on top of the [Poppler](https://poppler.freedesktop.org/) PDF rendering library
- Uses [elixir_make](https://github.com/elixir-lang/elixir_make) for NIF compilation

