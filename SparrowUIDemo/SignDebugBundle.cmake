if(NOT BUILD_CONFIG STREQUAL "Debug")
  return()
endif()

execute_process(
  COMMAND "${CODESIGN_EXECUTABLE}"
    --force
    --sign -
    --entitlements "${ENTITLEMENTS_FILE}"
    "${APP_BUNDLE}"
  COMMAND_ERROR_IS_FATAL ANY
)
