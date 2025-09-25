# CMakeLists.txt designed for
# downloading/configuring/building/installing
# Thirdparty dependencies

if (APPLE)
    # Disable annoying "has no symbols" warnings
    set(CMAKE_C_ARCHIVE_CREATE   "<CMAKE_AR> Scr <TARGET> <LINK_FLAGS> <OBJECTS>")
    set(CMAKE_CXX_ARCHIVE_CREATE "<CMAKE_AR> Scr <TARGET> <LINK_FLAGS> <OBJECTS>")
    set(CMAKE_C_ARCHIVE_FINISH   "<CMAKE_RANLIB> -no_warning_for_no_symbols -c <TARGET>")
    set(CMAKE_CXX_ARCHIVE_FINISH "<CMAKE_RANLIB> -no_warning_for_no_symbols -c <TARGET>")
endif()


if (COIN_DISABLE_THIRDPARTY)
    return ()
endif ()

# Prevent the "make clean" from cleaning this directory
set_directory_properties(PROPERTIES CLEAN_NO_CUSTOM TRUE)

include(ExternalProject)

set(ext-InstallDir ${CMAKE_BINARY_DIR}/Dependencies/${CMAKE_CFG_INTDIR})

if (NOT EXISTS ${ext-InstallDir})
    make_directory(${ext-InstallDir})
endif ()
if (NOT EXISTS ${ext-InstallDir}/bin)
    make_directory(${ext-InstallDir}/bin)
endif ()
if (NOT EXISTS ${ext-InstallDir}/lib)
    make_directory(${ext-InstallDir}/lib)
endif ()
if (NOT EXISTS ${ext-InstallDir}/include)
    make_directory(${ext-InstallDir}/include)
endif ()

set(CMAKE_GENERATOR_OLD    "${CMAKE_GENERATOR}")
set(CMAKE_MAKE_PROGRAM_OLD "${CMAKE_MAKE_PROGRAM}")
#if (WIN32)
#    set(CMAKE_GENERATOR    "MSYS Makefiles")
#    set(CMAKE_MAKE_PROGRAM "make")
#    set(CMAKE_OPT          "-j 16")
#else ()
#    set(CMAKE_GENERATOR    "Unix Makefiles")
#    set(CMAKE_MAKE_PROGRAM "make")
#    set(CMAKE_OPT          "-j 16")
#endif ()

