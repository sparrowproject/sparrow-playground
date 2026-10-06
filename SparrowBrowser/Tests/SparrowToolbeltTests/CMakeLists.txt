add_executable(SparrowToolbeltTests
  URLUtilsTests.swift
  MRUCacheTests.swift
)

set_target_properties(SparrowToolbeltTests PROPERTIES
  Swift_LANGUAGE_VERSION 6
)
target_compile_options(SparrowToolbeltTests PRIVATE
  "$<$<COMPILE_LANGUAGE:Swift>:-parse-as-library>"
)

target_link_libraries(SparrowToolbeltTests PRIVATE
  SparrowToolbelt
)

add_test(NAME SparrowToolbeltTests COMMAND SparrowToolbeltTests)
