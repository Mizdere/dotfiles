#!/usr/bin/env python3
import os
import json
import re
import subprocess
import sys
import time

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gdk, GLib, Gtk, Gtk4LayerShell


APP_CSS = """
window {
  background: transparent;
}

.panel {
  background: rgba(10, 10, 10, 0.54);
  border: 1px solid rgba(255, 255, 255, 0.10);
  border-radius: 24px;
  box-shadow: 0 16px 44px rgba(0, 0, 0, 0.24);
  padding: 14px 18px;
  color: #f5f5f5;
}

.title {
  font-size: 9px;
  font-weight: 700;
  letter-spacing: 0.10em;
  color: rgba(255, 255, 255, 0.68);
}

.subtle {
  font-size: 10px;
  color: rgba(255, 255, 255, 0.68);
}

.section-title {
  font-size: 9px;
  font-weight: 700;
  letter-spacing: 0.10em;
  color: rgba(255, 255, 255, 0.64);
  margin-top: 6px;
}

.value {
  font-size: 11px;
  font-weight: 700;
  color: rgba(255, 255, 255, 0.84);
}

button {
  background: rgba(0, 0, 0, 0.46);
  border: 1px solid rgba(255, 255, 255, 0.14);
  border-radius: 999px;
  box-shadow: none;
  color: rgba(255, 255, 255, 0.84);
  font-size: 10px;
  font-weight: 700;
  min-height: 0;
  padding: 7px 11px;
}

button:hover {
  background: rgba(0, 0, 0, 0.62);
  border-color: rgba(255, 255, 255, 0.24);
  color: rgba(255, 255, 255, 0.94);
}

button.active {
  background: rgba(255, 255, 255, 0.84);
  border-color: rgba(255, 255, 255, 0.84);
  color: #000000;
}

scale trough {
  background: rgba(0, 0, 0, 0.52);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 999px;
  min-height: 7px;
}

scale highlight {
  background: rgba(255, 255, 255, 0.84);
  border-radius: 999px;
}

scale slider {
  background: #ffffff;
  border-radius: 999px;
  box-shadow: none;
  min-height: 15px;
  min-width: 15px;
}
"""


def run(*args):
    return subprocess.run(args, text=True, capture_output=True, check=False)


def volume_state():
    out = run("wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@").stdout.strip()
    match = re.search(r"([0-9]+(?:\.[0-9]+)?)", out)
    value = round(float(match.group(1)) * 100) if match else 0
    muted = "MUTED" in out
    return max(0, min(100, value)), muted


def pactl_json(*args):
    out = run("pactl", "-f", "json", *args).stdout.strip()
    if not out:
        return []
    try:
        return json.loads(out)
    except json.JSONDecodeError:
        return []


def default_sink_name():
    return run("pactl", "get-default-sink").stdout.strip()


def output_sinks():
    sinks = []
    for sink in pactl_json("list", "sinks"):
        name = sink.get("name", "")
        if not name:
            continue
        props = sink.get("properties", {})
        label = sink.get("description") or props.get("node.nick") or name
        active_port = sink.get("active_port")
        ports = sink.get("ports", [])
        for port in ports:
            if port.get("name") == active_port and port.get("description"):
                label = port["description"]
                break
        sinks.append({"name": name, "label": label})
    return sinks


def sink_inputs():
    return pactl_json("list", "sink-inputs")


def active_profile():
    out = run("powerprofilesctl", "get").stdout.strip()
    return out or "unknown"


def battery_state():
    base = "/sys/class/power_supply"
    for name in os.listdir(base) if os.path.isdir(base) else []:
        path = os.path.join(base, name)
        type_path = os.path.join(path, "type")
        if os.path.exists(type_path) and open(type_path).read().strip() == "Battery":
            cap_path = os.path.join(path, "capacity")
            status_path = os.path.join(path, "status")
            capacity = open(cap_path).read().strip() if os.path.exists(cap_path) else "?"
            status = open(status_path).read().strip() if os.path.exists(status_path) else "Unknown"
            return capacity, status
    return "?", "Unknown"


