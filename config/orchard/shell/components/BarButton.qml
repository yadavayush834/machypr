import QtQuick
import "../services"

// A menu-bar title or status item. Highlights as a rounded capsule while its
// menu is open; hovering across titles while any menu is open switches menus.
Item {
    id: b
    property string text: ""
    property bool bold: false
    property string menu: ""            // Shell.popup name this opens
    property real pad: 9
    property bool open: menu !== "" && Shell.popup === menu
    default property alias extra: row.data
    signal clicked(var mouse)

    implicitWidth: row.implicitWidth + pad * 2
    implicitHeight: Theme.barHeight

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 3; anchors.bottomMargin: 3
        radius: height / 2
        color: Settings.barOnLight ? Qt.rgba(0, 0, 0, 0.12) : Qt.rgba(1, 1, 1, 0.22)
        opacity: b.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.quick } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5
        Text {
            visible: b.text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: b.text
            color: Theme.barText
            font.family: Theme.font
            font.pixelSize: Theme.textSize
            font.weight: b.bold ? Font.Bold : Font.Normal
            font.letterSpacing: Theme.tracking
            renderType: Text.NativeRendering
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: mouse => {
            if (b.menu !== "") {
                const p = b.mapToItem(null, 0, 0)
                Shell.toggle(b.menu, p.x)
            }
            b.clicked(mouse)
        }
        onEntered: {
            // slide between open menus without clicking, like macOS
            if (b.menu !== "" && Shell.popup !== "" && Shell.popup !== b.menu && Shell.popupFromBar) {
                const p = b.mapToItem(null, 0, 0)
                Shell.popupX = p.x
                Shell.popup = b.menu
            }
        }
    }
}
