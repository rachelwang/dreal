cmake_minimum_required(VERSION 2.8.7)
project(DREAL C CXX)
set(DREAL_VERSION_MAJOR 2)
set(DREAL_VERSION_MINOR 0)

set(CMAKE_COLOR_MAKEFILE ON)
enable_testing()

option(REQUIRE_ODE "REQUIRE_ODE" OFF)

# Added for CTest
include(CTest)
# Added for External Projects
include(ExternalProject)

set(DREAL_EXTRA_LINKER_FLAGS "")
set(DREAL_EXTRA_CXX_FLAGS "")

################################################################
# Set Module Path
################################################################
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")

################################################################
# Initialize CXXFLAGS.
################################################################
set(CMAKE_CXX_FLAGS                "-Wall -Wextra -std=c++11 ${DREAL_EXTRA_CXX_FLAGS}")
set(CMAKE_CXX_FLAGS_DEBUG          "-g -DDREAL_DEBUG -DDREAL_TRACE -fno-inline")
set(CMAKE_CXX_FLAGS_MINSIZEREL     "-Os -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE        "-O3 -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O2 -g")

################################################################
# Test coverage
################################################################
if("${TESTCOV}" MATCHES "ON")
  include(CodeCoverage)
  message(STATUS "Enable test-coverage")
  set(CMAKE_CXX_FLAGS_DEBUG        "${CMAKE_CXX_FLAGS_DEBUG} -O0 -fprofile-arcs -ftest-coverage --coverage")
  setup_target_for_coverage(cov ${DREAL_SOURCE_DIR}/script/run_tests.sh coverage)
endif()

################################################################
# Compiler-specific C++11 activation.
################################################################
if ("${CMAKE_CXX_COMPILER_ID}" MATCHES "GNU")
  execute_process(
    COMMAND ${CMAKE_CXX_COMPILER} -dumpversion OUTPUT_VARIABLE GCC_VERSION)
  if (NOT (GCC_VERSION VERSION_GREATER 4.8 OR GCC_VERSION VERSION_EQUAL 4.8))
    message(FATAL_ERROR "${PROJECT_NAME} requires g++ 4.8 or greater.")
  endif ()
elseif ("${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-mismatched-tags -Qunused-arguments")
  if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    # In OSX, clang requires "-stdlib=libc++" to support C++11
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
    set(DREAL_EXTRA_LINKER_FLAGS "-stdlib=libc++")
  endif ()
else ()
  message(FATAL_ERROR "Your C++ compiler does not support C++11.")
endif ()

################################################################
# Fix Paths
################################################################
SET(CMAKE_SYSTEM_INCLUDE_PATH ${CMAKE_SYSTEM_INCLUDE_PATH}
  /usr/local/include /opt/local/include
  /usr/include/w32api
  /usr/X11R6/include /usr/include/X11
  /usr/pkg/include
  /opt/csw/include /opt/include
  /usr/include /include
  )
SET(CMAKE_SYSTEM_LIBRARY_PATH ${CMAKE_SYSTEM_LIBRARY_PATH}
  $ENV{LD_LIBRARY_PATH}
  /usr/local/lib /opt/local/lib
  /usr/lib/w32api
  /usr/X11R6/lib /usr/lib/X11
  /usr/pkg/lib
  /opt/csw/lib /opt/lib
  /usr/lib /lib
  )
SET(CMAKE_SYSTEM_PROGRAM_PATH ${CMAKE_SYSTEM_PROGRAM_PATH}
  /usr/local/bin /usr/pkg/bin /usr/bin /sbin /bin
  )
SET(CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES
  ${CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES}
  /usr/lib64 /usr/lib32 /usr/lib /lib
  )

################################################################
# Packages
################################################################
# Bison & Flex
find_package(BISON REQUIRED)
find_package(FLEX REQUIRED)

################################################################
# External: FILIB++
################################################################
ExternalProject_Add(FILIBXX
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/external/filibxx
  GIT_REPOSITORY https://github.com/soonhokong/filibxx
  GIT_TAG origin/master
  UPDATE_COMMAND git pull origin master
  CONFIGURE_COMMAND autoreconf --install > /dev/null 2>&1 || autoreconf && ./configure CC=${CMAKE_C_COMPILER} CXX=${CMAKE_CXX_COMPILER} --prefix=${CMAKE_CURRENT_BINARY_DIR}
  BUILD_COMMAND make -j
  BUILD_IN_SOURCE 1
  INSTALL_COMMAND make -j install
)

################################################################
# External: CAPD-DynSys-3.0
################################################################
ExternalProject_Add(CAPD
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/external/capd_dynsys
# GIT_REPOSITORY https://github.com/soonhokong/capdDynSys-4.0.git
  GIT_REPOSITORY https://github.com/soonhokong/capdDynSys-3.0.git
  GIT_TAG origin/master
  UPDATE_COMMAND git pull origin master
  CONFIGURE_COMMAND autoreconf --install > /dev/null 2>&1 || autoreconf && ./configure CC=${CMAKE_C_COMPILER} CXX=${CMAKE_CXX_COMPILER} --prefix=${CMAKE_CURRENT_BINARY_DIR} --without-gui --with-filib=no --with-mpfr=no
  BUILD_COMMAND make -j
  BUILD_IN_SOURCE 1
  INSTALL_COMMAND make -j install
)

################################################################
# Threads
################################################################
find_package (Threads REQUIRED)
set(EXTRA_LIBS ${EXTRA_LIBS} ${CMAKE_THREAD_LIBS_INIT})

################################################################
# External: libunwind (only for Linux)
################################################################
if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
ExternalProject_Add(LIBUNWIND
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/external/libunwind
  GIT_REPOSITORY https://github.com/soonhokong/libunwind.git
  GIT_TAG origin/master
  UPDATE_COMMAND git pull origin master
  CONFIGURE_COMMAND autoreconf --install > /dev/null 2>&1 || autoreconf && ./configure CC=${CMAKE_C_COMPILER} CXX=${CMAKE_CXX_COMPILER} --prefix=${CMAKE_CURRENT_BINARY_DIR}
  BUILD_COMMAND make -j
  BUILD_IN_SOURCE 1
  INSTALL_COMMAND make install
)
endif()

################################################################
# External: gflags (Google Flags)
################################################################
ExternalProject_Add(GFLAGS
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/external/gflags
  GIT_REPOSITORY https://github.com/soonhokong/gflags.git
  GIT_TAG origin/master
  UPDATE_COMMAND git pull origin master
  CONFIGURE_COMMAND cmake -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} -DCMAKE_CXX_FLAGS=-fPIC -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_CURRENT_BINARY_DIR} ./
  BUILD_COMMAND make -j
  BUILD_IN_SOURCE 1
  INSTALL_COMMAND make install
)

