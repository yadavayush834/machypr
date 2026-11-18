import QtQuick
import "../services"

// A Control Center module: rounded, slightly lighter than the panel.
Rectangle {
    radius: Theme.tileRadius
    color: Theme.tile
    border.width: 0.5
    border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.05)
}
