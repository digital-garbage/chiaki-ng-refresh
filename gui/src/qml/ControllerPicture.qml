import QtQuick
import QtQuick.Controls

import org.streetpea.chiaking

// Controller drawing that lights up with the live input state (ControllerInfo.state).
Item {
    id: card
    width: 340
    height: 190
    readonly property color cLit: "#0a84ff"
    readonly property color cOff: "#4a4a50"
    readonly property color cBody: "#38383c"

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
