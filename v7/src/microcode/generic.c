/* -*-C-*-

$Id: generic.c,v 9.40 2002/11/20 19:46:09 cph Exp $

Copyright (c) 1987-1999 Massachusetts Institute of Technology

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

#include "scheme.h"
#include "prims.h"

#define INDIRECT(slot, arity)						\
{									\
  PRIMITIVE_CANONICALIZE_CONTEXT ();					\
 Will_Push (STACK_ENV_EXTRA_SLOTS + 1);					\
  STACK_PUSH (Get_Fixed_Obj_Slot (slot));				\
  STACK_PUSH (STACK_FRAME_HEADER + arity);				\
 Pushed ();								\
  PRIMITIVE_ABORT (PRIM_APPLY);						\
  /*NOTREACHED*/							\
  PRIMITIVE_RETURN (UNSPECIFIC);					\
}

#define INDIRECT_TEST_1(test, slot)					\
{									\
  PRIMITIVE_HEADER (1);							\
  {									\
    fast SCHEME_OBJECT x = (ARG_REF (1));				\
    if (FIXNUM_P (x))							\
      return (BOOLEAN_TO_OBJECT (test (x)));				\
  }									\
  INDIRECT (slot, 1);							\
}

DEFINE_PRIMITIVE ("ZERO?", Prim_zero, 1, 1, 0)
     INDIRECT_TEST_1 (FIXNUM_ZERO_P, GENERIC_TRAMPOLINE_ZERO_P)
DEFINE_PRIMITIVE ("POSITIVE?", Prim_positive, 1, 1, 0)
     INDIRECT_TEST_1 (FIXNUM_POSITIVE_P, GENERIC_TRAMPOLINE_POSITIVE_P)
DEFINE_PRIMITIVE ("NEGATIVE?", Prim_negative, 1, 1, 0)
     INDIRECT_TEST_1 (FIXNUM_NEGATIVE_P, GENERIC_TRAMPOLINE_NEGATIVE_P)

#define INDIRECT_INCREMENT(op, slot)					\
{									\
  PRIMITIVE_HEADER (1);							\
  {									\
    fast SCHEME_OBJECT x = (ARG_REF (1));				\
    if (FIXNUM_P (x))							\
      return (long_to_integer ((FIXNUM_TO_LONG (x)) op 1));		\
  }									\
  INDIRECT (slot, 1);							\
}

DEFINE_PRIMITIVE ("1+", Prim_add_one, 1, 1, 0)
     INDIRECT_INCREMENT (+, GENERIC_TRAMPOLINE_SUCCESSOR)
DEFINE_PRIMITIVE ("-1+", Prim_subtract_one, 1, 1, 0)
     INDIRECT_INCREMENT (-, GENERIC_TRAMPOLINE_PREDECESSOR)

#define INDIRECT_TEST_2(test, slot)					\
{									\
  PRIMITIVE_HEADER (2);							\
  {									\
    fast SCHEME_OBJECT x = (ARG_REF (1));				\
    fast SCHEME_OBJECT y = (ARG_REF (2));				\
    if ((FIXNUM_P (x)) && (FIXNUM_P (y)))				\
      return (BOOLEAN_TO_OBJECT (test (x, y)));				\
  }									\
  INDIRECT (slot, 2);							\
}

#define FIXNUM_GREATER_P(x, y) FIXNUM_LESS_P (y, x)

DEFINE_PRIMITIVE ("&=", Prim_equal_number, 2, 2, 0)
     INDIRECT_TEST_2 (FIXNUM_EQUAL_P, GENERIC_TRAMPOLINE_EQUAL_P)
DEFINE_PRIMITIVE ("&<", Prim_less, 2, 2, 0)
     INDIRECT_TEST_2 (FIXNUM_LESS_P, GENERIC_TRAMPOLINE_LESS_P)
DEFINE_PRIMITIVE ("&>", Prim_greater, 2, 2, 0)
     INDIRECT_TEST_2 (FIXNUM_GREATER_P, GENERIC_TRAMPOLINE_GREATER_P)

#define INDIRECT_SUM(op, slot)						\
{									\
  PRIMITIVE_HEADER (2);							\
  {									\
    fast SCHEME_OBJECT x = (ARG_REF (1));				\
    fast SCHEME_OBJECT y = (ARG_REF (2));				\
    if ((FIXNUM_P (x)) && (FIXNUM_P (y)))				\
      return (long_to_integer ((FIXNUM_TO_LONG (x)) op			\
			       (FIXNUM_TO_LONG (y))));			\
  }									\
  INDIRECT (slot, 2);							\
}

DEFINE_PRIMITIVE ("&+", Prim_add, 2, 2, 0)
     INDIRECT_SUM (+, GENERIC_TRAMPOLINE_ADD)
DEFINE_PRIMITIVE ("&-", Prim_subtract, 2, 2, 0)
     INDIRECT_SUM (-, GENERIC_TRAMPOLINE_SUBTRACT)

#define INDIRECT_2(slot)						\
{									\
  PRIMITIVE_HEADER (2);							\
  INDIRECT (slot, 2);							\
}

DEFINE_PRIMITIVE ("&*", Prim_multiply, 2, 2, 0)
     INDIRECT_2 (GENERIC_TRAMPOLINE_MULTIPLY)
DEFINE_PRIMITIVE ("&/", Prim_divide, 2, 2, 0)
     INDIRECT_2 (GENERIC_TRAMPOLINE_DIVIDE)
DEFINE_PRIMITIVE ("QUOTIENT", Prim_quotient, 2, 2, 0)
     INDIRECT_2 (GENERIC_TRAMPOLINE_QUOTIENT)
DEFINE_PRIMITIVE ("REMAINDER", Prim_remainder, 2, 2, 0)
     INDIRECT_2 (GENERIC_TRAMPOLINE_REMAINDER)
DEFINE_PRIMITIVE ("MODULO", Prim_modulo, 2, 2, 0)
     INDIRECT_2 (GENERIC_TRAMPOLINE_MODULO)
