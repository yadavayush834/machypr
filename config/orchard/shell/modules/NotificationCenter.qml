import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../services"
import "../components"

// Notification Center (click the clock): notifications on top, then the
// Calendar and Batteries widgets, all glass on the right edge.
Item {
    id: nc
    width: 356
    implicitHeight: Math.min(maxHeight, col.implicitHeight)
    property real maxHeight: 640

    Flickable {
        anchors.fill: parent
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            width: nc.width
            spacing: 10

            RowLayout {
                visible: Notifs.all.length > 0
                Layout.fillWidth: true; Layout.leftMargin: 6; Layout.rightMargin: 4
                Text { text: "Notifications"; color: "white"; font.family: Theme.font; font.pixelSize: 15; font.weight: Font.Bold; Layout.fillWidth: true
                       style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.3) }
                Rectangle {
                    implicitWidth: cl.implicitWidth + 18; implicitHeight: 22; radius: 11
                    color: Theme.glassThick
                    Text { id: cl; anchors.centerIn: parent; text: "Clear All"; color: Theme.label; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold }
                    MouseArea { anchors.fill: parent; onClicked: Notifs.clearAll() }
                }
            }
            Repeater {
                model: Notifs.all.slice(0, 30)
                NotifCard { required property var modelData; notif: modelData; Layout.fillWidth: true }
            }

            // ---- Calendar widget
            Glass {
                Layout.fillWidth: true
                implicitHeight: 196
                radius: 22; tint: Theme.glassThick; shadow: false
                CalendarGrid { anchors { fill: parent; margins: 14 } }
            }

            // ---- Batteries widget
            Glass {
                visible: UPower.displayDevice.isLaptopBattery
                Layout.fillWidth: true
                implicitHeight: 92
                radius: 22; tint: Theme.glassThick; shadow: false
                RowLayout {
                    anchors { fill: parent; margins: 14 }
                    spacing: 14
                    Item {
                        Layout.preferredWidth: 56; Layout.preferredHeight: 56
                        Canvas {
                            id: ring
                            anchors.fill: parent
                            property real p: UPower.displayDevice.percentage
                            onPChanged: requestPaint()
                            Connections { target: Theme; function onDarkChanged() { ring.requestPaint() } }
                            onPaint: {
                                const c = getContext("2d"); c.reset()
                                c.lineWidth = 5; c.lineCap = "round"
                                c.strokeStyle = Theme.dark ? "rgba(255,255,255,0.15)" : "rgba(0,0,0,0.1)"
                                c.beginPath(); c.arc(28, 28, 24, 0, Math.PI * 2); c.stroke()
                                c.strokeStyle = p < 0.2 ? Theme.red : Theme.green
                                c.beginPath(); c.arc(28, 28, 24, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * p); c.stroke()
                            }
                        }
                        Sym { anchors.centerIn: parent; name: "display"; size: 20; color: Theme.label }
                    }
                    ColumnLayout {
                        spacing: 2
                        Text { text: "This Laptop"; color: Theme.secondary; font.family: Theme.font; font.pixelSize: 12 }
                        Text { text: Math.round(UPower.displayDevice.percentage * 100) + "%"; color: Theme.label; font.family: Theme.fontDisplay; font.pixelSize: 26; font.weight: Font.DemiBold }
                    }
                    Item { Layout.fillWidth: true }
                }
            }
        }
    }
}
