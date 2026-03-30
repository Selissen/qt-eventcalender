// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import App

Item {
    id: root

    required property PlanDatabase planDatabase
    required property date referenceDate

    signal planEditRequested(int planId, string name, var startDate, var endDate, int unitId, var routeIds)

    readonly property date weekStart: CalendarUtils.weekStart(referenceDate, Qt.locale().firstDayOfWeek)

    // Left column: week number, matching WeekNumberColumn appearance
    Item {
        id: weekNumArea
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: weekNumLabel.implicitWidth + 16

        Label {
            id: weekNumLabel
            anchors.centerIn: parent
            text: CalendarUtils.isoWeekNumber(root.weekStart)
            font.bold: false
            opacity: 0.6
        }
    }

    Item {
        id: cellArea
        anchors.left: weekNumArea.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        // Grid lines drawn first (behind cells). Each line's x uses the same
        // formula as the cell x below, so alignment is structurally guaranteed.
        Repeater {
            model: 7
            Rectangle {
                required property int index
                x: index * cellArea.width / 7
                width: 1
                height: cellArea.height
                color: "#ccc"
            }
        }

        // Day cells positioned with the identical x formula as the lines above.
        Repeater {
            model: 7
            MonthGridDelegate {
                required property int index

                x: index * cellArea.width / 7
                width: cellArea.width / 7
                height: cellArea.height

                readonly property date cellDate: {
                    var d = new Date(root.weekStart)
                    d.setDate(d.getDate() + index)
                    return d
                }

                today: {
                    var now = new Date()
                    return cellDate.getFullYear() === now.getFullYear()
                        && cellDate.getMonth() === now.getMonth()
                        && cellDate.getDate() === now.getDate()
                }
                year: cellDate.getFullYear()
                month: cellDate.getMonth()
                day: cellDate.getDate()
                visibleMonth: month
                planDatabase: root.planDatabase
                onPlanEditRequested: (id, name, sd, ed, uid, rids) => root.planEditRequested(id, name, sd, ed, uid, rids)
            }
        }
    }
}
