import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

// The desktop picture, on the background layer. Crossfades (1.2 s) when the
// Dynamic Desktop changes between day and night.
PanelWindow {
    id: bg
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "black"
    WlrLayershell.namespace: "orchard-wallpaper"
    WlrLayershell.layer: WlrLayer.Background

    property string shown: Wallpaper.current
    property bool flip: false
    onShownChanged: { flip = !flip; (flip ? b : a).source = shown }

    Image {
        id: a
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(bg.width * bg.devicePixelRatio, bg.height * bg.devicePixelRatio)
        asynchronous: true
        source: bg.shown
        opacity: bg.flip ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 1200; easing.type: Easing.InOutQuad } }
    }
    Image {
        id: b
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: a.sourceSize
        asynchronous: true
        opacity: bg.flip ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 1200; easing.type: Easing.InOutQuad } }
    }
    // right-click the desktop: macOS desktop menu
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: m => { Shell.desktopMenuPos = Qt.point(m.x, m.y); Shell.popupX = m.x; Shell.popup = "desktop" }
    }
}
