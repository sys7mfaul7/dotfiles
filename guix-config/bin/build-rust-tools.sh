#!/usr/bin/env bash
# Build clipcat and xcolor from source into ~/.local/bin (Guix).
set -uo pipefail
mkdir -p "$HOME/.local/bin" "$HOME/.local/src"
guix shell -D gtk+ rust rust:cargo gcc-toolchain pkg-config gtk+ xz zlib libtiff gtk-layer-shell glib cairo pango \
  gdk-pixbuf libdbusmenu libx11 libxcb libxcursor libxrandr libxkbcommon dbus protobuf \
  openssl git coreutils bash -- bash -c '
  export CARGO_HOME=$HOME/.cargo
  S=$HOME/.local/src; B=$HOME/.local/bin; rc=0
  if ! [ -x $B/clipcatd ]; then
    rm -rf $S/clipcat && git clone -q --depth 1 --branch v0.26.0 https://github.com/xrelkd/clipcat $S/clipcat && cd $S/clipcat &&
    if cargo build --release --locked; then
      for x in clipcatd clipcatctl clipcat-menu clipcat-notify; do [ -x target/release/$x ] && install -m755 target/release/$x $B/; done
    else echo "CLIPCAT FAILED"; rc=1; fi
  fi
  if ! [ -x $B/xcolor ]; then
    cargo install --locked xcolor --root $HOME/.local || { echo "XCOLOR FAILED"; rc=1; }
  fi
  exit $rc'
echo "exit=$?"
