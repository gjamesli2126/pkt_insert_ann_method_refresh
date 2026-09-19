# Native Apple Silicon builds. Run here, or use make -C build_on_mac.
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:

# Keep relative source paths and cleanup paths anchored to this directory.
ifneq ($(abspath .),$(abspath $(dir $(lastword $(MAKEFILE_LIST)))))
$(error Run make -C build_on_mac instead of make -f build_on_mac/Makefile)
endif

# GNU Make's built-in CXX is g++; use Apple Clang unless explicitly overridden.
ifeq ($(origin CXX),default)
CXX := xcrun clang++
endif
CXX ?= xcrun clang++
CXXFLAGS ?= -O2
COMPILE_FLAGS := -arch arm64 -std=c++26

ifeq ($(origin LIBOMP_PREFIX),undefined)
LIBOMP_PREFIX := $(shell brew --prefix libomp 2>/dev/null)
endif
OPENMP_FLAGS = -Xpreprocessor -fopenmp -I"$(LIBOMP_PREFIX)/include"
OPENMP_LIBS = -L"$(LIBOMP_PREFIX)/lib" -Wl,-rpath,"$(LIBOMP_PREFIX)/lib" -lomp

CLASSBENCH := ../classbench-packet-classification
NETWORK := ../network-packet-classification
DB_SOURCES := $(wildcard $(CLASSBENCH)/db_generator/*.cc)
TRACE_SOURCES := $(wildcard $(CLASSBENCH)/trace_generator/*.cc)
NETWORK_SOURCES := $(addprefix $(NETWORK)/,main.cpp io/input.cpp \
    io/inputFile_test.cpp lib/equivalentPri.cpp lib/checkCovered_one.cpp \
    lib/hyperrectangleCoverChecker.cpp)

DB_OBJECTS := $(patsubst $(CLASSBENCH)/db_generator/%.cc,build/classbench/obj/db_generator/%.o,$(DB_SOURCES))
TRACE_OBJECTS := $(patsubst $(CLASSBENCH)/trace_generator/%.cc,build/classbench/obj/trace_generator/%.o,$(TRACE_SOURCES))
NETWORK_OBJECTS := $(patsubst $(NETWORK)/%.cpp,build/network/obj/%.o,$(NETWORK_SOURCES))
OBJECTS := $(DB_OBJECTS) $(TRACE_OBJECTS) $(NETWORK_OBJECTS)

.PHONY: all classbench network check-submodules check-openmp clean clean-data clean-all help

all: classbench network

classbench: build/classbench/db_generator build/classbench/trace_generator

network: build/network/m

check-submodules:
	@test -f "$(CLASSBENCH)/db_generator/db_generator.cc" && \
	    test -f "$(NETWORK)/main.cpp" || { \
	    printf '%s\n' 'Missing submodules: run git submodule update --init --recursive from the parent repository.' >&2; exit 1; }

check-openmp:
	@test -f "$(LIBOMP_PREFIX)/include/omp.h" && \
	    test -f "$(LIBOMP_PREFIX)/lib/libomp.dylib" || { \
	    printf '%s\n' 'OpenMP not found: run brew install libomp, or set LIBOMP_PREFIX=/path/to/libomp.' >&2; exit 1; }

$(OBJECTS): | check-submodules
$(NETWORK_OBJECTS): | check-openmp

build/classbench/obj/db_generator/%.o: $(CLASSBENCH)/db_generator/%.cc Makefile
	@mkdir -p "$(@D)"
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(COMPILE_FLAGS) -MMD -MP -c "$<" -o "$@"

build/classbench/obj/trace_generator/%.o: $(CLASSBENCH)/trace_generator/%.cc Makefile
	@mkdir -p "$(@D)"
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(COMPILE_FLAGS) -MMD -MP -c "$<" -o "$@"

build/network/obj/%.o: $(NETWORK)/%.cpp Makefile
	@mkdir -p "$(@D)"
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(COMPILE_FLAGS) $(OPENMP_FLAGS) \
	    -I"$(NETWORK)/io" -I"$(NETWORK)/lib" -MMD -MP -c "$<" -o "$@"

build/classbench/db_generator: $(DB_OBJECTS) Makefile | check-submodules
	@mkdir -p "$(@D)"
	$(CXX) $(CXXFLAGS) $(COMPILE_FLAGS) $(LDFLAGS) $(DB_OBJECTS) $(LDLIBS) -o "$@"

build/classbench/trace_generator: $(TRACE_OBJECTS) Makefile | check-submodules
	@mkdir -p "$(@D)"
	$(CXX) $(CXXFLAGS) $(COMPILE_FLAGS) $(LDFLAGS) $(TRACE_OBJECTS) $(LDLIBS) -o "$@"

build/network/m: $(NETWORK_OBJECTS) Makefile | check-submodules check-openmp
	@mkdir -p "$(@D)"
	$(CXX) $(CXXFLAGS) $(COMPILE_FLAGS) $(LDFLAGS) $(NETWORK_OBJECTS) $(OPENMP_LIBS) $(LDLIBS) -o "$@"

clean:
	rm -rf -- ./build

clean-data:
	./clean_data_logs.sh

clean-all:
	./clean_build_data_logs.sh

help:
	@printf '%s\n' \
	    'make [-j4]      Build both projects with -std=c++26 for arm64' \
	    'make classbench Build db_generator and trace_generator' \
	    'make network    Build the network analysis executable m' \
	    'make clean      Delete build/ (binaries, objects, dependency files)' \
	    'make clean-data Delete data/ and logs/; keep build/' \
	    'make clean-all  Delete build/, data/, and logs/' \
	    'All cleanup targets keep INFO/ reports, guides, and submodule sources.' \
	    'After changing CXX/CXXFLAGS/CPPFLAGS/LDFLAGS/LDLIBS/LIBOMP_PREFIX, run make clean before rebuilding.'

-include $(OBJECTS:.o=.d)
