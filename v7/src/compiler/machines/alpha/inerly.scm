#| -*-Scheme-*-

$Id: inerly.scm,v 1.4 2001/12/20 02:03:21 cph Exp $

Copyright (c) 1992-1999, 2001 Massachusetts Institute of Technology

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
02111-1307, USA.
|#

;;; Alpha Instruction Set Macros.  Early version
;;; Package: (compiler lap-syntaxer)

(declare (usual-integrations))

;;;; Transformers and utilities

;;; NOPs for now.

(define early-instructions '())
(define early-transformers '())

(define (define-early-transformer name transformer)
  (set! early-transformers
	(cons (cons name transformer)
	      early-transformers)))

;;; Instruction and addressing mode macros

(syntax-table/define (->environment '(COMPILER))
		     'DEFINE-INSTRUCTION
  (lambda (opcode . patterns)
    `(SET! EARLY-INSTRUCTIONS
	   (CONS
	    (LIST ',opcode
		  ,@(map (lambda (pattern)
			   `(early-parse-rule
			     ',(car pattern)
			     (lambda (pat vars)
			       (early-make-rule
				pat
				vars
				(scode-quote
				 (instruction->instruction-sequence
				  ,(parse-instruction (cadr pattern)
						      (cddr pattern)
						      true)))))))
			 patterns))
		 EARLY-INSTRUCTIONS))))