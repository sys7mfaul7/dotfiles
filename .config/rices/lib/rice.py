#!/usr/bin/env python3
"""rice : switch the colour theme ("rice") of every app at once.
part of sys7mfaul7 dotfiles

How it works
  * monochrome-green is the master palette. Every colour found in the files
    listed in ~/.config/rices/managed.list (while green is active) is the
    "domain" (domain.txt).
  * Each theme maps every domain colour to its own colour (map.tsv), built by
    `rice build` from the theme's theme.conf (a rule plus explicit overrides).
    Maps are kept one-to-one, so any theme can be turned back into green.
  * `rice set NAME` rewrites only the colour tokens in the managed files
    (current theme -> green -> NAME), keeps everything else byte for byte, saves
    the old files in state/snapshots/, flips the `current` symlink and reloads
    what is safe to reload.
  * Apps that can include a file (foot) read ~/.config/rices/current/... instead.
  * theme.conf [ui] holds role colours that are not plain recolours of a green
    token (selection highlight, prompt parts, focused border). Green's [ui] is
    the master; a theme that leaves a key out gets green's value through its
    map. `rice build` writes them to <theme>/ui.sh (scripts source
    ~/.config/rices/current/ui.sh) and <theme>/waybar.css (imported by both
    waybar style.css files; empty unless the theme sets select_bg itself).
  * theme.conf [files] can replace a managed file wholesale for one theme
    (e.g. an upstream btop theme): PATH = file-in-the-theme-dir. Leaving that
    theme re-renders the file from the green master copy (state/master/).
  * Files that also carry 256-colour indices (vifm ctermfg=N, 38;5;N, nnn) or
    16-colour names (Doom tty fallback) are rendered from a green master copy
    (state/master/, refreshed by `rice scan`): hex colours through the map,
    indices through the theme rule + nearest xterm-256 colour.  Edit those files
    only while green is active.
"""
import colorsys, hashlib, json, os, re, shutil, signal, socket, subprocess, sys, time, glob

HOME = os.path.expanduser("~")
R = os.path.join(HOME, ".config/rices")
MASTER = "monochrome-green"
STATE = os.path.join(R, "state")
MASTERDIR = os.path.join(STATE, "master")

# ---------------------------------------------------------------- colours
def hex2rgb(h): return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
def rgb2hex(r, g, b): return "%02x%02x%02x" % (r, g, b)
def hls(h):
    r, g, b = [x / 255 for x in hex2rgb(h)]
    return colorsys.rgb_to_hls(r, g, b)
def from_hls(hh, l, s):
    r, g, b = colorsys.hls_to_rgb(hh % 1.0, max(0, min(1, l)), max(0, min(1, s)))
    return rgb2hex(*(int(round(x * 255)) for x in (r, g, b)))

def is_red(hd): return hd < 25 or hd >= 330

def rule_hue(c, conf):
    """monochrome: every chromatic, non-red colour gets the target hue."""
    if c in conf["keep"]: return c
    hh, l, s = hls(c)
    if s < 0.12 or l < 0.015 or l > 0.985: return c
    if is_red(hh * 360): return c
    return from_hls(conf["hue"] / 360, l, s * conf.get("sat", 1.0))

def rule_azure(c, conf):
    """azure: greens -> GitHub-dark blues/greys, near-black -> navy, rest kept."""
    if c in conf["keep"]: return c
    hh, l, s = hls(c); hd = hh * 360
    H = conf["hue"] / 360
    if s < 0.12 or l < 0.015:                       # neutral
        if l < 0.25: return from_hls(H, 0.07 + l * 0.9, 0.24)   # dark greys -> navy greys
        return c
    if not (65 <= hd <= 175): return c              # yellow/purple/cyan/red stay (lunaperche-ish)
    if l >= 0.75: return from_hls(H, l, min(s, 0.35))           # pale text -> light grey-blue
    if l < 0.25:  return from_hls(H, 0.06 + l * 0.9, min(s, 0.35))  # dark tints -> navy
    if s > 0.6:   return from_hls(H, max(l, 0.58), min(s, 0.92))     # bright -> link blue
    return from_hls(H, l + 0.1, min(s, 0.45))                    # muted -> slate

RULES = {"hue": rule_hue, "azure": rule_azure, "identity": lambda c, conf: c}

def _lum(h):
    c = [x / 255 for x in hex2rgb(h)]
    c = [x / 12.92 if x <= 0.03928 else ((x + 0.055) / 1.055) ** 2.4 for x in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]
def contrast(a, b):
    x, y = sorted((_lum(a), _lum(b))); return (y + 0.05) / (x + 0.05)
TEXT_CLASS = 4.0   # a master colour this readable on black is (or may be) used as text

def lift(src, v, bg, mc):
    """min_contrast: a text-class master colour whose derived colour is too dark on the
    theme background gets lighter (same hue/saturation) until it reaches mc."""
    if contrast(src, "000000") < TEXT_CLASS or contrast(v, bg) >= mc: return v
    hh, l, s = hls(v)
    while l < 0.97 and contrast(v, bg) < mc:
        l += 0.005; v = from_hls(hh, l, s)
    return v