################################################################
# External: glog (Google Log)
################################################################
ExternalProject_Add(GLOG
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/external/glog
  GIT_REPOSITORY https://github.com/soonhokong/glog.git
  GIT_TAG origin/master
  UPDATE_COMMAND git pull origin master
  CONFIGURE_COMMAND autoreconf --install > /dev/null 2>&1 || autoreconf && ./configure CC=${CMAKE_C_COMPILER} CXX=${CMAKE_CXX_COMPILER} --prefix=${CMAKE_CURRENT_BINARY_DIR} --with-gflags=${CMAKE_CURRENT_BINARY_DIR}
  BUILD_COMMAND make -j
  BUILD_IN_SOURCE 1
  INSTALL_COMMAND make install
)
set(EXTRA_LIBS ${EXTRA_LIBS} "libglog.a")
set(EXTRA_LIBS ${EXTRA_LIBS} "gflags")

################################################################
# External: json11 (Dropbox json11)
################################################################
ExternalProject_Add(JSON11
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/external/json11
  GIT_REPOSITORY https://github.com/soonhokong/json11.git
  GIT_TAG origin/master
  UPDATE_COMMAND git pull origin master
  CONFIGURE_COMMAND cmake -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_CURRENT_BINARY_DIR} ./
  BUILD_COMMAND make -j
  BUILD_IN_SOURCE 1
  INSTALL_COMMAND make install
)
set(EXTRA_LIBS ${EXTRA_LIBS} "-ljson11")

