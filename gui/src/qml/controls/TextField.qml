import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

TextField {
    id: control
    property bool firstInFocusChain: false
    property bool lastInFocusChain: false
    property bool sendOutput: false
    readOnly: true

    implicitHeight: 30
    topPadding: 4
    bottomPadding: 4
    leftPadding: 10
    rightPadding: 10
    background: Rectangle {
        radius: 7
        color: control.readOnly ? "#26ffffff" : "#33ffffff"
        border.width: control.activeFocus ? 2 : 0
        border.color: "#0a84ff"
    }

    onActiveFocusChanged: {
        if (!activeFocus)
            readOnly = true;
    }

    Keys.onPressed: (event) => {
        switch (event.key) {
        case Qt.Key_Up:
            if (!firstInFocusChain && readOnly) {
                let item = nextItemInFocusChain(false);
                if (item)
                    item.forceActiveFocus(Qt.TabFocusReason);
                if(!sendOutput)
                    event.accepted = true;
            }
            break;
        case Qt.Key_Down:
            if (!lastInFocusChain && readOnly) {
                let item = nextItemInFocusChain();
                if (item)
                    item.forceActiveFocus(Qt.TabFocusReason);
                if(!sendOutput)
                    event.accepted = true;
            }
            break;
        case Qt.Key_Return:
            if (readOnly) {
                readOnly = false;
                Qt.inputMethod.show();
                event.accepted = true;
            } else {
                readOnly = true;
            }
            break;
        case Qt.Key_Escape:
            if (!readOnly) {
                readOnly = true;
                editingFinished();
                event.accepted = true;
            }
            break;
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: parent.readOnly
        onClicked: {
            parent.forceActiveFocus(Qt.TabFocusReason);
            parent.readOnly = false;
            Qt.inputMethod.show();
        }
    }
}
