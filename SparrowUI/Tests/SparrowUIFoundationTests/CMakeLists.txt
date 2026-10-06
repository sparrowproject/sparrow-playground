add_executable(SparrowUIFoundationTests
  PositionalAnchorTests.swift
)

set_target_properties(SparrowUIFoundationTests PROPERTIES
  Swift_LANGUAGE_VERSION 6
)
target_compile_options(SparrowUIFoundationTests PRIVATE
  "$<$<COMPILE_LANGUAGE:Swift>:-parse-as-library>"
)

target_link_libraries(SparrowUIFoundationTests PRIVATE
  SparrowUIFoundation
)

add_test(NAME SparrowUIFoundationTests COMMAND SparrowUIFoundationTests)

if(APPLE)
  add_executable(ImageCodecTests ImageCodecTests.swift)
  set_target_properties(ImageCodecTests PROPERTIES Swift_LANGUAGE_VERSION 6)
  target_compile_options(ImageCodecTests PRIVATE
    "$<$<COMPILE_LANGUAGE:Swift>:-parse-as-library>"
  )
  target_link_libraries(ImageCodecTests PRIVATE SparrowUIFoundation)
  add_test(NAME ImageCodecTests COMMAND ImageCodecTests)
endif()
