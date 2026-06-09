;;; init.el --- Emacs configuration -*- lexical-binding: t; -*-

;; macOS GUI Emacs PATH fix
;; (when (eq system-type 'darwin)
;;   (setq exec-path '("/opt/homebrew/bin" "/usr/local/bin" "/usr/bin" "/bin"))
;;   (setenv "PATH" (string-join exec-path ":")))

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

;; (use-package catppuccin-theme
;;   :pin "melpa"
;;   :init
;;   (setq catppuccin-flavor 'frappe)
;;   :config
;;   (load-theme 'catppuccin t))
(load-theme 'modus-vivendi)

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
  (corfu-auto t)
  (corfu-auto-delay 0.15)
  (corfu-auto-prefix 2)
  (corfu-preview-current nil)
  (corfu-preselect 'prompt)
  (corfu-quit-no-match 'separator)
  (corfu-on-exact-match nil)
  :bind
  (:map corfu-map
        ("<tab>"     . corfu-next)
        ("<backtab>" . corfu-previous)
        ("<escape>"  . corfu-quit)
        ("<return>"  . corfu-insert)
        ("C-g"       . corfu-quit))
  :init
  (global-corfu-mode)
  (corfu-history-mode)
  (corfu-popupinfo-mode))

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
  (add-to-list 'completion-at-point-functions #'cape-keyword)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides
   '((file (styles basic partial-completion)))))

(use-package nerd-icons)
(use-package nerd-icons-corfu
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters
	       #'nerd-icons-corfu-formatter))
(use-package nerd-icons-dired
  :defer t)

(use-package vertico
  :init (vertico-mode)
  :custom
  (vertico-cycle t))

(use-package marginalia
  :init
  (marginalia-mode))

(use-package consult
  :bind
  (("C-s" . consult-line)
   ("C-x b" . consult-buffer)
   ("M-y" . consult-yank-pop)))

(use-package vterm)

(use-package jtsx)

(setq treesit-font-lock-level 4) 
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
      '((javascript-mode . jtsx-jsx-mode)
        (typescript-mode . typescript-ts-mode)
        (css-mode        . css-ts-mode)
        (json-mode       . json-ts-mode)
	(c-mode          . c-ts-mode)
	(c++-mode        . c++-ts-mode)))

;; Hook eglot into ts modes
(use-package eglot
  :ensure nil  ;; built-in
  :hook ((jtsx-jsx-mode      . eglot-ensure)
         (typescript-ts-mode . eglot-ensure))
  :custom
  (eglot-autoshutdown t))

;; Eslint for javascript projects
(use-package flymake-eslint
  :init
  (setq flymake-eslint-executable-name "eslint_d")
  :hook
  (jtsx-jsx-mode . flymake-eslint-enable))

(use-package dumb-jump
  :init
  (add-hook 'xref-backend-functions #'dumb-jump-xref-activate)
  :config
  (setq dumb-jump-force-searcher 'rg))

(use-package dotenv-mode
  :defer t
  :mode ("\\.env\\..*\\'" . dotenv-mode)
  :config
  (add-hook 'dotenv-mode-hook
	    (lambda()
	      (setq imenu-generic-expression
		    '(("Variables" "^[[:space:]]*\\([A-Za-z0-9_]+\\)[[:space:]]*=" 1))))))

(use-package yasnippet
  :config
  (yas-global-mode 1))

(use-package which-key
  :init
  (which-key-mode))

(use-package editorconfig
  :config
  (editorconfig-mode 1)
  (add-to-list 'editorconfig-indentation-alist
	       '(jtsx-jsx-mode js-indent-level))
  (add-hook 'jtsx-jsx-mode-hook #'editorconfig-apply t))

(use-package evil
  :init
  (setq evil-default-state 'emacs
        evil-want-C-w-in-emacs-state t
        evil-want-C-w-delete nil
        evil-want-Y-yank-to-eol t
        evil-want-C-u-scroll t
        evil-vsplit-window-right t
        evil-split-window-below t
        evil-undo-system 'undo-redo
        evil-symbol-word-search t
        evil-kill-on-visual-paste nil)
  :config
  (evil-mode 1)
  (evil-set-initial-state 'prog-mode 'normal)
  (evil-set-initial-state 'text-mode 'normal)
  (evil-set-initial-state 'conf-mode 'normal)
  (evil-set-initial-state 'fundamental-mode 'normal)
  (evil-set-initial-state 'git-commit-mode 'emacs)
  (defalias #'forward-evil-word #'forward-evil-symbol))

(use-package evil-surround
  :after evil
  :config (global-evil-surround-mode 1))

(use-package projectile
  :init
  (projectile-mode +1)
  (setq projectile-project-search-path '("~/Documents/projects"))
  (setq projectile-completion-system 'default)
  :bind-keymap
  ("C-c p" . projectile-command-map))

;; Show startup time and garbage collections
(add-hook 'emacs-startup-hook
          (lambda ()
            (message "Emacs loaded in %.2f seconds with %d garbage collections."
                     (float-time
                      (time-subtract after-init-time before-init-time))
                     gcs-done)))

(defun open-init-file ()
  "This function opens the init.el file."
  (interactive)
  (find-file user-init-file))

(use-package projectile
  :init
  (projectile-mode +1)
  (setq projectile-project-search-path '("~/Documents/projects"))
  (setq projectile-completion-system 'default)
  :bind-keymap
  ("C-c p" . projectile-command-map))
(global-set-key (kbd "C-c e") #'open-init-file)
(global-set-key (kbd "C-c /") #'vterm)

(defvar highlight-codetags-keywords
  '(("\\<\\(TODO\\|FIXME\\|BUG\\|XXX\\)\\>" 1 font-lock-warning-face prepend)
    ("\\<\\(NOTE\\|HACK\\)\\>" 1 font-lock-doc-face prepend)))

(define-minor-mode highlight-codetags-local-mode
  "Highlight codetags like TODO, FIXME..."
  :global nil
  (if highlight-codetags-local-mode
      (font-lock-add-keywords nil highlight-codetags-keywords)
    (font-lock-remove-keywords nil highlight-codetags-keywords))

  ;; Fontify the current buffer
  (when (bound-and-true-p font-lock-mode)
    (if (fboundp 'font-lock-flush)
        (font-lock-flush)
      (with-no-warnings (font-lock-fontify-buffer)))))

(add-hook 'prog-mode-hook #'highlight-codetags-local-mode)
