// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import App

ColumnLayout {
    id: root

    required property PlanDatabase planDatabase

    required property bool today
    required property int year
    required property int month
    required property int day

    required property int visibleMonth

    signal planEditRequested(int planId, var startDate, var endDate, int unitId, var routeIds)

    Label {
        id: dayNameText
        horizontalAlignment: Text.AlignHCenter
        topPadding: 4
        opacity: month === root.visibleMonth ? 1 : 0
        text: Qt.locale().dayName(new Date(root.year, root.month, root.day).getDay(), Locale.ShortFormat)
        font.pixelSize: Qt.application.font.pixelSize * 0.75
        Layout.fillWidth: true
    }

    Label {
        id: dayText
        horizontalAlignment: Text.AlignHCenter
        topPadding: 0
        Material.theme: root.today ? Material.Dark : undefined
        opacity: month === root.visibleMonth ? 1 : 0
        text: day

        Layout.fillWidth: true

        Rectangle {
            width: height
            height: Math.max(dayText.implicitWidth, dayText.implicitHeight)
            radius: width / 2
            color: Material.primary
            anchors.centerIn: dayText
            anchors.verticalCenterOffset: dayText.height - dayText.baselineOffset
            z: -1
            visible: root.today
        }
    }

    ListView {
        id: listView
        spacing: 1
        clip: true

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: 4

        delegate: ItemDelegate {
            id: itemDelegate
            width: listView.width
            leftPadding: 4
            rightPadding: 4
            topPadding: 3
            bottomPadding: 3

            required property int       planId
            required property var       startDate
            required property var       endDate
            required property int       unitId
            required property string    unitName
            required property var       routeIds
            required property var       routeNames

            Material.theme: Material.Dark

            background: Rectangle {
                color: itemDelegate.Material.primary
                radius: 0
            }

            contentItem: Column {
                spacing: 0

                Label {
                    width: parent.width
                    text: unitName + "  " + Qt.formatTime(startDate, "hh:mm") + "\u2013" + Qt.formatTime(endDate, "hh:mm")
                    font.pixelSize: Qt.application.font.pixelSize * 0.75
                    font.bold: true
                    color: itemDelegate.Material.foreground
                    elide: Text.ElideRight
                }
                Label {
                    width: parent.width
                    text: routeNames.join(", ")
                    font.pixelSize: Qt.application.font.pixelSize * 0.68
                    color: itemDelegate.Material.foreground
                    opacity: 0.75
                    elide: Text.ElideRight
                    visible: routeNames.length > 0
                }
            }

            onClicked: root.planEditRequested(planId, startDate, endDate, unitId, routeIds)
        }
        model: PlanModel {
            planDatabase: root.planDatabase
            date: new Date(root.year, root.month, root.day)
        }
    }
}
