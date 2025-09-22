# -------------------------------------------------------
# FindCheckMetis.cmake
# Sets MUMPS_METIS_LIB_PATH and MUMPS_METIS_INC_PATH
# according to user-provided path, downloaded METIS, or system-installed METIS.
# Crashes if METIS is required but not found.
# -------------------------------------------------------

function(find_or_check_metis)
    if(NOT ${MUMPS_USE_METIS})
        set(MUMPS_METIS_LIB_PATH "None" CACHE PATH "METIS library path")
        set(MUMPS_METIS_INC_PATH "None" CACHE PATH "METIS include path")
        return()
    endif()

    # 1) User provided path
    if(DEFINED MUMPS_METIS_LIB_PATH AND NOT MUMPS_METIS_LIB_PATH STREQUAL "None")
        message(STATUS "Using user-provided METIS library: ${MUMPS_METIS_LIB_PATH}")
        return()
    endif()

    # 2) Downloaded METIS
    if(COIN_ENABLE_DOWNLOAD_METIS)
        set(MUMPS_METIS_LIB_PATH "${ext-InstallDir}/lib" CACHE PATH "METIS library path")
        set(MUMPS_METIS_INC_PATH "${ext-InstallDir}/include" CACHE PATH "METIS include path")
        message(STATUS "Using downloaded METIS at ${MUMPS_METIS_LIB_PATH}")
        return()
    endif()

    # 3) System-installed METIS
    if(WIN32)
        set(METIS_HINTS /usr/lib /mingw64/lib /usr/local/lib)
        set(METIS_INCLUDE_HINTS /usr/include /mingw64/include /usr/local/include)
    elseif(APPLE)
        set(METIS_HINTS /usr/local/lib /opt/homebrew/lib)
        set(METIS_INCLUDE_HINTS /usr/local/include /opt/homebrew/include)
    else()
        set(METIS_HINTS /usr/lib /usr/lib/x86_64-linux-gnu /usr/local/lib)
        set(METIS_INCLUDE_HINTS /usr/include /usr/local/include)
    endif()

    find_library(METIS_LIBRARY NAMES metis PATHS ${METIS_HINTS})
    find_path(METIS_INCLUDE_DIR NAMES metis.h PATHS ${METIS_INCLUDE_HINTS})

    if(NOT METIS_LIBRARY)
        message(FATAL_ERROR
            "METIS is required for MUMPS but could not be found."
            " Provide -DMUMPS_METIS_LIB_PATH=/path/to/metis/lib, disable METIS with -DMUMPS_USE_METIS=OFF"
            " or enable COIN_ENABLE_DOWNLOAD_METIS to download METIS automatically."
        )
    endif()

    set(MUMPS_METIS_LIB_PATH ${METIS_LIBRARY} CACHE PATH "METIS library path")
    set(MUMPS_METIS_INC_PATH ${METIS_INCLUDE_DIR} CACHE PATH "METIS include path")
    message(STATUS "Found system METIS: ${MUMPS_METIS_LIB_PATH}")
endfunction()
