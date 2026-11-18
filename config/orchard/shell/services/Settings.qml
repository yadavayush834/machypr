pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// User preferences, persisted to ~/.local/state/orchard/settings.json.
// System Settings, Control Center and the Apple menu all write here.
Singleton {
    id: s

    readonly property string bin: Quickshell.env("HOME") + "/.config/orchard/bin/"
    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/orchard"

    property alias appearance: data.appearance          // "auto" | "light" | "dark"
    property alias dockMagnify: data.dockMagnify
    property alias dockAutohide: data.dockAutohide
    property alias dockIconSize: data.dockIconSize
    property alias pinned: data.pinned
    property alias focusMode: data.focusMode            // Do Not Disturb
    property alias reduceMotion: data.reduceMotion
    property alias nightShift: data.nightShift
    property alias showRecents: data.showRecents
    property alias hotCorners: data.hotCorners
    property alias wallpaper: data.wallpaper

    // Auto appearance follows the day: light 07:00–19:00, like macOS
    // "Auto" without location services.
    property int hour: new Date().getHours()
    readonly property bool isDark: appearance === "dark" || (appearance === "auto" && (hour < 7 || hour >= 19))

    // Set by the wallpaper luminance probe; keeps menu bar text legible.
    property bool barOnLight: false

    onIsDarkChanged: applyAppearance()

    function applyAppearance() {
        Quickshell.execDetached([bin + "appearance", isDark ? "dark" : "light"])
    }

    Timer {
        interval: 60000; running: true; repeat: true
        onTriggered: s.hour = new Date().getHours()
    }

    FileView {
        id: file
        path: s.stateDir + "/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter() }

        JsonAdapter {
            id: data
            property string appearance: "auto"
            property bool dockMagnify: true
            property bool dockAutohide: false
            property int dockIconSize: 50
            property list<string> pinned: [
                "org.kde.dolphin", "brave-browser", "footclient", "com.microsoft.VSCode",
                "antigravity", "discord", "org.telegram.desktop"
            ]
            property bool focusMode: false
            property bool reduceMotion: false
            property bool nightShift: false
            property bool showRecents: true
            property bool hotCorners: true
            property string wallpaper: ""
        }
    }

    Component.onCompleted: applyAppearance()
}
