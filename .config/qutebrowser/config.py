# h4ck3r-themed qutebrowser config for r2d2 (4K @ Xft.dpi 144)
# -*- mode: python; coding: utf-8 -*-
config.load_autoconfig(False)

# ── Palette ──────────────────────────────────────────────────────────
bg       = "#000000"
bg_alt   = "#0d1218"
bg_sel   = "#1f6f2f"
fg       = "#c0ffc0"
fg_bright= "#e0ffe0"
accent   = "#00ff41"
dim      = "#4f7f5a"
warn     = "#ffcc66"
error    = "#ff5555"
border   = "#1a3a22"

# ── Fonts (4K 32" @ DPI 144) ─────────────────────────────────────────
font_ui  = "12pt DejaVu Sans Mono"
font_web = "12pt DejaVu Sans Mono"
font_sm  = "11pt DejaVu Sans Mono"

c.fonts.default_family = ["DejaVu Sans Mono", "Symbols Nerd Font Mono", "monospace"]
c.fonts.default_size = "12pt"
c.fonts.completion.entry = font_ui
c.fonts.completion.category = "bold " + font_ui
c.fonts.statusbar = font_ui
c.fonts.tabs.selected = font_ui
c.fonts.tabs.unselected = font_ui
c.fonts.hints = "bold 13pt DejaVu Sans Mono"
c.fonts.keyhint = font_ui
c.fonts.prompts = font_ui
c.fonts.downloads = font_sm
c.fonts.messages.info = font_ui
c.fonts.messages.error = font_ui
c.fonts.messages.warning = font_ui
c.fonts.contextmenu = font_ui
c.fonts.web.family.standard = "DejaVu Sans Mono"
c.fonts.web.family.fixed = "DejaVu Sans Mono"
c.fonts.web.family.serif = "DejaVu Sans Mono"
c.fonts.web.family.sans_serif = "DejaVu Sans Mono"
c.fonts.web.size.default = 16
c.fonts.web.size.default_fixed = 14

# ── Zoom for 4K / DPI 144 ────────────────────────────────────────────
c.zoom.default = "125%"

# ── Completion ───────────────────────────────────────────────────────
c.colors.completion.fg = fg
c.colors.completion.odd.bg = bg
c.colors.completion.even.bg = bg_alt
c.colors.completion.category.fg = accent
c.colors.completion.category.bg = bg
c.colors.completion.category.border.top = border
c.colors.completion.category.border.bottom = border
c.colors.completion.item.selected.fg = fg_bright
c.colors.completion.item.selected.bg = bg_sel
c.colors.completion.item.selected.border.top = accent
c.colors.completion.item.selected.border.bottom = accent
c.colors.completion.item.selected.match.fg = accent
c.colors.completion.match.fg = accent
c.colors.completion.scrollbar.fg = dim
c.colors.completion.scrollbar.bg = bg

# ── Context menu ─────────────────────────────────────────────────────
c.colors.contextmenu.menu.bg = bg
c.colors.contextmenu.menu.fg = fg
c.colors.contextmenu.selected.bg = bg_sel
c.colors.contextmenu.selected.fg = fg_bright
c.colors.contextmenu.disabled.bg = bg
c.colors.contextmenu.disabled.fg = dim

# ── Downloads ────────────────────────────────────────────────────────
c.colors.downloads.bar.bg = bg
c.colors.downloads.start.fg = bg
c.colors.downloads.start.bg = dim
c.colors.downloads.stop.fg = bg
c.colors.downloads.stop.bg = accent
c.colors.downloads.error.fg = error
c.colors.downloads.system.fg = "none"
c.colors.downloads.system.bg = "none"

# ── Hints ────────────────────────────────────────────────────────────
c.colors.hints.fg = fg_bright
c.colors.hints.bg = bg_sel
c.colors.hints.match.fg = accent
c.hints.border = "1px solid " + accent
c.hints.chars = "asdfghjkl"
c.hints.uppercase = True

# ── Keyhint ──────────────────────────────────────────────────────────
c.colors.keyhint.fg = fg
c.colors.keyhint.suffix.fg = accent
c.colors.keyhint.bg = bg

# ── Messages ─────────────────────────────────────────────────────────
c.colors.messages.error.fg = error
c.colors.messages.error.bg = bg
c.colors.messages.error.border = error
c.colors.messages.warning.fg = warn
c.colors.messages.warning.bg = bg
c.colors.messages.warning.border = warn
c.colors.messages.info.fg = fg
c.colors.messages.info.bg = bg
c.colors.messages.info.border = border

# ── Prompts ──────────────────────────────────────────────────────────
c.colors.prompts.fg = fg
c.colors.prompts.bg = bg
c.colors.prompts.border = "1px solid " + border
c.colors.prompts.selected.fg = fg_bright
c.colors.prompts.selected.bg = bg_sel

# ── Statusbar ────────────────────────────────────────────────────────
c.colors.statusbar.normal.fg = fg
c.colors.statusbar.normal.bg = bg
c.colors.statusbar.insert.fg = bg
c.colors.statusbar.insert.bg = accent
c.colors.statusbar.passthrough.fg = bg
c.colors.statusbar.passthrough.bg = dim
c.colors.statusbar.private.fg = fg
c.colors.statusbar.private.bg = "#1a1020"
c.colors.statusbar.command.fg = fg
c.colors.statusbar.command.bg = bg_alt
c.colors.statusbar.command.private.fg = fg
c.colors.statusbar.command.private.bg = "#1a1020"
c.colors.statusbar.caret.fg = bg
c.colors.statusbar.caret.bg = warn
c.colors.statusbar.caret.selection.fg = bg
c.colors.statusbar.caret.selection.bg = warn
c.colors.statusbar.progress.bg = accent
c.colors.statusbar.url.fg = fg
c.colors.statusbar.url.hover.fg = accent
c.colors.statusbar.url.success.http.fg = dim
c.colors.statusbar.url.success.https.fg = accent
c.colors.statusbar.url.warn.fg = warn
c.colors.statusbar.url.error.fg = error

