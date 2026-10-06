file(GLOB_RECURSE SparrowCommands_SOURCES
  "*.swift"
)
add_library(SparrowCommands ${SparrowCommands_SOURCES})

set_target_properties(SparrowCommands PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowCommands"
)
target_link_libraries(SparrowCommands PRIVATE
  SparrowUI
  SparrowUICore
  SparrowUIFoundation
)

if(WIN32)
target_link_libraries(SparrowCommands PRIVATE
  CWinRT
  WindowsFoundation
)
endif()