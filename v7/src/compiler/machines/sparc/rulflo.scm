#| -*-Scheme-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/compiler/machines/sparc/rulflo.scm,v 1.1 1993/06/08 06:11:02 gjr Exp $

Copyright (c) 1989-91 Massachusetts Institute of Technology

This material was developed by the Scheme project at the Massachusetts
Institute of Technology, Department of Electrical Engineering and
Computer Science.  Permission to copy this software, to redistribute
it, and to use it for any purpose is granted, subject to the following
restrictions and understandings.

1. Any copy made of this software must include this copyright notice
in full.

2. Users of this software agree to make their best efforts (a) to
return to the MIT Scheme project any improvements or extensions that
they make, so that these may be included in future releases; and (b)
to inform MIT of noteworthy uses of this software.

3. All materials developed as a consequence of the use of this
software shall duly acknowledge such use, in accordance with the usual
standards of acknowledging credit in academic research.

4. MIT has made no warrantee or representation that the operation of
this software will be error-free, and MIT is under no obligation to
provide any services, by way of maintenance, update, or otherwise.

5. In conjunction with products arising from the use of this material,
there shall be no use of the name of the Massachusetts Institute of
Technology nor of any adaptation thereof in any advertising,
promotional, or sales literature without prior written consent from
MIT in each case. |#

;;;; LAP Generation Rules: Flonum rules

(declare (usual-integrations))

(define (flonum-source! register)
  (float-register->fpr (load-alias-register! register 'FLOAT)))

(define (flonum-target! pseudo-register)
  (delete-dead-registers!)
  (float-register->fpr (allocate-alias-register! pseudo-register 'FLOAT)))

(define (flonum-temporary!)
  (float-register->fpr (allocate-temporary-register! 'FLOAT)))

(define-rule statement
  ;; convert a floating-point number to a flonum object
  (ASSIGN (REGISTER (? target))
	  (FLOAT->OBJECT (REGISTER (? source))))
  (let ((source (fpr->float-register (flonum-source! source))))
    (let ((target (standard-target! target)))
      (LAP
       ; (SW 0 (OFFSET 0 ,regnum:free))	; make heap parsable forwards
       (ORI ,regnum:free ,regnum:free #b100) ; Align to odd quad byte
       ,@(deposit-type-address (ucode-type flonum) regnum:free target)
       ,@(with-values
	     (lambda ()
	       (immediate->register
		(make-non-pointer-literal (ucode-type manifest-nm-vector) 2)))
	   (lambda (prefix alias)
	     (LAP ,@prefix
		  (SW ,alias (OFFSET 0 ,regnum:free)))))
       ,@(fp-store-doubleword 4 regnum:free source)
       (ADDI ,regnum:free ,regnum:free 12)))))

(define-rule statement
  ;; convert a flonum object to a floating-point number
  (ASSIGN (REGISTER (? target)) (OBJECT->FLOAT (REGISTER (? source))))
  (let ((source (standard-move-to-temporary! source)))
    (let ((target (fpr->float-register (flonum-target! target))))
      (LAP ,@(object->address source source)
	   ,@(fp-load-doubleword 4 source target #T)))))

;;;; Flonum Arithmetic

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (FLONUM-1-ARG (? operation) (REGISTER (? source)) (? overflow?)))
  overflow?				;ignore
  (let ((source (flonum-source! source)))
    ((flonum-1-arg/operator operation) (flonum-target! target) source)))

(define (flonum-1-arg/operator operation)
  (lookup-arithmetic-method operation flonum-methods/1-arg))

(define flonum-methods/1-arg
  (list 'FLONUM-METHODS/1-ARG))

;;; Notice the weird ,', syntax here.
;;; If LAP changes, this may also have to change.

(let-syntax
    ((define-flonum-operation
       (macro (primitive-name opcode)
	 `(define-arithmetic-method ',primitive-name flonum-methods/1-arg
	    (lambda (target source)
	      (LAP (,opcode ,',target ,',source)))))))
  (define-flonum-operation flonum-abs ABS.D)
  (define-flonum-operation flonum-negate NEG.D))

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (FLONUM-2-ARGS (? operation)
			 (REGISTER (? source1))
			 (REGISTER (? source2))
			 (? overflow?)))
  overflow?				;ignore
  (let ((source1 (flonum-source! source1))
	(source2 (flonum-source! source2)))
    ((flonum-2-args/operator operation) (flonum-target! target)
					source1
					source2)))

(define (flonum-2-args/operator operation)
  (lookup-arithmetic-method operation flonum-methods/2-args))

(define flonum-methods/2-args
  (list 'FLONUM-METHODS/2-ARGS))

(let-syntax
    ((define-flonum-operation
       (macro (primitive-name opcode)
	 `(define-arithmetic-method ',primitive-name flonum-methods/2-args
	    (lambda (target source1 source2)
	      (LAP (,opcode ,',target ,',source1 ,',source2)))))))
  (define-flonum-operation flonum-add ADD.D)
  (define-flonum-operation flonum-subtract SUB.D)
  (define-flonum-operation flonum-multiply MUL.D)
  (define-flonum-operation flonum-divide DIV.D))

;;;; Flonum Predicates

(define-rule predicate
  (FLONUM-PRED-1-ARG (? predicate) (REGISTER (? source)))
  ;; No immediate zeros, easy to generate by subtracting from itself
  (let ((temp (flonum-temporary!))
	(source (flonum-source! source)))
    (LAP (MTC1 0 ,temp)
	 (MTC1 0 ,(+ temp 1))
	 (NOP)
	 ,@(flonum-compare
	    (case predicate
	      ((FLONUM-ZERO?) 'C.EQ.D)
	      ((FLONUM-NEGATIVE?) 'C.LT.D)
	      ((FLONUM-POSITIVE?) 'C.GT.D)
	      (else (error "unknown flonum predicate" predicate)))
	    source temp))))

(define-rule predicate
  (FLONUM-PRED-2-ARGS (? predicate)
		      (REGISTER (? source1))
		      (REGISTER (? source2)))
  (flonum-compare (case predicate
		    ((FLONUM-EQUAL?) 'C.EQ.D)
		    ((FLONUM-LESS?) 'C.LT.D)
		    ((FLONUM-GREATER?) 'C.GT.D)
		    (else (error "unknown flonum predicate" predicate)))
		  (flonum-source! source1)
		  (flonum-source! source2)))

(define (flonum-compare cc r1 r2)
  (set-current-branches!
   (lambda (label)
     (LAP (BC1T (@PCR ,label)) (NOP)))
   (lambda (label)
     (LAP (BC1F (@PCR ,label)) (NOP))))
  (if (eq? cc 'C.GT.D)
      (LAP (C.LT.D ,r2 ,r1) (NOP))
      (LAP (,cc ,r1 ,r2) (NOP))))