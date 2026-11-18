pragma Singleton
import QtQuick
import Quickshell

// Menu definitions. ⌘ = Super, ⌥ = Alt, ⌃ = Ctrl, ⇧ = Shift.
// App menus send each app the shortcut it really understands (Keys.qml).
Singleton {
    function items(name) {
        const app = Apps.name(Hypr.activeClass || "Finder")
        const cls = Hypr.activeClass
        const has = Hypr.active !== null
        const user = Quickshell.env("USER")
        const k = a => () => KeyMap.send(a)
        switch (name) {
        case "apple": return [
            { text: "About This Mac", run: () => Shell.about = true },
            { sep: true },
            { text: "System Settings…", run: () => Shell.settings = true },
            { text: "App Store…", run: () => Quickshell.execDetached([Settings.bin + "term", "-e", "sh", "-c", "sudo pacman -Syu; read -n1 -p 'Done. Press any key'"]) },
            { sep: true },
            { text: "Force Quit…", keys: "⌥⌘⎋", run: () => Shell.open("forceQuit") },
            { sep: true },
            { text: "Sleep", run: () => Quickshell.execDetached(["systemctl", "suspend"]) },
            { text: "Restart…", run: () => Shell.confirm = "restart" },
            { text: "Shut Down…", run: () => Shell.confirm = "shutdown" },
            { sep: true },
            { text: "Lock Screen", keys: "⌃⌘Q", run: () => Quickshell.execDetached(["loginctl", "lock-session"]) },
            { text: "Log Out " + user + "…", keys: "⇧⌘Q", run: () => Shell.confirm = "logout" },
        ]
        case "app": return [
            { text: "About " + app, enabled: has, run: () => Shell.about = true },
            { sep: true },
            { text: "Settings…", keys: "⌘,", enabled: has, run: k("prefs") },
            { sep: true },
            { text: "Hide " + app, keys: "⌘H", enabled: has, run: () => Hypr.hideApp(cls) },
            { text: "Hide Others", keys: "⌥⌘H", enabled: has, run: () => Hypr.hideOthers(cls) },
            { text: "Show All", enabled: Hypr.minimized.length > 0, run: () => Hypr.minimized.forEach(c => Hypr.restore(c)) },
            { sep: true },
            { text: "Quit " + app, keys: "⌘Q", enabled: has, run: () => Hypr.quitApp(cls) },
        ]
        case "File": return [
            { text: "New Window", keys: "⌘N", enabled: has, run: k("newWindow") },
            { text: "New Tab", keys: "⌘T", enabled: has, run: k("newTab") },
            { text: "Open…", keys: "⌘O", enabled: has, run: k("open") },
            { sep: true },
            { text: "Close Window", keys: "⇧⌘W", enabled: has, run: () => Hypr.close(Hypr.active) },
            { text: "Close Tab", keys: "⌘W", enabled: has, run: k("closeTab") },
            { text: "Save", keys: "⌘S", enabled: has, run: k("save") },
            { text: "Save As…", keys: "⇧⌘S", enabled: has, run: k("saveAs") },
            { sep: true },
            { text: "Print…", keys: "⌘P", enabled: has, run: k("print") },
        ]
        case "Edit": return [
            { text: "Undo", keys: "⌘Z", enabled: has, run: k("undo") },
            { text: "Redo", keys: "⇧⌘Z", enabled: has, run: k("redo") },
            { sep: true },
            { text: "Cut", keys: "⌘X", enabled: has, run: k("cut") },
            { text: "Copy", keys: "⌘C", enabled: has, run: k("copy") },
            { text: "Paste", keys: "⌘V", enabled: has, run: k("paste") },
            { text: "Select All", keys: "⌘A", enabled: has, run: k("selectAll") },
            { sep: true },
            { text: "Find…", keys: "⌘F", enabled: has, run: k("find") },
            { text: "Clipboard History…", keys: "⇧⌘V", run: () => { Shell.spotlightMode = "clipboard"; Shell.open("spotlight") } },
        ]
        case "View": return [
            { text: "Enter Full Screen", keys: "⌃⌘F", enabled: has, run: () => Hypr.dispatch("hl.dsp.window.fullscreen({ mode = \"fullscreen\" })") },
            { sep: true },
            { text: "Zoom In", keys: "⌘+", enabled: has, run: k("zoomIn") },
            { text: "Zoom Out", keys: "⌘−", enabled: has, run: k("zoomOut") },
            { text: "Actual Size", keys: "⌘0", enabled: has, run: k("zoomReset") },
            { sep: true },
            { text: "Reload", keys: "⌘R", enabled: has, run: k("reload") },
            { sep: true },
            { text: "Mission Control", keys: "⌃↑", run: () => Shell.open("mission") },
            { text: "Show Desktop", keys: "F11", run: () => Hypr.here.forEach(c => Hypr.minimize(c)) },
        ]
        case "Window": {
            const wins = Hypr.windowsOf(cls).map(c => ({
                text: c.title.length > 48 ? c.title.slice(0, 47) + "…" : c.title,
                checked: c.address === Hypr.activeAddress,
                run: () => Hypr.focusWindow(c)
            }))
            return [
                { text: "Minimize", keys: "⌘M", enabled: has, run: () => Hypr.minimize() },
                { text: "Zoom", enabled: has, run: () => Hypr.dispatch("hl.dsp.window.fullscreen({ mode = \"maximized\" })") },
                { text: "Fill", keys: "⌃⌥F", enabled: has, run: () => Hypr.tile("fill") },
                { text: "Center", keys: "⌃⌥C", enabled: has, run: () => Hypr.tile("center") },
                { sep: true },
                { header: true, text: "Move & Resize" },
                { text: "Left", keys: "⌃⌥←", enabled: has, run: () => Hypr.tile("left") },
                { text: "Right", keys: "⌃⌥→", enabled: has, run: () => Hypr.tile("right") },
                { sep: true },
                { text: "Move to Next Desktop", enabled: has, run: () => Hypr.dispatch("hl.dsp.window.move({ workspace = \"r+1\" })") },
                { text: "Float on Top", checked: has && Hypr.active.pinned, enabled: has, run: () => Hypr.dispatch("hl.dsp.window.pin()") },
                { text: "Bring All to Front", enabled: has, run: () => Hypr.windowsOf(cls).forEach(c => Hypr.focusWindow(c)) },
                { sep: true },
            ].concat(wins)
        }
        case "desktop": return [
            { text: "New Finder Window", run: () => Quickshell.execDetached(["dolphin"]) },
            { text: "Open Terminal Here", run: () => Quickshell.execDetached([Settings.bin + "term"]) },
            { sep: true },
            { text: "Mission Control", run: () => Shell.open("mission") },
            { text: "Show Desktop", run: () => Hypr.here.forEach(c => Hypr.minimize(c)) },
            { sep: true },
            { text: "Change Wallpaper…", run: () => { Shell.settingsPage = "wallpaper"; Shell.settings = true } },
            { text: Settings.isDark ? "Switch to Light Appearance" : "Switch to Dark Appearance",
              run: () => Settings.appearance = Settings.isDark ? "light" : "dark" },
        ]
        case "Help": return [
            { text: "Keyboard Shortcuts", keys: "⌘/", run: () => Shell.open("shortcuts") },
            { text: app + " Help", enabled: has, run: () => Quickshell.execDetached(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(app + " help")]) },
            { text: "Arch Wiki", run: () => Quickshell.execDetached(["xdg-open", "https://wiki.archlinux.org"]) },
        ]
        }
        return []
    }
}
