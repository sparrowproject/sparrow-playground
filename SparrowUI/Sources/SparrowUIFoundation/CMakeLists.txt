file(GLOB_RECURSE SparrowUIFoundation_SOURCES
  "*.swift"
)
add_library(SparrowUIFoundation ${SparrowUIFoundation_SOURCES})

set_target_properties(SparrowUIFoundation PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowUIFoundation"
)
target_link_libraries(SparrowUIFoundation PUBLIC
  OrderedCollections
)

if(WIN32)
target_link_libraries(SparrowUIFoundation PUBLIC
  WinAppSupport
)
target_link_libraries(SparrowUIFoundation PRIVATE
  CWinRT
  WinAppSDK
  WindowsFoundation
  WinUI
)
endif()
