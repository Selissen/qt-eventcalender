# Copyright (C) 2021 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

find_package(Qt6 REQUIRED COMPONENTS Core Qml Sql Test)

# ── Helper macro ──────────────────────────────────────────────────────────────
# Adds a test executable, links it, and registers it with CTest.
function(add_eventcalendar_test TARGET)
    qt_add_executable(${TARGET} ${ARGN})
    set_target_properties(${TARGET} PROPERTIES AUTOMOC ON)
    target_include_directories(${TARGET} PRIVATE ..)
    target_link_libraries(${TARGET} PRIVATE Qt6::Core Qt6::Qml Qt6::Sql Qt6::Test)
    add_test(NAME ${TARGET} COMMAND ${TARGET})
endfunction()

# ── CalendarUtils ─────────────────────────────────────────────────────────────
add_eventcalendar_test(tst_calendarutils
    tst_calendarutils.cpp
    ../calendarutils.cpp
    ../calendarutils.h
)

# ── DateTimeUtils ─────────────────────────────────────────────────────────────
add_eventcalendar_test(tst_datetimeutils
    tst_datetimeutils.cpp
    ../datetimeutils.cpp
    ../datetimeutils.h
)

# ── SqlPlanDatabase ───────────────────────────────────────────────────────────
add_eventcalendar_test(tst_sqlplandatabase
    tst_sqlplandatabase.cpp
    ../sqlplandatabase.cpp
    ../sqlplandatabase.h
    ../plan.h
)

# ── PlanModel ─────────────────────────────────────────────────────────────────
add_eventcalendar_test(tst_planmodel
    tst_planmodel.cpp
    ../planmodel.cpp
    ../planmodel.h
    ../sqlplandatabase.cpp
    ../sqlplandatabase.h
    ../plan.h
)
