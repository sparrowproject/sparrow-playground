file(GLOB_RECURSE SparrowDesignSystem_SOURCES
  "*.swift"
)
add_library(SparrowDesignSystem ${SparrowDesignSystem_SOURCES})

set_target_properties(SparrowDesignSystem PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowDesignSystem"
)
target_link_libraries(SparrowDesignSystem PRIVATE
  SparrowUI
  SparrowUICore
  SparrowUIFoundation
)

if(WIN32)
target_link_libraries(SparrowDesignSystem PRIVATE
  CWinRT
  WindowsFoundation
)
endif()