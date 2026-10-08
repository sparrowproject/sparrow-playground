file(GLOB_RECURSE SparrowDownloads_SOURCES
  "*.swift"
)
add_library(SparrowDownloads ${SparrowDownloads_SOURCES})

set_target_properties(SparrowDownloads PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowDownloads"
)
target_link_libraries(SparrowDownloads PUBLIC
  SparrowTabs
  SparrowToolbelt
  SparrowWeb
)

if(WIN32)
target_link_libraries(SparrowDownloads PRIVATE
  CWinRT
  WinAppSupport
  WindowsFoundation
)
endif()