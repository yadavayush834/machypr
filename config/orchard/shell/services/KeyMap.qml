pragma Singleton
import QtQuick
import Quickshell

// ⌘ is the Super key. Menu items and ⌘-shortcuts are translated into what
// each Linux app actually listens for (Ctrl, or Ctrl+Shift in terminals).
Singleton {
    readonly property var terminals: ["footclient", "foot", "kitty", "Alacritty", "org.wezfm.wezterm", "com.mitchellh.ghostty"]
    function isTerm(cls) { return terminals.indexOf(cls) >= 0 }

    // action -> [mods, key]
    function chord(action, cls) {
        const t = isTerm(cls)
        switch (action) {
        case "copy":      return t ? ["CTRL SHIFT", "C"] : ["CTRL", "C"]
        case "paste":     return t ? ["CTRL SHIFT", "V"] : ["CTRL", "V"]
        case "cut":       return ["CTRL", "X"]
        case "undo":      return ["CTRL", "Z"]
        case "redo":      return ["CTRL SHIFT", "Z"]
        case "selectAll": return ["CTRL", "A"]
        case "find":      return t ? ["CTRL SHIFT", "F"] : ["CTRL", "F"]
        case "newWindow": return t ? ["CTRL SHIFT", "N"] : ["CTRL", "N"]
        case "newTab":    return t ? ["CTRL SHIFT", "T"] : ["CTRL", "T"]
        case "closeTab":  return ["CTRL", "W"]
        case "open":      return ["CTRL", "O"]
        case "save":      return ["CTRL", "S"]
        case "saveAs":    return ["CTRL SHIFT", "S"]
        case "print":     return ["CTRL", "P"]
        case "zoomIn":    return ["CTRL", "equal"]
        case "zoomOut":   return ["CTRL", "minus"]
        case "zoomReset": return ["CTRL", "0"]
        case "reload":    return ["CTRL", "R"]
        case "prefs":     return ["CTRL", "comma"]
        case "history":   return ["CTRL", "H"]
        case "bookmarks": return ["CTRL SHIFT", "O"]
        case "devtools":  return ["CTRL SHIFT", "I"]
        }
        return null
    }

    function send(action) {
        const cls = Hypr.activeClass
        if (action === "newWindow" && isTerm(cls)) return Quickshell.execDetached([Settings.bin + "term"])
        const c = chord(action, cls)
        if (!c) return
        // let the menu close and focus return to the app before the keys land
        Qt.callLater(() => Hypr.dispatch("hl.dsp.send_shortcut({ mods = \"" + c[0] + "\", key = \"" + c[1] + "\" })"))
    }
}
