file(GLOB_RECURSE SparrowTabsUI_SOURCES
  "*.swift"
)
add_library(SparrowTabsUI ${SparrowTabsUI_SOURCES})

set_target_properties(SparrowTabsUI PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowTabsUI"
)
target_link_libraries(SparrowTabsUI PUBLIC
  SparrowStorageBase
)
target_link_libraries(SparrowTabsUI PRIVATE
  SparrowCommands
  SparrowDesignSystem
  SparrowTabs
  SparrowToolbelt
  SparrowUI
  SparrowUICore
  SparrowUIFoundation
)

if(WIN32)
target_link_libraries(SparrowTabsUI PRIVATE
  CWinRT
  WindowsFoundation
)
endif()