#include <erl_nif.h>
#include <poppler-document.h>
#include <poppler-page.h>
#include <poppler-page-renderer.h>
#include <poppler-image.h>
#include <string>
#include <vector>
#include <fstream>
#include <memory>

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

// Helper function to create error tuples
static ERL_NIF_TERM make_error(ErlNifEnv* env, const char* error_msg) {
    ERL_NIF_TERM binary;
    size_t len = strlen(error_msg);
    unsigned char* bin_data = enif_make_new_binary(env, len, &binary);
    memcpy(bin_data, error_msg, len);
    
    return enif_make_tuple2(env, 
        enif_make_atom(env, "error"),
        binary);
}

// Helper function to create ok tuples
static ERL_NIF_TERM make_ok(ErlNifEnv* env, ERL_NIF_TERM value) {
    return enif_make_tuple2(env,
        enif_make_atom(env, "ok"),
        value);
}

// Get page count from a PDF file
static ERL_NIF_TERM get_page_count_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 1) {
        return enif_make_badarg(env);
    }

    unsigned len;
    if (!enif_get_list_length(env, argv[0], &len)) {
        return enif_make_badarg(env);
    }

    std::vector<char> path(len + 1);
    if (enif_get_string(env, argv[0], path.data(), len + 1, ERL_NIF_LATIN1) <= 0) {
        return enif_make_badarg(env);
    }

    std::unique_ptr<poppler::document> doc(poppler::document::load_from_file(path.data()));
    
    if (!doc) {
        return make_error(env, "Failed to open PDF document");
    }

    if (doc->is_locked()) {
        return make_error(env, "PDF document is locked");
    }

    int page_count = doc->pages();
    return make_ok(env, enif_make_int(env, page_count));
}

// Get text content from a specific page or all pages
static ERL_NIF_TERM get_text_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 2) {
        return enif_make_badarg(env);
    }

    unsigned len;
    if (!enif_get_list_length(env, argv[0], &len)) {
        return enif_make_badarg(env);
    }

    std::vector<char> path(len + 1);
    if (enif_get_string(env, argv[0], path.data(), len + 1, ERL_NIF_LATIN1) <= 0) {
        return enif_make_badarg(env);
    }

    // Get page number (0-indexed, or -1 for all pages)
    int page_num;
    if (!enif_get_int(env, argv[1], &page_num)) {
        return enif_make_badarg(env);
    }

    std::unique_ptr<poppler::document> doc(poppler::document::load_from_file(path.data()));
    
    if (!doc) {
        return make_error(env, "Failed to open PDF document");
    }

    if (doc->is_locked()) {
        return make_error(env, "PDF document is locked");
    }

    int total_pages = doc->pages();
    
    if (page_num >= total_pages) {
        return make_error(env, "Page number out of range");
    }

    std::string result;
    
    if (page_num == -1) {
        // Extract text from all pages
        for (int i = 0; i < total_pages; i++) {
            std::unique_ptr<poppler::page> page(doc->create_page(i));
            if (page) {
                poppler::byte_array text_bytes = page->text().to_utf8();
                result.append(text_bytes.begin(), text_bytes.end());
                if (i < total_pages - 1) {
                    result += "\n\n--- Page " + std::to_string(i + 1) + " ---\n\n";
                }
            }
        }
    } else {
        // Extract text from specific page
        std::unique_ptr<poppler::page> page(doc->create_page(page_num));
        if (!page) {
            return make_error(env, "Failed to create page");
        }
        poppler::byte_array text_bytes = page->text().to_utf8();
        result.assign(text_bytes.begin(), text_bytes.end());
    }

    ERL_NIF_TERM binary;
    unsigned char* bin_data = enif_make_new_binary(env, result.size(), &binary);
    memcpy(bin_data, result.c_str(), result.size());
    
    return make_ok(env, binary);
}

// Combine multiple PDF files into one
static ERL_NIF_TERM combine_pdfs_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 2) {
        return enif_make_badarg(env);
    }

    // Get the list of input files
    unsigned input_list_len;
    if (!enif_get_list_length(env, argv[0], &input_list_len)) {
        return enif_make_badarg(env);
    }

    if (input_list_len == 0) {
        return make_error(env, "No input files provided");
    }

    // Get the output file path
    unsigned output_len;
    if (!enif_get_list_length(env, argv[1], &output_len)) {
        return enif_make_badarg(env);
    }

    std::vector<char> output_path(output_len + 1);
    if (enif_get_string(env, argv[1], output_path.data(), output_len + 1, ERL_NIF_LATIN1) <= 0) {
        return enif_make_badarg(env);
    }

    // Parse input file list
    std::vector<std::string> input_files;
    ERL_NIF_TERM head, tail = argv[0];
    
    while (enif_get_list_cell(env, tail, &head, &tail)) {
        unsigned file_len;
        if (!enif_get_list_length(env, head, &file_len)) {
            return enif_make_badarg(env);
        }
        
        std::vector<char> file_path(file_len + 1);
        if (enif_get_string(env, head, file_path.data(), file_len + 1, ERL_NIF_LATIN1) <= 0) {
            return enif_make_badarg(env);
        }
        
        input_files.push_back(std::string(file_path.data()));
    }

    // Note: Poppler C++ API doesn't directly support PDF merging
    // This is a limitation - we'll return an informative error
    // For actual PDF merging, you would need to use poppler's Glib interface
    // or a different library like libharu or qpdf

    return make_error(env, "PDF combining is not yet implemented - requires additional library support");
}

