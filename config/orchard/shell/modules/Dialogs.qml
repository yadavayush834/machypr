import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"
import "../components"

// Modal system windows: About This Mac, Force Quit Applications, the
// restart / shut down / log out confirmation (60 s countdown), Keyboard
// Shortcuts, and the ⇧⌘5 screenshot toolbar.
PanelWindow {
    id: dlg
    required property var modelData
    screen: modelData
    readonly property bool any: Shell.about || Shell.forceQuit || Shell.confirm !== "" || Shell.shortcuts || Shell.shotMenu
    visible: any
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "orchard-dialog"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: any ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function closeAll() { Shell.about = false; Shell.forceQuit = false; Shell.confirm = ""; Shell.shortcuts = false; Shell.shotMenu = false }

    Rectangle {
        anchors.fill: parent
        color: Shell.confirm !== "" ? Qt.rgba(0, 0, 0, 0.25) : "transparent"
        MouseArea { anchors.fill: parent; onPressed: if (Shell.confirm === "") dlg.closeAll() }
    }
    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: dlg.closeAll()
        Keys.onReturnPressed: { if (Shell.confirm !== "") confirmBox.go(); else if (Shell.forceQuit) fq.kill(); else if (Shell.shotMenu) shot.capture() }
    }
    onVisibleChanged: if (visible) keys.forceActiveFocus()

    component Button: Rectangle {
        id: btn
        property string text
        property bool primary: false
        signal clicked()
        implicitWidth: Math.max(90, bt.implicitWidth + 28); implicitHeight: 28; radius: 14
        color: primary ? Theme.accent : (Theme.dark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.07))
        opacity: enabled ? 1 : 0.4
        Text { id: bt; anchors.centerIn: parent; text: btn.text; color: btn.primary ? "white" : Theme.label; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium }
        MouseArea { anchors.fill: parent; onClicked: btn.clicked() }
    }
    component Label: Text { color: Theme.label; font.family: Theme.font; font.pixelSize: 13; renderType: Text.NativeRendering }

    // ------------------------------------------------------------ About
    Glass {
        id: about
        visible: Shell.about
        anchors.centerIn: parent
        width: 300; height: ac.implicitHeight + 40
        radius: 24; tint: Theme.glassThick
        MouseArea { anchors.fill: parent }
        property var info: ({})
        Process {
            running: Shell.about
            command: ["sh", "-c", "cat /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_name 2>/dev/null | tr '\\n' ' '; echo; " +
                      "grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ *//;s/(R)//g;s/(TM)//g;s/ CPU//;s/ @.*//'; " +
                      "awk '/MemTotal/{printf \"%d GB\\n\", ($2/1048576)+0.5}' /proc/meminfo; " +
                      "lspci 2>/dev/null | grep -m1 -i vga | sed 's/.*: //;s/Corporation //;s/ (rev.*//'; " +
                      ". /etc/os-release; echo $PRETTY_NAME; uname -r; cat /sys/class/dmi/id/product_serial 2>/dev/null || echo '—'; " +
                      "df -h / | awk 'NR==2{print $4\" available of \"$2}'"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const l = text.split("\n")
                    about.info = { model: l[0].trim(), cpu: l[1], mem: l[2], gpu: l[3], os: l[4], kernel: l[5], serial: l[6], disk: l[7] }
                }
            }
        }
        ColumnLayout {
            id: ac
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
            spacing: 6
            Image {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 120; Layout.preferredHeight: 90
                source: Quickshell.iconPath("computer-laptop", "computer")
                sourceSize: Qt.size(240, 180); fillMode: Image.PreserveAspectFit
            }
            Text { Layout.alignment: Qt.AlignHCenter; text: about.info.model || "Laptop"
                   color: Theme.label; font.family: Theme.fontDisplay; font.pixelSize: 22; font.weight: Font.Bold }
            Text { Layout.alignment: Qt.AlignHCenter; text: about.info.os ?? ""; color: Theme.secondary; font.family: Theme.font; font.pixelSize: 12 }
            Item { implicitHeight: 8 }
            Repeater {
                model: [["Chip", about.info.cpu], ["Graphics", about.info.gpu], ["Memory", about.info.mem], ["Storage", about.info.disk],
                        ["Serial number", about.info.serial], ["Kernel", about.info.kernel], ["Desktop", "Orchard on Hyprland"]]
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true; spacing: 8
                    Text { text: modelData[0]; Layout.preferredWidth: 96; horizontalAlignment: Text.AlignRight; color: Theme.label; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold }
                    Text { text: modelData[1] ?? ""; Layout.fillWidth: true; elide: Text.ElideRight; color: Theme.secondary; font.family: Theme.font; font.pixelSize: 12 }
                }
            }
            Item { implicitHeight: 8 }
            Button { Layout.alignment: Qt.AlignHCenter; text: "More Info…"; onClicked: { dlg.closeAll(); Quickshell.execDetached([Settings.bin + "term", "-e", "sh", "-c", "fastfetch; read -n1"]) } }
        }
    }

    // ------------------------------------------------------- Force Quit
    Glass {
        id: fq
        visible: Shell.forceQuit
        anchors.centerIn: parent
        width: 380; height: 360
        radius: 20; tint: Theme.glassThick
        MouseArea { anchors.fill: parent }
        property int sel: 0
        readonly property var apps: {
            const out = []
            for (const c of Hypr.clients) if (!out.find(o => o.cls === c.class)) out.push({ cls: c.class, pid: c.pid })
            return out
        }
        function kill() {
            const a = apps[sel]; if (!a) return
            Quickshell.execDetached(["kill", "-9", String(a.pid)])
        }
        ColumnLayout {
            anchors { fill: parent; margins: 18 }
            spacing: 10
            Label { text: "Force Quit Applications"; font.weight: Font.Bold; Layout.alignment: Qt.AlignHCenter }
            Label { text: "If an app doesn’t respond for a while, select its name and click Force Quit."; wrapMode: Text.Wrap; Layout.fillWidth: true; font.pixelSize: 11; color: Theme.secondary }
            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true; radius: 8
                color: Theme.dark ? Qt.rgba(0, 0, 0, 0.25) : "white"
                border.width: 0.5; border.color: Theme.separator
                ListView {
                    anchors { fill: parent; margins: 4 }
                    clip: true
                    model: fq.apps
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: ListView.view.width; height: 28; radius: 5
                        color: fq.sel === index ? Theme.accent : "transparent"
                        RowLayout {
                            anchors { fill: parent; leftMargin: 6 }
                            Image { Layout.preferredWidth: 18; Layout.preferredHeight: 18; source: Apps.icon(modelData.cls); sourceSize: Qt.size(36, 36) }
                            Label { text: Apps.name(modelData.cls); color: fq.sel === index ? "white" : Theme.label; Layout.fillWidth: true }
                        }
                        MouseArea { anchors.fill: parent; onClicked: fq.sel = index }
                    }
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                Button { text: "Force Quit"; primary: true; enabled: fq.apps.length > 0; onClicked: fq.kill() }
            }
        }
    }

    // --------------------------------------------- restart / shut down
    Glass {
        id: confirmBox
        visible: Shell.confirm !== ""
        anchors.centerIn: parent
        width: 280; height: cbc.implicitHeight + 36
        radius: 22; tint: Theme.glassThick
        MouseArea { anchors.fill: parent }
        property int secs: 60
        readonly property var copy: ({
            restart: ["Are you sure you want to restart your computer now?", "restart", "Restart", ["systemctl", "reboot"]],
            shutdown: ["Are you sure you want to shut down your computer now?", "shut down", "Shut Down", ["systemctl", "poweroff"]],
            logout: ["Are you sure you want to quit all applications and log out now?", "log you out", "Log Out", ["hyprctl", "dispatch", "hl.dsp.exit()"]],
            trash: ["Are you sure you want to permanently erase the items in the Trash?", "", "Empty Trash", null],
        })
        readonly property var c: copy[Shell.confirm] ?? copy.restart
        onVisibleChanged: secs = 60
        function go() {
            const what = Shell.confirm
            Shell.confirm = ""
            if (what === "trash") return Trash.empty()
            Quickshell.execDetached(c[3])
        }
        Timer {
            running: confirmBox.visible && Shell.confirm !== "trash"
            interval: 1000; repeat: true
            onTriggered: if (--confirmBox.secs <= 0) confirmBox.go()
        }
        ColumnLayout {
            id: cbc
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
            spacing: 8
            Image {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 56; Layout.preferredHeight: 56
                source: Quickshell.iconPath(Shell.confirm === "trash" ? "user-trash-full" : "system-shutdown", "system-shutdown")
                sourceSize: Qt.size(112, 112)
            }
            Label { text: confirmBox.c[0]; font.weight: Font.Bold; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }
            Label {
                visible: Shell.confirm !== "trash"
                text: "If you do nothing, the computer will " + confirmBox.c[1] + " automatically in " + confirmBox.secs + " seconds."
                font.pixelSize: 11; color: Theme.secondary; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true
            }
            Label { visible: Shell.confirm === "trash"; text: "You can’t undo this action."; font.pixelSize: 11; color: Theme.secondary; Layout.alignment: Qt.AlignHCenter }
            RowLayout {
                Layout.fillWidth: true; Layout.topMargin: 6; spacing: 8
                Button { text: "Cancel"; Layout.fillWidth: true; onClicked: Shell.confirm = "" }
                Button { text: confirmBox.c[2]; primary: true; Layout.fillWidth: true; onClicked: confirmBox.go() }
            }
        }
    }

    // -------------------------------------------------- shortcuts sheet
    Glass {
        visible: Shell.shortcuts
        anchors.centerIn: parent
        width: 640; height: sc.implicitHeight + 40
        radius: 24; tint: Theme.glassThick
        MouseArea { anchors.fill: parent }
        GridLayout {
            id: sc
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
            columns: 4; columnSpacing: 14; rowSpacing: 5
            Repeater {
                model: [
                    ["⌘ Space", "Spotlight"], ["⌘ Tab", "Switch apps"], ["⌘ Q", "Quit app"], ["⌘ W", "Close tab / window"],
                    ["⌘ C / V / X", "Copy / Paste / Cut"], ["⌘ Z  ⇧⌘Z", "Undo / Redo"], ["⌘ A", "Select all"], ["⌘ F", "Find"],
                    ["⌘ N  ⌘ T", "New window / tab"], ["⌘ S", "Save"], ["⌘ H", "Hide app"], ["⌘ M", "Minimize"],
                    ["⌃⌘ F", "Full screen"], ["⌃⌥ F / C", "Fill / Center window"], ["⌃⌥ ← →", "Tile left / right"], ["⌘ ↑", "Mission Control"],
                    ["⌘ 1–9", "Go to desktop"], ["⇧⌘ 1–9", "Send window to desktop"], ["⌘ L", "Launchpad"], ["⇧⌘ V", "Clipboard history"],
                    ["⇧⌘ 3", "Screenshot screen"], ["⇧⌘ 4", "Screenshot area"], ["⇧⌘ 5", "Screenshot toolbar"], ["⌥⌘ Esc", "Force Quit"],
                    ["⌃⌘ Q", "Lock screen"], ["⌘ ,", "App settings"], ["⌘ Return", "Terminal"], ["⌘ E", "Finder"],
                    ["⌥⌘ D", "Hide / show Dock"], ["⌘ N (desktop)", "Notification Center"], ["⌘ /", "This sheet"], ["4 fingers ↑", "Mission Control"],
                ]
                RowLayout {
                    required property var modelData
                    Layout.columnSpan: 2; Layout.fillWidth: true
                    Text { text: modelData[0]; Layout.preferredWidth: 110; color: Theme.label; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignRight }
                    Text { text: modelData[1]; Layout.fillWidth: true; color: Theme.secondary; font.family: Theme.font; font.pixelSize: 12 }
                }
            }
        }
    }

    // ---------------------------------------------- ⇧⌘5 screenshot bar
    Glass {
        id: shot
        visible: Shell.shotMenu
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 110 }
        width: sr.implicitWidth + 24; height: 52
        radius: 16; tint: Theme.glassThick
        MouseArea { anchors.fill: parent }
        property string mode: "region"
        property int delay: 0
        property bool clip: false
        function capture() {
            Shell.shotMenu = false
            Quickshell.execDetached([Settings.bin + "shot", mode, String(delay), clip ? "clip" : "file"])
        }
        RowLayout {
            id: sr
            anchors.centerIn: parent
            spacing: 4
            Rectangle {
                implicitWidth: 28; implicitHeight: 28; radius: 14; color: Theme.hover
                Sym { anchors.centerIn: parent; name: "xmark"; size: 12; color: Theme.label; weight: 2.2 }
                MouseArea { anchors.fill: parent; onClicked: Shell.shotMenu = false }
            }
            Rectangle { implicitWidth: 1; implicitHeight: 28; color: Theme.separator; Layout.leftMargin: 6; Layout.rightMargin: 6 }
            Repeater {
                model: [["screen", "screen", "Capture Entire Screen"], ["window", "window", "Capture Selected Window"], ["region", "region", "Capture Selected Portion"]]
                Rectangle {
                    required property var modelData
                    implicitWidth: 40; implicitHeight: 36; radius: 9
                    color: shot.mode === modelData[0] ? Theme.tileHover : "transparent"
                    border.width: shot.mode === modelData[0] ? 0.5 : 0; border.color: Theme.separator
                    Sym { anchors.centerIn: parent; name: parent.modelData[1]; size: 20; color: Theme.label }
                    MouseArea { anchors.fill: parent; onClicked: shot.mode = parent.modelData[0] }
                }
            }
            Rectangle { implicitWidth: 1; implicitHeight: 28; color: Theme.separator; Layout.leftMargin: 6; Layout.rightMargin: 6 }
            Repeater {
                model: [["None", 0], ["5 s", 5], ["10 s", 10]]
                Rectangle {
                    required property var modelData
                    implicitWidth: tl.implicitWidth + 16; implicitHeight: 26; radius: 13
                    color: shot.delay === modelData[1] ? Theme.tileHover : "transparent"
                    Text { id: tl; anchors.centerIn: parent; text: parent.modelData[0]; color: Theme.label; font.family: Theme.font; font.pixelSize: 12 }
                    MouseArea { anchors.fill: parent; onClicked: shot.delay = parent.modelData[1] }
                }
            }
            Rectangle {
                implicitWidth: cl2.implicitWidth + 16; implicitHeight: 26; radius: 13
                color: shot.clip ? Theme.tileHover : "transparent"
                Text { id: cl2; anchors.centerIn: parent; text: shot.clip ? "Clipboard" : "Pictures"; color: Theme.label; font.family: Theme.font; font.pixelSize: 12 }
                MouseArea { anchors.fill: parent; onClicked: shot.clip = !shot.clip }
            }
            Button { text: "Capture"; primary: true; Layout.leftMargin: 6; onClicked: shot.capture() }
        }
    }
}
