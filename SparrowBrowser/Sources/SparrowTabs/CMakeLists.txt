file(GLOB_RECURSE SparrowTabs_SOURCES
  "*.swift"
)
add_library(SparrowTabs ${SparrowTabs_SOURCES})

set_target_properties(SparrowTabs PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowTabs"
)
target_link_libraries(SparrowTabs PUBLIC
  OrderedCollections
  SparrowToolbelt
  SparrowUI
  SparrowUICore
  SparrowUIFoundation
  SparrowWeb
  Tagged
)

if(WIN32)
target_link_libraries(SparrowTabs PRIVATE
  CWinRT
  WindowsFoundation
)
endif()