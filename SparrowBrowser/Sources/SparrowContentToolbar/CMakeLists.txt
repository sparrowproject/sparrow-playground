file(GLOB_RECURSE SparrowContentToolbar_SOURCES
  "*.swift"
)
add_library(SparrowContentToolbar ${SparrowContentToolbar_SOURCES})

set_target_properties(SparrowContentToolbar PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowContentToolbar"
)
target_link_libraries(SparrowContentToolbar PUBLIC
  SparrowAddressBar
  SparrowCommands
  SparrowDownloadsUI
  SparrowNetwork
  SparrowSpaces
  SparrowSpacesUI
)
target_link_libraries(SparrowContentToolbar PRIVATE
  SparrowDesignSystem
  SparrowProfileModel
  SparrowTabs
  SparrowToolbelt
  SparrowUI
  SparrowUICore
  SparrowUIFoundation
)

if(WIN32)
target_link_libraries(SparrowContentToolbar PRIVATE
  CWinRT
  WindowsFoundation
)
endif()