if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
set(EXTRA_LIBS ${EXTRA_LIBS} "libunwind.a")
endif()

################################################################
# External: set up include dir and libpath
################################################################
include_directories(${CMAKE_CURRENT_BINARY_DIR}/include)
set(EXTERNAL_LD_FLAGS "-L${CMAKE_CURRENT_BINARY_DIR}/lib")

################################################################
# CXX Flags
################################################################
set(DREAL_EXTRA_CXX_FLAGS "${DREAL_EXTRA_CXX_FLAGS} -mfpmath=sse -msse -msse2 -ffloat-store")

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
  set(DREAL_EXTRA_CXX_FLAGS "${DREAL_EXTRA_CXX_FLAGS} -frounding-math")
endif()

################################################################
# CAPD LIB
################################################################
set(EXTRA_LIBS ${EXTRA_LIBS} "-lcapddynsysfacade -lcapdcovrel -lcapddiffIncl -lcapdpoincare -lcapddiffAlgebra -lcapddynsys -lcapdmap -lcapddynset -lcapdgeomset -lcapdalgfacade -lcapdmatrixAlgorithms -lcapdvectalg -lprim -lcapdintervals -lcapdrounding -lcapdbasicalg -lcapdauxil -lcapdalglib")

set(ODE_ENABLED TRUE)

################################################################
# FILIB LIB
################################################################
set(EXTRA_LIBS ${EXTRA_LIBS} "-lprim")

################################################################
# GIT HASH
################################################################
include(GetGitRevisionDescription)
get_git_head_revision(GIT_REFSPEC GIT_SHA1)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/util/git_sha1.cpp.in" "${CMAKE_CURRENT_BINARY_DIR}/git_sha1.cpp" @ONLY)
add_library(git_sha1 "${CMAKE_CURRENT_BINARY_DIR}/git_sha1.cpp" "${CMAKE_CURRENT_SOURCE_DIR}/util/git_sha1.h")

################################################################
# EGLIBC (Optional)
################################################################
if(${CMAKE_SYSTEM_NAME} MATCHES "Linux" AND "${EGLIBCPATH}" MATCHES ".+")
  message(STATUS "Use EGLIBC Installed at ${EGLIBCPATH}")
 set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--rpath=${EGLIBCPATH}:/usr/lib/gcc/x86_64-linux-gnu/4.8:/usr/lib:/usr/lib/x86_64-linux-gnu/")
 set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--dynamic-linker=${EGLIBCPATH}/lib/ld-linux-x86-64.so.2")
else()
  message(STATUS "Use built-in EGLIBC.")
endif()

################################################################
# Include Directories
################################################################
include_directories(${DREAL_SOURCE_DIR})
include_directories(${DREAL_SOURCE_DIR}/opensmt/parsers)
include_directories(${DREAL_SOURCE_DIR}/opensmt/parsers/smt2)
include_directories(${DREAL_SOURCE_DIR}/opensmt)
include_directories(${DREAL_SOURCE_DIR}/opensmt/api)
include_directories(${DREAL_SOURCE_DIR}/opensmt/cnfizers)
include_directories(${DREAL_SOURCE_DIR}/opensmt/common)
include_directories(${DREAL_SOURCE_DIR}/opensmt/egraph)
include_directories(${DREAL_SOURCE_DIR}/opensmt/minisat)
include_directories(${DREAL_SOURCE_DIR}/opensmt/minisat/core)
include_directories(${DREAL_SOURCE_DIR}/opensmt/minisat/mtl)
include_directories(${DREAL_SOURCE_DIR}/opensmt/proof)
include_directories(${DREAL_SOURCE_DIR}/opensmt/simplifiers)
include_directories(${DREAL_SOURCE_DIR}/opensmt/smtsolvers)
include_directories(${DREAL_SOURCE_DIR}/opensmt/sorts)
include_directories(${DREAL_SOURCE_DIR}/opensmt/tsolvers)
include_directories(${DREAL_SOURCE_DIR}/opensmt/tsolvers/emptysolver)
configure_file("${DREAL_SOURCE_DIR}/version.h.in" "${DREAL_BINARY_DIR}/version.h")
configure_file("${DREAL_SOURCE_DIR}/config.h.in" "${DREAL_BINARY_DIR}/config.h")
include_directories("${DREAL_BINARY_DIR}")

