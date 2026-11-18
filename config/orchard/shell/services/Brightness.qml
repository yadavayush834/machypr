pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Display brightness through brightnessctl (works without root via logind).
Singleton {
    id: b
    property real value: 0.5        // 0..1
    property int max: 1

    function set(v) {
        v = Math.max(0.01, Math.min(1, v))
        value = v
        setter.command = ["brightnessctl", "-q", "set", Math.round(v * 100) + "%"]
        setter.running = true
    }
    function step(d) { set(value + d) }

    Process { id: setter }
    Process {
        id: reader
        command: ["brightnessctl", "-m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",")
                if (f.length >= 5) { b.max = +f[4]; b.value = (+f[2]) / b.max }
            }
        }
    }
    // pick up changes made elsewhere (keys, hypridle dimming)
    FileView {
        path: "/sys/class/backlight/intel_backlight/actual_brightness"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { const n = parseInt(text()); if (!isNaN(n) && b.max > 1 && !setter.running) b.value = n / b.max }
    }
}
