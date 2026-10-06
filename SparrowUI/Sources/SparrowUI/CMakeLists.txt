file(GLOB_RECURSE SparrowUI_SOURCES
  "*.swift"
)
add_library(SparrowUI ${SparrowUI_SOURCES})

set_target_properties(SparrowUI PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowUI"
)
target_link_libraries(SparrowUI PUBLIC
  SparrowUICore
  SparrowUIFoundation
)

if(WIN32)
target_link_libraries(SparrowUI PRIVATE
  CWinRT
  WinUI
)
endif()
