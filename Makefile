CXX = g++
CXXFLAGS += -Wall -std=c++20 -march=native

ifeq ($(OS), Windows_NT)
DETECTED_OS = Windows
else
DETECTED_OS = $(shell uname)
endif

SRC_DIR = src
LIB_DIR = lib
OBJ_DIR = target/obj
BIN_DIR = target
TARGET = $(BIN_DIR)/main

SUITESPARSE_BUILD = \
	$(LIB_DIR)/suitesparse/lib/libsuitesparseconfig.a \
	$(LIB_DIR)/suitesparse/lib/libamd.a \
	$(LIB_DIR)/suitesparse/lib/libcamd.a \
	$(LIB_DIR)/suitesparse/lib/libcolamd.a \
	$(LIB_DIR)/suitesparse/lib/libccolamd.a \
	$(LIB_DIR)/suitesparse/lib/libcholmod.a

# Find all subdirectories in lib/ to include them as -I
INCLUDES := $(LIB_DIR)/eigen \
			$(LIB_DIR)/fast_matrix_market/include \
			$(LIB_DIR)/suitesparse/include/Suitesparse

ifneq ($(DETECTED_OS), Darwin)
ifeq ($(MKLROOT),)
$(warning MKLROOT is not set. Please set the variables needed for Intel MKL.)
$(warning In Linux, you can set it with: source /opt/intel/oneapi/setvars.sh)
$(warning In Windows, you can set it with: call "C:\Program Files (x86)\Intel\oneAPI\setvars.bat")
endif
MKL_INCLUDE = '$(MKLROOT)/include'
INCLUDES += $(MKL_INCLUDE)
DEFINES := EIGEN_USE_MKL_ALL
else
DEFINES := EIGEN_USE_LAPACK EIGEN_USE_BLAS
endif

INCLUDE_FLAGS := $(addprefix -I, $(INCLUDES))
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
	$(LIB_DIR)/suitesparse/lib/libccolamd.a

ifeq ($(DETECTED_OS), Darwin)
CXXFLAGS += -I$(shell brew --prefix libomp)/include -D_OPENMP
LDFLAGS += \
	-L$(shell brew --prefix libomp)/lib -lomp \
	-framework Accelerate \
	# -L$(shell brew --prefix lapack)/lib -llapacke -lblas -llapack
else
LDFLAGS += -fopenmp -Wl,--start-group -lmkl_intel_ilp64 -lmkl_intel_thread -lmkl_core -Wl,--end-group -liomp5 -lpthread -lm -ldl
endif

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
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp $(SUITESPARSE_BUILD) 
	@mkdir -p $(OBJ_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Options for building Suitesparse
ifeq ($(DETECTED_OS), Darwin)
CMAKE_OPTIONS += \
    -DBLA_VENDOR=Apple # Apple Accelerate framework
else
# Intel MKL
CMAKE_OPTIONS += \
	-DBLA_VENDOR=Intel10_64ilp \
    -DSUITESPARSE_USE_64BIT_BLAS=ON \
    -DCHOLMOD_USE_LONG=ON \
	-DBUILD_SHARED_LIBS=OFF
endif

# Build Suitesparse library
$(SUITESPARSE_BUILD):
	echo $(DETECTED_OS)
	$(MAKE) -C $(LIB_DIR)/suitesparse/SuiteSparse_config local CMAKE_OPTIONS="$(CMAKE_OPTIONS)"
	$(MAKE) -C $(LIB_DIR)/suitesparse/SuiteSparse_config install
	$(MAKE) -C $(LIB_DIR)/suitesparse/AMD local CMAKE_OPTIONS="$(CMAKE_OPTIONS)"
	$(MAKE) -C $(LIB_DIR)/suitesparse/AMD install
	$(MAKE) -C $(LIB_DIR)/suitesparse/CAMD local CMAKE_OPTIONS="$(CMAKE_OPTIONS)"
	$(MAKE) -C $(LIB_DIR)/suitesparse/CAMD install
	$(MAKE) -C $(LIB_DIR)/suitesparse/COLAMD local CMAKE_OPTIONS="$(CMAKE_OPTIONS)"
	$(MAKE) -C $(LIB_DIR)/suitesparse/COLAMD install
	$(MAKE) -C $(LIB_DIR)/suitesparse/CCOLAMD local CMAKE_OPTIONS="$(CMAKE_OPTIONS)"
	$(MAKE) -C $(LIB_DIR)/suitesparse/CCOLAMD install
	$(MAKE) -C $(LIB_DIR)/suitesparse/CHOLMOD local CMAKE_OPTIONS="$(CMAKE_OPTIONS)"
	$(MAKE) -C $(LIB_DIR)/suitesparse/CHOLMOD install
	$(MAKE) -C $(LIB_DIR)/suitesparse/CHOLMOD test

# Clean everything
clean: clean-src clean-lib

# Clean only the source files and build artifacts
clean-src:
	rm -rf $(OBJ_DIR) $(TARGET)

# Clean only the libraries
clean-lib:
	$(MAKE) -C $(LIB_DIR)/suitesparse purge

.PHONY: all clean clean-src clean-lib
