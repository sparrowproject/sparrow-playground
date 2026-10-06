file(GLOB_RECURSE SparrowWindowModel_SOURCES
  "*.swift"
)
add_library(SparrowWindowModel ${SparrowWindowModel_SOURCES})

set_target_properties(SparrowWindowModel PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowWindowModel"
)
target_link_libraries(SparrowWindowModel PUBLIC
  SparrowProfileModel
  SparrowStorageBase
  SparrowTabs
)
target_link_libraries(SparrowWindowModel PRIVATE
)

if(WIN32)
target_link_libraries(SparrowWindowModel PRIVATE
  CWinRT
  WinAppSupport
  WindowsFoundation
)
endif()