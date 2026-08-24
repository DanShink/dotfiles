;;; init.el --- Emacs configuration -*- lexical-binding: t; -*-

;; macOS GUI Emacs PATH fix
;; This allows external processes like ripgrep to be used too 
(when (eq system-type 'darwin)
  (setq exec-path '("/opt/homebrew/bin" "/usr/local/bin" "/usr/bin" "/bin"))
  (setenv "PATH" (string-join exec-path ":")))

;; Startup Splash Screen Every Time (Client Mode)
(add-hook 'server-after-make-frame-hook #'about-emacs)

(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(blink-cursor-mode -1)

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

;; Save existing clipboard content into kill ring before overwriting
(setq save-interprogram-paste-before-kill t)

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
(global-set-key (kbd "M-z") #'zap-up-to-char)

;; Global line numbers
(setq display-line-numbers-type 'relative) 
(global-display-line-numbers-mode 1)

;; Font
(set-face-attribute 'default nil :font "JetBrainsMono Nerd Font-12")

;; (setq fast-but-imprecise-scrolling t)

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

;; Load the custom file if it exists, but don't throw an error if it doesn't
(when (file-exists-p custom-file)
  (load custom-file))

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

(global-set-key (kbd "C-c e") #'open-init-file)

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
(put 'narrow-to-region 'disabled nil)

(make-directory "~/.emacs.d/autosaves" t)
(make-directory "~/.emacs.d/backups" t)
(make-directory "~/.emacs.d/lock-files" t)

(setq backup-directory-alist
      `((".*" . ,(expand-file-name "~/.emacs.d/backups"))))

(setq auto-save-file-name-transforms
      `((".*" ,(expand-file-name "~/.emacs.d/autosaves/") t)))

(setq lock-file-name-transforms
      `((".*" ,(expand-file-name "~/.emacs.d/lock-files/") t)))

(global-set-key (kbd "M-[") #'flymake-goto-prev-error)
(global-set-key (kbd "M-]") #'flymake-goto-next-error)

(setq vc-handled-backends
      (remove 'SVN vc-handled-backends))

(add-to-list 'load-path
             (expand-file-name "custom-files" user-emacs-directory))
(require 'simpc-mode)
(add-to-list 'auto-mode-alist '("\\.[hc]\\(pp\\)?\\'" . simpc-mode))

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
;;   (setq catppuccin-flavor 'mocha))
;; :config
;; (load-theme 'catppuccin t))	     
;; (load-theme 'modus-vivendi)
;;(load-theme 'catppucin)
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

(use-package diff-hl
  :hook ((dired-mode . diff-hl-dired-mode)
	 (magit-pre-refresh . diff-hl-magit-pre-refresh)
	 (magit-post-refresh . diff-hl-magit-post-refresh))
  :config
  (global-diff-hl-mode 1)
  (diff-hl-flydiff-mode 1)
  (unless (display-graphic-p)
    (diff-hl-margin-mode 1)))

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
  :hook (dired-mode . nerd-icons-dired-mode))

(use-package vertico
  :init (vertico-mode)
  :custom
  (vertico-cycle t))

(use-package marginalia
  :init
  (marginalia-mode))

(use-package consult
  :bind
  (("C-c s b" . consult-line)
   ("C-x b" . consult-buffer)
   ("M-y" . consult-yank-pop)))

(use-package vterm)

(global-set-key (kbd "C-c /") #'vterm)

(setq treesit-font-lock-level 3) 
(setq treesit-language-source-alist
      '((javascript . ("https://github.com/tree-sitter/tree-sitter-javascript"))
        (typescript . ("https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src"))
        (tsx        . ("https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src"))
        (css        . ("https://github.com/tree-sitter/tree-sitter-css"))
        (html       . ("https://github.com/tree-sitter/tree-sitter-html"))
        (json       . ("https://github.com/tree-sitter/tree-sitter-json"))
	(c          . ("https://github.com/tree-sitter/tree-sitter-c"))
	(cpp        . ("https://github.com/tree-sitter/tree-sitter-cpp"))
	(graphql    . ("https://github.com/bkegley/tree-sitter-graphql"))))

;; Install any missing grammars automatically
(mapc #'treesit-install-language-grammar
      (seq-filter
       (lambda (lang)
         (not (treesit-language-available-p lang)))
       (mapcar #'car treesit-language-source-alist)))

(defun my-c-large-file-settings ()
  (when (> (buffer-size) (* 5 1024 1024))
    ;; Reduce expensive fontification.
    (setq-local treesit-font-lock-feature-list
                '((comment)
                  (string)
                  (function)))
    (treesit-font-lock-recompute-features)))

(add-hook 'c-ts-mode-hook #'my-c-large-file-settings)

(use-package jtsx)
(define-key jtsx-jsx-mode-map (kbd "C-c C-f") #'jtsx-jump-jsx-closing-tag)
(define-key jtsx-jsx-mode-map (kbd "C-c C-b") #'jtsx-jump-jsx-opening-tag)

(use-package graphql-ts-mode
  :mode ("\\.graphql\\'" "\\.gql\\'"))

;; Remap old modes to tree-sitter modes
(setq major-mode-remap-alist
      '((javascript-mode . jtsx-jsx-mode)
	(js-ts-mode      . jtsx-jsx-mode)
        (typescript-mode . typescript-ts-mode)
        (css-mode        . css-ts-mode)
        (json-mode       . json-ts-mode)
	(c++-mode        . c++-ts-mode)))

;; Hook eglot into ts modes
(use-package eglot
  :ensure nil  ;; built-in
  :hook ((jtsx-jsx-mode      . eglot-ensure)
         (typescript-ts-mode . eglot-ensure)
	 (js-ts-mode         . eglot-ensure))
  :custom
  (eglot-autoshutdown t)
  :config
  (add-to-list 'eglot-server-programs
               '(((js-ts-mode :language-id "javascript")
                  (typescript-ts-mode :language-id "typescript")
                  (jtsx-jsx-mode :language-id "javascriptreact"))
                 . ("vtsls" "--stdio"))))

;; Eslint for javascript projects
(use-package flymake-eslint
  :pin "melpa"
  :after (eglot project)
  :init
  (setq flymake-eslint-executable-name "eslint_d")
  :preface
  (defun my/flymake-eslint-enable()
    "Enable flymake-eslint after eglot has intialized."
    (when (derived-mode-p 'jtsx-jsx-mode 'js-ts-mode)
      (flymake-eslint-enable)))
  :hook
  ;; (jtsx-jsx-mode . flymake-eslint-enable)
  ;; (js-ts-mode    . flymake-eslint-enable))
  (eglot-managed-mode . my/flymake-eslint-enable))

(use-package htmlize
  :pin "melpa")

;; Eslint formatting for javascript projects
(use-package apheleia
  :config
  (apheleia-global-mode +1)
  (setf (alist-get 'eslint-fix apheleia-formatters)
        '("eslint_d" "--fix-to-stdout" "--stdin" "--stdin-filename" filepath))
  (setf (alist-get 'jtsx-jsx-mode apheleia-mode-alist) '(eslint-fix))
  (setf (alist-get 'js-ts-mode apheleia-mode-alist) '(eslint-fix)))

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

(use-package smartparens
  :defer t)
(add-hook 'prog-mode-hook #'smartparens-mode)

;; (use-package evil
;;   :init
;;   (setq evil-default-state 'emacs
;;         evil-want-C-w-in-emacs-state t
;;         evil-want-C-w-delete nil
;;         evil-want-Y-yank-to-eol t
;;         evil-want-C-u-scroll t
;;         evil-vsplit-window-right t
;;         evil-split-window-below t
;;         evil-undo-system 'undo-redo
;;         evil-symbol-word-search t
;;         evil-kill-on-visual-paste nil)
;;   :config
;;   (evil-mode 1)
;;   (evil-set-initial-state 'prog-mode 'normal)
;;   (evil-set-initial-state 'text-mode 'normal)
;;   (evil-set-initial-state 'conf-mode 'normal)
;;   (evil-set-initial-state 'fundamental-mode 'normal)
;;   (evil-set-initial-state 'git-commit-mode 'emacs)
;;   (defalias #'forward-evil-word #'forward-evil-symbol))

;; (use-package evil-surround
;;   :after evil
;;   :config (global-evil-surround-mode 1))

(use-package projectile
  :init
  (projectile-mode +1)
  (setq projectile-project-search-path '("~/Documents/projects"))
  (setq projectile-completion-system 'default)
  :bind-keymap
  ("C-c p" . projectile-command-map))

(use-package expreg
  :ensure t
  :bind (("C-=" . expreg-expand)))

(use-package move-text
  :config
  (move-text-default-bindings))

(use-package multiple-cursors)

;; Remove for emacs > 30
(use-package markdown-ts-mode
  :mode ("\\.md\\'" . markdown-ts-mode)
  :defer 't
  :config
  (add-to-list 'treesit-language-source-alist '(markdown "https://github.com/tree-sitter-grammars/tree-sitter-markdown" "split_parser" "tree-sitter-markdown/src"))
  (add-to-list 'treesit-language-source-alist '(markdown-inline "https://github.com/tree-sitter-grammars/tree-sitter-markdown" "split_parser" "tree-sitter-markdown-inline/src")))

(org-babel-do-load-languages
 'org-babel-load-languages
 '((js . t) (C . t) (python . t)))

(setq org-babel-python-command "python3")

(setq org-src-fontify-natively t)
(setq org-html-htmlize-output-type 'inline-css)

(use-package web-mode
  :mode
  ("\\.njk\\'" . web-mode))

(use-package doom-modeline
  :config
  (doom-modeline-mode 1))

(use-package ripgrep)

(defun restart-graphql ()
  "Restart Graphql"
  (interactive)
  (async-shell-command "bash -ic 'restart_graphql'" "*restart-graphql-log*"))

(defun view-graphql-logs ()
  "Restart Graphql"
  (interactive)
  (async-shell-command "bash -ic 'view_graphql_logs'" "*graphql-logs*"))

(defun restart-template-svc ()
  "Restart Graphql"
  (interactive)
  (async-shell-command "bash -ic 'restart_template'" "*restart-template-log*"))

(defun view-template-svc-logs ()
  "Restart Graphql"
  (interactive)
  (async-shell-command "bash -ic 'view_template_log_emacs'" "*template-logs*"))
