import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"
import "../components"

// Notification banners: slide in from the right edge under the menu bar,
// stay ~5 s (hover pauses), then slide away into Notification Center.
PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    visible: Notifs.banners.length > 0 && Shell.popup !== "notifications"
    anchors { top: true; right: true }
    margins { top: 4; right: 0 }
    implicitWidth: 356 + 24
    implicitHeight: Math.max(1, list.contentHeight + 16)
    exclusionMode: ExclusionMode.Normal
    color: "transparent"
    WlrLayershell.namespace: "orchard-banner"
    WlrLayershell.layer: WlrLayer.Overlay

    ListView {
        id: list
        anchors { fill: parent; topMargin: 8; leftMargin: 14 }
        spacing: 8
        interactive: false
        model: Notifs.banners
        add: Transition {
            NumberAnimation { property: "x"; from: 380; to: 0; duration: 420; easing.type: Easing.OutCubic }
        }
        displaced: Transition { NumberAnimation { property: "y"; duration: Theme.normal; easing.type: Theme.ease } }
        delegate: NotifCard {
            id: card
            required property var modelData
            notif: modelData
            banner: true
            onDismissed: Notifs.hideBanner(modelData)
            HoverHandler { id: h }
            Timer {
                interval: card.notif && card.notif.urgency === 2 ? 15000 : 5200
                running: !h.hovered
                onTriggered: out.start()
            }
            NumberAnimation {
                id: out; target: card; property: "x"; to: 400
                duration: 300; easing.type: Easing.InCubic
                onFinished: Notifs.hideBanner(card.modelData)
            }
        }
    }
}
