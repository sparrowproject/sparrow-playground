add_executable(SparrowStorageTests BlobStoreTests.swift PersistentWebHistoryTests.swift CachingWebHistoryTests.swift)
set_target_properties(SparrowStorageTests PROPERTIES Swift_LANGUAGE_VERSION 6)
target_compile_options(SparrowStorageTests PRIVATE
  "$<$<COMPILE_LANGUAGE:Swift>:-parse-as-library>"
)
target_link_libraries(SparrowStorageTests PRIVATE
  SparrowStorage SparrowTabs SparrowToolbelt SparrowUI SparrowUICore SparrowUIFoundation SparrowWeb
)
add_test(NAME SparrowStorageTests COMMAND SparrowStorageTests)
