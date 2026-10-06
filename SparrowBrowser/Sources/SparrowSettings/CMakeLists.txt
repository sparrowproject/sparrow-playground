file(GLOB_RECURSE SparrowSettings_SOURCES
  "*.swift"
)
add_library(SparrowSettings ${SparrowSettings_SOURCES})

set_target_properties(SparrowSettings PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowSettings"
)
target_link_libraries(SparrowSettings PRIVATE
)