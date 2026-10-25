;; Guix System config — Minisforum AI X1 Pro-470 (Ryzen AI 9 HX 470 / Radeon 890M)
;; nonguix kernel+firmware, LUKS root, bspwm (NO compositor), libvirt/QEMU,
;; docker (dockur/windows), zram swap, earlyoom, LLM tooling.

(use-modules (gnu)
             (guix gexp)
             (gnu system setuid)
             (gnu system pam)
             (nongnu packages linux)
             (nongnu system linux-initrd)
             (my packages))   ; needs -L ~/guix-config/my-packages

(use-service-modules base dbus desktop networking ssh xorg cups
                     virtualization docker linux lightdm shepherd
                     authentication)
(use-package-modules linux firmware wm admin security-token)   ; kbd for console font

(define %keyboard (keyboard-layout "us"))

;; --- YubiKey (pam_u2f) + fingerprint (pam_fprintd) as OPTIONAL shortcuts ---
;; Both are "sufficient" and sit in front of pam_unix: a key touch or a finger
;; logs you in, anything else (no key, no enrolled finger, timeout, wrong
;; finger) falls through to the normal password prompt.  Nothing is
;; "required", so the password alone always works.  LUKS/boot is untouched.
;; Keys live per user in ~/.config/Yubico/u2f_keys (one line; a backup key is
;; appended to that same line with `yubikey-enroll`).  "nouserok" = users
;; without that file just get the password prompt.
(define %auth-shortcut-services
  '("login" "lightdm" "sudo" "swaylock" "i3lock"))

(define %pam-u2f-entry
  (pam-entry
   (control "sufficient")
   (module (file-append pam-u2f "/lib/security/pam_u2f.so"))
   (arguments '("cue" "nouserok"))))

(define %pam-fprintd-entry
  (pam-entry
   (control "sufficient")
   (module (file-append fprintd-r2d2 "/lib/security/pam_fprintd.so"))
   (arguments '("max-tries=1" "timeout=10"))))

(define (add-auth-shortcuts pam)
  (if (member (pam-service-name pam) %auth-shortcut-services)
      (pam-service
       (inherit pam)
       (auth (cons* %pam-u2f-entry %pam-fprintd-entry
                    (pam-service-auth pam))))
      pam))

(define %r2d2-packages
  (specifications->packages
   '(;; --- X11 bspwm session (bar, menus, notifications, tools) ---
     "bspwm" "sxhkd" "polybar" "rofi" "dunst" "jgmenu" "feh"
     "xdo" "xdotool" "xsetroot" "xrandr" "xprop" "xwininfo" "xdpyinfo"
     "xkill" "xrdb" "xsettingsd" "xclip" "xdg-user-dirs" "xdg-utils"
     "maim" "imagemagick" "webp-pixbuf-loader" "brightnessctl"
     "pamixer" "playerctl" "redshift" "jq" "bc" "polkit-gnome"
     "papirus-icon-theme" "python-pygobject"
     ;; music
     "mpd" "mpd-mpc" "ncmpcpp" "mpv"
     ;; --- terminals / shells / file managers ---
     "foot" "xterm" "xmodmap" "picom" "xset" "qt5ct" "qt6ct" "zsh" "zsh-autosuggestions" "zsh-syntax-highlighting"
     "nnn" "vifm" "gvfs" ; pcmanfm is in the user profile
     ;; --- removable media: udisks automount + filesystem tools ---
     "udiskie" "exfatprogs" "ntfs-3g" "dosfstools"
     "eza" "bat" "fzf" "ripgrep" "fd" "findutils"
     ;; --- fonts ---
     "fontconfig" "font-jetbrains-mono" "font-inconsolata" "font-terminus"
     "font-google-noto" "font-awesome"
     ;; --- editors / Doom Emacs deps ---
     "neovim" "emacs" "geany" "git" "cmake" "libtool" "gcc-toolchain"
     "make" "shellcheck" "node"
     ;; --- apps ---
     "libreoffice" "qutebrowser" "icecat" "ungoogled-chromium" "w3m" "curl" "wget" "dmenu"
     "zathura" "zathura-pdf-mupdf"
     ;; --- AppImage / FHS support ---
     "fuse@2" "squashfuse"
     ;; --- GPU / LLM ---
     "mesa" "mesa-utils" "vulkan-tools" "vulkan-loader" "radeontop"
     "llama-cpp" "python" "uv"
     ;; --- virtualization ---
     "qemu" "virt-manager" "virt-viewer" "ovmf-x86-64" "swtpm"
     "docker-compose" "htop" "btop"
     ;; --- Wayland sessions (bspwm-wl, niri): wallpaper, idle, lock, bar, tools ---
     "swaybg" "swayidle" "swaylock" "waybar" "wl-clipboard" "grim" "slurp"
     "wlr-randr" "xdg-desktop-portal" "xdg-desktop-portal-wlr"
     "xdg-desktop-portal-gtk" "pipewire" "wireplumber" "xorg-server-xwayland"
     ;; --- YubiKey tools (pamu2fcfg, fido2-token, ykman) + X11 PAM locker ---
     "pam-u2f" "libfido2" "python-yubikey-manager" "i3lock")))

(operating-system
  (locale "en_US.utf8")
  (timezone "America/Chicago")
  (keyboard-layout %keyboard)
  (host-name "r2d2")
  (kernel linux)
  (initrd microcode-initrd)
  (firmware (list linux-firmware))

  (bootloader
   (bootloader-configuration
    (bootloader grub-efi-bootloader)
    (targets (list "/boot/efi"))
    (keyboard-layout %keyboard)))
  ;; kernel-arguments belong on operating-system, not bootloader-configuration
  (kernel-arguments
   (append '("thunderbolt.security=none"
             "amd_iommu=on" "iommu=pt"
             ;; let the iGPU borrow system RAM (GTT) beyond the 1G carve-out
             "amdgpu.gttsize=65536" "ttm.pages_limit=16777216")
           %default-kernel-arguments))

  (mapped-devices
   (list (mapped-device
          (source (uuid "eb6fe516-3781-4f47-9a9a-f32537282103"))
          (target "cryptroot")
          (type luks-device-mapping))))

  (file-systems
   (cons* (file-system
            (mount-point "/boot/efi")
            (device (uuid "2F11-C2CA" 'fat32))
            (type "vfat"))
          (file-system
            (mount-point "/")
            (device "/dev/mapper/cryptroot")
            (type "ext4")
            (dependencies mapped-devices))
          %base-file-systems))

  (users
   (cons* (user-account
           (name "smt")
           (comment "sys7mfaul7")
           (group "users")
           (home-directory "/home/USER")
          ;; login shell left as bash
           (supplementary-groups
            '("wheel" "netdev" "audio" "video" "input" "lp"
              "kvm" "libvirt" "docker")))
          %base-user-accounts))

  (packages (append (list font-nerd-jetbrains-mono font-nerd-terminus
                                font-nerd-ubuntu-mono bspwm-wl-session niri-session opendoas
                                fprintd-r2d2)
                          %r2d2-packages %base-packages))

  ;; doas (OpenDoas, built --with-timestamp so "persist" works); sudo stays
  (setuid-programs
   (cons (setuid-program (program (file-append opendoas "/bin/doas")))
         %setuid-programs))

  (services
   (append
    (list
     (service openssh-service-type)
     ;; /etc/doas.conf: wheel members may run commands as root; password
     ;; cached per terminal for 5 minutes (persist)
     (simple-service 'doas-conf etc-service-type
                     (list `("doas.conf"
                             ,(plain-file "doas.conf" "permit persist :wheel\n"))))
     ;; Let the active local session reboot/poweroff/suspend without a password
     (simple-service (quote power-polkit) polkit-service-type
       (list (file-union "power-polkit-rules"
               (list (list "share/polkit-1/rules.d/50-local-power.rules"
                           (plain-file "50-local-power.rules"
"polkit.addRule(function(action, subject) {\n  if (subject.local && subject.active && subject.isInGroup(\"wheel\") &&\n      /^org\\.freedesktop\\.login1\\.(reboot|power-off|suspend|hibernate)(-multiple-sessions)?$/.test(action.id)) {\n    return polkit.Result.YES;\n  }\n});\n"))))))
     ;; Bluetooth daemon for the polybar bluetooth widget
     (service bluetooth-service-type
              (bluetooth-configuration (auto-enable? #t)))
     ;; QMK keyboards: lets your user flash without root (uaccess tag)
     (udev-rules-service (quote qmk) qmk-udev-rules)
     ;; Vial keyboard configurator: hidraw access for Vial-firmware boards
     (udev-rules-service (quote vial)
                         (udev-rule "59-vial.rules"
                                    "KERNEL==\"hidraw*\", SUBSYSTEM==\"hidraw\", ATTRS{serial}==\"*vial:f64c2b3c*\", MODE=\"0660\", GROUP=\"users\", TAG+=\"uaccess\"\n"))
     ;; FIDO/U2F security keys (YubiKey): libfido2 udev rules tag the hidraw
     ;; node "uaccess" so the logged-in user (swaylock, i3lock, ykman,
     ;; pamu2fcfg) can talk to the key without root.
     (udev-rules-service (quote fido2) libfido2)
     ;; Fingerprint daemon (D-Bus activated), built on libfprint 1.94.10 for
     ;; the Realtek 2541:fa03 sensor.
     (service fprintd-service-type
              (fprintd-configuration (fprintd fprintd-r2d2)))
     ;; Put pam_u2f + pam_fprintd (sufficient) before pam_unix for the
     ;; services in %auth-shortcut-services.
     (simple-service (quote auth-shortcuts) pam-root-service-type
                     (list (pam-extension
                            (transformer add-auth-shortcuts))))
     (service cups-service-type)
     ;; swaylock via PAM (no setuid)
     (service screen-locker-service-type
              (screen-locker-configuration
               (name "swaylock")
               (program (file-append (@ (gnu packages window-management) swaylock) "/bin/swaylock"))
               (using-pam? #t)
               (using-setuid? #f)))
     ;; i3lock via PAM for the X11 bspwm session (its lock script prefers
     ;; i3lock over slock; slock does not use PAM, so no key/finger there)
     (service screen-locker-service-type
              (screen-locker-configuration
               (name "i3lock")
               (program (file-append (@ (gnu packages window-management) i3lock) "/bin/i3lock"))
               (using-pam? #t)
               (using-setuid? #f)))
     (service lightdm-service-type
              (lightdm-configuration
               (greeters
                (list (lightdm-gtk-greeter-configuration
                       (theme-name "Adwaita-dark")
                       (background (local-file "login.jpg")))))))
     (set-xorg-configuration
      (xorg-configuration (keyboard-layout %keyboard) (extra-config (list "Section \"Device\"
  Identifier \"AMD\"
  Driver \"amdgpu\"
  Option \"VariableRefresh\" \"true\"
  Option \"TearFree\" \"false\"
EndSection
")))
      lightdm-service-type)
     ;; virtualization
     (service libvirt-service-type
              (libvirt-configuration (unix-sock-group "libvirt")))
     (service virtlog-service-type)
     ;; docker (for dockur/windows, omarchy-style Win11)
     (service containerd-service-type)
     (service docker-service-type)
     ;; memory: zram swap (swap was disabled) + earlyoom
     (service zram-device-service-type
              (zram-device-configuration
               (size "32G")
               (compression-algorithm 'zstd)
               (priority 100)))
     (service earlyoom-service-type)
     ;; Performance power mode: amd-pstate-epp "performance" governor on every
     ;; CPU policy at boot (EPP follows it to "performance"). No ACPI
     ;; platform_profile exists on this board, so this is the knob.
     (simple-service 'cpu-performance shepherd-root-service-type
      (list (shepherd-service
             (provision '(cpu-performance))
             (requirement '(file-systems))
             (one-shot? #t)
             (documentation "Set the CPU frequency governor to performance.")
             (start #~(lambda _
                        (let loop ((n 0))
                          (let ((gov (string-append
                                      "/sys/devices/system/cpu/cpufreq/policy"
                                      (number->string n) "/scaling_governor")))
                            (when (file-exists? gov)
                              (call-with-output-file gov
                                (lambda (port) (display "performance" port)))
                              (loop (+ n 1)))))
                        #t)))))
     ;; Wi-Fi off while ethernet is up, back on when it drops
     (simple-service 'wifi-wired-exclusive activation-service-type
      (let ((script
              (program-file "wifi-wired-exclusive"
                  (with-imported-modules '()
                    #~(begin
                        (use-modules (ice-9 popen) (ice-9 textual-ports))
                        (let* ((nmcli #$(file-append (@ (gnu packages gnome) network-manager) "/bin/nmcli"))
                               (port (open-input-pipe
                                      (string-append nmcli " -t -f TYPE,STATE device")))
                               (txt (get-string-all port)))
                          (close-pipe port)
                          (system* nmcli "radio" "wifi"
                                   (if (string-contains txt "ethernet:connected")
                                       "off" "on"))))))))
        #~(begin
            (use-modules (guix build utils))
            (mkdir-p "/etc/NetworkManager/dispatcher.d")
            (let ((dst "/etc/NetworkManager/dispatcher.d/70-wifi-wired-exclusive"))
              (when (file-exists? dst) (delete-file dst))
              (copy-file #$script dst)
              (chmod dst #o755))))))
    (modify-services %desktop-services
      (delete gdm-service-type)
      (console-font-service-type
       _ => (map (lambda (tty)
                   (cons tty (file-append kbd
                              "/share/consolefonts/latarcyrheb-sun32.psfu.gz")))
                 '("tty1" "tty2" "tty3" "tty4" "tty5" "tty6")))
      (guix-service-type
       config => (guix-configuration
                  (inherit config)
                  (substitute-urls
                   (append (list "https://substitutes.nonguix.org")
                           %default-substitute-urls))
                  (authorized-keys
                   (append (list (plain-file "nonguix.pub"
                                  "(public-key (ecc (curve Ed25519) (q #C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98#)))"))
                           %default-authorized-guix-keys)))))))

  (name-service-switch %mdns-host-lookup-nss))
