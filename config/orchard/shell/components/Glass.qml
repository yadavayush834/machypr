import QtQuick
import QtQuick.Effects
import "../services"

// A Liquid-Glass surface: soft drop shadow, translucent tint (the compositor
// blurs what is behind it), a dark hairline outside and a light rim inside.
Item {
    id: g
    property real radius: Theme.panelRadius
    property color tint: Theme.glass
    property bool shadow: true
    property real shadowOpacity: Theme.dark ? 0.55 : 0.22
    default property alias content: inner.data

    RectangularShadow {
        visible: g.shadow
        anchors.fill: base
        offset.y: 8
        blur: 32
        spread: -2
        radius: g.radius
        color: Qt.rgba(0, 0, 0, g.shadowOpacity)
        cached: true
    }
    Rectangle {
        id: base
        anchors.fill: parent
        radius: g.radius
        color: g.tint
        border.width: 0.5
        border.color: Theme.outline
        Behavior on color { ColorAnimation { duration: Theme.normal } }
    }
    // inner specular rim, brighter along the top edge
    Rectangle {
        anchors.fill: parent
        anchors.margins: 0.5
        radius: g.radius - 0.5
        color: "transparent"
        border.width: 1
        border.color: Theme.rimBottom
    }
    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 0.5 }
        height: g.radius * 1.4
        radius: g.radius - 0.5
        color: "transparent"
        border.width: 1
        border.color: Theme.rimTop
        opacity: 0.55
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: fade
        }
    }
    Item {
        id: fade
        visible: false; layer.enabled: true
        width: g.width; height: g.radius * 1.4
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: "white" }
                GradientStop { position: 1; color: "transparent" }
            }
        }
    }
    Item { id: inner; anchors.fill: parent }
}
