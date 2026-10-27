;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;; (setq doom-theme 'doom-one)  ; replaced by doom-h4ck3r below
;; Specify both a dark and light theme, like so and Doom will choose which one
;; to load based on your system light/dark setting:
;;
;;   (setq doom-theme '(doom-one   . doom-one-light))   ; (DARK . LIGHT)
;;
;; If you want more pro-active theme switching based on OS light/dark mode, look
;; up the `auto-dark' package.

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; unified system clipboard
(setq select-enable-clipboard t
      select-enable-primary nil)

;;; --- Green matrix look (theme file: themes/doom-h4ck3r-theme.el) ---
(setq doom-theme 'doom-h4ck3r)
(setq doom-font (font-spec :family "DejaVu Sans Mono" :size 10.0)          ; float = points
      doom-variable-pitch-font (font-spec :family "DejaVu Sans Mono" :size 10.0)
      doom-serif-font (font-spec :family "DejaVu Sans Mono" :size 10.0)
      doom-symbol-font (font-spec :family "Symbols Nerd Font Mono")
      doom-big-font (font-spec :family "DejaVu Sans Mono" :size 15.0))
;; Emacs 31 (X11/GTK under Xwayland) supports alpha-background; text stays opaque.
(add-to-list 'default-frame-alist '(alpha-background . 90))

;;; --- Markdown: rendered look, aligned tables, sane lint (added 2026-10-27) ---
;; .md files open in gfm-mode (GitHub tables, strikethrough, fenced code).
(add-to-list 'auto-mode-alist '("\\.\\(?:md\\|markdown\\)\\'" . gfm-mode))
(setq markdown-header-scaling t                 ; bigger headings (before markdown-mode loads)
      markdown-header-scaling-values '(1.45 1.3 1.15 1.05 1.0 1.0)
      markdown-hide-markup t                    ; hide **, `, link URLs; SPC m t m toggles
      markdown-fontify-code-blocks-natively t
      markdown-enable-highlighting-syntax t     ; ==highlight==
      markdown-list-indent-width 2)

(after! markdown-mode
  (markdown-update-header-faces markdown-header-scaling markdown-header-scaling-values))

;; Display-only table alignment (never edits the file).
(use-package! valign
  :hook ((markdown-mode . valign-mode) (org-mode . valign-mode))
  :config
  (setq valign-fancy-bar t                     ; draw | and |---| as solid lines
        valign-max-table-size 0))              ; align tables of any size

(defun +md/toggle-markdownlint ()
  "Toggle the markdownlint flycheck checker in this buffer."
  (interactive)
  (if (memq 'markdown-markdownlint-cli2 flycheck-disabled-checkers)
      (progn (setq-local flycheck-disabled-checkers
                         (delq 'markdown-markdownlint-cli2 flycheck-disabled-checkers))
             (message "markdownlint: on"))
    (setq-local flycheck-disabled-checkers
                (cons 'markdown-markdownlint-cli2 flycheck-disabled-checkers))
    (message "markdownlint: off"))
  (flycheck-buffer))

(defun +md/toggle-table-view ()
  "Toggle line wrapping so wide tables stay on one line (horizontal scroll)."
  (interactive)
  (if truncate-lines
      (progn (setq-local truncate-lines nil) (visual-line-mode 1))
    (visual-line-mode -1) (setq-local truncate-lines t))
  (when (bound-and-true-p valign-mode) (font-lock-flush)))

(add-hook! (markdown-mode gfm-mode) #'visual-line-mode)

(map! :after markdown-mode
      (:map (markdown-mode-map gfm-mode-map)
       :localleader
       (:prefix ("t" . "toggle")
        :desc "Markdownlint"         "L" #'+md/toggle-markdownlint
        :desc "Wide tables (no wrap)" "t" #'+md/toggle-table-view
        :desc "Live preview (eww)"   "p" #'markdown-live-preview-mode)))
;; Lint rules: ~/.markdownlint-cli2.jsonc (line length, first-line heading, inline
;; HTML and table-style rules are off). Preview: SPC m p (browser), SPC m t p (live).
