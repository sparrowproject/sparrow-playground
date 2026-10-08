if(NOT WIN32)
  return()
endif()

set(SPARROW_NUGET_PACKAGES_DIR
  "${CMAKE_BINARY_DIR}/_nuget/packages"
  CACHE PATH "Directory for CMake-restored NuGet packages"
)
set(SPARROW_WIN2D_NUGET_VERSION
  "1.4.0"
  CACHE STRING "Microsoft.Graphics.Win2D NuGet package version"
)
set(SPARROW_WEBVIEW2_NUGET_VERSION
  "1.0.3719.77"
  CACHE STRING "Microsoft.Web.WebView2 NuGet package version"
)
option(SPARROW_RESTORE_NUGET_PACKAGES "Restore Windows NuGet packages during CMake configure" ON)

function(sparrow_install_nuget_package package_id package_version)
  set(package_dir "${SPARROW_NUGET_PACKAGES_DIR}/${package_id}")
  if(EXISTS "${package_dir}")
    return()
  endif()

  if(NOT SPARROW_RESTORE_NUGET_PACKAGES)
    return()
  endif()

  find_program(NUGET_EXE nuget REQUIRED)
  file(MAKE_DIRECTORY "${SPARROW_NUGET_PACKAGES_DIR}")
  execute_process(
    COMMAND "${NUGET_EXE}" install "${package_id}"
      -Version "${package_version}"
      -OutputDirectory "${SPARROW_NUGET_PACKAGES_DIR}"
      -ExcludeVersion
      -NonInteractive
      -Verbosity quiet
    RESULT_VARIABLE install_result
    OUTPUT_VARIABLE install_output
    ERROR_VARIABLE install_error
  )
  if(NOT install_result EQUAL 0)
    message(FATAL_ERROR
      "Failed to restore ${package_id} ${package_version} with NuGet.\n"
      "${install_output}\n${install_error}"
    )
  endif()
endfunction()

function(sparrow_get_nuget_package_root out_var package_id package_version)
  string(TOLOWER "${package_id}" package_id_lower)
  file(TO_CMAKE_PATH "$ENV{USERPROFILE}" user_profile)
  set(package_roots
    "${SPARROW_NUGET_PACKAGES_DIR}/${package_id}"
    "${SPARROW_NUGET_PACKAGES_DIR}/${package_id}.${package_version}"
    "${SPARROW_NUGET_PACKAGES_DIR}/${package_id_lower}"
    "${SPARROW_NUGET_PACKAGES_DIR}/${package_id_lower}.${package_version}"
    "${user_profile}/.nuget/packages/${package_id_lower}/${package_version}"
  )

  foreach(package_root IN LISTS package_roots)
    if(EXISTS "${package_root}")
      set("${out_var}" "${package_root}" PARENT_SCOPE)
      return()
    endif()
  endforeach()

  set("${out_var}" "" PARENT_SCOPE)
endfunction()

function(sparrow_glob_latest_nuget_file out_var)
  file(GLOB candidates ${ARGN})
  if(candidates)
    list(SORT candidates COMPARE NATURAL)
    list(GET candidates -1 latest_candidate)
    set("${out_var}" "${latest_candidate}" PARENT_SCOPE)
  else()
    set("${out_var}" "" PARENT_SCOPE)
  endif()
endfunction()

function(sparrow_restore_windows_nuget_packages)
  sparrow_install_nuget_package("Microsoft.Graphics.Win2D" "${SPARROW_WIN2D_NUGET_VERSION}")
  sparrow_install_nuget_package("Microsoft.Web.WebView2" "${SPARROW_WEBVIEW2_NUGET_VERSION}")

  sparrow_get_nuget_package_root(
    win2d_package_root
    "Microsoft.Graphics.Win2D"
    "${SPARROW_WIN2D_NUGET_VERSION}"
  )
  sparrow_get_nuget_package_root(
    webview2_package_root
    "Microsoft.Web.WebView2"
    "${SPARROW_WEBVIEW2_NUGET_VERSION}"
  )

  if(NOT win2d_package_root)
    message(FATAL_ERROR "Microsoft.Graphics.Win2D ${SPARROW_WIN2D_NUGET_VERSION} was not found after NuGet restore.")
  endif()
  if(NOT webview2_package_root)
    message(FATAL_ERROR "Microsoft.Web.WebView2 ${SPARROW_WEBVIEW2_NUGET_VERSION} was not found after NuGet restore.")
  endif()

  set(SPARROW_WIN2D_PACKAGE_ROOT "${win2d_package_root}" CACHE INTERNAL "Restored Win2D package root")
  set(SPARROW_WEBVIEW2_PACKAGE_ROOT "${webview2_package_root}" CACHE INTERNAL "Restored WebView2 package root")
endfunction()
