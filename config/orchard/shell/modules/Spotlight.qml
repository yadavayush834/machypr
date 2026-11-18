import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"
import "../components"

// Spotlight (⌘Space). One field, ranked results from apps, maths, system
// actions, files and the clipboard; ⌘1–4 jump to a single source like
// macOS 26. ↑↓ choose, ↩ open, ⌘↩ reveal in Finder, ⎋ close.
PanelWindow {
    id: sp
    required property var modelData
    screen: modelData
    visible: Shell.spotlight
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "orchard-spotlight"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string mode: ""                   // "" | apps | files | actions | clipboard
    property string query: ""
    property int current: 0
    property var files: []
    property var clips: []

    onVisibleChanged: {
        if (visible) {
            mode = Shell.spotlightMode === "clipboard" ? "clipboard" : ""
            Shell.spotlightMode = ""
            field.text = ""; query = ""; current = 0
            field.forceActiveFocus()
            clipProc.running = true
        }
    }

    // ------------------------------------------------------------- sources
    readonly property var actions: [
        { title: "Lock Screen", icon: "lock", run: () => Quickshell.execDetached(["loginctl", "lock-session"]) },
        { title: "Sleep", icon: "sleep", run: () => Quickshell.execDetached(["systemctl", "suspend"]) },
        { title: "Restart…", icon: "restart", run: () => Shell.confirm = "restart" },
        { title: "Shut Down…", icon: "power", run: () => Shell.confirm = "shutdown" },
        { title: "Log Out…", icon: "logout", run: () => Shell.confirm = "logout" },
        { title: "Toggle Dark Mode", icon: "contrast", run: () => Settings.appearance = Settings.isDark ? "light" : "dark" },
        { title: "Toggle Do Not Disturb", icon: "moon", run: () => Settings.focusMode = !Settings.focusMode },
        { title: "Toggle Night Shift", icon: "nightshift", run: () => Settings.nightShift = !Settings.nightShift },
        { title: "Toggle Wi-Fi", icon: "wifi3", run: () => Net.toggle() },
        { title: "Empty Trash", icon: "trash", run: () => Shell.confirm = "trash" },
        { title: "Take Screenshot", icon: "camera", run: () => Shell.shotMenu = true },
        { title: "Mission Control", icon: "spaces", run: () => Shell.mission = true },
        { title: "Show Desktop", icon: "display", run: () => Hypr.here.forEach(c => Hypr.minimize(c)) },
        { title: "Force Quit Applications", icon: "xmark", run: () => Shell.forceQuit = true },
        { title: "System Settings", icon: "gear", run: () => Shell.settings = true },
        { title: "Keyboard Shortcuts", icon: "keyboard", run: () => Shell.shortcuts = true },
        { title: "About This Mac", icon: "app", run: () => Shell.about = true },
    ]

    function score(text, q) {
        if (!text) return 0
        const t = text.toLowerCase()
        if (t === q) return 100
        if (t.startsWith(q)) return 80
        if (t.split(/[\s\-_.]/).some(w => w.startsWith(q))) return 60
        if (t.indexOf(q) >= 0) return 40
        // initials ("vsc" -> Visual Studio Code)
        let i = 0
        for (const ch of t) if (ch === q[i]) i++
        return i === q.length ? 20 : 0
    }

    function calc(q) {
        let e = q.replace(/×/g, "*").replace(/÷/g, "/").replace(/\^/g, "**").replace(/,/g, "")
        if (!/^[\d\s+\-*/().%*]+$/.test(e) || !/\d/.test(e) || !/[+\-*/%]/.test(e)) return null
        try {
            const v = Function('"use strict"; return (' + e + ')')()
            if (typeof v !== "number" || !isFinite(v)) return null
            return +v.toPrecision(12)
        } catch (err) { return null }
    }

    readonly property var results: {
        const q = query.trim().toLowerCase()
        const out = []
        if (mode === "clipboard") {
            for (const c of clips) if (!q || c.text.toLowerCase().indexOf(q) >= 0)
                out.push({ group: "Clipboard", title: c.text, sym: "clipboard", run: () => Quickshell.execDetached(["sh", "-c", "cliphist decode " + c.id + " | wl-copy"]) })
            return out.slice(0, 40)
        }
        if (!q) {
            if (mode === "" || mode === "apps") {
                // suggestions: running + pinned apps, like Siri Suggestions
                const seen = []
                for (const id of Hypr.clients.map(c => c.class).concat(Settings.pinned)) {
                    const e = Apps.entry(id); if (!e || seen.indexOf(e.id) >= 0) continue
                    seen.push(e.id)
                    out.push({ group: "Siri Suggestions", title: Apps.name(id), sub: "Application", icon: Apps.icon(id), run: () => Apps.activate(id) })
                }
            }
            if (mode === "actions") for (const a of actions) out.push({ group: "Actions", title: a.title, sym: a.icon, run: a.run })
            return out.slice(0, mode ? 40 : 8)
        }

        const v = (mode === "") ? calc(q) : null
        if (v !== null) out.push({ group: "Calculator", title: v.toLocaleString(Qt.locale(), "f", -128).replace(/\.?0+$/, ""), big: true, sub: query.trim() + " =", sym: "calc",
                                   run: () => Quickshell.execDetached(["wl-copy", String(v)]) })

        if (mode === "" || mode === "apps") {
            const apps = []
            for (const e of Apps.all) {
                const s = Math.max(score(e.name, q), score(e.genericName, q) * 0.6, score(String(e.keywords), q) * 0.5, score(e.id, q) * 0.5)
                if (s > 0) apps.push({ s: s, e: e })
            }
            apps.sort((a, b) => b.s - a.s)
            for (const a of apps.slice(0, mode ? 30 : 6))
                out.push({ group: "Applications", title: Apps.aliases[a.e.id] ?? a.e.name, sub: a.e.genericName || a.e.comment || "Application",
                           icon: Quickshell.iconPath(a.e.icon, "application-x-executable"), run: () => Apps.activate(a.e.id) })
        }
        if (mode === "" || mode === "actions") {
            for (const a of actions) if (score(a.title, q) > 0)
                out.push({ group: "Actions", title: a.title, sym: a.icon, run: a.run })
        }
        if (mode === "" || mode === "files") {
            for (const f of files.slice(0, mode ? 40 : 6)) {
                const name = f.split("/").pop()
                out.push({ group: "Documents", title: name, sub: f.replace(Quickshell.env("HOME"), "~"), path: f,
                           icon: Quickshell.iconPath(f.endsWith("/") ? "folder" : Mime.iconFor(name), "text-x-generic"),
                           run: () => Quickshell.execDetached(["xdg-open", f]) })
            }
        }
        if (mode === "") {
            out.push({ group: "Web", title: "Search the web for “" + query.trim() + "”", sym: "globe",
                       run: () => Quickshell.execDetached(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(query.trim())]) })
        }
        return out
    }
    onResultsChanged: current = Math.min(current, Math.max(0, results.length - 1))

    Timer {
        id: fileDebounce; interval: 120
        onTriggered: {
            if (sp.query.trim().length < 2 || (sp.mode !== "" && sp.mode !== "files")) { sp.files = []; return }
            fileProc.running = false
            fileProc.command = ["fd", "--max-results", "60", "--max-depth", "6", "-i", "--exclude", "node_modules", "--exclude", ".cache",
                                "--exclude", ".local", "--exclude", ".git", "--", sp.query.trim(), Quickshell.env("HOME")]
            fileProc.running = true
        }
    }
    Process {
        id: fileProc
        stdout: StdioCollector { onStreamFinished: sp.files = text.split("\n").filter(l => l).sort((a, b) => a.length - b.length) }
    }
    Process {
        id: clipProc
        command: ["sh", "-c", "cliphist list | head -60"]
        stdout: StdioCollector {
            onStreamFinished: sp.clips = text.split("\n").filter(l => l).map(l => {
                const i = l.indexOf("\t"); return { id: l.slice(0, i), text: l.slice(i + 1) }
            })
        }
    }

    function run(i) {
        const r = results[i]; if (!r) return
        Shell.spotlight = false
        r.run()
    }

    // --------------------------------------------------------------- view
    MouseArea { anchors.fill: parent; onPressed: Shell.spotlight = false }

    Column {
        id: panel
        width: 680
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.22
        spacing: 10
        opacity: sp.visible ? 1 : 0
        scale: sp.visible ? 1 : 0.97
        Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Theme.ease } }

        Glass {
            width: parent.width; height: 56
            radius: 28
            tint: Theme.glassThick
            MouseArea { anchors.fill: parent }
            RowLayout {
                anchors { fill: parent; leftMargin: 20; rightMargin: 14 }
                spacing: 12
                Sym { name: "search"; size: 22; weight: 1.6; color: Theme.secondary }
                TextInput {
                    id: field
                    Layout.fillWidth: true
                    color: Theme.label
                    font.family: Theme.fontDisplay; font.pixelSize: 22; font.weight: Font.Normal
                    selectionColor: Theme.accent
                    clip: true
                    onTextChanged: { sp.query = text; sp.current = 0; fileDebounce.restart() }
                    Text {
                        visible: !field.text
                        text: sp.mode === "apps" ? "Applications" : sp.mode === "files" ? "Files" : sp.mode === "actions" ? "Actions"
                            : sp.mode === "clipboard" ? "Clipboard History" : "Spotlight Search"
                        color: Theme.tertiary; font: field.font
                    }
                    Keys.onPressed: e => {
                        const cmd = e.modifiers & Qt.MetaModifier
                        if (e.key === Qt.Key_Escape) { if (sp.mode && !field.text) sp.mode = ""; else if (field.text) field.text = ""; else Shell.spotlight = false; e.accepted = true }
                        else if (e.key === Qt.Key_Down || (e.key === Qt.Key_N && e.modifiers & Qt.ControlModifier)) { sp.current = Math.min(sp.results.length - 1, sp.current + 1); e.accepted = true }
                        else if (e.key === Qt.Key_Up || (e.key === Qt.Key_P && e.modifiers & Qt.ControlModifier)) { sp.current = Math.max(0, sp.current - 1); e.accepted = true }
                        else if (e.key === Qt.Key_Tab) { sp.current = (sp.current + 1) % Math.max(1, sp.results.length); e.accepted = true }
                        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                            const r = sp.results[sp.current]
                            if (cmd && r && r.path) { Shell.spotlight = false; Quickshell.execDetached(["dolphin", "--select", r.path]) }
                            else sp.run(sp.current)
                            e.accepted = true
                        }
                        else if (cmd && e.key >= Qt.Key_1 && e.key <= Qt.Key_4) {
                            const m = ["apps", "files", "actions", "clipboard"][e.key - Qt.Key_1]
                            sp.mode = sp.mode === m ? "" : m
                            if (m === "files") fileDebounce.restart()
                            e.accepted = true
                        }
                    }
                }
                Repeater {
                    model: [["apps", "app", "⌘1"], ["files", "folder", "⌘2"], ["actions", "bolt", "⌘3"], ["clipboard", "clipboard", "⌘4"]]
                    Rectangle {
                        required property var modelData
                        implicitWidth: 34; implicitHeight: 34; radius: 17
                        color: sp.mode === modelData[0] ? Theme.accent : chip.containsMouse ? Theme.hover : "transparent"
                        Sym { anchors.centerIn: parent; name: parent.modelData[1]; size: 17; color: sp.mode === parent.modelData[0] ? "white" : Theme.secondary }
                        MouseArea {
                            id: chip; anchors.fill: parent; hoverEnabled: true
                            onClicked: { sp.mode = sp.mode === parent.modelData[0] ? "" : parent.modelData[0]; fileDebounce.restart(); field.forceActiveFocus() }
                        }
                    }
                }
            }
        }

        Glass {
            visible: sp.results.length > 0 && (sp.query !== "" || sp.mode !== "" )
            width: parent.width
            height: Math.min(440, list.contentHeight + 16)
            radius: 24
            tint: Theme.glassThick
            MouseArea { anchors.fill: parent }
            ListView {
                id: list
                anchors { fill: parent; margins: 8 }
                clip: true
                model: sp.results
                currentIndex: sp.current
                highlightMoveDuration: 0
                boundsBehavior: Flickable.StopAtBounds
                delegate: Column {
                  id: wrap
                  required property var modelData
                  required property int index
                  width: list.width
                  Text {
                    visible: wrap.index === 0 || sp.results[wrap.index - 1].group !== wrap.modelData.group
                    text: wrap.modelData.group
                    leftPadding: 12; topPadding: wrap.index === 0 ? 2 : 8; bottomPadding: 3
                    color: Theme.secondary; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold
                  }
                  Rectangle {
                    id: rowItem
                    readonly property var modelData: wrap.modelData
                    readonly property int index: wrap.index
                    width: list.width
                    height: modelData.big ? 56 : 40
                    radius: 10
                    color: sp.current === index ? Theme.accent : "transparent"
                    readonly property bool sel: sp.current === index
                    RowLayout {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 12 }
                        spacing: 10
                        Item {
                            Layout.preferredWidth: 28; Layout.preferredHeight: 28
                            Image {
                                visible: !!rowItem.modelData.icon
                                anchors.fill: parent
                                source: rowItem.modelData.icon ?? ""
                                sourceSize: Qt.size(56, 56); smooth: true; mipmap: true; asynchronous: true
                            }
                            Sym {
                                visible: !rowItem.modelData.icon
                                anchors.centerIn: parent
                                name: rowItem.modelData.sym ?? "app"; size: 20
                                color: rowItem.sel ? "white" : Theme.label
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: rowItem.modelData.title
                            elide: Text.ElideRight
                            color: rowItem.sel ? "white" : Theme.label
                            font.family: rowItem.modelData.big ? Theme.fontDisplay : Theme.font
                            font.pixelSize: rowItem.modelData.big ? 26 : 14
                            font.weight: rowItem.modelData.big ? Font.Medium : Font.Normal
                        }
                        Text {
                            visible: !!rowItem.modelData.sub
                            Layout.maximumWidth: 260
                            text: rowItem.modelData.sub ?? ""
                            elide: Text.ElideMiddle
                            color: rowItem.sel ? Qt.rgba(1, 1, 1, 0.75) : Theme.secondary
                            font.family: Theme.font; font.pixelSize: 12
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onPositionChanged: sp.current = rowItem.index
                        onClicked: sp.run(rowItem.index)
                    }
                  }
                }
            }
        }
    }
}
