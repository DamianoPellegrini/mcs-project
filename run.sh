#!/bin/bash
# filepath: run.sh

# Detect operating system and set build directory
if [ "$(uname)" == "Darwin" ]; then
    # macOS
    BUILD_DIR="build_macos"
    EXECUTABLE_SUFFIX="accelerate_macos"
    BLAS="Accelerate"
    echo "Detected macOS system"
elif [ "$(uname)" == "Linux" ]; then
    # Linux
    BUILD_DIR="build_linux"
    EXECUTABLE_SUFFIX="mkl_linux"
    BLAS="MKL"
    # Get Intel oneAPI path from command line or use default
    if [ -z "$1" ]; then
        ONEAPI_PATH="/opt/intel/oneapi/setvars.sh"
    else
        ONEAPI_PATH="$1"
    fi
    echo "Detected Linux system"
else
    echo "Unsupported operating system: $(uname)"
    exit 1
fi

if [ $BLAS = "MKL" ]; then
    # Initialize Intel oneAPI environment
    echo "Initializing Intel oneAPI environment from $ONEAPI_PATH..."
    source "$ONEAPI_PATH"
fi

# Navigate to build directory and build the project
echo "Building project in $BUILD_DIR..."
mkdir -p $BUILD_DIR
cd $BUILD_DIR
cmake ..
if [ $? -ne 0 ]; then
    exit 1
fi

cmake --build . --config Release
if [ $? -ne 0 ]; then
    cd ..
    echo "Build completely or partially failed"
    exit 1
fi

# Navigate back to root directory
cd ..

# Add OpenBLAS to path
echo "Adding OpenBLAS to PATH..."
export LD_LIBRARY_PATH="$PWD/cmake/openblas/lib:$LD_LIBRARY_PATH"

# Run the MKL version
echo "Waiting 5 seconds before running $BLAS version..."
sleep 5
echo "Running $BLAS version..."
./target/main_$EXECUTABLE_SUFFIX

# Run the OpenBLAS version
echo "Waiting 5 seconds before running OpenBLAS version..."
sleep 5
echo "Running OpenBLAS version..."
./target/main_openblas_linux

echo "Done!"

# Equivalent to pause - wait for user input
read -p "Press Enter to continue..."
