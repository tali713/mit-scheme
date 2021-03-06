#| -*-Scheme-*-

Copyright (C) 2008 Helmut Eller

This file is licensed under the terms of the GNU General Public
License as distributed with Emacs (press C-h C-c for details).

Copyright (C) 1986, 1987, 1988, 1989, 1990, 1991, 1992, 1993, 1994,
    1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
    2006, 2007, 2008, 2009, 2010, 2011, 2012 Massachusetts Institute
    of Technology

This file is part of MIT/GNU Scheme.

MIT/GNU Scheme is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

MIT/GNU Scheme is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with MIT/GNU Scheme; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301,
USA.

|#

;;;; SWANK module for MIT/GNU Scheme
;;; package: (runtime swank)

;;; Suggested for .emacs:
#|
\(when (require 'slime nil t)

  (defun mit-scheme-start-swank (file encoding)
    (format "%S\n\n" `(start-swank ,file)))

  (defun mit-scheme-find-buffer-package ()
    (save-excursion
      (let ((case-fold-search t))
	(goto-char (point-min))
	(and (re-search-forward "^;+ package: \\(([^)]+)\\)" nil t)
	     (match-string-no-properties 1)))))

  (defun mit-scheme-slime-mode-init ()
    (slime-mode t)
    (make-local-variable 'slime-find-buffer-package-function)
    (setq slime-find-buffer-package-function 'mit-scheme-find-buffer-package))

  (slime-setup)
  (if (not (memq 'mit-scheme slime-lisp-implementations))
      (setq slime-lisp-implementations
	    (cons '(mit-scheme ("mit-scheme")
			       :init mit-scheme-start-swank)
		  slime-lisp-implementations)))
  (setq slime-default-lisp 'mit-scheme)
  (add-hook 'scheme-mode-hook 'mit-scheme-slime-mode-init))
|#

(declare (usual-integrations))

(define (start-swank #!optional port-file)
  (let ((port-number 4005)
	(socket))
    (dynamic-wind
	(lambda ()
	  (set! socket
		(open-tcp-server-socket port-number
					(host-address-loopback)))
	  unspecific)
	(lambda ()
	  (if (not (default-object? port-file))
	      (call-with-output-file port-file
		(lambda (p)
		  (write port-number p))))
	  (serve (tcp-server-connection-accept socket #t #f)))
	(lambda ()
	  (close-tcp-server-socket socket)
	  (set! socket)
	  unspecific))))

(define (serve socket)
  (with-simple-restart 'DISCONNECT "Close connection."
    (lambda ()
      (with-keyboard-interrupt-handler
       (lambda ()
	 (main-loop socket))))))

(define (with-keyboard-interrupt-handler thunk)
  (let ((index (char->integer #\G))
	(new-handler
	 (lambda (char)
	   char
	   (with-simple-restart 'CONTINUE "Continue from interrupt."
	     (lambda ()
	       (error "Keyboard Interrupt.")))))
	(old-handler))
    (dynamic-wind
	(lambda ()
	  (let ((v keyboard-interrupt-vector))
	    (set! old-handler (vector-ref v index))
	    (vector-set! v index new-handler)))
	thunk
	(lambda ()
	  (vector-set! keyboard-interrupt-vector index old-handler)
	  (set! old-handler)
	  unspecific))))

(define (disconnect)
  (invoke-restart (find-restart 'DISCONNECT)))

(define (main-loop socket)
  (do () (#f)
    (with-simple-restart 'ABORT "Return to SLIME top-level."
      (lambda ()
	(fluid-let ((*top-level-restart* (find-restart 'ABORT)))
	  (process-one-message socket 0))))))

(define *top-level-restart*)

(define (get-current-environment)
  (nearest-repl/environment))

(define (set-current-environment! environment)
  (set-repl/environment! (nearest-repl) environment))

(define (top-level-abort)
  (invoke-restart *top-level-restart*))

(define (bound-restarts-for-emacs)
  (let loop ((restarts (bound-restarts)))
    (if (pair? restarts)
	(cons (car restarts)
	      (if (eq? (car restarts) *top-level-restart*)
		  '()
		  (loop (cdr restarts))))
	'())))

(define (process-one-message socket level)
  (dispatch (decode-message socket (read-packet socket)) socket level))

(define (read-packet in)
  (if (eof-object? (peek-char in))
      (disconnect))
  (let ((buffer
	 (make-string
	  (let ((buffer (make-string 6)))
	    (read-string! buffer in)
	    (string->number buffer 16 #t)))))
    (read-string! buffer in)
    buffer))

(define (decode-message socket packet)
  (bind-condition-handler (list condition-type:serious-condition)
      (lambda (condition)
	(write-message `(:reader-error ,packet
				       ,(condition/report-string condition))
		       socket)
	(top-level-abort))
    (lambda ()
      (read-from-string packet))))

