#!/usr/bin/env python3
import os
import json
import re
import subprocess
import sys
import time
from pathlib import Path


BACKLIGHT = "amdgpu_bl1"
SCRIPT = Path(__file__).resolve()
RUNTIME_DIR = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"))
STATE_PATH = RUNTIME_DIR / "hypr-osd-state.json"
START_LOCK = RUNTIME_DIR / "hypr-osd-start.lock"


def run(*args):
    return subprocess.run(args, text=True, capture_output=True, check=False)


def volume_state():
    out = run("wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@").stdout.strip()
    match = re.search(r"([0-9]+(?:\.[0-9]+)?)", out)
    value = round(float(match.group(1)) * 100) if match else 0
    muted = "MUTED" in out
    return max(0, min(100, value)), muted


def mic_state():
    out = run("wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@").stdout.strip()
    match = re.search(r"([0-9]+(?:\.[0-9]+)?)", out)
    value = round(float(match.group(1)) * 100) if match else 0
    muted = "MUTED" in out
    return max(0, min(100, value)), muted


def brightness_state():
    out = run("brightnessctl", "-d", BACKLIGHT, "info").stdout
    match = re.search(r"\((\d+)%\)", out)
    return max(0, min(100, int(match.group(1)))) if match else 0


def read_state():
    try:
        return json.loads(STATE_PATH.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return {"kind": "volume", "value": 0, "muted": False, "updated": 0}


def osd_is_running():
    current = os.getpid()
    for proc in Path("/proc").iterdir():
        if not proc.name.isdigit() or int(proc.name) == current:
            continue
        try:
            raw = (proc / "cmdline").read_bytes()
        except OSError:
            continue
        parts = [p.decode(errors="ignore") for p in raw.split(b"\0") if p]
        if any(arg in parts for arg in ("--show", "--watch")) and any(part == str(SCRIPT) for part in parts):
            return True
    return False


def show_osd(kind, value, muted=False):
    state = {"kind": kind, "value": value, "muted": muted, "updated": time.time()}
    tmp = STATE_PATH.with_name(f"{STATE_PATH.name}.{os.getpid()}.tmp")
    tmp.write_text(json.dumps(state))
    tmp.replace(STATE_PATH)

    if osd_is_running():
        return

    try:
        if START_LOCK.exists() and time.time() - START_LOCK.stat().st_mtime > 1:
            START_LOCK.unlink()
        START_LOCK.mkdir()
    except FileExistsError:
        return

    try:
        subprocess.Popen(
            [str(SCRIPT), "--show"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except Exception:
        try:
            START_LOCK.rmdir()
        except OSError:
            pass
        raise


def handle_control(kind, action):
    if kind == "volume":
        if action == "up":
            run("wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "5%+")
        elif action == "down":
            run("wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-")
        elif action == "mute":
            run("wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle")
        else:
            raise SystemExit("usage: osd_control.py volume [up|down|mute]")
        value, muted = volume_state()
        show_osd("volume", value, muted)
        return

    if kind == "mic":
        if action == "mute":
            run("wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle")
        else:
            raise SystemExit("usage: osd_control.py mic mute")
        value, muted = mic_state()
        show_osd("mic", value, muted)
        return

    if kind == "brightness":
        if action == "up":
            run("brightnessctl", "-d", BACKLIGHT, "set", "5%+")
        elif action == "down":
            run("brightnessctl", "-d", BACKLIGHT, "set", "5%-")
        else:
            raise SystemExit("usage: osd_control.py brightness [up|down]")
        show_osd("brightness", brightness_state())
        return

    raise SystemExit("usage: osd_control.py [volume|mic|brightness] ...")


def run_popup(persistent=False):
    if not os.environ.get("OSD_GTK4_LAYER_SHELL_PRELOADED"):
        for lib in (
            "/usr/lib/libgtk4-layer-shell.so",
            "/usr/lib/libgtk4-layer-shell.so.0",
        ):
            if os.path.exists(lib):
                env = os.environ.copy()
                env["OSD_GTK4_LAYER_SHELL_PRELOADED"] = "1"
                env["LD_PRELOAD"] = f"{lib}:{env.get('LD_PRELOAD', '')}".rstrip(":")
                os.execvpe(sys.executable, [sys.executable, *sys.argv], env)

    import gi

    gi.require_version("Gtk", "4.0")
    gi.require_version("Gdk", "4.0")
    gi.require_version("Gtk4LayerShell", "1.0")
    from gi.repository import Gdk, GLib, Gtk, Gtk4LayerShell

    css = """
    window { background: transparent; }
    .osd {
      background: rgba(10, 10, 10, 0.54);
      border: 1px solid rgba(255, 255, 255, 0.10);
      border-radius: 24px;
      box-shadow: 0 16px 44px rgba(0, 0, 0, 0.24);
      color: #f5f5f5;
      padding: 14px 18px;
    }
    image.icon { color: rgba(255, 255, 255, 0.88); }
    .label {
      font-size: 9px;
      font-weight: 700;
      letter-spacing: 0.10em;
      color: rgba(255, 255, 255, 0.56);
    }
    .value {
      font-size: 11px;
      font-weight: 700;
      color: rgba(255, 255, 255, 0.74);
    }
    progressbar trough {
      background: rgba(255, 255, 255, 0.16);
      border-radius: 999px;
      min-height: 7px;
    }
    progressbar progress {
      background: rgba(255, 255, 255, 0.84);
      border-radius: 999px;
      min-height: 7px;
    }
    """

    class Osd(Gtk.Application):
        def __init__(self):
            super().__init__(application_id="local.hypr.osd")
            self.last_seen_update = 0
            self.window = None

        def do_activate(self):
            if persistent:
                self.hold()

            try:
                START_LOCK.rmdir()
            except OSError:
                pass

            provider = Gtk.CssProvider()
            provider.load_from_data(css)
            Gtk.StyleContext.add_provider_for_display(
                Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )

            self.window = Gtk.ApplicationWindow(application=self)
            self.window.set_decorated(False)
            self.window.set_resizable(False)
            self.window.set_default_size(250, -1)

            Gtk4LayerShell.init_for_window(self.window)
            Gtk4LayerShell.set_namespace(self.window, "hypr-osd")
            Gtk4LayerShell.set_layer(self.window, Gtk4LayerShell.Layer.OVERLAY)
            Gtk4LayerShell.set_keyboard_mode(self.window, Gtk4LayerShell.KeyboardMode.NONE)
            Gtk4LayerShell.set_anchor(self.window, Gtk4LayerShell.Edge.BOTTOM, True)
            Gtk4LayerShell.set_margin(self.window, Gtk4LayerShell.Edge.BOTTOM, 145)

            box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
            box.add_css_class("osd")

            header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
            self.icon = Gtk.Image.new_from_icon_name("audio-volume-high-symbolic")
            self.icon.add_css_class("icon")
            self.icon.set_pixel_size(22)
            self.icon.set_hexpand(True)
            self.icon.set_halign(Gtk.Align.START)
            self.label = Gtk.Label()
            self.label.add_css_class("label")
            self.label.set_valign(Gtk.Align.CENTER)
            self.value_label = Gtk.Label()
            self.value_label.add_css_class("value")
            self.value_label.set_valign(Gtk.Align.CENTER)
            header.append(self.icon)
            header.append(self.label)
            header.append(self.value_label)
            box.append(header)

            self.progress = Gtk.ProgressBar()
            box.append(self.progress)

            self.window.set_child(box)
            self.refresh()

            GLib.timeout_add(35, self.refresh)

        def refresh(self):
            state = read_state()
            updated = float(state.get("updated", 0))
            if time.time() - updated > 0.72:
                if persistent:
                    if self.window.get_visible():
                        self.window.hide()
                    return GLib.SOURCE_CONTINUE
                self.quit()
                return GLib.SOURCE_REMOVE

            if updated == self.last_seen_update:
                return GLib.SOURCE_CONTINUE

            self.last_seen_update = updated
            kind = state.get("kind", "volume")
            value = max(0, min(100, int(state.get("value", 0))))
            muted = bool(state.get("muted", False))

            if kind == "mic":
                icon = "microphone-sensitivity-muted-symbolic" if muted else "audio-input-microphone-symbolic"
                label = "MIC MUTED" if muted else "MICROPHONE"
            elif kind == "volume":
                icon = "audio-volume-muted-symbolic" if muted else "audio-volume-high-symbolic"
                label = "MUTED" if muted else "VOLUME"
            else:
                icon = "display-brightness-symbolic"
                label = "BRIGHTNESS"

            self.icon.set_from_icon_name(icon)
            self.label.set_label(label)
            self.value_label.set_label("--" if muted else f"{value}%")
            self.progress.set_fraction(0 if muted else value / 100)
            if not self.window.get_visible():
                self.window.present()
            return GLib.SOURCE_CONTINUE

    raise SystemExit(Osd().run([]))


def main():
    if len(sys.argv) == 2 and sys.argv[1] == "--show":
        run_popup()
    if len(sys.argv) == 2 and sys.argv[1] == "--watch":
        run_popup(persistent=True)
    if len(sys.argv) != 3:
        raise SystemExit("usage: osd_control.py [volume|mic|brightness] [up|down|mute]")
    handle_control(sys.argv[1], sys.argv[2])


if __name__ == "__main__":
    main()
