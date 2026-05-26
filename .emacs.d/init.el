;;; init.el --- Emacs configuration -*- lexical-binding: t; -*-

;; macOS GUI Emacs PATH fix
(when (eq system-type 'darwin)
  (setq exec-path '("/opt/homebrew/bin" "/usr/local/bin" "/usr/bin" "/bin"))
  (setenv "PATH" (string-join exec-path ":")))

;; Startup Splash Screen Every Time (Client Mode)
(add-hook 'server-after-make-frame-hook #'about-emacs)

(load-theme 'modus-vivendi)

;; Optmizations
;; Only read left to right
(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right)
(setq bidi-inhibit-bpa t)

;; Skip font stuff while typing
(setq redisplay-skip-fontification-on-input t)

;; Good for lsp stuff
(setq read-process-output-max (* 4 1024 1024)) ; 4MB

;; No Duplicates in Kill Ring
(setq kill-do-not-save-duplicates t)

;; Auto chmod on save
(add-hook 'after-save-hook
          #'executable-make-buffer-file-executable-if-script-p)

;; Save window layout after ctrl-x 1
(winner-mode +1)

(defun toggle-delete-other-windows ()
  "Delete other windows in frame if any, or restore previous window config."
  (interactive)
  (if (and winner-mode
           (equal (selected-window) (next-window)))
      (winner-undo)
    (delete-other-windows)))

(global-set-key (kbd "C-x 1") #'toggle-delete-other-windows)

;; Global line numbers
(global-display-line-numbers-mode 1)

;; Font
(set-face-attribute 'default nil :font "JetBrains Mono-12")
