import QtQuick
import Quickshell

// Builds a surface only while it is wanted (plus a short grace period for its
// closing animation), so idle memory stays low and opening stays instant.
Scope {
    id: lz
    property bool when: false
    property Component surface
    property int grace: 700
    LazyLoader { active: lz.when || hold.running; component: lz.surface }
    Timer { id: hold; interval: lz.grace }
    onWhenChanged: if (!when) hold.restart()
}
