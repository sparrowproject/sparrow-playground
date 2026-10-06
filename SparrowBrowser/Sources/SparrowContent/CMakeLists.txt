file(GLOB_RECURSE SparrowContent_SOURCES
  "*.swift"
)
add_library(SparrowContent ${SparrowContent_SOURCES})

set_target_properties(SparrowContent PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowContent"
)
target_link_libraries(SparrowContent PUBLIC
  SparrowContentToolbar
  SparrowSuggest
  SparrowWeb
)
target_link_libraries(SparrowContent PRIVATE
  SparrowDesignSystem
  SparrowTabs
  SparrowToolbelt
  SparrowUI
  SparrowUICore
  SparrowUIFoundation
  SparrowWindowModel
)

if(WIN32)
target_link_libraries(SparrowContent PRIVATE
  CWinRT
  WindowsFoundation
)
endif()