pragma Singleton
import QtQuick
import Quickshell

// Window class <-> .desktop entry, names, icons, launching.
Singleton {
    id: a

    // Roles macOS users expect to see by name.
    readonly property var aliases: ({
        "org.kde.dolphin": "Finder", "dolphin": "Finder",
        "footclient": "Terminal", "foot": "Terminal", "kitty": "Terminal",
        "brave-browser": "Brave Browser", "code": "Code", "Code": "Code",
        "com.microsoft.VSCode": "Code", "org.quickshell": "System Settings",
    })

    property var cache: ({})

    function entry(id) {
        if (!id) return null
        if (cache[id]) return cache[id]
        void DesktopEntries.applications.values.length   // re-run bindings once entries load
        let e = DesktopEntries.byId(id)
        if (!e) e = DesktopEntries.heuristicLookup(id)
        if (e) cache[id] = e
        return e ?? null
    }
    function name(id) {
        if (aliases[id]) return aliases[id]
        const e = entry(id)
        if (e && e.id && aliases[e.id]) return aliases[e.id]
        return e ? e.name : (id.split(".").pop() || id)
    }
    function icon(id) {
        const e = entry(id)
        const n = e ? e.icon : id
        return Quickshell.iconPath(n, true) || Quickshell.iconPath(id.toLowerCase(), true)
               || Quickshell.iconPath("application-x-executable")
    }
    // the canonical class a desktop id runs as (so pinned and running merge)
    function matches(id, cls) {
        if (!cls) return false
        if (id === cls || id.toLowerCase() === cls.toLowerCase()) return true
        const e = entry(id)
        if (!e) return false
        if (e.startupClass && e.startupClass.toLowerCase() === cls.toLowerCase()) return true
        const viaCls = entry(cls)
        return !!viaCls && viaCls.id === e.id
    }

    function launch(id) {
        if (id === "footclient" || id === "foot")
            return Quickshell.execDetached([Settings.bin + "term"])
        const e = entry(id)
        if (e) e.execute()
        else Quickshell.execDetached(["sh", "-c", id])
    }

    // macOS click-on-dock semantics: launch if not running, focus if not
    // frontmost, cycle windows if already frontmost, restore if minimised.
    function activate(id) {
        const wins = Hypr.clients.filter(c => matches(id, c.class))
        if (!wins.length) return launch(id)
        const local = wins.filter(c => c.workspace.id === Hypr.activeWs)
        if (local.length) {
            if (Hypr.active && matches(id, Hypr.activeClass) && local.length > 1)
                return Hypr.focusWindow(local[local.length - 1])
            return Hypr.focusWindow(local[0])
        }
        const mins = wins.filter(c => c.workspace.name === "special:minimized")
        if (mins.length) return Hypr.restore(mins[0])
        Hypr.focusWindow(wins[0])        // lives on another desktop: switch there
    }

    readonly property var all: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .sort((x, y) => x.name.localeCompare(y.name))
}
