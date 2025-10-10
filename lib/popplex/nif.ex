defmodule Popplex.NIF do
  @moduledoc """
  Low-level NIF interface to Poppler C++ library.

  This module provides direct access to the NIF functions.
  Most users should use the `Popplex` module instead.
  """

  @on_load :load_nif

  def load_nif do
    nif_path =
      :popplex
      |> :code.priv_dir()
      |> Path.join("popplex_nif")
      |> to_charlist()

    :erlang.load_nif(nif_path, 0)
  end

  @doc """
  Gets the page count of a PDF file.

  Returns `{:ok, count}` or `{:error, reason}`.
  """
  def get_page_count_nif(_path) do
    exit(:nif_library_not_loaded)
  end

  @doc """
  Gets text content from a PDF file.

  Parameters:
  - `path`: Path to the PDF file
  - `page`: Page number (0-indexed) or -1 for all pages

  Returns `{:ok, text}` or `{:error, reason}`.
  """
  def get_text_nif(_path, _page) do
    exit(:nif_library_not_loaded)
  end

  @doc """
  Combines multiple PDF files into one.

  Parameters:
  - `input_files`: List of PDF file paths to combine
  - `output_file`: Path for the output PDF file

  Returns `{:ok, output_path}` or `{:error, reason}`.

  Note: This function is currently not implemented in the C++ layer.
  """
  def combine_pdfs_nif(_input_files, _output_file) do
    exit(:nif_library_not_loaded)
  end
end
