defmodule Popplex do
  @moduledoc """
  Popplex - Elixir NIF wrapper for Poppler PDF library.

  This module provides a high-level API for working with PDF files using
  the Poppler library through a Native Implemented Function (NIF).

  ## Features

  - Get page count from PDF files
  - Extract text content from PDF files (by page or entire document)
  - Combine multiple PDF files (planned feature)

  ## Examples

      # Get the number of pages in a PDF
      {:ok, count} = Popplex.get_page_count("document.pdf")

      # Extract text from all pages
      {:ok, text} = Popplex.get_text("document.pdf")

      # Extract text from a specific page (0-indexed)
      {:ok, text} = Popplex.get_text("document.pdf", page: 0)
  """

  alias Popplex.NIF

  @type page_count :: non_neg_integer()
  @type error_reason :: String.t()

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

  ## Parameters

  - `input_files`: List of PDF file paths to combine
  - `output_file`: Path where the combined PDF should be saved

  ## Returns

  - `{:ok, output_path}` on success
  - `{:error, reason}` on failure

  ## Examples

      Popplex.combine_pdfs(["file1.pdf", "file2.pdf"], "combined.pdf")
      # => {:ok, "combined.pdf"}

  ## Note

  This feature is not yet fully implemented. The Poppler C++ API has limited
  support for PDF manipulation. For production use, consider using additional
  libraries like QPDF or similar tools.
  """
  @spec combine_pdfs([Path.t()], Path.t()) :: {:ok, Path.t()} | {:error, error_reason()}
  def combine_pdfs(input_files, output_file)
      when is_list(input_files) and is_binary(output_file) do
    charlist_inputs =
      Enum.map(input_files, fn file ->
        if is_binary(file), do: to_charlist(file), else: file
      end)

    charlist_output = if is_binary(output_file), do: to_charlist(output_file), else: output_file

    case NIF.combine_pdfs_nif(charlist_inputs, charlist_output) do
      {:ok, _} -> {:ok, output_file}
      error -> error
    end
  end
end
