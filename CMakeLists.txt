cmake_minimum_required(VERSION 3.28)

# OneAPI environment check
if(NOT APPLE)
	if(WIN32)
		set(ONEAPI_SETVARS_PATH "call \"C:/Program Files (x86)/Intel/oneAPI/setvars.bat\"")
	elseif(UNIX)
		set(ONEAPI_SETVARS_PATH "source /opt/intel/oneapi/setvars.sh")
	endif()

	if(WIN32)
		find_program(CMAKE_Fortran_COMPILER NAMES ifx.exe PATHS $ENV{CMPLR_ROOT}/bin)
	endif()
	set(MKL_LINK static)
	find_package(MKL REQUIRED PATHS $ENV{MKLROOT})
endif()

project(MCS-Project LANGUAGES C CXX Fortran)

message(STATUS "CMAKE_SYSTEM_NAME: ${CMAKE_SYSTEM_NAME}")

# Define directories
set(SRC_DIR "${CMAKE_SOURCE_DIR}/src")
set(LIB_DIR "${CMAKE_SOURCE_DIR}/lib")
set(BIN_DIR "${CMAKE_SOURCE_DIR}/target")

# Create output directories (these will be created during the build)
file(MAKE_DIRECTORY ${BIN_DIR})

message(STATUS "Source Directory: ${SRC_DIR}")
message(STATUS "Library Directory: ${LIB_DIR}")
message(STATUS "Binary Directory: ${BIN_DIR}")

# SuiteSparse configuration
set(SUITESPARSE_DIR "${LIB_DIR}/suitesparse")

# Proper clean targets
add_custom_target(clean-src
	COMMAND ${CMAKE_COMMAND} -E remove_directory ${BASE_OBJ_DIR}
	COMMAND ${CMAKE_COMMAND} -E remove_directory ${BIN_DIR}
	COMMENT "Cleaning object files and main executable"
)

add_custom_target(clean-lib
	COMMAND ${CMAKE_COMMAND} -E remove_directory ${BASE_OBJ_DIR}/suitesparse_main-prefix
	COMMAND ${CMAKE_COMMAND} -E remove_directory ${BASE_OBJ_DIR}/suitesparse_openblas-prefix
	COMMAND ${CMAKE_COMMAND} -E remove_directory ${BASE_OBJ_DIR}/suitesparse_main
	COMMAND ${CMAKE_COMMAND} -E remove_directory ${BASE_OBJ_DIR}/suitesparse_openblas
	COMMENT "Cleaning SuiteSparse libraries"
)

add_custom_target(clean-all
	DEPENDS clean-src clean-lib
	COMMENT "Cleaning everything (sources and libraries)"
)

# Configure library paths based on platform
set(SUITESPARSE_LIB_NAMES
	"suitesparseconfig"
	"amd"
	"camd"
	"colamd"
	"ccolamd"
	"cholmod"
)

# Copy override files before building
add_custom_target(copy_override_files ALL
	COMMAND ${CMAKE_COMMAND} -E copy_if_different "${LIB_DIR}/override/cholmod.h.in"
	"${SUITESPARSE_DIR}/CHOLMOD/Config/cholmod.h.in"
	COMMAND ${CMAKE_COMMAND} -E copy_if_different "${LIB_DIR}/override/t_cholmod_malloc.c"
	"${SUITESPARSE_DIR}/CHOLMOD/Utility/t_cholmod_malloc.c"
	COMMAND ${CMAKE_COMMAND} -E copy_if_different "${LIB_DIR}/override/t_cholmod_realloc.c"
	"${SUITESPARSE_DIR}/CHOLMOD/Utility/t_cholmod_realloc.c"
	COMMENT "Copying override files to SuiteSparse"
)

set(SUITESPARSE_MAIN_INSTALL_DIR ${CMAKE_SOURCE_DIR}/cmake/suitesparse_main)
set(SUITESPARSE_OPENBLAS_INSTALL_DIR ${CMAKE_SOURCE_DIR}/cmake/suitesparse_openblas)

