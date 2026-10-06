file(GLOB_RECURSE SparrowWindowManager_SOURCES
  "*.swift"
)
add_library(SparrowWindowManager ${SparrowWindowManager_SOURCES})

set_target_properties(SparrowWindowManager PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowWindowManager"
)
target_link_libraries(SparrowWindowManager PUBLIC
  SparrowNetwork
  SparrowProfiles
  SparrowSpaces
  SparrowSpacesUI
  SparrowWindow
  SparrowWindowModel
)
target_link_libraries(SparrowWindowManager PRIVATE
  SparrowTabs
  SparrowUI
  SparrowUICore
  SparrowUIFoundation
)

if(WIN32)
target_link_libraries(SparrowWindowManager PRIVATE
  CWinRT
  WindowsFoundation
)
endif()