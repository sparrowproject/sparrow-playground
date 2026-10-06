file(GLOB_RECURSE SparrowProfileModel_SOURCES
  "*.swift"
)
add_library(SparrowProfileModel ${SparrowProfileModel_SOURCES})

set_target_properties(SparrowProfileModel PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowProfileModel"
)
target_link_libraries(SparrowProfileModel PUBLIC
  OrderedCollections
  Tagged
)
target_link_libraries(SparrowProfileModel PRIVATE
  SparrowToolbelt
)