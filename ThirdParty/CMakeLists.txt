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


set(COIN_HSL_PATH "None" CACHE PATH "The HSL source Path")

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
        NOT COIN_ENABLE_DOWNLOAD_CLAPACK AND
        NOT COIN_USE_SYSTEM_LAPACK)
    message(WARNING "One kind of Blas / Lapack can be selected:
 - COIN_ENABLE_DOWNLOAD_MINGW_LAPACK AND
 - COIN_ENABLE_DOWNLOAD_LAPACK AND
 - COIN_ENABLE_DOWNLOAD_CLAPACK AND
 - COIN_USE_SYSTEM_LAPACK")
endif ()

# #################################################
# ===>    System Lapack
# #################################################

if (COIN_USE_SYSTEM_LAPACK)
    find_package(LAPACK REQUIRED)

    set(COIN_ENABLE_DOWNLOAD_LAPACK  OFF CACHE BOOL "Enable the download / compilation of Blas / Lapack")
    set(COIN_ENABLE_DOWNLOAD_CLAPACK OFF CACHE BOOL "Enable the download / compilation of CBlas / CLapack")

    get_filename_component(LAPACK_LINK_PATH "${LAPACK_LIBRARIES}" DIRECTORY)
endif ()

# #################################################
# <===    System Lapack
# #################################################

# #################################################
# ===>    CLapack
# #################################################

if (COIN_ENABLE_DOWNLOAD_CLAPACK)
    set(CLAPACK_VERSION "3.2.1")

    if (UNIX)
        set(CLAPACK_C_FLAGS      "-w")
        set(CLAPACK_LINKER_FLAGS "-w")
        if (NOT HAVE_64_BIT)
            set(CLAPACK_C_FLAGS      "-fPIC -w")
            set(CLAPACK_LINKER_FLAGS "-fPIC -w")
        endif ()
    endif ()

    set(COIN_HAS_LAPACK ON CACHE BOOL "Enable the Lapack support of CoinUtils" FORCE)
    set(COIN_HAS_BLAS   ON CACHE BOOL "Enable the Blas support of CoinUtils"   FORCE)

    set(CLAPACK_URL        "http:////netlib.sandia.gov/clapack/clapack-${CLAPACK_VERSION}-CMAKE.tgz" CACHE FILEPATH "Path to clapack-${CLAPACK_VERSION}-CMAKE.tgz source archive")
    set(CLAPACK_InstallDir "${ext-InstallDir}/CLapack-${CLAPACK_VERSION}/${CMAKE_CFG_INTDIR}/")

    if (WIN32 AND NOT MINGW)
        ExternalProject_Add(ext-Lapack
                PREFIX            ${CLAPACK_InstallDir}
                URL               ${CLAPACK_URL}
                UPDATE_COMMAND    ""
                PATCH_COMMAND     ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/f2c.h ${CLAPACK_InstallDir}/src/ext-Lapack/INCLUDE/
                && ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/f2c.h ${CLAPACK_InstallDir}/src/ext-Lapack/F2CLIBS/libf2c/
                CONFIGURE_COMMAND ${CMAKE_COMMAND} -E make_directory ${CLAPACK_InstallDir}/src/ext-Lapack/build
                && ${CMAKE_COMMAND} -E chdir ${CLAPACK_InstallDir}/src/ext-Lapack/build ${CMAKE_COMMAND} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${ext-InstallDir} -DCMAKE_C_FLAGS:String=${CLAPACK_C_FLAGS} -DCMAKE_EXE_LINKER_FLAGS:String=${CLAPACK_LINKER_FLAGS} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} -G ${CMAKE_GENERATOR} ..
                BUILD_COMMAND     ${CMAKE_COMMAND} -E chdir ${CLAPACK_InstallDir}/src/ext-Lapack/build ${CMAKE_MAKE_PROGRAM}
                INSTALL_COMMAND   ${CMAKE_COMMAND} -E copy ${CLAPACK_InstallDir}/src/ext-Lapack/build/SRC/lapack.lib            ${ext-InstallDir}/lib
                && ${CMAKE_COMMAND} -E copy ${CLAPACK_InstallDir}/src/ext-Lapack/build/F2CLIBS/libf2c/libf2c.lib ${ext-InstallDir}/lib/f2c.lib
                && ${CMAKE_COMMAND} -E copy ${CLAPACK_InstallDir}/src/ext-Lapack/build/BLAS/SRC/blas.lib         ${ext-InstallDir}/lib
                )
    elseif (UNIX)
        ExternalProject_Add(ext-Lapack
                PREFIX            ${CLAPACK_InstallDir}
                URL               ${CLAPACK_URL}
                UPDATE_COMMAND    ""
                PATCH_COMMAND     ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/f2c.h ${CLAPACK_InstallDir}/src/ext-Lapack/INCLUDE/
                && ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/f2c.h ${CLAPACK_InstallDir}/src/ext-Lapack/F2CLIBS/libf2c/
                CONFIGURE_COMMAND ${CMAKE_COMMAND} -E make_directory ${CLAPACK_InstallDir}/src/ext-Lapack/build
                && ${CMAKE_COMMAND} -E chdir ${CLAPACK_InstallDir}/src/ext-Lapack/build ${CMAKE_COMMAND} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${ext-InstallDir} -DCMAKE_C_FLAGS:String=${CLAPACK_C_FLAGS} -DCMAKE_EXE_LINKER_FLAGS:String=${CLAPACK_LINKER_FLAGS} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} ..
                BUILD_COMMAND     ${CMAKE_COMMAND} -E chdir ${CLAPACK_InstallDir}/src/ext-Lapack/build ${CMAKE_MAKE_PROGRAM} -j 16
                INSTALL_COMMAND   ${CMAKE_COMMAND} -E copy ${CLAPACK_InstallDir}/src/ext-Lapack/build/SRC/liblapack.a         ${ext-InstallDir}/lib
                && ${CMAKE_COMMAND} -E copy ${CLAPACK_InstallDir}/src/ext-Lapack/build/F2CLIBS/libf2c/libf2c.a ${ext-InstallDir}/lib
                && ${CMAKE_COMMAND} -E copy ${CLAPACK_InstallDir}/src/ext-Lapack/build/BLAS/SRC/libblas.a      ${ext-InstallDir}/lib
                )
    endif ()
