import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../services"
import "../components"

// ⌘Tab: apps (not windows) in most-recently-used order in a glass strip.
// Hold ⌘, tap Tab / ⇧Tab to move, release ⌘ to switch. Q quits the
// selected app, H hides it — same as macOS.
PanelWindow {
    id: sw
    required property var modelData
    screen: modelData
    visible: Shell.switcher
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "orchard-switcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property var apps: []
    property int sel: 0

    function build() {
        const out = []
        for (const c of Hypr.clients) if (out.indexOf(c.class) < 0) out.push(c.class)
        apps = out
    }
    function next(d) {
        if (!Shell.switcher) {
            build()
            if (apps.length === 0) return
            sel = apps.length > 1 ? 1 : 0
            if (d < 0) sel = apps.length - 1
            Shell.switcher = true
            return
        }
        sel = (sel + d + apps.length) % apps.length
    }
    function commit() {
        if (!Shell.switcher) return
        Shell.switcher = false
        const cls = apps[sel]
        if (cls) Apps.activate(cls)
    }

    // releasing Super ends the switch; Hyprland tells us through these
    GlobalShortcut { appid: "orchard"; name: "switch-next"; onPressed: sw.next(1) }
    GlobalShortcut { appid: "orchard"; name: "switch-prev"; onPressed: sw.next(-1) }
    GlobalShortcut { appid: "orchard"; name: "switch-commit"; onPressed: sw.commit() }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Tab || e.key === Qt.Key_Right) { sw.next(1); e.accepted = true }
            else if (e.key === Qt.Key_Backtab || e.key === Qt.Key_Left) { sw.next(-1); e.accepted = true }
            else if (e.key === Qt.Key_Escape) { Shell.switcher = false; e.accepted = true }
            else if (e.key === Qt.Key_Q) { Hypr.quitApp(sw.apps[sw.sel]); sw.apps = sw.apps.filter((_, i) => i !== sw.sel); sw.sel = Math.min(sw.sel, sw.apps.length - 1); if (!sw.apps.length) Shell.switcher = false }
            else if (e.key === Qt.Key_H) { Hypr.hideApp(sw.apps[sw.sel]) }
            else if (e.key === Qt.Key_Return) sw.commit()
        }
        Keys.onReleased: e => { if (e.key === Qt.Key_Super_L || e.key === Qt.Key_Super_R || e.key === Qt.Key_Meta) sw.commit() }
    }
    onVisibleChanged: if (visible) contentItem.children[0].forceActiveFocus()

    Glass {
        anchors.centerIn: parent
        width: strip.width + 28
        height: 128
        radius: 26
        tint: Theme.glassThick
        Row {
            id: strip
            anchors.centerIn: parent
            spacing: 4
            Repeater {
                model: sw.apps
                Item {
                    required property string modelData
                    required property int index
                    width: 100; height: 100
                    Rectangle {
                        anchors.fill: parent; radius: 18
                        color: index === sw.sel ? (Theme.dark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"
                    }
                    Image {
                        anchors.centerIn: parent
                        width: 80; height: 80
                        source: Apps.icon(modelData)
                        sourceSize: Qt.size(160, 160); smooth: true; mipmap: true
                    }
                    MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: sw.sel = index; onClicked: { sw.sel = index; sw.commit() } }
                }
            }
        }
        Text {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 8 }
            text: sw.apps[sw.sel] ? Apps.name(sw.apps[sw.sel]) : ""
            color: "white"; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium
            style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.5)
        }
    }
}
