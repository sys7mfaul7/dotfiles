;; Local packages for r2d2.  Use with: guix ... -L ~/guix-config/my-packages
(define-module (my packages)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system font)
  #:use-module ((guix licenses) #:prefix license:))

(define %nerd-version "3.5.1")

(define (nerd-font name family hash)
  (package
    (name (string-append "font-nerd-" name))
    (version %nerd-version)
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/ryanoasis/nerd-fonts/releases/download/v"
                    version "/" family ".tar.xz"))
              (sha256 (base32 hash))))
    (build-system font-build-system)
    (home-page "https://www.nerdfonts.com/")
    (synopsis (string-append family " Nerd Font"))
    (description (string-append family " patched with Nerd Font glyphs."))
    (license license:silofl1.1)))

(define-public font-nerd-jetbrains-mono
  (nerd-font "jetbrains-mono" "JetBrainsMono"
             "1kqhj2hcs3bpg8rhsb67ncg6hkl3jklngy0n7v8rsgv90gwyim84"))

(define-public font-nerd-terminus
  (nerd-font "terminus" "Terminus"
             "146s5xnqf4vvm2nyynsq4c0hzp0chbpf7k2f8v3jv9w9awgl7il0"))

(define-public font-nerd-ubuntu-mono
  (nerd-font "ubuntu-mono" "UbuntuMono"
             "067avp0rh9fjffimxjah47i5hz76mmwyrbx0ky20ky0z7vi1hkcw"))

;; LightDM session entry for the user-built bspwm1 Wayland compositor
;; (binary lives in ~/.local/opt/bspwm-wl; launcher ~/.local/bin/bspwm-wl-session).
(define-public bspwm-wl-session
  (package
    (name "bspwm-wl-session")
    (version "0.1")
    (source #f)
    (build-system (@ (guix build-system trivial) trivial-build-system))
    (arguments
     (list #:modules '((guix build utils))
           #:builder
           #~(begin
               (use-modules (guix build utils))
               (let ((dir (string-append #$output "/share/wayland-sessions")))
                 (mkdir-p dir)
                 (call-with-output-file (string-append dir "/bspwm-wl.desktop")
                   (lambda (port)
                     (display "[Desktop Entry]
Name=bspwm-wl (bspwm1 Wayland)
Comment=bspwm1 wlroots compositor (test)
Exec=/home/USER/.local/bin/bspwm-wl-session
Type=Application
DesktopNames=bspwm-wl
" port)))))))
    (home-page "https://github.com/rotkonetworks/bspwm1")
    (synopsis "Wayland session entry for bspwm-wl")
    (description "Installs a wayland-sessions desktop file that starts the
user's locally built bspwm-wl compositor.")
    (license license:bsd-2)))

;; LightDM entry for niri (niri itself + xwayland-satellite live in the user
;; profile; launcher ~/.local/bin/niri-start sets env + dbus-run-session).
(define-public niri-session
  (package
    (name "niri-session")
    (version "0.1")
    (source #f)
    (build-system (@ (guix build-system trivial) trivial-build-system))
    (arguments
     (list #:modules '((guix build utils))
           #:builder
           #~(begin
               (use-modules (guix build utils))
               (let ((dir (string-append #$output "/share/wayland-sessions")))
                 (mkdir-p dir)
                 (call-with-output-file (string-append dir "/niri-r2d2.desktop")
                   (lambda (port)
                     (display "[Desktop Entry]
Name=Niri
Comment=Scrollable-tiling Wayland compositor (r2d2 config)
Exec=/home/USER/.local/bin/niri-start
Type=Application
DesktopNames=niri
" port)))))))
    (home-page "https://github.com/YaLTeR/niri")
    (synopsis "Wayland session entry for niri")
    (description "Installs a wayland-sessions desktop file that starts niri
through the user's ~/.local/bin/niri-start launcher.")
    (license license:gpl3+)))

;; PCManFM with vifm/nnn-style keys: Left = parent, Right = open,
;; Alt+D = address bar.  Install: guix install -L ~/guix-config/my-packages pcmanfm-vifm
(define-public pcmanfm-vifm
  (package
    (inherit (@ (gnu packages lxde) pcmanfm))
    (name "pcmanfm-vifm")
    (source
     (origin
       (inherit (package-source (@ (gnu packages lxde) pcmanfm)))
       (patches (list (local-file "pcmanfm-vifm-keys.patch")))))
    (synopsis "PCManFM with vifm-style Left/Right folder navigation")))

;; polkit-gnome with a narrow (~600px) Authenticate dialog: wrapped labels
;; get max-width-chars so they wrap instead of stretching the window.
;; Install: guix install -L ~/guix-config/my-packages polkit-gnome-narrow
(define-public polkit-gnome-narrow
  (package
    (inherit (@ (gnu packages polkit) polkit-gnome))
    (name "polkit-gnome-narrow")
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after (quote unpack) (quote narrow-labels)
            (lambda _
              (substitute* "src/polkitgnomeauthenticationdialog.c"
                (("gtk_label_set_line_wrap \\(GTK_LABEL \\(label\\), TRUE\\);")
                 "gtk_label_set_line_wrap (GTK_LABEL (label), TRUE); gtk_label_set_max_width_chars (GTK_LABEL (label), 60);")
                (("gtk_misc_set_alignment \\(GTK_MISC \\(label\\), 0, 1.0\\);")
                 "gtk_misc_set_alignment (GTK_MISC (label), 0, 1.0); gtk_label_set_line_wrap (GTK_LABEL (label), TRUE); gtk_label_set_line_wrap_mode (GTK_LABEL (label), PANGO_WRAP_WORD_CHAR); gtk_label_set_max_width_chars (GTK_LABEL (label), 50);")))))))
    (synopsis "GNOME polkit agent with a narrow, wrapping Authenticate dialog")))

;; libfprint 1.94.10: first release with the Realtek MOC driver entry for
;; 2541:fa03 (Minisforum AI X1 Pro fingerprint reader).  Pinned to 1.94.x on
;; purpose: enrolment reportedly segfaults with 1.95.x on this sensor.
;; Since 1.94.9 the uru4000 driver uses OpenSSL instead of NSS.
(define-public libfprint-r2d2
  (package
    (inherit (@ (gnu packages freedesktop) libfprint))
    (name "libfprint")
    (version "1.94.10")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://gitlab.freedesktop.org/libfprint/libfprint")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1zhvyq55w754l2xlw5ps0rrvdbxafirq63dmsd0gwg1plqh59l38"))))
    (arguments
     (list #:configure-flags
           #~(list (string-append "-Dudev_hwdb_dir=" #$output
                                  "/lib/udev/hwdb.d")
                   (string-append "-Dudev_rules_dir=" #$output
                                  "/lib/udev/rules.d"))))
    (inputs
     (modify-inputs (package-inputs (@ (gnu packages freedesktop) libfprint))
       (replace "nss" (@ (gnu packages tls) openssl))))))

;; fprintd (daemon, CLI tools and pam_fprintd.so) built against libfprint-r2d2.
(define-public fprintd-r2d2
  (package
    (inherit (@ (gnu packages freedesktop) fprintd))
    (inputs
     (modify-inputs (package-inputs (@ (gnu packages freedesktop) fprintd))
       (replace "libfprint" libfprint-r2d2)))))
