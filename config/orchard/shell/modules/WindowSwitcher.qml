import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../services"
import "../components"

// Alt+Tab: every window (not just apps), most recently used first, with a
// live preview of each. Hold Alt, tap Tab / Shift+Tab or use the arrows,
// release Alt to jump there — even onto another desktop or out of the
// minimised stack. W closes the selected window, Esc cancels.
PanelWindow {
    id: ws
    required property var modelData
    screen: modelData
    visible: open
    property bool open: false
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "orchard-switcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property var wins: []
    property int sel: 0
    readonly property int cols: Math.min(wins.length, 5)

    function build() {
        // this desktop first, then other desktops, then minimised — each MRU
        const here = Hypr.clients.filter(c => c.workspace.id === Hypr.activeWs)
        const other = Hypr.clients.filter(c => c.workspace.id !== Hypr.activeWs && c.workspace.id > 0)
        const mins = Hypr.minimized
        wins = here.concat(other).concat(mins)
    }
    function next(d) {
        if (!open) {
            build()
            if (!wins.length) return
            sel = wins.length > 1 ? (d > 0 ? 1 : wins.length - 1) : 0
            building = true; Shell.closeAll(); building = false
            open = true
            return
        }
        sel = (sel + d + wins.length) % wins.length
    }
    function commit() {
        if (!open) return
        open = false
        const c = wins[sel]
        if (c) Hypr.focusWindow(c)
    }
    function tl(addr) {
        const t = Hyprland.toplevels.values.find(t => "0x" + t.address === addr || t.address === addr)
        return t ? t.wayland : null
    }

    GlobalShortcut { appid: "orchard"; name: "winswitch-next"; onPressed: ws.next(1) }
    GlobalShortcut { appid: "orchard"; name: "winswitch-prev"; onPressed: ws.next(-1) }
    GlobalShortcut { appid: "orchard"; name: "winswitch-commit"; onPressed: ws.commit() }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Tab || e.key === Qt.Key_Right) ws.next(1)
            else if (e.key === Qt.Key_Backtab || e.key === Qt.Key_Left) ws.next(-1)
            else if (e.key === Qt.Key_Down) ws.sel = Math.min(ws.wins.length - 1, ws.sel + ws.cols)
            else if (e.key === Qt.Key_Up) ws.sel = Math.max(0, ws.sel - ws.cols)
            else if (e.key === Qt.Key_Escape) ws.open = false
            else if (e.key === Qt.Key_Return) ws.commit()
            else if (e.key === Qt.Key_W) {
                Hypr.close(ws.wins[ws.sel])
                ws.wins = ws.wins.filter((_, i) => i !== ws.sel)
                ws.sel = Math.min(ws.sel, ws.wins.length - 1)
                if (!ws.wins.length) ws.open = false
            } else return
            e.accepted = true
        }
        Keys.onReleased: e => { if (e.key === Qt.Key_Alt || e.key === Qt.Key_AltGr) ws.commit() }
    }
    onOpenChanged: if (open) keys.forceActiveFocus()
    Connections { target: Shell; function onCancelled() { if (!ws.building) ws.open = false } }
    property bool building: false
    MouseArea { anchors.fill: parent; onClicked: ws.open = false }

    Glass {
        anchors.centerIn: parent
        width: grid.width + 32
        height: grid.height + 32
        radius: 26
        tint: Theme.glassThick
        MouseArea { anchors.fill: parent }

        Grid {
            id: grid
            anchors.centerIn: parent
            columns: ws.cols
            spacing: 10
            Repeater {
                model: ws.open ? ws.wins : []
                Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property bool on: index === ws.sel
                    readonly property bool minimised: modelData.workspace.name === "special:minimized"
                    width: 196; height: 150

                    Rectangle {
                        anchors.fill: parent; radius: 14
                        color: cell.on ? (Theme.dark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.09)) : "transparent"
                        border.width: cell.on ? 2 : 0
                        border.color: Theme.accent
                    }
                    // preview, aspect-fitted
                    Item {
                        id: frame
                        x: 10; y: 10; width: parent.width - 20; height: 100
                        readonly property real k: Math.min(width / cell.modelData.size[0], height / cell.modelData.size[1])
                        Rectangle {
                            id: pv
                            anchors.centerIn: parent
                            width: cell.modelData.size[0] * frame.k
                            height: cell.modelData.size[1] * frame.k
                            radius: 6; clip: true
                            color: Theme.dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.05)
                            ScreencopyView {
                                id: sv
                                anchors.fill: parent
                                live: ws.open && !cell.minimised
                                captureSource: armed && !cell.minimised ? ws.tl(cell.modelData.address) : null
                                property bool armed: false
                                Timer { running: true; interval: 60; onTriggered: sv.armed = true }
                                property int tries: 0
                                onStopped: if (tries++ < 5) { armed = false; rearm.restart() }
                                Timer { id: rearm; interval: 120; onTriggered: sv.armed = true }
                            }
                            Image {
                                visible: !sv.hasContent
                                anchors.centerIn: parent
                                width: 48; height: 48
                                source: Apps.icon(cell.modelData.class); sourceSize: Qt.size(96, 96)
                            }
                        }
                        Image {
                            anchors { right: pv.right; bottom: pv.bottom; margins: -8 }
                            width: 34; height: 34
                            source: Apps.icon(cell.modelData.class); sourceSize: Qt.size(68, 68); smooth: true
                        }
                    }
                    Text {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 10; bottomMargin: 8 }
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: (cell.minimised ? "⌄ " : cell.modelData.workspace.id !== Hypr.activeWs ? cell.modelData.workspace.id + " · " : "")
                              + (cell.modelData.title || Apps.name(cell.modelData.class))
                        color: Theme.label
                        font.family: Theme.font; font.pixelSize: 12
                        font.weight: cell.on ? Font.DemiBold : Font.Normal
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: ws.sel = cell.index
                        onClicked: { ws.sel = cell.index; ws.commit() }
                    }
                }
            }
        }
    }
}
