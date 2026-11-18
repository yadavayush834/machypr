import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"
import "../components"

// macOS 26 volume / brightness HUD: a small glass capsule at the top right
// under the menu bar with a glyph and a level bar. Also hosts the floating
// screenshot thumbnail (bottom right, like macOS) — click to mark up.
Scope {
    id: hud
    required property var modelData

    PanelWindow {
        screen: hud.modelData
        visible: Osd.shown || outAnim.running
        anchors { top: true; right: true }
        margins { top: 6; right: 8 }
        implicitWidth: 230; implicitHeight: 52
        exclusionMode: ExclusionMode.Normal
        color: "transparent"
        WlrLayershell.namespace: "orchard-hud"
        WlrLayershell.layer: WlrLayer.Overlay

        Glass {
            anchors.fill: parent
            anchors.margins: 4
            radius: 20; tint: Theme.glassThick; shadow: false
            opacity: Osd.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { id: outAnim; duration: 260 } }
            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 16 }
                spacing: 10
                Sym {
                    size: 18; color: Theme.label
                    name: Osd.kind === "brightness" ? "sun" : (Audio.muted || Osd.value === 0 ? "mute" : "speaker")
                }
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 6; radius: 3
                    color: Theme.dark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.1)
                    Rectangle {
                        height: parent.height; radius: 3; color: Theme.label
                        width: parent.width * Math.max(0, Math.min(1, Osd.value))
                        Behavior on width { NumberAnimation { duration: 90 } }
                    }
                }
            }
        }
    }

    PanelWindow {
        id: thumbWin
        screen: hud.modelData
        visible: Osd.thumb !== ""
        anchors { bottom: true; right: true }
        margins { bottom: 16; right: 16 }
        implicitWidth: 220; implicitHeight: 140
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "orchard-thumb"
        WlrLayershell.layer: WlrLayer.Overlay

        Item {
            id: card
            anchors.fill: parent
            x: 0
            Rectangle {
                anchors.fill: parent; anchors.margins: 6
                radius: 10; color: "white"; clip: true
                border.width: 0.5; border.color: Qt.rgba(0, 0, 0, 0.3)
                Image {
                    anchors.fill: parent; anchors.margins: 3
                    source: Osd.thumb ? "file://" + Osd.thumb : ""
                    fillMode: Image.PreserveAspectFit
                    sourceSize: Qt.size(400, 260); asynchronous: true; cache: false
                }
            }
            transform: Translate { id: slide; x: 0 }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true
                onClicked: { Quickshell.execDetached(["swappy", "-f", Osd.thumb]); Osd.thumb = "" }
                onContainsMouseChanged: containsMouse ? life.stop() : life.restart()
            }
        }
        Timer { id: life; interval: 5000; running: Osd.thumb !== ""; onTriggered: Osd.thumb = "" }
    }
}