(define (write-message message out)
  (write-packet (write-to-string message) out))

(define (write-packet packet out)
  (let ((s (number->string (string-length packet) 16)))
    (if (> (string-length s) 6)
	(error "Expression length exceeds 24 bits:" s))
    (write-string (string-pad-left s 6 #\0) out))
  (write-string packet out)
  (flush-output out))

(define (dispatch message socket level)
  (let ((p
	 (find (lambda (p)
		 (syntax-match? (car p) message))
	       message-handlers)))
    (if (not p)
	(error "Unknown message:" message))
    (apply (cdr p) socket level (cdr message))))

(define (define-message-handler pattern handler)
  (set! message-handlers
	(cons (cons pattern handler)
	      message-handlers))
  unspecific)

(define message-handlers '())

;;;; Message handlers

(define-message-handler '(':emacs-rex form datum datum index)
  (lambda (socket level sexp pstring thread id)
    thread
    (call-with-current-continuation
     (lambda (k)
       (bind-condition-handler (list condition-type:serious-condition)
	   (lambda (condition)
	     (invoke-sldb socket (+ level 1) condition)
	     (write-message `(:return (:abort) ,id) socket)
	     (k unspecific))
	 (lambda ()
	   (write-message `(:return (:ok ,(emacs-rex socket sexp pstring))
				    ,id)
			  socket)))))))

(define (emacs-rex socket sexp pstring)
  (fluid-let ((*buffer-pstring* pstring))
    (eval (cons* (car sexp) socket (cdr sexp))
	  swank-env)))

(define *buffer-pstring*)

(define swank-env
  (the-environment))

(define (buffer-env)
  (pstring->env *buffer-pstring*))

(define (pstring->env pstring)
  (cond ((or (not (string? pstring))
	     (not (string? *buffer-pstring*))
	     (string-ci=? *buffer-pstring* "COMMON-LISP-USER"))
	 (get-current-environment))
	((string-prefix? anonymous-package-prefix pstring)
	 (let ((object
		(object-unhash
		 (string->number (string-tail pstring
					      (string-length
					       anonymous-package-prefix))
				 10
				 #t))))
	   (if (not (environment? object))
	       (error:wrong-type-datum object "environment"))
	   object))
	(else
	 (package/environment (find-package (read-from-string pstring) #t)))))

(define (env->pstring env)
  (let ((package (environment->package env)))
    (if package
	(write-to-string (package/name package))
	(string anonymous-package-prefix (object-hash env)))))

(define anonymous-package-prefix
  "environment-")

;;;; Evaluation

(define (swank:interactive-eval socket string)
  (interactive-eval (read-from-string string) socket #f))

(define (swank:interactive-eval-region socket string)
  (for-each-sexp (lambda (sexp) (interactive-eval sexp socket #f))
		 string))

(define (swank:listener-eval socket string)
  (write-message `(:write-string ,(interactive-eval (read-from-string string)
						    socket
						    #t)
				 :repl-result)
		 socket)
  'NIL)

(define (interactive-eval sexp socket nl?)
  (let ((value (repl-eval sexp socket)))
    (call-with-output-string
      (lambda (port)
	(port/write-result port sexp value (object-hash value) (buffer-env))
	(if nl? (newline port))))))

(define (for-each-sexp procedure string)
  (let ((input (open-input-string string)))
    (let loop ()
      (let ((sexp (read input)))
	(if (not (eof-object? sexp))
	    (begin
	      (procedure sexp)
	      (loop)))))))

(define (repl-eval sexp socket)
  (with-output-to-repl socket
    (lambda ()
      (with-repl-eval-boundary 'SWANK
	(lambda ()
	  (eval sexp (buffer-env)))))))

(define (with-output-to-repl socket thunk)
  (let ((p (make-port repl-port-type socket)))
    (dynamic-wind
	(lambda () unspecific)
	(lambda () (with-output-to-port p thunk))
	(lambda () (flush-output p)))))

(define repl-port-type)
(define (initialize-package!)
  (set! repl-port-type
	(make-port-type
	 `((WRITE-CHAR
	    ,(lambda (port char)
	       (write-message `(:write-string ,(string char))
			      (port/state port))
	       1))
	   (WRITE-SUBSTRING
	    ,(lambda (port string start end)
	       (if (< start end)
		   (write-message `(:write-string ,(substring string start end))
				  (port/state port)))
	       (- end start))))
	 #f))
  unspecific)

(define (swank:pprint-eval socket string)
  socket
  (pprint-to-string (eval (read-from-string string)
			  (buffer-env))))

;;;; Compilation

(define (swank:compile-string-for-emacs socket string . x)
  socket x
  (let ((sexps (snarf-string string)))
    (call-compiler
     (lambda ()
       (let ((env (buffer-env)))
	 (scode-eval (compile-scode (syntax `(begin ,@sexps) env) #t)
		     env))))))

(define (snarf-string string)
  (let ((port (open-input-string string)))
    (let loop ()
      (let ((e (read port)))
	(if (eof-object? e)
	    '()
	    (cons e (loop)))))))

(define (call-compiler fun)
  (let ((time #f))
    (with-timings fun
      (lambda (run-time gc-time real-time)
	run-time gc-time
	(set! time real-time)
	unspecific))
    (list 'NIL (string (internal-time/ticks->seconds time)))))

(define (swank:compile-file-for-emacs socket file load?)
  (call-compiler
   (lambda ()
     (with-output-to-repl socket
       (lambda ()
	 (compile-file file)))))
  (if (elisp-true? load?)
      (swank:load-file socket
		       (pathname-new-type file "com"))))

(define (swank:load-file socket file)
  (with-output-to-repl socket
    (lambda ()
      (load file (buffer-env)))))

(define (swank:disassemble-symbol socket string)
  socket
  (with-output-to-string
    (lambda ()
      (compiler:disassemble
       (eval (read-from-string string)
	     (buffer-env))))))

;;;; Miscellaneous

(define (swank:set-package socket pstring)
  socket
  (let ((env (pstring->env pstring)))
    (set-current-environment! env)
    (let ((pstring (env->pstring env)))
      (list pstring pstring))))

(define (swank:create-repl socket . args)
  socket args
  (let ((pstring (env->pstring (make-top-level-environment))))
    (list pstring pstring)))

(define (swank:swank-macroexpand-all socket string)
  socket
  (with-output-to-string
    (lambda ()
      (pp (syntax (read-from-string string)
		  (buffer-env))))))

(define swank:swank-macroexpand-1 swank:swank-macroexpand-all)
(define swank:swank-macroexpand swank:swank-macroexpand-all)

(define (swank:operator-arglist socket name pstring)
  socket
  (let ((v (ignore-errors
	    (lambda ()
	      (with-output-to-string
		(lambda ()
		  (carefully-pa
		   (eval (read-from-string name) (pstring->env pstring)))))))))
    (if (condition? v) 'NIL v)))

(define (carefully-pa o)
  (cond ((arity-dispatched-procedure? o)
	 ;; MIT Scheme crashes for (pa /)
	 (display "arity-dispatched-procedure"))
	((procedure? o) (pa o))
	(else (error "Not a procedure"))))

(define (swank:connection-info socket)
  socket
  (let ((pstring (env->pstring (buffer-env))))
    `(:pid ,(unix/current-pid)
      :package (:name ,pstring :prompt ,pstring)
      :lisp-implementation
      (:type "MIT/GNU Scheme"
       :version ,(get-subsystem-version-string "release"))
      :version "20100404")))

(define (swank:quit-lisp socket)
  socket
  (%exit))

;;;; Some unimplemented stuff.

(define (swank:buffer-first-change socket filename)
  socket filename
  'NIL)

;; M-. is beyond my capabilities.
(define (swank:find-definitions-for-emacs socket name)
  socket name
  'NIL)

#|
;;; List of names obtained by grepping through "slime.el" and
;;; "slime-repl.el".

swank:commit-edited-value
swank:compile-file-if-needed
swank:compile-multiple-strings-for-emacs
swank:create-server
swank:debug-nth-thread
swank:default-directory
swank:describe-definition-for-emacs
swank:describe-function
swank:describe-inspectee
swank:describe-symbol
swank:documentation-symbol
swank:eval-and-grab-output
swank:eval-string-in-frame
swank:find-source-location-for-emacs
swank:frame-source-location
swank:inspect-current-condition
swank:inspect-in-frame
swank:inspector-nth-part
swank:inspector-reinspect
swank:inspector-toggle-verbose
swank:io-speed-test
swank:kill-nth-thread
swank:list-threads
swank:pprint-eval-string-in-frame
swank:pprint-inspector-part
swank:profile-package
swank:profile-report
swank:profile-reset
swank:profiled-functions
swank:quit-thread-browser
swank:re-evaluate-defvar
swank:redirect-trace-output
swank:restart-frame
swank:set-default-directory
swank:sldb-break
swank:sldb-break-on-return
swank:sldb-break-with-default-debugger
swank:sldb-disassemble
swank:sldb-next
swank:sldb-out
swank:sldb-return-from-frame
swank:sldb-step
swank:start-server
swank:start-swank-server-in-thread
swank:swank-compiler-macroexpand
swank:swank-compiler-macroexpand-1
swank:swank-format-string-expand
swank:swank-require
swank:swank-toggle-trace
swank:toggle-profile-fdefinition
swank:undefine-function
swank:unprofile-all
swank:untrace-all
swank:update-indentation-information
swank:value-for-editing
swank:xref
|#

;;;; Debugger

(define-structure (sldb-state (conc-name sldb-state.))
  condition
  restarts)

(define *sldb-state* #f)

(define (invoke-sldb socket level condition)
  (fluid-let ((*sldb-state*
	       (make-sldb-state condition (bound-restarts-for-emacs))))
    (dynamic-wind
	(lambda () #f)
	(lambda ()
	  (write-message `(:debug 0 ,level ,@(sldb-info *sldb-state* 0 20))
			 socket)
	  (sldb-loop level socket))
	(lambda ()
	  (write-message `(:debug-return 0 ,(- level 1) 'NIL) socket)))))

(define (sldb-loop level socket)
  (write-message `(:debug-activate 0 ,level) socket)
  (with-simple-restart 'ABORT (string "Return to SLDB level " level ".")
    (lambda ()
      (process-one-message socket level)))
  (sldb-loop level socket))

(define (sldb-info state start end)
  (let ((c (sldb-state.condition state))
	(rs (sldb-state.restarts state)))
    (list (list (condition/report-string c)
		(string "  [" (condition-type/name (condition/type c)) "]")
		'NIL)
	  (sldb-restarts rs)
	  (sldb-backtrace c start end)
	  ;;'((0 "dummy frame"))
	  '())))

(define (sldb-restarts restarts)
  (map (lambda (r)
	 (list (symbol->string (restart/name r))
	       (with-string-output-port
		(lambda (p) (write-restart-report r p)))))
       restarts))

(define (swank:throw-to-toplevel socket . args)
  socket args
  (top-level-abort))

(define (swank:sldb-abort socket . args)
  socket args
  (abort (sldb-state.restarts *sldb-state*)))

(define (swank:sldb-continue socket . args)
  socket args
  (continue (sldb-state.restarts *sldb-state*)))

(define (swank:invoke-nth-restart-for-emacs socket sldb-level n)
  socket sldb-level
  (invoke-restart (list-ref (sldb-state.restarts *sldb-state*) n)))

(define (swank:debugger-info-for-emacs socket from to)
  socket
  (sldb-info *sldb-state* from to))

(define (swank:backtrace socket from to)
  socket
  (sldb-backtrace (sldb-state.condition *sldb-state*) from to))

(define (sldb-backtrace condition from to)
  (sldb-backtrace-aux (condition/continuation condition) from to))

(define (sldb-backtrace-aux k from to)
  (let ((l (map frame->string (substream (continuation->frames k) from to))))
    (let loop ((i from) (l l))
      (if (null? l)
	  '()
	  (cons (list i (car l)) (loop (+ i 1) (cdr l)))))))

;; Stack parser fails for this:
;; (map (lambda (x) x) "/tmp/x.x")

(define (continuation->frames k)
  (let loop ((frame (continuation->stack-frame k)))
    (if (or (not frame)
	    (stack-frame/repl-eval-boundary? frame))
	(stream)
	(cons-stream frame
		     (let ((next
			    (ignore-errors
			     (lambda ()
			       (stack-frame/next-subproblem frame)))))
		       (if (condition? next)
			   (stream next)
			   (loop next)))))))

(define (frame->string frame)
  (if (condition? frame)
      (string "Bogus frame: " frame
	      " " (condition/report-string frame))
      (call-with-output-string (lambda (p) (print-frame frame p)))))

(define (print-frame frame port)
  (receive (expression environment subexpression)
      (stack-frame/debugging-info frame)
    environment
    (cond ((debugging-info/compiled-code? expression)
	   (write-string ";unknown compiled code" port))
	  ((not (debugging-info/undefined-expression? expression))
	   (fluid-let ((*unparse-primitives-by-name?* #t))
	     (write
	      (unsyntax
	       (if (or (debugging-info/undefined-expression? subexpression)
		       (debugging-info/unknown-expression? subexpression))
		   expression
		   subexpression))
	      port)))
	  ((debugging-info/noise? expression)
	   (write-string ";" port)
	   (write-string ((debugging-info/noise expression) #f)
			 port))
	  (else
	   (write-string ";undefined expression" port)))))

(define (substream s from to)
  (let loop ((i 0) (l '()) (s s))
    (cond ((or (= i to) (stream-null? s)) (reverse l))
	  ((< i from) (loop (+ i 1) l (stream-cdr s)))
	  (else (loop (+ i 1) (cons (stream-car s) l) (stream-cdr s))))))

(define (swank:frame-locals-and-catch-tags socket frame)
  socket
  (list (map frame-var>elisp (frame-vars (sldb-get-frame frame)))
	'()))

(define (frame-vars frame)
  (receive (expression environment subexpression)
      (stack-frame/debugging-info frame)
    expression subexpression
    (if (environment? environment)
	(environment>frame-vars environment)
	'())))

(define (environment>frame-vars environment)
  (let loop ((e environment))
    (if (top-level-environment? e)
	'()
	(append (environment-bindings e)
		(if (environment-has-parent? e)
		    (loop (environment-parent e))
		    '())))))

(define (frame-var>elisp b)
  (list ':name (write-to-string (car b))
	':value (cond ((null? (cdr b)) "{unavailable}")
		      (else (->line (cadr b))))
	':id 0))

(define (sldb-get-frame index)
  (stream-ref (continuation->frames
	       (condition/continuation
		(sldb-state.condition *sldb-state*)))
	      index))

(define (frame-var-value frame var)
  (let ((binding (list-ref (frame-vars frame) var)))
    (cond ((cdr binding) (cadr binding))
	  (else unspecific))))

(define (swank:inspect-frame-var socket frame var)
  socket
  (reset-inspector)
  (inspect-object (frame-var-value (sldb-get-frame frame) var)))

;;;; Completion

(define (swank:simple-completions socket string pstring)
  socket
  (let ((strings (all-completions string (pstring->env pstring))))
    (list (sort strings string<?)
	  (longest-common-prefix strings))))

(define (all-completions prefix environment)
  (let ((prefix
	 (if (environment-lookup environment '*PARSER-CANONICALIZE-SYMBOLS?*)
	     (string-downcase prefix)
	     prefix))
	(completions '()))
    (for-each-interned-symbol
     (lambda (symbol)
       (if (and (string-prefix? prefix (symbol-name symbol))
		(environment-bound? environment symbol))
	   (set! completions (cons (symbol-name symbol) completions)))
       unspecific))
    completions))

(define (longest-common-prefix strings)
  (reduce (lambda (s1 s2)
	    (substring s1 0 (string-match-forward s1 s2)))
	  ""
	  strings))

;;;; Apropos

(define (swank:apropos-list-for-emacs socket text external-only? case-sensitive?
				      pstring)
  socket case-sensitive?
  (let ((env
	 (if (elisp-true? external-only?)
	     system-global-environment
	     (pstring->env pstring))))
    (map (lambda (symbol)
	   `((:designator ,(string symbol " " pstring))
	     ,@(case (environment-reference-type env symbol)
		 ((UNBOUND) '())
		 ((UNASSIGNED) `((:variable nil)))
		 ((MACRO) `((:macro nil)))
		 (else
		  (let ((v (environment-lookup env symbol)))
		    `((,(cond ((generic-procedure? v) ':generic-function)
			      ((procedure? v) ':function)
			      (else ':variable))
		       ,v)))))))
	 (apropos-list text env #t))))

(define (swank:list-all-package-names socket . args)
  socket args
  (map (lambda (package) (env->pstring (package/environment package)))
       (all-packages)))

(define (all-packages)
  (let loop ((package system-global-package))
    (cons package
	  (append-map loop (package/children package)))))

;;;; Inspector

(define-record-type <istate>
    (make-istate object parts next previous content)
    istate?
  (object istate-object)
  (parts istate-parts)
  (next istate-next set-istate-next!)
  (previous istate-previous)
  (content istate-content))

(define istate #f)

(define (reset-inspector)
  (set! istate #f)
  unspecific)

(define (swank:init-inspector socket string)
  socket
  (reset-inspector)
  (inspect-object (eval (read-from-string string)
			(buffer-env))))

(define (inspect-object o)
  (let ((previous istate)
	(content (inspect o))
	(parts (make-strong-eqv-hash-table)))
    (set! istate (make-istate o parts #f previous content))
    (if previous (set-istate-next! previous istate))
    (istate->elisp istate)))

(define (istate->elisp istate)
  `(:title ,(->line (istate-object istate))
    :id ,(assign-index (istate-object istate) (istate-parts istate))
    :content ,(prepare-range (istate-parts istate)
			     (istate-content istate)
			     0 500)))

(define (assign-index o parts)
  (let ((i (hash-table/count parts)))
    (hash-table/put! parts i o)
    i))

(define (prepare-range parts content from to)
  (let* ((cs (substream content from to))
	 (ps (prepare-parts cs parts)))
    (list ps
	  (if (< (length cs) (- to from))
	      (+ from (length cs))
	      (+ to 1000))
	  from to)))

(define (prepare-parts ps parts)
  (define (line label value)
    `(,(string label ": ")
      (:value ,(->line value) ,(assign-index value parts))
      "\n"))
  (append-map (lambda (p)
		(cond ((string? p) (list p))
		      ((symbol? p) (list (symbol->string p)))
		      (else
		       (case (car p)
			 ((line) (apply line (cdr p)))
			 (else (error "Invalid part:" p))))))
	      ps))

(define (swank:inspect-nth-part socket index)
  socket
  (inspect-object (hash-table/get (istate-parts istate) index 'no-such-part)))

(define (swank:quit-inspector socket)
  socket
  (reset-inspector))

(define (swank:inspector-pop socket)
  socket
  (cond ((istate-previous istate)
	 (set! istate (istate-previous istate))
	 (istate->elisp istate))
	(else 'NIL)))

(define (swank:inspector-next socket)
  socket
  (cond ((istate-next istate)
	 (set! istate (istate-next istate))
	 (istate->elisp istate))
	(else 'NIL)))

(define (swank:inspector-range socket from to)
  socket
  (prepare-range (istate-parts istate)
		 (istate-content istate)
		 from to))

(define (iline label value)
  `(LINE ,label ,value))

(define (inspect o)
  (cond ((environment? o) (inspect-environment o))
	((vector? o) (inspect-vector o))
	((procedure? o) (inspect-procedure o))
	((compiled-code-block? o) (inspect-code-block o))
	((pair? o) (inspect-pair o))
	;;((system-pair? o) (inspect-system-pair o))
	((probably-scode? o) (inspect-scode o))
	(else (inspect-fallback o))))

(define (inspect-fallback o)
  (cons-stream (iline "Object" o)
	       (stream)))

#;
(define (inspect-fallback o)
  (let* ((class (object-class o))
	 (slots (class-slots class)))
    (cons-stream (iline "Class" class)
		 (let loop ((slots slots))
		   (if (pair? slots)
		       (let ((n (slot-name (car slots))))
			 (cons-stream (iline n (slot-value o n))
				      (loop (cdr slots))))
		       (stream))))))

(define (inspect-pair pair)
  (if (or (pair? (cdr pair))
	  (null? (cdr pair)))
      (let loop ((l1 pair) (l2 pair) (i 0))
	(cond ((pair? l1)
	       (cons-stream (iline i (car l1))
			    (let ((l1 (cdr l1)))
			      (if (eq? l1 l2)
				  (stream "{circular list detected}")
				  (loop l1
					(if (odd? i) (cdr l2) l2)
					(+ i 1))))))
	      ((null? l1) (stream))
	      (else (stream (iline "tail" (cdr l1))))))
      (stream (iline "car" (car pair))
	      (iline "cdr" (cdr pair)))))

(define (inspect-environment env)
  (let ((package (environment->package env))
	(tail
	 (let loop ((bindings (environment-bindings env)))
	   (if (pair? bindings)
	       (cons-stream (let ((binding (car bindings)))
			      (iline (car binding)
				     (if (pair? (cdr binding))
					 (cadr binding)
					 (string "{"
						 (environment-reference-type
						  env
						  (car binding))
						 "}"))))
			    (loop (cdr bindings)))
	       (if (environment-has-parent? env)
		   (stream (iline "(<parent>)" (environment-parent env)))
		   (stream))))))
    (if package
	(cons-stream (iline "(package)" package) tail)
	tail)))

(define (inspect-vector o)
  (let ((len (vector-length o)))
    (let loop ((i 0))
      (if (< i len)
	  (cons-stream (iline i (vector-ref o i))
		       (loop (+ i 1)))
	  (stream)))))

(define (inspect-procedure o)
  (cond ((primitive-procedure? o)
	 (stream (iline "name" (primitive-procedure-name o))
		 (iline "arity" (primitive-procedure-arity o))
		 (iline "doc" (primitive-procedure-documentation o))))
	((compound-procedure? o)
	 (stream (iline "arity" (procedure-arity o))
		 (iline "lambda" (procedure-lambda o))
		 (iline "env" (ignore-errors
			       (lambda () (procedure-environment o))))))
	(else
	 (stream (iline "block" (compiled-entry/block o))
		 (with-output-to-string
		   (lambda ()
		     (compiler:disassemble o)))))))

(define (inspect-code-block block)
  (let loop ((i (compiled-code-block/constants-start block)))
    (if (< i (compiled-code-block/constants-end block))
	(cons-stream (iline i (system-vector-ref block i))
		     (loop (+ i compiled-code-block/bytes-per-object)))
	(stream (iline "debuginfo" (compiled-code-block/debugging-info block))
		(iline "env" (compiled-code-block/environment block))
		(with-output-to-string
		  (lambda ()
		    (compiler:disassemble block)))))))

(define (inspect-scode o)
  (stream (pprint-to-string o)))

(define (probably-scode? o)
  (any (lambda (predicate) (predicate o))
       scode-predicates))

(define scode-predicates
  (list access? assignment? combination? comment?
	conditional? definition? delay? disjunction? lambda?
	quotation? sequence? the-environment? variable?))

(define (inspect-system-pair o)
  (stream (iline "car" (system-pair-car o))
	  (iline "cdr" (system-pair-cdr o))))

;;;; Auxilary functions

(define (elisp-false? o) (or (null? o) (eq? o 'NIL)))
(define (elisp-true? o) (not (elisp-false? o)))

(define nil '())
(define t 'T)

(define (->line o)
  (let ((r (write-to-string o 100)))
    (if (car r)
	(string-append (cdr r) " ..")
	(cdr r))))

(define (read-from-string s)
  (read (open-input-string s)))

(define (pprint-to-string o)
  (call-with-output-string
    (lambda (p)
      (fluid-let ((*unparser-list-breadth-limit* 10)
		  (*unparser-list-depth-limit* 4)
		  (*unparser-string-length-limit* 100))
	(pp o p)))))