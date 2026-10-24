#!/bin/sh
# install.sh: put these dotfiles into $HOME.
#   ./install.sh            symlink every file into $HOME (default)
#   ./install.sh --copy     copy files instead of symlinking
#   ./install.sh --dry-run  show what would happen, change nothing
#   ./install.sh [--copy] path ...   only install the given repo paths (e.g. .config/bspwm-wl)
# Anything already in the way is MOVED to ~/.dotfiles-backup-<timestamp>/ first.
# Nothing is ever deleted.
# Files containing the placeholder /home/USER (for programs that cannot expand
# ~ or $HOME) are always installed as a COPY with /home/USER replaced by $HOME.
set -eu
REPO=$(cd "$(dirname "$0")" && pwd)
MODE=link; DRY=0
PH=/home/USER
while [ $# -gt 0 ]; do
  case $1 in
    --copy) MODE=copy; shift;;
    --link) MODE=link; shift;;
    --dry-run|-n) DRY=1; shift;;
    -h|--help) sed -n '2,11p' "$0"; exit 0;;
    --) shift; break;;
    -*) echo "unknown option: $1" >&2; exit 2;;
    *) break;;
  esac
done
BK="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
cd "$REPO"
list() {
  if [ -d .git ] && command -v git >/dev/null; then git ls-files -- "$@"
  else find "${@:-.}" -type f -o -type l | sed 's|^\./||'; fi |
  grep -v -x -e README.md -e install.sh -e .gitignore
}
run() { if [ "$DRY" = 1 ]; then echo "[dry-run] $*"; else "$@"; fi; }
# escape $HOME for use as a sed replacement
HOME_SED=$(printf '%s\n' "$HOME" | sed 's/[|&\\]/\\&/g')
list "$@" | while IFS= read -r f; do
  src="$REPO/$f"; dst="$HOME/$f"
  sub=0
  if [ -f "$src" ] && [ ! -L "$src" ] && grep -qI -F "$PH" "$src" 2>/dev/null; then
    sub=1
    sed "s|$PH|$HOME_SED|g" "$src" > "$TMP"
  fi
  if [ "$sub" = 0 ] && [ "$MODE" = link ] && [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then continue; fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ "$sub" = 1 ]; then
      [ -f "$dst" ] && [ ! -L "$dst" ] && cmp -s "$TMP" "$dst" && continue
    elif [ "$MODE" = copy ] && [ -f "$dst" ] && [ ! -L "$dst" ] && cmp -s "$src" "$dst"; then continue; fi
    run mkdir -p "$BK/$(dirname "$f")"
    run mv "$dst" "$BK/$f"
    echo "backed up: ~/$f"
  fi
  run mkdir -p "$(dirname "$dst")"
  if [ "$sub" = 1 ]; then
    if [ "$DRY" = 1 ]; then echo "[dry-run] copy $src -> $dst (with $PH -> $HOME)"
    else cp -p "$src" "$dst" && cat "$TMP" > "$dst"; fi
  elif [ "$MODE" = link ]; then run ln -s "$src" "$dst"
  else run cp -p "$src" "$dst"; fi
done
[ -d "$BK" ] && echo "Backups are in $BK" || true
fc-list : family 2>/dev/null | grep -q "Symbols Nerd Font" ||
  echo "Note: the X11 bar needs Symbols Nerd Font (NerdFontsSymbolsOnly.zip, see README)."
echo "Done ($MODE mode). Log out and back in (or reload bspwm-wl) to pick up changes."
