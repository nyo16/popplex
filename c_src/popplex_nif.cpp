#include <erl_nif.h>
#include <poppler-document.h>
#include <poppler-page.h>
#include <string>
#include <vector>
#include <fstream>
#include <memory>

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

static ErlNifFunc nif_funcs[] = {
    {"get_page_count_nif", 1, get_page_count_nif, 0},
    {"get_text_nif", 2, get_text_nif, 0},
    {"combine_pdfs_nif", 2, combine_pdfs_nif, 0}
};

ERL_NIF_INIT(Elixir.Popplex.NIF, nif_funcs, NULL, NULL, NULL, NULL)
