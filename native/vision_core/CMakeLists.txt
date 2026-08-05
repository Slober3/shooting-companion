cmake_minimum_required(VERSION 3.20)
project(shooting_companion_vision_core VERSION 0.1.0 LANGUAGES C CXX)

option(SC_VISION_ENABLE_OPENCV "Build the optional experimental OpenCV backend" ON)
option(SC_VISION_BUILD_TESTS "Build native vision tests" ON)
option(SC_VISION_WARNINGS_AS_ERRORS "Treat native compiler warnings as errors" OFF)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

function(sc_vision_enable_strict_warnings target)
  if(MSVC)
    target_compile_options(${target} PRIVATE /W4)
    if(SC_VISION_WARNINGS_AS_ERRORS)
      target_compile_options(${target} PRIVATE /WX)
    endif()
  else()
    target_compile_options(${target} PRIVATE -Wall -Wextra -Wpedantic)
    if(SC_VISION_WARNINGS_AS_ERRORS)
      target_compile_options(${target} PRIVATE -Werror)
    endif()
  endif()
endfunction()

if(SC_VISION_ENABLE_OPENCV)
  find_package(OpenCV QUIET COMPONENTS core imgproc imgcodecs)
endif()

set(VISION_CORE_IMPLEMENTATION_SOURCES
  src/geometry.cpp
  src/image_probe.cpp
  src/vision_core.cpp
)

if(OpenCV_FOUND)
  list(APPEND VISION_CORE_IMPLEMENTATION_SOURCES src/opencv_backend.cpp)
  set(SC_VISION_HAS_OPENCV 1)
  message(STATUS "Vision core: OpenCV ${OpenCV_VERSION} enabled")
else()
  list(APPEND VISION_CORE_IMPLEMENTATION_SOURCES src/opencv_backend_stub.cpp)
  set(SC_VISION_HAS_OPENCV 0)
  message(STATUS "Vision core: OpenCV unavailable; honest geometry-only fallback")
endif()

add_library(vision_core_impl STATIC ${VISION_CORE_IMPLEMENTATION_SOURCES})
sc_vision_enable_strict_warnings(vision_core_impl)
set_target_properties(vision_core_impl PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_include_directories(vision_core_impl
  PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include
  PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src
)
target_compile_definitions(vision_core_impl
  PRIVATE SC_VISION_HAS_OPENCV=${SC_VISION_HAS_OPENCV}
)
if(OpenCV_FOUND)
  target_include_directories(vision_core_impl PRIVATE ${OpenCV_INCLUDE_DIRS})
  target_link_libraries(vision_core_impl PRIVATE ${OpenCV_LIBS})
endif()

add_library(shooting_companion_vision SHARED src/c_api.cpp)
sc_vision_enable_strict_warnings(shooting_companion_vision)
target_include_directories(shooting_companion_vision
  PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include
)
target_compile_definitions(shooting_companion_vision
  PRIVATE SC_VISION_BUILD_SHARED=1
)
target_link_libraries(shooting_companion_vision PRIVATE vision_core_impl)

add_executable(vision_cli cli/main.cpp)
sc_vision_enable_strict_warnings(vision_cli)
target_link_libraries(vision_cli PRIVATE vision_core_impl)

if(SC_VISION_BUILD_TESTS)
  enable_testing()
  add_executable(vision_core_tests tests/vision_core_test.cpp src/c_api.cpp)
  sc_vision_enable_strict_warnings(vision_core_tests)
  target_compile_definitions(vision_core_tests PRIVATE SC_VISION_BUILD_SHARED=1)
  target_link_libraries(vision_core_tests PRIVATE vision_core_impl)
  add_test(
    NAME vision_core_tests
    COMMAND vision_core_tests
      ${CMAKE_CURRENT_SOURCE_DIR}/test/fixtures/checkerboard.pgm
  )
  add_executable(vision_c_abi_smoke tests/c_abi_smoke.c)
  sc_vision_enable_strict_warnings(vision_c_abi_smoke)
  target_link_libraries(vision_c_abi_smoke PRIVATE shooting_companion_vision)
  add_test(
    NAME vision_c_abi_smoke
    COMMAND vision_c_abi_smoke
      ${CMAKE_CURRENT_SOURCE_DIR}/test/fixtures/checkerboard.pgm
  )
  add_test(
    NAME vision_cli_unsupported
    COMMAND vision_cli analyze
      --image ${CMAKE_CURRENT_SOURCE_DIR}/test/fixtures/checkerboard.pgm
      --card-width-mm 550
      --card-height-mm 550
      --projectile-diameter-mm 5.6
      --minimum-long-side-px 8
  )
  set_tests_properties(
    vision_cli_unsupported
    PROPERTIES PASS_REGULAR_EXPRESSION "\\\"status\\\":\\\"unsupported\\\""
  )
endif()

install(TARGETS shooting_companion_vision vision_cli)
install(DIRECTORY include/ DESTINATION include)
