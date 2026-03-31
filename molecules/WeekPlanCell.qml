// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

// A single slot cell in the week-view grid.
// Shows a plan when `plan` is non-null, or renders empty space.

Item {
    id: cell

    // A plan object from plansForRangeQML, or null for an empty slot.
    property var plan: null

    signal clicked(var plan)

    // ── Right grid line ───────────────────────────────────────────────────
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: "#e0e0e0"
    }

    // ── Bottom grid line ──────────────────────────────────────────────────
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: "#e0e0e0"
    }

    // ── Plan chip (only visible when slot is filled) ───────────────────────
    Rectangle {
        id: chip
        anchors.fill: parent
        anchors.margins: 3
        radius: 3
        color: Material.primary
        visible: cell.plan !== null

        Column {
            anchors.fill: parent
            anchors.leftMargin: 5
            anchors.rightMargin: 5
            anchors.topMargin: 4
            spacing: 1
            clip: true

            Label {
                width: parent.width
                text: cell.plan ? cell.plan.name : ""
                font.pixelSize: Qt.application.font.pixelSize * 0.8
                font.bold: true
                color: "white"
                elide: Text.ElideRight
            }

            Label {
                width: parent.width
                text: cell.plan
                      ? Qt.formatTime(cell.plan.startDate, "hh:mm")
                        + " \u2013 "
                        + Qt.formatTime(cell.plan.endDate, "hh:mm")
                      : ""
                font.pixelSize: Qt.application.font.pixelSize * 0.68
                color: "white"
                opacity: 0.85
                elide: Text.ElideRight
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: cell.clicked(cell.plan)
        }
    }
}
