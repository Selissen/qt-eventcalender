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
    required property date         displayDate
    required property bool         weekViewActive

    // ── Derived date range for the current view ────────────────────────────
    CalendarRange {
        id: range
        displayDate:    root.displayDate
        weekViewActive: root.weekViewActive
    }
    readonly property date rangeStart: range.rangeStart
    readonly property date rangeEnd:   range.rangeEnd

    // ── State ──────────────────────────────────────────────────────────────
    property bool isEditing: false
    property int  editPlanId: -1

    // ── Seed UI models once the database is ready ──────────────────────────
    Component.onCompleted: {
        var units = root.planDatabase.allUnits()
        for (var i = 0; i < units.length; i++)
            unitsModel.append({ unitId: units[i].id, unitName: units[i].name })

        var routes = root.planDatabase.allRoutes()
        for (var j = 0; j < routes.length; j++)
            routesModel.append({ routeId: routes[j].id, routeName: routes[j].name, checked: false })
    }

    ListModel { id: unitsModel  }
    ListModel { id: routesModel }

    // ── Public API ─────────────────────────────────────────────────────────
    function requestEdit(planId, startDt, endDt, unitId, routeIds) {
        editPlanId                   = planId
        startPicker.selectedDateTime = startDt
        endPicker.selectedDateTime   = endDt

        for (var i = 0; i < unitsModel.count; i++) {
            if (unitsModel.get(i).unitId === unitId) {
                unitCombo.currentIndex = i
                break
            }
        }
        for (var j = 0; j < routesModel.count; j++) {
            var rid = routesModel.get(j).routeId
            routesModel.setProperty(j, "checked", routeIds.indexOf(rid) >= 0)
        }
        isEditing = true
    }

    // ── Helpers ────────────────────────────────────────────────────────────
    function savePlan() {
        var sd = startPicker.selectedDateTime || new Date()
        var ed = endPicker.selectedDateTime   || new Date()

        if (ed < sd) {
            endDateError.visible = true
            return
        }
        endDateError.visible = false

        var startSecs = sd.getHours() * 3600 + sd.getMinutes() * 60
        var endSecs   = ed.getHours() * 3600 + ed.getMinutes() * 60

        var unitId = unitsModel.get(unitCombo.currentIndex).unitId

        var routeIds = []
        for (var i = 0; i < routesModel.count; i++)
            if (routesModel.get(i).checked) routeIds.push(routesModel.get(i).routeId)

        if (editPlanId === -1)
            root.planDatabase.addPlan("", sd, startSecs, ed, endSecs, unitId, routeIds)
        else
            root.planDatabase.updatePlan(editPlanId, "", sd, startSecs, ed, endSecs, unitId, routeIds)

        isEditing = false
    }

    // ── Left border ────────────────────────────────────────────────────────
    Rectangle {
        anchors.left:   parent.left
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: "#ccc"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 1
        spacing: 0

        // ── Header ─────────────────────────────────────────────────────────
        Pane {
            Layout.fillWidth: true
            padding: 12

            RowLayout {
                anchors.left:  parent.left
                anchors.right: parent.right
                spacing: 8

                ToolButton {
                    visible: root.isEditing
                    text: "\u2190"
                    font.pixelSize: Qt.application.font.pixelSize * 1.2
                    onClicked: root.isEditing = false
                }

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    Label {
                        font.bold: true
                        font.pixelSize: Qt.application.font.pixelSize * 1.05
                        text: root.isEditing
                              ? (root.editPlanId === -1 ? qsTr("Add Plan") : qsTr("Edit Plan"))
                              : qsTr("Plans")
                    }
                    Label {
                        visible: !root.isEditing
                        font.pixelSize: Qt.application.font.pixelSize * 0.82
                        opacity: 0.6
                        text: root.weekViewActive
                              ? qsTr("Week %1").arg(CalendarUtils.isoWeekNumber(root.displayDate))
                              : root.displayDate.toLocaleString(Qt.locale(), "MMMM yyyy")
                    }
                }

                RoundButton {
                    visible: !root.isEditing
                    text: "+"
                    font.pixelSize: Qt.application.font.pixelSize * 1.2
                    Material.background: Material.primary
                    Material.foreground: "white"
                    onClicked: {
                        editPlanId = -1
                        var d = root.displayDate
                        startPicker.selectedDateTime = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 9,  0)
                        endPicker.selectedDateTime   = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 10, 0)
                        unitCombo.currentIndex = 0
                        for (var i = 0; i < routesModel.count; i++)
                            routesModel.setProperty(i, "checked", false)
                        root.isEditing = true
                    }
                }
            }
        }

        MenuSeparator { Layout.fillWidth: true; padding: 0 }

        // ── Content ─────────────────────────────────────────────────────────
        StackLayout {
            currentIndex: root.isEditing ? 1 : 0
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ── Index 0: Plan list ──────────────────────────────────────────
            Item {
                ListView {
                    id: planList
                    anchors.fill: parent
                    clip: true

                    model: PlanModel {
                        planDatabase: root.planDatabase
                        date:         root.rangeStart
                        endDate:      root.rangeEnd
                    }

                    delegate: Item {
                        width: planList.width
                        height: delegateLayout.implicitHeight

                        required property int       planId
                        required property var       startDate
                        required property var       endDate
                        required property int       unitId
                        required property string    unitName
                        required property var       routeIds
                        required property var       routeNames

                        ColumnLayout {
                            id: delegateLayout
                            anchors.left:  parent.left
                            anchors.right: parent.right
                            spacing: 0

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin:  12
                                Layout.rightMargin: 4
                                Layout.topMargin:   8

                                Label {
                                    text: unitName
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                ToolButton {
                                    text: "\u270E"
                                    font.pixelSize: Qt.application.font.pixelSize * 0.9
                                    onClicked: root.requestEdit(planId, startDate, endDate, unitId, routeIds)
                                }
                                ToolButton {
                                    text: "\u2715"
                                    font.pixelSize: Qt.application.font.pixelSize * 0.9
                                    onClicked: root.planDatabase.deletePlan(planId)
                                }
                            }

                            Label {
                                text: Qt.formatDate(startDate, "d MMM")
                                      + "  \u00B7  "
                                      + Qt.formatTime(startDate, "hh:mm")
                                      + " \u2013 "
                                      + Qt.formatTime(endDate, "hh:mm")
                                font.pixelSize: Qt.application.font.pixelSize * 0.82
                                opacity: 0.6
                                Layout.leftMargin: 12
                            }

                            Label {
                                visible: routeNames.length > 0
                                text: routeNames.join(", ")
                                font.pixelSize: Qt.application.font.pixelSize * 0.82
                                opacity: 0.6
                                Layout.leftMargin: 12
                                Layout.bottomMargin: 8
                                Layout.rightMargin: 12
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Item {
                                visible: routeNames.length === 0
                                Layout.preferredHeight: 8
                            }

                            MenuSeparator { Layout.fillWidth: true; padding: 0 }
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: qsTr("No plans")
                        opacity: 0.35
                        visible: planList.count === 0
                    }
                }
            }

            // ── Index 1: Edit / Add form ────────────────────────────────────
            Item {
                Flickable {
                    anchors.fill: parent
                    contentHeight: formLayout.implicitHeight + 24
                    clip: true

                    ColumnLayout {
                        id: formLayout
                        anchors.left:    parent.left
                        anchors.right:   parent.right
                        anchors.margins: 12
                        spacing: 4

                        Item { Layout.preferredHeight: 4 }

                        Label { text: qsTr("Unit") }
                        ComboBox {
                            id: unitCombo
                            Layout.fillWidth: true
                            model: unitsModel
                            textRole: "unitName"
                            valueRole: "unitId"
                        }

                        Item { Layout.preferredHeight: 4 }

                        Label { text: qsTr("Start") }
                        DatePickerField {
                            id: startPicker
                            Layout.fillWidth: true
                            onSelectedDateTimeChanged: endDateError.visible = false
                        }

                        Item { Layout.preferredHeight: 4 }

                        Label { text: qsTr("End") }
                        DatePickerField {
                            id: endPicker
                            Layout.fillWidth: true
                            onSelectedDateTimeChanged: endDateError.visible = false
                        }
                        Label {
                            id: endDateError
                            visible: false
                            text: qsTr("End must be after start")
                            color: Material.color(Material.Red)
                            font.pixelSize: Qt.application.font.pixelSize * 0.82
                        }

                        Item { Layout.preferredHeight: 8 }

                        Label { text: qsTr("Routes (optional)") }
                        Frame {
                            Layout.fillWidth: true
                            padding: 0

                            ListView {
                                id: routesList
                                implicitHeight: contentHeight
                                width: parent.width
                                interactive: false
                                model: routesModel

                                delegate: CheckDelegate {
                                    width: routesList.width
                                    text: model.routeName
                                    checked: model.checked
                                    onToggled: routesModel.setProperty(index, "checked", checked)
                                }
                            }
                        }

                        Item { Layout.preferredHeight: 8 }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Button {
                                text: qsTr("Cancel")
                                Layout.fillWidth: true
                                flat: true
                                onClicked: root.isEditing = false
                            }
                            Button {
                                text: qsTr("Save")
                                Layout.fillWidth: true
                                Material.background: Material.primary
                                Material.foreground: "white"
                                onClicked: root.savePlan()
                            }
                        }
                    }
                }
            }
        }
    }
}
