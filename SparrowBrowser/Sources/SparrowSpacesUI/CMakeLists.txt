file(GLOB_RECURSE SparrowSpacesUI_SOURCES
  "*.swift"
)
add_library(SparrowSpacesUI ${SparrowSpacesUI_SOURCES})

set_target_properties(SparrowSpacesUI PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowSpacesUI"
)
target_link_libraries(SparrowSpacesUI PUBLIC
  SparrowSpaces
  SparrowTabs
  SparrowToolbelt
  SparrowUI
  SparrowUICore
  SparrowUIFoundation
  SparrowWindowModel
)
target_link_libraries(SparrowSpacesUI PRIVATE
  SparrowDesignSystem
  SparrowProfileModel
)

if(WIN32)
target_link_libraries(SparrowSpacesUI PRIVATE
  CWinRT
  WindowsFoundation
)
endif()