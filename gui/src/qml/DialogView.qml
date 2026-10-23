import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

Item {
    id: dialog
    property alias header: headerLabel.text
    property alias title: titleLabel.text
    property alias buttonText: okButton.text
    property alias buttonEnabled: okButton.enabled
    property alias buttonVisible: okButton.visible
    property Item restoreFocusItem
    default property Item mainItem: null

    signal accepted()
    signal rejected()

    function close() {
        root.closeDialog();
    }

    Keys.onEscapePressed: close()

    Keys.onMenuPressed: {
        if (okButton.enabled)
            okButton.clicked()
    }

    StackView.onDeactivating: {
        restoreFocusItem = Window.window.activeFocusItem;
    }

    StackView.onActivated: {
        if (!restoreFocusItem) {
            let item = mainItem.nextItemInFocusChain();
            if (item)
                item.forceActiveFocus(Qt.TabFocusReason);
        } else {
            restoreFocusItem.forceActiveFocus(Qt.TabFocusReason);
            restoreFocusItem = null;
        }
    }

    onMainItemChanged: {
        if (mainItem) {
            mainItem.parent = contentItem;
            mainItem.anchors.fill = contentItem;
        }
    }

    // Modal sheet (macOS idiom): dimmed backdrop, centered rounded card, Done/Cancel in the header.
    Rectangle {
        anchors.fill: parent
        color: "#99000000"
        MouseArea { anchors.fill: parent }  // swallow clicks behind the sheet
    }

    Rectangle {
        id: sheet
        anchors.centerIn: parent
        width: Math.min(parent.width - 96, 1000)
        height: Math.min(parent.height - 96, 720)
        radius: 14
        color: "#1e1e1e"
        border.width: 1
        border.color: "#2effffff"
        clip: true

        Item {
            id: toolBar
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 56

            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1
                color: "#1fffffff"
            }

            Button {
                id: backButton
                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 16 }
                height: 28
                flat: true
                focusPolicy: Qt.NoFocus
                leftPadding: 14
                rightPadding: 14
                text: okButton.visible ? qsTr("Cancel") : qsTr("Done")
                font.pixelSize: 13
                contentItem: Label {
                    text: backButton.text
                    font: backButton.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 7
                    color: okButton.visible ? (backButton.down ? "#40ffffff" : "#26ffffff") : (backButton.down ? "#0060d0" : "#0a84ff")
                }
                onClicked: {
                    dialog.rejected();
                    dialog.close();
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 1
                Label {
                    id: titleLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.bold: true
                    font.pixelSize: 15
                }
                Label {
                    id: headerLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: text !== ""
                    color: "#99ffffff"
                    font.pixelSize: 11
                }
            }

            Button {
                id: okButton
                anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 16 }
                height: 28
                flat: true
                focusPolicy: Qt.NoFocus
                leftPadding: 14
                rightPadding: 14
                font.pixelSize: 13
                contentItem: Label {
                    text: okButton.text
                    font: okButton.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    opacity: okButton.enabled ? 1.0 : 0.5
                }
                background: Rectangle {
                    radius: 7
                    color: okButton.enabled ? (okButton.down ? "#0060d0" : "#0a84ff") : "#26ffffff"
                }
                onClicked: dialog.accepted()
            }
        }

        Item {
            id: contentItem
            anchors {
                top: toolBar.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
        }
    }
}
