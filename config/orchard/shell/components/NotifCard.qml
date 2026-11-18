import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"

// One notification, macOS style: app icon, bold title, body, time on the
// right, close button on hover (top-left), action buttons on hover.
Glass {
    id: card
    required property var notif
    property bool banner: false
    signal dismissed()
    radius: 20
    tint: Theme.glassThick
    shadow: banner
    implicitHeight: col.implicitHeight + 22
    width: 356

    readonly property string appIcon: {
        if (!notif) return ""
        const i = notif.appIcon || notif.desktopEntry || notif.appName
        if (i && i.startsWith("/")) return "file://" + i
        if (i && i.startsWith("file:")) return i
        return Quickshell.iconPath(i, true) || Apps.icon(notif.desktopEntry || notif.appName.toLowerCase())
    }

    HoverHandler { id: hov }

    RowLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 11 }
        spacing: 10
        Image {
            Layout.preferredWidth: 34; Layout.preferredHeight: 34
            Layout.alignment: Qt.AlignTop
            source: card.appIcon
            sourceSize: Qt.size(68, 68)
            smooth: true; mipmap: true
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: card.notif ? (card.notif.summary || card.notif.appName) : ""
                    elide: Text.ElideRight
                    color: Theme.label; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Bold
                    renderType: Text.NativeRendering
                }
                Text {
                    text: card.notif ? Notifs.ago(card.notif) : ""
                    color: Theme.secondary; font.family: Theme.font; font.pixelSize: 11
                }
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: card.notif ? card.notif.body : ""
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: card.banner ? 3 : 5
                elide: Text.ElideRight
                color: Theme.label; font.family: Theme.font; font.pixelSize: 13
                renderType: Text.NativeRendering
            }
            Image {
                visible: card.notif && card.notif.image !== "" && status === Image.Ready
                Layout.preferredWidth: 120; Layout.preferredHeight: 68; Layout.topMargin: 4
                source: card.notif ? card.notif.image : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(240, 136)
            }
            Row {
                visible: hov.hovered && card.notif && card.notif.actions.length > 0
                Layout.topMargin: 6
                spacing: 6
                Repeater {
                    model: card.notif ? card.notif.actions : []
                    Rectangle {
                        required property var modelData
                        width: at.implicitWidth + 20; height: 24; radius: 12
                        color: Theme.tileHover
                        Text { id: at; anchors.centerIn: parent; text: parent.modelData.text; color: Theme.label; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Medium }
                        MouseArea { anchors.fill: parent; onClicked: { parent.modelData.invoke(); card.dismissed() } }
                    }
                }
            }
        }
    }

    // click body = default action, like clicking a banner on macOS
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: {
            const def = card.notif.actions.find(a => a.identifier === "default")
            if (def) def.invoke()
            card.dismissed()
        }
    }

    Rectangle {
        visible: hov.hovered
        x: -6; y: -6; width: 20; height: 20; radius: 10
        color: Theme.glassThick
        border.width: 0.5; border.color: Theme.outline
        Sym { anchors.centerIn: parent; name: "xmark"; size: 9; weight: 2.4; color: Theme.label }
        MouseArea { anchors.fill: parent; onClicked: { card.notif.dismiss(); card.dismissed() } }
    }
}