endif ()

# #################################################
# <===    CLapack
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

# #################################################
# ===> Metis compilation
# #################################################

if (COIN_ENABLE_DOWNLOAD_METIS)
    set(METIS_VERSION "4.0.3")

    if (NOT EXISTS ${ext-InstallDir}/include/metis)
        make_directory(${ext-InstallDir}/include/metis)
    endif ()

    set(METIS_URL        "http:////glaros.dtc.umn.edu/gkhome/fetch/sw/metis/OLD/metis-${METIS_VERSION}.tar.gz" CACHE FILEPATH "Path to metis-${METIS_VERSION}.tar.gz source archive")
    set(METIS_InstallDir "${ext-InstallDir}/Metis-${METIS_VERSION}/${CMAKE_CFG_INTDIR}/")

    ExternalProject_Add(ext-Metis
            PREFIX            ${METIS_InstallDir}
            URL               ${METIS_URL}
            UPDATE_COMMAND    ""
            PATCH_COMMAND     ""
            CONFIGURE_COMMAND ""
            BUILD_COMMAND     ${CMAKE_COMMAND} -E chdir ${METIS_InstallDir}/src/ext-Metis/ ${CMAKE_MAKE_PROGRAM} -j 16
            INSTALL_COMMAND   ${CMAKE_COMMAND} -E copy ${METIS_InstallDir}/src/ext-Metis/libmetis.a   ${ext-InstallDir}/lib
            && ${CMAKE_COMMAND} -E copy ${METIS_InstallDir}/src/ext-Metis/Lib/macros.h ${ext-InstallDir}/include/metis/
            && ${CMAKE_COMMAND} -E copy ${METIS_InstallDir}/src/ext-Metis/Lib/struct.h ${ext-InstallDir}/include/metis/
            && ${CMAKE_COMMAND} -E copy ${METIS_InstallDir}/src/ext-Metis/Lib/proto.h  ${ext-InstallDir}/include/metis/
            && ${CMAKE_COMMAND} -E copy ${METIS_InstallDir}/src/ext-Metis/Lib/metis.h  ${ext-InstallDir}/include/metis/
            && ${CMAKE_COMMAND} -E copy ${METIS_InstallDir}/src/ext-Metis/Lib/defs.h   ${ext-InstallDir}/include/metis/
            && ${CMAKE_COMMAND} -E copy ${METIS_InstallDir}/src/ext-Metis/Lib/rename.h ${ext-InstallDir}/include/metis/
            )
endif ()

