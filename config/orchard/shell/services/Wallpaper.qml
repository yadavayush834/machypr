pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Dynamic Desktop: the Tahoe wallpaper switches between its day and night
// renditions with the appearance. A tiny probe measures the brightness under
// the menu bar so its text flips dark/light like macOS.
Singleton {
    id: w
    readonly property string dir: Quickshell.env("HOME") + "/.config/orchard/wallpapers/"
    readonly property string custom: Settings.wallpaper    // "" = Dynamic Desktop
    readonly property string current: "file://" + (custom !== "" ? custom
                                       : dir + (Settings.isDark ? "MacTahoe-night.jpeg" : "MacTahoe-day.jpeg"))

    onCurrentChanged: probe.running = true
    Component.onCompleted: probe.running = true

    Process {
        id: probe
        command: ["python3", "-c",
            "import sys\nfrom PIL import Image, ImageStat\nim=Image.open(sys.argv[1]).convert('L')\nw,h=im.size\nprint(ImageStat.Stat(im.crop((0,0,w,max(1,int(h*0.035))))).mean[0])",
            w.current.replace("file://", "")]
        stdout: StdioCollector { onStreamFinished: { const v = parseFloat(text); if (!isNaN(v)) Settings.barOnLight = v > 150 } }
    }
}
