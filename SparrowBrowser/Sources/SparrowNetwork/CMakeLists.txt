file(GLOB_RECURSE SparrowNetwork_SOURCES
  "*.swift"
)
add_library(SparrowNetwork ${SparrowNetwork_SOURCES})

set_target_properties(SparrowNetwork PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowNetwork"
)
target_link_libraries(SparrowNetwork PUBLIC
  SparrowToolbelt
)

if(WIN32)
target_link_libraries(SparrowNetwork PUBLIC
  CWinRT
  SparrowUIFoundation
  UWP
  WinAppSupport
  WindowsFoundation
)
endif()
