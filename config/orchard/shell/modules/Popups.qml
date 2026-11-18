import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"
import "../components"

// Everything that drops from the menu bar lives on one overlay below the
// bar. A click anywhere outside closes it and is swallowed, like macOS.
PanelWindow {
    id: win
    required property var modelData
    screen: modelData

    readonly property string p: Shell.popup
    readonly property bool isMenu: ["apple", "app", "File", "Edit", "View", "Window", "Help", "desktop"].indexOf(p) >= 0
    readonly property bool isStatus: ["wifi", "battery", "sound", "nowplaying"].indexOf(p) >= 0

    visible: p !== "" || fade.running
    anchors { top: true; left: true; right: true; bottom: true }
    margins.top: Theme.barHeight
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "orchard-popup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: p !== "" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: Shell.popup = ""
    }

    Item {
        id: stage
        anchors.fill: parent
        focus: true
        opacity: win.p !== "" ? 1 : 0
        Behavior on opacity { NumberAnimation { id: fade; duration: win.p !== "" ? 0 : 180; easing.type: Easing.OutQuad } }

        Keys.onEscapePressed: Shell.popup = ""
        Keys.onUpPressed: if (menu.visible) menu.move(-1)
        Keys.onDownPressed: if (menu.visible) menu.move(1)
        Keys.onReturnPressed: if (menu.visible) menu.activate(menu.current)
        Keys.onLeftPressed: step(-1)
        Keys.onRightPressed: step(1)
        function step(d) {
            const order = ["apple", "app", "File", "Edit", "View", "Window", "Help"]
            const i = order.indexOf(win.p); if (i < 0) return
            // titles live in the bar; approximate x by walking widths is not
            // needed — keep the menu where it is and swap its content.
            Shell.popup = order[(i + d + order.length) % order.length]
        }

        MenuList {
            id: menu
            visible: win.isMenu
            x: Math.min(Shell.popupX, win.width - width - 6)
            y: win.p === "desktop" ? Math.min(Shell.desktopMenuPos.y - Theme.barHeight, win.height - height - 8) : 2
            items: win.isMenu ? Menus.items(win.p) : []
            onItemsChanged: current = -1
            MouseArea { anchors.fill: parent; z: -1 }   // don't close on clicks inside
        }

        StatusMenus {
            visible: win.isStatus
            x: Math.max(6, Math.min(Shell.popupX - 8, win.width - width - 6))
            y: 4
            MouseArea { anchors.fill: parent; z: -1 }
        }

        ControlCenter {
            id: cc
            visible: win.p === "control"
            x: win.width - width - 8
            y: 6
            scale: visible ? 1 : 0.96
            transformOrigin: Item.TopRight
            Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Theme.ease } }
            MouseArea { anchors.fill: parent; z: -1 }
        }

        NotificationCenter {
            visible: win.p === "notifications"
            x: win.width - width - 8
            y: 6
            maxHeight: win.height - 20
        }
    }
}
