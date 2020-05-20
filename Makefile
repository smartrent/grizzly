# Makefile targets:
#
# all           build the package
# clean         clean build products and intermediates
#
# Variables to override:
#
# MIX_COMPILE_PATH path to the build's ebin directory
#
# CC            C compiler
# CROSSCOMPILE	crosscompiler prefix, if any
# CFLAGS	compiler flags for compiling all C files
# LDFLAGS	linker flags for linking all binaries

ifneq ($(ZIPGATEWAY_SKIP_COMPILE),)
TARGETS = skip
else
TOP := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
ZIPGATEWAY_SOURCE ?= $(TOP)/src

PREFIX = $(MIX_COMPILE_PATH)/../priv
BUILD  = $(MIX_COMPILE_PATH)/../obj

PATCH_DIR = $(TOP)/patches

CMAKE_OPTS += -DDISABLE_MOCK=ON -DBUILD_TESTING=OFF

ZIPGATEWAY_BIN ?= $(BUILD)/zipgateway

ifeq ($(wildcard $(ZIPGATEWAY_SOURCE)/CMakeLists.txt),)
TARGETS = no_source
else
TARGETS += $(PREFIX)/zipgateway
endif

ifneq ($(wildcard $(ZIPGATEWAY_BIN)),)
# Skip compilation if a binary is provided or already present
$(shell cp $(ZIPGATEWAY_BIN) $(PREFIX)/zipgateway)
TARGETS = ready
endif

MAKE_ENV = KCONFIG_NOTIMESTAMP=1

ifneq ($(CROSSCOMPILE),)
MAKE_OPTS += CROSS_COMPILE="$(CROSSCOMPILE)-"
endif

ifeq ($(shell uname -s),Darwin)
# Fixes to build on OSX
MAKE = $(shell which gmake)
ifeq ($(MAKE),)
    $(error gmake required to build. Install by running "brew install homebrew/core/make")
endif

SED = $(shell which gsed)
ifeq ($(SED),)
    $(error gsed required to build. Install by running "brew install gnu-sed")
endif

MAKE_OPTS += SED=$(SED)

ifeq ($(shell brew list --versions bison),)
    $(error bison required to build. Install by running "brew install bison")
endif

CMAKE_OPTS += -DBISON_EXECUTABLE=$(shell brew --prefix bison)/bin/bison -DPYTHON_EXECUTABLE=/usr/bin/python2.7
endif

# Set options for Nerves targets
ifneq ($(MIX_TARGET),host)
CMAKE_ENV = PKG_CONFIG_PATH="$(NERVES_SDK_SYSROOT)/usr/lib/pkgconfig" PKG_CONFIG_SYSROOT_DIR="$(NERVES_SDK_SYSROOT)"
CMAKE_OPTS += -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
    -DCMAKE_SYSTEM_PROCESSOR=armhf \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_SYSTEM_VERSION=1 \
    -DCMAKE_FIND_ROOT_PATH=$(NERVES_SDK_SYSROOT) \
    -DCMAKE_C_COMPILER=$(CC) \
    -DCMAKE_CXX_COMPILER=$(CXX) \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DDEBUG_ALLOW_NONSECURE=OFF \
    -DNO_ZW_NVM=ON
endif
endif

calling_from_make:
	mix compile

all: $(TARGETS)

skip:
	@echo "Skipping zipgateway compilation"

cmake: $(PREFIX) $(BUILD) $(ZIPGATEWAY_SOURCE)/.patched
	$(CMAKE_ENV) cmake $(CMAKE_OPTS) -S $(ZIPGATEWAY_SOURCE) -B $(BUILD)

ready:
	@echo "Using zipgateway binary: $(ZIPGATEWAY_BIN)"

no_source:
	@echo "\033[33mZIPGATEWAY_SOURCE is unset and no zipgateway bin was found - Skipping compilation\n\n\
If you are supplying your own zipgateway binary, set the path\n\
in ZIPGATEWAY_BIN when compiling:\n\n\
\tZIPGATEWAY_BIN=/path/to/zipgateway mix compile\n\n\
or in your config.exs\n\n\
\tSystem.put_env("ZIPGATEWAY_BIN", "/path/to/bin")\n\n\
To compile zipgateway for your system, follow the instructions in\n\
https://hexdocs.pm/grizzly/readme.html#compile-and-configure-zipgateway \033[0m"

$(BUILD)/zipgateway: cmake
	$(MAKE_ENV) $(MAKE) $(MAKE_OPTS) -C $(BUILD)

$(PREFIX)/zipgateway: $(BUILD)/zipgateway
	cp $< $@

$(PREFIX) $(BUILD):
	mkdir -p $@

$(ZIPGATEWAY_SOURCE)/.patched:
	cd $(ZIPGATEWAY_SOURCE); \
	for patch in $$(ls $(PATCH_DIR)); do \
        patch -p1 < "$(PATCH_DIR)/$$patch"; \
	done
	touch $(ZIPGATEWAY_SOURCE)/.patched

clean:
	rm -rf $(BUILD)/* $(PREFIX)/zipgateway

.PHONY: all clean calling_from_make
