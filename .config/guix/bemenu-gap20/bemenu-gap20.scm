;; ~/.config/guix/bemenu-gap20/bemenu-gap20.scm
;; bemenu 0.6.23 with the one-line prompt+filter area capped at
;; BEMENU_FILTER_WIDTH percent of the bar (default 20) instead of width/4.
;; Build:  guix build -r ~/.local/lib/bemenu-gap20-root -f ~/.config/guix/bemenu-gap20/bemenu-gap20.scm
(use-modules (guix packages) (guix gexp) (gnu packages xdisorg))

(package
  (inherit bemenu)
  (source
   (origin
     (inherit (package-source bemenu))
     (patches (list (local-file "bemenu-filter-width.patch"))))))
