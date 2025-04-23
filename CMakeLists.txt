cmake_minimum_required(VERSION 3.29)
set(CMAKE_Fortran_COMPILER "C:/Program Files (x86)/Intel/oneAPI/compiler/latest/bin")

project(MultiFolderBuild LANGUAGES C CXX Fortran)

# Define directories
set(SRC_DIR "${CMAKE_SOURCE_DIR}/src")
set(LIB_DIR "${CMAKE_SOURCE_DIR}/lib")
set(OBJ_DIR "${CMAKE_SOURCE_DIR}/target/obj")
set(BIN_DIR "${CMAKE_SOURCE_DIR}/target")

message(STATUS "Source Directory: ${SRC_DIR}")
message(STATUS "Library Directory: ${LIB_DIR}")
message(STATUS "Object Directory: ${OBJ_DIR}")
message(STATUS "Binary Directory: ${BIN_DIR}")

# Create output directories
file(MAKE_DIRECTORY ${OBJ_DIR})
file(MAKE_DIRECTORY ${BIN_DIR})

# List of SuiteSparse libraries
set(SUITESPARSE_BUILD
    ${LIB_DIR}/suitesparse/lib/suitesparseconfig_static.lib
    ${LIB_DIR}/suitesparse/lib/amd_static.lib
    ${LIB_DIR}/suitesparse/lib/camd_static.lib
    ${LIB_DIR}/suitesparse/lib/colamd_static.lib
    ${LIB_DIR}/suitesparse/lib/ccolamd_static.lib
    ${LIB_DIR}/suitesparse/lib/cholmod_static.lib
)

# Check if SuiteSparse libraries need to be built
set(BUILD_SUITESPARSE FALSE)
foreach(LIB ${SUITESPARSE_BUILD})
    if(EXISTS ${LIB})
        message(STATUS "Found ${LIB}")
    else()
        message(STATUS "Missing ${LIB}, will build SuiteSparse")
        set(BUILD_SUITESPARSE TRUE)
        break()
    endif()
endforeach()

