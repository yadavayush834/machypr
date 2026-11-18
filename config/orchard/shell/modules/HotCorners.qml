import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

// Hot Corners: push the pointer into the top-left corner for Mission
// Control, bottom-left for Launchpad, bottom-right for Show Desktop.
Variants {
    model: ["tl", "bl", "br"]
    PanelWindow {
        id: corner
        required property string modelData
        screen: Quickshell.screens[0]
        visible: Settings.hotCorners && !(Hypr.active && Hypr.active.fullscreen === 2)
        anchors {
            top: corner.modelData[0] === "t"; bottom: corner.modelData[0] === "b"
            left: corner.modelData[1] === "l"; right: corner.modelData[1] === "r"
        }
        implicitWidth: 2; implicitHeight: 2
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "orchard-corner"
        WlrLayershell.layer: WlrLayer.Overlay
        MouseArea {
            anchors.fill: parent; hoverEnabled: true
            onEntered: dwell.restart()
            onExited: dwell.stop()
        }
        Timer {
            id: dwell; interval: 220
            onTriggered: {
                if (corner.modelData === "tl") Shell.open("mission")
                else if (corner.modelData === "bl") Shell.open("launchpad")
                else Hypr.here.forEach(c => Hypr.minimize(c))
            }
        }
    }
}
