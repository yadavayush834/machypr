"""Keep the application grid ready; forward subsequent invocations over IPC."""
import fcntl
import os
from pathlib import Path
import socket
import sys
import time


class Session:
    def __init__(self):
        runtime = Path(os.environ['XDG_RUNTIME_DIR'])
        self.path = runtime / 'macos-launchpad.sock'
        command = b'hide' if '--hide' in sys.argv else b'show'
        if '--background' in sys.argv:
            command = b'background'
        self.background = command == b'background'
        self.lock = open(runtime / 'macos-launchpad.lock', 'w')
        try:
            fcntl.flock(self.lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            with socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM) as client:
                for _ in range(100):
                    try:
                        client.sendto(command, str(self.path))
                        raise SystemExit(0)
                    except (FileNotFoundError, ConnectionRefusedError):
                        time.sleep(.02)
            raise SystemExit('Launchpad is starting; please try again.')
        self.path.unlink(missing_ok=True)
        self.socket = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
        self.socket.bind(str(self.path))
        os.chmod(self.path, 0o600)
        self.socket.setblocking(False)

    def attach(self, GLib, show, hide):
        def receive(*_):
            try:
                command = self.socket.recv(64)
            except BlockingIOError:
                return True
            if command == b'show':
                show()
            elif command == b'hide':
                hide()
            return True
        GLib.io_add_watch(self.socket, GLib.IO_IN, receive)

    def close(self):
        self.socket.close()
        self.path.unlink(missing_ok=True)
