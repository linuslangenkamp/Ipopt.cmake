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

# #################################################
# ===>    Lapack
# #################################################

if (COIN_ENABLE_DOWNLOAD_LAPACK)
    set(LAPACK_VERSION "3.8.0")

    enable_language(Fortran)

    if (UNIX)
        set(LAPACK_C_FLAGS      "-w")
        set(LAPACK_LINKER_FLAGS "-w")
        if (NOT HAVE_64_BIT)
            set(LAPACK_C_FLAGS      "-fPIC -w")
            set(LAPACK_LINKER_FLAGS "-fPIC -w")
        endif ()
    endif ()

    set(COIN_HAS_LAPACK ON CACHE BOOL "Enable the Lapack support of CoinUtils" FORCE)
    set(COIN_HAS_BLAS   ON CACHE BOOL "Enable the Blas support of CoinUtils"   FORCE)

    set(LAPACK_URL        "http:////www.netlib.org/lapack/lapack-${LAPACK_VERSION}.tar.gz" CACHE FILEPATH "Path to lapack-${LAPACK_VERSION}.tgz source archive")
    set(LAPACK_InstallDir "${ext-InstallDir}/Lapack-${LAPACK_VERSION}/${CMAKE_CFG_INTDIR}/")

    if (WIN32 AND NOT MINGW)
        ExternalProject_Add(ext-Lapack
                PREFIX            ${LAPACK_InstallDir}
                URL               ${LAPACK_URL}
                UPDATE_COMMAND    ""
                CONFIGURE_COMMAND ${CMAKE_COMMAND} -E make_directory ${LAPACK_InstallDir}/src/ext-Lapack/build
                && ${CMAKE_COMMAND} -E chdir ${LAPACK_InstallDir}/src/ext-Lapack/build ${CMAKE_COMMAND} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${ext-InstallDir} -DBUILD_DEPRECATED:Bool=ON -DLAPACKE:Bool=ON -DLAPACKE_WITH_TMG:Bool=ON -DCMAKE_C_FLAGS:String=${CLAPACK_C_FLAGS} -DCMAKE_EXE_LINKER_FLAGS:String=${LAPACK_LINKER_FLAGS} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} -G ${CMAKE_GENERATOR} ..
                BUILD_COMMAND     ${CMAKE_COMMAND} -E chdir ${LAPACK_InstallDir}/src/ext-Lapack/build ${CMAKE_MAKE_PROGRAM}
                INSTALL_COMMAND   ${CMAKE_COMMAND} -E copy ${LAPACK_InstallDir}/src/ext-Lapack/build/lib/lapack.lib  ${ext-InstallDir}/lib
                && ${CMAKE_COMMAND} -E copy ${LAPACK_InstallDir}/src/ext-Lapack/build/lib/lapacke.lib ${ext-InstallDir}/lib
                && ${CMAKE_COMMAND} -E copy ${LAPACK_InstallDir}/src/ext-Lapack/build/lib/blas.lib    ${ext-InstallDir}/lib
                && ${CMAKE_COMMAND} -E copy ${LAPACK_InstallDir}/src/ext-Lapack/build/lib/tmglib.lib  ${ext-InstallDir}/lib
                )
    elseif (UNIX)
        ExternalProject_Add(ext-Lapack
                PREFIX            ${LAPACK_InstallDir}
                URL               ${LAPACK_URL}
                UPDATE_COMMAND    ""
                CONFIGURE_COMMAND ${CMAKE_COMMAND} -E make_directory ${LAPACK_InstallDir}/src/ext-Lapack/build
                && ${CMAKE_COMMAND} -E chdir ${LAPACK_InstallDir}/src/ext-Lapack/build ${CMAKE_COMMAND} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${ext-InstallDir} -DBUILD_DEPRECATED:Bool=ON -DLAPACKE:Bool=ON -DLAPACKE_WITH_TMG:Bool=ON -DCMAKE_C_FLAGS:String=${CLAPACK_C_FLAGS} -DCMAKE_EXE_LINKER_FLAGS:String=${LAPACK_LINKER_FLAGS} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} ..
                BUILD_COMMAND     ${CMAKE_COMMAND} -E chdir ${LAPACK_InstallDir}/src/ext-Lapack/build ${CMAKE_MAKE_PROGRAM} -j 16
                INSTALL_COMMAND   ${CMAKE_COMMAND} -E copy ${LAPACK_InstallDir}/src/ext-Lapack/build/lib/liblapack.a  ${ext-InstallDir}/lib
                && ${CMAKE_COMMAND} -E copy ${LAPACK_InstallDir}/src/ext-Lapack/build/lib/liblapacke.a ${ext-InstallDir}/lib
                && ${CMAKE_COMMAND} -E copy ${LAPACK_InstallDir}/src/ext-Lapack/build/lib/libblas.a    ${ext-InstallDir}/lib
                && ${CMAKE_COMMAND} -E copy ${LAPACK_InstallDir}/src/ext-Lapack/build/lib/libtmglib.a  ${ext-InstallDir}/lib
                )
    endif ()
