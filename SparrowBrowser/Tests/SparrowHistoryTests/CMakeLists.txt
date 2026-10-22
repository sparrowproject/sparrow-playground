add_executable(SparrowHistoryTests TypedHistoryTests.swift)

set_target_properties(SparrowHistoryTests PROPERTIES Swift_LANGUAGE_VERSION 6)
target_compile_options(SparrowHistoryTests PRIVATE
  "$<$<COMPILE_LANGUAGE:Swift>:-parse-as-library>"
)
target_link_libraries(SparrowHistoryTests PRIVATE SparrowHistory)

add_test(NAME SparrowHistoryTests COMMAND SparrowHistoryTests)
