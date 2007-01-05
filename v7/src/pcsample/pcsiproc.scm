#| -*-Scheme-*-

$Id: pcsiproc.scm,v 1.5 2007/01/05 15:33:09 cph Exp $

Copyright (c) 1993, 1999 Massachusetts Institute of Technology

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

;;;; PC Sampling Interp-Procs (i.e., interpreted procedure profiling)
;;; package: (pc-sample interp-procs)

(declare (usual-integrations))

;;; Interp-Procs (interpreted procedures) are profiled by recording profiling
;;; info about their associated procedure-lambdas. The reason the procedure
;;; lambda is used rather than the full procedure object (lambda + environment)
;;; is we want various dynamic activations of the same lambda to be identified.
;;; Were we to hash off the procedure object rather than just its lambda, these
;;; dynamic invocation instances would be distinguished since their associated
;;; envs would (normally) be distinguishable.
;;;
;;; An interesting issue arises when considering generated procedures,
;;; especially those such as would be generated by the canonical MAKE-COUNTER
;;; proc below:
;;;
;;; (define (make-counter)
;;;   (let ((count -1))
;;;     (lambda (msg)
;;;       (case msg
;;;         ((NEXT)  (set! count (1+ count)) count)
;;;         ((RESET) (set! count -1        ) count)
;;;        ))))
;;;
;;; (define a (make-counter))
;;; (define b (make-counter))
;;;
;;; At the time of creation of this facility (1993.03.31.04.02.01), under such
;;; an arrangement, the procedures A and B would share procedure lambdas so,
;;; for purposes of profiling them while interpreted, they would be indistin-
;;; guishable. To wit, time spent in either A or B would be attributed as time
;;; spent in the ``A-or-B'' procedure.
;;;
;;; The obvious alternative is to profile interpreted procedures by their full
;;; procedure object (lambda + environment). Under this approach, A and B
;;; would indeed be distinguishable. Unfortunately, so too would any two
;;; activations of the same procedure. This is clearly untenable for purposes
;;; of collecting useable profiling information. ???

(define (initialize-package!)
  (set! *interp-proc-profile-table* (interp-proc-profile-table/make))
  ;; microlevel buffer install
  (install-interp-proc-profile-buffer/length)
  )

(define-primitives
  (interp-proc-profile-buffer/empty?                0)
  (interp-proc-profile-buffer/next-empty-slot-index 0)
  (interp-proc-profile-buffer/slack           0)
  (interp-proc-profile-buffer/slack-increment 0)
  (interp-proc-profile-buffer/set-slack           1)
  (interp-proc-profile-buffer/set-slack-increment 1)
  (interp-proc-profile-buffer/extend-noisy?   0)
  (interp-proc-profile-buffer/flush-noisy?    0)
  (interp-proc-profile-buffer/overflow-noisy? 0)
  (interp-proc-profile-buffer/extend-noisy?/toggle!   0)
  (interp-proc-profile-buffer/flush-noisy?/toggle!    0)
  (interp-proc-profile-buffer/overflow-noisy?/toggle! 0)
  #|
  (interp-proc-profile-buffer/with-extend-notification!   0)
  (interp-proc-profile-buffer/with-flush-notification!    0)
  (interp-proc-profile-buffer/with-overflow-notification! 0)
  |#
  ;; microcode magic: don't look. Fnord!
  (%pc-sample/IPPB-overflow-count       0)
  (%pc-sample/IPPB-overflow-count/reset 0)
  (%pc-sample/IPPB-monitoring?         0)
  (%pc-sample/IPPB-monitoring?/toggle! 0)
  )

(define (profile-buffer/with-mumble-notification!     noise? thunk
						  x/f-noisy? toggle-noise!)
  (let ((already-noisy? (x/f-noisy?))
	(want-no-noise? (not noise?)))		; coerce to Boolean
    (if (eq? already-noisy? want-no-noise?) 	; xor want and got
	(dynamic-wind toggle-noise! thunk toggle-noise!)
	(thunk))))

