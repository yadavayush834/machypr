import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"

// Month view: red month name, today in a red disc, scroll to change month.
ColumnLayout {
    id: cal
    property date today: clock.date
    property int offset: 0
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + offset, 1)
    spacing: 6

    SystemClock { id: clock; precision: SystemClock.Hours }

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: Qt.formatDate(cal.shown, "MMMM").toUpperCase()
            color: Theme.red; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.Bold
            Layout.fillWidth: true
        }
        Text { text: cal.shown.getFullYear(); color: Theme.secondary; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold }
        Repeater {
            model: [["prev", -1], ["next", 1]]
            Item {
                required property var modelData
                implicitWidth: 18; implicitHeight: 16
                Sym { anchors.centerIn: parent; name: "chevron"; size: 11; weight: 2.4; color: Theme.secondary; rotation: parent.modelData[1] < 0 ? 180 : 0 }
                MouseArea { anchors.fill: parent; onClicked: cal.offset += parent.modelData[1] }
            }
        }
    }
    GridLayout {
        Layout.fillWidth: true; Layout.fillHeight: true
        columns: 7; rowSpacing: 0; columnSpacing: 0
        Repeater {
            model: ["S", "M", "T", "W", "T", "F", "S"]
            Text {
                required property string modelData
                Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                text: modelData; color: Theme.tertiary; font.family: Theme.font; font.pixelSize: 10; font.weight: Font.Bold
            }
        }
        Repeater {
            model: 42
            Item {
                required property int index
                readonly property date d: new Date(cal.shown.getFullYear(), cal.shown.getMonth(), index - cal.shown.getDay() + 1)
                readonly property bool inMonth: d.getMonth() === cal.shown.getMonth()
                readonly property bool isToday: d.toDateString() === cal.today.toDateString()
                Layout.fillWidth: true; Layout.fillHeight: true
                implicitHeight: 21
                Rectangle {
                    anchors.centerIn: parent; width: 20; height: 20; radius: 10
                    color: Theme.red; visible: parent.isToday
                }
                Text {
                    anchors.centerIn: parent
                    text: parent.d.getDate()
                    color: parent.isToday ? "white" : parent.inMonth ? Theme.label : Theme.tertiary
                    font.family: Theme.font; font.pixelSize: 11; font.weight: parent.isToday ? Font.Bold : Font.Medium
                }
            }
        }
    }
    WheelHandler { onWheel: e => cal.offset += e.angleDelta.y > 0 ? -1 : 1 }
}
