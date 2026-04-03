# Copyright (C) 2021 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick Sql Test)

# ── Runtime PATH for tests ─────────────────────────────────────────────────────
# Qt6_DIR is e.g. X:/Qt/6.11.0/mingw_64/lib/cmake/Qt6 — go up 3 levels for bin.
get_filename_component(_qt_install_dir "${Qt6_DIR}/../../.." ABSOLUTE)
set(_qt_bin_dir "${_qt_install_dir}/bin")
get_filename_component(_mingw_bin_dir "${CMAKE_CXX_COMPILER}" DIRECTORY)
# CMake treats bare semicolons in variables as list separators, breaking
# multi-directory PATH values.  Escape every semicolon in the system PATH
# so the entire value survives as a single ENVIRONMENT string element.
string(REPLACE ";" "\\;" _sys_path_escaped "$ENV{PATH}")
set(_test_path "${_qt_bin_dir}\\;${_mingw_bin_dir}\\;${_sys_path_escaped}")

# ── Helper macro ──────────────────────────────────────────────────────────────
# Adds a test executable, links it, and registers it with CTest.
function(add_eventcalendar_test TARGET)
    qt_add_executable(${TARGET} ${ARGN})
    set_target_properties(${TARGET} PROPERTIES AUTOMOC ON)
    target_include_directories(${TARGET} PRIVATE .. ../models ../utils)
    target_link_libraries(${TARGET} PRIVATE Qt6::Core Qt6::Qml Qt6::Sql Qt6::Test)
    add_test(NAME ${TARGET} COMMAND ${TARGET})
    set_tests_properties(${TARGET} PROPERTIES ENVIRONMENT "PATH=${_test_path}")
endfunction()

# ── CalendarUtils ─────────────────────────────────────────────────────────────
add_eventcalendar_test(tst_calendarutils
    tst_calendarutils.cpp
    ../utils/calendarutils.cpp
    ../utils/calendarutils.h
)

# ── DateTimeUtils ─────────────────────────────────────────────────────────────
add_eventcalendar_test(tst_datetimeutils
    tst_datetimeutils.cpp
    ../utils/datetimeutils.cpp
    ../utils/datetimeutils.h
)

# ── SqlPlanDatabase ───────────────────────────────────────────────────────────
add_eventcalendar_test(tst_sqlplandatabase
    tst_sqlplandatabase.cpp
    ../models/sqlplandatabase.cpp
    ../models/sqlplandatabase.h
    ../models/plan.h
)

# ── WeekGrid ──────────────────────────────────────────────────────────────────
add_eventcalendar_test(tst_weekgrid
    tst_weekgrid.cpp
    ../utils/calendarutils.cpp
    ../utils/calendarutils.h
)

# ── PlanModel ─────────────────────────────────────────────────────────────────
add_eventcalendar_test(tst_planmodel
    tst_planmodel.cpp
    ../models/planmodel.cpp
    ../models/planmodel.h
    ../models/sqlplandatabase.cpp
    ../models/sqlplandatabase.h
    ../models/plan.h
)

# ── Flutter embedding tests (desktop-only, use stub Flutter API) ───────────────
if(NOT EMSCRIPTEN)
    # Shared stub sources compiled into every embedding test target.
    set(FLUTTER_STUB_SOURCES
        embedding/flutter_stub.cpp
        embedding/flutter_stub.h
    )
    # Stub headers shadow the real Flutter engine headers; must be listed
    # BEFORE any path that contains the real flutter_windows.h.
    set(FLUTTER_STUB_INCLUDES
        "${CMAKE_CURRENT_SOURCE_DIR}/embedding/stubs"   # stub flutter_windows.h etc.
        "${CMAKE_CURRENT_SOURCE_DIR}/embedding"          # flutter_stub.h
        "${CMAKE_CURRENT_SOURCE_DIR}/../embedding"       # production headers
        "${CMAKE_CURRENT_SOURCE_DIR}/../models"
        "${CMAKE_CURRENT_SOURCE_DIR}/../utils"
    )

    function(add_embedding_test TARGET)
        qt_add_executable(${TARGET} ${ARGN} ${FLUTTER_STUB_SOURCES})
        set_target_properties(${TARGET} PROPERTIES AUTOMOC ON)
        target_include_directories(${TARGET} PRIVATE ${FLUTTER_STUB_INCLUDES})
        target_link_libraries(${TARGET} PRIVATE
            Qt6::Core Qt6::Quick Qt6::Test)
        add_test(NAME ${TARGET} COMMAND ${TARGET})
        # QT_QPA_PLATFORM=offscreen avoids loading the windows platform plugin
        # (which is not needed for logic-level unit tests).
        set_tests_properties(${TARGET} PROPERTIES
            ENVIRONMENT "PATH=${_test_path};QT_QPA_PLATFORM=offscreen;QT_QPA_PLATFORM_PLUGIN_PATH=${_qt_install_dir}/plugins/platforms")
    endfunction()

    add_embedding_test(tst_componentbridge
        embedding/tst_componentbridge.cpp
        ../embedding/ComponentBridge.cpp
        ../embedding/ComponentBridge.h
    )

    add_embedding_test(tst_navigationbridge
        embedding/tst_navigationbridge.cpp
        ../embedding/NavigationBridge.cpp
        ../embedding/NavigationBridge.h
        ../embedding/FlutterContainer.cpp
        ../embedding/FlutterContainer.h
    )

    add_embedding_test(tst_fluttercontainer
        embedding/tst_fluttercontainer.cpp
        ../embedding/FlutterContainer.cpp
        ../embedding/FlutterContainer.h
    )
endif()
