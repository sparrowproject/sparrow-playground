file(GLOB_RECURSE SparrowSpaces_SOURCES
  "*.swift"
)
add_library(SparrowSpaces ${SparrowSpaces_SOURCES})

set_target_properties(SparrowSpaces PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowSpaces"
)
target_link_libraries(SparrowSpaces PUBLIC
  SparrowStorageBase
  SparrowTabs
)
target_link_libraries(SparrowSpaces PRIVATE
  SparrowToolbelt
)

if(WIN32)
target_link_libraries(SparrowSpaces PRIVATE
  CWinRT
  WinAppSupport
  WindowsFoundation
)
endif()