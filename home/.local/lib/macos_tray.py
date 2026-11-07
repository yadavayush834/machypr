"""StatusNotifier host for apps that explicitly publish tray controls."""
import os
import signal
import subprocess
import cairo
import gi
gi.require_version('Gtk','3.0')
gi.require_version('DbusmenuGtk3','0.4')
from gi.repository import Gtk,Gdk,GdkPixbuf,Gio,GLib,DbusmenuGtk3

WATCHER='org.kde.StatusNotifierWatcher'
PATH='/StatusNotifierWatcher'
ITEM='org.kde.StatusNotifierItem'
XML='''<node><interface name="org.kde.StatusNotifierWatcher">
<method name="RegisterStatusNotifierItem"><arg type="s" direction="in"/></method>
<method name="RegisterStatusNotifierHost"><arg type="s" direction="in"/></method>
<property name="RegisteredStatusNotifierItems" type="as" access="read"/>
<property name="IsStatusNotifierHostRegistered" type="b" access="read"/>
<property name="ProtocolVersion" type="i" access="read"/>
<signal name="StatusNotifierItemRegistered"><arg type="s"/></signal>
<signal name="StatusNotifierItemUnregistered"><arg type="s"/></signal>
<signal name="StatusNotifierHostRegistered"/>
</interface></node>'''


