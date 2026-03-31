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

        // Pre-compute each plan's visible day range within this week
        var ws0 = new Date(weekStart)
        ws0.setHours(0, 0, 0, 0)
        allPlans.forEach(function(plan) {
            var pd = new Date(plan.startDate); pd.setHours(0, 0, 0, 0)
            var ed = new Date(plan.endDate);   ed.setHours(0, 0, 0, 0)
            plan._startDi = Math.max(0, Math.round((pd - ws0) / 86400000))
            plan._endDi   = Math.min(6, Math.round((ed - ws0) / 86400000))
        })

        // Collect unique plans per unit (multi-day plans appear in multiple days;
        // deduplicate by planId so the scheduler sees each plan exactly once)
        var byUnit = {}
        u.forEach(function(unit) { byUnit[unit.id] = {} })
        allPlans.forEach(function(plan) {
            if (byUnit[plan.unitId])
                byUnit[plan.unitId][plan.planId] = plan
        })

        // Build the flat row array
        var rows = []
        u.forEach(function(unit) {
            var uid = unit.id
            rows.push({ rowType: "header", unitId: uid, unitName: unit.name })

            // Collect and sort unique plans by start day, then end day
            var unitPlans = []
            var seen = byUnit[uid]
            Object.keys(seen).forEach(function(k) { unitPlans.push(seen[k]) })
            unitPlans.sort(function(a, b) {
                return a._startDi - b._startDi || a._endDi - b._endDi
            })

            // Greedy interval scheduling: assign each plan to the first slot where
            // it doesn't overlap with the last-placed plan (slots are sorted, so
            // checking only the tail is sufficient).
            var slots = []  // slots[s] = [plan, ...] non-overlapping, sorted by startDi
            unitPlans.forEach(function(plan) {
                var placed = false
                for (var s = 0; s < slots.length; s++) {
                    var last = slots[s][slots[s].length - 1]
                    if (plan._startDi > last._endDi) {
                        slots[s].push(plan)
                        placed = true
                        break
                    }
                }
                if (!placed)
                    slots.push([plan])
            })

            // Emit one plan-row per slot; fill each day cell with the plan that
            // covers it, or null for empty cells
            var numSlots = Math.max(1, slots.length)
            for (var s = 0; s < numSlots; s++) {
                var dayPlans = [null, null, null, null, null, null, null]
                if (s < slots.length) {
                    slots[s].forEach(function(plan) {
                        for (var d = plan._startDi; d <= plan._endDi; d++)
                            dayPlans[d] = plan
                    })
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
