import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

import org.streetpea.chiaking

import "controls" as C

// Modal controller test: while open the controller does not navigate the UI,
// L1 + R1 + B (O on PlayStation, A on Nintendo: the same east button) or the Close button ends it.
Popup {
    id: dlg
    property var info: ControllerInfo.controllers[ControllerInfo.current] || null
    readonly property string closeButtonName: info && (info.kind === "ps4" || info.kind === "ps5") ? qsTr("O") : (info && info.kind === "switch" ? qsTr("A") : qsTr("B"))

    parent: Overlay.overlay
    x: Math.round((root.width - width) / 2)
    y: Math.round((root.height - height) / 2)
    width: 560
    height: content.implicitHeight + 56
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape
    padding: 28

    onOpened: {
        ControllerInfo.active = true;
        ControllerInfo.suspendUi = true;
    }
    onClosed: {
        ControllerInfo.suspendUi = false;
        ControllerInfo.active = false;
    }

    Connections {
        target: ControllerInfo
        function onCloseComboPressed() {
            if (dlg.opened)
                dlg.close();
        }
    }

    background: Rectangle {
        radius: 14
        color: "#1e1e1e"
        border.width: 1
        border.color: "#26ffffff"
    }

    component Pill: Rectangle {
        id: pill
        property bool on: false
        property string label: ""
        implicitWidth: 52
        implicitHeight: 26
        radius: 7
        color: on ? "#0a84ff" : "#4a4a50"
        Label {
            anchors.centerIn: parent
            text: pill.label
            font.pixelSize: 12
            font.bold: true
            color: pill.on ? "#ffffff" : "#b0b0b8"
        }
    }

    ColumnLayout {
        id: content
        width: parent.width
        spacing: 12

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Test Controller")
            font.pixelSize: 17
            font.bold: true
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: dlg.info ? dlg.info.description : qsTr("No Controller Connected")
            font.pixelSize: 12
            color: "#99ffffff"
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            Layout.preferredWidth: 340 * 1.4
            Layout.preferredHeight: 190 * 1.4
            visible: dlg.info !== null
            ControllerPicture {
                scale: 1.4
                transformOrigin: Item.TopLeft
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            visible: dlg.info !== null && (dlg.info.hasPaddles || dlg.info.hasTouchpad)
            Label { text: qsTr("Extra buttons"); font.pixelSize: 12; color: "#99ffffff" }
            Pill { visible: dlg.info !== null && dlg.info.hasPaddles; label: "P1"; on: !!ControllerInfo.state["p1"] }
            Pill { visible: dlg.info !== null && dlg.info.hasPaddles; label: "P2"; on: !!ControllerInfo.state["p3"] }
            Pill { visible: dlg.info !== null && dlg.info.hasPaddles; label: "P3"; on: !!ControllerInfo.state["p2"] }
            Pill { visible: dlg.info !== null && dlg.info.hasPaddles; label: "P4"; on: !!ControllerInfo.state["p4"] }
            Pill { visible: dlg.info !== null && dlg.info.hasTouchpad; label: qsTr("Pad"); on: !!ControllerInfo.state["touchpad"] }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            text: qsTr("Press buttons and move the sticks. Hold L1 + R1 + %1 to close.").arg(dlg.closeButtonName)
            font.pixelSize: 12
            color: "#99ffffff"
        }

        C.Button {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 120
            text: qsTr("Close")
            onClicked: dlg.close()
        }
    }
}
