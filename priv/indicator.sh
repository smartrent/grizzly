#!/bin/sh

# $1 - Should be turned on or not. If 0, then the indicator should be turned off

BEAM_NOTIFY=$(ls /srv/erlang/lib/beam_notify-*/priv/beam_notify)
SOCKET_PATH=/tmp/grizzly_beam_notify_socket

$BEAM_NOTIFY -p $SOCKET_PATH -- $@