# #################################################
# <=== Metis compilation
# #################################################

# #################################################
# ===> Mumps compilation
# #################################################

# TODO: Modern CMake (≥ 3.12 - 3.15) encourages FetchContent combined with add_subdirectory so dependencies
#       become real CMake targets, with proper include directories and link information.
#    => refactor this

if (COIN_ENABLE_DOWNLOAD_MUMPS)
    set(MUMPS_VERSION "5.8.1")
    set(COIN_HAS_MUMPS  ON CACHE BOOL "Clp uses the MUMPS linear solver" FORCE)
    set(IPOPT_HAS_MUMPS ON CACHE BOOL "Enable Mumps solver" FORCE)

    set(MUMPS_DEPENDS "")

    include(FindCheckMetis.cmake)
    find_or_check_metis(MUMPS_USE_METIS)

    if (COIN_ENABLE_DOWNLOAD_CLAPACK OR COIN_ENABLE_DOWNLOAD_LAPACK)
        set(MUMPS_DEPENDS ${MUMPS_DEPENDS} ext-Lapack)
    endif ()
    if (COIN_ENABLE_DOWNLOAD_METIS)
        set(MUMPS_DEPENDS ${MUMPS_DEPENDS} ext-Metis)
    endif ()

    set(MUMPS_URL "https://mumps-solver.org/MUMPS_${MUMPS_VERSION}.tar.gz" CACHE STRING "URL to MUMPS_${MUMPS_VERSION}.tar.gz source archive")
    set(MUMPS_InstallDir "${ext-InstallDir}/Mumps-${MUMPS_VERSION}/${CMAKE_CFG_INTDIR}/")

    if (COIN_USE_SYSTEM_LAPACK)
        set(MUMPS_LAPACK_PATH "${LAPACK_LINK_PATH}")
    else ()
        set(MUMPS_LAPACK_PATH "${ext-InstallDir}/lib")
    endif ()

    # TODO: we need to add the path to mumps_mpi.h once Mumps is patched ...
    ExternalProject_Add(ext-Mumps
            PREFIX            ${MUMPS_InstallDir}
            DEPENDS           ${MUMPS_DEPENDS}
            URL               ${MUMPS_URL}
            UPDATE_COMMAND    ""
            PATCH_COMMAND     ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists_mumps.cmake ${MUMPS_InstallDir}/src/ext-Mumps/CMakeLists.txt
            #		                     && ${CMAKE_COMMAND} -E chdir ${MUMPS_InstallDir}/src/ext-Mumps ${PATCH_EXECUTABLE} -p1 < ${CMAKE_CURRENT_SOURCE_DIR}/mumps_mpi.patch
            #		                     && ${CMAKE_COMMAND} -E chdir ${MUMPS_InstallDir}/src/ext-Mumps ${PATCH_EXECUTABLE} -p1 < ${CMAKE_CURRENT_SOURCE_DIR}/mumps.patch
            CONFIGURE_COMMAND ${CMAKE_COMMAND} -E make_directory ${MUMPS_InstallDir}/src/ext-Mumps/build
            && ${CMAKE_COMMAND} -E chdir ${MUMPS_InstallDir}/src/ext-Mumps/build ${CMAKE_COMMAND} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${ext-InstallDir} -DMUMPS_USE_LIBSEQ=ON -DMUMPS_USE_METIS=${MUMPS_USE_METIS} -DMUMPS_LAPACK_LIB_PATH:Path=${MUMPS_LAPACK_PATH} -DMUMPS_METIS_LIB_PATH:Path=${MUMPS_METIS_LIB_PATH} -DMUMPS_INSTALL_COIN=ON -DMUMPS_USE_F2C=${COIN_ENABLE_DOWNLOAD_CLAPACK} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} -G ${CMAKE_GENERATOR} ..
            BUILD_COMMAND     ${CMAKE_COMMAND} -E chdir ${MUMPS_InstallDir}/src/ext-Mumps/build ${CMAKE_MAKE_PROGRAM} -j 16
            INSTALL_COMMAND   ${CMAKE_COMMAND} -E chdir ${MUMPS_InstallDir}/src/ext-Mumps/build ${CMAKE_MAKE_PROGRAM} install
            )

            # removed: -DMUMPS_METIS_INC_PATH:Path=${MUMPS_METIS_INC_PATH} 
endif ()
# #################################################
# <=== Mumps compilation
# #################################################

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
# ===>    HSL
# #################################################

