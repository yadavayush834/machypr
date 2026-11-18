import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import "../services"
import "../components"

// Control Center, laid out like macOS 26: connectivity block + Focus and
// Appearance on top, Display and Sound sliders, Now Playing, quick buttons.
Glass {
    id: cc
    width: 340
    implicitHeight: col.implicitHeight + 24
    radius: Theme.panelRadius

    readonly property var bt: Bluetooth.defaultAdapter
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    ColumnLayout {
        id: col
        anchors { fill: parent; margins: 12 }
        spacing: 10

        RowLayout {
            spacing: 10
            Layout.fillWidth: true

            Tile {
                Layout.preferredWidth: 154; Layout.preferredHeight: 154
                Column {
                    anchors { fill: parent; margins: 12 }
                    spacing: 13
                    RoundToggle {
                        icon: Networking.wifiEnabled ? "wifi3" : "wifioff"
                        on: Networking.wifiEnabled
                        title: "Wi-Fi"
                        subtitle: !Networking.wifiEnabled ? "Off" : Net.name || "Not Connected"
                        onClicked: Net.toggle()
                        onRightClicked: Shell.toggle("wifi")
                    }
                    RoundToggle {
                        icon: "bluetooth"
                        on: !!cc.bt && cc.bt.enabled
                        title: "Bluetooth"
                        subtitle: !cc.bt ? "Unavailable" : !cc.bt.enabled ? "Off"
                                  : (cc.bt.devices.values.filter(d => d.connected).map(d => d.name)[0] ?? "On")
                        onClicked: if (cc.bt) cc.bt.enabled = !cc.bt.enabled
                        onRightClicked: Quickshell.execDetached(["blueman-manager"])
                    }
                    RoundToggle {
                        icon: "airplane"
                        on: !Networking.wifiEnabled && !(cc.bt && cc.bt.enabled)
                        title: "Airplane Mode"
                        subtitle: on ? "On" : "Off"
                        onClicked: {
                            const goOn = !on
                            Networking.wifiEnabled = !goOn
                            if (cc.bt) cc.bt.enabled = !goOn
                        }
                    }
                }
            }

            ColumnLayout {
                spacing: 10
                Layout.fillWidth: true
                Tile {
                    Layout.fillWidth: true; Layout.preferredHeight: 72
                    RoundToggle {
                        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                        icon: "moon"; on: Settings.focusMode
                        title: "Focus"; subtitle: Settings.focusMode ? "Do Not Disturb" : "Off"
                        onClicked: Settings.focusMode = !Settings.focusMode
                    }
                }
                Tile {
                    Layout.fillWidth: true; Layout.preferredHeight: 72
                    RoundToggle {
                        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                        icon: "contrast"; on: Settings.isDark
                        title: "Dark Mode"
                        subtitle: Settings.appearance === "auto" ? "Auto" : (Settings.isDark ? "On" : "Off")
                        onClicked: Settings.appearance = Settings.isDark ? "light" : "dark"
                        onRightClicked: Settings.appearance = "auto"
                    }
                }
            }
        }

        Tile {
            Layout.fillWidth: true; Layout.preferredHeight: 68
            Column {
                anchors { fill: parent; margins: 12 }
                spacing: 9
                Text { text: "Display"; color: Theme.label; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold }
                RowLayout {
                    width: parent.width; spacing: 8
                    CCSlider {
                        Layout.fillWidth: true
                        icon: "sun"; value: Brightness.value
                        onMoved: v => Brightness.set(v)
                    }
                    RoundToggle {
                        dia: 26; icon: "nightshift"; on: Settings.nightShift
                        onClicked: Settings.nightShift = !Settings.nightShift
                    }
                }
            }
        }

        Tile {
            Layout.fillWidth: true; Layout.preferredHeight: 68
            Column {
                anchors { fill: parent; margins: 12 }
                spacing: 9
                RowLayout {
                    width: parent.width
                    Text { text: "Sound"; color: Theme.label; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: Audio.device; color: Theme.secondary; elide: Text.ElideRight
                        Layout.maximumWidth: 180
                        font.family: Theme.font; font.pixelSize: 11
                    }
                }
                RowLayout {
                    width: parent.width; spacing: 8
                    CCSlider {
                        Layout.fillWidth: true
                        icon: Audio.muted || Audio.volume === 0 ? "mute" : "speaker"
                        value: Audio.muted ? 0 : Audio.volume
                        onMoved: v => Audio.setVolume(v)
                    }
                    RoundToggle {
                        dia: 26; icon: "chevron"; on: false
                        onClicked: Shell.toggle("sound")
                    }
                }
            }
        }

        Tile {
            visible: cc.player !== null
            Layout.fillWidth: true; Layout.preferredHeight: 70
            NowPlayingRow { anchors { fill: parent; margins: 10 } player: cc.player }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Repeater {
                model: [
                    { icon: "camera", title: "Screenshot", on: false, run: () => { Shell.closeAll(); Shell.shotMenu = true } },
                    { icon: "bolt", title: "Low Power", on: PowerProfiles.profile === PowerProfile.PowerSaver,
                      run: () => PowerProfiles.profile = PowerProfiles.profile === PowerProfile.PowerSaver ? PowerProfile.Balanced : PowerProfile.PowerSaver },
                    { icon: "eye", title: "Caffeinate", on: Caffeine.on, run: () => Caffeine.on = !Caffeine.on },
                    { icon: "lock", title: "Lock", on: false, run: () => { Shell.closeAll(); Quickshell.execDetached(["loginctl", "lock-session"]) } },
                ]
                Tile {
                    required property var modelData
                    Layout.fillWidth: true; Layout.preferredHeight: 70
                    RoundToggle {
                        anchors.centerIn: parent
                        vertical: true; dia: 32
                        icon: parent.modelData.icon; title: parent.modelData.title; on: parent.modelData.on
                        onClicked: parent.modelData.run()
                    }
                }
            }
        }
    }
}
