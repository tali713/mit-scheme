#| -*-Scheme-*-

$Id: decls.scm,v 1.5 1993/07/16 19:27:46 gjr Exp $

Copyright (c) 1992-1993 Massachusetts Institute of Technology

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

;;;; Compiler File Dependencies
;;; package: (compiler declarations)

(declare (usual-integrations))

(define (initialize-package!)
  (add-event-receiver! event:after-restore reset-source-nodes!)
  (reset-source-nodes!))

(define (reset-source-nodes!)
  (set! source-filenames '())
  (set! source-hash)
  (set! source-nodes)
  (set! source-nodes/by-rank)
  unspecific)

(define (maybe-setup-source-nodes!)
  (if (null? source-filenames)
      (setup-source-nodes!)))

(define (setup-source-nodes!)
  (let ((filenames
	 (append-map!
	  (lambda (subdirectory)
	    (map (lambda (pathname)
		   (string-append subdirectory
				  "/"
				  (pathname-name pathname)))
		 (directory-read
		  (string-append subdirectory
				 "/"
				 source-file-expression))))
	  '("back" "base" "fggen" "fgopt" "rtlbase" "rtlgen" "rtlopt"
		   "machines/i386"))))
    (if (null? filenames)
	(error "Can't find source files of compiler"))
    (set! source-filenames filenames))
  (set! source-hash
	(make/hash-table
	 101
	 string-hash-mod
	 (lambda (filename source-node)
	   (string=? filename (source-node/filename source-node)))
	 make/source-node))
  (set! source-nodes
	(map (lambda (filename)
	       (hash-table/intern! source-hash
				   filename
				   identity-procedure
				   identity-procedure))
	     source-filenames))
  (initialize/syntax-dependencies!)
  (initialize/integration-dependencies!)
  (initialize/expansion-dependencies!)
  (source-nodes/rank!))

(define source-file-expression "*.scm")
(define source-filenames)
(define source-hash)
(define source-nodes)
(define source-nodes/by-rank)

(define (filename/append directory . names)
  (map (lambda (name) (string-append directory "/" name)) names))

