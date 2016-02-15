;;; Copyright (C) 2016 Rocky Bernstein <rocky@gnu.org>
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

;;; Ruby debugger2 debugger

(eval-when-compile (require 'cl))

(require 'realgud)
(require 'realgud-lang-ruby)
(require 'ansi-color)

(defvar realgud-pat-hash)
(declare-function make-realgud-loc-pat (realgud-loc))


(defconst realgud:rdb2-debugger-name "rdb2" "Name of debugger")

(defvar realgud:rdb2-pat-hash (make-hash-table :test 'equal)
  "hash key is the what kind of pattern we want to match:
backtrace, prompt, etc.  the values of a hash entry is a
realgud-loc-pat struct")

;; Regular expression that describes a debugger2 location generally shown
;; before a command prompt.
;; For example:
;;  /usr/lib/ruby/1.8/rubygems/custom_require.rb:31  # in Emacs
;; /usr/bin/irb:12
(setf (gethash "loc" realgud:rdb2-pat-hash)
      (make-realgud-loc-pat
       :regexp "\\(?:source \\)?\\(\\(?:[a-zA-Z]:\\)?\\(?:.+\\)\\):\\([0-9]+\\).*\\(?:\n\\|$\\)"
       :file-group 1
       :line-group 2
       :ignore-file-re  "(eval)"
      ))

;; Regular expression that describes a debugger2 command prompt
;; For example:
;;   (rdb2:1)
(setf (gethash "prompt" realgud:rdb2-pat-hash)
      (make-realgud-loc-pat
       :regexp "^(rdb2:[0-9]+) "
       ))

;;  Regular expression that describes a Ruby backtrace line.
(setf (gethash "lang-backtrace" realgud:rdb2-pat-hash)
      realgud-ruby-backtrace-loc-pat)

;;  Regular expression that describes a ruby $! backtrace
(setf (gethash "dollar-bang-backtrace" realgud:rdb2-pat-hash)
      realgud-ruby-dollar-bang-loc-pat)

;; Regular expression that describes a debugger2 "breakpoint set" line
;; For example:
;;   Breakpoint 1 file /test/gcd.rb, line 6
;;   -----------^------^^^^^^^^^^^^-------^
(setf (gethash "brkpt-set" realgud:rdb2-pat-hash)
      (make-realgud-loc-pat
       :regexp "^Breakpoint \\([0-9]+\\) file \\(.+\\), line \\([0-9]+\\)\n"
       :num 1
       :file-group 2
       :line-group 3))

(defconst realgud:rdb2-frame-file-line-regexp
  "[ \t\n]+at line \\(.*\\):\\([0-9]+\\)$")

(defconst realgud:rdb2-frame-start-regexp realgud:trepan-frame-start-regexp)
(defconst realgud:rdb2-frame-num-regexp   realgud:trepan-frame-num-regexp)

;;  Regular expression that describes a Ruby $! string
(setf (gethash "dollar-bang" realgud:rdb2-pat-hash)
      realgud-ruby-dollar-bang-loc-pat)

;;  Regular expression that describes a Ruby $! string
(setf (gethash "rails-backtrace" realgud:rdb2-pat-hash)
      realgud-rails-backtrace-loc-pat)

(setf (gethash "rspec-backtrace" realgud:rdb2-pat-hash)
      realgud-rspec-backtrace-loc-pat)

;;  Regular expression that describes a debugger "backtrace" command line.
;;  e.g.
;; --> #0 at line /usr/bin/irb:12
;;     #1 main.__script__ at /tmp/fact.rb:1
;;     #1 main.__script__ at /tmp/fact.rb:1
;;     #0 IRB.start(ap_path#String) at line /usr/lib/ruby/1.8/irb.rb:52
(setf (gethash "debugger-backtrace" realgud:rdb2-pat-hash)
      (make-realgud-loc-pat
       :regexp 	(concat realgud:rdb2-frame-start-regexp " "
			realgud:rdb2-frame-num-regexp
			"\\(?: \\(?:\\(.+\\)(\\(.*\\))\\)\\)?"
			realgud-rdebug-frame-file-line-regexp
			)
       :num 2
       :file-group 5
       :line-group 6)
      )

(setf (gethash "font-lock-keywords" realgud:rdb2-pat-hash)
      '(
	;; Parameters and first type entry. E.g Object.gcd(a#Fixnum, b#Fixnum)
	;;                                                 ^-^^^^^^  ^-^^^^^^
	("\\<\\([a-zA-Z_][a-zA-Z0-9_]*\\)#\\([a-zA-Z_][a-zA-Z0-9_]*\\)\\>"
	 (1 font-lock-variable-name-face)
	 (2 font-lock-constant-face))

	;; "::Type", which occurs in class name of function and in
	;; parameter list.
	("::\\([a-zA-Z_][a-zA-Z0-9_]*\\)"
	 (1 font-lock-type-face))

	;; The frame number and first type name, if present.
	;; E.g. --> #0 Object.gcd(a#Fixnum, b#Fixnum)
        ;;      -----^-^^^^^^.^^^
	("^\\(-->\\)? *#\\([0-9]+\\) *\\(\\([a-zA-Z_][a-zA-Z0-9_]*\\)[.:]\\)?"
	 (2 realgud-backtrace-number-face)
	 (4 font-lock-constant-face nil t))     ; t means optional.

	;; File name and line number. E.g. at line /test/gcd.rb:6
        ;;                                 -------^^^^^^^^^^^^^-^
	("at line \\(.*\\):\\([0-9]+\\)$"
	 (1 realgud-file-name-face)
	 (2 realgud-line-number-face))

	;; Function name.
	("\\<\\([a-zA-Z_][a-zA-Z0-9_]*\\)\\.\\([a-zA-Z_][a-zA-Z0-9_]*\\)"
	 (1 font-lock-type-face)
	 (2 font-lock-function-name-face))
	;; (rdebug-frames-match-current-line
	;;  (0 rdebug-frames-current-frame-face append))
	))


(setf (gethash "rdb2" realgud:variable-basename-hash) "realgud:rdb2")

(setf (gethash "rdb2" realgud-pat-hash) realgud:rdb2-pat-hash)

(defvar realgud:rdb2-command-hash (make-hash-table :test 'equal)
  "Hash key is command name like 'quit' and the value is
  the rdb2 command to use")

(setf (gethash "shell" realgud:rdb2-command-hash) "irb")
(setf (gethash "rdb2" realgud-command-hash) realgud:rdb2-command-hash)

(provide-me "realgud:rdb2-")
