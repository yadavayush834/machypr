pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Watches ~/.local/share/Trash so the Dock icon shows full / empty.
Singleton {
    id: t
    property bool full: false
    function check() { probe.running = true }
    function empty() {
        Quickshell.execDetached(["sh", "-c", "rm -rf ~/.local/share/Trash/files/* ~/.local/share/Trash/files/.[!.]* ~/.local/share/Trash/info/*"])
        Quickshell.execDetached([Settings.bin + "sound", "trash"])
        full = false
    }
    Process {
        id: probe
        command: ["sh", "-c", "ls -A ~/.local/share/Trash/files 2>/dev/null | head -1"]
        stdout: StdioCollector { onStreamFinished: t.full = text.trim() !== "" }
    }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: t.check() }
}
