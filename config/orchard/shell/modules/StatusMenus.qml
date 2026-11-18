import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import "../services"
import "../components"

// Menu-bar extras: Wi-Fi, Battery, Sound output, Now Playing.
Item {
    id: root
    property string which: Shell.popup
    implicitWidth: loader.item ? loader.item.implicitWidth : 0
    implicitHeight: loader.item ? loader.item.implicitHeight : 0

    Loader {
        id: loader
        sourceComponent: root.which === "wifi" ? wifi : root.which === "battery" ? battery
                       : root.which === "sound" ? sound : root.which === "nowplaying" ? nowplaying : null
    }

    component Heading: Text {
        color: Theme.label; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Bold
        renderType: Text.NativeRendering
    }
    component Caption: Text {
        color: Theme.secondary; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold
        renderType: Text.NativeRendering
    }
    component Row2: Rectangle {
        id: r2
        property alias text: t.text
        property bool active: false
        signal clicked()
        default property alias tailItems: tail.data
        Layout.fillWidth: true
        implicitHeight: 28; radius: 6
        color: h.containsMouse ? Theme.hover : "transparent"
        Text {
            id: t; x: 8; anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 60; elide: Text.ElideRight
            color: Theme.label; font.family: Theme.font; font.pixelSize: 13
            font.weight: r2.active ? Font.DemiBold : Font.Normal
            renderType: Text.NativeRendering
        }
        Row { id: tail; anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter } spacing: 6 }
        MouseArea { id: h; anchors.fill: parent; hoverEnabled: true; onClicked: r2.clicked() }
    }
    component Footer: Row2 { }

    // ------------------------------------------------------------------ Wi-Fi
    Component {
        id: wifi
        Glass {
            id: w
            radius: Theme.menuRadius + 2; tint: Theme.glassThick
            implicitWidth: 290
            implicitHeight: c.implicitHeight + 16
            property var pending: null
            Component.onCompleted: Net.setScanning(true)
            Component.onDestruction: Net.setScanning(false)
            ColumnLayout {
                id: c
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                spacing: 2
                RowLayout {
                    Layout.fillWidth: true; Layout.margins: 6
                    Heading { text: "Wi-Fi"; Layout.fillWidth: true }
                    Switch { checked: Networking.wifiEnabled; onToggled: Net.toggle() }
                }
                Caption { visible: Networking.wifiEnabled; text: "Known Networks"; Layout.leftMargin: 8; Layout.topMargin: 4 }
                Repeater {
                    model: Networking.wifiEnabled ? Net.networks.filter(n => n.known).slice(0, 5) : []
                    Row2 {
                        required property var modelData
                        text: modelData.name; active: modelData.connected
                        onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                        Sym { name: "lock"; size: 11; color: Theme.secondary; visible: modelData.security !== WifiSecurityType.Open }
                        Sym { size: 15; weight: 1.9; color: modelData.connected ? Theme.accent : Theme.label
                              name: modelData.signalStrength > 0.66 ? "wifi3" : modelData.signalStrength > 0.33 ? "wifi2" : "wifi1" }
                    }
                }
                Caption { visible: Networking.wifiEnabled; text: "Other Networks"; Layout.leftMargin: 8; Layout.topMargin: 6 }
                Repeater {
                    model: Networking.wifiEnabled ? Net.networks.filter(n => !n.known && n.name).slice(0, 7) : []
                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true; spacing: 2
                        Row2 {
                            text: modelData.name
                            onClicked: {
                                if (modelData.security === WifiSecurityType.Open) modelData.connect()
                                else w.pending = w.pending === modelData ? null : modelData
                            }
                            Sym { name: "lock"; size: 11; color: Theme.secondary; visible: modelData.security !== WifiSecurityType.Open }
                            Sym { size: 15; weight: 1.9; color: Theme.label
                                  name: modelData.signalStrength > 0.66 ? "wifi3" : modelData.signalStrength > 0.33 ? "wifi2" : "wifi1" }
                        }
                        Rectangle {
                            visible: w.pending === modelData
                            Layout.fillWidth: true; Layout.leftMargin: 8; Layout.rightMargin: 8
                            implicitHeight: 28; radius: 7
                            color: Theme.dark ? Qt.rgba(1, 1, 1, 0.08) : "white"
                            border.width: 1; border.color: Theme.accent
                            TextInput {
                                id: pw
                                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                verticalAlignment: TextInput.AlignVCenter
                                echoMode: TextInput.Password
                                color: Theme.label; font.family: Theme.font; font.pixelSize: 13
                                focus: parent.visible
                                onAccepted: { modelData.connectWithPsk(text); w.pending = null; Shell.popup = "" }
                                Text { visible: !pw.text; text: "Password"; color: Theme.tertiary; font: pw.font; anchors.verticalCenter: parent.verticalCenter }
                            }
                        }
                    }
                }
                Rectangle { Layout.fillWidth: true; Layout.topMargin: 4; Layout.bottomMargin: 4; implicitHeight: 1; color: Theme.separator }
                Row2 { text: "Wi-Fi Settings…"; onClicked: { Shell.popup = ""; Quickshell.execDetached(["nm-connection-editor"]) } }
            }
        }
    }

    // ---------------------------------------------------------------- Battery
    Component {
        id: battery
        Glass {
            radius: Theme.menuRadius + 2; tint: Theme.glassThick
            implicitWidth: 270
            implicitHeight: c2.implicitHeight + 20
            readonly property var dev: UPower.displayDevice
            function hm(s) { if (!s || s <= 0) return ""; const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60); return h + ":" + (m < 10 ? "0" : "") + m }
            ColumnLayout {
                id: c2
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                spacing: 4
                RowLayout {
                    Layout.fillWidth: true; Layout.margins: 4
                    Heading { text: "Battery"; Layout.fillWidth: true }
                    Text { text: Math.round(dev.percentage * 100) + "%"; color: Theme.secondary; font.family: Theme.font; font.pixelSize: 13 }
                }
                Caption {
                    Layout.leftMargin: 4
                    text: "Power Source: " + (UPower.onBattery ? "Battery" : "Power Adapter")
                }
                Caption {
                    Layout.leftMargin: 4
                    visible: text !== ""
                    text: dev.state === UPowerDeviceState.Charging && dev.timeToFull > 0 ? hm(dev.timeToFull) + " until full"
                        : dev.state === UPowerDeviceState.FullyCharged ? "Fully Charged"
                        : UPower.onBattery && dev.timeToEmpty > 0 ? hm(dev.timeToEmpty) + " remaining" : ""
                }
                Caption {
                    Layout.leftMargin: 4
                    visible: dev.healthSupported
                    text: "Battery Health: " + Math.round(dev.healthPercentage) + "%"
                }
                Rectangle { Layout.fillWidth: true; Layout.topMargin: 4; Layout.bottomMargin: 2; implicitHeight: 1; color: Theme.separator }
                Caption { text: "Energy Mode"; Layout.leftMargin: 4 }
                Repeater {
                    model: [["Low Power", PowerProfile.PowerSaver], ["Automatic", PowerProfile.Balanced], ["High Power", PowerProfile.Performance]]
                    Row2 {
                        required property var modelData
                        visible: modelData[1] !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                        text: modelData[0]
                        active: PowerProfiles.profile === modelData[1]
                        onClicked: PowerProfiles.profile = modelData[1]
                        Sym { name: "check"; size: 13; weight: 2.2; color: Theme.accent; visible: PowerProfiles.profile === modelData[1] }
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------------ Sound
    Component {
        id: sound
        Glass {
            radius: Theme.menuRadius + 2; tint: Theme.glassThick
            implicitWidth: 300
            implicitHeight: c3.implicitHeight + 20
            ColumnLayout {
                id: c3
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                spacing: 4
                Heading { text: "Sound"; Layout.margins: 4 }
                CCSlider {
                    Layout.fillWidth: true; Layout.margins: 4
                    icon: Audio.muted ? "mute" : "speaker"; value: Audio.muted ? 0 : Audio.volume
                    onMoved: v => Audio.setVolume(v)
                }
                Caption { text: "Output"; Layout.leftMargin: 4; Layout.topMargin: 4 }
                Repeater {
                    model: Audio.sinks
                    Row2 {
                        required property var modelData
                        text: modelData.description || modelData.nickname || modelData.name
                        active: Audio.sink === modelData
                        onClicked: Audio.use(modelData)
                        Sym { name: "check"; size: 13; weight: 2.2; color: Theme.accent; visible: Audio.sink === modelData }
                    }
                }
                Rectangle { Layout.fillWidth: true; Layout.topMargin: 4; Layout.bottomMargin: 2; implicitHeight: 1; color: Theme.separator }
                Row2 { text: "Sound Settings…"; onClicked: { Shell.popup = ""; Quickshell.execDetached(["pavucontrol"]) } }
            }
        }
    }

    // ------------------------------------------------------------ Now Playing
    Component {
        id: nowplaying
        Glass {
            radius: Theme.menuRadius + 4; tint: Theme.glassThick
            implicitWidth: 320
            implicitHeight: c4.implicitHeight + 24
            readonly property var p: Mpris.players.values.find(x => x.isPlaying) ?? Mpris.players.values[0] ?? null
            ColumnLayout {
                id: c4
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 10
                NowPlayingRow { Layout.fillWidth: true; player: p }
                Rectangle {
                    visible: p && p.lengthSupported && p.length > 0
                    Layout.fillWidth: true; implicitHeight: 4; radius: 2
                    color: Theme.dark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)
                    Rectangle {
                        height: parent.height; radius: 2; color: Theme.secondary
                        width: p && p.length > 0 ? parent.width * Math.min(1, p.position / p.length) : 0
                    }
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -6
                        onClicked: m => { if (p.canSeek) p.position = p.length * m.x / width }
                    }
                    Timer { running: parent.visible; interval: 1000; repeat: true; onTriggered: p.positionChanged() }
                }
                Caption { text: p ? p.identity : ""; Layout.alignment: Qt.AlignRight }
            }
        }
    }
}
