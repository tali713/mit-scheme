#| -*-Scheme-*-

$Id: table.scm,v 4.6 2002/11/20 19:46:25 cph Exp $

COPYRIGHT (c) 1988-1999 Massachusetts Institute of Technology

This file is part of MIT Scheme.

MIT Scheme is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

MIT Scheme is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with MIT Scheme; if not, write to the Free Software Foundation,
Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

|#

(declare (usual-integrations)
	 (automagic-integrations)
	 (open-block-optimizations)
	 (eta-substitution))

;;; simple table abstraction
;;;
;;; A table is a mutable mapping from key to value.  There is a
;;; comparison function to determine whether two keys are the same
 
;;; A table is a 4 tuple consisting of a get-function, a put-function,
;;; a remove-function, and a function to handle anything else.
;;;

;;; My big problem with this is that we have to go through the continuation
;;; passing style get function whether we want to or not.

(define-structure (table (conc-name %table-)
			 (constructor %make-table))
  (get-function false read-only true)
  (put!-function false read-only true)
  (remove!-function false read-only true)
  (anything-else false read-only true))

(define-integrable (table-get table key if-found if-not-found)
  ((%table-get-function table) key if-found if-not-found))

(define-integrable (table-put! table key value)
  ((%table-put!-function table) key value))

(define-integrable (table-remove! table key)
  ((%table-remove!-function table) key))

(define-integrable (table-function table operation arglist)
  ((%table-anything-else table) operation arglist))

(define (table-get-chain key1 if-found if-not-found . tables)
  (let loop ((table-list tables)
	     (key        key1))
    (if (null? table-list)
	(if-found key)
	(table-get (car table-list) key
	  (lambda (value) 
	    (loop (cdr table-list) value))
	  if-not-found))))

(define (table-get-list table keylist)
  (map (lambda (key)
	 (table-get table key 
		    identity-procedure
		    (lambda () #f)))
       keylist))

;;; Returns a table

(define (make-generic-eq?-table)
  (let ((the-table '()))

    (declare (integrate make-entry 
			entry-value
			set-entry-value!
			lookup 
			extend-table!))

    (define make-entry cons)
    (define entry-value cdr)
    (define set-entry-value! set-cdr!)

    (define (lookup key)
      (declare (integrate key))
      (assq key the-table))

    (define (extend-table! entry)
      (declare (integrate entry))
      (set! the-table (cons entry the-table)))

    ;; User functions

    (define (get key if-found if-not-found)
      (let ((entry (lookup key)))
	(if (not entry)
	    (if-not-found)
	    (if-found (entry-value entry)))))

    (define (put! key value)
      (let ((entry (lookup key)))
	(if (not entry)
	    (extend-table! (make-entry key value))
	    (set-entry-value! entry value))))

    (define (remove! key)
      (set! the-table (del-assq key the-table)))

    (define (dispatch message args)
      args
      (case message
	((predicate) eq?)
	(else (error "Don't understand that message"))))

    (%make-table get put! remove! dispatch)))