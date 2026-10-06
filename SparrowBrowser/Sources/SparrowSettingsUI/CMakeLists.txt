file(GLOB_RECURSE SparrowSettingsUI_SOURCES
  "*.swift"
)
add_library(SparrowSettingsUI ${SparrowSettingsUI_SOURCES})

set_target_properties(SparrowSettingsUI PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowSettingsUI"
)
target_link_libraries(SparrowSettingsUI PRIVATE
)