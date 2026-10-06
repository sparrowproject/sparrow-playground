include(FetchContent)

set(LEVELDB_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(LEVELDB_BUILD_BENCHMARKS OFF CACHE BOOL "" FORCE)
set(LEVELDB_INSTALL OFF CACHE BOOL "" FORCE)
FetchContent_Declare(leveldb
  GIT_REPOSITORY https://github.com/google/leveldb.git
  GIT_TAG 1.23
  GIT_SHALLOW TRUE
  GIT_SUBMODULES ""
)
FetchContent_MakeAvailable(leveldb)
if(WIN32)
  target_compile_definitions(leveldb PRIVATE
    _CRT_NONSTDC_NO_WARNINGS
    _CRT_SECURE_NO_WARNINGS
  )
endif()
# LevelDB's C++ warning flags must not propagate to Swift consumers.
set_property(TARGET leveldb PROPERTY INTERFACE_COMPILE_OPTIONS "")
add_library(CLevelDB INTERFACE)
target_include_directories(CLevelDB INTERFACE Sources/CLevelDB/include)
target_link_libraries(CLevelDB INTERFACE leveldb)

FetchContent_Declare(swift_tagged
  GIT_REPOSITORY https://github.com/pointfreeco/swift-tagged.git
  GIT_TAG 0.10.0
  GIT_SHALLOW TRUE
)

FetchContent_Declare(swift_collections
  GIT_REPOSITORY https://github.com/apple/swift-collections.git
  GIT_TAG 1.5.1
  GIT_SHALLOW TRUE
)

FetchContent_MakeAvailable(swift_tagged)
FetchContent_MakeAvailable(swift_collections)

file(GLOB_RECURSE Tagged_SOURCES CONFIGURE_DEPENDS
  "${swift_tagged_SOURCE_DIR}/Sources/Tagged/*.swift"
)
add_library(Tagged ${Tagged_SOURCES})
set_target_properties(Tagged PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libTagged"
)

if(WIN32)
add_library(CWinAppSDK STATIC
  Sources/CWinAppSDK/delayloadhelper.c
  Sources/CWinAppSDK/LegacyDispatcherQueueSetup.cpp
  Sources/CWinAppSDK/PackageGraphDiagnostics.cpp
)
target_sources(CWinAppSDK PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}/Sources/CWinAppSDK/include/module.modulemap
)
target_include_directories(CWinAppSDK PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}/Sources/CWinAppSDK/include
)
target_link_libraries(CWinAppSDK PUBLIC CoreMessaging)

add_library(CWinRT STATIC
  Sources/CWinRT/shim.c
)
target_sources(CWinRT PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}/Sources/CWinRT/include/module.modulemap
)
target_include_directories(CWinRT PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}/Sources/CWinRT/include
)

file(GLOB_RECURSE WindowsFoundation_SOURCES
  "Sources/WindowsFoundation/*.swift"
)
add_library(WindowsFoundation ${WindowsFoundation_SOURCES})
set_target_properties(WindowsFoundation PROPERTIES
  Swift_LANGUAGE_VERSION 5
  OUTPUT_NAME "libWindowsFoundation"
)
target_link_libraries(WindowsFoundation PRIVATE
  CWinRT
)

file(GLOB_RECURSE UWP_SOURCES
  "Sources/UWP/*.swift"
)
add_library(UWP ${UWP_SOURCES})
set_target_properties(UWP PROPERTIES
  Swift_LANGUAGE_VERSION 5
  OUTPUT_NAME "libUWP"
)
target_link_libraries(UWP PRIVATE
  CWinRT
  WindowsFoundation
)

file(GLOB_RECURSE WinAppSDK_SOURCES
  "Sources/WinAppSDK/*.swift"
)
add_library(WinAppSDK ${WinAppSDK_SOURCES})
set_target_properties(WinAppSDK PROPERTIES
  Swift_LANGUAGE_VERSION 5
  OUTPUT_NAME "libWinAppSDK"
)
target_link_libraries(WinAppSDK PRIVATE
  CWinRT
  UWP
  WindowsFoundation
)

file(GLOB_RECURSE Win2D_SOURCES
  "Sources/Win2D/*.swift"
)
add_library(Win2D ${Win2D_SOURCES})
set_target_properties(Win2D PROPERTIES
  Swift_LANGUAGE_VERSION 5
  OUTPUT_NAME "libWin2D"
)
target_link_libraries(Win2D PRIVATE
  CWinRT
  UWP
  WindowsFoundation
  WinAppSDK
)

file(GLOB_RECURSE WebView2Core_SOURCES
  "Sources/WebView2Core/*.swift"
)
add_library(WebView2Core ${WebView2Core_SOURCES})
set_target_properties(WebView2Core PROPERTIES
  Swift_LANGUAGE_VERSION 5
  OUTPUT_NAME "libWebView2Core"
)
target_link_libraries(WebView2Core PRIVATE
  CWinRT
  UWP
  WindowsFoundation
)

file(GLOB_RECURSE WinUI_SOURCES
  "Sources/WinUI/*.swift"
)
add_library(WinUI ${WinUI_SOURCES})
set_target_properties(WinUI PROPERTIES
  Swift_LANGUAGE_VERSION 5
  OUTPUT_NAME "libWinUI"
)
target_link_libraries(WinUI PRIVATE
  CWinRT
  UWP
  WebView2Core
  WindowsFoundation
  WinAppSDK
)

add_subdirectory(Sources/WinAppSupport)
endif()