(define (interp-proc-profile-buffer/with-extend-notification!	noise? thunk)
  (profile-buffer/with-mumble-notification!			noise? thunk
	 interp-proc-profile-buffer/extend-noisy?
	 interp-proc-profile-buffer/extend-noisy?/toggle!))

(define (interp-proc-profile-buffer/with-flush-notification!	noise? thunk)
  (profile-buffer/with-mumble-notification!			noise? thunk
	 interp-proc-profile-buffer/flush-noisy?
	 interp-proc-profile-buffer/flush-noisy?/toggle!))

(define (interp-proc-profile-buffer/with-overflow-notification! noise? thunk)
  (profile-buffer/with-mumble-notification!			noise? thunk
	 interp-proc-profile-buffer/overflow-noisy?
	 interp-proc-profile-buffer/overflow-noisy?/toggle!))

;;; Interp-Proc Profile Buffer is to buffer up sightings of interpreted procs
;;;   that are not yet hashed into the Interp-Proc Profile (Hash) Table

(define *interp-proc-profile-buffer* #F) ; software cache of fixed obj Ntry

(define (interp-proc-profiling-disabled?)
  (not  *interp-proc-profile-buffer*))

(define *interp-proc-profile-buffer/length/initial*)

(define (install-interp-proc-profile-buffer/length/initial)
  (set!         *interp-proc-profile-buffer/length/initial*
	  (*  4 (interp-proc-profile-buffer/slack))))

(define *interp-proc-profile-buffer/length*)

(define (install-interp-proc-profile-buffer/length)
  (      install-interp-proc-profile-buffer/length/initial)
  (set!         *interp-proc-profile-buffer/length*
		*interp-proc-profile-buffer/length/initial*))

(define (interp-proc-profile-buffer/length)
        *interp-proc-profile-buffer/length*)
(define (interp-proc-profile-buffer/length/set! new-value)
  (set! *interp-proc-profile-buffer/length*     new-value))

(define (interp-proc-profile-buffer/status)
  "()\n\
  Returns a CONS pair of the length and `slack' of the\n\
  interpreted procedure profile buffer.\
  "
  (cons (interp-proc-profile-buffer/length)
	(interp-proc-profile-buffer/slack)))

(define *interp-proc-profile-buffer/status/old* '(0 . 0))
(define (interp-proc-profile-buffer/status/previous)
  "()\n\
   Returns the status of the profile buffer before the last modification to\n\
   its length and/or slack.\
  "
        *interp-proc-profile-buffer/status/old*)

;;; TODO: flush/reset/spill/extend should all employ double buffering of the
;;;       interp-proc profile buffer.

(define            *interp-proc-profile-buffer/extend-count?* #F)
(define-integrable (interp-proc-profile-buffer/extend-count?)
                   *interp-proc-profile-buffer/extend-count?*)
(define-integrable (interp-proc-profile-buffer/extend-count?/toggle!)
  (set!            *interp-proc-profile-buffer/extend-count?*
	      (not *interp-proc-profile-buffer/extend-count?*)))
(define            (interp-proc-profile-buffer/with-extend-count! count?
								  thunk)
  (fluid-let     ((*interp-proc-profile-buffer/extend-count?*     count?))
    (thunk)))
(define		   *interp-proc-profile-buffer/extend-count* 0)
(define-integrable (interp-proc-profile-buffer/extend-count)
		   *interp-proc-profile-buffer/extend-count*)
(define-integrable (interp-proc-profile-buffer/extend-count/reset)
  (set!		   *interp-proc-profile-buffer/extend-count* 0))
(define-integrable (interp-proc-profile-buffer/extend-count/1+)
  (set!		   *interp-proc-profile-buffer/extend-count*
	       (1+ *interp-proc-profile-buffer/extend-count*)))

(define (interp-proc-profile-buffer/extend)
  (let ((stop/restart-sampler? (and (not *pc-sample/sample-sampler?*)
				    (pc-sample/started?))))
    ;; stop if need be
    (cond (stop/restart-sampler? (fluid-let ((*pc-sample/noisy?* #F))
				   (pc-sample/stop))))
    ;; count if willed to
    (cond ((interp-proc-profile-buffer/extend-count?)
	   (interp-proc-profile-buffer/extend-count/1+)))
    ;; No need to disable during extend since we build an extended copy of the
    ;;  buffer then install it in one swell foop...
    ;; Of course, any interp-proc samples made during the extend will be punted.
    ;; For this reason, we go ahead and disable interp-proc buffering anyway
    ;;  since it would be a waste of time.
    (fixed-interp-proc-profile-buffer/disable)
    (cond ((interp-proc-profile-buffer/extend-noisy?)
	   (with-output-to-port console-output-port ; in case we're in Edwin
	     (lambda ()
	       (display "\n;> > > > >  IPPB Extend Request being serviced.")))
	   (output-port/flush-output console-output-port)))
    (let* ((slack             (interp-proc-profile-buffer/slack) )
	   (old-buffer-length (interp-proc-profile-buffer/length))
	   (new-buffer-length (+ old-buffer-length slack)    )
	   (new-buffer (vector-grow *interp-proc-profile-buffer*
				    new-buffer-length)))
      ;; maintain invariant: unused slots of interp-proc-profile-buffer = #F
      (do ((index   old-buffer-length  (1+ index)))
	  ((= index new-buffer-length))
	(vector-set! new-buffer index #F))
      ;; Intall new-buffer...
      (set! *interp-proc-profile-buffer* new-buffer)
      ;; synch length cache
      (interp-proc-profile-buffer/length/set! new-buffer-length))
    ;; Re-enable: synch kludge... one swell foop
    (fixed-interp-proc-profile-buffer/install *interp-proc-profile-buffer*)
    ;; restart if need be
    (cond (stop/restart-sampler? (fluid-let ((*pc-sample/noisy?* #F))
				   (pc-sample/start)))))
  unspecific)

(define            *interp-proc-profile-buffer/flush-count?* #F)
(define-integrable (interp-proc-profile-buffer/flush-count?)
                   *interp-proc-profile-buffer/flush-count?*)
(define-integrable (interp-proc-profile-buffer/flush-count?/toggle!)
  (set!            *interp-proc-profile-buffer/flush-count?*
	      (not *interp-proc-profile-buffer/flush-count?*)))
(define            (interp-proc-profile-buffer/with-flush-count! count?
								 thunk)
  (fluid-let     ((*interp-proc-profile-buffer/flush-count?*     count?))
    (thunk)))
(define		   *interp-proc-profile-buffer/flush-count* 0)
(define-integrable (interp-proc-profile-buffer/flush-count)
		   *interp-proc-profile-buffer/flush-count*)
(define-integrable (interp-proc-profile-buffer/flush-count/reset)
  (set!		   *interp-proc-profile-buffer/flush-count* 0))
(define-integrable (interp-proc-profile-buffer/flush-count/1+)
  (set!		   *interp-proc-profile-buffer/flush-count*
	       (1+ *interp-proc-profile-buffer/flush-count*)))

(define-integrable (interp-proc-profile-buffer/flush)
  (cond ((and *interp-proc-profile-buffer*	; not disabled
	      (interp-proc-profile-buffer/flush?))
	 (interp-proc-profile-buffer/spill-into-interp-proc-profile-table)))
  unspecific)

(define (interp-proc-profile-buffer/reset)
  ;; It is important to disable the buffer during reset so we don't have any
  ;;  random ignored samples dangling in the buffer.
  (let ((next-mt-slot-index
	 ;; Bletch: need to disable buffer but must sniff next-mt-slot-index
	 ;;         first, then must ensure nothing new is buffered.
	 (without-interrupts
	  (lambda () 
	    (let ((nmtsi (interp-proc-profile-buffer/next-empty-slot-index)))
	      ;; NB: No interrupts between LET rhs and following assignment
	      (fixed-interp-proc-profile-buffer/disable)
	      nmtsi)))))
    ;; It is useful to keep a global var as a handle on this object.
    (if *interp-proc-profile-buffer*	; initialized already so avoid CONS-ing
	(subvector-fill! *interp-proc-profile-buffer* 0 next-mt-slot-index #F)
	(set! *interp-proc-profile-buffer*
	      (pc-sample/interp-proc-buffer/make))))
  ;; Re-enable: synch kludge... one swell foop
  (fixed-interp-proc-profile-buffer/install *interp-proc-profile-buffer*)
  (cond ((pc-sample/uninitialized?)
	 (pc-sample/set-state! 'RESET)))
  'RESET)

(define (interp-proc-profile-buffer/flush?)
  (not  (interp-proc-profile-buffer/empty?)))

(define (interp-proc-profile-buffer/spill-into-interp-proc-profile-table)
  (let ((stop/restart-sampler? (and (not *pc-sample/sample-sampler?*)
				    (pc-sample/started?))))
    ;; stop if need be
    (cond (stop/restart-sampler? (fluid-let ((*pc-sample/noisy?* #F))
				   (pc-sample/stop))))
    ;; count if willed to
    (cond ((interp-proc-profile-buffer/flush-count?)
	   (interp-proc-profile-buffer/flush-count/1+)))
    ;; It is important to disable the buffer during spillage so we don't have
    ;;  any random ignored samples dangling in the buffer.
    (let ((next-mt-slot-index
	   ;; Bletch: need to disable buffer but must sniff next-mt-slot-index
	   ;;         first, then must ensure nothing new is buffered.
	   (without-interrupts
	    (lambda () 
	      (let ((nmtsi (interp-proc-profile-buffer/next-empty-slot-index)))
		;; NB: No interrupts between LET rhs and following assignment
		(fixed-interp-proc-profile-buffer/disable)
		nmtsi)))))
      (cond ((interp-proc-profile-buffer/flush-noisy?)
	     (with-output-to-port console-output-port ; in case we're in Edwin
	       (lambda ()
		 (display "\n;> > > > >  IPPB Flush Request being serviced.")))
	     (output-port/flush-output console-output-port)))
      (do ((index 0 (1+ index)))
	  ((= index next-mt-slot-index))
	;; debuggery
	(cond ((not (vector-ref *interp-proc-profile-buffer* index))
	       (warn "Damn. Found a #F entry at index = " index)))
	;; copy from buffer into hash table
	(interp-proc-profile-table/hash-entry
         (vector-ref *interp-proc-profile-buffer* index))
	;; A rivederci, Baby
	(vector-set! *interp-proc-profile-buffer* index #F)
	))
  ;; Re-enable: synch kludge... one swell foop
  (fixed-interp-proc-profile-buffer/install *interp-proc-profile-buffer*)
  ;; restart if need be
  (cond (stop/restart-sampler? (fluid-let ((*pc-sample/noisy?* #F))
				 (pc-sample/start)))))
  unspecific)



(define-integrable (interp-proc-profile-buffer/overflow-count?)
                              (%pc-sample/IPPB-monitoring?))
(define-integrable (interp-proc-profile-buffer/overflow-count?/toggle!)
                              (%pc-sample/IPPB-monitoring?/toggle!))

(define (interp-proc-profile-buffer/with-overflow-count! count? thunk)
  (let ((counting?      (interp-proc-profile-buffer/overflow-count?))
	(want-no-count? (not count?)))	; coerce to Boolean
    (if (eq? counting? want-no-count?)	; xor want and got
	(dynamic-wind interp-proc-profile-buffer/overflow-count?/toggle!
		      thunk
		      interp-proc-profile-buffer/overflow-count?/toggle!)
	(thunk))))
	
(define-integrable (interp-proc-profile-buffer/overflow-count      )
                              (%pc-sample/IPPB-overflow-count      ))
(define-integrable (interp-proc-profile-buffer/overflow-count/reset)
                              (%pc-sample/IPPB-overflow-count/reset))

;;; Interp-Proc Profile (Hash) Table is where interpreted procs are profiled...
;;;   but the profile trap handler cannot CONS so if the current profiled
;;;   proc is not already hashed, we must buffer it in the Interp-Proc Profile
;;;   Buffer until the GC Daemon gets around to hashing it.    

(define *interp-proc-profile-table*)
(define (interp-proc-profile-table/make) (make-profile-hash-table 4096))

(define (interp-proc-profile-table)
  (interp-proc-profile-buffer/flush)
  (hash-table/entries-vector *interp-proc-profile-table*))

(define *interp-proc-profile-table/old* #F)
(define (interp-proc-profile-table/old)
        *interp-proc-profile-table/old*)

(define (interp-proc-profile-table/reset #!optional disable?)
  (set! *interp-proc-profile-table/old*
	(interp-proc-profile-table))
  (hash-table/clear! *interp-proc-profile-table*)
  (set! *interp-proc-profile-buffer/status/old*
	(interp-proc-profile-buffer/status))
  (cond ((and (not (default-object? disable?)) disable?)
	 (set! *interp-proc-profile-buffer* #F)	; disable buffer disables table
	 (fixed-interp-proc-profile-buffer/disable)
	 ;; TODO: really should detect if last to be disabled so set overall
	 ;;       sampling state to disabled
	 (if (pc-sample/initialized?)
	     'RESET-AND-DISABLED
	     'STILL-UNINITIALIZED))
	((not *interp-proc-profile-buffer*) 	; disabled but wanna enable?
	 (interp-proc-profile-buffer/reset))
	(else
	 'RESET)))

(define (interp-proc-profile-table/enable)
        (interp-proc-profile-table/reset))

(define (interp-proc-profile-table/disable)
        (interp-proc-profile-table/reset 'DISABLE))

(define (interp-proc-profile-table/hash-entry proc-lambda)
  (cond ((hash-table/get *interp-proc-profile-table* proc-lambda false)
	 =>
	 (lambda (datum)		; found
	   (interp-proc-profile-datum/update! datum)))
	(else				; not found
	 (hash-table/put! *interp-proc-profile-table* 
			  proc-lambda
			  (interp-proc-profile-datum/make)))))

;;; Interp-Proc Profile Datum

(define-structure (interp-proc-profile-datum
		   (conc-name interp-proc-profile-datum/)
		   (constructor interp-proc-profile-datum/make
				(#!optional count histogram rank utility)))
  (count     (interp-proc-profile-datum/count/make))
  (histogram (interp-proc-profile-datum/histogram/make))
  (rank      (interp-proc-profile-datum/rank/make))
  (utility   (interp-proc-profile-datum/utility/make))
  ;... more to come (?)
  )

(define (interp-proc-profile-datum/count/make)      1.0) ; FLONUM
(define (interp-proc-profile-datum/histogram/make) '#())
(define (interp-proc-profile-datum/rank/make)         0)
(define (interp-proc-profile-datum/utility/make)    0.0) ; FLONUM
;... more to come (?)

(define (interp-proc-profile-datum/update! datum)
  (set-interp-proc-profile-datum/count!
     datum
     (flo:+ 1.0 (interp-proc-profile-datum/count datum))) ; FLONUM
  ;; histogram not yet implemented
  ;; rank      not yet implemented
  ;; utility   not yet implemented

  ;; NB: returns datum
  datum)

;;; fini