// Context for accumulating image data in memory
struct ImageBuffer {
    std::vector<unsigned char> data;
};

// Callback for stb_image_write functions
static void stbi_write_callback(void* context, void* data, int size) {
    ImageBuffer* buffer = static_cast<ImageBuffer*>(context);
    unsigned char* bytes = static_cast<unsigned char*>(data);
    buffer->data.insert(buffer->data.end(), bytes, bytes + size);
}

// Encode poppler::image to PNG or JPEG binary
// format: 0 = PNG, 1 = JPEG
// quality: JPEG quality (1-100)
static bool encode_image(const poppler::image& img, int format, int quality,
                         std::vector<unsigned char>& output) {
    if (!img.is_valid()) {
        return false;
    }

    int width = img.width();
    int height = img.height();
    int stride = img.bytes_per_row();
    const char* data = img.const_data();

    ImageBuffer buffer;

    // Determine number of components based on format
    poppler::image::format_enum img_format = img.format();
    int components;
    const unsigned char* pixel_data;
    std::vector<unsigned char> converted_data;

    if (img_format == poppler::image::format_argb32) {
        // ARGB32: Need to convert to RGB or RGBA for stb
        // On little-endian systems, ARGB32 is stored as BGRA
        components = 4;
        converted_data.resize(width * height * 4);

        for (int y = 0; y < height; y++) {
            const unsigned char* src_row =
                reinterpret_cast<const unsigned char*>(data + y * stride);
            unsigned char* dst_row = converted_data.data() + y * width * 4;

            for (int x = 0; x < width; x++) {
                // BGRA -> RGBA conversion
                unsigned char b = src_row[x * 4 + 0];
                unsigned char g = src_row[x * 4 + 1];
                unsigned char r = src_row[x * 4 + 2];
                unsigned char a = src_row[x * 4 + 3];

                dst_row[x * 4 + 0] = r;
                dst_row[x * 4 + 1] = g;
                dst_row[x * 4 + 2] = b;
                dst_row[x * 4 + 3] = a;
            }
        }
        pixel_data = converted_data.data();
    } else if (img_format == poppler::image::format_rgb24) {
        components = 3;
        pixel_data = reinterpret_cast<const unsigned char*>(data);
    } else {
        // Unsupported format
        return false;
    }

    int result;
    if (format == 0) {
        // PNG
        result = stbi_write_png_to_func(stbi_write_callback, &buffer,
                                        width, height, components,
                                        pixel_data,
                                        (img_format == poppler::image::format_argb32)
                                            ? width * 4 : stride);
    } else {
        // JPEG - use 3 components (no alpha)
        if (components == 4) {
            // Convert RGBA to RGB for JPEG
            std::vector<unsigned char> rgb_data(width * height * 3);
            for (int i = 0; i < width * height; i++) {
                rgb_data[i * 3 + 0] = converted_data[i * 4 + 0];
                rgb_data[i * 3 + 1] = converted_data[i * 4 + 1];
                rgb_data[i * 3 + 2] = converted_data[i * 4 + 2];
            }
            result = stbi_write_jpg_to_func(stbi_write_callback, &buffer,
                                            width, height, 3,
                                            rgb_data.data(), quality);
        } else {
            result = stbi_write_jpg_to_func(stbi_write_callback, &buffer,
                                            width, height, components,
                                            pixel_data, quality);
        }
    }

    if (result) {
        output = std::move(buffer.data);
        return true;
    }
    return false;
}