# Only build SuiteSparse if needed
if(BUILD_SUITESPARSE)
    # Define options
    set(CMAKE_OPTIONS
        -DBLA_VENDOR=Intel10_64ilp
        -USUITESPARSE_PKGFILEDIR
        -DSUITESPARSE_LOCAL_INSTALL=1
        -DBUILD_SHARED_LIBS=OFF
        -DBUILD_STATIC_LIBS=ON
        -DCHOLMOD_PARTITION=OFF
    )

    # List of folders you want to process
    set(FOLDERS 
        "lib/suitesparse/SuiteSparse_config"
        "lib/suitesparse/AMD" 
        "lib/suitesparse/CAMD"
        "lib/suitesparse/COLAMD"
        "lib/suitesparse/CCOLAMD"
        "lib/suitesparse/CHOLMOD"
    )

    get_filename_component(PROJECT_ROOT "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)

    foreach(FOLDER IN LISTS FOLDERS)
        message(STATUS "Processing ${FOLDER}")

        file(MAKE_DIRECTORY "${PROJECT_ROOT}/${FOLDER}/build")

        # Configure step
        execute_process(
            COMMAND ${CMAKE_COMMAND} ${CMAKE_OPTIONS} ..
            WORKING_DIRECTORY "${PROJECT_ROOT}/${FOLDER}/build"
            RESULT_VARIABLE result
        )
        
        if(result)
            message(FATAL_ERROR "Configuration failed in ${FOLDER}")
        endif()

        # Build step
        execute_process(
            COMMAND ${CMAKE_COMMAND} --build . --config Release -j8
            WORKING_DIRECTORY "${PROJECT_ROOT}/${FOLDER}/build"
            RESULT_VARIABLE result
        )
        
        if(result)
            message(FATAL_ERROR "Build failed in ${FOLDER}")
        endif()

        # Install step
        execute_process(
            COMMAND ${CMAKE_COMMAND} --install .
            WORKING_DIRECTORY "${PROJECT_ROOT}/${FOLDER}/build"
            RESULT_VARIABLE result
        )
        
        if(result)
            message(FATAL_ERROR "Installation failed in ${FOLDER}")
        endif()
        
        message(STATUS "Successfully built and installed ${FOLDER}")
    endforeach()
else()
    message(STATUS "Skipping SuiteSparse build, all libraries found.")
endif()

# Now build the main project
message(STATUS "Building main project")

# Find all source files
file(GLOB_RECURSE SRC_FILES "${SRC_DIR}/*.cpp")

# Define include directories (add this section after defining directories)
set(INCLUDES
    ${LIB_DIR}/eigen
    ${LIB_DIR}/fast_matrix_market/include
    ${LIB_DIR}/suitesparse/include
    ${LIB_DIR}/suitesparse/include/suitesparse
)

# Begin with an empty string for the command
set(COMPILE_FLAGS "")
set(COMMAND_INCLUDES "")
set(LINK_FLAGS "")

if(MSVC)
    # MSVC-specific compilation flags
    foreach(INCLUDE_DIR ${INCLUDES})
        list(APPEND COMMAND_INCLUDES /I "\"${INCLUDE_DIR}\"")
    endforeach()
    
    # Add MKL if available
    if(DEFINED ENV{MKLROOT})
        list(APPEND COMMAND_INCLUDES /I "\"$ENV{MKLROOT}/include\"")
    endif()

    # Add remaining MSVC flags
    list(APPEND COMPILE_FLAGS "/W4" "/std:c++20" "/EHsc" "/DEIGEN_USE_MKL_ALL")

    list(APPEND LINK_FLAGS "/LIBPATH:'C:/Program Files (x86)/Intel/oneAPI/mkl/latest/lib'" "mkl_intel_ilp64.lib" "mkl_intel_thread.lib" "mkl_core.lib" "/LIBPATH:'C:/Program Files (x86)/Intel/oneAPI/compiler/latest/lib'" "libiomp5md.lib")
else()
    # GCC/Clang compilation flags
    foreach(INCLUDE_DIR ${INCLUDES})
        string(APPEND COMMAND_INCLUDES " -I${INCLUDE_DIR}")
    endforeach()
    
    # Add MKL if available
    if(DEFINED ENV{MKLROOT})
        string(APPEND COMMAND_INCLUDES " -I\"$ENV{MKLROOT}/include\"")
    endif()
    
    # Add remaining GCC/Clang flags
    string(APPEND COMPILE_FLAGS " -Wall -std=c++20 -march=native -mavx2 -mfma -DEIGEN_USE_MKL_ALL")
endif()

# Compile each source file to object files
set(OBJ_FILES "")  # Initialize the list

foreach(SRC_FILE ${SRC_FILES})
    get_filename_component(FILE_NAME ${SRC_FILE} NAME_WE)
    set(OBJ_FILE "${OBJ_DIR}/${FILE_NAME}.obj")
    
    message(STATUS "Compiling: ${SRC_FILE}")
    if(MSVC)
        message(STATUS "Command: \"${CMAKE_CXX_COMPILER}\" ${COMPILE_FLAGS} ${COMMAND_INCLUDES} /Fo\"${OBJ_FILE}\" /c \"${SRC_FILE}\"")
        execute_process(
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            COMMAND ${CMAKE_CXX_COMPILER}
                ${COMPILE_FLAGS}
                /I lib/fast_matrix_market/include
                /I lib/suitesparse/include
                /I lib/suitesparse/include/suitesparse
                /I lib/eigen
                ${COMMAND_INCLUDES}
                /Fo${OBJ_FILE}
                /c
                "${SRC_FILE}"
            RESULT_VARIABLE result
        )
    else()
        message(STATUS "Command: ${CMAKE_CXX_COMPILER} ${COMMAND_INCLUDES} ${COMPILE_FLAGS} -c \"${SRC_FILE}\" -o \"${OBJ_FILE}.o\"")
        execute_process(
            COMMAND ${CMAKE_CXX_COMPILER} ${COMMAND_INCLUDES} ${COMPILE_FLAGS} -c "${SRC_FILE}" -o "${OBJ_FILE}.o"
            RESULT_VARIABLE result
        )
    endif()
    
    if(result)
        message(FATAL_ERROR "Failed to compile ${SRC_FILE}")
    endif()
    
    list(APPEND OBJ_FILES ${OBJ_FILE})
endforeach()

# Link all object files and libraries to create the executable
if(MSVC)
    message(STATUS "Linking: ${OBJ_FILES}")
    message(STATUS "Command: \"${CMAKE_CXX_COMPILER}\" ${OBJ_FILES} /Fe:${BIN_DIR}/main.exe ${SUITESPARSE_BUILD} ${LINK_FLAGS}")
    execute_process(
        COMMAND ${CMAKE_CXX_COMPILER} ${OBJ_FILES} /Fe:${BIN_DIR}/main.exe /link ${SUITESPARSE_BUILD} ${LINK_FLAGS}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        RESULT_VARIABLE result
    )
else()
    execute_process(
        COMMAND ${CMAKE_CXX_COMPILER} -o ${BIN_DIR}/main.exe ${OBJ_FILES} ${SUITESPARSE_BUILD} ${LINK_FLAGS}
        RESULT_VARIABLE result
    )
endif()

if(result)
    message(FATAL_ERROR "Failed to link executable")
endif()

message(STATUS "Successfully built main.exe in ${BIN_DIR}")
