# OBLinux live session shell config for liveuser.
# This is a live/rescue account only; it is not carried over to installs made with Calamares.

autoload -Uz compinit && compinit
PS1='%F{cyan}oblinux%f:%~%# '
