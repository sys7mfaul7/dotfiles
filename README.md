# sys7mfaul7 dotfiles

Personal settings for my Guix System desktop (a Minisforum AI X1 Pro, AMD iGPU), running:

- **bspwm-wl**: a custom Wayland port of bspwm (wlroots). Main session.
- **X11 bspwm**: our own sxhkd + polybar session in `.config/bspwm` (see [X11 bspwm](#x11-bspwm)).
- **Niri**: a scrollable-tiling Wayland session that mirrors the bspwm-wl keys where it can.

Everything uses one green-on-black theme. No blue anywhere.

| Role | Colour |
|---|---|
| Background | `#000000` |
| Text | `#c0ffc0` |
| Accent | `#00ff41` |
| Selection | `#1f6f2f` |
| Dim | `#4f7f5a` |
| Charcoal panels | `#0a0e14` |

Fonts: the X11 session uses **DejaVu Sans Mono** (regular; Bold only for emphasis) with **Symbols Nerd Font** for icons, see [Fonts](#fonts). The Wayland sessions use JetBrains Mono Nerd Font for text and Symbols Nerd Font Mono for the waybar icons. Menus are one-line dmenu style on pure black.

> The bspwm-wl compositor source lives in a separate private repo. This repo only holds its config (`.config/bspwm-wl`).

## Layout

The repo mirrors `$HOME`, so every path here is the path it installs to.

```
.bashrc .bash_profile .profile .zshrc .zprofile .inputrc   shell
.Xresources .Xdefaults .xsession .gtkrc-2.0 .fehbg .dmrc    X11 / session
.gitconfig .guile guix-home-config.scm MiSTer.ini
.config/
  bspwm-wl/      bspwmrc, rules, flags, bin/ (wl-* helpers), waybar/, wallselect.lua, solid/
  bspwm/         X11 session: bspwmrc, theme, sxhkdrc, polybar/, rofi/, scripts/
  niri/          config.kdl, waybar/, bin/
  fontconfig/    conf.d
  xdg-desktop-portal(-wlr)/   screen-sharing portal config
  foot/ nvim/ doom/ zed/ qutebrowser/ vifm/ nnn/plugins/ mpv/ dunst/ waybar/ river/ ...
.local/bin/      launchers and helpers (bsp-pip, bsp-pin, bspwm-sel, chromium-wl, floorp, slack, ...)
.local/share/    applications/*.desktop, wayland-sessions, wallpapers (two), icons/hicolor, emoji
guix-config/       config.scm (system), my-packages/ (local Guix channel: fonts, niri-session...), NOTES.md
```

## Install

```sh
git clone https://github.com/sys7mfaul7/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh --dry-run      # see what would change
./install.sh                # symlink everything into $HOME
# or: ./install.sh --copy   # copy instead of symlink
# or: ./install.sh .config/bspwm-wl .local/bin   # just some parts
```

Anything already in the way is moved to `~/.dotfiles-backup-<timestamp>/`. Nothing is deleted.

### Machine-specific values

Nothing in this repo names a host, user or home directory. Shell scripts and configs that run through a shell use `$HOME` or `~`. A few programs cannot expand either, so those files use the placeholder **`/home/USER`** instead. `install.sh` always installs them as a **copy** with `/home/USER` replaced by your `$HOME`, even in symlink mode. Re-run `./install.sh` after editing one of them in the repo. Files with the placeholder:

- `.config/bspwm-wl/wallpaper`, `.config/bspwm-wl/wallpaper.last`
- `.config/btop/btop.conf`, `.config/geany/geany.conf`, `.config/gtk-3.0/bookmarks`
- `.config/qt5ct/qt5ct.conf`, `.config/qt6ct/qt6ct.conf`, `.config/.qmk-real/.qmk-real.ini`
- `.config/transmission-daemon/settings.json`, `.config/xdg-desktop-portal-wlr/config`
- `.local/share/applications/*.desktop` (launchers with `Exec=`/`Icon=` under `~/.local`), `.local/share/wayland-sessions/bspwm-wl.desktop`

List them any time with `git grep -l /home/USER`.

Other values to set for your own machine:

- `guix-config/config.scm`: host name (`myhost`), login name (`user`) and `home-directory` (`/home/user`), plus the LUKS and EFI partition UUIDs.
- `.config/brscan4/brsanenetdevice4.cfg`: the scanner's address is the placeholder `192.0.2.10`. Put your scanner's LAN IP there (or run `brsaneconfig4 -a ...`).

Guix System:

```sh
guix pull        # uses .config/guix/channels.scm (nonguix)
sudo guix system reconfigure -L ~/guix-config/my-packages ~/guix-config/config.scm
```

Before reconfiguring a new machine, edit `guix-config/config.scm` for its host name (`myhost`), user name (`user`, plus `home-directory`), file systems and bootloader UUIDs. Set your login password with `passwd` after the first boot.

Not included, supply them yourself:

- **Wallpapers.** Only the two current ones are in `.local/share/wallpapers/`. Drop your own images there; every session's wallpaper picker reads that folder.
- **Fonts** in `~/.local/share/fonts`: Symbols Nerd Font for X11 (see [Fonts](#fonts)). DejaVu Sans Mono comes from Guix, JetBrains Mono Nerd Font (Wayland) from `guix-config/my-packages`.
- **Secrets.** Any value set to `REPLACE_ME` needs your own key, for example in `.config/zed/settings.json` and `.config/transmission-daemon/settings.json`.
- **Doom Emacs core.** Clone Doom into `~/.config/emacs`, then run `doom sync`. `.config/doom` holds the personal config.

## bspwm-wl keybindings

This section is generated from the `K` / `KE` lines in `.config/bspwm-wl/bspwmrc`. In the tables, `(repeat)` means the key repeats while held. `$WB` is `~/.config/bspwm-wl/bin` and `$X11B` is `~/.local/bin`.


### apps / launchers

| Keys | Action |
|---|---|
| `super + t` | `foot` |
| `super + slash` | `colorpick` |
| `super + shift + t` | `foot --app-id=foot-float` |
| `super + ctrl + t` | `foot` |
| `super + ctrl + shift + t` | `foot --app-id=foot-float` |
| `super + space` | `$HOME/.local/bin/bspwm-wl-apps` |
| `super + ctrl + space` | `$HOME/.local/bin/bspwm-wl-menu` |
| `super + d` | `fm-term vifm tiled user` |
| `super + shift + d` | `fm-term vifm float user` |
| `super + ctrl + d` | `fm-term vifm tiled sudo` |
| `super + ctrl + shift + d` | `fm-term vifm float sudo` |
| `super + alt + d` | `fm-term nnn tiled user` |
| `super + alt + shift + d` | `fm-term nnn float user` |
| `super + alt + ctrl + d` | `fm-term nnn tiled sudo` |
| `super + alt + ctrl + shift + d` | `fm-term nnn float sudo` |
| `super + c` | `$WB/wl-calc` |
| `super + b` | `chromium-wl` |
| `super + shift + b` | `bspc rule -a chromium-browser -o state=floating center=on rectangle=1204x1152+0+0 && chromium-wl` |
| `super + ctrl + b` | `qutebrowser` |
| `super + ctrl + shift + b` | `bspc rule -a qutebrowser -o state=floating center=on rectangle=1204x1152+0+0 && qutebrowser` |
| `super + ctrl + e` | `emacs` |
| `super + ctrl + shift + e` | `bspc rule -a emacs -o state=floating center=on && bspc rule -a Emacs -o state=floating center=on && emacs` |
| `super + y` | `foot -e nnn` |
| `super + m` | `$WB/wl-minimize` |
| `super + n` | `foot -e nvim` |
| `super + shift + n` | `foot --app-id=foot-float -e nvim` |
| `super + e` | `zed` |
| `super + shift + e` | `bspc rule -a dev.zed.Zed -o state=floating center=on rectangle=1600x900+0+0; zed` |
| `super + v` | `$WB/wl-clip` |
| `super + alt + c` | `$WB/wl-clip` |
| `super + alt + v` | `pavucontrol` |
| `super + alt + n` | `$WB/wl-bartui network` |
| `super + alt + b` | `bt-menu` |
| `super + alt + p` | `$WB/wl-powermenu` |
| `super + alt + s` | `$WB/wl-shot area` |
| `super + alt + o` | `$WB/wl-scratchterm` |
| `super + alt + h` | `pkill -USR1 -x .waybar-real` |
| `super + alt + u` | `pkill -USR1 -x .waybar-real` |
| `ctrl + alt + w` | `$WB/wl-barreset` |

### session

| Keys | Action |
|---|---|
| `ctrl + super + alt + p` | `loginctl poweroff` |
| `ctrl + super + alt + Delete` | `loginctl reboot` |
| `ctrl + super + alt + q` | `bspc quit` |
| `super + alt + q` | `bspc quit` |
| `ctrl + alt + l` | `swaylock -f -c 000000 --indicator-idle-visible --inside-color 000000 --ring-color 1f6f2f --key-hl-color 00ff41 --text-color c0ffc0` |
| `ctrl + super + alt + k` | `bspc node -k` |
| `ctrl + super + alt + s` | `$HOME/.config/bspwm-wl/bspwmrc` |
| `super + alt + r` | `$HOME/.config/bspwm-wl/bspwmrc` - reload config |
| `ctrl + alt + b` | `$HOME/.config/bspwm-wl/bspwmrc && dunstify -u low bspwm-wl 'keys reloaded'` |

### media keys

| Keys | Action |
|---|---|
| `XF86MonBrightnessUp` | `$HOME/.local/bin/sys-brightness up` |
| `XF86MonBrightnessDown` | `$HOME/.local/bin/sys-brightness down` |
| `XF86AudioRaiseVolume` | `$HOME/.local/bin/sys-volume up` |
| `XF86AudioLowerVolume` | `$HOME/.local/bin/sys-volume down` |
| `XF86AudioMute` | `$HOME/.local/bin/sys-volume mute` |
| `XF86AudioNext` | `$HOME/.local/bin/sys-media next` |
| `XF86AudioPrev` | `$HOME/.local/bin/sys-media prev` |
| `XF86AudioPlay` | `$HOME/.local/bin/sys-media toggle` |
| `XF86AudioStop` | `$HOME/.local/bin/sys-media stop` |

### close / state / flags

| Keys | Action |
|---|---|
| `super + shift + w` | `$X11B/bspwm-sel kill` |
| `super + w` | `$X11B/bspwm-sel close` |
| `super + q` | `bspc rule -a qalculate-gtk -o state=floating center=on && bspc rule -a Qalculate-gtk -o state=floating center=on && qalculate-gtk` |
| `ctrl + alt + q` | `bspc quit` |
| `super + shift + alt + w` | `bspc query -N -d -n .window \| xargs -r -I id -n 1 bspc node id -c` |
| `super + f` | `$X11B/bspwm-sel float` |
| `super + shift + f` | `bspc node -t ~fullscreen` |
| `ctrl + alt + h` | `$WB/wl-hidenode --menu` |
| `super + p` | `$X11B/bspwm-sel pin` |
| `super + shift + p` | `bsp-pip` |
| `super + shift + alt + p` | `bsp-pip --big` |

### layout

| Keys | Action |
|---|---|
| `super + u` | `bspc node @parent -R 90` |
| `super + ctrl + alt + b` | `bspc node @/ -B` |
| `super + ctrl + equal` | `$WB/wl-center` |
| `super + shift + equal` | `$WB/wl-center fit` |
| `super + plus` | `$WB/wl-center fit` |
| `super + a` | `bspc node -f @parent` |
| `super + shift + a` | `bspc node -f @first.leaf \|\| bspc node -f last.local.leaf` |

### desktops

| Keys | Action |
|---|---|
| `super + bracketleft` | `bspc desktop -f prev` |
| `super + bracketright` | `bspc desktop -f next` |
| `super + r` | `bspc node @/ --rotate 90` |
| `super + shift + r` | `bspc node @/ --rotate -90` |
| `super + apostrophe` | `bspc desktop -f last` |
| `super + shift + apostrophe` | `bspc desktop -f last` |
| `ctrl + super + alt + l` | `$WB/wl-blank` |
| `super + Prior` | `bspc desktop -f next.local` |
| `super + Next` | `bspc desktop -f prev.local` |
| `super + shift + Prior` | `$X11B/bspwm-sel shift next` |
| `super + shift + Next` | `$X11B/bspwm-sel shift prev` |
| `super + alt + shift + Prior` | `$X11B/bspwm-sel shiftfollow next` |
| `super + alt + shift + Next` | `$X11B/bspwm-sel shiftfollow prev` |

_In the loop below, `$i` is 1-9 or 0, and `$n` is desktop 1-10._

| Keys | Action |
|---|---|
| `super + $i` | `bspc desktop -f ^$n` |
| `super + ctrl + $i` | `bspc node -d ^$n` |
| `super + shift + $i` | `$X11B/bspwm-sel send $i` |
| `super + alt + shift + $i` | `$X11B/bspwm-sel sendfollow $i` |

### focus / cycle

| Keys | Action |
|---|---|
| `alt + Tab` | `bspc node -f prev.local.!hidden.window` |
| `alt + shift + Tab` | `bspc node -f next.local.!hidden.window` |
| `super + Tab` | `$WB/wl-winswitch` |
| `super + shift + Tab` | `$WB/wl-winswitch` |
| `super + ctrl + Tab` | `bspc node -f next.local.!hidden.window` |
| `super + ctrl + shift + Tab` | `bspc node -f prev.local.!hidden.window` |

_In the loops below, `$k` is h/j/k/l or the arrow keys, and `$dir` is west/south/north/east._

| Keys | Action |
|---|---|
| `super + $k` | `bspc node -f $dir.!sticky.!hidden.local` |
| `super + shift + $k` (repeat) | `$WB/wl-smartmove $dir` |
| `ctrl + alt + $k` | `bspc node -s $dir.local` |
| `super + alt + $k` | `$WB/wl-altdir $dir` - floating: edge, tiled: presel |
| `super + alt + shift + Left` (repeat) | `bspc node focused.floating -v -80 0` |
| `super + alt + shift + Right` (repeat) | `bspc node focused.floating -v 80 0` |
| `super + alt + shift + Up` (repeat) | `bspc node focused.floating -v 0 -80` |
| `super + alt + shift + Down` (repeat) | `bspc node focused.floating -v 0 80` |

### preselection

| Keys | Action |
|---|---|
| `super + ctrl + v` | `bspc node -p south` |
| `super + ctrl + q` | `bspc node -p cancel` |
| `super + alt + Escape` | `bspc node -p cancel; $WB/wl-smartmove cancel` |
| `super + Return` | `$X11B/bspwm-sel toggle` |
| `super + shift + Escape` | `$X11B/bspwm-sel clear` |

### resize

| Keys | Action |
|---|---|
| `super + ctrl + Up` (repeat) | `$X11B/bspwm-cresize shrink v` |
| `super + ctrl + Down` (repeat) | `$X11B/bspwm-cresize grow v` |
| `super + ctrl + Left` (repeat) | `$X11B/bspwm-cresize shrink h` |
| `super + ctrl + Right` (repeat) | `$X11B/bspwm-cresize grow h` |
| `super + KP_Add` (repeat) | `$X11B/bspwm-resize grow` |
| `super + minus` (repeat) | `$X11B/bspwm-resize shrink` |
| `super + KP_Subtract` (repeat) | `$X11B/bspwm-resize shrink` |
| `super + alt + plus` (repeat) | `bspc node -z top_right 20 -20; bspc node -z bottom_left -20 20` |
| `super + alt + minus` (repeat) | `bspc node -z top_right -20 20; bspc node -z bottom_left 20 -20` |
| `super + ctrl + plus` (repeat) | `bspc node -z top_left -50 -25; bspc node -z bottom_right 50 25` |
| `super + ctrl + minus` (repeat) | `bspc node -z top_left 50 25; bspc node -z bottom_right -50 -25` |

### scratchpad

| Keys | Action |
|---|---|
| `super + s` | `$WB/wl-scratch toggle` |
| `super + shift + s` | `$WB/wl-scratch add` |
| `super + ctrl + s` | `$WB/wl-scratch remove` |

### desktop rename / equal columns

| Keys | Action |
|---|---|
| `super + ctrl + r` | `$WB/wl-rename` - type a name; "-" or "reset" = default number; Esc cancels |
| `super + equal` | `$WB/wl-eqkey` - floating: centre, tiled: equal-width columns |
| `super + KP_Equal` | `$WB/wl-eqkey` - keypad = : same as Super+= |
| `super + shift + KP_Equal` | `$WB/wl-center fit` |
| `super + ctrl + alt + equal` | `$WB/wl-eqcols -r` - equal columns + equal rows in each column |

### window stacking / minimize / floats / opacity / emoji

| Keys | Action |
|---|---|
| `super + shift + bracketleft` | `$WB/wl-stack raise` |
| `super + shift + bracketright` | `$WB/wl-stack lower` |
| `super + i` | `$WB/wl-hidefloats` |
| `super + o` | `$WB/wl-opacity` |
| `super + shift + grave` | `$WB/wl-emoji` |
| `super + alt + w` | `$WB/wl-wallselect` |
| `super + ctrl + w` | `$WB/wl-wallpaper toggle` - wallpaper on/off (plain black) |

### screenshots

| Keys | Action |
|---|---|
| `Print` | `$WB/wl-shot area` |
| `shift + Print` | `$WB/wl-shot full` |
| `super + Print` | `$WB/wl-shot area` |
| `super + shift + Print` | `$WB/wl-shot window` |

Mouse: Super + left-drag moves a window, and Super + right-drag resizes it. Focus follows the mouse, and a click raises the window. The mouse is set up left-handed.

X11 bspwm uses mostly the same keys, listed under [X11 keybindings](#x11-keybindings). Niri's equivalents are in `.config/niri/config.kdl`.

## X11 bspwm

The X11 session is our own: `bspwm` + `sxhkd` + `polybar` + `rofi` + `dunst`, all written for this repo. Everything lives in `.config/bspwm`:

```
.config/bspwm/
  bspwmrc        session start: input, monitors, DPI, theme, bar, autostart
  theme          THE one file for fonts, colours, borders, gaps, bar height, cursor, terminal
  sxhkdrc        key bindings (a "# text" line above each binding is its help text)
  polybar/       config.ini (colours and fonts come from generated/polybar.ini)
  rofi/          dmenu.rasi (one-line menu), windows.rasi (window switcher)
  scripts/       dpi, theme-apply, bar, launcher, power-menu, screenshot, wallselect, ...
  picom.conf     compositor (only shadows/opacity rules; picom is optional)
  menu.csv       right-click desktop menu (jgmenu)
  generated/     written at every start by scripts/theme-apply; not in git
```

Shared helpers in `.local/bin`: `sys-volume`, `sys-brightness`, `sys-media` (media keys, also used by bspwm-wl and niri), `polybar-ws`, `polybar-wintitle`, `display-auto`, `rofi-calc`, `rofi-emoji`, `bsp-*`, `bspwm-*`.

Start it from the display manager's **bspwm** entry, or with `startx`/`.xsession` (no argument = bspwm).

### Fonts

Requirements:

- **DejaVu Sans Mono**: the text font everywhere in the X11 session (Guix: `font-dejavu`).
- **Symbols Nerd Font** (families `Symbols Nerd Font` and `Symbols Nerd Font Mono`): icons in the bar, menus and notifications (polybar and all three waybars). Get `NerdFontsSymbolsOnly.zip` from the [ryanoasis/nerd-fonts releases](https://github.com/ryanoasis/nerd-fonts/releases), unzip it into `~/.local/share/fonts/NerdFontsSymbolsOnly/` and run `fc-cache -f`. Font files are not in this repo.

Text uses the regular weight (DejaVu calls it *Book*); **Bold** is used only for emphasis.

**Changing the font.** The font is defined once, in `.config/bspwm/theme`:

```sh
FONT_FAMILY="DejaVu Sans Mono"   # any name from: fc-list : family
FONT_STYLE="Book"                # normal weight (Regular/Book)
FONT_EMPH_STYLE="Bold"           # emphasis only
FONT_SIZE="11"                   # points
ICON_FONT="Symbols Nerd Font Mono"
```

Edit it and press `ctrl + super + alt + s` (reload) or log in again. `scripts/theme-apply` regenerates the polybar, rofi, dunst, xsettingsd (GTK/Qt) and jgmenu settings from it.

### DPI and sizes

All sizes are in **points**, so they follow the screen DPI. At login `scripts/dpi`:

1. reads the physical size of the primary (or first connected) output from `xrandr`,
2. computes DPI = pixels x 25.4 / mm (screens under 18" are treated as laptops and scaled by 0.6, since they are viewed closer),
3. rounds to a multiple of 24 (96, 120, 144, ...) and keeps it between 96 and 288 (96 if the size is unknown),
4. applies it with `xrdb -merge` (`Xft.dpi`, antialias, hintslight, no subpixel) and exports `XFT_DPI`.

To force a value, put a number in `~/.config/bspwm/dpi` (for example `echo 120 > ~/.config/bspwm/dpi`) or export `BSPWM_DPI=120` before starting the session. `dpi` with no argument prints the value it would use.

Reference look at 96 DPI: 11 pt text, bar 16.5 pt = 22 px (the waybars in bspwm-wl, niri and river are 22 px too). At 144 DPI the bar is 33 px. Polybar's `dpi` and rofi's `dpi` are set to the session DPI, the cursor is 24 px x DPI/96, and GTK/Qt get it through xsettingsd and `QT_FONT_DPI`.

Bar text and icons are centred with per-font vertical offsets in `theme` (`BAR_YOFF_TEXT`, `BAR_YOFF_ICON`, `BAR_YOFF_ICON_BIG`, pixels at 96 DPI, + = down). `theme-apply` scales them with the DPI (3/2/3 at 96 DPI become 5/3/5 at 144). If you change the font, rerun `theme-apply` and nudge these until digits and icons line up.

Apps that do **not** follow the session DPI (fixed sizes, change them by hand):

| App | Where the size is set |
|---|---|
| xterm | `faceSize` in `.Xresources` |
| zathura | `font` in `.config/zathura/zathurarc` |
| GTK 2 apps | `gtk-font-name` in `.gtkrc-2.0` |
| bspwm-wl and niri bars | `font-size` in `.config/bspwm-wl/waybar/style.css`, `.config/niri/waybar/style.css` |
| Wayland notifications | `font` in `.config/dunst/dunstrc` (X11 uses the generated one) |
| river | `xrdb` line in `.config/river/init`, wmenu font in `.config/river/menu-opts`, `.config/waybar/style.css` |

### Not carried over from the old setup

The style chooser, eww widgets, weather and update-count modules, animated wallpapers and the rice selector are gone. Network uses an `nmtui` popup, bluetooth a `bluetui` popup. The icon theme is **Papirus-Dark** (Guix `papirus-icon-theme`) and the cursor **Adwaita** (`adwaita-icon-theme`), set in `theme` (`ICON_THEME`, `CURSOR_THEME`), GTK 2/3/4 settings, qt5ct/qt6ct, `.Xresources`, `.icons/default` and the niri/river configs; GTK is Adwaita-dark with our green `gtk.css`. `scripts/lock` uses `i3lock` if installed and falls back to `slock`. `kbd-layout`, `pass-menu` and `android-mount` need `setxkbmap`, `pass` and `simple-mtpfs`.

### X11 keybindings

From `.config/bspwm/sxhkdrc` (press `super + F1` for the same list in a menu). `{a,b}` means one binding per choice, in order; `{shift + }` means "with or without shift".

### launching

| Keys | Action |
|---|---|
| `super + {shift + }t` | terminal (shift: floating) |
| `super + ctrl + {shift + }t` | plain xterm (shift: floating) |
| `super + alt + t` | pick which terminal to open |
| `super + space` | app launcher (one-line menu at the top) |
| `super + ctrl + space` | run a command |
| `super + {shift + }b` | chromium (shift: floating) |
| `super + ctrl + {shift + }b` | qutebrowser (shift: floating) |
| `super + e` | zed (shift: floating 1600x900) |
| `super + shift + e` | ″ |
| `super + ctrl + {shift + }e` | emacs (shift: floating) |
| `super + {shift + }n` | neovim in xterm (shift: floating) |
| `super + y` | nnn in a floating terminal |
| `super + {shift + ,ctrl + ,ctrl + shift + }d` | vifm (shift: floating, ctrl: as root) |
| `super + alt + {shift + ,ctrl + ,ctrl + shift + }d` | nnn (shift: floating, ctrl: as root) |
| `super + q` | qalculate (floating) |
| `super + alt + v` | volume mixer |
| `super + alt + o` | drop-down scratch terminal |

### menus and tools

| Keys | Action |
|---|---|
| `super + F1` | show this list |
| `super + c` | calculator (bc) |
| `super + shift + grave` | emoji picker |
| `super + {v,alt + c}` | clipboard history |
| `super + slash` | colour picker |
| `super + alt + w` | wallpaper picker |
| `super + ctrl + w` | wallpaper on / plain black |
| `super + alt + s` | screenshot menu |
| `{shift + }Print` | screenshot: area / whole screen (saved and copied) |
| `super + Print` | flameshot |
| `super + alt + n` | network (nmtui) |
| `super + alt + b` | bluetooth |
| `super + alt + a` | mount an Android phone |
| `super + alt + k` | keyboard layout |
| `super + alt + x` | password store |
| `super + alt + p` | power menu |
| `~button3` | desktop right-click menu |

### session

| Keys | Action |
|---|---|
| `ctrl + super + alt + {p,Delete,q,k,s}` | poweroff / reboot / log out / xkill / reload the session |
| `ctrl + alt + q` | log out |
| `super + Escape` | reload key bindings |
| `super + alt + {h,u}` | hide / show the bar |
| `ctrl + alt + l` | lock the screen |
| `ctrl + super + alt + l` | screen off now, no lock (any input wakes it) |
| `ctrl + alt + {plus,minus,t}` | opacity of the focused window: less / more / reset |
| `super + o` | toggle opacity of the focused window |
| `XF86MonBrightness{Up,Down}` | brightness |
| `XF86Audio{RaiseVolume,LowerVolume,Mute}` | volume |
| `XF86Audio{Next,Prev,Play,Stop}` | media player |

### windows

| Keys | Action |
|---|---|
| `super + {shift + }x` | close / kill |
| `super + {shift + }w` | close / kill (respects a marked selection) |
| `super + shift + alt + w` | close every window on this desktop |
| `super + n ; {x,k}` | then x: close, k: kill all other windows here |
| `super + n ; m` | then m: pull all marked windows here |
| `super + n ; {1-9}` | then 1-9: pull every window from that desktop here |
| `super + f` | floating toggle |
| `super + shift + f` | fullscreen toggle |
| `super + p` | pin on all desktops |
| `super + shift + {alt + }p` | picture-in-picture (alt: bigger) |
| `super + m` | minimize to the hidden M desktop |
| `ctrl + alt + h` | bring back a minimized / hidden window |
| `super + i` | hide / show all floating windows here |
| `super + {shift + ,ctrl + }s` | scratchpad: toggle / add focused / remove focused |
| `super + {Left,Down,Up,Right}` | focus in a direction |
| `super + shift + {Left,Down,Up,Right,h,j,k,l}` | move (tiled: swap, floating: nudge) |
| `ctrl + alt + {Left,Down,Up,Right}` | swap with the neighbour |
| `alt + {shift + }Tab` | previous / next window |
| `super + Tab` | window switcher with previews (hold Super, tap Tab; shift: backwards) |
| `super + shift + Tab` | ″ |
| `super + shift + {bracketleft,bracketright}` | raise / lower in the stack |
| `super + {equal,KP_Equal}` | floating: centre the window; tiled: equal-width columns (keypad = too) |
| `super + shift + KP_Equal` | centre floating window at 50% x 80% |
| `super + {ctrl + equal,shift + equal,plus}` | centre floating window (shift / plus: 50% x 80%) |
| `super + alt + shift + {Left,Down,Up,Right}` | move floating window fast (80 px, repeats while held) |
| `super + {KP_Add,minus,KP_Subtract}` | grow / shrink |
| `super + ctrl + {Up,Down,Left,Right}` | grow / shrink around the centre |
| `super + alt + {plus,minus}` | tiled window bigger / smaller |
| `super + ctrl + {plus,minus}` | floating window bigger / smaller |
| `super + a` | select parent (repeat to climb) / back down to a window |
| `super + shift + a` | ″ |
| `super + g` | window groups: toggle / join neighbour / next / previous |
| `super + ctrl + shift + {Left,Down,Up,Right}` | ″ |
| `super + ctrl + {shift + }Tab` | ″ |

### layout and preselection

| Keys | Action |
|---|---|
| `super + alt + {Left,Down,Up,Right}` | floating: snap to that edge (below the bar); tiled: preselect (press again to cancel) |
| `super + ctrl + {v,q}` | preselect below / cancel |
| `super + alt + Escape` | cancel preselection (also a pending smart-move) |
| `super + {Return,shift + Escape}` | move into the preselected spot / clear the selection |
| `super + u` | rotate the split of this window |
| `super + {shift + }r` | rotate the whole desktop |
| `super + ctrl + alt + b` | balance |
| `super + ctrl + alt + equal` | equal columns and equal rows in each column |

### desktops

| Keys | Action |
|---|---|
| `super + {ctrl + }{1-9,0}` | go to desktop 1-10 / send window there |
| `super + {alt + }shift + {1-9,0}` | send window to desktop 1-10 (alt: and follow) |
| `super + {bracketleft,bracketright}` | previous / next desktop |
| `super + {Next,Prior}` | previous / next desktop on this monitor |
| `super + {alt + }shift + {Next,Prior}` | send window left / right (alt: and follow) |
| `super + {shift + }apostrophe` | last desktop |
| `super + ctrl + r` | rename this desktop |

## License

These are personal configs, shared as-is. Third-party pieces keep their own licenses.