endif ()

if (COIN_ENABLE_FIND_LAPACK)
    find_package(LAPACK)
    find_package(BLAS)

    if (LAPACK_FOUND AND BLAS_FOUND)
        set(COIN_HAS_LAPACK ON CACHE BOOL "Enable the Lapack support of CoinUtils" FORCE)
        set(COIN_HAS_BLAS   ON CACHE BOOL "Enable the Blas support of CoinUtils"   FORCE)
    else ()
        set(COIN_HAS_LAPACK OFF CACHE BOOL "Enable the Lapack support of CoinUtils" FORCE)
        set(COIN_HAS_BLAS   OFF CACHE BOOL "Enable the Blas support of CoinUtils"   FORCE)
    endif ()
endif ()

# #################################################
# <===    Lapack
# #################################################

# #################################################
# ===>    MinGW Lapack
# #################################################

if (COIN_ENABLE_DOWNLOAD_MINGW_LAPACK)
    set(COIN_MINGW_LAPACK_ZIP_FILE "None" CACHE FILEPATH "Path to the zip file containing MinGW Lapack")

    set(COIN_HAS_LAPACK ON CACHE BOOL "Enable the Lapack support of CoinUtils" FORCE)
    set(COIN_HAS_BLAS   ON CACHE BOOL "Enable the Blas support of CoinUtils"   FORCE)

    ExternalProject_Add(ext-Lapack
            PREFIX            ${ext-InstallDir}/MinGW-Lapack
            URL               ${COIN_MINGW_LAPACK_ZIP_FILE}
            UPDATE_COMMAND    ""
            CONFIGURE_COMMAND ""
            BUILD_COMMAND     ""
            INSTALL_COMMAND   ${CMAKE_COMMAND} -E copy ${ext-InstallDir}/MinGW-Lapack/src/ext-Lapack/lib/liblapack.lib       ${ext-InstallDir}/lib/lapack.lib
            && ${CMAKE_COMMAND} -E copy ${ext-InstallDir}/MinGW-Lapack/src/ext-Lapack/lib/libblas.lib         ${ext-InstallDir}/lib/blas.lib
            && ${CMAKE_COMMAND} -E copy ${ext-InstallDir}/MinGW-Lapack/src/ext-Lapack/lib/libtmglib.lib       ${ext-InstallDir}/lib/tmglib.lib
            && ${CMAKE_COMMAND} -E copy ${ext-InstallDir}/MinGW-Lapack/src/ext-Lapack/bin/liblapack.dll       ${ext-InstallDir}/bin
            && ${CMAKE_COMMAND} -E copy ${ext-InstallDir}/MinGW-Lapack/src/ext-Lapack/bin/libblas.dll         ${ext-InstallDir}/bin
            && ${CMAKE_COMMAND} -E copy ${ext-InstallDir}/MinGW-Lapack/src/ext-Lapack/bin/libtmglib.dll       ${ext-InstallDir}/bin
            && ${CMAKE_COMMAND} -E copy ${ext-InstallDir}/MinGW-Lapack/src/ext-Lapack/bin/libgcc_s_seh-1.dll  ${ext-InstallDir}/bin
            && ${CMAKE_COMMAND} -E copy ${ext-InstallDir}/MinGW-Lapack/src/ext-Lapack/bin/libgfortran-3.dll   ${ext-InstallDir}/bin
            && ${CMAKE_COMMAND} -E copy ${ext-InstallDir}/MinGW-Lapack/src/ext-Lapack/bin/libquadmath-0.dll   ${ext-InstallDir}/bin
            && ${CMAKE_COMMAND} -E copy ${ext-InstallDir}/MinGW-Lapack/src/ext-Lapack/bin/libwinpthread-1.dll ${ext-InstallDir}/bin
            && ${CMAKE_COMMAND} -E copy ${ext-InstallDir}/MinGW-Lapack/src/ext-Lapack/bin/liblapack.dll       ${CMAKE_BINARY_DIR}/bin
            && ${CMAKE_COMMAND} -E copy ${ext-InstallDir}/MinGW-Lapack/src/ext-Lapack/bin/libblas.dll         ${CMAKE_BINARY_DIR}/bin
            && ${CMAKE_COMMAND} -E copy ${ext-InstallDir}/MinGW-Lapack/src/ext-Lapack/bin/libtmglib.dll       ${CMAKE_BINARY_DIR}/bin
            && ${CMAKE_COMMAND} -E copy ${ext-InstallDir}/MinGW-Lapack/src/ext-Lapack/bin/libgcc_s_seh-1.dll  ${CMAKE_BINARY_DIR}/bin
            && ${CMAKE_COMMAND} -E copy ${ext-InstallDir}/MinGW-Lapack/src/ext-Lapack/bin/libgfortran-3.dll   ${CMAKE_BINARY_DIR}/bin
            && ${CMAKE_COMMAND} -E copy ${ext-InstallDir}/MinGW-Lapack/src/ext-Lapack/bin/libquadmath-0.dll   ${CMAKE_BINARY_DIR}/bin
            && ${CMAKE_COMMAND} -E copy ${ext-InstallDir}/MinGW-Lapack/src/ext-Lapack/bin/libwinpthread-1.dll ${CMAKE_BINARY_DIR}/bin
            )
