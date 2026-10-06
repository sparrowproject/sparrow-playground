file(GLOB_RECURSE SparrowToolbelt_SOURCES
  "*.swift"
)
add_library(SparrowToolbelt ${SparrowToolbelt_SOURCES})

set_target_properties(SparrowToolbelt PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowToolbelt"
)
target_link_libraries(SparrowToolbelt PUBLIC
  OrderedCollections
)