// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import App

ApplicationWindow {
    id: window
    width: 1000
    height: 600
    title: qsTr("Event Calendar")
    visible: true

    required property PlanDatabase planDatabase

    readonly property date currentDate: new Date()

    property bool weekViewActive: false
    property date displayDate: currentDate
    property bool sidebarOpen: false

    function navigatePrev() {
        displayDate = CalendarUtils.navigatePrev(displayDate, weekViewActive)
    }

    function navigateNext() {
        displayDate = CalendarUtils.navigateNext(displayDate, weekViewActive)
    }

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4

            ToolButton {
                text: "\u2039"
                font.pixelSize: Qt.application.font.pixelSize * 1.5
                onClicked: window.navigatePrev()
            }

            // Month view: month + year label
            Label {
                visible: !window.weekViewActive
                text: window.displayDate.toLocaleString(Qt.locale(), "MMMM yyyy")
                font.pixelSize: Qt.application.font.pixelSize * 1.25
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            // Week view: sliding strip of clickable week numbers
            Row {
                visible: window.weekViewActive
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 0

                Repeater {
                    model: 7  // current week ± 3

                    ToolButton {
                        property int weekOffset: index - 3
                        property date weekRefDate: {
                            var d = new Date(window.displayDate)
                            d.setDate(d.getDate() + weekOffset * 7)
                            return d
                        }
                        readonly property bool isCurrent: weekOffset === 0

                        text: CalendarUtils.isoWeekNumber(weekRefDate)
                        font.bold: isCurrent
                        font.pixelSize: Qt.application.font.pixelSize * (isCurrent ? 1.15 : 1.0)

                        onClicked: window.displayDate = weekRefDate
                    }
                }
            }

            ToolButton {
                text: "\u203a"
                font.pixelSize: Qt.application.font.pixelSize * 1.5
                onClicked: window.navigateNext()
            }

            ToolButton {
                text: qsTr("Today")
                enabled: window.displayDate.toDateString() !== window.currentDate.toDateString()
                onClicked: window.displayDate = window.currentDate
            }

            ToolButton {
                text: window.weekViewActive ? qsTr("Month") : qsTr("Week")
                onClicked: window.weekViewActive = !window.weekViewActive
            }

            ToolButton {
                text: qsTr("Plans")
                font.bold: window.sidebarOpen
                onClicked: window.sidebarOpen = !window.sidebarOpen
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── Unit filter sidebar ──────────────────────────────────────────
        UnitFilterSidebar {
            planDatabase: window.planDatabase
            Layout.fillHeight: true
        }

        // ── Calendar views + footer ──────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: window.weekViewActive ? 1 : 0

                MonthView {
                    planDatabase: window.planDatabase
                    displayDate: window.displayDate
                    onPlanEditRequested: (id, sd, ed, uid, rids) => {
                        window.sidebarOpen = true
                        sidebar.requestEdit(id, sd, ed, uid, rids)
                    }
                }

                WeekView {
                    planDatabase: window.planDatabase
                    referenceDate: window.displayDate
                    onPlanEditRequested: (id, sd, ed, uid, rids) => {
                        window.sidebarOpen = true
                        sidebar.requestEdit(id, sd, ed, uid, rids)
                    }
                }
            }

            PlanFooter {
                Layout.fillWidth: true
                planDatabase:   window.planDatabase
                displayDate:    window.displayDate
                weekViewActive: window.weekViewActive
            }
        }

        // ── Sidebar ──────────────────────────────────────────────────────
        Item {
            id: sidebarWrapper
            clip: true
            Layout.fillHeight: true
            Layout.preferredWidth: sidebarWidth

            property real sidebarWidth: window.sidebarOpen ? 280 : 0
            Behavior on sidebarWidth {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }

            EventSidebar {
                id: sidebar
                anchors.fill: parent
                planDatabase:   window.planDatabase
                displayDate:    window.displayDate
                weekViewActive: window.weekViewActive
            }
        }
    }
}
