"""Read Codex quotas through its local app-server; render Waybar JSON or GTK UI."""

import argparse
import fcntl
import html
import json
import math
import os
import selectors
import subprocess
import threading
import time
from datetime import datetime
from pathlib import Path

CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "codex-usage"
CACHE.mkdir(parents=True, exist_ok=True, mode=0o700)
SNAPSHOT = CACHE / "limits.json"


def read_limits():
    """No inference calls, threads or credentials copied out of Codex."""
    proc = subprocess.Popen(
        ["codex", "app-server", "--stdio"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )

    def send(value):
        proc.stdin.write((json.dumps(value) + "\n").encode())
        proc.stdin.flush()

    selector = selectors.DefaultSelector()
    selector.register(proc.stdout, selectors.EVENT_READ)
    buffer = b""
    try:
        send(
            {
                "id": 1,
                "method": "initialize",
                "params": {
                    "clientInfo": {"name": "waybar_codex_usage", "version": "1.0.0"}
                },
            }
        )
        deadline = time.monotonic() + 25
        while time.monotonic() < deadline:
            if not selector.select(timeout=min(1, max(0, deadline - time.monotonic()))):
                continue
            chunk = os.read(proc.stdout.fileno(), 65536)
            if not chunk:
                raise RuntimeError("Codex account service closed before replying.")
            buffer += chunk
            while b"\n" in buffer:
                line, buffer = buffer.split(b"\n", 1)
                try:
                    message = json.loads(line)
                except (ValueError, UnicodeDecodeError):
                    continue
                if message.get("id") not in (1, 2):
                    continue
                if "error" in message:
                    raise RuntimeError(
                        "Codex could not read usage. Check your Codex sign-in."
                    )
                if message["id"] == 1:
                    send({"method": "initialized"})
                    send({"id": 2, "method": "account/rateLimits/read"})
                else:
                    result = message["result"]
                    limits = result.get("rateLimitsByLimitId", {}).get("codex")
                    limits = limits or result.get("rateLimits")
                    if not limits:
                        raise RuntimeError(
                            "This account did not return Codex usage limits."
                        )
                    # Store quota data only, never account IDs, auth tokens or reset-credit IDs.
                    return {
                        "fetched_at": time.time(),
                        "limits": {
                            key: limits.get(key)
                            for key in ("primary", "secondary", "planType")
                        },
                    }
        raise RuntimeError("Codex usage request timed out. Try Refresh.")
    finally:
        selector.close()
        proc.terminate()
        try:
            proc.wait(timeout=3)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()
        proc.stdin.close()
        proc.stdout.close()


def load_cache():
    try:
        value = json.loads(SNAPSHOT.read_text())
        if not isinstance(value.get("limits"), dict):
            return None
        float(value["fetched_at"])
        return value
    except (OSError, ValueError, TypeError, KeyError):
        return None


def snapshot(force=False):
    with (CACHE / "refresh.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        cached = load_cache()
        if not force and cached and 0 <= time.time() - cached["fetched_at"] < 55:
            return cached
        try:
            value = read_limits()
            temporary = SNAPSHOT.with_suffix(".tmp")
            temporary.write_text(json.dumps(value))
            temporary.chmod(0o600)
            temporary.replace(SNAPSHOT)
            return value
        except (OSError, RuntimeError, ValueError) as exc:
            if cached:
                return {**cached, "error": str(exc)}
            return {"limits": {}, "fetched_at": None, "error": str(exc)}


def windows(data):
    """Match by duration; the API does not promise primary always means five hours."""
    return {
        item.get("windowDurationMins"): item
        for key in ("primary", "secondary")
        if isinstance(item := data.get("limits", {}).get(key), dict)
    }


def remaining(window):
    if not window or window.get("usedPercent") is None:
        return None
    try:
        value = float(window["usedPercent"])
    except (ValueError, TypeError):
        return None
    return min(100, max(0, 100 - value)) if math.isfinite(value) else None


def percent(window):
    value = remaining(window)
    return f"{value:g}%" if value is not None else "unavailable"


def reset_text(window):
    if not window or not window.get("resetsAt"):
        return "Reset time unavailable"
    timestamp = window["resetsAt"]
    if timestamp <= time.time():
        return "Reset time passed — refresh for current usage"
    delta = int(timestamp - time.time())
    days, hours, minutes = delta // 86400, delta // 3600 % 24, delta // 60 % 60
    duration = (
        (f"{days}d " if days else "")
        + (f"{hours}h " if days or hours else "")
        + f"{minutes}m"
    )
    return f"Resets in {duration} · {datetime.fromtimestamp(timestamp):%a %d %b, %H:%M}"


def waybar(data):
    buckets = windows(data)
    values = [remaining(buckets.get(duration)) for duration in (300, 10080)]
    available = [value for value in values if value is not None]
    stale = bool(data.get("error")) or any(
        isinstance(item.get("resetsAt"), (int, float))
        and item["resetsAt"] <= time.time()
        for item in buckets.values()
    )
    state = (
        "stale"
        if stale
        else "unavailable"
        if not available
        else (
            "critical"
            if min(available) <= 10
            else "warning"
            if min(available) <= 25
            else "normal"
        )
    )
    short = [f"{value:g}%" if value is not None else "—" for value in values]
    lines = ["Codex usage remaining", ""]
    for duration, label in ((300, "5-hour window"), (10080, "Weekly window")):
        window = buckets.get(duration)
        lines.extend([f"{label}: {percent(window)} remaining", reset_text(window), ""])
    if data.get("fetched_at"):
        lines.append(
            f"Last checked: {datetime.fromtimestamp(data['fetched_at']):%H:%M:%S}"
        )
    if stale:
        lines.append("Saved snapshot — refresh for current usage.")
    if data.get("error"):
        lines.append(data["error"])
    lines.append("Click for details · Right-click to refresh")
    return {
        "text": f"Codex{' ~' if stale else ''} 5h {short[0]} · W {short[1]}",
        "class": state,
        "tooltip": html.escape("\n".join(lines)),
    }


def popup():
    import gi

    gi.require_version("Gtk", "3.0")
    gi.require_version("Gdk", "3.0")
    gi.require_version("GtkLayerShell", "0.1")
    from gi.repository import Gdk, GLib, Gtk, GtkLayerShell

    lock = (CACHE / "popup.lock").open("w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        return

    win = Gtk.Window(title="Codex usage")
    win.set_name("codex-usage")
    win.set_default_size(380, -1)
    win.set_resizable(False)
    GtkLayerShell.init_for_window(win)
    GtkLayerShell.set_namespace(win, "codex-usage")
    GtkLayerShell.set_layer(win, GtkLayerShell.Layer.OVERLAY)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.TOP, True)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.RIGHT, True)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.TOP, 10)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.RIGHT, 12)
    GtkLayerShell.set_keyboard_mode(win, GtkLayerShell.KeyboardMode.ON_DEMAND)
    css = Gtk.CssProvider()
    css.load_from_data(b"""
        #codex-usage { background: #0f1915; color: #d7e7d6;
            border: 1px solid #365b48; border-radius: 8px; }
        #codex-usage label { font-family: sans-serif; font-size: 13px; }
        #codex-usage .title { font-size: 18px; font-weight: bold; }
        #codex-usage .muted { color: #aec7b4; font-size: 12px; }
        #codex-usage .value { font-weight: bold; color: #9ed6ad; }
        #codex-usage progressbar trough { min-height: 6px; background: #273e30;
            border: none; border-radius: 3px; }
        #codex-usage progressbar progress { min-height: 6px; background: #9ed6ad;
            border: none; border-radius: 3px; }
        #codex-usage button { background: #273e30; color: #e1efdf;
            border: 1px solid #547c61; border-radius: 4px; padding: 6px 12px; }
        #codex-usage button:hover { background: #365b48; }
        #codex-usage button:focus { border-color: #e4ca95; }
        #codex-usage button:disabled { color: #aec7b4; }
    """)
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
    box.set_border_width(22)
    win.add(box)

    def label(text, style=None):
        item = Gtk.Label(label=text, xalign=0)
        if style:
            item.get_style_context().add_class(style)
        return item

    header = Gtk.Box(spacing=20)
    header.pack_start(label("Codex usage", "title"), True, True, 0)
    close = Gtk.Button(label="Close")
    close.connect("clicked", lambda *_: win.destroy())
    header.pack_end(close, False, False, 0)
    box.pack_start(header, False, False, 0)
    rows = {}
    for duration, title in ((300, "5-hour window"), (10080, "Weekly window")):
        group = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        line = Gtk.Box(spacing=20)
        line.pack_start(label(title), True, True, 0)
        value = label("Loading…", "value")
        line.pack_end(value, False, False, 0)
        bar = Gtk.ProgressBar()
        reset = label("", "muted")
        group.pack_start(line, False, False, 0)
        group.pack_start(bar, False, False, 0)
        group.pack_start(reset, False, False, 0)
        box.pack_start(group, False, False, 0)
        rows[duration] = value, bar, reset
    status = label("Checking your account…", "muted")
    status.set_line_wrap(True)
    status.set_max_width_chars(45)
    box.pack_start(status, False, False, 0)
    refresh = Gtk.Button(label="Refresh usage")
    box.pack_start(refresh, False, False, 0)
    last_data = [None]

    def render(data):
        last_data[0] = data
        buckets = windows(data)
        for duration, (value, bar, reset) in rows.items():
            window = buckets.get(duration)
            left = remaining(window)
            value.set_text(
                f"{percent(window)} left" if left is not None else "Unavailable"
            )
            bar.set_fraction((left or 0) / 100)
            reset.set_text(reset_text(window))
        if data.get("error"):
            status.set_text(
                "Could not refresh. "
                + data["error"]
                + (" Showing saved usage." if data.get("fetched_at") else "")
            )
        else:
            stamp = datetime.fromtimestamp(data["fetched_at"]).strftime("%H:%M:%S")
            status.set_text(
                f"Checked {stamp} · {(data['limits'].get('planType') or 'Codex').title()} plan\n"
                "Percentages show allowance remaining."
            )

    def done(data):
        if win.get_visible():
            render(data)
            refresh.set_sensitive(True)
            refresh.set_label("Refresh usage")
            subprocess.run(
                ["pkill", "-RTMIN+8", "-x", "waybar"],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        return False

    def update(*_):
        refresh.set_sensitive(False)
        refresh.set_label("Refreshing…")
        threading.Thread(
            target=lambda: GLib.idle_add(done, snapshot(force=True)), daemon=True
        ).start()

    refresh.connect("clicked", update)
    win.connect("destroy", lambda *_: Gtk.main_quit())
    win.connect(
        "key-press-event",
        lambda _, event: win.destroy() if event.keyval == Gdk.KEY_Escape else False,
    )
    win.connect("focus-out-event", lambda *_: win.destroy())
    cached = load_cache()
    if cached:
        render(cached)
        status.set_text("Saved snapshot · refreshing…")
    win.show_all()
    update()
    Gtk.main()
    lock.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "mode", nargs="?", choices=("bar", "popup", "refresh", "json"), default="bar"
    )
    args = parser.parse_args()
    if args.mode == "popup":
        popup()
    else:
        data = snapshot(force=args.mode == "refresh")
        if args.mode == "refresh":
            subprocess.run(
                ["pkill", "-RTMIN+8", "-x", "waybar"],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        else:
            print(json.dumps(waybar(data) if args.mode == "bar" else data))


if __name__ == "__main__":
    main()
