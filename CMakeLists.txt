# Copyright (C) 2022 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

cmake_minimum_required(VERSION 3.16)
project(eventcalendar LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Sql Network)

qt_add_library(eventcalendar_lib STATIC
    calendarutils.cpp calendarutils.h
    datetimeutils.cpp datetimeutils.h
    plan.h
    planmodel.cpp planmodel.h
    plansyncmanager.cpp plansyncmanager.h
    sqlplandatabase.cpp sqlplandatabase.h
    syncbackend.h
)

# Qt 6.8+ requires qmldir files in each QML subdirectory for the engine to
# discover types within those directories in static/WASM builds.
qt_policy(SET QTP0004 NEW)

qt_add_qml_module(eventcalendar_lib
    URI App
    QML_FILES
        atoms/CalendarRange.qml
        atoms/DatePickerField.qml
        molecules/MonthGridDelegate.qml
        molecules/WeekPlanCell.qml
        organisms/EventSidebar.qml
        organisms/PlanFooter.qml
        organisms/UnitFilterSidebar.qml
        templates/MonthView.qml
        templates/WeekView.qml
        pages/eventcalendar.qml
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

    target_sources(eventcalendar_lib PRIVATE grpcsyncbackend.cpp grpcsyncbackend.h)
    target_link_libraries(eventcalendar_lib PUBLIC
        Qt6::Protobuf Qt6::Grpc calendar_proto calendar_grpc)
    target_include_directories(eventcalendar_lib PUBLIC
        "${CMAKE_CURRENT_BINARY_DIR}/proto_gen")

    if(EMSCRIPTEN)
        target_sources(eventcalendar_lib PRIVATE
            qgrpcwebchannel.cpp qgrpcwebchannel.h
            grpcchannel_web.cpp)
        message(STATUS "[EventCalendar] WASM — gRPC-Web sync backend selected (requires Envoy proxy)")
    else()
        target_sources(eventcalendar_lib PRIVATE grpcchannel_http2.cpp)
        message(STATUS "[EventCalendar] Desktop — gRPC/HTTP-2 sync backend selected")
    endif()
else()
    target_sources(eventcalendar_lib PRIVATE noopsyncbackend.cpp noopsyncbackend.h)
    message(STATUS "[EventCalendar] Qt6::Protobuf/Grpc not found — no-op sync backend. "
                   "Install qt.qt6.6110.addons.qtgrpc via the Qt Online Installer to enable gRPC.")
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
