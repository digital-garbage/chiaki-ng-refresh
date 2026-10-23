import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Button {
    id: control
    property bool firstInFocusChain: false
    property bool lastInFocusChain: false
    property bool sendOutput: false

    flat: true
    implicitHeight: 36
    leftPadding: 20
    rightPadding: 20
    topPadding: 6
    bottomPadding: 6
    font.pixelSize: 14
    background: Rectangle {
        radius: 7
        color: control.down ? "#40ffffff" : (control.hovered ? "#2effffff" : "#26ffffff")
        border.width: control.visualFocus ? 2 : 0
        border.color: "#0a84ff"
    }

    Material.background: visualFocus ? Material.accent : undefined

    Component.onDestruction: {
        if (visualFocus) {
            let item = nextItemInFocusChain();
            if (item)
                item.forceActiveFocus(Qt.TabFocusReason);
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
                clicked();
            }
            event.accepted = true;
            break;
        }
    }
}
