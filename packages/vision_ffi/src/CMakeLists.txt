cmake_minimum_required(VERSION 3.20)

project(shooting_companion_vision_ffi LANGUAGES C CXX)

set(SC_VISION_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(SC_VISION_ENABLE_OPENCV ON CACHE BOOL "" FORCE)

if(NOT DEFINED ENV{OPENCV_ANDROID_SDK})
  message(FATAL_ERROR
    "OPENCV_ANDROID_SDK must point to the pinned OpenCV 4.13.0 Android SDK")
endif()

set(
  OpenCV_DIR
  "$ENV{OPENCV_ANDROID_SDK}/sdk/native/jni"
  CACHE PATH "" FORCE
)

add_subdirectory(
  "${CMAKE_CURRENT_LIST_DIR}/../../../native/vision_core"
  "${CMAKE_CURRENT_BINARY_DIR}/vision_core"
)
