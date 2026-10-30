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

;;; --- Active-window highlight (matches nvim): tinted active bg, dimmed others ---
;; Colours live in themes/doom-h4ck3r-theme.el (win-act / win-nc / win-cl / ml-*), rice-managed.
(setq hl-line-sticky-flag nil)  ; Doom sets global-hl-line-sticky-flag to window: selected window only
(use-package! auto-dim-other-buffers
  :hook (doom-after-init . auto-dim-other-buffers-mode)
  :config
  (setq auto-dim-other-buffers-dim-on-focus-out t
        auto-dim-other-buffers-dim-on-switch-to-minibuffer nil
        auto-dim-other-buffers-affected-faces
        '((default . auto-dim-other-buffers)
          (fringe . auto-dim-other-buffers)
          (line-number . auto-dim-other-buffers)
          (line-number-current-line . auto-dim-other-buffers)
          (hl-line . auto-dim-other-buffers)
          (org-block . auto-dim-other-buffers)
          (org-hide . auto-dim-other-buffers-hide))))
;; re-apply after a theme (re)load so rice switches keep the dimming
(add-hook! 'doom-load-theme-hook
  (when (bound-and-true-p auto-dim-other-buffers-mode)
    (auto-dim-other-buffers-mode -1) (auto-dim-other-buffers-mode 1)))

;;; --- Agenda, calendar grid & ICS calendar feeds (added 2026-10-30, *.bak-agenda) ---
;; Feeds: ~/.local/bin/calsync pulls each name in ~/.config/calsync/feeds into
;; ~/org/cal/<name>.org (URL from KeePassXC entry "Cal_ICS_<name>"). Read-only files.
(defvar +cal/dir (expand-file-name "cal/" org-directory))
(make-directory +cal/dir t)
(setq org-agenda-files (list org-directory +cal/dir))

(after! org
  ;; keep Doom's keyword set (TODO PROJ LOOP STRT WAIT HOLD IDEA | DONE KILL)
  (setq org-log-done 'time
        org-log-into-drawer t
        org-agenda-span 'week
        org-agenda-start-on-weekday 1
        org-agenda-start-day nil
        org-agenda-skip-deadline-if-done t
        org-agenda-skip-scheduled-if-done t
        org-deadline-warning-days 7
        org-agenda-include-diary nil
        org-agenda-block-separator ?─
        org-agenda-time-grid '((daily today require-timed) (800 1000 1200 1400 1600 1800)
                               " ┄┄┄┄┄ " "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄")
        org-agenda-current-time-string "◀── now ─────────"))

