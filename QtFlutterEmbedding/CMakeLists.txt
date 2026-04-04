# QtFlutterEmbedding — reusable Qt + Flutter Windows embedding library.
#
# Provides bidirectional bridges, engine lifecycle management, and Qt item
# wrappers for embedding Flutter components inside a Qt/QML application.
#
# Desktop-only: depends on the Flutter Windows C API (Win32 HWND hosting).
# This file is included by the parent project after the flutter_windows
# imported target and FLUTTER_ENGINE_DIR cache variable are defined.

if(EMSCRIPTEN)
    return()
endif()

set(QtFlutterEmbedding_VERSION "0.1.0")

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

add_library(QtFlutterEmbedding STATIC
    ComponentBridge.cpp         ComponentBridge.h
    ComponentEngineFactory.cpp  ComponentEngineFactory.h
    FlutterComponentView.cpp    FlutterComponentView.h
    FlutterContainer.cpp        FlutterContainer.h
    FlutterFocusFilter.cpp      FlutterFocusFilter.h
    FlutterView.cpp             FlutterView.h
    FlutterWidgetProxy.cpp      FlutterWidgetProxy.h
    NavigationBridge.cpp        NavigationBridge.h
)

add_library(QtFlutterEmbedding::Core ALIAS QtFlutterEmbedding)

set_target_properties(QtFlutterEmbedding PROPERTIES
    AUTOMOC ON
    VERSION ${QtFlutterEmbedding_VERSION}
)

# QML module: FlutterComponentView, FlutterView (and FlutterMapItem for
# app-specific use) declare QML_ELEMENT in their headers.  This call wires
# the MOC-generated registration code into a static plugin
# (QtFlutterEmbeddingplugin) so consumers can write:
#
#   import QtFlutterEmbedding
#   FlutterComponentView { entrypoint: "..."; channel: "..." }
#
# NOTE: The shared eventcalendar.qml also registers these types under the
# "App" URI via qmlRegisterType() (desktop only) so the existing QML file
# doesn't need a platform-conditional import statement.  New desktop-only
# QML files should use `import QtFlutterEmbedding` instead.
qt_add_qml_module(QtFlutterEmbedding
    URI     QtFlutterEmbedding
    VERSION 1.0
    # No QML_FILES — pure C++ type-registration module
)

# BUILD_INTERFACE: bare includes work during this build (source dir + engine dir).
# INSTALL_INTERFACE: installed headers live under include/QtFlutterEmbedding/.
#   Flutter engine headers are provided by the re-created flutter_windows target
#   in the installed config file, so no explicit path is needed here.
target_include_directories(QtFlutterEmbedding PUBLIC
    "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>"
    "$<BUILD_INTERFACE:${FLUTTER_ENGINE_DIR}>"
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/QtFlutterEmbedding>"
)

# PUBLIC link deps propagate to every target that links QtFlutterEmbedding::Core.
target_link_libraries(QtFlutterEmbedding PUBLIC
    Qt6::Core
    Qt6::Quick
    Qt6::Widgets
    flutter_windows
)

# ── Install rules ─────────────────────────────────────────────────────────────

# All four targets — including the two qt_add_qml_module-generated internal
# helpers — must appear in the same EXPORT set.  CMake's install(EXPORT)
# validation requires every transitive dependency of an exported target to
# itself be in an export set; installing without EXPORT is not sufficient.
install(TARGETS
        QtFlutterEmbedding
        QtFlutterEmbeddingplugin
        QtFlutterEmbedding_resources_1
        QtFlutterEmbeddingplugin_init
    EXPORT  QtFlutterEmbeddingTargets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# Install all public headers under include/QtFlutterEmbedding/
install(FILES
    ComponentBridge.h
    ComponentEngineFactory.h
    FlutterComponentView.h
    FlutterContainer.h
    FlutterFocusFilter.h
    FlutterView.h
    FlutterWidgetProxy.h
    NavigationBridge.h
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/QtFlutterEmbedding
)

# Export the targets file (QtFlutterEmbeddingTargets.cmake)
set(_cmake_install_dir "${CMAKE_INSTALL_LIBDIR}/cmake/QtFlutterEmbedding")

install(EXPORT QtFlutterEmbeddingTargets
    FILE        QtFlutterEmbeddingTargets.cmake
    NAMESPACE   QtFlutterEmbedding::
    DESTINATION ${_cmake_install_dir}
)

# Generate and install the version file
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/QtFlutterEmbeddingConfigVersion.cmake"
    VERSION       ${QtFlutterEmbedding_VERSION}
    COMPATIBILITY SameMajorVersion
)
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/QtFlutterEmbeddingConfigVersion.cmake"
    DESTINATION ${_cmake_install_dir}
)

# Configure and install the main config file from the .in template
configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/QtFlutterEmbeddingConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/QtFlutterEmbeddingConfig.cmake"
    INSTALL_DESTINATION ${_cmake_install_dir}
)
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/QtFlutterEmbeddingConfig.cmake"
    DESTINATION ${_cmake_install_dir}
)
