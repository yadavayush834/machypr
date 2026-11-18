pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Keep the Mac awake (like `caffeinate`): holds a logind idle inhibitor.
Singleton {
    property bool on: false
    Process {
        id: p
        command: ["systemd-inhibit", "--what=idle", "--who=Orchard", "--why=Caffeinate", "sleep", "infinity"]
    }
    onOnChanged: p.running = on
}
