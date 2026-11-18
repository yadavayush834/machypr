import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"
import "../components"

// Launchpad / Apps: every installed app in pages of 7×5 over a blurred,
// dimmed desktop. Type to filter, scroll or ←→ to page, ⎋ or click empty
// space to close. Zooms in like macOS.
PanelWindow {
    id: lp
    property var modelData: Quickshell.screens[0]
    screen: modelData
    visible: Shell.launchpad || out.running
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "orchard-launchpad"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Shell.launchpad ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property int cols: 7
    readonly property int rows: 5
    readonly property var apps: Apps.all.filter(e => !search.text || e.name.toLowerCase().indexOf(search.text.toLowerCase()) >= 0
                                                     || String(e.keywords).toLowerCase().indexOf(search.text.toLowerCase()) >= 0)
    readonly property int pages: Math.max(1, Math.ceil(apps.length / (cols * rows)))
    property int page: 0
    onAppsChanged: page = 0
    onVisibleChanged: if (visible) { search.text = ""; page = 0; search.forceActiveFocus() }
    property bool shown: false
    Component.onCompleted: { search.forceActiveFocus(); shown = true }

    Rectangle {
        id: dim
        anchors.fill: parent
        color: Theme.dark ? Qt.rgba(0, 0, 0, 0.45) : Qt.rgba(0.1, 0.1, 0.12, 0.30)
        opacity: lp.shown && Shell.launchpad ? 1 : 0
        Behavior on opacity { NumberAnimation { id: out; duration: Theme.normal; easing.type: Theme.ease } }
        MouseArea { anchors.fill: parent; onClicked: Shell.launchpad = false
                    onWheel: w => lp.page = Math.max(0, Math.min(lp.pages - 1, lp.page + (w.angleDelta.y < 0 || w.angleDelta.x < 0 ? 1 : -1))) }
    }

    Item {
        anchors.fill: parent
        opacity: dim.opacity
        scale: 0.9 + 0.1 * dim.opacity

        Rectangle {
            id: searchBox
            width: 240; height: 30; radius: 9
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 46 }
            color: Qt.rgba(1, 1, 1, 0.16)
            border.width: 0.5; border.color: Qt.rgba(1, 1, 1, 0.25)
            Sym { x: 9; anchors.verticalCenter: parent.verticalCenter; name: "search"; size: 13; color: Qt.rgba(1, 1, 1, 0.7) }
            TextInput {
                id: search
                anchors { fill: parent; leftMargin: 28; rightMargin: 8 }
                verticalAlignment: TextInput.AlignVCenter
                color: "white"; font.family: Theme.font; font.pixelSize: 13
                Text { visible: !search.text; text: "Search"; color: Qt.rgba(1, 1, 1, 0.55); font: search.font; anchors.verticalCenter: parent.verticalCenter }
                Keys.onEscapePressed: { if (text) text = ""; else Shell.launchpad = false }
                Keys.onRightPressed: lp.page = Math.min(lp.pages - 1, lp.page + 1)
                Keys.onLeftPressed: lp.page = Math.max(0, lp.page - 1)
                Keys.onReturnPressed: if (lp.apps.length) { Shell.launchpad = false; lp.apps[lp.page * lp.cols * lp.rows].execute() }
            }
        }

        Item {
            id: viewport
            anchors { top: searchBox.bottom; topMargin: 30; bottom: dots.top; bottomMargin: 16; left: parent.left; right: parent.right; leftMargin: 90; rightMargin: 90 }
            clip: true
            Row {
                x: -lp.page * viewport.width
                Behavior on x { NumberAnimation { duration: Theme.slow; easing.type: Theme.ease } }
                Repeater {
                    model: lp.pages
                    Grid {
                        id: pageGrid
                        required property int index
                        width: viewport.width; height: viewport.height
                        columns: lp.cols
                        readonly property real cw: width / lp.cols
                        readonly property real ch: height / lp.rows
                        Repeater {
                            model: lp.apps.slice(pageGrid.index * lp.cols * lp.rows, (pageGrid.index + 1) * lp.cols * lp.rows)
                            Item {
                                required property var modelData
                                width: pageGrid.cw; height: pageGrid.ch
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Image {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: Math.min(64, pageGrid.ch - 30); height: width
                                        source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                                        sourceSize: Qt.size(128, 128); smooth: true; mipmap: true; asynchronous: true
                                        scale: cell.pressed ? 0.88 : 1
                                        Behavior on scale { NumberAnimation { duration: 90 } }
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: pageGrid.cw - 12; horizontalAlignment: Text.AlignHCenter
                                        text: Apps.aliases[modelData.id] ?? modelData.name; elide: Text.ElideRight
                                        color: "white"; font.family: Theme.font; font.pixelSize: 12
                                        style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.35)
                                    }
                                }
                                MouseArea {
                                    id: cell; anchors.fill: parent
                                    onClicked: { Shell.launchpad = false; modelData.execute() }
                                }
                            }
                        }
                    }
                }
            }
        }

        Row {
            id: dots
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 40 }
            spacing: 9
            visible: lp.pages > 1
            Repeater {
                model: lp.pages
                Rectangle {
                    required property int index
                    width: 7; height: 7; radius: 3.5
                    color: index === lp.page ? "white" : Qt.rgba(1, 1, 1, 0.35)
                    MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: lp.page = parent.index }
                }
            }
        }
    }
}
