/* -*-C-*-

$Id: ntsys.h,v 1.9 2002/11/20 19:46:10 cph Exp $

Copyright (c) 1992-1999 Massachusetts Institute of Technology

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

#ifndef SCM_NTSYS_H
#define SCM_NTSYS_H

/* Misc */

extern BOOL win32_under_win32s_p ();
extern int  nt_console_write (void * vbuffer, size_t nsize);
extern BOOL nt_pathname_as_filename (const char * name, char * buffer);

#endif /* SCM_NTSYS_H */
