import QtQuick
import QtQuick.Layouts
import "../services"

// A macOS menu: glass, 12px corners, 22px rows, accent-blue highlight that
// follows the pointer or arrow keys, right-aligned ⌘ shortcut hints.
Glass {
    id: m
    // items: [{ text, keys, run: fn, sep: true, enabled, checked, header }]
    property var items: []
    property int current: -1
    signal chosen()
    radius: Theme.menuRadius
    tint: Theme.glassThick
    implicitWidth: Math.max(220, col.implicitWidth + 12)
    implicitHeight: col.implicitHeight + 10

    function activate(i) {
        const it = items[i]
        if (!it || it.sep || it.header || it.enabled === false) return
        Shell.popup = ""
        chosen()
        if (it.run) it.run()
    }
    function move(d) {
        let i = current
        for (let n = 0; n < items.length; n++) {
            i = (i + d + items.length) % items.length
            const it = items[i]
            if (!it.sep && !it.header && it.enabled !== false) { current = i; return }
        }
    }

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 5 }
        spacing: 0
        Repeater {
            model: m.items
            delegate: Item {
                id: row
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: modelData.sep ? 11 : 24
                implicitWidth: label.implicitWidth + keys.implicitWidth + 60
                readonly property bool on: m.current === index && !modelData.sep && !modelData.header && modelData.enabled !== false

                Rectangle {
                    visible: row.modelData.sep === true
                    anchors.centerIn: parent
                    width: parent.width - 18; height: 1
                    color: Theme.separator
                }
                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: Theme.accent
                    visible: row.on
                }
                Text {
                    visible: row.modelData.checked === true
                    x: 8; anchors.verticalCenter: parent.verticalCenter
                    text: "✓"; color: row.on ? "white" : Theme.label
                    font.pixelSize: 12; font.family: Theme.font
                }
                Text {
                    id: label
                    visible: !row.modelData.sep
                    x: 24; anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.text ?? ""
                    color: row.on ? "white" : (row.modelData.enabled === false || row.modelData.header) ? Theme.tertiary : Theme.label
                    font.family: Theme.font; font.pixelSize: Theme.textSize
                    font.weight: row.modelData.header ? Font.DemiBold : Font.Normal
                    font.letterSpacing: Theme.tracking
                    renderType: Text.NativeRendering
                }
                Text {
                    id: keys
                    visible: !row.modelData.sep && !!row.modelData.keys
                    anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    text: row.modelData.keys ?? ""
                    color: row.on ? Qt.rgba(1, 1, 1, 0.8) : Theme.secondary
                    font.family: Theme.font; font.pixelSize: Theme.textSize
                    renderType: Text.NativeRendering
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: m.current = row.index
                    onExited: if (m.current === row.index) m.current = -1
                    onClicked: m.activate(row.index)
                }
            }
        }
    }
}
