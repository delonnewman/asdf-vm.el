;;; asdf-vm.el --- Integrate asdf-vm with Emacs

;;; Version: 0.1.0

;; Copyright (C) 2021 Delon Newman

;; Author: Delon Newman
;; URL: https://github.com/delonnewman/asdf-vm.el
;; Created: 4 June 2021
;; Keywords: asdf-vm

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs.

;;; Commentary:

;; M-x asdf-vm-init initializes the asdf-vm enviroment

;;; Code:

(require 'cl-lib)

(defgroup asdf-vm nil
  "Add tools from asdf-vm to path"
  :group 'tools
  :link '(url-link :tag "GitHub" "https://github.com/delonnewman/asdf-vm.el"))

(defcustom asdf-vm-local-tool-versions-file ".tool-versions"
  "The 'local' .tool-versions file."
  :type 'string
  :group 'asdf-vm)

(defcustom asdf-vm-home-tool-versions-file "~/.tool-versions"
  "The 'home' .tool-versions file."
  :type 'string
  :group 'asdf-vm)

(defcustom asdf-vm-installs-path (concat (getenv "HOME") "/.asdf/installs")
  "The path for asdf installs."
  :type 'string
  :group 'adsf-vm)

(defcustom asdf-vm-shims-path (concat (getenv "HOME") "/.asdf/shims")
  "The path for asdf shims."
  :type 'string
  :group 'asdf-vm)

(defvar asdf-vm-path-seperator ":"
  "The path seperator for PATH environment variable."
  :type 'string
  :group 'asdf-vm)

(defvar asdf-vm--current-tools-listing nil
  "Current active tools.")

(defun asdf-vm--slurp (file-path)
  "Read the contents of the FILE-PATH to a string."
  (with-temp-buffer
    (insert-file-contents file-path)
    (buffer-string)))

(defun asdf-vm--chomp (string)
  "Remove any trailing new lines from the STRING."
  (replace-regexp-in-string "\n+$" "" string))

(defun asdf-vm--make-tool (name version)
  "Construct a new 'tool' with the given NAME and VERSION."
  (cons name version))

(defun asdf-vm--tool-name (tool)
  "Return the name from the TOOL."
  (car tool))

(defun asdf-vm--tool-version (tool)
  "Return the version from the TOOL."
  (cdr tool))

(defun asdf-vm--tool-from-line (tool-line)
  "Parse a line in a .tool-version file specified by TOOL-LINE."
  (let ((tool (split-string tool-line "\s+")))
    (asdf-vm--make-tool (intern (car tool)) (car (cdr tool)))))

(defun asdf-vm-tool-versions-from-file (file-path)
  "Return an alist of tool versions from this FILE-PATH."
  (let ((contents (asdf-vm--chomp (asdf-vm--slurp file-path))))
    (mapcar #'asdf-vm--tool-from-line (split-string contents "\n"))))

(defun asdf-vm-tool-versions ()
  "Return an alist of all tool versions for this asdf-vm enviroment.
If there is a .tool-versions file in the current directory the list
be constructed from that file.  Otherwise it will look for ~/.tool-versions."
  (if (file-exists-p asdf-vm-local-tool-versions-file)
      (asdf-vm-tool-versions-from-file asdf-vm-local-tool-versions-file)
    (asdf-vm-tool-versions-from-file asdf-vm-home-tool-versions-file)))

(defun asdf-vm--tool-bin-path (tool)
  "Return the bin path for the TOOL."
  (concat asdf-vm-installs-path "/"
	  (symbol-name (asdf-vm--tool-name tool)) "/"
	  (asdf-vm--tool-version tool) "/bin"))

(defun asdf-vm--tool-bin-path-listing (tool-list)
  "Return a bin path list for the TOOL-LIST."
  (mapcar #'asdf-vm--tool-bin-path tool-list))

(defun asdf-vm--list-join (list sep)
  "Join the LIST with the string SEP."
  (cl-reduce (lambda (str path) (concat str sep path)) list))

(defun asdf-vm-init ()
  "Initialize the asdf-vm environment."
  (setq asdf-vm--current-tools-listing (asdf-vm-tool-versions))
  (let ((paths (cons asdf-vm-shims-path (asdf-vm--tool-bin-path-listing asdf-vm--current-tools-listing)))
	(sep asdf-vm-path-seperator))
    (setenv "PATH" (concat (asdf-vm--list-join paths sep) sep (getenv "PATH")))
    (setq exec-path (append paths exec-path))))

(provide 'asdf-vm)
;;; asdf-vm.el ends here
