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

(desktop-save-mode 1)

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

(setq next-screen-context-lines 10)

;; Font
(if (eq system-type 'windows-nt)
    (set-face-attribute 'default nil :font "JetBrainsMono NF-12.0")
  (set-face-attribute 'default nil :font "JetBrainsMono Nerd Font-12"))

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
(use-package doom-themes
  :pin "melpa")
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
  (corfu-auto-delay 0.08)
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

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-keyword))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides
   '((file (styles basic partial-completion)))))

(use-package nerd-icons
  :pin "melpa")
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

(use-package nerd-icons-completion
  :after marginalia
  :config
  (nerd-icons-completion-mode)
  (add-hook 'marginalia-mode-hook
	    #'nerd-icons-completion-marginalia-setup))

(unless (eq system-type 'windows-nt)
  (use-package ghostel
    :pin "melpa")
  (global-set-key (kbd "C-c /") #'ghostel))

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

(defconst my-tsx-void-tags
  '("area" "base" "br" "col" "embed"
    "hr" "img" "input" "link" "meta"
    "param" "source" "track" "wbr"))

(defun my-tsx-auto-close-tag ()
  "Automatically insert a closing JSX tag after typing `>'."
  (when (and (derived-mode-p 'tsx-ts-mode)
             (eq last-command-event ?>))
    (let ((node (treesit-node-at (1- (point)) 'tsx)))
      (while (and node
                  (not (member (treesit-node-type node)
                               '("jsx_opening_element"
                                 "jsx_self_closing_element"))))
        (setq node (treesit-node-parent node)))

      (when (and node
                 (string= (treesit-node-type node)
                          "jsx_opening_element"))
        (when-let* ((name-node
                     (treesit-node-child-by-field-name node "name"))
                    (tag-name
                     (treesit-node-text name-node t)))
          (unless (member tag-name my-tsx-void-tags)
            (save-excursion
              (insert "</" tag-name ">"))))))))

(add-hook 'tsx-ts-mode-hook
          (lambda ()
            (add-hook 'post-self-insert-hook
                      #'my-tsx-auto-close-tag
                      nil t)))

(defun my-tsx--between-empty-tags-p ()
  "Return non-nil when point is between an empty pair of JSX tags."
  (when (derived-mode-p 'tsx-ts-mode)
    (let ((node (treesit-node-at
                 (max (point-min) (1- (point)))
                 'tsx)))

      ;; Find the containing JSX element.
      (while (and node
                  (not (string= (treesit-node-type node)
                                "jsx_element")))
        (setq node (treesit-node-parent node)))

      (when node
        (let ((open-tag
               (treesit-node-child-by-field-name node "open_tag"))
              (close-tag
               (treesit-node-child-by-field-name node "close_tag")))

          (and open-tag
               close-tag

               ;; Point must be between the opening and closing tags.
               (>= (point) (treesit-node-end open-tag))
               (<= (point) (treesit-node-start close-tag))

               ;; There can't already be content between them.
               (string-match-p
                "\\`[[:space:]]*\\'"
                (buffer-substring-no-properties
                 (treesit-node-end open-tag)
                 (treesit-node-start close-tag)))))))))


(defun my-tsx-newline ()
  "Insert a JSX-aware newline in `tsx-ts-mode'."
  (interactive)

  (if (my-tsx--between-empty-tags-p)

      ;; <div>|</div>
      (progn
        ;; First create the final structure:
        ;;
        ;; <div>
        ;;
        ;; </div>
        ;;
        (newline 2)

        ;; We're now on the closing-tag line.
        (indent-according-to-mode)

        ;; Move back to the empty inner line.
        (forward-line -1)
        (indent-according-to-mode))

    ;; Normal newline everywhere else.
    (newline)
    (indent-according-to-mode)))

(with-eval-after-load 'typescript-ts-mode
  (define-key tsx-ts-mode-map
              (kbd "RET")
              #'my-tsx-newline))

(use-package graphql-ts-mode
  :mode ("\\.graphql\\'" "\\.gql\\'"))

;; Remap old modes to tree-sitter modes
(setq major-mode-remap-alist
      '((javascript-mode . tsx-ts-mode)
	(js-ts-mode      . tsx-ts-mode)
        (typescript-mode . typescript-ts-mode)
        (css-mode        . css-ts-mode)
        (json-mode       . json-ts-mode)
	(c++-mode        . c++-ts-mode)))

;; Hook eglot into ts modes
(use-package eglot
  :ensure nil  ;; built-in
  :hook ((tsx-ts-mode      . eglot-ensure)
         (typescript-ts-mode . eglot-ensure)
	 (js-ts-mode         . eglot-ensure)
	 (tsx-ts-mode        . eglot-ensure))
  :custom
  (eglot-autoshutdown t)
  :config
  (add-to-list 'eglot-ignored-server-capabilities
	       :documentOnTypeFormattingProvider)
  (add-to-list 'eglot-server-programs
               '(((js-ts-mode :language-id "javascript")
                  (typescript-ts-mode :language-id "typescript")
		  (tsx-ts-mode :language-id "javascriptreact"))
                 . ("vtsls" "--stdio")))
  (setq eglot-events-buffer-config '(:size 0 :format short)))

;; Eslint for javascript projects
(use-package flymake-eslint
  :pin "melpa"
  :after (eglot project)
  :init
  (setq flymake-eslint-executable-name "eslint_d")
  :preface
  (defun my/flymake-eslint-enable()
    "Enable flymake-eslint after eglot has intialized."
    (when (derived-mode-p 'js-ts-mode 'tsx-ts-mode)
      (flymake-eslint-enable)))
  :hook
  ;; (jtsx-jsx-mode . flymake-eslint-enable)
  ;; (js-ts-mode    . flymake-eslint-enable))
  (eglot-managed-mode . my/flymake-eslint-enable))

(setq-default
 eglot-workspace-configuration
 '(:vtsls
   (:experimental
    (:completion
     (:enableServerSideFuzzyMatch t
				  :entriesLimit 200)))))

(use-package htmlize
  :pin "melpa")

;; Eslint formatting for javascript projects
(use-package apheleia
  :config
  (apheleia-global-mode +1)
  (setf (alist-get 'eslint-fix apheleia-formatters)
        '("eslint_d" "--fix-to-stdout" "--stdin" "--stdin-filename" filepath))
  (setf (alist-get 'tsx-ts-mode apheleia-mode-alist) '(eslint-fix))
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
	       '(tsx-ts-mode js-indent-level))
  (add-hook 'tsx-ts-mode-hook #'editorconfig-apply t))

;; (use-package smartparens
;;   :defer t)
;; (add-hook 'prog-mode-hook #'smartparens-mode)
(electric-pair-mode 1)

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

(use-package multiple-cursors
  :bind
  (("C->" . mc/mark-next-like-this)
   ("C-<" . mc/mark-previous-like-this)
   ("C-c m a" . mc/mark-all-like-this)
   ("C-c m l" . mc/edit-lines)
   ("C-c m n" . mc/skip-to-next-like-this)
   ("C-c m p" . mc/skip-to-previous-like-this)))

(org-babel-do-load-languages
 'org-babel-load-languages
 '((js . t) (C . t) (python . t)))

(setq org-babel-python-command "python3")
(with-eval-after-load 'org
  (add-to-list 'org-src-lang-modes '(("js" . js-ts) ("jsx" . tsx-ts))))

(setq org-src-fontify-natively t)
(setq org-html-htmlize-output-type 'inline-css)

(use-package web-mode
  :mode
  ("\\.njk\\'" . web-mode))

(use-package markdown-mode)

(use-package doom-modeline
  :config
  (doom-modeline-mode 1))

(use-package ripgrep)

(use-package restclient
  :mode ("\\.http\\'" . restclient-mode))

(when (>= emacs-major-version 31)
  (use-package markdown-ts-mode
    :mode ("\\.md\\'" . markdown-ts-mode)))

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

(defun my/get-wordle (date)
  "Fetch the wordle for the specified date (YYYY-MM-DD)"
  (interactive
   (list
    (read-string
     "Date (YYYY-MM-DD): "
     (format-time-string "%Y-%m-%d"))))

  (let ((buffer
         (url-retrieve-synchronously
          (format "https://www.nytimes.com/svc/wordle/v2/%s.json" date))))

    (with-current-buffer buffer
      ;; Move past the HTTP headers.
      (goto-char url-http-end-of-headers)
      ;; Turn the JSON response into an Emacs Lisp value.
      (let ((json
             (json-parse-buffer
              :object-type 'alist)))
        ;; Get the value associated with "solution".
        (let ((wordle (alist-get 'solution json)))
          (kill-buffer buffer)
          (message "Solution: %s" wordle)
          wordle)))))