# ---------------------------------------------------------------- config files
def read_conf(path):
    """tiny ini: key = value, [section] with 'aaaaaa = bbbbbb' map lines."""
    conf = {"keep": set(), "map": {}, "ansi": {}, "roles": {}, "ui": {}, "files": {}, "_sec": ""}
    sec = ""
    for raw in open(path, encoding="utf-8"):
        line = re.sub(r"(^|\s)#.*$", "", raw.rstrip("\n")).strip()
        if not line: continue
        if line.startswith("[") and line.endswith("]"):
            sec = line[1:-1].strip(); continue
        if "=" not in line: continue
        k, v = [x.strip() for x in line.split("=", 1)]
        if sec in ("map",): conf["map"][k.lower().lstrip("#")] = v.lower().lstrip("#")
        elif sec in ("ansi", "roles", "ui"): conf[sec][k] = v.lower().lstrip("#")
        elif sec == "files": conf["files"][os.path.expanduser(k)] = v
        elif k == "keep": conf["keep"] |= {x.lower().lstrip("#") for x in v.split()}
        elif k in ("hue", "sat"): conf[k] = float(v)
        else: conf[k] = v
    return conf

def themes():
    out = []
    for d in sorted(os.listdir(R)):
        if not os.path.islink(os.path.join(R, d)) and os.path.isfile(os.path.join(R, d, "theme.conf")): out.append(d)
    return out

_CONF = {}
def theme_conf(slug):
    if slug not in _CONF:
        c = read_conf(os.path.join(R, slug, "theme.conf"))
        if slug != MASTER:   # accent role of this theme (for single-colour settings)
            try:
                g = read_conf(os.path.join(R, MASTER, "theme.conf"))["roles"].get("accent")
                c["_accent"] = load_map(slug).get(g, "")
            except Exception: pass
        _CONF[slug] = c
    return _CONF[slug]

def current():
    p = os.path.join(R, "current")
    return os.path.basename(os.readlink(p)) if os.path.islink(p) else MASTER

def load_map(slug):
    if slug == MASTER: return {c: c for c in load_domain()}
    m = {}
    for line in open(os.path.join(R, slug, "map.tsv")):
        if line.startswith("#") or not line.strip(): continue
        a, b = line.split()[:2]; m[a] = b
    return m

def load_domain():
    p = os.path.join(R, "domain.txt")
    return [l.split()[0] for l in open(p) if l.strip() and not l.startswith("#")] if os.path.exists(p) else []

# ---------------------------------------------------------------- managed files
def managed():
    """[(path, modes)] from managed.list:  modes  path-or-glob  (~ allowed)."""
    out, seen = [], set()
    for raw in open(os.path.join(R, "managed.list"), encoding="utf-8"):
        line = re.sub(r"(^|\s)#.*$", "", raw.rstrip("\n")).strip()
        if not line: continue
        modes, pat = line.split(None, 1)
        for p in sorted(glob.glob(os.path.expanduser(pat))):
            if os.path.isfile(p) and not os.path.islink(p) and p not in seen and ".bak" not in os.path.basename(p):
                seen.add(p); out.append((p, modes.split(",")))
    return out

HEXC = "0-9a-fA-F"
PATS = {
    "hash":  re.compile(r"#([%s]{6})(?=(?:[%s]{2})?(?![%s]))" % (HEXC, HEXC, HEXC)),
    "argb":  re.compile(r"#[%s]{2}([%s]{6})(?![%s])" % (HEXC, HEXC, HEXC)),
    "lua0x": re.compile(r"0x[%s]{2}([%s]{6})(?![%s])" % (HEXC, HEXC, HEXC)),
    "bare":  re.compile(r"(?<![0-9A-Za-z#_])([%s]{6})(?![0-9A-Za-z_])" % HEXC),
    "rgbfunc": re.compile(r"rgba?\(\s*(\d{1,3})(\s*,\s*)(\d{1,3})(\s*,\s*)(\d{1,3})"),
    "ansi24":  re.compile(r"[34]8;2;(\d{1,3})(;)(\d{1,3})(;)(\d{1,3})(?![0-9])"),
    "jsonrgb": re.compile(r"\[(?:\s*)(\d{1,3})(\s*,\s*)(\d{1,3})(\s*,\s*)(\d{1,3})(?=\s*\])"),
    "loint":   re.compile(r"(?<=\bc )[A-Za-z]+ (\d+)\b"),
    "lopair":  re.compile(r"(?<![0-9A-Za-z])([0-9a-f]{6})=(\d+)\b"),
}
DEFAULT = ["hash", "rgbfunc", "ansi24"]

