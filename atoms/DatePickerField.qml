// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import App

// A combined date-time input that works like <input type="datetime-local">:
//   • Editable text field with a calendar icon button on the right, inside the field
//   • Calendar popup anchored below (or above) the field
//   • Popup: calendar grid + time input + Clear / Today buttons
//   • Clicking a date keeps the popup open so the time can be adjusted
//
// Format / parsing is handled by DateTimeUtils (C++).
//
// Property:
//   selectedDateTime  – JS Date (or null when cleared)
Item {
    id: root

    property var selectedDateTime: new Date()   // null = cleared

    implicitWidth:  field.implicitWidth
    implicitHeight: field.implicitHeight

    // Sync the text field when selectedDateTime is set programmatically
    onSelectedDateTimeChanged: {
        if (!field.activeFocus)
            field.text = DateTimeUtils.formatDateTime(selectedDateTime)
    }

    Component.onCompleted: field.text = DateTimeUtils.formatDateTime(selectedDateTime)

    // ── Text field with embedded calendar button ───────────────────────────
    TextField {
        id: field
        anchors.fill: parent

        // Leave room for the icon button on the right
        rightPadding: calBtn.width + 4

        placeholderText: DateTimeUtils.dateTimeFormat.toLowerCase()
        inputMethodHints: Qt.ImhDateTime

        onEditingFinished: {
            var dt = DateTimeUtils.parseDateTime(text)
            if (dt && !isNaN(dt.getTime())) {
                root.selectedDateTime = dt
                // Reformat to canonical form (e.g. "1/2/2026 9:0" → "01/02/2026 09:00")
                text = DateTimeUtils.formatDateTime(dt)
            } else {
                text = DateTimeUtils.formatDateTime(root.selectedDateTime)
            }
        }
    }

    // Calendar icon sits flush with the right edge, inside the field
    ToolButton {
        id: calBtn
        anchors.right: parent.right
        anchors.top:   parent.top
        anchors.bottom: parent.bottom
        width: height

        // U+1F4C5  📅
        text: "\uD83D\uDCC5"
        font.pixelSize: Qt.application.font.pixelSize * 0.9

        // Transparent so the TextField background shows through
        background: Item {}

        onClicked: popup.openAt(root)
    }

    // ── Calendar popup ─────────────────────────────────────────────────────
    Popup {
        id: popup
        parent: Overlay.overlay
        width: 272
        padding: 10
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property int viewMonth: new Date().getMonth()
        property int viewYear:  new Date().getFullYear()

        // Open anchored below (or above if no room) the given anchor Item
        function openAt(anchor) {
            var dt = root.selectedDateTime
            if (!dt || isNaN(dt.getTime())) dt = new Date()

            viewMonth = dt.getMonth()
            viewYear  = dt.getFullYear()
            timeField.text = Qt.formatTime(dt, "HH:mm")

            var below = anchor.mapToItem(Overlay.overlay, 0, anchor.height + 4)
            var px = Math.max(4, Math.min(below.x, Overlay.overlay.width - width - 4))
            var py = below.y

            if (py + implicitHeight + 4 > Overlay.overlay.height) {
                var above = anchor.mapToItem(Overlay.overlay, 0, -implicitHeight - 4)
                py = above.y
            }

            x = px
            y = py
            open()
        }

        function prevMonth() {
            if (viewMonth === 0) { viewMonth = 11; viewYear-- } else viewMonth--
        }
        function nextMonth() {
            if (viewMonth === 11) { viewMonth = 0; viewYear++ } else viewMonth++
        }

        // Combine a calendar date with the current time-field value
        function _withTime(date) {
            var parts = timeField.text.split(":")
            var h = parseInt(parts[0]) || 0
            var m = parseInt(parts[1]) || 0
            return new Date(date.getFullYear(), date.getMonth(), date.getDate(), h, m, 0, 0)
        }

        ColumnLayout {
            width: popup.width - 2 * popup.padding
            spacing: 2

            // ── Month / year navigation ─────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                ToolButton {
                    text: "\u2039"
                    font.pixelSize: Qt.application.font.pixelSize * 1.5
                    onClicked: popup.prevMonth()
                }
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: new Date(popup.viewYear, popup.viewMonth, 1)
                              .toLocaleDateString(Qt.locale(), "MMMM yyyy")
                }
                ToolButton {
                    text: "\u203a"
                    font.pixelSize: Qt.application.font.pixelSize * 1.5
                    onClicked: popup.nextMonth()
                }
            }

            // ── Day-of-week header ──────────────────────────────────────
            DayOfWeekRow {
                id: dowRow
                locale: monthGrid.locale
                font.bold: false
                Layout.fillWidth: true
                delegate: Label {
                    text: model.shortName
                    font: dowRow.font
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 0.6
                }
            }

            // ── Month grid ──────────────────────────────────────────────
            MonthGrid {
                id: monthGrid
                month: popup.viewMonth
                year:  popup.viewYear
                spacing: 0
                Layout.fillWidth: true
                Layout.preferredHeight: 6 * 34

                delegate: ItemDelegate {
                    padding: 0
                    implicitHeight: 34

                    readonly property bool isSelected:
                        root.selectedDateTime && !isNaN(root.selectedDateTime.getTime()) &&
                        model.date.toDateString() === root.selectedDateTime.toDateString()
                    readonly property bool inMonth: model.month === monthGrid.month

                    background: Item {}

                    contentItem: Item {
                        Rectangle {
                            anchors.centerIn: parent
                            width:  Math.min(parent.width, parent.height) - 4
                            height: width
                            radius: width / 2
                            color:        isSelected ? Material.primary : "transparent"
                            border.color: model.today && !isSelected ? Material.primary : "transparent"
                            border.width: 1
                        }
                        Label {
                            anchors.centerIn: parent
                            text: model.day
                            color: isSelected ? "white"
                                              : (model.today ? Material.primary : Material.foreground)
                            opacity: inMonth ? 1.0 : 0.3
                            font.bold: model.today || isSelected
                        }
                    }

                    // Select date, preserve time — keep popup open for time adjustment
                    onClicked: root.selectedDateTime = popup._withTime(model.date)
                }
            }

            MenuSeparator { Layout.fillWidth: true; padding: 0 }

            // ── Time input ──────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                Layout.bottomMargin: 2

                Label {
                    text: qsTr("Time")
                    opacity: 0.7
                }

                Item { Layout.fillWidth: true }

                TextField {
                    id: timeField
                    Layout.preferredWidth: 72
                    horizontalAlignment: Text.AlignHCenter
                    inputMethodHints: Qt.ImhTime
                    validator: RegularExpressionValidator {
                        regularExpression: /^([01]?\d|2[0-3]):[0-5]\d$/
                    }
                    onEditingFinished: {
                        var base = (root.selectedDateTime && !isNaN(root.selectedDateTime.getTime()))
                                   ? root.selectedDateTime : new Date()
                        root.selectedDateTime = popup._withTime(base)
                    }
                }
            }

            MenuSeparator { Layout.fillWidth: true; padding: 0 }

            // ── Action buttons ──────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    text: qsTr("Clear")
                    flat: true
                    Layout.fillWidth: true
                    onClicked: {
                        root.selectedDateTime = null
                        field.text = ""
                        popup.close()
                    }
                }

                Button {
                    text: qsTr("Today")
                    Layout.fillWidth: true
                    Material.background: Material.primary
                    Material.foreground: "white"
                    onClicked: {
                        var now = new Date()
                        root.selectedDateTime = now
                        timeField.text = Qt.formatTime(now, "HH:mm")
                        popup.viewMonth = now.getMonth()
                        popup.viewYear  = now.getFullYear()
                        popup.close()
                    }
                }
            }
        }
    }
}
