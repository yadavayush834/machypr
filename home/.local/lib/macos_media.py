"""Native Now Playing controls for MPRIS players, including supported browsers."""
import threading
import urllib.parse
import urllib.request
import gi
gi.require_version('Gtk','3.0')
gi.require_version('Playerctl','2.0')
from gi.repository import Gtk,GLib,GdkPixbuf,Playerctl,Pango


def clock(microseconds):
    seconds=max(0,int(microseconds)//1000000)
    return f'{seconds//60:02}:{seconds%60:02}'


class Media:
    def __init__(self):
        self.manager=Playerctl.PlayerManager.new();self.players={};self.changed=None
        self.manager.connect('name-appeared',lambda _,name:self.add(name))
        self.manager.connect('player-vanished',self.remove)
        for name in self.manager.props.player_names:self.add(name)

    def add(self,name):
        try:
            if name.instance in self.players:return
            player=Playerctl.Player.new_from_name(name);self.players[name.instance]=player;self.manager.manage_player(player)
            player.connect('metadata',self.notify);player.connect('playback-status',self.notify);self.notify()
        except GLib.Error:pass

    def remove(self,manager,player):
        self.players.pop(player.props.player_instance,None);self.notify()

    def notify(self,*_):
        if self.changed:self.changed()

    def selected(self,name=None):
        if name in self.players:return self.players[name]
        return next((p for p in self.players.values() if p.props.playback_status==Playerctl.PlaybackStatus.PLAYING),next(iter(self.players.values()),None))


class Panel(Gtk.Box):
    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL,spacing=5)
        self.set_border_width(10);self.set_size_request(290,-1)
        self.media=Media();self.alive=True;self.seeking=False;self.art_url=None;self.selection=None;self.populating=False
        self.sources=Gtk.ComboBoxText();self.sources.set_no_show_all(True);self.sources.connect('changed',self.choose);self.pack_start(self.sources,False,False,0)
        top=Gtk.Box(spacing=10);self.art=Gtk.Image.new_from_icon_name('audio-x-generic-symbolic',Gtk.IconSize.DIALOG);self.art.set_pixel_size(42);self.art.set_size_request(48,48);top.pack_start(self.art,False,False,0)
        text=Gtk.Box(orientation=Gtk.Orientation.VERTICAL,spacing=3);text.set_valign(Gtk.Align.CENTER)
        self.title=Gtk.Label(label='Nothing Playing',xalign=0);self.title.set_ellipsize(Pango.EllipsizeMode.END);self.title.set_max_width_chars(25);self.title.get_style_context().add_class('track-title')
        self.artist=Gtk.Label(label='Play music in a supported app.',xalign=0);self.artist.set_ellipsize(Pango.EllipsizeMode.END);self.artist.set_max_width_chars(27)
        text.pack_start(self.title,False,False,0);text.pack_start(self.artist,False,False,0);top.pack_start(text,True,True,0);self.pack_start(top,False,False,0)
        self.seek=Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL,0,1,1);self.seek.set_draw_value(False);self.seek.get_accessible().set_name('Playback position')
        self.seek.connect('button-press-event',lambda *_:self.drag(True));self.seek.connect('button-release-event',lambda *_:self.finish_seek())
        self.seek.connect('key-release-event',lambda *_:self.finish_seek());self.pack_start(self.seek,False,False,0)
        times=Gtk.Box();self.elapsed=Gtk.Label(label='00:00');self.length=Gtk.Label(label='00:00');times.pack_start(self.elapsed,False,False,0);times.pack_end(self.length,False,False,0);self.pack_start(times,False,False,0)
        controls=Gtk.Box(spacing=14);controls.set_halign(Gtk.Align.CENTER);self.buttons={}
        for name,icon,method in [('Previous','media-skip-backward-symbolic','previous'),('Play / Pause','media-playback-start-symbolic','play_pause'),('Next','media-skip-forward-symbolic','next')]:
            button=Gtk.Button.new_from_icon_name(icon,Gtk.IconSize.LARGE_TOOLBAR);button.set_tooltip_text(name);button.get_accessible().set_name(name)
            button.connect('clicked',lambda _,method=method:self.command(method));controls.pack_start(button,False,False,0);self.buttons[method]=button
        self.pack_start(controls,False,False,0)
        self.notice=Gtk.Label(label='',xalign=0);self.notice.set_no_show_all(True);self.notice.set_line_wrap(True);self.notice.set_max_width_chars(36);self.pack_start(self.notice,False,False,0)
        self.media.changed=self.refresh;self.refresh();self.timer=GLib.timeout_add_seconds(1,self.refresh)
        self.connect('destroy',self.stop)

    def stop(self,*_):
        self.alive=False;self.media.changed=None
        if self.timer:GLib.source_remove(self.timer);self.timer=None

    def choose(self,combo):
        if not self.populating:self.selection=combo.get_active_id();self.refresh()

    def drag(self,value):self.seeking=value;return False

    def finish_seek(self):
        player=self.media.selected(self.selection)
        if player and player.props.can_seek:
            try:player.set_position(int(self.seek.get_value()*1000000))
            except GLib.Error as error:self.notice.set_text(str(error))
        self.seeking=False;return False

    def command(self,method):
        player=self.media.selected(self.selection)
        if player:
            try:getattr(player,method)();self.notice.set_text('')
            except GLib.Error as error:self.notice.set_text(str(error))
        self.refresh()

    def artwork(self,url):
        if url==self.art_url:return
        self.art_url=url;self.art.set_from_icon_name('audio-x-generic-symbolic',Gtk.IconSize.DIALOG)
        if not url:return
        def fetch():
            pixbuf=None
            try:
                parsed=urllib.parse.urlparse(url)
                if parsed.scheme not in ('https','http','file'):return
                with urllib.request.urlopen(url,timeout=5) as stream:
                    data=stream.read(5*1024*1024+1)
                if len(data)>5*1024*1024:return
                loader=GdkPixbuf.PixbufLoader();loader.set_size(48,48);loader.write(data);loader.close();pixbuf=loader.get_pixbuf()
            except Exception:return
            def show():
                if self.alive and url==self.art_url:self.art.set_from_pixbuf(pixbuf)
                return False
            GLib.idle_add(show)
        threading.Thread(target=fetch,daemon=True).start()

    def refresh(self):
        if not self.alive:return False
        player=self.media.selected(self.selection);names=list(self.media.players)
        self.populating=True;self.sources.remove_all()
        for name in names:self.sources.append(name,self.media.players[name].props.player_name)
        if player:self.sources.set_active_id(player.props.player_instance)
        self.sources.set_visible(len(names)>1);self.populating=False
        metadata=player.props.metadata.unpack() if player and player.props.metadata else {}
        self.title.set_text(metadata.get('xesam:title') or ('Nothing Playing' if not player else 'Untitled Track'))
        self.title.set_tooltip_text(self.title.get_text())
        self.artist.set_text(' · '.join(filter(None,[', '.join(metadata.get('xesam:artist',[])),metadata.get('xesam:album','')])) or ('Play music or a video in a supported app.' if not player else player.props.player_name))
        self.artist.set_tooltip_text(self.artist.get_text());self.notice.set_visible(bool(self.notice.get_text()))
        length=max(0,int(metadata.get('mpris:length',0)));position=0
        if player:
            try:position=player.get_position()
            except GLib.Error:pass
        if not self.seeking:self.seek.set_range(0,max(1,length/1000000));self.seek.set_value(min(position,length)/1000000)
        self.seek.set_sensitive(bool(player and player.props.can_seek and length))
        self.elapsed.set_text(clock(position));self.length.set_text(clock(length))
        playing=player and player.props.playback_status==Playerctl.PlaybackStatus.PLAYING
        self.buttons['play_pause'].set_image(Gtk.Image.new_from_icon_name('media-playback-pause-symbolic' if playing else 'media-playback-start-symbolic',Gtk.IconSize.LARGE_TOOLBAR))
        self.buttons['play_pause'].get_accessible().set_name('Pause' if playing else 'Play')
        for method,capability in [('previous','can_go_previous'),('next','can_go_next')]:self.buttons[method].set_sensitive(bool(player and getattr(player.props,capability)))
        self.buttons['play_pause'].set_sensitive(bool(player and (player.props.can_pause if playing else player.props.can_play)))
        self.artwork(metadata.get('mpris:artUrl'))
        return True
