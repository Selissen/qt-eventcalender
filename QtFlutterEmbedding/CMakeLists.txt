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

set_target_properties(QtFlutterEmbedding PROPERTIES AUTOMOC ON)

# PUBLIC include dirs: consumers can use bare #include "ComponentBridge.h" etc.
# The Flutter engine headers are also propagated so callers don't need to know
# where FLUTTER_ENGINE_DIR lives.
target_include_directories(QtFlutterEmbedding PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${FLUTTER_ENGINE_DIR}"
)

# PUBLIC link deps propagate to every target that links QtFlutterEmbedding::Core.
target_link_libraries(QtFlutterEmbedding PUBLIC
    Qt6::Core
    Qt6::Quick
    Qt6::Widgets
    flutter_windows
)
