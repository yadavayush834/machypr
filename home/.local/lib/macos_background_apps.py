"""Window-independent app presence and explicit, scoped quit controls."""
from concurrent.futures import ThreadPoolExecutor
import os
from pathlib import Path
import signal
import subprocess

# Exact native executable names only: never match arbitrary command-line text.
NATIVE={
 'chatgpt':('ChatGPT','/usr/share/pixmaps/chatgpt.png',{'ChatGPT'}),
 'docker':('Docker Desktop','/opt/docker-desktop/share/icon.original.png',{'Docker Desktop','com.docker.backend'}),
 'discord':('Discord','com.discordapp.Discord',{'Discord','discord'}),
 'telegram':('Telegram','org.telegram.desktop',{'Telegram','telegram-desktop'}),
 'spotify':('Spotify','com.spotify.Client',{'spotify'}),
 'vlc':('VLC','org.videolan.VLC',{'vlc','vlc.bin'}),
 'code':('Visual Studio Code','visual-studio-code',{'code'}),
 'brave':('Brave','brave-browser',{'brave'}),
}


def process_record(folder):
    try:
        if folder.stat().st_uid!=os.getuid():return None
        args=(folder/'cmdline').read_bytes().split(b'\0')
        if not args[0] or any(a.startswith(b'--type=') for a in args):return None
        stat=(folder/'stat').read_text().rsplit(')',1)[1].split()
        if stat[0]=='Z':return None
        return (int(folder.name),stat[19],os.path.basename(os.readlink(folder/'exe')))
    except (OSError,ValueError,IndexError):return None


def discover(proc=Path('/proc'),flatpak_output=None):
    apps={}
    for folder in proc.iterdir():
        if not folder.name.isdigit():continue
        record=process_record(folder)
        if not record:continue
        # Sandboxed apps are accounted for by their Flatpak application ID below.
        if (folder/'root/.flatpak-info').exists():continue
        for key,(label,icon,names) in NATIVE.items():
            if record[2] in names:
                item=apps.setdefault(key,{'label':label,'icon':icon,'processes':[]})
                item['processes'].append(record)
    if flatpak_output is None:
        try:flatpak_output=subprocess.check_output(['flatpak','ps','--columns=application'],text=True,timeout=3)
        except (OSError,subprocess.SubprocessError):flatpak_output=''
    for app_id in set(flatpak_output.splitlines()):
        if not app_id or '.' not in app_id or any(c.isspace() for c in app_id):continue
        key=next((key for key in NATIVE if key in app_id.lower()),app_id)
        label,icon=NATIVE.get(key,(app_id.rsplit('.',1)[-1],app_id,set()))[:2]
        apps[key]={'label':label,'icon':icon,'flatpak':app_id,'processes':[]}
    return apps


def quit_app(key,item,proc=Path('/proc')):
    if key=='docker':
        subprocess.run(['systemctl','--user','stop','docker-desktop.service'],timeout=30,check=False)
    elif item.get('flatpak'):
        subprocess.run(['flatpak','kill',item['flatpak']],timeout=10,check=False)
    else:
        for record in item.get('processes',[]):
            # Revalidate the process start time and executable before signalling.
            if process_record(proc/str(record[0]))==record:
                try:os.kill(record[0],signal.SIGTERM)
                except ProcessLookupError:pass


class BackgroundApps:
    def __init__(self,container,tray):
        import gi
        gi.require_version('Gtk','3.0')
        from gi.repository import Gtk,Gdk,GLib
        self.Gtk,self.Gdk,self.GLib=Gtk,Gdk,GLib
        self.container=container;self.tray=tray;self.buttons={};self.apps={}
        self.executor=ThreadPoolExecutor(max_workers=1);self.future=None;self.alive=True
        self.timer=GLib.timeout_add_seconds(2,self.refresh);self.refresh()

    def refresh(self):
        if not self.alive:return False
        if self.future is not None and self.future.done():
            try:self.apps=self.future.result()
            except Exception:self.apps={}
            self.future=None;self.render()
        if self.future is None:self.future=self.executor.submit(discover)
        return True

    def render(self):
        Gtk=self.Gtk
        identities=' '.join(str(item['properties'].get('Id',''))+' '+str(item['properties'].get('Title','')) for item in self.tray.items.values()).lower()
        shown={key:item for key,item in self.apps.items() if key not in identities}
        for key in list(self.buttons):
            if key not in shown:self.buttons.pop(key).destroy()
        for key,item in sorted(shown.items()):
            if key not in self.buttons:
                button=Gtk.Button();button.get_style_context().add_class('status')
                if item['icon'].startswith('/'):
                    from gi.repository import GdkPixbuf
                    try:
                        scale=max(1,self.container.get_scale_factor())
                        pixbuf=GdkPixbuf.Pixbuf.new_from_file_at_scale(item['icon'],16*scale,16*scale,True)
                        image=Gtk.Image.new_from_surface(self.Gdk.cairo_surface_create_from_pixbuf(pixbuf,scale,None))
                    except Exception:image=Gtk.Image.new_from_icon_name('application-x-executable-symbolic',Gtk.IconSize.MENU)
                else:image=Gtk.Image.new_from_icon_name(item['icon'],Gtk.IconSize.MENU)
                image.set_pixel_size(16);button.add(image)
                button.connect('button-press-event',lambda w,e,k=key:self.menu(k,e))
                self.container.pack_start(button,False,False,0);self.buttons[key]=button;button.show_all()
            button=self.buttons[key];button.set_tooltip_text(item['label']+' is running — right-click to quit');button.get_accessible().set_name(item['label']+' running application')

    def menu(self,key,event):
        if event.button not in (1,3) or key not in self.apps:return False
        Gtk=self.Gtk;menu=Gtk.Menu();title=Gtk.MenuItem(label=self.apps[key]['label']+' · Running');title.set_sensitive(False);menu.append(title)
        snapshot=self.apps[key]
        quit=Gtk.MenuItem(label='Quit application');quit.connect('activate',lambda *_:self.executor.submit(quit_app,key,snapshot));menu.append(quit)
        menu.show_all();menu.popup_at_pointer(event);return True

    def stop(self):
        self.alive=False;self.GLib.source_remove(self.timer);self.executor.shutdown(wait=False,cancel_futures=True)
