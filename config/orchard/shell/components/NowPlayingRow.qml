import QtQuick
import QtQuick.Layouts
import "../services"

// Artwork, title/artist, transport controls — shared by Control Center and
// the Now Playing menu extra.
RowLayout {
    id: np
    property var player: null
    spacing: 10

    Rectangle {
        Layout.preferredWidth: 48; Layout.preferredHeight: 48
        radius: 9
        color: Theme.dark ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.08)
        clip: true
        Image {
            anchors.fill: parent
            source: np.player ? np.player.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(96, 96)
            asynchronous: true
            visible: status === Image.Ready
        }
        Sym { anchors.centerIn: parent; name: "music"; size: 20; color: Theme.secondary; visible: !np.player || !np.player.trackArtUrl }
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        Text {
            Layout.fillWidth: true; elide: Text.ElideRight
            text: np.player ? (np.player.trackTitle || np.player.identity) : ""
            color: Theme.label; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold
        }
        Text {
            Layout.fillWidth: true; elide: Text.ElideRight
            text: np.player ? (np.player.trackArtist || np.player.identity) : ""
            color: Theme.secondary; font.family: Theme.font; font.pixelSize: 12
        }
    }
    Repeater {
        model: [
            { icon: "prev", ok: np.player && np.player.canGoPrevious, run: () => np.player.previous() },
            { icon: np.player && np.player.isPlaying ? "pause" : "play", ok: np.player && np.player.canTogglePlaying, run: () => np.player.togglePlaying() },
            { icon: "next", ok: np.player && np.player.canGoNext, run: () => np.player.next() },
        ]
        Item {
            required property var modelData
            Layout.preferredWidth: 26; Layout.preferredHeight: 26
            opacity: modelData.ok ? 1 : 0.35
            Sym { anchors.centerIn: parent; name: parent.modelData.icon; size: 17; filled: true; color: Theme.label }
            MouseArea { anchors.fill: parent; enabled: !!parent.modelData.ok; onClicked: parent.modelData.run() }
        }
    }
}
