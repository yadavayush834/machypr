import QtQuick
import QtQuick.Shapes

// SF-Symbols-style glyphs drawn as vector paths on a 24x24 grid, so they
// stay sharp at any scale and take any colour (no icon font, no PNGs).
Item {
    id: root
    property string name: "search"
    property real size: 16
    property color color: "white"
    property real weight: 1.7
    property bool filled: false

    implicitWidth: size
    implicitHeight: size

    readonly property var paths: ({
        "search":   "M10.5 4a6.5 6.5 0 1 0 0 13a6.5 6.5 0 1 0 0-13M15.4 15.4L20.5 20.5",
        "wifi3":    "M2.6 9.2a13.5 13.5 0 0 1 18.8 0M5.6 12.4a9.2 9.2 0 0 1 12.8 0M8.6 15.6a4.9 4.9 0 0 1 6.8 0M12 19.4v0.1",
        "wifi2":    "M5.6 12.4a9.2 9.2 0 0 1 12.8 0M8.6 15.6a4.9 4.9 0 0 1 6.8 0M12 19.4v0.1",
        "wifi1":    "M8.6 15.6a4.9 4.9 0 0 1 6.8 0M12 19.4v0.1",
        "wifioff":  "M2.6 9.2a13.5 13.5 0 0 1 18.8 0M5.6 12.4a9.2 9.2 0 0 1 12.8 0M8.6 15.6a4.9 4.9 0 0 1 6.8 0M12 19.4v0.1M3 3L21 21",
        "ethernet": "M5 4h14v11H5zM9 15v4h6v-4M8 8v3M12 8v3M16 8v3",
        "bluetooth":"M7 7l10 10l-5 4.5V2.5L17 7L7 17",
        "control":  "M7 4.5h10a3.5 3.5 0 0 1 0 7H7a3.5 3.5 0 0 1 0-7zM7 6.6a1.4 1.4 0 1 0 0 2.8a1.4 1.4 0 1 0 0-2.8M7 12.5h10a3.5 3.5 0 0 1 0 7H7a3.5 3.5 0 0 1 0-7zM17 14.6a1.4 1.4 0 1 0 0 2.8a1.4 1.4 0 1 0 0-2.8",
        "moon":     "M20 14.5A8.5 8.5 0 1 1 9.5 4a7 7 0 0 0 10.5 10.5z",
        "sun":      "M12 8a4 4 0 1 0 0 8a4 4 0 1 0 0-8M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4",
        "speaker":  "M4 9.5h3.5L12 5.5v13l-4.5-4H4zM15.5 9a4 4 0 0 1 0 6M18 6.5a7.5 7.5 0 0 1 0 11",
        "mute":     "M4 9.5h3.5L12 5.5v13l-4.5-4H4zM16 9.5l5 5M21 9.5l-5 5",
        "bolt":     "M13 2L5 13.5h6L10 22l8-11.5h-6z",
        "play":     "M7 4.5v15l12.5-7.5z",
        "pause":    "M7 4.5h3.5v15H7zM13.5 4.5H17v15h-3.5z",
        "next":     "M3.5 5.5v13l8-6.5zM12.5 5.5v13l8-6.5z",
        "prev":     "M20.5 5.5v13l-8-6.5zM11.5 5.5v13l-8-6.5z",
        "chevron":  "M9 5l7 7l-7 7",
        "chevdown": "M5 9l7 7l7-7",
        "check":    "M5 12.5l4.5 4.5L19 7",
        "power":    "M12 3v8M7.1 6.2a7.5 7.5 0 1 0 9.8 0",
        "lock":     "M6 11h12v9.5H6zM8.5 11V8a3.5 3.5 0 0 1 7 0v3",
        "gear":     "M12 9a3 3 0 1 0 0 6a3 3 0 1 0 0-6M12 2.5l1.6 2.6l3-.7l.7 3l2.6 1.6l-1.5 2.6l1.5 2.6l-2.6 1.6l-.7 3l-3-.7L12 21.5l-1.6-2.6l-3 .7l-.7-3l-2.6-1.6L5.6 12L4.1 9.4l2.6-1.6l.7-3l3 .7z",
        "bell":     "M6 16.5V11a6 6 0 0 1 12 0v5.5l1.5 2h-15zM10 20.5a2 2 0 0 0 4 0",
        "display":  "M3 4.5h18v12H3zM9 20.5h6M12 16.5v4",
        "keyboard": "M2.5 6h19v12h-19zM6 9.5h.1M9.5 9.5h.1M13 9.5h.1M16.5 9.5h.1M7.5 14.5h9",
        "camera":   "M3 8h4l1.5-2.5h7L17 8h4v11H3zM12 10.5a3.2 3.2 0 1 0 0 6.4a3.2 3.2 0 1 0 0-6.4",
        "grid":     "M4 4h4v4H4zM10 4h4v4h-4zM16 4h4v4h-4zM4 10h4v4H4zM10 10h4v4h-4zM16 10h4v4h-4zM4 16h4v4H4zM10 16h4v4h-4zM16 16h4v4h-4z",
        "xmark":    "M6 6l12 12M18 6L6 18",
        "clipboard":"M8 4.5H6v16h12v-16h-2M9 3h6v3H9z",
        "calc":     "M5 3h14v18H5zM8 6.5h8v3H8zM8.5 13h.1M12 13h.1M15.5 13h.1M8.5 17h.1M12 17h.1M15.5 17h.1",
        "doc":      "M6 3h8l4 4v14H6zM14 3v4h4",
        "folder":   "M3 6.5h6l2 2h10v11H3z",
        "globe":    "M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18M3 12h18M12 3c3 3.2 3 14.8 0 18M12 3c-3 3.2-3 14.8 0 18",
        "airplane": "M10.5 3.5c0-1 3-1 3 0V9l7.5 4.5v2l-7.5-2.3V18l2 1.6V21L12 20l-3.5 1v-1.4l2-1.6v-4.8L3 15.5v-2L10.5 9z",
        "eye":      "M2.5 12s3.5-6.5 9.5-6.5s9.5 6.5 9.5 6.5s-3.5 6.5-9.5 6.5S2.5 12 2.5 12zM12 9a3 3 0 1 0 0 6a3 3 0 1 0 0-6",
        "spaces":   "M3 6h8v6H3zM13 6h8v6h-8zM3 14h18v4H3z",
        "trash":    "M4 6.5h16M9 6.5V4h6v2.5M6 6.5l1 14h10l1-14",
        "plus":     "M12 5v14M5 12h14",
        "minus":    "M5 12h14",
        "sidebar":  "M3 5h18v14H3zM9 5v14",
        "dnd":      "M20 14.5A8.5 8.5 0 1 1 9.5 4a7 7 0 0 0 10.5 10.5z",
        "contrast": "M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18M12 3v18",
        "music":    "M9 18V5.5l11-2V16M9 18a2.5 2.5 0 1 1-5 0a2.5 2.5 0 1 1 5 0M20 16a2.5 2.5 0 1 1-5 0a2.5 2.5 0 1 1 5 0",
        "person":   "M12 4a4 4 0 1 0 0 8a4 4 0 1 0 0-8M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7",
        "restart":  "M19.5 12a7.5 7.5 0 1 1-2.2-5.3M19.5 4v4.5H15",
        "logout":   "M14 4h5v16h-5M10 8l-4 4l4 4M6 12h10",
        "sleep":    "M20 14.5A8.5 8.5 0 1 1 9.5 4a7 7 0 0 0 10.5 10.5z",
        "battery":  "M3 7h16v10H3zM21 10.5v3",
        "copy":     "M8 8h12v12H8zM16 8V4H4v12h4",
        "link":     "M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1",
        "record":   "M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18M12 8a4 4 0 1 0 0 8a4 4 0 1 0 0-8",
        "screen":   "M3 4.5h18v12H3zM9 20.5h6",
        "region":   "M4 8V4h4M16 4h4v4M20 16v4h-4M8 20H4v-4",
        "window":   "M3 5h18v14H3zM3 9h18",
        "timer":    "M12 7v5l3 2M12 3.5a8.5 8.5 0 1 0 0 17a8.5 8.5 0 1 0 0-17M10 1.5h4",
        "nightshift": "M12 3v1.5M5.6 5.6l1 1M3 12h1.5M12 7.5a4.5 4.5 0 0 0 0 9M20 14.5A6 6 0 0 1 13.5 6a4.5 4.5 0 1 0 6.5 8.5z",
        "app":      "M5 3h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z",
    })

    Shape {
        anchors.centerIn: parent
        width: 24; height: 24
        scale: root.size / 24
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: root.filled ? "transparent" : root.color
            fillColor: root.filled ? root.color : "transparent"
            strokeWidth: root.weight * 24 / Math.max(root.size, 1) * (root.size / 16)
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: root.paths[root.name] ?? "" }
        }
    }
}
