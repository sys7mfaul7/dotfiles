#!/usr/bin/env python3
"""wl-winhint: vim-style on-screen window hints for bspwm-wl (Super+G).
Draws a letter over every visible window on each monitor's focused desktop.
  letter        focus that window
  Shift+letter  swap the focused window with it (bspc node -s), keep focus
  Esc / click / 10 s timeout   exit, change nothing
Run through the `wl-winhint` launcher (it sets up the winhint Guix profile)."""
import json, os, signal, subprocess, sys

TIMEOUT_S = 10
signal.signal(signal.SIGALRM, lambda *a: os._exit(3))   # hard watchdog: never hang on the keyboard
signal.alarm(TIMEOUT_S + 3)

import gi
gi.require_version("Gtk", "3.0"); gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gtk, Gdk, GLib, GtkLayerShell

HINTS = "asdfghjklqwertyuiopzxcvbnm"
ACCENT, DARK = "#00ff41", "#000000"
CSS = f"""
window, fixed {{ background-color: transparent; }}
.hint {{ background-color: {ACCENT}; color: {DARK}; border-radius: 14px; padding: 6px 26px;
        font: bold 54px "DejaVu Sans Mono"; border: 3px solid {DARK}; }}
.hint.cur {{ background-color: #4f7f5a; }}
"""

def bspc(*a):
    return subprocess.run(["bspc", *a], capture_output=True, text=True, timeout=3).stdout

def collect():
    """[(monitor_rect, [(node_id, rect, is_focused)])] for each monitor's focused desktop."""
    focused = bspc("query", "-N", "-n", "focused").strip()
    out = []
    for mid in bspc("query", "-M").split():
        m = json.loads(bspc("query", "-T", "-m", mid))
        did = m.get("focusedDesktopId")
        wins = []
        for nid in bspc("query", "-N", "-d", hex(did) if isinstance(did, int) else str(did),
                        "-n", ".window.!hidden").split():
            n = json.loads(bspc("query", "-T", "-n", nid))
            wins.append((nid, n["rectangle"], nid.lower() == focused.lower()))
        out.append((m["rectangle"], wins))
    return out

class Overlay:
    def __init__(self):
        self.targets = {}   # letter -> node id
        self.wins = []
        prov = Gtk.CssProvider(); prov.load_from_data(CSS.encode())
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), prov,
                                                 Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        disp = Gdk.Display.get_default()
        gmons = [disp.get_monitor(i) for i in range(disp.get_n_monitors())]
        letters = iter(HINTS)
        first = True
        for mrect, wins in collect():
            gmon = next((g for g in gmons if g.get_geometry().x == mrect["x"]
                         and g.get_geometry().y == mrect["y"]), None)
            if gmon is None:
                continue
            w = Gtk.Window(); GtkLayerShell.init_for_window(w)
            GtkLayerShell.set_monitor(w, gmon)
            GtkLayerShell.set_layer(w, GtkLayerShell.Layer.OVERLAY)
            GtkLayerShell.set_namespace(w, "wl-winhint")
            GtkLayerShell.set_exclusive_zone(w, -1)
            for e in (GtkLayerShell.Edge.TOP, GtkLayerShell.Edge.BOTTOM,
                      GtkLayerShell.Edge.LEFT, GtkLayerShell.Edge.RIGHT):
                GtkLayerShell.set_anchor(w, e, True)
            GtkLayerShell.set_keyboard_mode(w, GtkLayerShell.KeyboardMode.EXCLUSIVE if first
                                            else GtkLayerShell.KeyboardMode.NONE)
            first = False
            vis = w.get_screen().get_rgba_visual()
            if vis: w.set_visual(vis)
            w.set_app_paintable(True)
            fx = Gtk.Fixed(); w.add(fx)
            used = {}
            for nid, r, cur in wins:
                L = next(letters, None)
                if L is None: break
                self.targets[L] = nid
                lab = Gtk.Label(label=L.upper()); lab.get_style_context().add_class("hint")
                if cur: lab.get_style_context().add_class("cur")
                cx = r["x"] - mrect["x"] + r["width"] // 2
                cy = r["y"] - mrect["y"] + r["height"] // 2
                k = (cx // 40, cy // 40); off = used.get(k, 0); used[k] = off + 1   # monocle/stacked: fan out
                fx.put(lab, max(0, cx - 50 + off * 110), max(0, cy - 45))
            w.connect("key-press-event", self.on_key)
            w.connect("button-press-event", lambda *a: self.quit())
            w.add_events(Gdk.EventMask.BUTTON_PRESS_MASK)
            w.show_all(); self.wins.append(w)
        if not self.targets:
            self.quit(); return
        GLib.timeout_add_seconds(TIMEOUT_S, self.quit)

    def on_key(self, _w, ev):
        name = Gdk.keyval_name(ev.keyval) or ""
        if name == "Escape":
            return self.quit()
        L = name.lower()
        if L in self.targets:
            nid = self.targets[L]
            shift = bool(ev.state & Gdk.ModifierType.SHIFT_MASK) or name.isupper()
            self.quit()
            if shift:
                bspc("node", "-s", nid)
            else:
                bspc("node", nid, "-g", "hidden=off"); bspc("node", "-f", nid)
        return True

    def quit(self, *a):
        for w in self.wins: w.destroy()
        self.wins = []
        Gtk.main_quit() if Gtk.main_level() else None
        return False

if __name__ == "__main__":
    o = Overlay()
    if o.wins:
        Gtk.main()
    sys.exit(0)
