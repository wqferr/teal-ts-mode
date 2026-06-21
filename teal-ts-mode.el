;;; teal-ts-mode.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 William Quelho Ferreira
;;
;; Author: William Ferreira <quelho@mailbox.org>
;; Maintainer: William Ferreira <quelho@mailbox.org>
;; Created: junho 20, 2026
;; Modified: junho 20, 2026
;; Version: 0.0.1
;; Keywords: languages maint
;; Homepage: https://github.com/wqferr/teal-ts-mode
;; Package-Requires: ((emacs "29.1"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:


(require 'treesit)
(eval-when-compile 'rx)
(add-to-list
 'treesit-language-source-alist
 '(teal "https://github.com/euclidianAce/tree-sitter-teal.git"
   :commit "05d276e737055e6f77a21335b7573c9d3c091e2f")
 t)

(defgroup teal-ts nil
  "Major mode for editing Teal files."
  :prefix "teal-ts-"
  :group 'languages)
(defcustom teal-ts-mode-indent-offset 4
  "Offset of each indent level in Teal files."
  :type 'natnum
  :safe 'natnump)

(defvar teal-ts-mode--builtins
  '("assert" "collectgarbage" "coroutine" "debug" "dofile"
    "error" "getmetatable" "io" "ipairs" "load" "loadfile"
    "math" "next" "os" "package" "pairs" "pcall" "print"
    "rawequal" "rawget" "rawlen" "rawset" "require" "select"
    "setmetatable" "string" "table" "tonumber" "tostring"
    "type" "utf8" "warn" "xpcall")
  "Teal built-in functions for tree-sitter font-locking.")

(defvar teal-ts-mode--syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?+  "."    table)
    (modify-syntax-entry ?-  ". 12" table)
    (modify-syntax-entry ?=  "."    table)
    (modify-syntax-entry ?%  "."    table)
    (modify-syntax-entry ?^  "."    table)
    (modify-syntax-entry ?~  "."    table)
    (modify-syntax-entry ?<  "."    table)
    (modify-syntax-entry ?>  "."    table)
    (modify-syntax-entry ?/  "."    table)
    (modify-syntax-entry ?*  "."    table)
    (modify-syntax-entry ?\n ">"    table)
    (modify-syntax-entry ?\' "\""   table)
    (modify-syntax-entry ?\" "\""   table)
    table)
  "Syntax table for `teal-ts-mode'.")

(defvar teal-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :language 'teal
   :feature 'bracket
   '(["(" ")" "[" "]" "{" "}"] @font-lock-bracket-face)

   :language 'teal
   :feature 'delimiter
   '(["," ";"] @font-lock-delimiter-face)

   :language 'teal
   :feature 'escape
   '((escape_sequence) @font-lock-escape-face)

   :language 'teal
   :feature 'function
   '((function_call
      called_object: (identifier) @font-lock-function-call-face)
     (function_call
      called_object: (index (identifier) @font-lock-variable-name-face
                      key: (identifier) @font-lock-function-call-face))
     (function_call
      called_object: (method_index (identifier) @font-lock-variable-name-face
                      key: (identifier) @font-lock-function-call-face)))

   :language 'teal
   :feature 'type
   '((simple_type
      name: (identifier) @font-lock-type-face))

   :language 'teal
   :feature 'constant
   '((var
      attribute: (attribute))
     @font-lock-constant-face)

   :language 'teal
   :feature 'operator
   '(((op) @font-lock-operator-face)
     ((varargs ["..."]) @font-lock-operator-face))

   :language 'teal
   :feature 'property
   '((field
      key: (identifier) @font-lock-property-name-face)
     (index
      key: (identifier) @font-lock-property-use-face))

   :language 'teal
   :feature 'punctuation
   '(["." ":"] @font-lock-punctuation-face)

   :language 'teal
   :feature 'variable
   '((function_call
      arguments: (arguments (identifier))
      @font-lock-variable-use-face)
     (function_call
      called_object: (method_index
             key: (identifier) @font-lock-variable-use-face))
     (goto (identifier) @font-lock-variable-use-face)
     (identifier) @font-lock-variable-use-face)

   :language 'teal
   :feature 'assignment
   '((var (identifier) @font-lock-variable-name-face)
     (var (index (identifier) @font-lock-variable-name-face
                 key: (identifier) @font-lock-variable-name-face)))

   :language 'teal
   :feature 'number
   '((number) @font-lock-number-face)

   :language 'teal
   :feature 'keyword
   '((break) @font-lock-keyword-face
     (boolean) @font-lock-constant-face
     (nil) @font-lock-constant-face
     (["record" "interface" "local" "global" "end" "in" "if" "then" "as"
       "elseif" "else" "goto" "do" "while" "for" "type" "metamethod"
       "repeat" "until" "function" "return"] @font-lock-keyword-face))

   :language 'teal
   :feature 'string
   '((string) @font-lock-string-face)

   :language 'teal
   :feature 'comment
   '((comment) @font-lock-comment-face
     (shebang_comment) @font-lock-comment-face)

   :language 'teal
   :feature 'definition
   '((function_statement
      name: (identifier) @font-lock-function-name-face)
     (function_statement
      name: (function_name method: (identifier)) @font-lock-function-name-face)
     (record_declaration
      name: (identifier) @font-lock-type-face)
     (interface_declaration
      name: (identifier) @font-lock-type-face)
     (arg
      name: (identifier) @font-lock-variable-name-face)
     (label) @font-lock-variable-name-face)

   :language 'teal
   :feature 'builtin
   `(((identifier) @font-lock-builtin-face
      (:match ,(rx-to-string
                `(seq bol (or ,@teal-ts-mode--builtins) eol))
              @font-lock-builtin-face)))

   :language 'teal
   :feature 'error
   :override t
   '((ERROR) @font-lock-warning-face))
  "Tree-sitter font-lock settings for `teal-ts-mode'.")

