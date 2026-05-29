;;; init.el --- Emacs configuration -*- lexical-binding: t; -*-

;; macOS GUI Emacs PATH fix
(when (eq system-type 'darwin)
  (setq exec-path '("/opt/homebrew/bin" "/usr/local/bin" "/usr/bin" "/bin"))
  (setenv "PATH" (string-join exec-path ":")))

;; Startup Splash Screen Every Time (Client Mode)
(add-hook 'server-after-make-frame-hook #'about-emacs)

(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)

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
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)

;; Font
(set-face-attribute 'default nil :font "JetBrainsMono Nerd Font-12")

(setq fast-but-imprecise-scrolling t)

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

;; Load the custom file if it exists, but don't throw an error if it doesn't
(when (file-exists-p custom-file)
  (load custom-file))

;; Package Management
(require 'package)

(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa stable"  . "https://stable.melpa.org/packages/")
	("melpa" . "https://melpa.org/packages/")))

(setq package-archive-priorities
      '(("gnu" . 10)
	("nongnu" . 5)
	("melpa stable" . 3)
	("melpa" . 0)))
(setq package-install-upgrade-built-in t)
(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))
  
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

(use-package doom-themes)
(load-theme 'doom-one)


;; Force transient from archive if stuck on old built-in
(unless (assq 'transient package-alist)
  (package-refresh-contents)
  (package-install 'transient))

(use-package transient
  :pin "melpa stable"
  :defer t)

(use-package magit
  :defer t)

(use-package corfu
  :custom
  (corfu-cycle t)
  :init
  (global-corfu-mode))

(use-package prescient
  :config
  (prescient-persist-mode 1))

(use-package corfu-prescient
  :after (corfu prescient)
  :config
  (corfu-prescient-mode 1))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-keyword)
  (add-to-list 'completion-at-point-functions #'cape-symbol))

(use-package nerd-icons)
(use-package nerd-icons-corfu
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters
	       #'nerd-icons-corfu-formatter))
(use-package nerd-icons-dired
  :defer t)

(use-package vertico
  :init (vertico-mode))

(use-package marginalia
  :init
  (marginalia-mode))

(use-package vterm)

(setq treesit-language-source-alist
      '((javascript . ("https://github.com/tree-sitter/tree-sitter-javascript"))
        (typescript . ("https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src"))
        (tsx        . ("https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src"))
        (css        . ("https://github.com/tree-sitter/tree-sitter-css"))
        (html       . ("https://github.com/tree-sitter/tree-sitter-html"))
        (json       . ("https://github.com/tree-sitter/tree-sitter-json"))
	(c          . ("https://github.com/tree-sitter/tree-sitter-c"))
	(cpp        . ("https://github.com/tree-sitter/tree-sitter-cpp"))))

;; Install any missing grammars automatically
(mapc #'treesit-install-language-grammar
      (seq-filter
       (lambda (lang)
         (not (treesit-language-available-p lang)))
       (mapcar #'car treesit-language-source-alist)))

;; Remap old modes to tree-sitter modes
(setq major-mode-remap-alist
      '((javascript-mode . js-ts-mode)
        (typescript-mode . typescript-ts-mode)
        (css-mode        . css-ts-mode)
        (json-mode       . json-ts-mode)
	(c-mode          . c-ts-mode)
	(c++-mode        . c++-ts-mode)))

;; Hook eglot into ts modes
(use-package eglot
  :ensure nil  ;; built-in
  :hook ((js-ts-mode         . eglot-ensure)
         (typescript-ts-mode . eglot-ensure))
  :custom
  (eglot-autoshutdown t))

(use-package dumb-jump
  :init
  (add-hook 'xref-backend-functions #'dumb-jump-xref-activate)
  :config
  (setq dumb-jump-force-searcher 'rg))

(use-package dotenv-mode
  :mode ("\\.env\\..*\\'" . dotenv-mode)
  :config
  (add-hook 'dotenv-mode-hook
	    (lambda()
	      (setq imenu-generic-expression
		    '(("Variables" "^[[:space:]]*\\([A-Za-z0-9_]+\\)[[:space:]]*=" 1))))))

;; Show startup time and garbage collections
(add-hook 'emacs-startup-hook
          (lambda ()
            (message "Emacs loaded in %.2f seconds with %d garbage collections."
                     (float-time
                      (time-subtract after-init-time before-init-time))
                     gcs-done)))

(defun open-init-file ()
  (interactive)
  (find-file user-init-file))

(global-set-key (kbd "C-c e") #'open-init-file)
