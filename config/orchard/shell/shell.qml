//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma IconTheme MacTahoe
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=12000
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "services"
import "modules"
import "components"

// Orchard — a macOS 26 desktop for Hyprland, in one Quickshell process.
ShellRoot {
    Variants { model: Quickshell.screens; Background {} }
    Variants { model: Quickshell.screens; MenuBar {} }
    Variants { model: Quickshell.screens; Dock {} }
    Variants { model: Quickshell.screens; Banners {} }
    Variants { model: Quickshell.screens; Hud {} }
    Variants { model: Quickshell.screens; Popups {} }
    Variants { model: Quickshell.screens; AppSwitcher {} }
    // heavy surfaces exist only while open
    Lazy { when: Shell.spotlight; surface: Component { Spotlight {} } }
    Lazy { when: Shell.launchpad; surface: Component { Launchpad {} } }
    Lazy { when: Shell.mission; surface: Component { MissionControl {} } }
    Lazy { when: Shell.about || Shell.forceQuit || Shell.confirm !== "" || Shell.shortcuts || Shell.shotMenu; surface: Component { Dialogs {} } }
    Lazy { when: Shell.settings; grace: 0; surface: Component { SystemSettings {} } }

    // keyboard entry points (Hyprland: hl.dsp.global("orchard:<name>"))
    GlobalShortcut { appid: "orchard"; name: "spotlight";     onPressed: Shell.open("spotlight") }
    GlobalShortcut { appid: "orchard"; name: "clipboard";     onPressed: { Shell.spotlightMode = "clipboard"; Shell.closeAll(); Shell.spotlight = true } }
    GlobalShortcut { appid: "orchard"; name: "launchpad";     onPressed: Shell.open("launchpad") }
    GlobalShortcut { appid: "orchard"; name: "mission";       onPressed: Shell.open("mission") }
    GlobalShortcut { appid: "orchard"; name: "control";       onPressed: { Shell.popupX = 99999; Shell.toggle("control") } }
    GlobalShortcut { appid: "orchard"; name: "notifications"; onPressed: Shell.toggle("notifications") }
    GlobalShortcut { appid: "orchard"; name: "forcequit";     onPressed: Shell.open("forceQuit") }
    GlobalShortcut { appid: "orchard"; name: "shortcuts";     onPressed: Shell.open("shortcuts") }
    GlobalShortcut { appid: "orchard"; name: "screenshot";    onPressed: Shell.open("shotMenu") }
    GlobalShortcut { appid: "orchard"; name: "settings";      onPressed: Shell.settings = !Shell.settings }
    GlobalShortcut { appid: "orchard"; name: "dock";          onPressed: Settings.dockAutohide = !Settings.dockAutohide }
    GlobalShortcut { appid: "orchard"; name: "hide";          onPressed: Hypr.hideApp(Hypr.activeClass) }
    GlobalShortcut { appid: "orchard"; name: "hideothers";    onPressed: Hypr.hideOthers(Hypr.activeClass) }
    GlobalShortcut { appid: "orchard"; name: "quit";          onPressed: Hypr.quitApp(Hypr.activeClass) }
    GlobalShortcut { appid: "orchard"; name: "minimize";      onPressed: Hypr.minimize() }
    GlobalShortcut { appid: "orchard"; name: "fill";          onPressed: Hypr.tile("fill") }
    GlobalShortcut { appid: "orchard"; name: "center";        onPressed: Hypr.tile("center") }
    GlobalShortcut { appid: "orchard"; name: "tileleft";      onPressed: Hypr.tile("left") }
    GlobalShortcut { appid: "orchard"; name: "tileright";     onPressed: Hypr.tile("right") }
    GlobalShortcut { appid: "orchard"; name: "showdesktop";   onPressed: Hypr.here.forEach(c => Hypr.minimize(c)) }
    GlobalShortcut { appid: "orchard"; name: "about";         onPressed: Shell.open("about") }
    GlobalShortcut { appid: "orchard"; name: "escape";        onPressed: Shell.closeAll() }

    IpcHandler {
        target: "shell"
        function open(what: string): void { Shell.open(what) }
        function popup(name: string): void { Shell.toggle(name) }
        function appearance(mode: string): void { Settings.appearance = mode }
        function confirm(what: string): void { Shell.closeAll(); Shell.confirm = what }
    }

    // Hot corners (macOS defaults): top-left Mission Control, bottom-right Desktop
    HotCorners {}

    Connections {
        target: Settings
        function onNightShiftChanged() { Quickshell.execDetached([Settings.bin + "night", Settings.nightShift ? "on" : "off"]) }
    }
}
