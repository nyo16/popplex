# Detect OS
UNAME_S := $(shell uname -s)

# Erlang include path
ERL_INCLUDE_PATH ?= $(shell erl -noshell -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s erlang halt)

# Output directory
PRIV_DIR = $(MIX_APP_PATH)/priv
NIF_SO = $(PRIV_DIR)/popplex_nif.so

# Compiler flags
CXXFLAGS = -fPIC -I$(ERL_INCLUDE_PATH) -std=c++11 -Wall -Wextra -O3

# Linker flags
LDFLAGS = -shared

# OS-specific configurations
ifeq ($(UNAME_S),Darwin)
    # macOS
    LDFLAGS += -undefined dynamic_lookup -dynamiclib
    POPPLER_CFLAGS = $(shell pkg-config --cflags poppler-cpp)
    POPPLER_LIBS = $(shell pkg-config --libs poppler-cpp)
else ifeq ($(UNAME_S),Linux)
    # Linux
    POPPLER_CFLAGS = $(shell pkg-config --cflags poppler-cpp)
    POPPLER_LIBS = $(shell pkg-config --libs poppler-cpp)
else
    $(error Unsupported operating system: $(UNAME_S))
endif

CXXFLAGS += $(POPPLER_CFLAGS)
LDFLAGS += $(POPPLER_LIBS)

# Source files
SRC = c_src/popplex_nif.cpp

all: $(PRIV_DIR) $(NIF_SO)

$(PRIV_DIR):
	mkdir -p $(PRIV_DIR)

$(NIF_SO): $(SRC)
	$(CXX) $(CXXFLAGS) $(SRC) $(LDFLAGS) -o $(NIF_SO)

clean:
	rm -f $(NIF_SO)

.PHONY: all clean
