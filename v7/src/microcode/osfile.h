/* -*-C-*-

$Id: osfile.h,v 1.7 2007/01/05 15:33:07 cph Exp $

Copyright 1990,1993,2004 Massachusetts Institute of Technology

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

*/

#ifndef SCM_OSFILE_H
#define SCM_OSFILE_H

#include "os.h"

extern Tchannel EXFUN (OS_open_input_file, (CONST char * filename));
extern Tchannel EXFUN (OS_open_output_file, (CONST char * filename));
extern Tchannel EXFUN (OS_open_io_file, (CONST char * filename));
extern Tchannel EXFUN (OS_open_append_file, (CONST char * filename));
extern Tchannel EXFUN (OS_open_load_file, (CONST char * filename));
extern Tchannel EXFUN (OS_open_dump_file, (CONST char * filename));
extern off_t EXFUN (OS_file_length, (Tchannel channel));
extern off_t EXFUN (OS_file_position, (Tchannel channel));
extern void EXFUN (OS_file_set_position, (Tchannel channel, off_t position));
extern void EXFUN (OS_file_truncate, (Tchannel channel, off_t length));

#endif /* SCM_OSFILE_H */
