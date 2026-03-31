// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import App

// Week view with a unified row grid shared across all 7 days.
// Plans are grouped by unit; each unit occupies a consecutive band of rows.
// The number of rows per unit = max plans for that unit on any single day
// of the displayed week, so every day column uses the same row layout.

Item {
    id: root

    required property PlanDatabase planDatabase
    required property date referenceDate

    signal planEditRequested(int planId, string name, var startDate, var endDate, int unitId, var routeIds)

    readonly property date weekStart: CalendarUtils.weekStart(referenceDate, Qt.locale().firstDayOfWeek)

    // ── Grid data ────────────────────────────────────────────────────────────
    // Flat array of row descriptors:
    //   { rowType: "header", unitId, unitName }
    //   { rowType: "plan",   unitId, slotIndex, dayPlans: [plan|null × 7] }
    property var gridRows: []

    function computeGrid() {
        var u = planDatabase.allUnits()

        // Respect the active unit filter
        var filter = planDatabase.unitFilter
        if (filter.length > 0)
            u = u.filter(function(unit) { return filter.indexOf(unit.id) >= 0 })

        // Fetch all plans that overlap this week
        var we = new Date(weekStart)
        we.setDate(we.getDate() + 6)
        var allPlans = planDatabase.plansForRangeQML(weekStart, we)

        // Group plans: byUnitDay[unitId][dayIndex 0-6] = [plan, ...]
        var byUnitDay = {}
        u.forEach(function(unit) {
            byUnitDay[unit.id] = [[], [], [], [], [], [], []]
        })
        allPlans.forEach(function(plan) {
            var pd = new Date(plan.startDate)
            pd.setHours(0, 0, 0, 0)
            var ws = new Date(weekStart)
            ws.setHours(0, 0, 0, 0)
            var di = Math.round((pd - ws) / 86400000)
            if (di >= 0 && di < 7 && byUnitDay[plan.unitId])
                byUnitDay[plan.unitId][di].push(plan)
        })

        // Build the flat row array
        var rows = []
        u.forEach(function(unit) {
            var uid = unit.id
            rows.push({ rowType: "header", unitId: uid, unitName: unit.name })

            // How many plan rows does this unit need across the whole week?
            var maxSlots = 1
            for (var d = 0; d < 7; d++) {
                var cnt = byUnitDay[uid][d].length
                if (cnt > maxSlots) maxSlots = cnt
            }

            // One row per slot, pre-filling nulls for days with fewer plans
            for (var s = 0; s < maxSlots; s++) {
                var dayPlans = []
                for (var d = 0; d < 7; d++) {
                    var arr = byUnitDay[uid][d]
                    dayPlans.push(s < arr.length ? arr[s] : null)
                }
                rows.push({ rowType: "plan", unitId: uid, slotIndex: s, dayPlans: dayPlans })
            }
        })

        gridRows = rows
    }

    Component.onCompleted: computeGrid()
    onWeekStartChanged:    computeGrid()

    Connections {
        target: root.planDatabase
        function onPlansChanged()      { root.computeGrid() }
        function onUnitFilterChanged() { root.computeGrid() }
    }

    // ── Left column: week number ─────────────────────────────────────────────
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

    // ── Main grid area ───────────────────────────────────────────────────────
    Item {
        id: mainArea
        anchors.left: weekNumArea.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        readonly property real colWidth: width / 7

        // Fixed day-header row
        Item {
            id: dayHeaderRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 52

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: "#ccc"
            }

            Repeater {
                model: 7
                delegate: Item {
                    required property int index

                    readonly property date cellDate: {
                        var d = new Date(root.weekStart)
                        d.setDate(d.getDate() + index)
                        return d
                    }
                    readonly property bool isToday: {
                        var now = new Date()
                        return cellDate.getFullYear() === now.getFullYear()
                            && cellDate.getMonth() === now.getMonth()
                            && cellDate.getDate() === now.getDate()
                    }

                    x: index * mainArea.colWidth
                    width: mainArea.colWidth
                    height: dayHeaderRow.height

                    Rectangle {
                        visible: index > 0
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 1
                        color: "#ccc"
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.locale().dayName(cellDate.getDay(), Locale.ShortFormat)
                            font.pixelSize: Qt.application.font.pixelSize * 0.75
                            opacity: 0.7
                        }

                        // Day number with "today" circle
                        Item {
                            readonly property real sz: Math.max(numLabel.implicitWidth, numLabel.implicitHeight) + 8
                            width: sz
                            height: sz
                            anchors.horizontalCenter: parent.horizontalCenter

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: Material.primary
                                visible: isToday
                            }

                            Label {
                                id: numLabel
                                anchors.centerIn: parent
                                text: cellDate.getDate()
                                font.bold: isToday
                                color: isToday ? "white" : Material.foreground
                            }
                        }
                    }
                }
            }
        }

        // Scrollable body — unit bands + plan rows
        Flickable {
            id: flickable
            anchors.top: dayHeaderRow.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            contentHeight: gridBody.implicitHeight
            clip: true

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            Column {
                id: gridBody
                width: flickable.width

                Repeater {
                    model: root.gridRows

                    delegate: Item {
                        required property var modelData
                        required property int index

                        readonly property bool isHeader: modelData.rowType === "header"

                        width: gridBody.width
                        height: isHeader ? 26 : 52

                        // ── Unit header band ─────────────────────────────────
                        Rectangle {
                            visible: isHeader
                            anchors.fill: parent
                            // Subtle tinted background for the unit band header
                            color: Material.theme === Material.Dark
                                   ? Qt.rgba(1, 1, 1, 0.06)
                                   : Qt.rgba(0, 0, 0, 0.04)

                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                text: modelData.unitName || ""
                                font.bold: true
                                font.pixelSize: Qt.application.font.pixelSize * 0.8
                                opacity: 0.75
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 1
                                color: "#ccc"
                            }
                        }

                        // ── Plan row: 7 cells, one per day ──────────────────
                        Row {
                            visible: !isHeader
                            anchors.fill: parent

                            Repeater {
                                model: 7
                                delegate: WeekPlanCell {
                                    required property int index
                                    width: gridBody.width / 7
                                    height: 52
                                    plan: !isHeader ? modelData.dayPlans[index] : null
                                    onClicked: function(p) {
                                        root.planEditRequested(
                                            p.planId, p.name,
                                            p.startDate, p.endDate,
                                            p.unitId, p.routeIds)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