// Render PDF page(s) to image(s)
static ERL_NIF_TERM render_page_nif(ErlNifEnv* env, int argc,
                                    const ERL_NIF_TERM argv[]) {
    if (argc != 5) {
        return enif_make_badarg(env);
    }

    // Check if rendering is supported
    if (!poppler::page_renderer::can_render()) {
        return make_error(env, "PDF rendering not supported - Splash backend not available");
    }

    // Parse path argument
    unsigned len;
    if (!enif_get_list_length(env, argv[0], &len)) {
        return enif_make_badarg(env);
    }
    std::vector<char> path(len + 1);
    if (enif_get_string(env, argv[0], path.data(), len + 1, ERL_NIF_LATIN1) <= 0) {
        return enif_make_badarg(env);
    }

    // Parse page number (-1 for all pages)
    int page_num;
    if (!enif_get_int(env, argv[1], &page_num)) {
        return enif_make_badarg(env);
    }

    // Parse format (0 = PNG, 1 = JPEG)
    int format;
    if (!enif_get_int(env, argv[2], &format)) {
        return enif_make_badarg(env);
    }
    if (format < 0 || format > 1) {
        return make_error(env, "Invalid format: use 0 for PNG, 1 for JPEG");
    }

    // Parse DPI
    int dpi;
    if (!enif_get_int(env, argv[3], &dpi)) {
        return enif_make_badarg(env);
    }
    if (dpi <= 0 || dpi > 1200) {
        return make_error(env, "DPI must be between 1 and 1200");
    }

    // Parse quality (1-100)
    int quality;
    if (!enif_get_int(env, argv[4], &quality)) {
        return enif_make_badarg(env);
    }
    if (quality < 1 || quality > 100) {
        return make_error(env, "Quality must be between 1 and 100");
    }

    // Load PDF document
    std::unique_ptr<poppler::document> doc(
        poppler::document::load_from_file(path.data()));

    if (!doc) {
        return make_error(env, "Failed to open PDF document");
    }
    if (doc->is_locked()) {
        return make_error(env, "PDF document is locked");
    }

    int total_pages = doc->pages();

    if (page_num >= total_pages) {
        return make_error(env, "Page number out of range");
    }

    // Configure renderer
    poppler::page_renderer renderer;
    renderer.set_render_hint(poppler::page_renderer::antialiasing);
    renderer.set_render_hint(poppler::page_renderer::text_antialiasing);
    renderer.set_render_hint(poppler::page_renderer::text_hinting);

    if (page_num == -1) {
        // Render all pages - return list of binaries
        std::vector<ERL_NIF_TERM> image_terms;

        for (int i = 0; i < total_pages; i++) {
            std::unique_ptr<poppler::page> page(doc->create_page(i));
            if (!page) {
                return make_error(env, ("Failed to create page " +
                                        std::to_string(i)).c_str());
            }

            // Render page at specified DPI
            poppler::image img = renderer.render_page(page.get(), dpi, dpi);

            if (!img.is_valid()) {
                return make_error(env, ("Failed to render page " +
                                        std::to_string(i)).c_str());
            }

            // Encode to requested format
            std::vector<unsigned char> encoded;
            if (!encode_image(img, format, quality, encoded)) {
                return make_error(env, ("Failed to encode page " +
                                        std::to_string(i)).c_str());
            }

            // Create Erlang binary
            ERL_NIF_TERM binary;
            unsigned char* bin_data = enif_make_new_binary(env,
                                                           encoded.size(),
                                                           &binary);
            memcpy(bin_data, encoded.data(), encoded.size());
            image_terms.push_back(binary);
        }

        // Create list from vector
        ERL_NIF_TERM list = enif_make_list_from_array(env,
                                                       image_terms.data(),
                                                       image_terms.size());
        return make_ok(env, list);

    } else {
        // Render single page - return single binary
        std::unique_ptr<poppler::page> page(doc->create_page(page_num));
        if (!page) {
            return make_error(env, "Failed to create page");
        }

        poppler::image img = renderer.render_page(page.get(), dpi, dpi);

        if (!img.is_valid()) {
            return make_error(env, "Failed to render page");
        }

        std::vector<unsigned char> encoded;
        if (!encode_image(img, format, quality, encoded)) {
            return make_error(env, "Failed to encode image");
        }

        ERL_NIF_TERM binary;
        unsigned char* bin_data = enif_make_new_binary(env,
                                                        encoded.size(),
                                                        &binary);
        memcpy(bin_data, encoded.data(), encoded.size());

        return make_ok(env, binary);
    }
}

static ErlNifFunc nif_funcs[] = {
    {"get_page_count_nif", 1, get_page_count_nif, 0},
    {"get_text_nif", 2, get_text_nif, 0},
    {"combine_pdfs_nif", 2, combine_pdfs_nif, 0},
    {"render_page_nif", 5, render_page_nif, ERL_NIF_DIRTY_JOB_CPU_BOUND}
};

ERL_NIF_INIT(Elixir.Popplex.NIF, nif_funcs, NULL, NULL, NULL, NULL)
