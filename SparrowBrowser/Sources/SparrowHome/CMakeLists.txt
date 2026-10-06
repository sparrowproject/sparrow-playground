file(GLOB_RECURSE SparrowHome_SOURCES
  "*.swift"
)
add_library(SparrowHome ${SparrowHome_SOURCES})

set_target_properties(SparrowHome PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowHome"
)
target_link_libraries(SparrowHome PRIVATE
)