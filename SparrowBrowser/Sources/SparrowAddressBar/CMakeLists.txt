file(GLOB_RECURSE SparrowAddressBar_SOURCES
  "*.swift"
)
add_library(SparrowAddressBar ${SparrowAddressBar_SOURCES})

set_target_properties(SparrowAddressBar PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowAddressBar"
)
target_link_libraries(SparrowAddressBar PUBLIC
  SparrowHistory
  SparrowSuggest
)
target_link_libraries(SparrowAddressBar PRIVATE
  SparrowDesignSystem
  SparrowTabs
  SparrowUI
  SparrowUICore
  SparrowUIFoundation
  SparrowWeb
)

if(WIN32)
target_link_libraries(SparrowAddressBar PRIVATE
  CWinRT
  WindowsFoundation
)
endif()
