# Guix System notes

## What changed vs your config
- `services`: `modify-services` now takes the service list first; based on `%desktop-services` with `(delete gdm-service-type)`. NM, wpa-supplicant and NTP were removed from your list because `%desktop-services` already provides them.
- `packages`: `%base-packages` now sits inside `append`. Packages are listed by name with `specifications->packages`, so no extra `use-package-modules` is needed. If a name is wrong, `guix system build` names it.
- LightDM: now `(lightdm-configuration (xorg-configuration (xorg-configuration ...)))`.
- `thunderbolt.security=none` moved to `operating-system (kernel-arguments ...)`, where it belongs. Also added `amd_iommu=on iommu=pt` and `amdgpu.gttsize` / `ttm.pages_limit` so the iGPU can map about 64 GB of system RAM for LLMs on top of the 1 GB carve-out.
- Removed: the `(fonts)` module and the duplicate `nss-certs`. Chromium is now `ungoogled-chromium` from Guix proper. Floorp runs through the launcher `bin/floorp`. No Flatpak.
- Added: libvirt, virtlog, containerd + docker, 32G zstd zram swap, earlyoom. User added to kvm, libvirt, docker, input and lp. Login shell is zsh.
- picom is optional: the X11 bspwmrc starts it only when it is installed.

## Apply
```
guix pull                                   # with nonguix channel in ~/.config/guix/channels.scm
sudo cp config.scm /etc/config.scm
guix system build -L ~/guix-config/my-packages /etc/config.scm           # test first
sudo guix system reconfigure -L ~/guix-config/my-packages /etc/config.scm
```
Unverified package names (if the build fails on one, remove it or rename it): `mpd-mpc`, `ovmf-x86-64` (older Guix: `ovmf`), `jgmenu`, `xsettingsd`, `webp-pixbuf-loader`, `llama-cpp`, `uv`, `swtpm`, `radeontop`, `docker-compose`, `fuse@2`, `font-terminus`, `polkit-gnome`.
## Local packages (`my-packages/my/packages.scm`, module `(my packages)`)
- **Nerd Fonts** (Guix packages, font-build-system, v3.5.1 release tarballs, sha256 computed on download): `font-nerd-jetbrains-mono`, `font-nerd-terminus`, `font-nerd-ubuntu-mono`.
- **Icon font:** the X11 bar, menus and notifications use Symbols Nerd Font (`NerdFontsSymbolsOnly.zip` from ryanoasis/nerd-fonts, unzipped into `~/.local/share/fonts/NerdFontsSymbolsOnly`). The text font is DejaVu Sans Mono (`font-dejavu`).
- **clipcat, xcolor:** upstream ships no usable Linux binaries, and cargo packaging would need hundreds of crate inputs. Run `bin/build-rust-tools.sh` instead. It builds them into `~/.local/bin` inside `guix shell`.
- **Floorp:** `bin/floorp` downloads the official tarball (v12.20.1) to `~/.local/opt/floorp` and runs it in a `guix shell --container --emulate-fhs`. It is more reliable than a patchelf package. Copy it to `~/.local/bin`.
- **lxsession:** not in Guix; polkit-gnome is used instead.

## Dotfiles
Run `./install.sh` from the dotfiles repo (see its README). Then pick the "bspwm" (X11) or "bspwm-wl" (Wayland) session in LightDM.

## Windows 11 VM
How Omarchy does it: `omarchy-windows-vm` runs **dockur/windows** in Docker. That is QEMU/KVM inside a container that downloads Win11 automatically, with RDP and a web viewer on :8006. It is then reached through FreeRDP. Guix equivalent with the docker service above:
```
mkdir -p ~/windows && cat > ~/windows/compose.yml <<'Y'
services:
  windows:
    image: dockurr/windows
    environment: { VERSION: "11", RAM_SIZE: "16G", CPU_CORES: "8", DISK_SIZE: "128G" }
    devices: [/dev/kvm, /dev/net/tun]
    cap_add: [NET_ADMIN]
    ports: ["8006:8006", "3389:3389/tcp", "3389:3389/udp"]
    volumes: ["./storage:/storage", "./shared:/data"]
    stop_grace_period: 2m
Y
cd ~/windows && docker-compose up -d     # browse http://localhost:8006, then: xfreerdp /v:localhost /u:Docker
```
Native alternative: open virt-manager, create a new VM from the Win11 ISO, choose firmware "UEFI (OVMF secboot)", and add a TPM 2.0 emulated device (swtpm). Use virtio disk and network with the virtio-win ISO.

## LLMs on the 890M
- Vulkan is the easy path on Guix (Mesa RADV). Test it with `vulkaninfo --summary`. If the Guix `llama-cpp` lacks Vulkan, build it: `guix shell gcc-toolchain cmake vulkan-headers vulkan-loader shaderc git -- cmake -B build -DGGML_VULKAN=ON && cmake --build build -j`.
- ROCm in Guix is limited and gfx1150 support is spotty, so use Vulkan.
- Watch GPU memory with `radeontop`.

## AppImages (LM Studio, Grok Bot terminal agent)
AppImages expect an FHS layout plus FUSE 2, and Guix has neither by default. Reliable method:
```
chmod +x ~/LM-Studio-*.AppImage
guix shell --container --emulate-fhs --network --share=$HOME --preserve='^DISPLAY$' --expose=/tmp/.X11-unix \
  --share=/dev/dri --expose=/sys \
  coreutils bash glibc gcc:lib zlib fuse@2 nss nspr gtk+ alsa-lib libxkbfile libxshmfence mesa libdrm \
  libx11 libxcomposite libxdamage libxrandr libxext libxfixes libxcb dbus cups at-spi2-core expat libsecret \
  -- ~/LM-Studio-*.AppImage --appimage-extract-and-run
```
- `--appimage-extract-and-run`, or `--appimage-extract` followed by running `squashfs-root/AppRun`, avoids FUSE entirely.
- Save it as a script, e.g. `~/.local/bin/lmstudio`.
- `lms`: after the first LM Studio launch, run `~/.lmstudio/bin/lms bootstrap`, or add `~/.lmstudio/bin` to PATH.
- Grok Bot AppImage in `~/`: same recipe. If it is a terminal app, drop the X11 flags. If it complains about a missing `.so`, add the matching package to the list. Run `ldd squashfs-root/<binary>` inside the shell to find it.
- Flatpak option for LM Studio: none official. The AppImage is the supported route.

## Hermes agent (Nous Research `hermes-agent`, verify upstream README)
It's a Python app. Install it with uv in a user environment: `guix shell python uv git gcc-toolchain -- uv tool install git+https://github.com/NousResearch/hermes-agent`. Or follow its install script inside `guix shell --emulate-fhs ...` if it needs prebuilt wheels. Point it at LM Studio's OpenAI-compatible server `http://localhost:1234/v1`, or at `llama-server`.

## Doom Emacs
```
git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
~/.config/emacs/bin/doom install
echo 'export PATH=$HOME/.config/emacs/bin:$PATH' >> ~/.zshrc
```
The deps are in config.scm: git, ripgrep, fd, findutils, cmake, libtool and gcc-toolchain (for vterm), plus fonts. Run `doom doctor` afterwards. Set the font in `~/.config/doom/config.el`: `(setq doom-font (font-spec :family "JetBrains Mono" :size 14))`.
