defmodule Popplex do
  @moduledoc """
  Popplex - Elixir NIF wrapper for Poppler PDF library.

  This module provides a high-level API for working with PDF files using
  the Poppler library through a Native Implemented Function (NIF).

  ## Features

  - Get page count from PDF files
  - Extract text content from PDF files (by page or entire document)
  - Combine multiple PDF files
  - Render PDF pages to images (PNG, JPEG)

  ## Examples

      # Get the number of pages in a PDF
      {:ok, count} = Popplex.get_page_count("document.pdf")

      # Extract text from all pages
      {:ok, text} = Popplex.get_text("document.pdf")

      # Extract text from a specific page (0-indexed)
      {:ok, text} = Popplex.get_text("document.pdf", page: 0)

      # Render a page to PNG
      {:ok, png_data} = Popplex.render_page("document.pdf", page: 0)
      File.write!("page.png", png_data)
  """

  alias Popplex.NIF

  @type page_count :: non_neg_integer()
  @type error_reason :: String.t()
  @type image_format :: :png | :jpeg
  @type render_opts :: [
          page: non_neg_integer(),
          all: boolean(),
          format: image_format(),
          dpi: pos_integer(),
          quality: 1..100
        ]

  @doc """
  Gets the total number of pages in a PDF file.

  ## Parameters

  - `path`: Path to the PDF file (string or charlist)

  ## Returns

  - `{:ok, page_count}` on success
  - `{:error, reason}` on failure

  ## Examples

      Popplex.get_page_count("my_document.pdf")
      # => {:ok, 42}

      Popplex.get_page_count("nonexistent.pdf")
      # => {:error, "Failed to open PDF document"}
  """
  @spec get_page_count(Path.t()) :: {:ok, page_count()} | {:error, error_reason()}
  def get_page_count(path) when is_binary(path) do
    path
    |> to_charlist()
    |> NIF.get_page_count_nif()
  end

  def get_page_count(path) when is_list(path) do
    NIF.get_page_count_nif(path)
  end

  @doc """
  Extracts text content from a PDF file.

  ## Parameters

  - `path`: Path to the PDF file (string or charlist)
  - `opts`: Options keyword list
    - `:page` - Page number to extract (0-indexed). If not provided, extracts all pages.
    - `:all` - If true, extracts all pages (default behavior)

  ## Returns

  - `{:ok, text}` on success, where text is a binary string
  - `{:error, reason}` on failure

  ## Examples

      # Extract text from all pages
      Popplex.get_text("document.pdf")
      # => {:ok, "Full document text..."}

      # Extract text from page 1 (0-indexed)
      Popplex.get_text("document.pdf", page: 0)
      # => {:ok, "First page text..."}

      # Explicitly extract all pages
      Popplex.get_text("document.pdf", all: true)
      # => {:ok, "Full document text..."}
  """
  @spec get_text(Path.t(), keyword()) :: {:ok, binary()} | {:error, error_reason()}
  def get_text(path, opts \\ []) when is_binary(path) or is_list(path) do
    charlist_path = if is_binary(path), do: to_charlist(path), else: path

    page_num =
      cond do
        Keyword.has_key?(opts, :page) -> Keyword.get(opts, :page)
        Keyword.get(opts, :all, false) -> -1
        # Default to all pages
        true -> -1
      end

    NIF.get_text_nif(charlist_path, page_num)
  end

  @doc """
  Combines multiple PDF files into a single output file.

  Uses the `pdfunite` command-line tool (part of Poppler utilities) to merge PDFs.

  ## Parameters

  - `input_files`: List of PDF file paths to combine (minimum 2 files)
  - `output_file`: Path where the combined PDF should be saved

  ## Returns

  - `{:ok, output_path}` on success
  - `{:error, reason}` on failure

  ## Examples

      Popplex.combine_pdfs(["file1.pdf", "file2.pdf"], "combined.pdf")
      # => {:ok, "combined.pdf"}

      Popplex.combine_pdfs(["page1.pdf", "page2.pdf", "page3.pdf"], "book.pdf")
      # => {:ok, "book.pdf"}

  ## Requirements

  This function requires `pdfunite` to be installed on your system:

  - **macOS**: `brew install poppler` (included with Poppler)
  - **Ubuntu/Debian**: `sudo apt-get install poppler-utils`
  - **Fedora/RHEL**: `sudo dnf install poppler-utils`
  """
  @spec combine_pdfs([Path.t()], Path.t()) :: {:ok, Path.t()} | {:error, error_reason()}
  def combine_pdfs(input_files, output_file)
      when is_list(input_files) and is_binary(output_file) do
    cond do
      length(input_files) < 2 ->
        {:error, "At least 2 input files are required"}

      not Enum.all?(input_files, &File.exists?/1) ->
        missing = Enum.reject(input_files, &File.exists?/1)
        {:error, "Input files not found: #{Enum.join(missing, ", ")}"}

      true ->
        execute_pdfunite(input_files, output_file)
    end
  end

  defp execute_pdfunite(input_files, output_file) do
    args = input_files ++ [output_file]

    case System.cmd("pdfunite", args, stderr_to_stdout: true) do
      {_, 0} ->
        {:ok, output_file}

      {error_msg, _exit_code} ->
        error_msg = String.trim(error_msg)
        {:error, "Failed to combine PDFs: #{error_msg}"}
    end
  rescue
    e in ErlangError ->
      case e.original do
        :enoent -> {:error, "pdfunite command not found. Please install poppler-utils."}
        _ -> {:error, "System error: #{Exception.message(e)}"}
      end
  end

  @doc """
  Renders PDF pages to images.

  ## Parameters

  - `path`: Path to the PDF file (string or charlist)
  - `opts`: Options keyword list
    - `:page` - Page number to render (0-indexed). If not provided, renders all pages.
    - `:all` - If true, renders all pages (default behavior)
    - `:format` - Output format: `:png` (default) or `:jpeg`
    - `:dpi` - Resolution in dots per inch (default: 150)
    - `:quality` - JPEG quality 1-100 (default: 90, ignored for PNG)

  ## Returns

  - `{:ok, binary}` for single page - raw image binary data
  - `{:ok, [binary]}` for all pages - list of raw image binary data
  - `{:error, reason}` on failure

  ## Examples

      # Render first page as PNG at 150 DPI
      {:ok, png_data} = Popplex.render_page("document.pdf", page: 0)
      File.write!("page1.png", png_data)

      # Render all pages as JPEG at 300 DPI
      {:ok, images} = Popplex.render_page("document.pdf", format: :jpeg, dpi: 300)

      # Render specific page as high-quality JPEG
      {:ok, jpeg_data} = Popplex.render_page("document.pdf", page: 2, format: :jpeg, quality: 95)

  ## Requirements

  This function requires Poppler to be compiled with the Splash rendering backend.
  Most standard Poppler installations include this support.
  """
  @spec render_page(Path.t(), render_opts()) ::
          {:ok, binary()} | {:ok, [binary()]} | {:error, error_reason()}
  def render_page(path, opts \\ []) when is_binary(path) or is_list(path) do
    charlist_path = if is_binary(path), do: to_charlist(path), else: path

    page_num =
      cond do
        Keyword.has_key?(opts, :page) -> Keyword.get(opts, :page)
        Keyword.get(opts, :all, false) -> -1
        # Default to all pages
        true -> -1
      end

    format =
      case Keyword.get(opts, :format, :png) do
        :png -> 0
        :jpeg -> 1
        _ -> 0
      end

    dpi = Keyword.get(opts, :dpi, 150)
    quality = Keyword.get(opts, :quality, 90)

    NIF.render_page_nif(charlist_path, page_num, format, dpi, quality)
  end
end
