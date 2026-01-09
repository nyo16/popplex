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
    test "returns error for less than 2 files" do
      assert {:error, reason} = Popplex.combine_pdfs(["single.pdf"], "output.pdf")
      assert reason == "At least 2 input files are required"
    end

    test "returns error for non-existent files" do
      assert {:error, reason} =
               Popplex.combine_pdfs(["missing1.pdf", "missing2.pdf"], "output.pdf")

      assert String.contains?(reason, "not found")
      assert String.contains?(reason, "missing1.pdf")
    end

    @tag :integration
    test "successfully combines multiple PDFs" do
      # Use the sample.pdf twice to create a combined PDF
      input1 = Path.join([__DIR__, "fixtures", "sample.pdf"])
      input2 = Path.join([__DIR__, "fixtures", "sample.pdf"])
      output = Path.join([System.tmp_dir!(), "combined_test.pdf"])

      # Clean up any previous test file
      File.rm(output)

      if File.exists?(input1) do
        assert {:ok, ^output} = Popplex.combine_pdfs([input1, input2], output)
        assert File.exists?(output)

        # Verify the combined PDF has 6 pages (3 + 3)
        assert {:ok, 6} = Popplex.get_page_count(output)

        # Clean up
        File.rm(output)
      else
        IO.puts("Skipping integration test - no sample PDF found")
      end
    end

    @tag :integration
    test "combines three PDFs correctly" do
      input = Path.join([__DIR__, "fixtures", "sample.pdf"])
      output = Path.join([System.tmp_dir!(), "combined_three.pdf"])

      # Clean up any previous test file
      File.rm(output)

      if File.exists?(input) do
        assert {:ok, ^output} = Popplex.combine_pdfs([input, input, input], output)
        assert File.exists?(output)

        # Verify the combined PDF has 9 pages (3 + 3 + 3)
        assert {:ok, 9} = Popplex.get_page_count(output)

        # Clean up
        File.rm(output)
      else
        IO.puts("Skipping integration test - no sample PDF found")
      end
    end
  end

  describe "render_page/2" do
    test "returns error for non-existent file" do
      assert {:error, _reason} = Popplex.render_page("nonexistent.pdf")
    end

    test "returns error for invalid page number" do
      pdf_path = Path.join([__DIR__, "fixtures", "sample.pdf"])

      if File.exists?(pdf_path) do
        assert {:error, _reason} = Popplex.render_page(pdf_path, page: 9999)
      end
    end

    test "accepts charlist paths" do
      assert {:error, _reason} = Popplex.render_page(~c"nonexistent.pdf")
    end

    @tag :integration
    test "renders single page as PNG" do
      pdf_path = Path.join([__DIR__, "fixtures", "sample.pdf"])

      if File.exists?(pdf_path) do
        assert {:ok, png_data} = Popplex.render_page(pdf_path, page: 0)
        assert is_binary(png_data)
        # PNG magic bytes
        assert <<0x89, 0x50, 0x4E, 0x47, _rest::binary>> = png_data
      else
        IO.puts("Skipping integration test - no sample PDF found at #{pdf_path}")
      end
    end

    @tag :integration
    test "renders single page as JPEG" do
      pdf_path = Path.join([__DIR__, "fixtures", "sample.pdf"])

      if File.exists?(pdf_path) do
        assert {:ok, jpeg_data} = Popplex.render_page(pdf_path, page: 0, format: :jpeg)
        assert is_binary(jpeg_data)
        # JPEG magic bytes (SOI marker)
        assert <<0xFF, 0xD8, _rest::binary>> = jpeg_data
      else
        IO.puts("Skipping integration test - no sample PDF found at #{pdf_path}")
      end
    end

    @tag :integration
    test "renders all pages returns list of binaries" do
      pdf_path = Path.join([__DIR__, "fixtures", "sample.pdf"])

      if File.exists?(pdf_path) do
        {:ok, page_count} = Popplex.get_page_count(pdf_path)
        assert {:ok, images} = Popplex.render_page(pdf_path)
        assert is_list(images)
        assert length(images) == page_count

        Enum.each(images, fn img ->
          assert is_binary(img)
          # Verify PNG format
          assert <<0x89, 0x50, 0x4E, 0x47, _rest::binary>> = img
        end)
      else
        IO.puts("Skipping integration test - no sample PDF found at #{pdf_path}")
      end
    end

    @tag :integration
    test "respects DPI parameter" do
      pdf_path = Path.join([__DIR__, "fixtures", "sample.pdf"])

      if File.exists?(pdf_path) do
        {:ok, low_dpi} = Popplex.render_page(pdf_path, page: 0, dpi: 72)
        {:ok, high_dpi} = Popplex.render_page(pdf_path, page: 0, dpi: 300)
        # Higher DPI should produce larger image data
        assert byte_size(high_dpi) > byte_size(low_dpi)
      else
        IO.puts("Skipping integration test - no sample PDF found at #{pdf_path}")
      end
    end

    @tag :integration
    test "respects JPEG quality parameter" do
      pdf_path = Path.join([__DIR__, "fixtures", "sample.pdf"])

      if File.exists?(pdf_path) do
        {:ok, low_quality} =
          Popplex.render_page(pdf_path, page: 0, format: :jpeg, quality: 10)

        {:ok, high_quality} =
          Popplex.render_page(pdf_path, page: 0, format: :jpeg, quality: 95)

        # Higher quality should produce larger file
        assert byte_size(high_quality) > byte_size(low_quality)
      else
        IO.puts("Skipping integration test - no sample PDF found at #{pdf_path}")
      end
    end
  end
end