make_directory(${SUITESPARSE_MAIN_INSTALL_DIR})
make_directory(${SUITESPARSE_OPENBLAS_INSTALL_DIR})

set(OPENBLAS_DIR ${CMAKE_SOURCE_DIR}/cmake/openblas)

include(ExternalProject)

# Set the common CMake options for SuiteSparse
list(APPEND SUITESPARSE_CMAKE_OPTIONS
	-DSUITESPARSE_USE_64BIT_BLAS=ON
	-DSUITESPARSE_LOCAL_INSTALL=1
	-DBUILD_SHARED_LIBS=OFF
	-DBUILD_STATIC_LIBS=ON
	-DSUITESPARSE_ENABLE_PROJECTS=cholmod
)

if (WIN32)
	list(APPEND SUITESPARSE_CMAKE_OPTIONS -DCMAKE_Fortran_COMPILER=${CMAKE_Fortran_COMPILER})
endif()

function(suitesparse_main)
	list(APPEND SUITESPARSE_CMAKE_OPTIONS
		-DCMAKE_INSTALL_PREFIX=${SUITESPARSE_MAIN_INSTALL_DIR}
	)

	if(APPLE)
		list(APPEND SUITESPARSE_CMAKE_OPTIONS -DBLA_VENDOR=Apple -DSUITESPARSE_USE_64BIT_BLAS=OFF)
		execute_process(
			COMMAND brew --prefix libomp
			OUTPUT_VARIABLE LIBOMP_PREFIX
			OUTPUT_STRIP_TRAILING_WHITESPACE
		)
		message (STATUS "OpenMP prefix location " ${LIBOMP_PREFIX})
		list(APPEND SUITESPARSE_CMAKE_OPTIONS
			-DBLA_VENDOR=Apple
			-DSUITESPARSE_USE_64BIT_BLAS=OFF
			-DOpenMP_FOUND=TRUE
			-DOpenMP_C_FOUND=C
			-DOpenMP_C_FLAGS="-lomp"
			-DOpenMP_C_INCLUDE_DIRS=${LIBOMP_PREFIX}/include
			-DOpenMP_C_LIBRARIES=${LIBOMP_PREFIX}/lib
			-DOpenMP_C_LIB_NAMES=libomp
			-DOpenMP_libomp_LIBRARY=${LIBOMP_PREFIX}/lib/libomp.a
		)
	else()
		list(APPEND SUITESPARSE_CMAKE_OPTIONS -DBLA_VENDOR=Intel10_64ilp)
	endif()

	if(LINUX)
		get_target_property(MKL_INTEL_ILP64_PATH MKL::mkl_intel_ilp64 IMPORTED_LOCATION)
		get_target_property(MKL_INTEL_THREAD_PATH MKL::mkl_intel_thread IMPORTED_LOCATION)
		get_target_property(MKL_CORE_PATH MKL::mkl_core IMPORTED_LOCATION)

		set(MKL_LIBS "-m64 -Wl,--start-group ${MKL_INTEL_ILP64_PATH} ${MKL_INTEL_THREAD_PATH} ${MKL_CORE_PATH} -Wl,--end-group -liomp5 -lpthread -lm -ldl")
	endif()

	message(STATUS "SUITESPARSE_CMAKE_OPTIONS: ${SUITESPARSE_CMAKE_OPTIONS}")

	if(LINUX)
		ExternalProject_Add(
			suitesparse_main
			SOURCE_DIR "${SUITESPARSE_DIR}"
			CONFIGURE_COMMAND ${CMAKE_COMMAND} -S "${SUITESPARSE_DIR}" -B "${CMAKE_BINARY_DIR}/suitesparse_main" ${SUITESPARSE_CMAKE_OPTIONS} ${SUITESPARSE_CMAKE_OPTIONS} -DBLAS_LIBRARIES=${MKL_LIBS} -DLAPACK_LIBRARIES=${MKL_LIBS}
			BUILD_COMMAND ${CMAKE_COMMAND} --build "${CMAKE_BINARY_DIR}/suitesparse_main" --config Release
			INSTALL_COMMAND ${CMAKE_COMMAND} --install ${CMAKE_BINARY_DIR}/suitesparse_main
		)
	else()
		ExternalProject_Add(
			suitesparse_main
			SOURCE_DIR "${SUITESPARSE_DIR}"
			CONFIGURE_COMMAND ${CMAKE_COMMAND} -S "${SUITESPARSE_DIR}" -B "${CMAKE_BINARY_DIR}/suitesparse_main" ${SUITESPARSE_CMAKE_OPTIONS}
			BUILD_COMMAND ${CMAKE_COMMAND} --build "${CMAKE_BINARY_DIR}/suitesparse_main" --config Release
			INSTALL_COMMAND ${CMAKE_COMMAND} --install ${CMAKE_BINARY_DIR}/suitesparse_main
		)
	endif()
