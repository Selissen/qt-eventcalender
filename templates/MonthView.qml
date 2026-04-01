// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import App

GridLayout {
    id: root

    required property PlanDatabase planDatabase
    required property date displayDate

    signal planEditRequested(int planId, var startDate, var endDate, int unitId, var routeIds)

    columns: 2

    DayOfWeekRow {
        id: dayOfWeekRow
        locale: grid.locale
        font.bold: false
        delegate: Label {
            text: model.shortName
            font: dayOfWeekRow.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Layout.column: 1
        Layout.fillWidth: true
    }

    WeekNumberColumn {
        month: grid.month
        year: grid.year
        locale: grid.locale
        font.bold: false

        Layout.fillHeight: true
    }

    MonthGrid {
        id: grid
        month: root.displayDate.getMonth()
        year: root.displayDate.getFullYear()
        spacing: 0

        readonly property int gridLineThickness: 1

        Layout.fillWidth: true
        Layout.fillHeight: true

        delegate: MonthGridDelegate {
            visibleMonth: grid.month
            planDatabase: root.planDatabase
            onPlanEditRequested: (id, sd, ed, uid, rids) => root.planEditRequested(id, sd, ed, uid, rids)
        }

        background: Item {
            x: grid.leftPadding
            y: grid.topPadding
            width: grid.availableWidth
            height: grid.availableHeight

            // Vertical lines
            Row {
                spacing: (parent.width - (grid.gridLineThickness * rowRepeater.model)) / rowRepeater.model

                Repeater {
                    id: rowRepeater
                    model: 7
                    delegate: Rectangle {
                        width: 1
                        height: grid.height
                        color: "#ccc"
                    }
                }
            }

            // Horizontal lines
            Column {
                spacing: (parent.height - (grid.gridLineThickness * columnRepeater.model)) / columnRepeater.model

                Repeater {
                    id: columnRepeater
                    model: 6
                    delegate: Rectangle {
                        width: grid.width
                        height: 1
                        color: "#ccc"
                    }
                }
            }
        }
    }
}
