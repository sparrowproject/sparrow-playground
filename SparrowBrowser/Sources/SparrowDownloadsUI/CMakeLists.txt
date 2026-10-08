file(GLOB_RECURSE SparrowDownloadsUI_SOURCES
  "*.swift"
)
add_library(SparrowDownloadsUI ${SparrowDownloadsUI_SOURCES})

set_target_properties(SparrowDownloadsUI PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowDownloadsUI"
)
target_link_libraries(SparrowDownloadsUI PUBLIC
  SparrowDownloads
  SparrowUI
  SparrowUICore
  SparrowUIFoundation
  Tagged
)
target_link_libraries(SparrowDownloadsUI PRIVATE
  SparrowDesignSystem
  SparrowStorageBase
)

if(WIN32)
target_link_libraries(SparrowDownloadsUI PRIVATE
  CWinRT
  WindowsFoundation
)
endif()