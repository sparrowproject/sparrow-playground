file(GLOB_RECURSE SparrowStorageBase_SOURCES
  "*.swift"
)
add_library(SparrowStorageBase ${SparrowStorageBase_SOURCES})

set_target_properties(SparrowStorageBase PROPERTIES
  Swift_LANGUAGE_VERSION 6
  OUTPUT_NAME "libSparrowStorageBase"
)
target_link_libraries(SparrowStorageBase PUBLIC
)
target_link_libraries(SparrowStorageBase PRIVATE
  SparrowToolbelt
)

if(WIN32)
target_link_libraries(SparrowStorageBase PRIVATE
  CWinRT
  WindowsFoundation
)
endif()