endfunction()

suitesparse_main()

function(suitesparse_openblas)
	list(APPEND SUITESPARSE_CMAKE_OPTIONS
		-DCMAKE_INSTALL_PREFIX=${SUITESPARSE_OPENBLAS_INSTALL_DIR}
		-DBLA_VENDOR=OpenBLAS
	)

	if(WIN32)
		list(APPEND SUITESPARSE_CMAKE_OPTIONS
			-DBLAS_LIBRARIES=${OPENBLAS_DIR}/lib/libopenblas.lib
			-DLAPACK_LIBRARIES=${OPENBLAS_DIR}/lib/libopenblas.lib
		)
	elseif(APPLE)
		execute_process(
			COMMAND brew --prefix openblas
			OUTPUT_VARIABLE OPENBLAS_DIR
			OUTPUT_STRIP_TRAILING_WHITESPACE
		)
		list(APPEND SUITESPARSE_CMAKE_OPTIONS
			-DSUITESPARSE_USE_64BIT_BLAS=OFF
			-DBLAS_LIBRARIES=${OPENBLAS_DIR}/lib/libopenblas.a
			-DLAPACK_LIBRARIES=${OPENBLAS_DIR}/lib/libopenblas.a
		)
		execute_process(
			COMMAND brew --prefix libomp
			OUTPUT_VARIABLE LIBOMP_PREFIX
			OUTPUT_STRIP_TRAILING_WHITESPACE
		)
		message (STATUS "OpenMP prefix location " ${LIBOMP_PREFIX})
		list(APPEND SUITESPARSE_CMAKE_OPTIONS
			-DBLA_VENDOR=Apple
			-DSUITESPARSE_USE_64BIT_BLAS=OFF
			-DOpenMP_FOUND=TRUE
			-DOpenMP_C_FOUND=C
			-DOpenMP_C_FLAGS="-lomp"
			-DOpenMP_C_INCLUDE_DIRS=${LIBOMP_PREFIX}/include
			-DOpenMP_C_LIBRARIES=${LIBOMP_PREFIX}/lib
			-DOpenMP_C_LIB_NAMES=libomp
			-DOpenMP_libomp_LIBRARY=${LIBOMP_PREFIX}/lib/libomp.a
		)
	endif()

	message(STATUS "SUITESPARSE_CMAKE_OPTIONS: ${SUITESPARSE_CMAKE_OPTIONS}")

	ExternalProject_Add(
		suitesparse_openblas
		SOURCE_DIR "${SUITESPARSE_DIR}"
		CONFIGURE_COMMAND ${CMAKE_COMMAND} -S "${SUITESPARSE_DIR}" -B "${CMAKE_BINARY_DIR}/suitesparse_openblas" ${SUITESPARSE_CMAKE_OPTIONS}
		BUILD_COMMAND ${CMAKE_COMMAND} --build "${CMAKE_BINARY_DIR}/suitesparse_openblas" --config Release
		INSTALL_COMMAND ${CMAKE_COMMAND} --install ${CMAKE_BINARY_DIR}/suitesparse_openblas
	)
