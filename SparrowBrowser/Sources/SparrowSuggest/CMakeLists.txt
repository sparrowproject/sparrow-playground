file(GLOB_RECURSE SparrowSuggest_SOURCES
  "*.swift"
)
add_library(SparrowSuggest ${SparrowSuggest_SOURCES})

set_target_properties(SparrowSuggest PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowSuggest"
)
target_link_libraries(SparrowSuggest PUBLIC
  SparrowNetwork
  SparrowToolbelt
)