;;; -*-Scheme-*-
;;;
;;; $Id: javamode.scm,v 1.5 1999/10/07 15:18:57 cph Exp $
;;;
;;; Copyright (c) 1998-1999 Massachusetts Institute of Technology
;;;
;;; This program is free software; you can redistribute it and/or
;;; modify it under the terms of the GNU General Public License as
;;; published by the Free Software Foundation; either version 2 of the
;;; License, or (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program; if not, write to the Free Software
;;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;;; Major Mode for Java Programs

;;; This isn't a very good mode for Java, but it is good enough for
;;; some purposes and it was quickly implemented.  The major flaw is
;;; that it indents the body of a definition, such as a method or
;;; nested class, exactly the same as a continued statement.  The only
;;; way to treat these cases differently is to do more sophisticated
;;; parsing that recognizes that the contexts are different.  This
;;; could be done using the keyparser, but that would be much more
;;; work than this was.

(declare (usual-integrations))

(define-major-mode java c "Java"
  "Major mode for editing Java code.
This is just like C mode, except that
  (1) comments begin with // and end at the end of line, and
  (2) c-continued-brace-offset defaults to -2 instead of 0."
  (lambda (buffer)
    (local-set-variable! syntax-table java-syntax-table buffer)
    (local-set-variable! syntax-ignore-comments-backwards #f buffer)
    (local-set-variable! comment-locator-hook java-comment-locate buffer)
    (local-set-variable! comment-indent-hook java-comment-indentation buffer)
    (local-set-variable! comment-start "// " buffer)
    (local-set-variable! comment-end "" buffer)
    (local-set-variable! c-continued-brace-offset -2 buffer)
    (event-distributor/invoke! (ref-variable java-mode-hook buffer) buffer)))

(define-command java-mode
  "Enter Java mode."
  ()
  (lambda () (set-current-major-mode! (ref-mode-object java))))

(define-variable java-mode-hook
  "An event distributor that is invoked when entering Java mode."
  (make-event-distributor))

(define java-syntax-table
  (let ((syntax-table (make-syntax-table c-syntax-table)))
    (modify-syntax-entry! syntax-table #\/ ". 1456")
    (modify-syntax-entry! syntax-table #\newline ">")
    syntax-table))

(define (java-comment-locate mark)
  (let ((state (parse-partial-sexp mark (line-end mark 0))))
    (and (parse-state-in-comment? state)
	 (re-match-forward "/\\(/+\\|\\*+\\)[ \t]*"
			   (parse-state-comment-start state))
	 (cons (re-match-start 0) (re-match-end 0)))))

(define (java-comment-indentation mark)
  (let ((column
	 (cond ((re-match-forward "^/\\*" mark)
		0)
	       ((and (match-forward "//" mark)
		     (within-indentation? mark))
		(c-compute-indentation mark))
	       (else
		(ref-variable comment-column mark)))))
    (if (within-indentation? mark)
	column
	(max (+ (mark-column (horizontal-space-start mark)) 1)
	     column))))

(define-major-mode php java "PHP"
  "Major mode for editing PHP code.
This is just like C mode, except that
  (1) comments begin with // and end at the end of line,
  (2) c-continued-brace-offset defaults to -2 instead of 0, and
  (3) $ is a prefix character rather than a word constituent."
  (lambda (buffer)
    (local-set-variable! syntax-table php-syntax-table buffer)
    (event-distributor/invoke! (ref-variable php-mode-hook buffer) buffer)))

(define-command PHP-mode
  "Enter PHP mode."
  ()
  (lambda () (set-current-major-mode! (ref-mode-object php))))

(define-variable php-mode-hook
  "An event distributor that is invoked when entering PHP mode."
  (make-event-distributor))

(define php-syntax-table
  (let ((syntax-table (make-syntax-table java-syntax-table)))
    (modify-syntax-entry! syntax-table #\$ "  p")
    syntax-table))