alias cmatrix="cmatrix -b -u 5"
export PATH="$HOME/.local/bin:$PATH"
[ -z "$DBUS_SESSION_BUS_ADDRESS" ] && [ -r "$XDG_RUNTIME_DIR/dbus-env" ] && . "$XDG_RUNTIME_DIR/dbus-env"


[ -r ~/.config/bash/prompt.sh ] && . ~/.config/bash/prompt.sh
[ -r ~/.config/bash/nnn.sh ] && . ~/.config/bash/nnn.sh

export NNN_FCOLORS=41412f9b006c6c4141b2b241 NNN_COLORS="#41414141"  # nnn: no red, dim green
export NNN_BMS="m:/run/media/$USER;h:$HOME"  # nnn bookmarks: b then m = removable media
