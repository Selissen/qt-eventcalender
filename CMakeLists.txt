# Copyright (C) 2022 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

cmake_minimum_required(VERSION 3.16)
project(eventcalendar LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Sql Network)
# Widgets is needed by FlutterContainer (QWidget) when Flutter embedding is enabled.
# Found separately so the base build stays widget-free on WASM.
if(NOT EMSCRIPTEN)
    find_package(Qt6 OPTIONAL_COMPONENTS Widgets)
endif()

qt_add_library(eventcalendar_lib STATIC
    utils/calendarutils.cpp utils/calendarutils.h
    utils/datetimeutils.cpp utils/datetimeutils.h
    models/plan.h
    models/planmodel.cpp models/planmodel.h
    sync/plansyncmanager.cpp sync/plansyncmanager.h
    models/sqlplandatabase.cpp models/sqlplandatabase.h
    sync/syncbackend.h
)

# Subdirectory headers are found via bare #include "Foo.h" through these paths.
target_include_directories(eventcalendar_lib PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/models"
    "${CMAKE_CURRENT_SOURCE_DIR}/utils"
    "${CMAKE_CURRENT_SOURCE_DIR}/sync"
)

# Qt 6.8+ requires qmldir files in each QML subdirectory for the engine to
# discover types within those directories in static/WASM builds.
qt_policy(SET QTP0004 NEW)

qt_add_qml_module(eventcalendar_lib
    URI App
    QML_FILES
        qml/atoms/CalendarRange.qml
        qml/atoms/DatePickerField.qml
        qml/molecules/MonthGridDelegate.qml
        qml/molecules/WeekPlanCell.qml
        qml/organisms/EventSidebar.qml
        qml/organisms/PlanFooter.qml
        qml/organisms/UnitFilterSidebar.qml
        qml/templates/MonthView.qml
        qml/templates/WeekView.qml
        qml/pages/eventcalendar.qml
    RESOURCES
        qtquickcontrols2.conf
)

target_link_libraries(eventcalendar_lib PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Sql
    Qt6::Network
)

# Sync transport selection — one factory .cpp is compiled alongside grpcsyncbackend.cpp,
# together they define createSyncBackend(). Both platforms use the same generated proto/gRPC
# client code; only the channel type differs:
#
#   Desktop  → QGrpcHttp2Channel (native gRPC/HTTP-2, direct to server)
#   WASM     → QGrpcWebChannel   (gRPC-Web framing over fetch, requires Envoy proxy)
#   No gRPC  → NoopSyncBackend   (graceful fallback when addon is not installed)
#
# Find Protobuf and Grpc individually to bypass the Qt6 umbrella package, which can set
# Qt6_FOUND=FALSE via Qt Creator's maintenance_tool_provider even when the cmake config
# files are present on disk.
find_package(Qt6Protobuf QUIET)
find_package(Qt6Grpc QUIET)

if(Qt6Protobuf_FOUND AND Qt6Grpc_FOUND)
    qt_add_protobuf(calendar_proto
        PROTO_FILES proto/calendar.proto
        OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/proto_gen"
    )

    qt_add_grpc(calendar_grpc CLIENT
        PROTO_FILES proto/calendar.proto
        OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/proto_gen"
    )

    if(NOT EMSCRIPTEN)
        # The generated gRPC client DLL references symbols from the proto target;
        # it must link calendar_proto directly or the linker will find undefined refs.
        target_link_libraries(calendar_grpc PRIVATE calendar_proto)
    endif()

    target_sources(eventcalendar_lib PRIVATE sync/grpcsyncbackend.cpp sync/grpcsyncbackend.h)
    target_link_libraries(eventcalendar_lib PUBLIC
        Qt6::Protobuf Qt6::Grpc calendar_proto calendar_grpc)
    target_include_directories(eventcalendar_lib PUBLIC
        "${CMAKE_CURRENT_BINARY_DIR}/proto_gen")

    if(EMSCRIPTEN)
        target_sources(eventcalendar_lib PRIVATE
            sync/qgrpcwebchannel.cpp sync/qgrpcwebchannel.h
            sync/grpcchannel_web.cpp)
        message(STATUS "[EventCalendar] WASM — gRPC-Web sync backend selected (requires Envoy proxy)")
    else()
        target_sources(eventcalendar_lib PRIVATE sync/grpcchannel_http2.cpp)
        message(STATUS "[EventCalendar] Desktop — gRPC/HTTP-2 sync backend selected")
    endif()
else()
    target_sources(eventcalendar_lib PRIVATE sync/noopsyncbackend.cpp sync/noopsyncbackend.h)
    message(STATUS "[EventCalendar] Qt6::Protobuf/Grpc not found — no-op sync backend. "
                   "Install qt.qt6.6110.addons.qtgrpc via the Qt Online Installer to enable gRPC.")
endif()

