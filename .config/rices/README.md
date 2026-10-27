# rices: one-command colour themes

Run `rice set <slug>` and the colours change in every managed app,
the way Omarchy theme switching works.

| Display name      | Slug              | Notes                                         |
|-------------------|-------------------|-----------------------------------------------|
| Monochrome Green  | monochrome-green  | master (the original h4ck3r look)             |
| Monochrome Orange | monochrome-orange | IBM amber CRT                                 |
| Monochrome Blue   | monochrome-blue   | neon blue on black                            |
| Azure Glow        | azure-glow        | GitHub-dark / lunaperche / azureglow style, bg 010409 |

## Usage

    rice list                      # display names, * = current
    rice current
    rice set monochrome-orange --dry-run   # show which files would change
    rice set monochrome-orange     # switch and reload what is safe
    rice set monochrome-green      # back to the master
    rice check                     # round-trip test green -> X -> green
    rice render <slug> <dir>       # write a theme's files into <dir> without switching

Picker: Super+Ctrl+Alt+T (bspwm-wl, X11 bspwm/sxhkd and niri), which runs `rice-menu`.
It logs to ~/.local/state/rice.log.

## How it works

Green is the source of truth. `managed.list` names every file whose colours are
themed. While green is active, `rice scan` collects every colour in those files
into `domain.txt`. `rice build` turns each `<slug>/theme.conf` into a one-to-one
green-to-theme colour map (`map.tsv`), plus `palette.sh` and `foot.ini`.

A switch runs current -> green -> target and rewrites only the colour tokens.
Supported token forms are #hex, rgb()/rgba(), 38;2;r;g;b, Qt argb, lua 0x,
JSON [r,g,b] and LibreOffice ints. File structure is never touched, so green
stays byte-identical and every file stays hand-editable.

Before each switch, the files it changes are copied to
`state/snapshots/<time>_<from>_to_<to>/`.

Files that also use 256-colour numbers or colour names are rendered from a green
master copy in `state/master/` (refreshed by `rice scan`). They are marked in
managed.list with these modes:
- `cterm`: vifm `ctermfg=N` and `ctermbg=N`. vifm uses these, not the `gui*` hex,
  unless TERM is a `*-direct` terminfo.
- `ansi256`: `38;5;N`.
- `nnn`: NNN_FCOLORS and NNN_COLORS.
- `doom16`: Doom's tty colour names.

Numbers 16-255 go through the theme rule and are snapped to the nearest xterm-256
colour; 0-15 follow the terminal palette. `special` files hold no colours, only
per-theme settings: htop `color_scheme` (theme.conf `htop_scheme`) and remmina
`grab_color` (`remmina_grab`, defaulting to the accent).

foot is the only include-based app: foot.ini includes `current/foot.ini`, so each
theme can have its own 16 ANSI colours. `current` is a symlink to the active theme.

Wallpaper: when you leave a theme, its wallpaper is saved to `<slug>/wallpaper.last`.
When you enter a theme, `wallpaper.last` is applied, or `wallpaper.jpg` if there
is no saved one. Nothing changes if a solid colour is set.

## What reloads live and what needs reopening

These reload live: waybar, bspwm/bspwm-wl borders, dunst, polybar, rofi/jgmenu
(theme-apply), niri, tmux, and qutebrowser, Emacs and nvim if they are running.
The bat cache is rebuilt. xdg-desktop-portal-gtk (the Open/Save file dialog) is
restarted by its exact process, and D-Bus starts it again on demand.

GTK3/GTK4 read gtk.css only at start-up, so already-open GTK apps keep the old
colours until reopened. A gsettings theme toggle does not reload the user gtk.css.

Reopen to see the new colours: foot/xterm windows, Brave, Floorp, Zed, KeePassXC,
Qt apps, btop, htop, vifm, geany, remmina, and new shells (fzf/LS_COLORS/prompt).
geany, remmina and htop rewrite their config when they exit, so close them before
`rice set`.

## Adding a theme

1. `mkdir ~/.config/rices/<new-slug>` and copy a theme.conf from a similar theme.
2. Set `name=`, then pick a method:
   - `method=hue` with `hue=<deg>` re-hues every chromatic, non-red colour.
   - `method=azure` maps to a GitHub-dark style.
3. Pin exact colours under `[map]` (green=new), list colours to leave alone in
   `keep=`, and put the terminal colours in `[ansi]`.
4. Run `rice build`, then `rice check`, then `rice render <slug> /tmp/x` to inspect
   the output.

## Adding a managed file

Add the path to managed.list (with `default,<extra modes>` if needed). Switch to
green, then run `rice scan` and `rice build`. Colours added while another theme is
active are not converted, so always edit colours while on green.

## Not themed

Zed settings.json is not touched because it holds secrets; the theme *file*
zed/themes/h4ck3r.json is themed instead. Also untouched: keepassxc.ini and Floorp
(it only follows GTK dark). htop has no custom colours: it uses the terminal's 16
colours, so the mono themes recolour it fully, while Azure shows its real ANSI
green/red. Set `htop_scheme = 1` (Monochrome) in a theme.conf to avoid that.
Remmina's SSH terminal palette is its own and is left alone; its window is GTK. Theme names such as "h4ck3r"
stay the same in every app; only their colours change.
