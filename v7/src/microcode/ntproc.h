/* -*-C-*-

$Id: ntproc.h,v 1.3 2002/11/20 19:46:10 cph Exp $

Copyright (c) 1997, 1999 Massachusetts Institute of Technology

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

#ifndef SCM_NTPROC_H
#define SCM_NTPROC_H

#include "osproc.h"

extern Tprocess NT_make_subprocess
 (const char *, const char *, const char *, const char *,
  enum process_channel_type, Tchannel,
  enum process_channel_type, Tchannel,
  enum process_channel_type, Tchannel,
  int);

#endif /* SCM_NTPROC_H */
