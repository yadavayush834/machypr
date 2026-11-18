import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../services"
import "../components"

// The Dock. Pinned apps, then running ones, a divider, minimised windows,
// Downloads and Trash. Cosine magnification under the pointer, running dots,
// name tooltips, right-click Options menu, auto-hide.
PanelWindow {
    id: dock
    required property var modelData
    screen: modelData

    readonly property real base: Settings.dockIconSize
    readonly property real maxSize: Settings.dockMagnify ? base * 1.55 : base
    readonly property real pad: 6
    readonly property real barH: base + pad * 2 + 6
    readonly property bool fullscreen: Hypr.active && Hypr.active.fullscreen === 2
    property bool menuOpen: ctx.visible
    readonly property bool hovering: hot.containsMouse
    // auto-hide: appears after the pointer rests on the bottom edge briefly,
    // leaves shortly after the pointer does (macOS timings, no flicker)
    property bool shown: false
    readonly property bool revealed: !Settings.dockAutohide || shown || menuOpen || Shell.popup === "dock"
    Timer { id: showTimer; interval: 90; onTriggered: dock.shown = true }
    Timer { id: hideTimer; interval: 450; onTriggered: if (!hot.containsMouse && !dock.menuOpen) dock.shown = false }
    onHoveringChanged: {
        if (hovering) { hideTimer.stop(); if (!shown) showTimer.restart() }
        else { showTimer.stop(); hideTimer.restart() }
    }
    onMenuOpenChanged: if (!menuOpen && !hovering) hideTimer.restart()

    visible: !fullscreen && !Shell.launchpad && !Shell.mission
    anchors { bottom: true; left: true; right: true }
    implicitHeight: barH + (maxSize - base) + 40          // room to magnify + tooltip
    exclusiveZone: Settings.dockAutohide ? 0 : barH + 4
    color: "transparent"
    WlrLayershell.namespace: "orchard-dock"
    WlrLayershell.layer: WlrLayer.Top

    // Input zone. It must not change while the pointer moves (magnification
    // resizing it every frame made the pointer leave/enter = the glitch).
    // Revealed: the dock plus headroom for magnified icons. Hidden: a 2px
    // strip along the bottom edge under the dock.
    readonly property real extra: (maxSize - base) * 2.2
    Item {
        id: hitbox
        x: Math.max(0, dock.restLeft - dock.extra)
        width: Math.min(dock.width, dock.restRow + dock.pad * 2 + 4 + dock.extra * 2)
        y: dock.revealed ? dock.height - dock.barH - 8 - (dock.maxSize - dock.base) : dock.height - 2
        height: dock.height - y
    }

    // ----- data
    readonly property var pinned: Settings.pinned
    readonly property var running: {
        const seen = []
        const out = []
        for (const c of Hypr.clients) {
            if (seen.indexOf(c.class) >= 0) continue
            seen.push(c.class)
            if (!pinned.some(p => Apps.matches(p, c.class))) out.push(c.class)
        }
        return out
    }
    readonly property var apps: buildApps()
    function buildApps() {
        // Finder first, then Apps (Launchpad), then the rest — like macOS
        const list = pinned.map(id => ({ id: id, pinned: true }))
        list.splice(1, 0, { id: "@apps", pinned: true })
        return list.concat(running.map(id => ({ id: id, pinned: false })))
    }
    readonly property var trailing: Hypr.minimized.map(c => ({ id: "@min", win: c }))
        .concat([{ id: "@downloads" }, { id: "@trash" }])

    // ----- magnification
    property real mouseX: -1000
    readonly property real restRow: (apps.length + trailing.length) * (base + 4) - 4 + 5
    readonly property real restLeft: (width - (restRow + pad * 2 + 4)) / 2
    function sizeFor(item) {
        if (!Settings.dockMagnify || !hot.containsMouse || !revealed) return base
        const center = restLeft + pad + 2 + item.restX + base / 2
        const d = Math.abs(dock.mouseX - center)
        const range = base * 3
        if (d >= range) return base
        return base + (maxSize - base) * Math.cos(d / range * Math.PI / 2)
    }

    Item {
        id: slide
        anchors.fill: parent
        // Hover is tracked on the parent of the icons, so moving onto an icon
        // never counts as leaving the dock. The window mask limits it to the
        // dock zone.
        HoverHandler {
            id: hot
            readonly property bool containsMouse: hovered
            onPointChanged: dock.mouseX = point.position.x
            onHoveredChanged: if (!hovered) dock.mouseX = -1000
        }
        transform: Translate {
            y: dock.revealed ? 0 : dock.barH + 16
            Behavior on y { NumberAnimation { duration: Theme.normal; easing.type: Theme.ease } }
        }

        Glass {
            id: shelf
            anchors { bottom: parent.bottom; bottomMargin: 6; horizontalCenter: parent.horizontalCenter }
            height: dock.barH
            width: row.width + dock.pad * 2 + 4
            radius: Theme.dockRadius
            tint: Theme.dark ? Qt.rgba(0.16, 0.16, 0.17, 0.45) : Qt.rgba(1, 1, 1, 0.38)
            Behavior on width { enabled: !hot.containsMouse; NumberAnimation { duration: Theme.normal; easing.type: Theme.ease } }
        }

        Row {
            id: row
            anchors { bottom: shelf.bottom; bottomMargin: dock.pad + 4; horizontalCenter: shelf.horizontalCenter }
            spacing: 4

            Repeater {
                model: dock.apps
                DockIcon { required property var modelData; required property int index; entry: modelData; dockRef: dock; restX: index * (dock.base + 4) }
            }
            Rectangle {
                width: 1; height: dock.base * 0.8
                anchors.bottom: parent.bottom; anchors.bottomMargin: dock.base * 0.1
                color: Theme.dark ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(0, 0, 0, 0.18)
                x: 0
            }
            Repeater {
                model: dock.trailing
                DockIcon { required property var modelData; required property int index; entry: modelData; dockRef: dock; restX: (dock.apps.length + index) * (dock.base + 4) + 5 }
            }
        }
    }

    mask: menuOpen ? fullRegion : maskRegion

    // ----- right-click menu (macOS dock "Options")
    property var ctxItems: []
    property real ctxX: 0
    function openMenu(icon, items) {
        ctxItems = items
        const p = icon.mapToItem(dock.contentItem, icon.width / 2, 0)
        ctxX = p.x
        ctx.visible = true
    }
    MenuList {
        id: ctx
        visible: false
        items: dock.ctxItems
        x: Math.max(6, Math.min(dock.ctxX - width / 2, dock.width - width - 6))
        y: dock.height - dock.barH - height - 14
        onVisibleChanged: if (visible) current = -1
        onChosen: visible = false
        Connections { target: Shell; function onPopupChanged() { if (Shell.popup === "") ctx.visible = false } }
    }
    // the context menu needs the whole window to take input while open
    Region { id: fullRegion; item: dock.contentItem }
    Region { id: maskRegion; item: hitbox }
    MouseArea {
        anchors.fill: parent
        visible: dock.menuOpen
        z: -1
        onPressed: ctx.visible = false
    }
}
