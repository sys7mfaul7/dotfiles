#!/bin/sh
# ~/.xsession : called by the Guix lightdm session wrapper with the session
# command as arguments; with none, start the X11 bspwm session.
# part of sys7mfaul7 dotfiles
[ $# -eq 0 ] && exec bspwm
exec "$@"
