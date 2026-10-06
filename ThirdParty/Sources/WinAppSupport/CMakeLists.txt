file(GLOB_RECURSE WinAppSupport_SOURCES
  "*.swift"
)
add_library(WinAppSupport ${WinAppSupport_SOURCES})
set_target_properties(WinAppSupport PROPERTIES
  Swift_LANGUAGE_VERSION 5
  OUTPUT_NAME "libWinAppSupport"
)
target_link_libraries(WinAppSupport PUBLIC
  CWinAppSDK
)
target_link_libraries(WinAppSupport PRIVATE
  CWinRT
  WindowsFoundation
  WinAppSDK
  WinUI
)
