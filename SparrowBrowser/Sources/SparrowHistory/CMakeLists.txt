file(GLOB_RECURSE SparrowHistory_SOURCES
  "*.swift"
)
add_library(SparrowHistory ${SparrowHistory_SOURCES})

set_target_properties(SparrowHistory PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowHistory"
)
target_link_libraries(SparrowHistory PUBLIC
  SparrowToolbelt
)
