option(s2_build_testing  "Build S2 tests and add `make check` target)." OFF)
option(s2_build_python   "Build S2 Python bindings" OFF)

project(s2 CXX)
cmake_minimum_required(VERSION 3.1.0 FATAL_ERROR)

set(PROJECT_VERSION 0.1.0)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_definitions(-DS2_USE_EXACTFLOAT -DNDEBUG)

find_package(OpenSSL REQUIRED)

include_directories(
  s2
  .
  ${OPENSSL_INCLUDE_DIR}
)

add_library(
  s2util SHARED

  base/int128.cc
  base/logging.cc
  base/stringprintf.cc
  base/strtoint.cc
  strings/split.cc
  strings/stringprintf.cc
  strings/strutil.cc
  util/coding/coder.cc
  util/coding/varint.cc
  util/math/exactfloat/exactfloat.cc
  util/math/mathlimits.cc
  util/math/mathutil.cc
)

add_library(
  s2cellid SHARED

  s1angle.cc
  s2.cc
  s2cellid.cc
  s2latlng.cc
)

add_library(
  s2 SHARED

  s1interval.cc
  s2cap.cc
  s2cell.cc
  s2cellunion.cc
  s2edgeindex.cc
  s2edgeutil.cc
  s2latlngrect.cc
  s2loop.cc
  s2pointregion.cc
  s2polygon.cc
  s2polygonbuilder.cc
  s2polyline.cc
  s2r2rect.cc
  s2region.cc
  s2regioncoverer.cc
  s2regionintersection.cc
  s2regionunion.cc
)

target_link_libraries(s2util ${OPENSSL_LIBRARIES})
target_link_libraries(s2cellid s2util)
target_link_libraries(s2 s2cellid s2util ${OPENSSL_LIBRARIES} pthread)

install(TARGETS s2util s2cellid s2
  INCLUDES DESTINATION include/s2
  LIBRARY DESTINATION lib
  ARCHIVE DESTINATION lib
)

# Install header files
install(DIRECTORY s2 DESTINATION include)
install(DIRECTORY base DESTINATION include/s2 FILES_MATCHING PATTERN "*.h")
install(DIRECTORY strings DESTINATION include/s2 FILES_MATCHING PATTERN "*.h")
install(DIRECTORY util DESTINATION include/s2 FILES_MATCHING PATTERN "*.h")

if(PKG_CONFIG_FOUND)
  # Produce a pkg-config file for linking against the shared lib
  configure_file("s2.pc.in" "s2.pc" @ONLY)
  configure_file("s2cellid.pc.in" "s2cellid.pc" @ONLY)
  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/s2.pc ${CMAKE_CURRENT_BINARY_DIR}/s2cellid.pc DESTINATION lib/pkgconfig)
endif()

if(s2_build_testing)
  enable_testing()
  add_subdirectory(tests)
endif(s2_build_testing)

if(s2_build_python)
  add_subdirectory(python)
endif(s2_build_python)
