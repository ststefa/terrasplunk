#!/bin/bash
# $Id: 20190701 ssteine2 $

#set -x

# ensure proper umask in case parent shell has messed it up
umask 0002 || exit 1

HOME="$(cd "$(dirname "$0")" && pwd)" || exit $(false)

export PYTHONPATH=${HOME}

# Wildcard characters must not be expanded but instead passed to python as-is.
# However this cannot keep the parent (calling) shell from substituting :-/
# http://stackoverflow.com/questions/11456403/stop-shell-wildcard-character-expansion
set -f

if [ "$1" == "-i" ] ; then
    /usr/bin/env python3 $@
else
    /usr/bin/env python3 ${HOME}/parse_tfstate.py $@
fi

exit $?
