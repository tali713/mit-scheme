#| -*-Scheme-*-

$Id: os2dir.scm,v 1.8 2007/01/05 15:33:10 cph Exp $

Copyright (c) 1994-1999 Massachusetts Institute of Technology

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

;;;; Directory Operations -- OS/2
;;; package: (runtime directory)

(declare (usual-integrations))

(define *expand-directory-prefixes?* #t)

(define (directory-read pattern #!optional sort?)
  (if (if (default-object? sort?) #t sort?)
      (sort (directory-read-nosort pattern) pathname<?)
      (directory-read-nosort pattern)))

(define (directory-read-nosort pattern)
  (let ((pattern (merge-pathnames pattern)))
    (map (let ((directory-path (directory-pathname pattern)))
	   (lambda (pathname)
	     (merge-pathnames pathname directory-path)))
	 (let ((fnames (generate-directory-pathnames pattern)))
	   (fluid-let ((*expand-directory-prefixes?* #f))
	     (map ->pathname fnames))))))

(define (generate-directory-pathnames pathname)
  (let ((channel (directory-channel-open (->namestring pathname))))
    (let loop ((result '()))
      (let ((name (directory-channel-read channel)))
	(if name
	    (loop (cons name result))
	    (begin
	      (directory-channel-close channel)
	      result))))))

(define (pathname<? x y)
  (string-ci<? (file-namestring x) (file-namestring y)))