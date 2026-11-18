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
    visible: Notifs.banners.length > 0 && Shell.popup !== "notifications" && !Shell.mission
    anchors { top: true; right: true }
    margins { top: 4; right: 0 }
    implicitWidth: 356 + 24
    implicitHeight: Math.max(1, stack.implicitHeight + 16)
    exclusionMode: ExclusionMode.Normal
    color: "transparent"
    WlrLayershell.namespace: "orchard-banner"
    WlrLayershell.layer: WlrLayer.Overlay

    Column {
        id: stack
        x: 14; y: 8
        spacing: 8
        move: Transition { NumberAnimation { property: "y"; duration: Theme.normal; easing.type: Theme.ease } }

        Repeater {
            model: ScriptModel { values: Notifs.banners }
            NotifCard {
                id: card
                required property var modelData
                notif: modelData
                banner: true
                property bool leaving: false
                transform: Translate { id: tr; x: 380 }
                onDismissed: Notifs.hideBanner(modelData)

                Component.onCompleted: enter.start()
                NumberAnimation { id: enter; target: tr; property: "x"; from: 380; to: 0; duration: 420; easing.type: Easing.OutCubic }
                SequentialAnimation {
                    id: leave
                    NumberAnimation { target: tr; property: "x"; to: 400; duration: 280; easing.type: Easing.InCubic }
                    ScriptAction { script: Notifs.hideBanner(card.modelData) }
                }
                HoverHandler { id: h }
                Timer {
                    interval: card.notif && card.notif.urgency === 2 ? 15000 : 5000
                    running: !h.hovered && !leave.running
                    onTriggered: leave.start()
                }
            }
        }
    }
}
