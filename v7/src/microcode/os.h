/* -*-C-*-

$Id: os.h,v 1.8 2002/11/20 19:46:11 cph Exp $

Copyright (c) 1990-2000 Massachusetts Institute of Technology

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

#ifndef SCM_OS_H
#define SCM_OS_H

#include "config.h"

typedef unsigned int Tchannel;

extern PTR EXFUN (OS_malloc, (unsigned int));
extern PTR EXFUN (OS_realloc, (PTR, unsigned int));
extern void EXFUN (OS_free, (PTR));

#define FASTCOPY(from, to, n)						\
{									\
  const char * FASTCOPY_scan_src = (from);				\
  const char * FASTCOPY_end_src = (FASTCOPY_scan_src + (n));		\
  char * FASTCOPY_scan_dst = (to);					\
  while (FASTCOPY_scan_src < FASTCOPY_end_src)				\
    (*FASTCOPY_scan_dst++) = (*FASTCOPY_scan_src++);			\
}

#endif /* SCM_OS_H */