# ---------------------------------------------------------------- 256-colour indices
IDXPATS = {
    "cterm":   re.compile(r"(?<=cterm[fb]g=)(\d{1,3})(?![0-9])"),
    "ansi256": re.compile(r"(?<=[34]8;5;)(\d{1,3})(?![0-9])"),
    "nnn":     re.compile(r"(?:(?<=NNN_FCOLORS=)|(?<=NNN_COLORS=\"#))([0-9a-fA-F]+)"),
    "doom16":  re.compile(r"(?<=\")(bright)?(green)(?=\"\)\))"),
}
MASTERMODES = set(IDXPATS)
STD16 = ["000000", "800000", "008000", "808000", "000080", "800080", "008080", "c0c0c0",
         "808080", "ff0000", "00ff00", "ffff00", "0000ff", "ff00ff", "00ffff", "ffffff"]
def xpal(n):
    if n < 16: return STD16[n]
    if n < 232:
        n -= 16; lv = [0, 95, 135, 175, 215, 255]
        return rgb2hex(lv[n // 36], lv[n // 6 % 6], lv[n % 6])
    g = 8 + 10 * (n - 232); return rgb2hex(g, g, g)
def nearest256(h):
    r, g, b = hex2rgb(h)
    def d(n):
        R_, G_, B_ = hex2rgb(xpal(n)); rm = (r + R_) / 2
        return (2 + rm / 256) * (r - R_) ** 2 + 4 * (g - G_) ** 2 + (2 + (255 - rm) / 256) * (b - B_) ** 2
    return min(range(16, 256), key=d)
_IDX = {}
def idx_map(dst):
    """xterm-256 index -> index for theme dst (0-15 follow the terminal palette, kept)."""
    if dst in _IDX: return _IDX[dst]
    if dst == MASTER: out = {n: n for n in range(256)}
    else:
        m, conf = load_map(dst), theme_conf(dst); rule = RULES[conf.get("method", "identity")]
        out = {n: n for n in range(16)}
        for n in range(16, 256):
            c = xpal(n); v = m.get(c) or conf["map"].get(c) or rule(c, conf)
            out[n] = n if v == c else nearest256(v)
    _IDX[dst] = out; return out

def render_idx(text, modes, dst):
    """mask index tokens, return (masked_text, [replacements])."""
    conf = theme_conf(dst); im = idx_map(dst); spans = []
    for k in modes:
        if k not in IDXPATS: continue
        for mt in IDXPATS[k].finditer(text):
            v = mt.group(0)
            if k in ("cterm", "ansi256"):
                n = int(v); new = str(im[n]) if n < 256 else v
            elif k == "nnn":
                pairs = [v[i:i + 2] for i in range(0, len(v) - 1, 2)]
                new = "".join("%02x" % im[int(x, 16)] for x in pairs) + v[len(pairs) * 2:]
                if v.isupper(): new = new.upper()
            else:  # doom16: tty fallback names
                name = conf.get("name16", "green")
                new = ("bright" if mt.group(1) else "") + name
            spans.append((mt.start(), mt.end(), new))
    spans.sort(); out, pos, reps = [], 0, []
    for a, b, new in spans:
        if a < pos: continue
        out.append(text[pos:a]); out.append("\x00%d\x00" % len(reps)); reps.append(new); pos = b
    out.append(text[pos:]); return "".join(out), reps

def unmask(text, reps):
    return re.sub(r"\x00(\d+)\x00", lambda m: reps[int(m.group(1))], text)

def master_path(p): return os.path.join(MASTERDIR, os.path.relpath(p, HOME))
def uses_master(modes): return bool(MASTERMODES & set(modes))
def overridden(p):
    """managed files that some theme replaces wholesale ([files])."""
    return any(p in theme_conf(t).get("files", {}) for t in themes())
def needs_master(p, modes): return uses_master(modes) or overridden(p)

def render_file(p, modes, text, src, dst, table):
    """new text of managed file p for theme dst (text = its current content)."""
    conf = theme_conf(dst); conf["_ui"] = ui_of(dst)
    over = conf.get("files", {})
    if p in over:                      # this theme ships its own copy of the file
        return open(os.path.join(R, dst, over[p]), encoding="utf-8").read()
    mp = master_path(p)
    if (uses_master(modes) or p in theme_conf(src).get("files", {})) and os.path.exists(mp):
        base = open(mp, encoding="utf-8").read()
        masked, reps = render_idx(base, modes, dst)
        new = recolour(masked, modes, transition(MASTER, dst))[0]
        return special(unmask(new, reps), p, conf)
    return special(recolour(text, modes, table)[0], p, conf)

def tokens(text, modes):
    """yield (start, end, colour, kind, match) for every colour token."""
    spans = []
    ms = []
    for m in modes:
        if m == "default": ms += DEFAULT
        elif m in PATS: ms.append(m)
    for kind in ms:
        for mt in PATS[kind].finditer(text):
            if kind in ("hash", "argb", "lua0x", "bare"):
                tok = mt.group(1)
                if kind == "bare" and not re.search(r"\d", tok): continue
                spans.append((mt.start(1), mt.end(1), tok.lower(), kind, mt))
            elif kind in ("rgbfunc", "ansi24", "jsonrgb"):
                r, g, b = int(mt.group(1)), int(mt.group(3)), int(mt.group(5))
                if max(r, g, b) > 255: continue
                spans.append((mt.start(1), mt.end(5), rgb2hex(r, g, b), kind, mt))
            elif kind == "loint":
                v = int(mt.group(1))
                if v > 0xffffff: continue
                spans.append((mt.start(1), mt.end(1), "%06x" % v, kind, mt))
            elif kind == "lopair":
                spans.append((mt.start(1), mt.end(2), mt.group(1), kind, mt))
    spans.sort(key=lambda s: (s[0], -s[1]))
    out, last = [], -1
    for s in spans:
        if s[0] >= last: out.append(s); last = s[1]
    return out

def fmt(new, kind, mt, text, s, e):
    if kind in ("hash", "argb", "lua0x", "bare"):
        old = text[s:e]
        return new.upper() if any(ch.isupper() for ch in old) else new
    if kind in ("rgbfunc", "ansi24", "jsonrgb"):
        r, g, b = hex2rgb(new)
        return "%d%s%d%s%d" % (r, mt.group(2), g, mt.group(4), b)
    if kind == "loint": return str(int(new, 16))
    if kind == "lopair":      # comment "rrggbb=int": fix the int only if it was right
        old_hex, old_int = mt.group(1), int(mt.group(2))
        return "%s=%d" % (new, int(new, 16) if old_int == int(old_hex, 16) else old_int)

def recolour(text, modes, table):
    """replace every colour token found in table; return (text, n, unknown set)."""
    out, pos, n, unknown = [], 0, 0, set()
    for s, e, c, kind, mt in tokens(text, modes):
        if c in table:
            new = table[c]
            rep = fmt(new, kind, mt, text, s, e)
            if rep != text[s:e]: n += 1
            out.append(text[pos:s]); out.append(rep); pos = e
        else:
            unknown.add(c)
    out.append(text[pos:])
    return "".join(out), n, unknown

# per-theme words (not colours)
def special(text, path, conf):
    if path.endswith("/.bashrc"):
        col = conf.get("cmatrix", "")
        def f(m):
            args = re.sub(r"\s+-C\s+\w+", "", m.group(1))
            return 'alias cmatrix="cmatrix%s%s"' % (args, (" -C " + col) if col else "")
        text = re.sub(r'alias cmatrix="cmatrix([^"]*)"', f, text)
    if path.endswith("/htop/htoprc"):
        text = re.sub(r"(?m)^color_scheme=\d+", "color_scheme=%s" % conf.get("htop_scheme", "0"), text)
    if path.endswith("/remmina/remmina.pref"):
        g = conf.get("remmina_grab") or conf.get("_accent", "")
        if g: text = re.sub(r"(?m)^grab_color=#[0-9a-fA-F]{6}", "grab_color=#" + g.lstrip("#"), text)
    bf = conf.get("_ui", {}).get("border_focused")
    if bf:
        if path.endswith("/bspwm-wl/bspwmrc"):
            text = re.sub(r"(?m)^(bspc config focused_border_color\s+')#[0-9a-fA-F]{6}", lambda m: m.group(1) + "#" + bf, text)
        if path.endswith("/.config/bspwm/theme"):
            text = re.sub(r'(?m)^(BORDER_FOCUSED=")#[0-9a-fA-F]{6}', lambda m: m.group(1) + "#" + bf, text)
    if path.endswith("brave-h4ck3r-theme/manifest.json") and conf.get("brave_tint"):
        text = re.sub(r'("buttons"\s*:\s*\[\s*)[0-9.]+', lambda m: m.group(1) + conf["brave_tint"], text)
    return text

# ---------------------------------------------------------------- scan / build
def scan(write=True):
    if current() != MASTER:
        sys.exit("rice scan: only while %s is active (it reads the master colours)" % MASTER)
    seen = {}
    for p, modes in managed():
        text = open(p, encoding="utf-8").read()
        if write and needs_master(p, modes):
            q = master_path(p); os.makedirs(os.path.dirname(q), exist_ok=True)
            open(q, "w", encoding="utf-8").write(text)
        for s, e, c, kind, mt in tokens(text, [m for m in modes if m != "bare"]):
            seen.setdefault(c, set()).add(p.replace(HOME, "~"))
    # keep previously known colours too (files may have dropped them)
    for c in load_domain(): seen.setdefault(c, set())
    if write:
        with open(os.path.join(R, "domain.txt"), "w") as f:
            f.write("# every colour in the managed files while %s is active (rice scan)\n" % MASTER)
            for c in sorted(seen): f.write("%s  %d\n" % (c, len(seen[c])))
    return sorted(seen)

def nudge(v, used):
    r, g, b = hex2rgb(v); k = 0
    while rgb2hex(r, g, b) in used:
        k += 1; d = (k + 1) // 2 * (1 if k % 2 else -1)
        r, g, b = [max(0, min(255, x + d)) for x in hex2rgb(v)]
    return rgb2hex(r, g, b)

def build_map(slug, domain):
    conf = theme_conf(slug)
    rule = RULES[conf.get("method", "identity")]
    m, used = {}, set()
    for c in conf["map"]:                      # explicit first, they win
        if c in domain:
            m[c] = conf["map"][c]
    if len(set(m.values())) != len(m):
        sys.exit("rice build: %s: two [map] entries give the same colour" % slug)
    used |= set(m.values())
    mc, bg = float(conf.get("min_contrast") or 0), m.get("000000", "000000")
    for c in domain:
        if c in m: continue
        v = rule(c, conf)
        if mc: v = lift(c, v, bg, mc)
        if v in used: v = nudge(v, used)
        if mc:                                 # a nudge may step back under the floor
            v = lift(c, v, bg, mc)
            for _ in range(50):
                if v not in used: break
                v = lift(c, v, bg, contrast(v, bg) + 0.01)
            if v in used: v = nudge(v, used)
        m[c] = v; used.add(v)
    return m, conf

def roles_of(slug, m):
    g = theme_conf(MASTER)
    return {k: m.get(v, v) for k, v in g["roles"].items()}

def ansi_of(slug, m, conf):
    g = theme_conf(MASTER)["ansi"]
    if conf["ansi"]: return {k: conf["ansi"].get(k, m.get(g[k], g[k])) for k in g}
    return {k: m.get(v, v) for k, v in g.items()}

def ui_of(slug, m=None):
    """[ui] colours of slug: its own value, else green's value through slug's map ('' = unset)."""
    g = theme_conf(MASTER)["ui"]; own = theme_conf(slug)["ui"]
    if m is None:
        try: m = load_map(slug)
        except Exception: m = {}
    out = {k: (m.get(v, v) if v else "") for k, v in g.items()}
    out.update(own)
    return out

WAYBAR_WS = ", ".join(["window#waybar #custom-ws%d.focused%s" % (i, h) for h in ("", ":hover") for i in range(1, 11)] +
                      ["window#waybar #workspaces button.%s%s" % (c, h) for h in ("", ":hover") for c in ("active", "focused")])
WAYBAR_TASK = "window#waybar #taskbar button.active, window#waybar #taskbar button.active:hover"
WAYBAR_FOCUS = WAYBAR_WS + ", " + WAYBAR_TASK

def sgr(h): return "38;2;%d;%d;%d" % hex2rgb(h) if h else ""

def write_ui(slug, m, conf):
    d = os.path.join(R, slug); ui = ui_of(slug, m)
    with open(os.path.join(d, "ui.sh"), "w") as f:
        f.write("# generated by `rice build` from theme.conf [ui] - do not edit\n")
        f.write("# RICE_PS_*: SGR colour for the bash prompt parts ('' = terminal default)\n")
        for k in sorted(ui):
            v = ui[k]
            if k.startswith("prompt_"): f.write("RICE_PS_%s='%s'\n" % (k[7:].upper(), sgr(v)))
            else: f.write("RICE_%s='%s'\n" % (k.upper(), ("#" + v) if v else ""))
    with open(os.path.join(d, "waybar.css"), "w") as f:
        f.write("/* generated by `rice build` from theme.conf [ui] - do not edit\n"
                "   imported by ~/.config/{bspwm-wl,niri}/waybar/style.css via ~/.config/rices/current/ */\n")
        own = conf["ui"]
        if slug != MASTER and own.get("select_bg"):
            f.write("/* selected / focused items: select_bg / select_fg (window#waybar wins over style.css) */\n")
            sel = (ui["select_bg"], ui.get("select_fg") or ui.get("fg", "000000"))
            if own.get("ws_fg"):   # ws_fg set: focused workspace = plain text in ws_fg, no highlight
                f.write("%s { background: transparent; color: #%s; }\n" % (WAYBAR_WS, own["ws_fg"]))
                f.write("%s { background: #%s; color: #%s; }\n" % ((WAYBAR_TASK,) + sel))
            else:
                f.write("%s { background: #%s; color: #%s; }\n" % ((WAYBAR_FOCUS,) + sel))
            f.write("window#waybar #workspaces button.active label, window#waybar #workspaces button.focused label { color: inherit; }\n")

FOOT_KEYS = ["background", "foreground", "selection-background", "selection-foreground"] + \
    ["regular%d" % i for i in range(8)] + ["bright%d" % i for i in range(8)]

def write_fragments(slug, m, conf):
    d = os.path.join(R, slug)
    roles = roles_of(slug, m); ansi = ansi_of(slug, m, conf)
    with open(os.path.join(d, "palette.sh"), "w") as f:
        f.write("# generated by `rice build` from theme.conf - do not edit\n")
        f.write("RICE_SLUG=%s\nRICE_NAME='%s'\n" % (slug, conf.get("name", slug)))
        for k, v in roles.items(): f.write("C_%s='#%s'\n" % (k.upper(), v))
        for k in FOOT_KEYS[4:]: f.write("C_%s='#%s'\n" % (k.upper(), ansi[k]))
    alpha = conf.get("foot_alpha", theme_conf(MASTER).get("foot_alpha", "0.9"))
    with open(os.path.join(d, "foot.ini"), "w") as f:
        f.write("# foot colours for %s (generated by `rice build`; foot.ini includes\n# ~/.config/rices/current/foot.ini). New foot windows pick it up.\n" % conf.get("name", slug))
        f.write("[colors-dark]\nalpha=%s\n" % alpha)
        for k in FOOT_KEYS: f.write("%s=%s\n" % (k, ansi[k]))

def build(quiet=False):
    domain = load_domain()
    if not domain: sys.exit("rice build: domain.txt is empty; run `rice scan` while green is active")
    for slug in themes():
        conf = theme_conf(slug)
        if slug == MASTER:
            m = {c: c for c in domain}
        else:
            m, conf = build_map(slug, domain)
            with open(os.path.join(R, slug, "map.tsv"), "w") as f:
                f.write("# %s -> %s colour map (generated by `rice build`)\n" % (MASTER, slug))
                for c in domain: f.write("%s %s\n" % (c, m[c]))
        if len(set(m.values())) != len(m): sys.exit("rice build: %s map is not one-to-one" % slug)
        write_fragments(slug, m, conf); write_ui(slug, m, conf)
        if not quiet: print("built %-20s %3d colours" % (slug, len(m)))

# ---------------------------------------------------------------- switching
def transition(src, dst):
    a, b = load_map(src), load_map(dst)
    inv = {v: k for k, v in a.items()}
    return {cur: b[g] for cur, g in inv.items() if g in b}

def render_all(src, dst, outroot=None, dry=False):
    table = transition(src, dst)
    changes = []
    for p, modes in managed():
        text = open(p, encoding="utf-8").read()
        new = render_file(p, modes, text, src, dst, table)
        n = sum(1 for a, b in zip(text.splitlines(), new.splitlines()) if a != b)
        if new != text: changes.append((p, text, new, n))
    if outroot:
        for p, text, new, n in changes:
            q = os.path.join(outroot, os.path.relpath(p, HOME))
            os.makedirs(os.path.dirname(q), exist_ok=True)
            open(q, "w", encoding="utf-8").write(new)
    return changes

def atomic_write(p, data):
    t = p + ".rice-tmp"
    with open(t, "w", encoding="utf-8") as f: f.write(data)
    shutil.copymode(p, t); os.replace(t, p)

def run(cmd, **kw):
    try: return subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=10, **kw)
    except Exception as e: return None

def pgrep(name):
    r = run(["pgrep", "-x", name]); return bool(r and r.returncode == 0)

def reload_live(dst, log):
    xdg = os.environ.get("XDG_RUNTIME_DIR", "/run/user/%d" % os.getuid())
    # X11 bspwm: regenerate rofi/dunst/polybar/jgmenu colours from ~/.config/bspwm/theme
    ta = os.path.join(HOME, ".config/bspwm/scripts/theme-apply")
    if os.access(ta, os.X_OK): run([ta]); log("X11 generated/ files rewritten (theme-apply)")
    # window borders: same `bspc config *_color` lines the rc files use
    for rc, bspc, proc in ((".config/bspwm-wl/bspwmrc", os.path.join(HOME, ".local/opt/bspwm-wl/bin/bspc"), "bspwm-wl"),
                           (".config/bspwm/theme", "bspc", "bspwm")):
        if not pgrep(proc): continue
        if proc == "bspwm-wl":
            txt = open(os.path.join(HOME, rc)).read()
            pairs = re.findall(r"^bspc config (\w+_color)\s+'(#[0-9a-fA-F]{6})'", txt, re.M)
        else:
            th = dict(re.findall(r'^(\w+)="(#[0-9a-fA-F]{6})"', open(os.path.join(HOME, rc)).read(), re.M))
            pairs = [("normal_border_color", th.get("BORDER_NORMAL")), ("active_border_color", th.get("BORDER_NORMAL")),
                     ("focused_border_color", th.get("BORDER_FOCUSED")), ("presel_feedback_color", th.get("C_SEL"))]
        env = dict(os.environ)
        if proc == "bspwm-wl": env.pop("DISPLAY", None)   # with Xwayland's DISPLAY set, bspc looks for X11 bspwm
        for k, v in pairs:
            if v: run([bspc, "config", k, v], env=env)
        log("%s border colours set" % proc)
    # tray: re-tint pixmap-only tray icons (Slack ...) for the new theme before waybar reloads
    rt = os.path.expanduser("~/.local/bin/rice-tray")
    if os.access(rt, os.X_OK):
        run([rt, "recolor", "--theme", dst, "--quiet"])
    if pgrep(".waybar-real") or pgrep("waybar"):
        run(["pkill", "-USR2", "-x", ".waybar-real"]); run(["pkill", "-USR2", "-x", "waybar"]); log("waybar reloaded (SIGUSR2)")
    if pgrep("polybar"): run(["polybar-msg", "cmd", "restart"]); log("polybar restarted")
    if pgrep("dunst"): run(["dunstctl", "reload"]); log("dunst reloaded")
    if os.environ.get("DISPLAY") and run(["xrdb", "-query"]) and run(["xrdb", "-query"]).stdout.strip():
        run(["xrdb", "-merge", os.path.join(HOME, ".Xresources")]); log("Xresources merged (new xterms)")
    r = run(["tmux", "list-sessions"])
    if r and r.returncode == 0:
        run(["tmux", "source-file", os.path.join(HOME, ".config/tmux/tmux.conf")]); log("tmux config re-sourced")
    for sock in glob.glob(os.path.join(xdg, "qutebrowser", "ipc-*")):
        try:
            s = socket.socket(socket.AF_UNIX); s.settimeout(2); s.connect(sock)
            s.sendall((json.dumps({"args": [":config-source"], "target_arg": None,
                                   "protocol_version": 1, "cwd": HOME}) + "\n").encode()); s.close()
            log("qutebrowser :config-source")
        except Exception: pass
    if glob.glob(os.path.join(xdg, "emacs", "server")) or glob.glob("/tmp/emacs%d/server" % os.getuid()):
        r = run(["emacsclient", "-a", "false", "-e", "(load-theme doom-theme t)"])
        if r and r.returncode == 0: log("emacs theme reloaded")
    for sock in glob.glob(os.path.join(xdg, "nvim.*")):
        r = run(["nvim", "--server", sock, "--remote-expr", 'execute("colorscheme " . g:colors_name)'])
        if r and r.returncode == 0: log("nvim %s: colorscheme reloaded" % os.path.basename(sock))
    # GTK apps read ~/.config/gtk-*/gtk.css once at start-up; the file-chooser portal is a
    # long-running GTK app, so restart it (exact process, D-Bus re-activates it on demand)
    n = restart_portal_gtk()
    if n: log("xdg-desktop-portal-gtk restarted (file dialogs use the new GTK colours)")
    if pgrep("vifm"):   # running vifm instances re-read the colour scheme over its own IPC
        r = run(["vifm", "--remote", "-c", "colorscheme h4ck3r"])
        if r and r.returncode == 0: log("vifm colorscheme reloaded")
    if os.path.isdir(os.path.join(HOME, ".config/bat/themes")):
        r = run(["bat", "cache", "--build"])
        if r and r.returncode == 0: log("bat theme cache rebuilt")
    if not pgrep("soffice.bin"):
        lo = os.path.join(HOME, ".local/bin/lo-h4ck3r-black")
        if os.access(lo, os.X_OK) and os.path.exists(os.path.join(HOME, ".config/libreoffice/4/user/registrymodifications.xcu")):
            run([lo]); log("LibreOffice colours written (lo-h4ck3r-black)")
    else:
        log("LibreOffice is open: close it, then run lo-h4ck3r-black")

def own_pids_by_exe(names):
    out = []
    for d in os.listdir("/proc"):
        if not d.isdigit(): continue
        try:
            if os.stat("/proc/" + d).st_uid != os.getuid(): continue
            exe = os.path.basename(os.readlink("/proc/%s/exe" % d))
            if exe in names: out.append(int(d))
        except OSError: pass
    return out

def restart_portal_gtk():
    pids = own_pids_by_exe({"xdg-desktop-portal-gtk", ".xdg-desktop-portal-gtk-real"})
    for pid in pids:
        try: os.kill(pid, signal.SIGTERM)
        except OSError: pass
    if pids:
        for _ in range(20):
            if not own_pids_by_exe({"xdg-desktop-portal-gtk", ".xdg-desktop-portal-gtk-real"}): break
            time.sleep(0.1)
        run(["gdbus", "call", "--session", "--dest", "org.freedesktop.impl.portal.desktop.gtk",
             "--object-path", "/org/freedesktop/portal/desktop", "--method", "org.freedesktop.DBus.Peer.Ping"])
    return len(pids)

def wallpaper(src, dst, log):
    save = os.path.join(HOME, ".config/bspwm-wl/wallpaper")
    cur = open(save).read().strip() if os.path.exists(save) else ""
    solid = os.path.join(HOME, ".config/bspwm-wl/solid")
    if cur and not cur.startswith(solid):
        open(os.path.join(R, src, "wallpaper.last"), "w").write(cur + "\n")
    else:
        return
    w = ""
    p = os.path.join(R, dst, "wallpaper.last")
    if os.path.exists(p): w = open(p).read().strip()
    if not os.path.isfile(w):
        cand = sorted(glob.glob(os.path.join(R, dst, "wallpaper.*")))
        cand = [c for c in cand if not c.endswith(".last")]
        w = cand[0] if cand else ""
    if os.path.isfile(w) and w != cur:
        ww = os.path.join(HOME, ".config/bspwm-wl/bin/wl-wallpaper")
        if os.environ.get("WAYLAND_DISPLAY") or os.environ.get("DISPLAY"):
            run([ww, "set", w]); log("wallpaper -> %s" % w.replace(HOME, "~"))
        else:
            open(save, "w").write(w + "\n"); log("wallpaper saved for next login")

def cmd_set(dst, dry=False, reload=True, force=False):
    if dst not in themes(): sys.exit("rice: no theme '%s' (rice list)" % dst)
    src = current()
    if src == dst and not force: print("rice: %s is already active" % dst); return
    if src == MASTER:                      # pick up colours added since the last build
        scan(); build(quiet=True)
    written = load_written()
    if src != MASTER:
        for p, modes in managed():
            if needs_master(p, modes) and p in written and sha(open(p, encoding="utf-8").read()) != written[p]:
                print("rice: warning: %s was edited while %s was active; it is rebuilt from the green master"
                      " (your version is kept in the snapshot). Make colour edits while green is active."
                      % (p.replace(HOME, "~"), src))
    changes = render_all(src, dst)
    print("%s -> %s: %d files change" % (src, dst, len(changes)))
    if dry:
        for p, t, n2, n in changes: print("  %4d  %s" % (n, p.replace(HOME, "~")))
        return
    ts = time.strftime("%Y%m%d-%H%M%S")
    snap = os.path.join(STATE, "snapshots", "%s_%s_to_%s" % (ts, src, dst))
    for p, text, new, n in changes:
        q = os.path.join(snap, os.path.relpath(p, HOME)); os.makedirs(os.path.dirname(q), exist_ok=True)
        shutil.copy2(p, q)
    # brave caches the compiled theme next to the manifest; move it so brave rebuilds it
    pak = os.path.join(HOME, ".local/share/brave-h4ck3r-theme/Cached Theme.pak")
    if os.path.exists(pak):
        q = os.path.join(snap, "brave-Cached Theme.pak"); os.makedirs(snap, exist_ok=True); shutil.move(pak, q)
    for p, text, new, n in changes: atomic_write(p, new)
    for p, modes in managed():
        if needs_master(p, modes): written[p] = sha(open(p, encoding="utf-8").read())
    save_written(written)
    link = os.path.join(R, "current"); tmp = link + ".new"
    if os.path.lexists(tmp): os.remove(tmp)
    os.symlink(dst, tmp); os.replace(tmp, link)
    print("backups: %s" % snap.replace(HOME, "~"))
    log = lambda s: print("  " + s)
    if reload:
        reload_live(dst, log); wallpaper(src, dst, log)
        run(["notify-send", "-a", "rice", "Theme", theme_conf(dst).get("name", dst)])
    print("done. Reopen to see it: foot/xterm windows, GTK/Qt apps, Zed, Brave, KeePassXC, btop, htop, vifm, geany, remmina.")

def sha(t): return hashlib.sha1(t.encode("utf-8")).hexdigest()
def load_written():
    p = os.path.join(STATE, "written.json")
    return json.load(open(p)) if os.path.exists(p) else {}
def save_written(w):
    json.dump(w, open(os.path.join(STATE, "written.json"), "w"), indent=0)

def cmd_list():
    cur = current()
    for t in themes():
        print("%s %-20s %s" % ("*" if t == cur else " ", t, theme_conf(t).get("name", t)))

def cmd_check():
    """round trip every theme on copies: green -> X -> green must be byte-identical."""
    if current() != MASTER: sys.exit("rice check: run while %s is active" % MASTER)
    scan(); build(quiet=True)
    files = managed(); ok = True
    for t in themes():
        if t == MASTER: continue
        tab1, tab2 = transition(MASTER, t), transition(t, MASTER)
        c1 = theme_conf(t); c0 = theme_conf(MASTER); bad = []
        for p, modes in files:
            a = open(p, encoding="utf-8").read()
            b = render_file(p, modes, a, MASTER, t, tab1)
            c = render_file(p, modes, b, t, MASTER, tab2)
            if c != a: bad.append(p)
        print("%-20s round trip %s" % (t, "OK" if not bad else "FAILED: " + ", ".join(bad)))
        ok &= not bad
    sys.exit(0 if ok else 1)

def main(a):
    if not a or a[0] in ("-h", "--help", "help"):
        print(__doc__.split("How it works")[0].strip())
        print("usage: rice list | current | set NAME [--dry-run] [--no-reload] | menu |\n"
              "       render NAME DIR (write NAME's files into DIR, no changes) | check | scan | build")
        return
    c = a[0]
    if c == "list": cmd_list()
    elif c == "current": print(current())
    elif c == "set" and len(a) > 1: cmd_set(a[1], dry="--dry-run" in a, reload="--no-reload" not in a, force="--force" in a)
    elif c == "render" and len(a) > 2:
        ch = render_all(current(), a[1], outroot=a[2]); print("%d files written under %s" % (len(ch), a[2]))
    elif c == "scan": print("%d colours" % len(scan()))
    elif c == "build": build()
    elif c == "check": cmd_check()
    elif c == "names":
        for t in themes(): print("%s\t%s" % (theme_conf(t).get("name", t), t))
    else: main(["help"]); sys.exit(2)

if __name__ == "__main__": main(sys.argv[1:])