add_subdirectory(opensmt/parsers/smt2)
set(DREAL_LIBS ${DREAL_LIBS} opensmt_smt2parser)
add_subdirectory(opensmt)
add_subdirectory(opensmt/parsers)
add_subdirectory(opensmt/egraph)
set(DREAL_LIBS ${DREAL_LIBS} opensmt_egraph)
add_subdirectory(opensmt/common)
set(DREAL_LIBS ${DREAL_LIBS} opensmt_common)
add_subdirectory(opensmt/api)
set(DREAL_LIBS ${DREAL_LIBS} opensmt_api)
add_subdirectory(opensmt/cnfizers)
set(DREAL_LIBS ${DREAL_LIBS} opensmt_cnfizers)
add_subdirectory(opensmt/sorts)
set(DREAL_LIBS ${DREAL_LIBS} opensmt_sorts)
add_subdirectory(opensmt/minisat)
add_subdirectory(opensmt/simplifiers)
set(DREAL_LIBS ${DREAL_LIBS} opensmt_simplifiers)
add_subdirectory(opensmt/smtsolvers)
set(DREAL_LIBS ${DREAL_LIBS} opensmt_smtsolvers)
add_subdirectory(opensmt/tsolvers)
set(DREAL_LIBS ${DREAL_LIBS} opensmt_tsolvers)
add_subdirectory(opensmt/tsolvers/emptysolver)
set(DREAL_LIBS ${DREAL_LIBS} opensmt_emptysolver)
add_subdirectory(dsolvers)
set(DREAL_LIBS ${DREAL_LIBS} dsolvers)
add_subdirectory(realpaver)
set(DREAL_LIBS ${DREAL_LIBS} realpaver)
add_subdirectory(util)
set(DREAL_LIBS ${DREAL_LIBS} util)
set(DREAL_LIBS ${DREAL_LIBS} git_sha1)

#add tests
add_subdirectory(tests/nra)
add_subdirectory(tests/nra_ode)

#dependencies
add_dependencies(GFLAGS LIBUNWIND)
add_dependencies(GLOG GFLAGS)
add_dependencies(opensmt_smtsolvers GFLAGS)
add_dependencies(opensmt_smtsolvers GLOG)
add_dependencies(dsolvers GLOG)
add_dependencies(dsolvers FILIBXX)
add_dependencies(dsolvers CAPD)
add_dependencies(realpaver FILIBXX)
add_dependencies(realpaver CAPD)
add_dependencies(realpaver GLOG)
add_dependencies(util GLOG)

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${DREAL_EXTRA_LINKER_FLAGS} ${EXTERNAL_LD_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS_TESTCOV "${CMAKE_EXE_LINKER_FLAGS} -fprofile-arcs -ftest-coverage")

set(EXTRA_LIBS ${DREAL_LIBS} ${EXTRA_LIBS})
add_executable(solver main.cpp)
target_link_libraries(solver ${EXTRA_LIBS})

# Include style check
include(StyleCheck)
file(GLOB_RECURSE DREAL_SOURCES
         ${DREAL_SOURCE_DIR}
         ${DREAL_SOURCE_DIR}/dsolvers/[A-Za-z]*.cpp
         ${DREAL_SOURCE_DIR}/dsolvers/[A-Za-z]*.h)
add_style_check_target(style "${DREAL_SOURCES}")
add_test(NAME style_check COMMAND ${DREAL_SOURCE_DIR}/cmake/Modules/cpplint.py ${DREAL_SOURCES})

ADD_CUSTOM_COMMAND(TARGET solver
          POST_BUILD
          COMMAND ${CMAKE_COMMAND} -E make_directory ${DREAL_SOURCE_DIR}/../bin
          COMMAND ${CMAKE_COMMAND} -E copy ${DREAL_BINARY_DIR}/solver ${DREAL_SOURCE_DIR}/../bin/
          COMMAND ${CMAKE_COMMAND} -E copy ${DREAL_BINARY_DIR}/solver ${DREAL_SOURCE_DIR}/../bin/dReal
)
