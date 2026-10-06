cmake_minimum_required(VERSION 3.29)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(BUILD_SHARED_LIBS ON)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL")

project(SwiftPlayground LANGUAGES Swift C CXX)

if(WIN32)
  include(cmake/SparrowNuGet.cmake)
  sparrow_restore_windows_nuget_packages()
endif()

add_compile_options(
  "$<$<AND:$<COMPILE_LANGUAGE:Swift>,$<CONFIG:Debug>>:-DDEBUG>"
)

include(CTest)

add_subdirectory(SparrowBrowser)
add_subdirectory(SparrowUI)
add_subdirectory(SparrowUIDemo)
add_subdirectory(ThirdParty)