class Popup(Gtk.Application):
    def __init__(self, mode):
        super().__init__(application_id=f"local.waybar.{mode}.popup")
        self.mode = mode
        self.window = None
        self.started_at = time.monotonic()
        self.close_source = None
        self.scale_is_dragging = False
        self.output_buttons = {}

    def do_activate(self):
        css = Gtk.CssProvider()
        css.load_from_data(APP_CSS)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        self.window = Gtk.ApplicationWindow(application=self)
        self.window.set_decorated(False)
        self.window.set_resizable(False)
        self.window.set_default_size(250, -1)
        self.window.add_css_class("background")

        Gtk4LayerShell.init_for_window(self.window)
        Gtk4LayerShell.set_namespace(self.window, f"waybar-{self.mode}-popup")
        Gtk4LayerShell.set_layer(self.window, Gtk4LayerShell.Layer.OVERLAY)
        Gtk4LayerShell.set_keyboard_mode(self.window, Gtk4LayerShell.KeyboardMode.ON_DEMAND)
        Gtk4LayerShell.set_anchor(self.window, Gtk4LayerShell.Edge.TOP, True)
        Gtk4LayerShell.set_anchor(self.window, Gtk4LayerShell.Edge.RIGHT, True)
        Gtk4LayerShell.set_margin(self.window, Gtk4LayerShell.Edge.TOP, 28)
        Gtk4LayerShell.set_margin(self.window, Gtk4LayerShell.Edge.RIGHT, 10)

        key = Gtk.EventControllerKey.new()
        key.connect("key-pressed", self.on_key)
        self.window.add_controller(key)
        self.window.connect("notify::is-active", self.on_active_changed)

        self.window.set_child(self.volume_panel() if self.mode == "volume" else self.power_panel())
        self.window.present()

    def on_active_changed(self, window, _param):
        if window.is_active():
            if self.close_source:
                GLib.source_remove(self.close_source)
                self.close_source = None
            return

        if not self.close_source:
            self.close_source = GLib.timeout_add(180, self.quit_if_inactive)

    def quit_if_inactive(self):
        self.close_source = None
        if time.monotonic() - self.started_at < 0.35:
            return GLib.SOURCE_REMOVE
        if self.window and not self.window.is_active():
            self.quit()
        return GLib.SOURCE_REMOVE

    def on_key(self, _controller, keyval, _keycode, _state):
        if keyval == Gdk.KEY_Escape:
            self.quit()
            return True
        return False

    def volume_panel(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.add_css_class("panel")

        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        title = Gtk.Label(label="VOLUME")
        title.add_css_class("title")
        title.set_halign(Gtk.Align.START)
        title.set_hexpand(True)
        self.vol_value = Gtk.Label()
        self.vol_value.add_css_class("value")
        header.append(title)
        header.append(self.vol_value)
        box.append(header)

        self.scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 1)
        self.scale.set_draw_value(False)
        self.scale.connect("value-changed", self.on_volume_changed)
        box.append(self.scale)

        output_title = Gtk.Label(label="OUTPUT")
        output_title.add_css_class("section-title")
        output_title.set_halign(Gtk.Align.START)
        box.append(output_title)

        self.output_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        box.append(self.output_box)

        self.refresh_volume()
        self.refresh_outputs()
        GLib.timeout_add_seconds(1, self.refresh_volume)
        GLib.timeout_add_seconds(2, self.refresh_outputs)
        return box

    def refresh_volume(self):
        value, muted = volume_state()
        self.scale.handler_block_by_func(self.on_volume_changed)
        self.scale.set_value(value)
        self.scale.handler_unblock_by_func(self.on_volume_changed)
        self.vol_value.set_label("--" if muted else f"{value}%")
        return True

    def on_volume_changed(self, scale):
        value = int(scale.get_value())
        run("wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", f"{value}%")
        self.vol_value.set_label(f"{value}%")

    def refresh_outputs(self):
        sinks = output_sinks()
        current = default_sink_name()
        existing = set(self.output_buttons)
        seen = set()

        for sink in sinks:
            name = sink["name"]
            seen.add(name)
            button = self.output_buttons.get(name)
            if not button:
                button = Gtk.Button(label=sink["label"].upper())
                button.set_hexpand(True)
                button.connect("clicked", self.set_output, name)
                self.output_box.append(button)
                self.output_buttons[name] = button
            elif button.get_label() != sink["label"].upper():
                button.set_label(sink["label"].upper())

            if name == current:
                button.add_css_class("active")
            else:
                button.remove_css_class("active")

        for name in existing - seen:
            self.output_box.remove(self.output_buttons.pop(name))

        if not sinks and not self.output_buttons:
            button = Gtk.Button(label="NO OUTPUTS")
            button.set_sensitive(False)
            self.output_box.append(button)
            self.output_buttons["__none__"] = button

        return True

    def set_output(self, _button, sink_name):
        run("pactl", "set-default-sink", sink_name)
        for stream in sink_inputs():
            index = str(stream.get("index", ""))
            if index:
                run("pactl", "move-sink-input", index, sink_name)
        self.refresh_outputs()
        self.refresh_volume()

    def power_panel(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.add_css_class("panel")

        capacity, status = battery_state()
        title = Gtk.Label(label="POWER PROFILE")
        title.add_css_class("title")
        title.set_halign(Gtk.Align.START)
        box.append(title)

        info = Gtk.Label(label=f"Battery {capacity}%  /  {status}")
        info.add_css_class("subtle")
        info.set_halign(Gtk.Align.START)
        box.append(info)

        self.profile_buttons = {}
        for profile, label in (
            ("power-saver", "POWER SAVER"),
            ("balanced", "BALANCED"),
            ("performance", "PERFORMANCE"),
        ):
            button = Gtk.Button(label=label)
            button.connect("clicked", self.set_profile, profile)
            box.append(button)
            self.profile_buttons[profile] = button

        self.refresh_profile()
        GLib.timeout_add_seconds(2, self.refresh_profile)
        return box

    def refresh_profile(self):
        current = active_profile()
        for profile, button in self.profile_buttons.items():
            if profile == current:
                button.add_css_class("active")
            else:
                button.remove_css_class("active")
        return True

    def set_profile(self, _button, profile):
        run("powerprofilesctl", "set", profile)
        self.refresh_profile()


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "volume"
    if mode not in {"volume", "power"}:
        raise SystemExit("usage: dropdown_popup.py [volume|power]")
    raise SystemExit(Popup(mode).run([]))
