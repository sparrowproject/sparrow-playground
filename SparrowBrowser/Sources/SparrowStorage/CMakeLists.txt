file(GLOB_RECURSE SparrowStorage_SOURCES
  "*.swift"
)
add_library(SparrowStorage ${SparrowStorage_SOURCES})
if(BUILD_TESTING)
  target_compile_options(SparrowStorage PRIVATE "$<$<COMPILE_LANGUAGE:Swift>:-enable-testing>")
endif()

set_target_properties(SparrowStorage PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowStorage"
)
target_link_libraries(SparrowStorage PUBLIC
  CLevelDB
  SparrowStorageBase
)
target_link_libraries(SparrowStorage PRIVATE
  SparrowProfileModel
  SparrowSpaces
  SparrowTabs
  SparrowToolbelt
  SparrowUI
  SparrowUICore
  SparrowUIFoundation
  SparrowWeb
  SparrowWindowModel
)

if(WIN32)
target_link_libraries(SparrowStorage PRIVATE
  CWinRT
  WindowsFoundation
)
endif()