class Tray:
    def __init__(self,container):
        self.container=container;self.items={};self.owned=False;self.alive=True
        self.bus=Gio.bus_get_sync(Gio.BusType.SESSION,None)
        info=Gio.DBusNodeInfo.new_for_xml(XML).interfaces[0]
        self.registration=self.bus.register_object(PATH,info,self.method,self.property,None)
        self.owner=Gio.bus_own_name_on_connection(self.bus,WATCHER,Gio.BusNameOwnerFlags.NONE,self.acquired,self.existing)
        self.subscriptions=[self.bus.signal_subscribe('org.freedesktop.DBus','org.freedesktop.DBus','NameOwnerChanged','/org/freedesktop/DBus',None,Gio.DBusSignalFlags.NONE,self.owner_changed)]
        self.subscriptions.append(self.bus.signal_subscribe(None,ITEM,None,None,None,Gio.DBusSignalFlags.NONE,self.item_changed))
        self.subscriptions.append(self.bus.signal_subscribe(WATCHER,WATCHER,None,PATH,None,Gio.DBusSignalFlags.NONE,self.watcher_changed))

    def emit(self,name,item=None):
        if self.owned:self.bus.emit_signal(None,PATH,WATCHER,name,GLib.Variant('(s)',(item,)) if item else None)

    def property(self,connection,sender,path,interface,name):
        if name=='RegisteredStatusNotifierItems':return GLib.Variant('as',list(self.items))
        if name=='IsStatusNotifierHostRegistered':return GLib.Variant('b',True)
        if name=='ProtocolVersion':return GLib.Variant('i',0)

    def method(self,connection,sender,path,interface,method,args,invocation):
        if method=='RegisterStatusNotifierItem':
            value=args.unpack()[0]
            self.add(sender+value if value.startswith('/') else value+'/StatusNotifierItem')
        elif method=='RegisterStatusNotifierHost':self.emit('StatusNotifierHostRegistered')
        invocation.return_value(None)

    def acquired(self,*_):
        self.owned=True;self.emit('StatusNotifierHostRegistered')

    def existing(self,*_):
        self.owned=False
        self.bus.call(WATCHER,PATH,WATCHER,'RegisterStatusNotifierHost',GLib.Variant('(s)',(self.bus.get_unique_name(),)),None,Gio.DBusCallFlags.NONE,2000,None,None)
        def loaded(bus,result):
            try:
                for item in bus.call_finish(result).unpack()[0]:self.add(item)
            except GLib.Error:pass
        self.bus.call(WATCHER,PATH,'org.freedesktop.DBus.Properties','Get',GLib.Variant('(ss)',(WATCHER,'RegisteredStatusNotifierItems')),None,Gio.DBusCallFlags.NONE,2000,None,loaded)

    def watcher_changed(self,bus,sender,path,interface,signal,args):
        if self.owned:return
        if signal=='StatusNotifierItemRegistered':self.add(args.unpack()[0])
        elif signal=='StatusNotifierItemUnregistered':self.remove(args.unpack()[0])

    def add(self,key):
        if '/' not in key:return
        if key in self.items:self.refresh(key);return
        service,path=key.split('/',1);path='/'+path
        button=Gtk.Button();button.get_style_context().add_class('status');image=Gtk.Image();image.set_pixel_size(16);button.add(image)
        self.items[key]={'service':service,'path':path,'button':button,'image':image,'properties':{},'menu':None,'pending':False}
        button.connect('button-press-event',lambda widget,event:self.press(key,widget,event))
        button.connect('scroll-event',lambda _,event:self.scroll(key,event))
        button.add_events(Gdk.EventMask.SCROLL_MASK)
        self.container.pack_start(button,False,False,0);self.refresh(key)
        def owner(bus,result):
            try:
                if key in self.items:self.items[key]['owner']=bus.call_finish(result).unpack()[0]
            except GLib.Error:self.remove(key)
        self.bus.call('org.freedesktop.DBus','/org/freedesktop/DBus','org.freedesktop.DBus','GetNameOwner',GLib.Variant('(s)',(service,)),None,Gio.DBusCallFlags.NONE,2000,None,owner)
        self.emit('StatusNotifierItemRegistered',key)

    def remove(self,key):
        item=self.items.pop(key,None)
        if item:
            if item['menu']:item['menu'].destroy()
            item['button'].destroy();self.emit('StatusNotifierItemUnregistered',key)

    def owner_changed(self,bus,sender,path,interface,signal,args):
        name,old,new=args.unpack()
        if old and not new:
            for key,item in list(self.items.items()):
                if name in (item['service'],item.get('owner')):self.remove(key)

    def item_changed(self,bus,sender,path,interface,signal,args):
        for key,item in list(self.items.items()):
            if path==item['path'] and sender in (item['service'],item.get('owner')):self.refresh(key)

    def refresh(self,key):
        item=self.items.get(key)
        if not item or item['pending']:return
        item['pending']=True
        def done(bus,result):
            if not self.alive or key not in self.items:return
            item['pending']=False
            try:props=bus.call_finish(result).unpack()[0]
            except GLib.Error:return
            item['properties']=props
            menu_path=props.get('Menu')
            if menu_path!=item.get('menu_path'):
                if item['menu']:item['menu'].destroy()
                item['menu']=DbusmenuGtk3.Menu.new(item['service'],menu_path) if menu_path and menu_path!='/' else None
                item['menu_path']=menu_path
            title=props.get('Title') or props.get('Id') or item['service']
            item['button'].set_tooltip_text(title);item['button'].get_accessible().set_name(title+' background app')
            theme_path=props.get('IconThemePath')
            theme=Gtk.IconTheme.get_default()
            if theme_path and theme_path not in theme.get_search_path():theme.append_search_path(theme_path)
            icon=props.get('AttentionIconName') if props.get('Status')=='NeedsAttention' else props.get('IconName')
            if icon:item['image'].set_from_icon_name(icon,Gtk.IconSize.MENU)
            else:
                pixmaps=props.get('IconPixmap',[])
                if pixmaps:
                    scale=max(1,item['button'].get_scale_factor());target=16*scale
                    choices=[p for p in pixmaps if p[0]>=target and p[1]>=target] or pixmaps
                    w,h,pixels=min(choices,key=lambda p:abs(p[0]-target));argb=bytes(pixels)
                    if w>0 and h>0 and len(argb)==w*h*4:
                        rgba=bytearray(len(argb))
                        for i in range(0,len(argb),4):rgba[i:i+4]=argb[i+1:i+4]+argb[i:i+1]
                        pixbuf=GdkPixbuf.Pixbuf.new_from_bytes(GLib.Bytes.new(bytes(rgba)),GdkPixbuf.Colorspace.RGB,True,8,w,h,w*4)
                        pixbuf=pixbuf.scale_simple(target,target,GdkPixbuf.InterpType.HYPER)
                        surface=Gdk.cairo_surface_create_from_pixbuf(pixbuf,scale,None)
                        item['image'].set_from_surface(surface)
                else:item['image'].set_from_icon_name('application-x-executable-symbolic',Gtk.IconSize.MENU)
            # Network and Bluetooth already have dedicated menu-bar controls.
            duplicate=props.get('Id','').lower() in ('nm-applet','blueman','blueman-applet')
            item['button'].show_all();item['button'].set_visible(props.get('Status')!='Passive' and not duplicate)
        self.bus.call(item['service'],item['path'],'org.freedesktop.DBus.Properties','GetAll',GLib.Variant('(s)',(ITEM,)),None,Gio.DBusCallFlags.NONE,2000,None,done)

    def call(self,key,method,args):
        item=self.items.get(key)
        if item:self.bus.call(item['service'],item['path'],ITEM,method,args,None,Gio.DBusCallFlags.NONE,2000,None,None)

    def press(self,key,button,event):
        item=self.items.get(key)
        if not item:return False
        mouse_button=event.get_button()[1]
        _,x,y=event.get_root_coords()
        menu_path=item['properties'].get('Menu')
        if mouse_button==3 or item['properties'].get('ItemIsMenu'):
            if menu_path and menu_path!='/':
                if item['menu'] is None:item['menu']=DbusmenuGtk3.Menu.new(item['service'],menu_path)
                item['menu'].show_all();item['menu'].popup_at_widget(button,Gdk.Gravity.SOUTH_EAST,Gdk.Gravity.NORTH_EAST,event)
            else:
                self.call(key,'ContextMenu',GLib.Variant('(ii)',(int(x),int(y))))
                menu=Gtk.Menu()
                for label,callback in [('Open',lambda *_:self.call(key,'Activate',GLib.Variant('(ii)',(int(x),int(y))))),('Quit application',lambda *_:self.quit_app(key))]:
                    entry=Gtk.MenuItem(label=label);entry.connect('activate',callback);menu.append(entry)
                menu.show_all();menu.popup_at_pointer(event)
        elif mouse_button==1:self.call(key,'Activate',GLib.Variant('(ii)',(int(x),int(y))))
        elif mouse_button==2:self.call(key,'SecondaryActivate',GLib.Variant('(ii)',(int(x),int(y))))
        return True

    def quit_app(self,key):
        item=self.items.get(key)
        if not item:return
        identity=(str(item['properties'].get('Id',''))+' '+str(item['properties'].get('Title',''))).lower()
        for name,app_id in [('discord','com.discordapp.Discord'),('spotify','com.spotify.Client'),('telegram','org.telegram.desktop'),('vlc','org.videolan.VLC')]:
            if name in identity:
                subprocess.Popen(['flatpak','kill',app_id]);return
        def done(bus,result):
            try:
                pid=bus.call_finish(result).unpack()[0]
                from pathlib import Path
                command=Path(f'/proc/{pid}/cmdline').read_bytes()
                if pid>1 and b'dbus-proxy' not in command:os.kill(pid,signal.SIGTERM)
            except (GLib.Error,OSError):pass
        self.bus.call('org.freedesktop.DBus','/org/freedesktop/DBus','org.freedesktop.DBus','GetConnectionUnixProcessID',GLib.Variant('(s)',(item['service'],)),None,Gio.DBusCallFlags.NONE,2000,None,done)

    def scroll(self,key,event):
        self.call(key,'Scroll',GLib.Variant('(is)',(120 if event.direction==Gdk.ScrollDirection.UP else -120,'vertical')));return True

    def stop(self):
        self.alive=False
        for key in list(self.items):self.remove(key)
        for subscription in self.subscriptions:self.bus.signal_unsubscribe(subscription)
        Gio.bus_unown_name(self.owner);self.bus.unregister_object(self.registration)