endif ()

# #################################################
# <===    MinGW Lapack
# #################################################

# ============================================================
# ===> LAPACK/BLAS (example, adapt to your setup)
# ============================================================

# TODO: also set LAPACK::LAPACK ?!

if(COIN_USE_SYSTEM_LAPACK)
    find_package(LAPACK REQUIRED)
    set(LAPACK_TARGET LAPACK::LAPACK)
else()
    set(LAPACK_TARGET ext-Lapack)
endif()

# ============================================================
# ===> MUMPS via FetchContent
# ============================================================

include(FetchContent)

if (POLICY CMP0169)
    cmake_policy(SET CMP0169 OLD) # needed for non-deprecated single arg FetchContent_Populate
endif ()

if (COIN_ENABLE_DOWNLOAD_MUMPS)
    set(MUMPS_VERSION "5.8.1")
    set(MUMPS_URL "https://mumps-solver.org/MUMPS_${MUMPS_VERSION}.tar.gz")

    FetchContent_Declare(
        Mumps
        URL ${MUMPS_URL}
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    )

    FetchContent_GetProperties(Mumps)
    if(NOT mumps_POPULATED)
        FetchContent_Populate(Mumps)

        file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists_mumps.cmake
             DESTINATION ${mumps_SOURCE_DIR})
        file(RENAME ${mumps_SOURCE_DIR}/CMakeLists_mumps.cmake
             ${mumps_SOURCE_DIR}/CMakeLists.txt)

        add_subdirectory(${mumps_SOURCE_DIR} ${mumps_BINARY_DIR})
    endif()
endif()

# #################################################
# ===> ASL compilation
# #################################################

