import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

import org.streetpea.chiaking

Pane {
    padding: 0
    id: consolePane
    StackView.visible: true  // stays visible (dimmed) behind modal sheets
    StackView.onActivated: {
        forceActiveFocus(Qt.TabFocusReason);
        if(!Chiaki.autoConnect && !root.initialAsk && !Chiaki.window.directStream)
        {
            root.initialAsk = true;
            if(Chiaki.settings.addSteamShortcutAsk && (typeof Chiaki.createSteamShortcut === "function"))
                root.showRemindDialog(qsTr("Official Steam artwork + controller layout"), qsTr("Would you like to either create a new non-Steam game for chiaki-ng\nor update an existing non-Steam game with the official artwork and controller layout?") + "\n\n" + qsTr("(Note: If you select no now and want to do this later, click the button or press R3 from the main menu.)"), false, () => root.showSteamShortcutDialog(true));
            else if(Chiaki.settings.remotePlayAsk)
            {
                if(!Chiaki.settings.psnRefreshToken || !Chiaki.settings.psnAuthToken || !Chiaki.settings.psnAuthTokenExpiry || !Chiaki.settings.psnAccountId)
                    root.showRemindDialog(qsTr("Remote Play via PSN"), qsTr("Would you like to connect to PSN?\nThis enables:\n- Automatic registration\n- Playing outside of your home network without port forwarding?") + "\n\n" + qsTr("(Note: If you select no now and want to do this later, go to the Config section of the settings.)"), true, () => root.showPSNTokenDialog(false));
                else
                    Chiaki.settings.remotePlayAsk = false;
            }
        }
    }
    Keys.onUpPressed: {
        if(hostsView.currentItem && hostsView.currentItem.visible)
        {
            hostsView.decrementCurrentIndex()
            while(!hostsView.currentItem.visible)
                hostsView.decrementCurrentIndex()
        }
    }
    Keys.onDownPressed: {
        if(hostsView.currentItem && hostsView.currentItem.visible)
        {
            hostsView.incrementCurrentIndex()
            while(!hostsView.currentItem.visible)
                 hostsView.incrementCurrentIndex()
        }
    }
    Keys.onMenuPressed: settingsButton.clicked()
    Keys.onReturnPressed: if (hostsView.currentItem) hostsView.currentItem.connectToHost()
    Keys.onYesPressed: if (hostsView.currentItem) hostsView.currentItem.wakeUpHost()
    Keys.onNoPressed: if (hostsView.currentItem) hostsView.currentItem.deleteHost()
    Keys.onEscapePressed: root.showConfirmDialog(qsTr("Quit"), qsTr("Are you sure you want to quit?"), () => Qt.quit())
    Keys.onPressed: (event) => {
        if (event.modifiers)
            return;
        switch (event.key) {
        case Qt.Key_PageUp:
            if (hostsView.currentItem) hostsView.currentItem.setConsolePin();
            event.accepted = true;
            break;
        case Qt.Key_PageDown:
            if (Chiaki.settings.psnAuthToken) Chiaki.refreshPsnToken();
            event.accepted = true;
            break;
        case Qt.Key_F1:
            if (typeof Chiaki.createSteamShortcut === "function") root.showSteamShortcutDialog(false);
            event.accepted = true;
            break;
        case Qt.Key_F2:
            root.showManualHostDialog();
            event.accepted = true;
            break;
        }
    }

    // ---- visual layer: macOS System Settings idiom (sidebar + grouped detail, dark appearance) ----
    readonly property color cWindow: "#1e1e1e"
    readonly property color cSidebar: "#252528"
    readonly property color cGroup: "#2a2a2c"
    readonly property color cSeparator: "#1fffffff"
    readonly property color cLabel: "#ffffff"
    readonly property color cSecondary: "#99ffffff"
    readonly property color cAccent: "#0a84ff"
    readonly property color cGreen: "#30d158"
    readonly property color cOrange: "#ff9f0a"
    readonly property color cGray: "#98989d"

    readonly property var current: hostsView.currentItem && hostsView.currentItem.visible ? hostsView.currentItem : null
    readonly property var cur: current ? current.host : null

    background: Rectangle { color: consolePane.cWindow }

    // Standard macOS button: bordered, 8pt radius. prominent = default (accent) button.
    component MacButton: Button {
        id: btn
        property bool prominent: false
        property url glyph
        flat: true
        focusPolicy: Qt.NoFocus
        implicitHeight: 28
        leftPadding: 14
        rightPadding: 14
        font.pixelSize: 13
        contentItem: Row {
            spacing: 6
            Image {
                visible: btn.glyph.toString() !== ""
                source: btn.glyph
                width: 16; height: 16
                sourceSize: Qt.size(16, 16)
                anchors.verticalCenter: parent.verticalCenter
            }
            Label {
                visible: btn.text !== ""
                text: btn.text
                font: btn.font
                color: consolePane.cLabel
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        background: Rectangle {
            radius: 7
            color: btn.prominent ? (btn.down ? "#0060d0" : consolePane.cAccent)
                                 : (btn.down ? "#40ffffff" : (btn.hovered ? "#2effffff" : "#26ffffff"))
            Behavior on color { ColorAnimation { duration: 100 } }
        }
        ToolTip.visible: hovered && ToolTip.text !== ""
        ToolTip.delay: 600
    }

    // macOS-style toggle: compact track, white thumb, accent color when on.
    component MacSwitch: Item {
        id: sw
        property bool checked: false
        signal toggled()
        implicitWidth: 38
        implicitHeight: 22
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: sw.checked ? consolePane.cAccent : "#47ffffff"
            Behavior on color { ColorAnimation { duration: 120 } }
        }
        Rectangle {
            width: 18; height: 18; radius: 9
            y: 2
            x: sw.checked ? sw.width - width - 2 : 2
            color: "#ffffff"
            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
        MouseArea { anchors.fill: parent; onClicked: sw.toggled() }
    }

    // Grouped section: bold header above a rounded container of rows.
    component Section: ColumnLayout {
        id: sec
        property string title
        default property alias rows: box.data
        spacing: 8
        Label {
            visible: sec.title !== ""
            text: sec.title
            color: consolePane.cLabel
            font.pixelSize: 15
            font.weight: Font.Bold
            leftPadding: 4
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: box.implicitHeight
            radius: 10
            color: consolePane.cGroup
            ColumnLayout {
                id: box
                anchors { left: parent.left; right: parent.right; leftMargin: 16; rightMargin: 16 }
                spacing: 0
            }
        }
    }

    // One row: label left, value (or a button) right. Separator on top unless first.
    component Row2: Item {
        id: row
        property string label
        property string value
        property bool first: false
        property color valueColor: consolePane.cSecondary
        default property alias trailing: slot.data
        Layout.fillWidth: true
        implicitHeight: 44
        Rectangle {
            visible: !row.first
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 1
            color: consolePane.cSeparator
        }
        Label {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text: row.label
            color: consolePane.cLabel
            font.pixelSize: 13
        }
        Label {
            visible: row.value !== ""
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            text: row.value
            color: row.valueColor
            font.pixelSize: 13
        }
        Row {
            id: slot
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 8
        }
    }

    // ---------------- Sidebar ----------------
    Rectangle {
        id: sidebar
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: 260
        color: consolePane.cSidebar

        Rectangle {
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            width: 1
            color: consolePane.cSeparator
        }

        Label {
            id: sidebarTitle
            anchors { left: parent.left; top: parent.top; leftMargin: 20; topMargin: 20 }
            text: qsTr("Consoles")
            color: consolePane.cLabel
            font.pixelSize: 22
            font.weight: Font.Bold
        }

        ListView {
            id: hostsView
            anchors { left: parent.left; right: parent.right; top: sidebarTitle.bottom; topMargin: 12; bottom: sidebarFooter.top }
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            keyNavigationWraps: true
            clip: true
            spacing: 2
            model: Chiaki.hosts
            onCountChanged: {
                if(!hostsView.currentItem)
                    hostsView.incrementCurrentIndex();
                if(!hostsView.currentItem)
                    return;
                if(!hostsView.currentItem.visible)
                {
                    for(var i = 0; i < hostsView.count; i++)
                    {
                        hostsView.incrementCurrentIndex()
                        if(hostsView.currentItem.visible)
                        {
                            break;
                        }
                    }
                }
            }
            delegate: ItemDelegate {
                id: delegate
                visible: modelData.display
                width: hostsView.width
                height: modelData.display ? 52 : 0
                highlighted: ListView.isCurrentItem
                padding: 0
                readonly property var host: modelData
                onClicked: hostsView.currentIndex = index
                onDoubleClicked: connectToHost()

                function connectToHost() {
                    if(modelData.discovered)
                        Chiaki.connectToHost(index, modelData.name);
                    else
                        Chiaki.connectToHost(index);
                }

                function wakeUpHost() {
                    if(!modelData.discovered && !modelData.duid)
                        Chiaki.wakeUpHost(index);
                }

                function deleteHost() {
                    if (modelData.manual)
                        root.showConfirmDialog(qsTr("Delete Console"), qsTr("Are you sure you want to delete this console?"), () => {Chiaki.deleteHost(index)});

                    else if (modelData.discovered && !modelData.registered)
                        root.showConfirmDialog(qsTr("Hide Console"), qsTr("Are you sure you want to hide this console?") + "\n\n" + qsTr("Note: You can unhide from the Consoles section of the Settings under Hidden Consoles"), () => Chiaki.hideHost(modelData.mac, modelData.name));

                }

                function setConsolePin() {
                    root.showConsolePinDialog(index);
                }

                background: Rectangle {
                    radius: 8
                    color: delegate.highlighted ? consolePane.cAccent : (delegate.hovered ? "#0dffffff" : "transparent")
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 7
                        color: "#e8e8ed"
                        Image {
                            anchors { fill: parent; margins: 3 }
                            fillMode: Image.PreserveAspectFit
                            source: "image://svg/console-ps" + (modelData.ps5 ? "5" : "4") + (modelData.state == "standby" ? "#light_standby" : "#light_on")
                            sourceSize: Qt.size(width, height)
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label {
                            Layout.fillWidth: true
                            text: modelData.name ? modelData.name : (modelData.ps5 ? "PlayStation 5" : "PlayStation 4")
                            color: "#ffffff"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                        Label {
                            Layout.fillWidth: true
                            text: modelData.duid ? qsTr("Remote via PSN")
                                  : (modelData.state === "ready" ? qsTr("Online") : (modelData.state === "standby" ? qsTr("Rest mode") : qsTr("Unavailable")))
                            color: delegate.highlighted ? "#ccffffff" : consolePane.cSecondary
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        Item {
            id: sidebarFooter
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 96

            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 10; rightMargin: 10 }
                height: 1
                color: consolePane.cSeparator
            }
            ColumnLayout {
                anchors { fill: parent; leftMargin: 20; rightMargin: 20; topMargin: 12; bottomMargin: 12 }
                spacing: 8
                MacButton {
                    Layout.fillWidth: true
                    text: qsTr("Add Console...")
                    glyph: "qrc:/icons/r3.svg"
                    onClicked: root.showManualHostDialog()
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 8
                    Label {
                        Layout.fillWidth: true
                        text: qsTr("Discover on network")
                        color: consolePane.cLabel
                        font.pixelSize: 14
                    }
                    MacSwitch {
                        checked: Chiaki.discoveryEnabled
                        onToggled: Chiaki.discoveryEnabled = !Chiaki.discoveryEnabled
                    }
                }
            }
        }
    }

    // ---------------- Detail ----------------
    Item {
        id: detail
        anchors { left: sidebar.right; right: parent.right; top: parent.top; bottom: parent.bottom }

        // toolbar: icon buttons, trailing
        Row {
            id: toolbar
            anchors { right: parent.right; top: parent.top; rightMargin: 20; topMargin: 14 }
            spacing: 8
            MacButton {
                text: qsTr("Steam Shortcut")
                glyph: "qrc:/icons/l3.svg"
                visible: typeof Chiaki.createSteamShortcut === "function"
                onClicked: root.showSteamShortcutDialog(false)
            }
            MacButton {
                text: qsTr("Refresh PSN")
                glyph: "qrc:/icons/r1.svg"
                visible: Chiaki.settings.psnAuthToken
                onClicked: Chiaki.refreshPsnToken()
            }
            MacButton {
                id: settingsButton
                text: qsTr("Settings")
                glyph: "qrc:/icons/settings-20px.svg"
                onClicked: root.showSettingsDialog()
            }
        }

        // empty state
        Column {
            anchors.centerIn: parent
            spacing: 8
            visible: !consolePane.cur
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("No Console Selected")
                color: consolePane.cLabel
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Turn on your PlayStation or put it in rest mode on the same network, or add one manually.")
                color: consolePane.cSecondary
                font.pixelSize: 13
            }
        }

        Flickable {
            id: scroller
            visible: !!consolePane.cur
            anchors { fill: parent; topMargin: 56 }
            contentWidth: width
            contentHeight: page.implicitHeight + 40
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: page
                width: Math.min(scroller.width - 64, 620)
                x: (scroller.width - width) / 2
                spacing: 24

                // hero
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: page.width
                    Layout.topMargin: 8
                    spacing: 6
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 112
                        Layout.preferredHeight: 112
                        radius: 24
                        color: "#e8e8ed"
                        Image {
                            anchors { fill: parent; margins: 12 }
                            fillMode: Image.PreserveAspectFit
                            source: consolePane.cur ? "image://svg/console-ps" + (consolePane.cur.ps5 ? "5" : "4") + (consolePane.cur.state == "standby" ? "#light_standby" : "#light_on") : ""
                            sourceSize: Qt.size(width, height)
                        }
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 10
                        text: consolePane.cur ? (consolePane.cur.name ? consolePane.cur.name : (consolePane.cur.ps5 ? "PlayStation 5" : "PlayStation 4")) : ""
                        color: consolePane.cLabel
                        font.pixelSize: 28
                        font.weight: Font.Bold
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: consolePane.cur ? (consolePane.cur.ps5 ? "PlayStation 5" : "PlayStation 4") : ""
                        color: consolePane.cSecondary
                        font.pixelSize: 13
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 12
                        spacing: 8
                        MacButton {
                            text: qsTr("Connect")
                            prominent: true
                            implicitHeight: 32
                            leftPadding: 24
                            rightPadding: 24
                            onClicked: consolePane.current.connectToHost()
                        }
                        MacButton {
                            text: qsTr("Wake Up")
                            glyph: root.controllerButton("pyramid")
                            implicitHeight: 32
                            visible: !!consolePane.cur && consolePane.cur.registered && !consolePane.cur.duid && !consolePane.cur.discovered
                            onClicked: consolePane.current.wakeUpHost()
                        }
                    }
                }

                Section {
                    Layout.fillWidth: true
                    title: qsTr("Console")
                    Row2 { first: true; label: qsTr("Name"); value: consolePane.cur && consolePane.cur.name ? consolePane.cur.name : "-" }
                    Row2 {
                        label: qsTr("Status")
                        value: !consolePane.cur ? "" : (consolePane.cur.duid ? qsTr("Remote via PSN")
                               : (consolePane.cur.state === "ready" ? qsTr("Online") : (consolePane.cur.state === "standby" ? qsTr("Rest mode") : qsTr("Unavailable"))))
                        valueColor: !consolePane.cur ? consolePane.cSecondary : (consolePane.cur.state === "ready" ? consolePane.cGreen : (consolePane.cur.state === "standby" ? consolePane.cOrange : consolePane.cSecondary))
                    }
                    Row2 {
                        label: qsTr("Address")
                        visible: !!consolePane.cur && !!consolePane.cur.address
                        value: Chiaki.settings.streamerMode ? qsTr("Hidden") : (consolePane.cur ? consolePane.cur.address : "")
                    }
                    Row2 {
                        label: qsTr("ID")
                        visible: !!consolePane.cur && !!consolePane.cur.mac
                        value: Chiaki.settings.streamerMode ? qsTr("Hidden") : (consolePane.cur ? consolePane.cur.mac : "")
                    }
                    Row2 {
                        label: qsTr("Registration")
                        value: !consolePane.cur ? "" : (consolePane.cur.registered ? qsTr("Registered")
                               : (consolePane.cur.duid && consolePane.cur.discovered ? qsTr("Automatic registration available") : qsTr("Not registered")))
                    }
                }

                Section {
                    Layout.fillWidth: true
                    visible: !!consolePane.cur && !consolePane.cur.duid && consolePane.cur.discovered && (!!consolePane.cur.app || !!consolePane.cur.titleId)
                    title: qsTr("Now Playing")
                    Row2 { first: true; label: qsTr("App"); visible: !!consolePane.cur && !!consolePane.cur.app; value: consolePane.cur ? consolePane.cur.app : "" }
                    Row2 { label: qsTr("Title ID"); visible: !!consolePane.cur && !!consolePane.cur.titleId; value: consolePane.cur ? consolePane.cur.titleId : "" }
                }

                Section {
                    Layout.fillWidth: true
                    title: qsTr("Manage")
                    Row2 {
                        first: true
                        label: qsTr("Console PIN")
                        visible: !!consolePane.cur && consolePane.cur.registered
                        MacButton { text: qsTr("Update..."); glyph: "qrc:/icons/l1.svg"; onClicked: consolePane.current.setConsolePin() }
                    }
                    Row2 {
                        label: !!consolePane.cur && consolePane.cur.manual ? qsTr("Delete this console") : qsTr("Hide this console")
                        visible: !!consolePane.cur && (consolePane.cur.manual || (consolePane.cur.discovered && !consolePane.cur.registered))
                        MacButton { text: !!consolePane.cur && consolePane.cur.manual ? qsTr("Delete...") : qsTr("Hide..."); glyph: root.controllerButton("box"); onClicked: consolePane.current.deleteHost() }
                    }
                    Row2 {
                        label: qsTr("Version")
                        value: Qt.application.version
                    }
                }
            }
        }
    }
}
