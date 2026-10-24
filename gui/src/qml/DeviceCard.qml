import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

import org.streetpea.chiaking

// Card for one keyboard or mouse: silhouette, name, connection and battery,
// laid out like the Controllers card.
Rectangle {
    id: card
    property string kind: "keyboard"   // keyboard | mouse
    property var devices: []
    // an external device wins over the built-in one
    readonly property var info: devices.find(d => !d.builtIn) || devices[0] || null
    readonly property color cBody: "#8e8e93"
    readonly property color cLine: "#48484a"

    radius: 10
    color: "#333337"
    implicitHeight: content.implicitHeight + 24

    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 12 }
        spacing: 4

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 120
            Layout.preferredHeight: 62
            opacity: card.info ? 1 : 0.4

            // keyboard: body with three rows of keys and a space bar
            Rectangle {
                visible: card.kind === "keyboard"
                anchors.centerIn: parent
                width: 120; height: 44; radius: 7
                color: card.cBody; border.width: 2; border.color: card.cLine
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    Repeater {
                        model: 3
                        Row {
                            spacing: 3
                            Repeater {
                                model: 9
                                Rectangle { width: 9; height: 6; radius: 1.5; color: card.cLine; opacity: 0.55 }
                            }
                        }
                    }
                    Rectangle { width: 54; height: 6; radius: 1.5; color: card.cLine; opacity: 0.55; anchors.horizontalCenter: parent.horizontalCenter }
                }
            }

            // mouse: rounded body, button split and wheel
            Rectangle {
                visible: card.kind === "mouse"
                anchors.centerIn: parent
                width: 40; height: 60; radius: 20
                color: card.cBody; border.width: 2; border.color: card.cLine
                Rectangle { x: parent.width / 2 - 1; y: 2; width: 2; height: 20; color: card.cLine }
                Rectangle { x: parent.width / 2 - 3; y: 9; width: 6; height: 11; radius: 3; color: card.cLine }
                Rectangle { x: 4; y: 24; width: parent.width - 8; height: 2; color: card.cLine }
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            Layout.maximumWidth: card.width - 24
            elide: Text.ElideRight
            text: card.info ? card.info.name : (card.kind === "keyboard" ? qsTr("No Keyboard Found") : qsTr("No Mouse Found"))
            font.pixelSize: 15
            font.bold: true
        }

        Rectangle { Layout.fillWidth: true; Layout.topMargin: 6; Layout.preferredHeight: 1; color: "#1fffffff" }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            Label { Layout.fillWidth: true; Layout.leftMargin: 16; text: qsTr("Connection"); font.pixelSize: 13 }
            Label { Layout.rightMargin: 16; text: card.info ? card.info.connection : "-"; font.pixelSize: 13; color: "#b3ffffff" }
        }
        Rectangle { Layout.fillWidth: true; Layout.leftMargin: 16; Layout.preferredHeight: 1; color: "#1fffffff" }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            Label { Layout.fillWidth: true; Layout.leftMargin: 16; text: qsTr("Battery"); font.pixelSize: 13 }
            Row {
                visible: card.info !== null && card.info.battery >= 0
                spacing: 2
                Repeater {
                    model: 4
                    Rectangle {
                        width: 8; height: 14; radius: 2
                        color: card.info && index < card.info.battery ? "#30d158" : "#4a4a50"
                    }
                }
            }
            Label { Layout.rightMargin: 16; text: card.info ? card.info.batteryText : "-"; font.pixelSize: 13; color: "#b3ffffff" }
        }
    }
}