if (NOT COIN_ENABLE_DOWNLOAD_MINGW_LAPACK AND
        NOT COIN_ENABLE_DOWNLOAD_LAPACK AND
        NOT COIN_USE_SYSTEM_LAPACK)
    message(WARNING "One kind of Blas / Lapack can be selected:
 - COIN_ENABLE_DOWNLOAD_MINGW_LAPACK AND
 - COIN_ENABLE_DOWNLOAD_LAPACK AND
 - COIN_USE_SYSTEM_LAPACK")
endif ()

# #################################################
# ===>    System Lapack
# #################################################

if (COIN_USE_SYSTEM_LAPACK)
    find_package(LAPACK REQUIRED)

    set(COIN_ENABLE_DOWNLOAD_LAPACK  OFF CACHE BOOL "Enable the download / compilation of Blas / Lapack")

    get_filename_component(LAPACK_LINK_PATH "${LAPACK_LIBRARIES}" DIRECTORY)
endif ()

# #################################################
# <===    System Lapack
# #################################################

# TODO: add HSL   from source build?
# TODO: add METIS from source build?

include(FetchContent)

# #################################################
# ===>    Lapack
# #################################################

add_library(LAPACK_TARGET INTERFACE)

if(COIN_ENABLE_DOWNLOAD_LAPACK)
    safe_tmp(_TMP_BUILD_SHARED_LIBS BUILD_SHARED_LIBS)
    safe_tmp(_TMP_BUILD_TESTING     BUILD_TESTING)
    safe_tmp(_TMP_CFLAGS            CMAKE_C_FLAGS)
    safe_tmp(_TMP_CXXFLAGS          CMAKE_CXX_FLAGS)
    safe_tmp(_TMP_FortranFLAGS      CMAKE_Fortran_FLAGS)

    set(BUILD_SHARED_LIBS   ON  CACHE BOOL "Build shared libraries for OpenBLAS" FORCE)
    set(BUILD_TESTING       OFF CACHE BOOL "Build testing for OpenBLAS" FORCE)

    if(CMAKE_C_COMPILER_ID MATCHES "GNU")
        set(CMAKE_C_FLAGS       "${CMAKE_C_FLAGS} -w")
        set(CMAKE_CXX_FLAGS     "${CMAKE_CXX_FLAGS} -w")
        set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -w")
    endif()

    # sadly we cannot restrict ourselves to only double and complex OpenBLAS build,
    # since the utest and ctest will fail and the build terminates

    set(OPEN_BLAS_VERSION "0.3.30")
    set(OPEN_BLAS_URL "https://github.com/OpenMathLib/OpenBLAS/archive/refs/tags/v${OPEN_BLAS_VERSION}.tar.gz")

    FetchContent_Declare(
        OpenBLAS
        URL ${OPEN_BLAS_URL}
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    )

    FetchContent_MakeAvailable(OpenBLAS)
    target_link_libraries(LAPACK_TARGET INTERFACE openblas_shared)

    restore_tmp(BUILD_SHARED_LIBS   _TMP_BUILD_SHARED_LIBS)
    restore_tmp(BUILD_TESTING       _TMP_BUILD_TESTING)
    restore_tmp(CMAKE_C_FLAGS       _TMP_CFLAGS)
    restore_tmp(CMAKE_CXX_FLAGS     _TMP_CXXFLAGS)
    restore_tmp(CMAKE_Fortran_FLAGS _TMP_FortranFLAGS)

elseif(COIN_USE_SYSTEM_LAPACK)
    find_package(LAPACK REQUIRED)
    target_link_libraries(LAPACK_TARGET INTERFACE LAPACK::LAPACK)
else()
    message(FATAL_ERROR "No LAPACK available, because COIN_USE_SYSTEM_LAPACK=OFF and COIN_ENABLE_DOWNLOAD_LAPACK=OFF.")
endif()

# #################################################
# <===    Lapack
# #################################################

# ============================================================
# ===> MUMPS via FetchContent
# ============================================================

if (COIN_ENABLE_DOWNLOAD_MUMPS)
    set(MUMPS_VERSION "5.8.1")
    set(MUMPS_URL "https://mumps-solver.org/MUMPS_${MUMPS_VERSION}.tar.gz")

    FetchContent_Declare(
        Mumps
        URL ${MUMPS_URL}
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        PATCH_COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists_mumps.cmake CMakeLists.txt
    )

    FetchContent_GetProperties(Mumps)
    if(NOT mumps_POPULATED)
        FetchContent_MakeAvailable(Mumps)
    endif()
endif()

set(CMAKE_GENERATOR    "${CMAKE_GENERATOR_OLD}")
set(CMAKE_MAKE_PROGRAM "${CMAKE_MAKE_PROGRAM_OLD}")

# #################################################
# ===>   Restart cmake
# #################################################

## Overload some CMake command to avoid modif all sub-projects CMakLists.txt file
## The original built-in commands are prefixed with an underscore if overriding any of them
## Prevent the modification of all sub-project

macro(add_library_mod _target)
    add_library (${_target} ${ARGN})

    if (COIN_ENABLE_DOWNLOAD_MUMPS)
        add_dependencies(${_target} dmumps)
    endif ()
    if (COIN_ENABLE_DOWNLOAD_LAPACK)
        add_dependencies(${_target} LAPACK_TARGET)
    endif ()
endmacro ()

macro(add_executable_mod _target)
    add_executable (${_target} ${ARGN})

    if (COIN_ENABLE_DOWNLOAD_MUMPS)
        add_dependencies(${_target} dmumps)
    endif ()
    if (COIN_ENABLE_DOWNLOAD_LAPACK)
        add_dependencies(${_target} LAPACK_TARGET)
    endif ()
endmacro ()

# #################################################
# <===   Restart cmake
# #################################################
