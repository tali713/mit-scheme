;;; -*-Scheme-*-
;;;
;;; $Id: compile.scm,v 1.6 2002/11/20 19:46:25 cph Exp $
;;;
;;; Copyright (c) 1995-1999, 2001 Massachusetts Institute of Technology
;;;
;;; This file is part of MIT Scheme.
;;;
;;; MIT Scheme is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published
;;; by the Free Software Foundation; either version 2 of the License,
;;; or (at your option) any later version.
;;;
;;; MIT Scheme is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with MIT Scheme; if not, write to the Free Software
;;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;;; 02111-1307, USA.

(load-option 'CREF)

(with-working-directory-pathname (directory-pathname (current-load-pathname))
  (lambda ()
    (compile-file "class")
    (compile-file "instance")
    (compile-file "macros")
    (compile-file "method")
    (compile-file "printer")
    (compile-file "slot")
    (cref/generate-constructors "sos")))