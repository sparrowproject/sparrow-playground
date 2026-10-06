file(GLOB_RECURSE SparrowBrowser_SOURCES
  "*.swift"
)
set(SparrowBrowser_MANIFEST "${CMAKE_CURRENT_SOURCE_DIR}/SparrowBrowser.exe.manifest")
if(APPLE)
add_executable(SparrowBrowser MACOSX_BUNDLE ${SparrowBrowser_SOURCES})
elseif(WIN32)
add_executable(SparrowBrowser ${SparrowBrowser_SOURCES} "${SparrowBrowser_MANIFEST}")
endif()

set_target_properties(SparrowBrowser PROPERTIES
  Swift_LANGUAGE_VERSION 6
)
target_compile_options(SparrowBrowser PRIVATE
  "$<$<COMPILE_LANGUAGE:Swift>:-parse-as-library>"
)

if(APPLE)
set_target_properties(SparrowBrowser PROPERTIES
  # Bundle metadata
  MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist.in"
  MACOSX_BUNDLE_GUI_IDENTIFIER org.sparrowproject.SparrowBrowser
  MACOSX_BUNDLE_BUNDLE_NAME "Sparrow"
  MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0"
  MACOSX_BUNDLE_BUNDLE_VERSION "1"

  XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS
    "${CMAKE_CURRENT_SOURCE_DIR}/SparrowBrowser.entitlements"
)
if(EXISTS "${CMAKE_SOURCE_DIR}/SparrowBrowser/Sources/SparrowDesignSystem/Resources")
add_custom_command(TARGET SparrowBrowser POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_directory
          "${CMAKE_SOURCE_DIR}/SparrowBrowser/Sources/SparrowDesignSystem/Resources"
          "$<TARGET_BUNDLE_CONTENT_DIR:SparrowBrowser>/Resources"
)
endif()

# Xcode applies CODE_SIGN_ENTITLEMENTS during its normal signing phase. Other
# generators need to re-sign the completed bundle with its entitlements after
# resources have been copied into place.
if(NOT CMAKE_GENERATOR STREQUAL "Xcode")
  find_program(CODESIGN_EXECUTABLE codesign REQUIRED)
  add_custom_command(TARGET SparrowBrowser POST_BUILD
    COMMAND "${CODESIGN_EXECUTABLE}"
      --force
      --sign -
      --entitlements "${CMAKE_CURRENT_SOURCE_DIR}/SparrowBrowser.entitlements"
      "$<TARGET_BUNDLE_DIR:SparrowBrowser>"
    VERBATIM
  )
endif()
endif()

target_link_libraries(SparrowBrowser PRIVATE
  SparrowContent
  SparrowContentToolbar
  SparrowDesignSystem
  SparrowProfiles
  SparrowStorage
  SparrowTabs
  SparrowTabsUI
  SparrowToolbelt
  SparrowUI
  SparrowUICore
  SparrowUIFoundation
  SparrowWindowManager
)

if(WIN32)
find_program(MAKEPRI_EXE makepri)
if(NOT MAKEPRI_EXE)
  message(FATAL_ERROR "makepri.exe not found; install the Windows SDK to build SparrowBrowser resources")
endif()

set(SparrowBrowser_RESOURCES_DIR "${CMAKE_SOURCE_DIR}/SparrowBrowser/Resources")
set(SparrowBrowser_GENERATED_RESOURCES_DIR "${CMAKE_CURRENT_BINARY_DIR}/Resources")
if(NOT EXISTS "${SparrowBrowser_RESOURCES_DIR}")
  file(MAKE_DIRECTORY "${SparrowBrowser_GENERATED_RESOURCES_DIR}")
endif()

target_link_libraries(SparrowBrowser PRIVATE
  CWinAppSDK
  CWinRT
  WinAppSDK
  WinAppSupport
)
add_custom_command(TARGET SparrowBrowser POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${CMAKE_SOURCE_DIR}/ThirdParty/Sources/CWinAppSDK/nuget/bin/Microsoft.WindowsAppRuntime.Bootstrap.dll"
    "$<TARGET_FILE_DIR:SparrowBrowser>/SparrowBrowser.resources/Microsoft.WindowsAppRuntime.Bootstrap.dll"
)

if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(AMD64|x86_64)$")
  set(SparrowBrowser_WEBVIEW2_ARCH "x64")
  set(SparrowBrowser_NUGET_RUNTIME_ARCH "x64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(ARM64|aarch64)$")
  set(SparrowBrowser_WEBVIEW2_ARCH "arm64")
  set(SparrowBrowser_NUGET_RUNTIME_ARCH "arm64")
else()
  set(SparrowBrowser_WEBVIEW2_ARCH "x86")
  set(SparrowBrowser_NUGET_RUNTIME_ARCH "x86")
endif()