(defun +cal/feed-names ()
  (mapcar #'file-name-base (directory-files +cal/dir nil "\\.org\\'")))

;; one colour per calendar account, taken from the active (rice) theme palette
(defvar +cal/palette '(cyan green magenta orange yellow violet teal red))
(defun +cal/color (name)
  (let* ((i (or (cl-position name (+cal/feed-names) :test #'equal) 0))
         (c (nth (mod i (length +cal/palette)) +cal/palette)))
    (or (ignore-errors (doom-color c)) "#4a8cff")))

(defun +cal/colorize-agenda-h ()
  "Colour agenda lines coming from a calendar feed by account."
  (save-excursion
    (goto-char (point-min))
    (while (not (eobp))
      (when-let* ((m (get-text-property (point) 'org-hd-marker))
                  (f (buffer-file-name (marker-buffer m)))
                  ((string-prefix-p (file-truename +cal/dir) (file-truename f))))
        (add-face-text-property (line-beginning-position) (line-end-position)
                                `(:foreground ,(+cal/color (file-name-base f)))))
      (forward-line 1))))
(add-hook 'org-agenda-finalize-hook #'+cal/colorize-agenda-h)

(use-package! org-super-agenda
  :after org-agenda
  :config
  (setq org-super-agenda-header-map (make-sparse-keymap)) ; keep evil keys on headers
  (org-super-agenda-mode 1))

(defvar +agenda/groups
  `((:name "Overdue" :deadline past :scheduled past :order 1)
    (:name "Today" :time-grid t :date today :scheduled today :deadline today :order 2)
    (:name "Due soon" :deadline future :order 3)
    (:name "Calendar events" :pred (lambda (it) (let ((m (get-text-property 0 'org-hd-marker it)))
                                                  (and m (buffer-file-name (marker-buffer m))
                                                       (string-prefix-p (file-truename +cal/dir)
                                                                        (file-truename (buffer-file-name (marker-buffer m)))))))
     :order 4)
    (:name "Scheduled" :scheduled future :order 5)
    (:name "Next / in progress" :todo ("STRT" "NEXT") :order 6)
    (:name "Waiting / on hold" :todo ("WAIT" "HOLD") :order 8)
    (:name "Priority A" :priority "A" :order 7)
    (:name "Priority B" :priority "B" :order 9)
    (:name "Projects" :todo "PROJ" :order 10)
    (:name "Ideas" :todo "IDEA" :order 12)
    (:name "Other TODO" :anything t :order 11)))

(after! org-agenda
  (setq org-agenda-custom-commands
        `(("d" "Dashboard: today + week + TODOs"
           ((agenda "" ((org-agenda-span 1) (org-agenda-start-day nil)
                        (org-agenda-overriding-header "  Today")
                        (org-super-agenda-groups +agenda/groups)))
            (agenda "" ((org-agenda-span 7) (org-agenda-start-day "+1d") (org-agenda-start-on-weekday nil)
                        (org-agenda-overriding-header "  Next 7 days")
                        (org-agenda-time-grid nil)
                        (org-super-agenda-groups '((:auto-category t)))))
            (alltodo "" ((org-agenda-overriding-header "  TODO list")
                         (org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled 'deadline))
                         (org-super-agenda-groups +agenda/groups)))))
          ("w" "Week view"
           ((agenda "" ((org-agenda-span 'week) (org-agenda-start-on-weekday 1)
                        (org-super-agenda-groups nil)))))
          ("t" "TODO list (by status/priority)"
           ((alltodo "" ((org-agenda-overriding-header "  TODO list")
                         (org-super-agenda-groups +agenda/groups))))))))

;; calfw month/week/day grid (Doom :app calendar). Org items + one coloured source per feed.
(defun +cal/sources ()
  (require 'calfw-org)
  (let ((own (cl-remove-if (lambda (f) (string-prefix-p (file-truename +cal/dir) (file-truename f)))
                           (org-agenda-files))))
    (append
          (mapcar (lambda (f) (calfw-org-create-file-source (file-name-base f) f (doom-color 'blue))) own)
          (mapcar (lambda (n) (calfw-org-create-file-source
                               n (expand-file-name (concat n ".org") +cal/dir) (+cal/color n)))
                  (+cal/feed-names)))))
(defun +cal/open (&optional view)
  "Open the calendar grid. VIEW is month (default), week, two-weeks or day."
  (interactive)
  (require 'calfw) (require 'calfw-org)
  (calfw-open-calendar-buffer :contents-sources (+cal/sources) :view (or view 'month)))
(defun +cal/open-week () (interactive) (+cal/open 'week))
(defun +cal/open-day () (interactive) (+cal/open 'day))
(setq +calendar-open-function #'+cal/open)
(after! calfw (setq calfw-display-calendar-holidays nil calfw-week-start 1))

(defun +cal/sync ()
  "Run calsync asynchronously, then refresh agenda/calendar buffers."
  (interactive)
  (let ((buf (get-buffer-create " *calsync*")))
    (with-current-buffer buf (erase-buffer))
    (make-process
     :name "calsync" :buffer buf :noquery t
     :command (list (expand-file-name "~/.local/bin/calsync"))
     :sentinel (lambda (p _e)
                 (when (memq (process-status p) '(exit signal))
                   (dolist (f (directory-files +cal/dir t "\\.org\\'"))
                     (when-let* ((b (get-file-buffer f)))
                       (with-current-buffer b (revert-buffer t t t))))
                   (dolist (b (buffer-list))
                     (with-current-buffer b
                       (cond ((derived-mode-p 'org-agenda-mode) (ignore-errors (org-agenda-redo t)))
                             ((derived-mode-p 'calfw-calendar-mode) (ignore-errors (calfw-refresh-calendar-buffer nil))))))
                   (message "calsync: %s"
                            (string-trim (with-current-buffer (process-buffer p)
                                           (replace-regexp-in-string "\n" " | " (buffer-string))))))))))
(defvar +cal/sync-timer nil)
(when +cal/sync-timer (cancel-timer +cal/sync-timer))
(setq +cal/sync-timer (run-with-timer 60 1800 #'+cal/sync))  ; 1 min after start, then every 30 min

(map! :leader
      (:prefix "o"
       :desc "Calendar (month)"   "c" #'+cal/open
       (:prefix ("a" . "org agenda")
        :desc "Dashboard"         "d" (cmd! (org-agenda nil "d"))
        :desc "Week view"         "w" (cmd! (org-agenda nil "w"))
        :desc "TODO by priority"  "T" (cmd! (org-agenda nil "t"))
        :desc "Calendar month"    "c" #'+cal/open
        :desc "Calendar week"     "W" #'+cal/open-week
        :desc "Calendar day"      "D" #'+cal/open-day
        :desc "Sync calendars"    "s" #'+cal/sync)))
