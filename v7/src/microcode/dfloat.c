/* -*-C-*-

$Id: dfloat.c,v 1.7 2002/11/20 19:46:08 cph Exp $

Copyright (c) 1991-1999 Massachusetts Institute of Technology

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

*/

/* Floating-point vector primitives */

#include "scheme.h"
#include "prims.h"

#define FLOATING_VECTOR_INDEX_ARG(argument_number, vector)		\
  (arg_index_integer ((argument_number), (FLOATING_VECTOR_LENGTH (vector))))

DEFINE_PRIMITIVE ("FLOATING-VECTOR-CONS", Prim_floating_vector_cons, 1, 1, 0)
{
  PRIMITIVE_HEADER (1);
  {
    long length = (arg_nonnegative_integer (1));
    long length_in_words = (length * FLONUM_SIZE);
    SCHEME_OBJECT result;
    fast double *vect;

    ALIGN_FLOAT (Free);
    Primitive_GC_If_Needed (length_in_words + 1);
    result = (MAKE_POINTER_OBJECT (TC_BIG_FLONUM, Free));
    (*Free++) = (MAKE_OBJECT (TC_MANIFEST_NM_VECTOR, length_in_words));
    vect = ((double *) Free);
    while ((length--) > 0) (*vect++) = 0.0;
    Free = ((SCHEME_OBJECT *) vect);
    PRIMITIVE_RETURN (result);
  }
}

DEFINE_PRIMITIVE ("FLOATING-VECTOR-REF", Prim_floating_vector_ref, 2, 2, 0)
{
  PRIMITIVE_HEADER (2);
  {
    SCHEME_OBJECT vector = (FLOATING_VECTOR_ARG (1));
    Primitive_GC_If_Needed (FLONUM_SIZE + 1);
    PRIMITIVE_RETURN
      (FLOAT_TO_FLONUM
       (FLOATING_VECTOR_REF (vector,
			     (FLOATING_VECTOR_INDEX_ARG (2, vector)))));
  }
}

extern double EXFUN (arg_flonum, (int));

DEFINE_PRIMITIVE ("FLOATING-VECTOR-SET!", Prim_floating_vector_set, 3, 3, 0)
{
  PRIMITIVE_HEADER (3);
  {
    SCHEME_OBJECT vector = (FLOATING_VECTOR_ARG (1));
    FLOATING_VECTOR_SET
      (vector,
       (FLOATING_VECTOR_INDEX_ARG (2, vector)),
       (arg_flonum (3)));
  }
  PRIMITIVE_RETURN (UNSPECIFIC);
}

DEFINE_PRIMITIVE ("FLOATING-VECTOR-LENGTH", Prim_floating_vector_length, 1, 1,
		  0)
{
  PRIMITIVE_HEADER (1);
  PRIMITIVE_RETURN
    (LONG_TO_UNSIGNED_FIXNUM
     (FLOATING_VECTOR_LENGTH (FLOATING_VECTOR_ARG (1))));
}
