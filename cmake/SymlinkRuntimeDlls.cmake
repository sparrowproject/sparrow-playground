if(NOT DEFINED OUTPUT_DIR)
  message(FATAL_ERROR "OUTPUT_DIR is required")
endif()

foreach(runtime_dll IN LISTS RUNTIME_DLLS)
  if(runtime_dll STREQUAL "")
    continue()
  endif()

  get_filename_component(runtime_dll_name "${runtime_dll}" NAME)
  set(link_path "${OUTPUT_DIR}/${runtime_dll_name}")

  file(REMOVE "${link_path}")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E create_symlink "${runtime_dll}" "${link_path}"
    RESULT_VARIABLE create_symlink_result
  )
  if(NOT create_symlink_result EQUAL 0)
    message(FATAL_ERROR "Failed to create symlink: ${link_path} -> ${runtime_dll}")
  endif()
endforeach()
