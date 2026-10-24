import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

import org.streetpea.chiaking

// In-stream menu: a compact floating card with status (stream, battery of the controller and of this
// device, clock) and the stream controls. Used by StreamMenuWindow and the inline menu in StreamView.
Item {
    id: menu
    property Item initialFocusItem: closeButton
    readonly property var pad: ControllerInfo.controllers.length ? ControllerInfo.controllers[0] : null
    readonly property color cDim: "#99ffffff"

    signal closeRequested()
    signal displaySettingsRequested()
    signal placeboSettingsRequested()
    signal mainViewRequested()

    function focusInitialItem() {
        closeButton.forceActiveFocus(Qt.TabFocusReason);
    }

    onVisibleChanged: {
        if (visible) {
            ControllerInfo.refresh();
            SystemStatus.refresh();
            clock.now = new Date();
        }
    }

    Timer {
        id: clock
        property date now: new Date()
        interval: 1000
        running: menu.visible
        repeat: true
        onTriggered: now = new Date()
    }

    component Stat: RowLayout {
        property string value: ""
        property string unit: ""
        property color valueColor: Material.accent
        spacing: 4
        Label {
            text: parent.value
            color: parent.valueColor
            font.bold: true
            font.pixelSize: 15
        }
        Label {
            text: parent.unit
            color: menu.cDim
            font.pixelSize: 11
            Layout.alignment: Qt.AlignBaseline
        }
    }

    component Battery: RowLayout {
        property string title: ""
        property int level: -1      // 0..4 segments, -1 unknown
        property string text: ""
        property bool charging: false
        spacing: 6
        Label { text: parent.title; color: menu.cDim; font.pixelSize: 11 }
        Row {
            spacing: 2
            Repeater {
                model: 4
                Rectangle {
                    width: 6
                    height: 12
                    radius: 2
                    color: index < level ? (level <= 1 ? "#ff453a" : "#30d158") : "#55ffffff"
                }
            }
        }
        Label { text: (parent.charging ? "⚡ " : "") + parent.text; font.pixelSize: 12 }
    }

    component MenuButton: ToolButton {
        padding: 8
        topPadding: 4
        bottomPadding: 4
        implicitHeight: 34
        font.pixelSize: 13
        Keys.onReturnPressed: clicked()
        Keys.onEscapePressed: menu.closeRequested()
    }

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: "#f0222225"
        border.width: 1
        border.color: "#33ffffff"
    }

    ColumnLayout {
        anchors {
            fill: parent
            leftMargin: 18
            rightMargin: 18
            topMargin: 12
            bottomMargin: 12
        }
        spacing: 8

        // status
        RowLayout {
            Layout.fillWidth: true
            spacing: 18

            Label {
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: 13
                text: {
                    if (!Chiaki.session)
                        return "";
                    const host = Chiaki.settings.streamerMode ? "hidden" : Chiaki.session.host;
                    return Chiaki.session.connected ? qsTr("Connected to <b>%1</b>").arg(host) : qsTr("Connecting to <b>%1</b>").arg(host);
                }
            }

            Stat {
                visible: Chiaki.session
                value: Chiaki.session ? Chiaki.session.measuredBitrate.toFixed(1) : ""
                unit: qsTr("Mbps")
            }
            Stat {
                visible: Chiaki.session
                readonly property real loss: Chiaki.session && isFinite(Chiaki.session.averagePacketLoss) ? Chiaki.session.averagePacketLoss * 100 : 0
                value: loss.toFixed(1)
                unit: qsTr("% loss")
                valueColor: loss > 1 ? "#ff453a" : "#ef9a9a"
            }
            Stat {
                visible: Chiaki.window.droppedFrames > 0
                value: Chiaki.window.droppedFrames
                unit: qsTr("dropped")
                valueColor: "#ef9a9a"
            }

            Battery {
                visible: menu.pad !== null
                title: qsTr("Controller")
                level: menu.pad ? menu.pad.battery : -1
                text: menu.pad ? menu.pad.batteryText : ""
                charging: menu.pad !== null && menu.pad.batteryText === qsTr("Wired")
            }
            Battery {
                visible: SystemStatus.hasBattery
                title: qsTr("This Mac")
                level: SystemStatus.hasBattery ? (SystemStatus.batteryPercent + 24) / 25 : -1
                text: SystemStatus.batteryPercent + "%"
                charging: SystemStatus.charging
            }

            ColumnLayout {
                spacing: 0
                Label {
                    Layout.alignment: Qt.AlignRight
                    text: Qt.formatTime(clock.now, Locale.ShortFormat)
                    font.pixelSize: 15
                    font.bold: true
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    text: Qt.formatDate(clock.now, "ddd d MMM")
                    color: menu.cDim
                    font.pixelSize: 11
                }
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#26ffffff" }

        // controls
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            MenuButton {
                id: closeButton
                text: Chiaki.session ? qsTr("Disconnect") : "×"
                font.bold: true
                Material.foreground: "#ff453a"
                down: activeFocus
                activeFocusOnTab: true
                onClicked: {
                    if (Chiaki.session)
                        Chiaki.window.close();
                    else
                        menu.mainViewRequested();
                }
                KeyNavigation.right: volMinus
                KeyNavigation.down: defaultButton
            }

            ToolSeparator {}

            Label { text: qsTr("Volume"); color: menu.cDim; font.pixelSize: 11; Layout.leftMargin: 4 }
            MenuButton {
                id: volMinus
                text: "−"
                autoRepeat: true
                onClicked: Chiaki.settings.audioVolume = Math.max(0, Chiaki.settings.audioVolume - 6)
                KeyNavigation.left: closeButton
                KeyNavigation.right: volPlus
                KeyNavigation.down: defaultButton
            }
            Label {
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignHCenter
                text: ((Chiaki.settings.audioVolume / 128.0) * 100).toFixed(0) + "%"
                font.pixelSize: 13
            }
            MenuButton {
                id: volPlus
                text: "+"
                autoRepeat: true
                onClicked: Chiaki.settings.audioVolume = Math.min(128, Chiaki.settings.audioVolume + 6)
                KeyNavigation.left: volMinus
                KeyNavigation.right: muteButton
                KeyNavigation.down: defaultButton
            }

            ToolSeparator {}

            MenuButton {
                id: muteButton
                text: qsTr("Mic")
                checkable: true
                enabled: Chiaki.session && Chiaki.session.connected
                checked: Chiaki.session && !Chiaki.session.muted
                onToggled: Chiaki.session.muted = !Chiaki.session.muted
                Keys.onReturnPressed: toggled()
                KeyNavigation.left: volPlus
                KeyNavigation.right: zoomButton
                KeyNavigation.down: highQualityButton
            }

            MenuButton {
                id: zoomButton
                text: qsTr("Zoom")
                checkable: true
                checked: Chiaki.window.videoMode == ChiakiWindow.VideoMode.Zoom
                onToggled: Chiaki.window.videoMode = Chiaki.window.videoMode == ChiakiWindow.VideoMode.Zoom ? ChiakiWindow.VideoMode.Normal : ChiakiWindow.VideoMode.Zoom
                Keys.onReturnPressed: toggled()
                KeyNavigation.left: muteButton
                KeyNavigation.right: Chiaki.window.videoMode == ChiakiWindow.VideoMode.Zoom ? zoomMinus : stretchButton
                KeyNavigation.down: highQualitySpatialButton
            }
            MenuButton {
                id: zoomMinus
                visible: Chiaki.window.videoMode == ChiakiWindow.VideoMode.Zoom
                text: "−"
                autoRepeat: true
                onClicked: {
                    Chiaki.window.ZoomFactor = Math.max(-1, Chiaki.window.ZoomFactor - 0.1);
                    Chiaki.settings.sZoomFactor = Chiaki.window.ZoomFactor;
                }
                KeyNavigation.left: zoomButton
                KeyNavigation.right: zoomPlus
                KeyNavigation.down: highQualitySpatialButton
            }
            Label {
                visible: Chiaki.window.videoMode == ChiakiWindow.VideoMode.Zoom
                Layout.preferredWidth: 64
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 12
                text: Chiaki.window.ZoomFactor === -1 ? qsTr("No bars") : (Chiaki.window.ZoomFactor + 1).toFixed(2) + " x"
            }
            MenuButton {
                id: zoomPlus
                visible: Chiaki.window.videoMode == ChiakiWindow.VideoMode.Zoom
                text: "+"
                autoRepeat: true
                onClicked: {
                    Chiaki.window.ZoomFactor = Math.min(4, Chiaki.window.ZoomFactor + 0.1);
                    Chiaki.settings.sZoomFactor = Chiaki.window.ZoomFactor;
                }
                KeyNavigation.left: zoomMinus
                KeyNavigation.right: stretchButton
                KeyNavigation.down: highQualitySpatialButton
            }

            MenuButton {
                id: stretchButton
                text: qsTr("Stretch")
                checkable: true
                checked: Chiaki.window.videoMode == ChiakiWindow.VideoMode.Stretch
                onToggled: Chiaki.window.videoMode = Chiaki.window.videoMode == ChiakiWindow.VideoMode.Stretch ? ChiakiWindow.VideoMode.Normal : ChiakiWindow.VideoMode.Stretch
                Keys.onReturnPressed: toggled()
                KeyNavigation.left: Chiaki.window.videoMode == ChiakiWindow.VideoMode.Zoom ? zoomPlus : zoomButton
                KeyNavigation.right: displaySettingsButton
                KeyNavigation.down: highQualityAdvancedSpatialButton
            }

            Item { Layout.fillWidth: true }

            MenuButton {
                id: displaySettingsButton
                text: qsTr("Display")
                icon.source: "qrc:/icons/settings-20px.svg"
                onClicked: menu.displaySettingsRequested()
                KeyNavigation.left: stretchButton
                KeyNavigation.right: Chiaki.window.videoPreset == ChiakiWindow.VideoPreset.Custom ? placeboSettingsButton : displaySettingsButton
                KeyNavigation.down: customButton
            }
            MenuButton {
                id: placeboSettingsButton
                text: qsTr("Placebo")
                icon.source: "qrc:/icons/settings-20px.svg"
                visible: Chiaki.window.videoPreset == ChiakiWindow.VideoPreset.Custom
                onClicked: menu.placeboSettingsRequested()
                KeyNavigation.left: displaySettingsButton
                KeyNavigation.down: customButton
            }
        }

        // quality presets
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Label { text: qsTr("Quality"); color: menu.cDim; font.pixelSize: 11; Layout.leftMargin: 4; Layout.rightMargin: 4 }

            MenuButton {
                id: defaultButton
                text: qsTr("Default")
                checkable: true
                checked: Chiaki.window.videoPreset == ChiakiWindow.VideoPreset.Default
                onToggled: {
                    Chiaki.window.videoPreset = ChiakiWindow.VideoPreset.Default
                    Chiaki.settings.videoPreset = ChiakiWindow.VideoPreset.Default
                }
                Keys.onReturnPressed: toggled()
                KeyNavigation.right: highQualityButton
                KeyNavigation.up: closeButton
                KeyNavigation.down: presetPrevButton
            }
            MenuButton {
                id: highQualityButton
                text: qsTr("High Quality")
                checkable: true
                checked: Chiaki.window.videoPreset == ChiakiWindow.VideoPreset.HighQuality
                onToggled: {
                    Chiaki.window.videoPreset = ChiakiWindow.VideoPreset.HighQuality
                    Chiaki.settings.videoPreset = ChiakiWindow.VideoPreset.HighQuality
                }
                Keys.onReturnPressed: toggled()
                KeyNavigation.left: defaultButton
                KeyNavigation.right: highQualitySpatialButton
                KeyNavigation.up: muteButton
                KeyNavigation.down: presetPrevButton
            }
            MenuButton {
                id: highQualitySpatialButton
                text: qsTr("HQ + Spatial")
                checkable: true
                checked: Chiaki.window.videoPreset == ChiakiWindow.VideoPreset.HighQualitySpatial
                onToggled: {
                    Chiaki.window.videoPreset = ChiakiWindow.VideoPreset.HighQualitySpatial
                    Chiaki.settings.videoPreset = ChiakiWindow.VideoPreset.HighQualitySpatial
                }
                Keys.onReturnPressed: toggled()
                KeyNavigation.left: highQualityButton
                KeyNavigation.right: highQualityAdvancedSpatialButton
                KeyNavigation.up: zoomButton
                KeyNavigation.down: presetPrevButton
            }
            MenuButton {
                id: highQualityAdvancedSpatialButton
                text: qsTr("HQ + Adv Spatial")
                checkable: true
                checked: Chiaki.window.videoPreset == ChiakiWindow.VideoPreset.HighQualityAdvancedSpatial
                onToggled: {
                    Chiaki.window.videoPreset = ChiakiWindow.VideoPreset.HighQualityAdvancedSpatial
                    Chiaki.settings.videoPreset = ChiakiWindow.VideoPreset.HighQualityAdvancedSpatial
                }
                Keys.onReturnPressed: toggled()
                KeyNavigation.left: highQualitySpatialButton
                KeyNavigation.right: customButton
                KeyNavigation.up: stretchButton
                KeyNavigation.down: presetPrevButton
            }
            MenuButton {
                id: customButton
                text: qsTr("Custom")
                checkable: true
                checked: Chiaki.window.videoPreset == ChiakiWindow.VideoPreset.Custom
                onToggled: {
                    Chiaki.window.videoPreset = ChiakiWindow.VideoPreset.Custom
                    Chiaki.settings.videoPreset = ChiakiWindow.VideoPreset.Custom
                }
                Keys.onReturnPressed: toggled()
                KeyNavigation.left: highQualityAdvancedSpatialButton
                KeyNavigation.up: displaySettingsButton
                KeyNavigation.down: presetNextButton
            }
            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            readonly property var presets: Chiaki.settings.inputPresets
            readonly property int presetIndex: Math.max(0, presets.indexOf(Chiaki.settings.inputPreset))
            function step(delta) {
                const list = presets;
                Chiaki.settings.selectInputPreset(list[(presetIndex + delta + list.length) % list.length]);
                if (Chiaki.session)
                    Chiaki.session.ReloadInput();
            }

            Label { text: qsTr("Input"); color: menu.cDim; font.pixelSize: 11; Layout.leftMargin: 4; Layout.rightMargin: 4 }
            MenuButton {
                id: presetPrevButton
                text: "\u2039"
                onClicked: parent.step(-1)
                KeyNavigation.right: presetNextButton
                KeyNavigation.up: defaultButton
            }
            Label {
                Layout.preferredWidth: 150
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: Chiaki.settings.inputPreset
                font.pixelSize: 13
            }
            MenuButton {
                id: presetNextButton
                text: "\u203a"
                onClicked: parent.step(1)
                KeyNavigation.left: presetPrevButton
                KeyNavigation.up: customButton
            }
            Item { Layout.fillWidth: true }
            Label { text: qsTr("Menu: \u2318O"); color: menu.cDim; font.pixelSize: 11; Layout.rightMargin: 4 }
        }
    }
}