# ── Tabs ─────────────────────────────────────────────────────────────
c.colors.tabs.bar.bg = bg
c.colors.tabs.odd.fg = dim
c.colors.tabs.odd.bg = bg
c.colors.tabs.even.fg = dim
c.colors.tabs.even.bg = bg_alt
c.colors.tabs.selected.odd.fg = fg_bright
c.colors.tabs.selected.odd.bg = bg_sel
c.colors.tabs.selected.even.fg = fg_bright
c.colors.tabs.selected.even.bg = bg_sel
c.colors.tabs.pinned.odd.fg = accent
c.colors.tabs.pinned.odd.bg = bg
c.colors.tabs.pinned.even.fg = accent
c.colors.tabs.pinned.even.bg = bg_alt
c.colors.tabs.pinned.selected.odd.fg = fg_bright
c.colors.tabs.pinned.selected.odd.bg = bg_sel
c.colors.tabs.pinned.selected.even.fg = fg_bright
c.colors.tabs.pinned.selected.even.bg = bg_sel
c.colors.tabs.indicator.start = dim
c.colors.tabs.indicator.stop = accent
c.colors.tabs.indicator.error = error
c.colors.tabs.indicator.system = "none"
c.tabs.favicons.show = "always"
c.tabs.position = "top"
c.tabs.show = "multiple"
c.tabs.title.format = "{audio}{index}: {current_title}"
c.tabs.padding = {"top": 4, "bottom": 4, "left": 8, "right": 8}
c.tabs.indicator.width = 3

# ── Webpage ──────────────────────────────────────────────────────────
c.colors.webpage.bg = bg
c.colors.webpage.preferred_color_scheme = "dark"
c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.policy.images = "never"
c.colors.webpage.darkmode.policy.page = "smart"
try:
    c.colors.webpage.darkmode.algorithm = "lightness-cielab"
except Exception:
    pass

# ── Adblock ──────────────────────────────────────────────────────────
c.content.blocking.enabled = True
c.content.blocking.method = "both"
c.content.blocking.adblock.lists = [
    "https://easylist.to/easylist/easylist.txt",
    "https://easylist.to/easylist/easyprivacy.txt",
    "https://secure.fanboy.co.nz/fanboy-annoyance.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/badware.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/privacy.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/quick-fixes.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/unbreak.txt",
]

# ── Privacy / content ────────────────────────────────────────────────
c.content.autoplay = False
c.content.cookies.accept = "no-3rdparty"
c.content.geolocation = False
c.content.notifications.enabled = False
c.content.media.audio_capture = "ask"
c.content.media.video_capture = "ask"
c.content.desktop_capture = False
c.content.pdfjs = True
c.content.javascript.clipboard = "access-paste"

# Spellcheck (dicts from aspell/hunspell if installed)
c.spellcheck.languages = ["en-US"]

# ── Downloads / sessions ─────────────────────────────────────────────
c.downloads.location.directory = "~/Downloads"
c.downloads.location.prompt = False
c.downloads.remove_finished = 10000
c.session.lazy_restore = True
c.auto_save.session = True

# ── Statusbar ────────────────────────────────────────────────────────
c.statusbar.show = "always"
c.statusbar.widgets = ["keypress", "url", "scroll", "history", "tabs", "progress"]

# ── Search engines ───────────────────────────────────────────────────
c.url.searchengines = {
    "DEFAULT": "https://duckduckgo.com/?q={}",
    "g":  "https://www.google.com/search?q={}",
    "gh": "https://github.com/search?q={}",
    "yt": "https://www.youtube.com/results?search_query={}",
    "aw": "https://wiki.archlinux.org/index.php?search={}",
    "gx": "https://packages.guix.gnu.org/search/?query={}",
    "hf": "https://huggingface.co/models?search={}",
}
c.url.start_pages = ["https://duckduckgo.com"]
c.url.default_page = "https://duckduckgo.com"

# ── Keybindings ──────────────────────────────────────────────────────
# Toggle UI
config.bind("xs", "config-cycle statusbar.show always never")
config.bind("xb", "config-cycle tabs.show multiple never")

# Move tabs
config.bind("<Ctrl-Shift-J>", "tab-move +")
config.bind("<Ctrl-Shift-K>", "tab-move -")

# Userscripts
config.bind(",m", "spawn --userscript view_in_mpv")
config.bind(",r", "spawn --userscript readability")

# Password fill — only useful when pass or keepassxc is installed.
# Tools not present on r2d2 yet; binding kept for when they are.
# config.bind(",p", "spawn --userscript qute-pass")

# Handy extras
config.bind(",M", "hint links spawn mpv {hint-url}")
config.bind("tt", "set-cmd-text -s :open -t ")
config.bind("tT", "set-cmd-text -s :open -t -r ")

# ── Misc ─────────────────────────────────────────────────────────────
c.scrolling.smooth = False
c.input.insert_mode.auto_load = True
c.editor.command = ["emacsclient", "-c", "-a", "emacs", "{}"]
c.confirm_quit = ["downloads"]

# new launches (Super+Ctrl+B, menus, xdg-open) open a NEW window on the current workspace
c.new_instance_open_target = "window"
c.new_instance_open_target_window = "last-opened"
