pragma Singleton
import QtQuick
import Quickshell

// Which transient surface is open. Only one menu/popover at a time, like
// macOS; opening Spotlight or Mission Control closes any menu.
Singleton {
    id: s
    property string popup: ""          // "apple" | "app" | "File" … | "control" | "notifications" | "wifi" | "battery" | "bluetooth" | "sound"
    property real popupX: 0            // left edge of the bar item that opened it
    readonly property bool popupFromBar: popup !== ""
    property bool spotlight: false
    property bool launchpad: false
    property bool mission: false
    property bool switcher: false
    property bool forceQuit: false
    property bool about: false
    property bool shotMenu: false
    property bool settings: false
    property string settingsPage: "appearance"
    property bool shortcuts: false
    property string confirm: ""        // "restart" | "shutdown" | "logout"
    property string spotlightMode: ""  // "" | "clipboard"
    property point desktopMenuPos: Qt.point(0, 0)

    function toggle(name, x) {
        if (popup === name) { popup = ""; return }
        popupX = x ?? popupX
        popup = name
    }
    signal cancelled()
    function closeAll() {
        cancelled()
        popup = ""; spotlight = false; launchpad = false; mission = false
        switcher = false; forceQuit = false; shotMenu = false; shortcuts = false; about = false; confirm = ""
    }
    function open(what) {
        const was = s[what]
        closeAll()
        s[what] = !was
    }
}
