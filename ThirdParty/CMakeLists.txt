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

include(FetchContent)

safe_tmp(_TMP_CFLAGS            CMAKE_C_FLAGS)
safe_tmp(_TMP_CXXFLAGS          CMAKE_CXX_FLAGS)
safe_tmp(_TMP_FortranFLAGS      CMAKE_Fortran_FLAGS)

if(CMAKE_C_COMPILER_ID MATCHES "GNU")
    set(CMAKE_C_FLAGS       "${CMAKE_C_FLAGS} -w")
    set(CMAKE_CXX_FLAGS     "${CMAKE_CXX_FLAGS} -w")
    set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -w")
endif()

# #################################################
# ===>    Lapack
# #################################################

add_library(LAPACK_TARGET INTERFACE)

if(COIN_ENABLE_DOWNLOAD_LAPACK)
    safe_tmp(_TMP_BUILD_SHARED_LIBS BUILD_SHARED_LIBS)
    safe_tmp(_TMP_BUILD_TESTING     BUILD_TESTING)

    set(BUILD_SHARED_LIBS   ON  CACHE BOOL "Build shared libraries for OpenBLAS" FORCE)
    set(BUILD_TESTING       OFF CACHE BOOL "Build testing for OpenBLAS" FORCE)

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

elseif(COIN_USE_SYSTEM_LAPACK)
    find_package(LAPACK REQUIRED)
    target_link_libraries(LAPACK_TARGET INTERFACE LAPACK::LAPACK)
else()
    message(FATAL_ERROR "No LAPACK available, because COIN_USE_SYSTEM_LAPACK=OFF and COIN_ENABLE_DOWNLOAD_LAPACK=OFF.")
endif()

# #################################################
# <===    Lapack
# #################################################

# #################################################
# ===> METIS via FetchContent
# #################################################

add_library(METIS_TARGET INTERFACE)

if (MUMPS_USE_METIS)
    if (METIS_LIB_PATH AND METIS_INC_PATH)
        add_library(_METIS_USER_IMPORTED UNKNOWN IMPORTED)
        set_target_properties(_METIS_USER_IMPORTED PROPERTIES
            IMPORTED_LOCATION "${METIS_LIB_PATH}"
            INTERFACE_INCLUDE_DIRECTORIES "${METIS_INC_PATH}"
        )
        message(STATUS "Using user-provided METIS: ${METIS_LIB_PATH}")
        target_link_libraries(METIS_TARGET INTERFACE _METIS_USER_IMPORTED)
    elseif (COIN_ENABLE_DOWNLOAD_METIS)
        set(METIS_URL "https://github.com/KarypisLab/METIS/archive/refs/tags/v5.2.1.tar.gz")

        set(IDXWIDTH "#define IDXTYPEWIDTH 32")
        set(REALWIDTH "#define REALTYPEWIDTH 32")
        set(GKLIB_PATH "$ENV{HOME}/local") 
        set(METIS_URL "https://github.com/KarypisLab/METIS/archive/refs/tags/v5.2.1.tar.gz")

        FetchContent_Declare(
            METIS
            URL ${METIS_URL}
            DOWNLOAD_EXTRACT_TIMESTAMP TRUE
            PATCH_COMMAND
                ${CMAKE_COMMAND} -E make_directory build
                COMMAND ${CMAKE_COMMAND} -E make_directory build/xinclude
                COMMAND ${CMAKE_COMMAND} -E echo "${IDXWIDTH}" > build/xinclude/metis.h
                COMMAND ${CMAKE_COMMAND} -E echo "${REALWIDTH}" >> build/xinclude/metis.h
                COMMAND ${CMAKE_COMMAND} -E cat include/metis.h >> build/xinclude/metis.h
                COMMAND ${CMAKE_COMMAND} -E copy include/CMakeLists.txt build/xinclude
        )
        FetchContent_MakeAvailable(METIS)

        target_include_directories(METIS_TARGET INTERFACE ${CMAKE_BINARY_DIR}/metis-xinclude)
        target_link_libraries(METIS_TARGET INTERFACE metis)
    else ()
        find_package(METIS)
        if(NOT METIS_FOUND)
            message(FATAL_ERROR "METIS is required for MUMPS but not found. "
                                "Provide -DMETIS_LIB_PATH=/path/to/libmetis.so "
                                "and -DMETIS_INC_PATH=/path/to/include, "
                                "build METIS from source -DCOIN_ENABLE_DOWNLOAD_METIS=ON "
                                "or disable METIS with -DMUMPS_USE_METIS=OFF")
        else ()
            target_link_libraries(METIS_TARGET INTERFACE METIS::METIS)
        endif ()
    endif ()
endif ()

restore_tmp(CMAKE_C_FLAGS       _TMP_CFLAGS)
restore_tmp(CMAKE_CXX_FLAGS     _TMP_CXXFLAGS)
restore_tmp(CMAKE_Fortran_FLAGS _TMP_FortranFLAGS)

# #################################################
# ===> MUMPS via FetchContent
# #################################################

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
