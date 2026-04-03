import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import App

Item {
    id: root

    required property PlanDatabase planDatabase
    required property date         displayDate
    required property bool         weekViewActive

    implicitHeight: content.implicitHeight

    // ── Date range ────────────────────────────────────────────────────────
    CalendarRange {
        id: range
        displayDate:    root.displayDate
        weekViewActive: root.weekViewActive
    }
    readonly property date rangeStart: range.rangeStart
    readonly property date rangeEnd:   range.rangeEnd

    // ── Data ──────────────────────────────────────────────────────────────
    property var unitData: []

    readonly property real totalHours: {
        var sum = 0
        for (var i = 0; i < unitData.length; i++) sum += unitData[i].hours
        return sum
    }

    function refresh() {
        unitData = root.planDatabase.plannedHoursPerUnit(rangeStart, rangeEnd)
    }

    Component.onCompleted:  refresh()
    onRangeStartChanged:    refresh()
    onRangeEndChanged:      refresh()

    Connections {
        target: root.planDatabase
        function onPlansChanged()      { root.refresh() }
        function onUnitFilterChanged() { root.refresh() }
    }

    // ── Visual ────────────────────────────────────────────────────────────
    ColumnLayout {
        id: content
        anchors.left:  parent.left
        anchors.right: parent.right
        spacing: 0

        MenuSeparator { Layout.fillWidth: true; padding: 0 }

        // Header row — unit names + "Total"
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: root.unitData
                delegate: Label {
                    Layout.fillWidth: true
                    text: modelData.unitName
                    font.bold: true
                    font.pixelSize: Qt.application.font.pixelSize * 0.82
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: 8
                    bottomPadding: 2
                    opacity: 0.7
                }
            }

            Label {
                Layout.fillWidth: true
                text: qsTr("Total")
                font.bold: true
                font.pixelSize: Qt.application.font.pixelSize * 0.82
                horizontalAlignment: Text.AlignHCenter
                topPadding: 8
                bottomPadding: 2
            }
        }

        // Body row — planned hours per unit + grand total
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: root.unitData
                delegate: Label {
                    Layout.fillWidth: true
                    text: modelData.hours.toFixed(1) + " h"
                    font.pixelSize: Qt.application.font.pixelSize * 0.95
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: 2
                    bottomPadding: 8
                }
            }

            Label {
                Layout.fillWidth: true
                text: root.totalHours.toFixed(1) + " h"
                font.bold: true
                font.pixelSize: Qt.application.font.pixelSize * 0.95
                horizontalAlignment: Text.AlignHCenter
                topPadding: 2
                bottomPadding: 8
            }
        }
    }
}