endfunction()

suitesparse_openblas()

# Find all source files in the src directory
file(GLOB_RECURSE SRC_FILES "${SRC_DIR}/*.cpp")

if(WIN32)
	set(EXE_SUFFIX "windows")
	set(EXE_BLAS "mkl")
elseif(LINUX)
	set(EXE_SUFFIX "linux")
	set(EXE_BLAS "mkl")
elseif(APPLE)
	set(EXE_SUFFIX "macos")
	set(EXE_BLAS "accelerate")
else()
	set(EXE_SUFFIX "unknown")
endif()

# Create the main executable target that uses MKL
add_executable(main ${SRC_FILES})
set_target_properties(main PROPERTIES
	OUTPUT_NAME "main_${EXE_BLAS}_${EXE_SUFFIX}"
	OUTPUT_NAME_RELEASE "main_${EXE_BLAS}_${EXE_SUFFIX}"
	RUNTIME_OUTPUT_DIRECTORY "${BIN_DIR}"
	RUNTIME_OUTPUT_DIRECTORY_RELEASE "${BIN_DIR}"
)

# Create the main executable target that uses OpenBLAS
add_executable(main_openblas ${SRC_FILES})
set_target_properties(main_openblas PROPERTIES
	OUTPUT_NAME "main_openblas_${EXE_SUFFIX}"
	OUTPUT_NAME_RELEASE "main_openblas_${EXE_SUFFIX}"
	RUNTIME_OUTPUT_DIRECTORY "${BIN_DIR}"
	RUNTIME_OUTPUT_DIRECTORY_RELEASE "${BIN_DIR}"
)

# Set C++ standard to C++20
target_compile_features(main PRIVATE
	cxx_std_20
)
target_compile_features(main_openblas PRIVATE
	cxx_std_20
)

target_link_directories(main PRIVATE ${SUITESPARSE_MAIN_INSTALL_DIR}/lib)
target_link_directories(main_openblas PRIVATE ${SUITESPARSE_OPENBLAS_INSTALL_DIR}/lib)

if(WIN32)
	set(SUITESPARSE_LIB_SUFFIX "_static")
endif()

# Link against SuiteSparse libraries using imported targets
target_link_libraries(main PRIVATE
	cholmod${SUITESPARSE_LIB_SUFFIX}
	suitesparseconfig${SUITESPARSE_LIB_SUFFIX}
	amd${SUITESPARSE_LIB_SUFFIX}
	camd${SUITESPARSE_LIB_SUFFIX}
	colamd${SUITESPARSE_LIB_SUFFIX}
	ccolamd${SUITESPARSE_LIB_SUFFIX}
)
target_link_libraries(main_openblas PRIVATE
	cholmod${SUITESPARSE_LIB_SUFFIX}
	suitesparseconfig${SUITESPARSE_LIB_SUFFIX}
	amd${SUITESPARSE_LIB_SUFFIX}
	camd${SUITESPARSE_LIB_SUFFIX}
	colamd${SUITESPARSE_LIB_SUFFIX}
	ccolamd${SUITESPARSE_LIB_SUFFIX}
)

# Define include directories
set(INCLUDES
	${LIB_DIR}/eigen
	${LIB_DIR}/fast_matrix_market/include
)
# Add include directories
target_include_directories(main PRIVATE ${INCLUDES} ${SUITESPARSE_MAIN_INSTALL_DIR}/include/suitesparse)
target_include_directories(main_openblas PRIVATE ${INCLUDES} ${SUITESPARSE_OPENBLAS_INSTALL_DIR}/include/suitesparse)