if ((COIN_ENABLE_COMPILE_HSL OR COIN_USE_COINHSL) AND NOT COIN_HSL_PATH STREQUAL "None")
    set(COIN_HAS_HSL ON CACHE BOOL "Enable the HSL support" FORCE)
    set(COIN_HAS_HSL_OTHER OFF CACHE BOOL "Enable the non local solver HSL support" FORCE)

    set(COINHSL_HAS_METIS  "${COIN_ENABLE_DOWNLOAD_METIS}")
    set(COINHSL_HSL2013    OFF)
    set(COIN_HAS_HSL_OTHER OFF)

    set(COINHSL_VERSION "2014.01.17")
    set(COINHSL_VERSION_MAJOR   2014)
    set(COINHSL_VERSION_MINOR   1)
    set(COINHSL_VERSION_RELEASE 17)

    set(HSL_SOLVER_SRCS )
    set(HSL_OTHER_SRCS )

    set(COIN_HAS_HSL       OFF CACHE INTERNAL "")
    set(COINHSL_HAS_MA27   OFF CACHE INTERNAL "")
    set(COINHSL_HAS_MA28   OFF CACHE INTERNAL "")
    set(COINHSL_HAS_MC19   OFF CACHE INTERNAL "")
    set(COINHSL_HAS_MA57   OFF CACHE INTERNAL "")
    set(COINHSL_HAS_MA86   OFF CACHE INTERNAL "")
    set(COINHSL_HAS_MA77   OFF CACHE INTERNAL "")
    set(COINHSL_HAS_MC68   OFF CACHE INTERNAL "")
    set(COINHSL_HAS_MA97   OFF CACHE INTERNAL "")
    set(COIN_HAS_HSL_OTHER OFF CACHE INTERNAL "")

    if (COIN_USE_COINHSL)
        set(COIN_HAS_HSL     ON CACHE INTERNAL "")
        set(COINHSL_HAS_MA27 ON CACHE INTERNAL "")
        set(COINHSL_HAS_MA28 ON CACHE INTERNAL "")
        set(COINHSL_HAS_MC19 ON CACHE INTERNAL "")

        add_definitions(-DCOINHSL_HAS_MA27 -DCOINHSL_HAS_MA28 -DCOINHSL_HAS_MC19)

        set(HSL_SOLVER_SRCS ${HSL_SOLVER_SRCS}
                ${COIN_HSL_PATH}/ma27/ma27d.f
                ${COIN_HSL_PATH}/ma28/ma28d.f
                ${COIN_HSL_PATH}/mc19/mc19d.f
                ${COIN_HSL_PATH}/common/deps.f)
    else ()
        if (EXISTS ${COIN_HSL_PATH}/ma27/ma27d.f)
            set(COINHSL_HAS_MA27 ON CACHE INTERNAL "")
            set(COIN_HAS_HSL     ON CACHE INTERNAL "")

            add_definitions(-DCOINHSL_HAS_MA27)

            set(HSL_SOLVER_SRCS ${HSL_SOLVER_SRCS}
                    ${COIN_HSL_PATH}/ma27/ma27d.f)
        endif ()
        if (EXISTS ${COIN_HSL_PATH}/ma28/ma28d.f)
            set(COINHSL_HAS_MA28 ON CACHE INTERNAL "")
            set(COIN_HAS_HSL     ON CACHE INTERNAL "")

            add_definitions(-DCOINHSL_HAS_MA28)

            set(HSL_SOLVER_SRCS ${HSL_SOLVER_SRCS}
                    ${COIN_HSL_PATH}/ma28/ma28d.f)
        endif ()
        if (EXISTS ${COIN_HSL_PATH}/mc19/mc19d.f)
            set(COINHSL_HAS_MC19 ON CACHE INTERNAL "")
            set(COIN_HAS_HSL     ON CACHE INTERNAL "")

            add_definitions(-DCOINHSL_HAS_MC19)

            set(HSL_SOLVER_SRCS ${HSL_SOLVER_SRCS}
                    ${COIN_HSL_PATH}/mc19/mc19d.f)
        endif ()
    endif ()

    if (EXISTS ${COIN_HSL_PATH}/ma57/ma57d.f)
        set(COINHSL_HAS_MA57   ON CACHE INTERNAL "")
        set(COIN_HAS_HSL_OTHER ON CACHE INTERNAL "")

        add_definitions(-DCOINHSL_HAS_MA57)

        set(HSL_OTHER_SRCS ${HSL_OTHER_SRCS}
                ${COIN_HSL_PATH}/ma57/ma57d.f)
    endif ()
    if (EXISTS ${COIN_HSL_PATH}/ma86/ma86d.f)
        set(COINHSL_HAS_MA86   ON CACHE INTERNAL "")
        set(COIN_HAS_HSL_OTHER ON CACHE INTERNAL "")

        add_definitions(-DCOINHSL_HAS_MA86)

        set(HSL_OTHER_SRCS ${HSL_OTHER_SRCS}
                ${COIN_HSL_PATH}/ma86/ma86d.f)
    endif ()
    if (EXISTS ${COIN_HSL_PATH}/ma77/ma77d.f)
        set(COINHSL_HAS_MA77   ON CACHE INTERNAL "")
        set(COIN_HAS_HSL_OTHER ON CACHE INTERNAL "")

        add_definitions(-DCOINHSL_HAS_MA77)

        set(HSL_OTHER_SRCS ${HSL_OTHER_SRCS}
                ${COIN_HSL_PATH}/ma77/ma77d.f)
    endif ()
    if (EXISTS ${COIN_HSL_PATH}/mc68/mc68.f)
        set(COINHSL_HAS_MC68   ON CACHE INTERNAL "")
        set(COIN_HAS_HSL_OTHER ON CACHE INTERNAL "")

        add_definitions(-DCOINHSL_HAS_MC68)

        set(HSL_OTHER_SRCS ${HSL_OTHER_SRCS}
                ${COIN_HSL_PATH}/mc68/mc68.f)
    endif ()
    if (EXISTS ${COIN_HSL_PATH}/ma97/ma97d.f)
        set(COINHSL_HAS_MA97   ON CACHE INTERNAL "")
        set(COIN_HAS_HSL_OTHER ON CACHE INTERNAL "")

        add_definitions(-DCOINHSL_HAS_MA97)

        set(HSL_OTHER_SRCS ${HSL_OTHER_SRCS}
                ${COIN_HSL_PATH}/ma97/ma97d.f)
    endif ()

    if (COINHSL_HSL2013)
        set(COIN_HAS_HSL ON CACHE INTERNAL "")

        add_definitions(-DCOINHSL_HSL2013)
    endif ()

    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/../Ipopt/include/config_coinhsl.h.in ${CMAKE_BINARY_DIR}/Ipopt/include/config_coinhsl.h)
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/../Ipopt/include/config_coinhsl.h.in ${CMAKE_BINARY_DIR}/Ipopt/include/CoinHslConfig.h)

    add_library(hsl SHARED ${HSL_SOLVER_SRCS})
    add_library(hsl-static STATIC ${HSL_SOLVER_SRCS})
    if (COIN_HAS_HSL_OTHER)
        add_library(hsl-other STATIC ${HSL_OTHER_SRCS})
    endif ()

    if (IPOPT_HAS_LINEARSOLVERLOADER)
        install(TARGETS hsl
                RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}
                LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR})
    endif ()
