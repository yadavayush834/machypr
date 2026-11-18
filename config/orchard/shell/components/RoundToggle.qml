import QtQuick
import "../services"

// Circular Control Center button: accent fill when on, label beside/below.
Item {
    id: r
    property string icon: "wifi3"
    property bool on: false
    property string title: ""
    property string subtitle: ""
    property bool vertical: false
    property real dia: 30
    signal clicked()
    signal rightClicked()
    implicitWidth: vertical ? Math.max(dia, lbl.implicitWidth) : dia + 8 + Math.max(lbl.implicitWidth, sub.implicitWidth)
    implicitHeight: vertical ? dia + 4 + lbl.implicitHeight : dia

    Rectangle {
        id: circle
        width: r.dia; height: r.dia; radius: r.dia / 2
        x: r.vertical ? (r.width - width) / 2 : 0
        color: r.on ? Theme.accent : (Theme.dark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.08))
        Behavior on color { ColorAnimation { duration: Theme.quick } }
        Sym {
            anchors.centerIn: parent
            name: r.icon; size: r.dia * 0.5; weight: 2
            color: r.on ? "white" : Theme.label
        }
        scale: ma.pressed ? 0.92 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
    }
    Text {
        id: lbl
        x: r.vertical ? (r.width - width) / 2 : r.dia + 8
        y: r.vertical ? r.dia + 4 : (r.subtitle ? r.dia / 2 - height + 1 : (r.dia - height) / 2)
        text: r.title
        color: Theme.label
        font.family: Theme.font; font.pixelSize: r.vertical ? 10 : 12; font.weight: Font.DemiBold
        renderType: Text.NativeRendering
    }
    Text {
        id: sub
        visible: !r.vertical && r.subtitle !== ""
        x: r.dia + 8; y: r.dia / 2 + 1
        width: 110; elide: Text.ElideRight
        text: r.subtitle
        color: Theme.secondary
        font.family: Theme.font; font.pixelSize: 11
        renderType: Text.NativeRendering
    }
    MouseArea {
        id: ma; anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => m.button === Qt.RightButton ? r.rightClicked() : r.clicked()
    }
}