if (COIN_ENABLE_DOWNLOAD_ASL)
    set(ASL_VERSION "3.1.0")
    set(COIN_HAS_ASL ON CACHE BOOL "Enable the ASL support" FORCE)

    set(ASL_URL        "https:////github.com/ampl/mp/archive/${ASL_VERSION}.tar.gz" CACHE FILEPATH "Path to ${ASL_VERSION}.tar.gz source archive")
    set(ASL_InstallDir "${ext-InstallDir}/ASL-${ASL_VERSION}/${CMAKE_CFG_INTDIR}/")

    ExternalProject_Add(ext-ASL
            PREFIX            ${ASL_InstallDir}
            URL               ${ASL_URL}
            UPDATE_COMMAND    ""
            PATCH_COMMAND     ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/ASL/AMPLConfig.cmake.in ${ASL_InstallDir}/src/ext-ASL/src/asl/solvers/
            && ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/ASL/CMakeLists.txt      ${ASL_InstallDir}/src/ext-ASL/src/asl/solvers/
            && ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/ASL/FindDL.cmake        ${ASL_InstallDir}/src/ext-ASL/src/asl/solvers/
            && ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/ASL/details.c0.cmake.in ${ASL_InstallDir}/src/ext-ASL/src/asl/solvers/
            CONFIGURE_COMMAND ${CMAKE_COMMAND} -E make_directory ${ASL_InstallDir}/src/ext-ASL/src/asl/solvers/build
            && ${CMAKE_COMMAND} -E chdir ${ASL_InstallDir}/src/ext-ASL/src/asl/solvers/build ${CMAKE_COMMAND} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${ext-InstallDir} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} -G ${CMAKE_GENERATOR} ..
            BUILD_COMMAND     ${CMAKE_COMMAND} -E chdir ${ASL_InstallDir}/src/ext-ASL/src/asl/solvers/build ${CMAKE_MAKE_PROGRAM}
            INSTALL_COMMAND   ${CMAKE_COMMAND} -E chdir ${ASL_InstallDir}/src/ext-ASL/src/asl/solvers/build ${CMAKE_MAKE_PROGRAM} install
            )

    set(IPOPT_HAS_AMPL ON CACHE BOOL "Enable Ampl interface")
endif ()

# #################################################
# <=== ASL compilation
# #################################################

# #################################################
# ===> Tests
# #################################################

if (COIN_ENABLE_DOWNLOAD_MINLPLIB)
    set(MINLPLIB_URL "http:////www.minlplib.org/minlplib_nl.zip" CACHE FILEPATH "Path to MinLpNl source archive")

    ExternalProject_Add(ext-MINLPLIB
            PREFIX            ${ext-InstallDir}/MINLPLIB
            URL               ${MINLPLIB_URL}
            PATCH_COMMAND     ""
            UPDATE_COMMAND    ""
            CONFIGURE_COMMAND ""
            BUILD_COMMAND     ""
            INSTALL_COMMAND   ""
            )

    include(MinLpTests.cmake)
endif ()

# #################################################
# <=== Tests
# #################################################

# #################################################
# ===> Patch
# #################################################

if (WIN32 AND COIN_ENABLE_DOWNLOAD_PATCH)
    set(PATCH_VERSION "2.5.9-7")

    set(PATCH_URL "https:////sourceforge.net//projects//gnuwin32//files//patch//${PATCH_VERSION}//patch-${PATCH_VERSION}-bin.zip" CACHE FILEPATH "Path to Patch-${PATCH_VERSION} binary archive")

    ExternalProject_Add(ext-PATCH
            PREFIX            ${ext-InstallDir}/Patch-${PATCH_VERSION}/
            URL               ${PATCH_URL}
            PATCH_COMMAND     ""
            UPDATE_COMMAND    ""
            CONFIGURE_COMMAND ""
            BUILD_COMMAND     ""
            INSTALL_COMMAND   ""
            )

    set(PATCH_EXECUTABLE "${ext-InstallDir}/Patch-${PATCH_VERSION}/src/ext-PATCH/bin/patch.exe" CACHE FILEPATH "Path to the patch executable")
else ()
    find_program(TMP_PATCH_EXECUTABLE patch)
    set(PATCH_EXECUTABLE "${TMP_PATCH_EXECUTABLE}" CACHE FILEPATH "Path to the patch executable")
endif ()

# #################################################
# <=== Patch
# #################################################

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
    if (COIN_ENABLE_DOWNLOAD_ASL)
        add_dependencies(${_target} ext-ASL)
    endif ()
    if (COIN_ENABLE_DOWNLOAD_LAPACK)
        add_dependencies(${_target} ext-Lapack)
    endif ()
endmacro ()

macro(add_executable_mod _target)
    add_executable (${_target} ${ARGN})

    if (COIN_ENABLE_DOWNLOAD_MUMPS)
        add_dependencies(${_target} dmumps)
    endif ()
    if (COIN_ENABLE_DOWNLOAD_ASL)
        add_dependencies(${_target} ext-ASL)
    endif ()
    if (COIN_ENABLE_DOWNLOAD_LAPACK)
        add_dependencies(${_target} ext-Lapack) # TODO: link with LAPACK::LAPACK or ext-Lapack depending on ctx
    endif ()
endmacro ()

# #################################################
# <===   Restart cmake
# #################################################
