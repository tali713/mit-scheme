#!/bin/sh
#
# $Id: functions.sh,v 1.2 2002/11/20 19:46:05 cph Exp $
#
# Copyright (c) 2000 Massachusetts Institute of Technology
#
# This file is part of MIT Scheme.
#
# MIT Scheme is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# MIT Scheme is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with MIT Scheme; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.

# Functions for shell scripts.

maybe_mkdir ()
{
    if [ ! -e ${1} ]; then
	echo "mkdir ${1}"
	mkdir ${1}
    fi
}

maybe_link ()
{
    if [ ! -e ${1} ] && [ ! -L ${1} ]; then
	echo "ln -s ${2} ${1}"
	ln -s ${2} ${1}
    fi
}
