pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The notification daemon. Banners slide in at the top right; everything
// stays in Notification Center until cleared. Focus mode silences banners.
Singleton {
    id: n
    property var banners: []          // currently shown, newest first
    property var times: ({})
    readonly property var all: server.trackedNotifications.values.slice().reverse()
    signal posted(var notif)

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true
        onNotification: notif => {
            notif.tracked = true
            n.times[notif.id] = Date.now()
            if (!Settings.focusMode || notif.urgency === NotificationUrgency.Critical) {
                n.banners = [notif].concat(n.banners).slice(0, 4)
                Quickshell.execDetached([Settings.bin + "sound", "notify"])
            }
            n.posted(notif)
        }
    }
    function hideBanner(notif) { banners = banners.filter(b => b !== notif) }
    function clearAll() { for (const x of server.trackedNotifications.values.slice()) x.dismiss(); banners = [] }
    function ago(notif) {
        const t = times[notif.id]
        if (!t) return "now"
        const s = (Date.now() - t) / 1000
        if (s < 60) return "now"
        if (s < 3600) return Math.floor(s / 60) + "m ago"
        if (s < 86400) return Math.floor(s / 3600) + "h ago"
        return Math.floor(s / 86400) + "d ago"
    }
}
