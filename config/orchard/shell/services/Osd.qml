pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Drives the HUD. Hyprland media keys call `qs -c orchard ipc call osd …`
// (or the shell's own sliders) and the HUD shows for 1.5 s.
Singleton {
    id: o
    property bool shown: false
    property string kind: "volume"
    property real value: 0
    property string thumb: ""

    function show(k) {
        kind = k
        value = k === "brightness" ? Brightness.value : (Audio.muted ? 0 : Audio.volume)
        shown = true
        hide.restart()
    }
    Timer { id: hide; interval: 1500; onTriggered: o.shown = false }

    Connections { target: Brightness; function onValueChanged() { if (o.shown && o.kind === "brightness") o.value = Brightness.value } }
    Connections { target: Audio; function onVolumeChanged() { if (o.shown && o.kind === "volume") o.value = Audio.volume } }

    IpcHandler {
        target: "osd"
        function volume(step: string): void {
            if (step === "mute") Audio.toggleMute()
            else Audio.setVolume(Audio.volume + parseFloat(step))
            o.show("volume")
            if (step !== "mute") Quickshell.execDetached([Settings.bin + "sound", "volume"])
        }
        function brightness(step: string): void {
            Brightness.step(parseFloat(step))
            o.show("brightness")
        }
        function thumbnail(path: string): void { o.thumb = ""; o.thumb = path }
    }
}