set(COMPILER_FLAGS "")

# Set up compiler flags for target main
if(MSVC)
	list(APPEND COMPILER_FLAGS /external:W0 /W4 /EHsc /O2)

	# MKL setup for Windows
	target_compile_definitions(main PRIVATE -DEIGEN_USE_MKL_ALL -DMKL_ILP64)

	target_include_directories(main PRIVATE $ENV{MKLROOT}/include)

	target_link_directories(main PRIVATE $ENV{CMPLR_ROOT}/lib)
	target_link_libraries(main PRIVATE
		MKL::mkl_intel_ilp64
		MKL::mkl_intel_thread
		MKL::mkl_core
		libiomp5md.lib
	)
else()
	list(APPEND COMPILER_FLAGS -Wall -march=native -O3)

	if(APPLE)
		execute_process(
			COMMAND brew --prefix libomp
			OUTPUT_VARIABLE LIBOMP_PREFIX
			OUTPUT_STRIP_TRAILING_WHITESPACE
		)
		message (STATUS "OpenMP prefix location " ${LIBOMP_PREFIX})
		target_compile_definitions(main PRIVATE -D_OPENMP -DUSING_ACCEL)
		# find_package(OpenMP REQUIRED PATHS ${LIBOMP_PREFIX}/lib)
		target_include_directories(main PRIVATE ${LIBOMP_PREFIX}/include)
		# target_compile_definitions(main PRIVATE EIGEN_USE_BLAS EIGEN_USE_LAPACK)
		target_link_directories(main PRIVATE ${LIBOMP_PREFIX}/lib)
		target_link_libraries(main PRIVATE
			"-framework Accelerate"
			"-lomp"
		)
	else() # here i'm linux
		list(APPEND COMPILER_FLAGS -m64)
		target_compile_definitions(main PRIVATE -DEIGEN_USE_MKL_ALL -DMKL_ILP64)

		# MKL setup for Linux
		target_include_directories(main PRIVATE $ENV{MKLROOT}/include)

		target_link_libraries(main PRIVATE
			-m64 -Wl,--start-group
			MKL::mkl_intel_ilp64
			MKL::mkl_intel_thread
			MKL::mkl_core
			-Wl,--end-group
			-liomp5 -lpthread -lm -ldl
		)
	endif()
endif()

target_compile_definitions(main_openblas PRIVATE -DEIGEN_USE_BLAS -DEIGEN_USE_LAPACK -DOPEN_BLAS)
if(APPLE)
	execute_process(
		COMMAND brew --prefix openblas
		OUTPUT_VARIABLE OPENBLAS_DIR
		OUTPUT_STRIP_TRAILING_WHITESPACE
	)
	target_include_directories(main_openblas PRIVATE ${OPENBLAS_DIR}/include)
	target_link_directories(main_openblas PRIVATE ${OPENBLAS_DIR}/lib)
else()
	target_include_directories(main_openblas PRIVATE ${OPENBLAS_DIR}/include)
endif()

if(WIN32)
	target_link_libraries(main_openblas PRIVATE
		${OPENBLAS_DIR}/lib/libopenblas.lib
	)
elseif(APPLE)
	target_link_libraries(main_openblas PRIVATE
		-lopenblas
	)
else() # here i'm linux
	target_link_libraries(main_openblas PRIVATE
		-fopenmp
		-lopenblas64
	)
endif()

# Finalize the target properties
target_compile_options(main PUBLIC ${COMPILER_FLAGS})
add_dependencies(main copy_override_files suitesparse_main)
install(TARGETS main)

target_compile_options(main_openblas PUBLIC ${COMPILER_FLAGS})
add_dependencies(main_openblas copy_override_files suitesparse_openblas)
install(TARGETS main_openblas)

message(STATUS "CMake configuration complete. Run 'make' or 'cmake --build . --config Release' to build the project.")
