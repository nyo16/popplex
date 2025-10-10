defmodule PopplexTest do
  use ExUnit.Case
  doctest Popplex

  @moduledoc """
  Tests for Popplex PDF operations.

  Note: These tests require actual PDF files to run successfully.
  Create a `test/fixtures` directory with sample PDF files for testing.
  """

  describe "get_page_count/1" do
    test "returns error for non-existent file" do
      assert {:error, _reason} = Popplex.get_page_count("nonexistent.pdf")
    end

    @tag :integration
    test "returns page count for valid PDF" do
      # This test requires a valid PDF file in test/fixtures/sample.pdf
      # Create this file manually for integration testing
      pdf_path = Path.join([__DIR__, "fixtures", "sample.pdf"])

      if File.exists?(pdf_path) do
        assert {:ok, count} = Popplex.get_page_count(pdf_path)
        assert is_integer(count)
        assert count > 0
      else
        IO.puts("Skipping integration test - no sample PDF found at #{pdf_path}")
      end
    end

    test "accepts charlist paths" do
      assert {:error, _reason} = Popplex.get_page_count(~c"nonexistent.pdf")
    end
  end

  describe "get_text/2" do
    test "returns error for non-existent file" do
      assert {:error, _reason} = Popplex.get_text("nonexistent.pdf")
    end

    @tag :integration
    test "extracts text from all pages by default" do
      pdf_path = Path.join([__DIR__, "fixtures", "sample.pdf"])

      if File.exists?(pdf_path) do
        assert {:ok, text} = Popplex.get_text(pdf_path)
        assert is_binary(text)
      else
        IO.puts("Skipping integration test - no sample PDF found at #{pdf_path}")
      end
    end

    @tag :integration
    test "extracts text from specific page" do
      pdf_path = Path.join([__DIR__, "fixtures", "sample.pdf"])

      if File.exists?(pdf_path) do
        assert {:ok, text} = Popplex.get_text(pdf_path, page: 0)
        assert is_binary(text)
      else
        IO.puts("Skipping integration test - no sample PDF found at #{pdf_path}")
      end
    end

    @tag :integration
    test "returns error for invalid page number" do
      pdf_path = Path.join([__DIR__, "fixtures", "sample.pdf"])

      if File.exists?(pdf_path) do
        assert {:error, _reason} = Popplex.get_text(pdf_path, page: 9999)
      else
        IO.puts("Skipping integration test - no sample PDF found at #{pdf_path}")
      end
    end
  end

  describe "combine_pdfs/2" do
    @tag :integration
    test "returns not implemented error" do
      # This feature is not yet implemented in the NIF
      result = Popplex.combine_pdfs(["file1.pdf", "file2.pdf"], "output.pdf")
      assert {:error, reason} = result
      assert is_binary(reason)
      assert String.contains?(reason, "not yet implemented")
    end
  end
end
