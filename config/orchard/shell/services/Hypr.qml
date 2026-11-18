pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// One source of truth for windows. Hyprland pushes events; we re-read
// `hyprctl clients -j` (debounced) so every surface sees the same model.
Singleton {
    id: h

    property var clients: []            // raw hyprctl objects, focus order (MRU first)
    property int activeWs: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    property string activeAddress: ""
    readonly property var active: clients.find(c => c.address === activeAddress) ?? null
    readonly property string activeClass: active ? active.class : ""
    readonly property bool activeIsMax: !!active && (active.fullscreen === 1 || active.size[1] > 560)
    property var workspaceIds: [1]

    // windows on the current desktop, not minimised
    readonly property var here: clients.filter(c => c.workspace.id === activeWs)
    readonly property var minimized: clients.filter(c => c.workspace.name === "special:minimized")

    function dispatch(lua) {
        Quickshell.execDetached(["hyprctl", "eval", "hl.dispatch(" + lua + ")"])
    }
    function sel(address) { return "{ window = \"address:" + address + "\" }" }

    function focusWindow(c) {
        if (c.workspace.name === "special:minimized")
            return restore(c)
        dispatch("hl.dsp.focus(" + sel(c.address) + ")")
        dispatch("hl.dsp.window.bring_to_top()")
    }
    function close(c) { dispatch("hl.dsp.window.close(" + sel(c.address) + ")") }
    function minimize(c) {
        c = c ?? active; if (!c) return
        dispatch("hl.dsp.window.move({ workspace = \"special:minimized\", follow = false, window = \"address:" + c.address + "\" })")
    }
    function restore(c) {
        dispatch("hl.dsp.window.move({ workspace = " + activeWs + ", window = \"address:" + c.address + "\" })")
        dispatch("hl.dsp.focus(" + sel(c.address) + ")")
    }
    // Quit = close every window of the app (what ⌘Q means on macOS).
    function quitApp(cls) {
        for (const c of clients) if (c.class === cls) close(c)
    }
    function hideApp(cls) {
        for (const c of here) if (c.class === cls) minimize(c)
    }
    function hideOthers(cls) {
        for (const c of here) if (c.class !== cls) minimize(c)
    }
    function windowsOf(cls) { return clients.filter(c => c.class === cls) }
    function goWorkspace(id) { dispatch("hl.dsp.focus({ workspace = " + id + " })") }

    // macOS window tiling (Sequoia): fill, halves, centre.
    function tile(how) {
        if (!active) return
        const m = Hyprland.focusedMonitor
        const sw = m ? m.width / m.scale : 1280, sh = m ? m.height / m.scale : 720
        const w = sw, top = Theme.barHeight + 6, dockH = Settings.dockAutohide ? 6 : Settings.dockIconSize + 30
        const H = sh - top - dockH, g = 6
        const rects = {
            fill:   [g, top, w - 2 * g, H],
            left:   [g, top, w / 2 - 1.5 * g, H],
            right:  [w / 2 + g / 2, top, w / 2 - 1.5 * g, H],
            center: [w * 0.16, top + H * 0.06, w * 0.68, H * 0.88],
        }
        const r = rects[how]; if (!r) return
        dispatch("hl.dsp.window.float({ action = \"enable\" })")
        dispatch("hl.dsp.window.resize({ x = " + Math.round(r[2]) + ", y = " + Math.round(r[3]) + " })")
        dispatch("hl.dsp.window.move({ x = " + Math.round(r[0]) + ", y = " + Math.round(r[1]) + " })")
    }

    function refresh() { debounce.restart() }

    Timer { id: debounce; interval: 40; onTriggered: { if (!proc.running) proc.running = true; else again = true } }
    property bool again: false

    Process {
        id: proc
        command: ["sh", "-c", "hyprctl -j clients; printf '\\036'; hyprctl -j activewindow; printf '\\036'; hyprctl -j workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("\x1e")
                try {
                    const all = JSON.parse(parts[0]).filter(c => c.mapped && c.class !== "")
                    all.sort((a, b) => a.focusHistoryID - b.focusHistoryID)
                    h.clients = all
                } catch (e) {}
                try { h.activeAddress = JSON.parse(parts[1]).address ?? "" } catch (e) { h.activeAddress = "" }
                try {
                    const ws = JSON.parse(parts[2]).filter(w => w.id > 0).map(w => w.id)
                    if (ws.indexOf(h.activeWs) < 0) ws.push(h.activeWs)
                    ws.sort((a, b) => a - b)
                    h.workspaceIds = ws
                } catch (e) {}
            }
        }
        onExited: if (h.again) { h.again = false; running = true }
    }

    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            switch (ev.name) {
            case "openwindow": case "closewindow": case "movewindow": case "movewindowv2":
            case "activewindowv2": case "windowtitlev2": case "workspacev2": case "fullscreen":
            case "changefloatingmode": case "createworkspacev2": case "destroyworkspacev2":
            case "focusedmonv2":
                h.refresh()
            }
        }
    }

    Component.onCompleted: refresh()
}