file(TO_CMAKE_PATH "$ENV{USERPROFILE}" SparrowBrowser_USERPROFILE)
file(GLOB SparrowBrowser_WEBVIEW2_LOADER_CANDIDATES
  "${SparrowBrowser_USERPROFILE}/.nuget/packages/microsoft.web.webview2/*/build/native/${SparrowBrowser_WEBVIEW2_ARCH}/WebView2Loader.dll"
  "${SparrowBrowser_USERPROFILE}/.nuget/packages/microsoft.web.webview2/*/runtimes/win-${SparrowBrowser_WEBVIEW2_ARCH}/native/WebView2Loader.dll"
)
file(GLOB SparrowBrowser_WEBVIEW2_CORE_CANDIDATES
  "${SparrowBrowser_USERPROFILE}/.nuget/packages/microsoft.web.webview2/*/runtimes/win-${SparrowBrowser_WEBVIEW2_ARCH}/native_uap/Microsoft.Web.WebView2.Core.dll"
)
file(GLOB SparrowBrowser_WIN2D_CANVAS_CANDIDATES
  "${SparrowBrowser_USERPROFILE}/.nuget/packages/microsoft.graphics.win2d/*/runtimes/win-${SparrowBrowser_NUGET_RUNTIME_ARCH}/native/Microsoft.Graphics.Canvas.dll"
)
if(SparrowBrowser_WEBVIEW2_LOADER_CANDIDATES)
  list(SORT SparrowBrowser_WEBVIEW2_LOADER_CANDIDATES COMPARE NATURAL)
  list(GET SparrowBrowser_WEBVIEW2_LOADER_CANDIDATES -1 SparrowBrowser_WEBVIEW2_LOADER)
  add_custom_command(TARGET SparrowBrowser POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${SparrowBrowser_WEBVIEW2_LOADER}"
      "$<TARGET_FILE_DIR:SparrowBrowser>/WebView2Loader.dll"
  )
else()
  message(WARNING "WebView2Loader.dll was not found in the local NuGet cache; WebView2 may fail to initialize at runtime.")
endif()
if(SparrowBrowser_WEBVIEW2_CORE_CANDIDATES)
  list(SORT SparrowBrowser_WEBVIEW2_CORE_CANDIDATES COMPARE NATURAL)
  list(GET SparrowBrowser_WEBVIEW2_CORE_CANDIDATES -1 SparrowBrowser_WEBVIEW2_CORE)
  add_custom_command(TARGET SparrowBrowser POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${SparrowBrowser_WEBVIEW2_CORE}"
      "$<TARGET_FILE_DIR:SparrowBrowser>/Microsoft.Web.WebView2.Core.dll"
  )
else()
  message(WARNING "Microsoft.Web.WebView2.Core.dll was not found in the local NuGet cache; WebView2 may fail to initialize at runtime.")
endif()
if(SparrowBrowser_WIN2D_CANVAS_CANDIDATES)
  list(SORT SparrowBrowser_WIN2D_CANVAS_CANDIDATES COMPARE NATURAL)
  list(GET SparrowBrowser_WIN2D_CANVAS_CANDIDATES -1 SparrowBrowser_WIN2D_CANVAS)
  add_custom_command(TARGET SparrowBrowser POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${SparrowBrowser_WIN2D_CANVAS}"
      "$<TARGET_FILE_DIR:SparrowBrowser>/Microsoft.Graphics.Canvas.dll"
  )
else()
  message(WARNING "Microsoft.Graphics.Canvas.dll was not found in the local NuGet cache; Win2D may fail to initialize at runtime.")
endif()

add_custom_command(TARGET SparrowBrowser POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${SparrowBrowser_MANIFEST}"
    "$<TARGET_FILE_DIR:SparrowBrowser>/SparrowBrowser.exe.manifest"
)
add_custom_command(TARGET SparrowBrowser POST_BUILD
  COMMAND ${CMAKE_COMMAND}
    "-DOUTPUT_DIR=$<TARGET_FILE_DIR:SparrowBrowser>"
    "-DRUNTIME_DLLS=$<TARGET_RUNTIME_DLLS:SparrowBrowser>"
    -P "${CMAKE_SOURCE_DIR}/cmake/SymlinkRuntimeDlls.cmake"
)
if(EXISTS "${SparrowBrowser_RESOURCES_DIR}")
add_custom_command(TARGET SparrowBrowser POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_directory
    "${SparrowBrowser_RESOURCES_DIR}"
    "$<TARGET_FILE_DIR:SparrowBrowser>/SparrowBrowser.resources/"
)
add_custom_command(TARGET SparrowBrowser POST_BUILD
  COMMAND "${MAKEPRI_EXE}" new
    /pr "${SparrowBrowser_RESOURCES_DIR}"
    /cf "${CMAKE_SOURCE_DIR}/SparrowBrowser/priconfig.xml"
    /in SparrowBrowser
    /of "$<TARGET_FILE_DIR:SparrowBrowser>/resources.pri"
    /o
)
else()
add_custom_command(TARGET SparrowBrowser POST_BUILD
  COMMAND "${MAKEPRI_EXE}" new
    /pr "${SparrowBrowser_GENERATED_RESOURCES_DIR}"
    /cf "${CMAKE_SOURCE_DIR}/SparrowBrowser/priconfig.xml"
    /in SparrowBrowser
    /of "$<TARGET_FILE_DIR:SparrowBrowser>/resources.pri"
    /o
)
endif()

if(EXISTS "${CMAKE_SOURCE_DIR}/SparrowBrowser/Sources/SparrowDesignSystem/Resources")
add_custom_command(TARGET SparrowBrowser POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_directory
          "${CMAKE_SOURCE_DIR}/SparrowBrowser/Sources/SparrowDesignSystem/Resources"
          "$<TARGET_FILE_DIR:SparrowBrowser>/SparrowBrowser.resources/"
)
endif()

endif()
