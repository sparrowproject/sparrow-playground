file(GLOB_RECURSE SparrowWindow_SOURCES
  "*.swift"
)
add_library(SparrowWindow ${SparrowWindow_SOURCES})

set_target_properties(SparrowWindow PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowWindow"
)
target_link_libraries(SparrowWindow PUBLIC
  SparrowAddressBar
  SparrowCommands
  SparrowContent
  SparrowContentToolbar
  SparrowDesignSystem
  SparrowProfileModel
  SparrowSpacesUI
  SparrowStorage
  SparrowTabsUI
  SparrowWeb
  SparrowWindowModel
)
target_link_libraries(SparrowWindow PRIVATE
  SparrowTabs
  SparrowToolbelt
  SparrowUI
  SparrowUICore
  SparrowUIFoundation
)

if(WIN32)
target_link_libraries(SparrowWindow PRIVATE
  CWinRT
  WindowsFoundation
)
endif()