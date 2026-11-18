import QtQuick
import Quickshell
import "../services"

// One Dock tile. Grows with magnification (anchored at the bottom so it
// rises), shows a dot when running, a name pill on hover, hops on launch.
Item {
    id: di
    required property var entry          // { id, pinned } | { id: "@min", win }
    required property var dockRef
    property real restX: 0

    readonly property string id: entry.id
    readonly property bool special: id.startsWith("@")
    readonly property var wins: special ? [] : Hypr.clients.filter(c => Apps.matches(id, c.class))
    readonly property bool running: id === "@min" || wins.length > 0
    readonly property real size: dockRef.sizeFor(di)
    readonly property string label: id === "@apps" ? "Apps" : id === "@trash" ? "Trash" : id === "@downloads" ? "Downloads"
                                   : id === "@min" ? entry.win.title : Apps.name(id)
    property bool launching: false

    width: size
    height: size
    anchors.bottom: parent ? parent.bottom : undefined
    Behavior on width { enabled: !dockRef.hovering; NumberAnimation { duration: Theme.quick; easing.type: Theme.ease } }

    Image {
        id: img
        width: parent.width; height: parent.height
        y: -hop.offset
        sourceSize: Qt.size(dockRef.maxSize * 2, dockRef.maxSize * 2)
        smooth: true; mipmap: true
        asynchronous: true
        source: di.id === "@apps" ? Quickshell.iconPath("view-app-grid", "appgrid")
              : di.id === "@trash" ? Quickshell.iconPath(Trash.full ? "user-trash-full" : "user-trash")
              : di.id === "@downloads" ? Quickshell.iconPath("folder-downloads")
              : di.id === "@min" ? Apps.icon(di.entry.win.class)
              : Apps.icon(di.id)
        opacity: ma.pressed ? 0.7 : 1
    }
    // minimised windows: small app badge in the corner, like macOS genie target
    Rectangle {
        visible: di.id === "@min"
        anchors { right: parent.right; bottom: parent.bottom }
        width: parent.width * 0.42; height: width; radius: width * 0.25
        color: Theme.glassThick
        Text { anchors.centerIn: parent; text: "–"; color: Theme.label; font.pixelSize: parent.width * 0.7 }
    }

    QtObject {
        id: hop
        property real offset: 0
    }
    SequentialAnimation {
        id: hopAnim
        loops: 2
        NumberAnimation { target: hop; property: "offset"; to: di.size * 0.32; duration: 260; easing.type: Easing.OutQuad }
        NumberAnimation { target: hop; property: "offset"; to: 0; duration: 260; easing.type: Easing.InQuad }
    }
    onRunningChanged: if (running) { launching = false; hopAnim.stop(); hop.offset = 0 }

    // running indicator
    Rectangle {
        visible: di.running && di.id !== "@min"
        width: 4; height: 4; radius: 2
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 2 }
        color: Theme.dark ? Qt.rgba(1, 1, 1, 0.8) : Qt.rgba(0, 0, 0, 0.75)
    }

    // name tooltip
    Rectangle {
        visible: ma.containsMouse && !dockRef.menuOpen
        anchors { horizontalCenter: parent.horizontalCenter; bottom: img.top; bottomMargin: 10 }
        width: tip.implicitWidth + 20; height: 26; radius: 8
        color: Theme.glassThick
        border.width: 0.5; border.color: Theme.outline
        Text {
            id: tip; anchors.centerIn: parent
            text: di.label.length > 40 ? di.label.slice(0, 39) + "…" : di.label
            color: Theme.label; font.family: Theme.font; font.pixelSize: 13
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: m => {
            if (m.button === Qt.RightButton) return di.dockRef.openMenu(di, di.menu())
            if (m.button === Qt.MiddleButton && !di.special) return Apps.launch(di.id)
            switch (di.id) {
            case "@apps": return Shell.open("launchpad")
            case "@trash": return Quickshell.execDetached(["dolphin", "trash:/"])
            case "@downloads": return Quickshell.execDetached(["dolphin", Quickshell.env("HOME") + "/Downloads"])
            case "@min": return Hypr.restore(di.entry.win)
            }
            if (!di.running && !Settings.reduceMotion) { di.launching = true; hopAnim.restart() }
            Apps.activate(di.id)
        }
    }

    function menu() {
        if (id === "@trash") return [
            { text: "Open", run: () => Quickshell.execDetached(["dolphin", "trash:/"]) },
            { sep: true },
            { text: "Empty Trash", enabled: Trash.full, run: () => Shell.confirm = "trash" },
        ]
        if (id === "@downloads") return [
            { text: "Open in Finder", run: () => Quickshell.execDetached(["dolphin", Quickshell.env("HOME") + "/Downloads"]) },
        ]
        if (id === "@apps") return [{ text: "Open", run: () => Shell.open("launchpad") }]
        if (id === "@min") return [
            { text: "Restore", run: () => Hypr.restore(entry.win) },
            { text: "Close", run: () => Hypr.close(entry.win) },
        ]
        const items = wins.map(c => ({
            text: c.title.length > 44 ? c.title.slice(0, 43) + "…" : c.title,
            checked: c.address === Hypr.activeAddress,
            run: () => Hypr.focusWindow(c)
        }))
        if (items.length) items.push({ sep: true })
        const pinned = Settings.pinned.indexOf(id) >= 0
        items.push({ text: "New Window", run: () => Apps.launch(id) })
        items.push({ header: true, text: "Options" })
        items.push({ text: pinned ? "Remove from Dock" : "Keep in Dock", run: () => {
            Settings.pinned = pinned ? Settings.pinned.filter(p => p !== id) : Settings.pinned.concat([id])
        }})
        if (wins.length) {
            items.push({ text: "Show All Windows", run: () => Shell.open("mission") })
            items.push({ sep: true })
            items.push({ text: "Hide", run: () => Hypr.hideApp(wins[0].class) })
            items.push({ text: "Quit", run: () => Hypr.quitApp(wins[0].class) })
        }
        return items
    }
}
