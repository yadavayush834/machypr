#!/usr/bin/env python3
"""Download pinned macOS sound samples locally and convert them for PipeWire."""
from pathlib import Path
import subprocess
import tempfile
import urllib.request

REVISION='20dab112698edc9523afe9f09b8e921f75da8a96'
FILES={'notification':'sounds/error/Glass.aiff','critical':'sounds/error/Basso.aiff','volume':'sounds/system/Media_Keys.aif','screenshot':'sounds/system/Screen_Capture.aif'}
destination=Path.home()/'.local/share/sounds/MacDesktop/stereo'
destination.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(prefix='mac-sounds-') as directory:
    for name,remote in FILES.items():
        target=destination/(name+'.wav')
        if target.exists():continue
        source=Path(directory)/(name+Path(remote).suffix)
        urllib.request.urlretrieve('https://raw.githubusercontent.com/ThisIsNoahEvans/BigSurSounds/'+REVISION+'/'+remote,source)
        temporary=destination/('.'+name+'.wav')
        subprocess.run(['ffmpeg','-v','error','-y','-i',str(source),'-ar','48000','-ac','2',str(temporary)],check=True)
        temporary.replace(target)
        print('Installed:',name)
(destination.parent/'index.theme').write_text('[Sound Theme]\nName=Mac Desktop\nDirectories=stereo\nInherits=freedesktop\n\n[stereo]\nOutputProfile=stereo\n')
for alias,name in {'message-new-instant':'notification','dialog-information':'notification','dialog-warning':'critical','dialog-error':'critical','audio-volume-change':'volume','screen-capture':'screenshot'}.items():
    target=destination/(alias+'.wav');target.unlink(missing_ok=True);target.symlink_to(name+'.wav')
(destination.parent/'SOURCE.txt').write_text('Source: https://github.com/ThisIsNoahEvans/BigSurSounds\nRevision: '+REVISION+'\nOriginal macOS sounds belong to Apple. Samples are downloaded locally, not bundled with the dotfiles.\n')
