# nnn config (h4ck3r green, no blue)
export NNN_OPTS="deH"
export NNN_FIFO="/tmp/nnn.fifo"
export NNN_TRASH=1
export NNN_PLUG='p:preview-tui;f:fzcd;o:fzopen;d:diffs;m:mimelist;t:nmount;x:xdgdefault;c:cdpath;z:autojump'
# context colors (256-color hex): 47 green,155 lime,65 dim,108 sage
export NNN_COLORS='#2f9b416c'
# order: blk chr dir exe reg hardlink symlink missing orphan fifo sock other
export NNN_FCOLORS='b2b22f9b006c6cc4c4b2b241'
export NNN_PREVIEWIMGPROG=chafa
export NNN_ICONLOOKUP=0
export NNN_BATTHEME=ansi
export NNN_BATSTYLE=plain
export SPLIT=v
n () {
    [ "${NNNLVL:-0}" -eq 0 ] || { echo "nnn is already running"; return; }
    export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    command nnn "$@"
    [ ! -f "$NNN_TMPFILE" ] || { . "$NNN_TMPFILE"; rm -f "$NNN_TMPFILE" > /dev/null; }
}
export VIFM_SIXEL=1
