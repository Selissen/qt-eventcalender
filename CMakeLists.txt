# Copyright (C) 2022 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

cmake_minimum_required(VERSION 3.16)
project(eventcalendar LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Sql)

qt_add_library(eventcalendar_lib STATIC
    calendarutils.cpp calendarutils.h
    datetimeutils.cpp datetimeutils.h
    plan.h
    planmodel.cpp planmodel.h
    sqlplandatabase.cpp sqlplandatabase.h
)

# Qt 6.8+ requires qmldir files in each QML subdirectory for the engine to
# discover types within those directories in static/WASM builds.
qt_policy(SET QTP0004 NEW)

qt_add_qml_module(eventcalendar_lib
    URI App
    QML_FILES
        atoms/DatePickerField.qml
        molecules/MonthGridDelegate.qml
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
)

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
