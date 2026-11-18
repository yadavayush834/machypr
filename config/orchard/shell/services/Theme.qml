pragma Singleton
import QtQuick
import Quickshell

// Every visual constant lives here. Numbers follow macOS 26 (Tahoe):
// 13pt system text, 24pt menu bar, continuous-corner glass, #0A84FF accent.
Singleton {
    id: t

    readonly property bool dark: Settings.isDark

    // ---- type -------------------------------------------------------------
    // SF Pro if the user installed it, otherwise Inter (the closest open
    // relative: same grotesque skeleton, tuned optical sizes).
    readonly property string font: Qt.fontFamilies().indexOf("SF Pro Text") >= 0 ? "SF Pro Text" : "Inter"
    readonly property string fontDisplay: Qt.fontFamilies().indexOf("SF Pro Display") >= 0 ? "SF Pro Display"
                                        : (Qt.fontFamilies().indexOf("Inter Display") >= 0 ? "Inter Display" : font)
    readonly property string fontMono: Qt.fontFamilies().indexOf("SF Mono") >= 0 ? "SF Mono" : "JetBrainsMono Nerd Font"
    readonly property int textSize: 13          // px == pt on macOS @1x
    // SF Pro Text is tracked tighter than Inter at UI sizes; close the gap
    readonly property real tracking: font === "Inter" ? -0.18 : 0
    readonly property int smallSize: 11

    // ---- colour -----------------------------------------------------------
    readonly property color accent: dark ? "#0A84FF" : "#007AFF"
    readonly property color red:    dark ? "#FF453A" : "#FF3B30"
    readonly property color orange: dark ? "#FF9F0A" : "#FF9500"
    readonly property color yellow: dark ? "#FFD60A" : "#FFCC00"
    readonly property color green:  dark ? "#30D158" : "#34C759"
    readonly property color purple: dark ? "#BF5AF2" : "#AF52DE"

    readonly property color label:     dark ? Qt.rgba(1, 1, 1, 0.88) : Qt.rgba(0, 0, 0, 0.86)
    readonly property color secondary: dark ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(0, 0, 0, 0.50)
    readonly property color tertiary:  dark ? Qt.rgba(1, 1, 1, 0.28) : Qt.rgba(0, 0, 0, 0.26)
    readonly property color separator: dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.10)

    // Glass: tinted base + 1px specular rim. The compositor supplies the blur.
    readonly property color glass:      dark ? Qt.rgba(0.11, 0.11, 0.12, 0.62) : Qt.rgba(0.97, 0.97, 0.98, 0.66)
    readonly property color glassThick: dark ? Qt.rgba(0.13, 0.13, 0.14, 0.80) : Qt.rgba(0.98, 0.98, 0.99, 0.82)
    readonly property color tile:       dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.55)
    readonly property color tileHover:  dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.80)
    readonly property color rimTop:     dark ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.90)
    readonly property color rimBottom:  dark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.06)
    readonly property color outline:    dark ? Qt.rgba(0, 0, 0, 0.55) : Qt.rgba(0, 0, 0, 0.12)
    readonly property color hover:      dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)

    // Menu bar text sits directly on the wallpaper (Tahoe has no bar fill).
    readonly property color barText: Settings.barOnLight ? Qt.rgba(0, 0, 0, 0.85) : "white"

    // ---- shape --------------------------------------------------------------
    readonly property int barHeight: 24
    readonly property int menuRadius: 12
    readonly property int panelRadius: 22
    readonly property int tileRadius: 16
    readonly property int dockRadius: 26

    // ---- motion -------------------------------------------------------------
    // Apple's default "smooth" spring with zero bounce is ~ OutCubic over
    // 0.35s; quick UI (hover, menus) settles in ~0.15s. Nothing overshoots.
    readonly property int quick: Settings.reduceMotion ? 0 : 140
    readonly property int normal: Settings.reduceMotion ? 0 : 240
    readonly property int slow: Settings.reduceMotion ? 0 : 380
    readonly property int ease: Easing.OutCubic
    readonly property int easeInOut: Easing.InOutCubic
}
