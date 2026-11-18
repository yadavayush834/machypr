import QtQuick
import "../services"

// Control Center slider: a fat capsule whose white fill is the value,
// glyph riding inside the fill on the left. Drag anywhere, scroll to nudge.
Item {
    id: sl
    property real value: 0.5
    property string icon: "sun"
    signal moved(real v)
    implicitHeight: 26

    Rectangle {
        id: track
        anchors.fill: parent; radius: height / 2
        color: Theme.dark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.08)
        clip: true
        Rectangle {
            height: parent.height; radius: height / 2
            width: Math.max(parent.height, parent.width * sl.value)
            color: "white"
            Behavior on width { enabled: !ma.pressed; NumberAnimation { duration: Theme.quick } }
        }
        Sym {
            x: 7; anchors.verticalCenter: parent.verticalCenter
            name: sl.icon; size: 13; weight: 2
            color: Qt.rgba(0, 0, 0, 0.6)
        }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        function upd(x) { sl.moved(Math.max(0, Math.min(1, x / width))) }
        onPressed: m => upd(m.x)
        onPositionChanged: m => { if (pressed) upd(m.x) }
        onWheel: w => sl.moved(Math.max(0, Math.min(1, sl.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
