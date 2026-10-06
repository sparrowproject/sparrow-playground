file(GLOB_RECURSE SparrowWeb_SOURCES
  "*.swift"
)
add_library(SparrowWeb ${SparrowWeb_SOURCES})

set_target_properties(SparrowWeb PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowWeb"
)
target_link_libraries(SparrowWeb PUBLIC
  SparrowStorageBase
  SparrowToolbelt
  SparrowUI
  SparrowUICore
  SparrowUIFoundation
)

if(WIN32)
target_link_libraries(SparrowWeb PUBLIC
  CWinRT
  WebView2Core
  WindowsFoundation
  WinUI
)
endif()
