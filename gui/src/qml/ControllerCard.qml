import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

import org.streetpea.chiaking

import "controls" as C

// About-style card for the connected controller: picture that lights up while testing,
// description, connection and battery.
ColumnLayout {
    id: card
    property var info: ControllerInfo.controllers[ControllerInfo.current] || null
    readonly property color cLit: "#0a84ff"
    readonly property color cOff: "#4a4a50"
    readonly property color cBody: "#38383c"

    spacing: 6

    Component.onCompleted: ControllerInfo.active = Qt.binding(() => card.visible)

    function pressed(name) {
        return !!ControllerInfo.state[name];
    }
    function axis(name) {
        return ControllerInfo.state[name] || 0;
    }

    component Lamp: Rectangle {
        id: lamp
        property bool on: false
        property string label: ""
        implicitWidth: 26
        implicitHeight: 26
        radius: height / 2
        color: on ? card.cLit : card.cOff
        Label {
            anchors.centerIn: parent
            text: lamp.label
            font.pixelSize: 11
            font.bold: true
            color: lamp.on ? "#ffffff" : "#b0b0b8"
        }
    }

    component Pill: Rectangle {
        id: pill
        property bool on: false
        property string label: ""
        implicitWidth: 44
        implicitHeight: 22
        radius: 6
        color: on ? card.cLit : card.cOff
        Label {
            anchors.centerIn: parent
            text: pill.label
            font.pixelSize: 11
            font.bold: true
            color: pill.on ? "#ffffff" : "#b0b0b8"
        }
    }

    component Stick: Item {
        id: stick
        property real sx: 0
        property real sy: 0
        property bool on: false
        implicitWidth: 56
        implicitHeight: 56
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "#222226"
            border.width: 1
            border.color: "#55ffffff"
        }
        Rectangle {
            width: 30
            height: 30
            radius: 15
            color: stick.on ? card.cLit : "#6a6a72"
            x: (stick.width - width) / 2 + stick.sx * (stick.width - width) / 2
            y: (stick.height - height) / 2 + stick.sy * (stick.height - height) / 2
        }
    }

    // picker, only when more than one controller is connected
    C.ComboBox {
        Layout.alignment: Qt.AlignHCenter
        visible: ControllerInfo.controllers.length > 1
        model: ControllerInfo.controllers.map(c => c.name)
        currentIndex: ControllerInfo.current
        onActivated: index => ControllerInfo.current = index
    }

    component InfoRow: RowLayout {
        property string label: ""
        default property alias extra: slot.data
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        Label {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            text: parent.label
            font.pixelSize: 13
        }
        RowLayout {
            id: slot
            Layout.rightMargin: 16
            spacing: 8
        }
    }

    // icon: the test picture, scaled down like the device icon in macOS About
    Item {
        visible: card.info !== null
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 4
        Layout.preferredWidth: 170
        Layout.preferredHeight: 96
        Item {
            id: picture
            width: 340
            height: 190
            scale: 170 / 340
            transformOrigin: Item.TopLeft

            // triggers and bumpers
            Rectangle {
                x: 52; y: 0; width: 64; height: 12; radius: 5; color: card.cOff
                Rectangle {
                    height: parent.height; radius: 5; color: card.cLit
                    width: parent.width * card.axis("lt")
                }
            }
            Rectangle {
                x: 224; y: 0; width: 64; height: 12; radius: 5; color: card.cOff
                Rectangle {
                    height: parent.height; radius: 5; color: card.cLit
                    width: parent.width * card.axis("rt")
                }
            }
            Rectangle {
                x: 44; y: 18; width: 80; height: 14; radius: 6
                color: card.pressed("lb") ? card.cLit : card.cOff
            }
            Rectangle {
                x: 216; y: 18; width: 80; height: 14; radius: 6
                color: card.pressed("rb") ? card.cLit : card.cOff
            }

            // body
            Rectangle {
                x: 10; y: 36; width: 320; height: 150; radius: 72
                color: card.cBody
                border.width: 2
                border.color: "#66ffffff"
            }

            Stick {
                x: 58; y: 56
                sx: card.axis("lx"); sy: card.axis("ly"); on: card.pressed("ls")
            }
            Item {
                x: 112; y: 112; width: 72; height: 72
                Rectangle { x: 24; y: 0; width: 24; height: 28; radius: 5; color: card.pressed("up") ? card.cLit : card.cOff }
                Rectangle { x: 24; y: 44; width: 24; height: 28; radius: 5; color: card.pressed("down") ? card.cLit : card.cOff }
                Rectangle { x: 0; y: 24; width: 28; height: 24; radius: 5; color: card.pressed("left") ? card.cLit : card.cOff }
                Rectangle { x: 44; y: 24; width: 28; height: 24; radius: 5; color: card.pressed("right") ? card.cLit : card.cOff }
            }
            Stick {
                x: 182; y: 112
                sx: card.axis("rx"); sy: card.axis("ry"); on: card.pressed("rs")
            }
            Item {
                x: 236; y: 54; width: 70; height: 70
                Lamp { x: 22; y: 44; label: "A"; on: card.pressed("a") }
                Lamp { x: 44; y: 22; label: "B"; on: card.pressed("b") }
                Lamp { x: 0; y: 22; label: "X"; on: card.pressed("x") }
                Lamp { x: 22; y: 0; label: "Y"; on: card.pressed("y") }
            }

            Lamp { x: 133; y: 62; width: 20; height: 20; on: card.pressed("back") }
            Lamp { x: 187; y: 62; width: 20; height: 20; on: card.pressed("start") }
            Lamp { x: 155; y: 50; width: 30; height: 30; on: card.pressed("guide") }
        }
    }

    // title and subtitle
    Label {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10
        text: card.info ? card.info.description : qsTr("No Controller Connected")
        font.pixelSize: 24
        font.bold: true
    }
    Label {
        Layout.alignment: Qt.AlignHCenter
        text: card.info ? card.info.name : qsTr("Connect an Xbox, PlayStation or other game controller.")
        font.pixelSize: 12
        color: "#99ffffff"
    }

    // grouped rows
    Rectangle {
        visible: card.info !== null
        Layout.fillWidth: true
        Layout.topMargin: 14
        Layout.preferredHeight: rows.implicitHeight
        radius: 10
        color: "#333337"

        ColumnLayout {
            id: rows
            anchors { left: parent.left; right: parent.right }
            spacing: 0

            InfoRow {
                label: qsTr("Connection")
                Label { text: card.info ? card.info.connection : ""; font.pixelSize: 13; color: "#b3ffffff" }
            }
            Rectangle { Layout.fillWidth: true; Layout.leftMargin: 16; Layout.preferredHeight: 1; color: "#1fffffff" }
            InfoRow {
                label: qsTr("Battery")
                Row {
                    spacing: 2
                    Repeater {
                        model: 4
                        Rectangle {
                            width: 8
                            height: 14
                            radius: 2
                            readonly property int level: card.info ? card.info.battery : -1
                            color: index < level ? "#30d158" : card.cOff
                        }
                    }
                }
                Label { text: card.info ? card.info.batteryText : ""; font.pixelSize: 13; color: "#b3ffffff" }
            }
            Rectangle {
                visible: card.info !== null && (card.info.hasPaddles || card.info.hasTouchpad)
                Layout.fillWidth: true; Layout.leftMargin: 16; Layout.preferredHeight: 1; color: "#1fffffff"
            }
            InfoRow {
                visible: card.info !== null && (card.info.hasPaddles || card.info.hasTouchpad)
                label: qsTr("Extra buttons")
                Pill { visible: card.info !== null && card.info.hasPaddles; label: "P1"; on: card.pressed("p1") }
                Pill { visible: card.info !== null && card.info.hasPaddles; label: "P2"; on: card.pressed("p2") }
                Pill { visible: card.info !== null && card.info.hasPaddles; label: "P3"; on: card.pressed("p3") }
                Pill { visible: card.info !== null && card.info.hasPaddles; label: "P4"; on: card.pressed("p4") }
                Pill { visible: card.info !== null && card.info.hasTouchpad; label: qsTr("Pad"); on: card.pressed("touchpad") }
            }
        }
    }

    Label {
        visible: card.info !== null
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 4
        text: qsTr("Press buttons and move the sticks to test the controller.")
        font.pixelSize: 11
        color: "#99ffffff"
    }
}
