import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import "../services"
import "../components"

// System Settings: a normal window (it tiles, moves and closes like any
// app) with the macOS sidebar of coloured icons and grouped inset forms.
FloatingWindow {
    id: ss
    visible: Shell.settings
    title: "System Settings"
    implicitWidth: 760
    implicitHeight: 540
    color: Theme.dark ? "#1e1e20" : "#f2f2f4"
    onVisibleChanged: if (!visible) Shell.settings = false
    onClosed: Shell.settings = false

    property string page: Shell.settingsPage
    onPageChanged: Shell.settingsPage = page

    readonly property var pages: [
        { id: "wifi", title: "Wi-Fi", icon: "wifi3", tint: "#0A84FF" },
        { id: "bluetooth", title: "Bluetooth", icon: "bluetooth", tint: "#0A84FF" },
        { id: "sep" },
        { id: "notifications", title: "Notifications", icon: "bell", tint: "#FF453A" },
        { id: "sound", title: "Sound", icon: "speaker", tint: "#FF375F" },
        { id: "focus", title: "Focus", icon: "moon", tint: "#5E5CE6" },
        { id: "sep" },
        { id: "general", title: "General", icon: "gear", tint: "#8E8E93" },
        { id: "appearance", title: "Appearance", icon: "contrast", tint: "#1C1C1E" },
        { id: "desktop", title: "Desktop & Dock", icon: "display", tint: "#1C1C1E" },
        { id: "displays", title: "Displays", icon: "sun", tint: "#0A84FF" },
        { id: "wallpaper", title: "Wallpaper", icon: "app", tint: "#32ADE6" },
        { id: "battery", title: "Battery", icon: "battery", tint: "#30D158" },
        { id: "sep" },
        { id: "keyboard", title: "Keyboard", icon: "keyboard", tint: "#8E8E93" },
        { id: "lock", title: "Lock Screen", icon: "lock", tint: "#1C1C1E" },
    ]

    component Group: Rectangle {
        default property alias rows: gcol.data
        Layout.fillWidth: true
        implicitHeight: gcol.implicitHeight
        radius: 10
        color: Theme.dark ? Qt.rgba(1, 1, 1, 0.05) : "white"
        border.width: 0.5; border.color: Theme.separator
        ColumnLayout { id: gcol; anchors { left: parent.left; right: parent.right } spacing: 0 }
    }
    component FormRow: Item {
        property string label
        property string detail: ""
        default property alias control: ctl.data
        Layout.fillWidth: true
        implicitHeight: 40
        Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: parent.label; color: Theme.label; font.family: Theme.font; font.pixelSize: 13 }
        Text { visible: parent.detail !== ""; anchors { right: ctl.left; rightMargin: 10; verticalCenter: parent.verticalCenter } text: parent.detail; color: Theme.secondary; font.family: Theme.font; font.pixelSize: 13 }
        Row { id: ctl; anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter } spacing: 8 }
        Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 14 } height: 0.5; color: Theme.separator }
    }
    component H: Text { color: Theme.label; font.family: Theme.fontDisplay; font.pixelSize: 15; font.weight: Font.Bold; Layout.topMargin: 6 }
    component Seg: Row {
        id: seg
        property var options: []
        property var value
        signal picked(var v)
        spacing: 0
        Repeater {
            model: seg.options
            Rectangle {
                required property var modelData
                width: Math.max(64, st.implicitWidth + 20); height: 24; radius: 6
                color: seg.value === modelData[1] ? (Theme.dark ? Qt.rgba(1, 1, 1, 0.22) : "white") : "transparent"
                border.width: seg.value === modelData[1] ? 0.5 : 0; border.color: Theme.separator
                Text { id: st; anchors.centerIn: parent; text: parent.modelData[0]; color: Theme.label; font.family: Theme.font; font.pixelSize: 12 }
                MouseArea { anchors.fill: parent; onClicked: seg.picked(parent.modelData[1]) }
            }
        }
    }
    component Slide: Item {
        property real value
        signal moved(real v)
        width: 200; height: 20
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: Theme.separator
            Rectangle { width: parent.width * parent.parent.value; height: 4; radius: 2; color: Theme.accent } }
        Rectangle { x: (parent.width - 18) * parent.value; anchors.verticalCenter: parent.verticalCenter; width: 18; height: 18; radius: 9; color: "white"; border.width: 0.5; border.color: Qt.rgba(0, 0, 0, 0.25) }
        MouseArea {
            anchors.fill: parent
            onPressed: m => parent.moved(Math.max(0, Math.min(1, m.x / width)))
            onPositionChanged: m => { if (pressed) parent.moved(Math.max(0, Math.min(1, m.x / width))) }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ------------------------------------------------------- sidebar
        Rectangle {
            Layout.preferredWidth: 210; Layout.fillHeight: true
            color: Theme.dark ? "#262628" : "#e8e8ec"
            ColumnLayout {
                anchors { fill: parent; margins: 10; topMargin: 14 }
                spacing: 1
                RowLayout {
                    Layout.bottomMargin: 10; spacing: 10
                    Rectangle { implicitWidth: 38; implicitHeight: 38; radius: 19; color: Theme.dark ? "#3a3a3c" : "#c7c7cc"
                        Sym { anchors.centerIn: parent; name: "person"; size: 22; color: "white" } }
                    ColumnLayout { spacing: 0
                        Text { text: Quickshell.env("USER"); color: Theme.label; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold }
                        Text { text: "Local Account"; color: Theme.secondary; font.family: Theme.font; font.pixelSize: 11 } }
                }
                Repeater {
                    model: ss.pages
                    Item {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: modelData.id === "sep" ? 10 : 28
                        Rectangle {
                            visible: parent.modelData.id !== "sep"
                            anchors.fill: parent; radius: 6
                            color: ss.page === parent.modelData.id ? Theme.accent : "transparent"
                        }
                        Rectangle {
                            visible: parent.modelData.id !== "sep"
                            x: 6; anchors.verticalCenter: parent.verticalCenter
                            width: 20; height: 20; radius: 5; color: parent.modelData.tint ?? "gray"
                            Sym { anchors.centerIn: parent; name: parent.parent.modelData.icon ?? "app"; size: 13; color: "white"; weight: 2 }
                        }
                        Text {
                            visible: parent.modelData.id !== "sep"
                            x: 34; anchors.verticalCenter: parent.verticalCenter
                            text: parent.modelData.title ?? ""
                            color: ss.page === parent.modelData.id ? "white" : Theme.label
                            font.family: Theme.font; font.pixelSize: 13
                        }
                        MouseArea { anchors.fill: parent; enabled: parent.modelData.id !== "sep"; onClicked: ss.page = parent.modelData.id }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }

        // -------------------------------------------------------- content
        Flickable {
            Layout.fillWidth: true; Layout.fillHeight: true
            contentHeight: body.implicitHeight + 40
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ColumnLayout {
                id: body
                x: 24; y: 18
                width: parent.width - 48
                spacing: 10
                Text {
                    text: (ss.pages.find(p => p.id === ss.page) ?? {}).title ?? ""
                    color: Theme.label; font.family: Theme.fontDisplay; font.pixelSize: 20; font.weight: Font.Bold
                    Layout.bottomMargin: 6
                }

                // Appearance
                Group {
                    visible: ss.page === "appearance"
                    FormRow { label: "Appearance"
                        Seg { options: [["Auto", "auto"], ["Light", "light"], ["Dark", "dark"]]; value: Settings.appearance; onPicked: v => Settings.appearance = v } }
                    FormRow { label: "Reduce motion"; Switch { checked: Settings.reduceMotion; onToggled: Settings.reduceMotion = !Settings.reduceMotion } }
                    FormRow { label: "Text size"; detail: "Bigger text in apps"
                        Seg { options: [["A−", "down"], ["A+", "up"]]; value: ""; onPicked: v => Quickshell.execDetached([Settings.bin + "textsize", v]) } }
                }

                // Desktop & Dock
                Group {
                    visible: ss.page === "desktop"
                    FormRow { label: "Size"; Slide { value: (Settings.dockIconSize - 32) / 40; onMoved: v => Settings.dockIconSize = Math.round(32 + v * 40) } }
                    FormRow { label: "Magnification"; Switch { checked: Settings.dockMagnify; onToggled: Settings.dockMagnify = !Settings.dockMagnify } }
                    FormRow { label: "Automatically hide and show the Dock"; Switch { checked: Settings.dockAutohide; onToggled: Settings.dockAutohide = !Settings.dockAutohide } }
                    FormRow { label: "Hot Corners"; detail: "Mission Control · Launchpad · Desktop"; Switch { checked: Settings.hotCorners; onToggled: Settings.hotCorners = !Settings.hotCorners } }
                }

                // Displays
                Group {
                    visible: ss.page === "displays"
                    FormRow { label: "Brightness"; Slide { value: Brightness.value; onMoved: v => Brightness.set(v) } }
                    FormRow { label: "Night Shift"; Switch { checked: Settings.nightShift; onToggled: Settings.nightShift = !Settings.nightShift } }
                    FormRow { label: "Display"; detail: (Quickshell.screens[0]?.name ?? "") + "  " + (Quickshell.screens[0]?.width ?? 0) + " × " + (Quickshell.screens[0]?.height ?? 0) }
                }

                // Wallpaper
                GridLayout {
                    visible: ss.page === "wallpaper"
                    columns: 3; columnSpacing: 12; rowSpacing: 12
                    Layout.fillWidth: true
                    Repeater {
                        model: wpList.files
                        Rectangle {
                            required property string modelData
                            Layout.preferredWidth: 160; Layout.preferredHeight: 92
                            radius: 9; clip: true; color: "black"
                            border.width: (Wallpaper.custom === modelData || (Wallpaper.custom === "" && modelData === "dynamic")) ? 3 : 0
                            border.color: Theme.accent
                            Image {
                                anchors.fill: parent; anchors.margins: parent.border.width
                                source: "file://" + (parent.modelData === "dynamic" ? Wallpaper.dir + "MacTahoe-day.jpeg" : parent.modelData)
                                fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(320, 184); asynchronous: true
                            }
                            Text {
                                visible: parent.modelData === "dynamic"
                                anchors { left: parent.left; bottom: parent.bottom; margins: 8 }
                                text: "Tahoe · Dynamic"; color: "white"; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold
                                style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.5)
                            }
                            MouseArea { anchors.fill: parent; onClicked: Settings.wallpaper = parent.modelData === "dynamic" ? "" : parent.modelData }
                        }
                    }
                    Process {
                        id: wpList
                        property var files: []
                        running: ss.page === "wallpaper" && ss.visible
                        command: ["sh", "-c", "ls -1 \"$HOME/.config/orchard/wallpapers\"/* \"$HOME/Pictures/Wallpapers\"/* 2>/dev/null | grep -iE '\\.(jpe?g|png|webp)$' | grep -v MacTahoe-"]
                        stdout: StdioCollector { onStreamFinished: wpList.files = ["dynamic"].concat(text.split("\n").filter(l => l)) }
                    }
                }
                Text { visible: ss.page === "wallpaper"; text: "Add pictures to ~/Pictures/Wallpapers to see them here."; color: Theme.secondary; font.family: Theme.font; font.pixelSize: 11 }

                // Sound
                Group {
                    visible: ss.page === "sound"
                    FormRow { label: "Output volume"; Slide { value: Audio.volume; onMoved: v => Audio.setVolume(v) } }
                    FormRow { label: "Mute"; Switch { checked: Audio.muted; onToggled: Audio.toggleMute() } }
                    FormRow { label: "Output device"; detail: Audio.device }
                    FormRow { label: "Advanced…"; Text { text: "Open"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 13
                        MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["pavucontrol"]) } } }
                }

                // Wi-Fi
                Group {
                    visible: ss.page === "wifi"
                    FormRow { label: "Wi-Fi"; detail: Net.name; Switch { checked: Networking.wifiEnabled; onToggled: Net.toggle() } }
                    FormRow { label: "Network settings…"; Text { text: "Open"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 13
                        MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["nm-connection-editor"]) } } }
                }

                // Bluetooth
                Group {
                    visible: ss.page === "bluetooth"
                    FormRow { label: "Bluetooth"; Switch { checked: !!Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                        onToggled: if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled } }
                    Repeater {
                        model: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.devices.values.filter(d => d.paired) : []
                        FormRow {
                            required property var modelData
                            label: modelData.name; detail: modelData.connected ? "Connected" : "Not Connected"
                            Text { text: modelData.connected ? "Disconnect" : "Connect"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 13
                                MouseArea { anchors.fill: parent; onClicked: modelData.connected = !modelData.connected } }
                        }
                    }
                    FormRow { label: "Pair a new device…"; Text { text: "Open"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 13
                        MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["blueman-manager"]) } } }
                }

                // Notifications / Focus
                Group {
                    visible: ss.page === "notifications" || ss.page === "focus"
                    FormRow { label: "Do Not Disturb"; Switch { checked: Settings.focusMode; onToggled: Settings.focusMode = !Settings.focusMode } }
                    FormRow { label: "Notifications in Notification Center"; detail: Notifs.all.length + "" }
                    FormRow { label: "Clear all notifications"; Text { text: "Clear"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 13
                        MouseArea { anchors.fill: parent; onClicked: Notifs.clearAll() } } }
                }

                // Battery
                Group {
                    visible: ss.page === "battery"
                    FormRow { label: "Battery level"; detail: Math.round(UPower.displayDevice.percentage * 100) + "%" }
                    FormRow { label: "Battery health"; detail: UPower.displayDevice.healthSupported ? Math.round(UPower.displayDevice.healthPercentage) + "%" : "—" }
                    FormRow { label: "Energy mode"
                        Seg { options: [["Low Power", PowerProfile.PowerSaver], ["Automatic", PowerProfile.Balanced], ["High Power", PowerProfile.Performance]]
                              value: PowerProfiles.profile; onPicked: v => PowerProfiles.profile = v } }
                }

                // General
                Group {
                    visible: ss.page === "general"
                    FormRow { label: "About"; Text { text: "About This Mac"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 13
                        MouseArea { anchors.fill: parent; onClicked: Shell.about = true } } }
                    FormRow { label: "Software Update"; Text { text: "Update Now"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 13
                        MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached([Settings.bin + "term", "-e", "sh", "-c", "sudo pacman -Syu; read -n1 -p 'Done. Press any key'"]) } } }
                    FormRow { label: "Storage"; Text { text: "Open Finder"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 13
                        MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["dolphin", "/"]) } } }
                }

                // Keyboard
                Group {
                    visible: ss.page === "keyboard"
                    FormRow { label: "Keyboard Shortcuts…"; Text { text: "Show"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 13
                        MouseArea { anchors.fill: parent; onClicked: Shell.shortcuts = true } } }
                    FormRow { label: "⌘ key"; detail: "Super (Windows key)" }
                    FormRow { label: "Arrow keys"; detail: "Hold Tab + Q W E R (keyd)" }
                }

                // Lock screen
                Group {
                    visible: ss.page === "lock"
                    FormRow { label: "Lock Screen now"; Text { text: "Lock"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 13
                        MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["loginctl", "lock-session"]) } } }
                    FormRow { label: "Turn display off when inactive"; detail: "after 5 minutes" }
                    FormRow { label: "Require password after screen saver"; detail: "Immediately" }
                }
            }
        }
    }
}
