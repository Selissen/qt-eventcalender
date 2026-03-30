# Copyright (C) 2022 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

cmake_minimum_required(VERSION 3.16)
project(eventcalendar LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Sql)

qt_add_executable(eventcalendar
    eventcalendar.cpp
    calendarutils.cpp calendarutils.h
    datetimeutils.cpp datetimeutils.h
    plan.h
    planmodel.cpp planmodel.h
    sqlplandatabase.cpp sqlplandatabase.h
)

set_target_properties(eventcalendar PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
)

target_link_libraries(eventcalendar PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Sql
)

qt_add_qml_module(eventcalendar
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
    NO_RESOURCE_TARGET_PATH
)

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
