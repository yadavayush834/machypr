import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
import Quickshell.Networking
import "../services"
import "../components"

// The macOS 26 menu bar: transparent over the wallpaper, Apple menu, bold
// app name and its menus on the left; status items and clock on the right.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "orchard-bar"
    WlrLayershell.layer: WlrLayer.Top

    // Hidden with fullscreen apps, like macOS (reveals at the top edge).
    visible: !(Hypr.active && Hypr.active.fullscreen === 2) && !Shell.mission && !Shell.launchpad

    // faint scrim keeps white text legible over bright wallpapers
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Settings.barOnLight ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.22) }
            GradientStop { position: 1; color: "transparent" }
        }
    }
    MouseArea { anchors.fill: parent; onPressed: Shell.popup = "" }

    Item {
        id: content
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: !Settings.barOnLight
            shadowColor: Qt.rgba(0, 0, 0, 0.45)
            shadowBlur: 0.35
            shadowVerticalOffset: 0.5
            shadowHorizontalOffset: 0
        }

        // ------------------------------------------------------------ left
        Row {
            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: 0

            BarButton {
                menu: "apple"
                pad: 11
                Text {
                    text: ""
                    color: Theme.barText
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -1
                }
            }
            BarButton { menu: "app"; bold: true; text: Hypr.activeClass ? Apps.name(Hypr.activeClass) : "Finder" }
            Repeater {
                model: ["File", "Edit", "View", "Window", "Help"]
                BarButton { required property string modelData; menu: modelData; text: modelData }
            }
        }

        // ----------------------------------------------------------- right
        Row {
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: 0
            layoutDirection: Qt.LeftToRight

            // third-party status items (StatusNotifier tray)
            Repeater {
                model: SystemTray.items
                BarButton {
                    id: trayItem
                    required property var modelData
                    pad: 6
                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        source: trayItem.modelData.icon
                        sourceSize: Qt.size(16, 16)
                        width: 16; height: 16
                        smooth: true
                    }
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton || trayItem.modelData.onlyMenu) {
                            if (trayItem.modelData.hasMenu) {
                                const p = trayItem.mapToItem(null, 0, trayItem.height)
                                trayItem.modelData.display(bar, p.x, p.y)
                            }
                        } else trayItem.modelData.activate()
                    }
                }
            }

            // Now Playing appears while something plays (macOS 26 menu extra)
            BarButton {
                menu: "nowplaying"
                visible: Mpris.players.values.some(p => p.isPlaying)
                pad: 8
                Sym { name: "music"; size: 15; color: Theme.barText; anchors.verticalCenter: parent.verticalCenter }
            }

            BarButton {
                visible: Settings.focusMode
                menu: "control"
                pad: 7
                Sym { name: "moon"; size: 15; color: Theme.barText; filled: true; anchors.verticalCenter: parent.verticalCenter }
            }

            BarButton {
                menu: "battery"
                visible: UPower.displayDevice && UPower.displayDevice.isLaptopBattery
                pad: 8
                Battery { anchors.verticalCenter: parent.verticalCenter; color: Theme.barText }
            }

            BarButton {
                menu: "wifi"
                pad: 8
                Sym {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 16; color: Theme.barText; weight: 1.9
                    name: Net.wired ? "ethernet" : !Networking.wifiEnabled ? "wifioff"
                          : Net.strength > 0.66 ? "wifi3" : Net.strength > 0.33 ? "wifi2" : Net.strength > 0 ? "wifi1" : "wifioff"
                    opacity: Net.connected || !Networking.wifiEnabled ? 1 : 0.45
                }
            }

            BarButton {
                pad: 8
                Sym { name: "search"; size: 15; color: Theme.barText; weight: 2; anchors.verticalCenter: parent.verticalCenter }
                onClicked: Shell.open("spotlight")
            }

            BarButton {
                menu: "control"
                pad: 8
                Sym { name: "control"; size: 16; color: Theme.barText; weight: 1.6; anchors.verticalCenter: parent.verticalCenter }
            }

            BarButton {
                menu: "notifications"
                pad: 9
                text: Qt.formatDateTime(clock.date, "ddd d MMM") + "   " + Qt.formatDateTime(clock.date, "h:mm AP")
            }
        }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }
}
