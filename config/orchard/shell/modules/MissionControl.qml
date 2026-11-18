import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../services"
import "../components"

// Mission Control (⌃↑, F3, four-finger swipe up). Live window previews fly
// from where they are to a tidy grid; the Spaces bar on top switches desktops
// and accepts windows dragged onto it. Click a window to bring it forward.
PanelWindow {
    id: mc
    required property var modelData
    screen: modelData
    visible: Shell.mission || leaving.running
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "orchard-mission"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Shell.mission ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property real t: Shell.mission ? 1 : 0          // 0 = windows in place, 1 = grid
    Behavior on t { NumberAnimation { id: leaving; duration: Theme.slow; easing.type: Theme.easeInOut } }

    readonly property var wins: Hypr.here.filter(c => !c.hidden)
    readonly property var tops: Hyprland.toplevels.values
    function toplevel(addr) {
        const t = tops.find(t => "0x" + t.address === addr || t.address === addr)
        return t ? t.wayland : null
    }

    // grid geometry
    readonly property real top: 110
    readonly property real side: 50
    readonly property int n: wins.length
    readonly property int cols: Math.max(1, Math.ceil(Math.sqrt(n * (width / height) / 1.6)))
    readonly property int rows: Math.max(1, Math.ceil(n / cols))
    readonly property real cellW: (width - side * 2) / cols
    readonly property real cellH: (height - top - 40) / rows

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.42 * mc.t)
        MouseArea { anchors.fill: parent; onClicked: Shell.mission = false }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Shell.mission = false
    }
    onVisibleChanged: if (visible) contentItem.forceActiveFocus()

    // ---------------------------------------------------------- spaces bar
    Row {
        id: spaces
        anchors.horizontalCenter: parent.horizontalCenter
        y: 18 - (1 - mc.t) * 90
        spacing: 14
        Repeater {
            model: Hypr.workspaceIds
            Rectangle {
                id: wsTile
                required property int modelData
                width: 128; height: 72; radius: 10
                color: Qt.rgba(1, 1, 1, drop.containsDrag ? 0.3 : 0.12)
                border.width: modelData === Hypr.activeWs ? 2.5 : 0.5
                border.color: modelData === Hypr.activeWs ? "white" : Qt.rgba(1, 1, 1, 0.3)
                clip: true
                Image {
                    anchors.fill: parent; anchors.margins: 2
                    source: Wallpaper.current; fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(256, 144); asynchronous: true; opacity: 0.85
                }
                // tiny icons of what is on that desktop
                Row {
                    anchors.centerIn: parent; spacing: 3
                    Repeater {
                        model: Hypr.clients.filter(c => c.workspace.id === wsTile.modelData).slice(0, 4)
                        Image { required property var modelData; width: 22; height: 22; source: Apps.icon(modelData.class); sourceSize: Qt.size(44, 44); smooth: true }
                    }
                }
                Text {
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 4 }
                    text: "Desktop " + wsTile.modelData
                    color: "white"; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.Medium
                }
                MouseArea { anchors.fill: parent; onClicked: { Hypr.goWorkspace(wsTile.modelData) } }
                DropArea {
                    id: drop; anchors.fill: parent
                    onDropped: d => Hypr.dispatch("hl.dsp.window.move({ workspace = " + wsTile.modelData + ", follow = false, window = \"address:" + d.source.addr + "\" })")
                }
            }
        }
        Rectangle {
            width: 40; height: 72; radius: 10
            color: Qt.rgba(1, 1, 1, 0.12)
            Sym { anchors.centerIn: parent; name: "plus"; size: 18; color: "white" }
            MouseArea {
                anchors.fill: parent
                onClicked: Hypr.goWorkspace(Math.max.apply(null, Hypr.workspaceIds) + 1)
            }
        }
    }

    // ------------------------------------------------------------- windows
    Repeater {
        model: mc.wins
        Item {
            id: w
            required property var modelData
            required property int index
            readonly property string addr: modelData.address
            readonly property real aw: modelData.size[0]
            readonly property real ah: modelData.size[1]
            readonly property real ax: modelData.at[0]
            readonly property real ay: modelData.at[1]
            // fitted cell rectangle
            readonly property int col: index % mc.cols
            readonly property int row: Math.floor(index / mc.cols)
            readonly property real k: Math.min((mc.cellW - 40) / aw, (mc.cellH - 50) / ah, 1)
            readonly property real gw: aw * k
            readonly property real gh: ah * k
            readonly property real lastRowOffset: row === mc.rows - 1 ? (mc.cols - (mc.n - row * mc.cols)) * mc.cellW / 2 : 0
            readonly property real gx: mc.side + lastRowOffset + col * mc.cellW + (mc.cellW - gw) / 2
            readonly property real gy: mc.top + row * mc.cellH + (mc.cellH - gh) / 2

            x: ax + (gx - ax) * mc.t
            y: ay + (gy - ay) * mc.t
            width: aw + (gw - aw) * mc.t
            height: ah + (gh - ah) * mc.t
            z: hov.hovered ? 2 : 1


            Rectangle {
                anchors.fill: parent; anchors.margins: -3
                radius: 13
                color: "transparent"
                border.width: 3
                border.color: Theme.accent
                visible: hov.hovered && mc.t > 0.9
            }
            ScreencopyView {
                id: shot
                anchors.fill: parent
                captureSource: Shell.mission ? mc.toplevel(w.addr) : null
                live: false
                layer.enabled: true
                layer.smooth: true
            }
            Rectangle {   // fallback when capture is unavailable
                anchors.fill: parent; radius: 10
                visible: !shot.hasContent
                color: Theme.glassThick
                Image { anchors.centerIn: parent; width: 64; height: 64; source: Apps.icon(w.modelData.class); sourceSize: Qt.size(128, 128) }
            }
            Image {
                anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.bottom }
                width: 40; height: 40; opacity: mc.t
                source: Apps.icon(w.modelData.class); sourceSize: Qt.size(80, 80); smooth: true
            }
            Rectangle {
                visible: hov.hovered && mc.t > 0.9
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 22 }
                width: Math.min(260, ttl.implicitWidth + 18); height: 22; radius: 7
                color: Qt.rgba(0, 0, 0, 0.6)
                Text { id: ttl; anchors.centerIn: parent; width: Math.min(242, implicitWidth); elide: Text.ElideRight
                       text: w.modelData.title; color: "white"; font.family: Theme.font; font.pixelSize: 12 }
            }
            HoverHandler { id: hov }
            DragHandler { id: dragger; target: null; onActiveChanged: if (!active) ghost.Drag.drop() }
            // a small icon follows the pointer while dragging to a desktop
            Image {
                id: ghost
                readonly property string addr: w.addr
                visible: dragger.active
                x: dragger.centroid.position.x - 28; y: dragger.centroid.position.y - 28
                width: 56; height: 56
                source: Apps.icon(w.modelData.class); sourceSize: Qt.size(112, 112)
                Drag.active: dragger.active
                Drag.source: ghost
                Drag.hotSpot.x: 28; Drag.hotSpot.y: 28
            }
            TapHandler { onTapped: { Shell.mission = false; Hypr.focusWindow(w.modelData) } }
        }
    }
}
