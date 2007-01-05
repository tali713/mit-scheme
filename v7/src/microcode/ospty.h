/* -*-C-*-

$Id: ospty.h,v 1.7 2007/01/05 15:33:07 cph Exp $

Copyright (c) 1992, 1999 Massachusetts Institute of Technology

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

#ifndef SCM_OSPTY_H
#define SCM_OSPTY_H

#include "os.h"

extern CONST char * EXFUN
  (OS_open_pty_master, (Tchannel * master_fd, CONST char ** master_fname));
extern void EXFUN (OS_pty_master_send_signal, (Tchannel channel, int sig));
extern void EXFUN (OS_pty_master_kill, (Tchannel channel));
extern void EXFUN (OS_pty_master_stop, (Tchannel channel));
extern void EXFUN (OS_pty_master_continue, (Tchannel channel));
extern void EXFUN (OS_pty_master_interrupt, (Tchannel channel));
extern void EXFUN (OS_pty_master_quit, (Tchannel channel));
extern void EXFUN (OS_pty_master_hangup, (Tchannel channel));

#endif /* SCM_OSPTY_H */
