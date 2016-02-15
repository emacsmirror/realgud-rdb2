;;; realgud.el --- A modular front-end for interacting with external debuggers

;; Author: Rocky Bernstein
;; Version: 1.0
;; Package-Requires: ((realgud))
;; URL: http://github.com/ko1/debugger2
;; Compatibility: GNU Emacs 24.x

;; Copyright (C) 2016 Free Software Foundation, Inc

;; Author: Rocky Bernstein <rocky@gnu.org>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; realgud support for the Ruby debugger2 debugger

;;; Code:

(require 'load-relative)

(defgroup realgud nil
  "Realgud interface to Ruby debugger2 debugger"
  :group 'processes
  :group 'tools
  :version "24.3")

(require-relative-list '( "./rdb2/rdb2" ) "realgud-")

(provide-me)


;;; realgud-rdb2.el ends here
