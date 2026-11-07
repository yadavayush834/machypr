#!/usr/bin/env python3
"""Run with dbus-run-session: real tray/MPRIS lifecycle and playback dispatch."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import gi
gi.require_version('Gtk','3.0')
from gi.repository import Gio,GLib,Gtk,Gdk
ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT/'home/.local/lib'))


def mock(log):
    bus=Gio.bus_get_sync(Gio.BusType.SESSION,None)
    xml='''<node><interface name="org.kde.StatusNotifierItem">
    <property name="Id" type="s" access="read"/><property name="Title" type="s" access="read"/>
    <property name="Status" type="s" access="read"/><property name="IconName" type="s" access="read"/>
    <property name="Menu" type="o" access="read"/><property name="ItemIsMenu" type="b" access="read"/>
    <method name="Activate"><arg type="i" direction="in"/><arg type="i" direction="in"/></method>
    <method name="ContextMenu"><arg type="i" direction="in"/><arg type="i" direction="in"/></method>
    </interface><interface name="org.mpris.MediaPlayer2">
    <property name="Identity" type="s" access="read"/><property name="CanQuit" type="b" access="read"/>
    <property name="CanRaise" type="b" access="read"/><property name="HasTrackList" type="b" access="read"/>
    <property name="SupportedUriSchemes" type="as" access="read"/><property name="SupportedMimeTypes" type="as" access="read"/>
    </interface><interface name="org.mpris.MediaPlayer2.Player">
    <property name="PlaybackStatus" type="s" access="read"/><property name="Metadata" type="a{sv}" access="read"/>
    <property name="Position" type="x" access="read"/><property name="CanControl" type="b" access="read"/>
    <property name="CanPlay" type="b" access="read"/><property name="CanPause" type="b" access="read"/>
    <property name="CanSeek" type="b" access="read"/><property name="CanGoNext" type="b" access="read"/>
    <property name="CanGoPrevious" type="b" access="read"/><property name="Volume" type="d" access="read"/>
    <method name="PlayPause"/><method name="Next"/><method name="Previous"/>
    <method name="SetPosition"><arg type="o" direction="in"/><arg type="x" direction="in"/></method>
    </interface></node>'''
    playing=[True]
    def method(connection,sender,path,interface,name,args,invocation):
        with open(log,'a') as stream:stream.write(json.dumps([name,args.unpack()])+'\n')
        if name=='PlayPause':
            playing[0]=not playing[0]
            bus.emit_signal(None,path,'org.freedesktop.DBus.Properties','PropertiesChanged',GLib.Variant('(sa{sv}as)',(interface,{'PlaybackStatus':GLib.Variant('s','Playing' if playing[0] else 'Paused')},[])))
        invocation.return_value(None)
    def prop(connection,sender,path,interface,name):
        values={'Id':('s','mock-tray'),'Title':('s','Test Background App'),'Status':('s','Active'),'IconName':('s','application-x-executable-symbolic'),'Menu':('o','/'),'ItemIsMenu':('b',False),
                'Identity':('s','Test Music'),'CanQuit':('b',False),'CanRaise':('b',False),'HasTrackList':('b',False),'SupportedUriSchemes':('as',[]),'SupportedMimeTypes':('as',[]),
                'PlaybackStatus':('s','Playing' if playing[0] else 'Paused'),'Position':('x',18000000),'Volume':('d',1.0),
                'Metadata':('a{sv}',{'xesam:title':GLib.Variant('s','Test Song'),'xesam:artist':GLib.Variant('as',['Test Artist']),'mpris:length':GLib.Variant('x',180000000),'mpris:trackid':GLib.Variant('o','/track/test')})}
        if name.startswith('Can'):return GLib.Variant('b',True)
        return GLib.Variant(*values[name])
    for info in Gio.DBusNodeInfo.new_for_xml(xml).interfaces:
        bus.register_object('/StatusNotifierItem' if info.name=='org.kde.StatusNotifierItem' else '/org/mpris/MediaPlayer2',info,method,prop,None)
    ids=[Gio.bus_own_name_on_connection(bus,name,Gio.BusNameOwnerFlags.NONE,None,None) for name in ('org.test.BackgroundApp','org.mpris.MediaPlayer2.machyprtest')]
    def register():
        bus.call('org.kde.StatusNotifierWatcher','/StatusNotifierWatcher','org.kde.StatusNotifierWatcher','RegisterStatusNotifierItem',GLib.Variant('(s)',('org.test.BackgroundApp',)),None,Gio.DBusCallFlags.NONE,1000,None,None)
        return True
    GLib.timeout_add(500,register);GLib.MainLoop().run()


def pump(seconds):
    end=time.monotonic()+seconds
    while time.monotonic()<end:
        while GLib.MainContext.default().pending():GLib.MainContext.default().iteration(False)
        time.sleep(.01)


def test():
    from macos_tray import Tray
    from macos_media import Panel
    with tempfile.TemporaryDirectory() as folder:
        log=Path(folder)/'calls';box=Gtk.Box();window=Gtk.Window();window.add(box);tray=Tray(box);window.show_all();pump(.3)
        process=subprocess.Popen([sys.executable,__file__,'--mock',str(log)])
        try:
            pump(1.5)
            assert len(tray.items)==1,tray.items
            item=next(iter(tray.items.values()));assert item['button'].get_visible()
            assert item['button'].get_tooltip_text()=='Test Background App'
            event=Gdk.Event.new(Gdk.EventType.BUTTON_PRESS);event.button=1;event.x_root=0;event.y_root=0
            key=next(iter(tray.items));tray.press(key,item['button'],event);event.button=3;tray.press(key,item['button'],event)
            panel=Panel();box.pack_start(panel,False,False,0);panel.show_all();pump(1)
            assert panel.title.get_text()=='Test Song',panel.title.get_text()
            assert panel.artist.get_text()=='Test Artist',panel.artist.get_text()
            assert panel.length.get_text()=='03:00',panel.length.get_text()
            panel.command('play_pause');panel.command('next');panel.command('previous');panel.seek.set_value(30);panel.finish_seek();pump(.5)
            calls=[json.loads(line) for line in log.read_text().splitlines()]
            methods=[call[0] for call in calls]
            for name in ('Activate','ContextMenu','PlayPause','Next','Previous','SetPosition'):assert name in methods,(name,calls)
            assert next(call[1] for call in calls if call[0]=='SetPosition')==['/track/test',30000000],calls
            assert panel.buttons['play_pause'].get_accessible().get_name()=='Play'
            process.terminate();process.wait(timeout=3);pump(1)
            assert not tray.items,tray.items
            assert panel.title.get_text()=='Nothing Playing';assert not panel.buttons['play_pause'].get_sensitive()
            window.destroy();tray.stop();pump(.1)
        finally:
            if process.poll() is None:process.terminate();process.wait(timeout=3)
    print('Tray registration, activation, context action and exit cleanup passed. MPRIS metadata, playback, seeking and player removal passed.')


if __name__=='__main__':
    if '--mock' in sys.argv:mock(sys.argv[-1])
    else:test()
