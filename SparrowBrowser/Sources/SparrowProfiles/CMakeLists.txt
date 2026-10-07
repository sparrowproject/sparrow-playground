file(GLOB_RECURSE SparrowProfiles_SOURCES
  "*.swift"
)
add_library(SparrowProfiles ${SparrowProfiles_SOURCES})

set_target_properties(SparrowProfiles PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowProfiles"
)
target_link_libraries(SparrowProfiles PUBLIC
  SparrowDownloads
  SparrowProfileModel
  SparrowStorage
  SparrowStorageBase
  SparrowSuggest
)
target_link_libraries(SparrowProfiles PRIVATE
  SparrowSpaces
  SparrowTabs
  SparrowToolbelt
  SparrowUI
  SparrowUICore
  SparrowUIFoundation
  SparrowWeb
  SparrowWindow
)