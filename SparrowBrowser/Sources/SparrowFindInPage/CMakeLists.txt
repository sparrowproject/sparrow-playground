file(GLOB_RECURSE SparrowFindInPage_SOURCES
  "*.swift"
)
add_library(SparrowFindInPage ${SparrowFindInPage_SOURCES})

set_target_properties(SparrowFindInPage PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowFindInPage"
)
target_link_libraries(SparrowFindInPage PUBLIC
  SparrowTabs
  SparrowToolbelt
  SparrowUI
  SparrowUICore
  SparrowUIFoundation
)
target_link_libraries(SparrowFindInPage PRIVATE
  SparrowStorageBase
)