endif ()

# #################################################
# <===    HSL
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
        add_dependencies(${_target} ext-Mumps)
    endif ()
    if (COIN_ENABLE_DOWNLOAD_METIS)
        add_dependencies(${_target} ext-Metis)
    endif ()
    if (COIN_ENABLE_DOWNLOAD_ASL)
        add_dependencies(${_target} ext-ASL)
    endif ()
    if (COIN_ENABLE_DOWNLOAD_LAPACK OR COIN_ENABLE_DOWLOAD_CLAPACK)
        add_dependencies(${_target} ext-Lapack)
    endif ()
endmacro ()

macro(add_executable_mod _target)
    add_executable (${_target} ${ARGN})

    if (COIN_ENABLE_DOWNLOAD_MUMPS)
        add_dependencies(${_target} ext-Mumps)
    endif ()
    if (COIN_ENABLE_DOWNLOAD_METIS)
        add_dependencies(${_target} ext-Metis)
    endif ()
    if (COIN_ENABLE_DOWNLOAD_ASL)
        add_dependencies(${_target} ext-ASL)
    endif ()
    if (COIN_ENABLE_DOWNLOAD_LAPACK OR COIN_ENABLE_DOWLOAD_CLAPACK)
        add_dependencies(${_target} ext-Lapack)
    endif ()
endmacro ()

# #################################################
# <===   Restart cmake
# #################################################
