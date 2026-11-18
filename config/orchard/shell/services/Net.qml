pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

// Wi-Fi / Ethernet state from NetworkManager, via Quickshell.Networking.
Singleton {
    readonly property var devices: Networking.devices.values
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property bool wired: devices.some(d => d.type === DeviceType.Wired && d.connected)
    readonly property var networks: wifi ? wifi.networks.values.slice().sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength)) : []
    readonly property var current: networks.find(n => n.connected) ?? null
    readonly property bool connected: wired || current !== null
    readonly property real strength: current ? current.signalStrength : 0
    readonly property string name: wired ? "Ethernet" : current ? current.name : ""

    function setScanning(on) { if (wifi) wifi.scannerEnabled = on }
    function toggle() { Networking.wifiEnabled = !Networking.wifiEnabled }
}
