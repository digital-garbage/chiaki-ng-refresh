import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

ComboBox {
    id: control
    property bool firstInFocusChain: false
    property bool lastInFocusChain: false
    implicitContentWidthPolicy: ComboBox.WidestText

    // width = widest entry + room for the chevron capsule (the stock policy ignores our custom content)
    FontMetrics { id: fm; font: control.font }
    readonly property real widestText: {
        control.count; control.model; control.font.pixelSize;
        let w = 0;
        for (let i = 0; i < control.count; i++) {
            w = Math.max(w, fm.advanceWidth(control.textAt(i)));
        }
        return w;
    }
    implicitWidth: widestText + leftPadding + rightPadding
    implicitHeight: 32
    leftPadding: 10
    rightPadding: 36
    topPadding: 0
    bottomPadding: 0
    font.pixelSize: 13

    contentItem: Label {
        text: control.displayText
        font: control.font
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: 7
        color: control.pressed ? "#40ffffff" : (control.hovered ? "#2effffff" : "#26ffffff")
        border.width: control.visualFocus ? 2 : 0
        border.color: "#0a84ff"
    }

    // round up/down chevron capsule, as in macOS pop-up buttons
    indicator: Rectangle {
        x: control.width - width - 5
        y: (control.height - height) / 2
        width: 22
        height: 22
        radius: 11
        color: "#26ffffff"
        Canvas {
            anchors.centerIn: parent
            width: 10
            height: 12
            onPaint: {
                var c = getContext("2d");
                c.reset();
                c.strokeStyle = "#ffffff";
                c.lineWidth = 1.5;
                c.lineCap = "round";
                c.lineJoin = "round";
                c.beginPath();
                c.moveTo(1.5, 4.5); c.lineTo(5, 1.5); c.lineTo(8.5, 4.5);
                c.moveTo(1.5, 7.5); c.lineTo(5, 10.5); c.lineTo(8.5, 7.5);
                c.stroke();
            }
        }
    }

    delegate: ItemDelegate {
        id: item
        required property int index
        width: ListView.view ? ListView.view.width : control.width
        height: 28
        padding: 0
        highlighted: control.highlightedIndex === index
        contentItem: Row {
            spacing: 6
            leftPadding: 6
            Label {
                width: 18
                anchors.verticalCenter: parent.verticalCenter
                text: "\u2713"
                font.pixelSize: 12
                font.bold: true
                color: "#ffffff"
                visible: control.currentIndex === item.index
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: control.textAt(item.index)
                font.pixelSize: 13
                color: "#ffffff"
            }
        }
        background: Rectangle {
            radius: 6
            color: item.highlighted ? "#0a84ff" : "transparent"
        }
    }

    popup: Popup {
        // macOS pop-up: the menu opens over the control, current item lined up with it
        y: -(Math.max(control.currentIndex, 0) * 28) - 6 + (control.height - 28) / 2
        margins: 8
        width: control.width
        implicitHeight: Math.min(contentItem.implicitHeight + 12, 360)
        padding: 6
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            spacing: 0
        }
        background: Rectangle {
            radius: 12
            color: "#2b2b2f"
            border.width: 1
            border.color: "#33ffffff"
        }
    }

    Keys.onPressed: (event) => {
        switch (event.key) {
        case Qt.Key_Up:
            if (!popup.visible) {
                let item = nextItemInFocusChain(false);
                if (!firstInFocusChain && item)
                    item.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            break;
        case Qt.Key_Down:
            if (!popup.visible) {
                let item = nextItemInFocusChain();
                if (!lastInFocusChain && item)
                    item.forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
            break;
        case Qt.Key_Return:
            if (popup.visible) {
                activated(highlightedIndex);
                popup.close();
            } else {
                popup.open();
            }
            event.accepted = true;
            break;
        }
    }

    Keys.onReleased: (event) => {
        if (event.key == Qt.Key_Return)
            event.accepted = true;
    }
}