# ── Flutter Windows Embedding (desktop only, opt-in) ─────────────────────────
#
# Enable with:  cmake -DEC_FLUTTER_EMBED_ENABLED=ON \
#                     -DFLUTTER_ENGINE_DIR="X:/Flutter/bin/cache/artifacts/engine/windows-x64" ..
#
# FLUTTER_ENGINE_DIR must contain flutter_windows.dll, flutter_windows.dll.lib,
# and the flutter/ header sub-directory produced by the Flutter SDK.
# After enabling, also build the Flutter app:
#   cd flutter/app && flutter build windows --release
# and copy the build output next to the Qt executable (cmake install does this).
#
if(NOT EMSCRIPTEN)
    option(EC_FLUTTER_EMBED_ENABLED
        "Embed Flutter inside the Qt shell via Win32 HWND hosting" ON)

    # Default to the committed prebuilt artifacts so no Flutter SDK is required.
    # Override with -DFLUTTER_ENGINE_DIR=... to use a local Flutter SDK instead.
    if(NOT DEFINED FLUTTER_ENGINE_DIR)
        set(FLUTTER_ENGINE_DIR
            "${CMAKE_SOURCE_DIR}/prebuilt/flutter_engine"
            CACHE PATH "Path to Flutter Windows engine artifacts (contains flutter_windows.dll)")
    endif()

    if(EC_FLUTTER_EMBED_ENABLED)
        if(NOT EXISTS "${FLUTTER_ENGINE_DIR}/flutter_windows.dll")
            message(FATAL_ERROR
                "[EventCalendar] FLUTTER_ENGINE_DIR must point to a directory "
                "containing flutter_windows.dll "
                "(e.g. X:/Flutter/bin/cache/artifacts/engine/windows-x64).")
        endif()

        add_library(flutter_windows SHARED IMPORTED)
        set_target_properties(flutter_windows PROPERTIES
            IMPORTED_LOCATION     "${FLUTTER_ENGINE_DIR}/flutter_windows.dll"
            IMPORTED_IMPLIB       "${FLUTTER_ENGINE_DIR}/flutter_windows.dll.lib"
            INTERFACE_INCLUDE_DIRECTORIES "${FLUTTER_ENGINE_DIR}"
        )

        add_subdirectory(QtFlutterEmbedding)

        message(STATUS "[EventCalendar] Flutter embedding enabled — engine: ${FLUTTER_ENGINE_DIR}")
    endif()
endif()

qt_add_executable(eventcalendar
    eventcalendar.cpp
)

if(NOT EMSCRIPTEN)
    set_target_properties(eventcalendar PROPERTIES
        WIN32_EXECUTABLE TRUE
        MACOSX_BUNDLE TRUE
    )
endif()

target_link_libraries(eventcalendar PRIVATE eventcalendar_lib eventcalendar_libplugin)

if(NOT EMSCRIPTEN AND EC_FLUTTER_EMBED_ENABLED)
    # App-specific embedding: only FlutterMapItem stays in embedding/.
    # All generic classes are in QtFlutterEmbedding::Core.
    target_sources(eventcalendar PRIVATE
        embedding/FlutterMapItem.cpp
        embedding/FlutterMapItem.h
    )
    # embedding/ for FlutterMapItem.h and flutter_constants.h.
    # QtFlutterEmbedding::Core PUBLIC includes propagate the rest.
    target_include_directories(eventcalendar PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/embedding"
    )
    target_link_libraries(eventcalendar PRIVATE QtFlutterEmbedding::Core QtFlutterEmbeddingplugin)
    target_compile_definitions(eventcalendar PRIVATE EC_FLUTTER_EMBED_ENABLED)

    # Copy flutter_windows.dll and the Flutter app build artifacts next to the
    # executable at install time.  Run `flutter build windows --release` inside
    # flutter/app first, then cmake --install.
    set(FLUTTER_APP_RELEASE
        "${CMAKE_CURRENT_SOURCE_DIR}/flutter/app/build/windows/x64/runner/Release")
    install(FILES "${FLUTTER_ENGINE_DIR}/flutter_windows.dll"
            DESTINATION ${CMAKE_INSTALL_BINDIR})
    if(EXISTS "${FLUTTER_APP_RELEASE}")
        install(DIRECTORY "${FLUTTER_APP_RELEASE}/"
                DESTINATION ${CMAKE_INSTALL_BINDIR}
                FILES_MATCHING
                    PATTERN "*.dll"
                    PATTERN "flutter_assets" EXCLUDE
                    PATTERN "app.so" EXCLUDE
        )
        install(DIRECTORY "${FLUTTER_APP_RELEASE}/flutter_assets"
                DESTINATION ${CMAKE_INSTALL_BINDIR}/flutter_assets)
        install(FILES
                    "${FLUTTER_APP_RELEASE}/icudtl.dat"
                    "${FLUTTER_APP_RELEASE}/app.so"   # AOT snapshot (release)
                DESTINATION ${CMAKE_INSTALL_BINDIR})
    endif()
endif()

qt_import_qml_plugins(eventcalendar)

if(NOT EMSCRIPTEN)
    enable_testing()
    add_subdirectory(tests)

    install(TARGETS eventcalendar
        BUNDLE  DESTINATION .
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    )

    qt_generate_deploy_qml_app_script(
        TARGET eventcalendar
        OUTPUT_SCRIPT deploy_script
        MACOS_BUNDLE_POST_BUILD
        NO_UNSUPPORTED_PLATFORM_ERROR
        DEPLOY_USER_QML_MODULES_ON_UNSUPPORTED_PLATFORM
    )
    install(SCRIPT ${deploy_script})
endif()
