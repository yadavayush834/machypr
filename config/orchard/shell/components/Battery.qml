import QtQuick
import Quickshell.Services.UPower
import "../services"

// macOS battery glyph: outlined capsule, fill proportional to charge,
// percentage beside it, bolt while charging.
Row {
    id: r
    property color color: "white"
    property bool showPercent: true
    readonly property var dev: UPower.displayDevice
    readonly property real pct: dev ? dev.percentage : 0     // 0..1
    readonly property bool charging: dev && (dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.FullyCharged || (dev.state === UPowerDeviceState.PendingCharge))
    spacing: 5

    Text {
        visible: r.showPercent
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(r.pct * 100) + "%"
        color: r.color
        font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Medium
        renderType: Text.NativeRendering
    }
    Item {
        width: 27; height: 13
        anchors.verticalCenter: parent.verticalCenter
        Rectangle {
            id: shell
            width: 24; height: 12.5
            radius: 3.8
            color: "transparent"
            border.width: 1.1
            border.color: Qt.rgba(r.color.r, r.color.g, r.color.b, 0.5)
            Rectangle {
                x: 2; y: 2
                height: parent.height - 4
                width: Math.max(2, (parent.width - 4) * r.pct)
                radius: 2
                color: r.pct <= 0.1 && !r.charging ? Theme.red : r.charging ? (r.color === Qt.color("white") ? "white" : Theme.green) : r.color
            }
        }
        Rectangle {
            x: 24.8; y: 4.5; width: 1.6; height: 4; radius: 1
            color: Qt.rgba(r.color.r, r.color.g, r.color.b, 0.5)
        }
        Sym {
            visible: r.charging
            anchors.centerIn: shell
            name: "bolt"; size: 11; filled: true
            color: Theme.dark || r.color === Qt.color("white") ? "black" : "white"
        }
    }
}
