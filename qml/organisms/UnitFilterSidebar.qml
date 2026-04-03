import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import App

Item {
    id: root

    required property PlanDatabase planDatabase

    implicitWidth: 96

    // ── Internal state ────────────────────────────────────────────────────
    property var activeUnitIds: []

    ListModel { id: unitsModel }

    Component.onCompleted: {
        var units = root.planDatabase.allUnits()
        for (var i = 0; i < units.length; i++)
            unitsModel.append({ unitId: units[i].id, unitName: units[i].name })
    }

    // ── Selection logic ───────────────────────────────────────────────────
    // Without Ctrl: exclusive — selects only this unit;
    //               clicking the already-sole active unit clears the filter.
    // With Ctrl:    additive toggle — flips this unit without touching others.
    function toggleUnit(unitId, ctrlHeld) {
        var copy = activeUnitIds.slice()
        var idx  = copy.indexOf(unitId)

        if (ctrlHeld) {
            if (idx >= 0) copy.splice(idx, 1)
            else          copy.push(unitId)
        } else {
            copy = (copy.length === 1 && idx >= 0) ? [] : [unitId]
        }

        activeUnitIds              = copy
        root.planDatabase.unitFilter = copy
    }

    // ── Right border ──────────────────────────────────────────────────────
    Rectangle {
        anchors.right:  parent.right
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: "#ccc"
    }

    // ── Content ───────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.rightMargin: 1
        spacing: 0

        Pane {
            Layout.fillWidth: true
            padding: 12
            bottomPadding: 8

            Label {
                text: qsTr("Units")
                font.bold: true
                font.pixelSize: Qt.application.font.pixelSize * 1.05
            }
        }

        MenuSeparator { Layout.fillWidth: true; padding: 0 }

        Item { Layout.preferredHeight: 6 }

        Column {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            spacing: 4

            Repeater {
                model: unitsModel

                delegate: Rectangle {
                    required property int    unitId
                    required property string unitName

                    width:  parent.width
                    height: 32
                    radius: 4

                    property bool active: root.activeUnitIds.indexOf(unitId) >= 0

                    color:        active ? Material.color(Material.primary) : "transparent"
                    border.color: Material.color(Material.primary, Material.Shade300)
                    border.width: 1

                    Label {
                        anchors.centerIn: parent
                        text: unitName
                        font.pixelSize: Qt.application.font.pixelSize * 0.85
                        color: parent.active
                               ? "white"
                               : Material.foreground
                        elide: Text.ElideRight
                        width: parent.width - 8
                        horizontalAlignment: Text.AlignHCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onClicked: (mouse) => root.toggleUnit(
                            unitId, mouse.modifiers & Qt.ControlModifier)
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