(define-structure (source-node
		   (conc-name source-node/)
		   (constructor make/source-node (filename)))
  (filename false read-only true)
  (pathname (->pathname filename) read-only true)
  (forward-links '())
  (backward-links '())
  (forward-closure '())
  (backward-closure '())
  (dependencies '())
  (dependents '())
  (rank false)
  (syntax-table false)
  (declarations '())
  (modification-time false))

(define (filename->source-node filename)
  (hash-table/lookup source-hash
		     filename
		     identity-procedure
		     (lambda () (error "Unknown source file" filename))))

(define (source-node/circular? node)
  (memq node (source-node/backward-closure node)))

(define (source-node/link! node dependency)
  (if (not (memq dependency (source-node/backward-links node)))
      (begin
	(set-source-node/backward-links!
	 node
	 (cons dependency (source-node/backward-links node)))
	(set-source-node/forward-links!
	 dependency
	 (cons node (source-node/forward-links dependency)))
	(source-node/close! node dependency))))

(define (source-node/close! node dependency)
  (if (not (memq dependency (source-node/backward-closure node)))
      (begin
	(set-source-node/backward-closure!
	 node
	 (cons dependency (source-node/backward-closure node)))
	(set-source-node/forward-closure!
	 dependency
	 (cons node (source-node/forward-closure dependency)))
	(for-each (lambda (dependency)
		    (source-node/close! node dependency))
		  (source-node/backward-closure dependency))
	(for-each (lambda (node)
		    (source-node/close! node dependency))
		  (source-node/forward-closure node)))))

;;;; Rank

(define (source-nodes/rank!)
  (compute-dependencies! source-nodes)
  (compute-ranks! source-nodes)
  (set! source-nodes/by-rank (source-nodes/sort-by-rank source-nodes))
  unspecific)

(define (compute-dependencies! nodes)
  (for-each (lambda (node)
	      (set-source-node/dependencies!
	       node
	       (list-transform-negative (source-node/backward-closure node)
		 (lambda (node*)
		   (memq node (source-node/backward-closure node*)))))
	      (set-source-node/dependents!
	       node
	       (list-transform-negative (source-node/forward-closure node)
		 (lambda (node*)
		   (memq node (source-node/forward-closure node*))))))
	    nodes))

(define (compute-ranks! nodes)
  (let loop ((nodes nodes) (unranked-nodes '()))
    (if (null? nodes)
	(if (not (null? unranked-nodes))
	    (loop unranked-nodes '()))
	(loop (cdr nodes)
	      (let ((node (car nodes)))
		(let ((rank (source-node/rank* node)))
		  (if rank
		      (begin
			(set-source-node/rank! node rank)
			unranked-nodes)
		      (cons node unranked-nodes))))))))

(define (source-node/rank* node)
  (let loop ((nodes (source-node/dependencies node)) (rank -1))
    (if (null? nodes)
	(1+ rank)
	(let ((rank* (source-node/rank (car nodes))))
	  (and rank*
	       (loop (cdr nodes) (max rank rank*)))))))

(define (source-nodes/sort-by-rank nodes)
  (sort nodes (lambda (x y) (< (source-node/rank x) (source-node/rank y)))))

;;;; File Syntaxer

(define (syntax-files!)
  (maybe-setup-source-nodes!)
  (for-each
   (lambda (node)
     (let ((modification-time
	    (let ((source (modification-time node "scm"))
		  (binary (modification-time node "bin")))
	      (if (not source)
		  (error "Missing source file" (source-node/filename node)))
	      (and binary (< source binary) binary))))
     (set-source-node/modification-time! node modification-time)
     (if (not modification-time)
	 (begin (write-string "\nSource file newer than binary: ")
		(write (source-node/filename node))))))
   source-nodes)
  (if compiler:enable-integration-declarations?
      (begin
	(for-each
	 (lambda (node)
	   (let ((time (source-node/modification-time node)))
	     (if (and time
		      (there-exists? (source-node/dependencies node)
			(lambda (node*)
			  (let ((newer?
				 (let ((time*
					(source-node/modification-time node*)))
				   (or (not time*)
				       (> time* time)))))
			    (if newer?
				(begin
				  (write-string "\nBinary file ")
				  (write (source-node/filename node))
				  (write-string " newer than dependency ")
				  (write (source-node/filename node*))))
			    newer?))))
		 (set-source-node/modification-time! node false))))
	 source-nodes)
	(for-each
	 (lambda (node)
	   (if (not (source-node/modification-time node))
	       (for-each (lambda (node*)
			   (if (source-node/modification-time node*)
			       (begin
				 (write-string "\nBinary file ")
				 (write (source-node/filename node*))
				 (write-string " depends on ")
				 (write (source-node/filename node))))
			   (set-source-node/modification-time! node* false))
			 (source-node/forward-closure node))))
	 source-nodes)))
  (for-each (lambda (node)
	      (if (not (source-node/modification-time node))
		  (pathname-delete!
		   (pathname-new-type (source-node/pathname node) "ext"))))
	    source-nodes/by-rank)
  (write-string "\n\nBegin pass 1:")
  (for-each (lambda (node)
	      (if (not (source-node/modification-time node))
		  (source-node/syntax! node)))
	    source-nodes/by-rank)
  (if (there-exists? source-nodes/by-rank
	(lambda (node)
	  (and (not (source-node/modification-time node))
	       (source-node/circular? node))))
      (begin
	(write-string "\n\nBegin pass 2:")
	(for-each (lambda (node)
		    (if (not (source-node/modification-time node))
			(if (source-node/circular? node)
			    (source-node/syntax! node)
			    (source-node/touch! node))))
		  source-nodes/by-rank))))

(define (source-node/touch! node)
  (with-values
      (lambda ()
	(sf/pathname-defaulting (source-node/pathname node) "" false))
    (lambda (input-pathname bin-pathname spec-pathname)
      input-pathname
      (pathname-touch! bin-pathname)
      (pathname-touch! (pathname-new-type bin-pathname "ext"))
      (if spec-pathname (pathname-touch! spec-pathname)))))

(define (pathname-touch! pathname)
  (if (file-exists? pathname)
      (begin
	(write-string "\nTouch file: ")
	(write (enough-namestring pathname))
	(file-touch pathname))))

(define (pathname-delete! pathname)
  (if (file-exists? pathname)
      (begin
	(write-string "\nDelete file: ")
	(write (enough-namestring pathname))
	(delete-file pathname))))

(define (sc filename)
  (maybe-setup-source-nodes!)
  (source-node/syntax! (filename->source-node filename)))

(define (source-node/syntax! node)
  (with-values
      (lambda ()
	(sf/pathname-defaulting (source-node/pathname node) "" false))
    (lambda (input-pathname bin-pathname spec-pathname)
      (sf/internal
       input-pathname bin-pathname spec-pathname
       (source-node/syntax-table node)
       ((if compiler:enable-integration-declarations?
	    identity-procedure
	    (lambda (declarations)
	      (list-transform-negative declarations
		integration-declaration?)))
	((if compiler:enable-expansion-declarations?
	     identity-procedure
	     (lambda (declarations)
	       (list-transform-negative declarations
		 expansion-declaration?)))
	 (source-node/declarations node)))))))

(define-integrable (modification-time node type)
  (file-modification-time
   (pathname-new-type (source-node/pathname node) type)))

;;;; Syntax dependencies

(define (initialize/syntax-dependencies!)
  (let ((file-dependency/syntax/join
	 (lambda (filenames syntax-table)
	   (for-each (lambda (filename)
		       (set-source-node/syntax-table!
			(filename->source-node filename)
			syntax-table))
		     filenames))))
    (file-dependency/syntax/join
     (append (filename/append "base"
			      "toplev" "asstop" "crstop"
			      "blocks" "cfg1" "cfg2" "cfg3" "constr"
			      "contin" "ctypes" "debug" "enumer"
			      "infnew" "lvalue" "object" "pmerly" "proced"
			      "refctx" "rvalue" "scode" "sets" "subprb"
			      "switch" "utils")
	     (filename/append "back"
			      "asmmac" "bittop" "bitutl" "insseq" "lapgn1"
			      "lapgn2" "lapgn3" "linear" "regmap" "symtab"
			      "syntax")
	     (filename/append "machines/i386"
			      "dassm1" "insmac" "lapopt" "machin" "rgspcm"
			      "rulrew")
	     (filename/append "fggen"
			      "declar" "fggen" "canon")
	     (filename/append "fgopt"
			      "blktyp" "closan" "conect" "contan" "delint"
			      "desenv" "envopt" "folcon" "offset" "operan"
			      "order" "outer" "param" "reord" "reteqv" "reuse"
			      "sideff" "simapp" "simple" "subfre" "varind")
	     (filename/append "rtlbase"
			      "regset" "rgraph" "rtlcfg" "rtlcon" "rtlexp"
			      "rtline" "rtlobj" "rtlreg" "rtlty1" "rtlty2"
			      "valclass")
	     (filename/append "rtlgen"
			      "fndblk" "fndvar" "opncod" "rgcomb" "rgproc"
			      "rgretn" "rgrval" "rgstmt" "rtlgen")
	     (filename/append "rtlopt"
			      "ralloc" "rcompr" "rcse1" "rcse2" "rcseep"
			      "rcseht" "rcserq" "rcsesr" "rdebug" "rdflow"
			      "rerite" "rinvex" "rlife" "rtlcsm"))
     compiler-syntax-table)
    (file-dependency/syntax/join
     (filename/append "machines/i386"
		      "lapgen"
		      "rules1" "rules2" "rules3" "rules4" "rulfix" "rulflo")
     lap-generator-syntax-table)
    (file-dependency/syntax/join
     (filename/append "machines/i386" "insutl" "instr1" "instr2" "instrf")
     assembler-syntax-table)))

;;;; Integration Dependencies

(define (initialize/integration-dependencies!)

  (define (add-declaration! declaration filenames)
    (for-each (lambda (filenames)
		(let ((node (filename->source-node filenames)))
		  (set-source-node/declarations!
		   node
		   (cons declaration
			 (source-node/declarations node)))))
	      filenames))

  (let* ((front-end-base
	  (filename/append "base"
			   "blocks" "cfg1" "cfg2" "cfg3"
			   "contin" "ctypes" "enumer" "lvalue"
			   "object" "proced" "rvalue"
			   "scode" "subprb" "utils"))
	 (i386-base
	  (append (filename/append "machines/i386" "machin")
		  (filename/append "back" "asutl")))
	 (rtl-base
	  (filename/append "rtlbase"
			   "rgraph" "rtlcfg" "rtlobj" "rtlreg" "rtlty1"
			   "rtlty2"))
	 (cse-base
	  (filename/append "rtlopt"
			   "rcse1" "rcseht" "rcserq" "rcsesr"))
	 (cse-all
	  (append (filename/append "rtlopt"
				   "rcse2" "rcseep")
		  cse-base))
	 (instruction-base
	  (filename/append "machines/i386" "assmd" "machin"))
	 (lapgen-base
	  (append (filename/append "back" "linear" "regmap")
		  (filename/append "machines/i386" "lapgen")))
	 (assembler-base
	  (append (filename/append "back" "symtab")
		  (filename/append "machines/i386" "insutl")))
	 (lapgen-body
	  (append
	   (filename/append "back" "lapgn1" "lapgn2" "syntax")
	   (filename/append "machines/i386"
			    "rules1" "rules2" "rules3" "rules4"
			    "rulfix" "rulflo")))
	 (assembler-body
	  (append
	   (filename/append "back" "bittop")
	   (filename/append "machines/i386"
			    "instr1" "instr2" "instrf"))))

    (define (file-dependency/integration/join filenames dependencies)
      (for-each (lambda (filename)
		  (file-dependency/integration/make filename dependencies))
		filenames))

    (define (file-dependency/integration/make filename dependencies)
      (let ((node (filename->source-node filename)))
	(for-each (lambda (dependency)
		    (let ((node* (filename->source-node dependency)))
		      (if (not (eq? node node*))
			  (source-node/link! node node*))))
		  dependencies)))

    (define (define-integration-dependencies directory name directory* . names)
      (file-dependency/integration/make
       (string-append directory "/" name)
       (apply filename/append directory* names)))

    (define-integration-dependencies "machines/i386" "machin" "back" "asutl")
    (define-integration-dependencies "base" "object" "base" "enumer")
    (define-integration-dependencies "base" "enumer" "base" "object")
    (define-integration-dependencies "base" "utils" "base" "scode")
    (define-integration-dependencies "base" "cfg1" "base" "object")
    (define-integration-dependencies "base" "cfg2" "base"
      "cfg1" "cfg3" "object")
    (define-integration-dependencies "base" "cfg3" "base" "cfg1" "cfg2")
    (define-integration-dependencies "base" "ctypes" "base"
      "blocks" "cfg1" "cfg2" "cfg3" "contin" "lvalue" "object" "subprb")
    (define-integration-dependencies "base" "rvalue" "base"
      "blocks" "cfg1" "cfg2" "cfg3" "enumer" "lvalue" "object" "utils")
    (define-integration-dependencies "base" "lvalue" "base"
      "blocks" "object" "proced" "rvalue" "utils")
    (define-integration-dependencies "base" "blocks" "base"
      "enumer" "lvalue" "object" "proced" "rvalue" "scode")
    (define-integration-dependencies "base" "proced" "base"
      "blocks" "cfg1" "cfg2" "cfg3" "contin" "enumer" "lvalue" "object"
      "rvalue" "utils")
    (define-integration-dependencies "base" "contin" "base"
      "blocks" "cfg3" "ctypes")
    (define-integration-dependencies "base" "subprb" "base"
      "cfg3" "contin" "enumer" "object" "proced")

    (define-integration-dependencies "machines/i386" "machin" "rtlbase"
      "rtlreg" "rtlty1" "rtlty2")

    (define-integration-dependencies "rtlbase" "rgraph" "base" "cfg1" "cfg2")
    (define-integration-dependencies "rtlbase" "rgraph" "machines/i386"
      "machin")
    (define-integration-dependencies "rtlbase" "rtlcfg" "base"
      "cfg1" "cfg2" "cfg3")
    (define-integration-dependencies "rtlbase" "rtlcon" "base" "cfg3" "utils")
    (define-integration-dependencies "rtlbase" "rtlcon" "machines/i386"
      "machin")
    (file-dependency/integration/join (filename/append "rtlbase" "rtlcon")
				      rtl-base)
    (define-integration-dependencies "rtlbase" "rtlexp" "rtlbase"
      "rtlreg" "rtlty1")
    (define-integration-dependencies "rtlbase" "rtline" "base" "cfg1" "cfg2")
    (define-integration-dependencies "rtlbase" "rtline" "rtlbase"
      "rtlcfg" "rtlty2")
    (define-integration-dependencies "rtlbase" "rtlobj" "base"
      "cfg1" "object" "utils")
    (define-integration-dependencies "rtlbase" "rtlreg" "machines/i386"
      "machin")
    (define-integration-dependencies "rtlbase" "rtlreg" "rtlbase"
      "rgraph" "rtlty1")
    (define-integration-dependencies "rtlbase" "rtlty1" "rtlbase" "rtlcfg")
    (define-integration-dependencies "rtlbase" "rtlty2" "base" "scode")
    (define-integration-dependencies "rtlbase" "rtlty2" "machines/i386"
      "machin")
    (define-integration-dependencies "rtlbase" "rtlty2" "rtlbase" "rtlty1")

    (file-dependency/integration/join
     (append
      (filename/append "base" "refctx")
      (filename/append "fggen"
		       "declar" "fggen") ; "canon" needs no integrations
      (filename/append "fgopt"
		       "blktyp" "closan" "conect" "contan" "delint" "desenv"
		       "envopt" "folcon" "offset" "operan" "order" "param"
		       "outer" "reuse" "reteqv" "sideff" "simapp" "simple"
		       "subfre" "varind"))
     (append i386-base front-end-base))

    (define-integration-dependencies "fgopt" "reuse" "fgopt" "reord")

    (file-dependency/integration/join
     (filename/append "rtlgen"
		      "fndblk" "fndvar" "opncod" "rgcomb" "rgproc" "rgretn"
		      "rgrval" "rgstmt" "rtlgen")
     (append i386-base front-end-base rtl-base))

    (file-dependency/integration/join
     (append cse-all
	     (filename/append "rtlopt" "ralloc" "rcompr" "rdebug" "rdflow"
			      "rerite" "rinvex" "rlife" "rtlcsm")
	     (filename/append "machines/i386" "rulrew"))
     (append i386-base rtl-base))

    (file-dependency/integration/join cse-all cse-base)

    (file-dependency/integration/join
     (filename/append "rtlopt" "ralloc" "rcompr" "rdebug" "rlife")
     (filename/append "rtlbase" "regset"))

    (file-dependency/integration/join
     (filename/append "rtlopt" "rcseht" "rcserq")
     (filename/append "base" "object"))

    (define-integration-dependencies "rtlopt" "rlife"  "base" "cfg2")

    (let ((dependents
	   (append instruction-base
		   lapgen-base
		   lapgen-body
		   assembler-base
		   assembler-body
		   (filename/append "back" "linear" "syerly"))))
      (add-declaration! '(USUAL-DEFINITION (SET EXPT)) dependents)
      (file-dependency/integration/join dependents instruction-base))

    (file-dependency/integration/join (append lapgen-base lapgen-body)
				      lapgen-base)

    (file-dependency/integration/join (append assembler-base assembler-body)
				      assembler-base)

    (define-integration-dependencies "back" "lapgn1" "base"
      "cfg1" "cfg2" "utils")
    (define-integration-dependencies "back" "lapgn1" "rtlbase"
      "rgraph" "rtlcfg")
    (define-integration-dependencies "back" "lapgn2" "rtlbase" "rtlreg")
    (define-integration-dependencies "back" "linear" "base" "cfg1" "cfg2")
    (define-integration-dependencies "back" "linear" "rtlbase" "rtlcfg")
    (define-integration-dependencies "back" "mermap" "back" "regmap")
    (define-integration-dependencies "back" "regmap" "base" "utils")
    (define-integration-dependencies "back" "symtab" "base" "utils"))

  (for-each (lambda (node)
	      (let ((links (source-node/backward-links node)))
		(if (not (null? links))
		    (set-source-node/declarations!
		     node
		     (cons (make-integration-declaration
			    (source-node/pathname node)
			    (map source-node/pathname links))
			   (source-node/declarations node))))))
	    source-nodes))

(define (make-integration-declaration pathname integration-dependencies)
  `(INTEGRATE-EXTERNAL
    ,@(map (let ((default
		  (make-pathname
		   false
		   false
		   (cons 'RELATIVE
			 (make-list
			  (length (cdr (pathname-directory pathname)))
			  'UP))
		   false
		   false
		   false)))
	     (lambda (pathname)
	       (merge-pathnames pathname default)))
	   integration-dependencies)))

(define-integrable (integration-declaration? declaration)
  (eq? (car declaration) 'INTEGRATE-EXTERNAL))

;;;; Expansion Dependencies

(define (initialize/expansion-dependencies!)
  (let ((file-dependency/expansion/join
	 (lambda (filenames expansions)
	   (for-each (lambda (filename)
		       (let ((node (filename->source-node filename)))
			 (set-source-node/declarations!
			  node
			  (cons (make-expansion-declaration expansions)
				(source-node/declarations node)))))
		     filenames))))
    (file-dependency/expansion/join
     (filename/append "machines/i386"
		      "lapgen" "rules1" "rules2" "rules3" "rules4"
		      "rulfix" "rulflo")
     (map (lambda (entry)
	    `(,(car entry)
	      (PACKAGE/REFERENCE (FIND-PACKAGE '(COMPILER LAP-SYNTAXER))
				 ',(cadr entry))))
	  '((LAP:SYNTAX-INSTRUCTION LAP:SYNTAX-INSTRUCTION-EXPANDER)
	    (INSTRUCTION->INSTRUCTION-SEQUENCE
	     INSTRUCTION->INSTRUCTION-SEQUENCE-EXPANDER)
	    (SYNTAX-EVALUATION SYNTAX-EVALUATION-EXPANDER)
	    (CONS-SYNTAX CONS-SYNTAX-EXPANDER)
	    (OPTIMIZE-GROUP-EARLY OPTIMIZE-GROUP-EXPANDER)
	    (EA-KEYWORD-EARLY EA-KEYWORD-EXPANDER)
	    (EA-MODE-EARLY EA-MODE-EXPANDER)
	    (EA-REGISTER-EARLY EA-REGISTER-EXPANDER)
	    (EA-EXTENSION-EARLY EA-EXTENSION-EXPANDER)
	    (EA-CATEGORIES-EARLY EA-CATEGORIES-EXPANDER))))))

(define-integrable (make-expansion-declaration expansions)
  `(EXPAND-OPERATOR ,@expansions))

(define-integrable (expansion-declaration? declaration)
  (eq? (car declaration) 'EXPAND-OPERATOR))