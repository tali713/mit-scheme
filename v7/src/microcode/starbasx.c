/* -*-C-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/microcode/Attic/starbasx.c,v 1.4 1990/10/02 22:52:12 cph Rel $

Copyright (c) 1989, 1990 Massachusetts Institute of Technology

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
MIT in each case. */

/* Starbase/X11 interface */

#include "scheme.h"
#include "prims.h"
#include "x11.h"
#include <starbase.c.h>

DEFINE_PRIMITIVE ("X11-WINDOW-STARBASE-FILENAME", Prim_x11_window_starbase_filename, 1, 1,
  "Given a window, returns the name of a file which can be opened\n\
as a Starbase graphics device.")
{
  PRIMITIVE_HEADER (1);
  {
    struct xwindow * xw = (x_window_arg (1));
    char * starbase_filename =
      (make_X11_gopen_string ((XW_DISPLAY (xw)), (XW_WINDOW (xw))));
    PRIMITIVE_RETURN
      ((starbase_filename == 0)
       ? SHARP_F
       : (char_pointer_to_string (starbase_filename)));
  }
}
