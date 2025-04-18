CXX = g++
CXXFLAGS += -Wall -std=c++20 -march=native

SRC_DIR = src
LIB_DIR = lib
OBJ_DIR = target/obj
BIN_DIR = target
TARGET = $(BIN_DIR)/main

SUITESPARSE_BUILD = $(LIB_DIR)/suitesparse/lib/libcholmod.a \
					$(LIB_DIR)/suitesparse/lib/libsuitesparseconfig.a \
					$(LIB_DIR)/suitesparse/lib/libamd.a \
					$(LIB_DIR)/suitesparse/lib/libcamd.a \
					$(LIB_DIR)/suitesparse/lib/libcolamd.a \
					$(LIB_DIR)/suitesparse/lib/libccolamd.a

LAPACK_BUILD = $(LIB_DIR)/lapack/liblapack.a

BLAS_BUILD = $(LIB_DIR)/lapack/librefblas.a

LAPCAKE_BUILD = $(LIB_DIR)/lapack/liblapacke.a

# Find all subdirectories in lib/ to include them as -I
INCLUDES := $(LIB_DIR)/eigen \
			$(LIB_DIR)/fast_matrix_market/include \
			$(LIB_DIR)/suitesparse/include/Suitesparse

INCLUDE_FLAGS := $(addprefix -I, $(INCLUDES))

DEFINES := EIGEN_USE_LAPACKE
DEFINE_FLAGS := $(addprefix -D, $(DEFINES))

CXXFLAGS += $(INCLUDE_FLAGS)
CXXFLAGS += $(DEFINE_FLAGS)

# cholmod requires AMD, CAMD, COLAMD, CCOLAMD, the BLAS, and LAPACK, linking is done at load time so we force static linking
LDFLAGS += \
	$(LIB_DIR)/suitesparse/lib/libcholmod.a \
	$(LIB_DIR)/suitesparse/lib/libsuitesparseconfig.a \
	$(LIB_DIR)/suitesparse/lib/libamd.a \
	$(LIB_DIR)/suitesparse/lib/libcamd.a \
	$(LIB_DIR)/suitesparse/lib/libcolamd.a \
	$(LIB_DIR)/suitesparse/lib/libccolamd.a \
	$(LIB_DIR)/lapack/liblapacke.a

	ifeq ($(OS), Windows_NT)
DETECTED_OS = Windows
else
DETECTED_OS = $(shell uname)
endif

ifeq ($(DETECTED_OS), Windows)
LDFLAGS += -fopenmp
endif
ifeq ($(DETECTED_OS), Darwin)
CXXFLAGS += -I$(shell brew --prefix libomp)/include -D_OPENMP
LDFLAGS += \
	-L$(shell brew --prefix libomp)/lib \
	-framework Accelerate \
	-lomp
else
LDFLAGS += -fopenmp
endif

ifneq ($(DETECTED_OS), Darwin)
LDFLAGS += \
	$(LIB_DIR)/lapack/liblapack.a \
	$(LIB_DIR)/lapack/librefblas.a \
	-lgfortran
endif

# or
# LDFLAGS += -Wl,-rpath,$(LIB_DIR)/suitesparse/lib

# Find all .cpp files in src/
SRCS := $(wildcard $(SRC_DIR)/*.cpp)
# Convert the path of .cpp files to .o files under target/obj/
OBJS := $(patsubst $(SRC_DIR)/%.cpp, $(OBJ_DIR)/%.o, $(SRCS))

# Main rule
all: $(TARGET)

# Final link step
$(TARGET): $(OBJS)
	@mkdir -p $(BIN_DIR)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

# Rule to compile each .cpp to .o
# The compilation of suitesparse is put here because otherwise it does not find the header files
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp $(BLAS_BUILD) $(LAPACK_BUILD) $(LAPCAKE_BUILD) $(SUITESPARSE_BUILD) 
	@mkdir -p $(OBJ_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Options for building Suitesparse
CMAKE_OPTIONS += \
	-DSUITESPARSE_USE_64BIT_BLAS=ON

ifeq ($(DETECTED_OS), Windows)
CMAKE_OPTIONS += \
    -DBLAS_LIBRARIES='$(abspath $(LIB_DIR)/lapack/librefblas.a)' \
    -DLAPACK_LIBRARIES='$(abspath $(LIB_DIR)/lapack/liblapack.a)' \
    -DCMAKE_C_STANDARD_LIBRARIES='-lgfortran'
endif

# Build Suitesparse library
$(SUITESPARSE_BUILD):
	echo $(DETECTED_OS)
	$(MAKE) -C $(LIB_DIR)/suitesparse/SuiteSparse_config local CMAKE_OPTIONS="$(CMAKE_OPTIONS)"
	$(MAKE) -C $(LIB_DIR)/suitesparse/SuiteSparse_config install
	$(MAKE) -C $(LIB_DIR)/suitesparse/AMD local
	$(MAKE) -C $(LIB_DIR)/suitesparse/AMD install
	$(MAKE) -C $(LIB_DIR)/suitesparse/CAMD local
	$(MAKE) -C $(LIB_DIR)/suitesparse/CAMD install
	$(MAKE) -C $(LIB_DIR)/suitesparse/COLAMD local
	$(MAKE) -C $(LIB_DIR)/suitesparse/COLAMD install
	$(MAKE) -C $(LIB_DIR)/suitesparse/CCOLAMD local
	$(MAKE) -C $(LIB_DIR)/suitesparse/CCOLAMD install
	$(MAKE) -C $(LIB_DIR)/suitesparse/CHOLMOD local CMAKE_OPTIONS="$(CMAKE_OPTIONS)"
	$(MAKE) -C $(LIB_DIR)/suitesparse/CHOLMOD install

ifeq ($(DETECTED_OS), Windows)
# Build BLAS library
$(BLAS_BUILD):
	$(MAKE) -C $(LIB_DIR)/lapack blaslib

# Build LAPACK library
$(LAPACK_BUILD):
	$(MAKE) -C $(LIB_DIR)/lapack lapacklib
else
$(BLAS_BUILD):
$(LAPACK_BUILD):
endif

# Build LAPACKE library
$(LAPCAKE_BUILD):
	$(MAKE) -C $(LIB_DIR)/lapack lapackelib

# Clean everything
clean: clean-src clean-lib

# Clean only the source files and build artifacts
clean-src:
	rm -rf $(OBJ_DIR) $(TARGET)

# Clean only the libraries
clean-lib:
	$(MAKE) -C $(LIB_DIR)/lapack clean
	$(MAKE) -C $(LIB_DIR)/suitesparse purge

.PHONY: all clean clean-src clean-lib
