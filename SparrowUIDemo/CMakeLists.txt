file(GLOB_RECURSE SparrowUIDemo_SOURCES
  "*.swift"
)
if(APPLE)
add_executable(SparrowUIDemo MACOSX_BUNDLE ${SparrowUIDemo_SOURCES})
elseif(WIN32)
add_executable(SparrowUIDemo ${SparrowUIDemo_SOURCES})
endif()

set_target_properties(SparrowUIDemo PROPERTIES
  Swift_LANGUAGE_VERSION 6
)

if(APPLE)
set_target_properties(SparrowUIDemo PROPERTIES
  # Bundle metadata
  MACOSX_BUNDLE_GUI_IDENTIFIER org.sparrowui.SparrowUIDemo
  MACOSX_BUNDLE_BUNDLE_NAME "SparrowUIDemo"
  MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0"
  MACOSX_BUNDLE_BUNDLE_VERSION "1"

  # Allow Xcode's debugging and profiling tools to attach to Debug builds.
  XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS
    "$<$<CONFIG:Debug>:${CMAKE_CURRENT_SOURCE_DIR}/SparrowUIDemoDebug.entitlements>"
)
add_custom_command(TARGET SparrowUIDemo POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_directory
          "${CMAKE_SOURCE_DIR}/SparrowUIDemo/Resources"
          "$<TARGET_BUNDLE_CONTENT_DIR:SparrowUIDemo>/Resources"
)

# Xcode applies CODE_SIGN_ENTITLEMENTS during its normal signing phase. Other
# generators only produce a linker-signed bundle, so sign Debug bundles after
# all resources have been copied into place.
if(NOT CMAKE_GENERATOR STREQUAL "Xcode")
  find_program(CODESIGN_EXECUTABLE codesign REQUIRED)
  add_custom_command(TARGET SparrowUIDemo POST_BUILD
    COMMAND ${CMAKE_COMMAND}
      "-DBUILD_CONFIG=$<CONFIG>"
      "-DCODESIGN_EXECUTABLE=${CODESIGN_EXECUTABLE}"
      "-DENTITLEMENTS_FILE=${CMAKE_CURRENT_SOURCE_DIR}/SparrowUIDemoDebug.entitlements"
      "-DAPP_BUNDLE=$<TARGET_BUNDLE_DIR:SparrowUIDemo>"
      -P "${CMAKE_CURRENT_SOURCE_DIR}/SignDebugBundle.cmake"
    VERBATIM
  )
endif()
endif()

target_link_libraries(SparrowUIDemo PRIVATE
  SparrowUI
  SparrowUICore
  SparrowUIFoundation
)

if(WIN32)
find_program(MAKEPRI_EXE makepri)
if(NOT MAKEPRI_EXE)
  message(FATAL_ERROR "makepri.exe not found; install the Windows SDK to build SparrowUIDemo resources")
endif()

target_link_libraries(SparrowUIDemo PRIVATE
  CWinAppSDK
  CWinRT
  WinAppSDK
  WinAppSupport
  WinUI
)
add_custom_command(TARGET SparrowUIDemo POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${CMAKE_SOURCE_DIR}/ThirdParty/Sources/CWinAppSDK/nuget/bin/Microsoft.WindowsAppRuntime.Bootstrap.dll"
    "$<TARGET_FILE_DIR:SparrowUIDemo>/SparrowUIDemo.resources/Microsoft.WindowsAppRuntime.Bootstrap.dll"
)
add_custom_command(TARGET SparrowUIDemo POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${CMAKE_SOURCE_DIR}/SparrowUIDemo/SparrowUIDemo.exe.manifest"
    "$<TARGET_FILE_DIR:SparrowUIDemo>/SparrowUIDemo.exe.manifest"
)
add_custom_command(TARGET SparrowUIDemo POST_BUILD
  COMMAND ${CMAKE_COMMAND}
    "-DOUTPUT_DIR=$<TARGET_FILE_DIR:SparrowUIDemo>"
    "-DRUNTIME_DLLS=$<TARGET_RUNTIME_DLLS:SparrowUIDemo>"
    -P "${CMAKE_SOURCE_DIR}/cmake/SymlinkRuntimeDlls.cmake"
)
add_custom_command(TARGET SparrowUIDemo POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_directory
    "${CMAKE_SOURCE_DIR}/SparrowUIDemo/Resources"
    "$<TARGET_FILE_DIR:SparrowUIDemo>/SparrowUIDemo.resources/"
)
add_custom_command(TARGET SparrowUIDemo POST_BUILD
  COMMAND "${MAKEPRI_EXE}" new
    /pr "${CMAKE_SOURCE_DIR}/SparrowUIDemo/Resources"
    /cf "${CMAKE_SOURCE_DIR}/SparrowUIDemo/priconfig.xml"
    /in SparrowUIDemo
    /of "$<TARGET_FILE_DIR:SparrowUIDemo>/resources.pri"
    /o
)
endif()
