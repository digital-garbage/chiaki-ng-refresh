import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

CheckBox {
    id: control
    property bool firstInFocusChain: false
    property bool lastInFocusChain: false
    property bool sendOutput: false

    spacing: 8
    implicitHeight: 28
    topPadding: 2
    bottomPadding: 2
    indicator: Rectangle {
        implicitWidth: 18
        implicitHeight: 18
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        radius: 5
        color: control.checked ? "#0a84ff" : "#26ffffff"
        border.width: control.visualFocus ? 2 : 1
        border.color: control.visualFocus ? "#0a84ff" : "#33ffffff"
        Label {
            anchors.centerIn: parent
            visible: control.checked
            text: "\u2713"
            color: "#ffffff"
            font.pixelSize: 12
            font.bold: true
        }
    }

    Keys.onPressed: (event) => {
        switch (event.key) {
        case Qt.Key_Up:
            if (!firstInFocusChain) {
                let item = nextItemInFocusChain(false);
                if (item)
                    item.forceActiveFocus(Qt.TabFocusReason);
                if(!sendOutput)
                    event.accepted = true;
            }
            break;
        case Qt.Key_Down:
            if (!lastInFocusChain) {
                let item = nextItemInFocusChain();
                if (item)
                    item.forceActiveFocus(Qt.TabFocusReason);
                if(!sendOutput)
                    event.accepted = true;
            }
            break;
        case Qt.Key_Return:
            if (visualFocus) {
                toggle();
                clicked();
            }
            event.accepted = true;
            break;
        }
    }
}