(setq treesit--indent-verbose t)

(defvar teal-ts-mode--indent-rules
  (let ((neg-offset (- teal-ts-mode-indent-offset)))
        `((teal
           ((parent-is "program") column-0 0)
           ((node-is "comment_end") column-0 0)
           ((node-is "}") parent-bol 0)
           ((node-is ")") parent-bol 0)
           ((node-is "else_block") parent-bol 0)
           ((node-is "elseif_block") parent-bol 0)
           ((node-is "until") parent-bol 0)

           ;; This is terrible
           ((and (not (match "end")) (parent-is "function_body")) parent-bol 0)
           ((and (match "end") (parent-is "function_body")) parent-bol ,neg-offset)

           ((and (not (match "end")) (parent-is "interface_body")) parent-bol 0)
           ((and (match "end") (parent-is "interface_body")) parent-bol ,neg-offset)

           ((and (not (match "end")) (parent-is "record_body")) parent-bol 0)
           ((and (match "end") (parent-is "record_body")) parent-bol ,neg-offset)
           ((and (match "end") (not (or (parent-is "function_body") (parent-is "interface_body") (parent-is "record_body")))) parent-bol 0)

           ((parent-is "do_statement") parent-bol teal-ts-mode-indent-offset)
           ((parent-is "function_statement") parent-bol teal-ts-mode-indent-offset)
           ((parent-is "interface_declaration") parent-bol teal-ts-mode-indent-offset)
           ((parent-is "record_declaration") parent-bol teal-ts-mode-indent-offset)
           ((parent-is "for_body") parent-bol teal-ts-mode-indent-offset)
           ((parent-is "while_body") parent-bol teal-ts-mode-indent-offset)
           ((parent-is "if_statement") parent-bol teal-ts-mode-indent-offset)
           ((parent-is "else_block") parent-bol teal-ts-mode-indent-offset)
           ((parent-is "elseif_block") parent-bol teal-ts-mode-indent-offset)
           ((parent-is "repeat_statement") parent-bol teal-ts-mode-indent-offset)
           ((parent-is "table_constructor") parent-bol teal-ts-mode-indent-offset)
           ((parent-is "arguments") parent-bol teal-ts-mode-indent-offset)
           ((parent-is "ERROR") no-indent 0)))))

(defun teal-ts-mode--defun-name (node)
  "Return the defun name of NODE.
Return nil if there is no name or if NODE is not a defun node."
  (pcase (treesit-node-type node)
    ((or "function_statement" "interface_declaration" "record_declaration")
     (treesit-node-text
      (treesit-node-child-by-field-name node "name") t))
    ("var"
     (let ((child (treesit-node-child-by-field-name node "name")))
       (if child (treesit-node-text child t)
         (treesit-node-text
          (treesit-node-child-by-field-name
           (treesit-search-subtree node "assignment_statement" nil nil 1)
           "name")
          t))))
    ("field"
     (and (treesit-search-subtree node "function_statement" nil nil 1)
          (treesit-node-text
           (treesit-node-child-by-field-name node "name") t)))))

;;;###autoload
(define-derived-mode teal-ts-mode prog-mode "Teal"
  "Major mode for editing Teal, powered by tree-sitter."
  :group 'teal
  :syntax-table teal-ts-mode--syntax-table

  (when (treesit-ready-p 'teal)
    (treesit-parser-create 'teal)

    (setq-local treesit-defun-prefer-top-level t)

    ;; Comments.
    (setq-local comment-start "--")
    (setq-local comment-start-skip (rx "--" (* (syntax whitespace))))
    (setq-local comment-end "")

    ;; Font-lock.
    (setq-local treesit-font-lock-settings teal-ts-mode--font-lock-settings)
    (setq-local treesit-font-lock-feature-list
                '((comment definition)
                  (builtin keyword string type)
                  (assignment constant number)
                  (bracket
                   delimiter
                   escape
                   function
                   constant
                   operator
                   property
                   punctuation
                   variable)))

    ;; Indent.
    (setq-local treesit-simple-indent-rules teal-ts-mode--indent-rules)

    ;; Navigation.
    (setq-local treesit-defun-name-function #'teal-ts-mode--defun-name)
    (setq-local treesit-defun-type-regexp
                (regexp-opt '("function_statement"
                              "record_declaration"
                              "interface_declaration")))
    (setq-local treesit-sentence-type-regexp
                (regexp-opt '("do_statement"
                              "while_statement"
                              "repeat_statement"
                              "if_statement"
                              "generic_for_statement"
                              "numeric_for_statement"
                              "var_assignment")))
    (setq-local treesit-sexp-type-regexp
                (regexp-opt '("arg"
                              "comment"
                              "string"
                              "table_constructor")))

    ;; Imenu.
    (setq-local treesit-simple-imenu-settings
                `(("Variable" "\\`var\\'" nil nil)
                  ("Record" "\\`record_declaration\\'" nil nil)
                  ("Interface" "\\`interface_declaration\\'" nil nil)
                  ("Function" ,(rx bos (or "function_statement"
                                           "field")
                                   eos)
                   nil nil)))

    ;; Which-function.
    (setq-local which-func-functions (treesit-defun-at-point))

    ;; Outline.
    (setq-local outline-regexp
                (regexp-opt '("do" "for" "function" "local" "global"
                              "record" "interface" "enum"
                              "if" "repeat" "while" "--[[")))

    (treesit-major-mode-setup)))

(if (treesit-ready-p 'teal)
    (add-to-list 'auto-mode-alist '("\\.tl\\'" . teal-ts-mode)))

(provide 'teal-ts-mode)
;;; teal-ts-mode.el ends here
