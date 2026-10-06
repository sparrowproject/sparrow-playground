file(GLOB_RECURSE SparrowUICore_SOURCES
  "*.swift"
)
add_library(SparrowUICore ${SparrowUICore_SOURCES})

set_target_properties(SparrowUICore PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowUICore"
)
target_link_libraries(SparrowUICore PUBLIC
  OrderedCollections
  SparrowUIFoundation
)

if(WIN32)
target_link_libraries(SparrowUICore PRIVATE
  CWinRT
  UWP
  Win2D
  WinAppSDK
  WindowsFoundation
  WinUI
)
endif()
