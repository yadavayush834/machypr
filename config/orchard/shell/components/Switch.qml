import QtQuick
import "../services"

// macOS toggle switch: 26x15 capsule, green-free (accent blue) when on.
Item {
    id: s
    property bool checked: false
    signal toggled()
    implicitWidth: 28; implicitHeight: 16
    Rectangle {
        anchors.fill: parent; radius: height / 2
        color: s.checked ? Theme.accent : (Theme.dark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.12))
        Behavior on color { ColorAnimation { duration: Theme.quick } }
    }
    Rectangle {
        width: parent.height - 2; height: width; radius: width / 2
        y: 1; x: s.checked ? parent.width - width - 1 : 1
        color: "white"
        Behavior on x { NumberAnimation { duration: Theme.quick; easing.type: Theme.ease } }
    }
    MouseArea { anchors.fill: parent; onClicked: s.toggled() }
}
